# Native runtime integration result

Automated verification on this Apple Silicon Mac: **23 tests passed, 0 failures**.
This includes 21 flow/shortcut tests, a correction-prompt check, and the opt-in
real-model integration test. All retained pre-existing behavior tests passed after
async API migration; the obsolete application-lookup test was removed with that API.

```sh
TEST_RUNNER_VOICE_TYPING_MODEL_TESTS=1 \
TEST_RUNNER_VOICE_TYPING_DOWNLOAD_MODELS=1 \
TEST_RUNNER_VOICE_TYPING_TEST_AUDIO=/tmp/csci8700-speech.wav \
xcodebuild test -project CSCI8700-Project.xcodeproj \
  -scheme CSCI8700-Project -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/csci8700-runtime-build
```

```text
Real LFM correction: Please schedule the meeting for Tuesday, not Thursday.
Real Whisper transcription: Please send the report tomorrow. en
Executed 23 tests, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

The audio fixture was created locally using macOS `say -o` and converted using
`afconvert` to mono float32 16 kHz. Real Silero detected silence and returned no
transcription. Real Whisper transcribed the generated English speech and returned
en; real LFM fixed “teh” without adding an explanation, preserving Tuesday/not
Thursday. Real LFM also retained short thanks phrases in all ten supported languages.
This checks short-text language preservation, not full multilingual speech quality.

Earlier real-model runs exposed a missing chat-template asset and reasoning text
leaking into the answer. Setup now includes the template and the LFM container
uses always-on-thinking separation, returning only final answer chunks. The input
is explicitly delimited transcription data, not a conversational request.

The Xcode build/run also succeeded. The app window displayed the native controls
and “Models loaded. Prepare permissions before recording.” Start recording was
correctly disabled without permissions. Model files were downloaded into local
Application Support; they are not part of the repository.

**Still unverified:** actual microphone capture, actual editable-focus/Command-V
insertion, global key events under granted permissions, macOS notification display,
full ten-language spoken recordings, and physically disconnected-network operation.
NATIVE-01–NATIVE-07 remain pending; AC-001 is not claimed as real-device complete.
User permission setup is required before these native checks. See SETUP.md.

Logs: `/tmp/csci8700-full-model-tests-fixed.log` (passing full run),
`/tmp/csci8700-runtime-tests.log` (earlier 21-test unit run). Xcode successful launch
log: `/var/folders/22/yg9k3vp95sng8yw7n9nf5pz00000gn/T/ActionArtifacts/default/RunProject/RunProject-Log-20261113-194737.txt`.

---

# Test results

## Slice 5 result

Added `test_FR006_discardsRejectedDeliveryWithoutRetry`,
`test_FR006_discardsTextAfterFocusFailureWithoutRetry`,
`test_FR006_discardsTextAfterClipboardFailureWithoutRetry`, and
`test_FR006_discardsTextAfterPasteFailureWithoutRetry`.

Each case checks unchanged field content on failure/rejection, original error
identity where throwing, no notification or automatic retry, audio release, and
fresh capture followed by exactly one delivery of new text. A failed paste may
leave the clipboard written; rollback is not expected. These tests extend the
Slice 3 paste-error boundary check with coverage of all delivery failure stages.

Existing request-local state, idle transition before inference/delivery, and error
propagation already implement the required behavior; no production change was
necessary. Real macOS clipboard/focus/paste failures remain unverified.
Full-suite command is the same as Slice 3 below.
Output: `/tmp/csci8700-slice5-test-output.log`.

```text
Executed 16 tests, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

## Slice 4 result

Added `test_FR006_pastesIntoSelectionChangedBeforePaste`,
`test_FR006_pastesIntoUnchangedSelection`, and
`test_FR006_skipsClipboardAndPasteWithoutEditableSelection`.
They cover A → B → C selection changes, the B-selection control, and absence of
editable selection. Only the final selected field changes; no selection leaves
the clipboard untouched and sends no paste or notification.

The existing implementation already supplies this behavior; no production-code
change was necessary. Full-suite command is the same as Slice 3 below.
Actual macOS focus and paste are simulated, not validated.
Output: `/tmp/csci8700-slice4-test-output.log`.

```text
Executed 12 tests, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

## Slice 3 result (2026-11-13)

Added four FR-007 tests; existing tests were unchanged. Before implementation,
the transcription and correction failure tests failed because notification was
missing. The other seven tests passed. Output: `/tmp/csci8700-slice3-red.log`.

Full suite command:

```sh
xcodebuild test -project CSCI8700-Project.xcodeproj \
  -scheme CSCI8700-Project -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/csci8700-plan-build
```

After implementation:

```text
test_FR007_notifiesOnTranscriptionFailureAndRecovers passed
test_FR007_notifiesOnCorrectionFailureAndRecovers passed
test_FR007_doesNotNotifyOnApplicationLookupFailure passed
test_FR007_doesNotNotifyOnPasteFailure passed
Executed 9 tests, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

Both inference-failure cases verify exactly one notification, original error
identity, no delivery or clipboard changes, audio release after the call, and a
fresh successful recording without old-text retry. Lookup and paste failures
verify no inference notification; paste failure does not assume clipboard rollback.
The injected notification callback is tested, not actual macOS notification delivery.
Full output: `/tmp/csci8700-slice3-test-output.log`.

## Slice 2 result (2026-11-13)

Added four FR-008 tests without changing `test_AC001`. Before implementation,
three new tests failed and the nonempty-text test and AC-001 passed (34 assertion
failures across five tests). The failures showed blank text reaching correction
and delivery. Red-run output: `/tmp/csci8700-slice2-red.log`.

After implementation, the full suite passed:

```sh
xcodebuild test -project CSCI8700-Project.xcodeproj \
  -scheme CSCI8700-Project -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/csci8700-plan-build
```

```text
test_AC001 passed
test_FR008_discardsEmptyTranscription passed
test_FR008_discardsWhitespaceOnlyTranscription passed
test_FR008_preservesNonemptyTranscription passed
test_FR008_startsFreshRecordingAfterDiscard passed
Executed 5 tests, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

Checks cover empty, space, tab, newline, mixed and Unicode whitespace; no
application lookup/correction/focus/clipboard/paste/notification on discard;
unchanged clipboard; fresh recording and successful delivery after discard;
and unchanged nonempty text including surrounding whitespace. Actual model
silence detection is not tested. Full output: `/tmp/csci8700-slice2-test-output.log`.

## Slice 1 result (2026-11-13)

Full suite command:

```sh
xcodebuild test -project CSCI8700-Project.xcodeproj \
  -scheme CSCI8700-Project -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/csci8700-plan-build
```

```text
Test Case '-[CSCI8700_ProjectTests.VoiceTypingAcceptanceTests test_AC001]' passed (0.001 seconds).
Executed 1 test, with 0 failures (0 unexpected)
** TEST SUCCEEDED **
```

Tests were unchanged. This verifies the injected successful flow, not real model
inference or macOS delivery. Full output: `/tmp/csci8700-slice1-test-output.log`.

## Original skeleton baseline

Framework: XCTest. Run on macOS (Apple Silicon).

```sh
xcodebuild test -project CSCI8700-Project.xcodeproj \
  -scheme CSCI8700-Project -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/csci8700-ac001-build \
  -only-testing:CSCI8700-ProjectTests/VoiceTypingAcceptanceTests/test_AC001
```

Actual output (excerpt):

```text
Test Case '-[CSCI8700_ProjectTests.VoiceTypingAcceptanceTests test_AC001]' started.
```

Failure message:

```text
AC-001 requires a successful flow; Recording initialization threw notImplemented
```

```text
Test Case '-[CSCI8700_ProjectTests.VoiceTypingAcceptanceTests test_AC001]' failed (0.087 seconds).
Executed 1 test, with 1 failure (0 unexpected) in 0.087 (0.088) seconds
** TEST FAILED **
```

`test_AC001`: behavior assertion failed because the valid Recording initializer is not implemented. Compilation and test loading succeeded. Later assertions were not reached.

The test uses only the documented application contracts and their injected closures. It checks Control double-tap registration, start/delivery results, audio/text/context forwarding, processing order, clipboard/paste calls, and no failure notification on success. Local inference results are fixed test inputs; this does not verify model quality, actual field insertion, or absence of external communication. AC-001 has no rejection or error-code contract.
