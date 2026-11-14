# 1. Overview

Local AI Voice Typing Assistant is a local macOS application with an ordered processing path from recording to transcription, text correction, and insertion. Speech recognition and the LLM run through MLX on Apple Silicon, while a clipboard paste module sends the corrected text to the currently selected input field using the system paste command.

# 2. Modules

These are logical modules within one application, rather than separate services.

| Module | Responsibility | May depend on |
|---|---|---|
| Recording | Capture one audio recording (FR-001). | Microphone APIs |
| Voice Typing Flow | Coordinate recording, processing, delivery, and cleanup (FR-001, FR-006–FR-008, AC-001). | Recording, Transcription, Text Correction, Clipboard Paste, macOS notification APIs |
| Transcription | Detect speech and convert recorded audio into text (FR-001, FR-005, FR-008). | Local Silero VAD, MLX, and local `mlx-community/whisper-large-v3-turbo-4bit` |
| Text Correction | Produce corrected text using the same rules in every application (FR-002, FR-004, FR-005). | MLX and local `LiquidAI/LFM2.5-2.6B-MLX` |
| Clipboard Paste | Paste supplied text into the current input field when one is selected (FR-003, FR-006). | macOS clipboard, focus inspection, and keyboard event APIs |

# 3. Request flow

1. With local models ready, the user double-taps the Control key. Voice Typing Flow starts Recording.
2. The user speaks and double-taps the Control key again. Voice Typing Flow stops Recording and passes the completed audio to Transcription. Transcription checks speech locally with Silero VAD. If no speech is detected, it returns an empty string without Whisper inference, ending the flow without insertion or further action.
3. Transcription returns text through local MLX inference. Voice Typing Flow passes the text to Text Correction, which returns the corrected text through the local LLM.
4. Clipboard Paste checks whether an editable text field is selected at paste time. If selected, it writes the corrected text to the system clipboard and sends the system paste command. Otherwise, it sends no paste command.
5. Undelivered text is discarded; there is no pending-text state or retry.
6. If either inference stage fails, Voice Typing Flow displays a macOS notification and discards the recording and all intermediate text.

# 4. Design decisions

| Decision | Reason |
|---|---|
| Use macOS, Apple Silicon, and MLX for local inference. | Fixed by Description. |
| Use local [Silero VAD](https://github.com/snakers4/silero-vad) within Transcription to detect speech before Whisper inference. | Fixed by spec Technical Constraints and FR-008; no new module or public interface is needed. |
| Use the 4-bit quantized MLX Whisper Large v3 Turbo model, [`mlx-community/whisper-large-v3-turbo-4bit`](https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit), for transcription. | Fixed by spec Technical Constraints; model files are prepared during initial setup. |
| Use the `4bit/` variant of [`LiquidAI/LFM2.5-2.6B-MLX`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-MLX) locally for text correction. | Fixed by spec Technical Constraints; integration remains pending. |
| Keep both inference stages within the local application, with no external inference API calls. | Description requires local audio and text processing. |
| Use one application with direct calls between logical modules. | **Preference:** a simple deployment and call structure for Acceptance Criteria, AC-001; the spec does not require a process layout. |
| Have Voice Typing Flow order transcription, correction, and insertion. | Acceptance Criteria, AC-001 requires this processing order. |
| Use the system clipboard and paste command, selecting the destination at paste time. | Functional Requirements, FR-003 and FR-006 define clipboard delivery and destination timing. No application-specific insertion adapter is needed. |
| Apply the same minimal-correction rules in every application. | FR-002 and FR-004 require meaning/language preservation and application-independent correction; the destination must not affect wording or format. |
| Treat language coverage as a condition on both local models. | Functional Requirements, FR-005 applies to both transcription and correction. Both selected models require validation. |

# 5. Constraints and known limits

The fixed platform constraints are macOS, Apple Silicon, and MLX (Description).
Technical Constraints fixes the speech model to `mlx-community/whisper-large-v3-turbo-4bit`
(Whisper Large v3 Turbo, 4-bit quantization) and the text-correction model to
`LiquidAI/LFM2.5-2.6B-MLX`, using its `4bit/` variant. Local speech detection uses
Silero VAD. Its runtime integration and detection settings remain undecided.
The spec does not fix an
implementation language. Model selection does not
establish integration or accuracy: ten-language coverage and silence/non-speech
handling still require real-model validation.

The request flow covers the model-ready starting condition in Acceptance Criteria, AC-001. Models and required permissions are prepared during initial setup; runtime readiness and permission failures are outside scope.

Clipboard Paste uses the standard system paste action rather than writing directly to a field through an application-specific interface. It still needs a way to detect whether an editable field is selected and permission to send the paste shortcut. Focus detection and paste-command support require validation across applications.

Longer recordings or a wider range of Macs would require latency and memory measurements and might require changes to audio processing. Replacing either specified model would require a spec change. Additional applications would require validation of focus detection and standard paste behavior. Broader language coverage would require rechecking both models.

# 6. Out of scope

Runtime handling of missing models or permissions, concurrent operations, pending-text retention, and delivery retries are outside scope (Scope; FR-006).

# 7. Native runtime integration

The same five logical modules are retained. Real OS adapters and app composition
live in `Runtime/`; these are implementation helpers, not additional services.
`VoiceTypingAppModel` holds the flow, exposes status/setup UI, and serializes user
operations. `MicrophoneCapture` uses AVAudioEngine and converts captured audio to
mono float32 at 16 kHz. The tap uses locked capture storage, cleared on stop/failure.

`LocalModels`, in the local `VoiceTypingModels` Swift package, owns Silero,
Whisper, and LFM inference on a non-main actor. Dependencies are `mlx-audio-swift`
(Core/VAD) and `mlx-swift-lm`. The small MIT-licensed Whisper compatibility layer
adds explicit language-token detection and forbids tokenizer downloads at runtime.
The Whisper decoder automatically identifies an ISO language code; the flow maps
it to the ten supported languages. Unsupported codes discard without LFM/paste;
missing language on nonblank text is an inference failure.

Transcription, correction, and shortcut handling use async contracts. No UI thread
waits synchronously for model execution. Only one capture/request runs; shortcuts
during inference are ignored. Audio and intermediate text are not retained in UI.
Initial model preparation is an explicit network-enabled setup operation. It also
requests microphone, Accessibility, event-monitoring/posting, and notification
permissions. Runtime model loading uses local paths only.

`ControlShortcut` observes local/global key events. Two Control-only taps within
0.3 seconds trigger the flow; intervening keys/modifiers reset detection.
`SystemDelivery` inspects accessibility focus without reading app identifiers,
rejects secure/noneditable fields, writes NSPasteboard, and posts Command-V.
A selected element's application is represented only by the accessibility object
needed to inspect focus, never by bundle ID or stored application identity.

This personal macOS build disables App Sandbox for cross-application interaction.
The setup UI gives permission instructions and reports progress/failure. No LLM
identity stub is used in the production path. Real OS behavior and multilingual
model quality require separate validation from injected-boundary unit tests.
