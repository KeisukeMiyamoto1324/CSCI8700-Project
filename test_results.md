# AC-001 test result

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
