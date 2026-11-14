import AVFoundation

// ---------------------------------------------------------
// Define supported languages and local speech inference.
// ---------------------------------------------------------
enum Language: String, CaseIterable {
    case english = "en"
    case arabic = "ar"
    case chinese = "zh"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case portuguese = "pt"
    case spanish = "es"
}

@MainActor
protocol TranscriptionContract {
    func transcribe(audio: AVAudioPCMBuffer, language: Language) throws -> String
}

@MainActor
final class Transcription: TranscriptionContract {
    private let localInference: (AVAudioPCMBuffer, Language) throws -> String

    init(
        localInference: @escaping (AVAudioPCMBuffer, Language) throws -> String
    ) throws {
        self.localInference = localInference
    }

    func transcribe(audio: AVAudioPCMBuffer, language: Language) throws -> String {
        return try localInference(audio, language)
    }
}
