import Foundation

enum ShortcutResult: Equatable {
    case recordingStarted, pasted, discarded, busy
    case unsupportedLanguage(String)
}

enum VoiceTypingError: Error, LocalizedError, Equatable {
    case invalidLanguage, invalidCorrection, notReady, capture, focus, clipboard, paste

    var errorDescription: String? {
        switch self {
        case .invalidLanguage: return "Speech language could not be detected."
        case .invalidCorrection: return "Correction was empty or incomplete."
        case .notReady: return "Complete setup before recording."
        case .capture: return "Microphone capture failed."
        case .focus: return "Could not inspect the selected field."
        case .clipboard: return "Could not write the clipboard."
        case .paste: return "Could not send the paste command."
        }
    }
}

// ---------------------------------------------------------
// Serialize one recording and its inference/delivery request.
// Keep audio and intermediate text local, with no pending-text state.
// ---------------------------------------------------------
@MainActor
final class VoiceTypingFlow {
    private let recording: any RecordingContract
    private let transcription: any TranscriptionContract
    private let textCorrection: any TextCorrectionContract
    private let clipboardPaste: any ClipboardPasteContract
    private let notifyInferenceFailure: () -> Void
    private(set) var lastResult: ShortcutResult?
    private var isRecording = false
    private var isProcessing = false

    init(
        recording: any RecordingContract,
        transcription: any TranscriptionContract,
        textCorrection: any TextCorrectionContract,
        clipboardPaste: any ClipboardPasteContract,
        shortcut: String,
        registerShortcut: @escaping (String, @escaping () async throws -> Void) throws -> Void,
        notifyInferenceFailure: @escaping () -> Void
    ) throws {
        self.recording = recording
        self.transcription = transcription
        self.textCorrection = textCorrection
        self.clipboardPaste = clipboardPaste
        self.notifyInferenceFailure = notifyInferenceFailure
        try registerShortcut(shortcut) { [weak self] () async throws -> Void in
            _ = try await self?.handleShortcut()
        }
    }

    func handleShortcut() async throws -> ShortcutResult {
        guard !isProcessing else { return .busy }
        guard isRecording else {
            try recording.start()
            isRecording = true
            lastResult = .recordingStarted
            return .recordingStarted
        }
        isRecording = false
        isProcessing = true
        defer { isProcessing = false }
        let audio = try recording.stop()
        let result: TranscriptionResult
        do {
            result = try await transcription.transcribe(audio: audio)
        } catch {
            notifyInferenceFailure()
            throw error
        }
        guard !result.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lastResult = .discarded
            return .discarded
        }
        guard let code = result.languageCode else {
            notifyInferenceFailure()
            throw VoiceTypingError.invalidLanguage
        }
        guard let language = Language(rawValue: code) else {
            lastResult = .unsupportedLanguage(code)
            return .unsupportedLanguage(code)
        }

        // ---------------------------------------------------------
        // Only inference errors notify; delivery errors propagate unchanged.
        // ---------------------------------------------------------
        let corrected: String
        do {
            corrected = try await textCorrection.correct(text: result.text, language: language)
            guard !corrected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw VoiceTypingError.invalidCorrection
            }
        } catch {
            notifyInferenceFailure()
            throw error
        }
        let outcome: ShortcutResult = try clipboardPaste.paste(text: corrected) ? .pasted : .discarded
        lastResult = outcome
        return outcome
    }
}
