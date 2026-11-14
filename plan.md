# Implementation plan

Scope: Slices 1–6 use the five existing modules and their contracted initializers/methods. Slice 7 connects real recording and transcription to the app UI. Slice 8 connects the existing VoiceTypingFlow to real shortcuts and clipboard delivery. These are development steps toward the unchanged final architecture and contracts; integration design decisions must be resolved before implementation. This is a desktop app.

During slice 8, inject a development-only TextCorrection inference closure that
returns its input unchanged. Keep TextCorrection in the VoiceTypingFlow path;
do not bypass it or claim that correction is implemented. LLM correction remains incomplete. Success in slices 7–8
does not complete AC-001, which requires actual text correction. The final spec,
architecture, contracts, and existing tests remain unchanged.

Source references: architecture §1–§6; contracts “Methods,” “Initializers and injected dependencies,” and “Shared types.” `spec.md` has no numbered sections, so references below use its headings and FR IDs rather than inventing section numbers.

1. **Name:** Successful voice flow.
   **Goal:** Carry one English recording through transcription, correction, and clipboard delivery using the injected dependencies.
   **Spec sources:** spec “Acceptance Criteria” AC-001 and “Functional Requirements” FR-001–FR-003; architecture §2, §3 steps 1–4, §4; contracts Methods and Initializers.
   **Criteria:** AC-001 (suite coverage; real-device validation remains necessary).
   **Tests that should turn green:** `test_AC001`.
   **Depends on:** None.
   **Done when:** The listed test passes and no previously passing test fails; real-device AC-001 validation is required before claiming product acceptance.
   **Status:** implemented; `test_AC001` passes. Real-device acceptance remains unverified.
   Scope includes all five initializers, `Recording.start/stop`, `Transcription.transcribe`, `TextCorrection.correct`, `ClipboardPaste.paste`, and `VoiceTypingFlow.handleShortcut`. Register the shortcut handler and alternate start/stop. Keep this first slice to the successful request flow.

2. **Name:** Silent input.
   **Goal:** Discard empty or whitespace/newline-only transcription without correction, delivery, notification, or retained data.
   **Spec sources:** spec Functional Requirements FR-008; architecture §3 step 2; contracts Transcription and VoiceTypingFlow Methods.
   **Criteria:** None; FR-008 has no acceptance criterion.
   **Tests that should turn green:** `test_FR008_discardsEmptyTranscription`, `test_FR008_discardsWhitespaceOnlyTranscription`, `test_FR008_startsFreshRecordingAfterDiscard`, `test_FR008_preservesNonemptyTranscription`.
   **Depends on:** 1.
   **Done when:** The listed tests pass and no previously passing test fails. Actual silence/non-speech detection requires real-model validation outside this slice.
   **Status:** implemented; automated results recorded in test_results.md. Real audio detection remains unverified.

3. **Name:** Inference failure cleanup.
   **Goal:** Notify once and discard recording and intermediate text when either inference stage throws, then propagate the failure.
   **Spec sources:** spec Functional Requirements FR-007; architecture §3 step 6; contracts VoiceTypingFlow Methods.
   **Criteria:** None; FR-007 has no acceptance criterion.
   **Tests that should turn green:** `test_FR007_notifiesOnTranscriptionFailureAndRecovers`, `test_FR007_notifiesOnCorrectionFailureAndRecovers`. Boundary controls: `test_FR007_doesNotNotifyOnPasteFailure`.
   **Depends on:** 1, 2.
   **Done when:** The listed tests pass and no previously passing test fails; verify both inference-failure probes and a fresh successful run from test_plan “Extra cases.”
   **Status:** implemented; automated results recorded in test_results.md. Actual macOS notification delivery remains unverified.

4. **Name:** Paste-time selection.
   **Goal:** Deliver to the field selected at paste time and skip clipboard writing and paste when no editable field exists.
   **Spec sources:** spec Functional Requirements FR-003, FR-006; architecture §3 step 4, §5; contracts ClipboardPaste Methods.
   **Criteria:** None; FR-006 has no acceptance criterion.
   **Tests that should turn green:** `test_FR006_pastesIntoSelectionChangedBeforePaste`, `test_FR006_pastesIntoUnchangedSelection`, `test_FR006_skipsClipboardAndPasteWithoutEditableSelection`.
   **Depends on:** 1.
   **Done when:** The listed tests pass and no previously passing test fails; verify changed-focus and absent-selection probes from test_plan “Extra cases.”
   **Status:** implemented by existing selection-at-paste behavior; dedicated tests added. Real macOS focus detection remains unverified.

5. **Name:** Delivery failure cleanup.
   **Goal:** Discard undelivered text without retry after rejected or failed delivery, and allow a new recording.
   **Spec sources:** spec Functional Requirements FR-006; architecture §3 step 5, §6; contracts ClipboardPaste and VoiceTypingFlow Methods.
   **Criteria:** None.
   **Tests that should turn green:** `test_FR006_discardsRejectedDeliveryWithoutRetry`, `test_FR006_discardsTextAfterFocusFailureWithoutRetry`, `test_FR006_discardsTextAfterClipboardFailureWithoutRetry`, `test_FR006_discardsTextAfterPasteFailureWithoutRetry`.
   **Depends on:** 3, 4.
   **Done when:** The listed tests pass and no previously passing test fails; verify the delivery-failure/fresh-recording probes from test_plan “Extra cases,” without assuming clipboard rollback.
   **Status:** implemented by existing request-local state and error propagation; dedicated recovery tests added. Real macOS delivery failures remain unverified.

6. **Name:** Language and uniform text correction.
   **Goal:** Support all ten languages and correct text with the same minimal-change rules in every application, preserving meaning and language.
   **Spec sources:** spec Functional Requirements FR-002, FR-004, FR-005; architecture §2, §4–§5; contracts Transcription/TextCorrection Methods and Shared types.
   **Criteria:** None; FR-004–FR-005 have no acceptance criteria.
   **Tests that should turn green:** None in the current suite.
   **Depends on:** 1, 5.
   **Done when:** The listed tests pass and no previously passing test fails; verify the ten-language, meaning preservation, and application-independence probes from test_plan “Extra cases,” after resolving remaining model integration questions below.
   **Status:** not started.

7. **Name:** Minimal real-device transcription.
   **Goal:** Record speech on the Mac, transcribe it locally with the specified Whisper model, and display the transcription in the app.
   **Spec sources:** spec Description, Functional Requirements FR-001 (recording/transcription portion), Technical Constraints, and Scope; architecture §2–§5; contracts Recording and Transcription Methods and Initializers. Start/stop buttons and in-app result display are the agreed demo scope, not completion of the Control double-tap requirement.
   **Criteria:** None completed; AC-001 remains assigned to slice 1 and still requires full real-device validation.
   **Tests that should turn green:** None in the current suite; planned real-device checks DEV-7-01 and DEV-7-02 are defined in test_plan.md. Integration tests must be defined after the inference integration approach is decided.
   **Depends on:** 1. Can be implemented before slice 6; initial demo uses English and does not establish ten-language support.
   **Done when:** With microphone permission and model files prepared during setup, the user can start/stop actual recording using app buttons, see the recorded speech transcribed through local `mlx-community/whisper-large-v3-turbo-4bit`, and repeat with a fresh recording. Runtime sends no audio or text to external servers. Verify this on the Mac, record the results, and keep all existing tests passing.
   **Status:** not started.
   Includes microphone setup instructions, real capture, local model loading, audio conversion/transfer, and result display. Control double-tap handling and delivery into other apps follow in slice 8; LLM correction remains deferred. The inference library, Swift integration, UI composition, and handling of slow inference must be decided under Design questions before implementation, within the existing architecture and contracts.

8. **Name:** Real transcription delivery.
   **Goal:** Start and stop recording with Control double-taps, transcribe locally, and paste the unchanged transcription into the selected field using real macOS operations.
   **Spec sources:** spec Description, Functional Requirements FR-001, FR-003, FR-006–FR-008, Technical Constraints, and Scope; architecture §2–§5; contracts Methods and Initializers. This development step defers FR-002/FR-004 correction and does not establish FR-005 ten-language coverage.
   **Criteria:** None completed; AC-001 remains assigned to slice 1 and requires actual LLM correction and full real-device validation.
   **Tests that should turn green:** None in the current suite establishes real OS integration; planned real-device checks DEV-8-01–DEV-8-07 are defined in test_plan.md. All existing 16 tests must remain passing.
   **Depends on:** 1–5, 7. Can be implemented before slice 6; initial demo uses English.
   **Done when:** With model files and microphone, focus/paste, shortcut, and notification permissions prepared during setup, real Control double-taps drive VoiceTypingFlow from capture through transcription and clipboard paste. The development-only TextCorrection closure returns input unchanged. The destination is checked at paste time; absent selection, silent input, and failures follow existing discard/no-retry rules. Transcription failure triggers a real macOS notification. DEV-8-01–DEV-8-07 are verified on the Mac, outcomes are recorded, and all retained existing tests pass without regression. No runtime audio or text leaves the Mac.
   **Status:** not started.
   Wire existing injected dependencies for shortcut registration, editable focus inspection, clipboard writing, paste command, and inference-failure notification. Do not add a new processing route around VoiceTypingFlow or alter contracted signatures. The app must identify this development stage as having no LLM correction; retain no pending text for retry. UI behavior during capture/inference, shortcut timing, and OS dependency composition must be resolved before implementation.

## Test issues

- The suite covers AC-001 coordination and Slices 2–5. Slice 6 still needs dedicated coverage.
- Slices 7–8 need real microphone/model/OS validation; injected-closure tests do not demonstrate working speech recognition, in-app results, global shortcuts, or external field insertion. Their DEV checks are planned manual checks, not implemented XCTest methods or passing results.
- The test explicitly uses fixed inference results and simulated capture/paste. It checks coordination, not actual Control double-tap handling, MLX locality, model quality, or field insertion. Its zero-valued audio is a fixture, not a silence test.
- The registered handler is checked for presence but never invoked. No contradiction with the spec was found; these are coverage gaps.
- Exact generated wording is not fixed. Verify minimal correction, preserved meaning/language, consistent correction rules in every application.

## Selected speech model

Speech model selection is resolved by spec Technical Constraints:
[`mlx-community/whisper-large-v3-turbo-4bit`](https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit),
the 4-bit quantized MLX Whisper Large v3 Turbo model. Runtime integration and
real-model validation are not implemented. Validate local loading, ten-language
transcription, and silence/non-speech behavior using test_plan's selected-model
checks.

## Selected correction model

Text-correction model selection is resolved by spec Technical Constraints:
[`LiquidAI/LFM2.5-2.6B-MLX`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-MLX).
Use the repository's `4bit/` variant. Prompt and Swift inference
integration remain undecided. Runtime integration and quality
validation are not implemented. Selection does not change slices 7–8: they still
defer real LLM correction and slice 8 uses a development-only identity closure.

## Selected speech detector

Use local [Silero VAD](https://github.com/snakers4/silero-vad) within the existing
Transcription inference dependency before Whisper. Return an empty string when
no speech is detected, without invoking Whisper. VAD runtime integration and
detection settings remain to be decided and validated in slice 7; no new module
or contracted signature is required.

## Design questions

- Before slice 7: how should Swift call the selected model, which inference library should load it, and what audio format/transfer mechanism should connect Recording to Transcription? Decide where the existing app UI composes these dependencies and how inference avoids blocking UI updates while preserving existing contracts.
- Before slice 8: decide Control double-tap timing and event handling, real editable-focus inspection and paste support, notification wiring, and UI behavior during capture/inference. Define setup permissions and a repeatable way to exercise inference and delivery failures without changing the final contracts.
- Where should real microphone, MLX, global shortcut, focus, clipboard, paste, and notification closures be composed? The app currently only displays a placeholder. Existing contracts expose injection points but no composition function. Any new function/module needs a design decision first.
- Which correction prompt should be used for the selected 4-bit LFM model, and how should Swift invoke it? Both model choices and precisions, and Silero VAD selection, are fixed above; inference integration, correction-quality validation, and VAD runtime/settings remain pending. Model files are prepared during setup.
- What cleanup is expected after capture failures beyond the contracted throw/discard behavior?

## Coverage audit

Unassigned acceptance criteria: none. Unassigned failing tests: none. AC-001 and `test_AC001` are assigned only to slice 1; the four FR-008 tests belong only to slice 2; the retained FR-007 tests belong only to slice 3; obsolete interface tests need alignment with the revised contracts.
The three selection tests listed in slice 4 belong only to slice 4; the four
delivery-discard/recovery tests listed in slice 5 belong only to slice 5.

The revised contracts require implementation/test alignment; earlier slice results describe the interfaces at the time they were tested. Slice 7 plans real Recording/Transcription dependency composition and placeholder UI replacement; slice 8 plans global shortcut, external clipboard delivery, and notification wiring. DEV-7 checks belong only to slice 7; DEV-8 checks belong only to slice 8. Real LLM correction integration remains unfinished; the temporary identity closure does not fulfill TextCorrection's final behavior.

Next action: Slice 7, Minimal real-device transcription — decide the Swift-to-MLX integration approach before implementation; slice 6 remains pending.
