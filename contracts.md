# Contracts

## Scope and status

Swift / SwiftUI macOS skeleton, using the existing Xcode app. The five files in `CSCI8700-Project/Modules/` match the five logical modules in `../architecture.md`. Requirements below refer to `../spec.md`. No recording, inference, shortcut registration, clipboard access, or processing is implemented.

Every explicit module initializer and method throws `SkeletonError.notImplemented` immediately, before invoking dependencies or causing side effects. The SwiftUI app entry point and view remain runnable scaffolding; they do not construct the modules. Protocol requirements have no bodies. Enums only define contract values. There are no extra services or modules.

The tables describe the proposed implemented behavior, not behavior available in this skeleton. Swift `throws` is the failure channel; there are no HTTP statuses or response bodies. Runtime error codes and recovery rules are not specified by the source documents. Do not treat them as settled requirements.

## Shared types and execution

All module classes and protocols are `@MainActor`. Methods are synchronous contracts; scheduling and background execution remain undecided. `AVAudioPCMBuffer` carries recorded audio in memory. `String` carries transcribed and corrected text. `Language` has exactly the ten FR-005 cases: `english/en`, `arabic/ar`, `chinese/zh`, `french/fr`, `german/de`, `italian/it`, `japanese/ja`, `korean/ko`, `portuguese/pt`, and `spanish/es`. The language parameter is a proposed calling interface, not an added language-selection UI.

Application context is an optional application bundle identifier. `nil` represents unavailable context; formatting fallback behavior needs specification. `ShortcutResult` has `recordingStarted`, `pasted`, and `pending`. `pasted` means the system paste command completed, not verified insertion into another app. `SkeletonError.notImplemented` is the only implemented failure.

Protocols `RecordingContract`, `TranscriptionContract`, `TextCorrectionContract`, and `ClipboardPasteContract` repeat the respective method signatures below so later tests can inject substitutes. They introduce no additional operations.

## Initializers

The following signatures are exact Swift declarations. In the future, successful initialization returns an instance with the supplied dependencies. Currently each initializer throws `SkeletonError.notImplemented`. Future dependency/setup failures may throw, but their handling is not specified. No clock is injected because neither source defines timed behavior.

```swift
Recording.init(
    startCapture: @escaping () throws -> Void,
    stopCapture: @escaping () throws -> AVAudioPCMBuffer
) throws

Transcription.init(
    localInference: @escaping (AVAudioPCMBuffer, Language) throws -> String
) throws

TextCorrection.init(
    localInference: @escaping (String, Language, String?) throws -> String
) throws

ClipboardPaste.init(
    activeApplication: @escaping () throws -> String?,
    hasEditableSelection: @escaping () throws -> Bool,
    writeClipboard: @escaping (String) throws -> Void,
    sendPasteCommand: @escaping () throws -> Void
) throws

VoiceTypingFlow.init(
    recording: any RecordingContract,
    transcription: any TranscriptionContract,
    textCorrection: any TextCorrectionContract,
    clipboardPaste: any ClipboardPasteContract,
    language: Language,
    shortcut: String,
    registerShortcut: @escaping (String, @escaping () throws -> Void) throws -> Void
) throws
```

| Initializer | Injected dependencies and proposed success | Rules served |
|---|---|---|
| `Recording.init` | Microphone start and stop operations; instance ready to capture one recording. | FR-001 |
| `Transcription.init` | Local MLX speech-model inference; instance ready to transcribe. Model is already installed and ready. No network inference. | FR-001, FR-005; Description |
| `TextCorrection.init` | Local MLX LLM inference receiving text, language, and application identifier; instance ready to correct text. No network inference. | FR-002, FR-004, FR-005; Description |
| `ClipboardPaste.init` | Active-app inspection, editable-selection inspection, clipboard writer, and system paste sender; instance ready to inspect focus and deliver text. | FR-003, FR-006; architecture §2–3 |
| `VoiceTypingFlow.init` | Four module substitutes, language, configured shortcut, and shortcut registrar. Proposed initial state: idle, no pending text; registrar connects the configured shortcut to `handleShortcut()`. | FR-001; architecture §3 |

Shortcut syntax, invalid shortcut handling, permissions, model loading, and registration failure recovery are unresolved. The registrar callback can throw so the interface does not silently discard processing errors; presentation of those errors is unspecified.

## Module methods

Every method currently throws `SkeletonError.notImplemented`. Future failures below describe the proposed failure channel only; detailed error policies require specification.

| Module and exact signature | Proposed success result and side effects | Proposed failure | Rules served | Injection used |
|---|---|---|---|---|
| Recording: `func start() throws -> Void` | Begin one microphone recording. | Throw if capture cannot start; duplicate-start policy unspecified. | FR-001; architecture §3.1 | `startCapture` |
| Recording: `func stop() throws -> AVAudioPCMBuffer` | Stop capture and return the completed audio buffer. | Throw if capture cannot stop; stop-while-idle and empty-audio policy unspecified. | FR-001; architecture §3.2 | `stopCapture` |
| Transcription: `func transcribe(audio: AVAudioPCMBuffer, language: Language) throws -> String` | Return local transcription in the supplied supported language. No external inference calls. | Local inference errors throw; audio limits and validation unspecified. | FR-001, FR-005, AC-001; Description | `localInference` |
| Text Correction: `func correct(text: String, language: Language, applicationBundleIdentifier: String?) throws -> String` | Return locally corrected spelling and wording preserving intended meaning, with formatting/style based on app context. | Local inference errors throw; empty input, unavailable context, and quality thresholds unspecified. | FR-002, FR-004, FR-005, AC-001 | `localInference` |
| Clipboard Paste: `func currentApplicationBundleIdentifier() throws -> String?` | Return the current application's bundle identifier, or `nil` if unavailable. Read-only inspection for correction context. | Inspection errors throw; missing identity returns `nil`. | FR-004; architecture §2 | `activeApplication` |
| Clipboard Paste: `func paste(text: String) throws -> Bool` | Inspect the current selection. If editable, write text to clipboard, send system paste, then return `true`. Otherwise return `false` without writing clipboard or sending paste. | Clipboard, focus, or keyboard errors throw. A partial failure may already have changed the clipboard; rollback is unspecified. | FR-003; architecture §3.4–7; FR-006 timing conflict below | `hasEditableSelection`, `writeClipboard`, `sendPasteCommand` |
| Voice Typing Flow: `func handleShortcut() throws -> ShortcutResult` | Idle: start recording and return `.recordingStarted`. Recording: stop, transcribe, inspect application context, correct, retain result, then attempt paste. Return `.pasted` and clear pending text when paste returns `true`; otherwise return `.pending` and retain it. Pending: retry paste only, without recording or repeating inference. | Dependency failures throw; state recovery after errors and reentrant calls unspecified. | FR-001–FR-005, AC-001; architecture §3; FR-006 timing conflict below | All four module contracts; configured `language`. Shortcut registration uses the initializer's registrar. |

## Coverage and source gaps

FR-001 maps to configured shortcut registration, `handleShortcut()`, recording, and transcription. FR-002 maps to `correct()`. FR-003 maps to `paste()`. FR-004 maps to app inspection and correction context. FR-005 maps to `Language` and both inference methods. AC-001 maps to the ordered calls coordinated by `handleShortcut()`.

FR-006 requires insertion into the field selected **when recording stops**, even if selection changed during recording. Architecture §3 instead checks the field **at paste time**, after inference, and retries against a later selection. Those destinations can differ. This skeleton exposes the architecture's paste-time interface; it does not settle or fully cover FR-006. Stop-time destination capture needs a source-document decision before adding an API.

The architecture references AC-002 and NFR-001/NFR-003, but the supplied spec defines none of them. Pending-text retry is listed here because architecture §3 explicitly requires it; no missing acceptance criterion is invented. The architecture also describes clipboard delivery as specified by FR-003/FR-006, although those requirements do not name a clipboard.

FR-004, FR-005, and FR-006 have no acceptance criteria in the supplied spec. Application-specific style rules, inference quality thresholds, language detection/selection behavior, focus changes during processing, input limits, error precedence, and concurrency behavior are unspecified. No validation or business logic has been added to resolve these gaps.

## Build and launch

From this directory (the inner `CSCI8700-Project/` repository):

```sh
xcodebuild -project CSCI8700-Project.xcodeproj -scheme CSCI8700-Project -configuration Debug -derivedDataPath .build CODE_SIGNING_ALLOWED=NO build
open .build/Build/Products/Debug/CSCI8700-Project.app
```

Or open `CSCI8700-Project.xcodeproj` in Xcode and use Run. The app displays a skeleton notice. Voice typing remains unimplemented. No Python environment, pip packages, local model downloads, or extra frameworks are needed to build this skeleton.
