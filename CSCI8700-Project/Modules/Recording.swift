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
    init(
        startCapture: @escaping () throws -> Void,
        stopCapture: @escaping () throws -> AVAudioPCMBuffer
    ) throws {
        throw SkeletonError.notImplemented
    }

    func start() throws -> Void {
        throw SkeletonError.notImplemented
    }

    func stop() throws -> AVAudioPCMBuffer {
        throw SkeletonError.notImplemented
    }
}
