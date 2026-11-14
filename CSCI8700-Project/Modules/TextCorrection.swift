import Foundation

// ---------------------------------------------------------
// Define correction with local inference and app context.
// ---------------------------------------------------------
@MainActor
protocol TextCorrectionContract {
    func correct(
        text: String,
        language: Language,
        applicationBundleIdentifier: String?
    ) throws -> String
}

@MainActor
final class TextCorrection: TextCorrectionContract {
    private let localInference: (String, Language, String?) throws -> String

    init(
        localInference: @escaping (String, Language, String?) throws -> String
    ) throws {
        self.localInference = localInference
    }

    func correct(
        text: String,
        language: Language,
        applicationBundleIdentifier: String?
    ) throws -> String {
        return try localInference(text, language, applicationBundleIdentifier)
    }
}
