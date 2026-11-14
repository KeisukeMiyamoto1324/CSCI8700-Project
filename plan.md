# Implementation plan

The app retains five logical modules with native OS adapters and one model actor.
Slices 1–5 originally proved internal behavior with injected dependencies; they did
not establish microphone/model/OS integration. Their tests are now aligned with
async contracts and removal of application identification. Slice 6 includes actual
LFM correction, and slices 7–8 connect capture, transcription, and native delivery.
Production never substitutes identity correction for the LLM.

Sources: spec Functional Requirements, Acceptance Criteria, Technical Constraints,
and Scope; architecture §2–§7; contracts Methods, Initializers, and Shared types.
Spec/contract headings are unnumbered. Automated and real-device results are
reported separately in test_results.md; code completion alone is not acceptance.

1. **Name:** Successful voice flow.
   **Goal:** Coordinate capture, transcription, correction, and delivery in order.
   **Spec sources:** FR-001–FR-003; architecture §2–§4; contracts Methods.
   **Criteria:** AC-001 (full acceptance still requires real-device/model evidence).
   **Tests that should turn green:** `test_AC001`.
   **Depends on:** None.
   **Done when:** Listed test passes without regressions; actual corrected voice delivery is verified separately before claiming AC-001.
   **Status:** internal logic implemented; native acceptance validation pending.

2. **Name:** Silent input.
   **Goal:** Discard empty/whitespace-only transcription without correction, delivery, notification, or retained data.
   **Spec sources:** FR-008; architecture §3; contracts Transcription/VoiceTypingFlow.
   **Criteria:** None.
   **Tests that should turn green:** `test_FR008_discardsEmptyTranscription`, `test_FR008_discardsWhitespaceOnlyTranscription`, `test_FR008_startsFreshRecordingAfterDiscard`, `test_FR008_preservesNonemptyTranscription`.
   **Depends on:** 1.
   **Done when:** Listed tests pass and no previously passing test fails; actual Silero detection is validated in slice 7.
   **Status:** internal logic implemented; real non-speech validation pending.

3. **Name:** Inference failure cleanup.
   **Goal:** Notify once, discard intermediate data, rethrow inference errors, and allow fresh capture.
   **Spec sources:** FR-007; architecture §3; contracts VoiceTypingFlow.
   **Criteria:** None.
   **Tests that should turn green:** `test_FR007_notifiesOnTranscriptionFailureAndRecovers`, `test_FR007_notifiesOnCorrectionFailureAndRecovers`, `test_FR007_doesNotNotifyOnPasteFailure`, `test_missingDetectedLanguageNotifies`, `test_emptyCorrectionNotifiesWithoutDelivery`.
   **Depends on:** 1, 2.
   **Done when:** Listed tests pass with no regressions; real notification is verified in slice 8.
   **Status:** internal logic implemented; notification display validation pending.

4. **Name:** Paste-time selection.
   **Goal:** Deliver to the current editable selection and avoid clipboard/paste work when absent.
   **Spec sources:** FR-003, FR-006; architecture §3, §5; contracts ClipboardPaste.
   **Criteria:** None.
   **Tests that should turn green:** `test_FR006_pastesIntoSelectionChangedBeforePaste`, `test_FR006_pastesIntoUnchangedSelection`, `test_FR006_skipsClipboardAndPasteWithoutEditableSelection`.
   **Depends on:** 1.
   **Done when:** Listed tests pass with no regressions; actual focus/paste is verified in slice 8.
   **Status:** internal logic implemented; native focus validation pending.

5. **Name:** Delivery failure cleanup.
   **Goal:** Discard rejected/failed delivery without retry and start a new recording next time.
   **Spec sources:** FR-006; architecture §3, §6; contracts ClipboardPaste/VoiceTypingFlow.
   **Criteria:** None.
   **Tests that should turn green:** `test_FR006_discardsRejectedDeliveryWithoutRetry`, `test_FR006_discardsTextAfterFocusFailureWithoutRetry`, `test_FR006_discardsTextAfterClipboardFailureWithoutRetry`, `test_FR006_discardsTextAfterPasteFailureWithoutRetry`.
   **Depends on:** 3, 4.
   **Done when:** Listed tests pass without regressions; native delivery failures are verified separately, without requiring clipboard rollback.
   **Status:** internal logic implemented; native failure validation pending.

6. **Name:** Automatic language and uniform LLM correction.
   **Goal:** Correct detected-language text with actual local 4-bit LFM using identical minimal-change rules for every application.
   **Spec sources:** FR-002, FR-004, FR-005; Technical Constraints; architecture §2, §4, §7; contracts TranscriptionResult/TextCorrection.
   **Criteria:** None; AC-001 remains assigned to slice 1.
   **Tests that should turn green:** `test_FR005_forwardsAllDetectedLanguages`, `test_unsupportedLanguageIsDiscarded`, `test_correctionPromptUsesMinimalRules`.
   **Depends on:** 1, 5.
   **Done when:** Listed tests pass without regressions and real-model correction preserves language, meaning, names, numbers, negation, and dates for ten-language probes. Unsupported languages discard before LFM/paste. Do not claim language quality from fixed-output tests.
   **Status:** runtime implemented; real LFM typo/meaning and ten-language short-text checks passed. Full language-quality validation remains pending.

7. **Name:** Real capture and speech recognition.
   **Goal:** Record microphone audio and transcribe locally after Silero VAD with automatic language detection.
   **Spec sources:** FR-001, FR-005, FR-008; Technical Constraints; architecture §2–§3, §7; contracts Recording/Transcription.
   **Criteria:** None.
   **Tests that should turn green:** `test_realLocalModels` (opt-in integration test; also exercises LFM smoke checks).
   **Depends on:** 1.
   **Done when:** Selected Whisper/Silero load locally, silence skips Whisper, actual speech detects language and transcribes, repeated recordings use fresh data, and no previous test regresses. Generated-audio verification does not replace actual microphone validation.
   **Status:** capture/runtime implemented; real Whisper English generated-audio and Silero silence checks passed. Microphone and broader spoken-language validation remain pending.

8. **Name:** Native application delivery.
   **Goal:** Connect setup, UI, Control shortcut, inference, focus checking, clipboard paste, and notifications into the running app.
   **Spec sources:** FR-001, FR-003, FR-006–FR-008; Scope; architecture §3, §5, §7; contracts VoiceTypingFlow/ClipboardPaste.
   **Criteria:** None.
   **Tests that should turn green:** `test_controlDoubleTapRequiresTwoCleanTaps`, `test_shortcutsDuringInferenceAreIgnored`; manual checks NATIVE-01–NATIVE-07 in test_plan.md.
   **Depends on:** 1–7.
   **Done when:** Setup downloads weights/tokenizers and prepares permissions; Control-only double-taps within 0.3 seconds run the complete real-model path and paste into the final selected field. UI stays responsive and ignores recording actions during processing. Native checks pass and previous automated tests remain green.
   **Status:** native adapters/UI implemented; Xcode build, launch, and local model loading verified. Permission-dependent hands-on checks remain pending.

## Fixed decisions

- All inference runs in Swift within this app. Model access is serialized on a non-main actor.
- Speech: `mlx-community/whisper-large-v3-turbo-4bit`; detector: local Silero VAD (`mlx-community/silero-vad`), using supplied detection settings.
- Correction: `LiquidAI/LFM2.5-2.6B-MLX`, `4bit/`. Temperature 0; 4096 generated-token cap; empty/capped output fails instead of pasting partial text.
- Detect language automatically. Support en/ar/zh/fr/de/it/ja/ko/pt/es; other languages discard with UI status.
- Preserve meaning/language and make minimal spelling/grammar/wording changes. Add no facts/explanations. Do not acquire application identifiers.
- Initial setup may download required assets. Runtime uses local paths only. No model revision pinning is required.
- App Sandbox is disabled for this personal cross-application macOS build. Permissions are setup preconditions.
- No runtime identity-correction stub, pending text, automatic retries, or clipboard rollback.

## Test issues and coverage audit

Every acceptance criterion and retained automated test is assigned once above.
The obsolete application-lookup test was removed with its deleted interface;
retained tests keep behavior coverage while using the new asynchronous API.
Historical test_results entries describe earlier contracts and test counts.
The existing AC-001 sentence uses a written typo as a fixed inference fixture;
real speech validation must assess actual transcription/correction separately.

No contracted function is left without an implementation slice. Native adapters
are implementation helpers for existing logical modules, documented in architecture
§7. Actual microphone/field insertion, OS notification presentation, real ten-language
quality, and failure-path checks remain separate acceptance evidence.

Next action: Complete the running app’s macOS permission setup, then execute NATIVE-01–NATIVE-07 and record actual observations.
