import AVFoundation
import XCTest
import VoiceTypingModels

final class LocalModelIntegrationTests: XCTestCase {
    func test_correctionPromptUsesMinimalRules() -> Void {
        let prompt = LocalModels.correctionInstruction(languageCode: "ja")
        XCTAssertTrue(prompt.contains("ja"))
        XCTAssertTrue(prompt.contains("minimal"))
        XCTAssertTrue(prompt.contains("negations"))
        XCTAssertTrue(prompt.contains("do not answer"))
    }

    // ---------------------------------------------------------
    // Opt in explicitly: this test downloads real weights and uses the GPU.
    // The audio fixture is a local recording/synthesized speech WAV.
    // ---------------------------------------------------------
    func test_realLocalModels() async throws -> Void {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["VOICE_TYPING_MODEL_TESTS"] == "1",
                          "Real-model validation is opt-in; ordinary tests use no model downloads.")
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LocalVoiceTyping/Models")
        let models = LocalModels(root: root)
        try await models.prepare(download: ProcessInfo.processInfo.environment["VOICE_TYPING_DOWNLOAD_MODELS"] == "1") {
            print($0)
        }
        let silence = try await models.transcribe(samples: [Float](repeating: 0, count: 16000))
        XCTAssertEqual(silence.text, "")
        XCTAssertNil(silence.languageCode)
        let corrected = try await models.correct(
            text: "Please schedule teh meeting for Tuesday, not Thursday.", languageCode: "en"
        )
        print("Real LFM correction:", corrected)
        XCTAssertTrue(corrected.lowercased().contains("tuesday"))
        XCTAssertTrue(corrected.lowercased().contains("not thursday"))
        XCTAssertFalse(corrected.lowercased().contains("teh"))
        let phrases = ["en": "Thank you", "ar": "شكراً", "zh": "谢谢", "fr": "Merci",
                       "de": "Danke", "it": "Grazie", "ja": "ありがとうございます", "ko": "감사합니다",
                       "pt": "Obrigado", "es": "Gracias"]
        for (language, phrase) in phrases.sorted(by: { $0.key < $1.key }) {
            let output = try await models.correct(text: phrase, languageCode: language)
            print("Real LFM language check:", language, output)
            let expected = phrase.lowercased().unicodeScalars.filter { CharacterSet.letters.contains($0) }
            let actual = output.lowercased().unicodeScalars.filter { CharacterSet.letters.contains($0) }
            XCTAssertTrue(String(String.UnicodeScalarView(actual)).contains(String(String.UnicodeScalarView(expected))))
        }
        guard let path = ProcessInfo.processInfo.environment["VOICE_TYPING_TEST_AUDIO"] else {
            XCTFail("Supply VOICE_TYPING_TEST_AUDIO with a mono float32 16 kHz WAV path.")
            return
        }
        let file = try AVAudioFile(forReading: URL(fileURLWithPath: path))
        XCTAssertEqual(file.processingFormat.sampleRate, 16000)
        XCTAssertEqual(file.processingFormat.channelCount, 1)
        let audio = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)))
        try file.read(into: audio)
        let samples = Array(UnsafeBufferPointer(start: audio.floatChannelData![0], count: Int(audio.frameLength)))
        let output = try await models.transcribe(samples: samples)
        print("Real Whisper transcription:", output.text, output.languageCode ?? "nil")
        XCTAssertEqual(output.languageCode, "en")
        XCTAssertTrue(output.text.lowercased().contains("report"))
    }
}
