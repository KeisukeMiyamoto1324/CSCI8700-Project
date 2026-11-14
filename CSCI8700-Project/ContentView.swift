import SwiftUI

struct ContentView: View {
    @StateObject private var model = VoiceTypingAppModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Local AI Voice Typing Assistant").font(.title2).bold()
            Text("Speech recognition and correction run on this Mac.")
                .foregroundStyle(.secondary)
            Text(model.status).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("voiceStatus")
            if model.busy { ProgressView().controlSize(.small) }
            HStack {
                Button("Prepare models and permissions") { Task { await model.prepare(download: true) } }
                    .disabled(model.busy || model.recording)
                Button("Permissions…") { model.openPermissions() }
                Button(model.recording ? "Stop recording" : "Start recording") {
                    Task { await model.toggleRecording() }
                }
                .disabled(!model.ready || model.busy)
            }
            Text("For another app: select its text field, then double-tap Control to start and stop.\nControl taps must be within 0.3 seconds. Language is detected automatically.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 640, minHeight: 230)
        .task {
            if NSClassFromString("XCTestCase") == nil { await model.restore() }
        }
    }
}
