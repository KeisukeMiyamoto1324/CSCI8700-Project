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
    private let activeApplication: () throws -> String?
    private let hasEditableSelection: () throws -> Bool
    private let writeClipboard: (String) throws -> Void
    private let sendPasteCommand: () throws -> Void

    init(
        activeApplication: @escaping () throws -> String?,
        hasEditableSelection: @escaping () throws -> Bool,
        writeClipboard: @escaping (String) throws -> Void,
        sendPasteCommand: @escaping () throws -> Void
    ) throws {
        self.activeApplication = activeApplication
        self.hasEditableSelection = hasEditableSelection
        self.writeClipboard = writeClipboard
        self.sendPasteCommand = sendPasteCommand
    }

    func currentApplicationBundleIdentifier() throws -> String? {
        return try activeApplication()
    }

    func paste(text: String) throws -> Bool {
        // ---------------------------------------------------------
        // Check selection before writing and sending the paste command.
        // ---------------------------------------------------------
        guard try hasEditableSelection() else { return false }
        try writeClipboard(text)
        try sendPasteCommand()
        return true
    }
}
