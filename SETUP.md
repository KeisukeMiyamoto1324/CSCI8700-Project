# Run the native app

Open `CSCI8700-Project.xcodeproj`, select `CSCI8700-Project` and **My Mac**, and run.
Swift Package Manager resolves the local VoiceTypingModels package and its Swift
MLX dependencies. This personal build runs without App Sandbox.

Choose **Prepare models and permissions**. Allow microphone, Accessibility,
Input Monitoring/event posting, and notifications for the app in System Settings.
If a permission was changed, prepare again (restart the app if macOS requests it).
Preparation downloads the selected Whisper, Silero VAD, LFM 4bit, and tokenizer
assets. Downloads are stored in `~/Library/Application Support/LocalVoiceTyping/Models`.
Keep these folders for offline launches; models are loaded from them on restart.
No recording or transcript is saved there.

Once Ready, select a text field in TextEdit. Double-tap Control, speak, and
double-tap Control again. Taps must be within 0.3 seconds without another key.
The app detects language, corrects locally, then pastes into the field selected
at delivery time. The app window also has start/stop controls for testing;
using the global shortcut avoids moving focus away from the destination.

Recording and inference do not send audio/text to servers. Unsupported languages,
no speech, or no editable field discard the request; there is no retry buffer.
The clipboard remains changed after a successful paste or a post-write failure.

Run automated checks from the repository root:

```sh
xcodebuild test -project CSCI8700-Project.xcodeproj \
  -scheme CSCI8700-Project -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/csci8700-runtime-build
```

Unit tests use injected OS/inference boundaries and need no microphone or model
downloads. Real microphone/paste/notifications and ten-language quality require
separate hands-on verification; see `test_results.md` for observed results.
