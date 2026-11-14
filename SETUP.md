# Run the native app

Open `CSCI8700-Project.xcodeproj`, select `CSCI8700-Project` and **My Mac**, and run.
Swift Package Manager resolves the local VoiceTypingModels package and its Swift
MLX dependencies. This personal build runs without App Sandbox.

The app and test targets use automatic signing with the existing development
team. On another Mac, select your own team in Signing & Capabilities for both
targets. An ad-hoc signature has no Team ID: macOS can reject its automatic
AppIntents registration with `com.apple.linkd.autoShortcut` error 4097.
After changing from an ad-hoc signature, remove the old app entry from the
Accessibility permission list and add the currently built app again if access
still fails. Multiple build folders can contain apps with the same name.

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

MLX may print `Compilation succeeded with` followed by `-Wunused-const-variable`
warnings for its Metal kernel constants. These are runtime shader compilation
warnings from the dependency, not failed model inference. The upstream constants
are in [MLX defines.h](https://github.com/ml-explore/mlx/blob/main/mlx/backend/metal/kernels/defines.h).
They remain unchanged; other compilation errors should still be investigated.
