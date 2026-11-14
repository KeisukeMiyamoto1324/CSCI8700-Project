# Contracts

These contracts match the Swift skeleton in `CSCI8700-Project/Modules/`.
All module classes and protocols use `@MainActor`.
Slice 1 implements dependency forwarding, shortcut registration, and the successful
recording-to-paste flow. Application context is read immediately before correction.
The tables describe the full intended behavior; empty-transcription handling and
inference-failure notification remain for later slices. Real microphone, MLX, and
macOS operations are not wired into the app yet.

## Methods

| Module / signature | Success result and side effects | Failure | Spec rule |
|---|---|---|---|
| Recording: `start() throws -> Void` | Starts one microphone recording. | Throws on capture failure. | FR-001 |
| Recording: `stop() throws -> AVAudioPCMBuffer` | Stops recording and returns the recorded audio. | Throws on capture failure. | FR-001 |
| Transcription: `transcribe(audio: AVAudioPCMBuffer, language: Language) throws -> String` | Returns a local transcription in the selected language, or an empty string for silent or non-speech audio. | Throws on local inference failure. | FR-001, FR-005, FR-008 |
| TextCorrection: `correct(text: String, language: Language, applicationBundleIdentifier: String?) throws -> String` | Returns locally corrected text, preserving meaning and applying the application's format and style. | Throws on local inference failure. | FR-002, FR-004, FR-005 |
| ClipboardPaste: `currentApplicationBundleIdentifier() throws -> String?` | Returns the active application's bundle identifier, or `nil` if unavailable. | Throws on application lookup failure. | FR-004 |
| ClipboardPaste: `paste(text: String) throws -> Bool` | With an editable field selected, writes the clipboard, sends paste, and returns `true`. Otherwise returns `false` without writing the clipboard or sending paste. | Throws on focus, clipboard, or paste-command failure. | FR-003, FR-006 |
| VoiceTypingFlow: `handleShortcut() throws -> ShortcutResult` | Idle: starts recording on a Control double-tap and returns `.recordingStarted`. Recording: stops, transcribes, corrects, and attempts paste. Returns `.pasted` after delivery, or `.discarded` for empty transcription or no editable selection. Undelivered text is discarded without retry. | On inference failure, displays a macOS notification and discards recording and intermediate text before throwing. Other dependency failures throw; undelivered text is discarded without retry. | FR-001–FR-008, AC-001 |

`true` / `.pasted` means the paste command completed; it does not confirm that the destination application inserted the text.
Error types are not specified. Inference failures follow FR-007; silent or non-speech audio follows FR-008.

## Initializers and injected dependencies

Each initializer returns a configured instance on success. All are `throws`; setup error types are not specified.
Closure arguments use `@escaping`.
The fixed shortcut is represented by the string `"control-double-tap"`.

| Class | Exact initializer signature | Injected dependencies | Spec rule |
|---|---|---|---|
| Recording | `init(startCapture: @escaping () throws -> Void, stopCapture: @escaping () throws -> AVAudioPCMBuffer) throws` | Microphone start and stop operations. | FR-001 |
| Transcription | `init(localInference: @escaping (AVAudioPCMBuffer, Language) throws -> String) throws` | Local MLX speech inference. | FR-001, FR-005 |
| TextCorrection | `init(localInference: @escaping (String, Language, String?) throws -> String) throws` | Local MLX text inference with application context. | FR-002, FR-004, FR-005 |
| ClipboardPaste | `init(activeApplication: @escaping () throws -> String?, hasEditableSelection: @escaping () throws -> Bool, writeClipboard: @escaping (String) throws -> Void, sendPasteCommand: @escaping () throws -> Void) throws` | Application lookup, focus inspection, clipboard writing, and paste command. | FR-003, FR-004, FR-006 |
| VoiceTypingFlow | `init(recording: any RecordingContract, transcription: any TranscriptionContract, textCorrection: any TextCorrectionContract, clipboardPaste: any ClipboardPasteContract, language: Language, shortcut: String, registerShortcut: @escaping (String, @escaping () throws -> Void) throws -> Void, notifyInferenceFailure: @escaping () -> Void) throws` | Four module contracts, language, fixed Control double-tap shortcut and registration, and macOS inference-failure notification. | FR-001–FR-008, AC-001 |

## Shared types

| Type | Values |
|---|---|
| `Language: String, CaseIterable` | `english = "en"`, `arabic = "ar"`, `chinese = "zh"`, `french = "fr"`, `german = "de"`, `italian = "it"`, `japanese = "ja"`, `korean = "ko"`, `portuguese = "pt"`, `spanish = "es"` |
| `ShortcutResult: Equatable` | `.recordingStarted`, `.pasted`, `.discarded` |
| `SkeletonError: Error` | `.notImplemented` |

## Start the skeleton

From the repository root:

```sh
open CSCI8700-Project.xcodeproj
```

In Xcode, select the `CSCI8700-Project` scheme and **My Mac**, then press **Command-R**.
The app displays a placeholder window; voice typing is not connected yet.
