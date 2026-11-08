import Foundation

// ---------------------------------------------------------
// Define focus inspection and system clipboard delivery.
// ---------------------------------------------------------
@MainActor
protocol ClipboardPasteContract {
    func currentApplicationBundleIdentifier() throws -> String?
    func paste(text: String) throws -> Bool
}

@MainActor
final class ClipboardPaste: ClipboardPasteContract {
    init(
        activeApplication: @escaping () throws -> String?,
        hasEditableSelection: @escaping () throws -> Bool,
        writeClipboard: @escaping (String) throws -> Void,
        sendPasteCommand: @escaping () throws -> Void
    ) throws {
        throw SkeletonError.notImplemented
    }

    func currentApplicationBundleIdentifier() throws -> String? {
        throw SkeletonError.notImplemented
    }

    func paste(text: String) throws -> Bool {
        throw SkeletonError.notImplemented
    }
}
