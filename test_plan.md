# Test plan

Source: `spec.md`, `architecture.md`, and the clarified requirements. No implementation inspected.

“Status” means the desktop flow outcome, not an HTTP code. “Body” means returned text or field content; no response fields or error codes are specified. Expected values are derived manually. Exact model wording is unspecified; check meaning and required corrections.

## Acceptance criteria

| ID | Requirement | Cases (request/call; expected status; expected body fields; expected side effects) | Inside/outside | Control |
|---|---|---|---|---|
| AC-001 | FR-001, FR-002, FR-003; Description | With models and permissions ready and editable field A selected, double-tap Control, say “Please send teh report tomorrow,” then double-tap Control again. **Status:** recording starts, stops, and delivery completes. **Body:** “the” is spelled correctly; the request and tomorrow are preserved. **Side effects:** local transcription precedes local correction; the system clipboard and paste command deliver corrected text to A without manual paste. | No numeric limit is specified. Model readiness and permissions are setup preconditions. | No rejection in AC-001; this is the successful baseline. |

## Extra cases from the gap checklist

These are additional probes, not acceptance criteria.

| ID | Requirement | Cases (request/call; expected status; expected body fields; expected side effects) | Inside/outside | Control |
|---|---|---|---|---|
| extra—boundaries / input types | FR-005 | Repeat AC-001 with English “Thank you,” Arabic “شكراً,” Chinese “谢谢,” French “Merci,” German “Danke,” Italian “Grazie,” Japanese “ありがとうございます,” Korean “감사합니다,” Portuguese “Obrigado,” and Spanish “Gracias.” **Status:** delivered. **Body:** thanks in the original language. **Side effects:** local processing and paste into A. | Inside: all 10 languages. Outside: Russian “Спасибо”; no outcome is specified, so no rejection is assumed. No duration or size limits are defined. | No specified rejection. |
| extra—meaning / context / returned text | FR-002, FR-004 | Record “Please schedule the meeting for Tuesday, not Thursday” in two applications. **Status:** delivered. **Body:** Tuesday remains the requested day; Thursday is not selected. **Side effects:** corrected text enters the selected field with suitable style. Exact application-specific styles remain unspecified. | No application coverage or style limits are defined. | No rejection required. |
| extra—identity / time | FR-006 | Start in A, select B before stopping, then select C before paste. **Status:** delivered. **Body:** corrected sentence in C. **Side effects:** A and B unchanged. | Select B just before stopping and C just after stopping, before paste; C is the destination. No numeric timing threshold is specified. | Keep B selected through paste; B receives the text. |
| extra—state | FR-003, FR-006 | Stop with no editable field selected. **Status:** discarded. **Body:** no inserted text. **Side effects:** no clipboard write or paste command; no recording or text result retained for retry. Selecting A and double-tapping Control starts a new recording rather than delivering old text. Separately, make the paste command fail with a field selected: delivery throws and undelivered text is discarded without retry. | Editable selection present/absent; paste command succeeds/fails. A failed paste may already have written the clipboard. | For each case, change only selection availability or paste-command success; delivery succeeds with the same text. For failure, verify no new field content or retained result is created; do not assume clipboard rollback. |
| extra—errors | FR-007 | Separately make transcription inference fail and correction inference fail during the baseline flow. **Status:** failure is reported by throwing. **Body:** no inserted text; no specified error code. **Side effects:** macOS notification; recording and intermediate text discarded; no clipboard write, paste, retained result, or new field content. | Each run has exactly one failing inference stage. | Adjacent successful run changes only the failing inference dependency to success; the baseline text is delivered. |
| extra—silent / non-speech input | FR-008 | Record silence, then separately non-speech sound, and stop with a Control double-tap. **Status:** recording ends; result discarded. **Body:** no text. **Side effects:** no correction, clipboard write, paste, notification, or retained recording/text. | Speech versus silence/non-speech; no loudness or duration threshold is specified. | Same setup with the AC-001 sentence succeeds. |

Checklist: readiness and permission failures, concurrency, and error precedence involving simultaneous failures are outside scope. No listing operation is required. Timing, state, identity, input types, errors, and returned text are covered above.

## Selected speech model validation

Production speech recognition uses
[`mlx-community/whisper-large-v3-turbo-4bit`](https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit)
(MLX Whisper Large v3 Turbo, 4-bit quantization; spec Technical Constraints).
After model files and permissions are prepared during setup, verify that runtime
loads this model locally and performs transcription without sending audio or
text to external servers. Record validation results.

Run AC-001 and the ten-language and silence/non-speech probes above with actual
recordings and the selected speech model. Verify that supported-language speech
is transcribed in its original language and silence/non-speech yields an empty
transcription with no downstream work. Check meaning rather than exact model
wording. Full-flow validation also requires the selected local correction LLM
described below.

These are planned integration checks, not passing test results. The current
injected-closure tests do not load the model or establish speech-recognition quality.
Speech detection uses local [Silero VAD](https://github.com/snakers4/silero-vad)
inside Transcription. Verify silence/non-speech returns an empty string without
Whisper inference, while speech proceeds to Whisper. The inference library,
Swift integration, VAD runtime, and detection settings remain to be decided;
no thresholds or quality scores are specified here.

## Selected correction model validation

Production text correction uses
[`LiquidAI/LFM2.5-2.6B-MLX`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-MLX)
locally through MLX using its `4bit/` variant (spec Technical Constraints).
Verify the selected precision and record the correction
prompt before real-model validation.
Prepare model files during setup and verify runtime correction sends no audio
or text to external servers.

Run AC-001 and the ten-language, meaning/context, and inference-failure probes
with the actual correction model. Verify spelling/wording correction, preserved
meaning and language, agreed application style, and notification/discard on
correction failure. Exact generated wording is not fixed. Model selection alone
does not establish that all ten required languages or style rules are supported.
These checks are planned, not executed; current fixed-result tests do not load
the LLM. Development-stage slices 7–8 below continue to defer LLM integration.

## Development-stage real-device checks (no LLM)

These checks cover slices 7–8, not final product acceptance. Slice 7 uses app
buttons and shows the transcript. Slice 8 uses the existing VoiceTypingFlow and
TextCorrection module with a development-only inference closure that returns
the input unchanged, then delivers through real ClipboardPaste dependencies.
No LLM is loaded; spelling/wording correction and application-style adjustment
remain incomplete. Keep AC-001 and all existing tests unchanged; passing these
checks does not establish AC-001 or ten-language support.

Prepare model files and required permissions during setup. Use English initially
and the specified `mlx-community/whisper-large-v3-turbo-4bit` model locally.
For delivery checks, use TextEdit fields/documents as destinations and prepare
clipboard/field contents whose changes can be observed. Verify actual destination
content as well as flow results; `.pasted` alone only confirms command completion.

| ID | Slice | Procedure and expected result | Status |
|---|---|---|---|
| DEV-7-01 | 7 | Start/stop real microphone capture using app buttons. Verify the specified local model transcribes the recording and the result appears in the app. Check that runtime sends no audio or text to external servers. | not run |
| DEV-7-02 | 7 | Record two different sentences in succession. Each run displays its own transcription, without reusing earlier audio/text, and the UI remains usable during inference. | not run |
| DEV-8-01 | 8 | With an editable field selected, double-tap Control to start capture, speak, and double-tap again to stop. Verify automatic clipboard/paste delivery. Inspect the development TextCorrection input/output and confirm exact equality; inserted text matches the transcription without LLM changes. | not run |
| DEV-8-02 | 8 | Start in field A, select B before stopping, then C before paste. Verify only C receives the transcription. Repeat keeping B selected; only B receives it. | not run |
| DEV-8-03 | 8 | Finish with no editable field selected. Verify discard, unchanged clipboard, and no paste command. Select a field and invoke the shortcut: fresh capture starts, and no previous text is delivered. | not run |
| DEV-8-04 | 8 | Record silence and non-speech separately. Verify Silero VAD detects no speech, Whisper is not invoked, and an empty transcription is discarded with no TextCorrection, clipboard, paste, or notification call. Repeat with speech as a successful control. | not run |
| DEV-8-05 | 8 | Make transcription inference fail in a controlled run. Verify exactly one actual macOS notification, propagated failure, no clipboard/field change, and discarded audio/intermediate text. Restore inference and verify a fresh recording succeeds without retrying old text. | not run |
| DEV-8-06 | 8 | Exercise focus inspection, clipboard write, and paste-command failures separately through the delivery dependency boundary. Verify original failure propagation, no inference notification, no automatic retry, and fresh capture afterward. A failed paste may already have written the clipboard; do not require rollback or delivery confirmation from the destination. | not run |
| DEV-8-07 | 8 | Run the existing automated suite: all 16 tests must pass, including the original correction-path AC-001 test. Keep development identity correction out of the existing test configuration. | not run |

Record setup, observed outcomes, and whether a failure was injected
or arose from an actual OS operation. These checks are not new XCTest method names.
They are planned and unexecuted; failure-injection mechanics and inference/OS
integration details must be settled before implementation. Final correction,
style, and ten-language checks above remain required for the complete application.

## Spec gaps

| Gap | Unresolved detail |
|---|---|
| Requirements with no acceptance criterion | FR-004–FR-008. AC-001 does not explicitly test unnatural wording or meaning preservation. |
| Unspecified test values | Application-specific style rules and exact model output are not specified; exact style assertions cannot be derived. |

Missing AC/NFR references are excluded from this review. No requirements are inferred from unsupported languages or absent listing features.
