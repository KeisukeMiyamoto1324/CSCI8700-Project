import AppKit
import ApplicationServices

// ---------------------------------------------------------
// Use only accessibility focus, never application identifiers.
// Standard paste goes to the selection that exists at delivery time.
// ---------------------------------------------------------
@MainActor
enum SystemDelivery {
    static func hasEditableSelection() throws -> Bool {
        let system = AXUIElementCreateSystemWide()
        var application: CFTypeRef?
        let appStatus = AXUIElementCopyAttributeValue(system, kAXFocusedApplicationAttribute as CFString, &application)
        if appStatus == .noValue { return false }
        guard appStatus == .success, let application else { throw VoiceTypingError.focus }
        var selection: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(application as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &selection)
        if status == .noValue { return false }
        guard status == .success, let selection else { throw VoiceTypingError.focus }
        let field = selection as! AXUIElement
        var role: CFTypeRef?
        guard AXUIElementCopyAttributeValue(field, kAXRoleAttribute as CFString, &role) == .success else { return false }
        var subrole: CFTypeRef?
        AXUIElementCopyAttributeValue(field, kAXSubroleAttribute as CFString, &subrole)
        if subrole as? String == kAXSecureTextFieldSubrole { return false }
        guard [kAXTextFieldRole, kAXTextAreaRole, kAXComboBoxRole].contains(role as? String ?? "") else { return false }
        var settable = DarwinBoolean(false)
        let editable = AXUIElementIsAttributeSettable(field, kAXValueAttribute as CFString, &settable)
        guard editable == .success else { return false }
        return settable.boolValue
    }

    static func writeClipboard(_ text: String) throws -> Void {
        NSPasteboard.general.clearContents()
        guard NSPasteboard.general.setString(text, forType: .string) else { throw VoiceTypingError.clipboard }
    }

    static func sendPasteCommand() throws -> Void {
        guard CGPreflightPostEventAccess(),
              let source = CGEventSource(stateID: .combinedSessionState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        else { throw VoiceTypingError.paste }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
