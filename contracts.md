# Contracts

The Swift app uses five logical modules. Public coordination and OS-facing modules
are `@MainActor`; a `LocalModels` actor owns MLX inference off the main actor.
The app composition (`VoiceTypingAppModel`) injects real implementations of the
same boundaries used by tests. Application identifiers are neither acquired nor passed.

## Methods

| Module / signature | Success and side effects | Failure |
|---|---|---|
| Recording: `start() throws -> Void` | Begins microphone capture. | Capture error propagates. |
| Recording: `stop() throws -> AVAudioPCMBuffer` | Stops capture, clears capture storage, returns mono float32 audio at 16 kHz. | Capture/conversion error propagates; flow returns to idle. |
| Transcription: `transcribe(audio: AVAudioPCMBuffer) async throws -> TranscriptionResult` | Runs local Silero VAD. No speech returns empty text and no language, without Whisper. Otherwise runs specified Whisper with automatic language detection. | VAD or transcription error propagates. |
| TextCorrection: `correct(text: String, language: Language) async throws -> String` | Runs local LFM with the same minimal-correction prompt for every destination, returning corrected text only. | Inference, empty-output, or generation-limit failure propagates. |
| ClipboardPaste: `paste(text: String) throws -> Bool` | At delivery time, checks editable focus, writes the clipboard, and posts Command-V; returns true. No editable focus returns false without writing or posting. | Focus/clipboard/event failure propagates. No rollback or retry. |
| VoiceTypingFlow: `handleShortcut() async throws -> ShortcutResult` | Idle starts capture. Recording stops capture, awaits transcription/correction, and attempts delivery. Empty text discards. Unsupported detected language discards before correction/delivery. Processing ignores new shortcuts. | Inference failures notify once and rethrow the original error. Capture/delivery failures do not trigger inference notifications. Request-local audio/text is discarded; next shortcut starts fresh. |

`.pasted` confirms that the paste events were posted, not that another application
inserted text. Successful destination insertion needs real-device validation.
No pending-text queue or retry exists. Clipboard contents may already have changed
when posting fails. Missing language on nonblank transcription and blank correction
are inference failures. Blank means empty after `.whitespacesAndNewlines` trimming;
nonblank transcription is passed unchanged into correction.

## Initializers and injected dependencies

All module initializers remain `throws`. Inference closures and shortcut handlers
are asynchronous; OS capture and paste closures are synchronous on the main actor.

| Class | Signature |
|---|---|
| Recording | `init(startCapture: @escaping () throws -> Void, stopCapture: @escaping () throws -> AVAudioPCMBuffer) throws` |
| Transcription | `init(localInference: @escaping (AVAudioPCMBuffer) async throws -> TranscriptionResult) throws` |
| TextCorrection | `init(localInference: @escaping (String, Language) async throws -> String) throws` |
| ClipboardPaste | `init(hasEditableSelection: @escaping () throws -> Bool, writeClipboard: @escaping (String) throws -> Void, sendPasteCommand: @escaping () throws -> Void) throws` |
| VoiceTypingFlow | `init(recording: any RecordingContract, transcription: any TranscriptionContract, textCorrection: any TextCorrectionContract, clipboardPaste: any ClipboardPasteContract, shortcut: String, registerShortcut: @escaping (String, @escaping () async throws -> Void) throws -> Void, notifyInferenceFailure: @escaping () -> Void) throws` |

## Shared types

| Type | Values |
|---|---|
| `Language: String, CaseIterable, Sendable` | english/en, arabic/ar, chinese/zh, french/fr, german/de, italian/it, japanese/ja, korean/ko, portuguese/pt, spanish/es |
| `TranscriptionResult: Equatable, Sendable` | `text: String`, `languageCode: String?` (ISO code; nil for no speech) |
| `ShortcutResult: Equatable` | `.recordingStarted`, `.pasted`, `.discarded`, `.busy`, `.unsupportedLanguage(String)` |
| `VoiceTypingError` | invalidLanguage, invalidCorrection, notReady, capture, focus, clipboard, paste |

`lastResult` exposes only the flow outcome for UI status, never recorded audio or
intermediate text. The fixed shortcut string is `control-double-tap`.

## Production inference

Speech: [`mlx-community/whisper-large-v3-turbo-4bit`](https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit).
VAD: local Silero VAD (`mlx-community/silero-vad`) with its supplied configuration.
Correction: [`LiquidAI/LFM2.5-2.6B-MLX`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-MLX), `4bit/`.

Initial setup downloads weights and tokenizer assets to local Application Support.
Runtime loads only those folders. LFM uses temperature 0 and a 4096-token output
limit; reaching the limit is a failure, not a truncated successful result. The
prompt preserves language, meaning, names, numbers, negations, and dates, makes
minimal spelling/grammar/wording changes, and returns no explanation or new facts.
The LFM container separates always-on reasoning from final answer chunks; reasoning
content is never pasted. Input is delimited transcription data, never a conversational
request to answer. Tests with injected inference results establish forwarding/error handling, not
real-model correction quality or ten-language accuracy.
