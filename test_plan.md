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

## Spec gaps

| Gap | Unresolved detail |
|---|---|
| Requirements with no acceptance criterion | FR-004–FR-008. AC-001 does not explicitly test unnatural wording or meaning preservation. |
| Unspecified test values | Application-specific style rules and exact model output are not specified; exact style assertions cannot be derived. |

Missing AC/NFR references are excluded from this review. No requirements are inferred from unsupported languages or absent listing features.
