import AVFoundation

// ---------------------------------------------------------
// Define the recording interface and microphone dependencies.
// ---------------------------------------------------------
@MainActor
protocol RecordingContract {
    func start() throws -> Void
    func stop() throws -> AVAudioPCMBuffer
}

@MainActor
final class Recording: RecordingContract {
    private let startCapture: () throws -> Void
    private let stopCapture: () throws -> AVAudioPCMBuffer

    init(
        startCapture: @escaping () throws -> Void,
        stopCapture: @escaping () throws -> AVAudioPCMBuffer
    ) throws {
        self.startCapture = startCapture
        self.stopCapture = stopCapture
    }

    func start() throws -> Void {
        try startCapture()
    }

    func stop() throws -> AVAudioPCMBuffer {
        return try stopCapture()
    }
}
