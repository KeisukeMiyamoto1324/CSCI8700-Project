# Implementation plan

Scope: the five existing modules and their contracted initializers/methods only. This is a desktop app. No implementation or test changes are proposed here.

Source references: architecture §1–§6; contracts “Methods,” “Initializers and injected dependencies,” and “Shared types.” `spec.md` has no numbered sections, so references below use its headings and FR IDs rather than inventing section numbers.

1. **Name:** Successful voice flow.
   **Goal:** Carry one English recording through transcription, correction, application lookup, and clipboard delivery using the injected dependencies.
   **Spec sources:** spec “Acceptance Criteria” AC-001 and “Functional Requirements” FR-001–FR-003; architecture §2, §3 steps 1–4, §4; contracts Methods and Initializers.
   **Criteria:** AC-001 (suite coverage; real-device validation remains necessary).
   **Tests that should turn green:** `test_AC001`.
   **Depends on:** None.
   **Done when:** The listed test passes and no previously passing test fails; real-device AC-001 validation is required before claiming product acceptance.
   **Status:** not started.
   Scope includes all five initializers, `Recording.start/stop`, `Transcription.transcribe`, `TextCorrection.correct`, `ClipboardPaste.currentApplicationBundleIdentifier/paste`, and `VoiceTypingFlow.handleShortcut`. Register the shortcut handler and alternate start/stop. Keep this first slice to the successful request flow.

2. **Name:** Silent input.
   **Goal:** Discard empty transcription without correction, delivery, notification, or retained data.
   **Spec sources:** spec Functional Requirements FR-008; architecture §3 step 2; contracts Transcription and VoiceTypingFlow Methods.
   **Criteria:** None; FR-008 has no acceptance criterion.
   **Tests that should turn green:** None in the current suite.
   **Depends on:** 1.
   **Done when:** The listed tests pass and no previously passing test fails; verify the silence/non-speech probe in test_plan “Extra cases” because automated coverage is absent.
   **Status:** not started.

3. **Name:** Inference failure cleanup.
   **Goal:** Notify once and discard recording and intermediate text when either inference stage throws, then propagate the failure.
   **Spec sources:** spec Functional Requirements FR-007; architecture §3 step 6; contracts VoiceTypingFlow Methods.
   **Criteria:** None; FR-007 has no acceptance criterion.
   **Tests that should turn green:** None in the current suite.
   **Depends on:** 1, 2.
   **Done when:** The listed tests pass and no previously passing test fails; verify both inference-failure probes and a fresh successful run from test_plan “Extra cases.”
   **Status:** not started.

4. **Name:** Paste-time selection.
   **Goal:** Deliver to the field selected at paste time and skip clipboard writing and paste when no editable field exists.
   **Spec sources:** spec Functional Requirements FR-003, FR-006; architecture §3 step 4, §5; contracts ClipboardPaste Methods.
   **Criteria:** None; FR-006 has no acceptance criterion.
   **Tests that should turn green:** None in the current suite.
   **Depends on:** 1.
   **Done when:** The listed tests pass and no previously passing test fails; verify changed-focus and absent-selection probes from test_plan “Extra cases.”
   **Status:** not started.

5. **Name:** Delivery failure cleanup.
   **Goal:** Discard undelivered text without retry after rejected or failed delivery, and allow a new recording.
   **Spec sources:** spec Functional Requirements FR-006; architecture §3 step 5, §6; contracts ClipboardPaste and VoiceTypingFlow Methods.
   **Criteria:** None.
   **Tests that should turn green:** None in the current suite.
   **Depends on:** 3, 4.
   **Done when:** The listed tests pass and no previously passing test fails; verify the delivery-failure/fresh-recording probes from test_plan “Extra cases,” without assuming clipboard rollback.
   **Status:** not started.

6. **Name:** Language and application context.
   **Goal:** Forward all ten supported languages and application context to local inference while preserving meaning and applying agreed style rules.
   **Spec sources:** spec Functional Requirements FR-002, FR-004, FR-005; architecture §2, §4–§5; contracts Transcription/TextCorrection Methods and Shared types.
   **Criteria:** None; FR-004–FR-005 have no acceptance criteria.
   **Tests that should turn green:** None in the current suite.
   **Depends on:** 1, 5.
   **Done when:** The listed tests pass and no previously passing test fails; verify the ten-language and meaning/context probes from test_plan “Extra cases,” after resolving style/model questions below.
   **Status:** not started.

## Test issues

- Only `test_AC001` exists. Later slices have no existing tests to turn green; their completion cannot be established by this suite alone.
- The test explicitly uses fixed inference results and simulated capture/paste. It checks coordination, not actual Control double-tap handling, MLX locality, model quality, or field insertion. Its zero-valued audio is a fixture, not a silence test.
- The registered handler is checked for presence but never invoked. No contradiction with the spec was found; these are coverage gaps.
- Application style and exact model output are unspecified, so exact style assertions cannot yet be derived.

## Design questions

- Where should real microphone, MLX, global shortcut, focus, clipboard, paste, and notification closures be composed? The app currently only displays a placeholder. Existing contracts expose injection points but no composition function. Any new function/module needs a design decision first.
- Which local models and silence-detection behavior meet the ten-language requirements? Model setup is out of scope; runtime inference still needs validation.
- Which applications and formatting/style rules must TextCorrection support? When should application context be sampled? Destination focus is explicitly checked at paste time.
- What cleanup is expected after capture or application-lookup failures beyond the contracted throw/discard behavior?

## Coverage audit

Unassigned acceptance criteria: none. Unassigned failing tests: none. AC-001 and its sole test are assigned only to slice 1.

Unfilled contracted functions/initializers: none; slice 1 covers every signature, and later slices extend their behavior. Real dependency composition and placeholder UI replacement remain unresolved under Design questions, outside the contracted module surface.

Next action: Slice 1, Successful voice flow — make `test_AC001` pass, starting with `Recording.init`.
