# Contracts

These contracts match the Swift skeleton in `CSCI8700-Project/Modules/`.
All module classes and protocols use `@MainActor`.
Slice 1 implements dependency forwarding, shortcut registration, and the successful
recording-to-paste flow. The current implementation reads the application identifier
before correction; this identifier must not affect correction under revised FR-004.
Slice 2 discards transcription that is empty after trimming `.whitespacesAndNewlines`,
without application lookup, correction, delivery, or notification. Nonempty text
is forwarded unchanged. Slice 3 invokes the injected notification once when
transcription or correction throws, then rethrows the original error. Intermediate
audio and text remain local to the call; the next shortcut starts fresh capture.
Lookup and delivery failures do not trigger inference notifications.
Slice 4 verifies that selection is checked during paste. No editable selection means no
clipboard write or paste command.
Slice 5 verifies rejection and focus/clipboard/paste failures: no retained pending
text, no retry or inference notification, and fresh capture on the next shortcut.
Errors propagate unchanged. Paste failure may leave the clipboard already written;
no clipboard rollback is promised.
The tables describe the full intended behavior. Real microphone, MLX, and
macOS operations are not wired into the app yet.

## Methods

The production `Transcription.localInference` dependency shall run
[`mlx-community/whisper-large-v3-turbo-4bit`](https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit)
locally through MLX (Whisper Large v3 Turbo, 4-bit quantization), as required by
spec Technical Constraints. Model files are prepared during initial setup.
This dependency shall first check speech locally with Silero VAD and return an
empty string without Whisper inference when no speech is detected. VAD remains
inside the existing Transcription dependency; signatures are unchanged.
Injected test closures may supply fixed results; they do not validate model use,
accuracy, or silence detection. Existing signatures are unchanged, and the
production model dependency is not connected yet.

The production `TextCorrection.localInference` dependency shall use
[`LiquidAI/LFM2.5-2.6B-MLX`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-MLX)
locally through MLX, using the existing text and language arguments and the
repository's `4bit/` variant. The existing `applicationBundleIdentifier` argument
is retained for signature compatibility but shall not affect the prompt or output.
Use identical minimal-correction rules for all identifiers, including `nil`:
preserve language and meaning, fix spelling/grammar/unnatural wording, preserve
names/numbers/negations/dates, and add no information or explanation. Prompt and inference
integration remain undecided.
Model selection does not change any signature or complete model integration.
Injected test closures do not establish correction quality or language coverage.

| Module / signature | Success result and side effects | Failure | Spec rule |
|---|---|---|---|
| Recording: `start() throws -> Void` | Starts one microphone recording. | Throws on capture failure. | FR-001 |
| Recording: `stop() throws -> AVAudioPCMBuffer` | Stops recording and returns the recorded audio. | Throws on capture failure. | FR-001 |
| Transcription: `transcribe(audio: AVAudioPCMBuffer, language: Language) throws -> String` | Returns a local transcription in the selected language, or an empty string for silent or non-speech audio. | Throws on local inference failure. | FR-001, FR-005, FR-008 |
| TextCorrection: `correct(text: String, language: Language, applicationBundleIdentifier: String?) throws -> String` | Returns locally corrected text using the same minimal-correction rules in every application, preserving language and meaning. The application identifier does not affect correction. | Throws on local inference failure. | FR-002, FR-004, FR-005 |
| ClipboardPaste: `currentApplicationBundleIdentifier() throws -> String?` | Returns the active application's bundle identifier, or `nil` if unavailable. Retained for compatibility; not used to choose correction rules. | Throws on application lookup failure. | Existing interface; no application-dependent correction requirement |
| ClipboardPaste: `paste(text: String) throws -> Bool` | With an editable field selected, writes the clipboard, sends paste, and returns `true`. Otherwise returns `false` without writing the clipboard or sending paste. | Throws on focus, clipboard, or paste-command failure. | FR-003, FR-006 |
| VoiceTypingFlow: `handleShortcut() throws -> ShortcutResult` | Idle: starts recording on a Control double-tap and returns `.recordingStarted`. Recording: stops, transcribes, corrects, and attempts paste. Returns `.pasted` after delivery, or `.discarded` for empty transcription or no editable selection. Undelivered text is discarded without retry. | On inference failure, displays a macOS notification and discards recording and intermediate text before throwing. Other dependency failures throw; undelivered text is discarded without retry. | FR-001–FR-008, AC-001 |

`true` / `.pasted` means the paste command completed; it does not confirm that the destination application inserted the text.
Error types are not specified. Inference failures follow FR-007; silent or non-speech audio follows FR-008.
For VoiceTypingFlow, empty transcription includes whitespace/newline-only output.
After discarding it, the next shortcut starts a fresh recording.

## Initializers and injected dependencies

Each initializer returns a configured instance on success. All are `throws`; setup error types are not specified.
Closure arguments use `@escaping`.
The fixed shortcut is represented by the string `"control-double-tap"`.

| Class | Exact initializer signature | Injected dependencies | Spec rule |
|---|---|---|---|
| Recording | `init(startCapture: @escaping () throws -> Void, stopCapture: @escaping () throws -> AVAudioPCMBuffer) throws` | Microphone start and stop operations. | FR-001 |
| Transcription | `init(localInference: @escaping (AVAudioPCMBuffer, Language) throws -> String) throws` | Local MLX speech inference using `mlx-community/whisper-large-v3-turbo-4bit` in production. | FR-001, FR-005; Technical Constraints |
| TextCorrection | `init(localInference: @escaping (String, Language, String?) throws -> String) throws` | Local MLX `LiquidAI/LFM2.5-2.6B-MLX` inference using `4bit/` and application-independent correction rules in production. | FR-002, FR-004, FR-005; Technical Constraints |
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
