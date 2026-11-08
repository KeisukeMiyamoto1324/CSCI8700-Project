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
        throw SkeletonError.notImplemented
    }

    func handleShortcut() throws -> ShortcutResult {
        throw SkeletonError.notImplemented
    }
}
