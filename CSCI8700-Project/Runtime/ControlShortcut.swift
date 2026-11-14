import AppKit

// ---------------------------------------------------------
// Recognize completed Control taps; other keys/modifiers cancel the pair.
// Both local and global event monitors use the same state machine.
// ---------------------------------------------------------
struct ControlTapMatcher {
    private var pressed = false
    private var firstTap: TimeInterval?

    mutating func consume(keyCode: UInt16, controlOnly: Bool, timestamp: TimeInterval, keyEvent: Bool) -> Bool {
        guard !keyEvent, keyCode == 59 || keyCode == 62 else {
            pressed = false
            firstTap = nil
            return false
        }
        if controlOnly { pressed = true; return false }
        guard pressed else { firstTap = nil; return false }
        pressed = false
        guard let firstTap, timestamp - firstTap <= 0.3, timestamp >= firstTap else {
            firstTap = timestamp
            return false
        }
        self.firstTap = nil
        return true
    }
}

@MainActor
final class ControlShortcut {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var matcher = ControlTapMatcher()
    private var action: (() -> Void)?

    func install(action: @escaping () -> Void) -> Void {
        remove()
        self.action = action
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            MainActor.assumeIsolated { self?.receive(event) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            MainActor.assumeIsolated { self?.receive(event) }
            return event
        }
    }

    func remove() -> Void {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        matcher = ControlTapMatcher()
    }

    private func receive(_ event: NSEvent) -> Void {
        let flags = event.modifierFlags.intersection([.control, .shift, .option, .command, .function])
        if matcher.consume(keyCode: event.keyCode, controlOnly: flags == .control,
                           timestamp: event.timestamp, keyEvent: event.type == .keyDown) {
            action?()
        }
    }
}
