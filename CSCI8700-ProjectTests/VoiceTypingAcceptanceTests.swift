import AVFoundation
import XCTest
@testable import CSCI8700_Project

final class VoiceTypingAcceptanceTests: XCTestCase {
    @MainActor
    func test_FR008_discardsEmptyTranscription() throws -> Void {
        try checkTranscriptions(
            [""], results: [.discarded],
            events: ["start", "stop", "transcribe"], delivered: []
        )
    }

    @MainActor
    func test_FR008_discardsWhitespaceOnlyTranscription() throws -> Void {
        for text in [" ", "\t", "\n", " \t\r\n", "\u{3000}\u{00A0}"] {
            try checkTranscriptions(
                [text], results: [.discarded],
                events: ["start", "stop", "transcribe"], delivered: []
            )
        }
    }

    @MainActor
    func test_FR008_startsFreshRecordingAfterDiscard() throws -> Void {
        try checkTranscriptions(
            ["", "Thank you."], results: [.discarded, .pasted],
            events: [
                "start", "stop", "transcribe",
                "start", "stop", "transcribe", "application", "correct", "focus", "clipboard", "paste"
            ],
            delivered: ["Thank you."]
        )
    }

    @MainActor
    func test_FR008_preservesNonemptyTranscription() throws -> Void {
        try checkTranscriptions(
            [" \tThank you.\n"], results: [.pasted],
            events: ["start", "stop", "transcribe", "application", "correct", "focus", "clipboard", "paste"],
            delivered: [" \tThank you.\n"]
        )
    }

    // ---------------------------------------------------------
    // Observe the complete flow with injected inference and delivery.
    // Each recording receives a distinct buffer to check fresh capture.
    // ---------------------------------------------------------
    @MainActor
    private func checkTranscriptions(
        _ transcripts: [String],
        results: [ShortcutResult],
        events expectedEvents: [String],
        delivered expectedDelivered: [String]
    ) throws -> Void {
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let buffers = try transcripts.map { _ in
            try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1))
        }
        var index = 0
        var events: [String] = []
        var correctedInputs: [String] = []
        var clipboard = "Existing clipboard"
        var delivered: [String] = []
        let recording = try Recording(
            startCapture: { events.append("start") },
            stopCapture: {
                events.append("stop")
                return buffers[index]
            }
        )
        let transcription = try Transcription(localInference: { audio, _ in
            events.append("transcribe")
            XCTAssertTrue(audio === buffers[index])
            let text = transcripts[index]
            index += 1
            return text
        })
        let correction = try TextCorrection(localInference: { text, _, _ in
            events.append("correct")
            correctedInputs.append(text)
            return text
        })
        let paste = try ClipboardPaste(
            activeApplication: {
                events.append("application")
                return "com.apple.TextEdit"
            },
            hasEditableSelection: {
                events.append("focus")
                return true
            },
            writeClipboard: { text in
                events.append("clipboard")
                clipboard = text
            },
            sendPasteCommand: {
                events.append("paste")
                delivered.append(clipboard)
            }
        )
        let flow = try VoiceTypingFlow(
            recording: recording, transcription: transcription, textCorrection: correction,
            clipboardPaste: paste, language: .english, shortcut: "control-double-tap",
            registerShortcut: { _, _ in },
            notifyInferenceFailure: { events.append("notify") }
        )

        // ---------------------------------------------------------
        // Verify all observable work, including no downstream effects.
        // ---------------------------------------------------------
        for result in results {
            XCTAssertEqual(try flow.handleShortcut(), .recordingStarted)
            XCTAssertEqual(try flow.handleShortcut(), result)
        }
        XCTAssertEqual(events, expectedEvents)
        XCTAssertEqual(index, transcripts.count)
        XCTAssertEqual(correctedInputs, expectedDelivered)
        XCTAssertEqual(delivered, expectedDelivered)
        XCTAssertEqual(clipboard, expectedDelivered.last ?? "Existing clipboard")
    }

    @MainActor
    func test_AC001() throws -> Void {
        // ---------------------------------------------------------
        // Use fixed local inference results and an editable field.
        // This tests coordination, not model quality or macOS delivery.
        // ---------------------------------------------------------
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1))
        let audio = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1))
        audio.frameLength = 1
        audio.floatChannelData?[0][0] = 0
        let transcript = "Please send teh report tomorrow."
        let correctedText = "Please send the report tomorrow."
        let application = "com.apple.TextEdit"
        let shortcut = "control-double-tap"
        var events: [String] = []
        var clipboard: String?
        var pastedText: String?
        var registeredShortcuts: [String] = []
        var registeredHandler: (() throws -> Void)?
        var applicationLookups = 0
        var failureNotifications = 0
        var stage = "Recording initialization"

        do {
            let recording = try Recording(
                startCapture: { events.append("start") },
                stopCapture: {
                    events.append("stop")
                    return audio
                }
            )
            stage = "Transcription initialization"
            let transcription = try Transcription(localInference: { receivedAudio, language in
                events.append("transcribe")
                XCTAssertTrue(receivedAudio === audio)
                XCTAssertEqual(language, .english)
                return transcript
            })
            stage = "TextCorrection initialization"
            let correction = try TextCorrection(localInference: { text, language, bundleIdentifier in
                events.append("correct")
                XCTAssertEqual(text, transcript)
                XCTAssertEqual(language, .english)
                XCTAssertEqual(bundleIdentifier, application)
                return correctedText
            })
            stage = "ClipboardPaste initialization"
            let paste = try ClipboardPaste(
                activeApplication: {
                    applicationLookups += 1
                    return application
                },
                hasEditableSelection: {
                    events.append("focus")
                    return true
                },
                writeClipboard: { text in
                    events.append("clipboard")
                    clipboard = text
                },
                sendPasteCommand: {
                    events.append("paste")
                    XCTAssertEqual(clipboard, correctedText)
                    pastedText = clipboard
                }
            )
            stage = "VoiceTypingFlow initialization"
            let flow = try VoiceTypingFlow(
                recording: recording,
                transcription: transcription,
                textCorrection: correction,
                clipboardPaste: paste,
                language: .english,
                shortcut: shortcut,
                registerShortcut: { value, handler in
                    registeredShortcuts.append(value)
                    registeredHandler = handler
                },
                notifyInferenceFailure: { failureNotifications += 1 }
            )

            // ---------------------------------------------------------
            // The first shortcut starts capture without producing text.
            // ---------------------------------------------------------
            XCTAssertEqual(registeredShortcuts, [shortcut])
            XCTAssertNotNil(registeredHandler)
            stage = "first handleShortcut()"
            XCTAssertEqual(try flow.handleShortcut(), .recordingStarted)
            XCTAssertEqual(events, ["start"])
            XCTAssertNil(clipboard)
            XCTAssertNil(pastedText)
            XCTAssertEqual(failureNotifications, 0)

            // ---------------------------------------------------------
            // The second shortcut processes audio and delivers correction.
            // AC-001 defines no rejection or error code to assert.
            // ---------------------------------------------------------
            stage = "second handleShortcut()"
            XCTAssertEqual(try flow.handleShortcut(), .pasted)
            XCTAssertEqual(events, ["start", "stop", "transcribe", "correct", "focus", "clipboard", "paste"])
            XCTAssertGreaterThanOrEqual(applicationLookups, 1)
            XCTAssertEqual(clipboard, correctedText)
            XCTAssertEqual(pastedText, correctedText)
            XCTAssertEqual(failureNotifications, 0)
        } catch {
            XCTFail("AC-001 requires a successful flow; \(stage) threw \(error)")
        }
    }
}
