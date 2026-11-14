import AppKit
import ApplicationServices
import AVFoundation
import Combine
import UserNotifications
import VoiceTypingModels

// ---------------------------------------------------------
// Compose real dependencies once models and initial permissions are ready.
// The view never stores recordings, transcripts, or corrected text.
// ---------------------------------------------------------
@MainActor
final class VoiceTypingAppModel: ObservableObject {
    @Published private(set) var status = "Prepare models and permissions to begin."
    @Published private(set) var busy = false
    @Published private(set) var ready = false
    @Published private(set) var recording = false
    private let microphone = MicrophoneCapture()
    private let shortcut = ControlShortcut()
    private let models: LocalModels
    private let root: URL
    private var flow: VoiceTypingFlow?
    private var handler: (() async throws -> Void)?

    init() {
        root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LocalVoiceTyping/Models")
        models = LocalModels(root: root)
    }

    func prepare(download: Bool) async -> Void {
        guard !busy, !recording else { return }
        busy = true
        ready = false
        defer { busy = false }
        do {
            if download {
                guard await AVCaptureDevice.requestAccess(for: .audio) else {
                    status = "Enable Microphone permission in System Settings."
                    return
                }
                let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                let accessibility = AXIsProcessTrustedWithOptions(options)
                let listening = CGRequestListenEventAccess()
                let posting = CGRequestPostEventAccess()
                let notifications = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound])
                guard accessibility, listening, posting, notifications else {
                    status = "Enable Accessibility, Input Monitoring, and Notifications, then prepare again."
                    return
                }
            }
            try await models.prepare(download: download) { [weak self] message in
                await MainActor.run { self?.status = message }
            }
            let capture = microphone
            let models = models
            let recording = try Recording(startCapture: { try capture.start() }, stopCapture: { try capture.stop() })
            let transcription = try Transcription(localInference: { buffer in
                let count = Int(buffer.frameLength)
                let samples = count == 0 ? [] : Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: count))
                let result = try await models.transcribe(samples: samples)
                return TranscriptionResult(text: result.text, languageCode: result.languageCode)
            })
            let correction = try TextCorrection(localInference: { text, language in
                return try await models.correct(text: text, languageCode: language.rawValue)
            })
            let paste = try ClipboardPaste(
                hasEditableSelection: SystemDelivery.hasEditableSelection,
                writeClipboard: SystemDelivery.writeClipboard,
                sendPasteCommand: SystemDelivery.sendPasteCommand
            )
            flow = try VoiceTypingFlow(
                recording: recording, transcription: transcription, textCorrection: correction,
                clipboardPaste: paste, shortcut: "control-double-tap",
                registerShortcut: { [weak self] _, action in
                    self?.handler = action
                    self?.shortcut.install { [weak self] in Task { await self?.toggleRecording() } }
                },
                notifyInferenceFailure: {
                    let content = UNMutableNotificationContent()
                    content.title = "Voice typing failed"
                    content.body = "Local inference failed. The recording and text were discarded."
                    content.sound = .default
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            )
            let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
            ready = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
                && AXIsProcessTrusted() && CGPreflightListenEventAccess()
                && CGPreflightPostEventAccess() && notificationSettings.authorizationStatus == .authorized
            status = ready ? "Ready. Select a text field and double-tap Control."
                : "Models loaded. Prepare permissions before recording."
        } catch {
            shortcut.remove()
            flow = nil
            handler = nil
            status = error.localizedDescription
        }
    }

    func restore() async -> Void {
        guard FileManager.default.fileExists(atPath: root.appendingPathComponent("correction/config.json").path) else { return }
        await prepare(download: false)
    }

    func toggleRecording() async -> Void {
        guard ready, !busy, let handler else { return }
        busy = true
        status = recording ? "Transcribing and correcting locally…" : "Starting recording…"
        defer { busy = false }
        do {
            try await handler()
            recording = flow?.lastResult == .recordingStarted
            switch flow?.lastResult {
            case .recordingStarted: status = "Recording. Double-tap Control to stop."
            case .pasted: status = "Pasted. Ready for another recording."
            case .unsupportedLanguage(let code): status = "Unsupported language: \(code). Text discarded."
            case .discarded: status = "No speech or no editable selection. Text discarded."
            default: status = "Ready."
            }
        } catch {
            recording = false
            status = error.localizedDescription
        }
    }

    func openPermissions() -> Void {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
