# 1. Overview

Local AI Voice Typing Assistant is a local macOS application with an ordered processing path from recording to transcription, text correction, and insertion. Speech recognition and the LLM run through MLX on Apple Silicon, while a clipboard paste module sends the corrected text to the currently selected input field using the system paste command.

# 2. Modules

These are logical modules within one application, rather than separate services.

| Module | Responsibility | May depend on |
|---|---|---|
| Recording | Capture one audio recording (FR-001). | Microphone APIs |
| Voice Typing Flow | Coordinate recording, processing, delivery, and cleanup (FR-001, FR-006–FR-008, AC-001). | Recording, Transcription, Text Correction, Clipboard Paste, macOS notification APIs |
| Transcription | Convert recorded audio into text (FR-001, FR-005). | MLX and local `mlx-community/whisper-large-v3-turbo-4bit` |
| Text Correction | Produce corrected text using application context (FR-002, FR-004, FR-005). | MLX and local `LiquidAI/LFM2.5-2.6B-MLX` |
| Clipboard Paste | Paste supplied text into the current input field when one is selected (FR-003, FR-006). | macOS clipboard, focus inspection, and keyboard event APIs |

# 3. Request flow

1. With local models ready, the user double-taps the Control key. Voice Typing Flow starts Recording.
2. The user speaks and double-taps the Control key again. Voice Typing Flow stops Recording and passes the completed audio to Transcription. Silent or non-speech audio ends the flow without insertion or further action.
3. Transcription returns text through local MLX inference. Voice Typing Flow passes the text to Text Correction, which returns the corrected text through the local LLM.
4. Clipboard Paste checks whether an editable text field is selected at paste time. If selected, it writes the corrected text to the system clipboard and sends the system paste command. Otherwise, it sends no paste command.
5. Undelivered text is discarded; there is no pending-text state or retry.
6. If either inference stage fails, Voice Typing Flow displays a macOS notification and discards the recording and all intermediate text.

# 4. Design decisions

| Decision | Reason |
|---|---|
| Use macOS, Apple Silicon, and MLX for local inference. | Fixed by Description. |
| Use the 4-bit quantized MLX Whisper Large v3 Turbo model, [`mlx-community/whisper-large-v3-turbo-4bit`](https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit), for transcription. | Fixed by spec Technical Constraints; model files are prepared during initial setup. |
| Use the `4bit/` variant of [`LiquidAI/LFM2.5-2.6B-MLX`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-MLX) locally for text correction. | Fixed by spec Technical Constraints; integration remains pending. |
| Keep both inference stages within the local application, with no external inference API calls. | Description requires local audio and text processing. |
| Use one application with direct calls between logical modules. | **Preference:** a simple deployment and call structure for Acceptance Criteria, AC-001; the spec does not require a process layout. |
| Have Voice Typing Flow order transcription, correction, and insertion. | Acceptance Criteria, AC-001 requires this processing order. |
| Use the system clipboard and paste command, selecting the destination at paste time. | Functional Requirements, FR-003 and FR-006 define clipboard delivery and destination timing. No application-specific insertion adapter is needed. |
| Apply wording correction and application-specific formatting in the same Text Correction module. | Functional Requirements, FR-002 and FR-004 both concern producing the final text. They do not require separate processing services. |
| Treat language coverage as a condition on both local models. | Functional Requirements, FR-005 applies to both transcription and correction. Both selected models require validation. |

# 5. Constraints and known limits

The fixed platform constraints are macOS, Apple Silicon, and MLX (Description).
Technical Constraints fixes the speech model to `mlx-community/whisper-large-v3-turbo-4bit`
(Whisper Large v3 Turbo, 4-bit quantization) and the text-correction model to
`LiquidAI/LFM2.5-2.6B-MLX`, using its `4bit/` variant. The correction model's
revision remains undecided. The spec does not fix an
implementation language. Model selection does not
establish integration or accuracy: ten-language coverage and silence/non-speech
handling still require real-model validation.

The request flow covers the model-ready starting condition in Acceptance Criteria, AC-001. Models and required permissions are prepared during initial setup; runtime readiness and permission failures are outside scope.

Clipboard Paste uses the standard system paste action rather than writing directly to a field through an application-specific interface. It still needs a way to detect whether an editable field is selected and permission to send the paste shortcut. Focus detection and paste-command support require validation across applications.

Longer recordings or a wider range of Macs would require latency and memory measurements and might require changes to audio processing. Replacing either specified model would require a spec change. Additional applications would require validation of focus detection, standard paste behavior, and writing-style rules. Broader language coverage would require rechecking both models.

# 6. Out of scope

Runtime handling of missing models or permissions, concurrent operations, pending-text retention, and delivery retries are outside scope (Scope; FR-006).
