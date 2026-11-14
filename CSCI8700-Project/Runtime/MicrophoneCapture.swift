import AVFoundation
import Foundation

// ---------------------------------------------------------
// Copy microphone samples under a lock; the audio tap never touches UI.
// The completed recording is converted to mono float32 at 16 kHz.
// ---------------------------------------------------------
final class MicrophoneCapture: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var samples: [Float] = []
    private var rate: Double = 16000
    private var active = false

    @MainActor
    func start() throws -> Void {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw VoiceTypingError.capture }
        lock.withLock { samples.removeAll(); rate = format.sampleRate }
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self, let channels = buffer.floatChannelData else { return }
            let count = Int(buffer.frameLength)
            let channelCount = Int(buffer.format.channelCount)
            var mono = [Float](repeating: 0, count: count)
            for channel in 0..<channelCount {
                for frame in 0..<count { mono[frame] += channels[channel][frame] / Float(channelCount) }
            }
            self.lock.withLock { self.samples.append(contentsOf: mono) }
        }
        do {
            engine.prepare()
            try engine.start()
            active = true
        } catch {
            input.removeTap(onBus: 0)
            lock.withLock { samples.removeAll() }
            throw error
        }
    }

    @MainActor
    func stop() throws -> AVAudioPCMBuffer {
        guard active else { throw VoiceTypingError.capture }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        active = false
        let (captured, sampleRate) = lock.withLock { () -> ([Float], Double) in
            let result = (samples, rate)
            samples = []
            return result
        }
        guard let sourceFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1),
              let source = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: AVAudioFrameCount(max(1, captured.count))),
              let converter = AVAudioConverter(from: sourceFormat, to: targetFormat),
              let output = AVAudioPCMBuffer(pcmFormat: targetFormat,
                  frameCapacity: AVAudioFrameCount(max(1, ceil(Double(captured.count) * 16000 / sampleRate) + 256)))
        else { throw VoiceTypingError.capture }
        guard !captured.isEmpty else { return output }
        source.frameLength = AVAudioFrameCount(captured.count)
        if !captured.isEmpty {
            captured.withUnsafeBufferPointer { data in
                source.floatChannelData![0].update(from: data.baseAddress!, count: data.count)
            }
        }
        var supplied = false
        var error: NSError?
        let status = converter.convert(to: output, error: &error) { _, state in
            if supplied { state.pointee = .endOfStream; return nil }
            supplied = true
            state.pointee = .haveData
            return source
        }
        if let error { throw error }
        guard status != .error else { throw VoiceTypingError.capture }
        return output
    }
}
