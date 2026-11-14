import AVFoundation
import XCTest
@testable import CSCI8700_Project

// ---------------------------------------------------------
// Observe the real module flow through replaceable OS/inference boundaries.
// No model, microphone, clipboard, or permission prompt is used here.
// ---------------------------------------------------------
@MainActor
private final class FlowFixture {
    var events: [String] = []
    var transcript = "Please send teh report tomorrow."
    var languageCode: String? = "en"
    var correction = "Please send the report tomorrow."
    var receivedLanguage: Language?
    var receivedText: String?
    var clipboard = "Existing clipboard"
    var delivered: [String] = []
    var selection: String? = "A"
    var destination: String?
    var changeSelection: (() -> Void)?
    var failureStage: String?
    var inference: (() async throws -> TranscriptionResult)?
    var captures = 0
    var handler: (() async throws -> Void)?
    var registered: [String] = []
    let failure = NSError(domain: "FlowTests", code: 1)
    var flow: VoiceTypingFlow!
    weak var audio: AVAudioPCMBuffer?

    init() throws {
        let recording = try Recording(startCapture: {
            self.events.append("start")
            if self.failureStage == "start" { throw self.failure }
            self.captures += 1
        }, stopCapture: {
            self.events.append("stop")
            if self.failureStage == "stop" { throw self.failure }
            let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1))
            let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1))
            buffer.frameLength = 1
            buffer.floatChannelData?[0][0] = 0
            self.audio = buffer
            return buffer
        })
        let transcription = try Transcription(localInference: { audio in
            self.events.append("transcribe")
            XCTAssertTrue(audio === self.audio)
            if self.failureStage == "transcribe" { throw self.failure }
            if let inference = self.inference { return try await inference() }
            return TranscriptionResult(text: self.transcript, languageCode: self.languageCode)
        })
        let correction = try TextCorrection(localInference: { text, language in
            self.events.append("correct")
            self.receivedText = text
            self.receivedLanguage = language
            if self.failureStage == "correct" { throw self.failure }
            self.changeSelection?()
            return self.correction
        })
        let paste = try ClipboardPaste(hasEditableSelection: {
            self.events.append("focus")
            if self.failureStage == "focus" { throw self.failure }
            return self.selection != nil
        }, writeClipboard: { text in
            self.events.append("clipboard")
            if self.failureStage == "clipboard" { throw self.failure }
            self.clipboard = text
        }, sendPasteCommand: {
            self.events.append("paste")
            if self.failureStage == "paste" { throw self.failure }
            self.destination = self.selection
            self.delivered.append(self.clipboard)
        })
        flow = try VoiceTypingFlow(
            recording: recording, transcription: transcription, textCorrection: correction,
            clipboardPaste: paste, shortcut: "control-double-tap",
            registerShortcut: { name, handler in
                self.registered.append(name)
                self.handler = handler
            }, notifyInferenceFailure: { self.events.append("notify") }
        )
    }

    func run() async throws -> ShortcutResult {
        let started = try await flow.handleShortcut()
        XCTAssertEqual(started, .recordingStarted)
        return try await flow.handleShortcut()
    }
}

final class VoiceTypingAcceptanceTests: XCTestCase {
    @MainActor
    func test_AC001() async throws -> Void {
        let f = try FlowFixture()
        XCTAssertEqual(f.registered, ["control-double-tap"])
        XCTAssertNotNil(f.handler)
        try await f.handler?()
        XCTAssertEqual(f.flow.lastResult, .recordingStarted)
        XCTAssertEqual(f.events, ["start"])
        try await f.handler?()
        XCTAssertEqual(f.flow.lastResult, .pasted)
        XCTAssertEqual(f.events, ["start", "stop", "transcribe", "correct", "focus", "clipboard", "paste"])
        XCTAssertEqual(f.receivedText, f.transcript)
        XCTAssertEqual(f.receivedLanguage, .english)
        XCTAssertEqual(f.delivered, [f.correction])
    }

    @MainActor
    func test_FR008_discardsEmptyTranscription() async throws -> Void {
        try await checkBlank("")
    }

    @MainActor
    func test_FR008_discardsWhitespaceOnlyTranscription() async throws -> Void {
        for text in [" ", "\t", "\n", " \t\r\n", "\u{3000}\u{00A0}"] { try await checkBlank(text) }
    }

    @MainActor
    private func checkBlank(_ text: String) async throws -> Void {
        let f = try FlowFixture()
        f.transcript = text
        f.languageCode = nil
        let result = try await f.run()
        XCTAssertEqual(result, .discarded)
        XCTAssertEqual(f.events, ["start", "stop", "transcribe"])
        XCTAssertEqual(f.clipboard, "Existing clipboard")
        XCTAssertTrue(f.delivered.isEmpty)
        XCTAssertNil(f.audio)
    }

    @MainActor
    func test_FR008_startsFreshRecordingAfterDiscard() async throws -> Void {
        let f = try FlowFixture()
        f.transcript = ""
        let discarded = try await f.run()
        XCTAssertEqual(discarded, .discarded)
        f.transcript = "Fresh text"
        f.correction = "Fresh text."
        let pasted = try await f.run()
        XCTAssertEqual(pasted, .pasted)
        XCTAssertEqual(f.captures, 2)
        XCTAssertEqual(f.delivered, ["Fresh text."])
    }

    @MainActor
    func test_FR008_preservesNonemptyTranscription() async throws -> Void {
        let f = try FlowFixture()
        f.transcript = " \tThank you.\n"
        _ = try await f.run()
        XCTAssertEqual(f.receivedText, f.transcript)
    }

    @MainActor
    func test_FR007_notifiesOnTranscriptionFailureAndRecovers() async throws -> Void {
        try await checkFailure("transcribe", events: ["start", "stop", "transcribe", "notify"])
    }

    @MainActor
    func test_FR007_notifiesOnCorrectionFailureAndRecovers() async throws -> Void {
        try await checkFailure("correct", events: ["start", "stop", "transcribe", "correct", "notify"])
    }

    @MainActor
    func test_FR007_doesNotNotifyOnPasteFailure() async throws -> Void {
        try await checkFailure("paste", events: ["start", "stop", "transcribe", "correct", "focus", "clipboard", "paste"])
    }

    @MainActor
    private func checkFailure(_ stage: String, events: [String]) async throws -> Void {
        let f = try FlowFixture()
        f.failureStage = stage
        do {
            _ = try await f.run()
            XCTFail("Expected failure at \(stage)")
        } catch { XCTAssertTrue((error as NSError) === f.failure) }
        XCTAssertEqual(f.events, events)
        XCTAssertNil(f.audio)
        XCTAssertTrue(f.delivered.isEmpty)
        XCTAssertEqual(f.clipboard, stage == "paste" ? f.correction : "Existing clipboard")
        f.failureStage = nil
        f.events = []
        f.transcript = "Fresh transcript"
        f.correction = "Fresh correction"
        let start = try await f.flow.handleShortcut()
        XCTAssertEqual(start, .recordingStarted)
        XCTAssertEqual(f.events, ["start"])
        let pasted = try await f.flow.handleShortcut()
        XCTAssertEqual(pasted, .pasted)
        XCTAssertEqual(f.delivered, ["Fresh correction"])
        XCTAssertEqual(f.captures, 2)
        XCTAssertNil(f.audio)
    }

    @MainActor
    func test_FR006_pastesIntoSelectionChangedBeforePaste() async throws -> Void {
        let f = try FlowFixture()
        let started = try await f.flow.handleShortcut()
        XCTAssertEqual(started, .recordingStarted)
        f.selection = "B"
        f.changeSelection = { f.selection = "C" }
        let result = try await f.flow.handleShortcut()
        XCTAssertEqual(result, .pasted)
        XCTAssertEqual(f.destination, "C")
    }

    @MainActor
    func test_FR006_pastesIntoUnchangedSelection() async throws -> Void {
        let f = try FlowFixture()
        f.selection = "B"
        _ = try await f.run()
        XCTAssertEqual(f.destination, "B")
    }

    @MainActor
    func test_FR006_skipsClipboardAndPasteWithoutEditableSelection() async throws -> Void {
        let f = try FlowFixture()
        f.selection = nil
        let result = try await f.run()
        XCTAssertEqual(result, .discarded)
        XCTAssertEqual(f.events, ["start", "stop", "transcribe", "correct", "focus"])
        XCTAssertEqual(f.clipboard, "Existing clipboard")
        XCTAssertTrue(f.delivered.isEmpty)
    }

    @MainActor
    func test_FR006_discardsRejectedDeliveryWithoutRetry() async throws -> Void {
        let f = try FlowFixture()
        f.selection = nil
        let discarded = try await f.run()
        XCTAssertEqual(discarded, .discarded)
        f.selection = "A"
        f.events = []
        f.correction = "New recording"
        let start = try await f.flow.handleShortcut()
        XCTAssertEqual(start, .recordingStarted)
        XCTAssertEqual(f.events, ["start"])
        XCTAssertTrue(f.delivered.isEmpty)
        _ = try await f.flow.handleShortcut()
        XCTAssertEqual(f.delivered, ["New recording"])
    }

    @MainActor
    func test_FR006_discardsTextAfterFocusFailureWithoutRetry() async throws -> Void {
        try await checkFailure("focus", events: ["start", "stop", "transcribe", "correct", "focus"])
    }

    @MainActor
    func test_FR006_discardsTextAfterClipboardFailureWithoutRetry() async throws -> Void {
        try await checkFailure("clipboard", events: ["start", "stop", "transcribe", "correct", "focus", "clipboard"])
    }

    @MainActor
    func test_FR006_discardsTextAfterPasteFailureWithoutRetry() async throws -> Void {
        try await checkFailure("paste", events: ["start", "stop", "transcribe", "correct", "focus", "clipboard", "paste"])
    }

    @MainActor
    func test_FR005_forwardsAllDetectedLanguages() async throws -> Void {
        let texts: [(Language, String)] = [(.english, "Thank you"), (.arabic, "شكراً"), (.chinese, "谢谢"),
            (.french, "Merci"), (.german, "Danke"), (.italian, "Grazie"), (.japanese, "ありがとうございます"),
            (.korean, "감사합니다"), (.portuguese, "Obrigado"), (.spanish, "Gracias")]
        XCTAssertEqual(Set(texts.map { $0.0 }), Set(Language.allCases))
        for (language, text) in texts {
            let f = try FlowFixture()
            f.transcript = text
            f.languageCode = language.rawValue
            f.correction = text
            let result = try await f.run()
            XCTAssertEqual(result, .pasted)
            XCTAssertEqual(f.receivedLanguage, language)
            XCTAssertEqual(f.receivedText, text)
            XCTAssertEqual(f.delivered, [text])
        }
    }

    @MainActor
    func test_unsupportedLanguageIsDiscarded() async throws -> Void {
        let f = try FlowFixture()
        f.languageCode = "ru"
        let result = try await f.run()
        XCTAssertEqual(result, .unsupportedLanguage("ru"))
        XCTAssertEqual(f.events, ["start", "stop", "transcribe"])
    }

    @MainActor
    func test_missingDetectedLanguageNotifies() async throws -> Void {
        let f = try FlowFixture()
        f.languageCode = nil
        do { _ = try await f.run(); XCTFail("Expected missing language error") }
        catch { XCTAssertEqual(error as? VoiceTypingError, .invalidLanguage) }
        XCTAssertEqual(f.events, ["start", "stop", "transcribe", "notify"])
    }

    @MainActor
    func test_emptyCorrectionNotifiesWithoutDelivery() async throws -> Void {
        let f = try FlowFixture()
        f.correction = " \n"
        do { _ = try await f.run(); XCTFail("Expected correction error") }
        catch { XCTAssertEqual(error as? VoiceTypingError, .invalidCorrection) }
        XCTAssertEqual(f.events, ["start", "stop", "transcribe", "correct", "notify"])
    }

    @MainActor
    func test_shortcutsDuringInferenceAreIgnored() async throws -> Void {
        let f = try FlowFixture()
        var continuation: CheckedContinuation<TranscriptionResult, Never>?
        f.inference = { await withCheckedContinuation { continuation = $0 } }
        _ = try await f.flow.handleShortcut()
        let task = Task { try await f.flow.handleShortcut() }
        while continuation == nil { await Task.yield() }
        let result = try await f.flow.handleShortcut()
        XCTAssertEqual(result, .busy)
        XCTAssertEqual(f.captures, 1)
        continuation?.resume(returning: TranscriptionResult(text: f.transcript, languageCode: "en"))
        let delivered = try await task.value
        XCTAssertEqual(delivered, .pasted)
    }

    func test_controlDoubleTapRequiresTwoCleanTaps() -> Void {
        var matcher = ControlTapMatcher()
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: true, timestamp: 1, keyEvent: false))
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: false, timestamp: 1.01, keyEvent: false))
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: true, timestamp: 1.1, keyEvent: false))
        XCTAssertTrue(matcher.consume(keyCode: 59, controlOnly: false, timestamp: 1.2, keyEvent: false))
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: true, timestamp: 1.25, keyEvent: false))
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: false, timestamp: 1.26, keyEvent: false))
        XCTAssertFalse(matcher.consume(keyCode: 1, controlOnly: false, timestamp: 1.27, keyEvent: true))
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: true, timestamp: 1.28, keyEvent: false))
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: false, timestamp: 1.29, keyEvent: false))
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: true, timestamp: 2, keyEvent: false))
        XCTAssertFalse(matcher.consume(keyCode: 59, controlOnly: false, timestamp: 2.1, keyEvent: false))
    }
}
