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
    init(
        localInference: @escaping (String, Language, String?) throws -> String
    ) throws {
        throw SkeletonError.notImplemented
    }

    func correct(
        text: String,
        language: Language,
        applicationBundleIdentifier: String?
    ) throws -> String {
        throw SkeletonError.notImplemented
    }
}
