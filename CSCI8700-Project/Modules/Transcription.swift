import AVFoundation

enum Language: String, CaseIterable, Sendable {
    case english = "en", arabic = "ar", chinese = "zh", french = "fr", german = "de"
    case italian = "it", japanese = "ja", korean = "ko", portuguese = "pt", spanish = "es"
}

struct TranscriptionResult: Equatable, Sendable {
    let text: String
    let languageCode: String?
}

// ---------------------------------------------------------
// Keep language detection with transcription, not in the UI.
// ---------------------------------------------------------
@MainActor
protocol TranscriptionContract {
    func transcribe(audio: AVAudioPCMBuffer) async throws -> TranscriptionResult
}

@MainActor
final class Transcription: TranscriptionContract {
    private let localInference: (AVAudioPCMBuffer) async throws -> TranscriptionResult

    init(localInference: @escaping (AVAudioPCMBuffer) async throws -> TranscriptionResult) throws {
        self.localInference = localInference
    }

    func transcribe(audio: AVAudioPCMBuffer) async throws -> TranscriptionResult {
        return try await localInference(audio)
    }
}
