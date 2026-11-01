# 1. Overview

Local AI Voice Typing Assistant is a local macOS application with an ordered processing path from recording to transcription, text correction, and insertion. Speech recognition and the LLM run through MLX on Apple Silicon, while a clipboard paste module sends the corrected text to the currently selected input field using the system paste command.

# 2. Modules

These are logical modules within one application, rather than separate services.

| Module | Responsibility | May depend on |
|---|---|---|
| Recording | Capture one audio recording (FR-001). | Microphone APIs |
| Voice Typing Flow | Coordinate recording, processing, and pending-text state (FR-001, FR-006, AC-001, AC-002). | Recording, Transcription, Text Correction, Clipboard Paste |
| Transcription | Convert recorded audio into text (FR-001, FR-005). | MLX and a local speech recognition model |
| Text Correction | Produce corrected text using application context (FR-002, FR-004, FR-005). | MLX and a local LLM |
| Clipboard Paste | Paste supplied text into the current input field when one is selected (FR-003, FR-006). | macOS clipboard, focus inspection, and keyboard event APIs |

# 3. Request flow

1. With local models ready and no corrected text pending, the user presses the configured shortcut. Voice Typing Flow starts Recording.
2. The user speaks and presses the shortcut again. Voice Typing Flow stops Recording and passes the completed audio to Transcription.
3. Transcription returns text through local MLX inference. Voice Typing Flow passes the text to Text Correction, which returns the corrected text through the local LLM.
4. Voice Typing Flow holds the corrected text as pending and asks Clipboard Paste to attempt delivery. Clipboard Paste checks whether an editable text field is selected at this moment.
5. If a text field is selected, Clipboard Paste writes the corrected text to the system clipboard and sends the system paste command to the active application. Voice Typing Flow clears the pending text after the paste attempt completes.
6. If no text field is selected, Clipboard Paste sends no paste command. Voice Typing Flow retains the corrected text locally as pending.
7. While text is pending, the next shortcut press triggers another paste attempt instead of starting Recording. Clipboard Paste checks the current selection again. If a field is selected, step 5 applies; otherwise the text remains pending as in step 6.

# 4. Design decisions

| Decision | Reason |
|---|---|
| Use macOS, Apple Silicon, and MLX for local inference. | Fixed by Description; supports Nonfunctional Requirements, NFR-001. |
| Keep both inference stages within the local application, with no external inference API calls. | Nonfunctional Requirements, NFR-001 constrains the Transcription and Text Correction dependencies. |
| Use one application with direct calls between logical modules. | **Preference:** a simple deployment and call structure for Acceptance Criteria, AC-001; the spec does not require a process layout. |
| Have Voice Typing Flow order transcription, correction, and insertion. | Acceptance Criteria, AC-001 requires this processing order. |
| Use the system clipboard and paste command, selecting the destination at paste time. | Functional Requirements, FR-003 and FR-006 define clipboard delivery and destination timing. No application-specific insertion adapter is needed. |
| Retain one pending result and route the next shortcut press to another paste attempt. | Functional Requirements, FR-006 and Acceptance Criteria, AC-002 define deferred delivery and shortcut behavior. Voice Typing Flow owns this state; Clipboard Paste checks the current selection. |
| Apply wording correction and application-specific formatting in the same Text Correction module. | Functional Requirements, FR-002 and FR-004 both concern producing the final text. They do not require separate processing services. |
| Treat language coverage as a condition on both local models. | Functional Requirements, FR-005 applies to both transcription and correction; Nonfunctional Requirements, NFR-003 also constrains their output quality. Model choices require validation. |

# 5. Constraints and known limits

The fixed platform constraints are macOS, Apple Silicon, and MLX (Description). Nonfunctional Requirements, NFR-001 constrains all handling of audio and text. The spec does not fix an implementation language, model, or model size.

The request flow covers the model-ready starting condition in Acceptance Criteria, AC-001. Setup, model installation, permissions, and model readiness failures need specification before their behavior can be designed.

Clipboard Paste uses the standard system paste action rather than writing directly to a field through an application-specific interface. It still needs a way to detect whether an editable field is selected and permission to send the paste shortcut. Focus detection and paste-command support require validation across applications.

Longer recordings or a wider range of Macs would require renewed latency and memory measurements, and might require different local models or changes to audio processing. Additional applications would require validation of focus detection, standard paste behavior, and writing-style rules. Broader language coverage would require rechecking both models.

# 6. Out of scope

The spec has no Non-goals or Out of scope section, so there are no explicit non-goals to copy. 
