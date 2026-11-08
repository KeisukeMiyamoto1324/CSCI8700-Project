import AVFoundation
import XCTest
@testable import CSCI8700_Project

final class VoiceTypingAcceptanceTests: XCTestCase {
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
        let shortcut = "command+shift+space"
        var events: [String] = []
        var clipboard: String?
        var pastedText: String?
        var registeredShortcuts: [String] = []
        var registeredHandler: (() throws -> Void)?
        var applicationLookups = 0
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
                }
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
        } catch {
            XCTFail("AC-001 requires a successful flow; \(stage) threw \(error)")
        }
    }
}
