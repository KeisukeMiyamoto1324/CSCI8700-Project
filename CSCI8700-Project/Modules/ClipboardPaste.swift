import Foundation

@MainActor
protocol ClipboardPasteContract {
    func paste(text: String) throws -> Bool
}

// ---------------------------------------------------------
// Inspect focus immediately before writing the clipboard and pasting.
// ---------------------------------------------------------
@MainActor
final class ClipboardPaste: ClipboardPasteContract {
    private let hasEditableSelection: () throws -> Bool
    private let writeClipboard: (String) throws -> Void
    private let sendPasteCommand: () throws -> Void

    init(
        hasEditableSelection: @escaping () throws -> Bool,
        writeClipboard: @escaping (String) throws -> Void,
        sendPasteCommand: @escaping () throws -> Void
    ) throws {
        self.hasEditableSelection = hasEditableSelection
        self.writeClipboard = writeClipboard
        self.sendPasteCommand = sendPasteCommand
    }

    func paste(text: String) throws -> Bool {
        guard try hasEditableSelection() else { return false }
        try writeClipboard(text)
        try sendPasteCommand()
        return true
    }
}
