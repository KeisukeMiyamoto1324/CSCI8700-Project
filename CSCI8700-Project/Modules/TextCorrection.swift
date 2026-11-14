import Foundation

// ---------------------------------------------------------
// Correction depends on text and language, never on the destination.
// ---------------------------------------------------------
@MainActor
protocol TextCorrectionContract {
    func correct(text: String, language: Language) async throws -> String
}

@MainActor
final class TextCorrection: TextCorrectionContract {
    private let localInference: (String, Language) async throws -> String

    init(localInference: @escaping (String, Language) async throws -> String) throws {
        self.localInference = localInference
    }

    func correct(text: String, language: Language) async throws -> String {
        return try await localInference(text, language)
    }
}
