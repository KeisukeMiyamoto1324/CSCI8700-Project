import Foundation

// ---------------------------------------------------------
// Define the shared stub error and shortcut outcomes.
// ---------------------------------------------------------
enum SkeletonError: Error {
    case notImplemented
}

enum ShortcutResult: Equatable {
    case recordingStarted
    case pasted
    case discarded
}

// ---------------------------------------------------------
// Define coordination using replaceable module dependencies.
// ---------------------------------------------------------
@MainActor
final class VoiceTypingFlow {
    private let recording: any RecordingContract
    private let transcription: any TranscriptionContract
    private let textCorrection: any TextCorrectionContract
    private let clipboardPaste: any ClipboardPasteContract
    private let language: Language
    private var isRecording = false

    init(
        recording: any RecordingContract,
        transcription: any TranscriptionContract,
        textCorrection: any TextCorrectionContract,
        clipboardPaste: any ClipboardPasteContract,
        language: Language,
        shortcut: String,
        registerShortcut: @escaping (String, @escaping () throws -> Void) throws -> Void,
        notifyInferenceFailure: @escaping () -> Void
    ) throws {
        self.recording = recording
        self.transcription = transcription
        self.textCorrection = textCorrection
        self.clipboardPaste = clipboardPaste
        self.language = language

        // ---------------------------------------------------------
        // Register without retaining the flow through the handler.
        // ---------------------------------------------------------
        try registerShortcut(shortcut) { [weak self] () throws -> Void in
            _ = try self?.handleShortcut()
        }
    }

    func handleShortcut() throws -> ShortcutResult {
        // ---------------------------------------------------------
        // Start capture on the first shortcut and process on the next.
        // ---------------------------------------------------------
        guard isRecording else {
            try recording.start()
            isRecording = true
            return .recordingStarted
        }

        let audio = try recording.stop()
        isRecording = false
        let text = try transcription.transcribe(audio: audio, language: language)

        // ---------------------------------------------------------
        // Discard blank input without changing nonempty transcription.
        // ---------------------------------------------------------
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .discarded
        }

        // ---------------------------------------------------------
        // Read application context immediately before correction.
        // Keep intermediate results local to this request.
        // ---------------------------------------------------------
        let application = try clipboardPaste.currentApplicationBundleIdentifier()
        let correctedText = try textCorrection.correct(
            text: text,
            language: language,
            applicationBundleIdentifier: application
        )
        let pasted = try clipboardPaste.paste(text: correctedText)
        return pasted ? .pasted : .discarded
    }
}
