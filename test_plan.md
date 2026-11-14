# Test plan

Sources: spec.md, architecture.md, contracts.md, and the agreed native runtime plan.
Automated dependency tests and actual model/OS checks are separate evidence.
A passing mock inference test does not prove recognition/correction quality.

## Acceptance criterion

| ID | Requirements | Expected flow |
|---|---|---|
| AC-001 | FR-001–FR-003 | With local models/permissions ready and an editable field selected, Control double-tap starts real capture; another stops it. Local transcription precedes actual LFM correction; clipboard and Command-V deliver corrected text while preserving meaning. |

`test_AC001` checks module coordination through injected boundaries and the registered
async shortcut handler. Actual voice/model/field behavior needs NATIVE-01 below.
The historical written “teh” fixture validates correction forwarding, not how a
spoken misspelling would be recognized. Real tests use meaning/correction checks.

## Automated behavior tests

- Normal flow: capture ordering, real handler invocation, transcription forwarding,
  detected-language forwarding, correction result delivery, and no failure notification.
- Blank transcription: empty, spaces, tabs, newlines, mixed and Unicode whitespace
  skip correction/focus/clipboard/paste/notification; nonblank text remains unchanged.
- Inference failures: one notification, original error propagation, audio release,
  no delivery/retained pending text, and a fresh successful run afterward.
- Delivery: final selected field, absent selection, focus/clipboard/posting failures,
  no automatic retry or inference notification, and fresh capture after failure.
  Do not require clipboard rollback after a failed paste command.
- Language: all ten supported codes are forwarded with original-language text.
  Unsupported codes discard before correction/paste; missing detected language on
  nonblank transcription notifies as inference failure.
- Invalid correction: blank output notifies and does not paste. Actual model output
  reaching the generation cap is a failure, not a partial success.
- Processing: a shortcut during suspended inference returns busy without new capture.
- Shortcut recognition: two clean Control taps within 0.3 seconds, cancellation by
  other keys/modifiers, no action for a third tap alone, and timeout boundaries.
- Correction prompt: identical minimal-correction instruction regardless of destination;
  preserve names, numbers, negation, dates, language, and meaning. No app ID interface exists.

## Opt-in real-model checks

`LocalModelIntegrationTests.test_realLocalModels` runs only when
`VOICE_TYPING_MODEL_TESTS=1` is passed to the test process. Add
`VOICE_TYPING_DOWNLOAD_MODELS=1` for explicit initial setup; otherwise loading is
local-only. `VOICE_TYPING_TEST_AUDIO` supplies a mono float32 16 kHz WAV fixture.
For xcodebuild, prefix these environment names with `TEST_RUNNER_` so they reach
the test host. Synthesized speech tests model integration, not microphone capture.

Models: `mlx-community/whisper-large-v3-turbo-4bit`, local Silero VAD
(`mlx-community/silero-vad`), and `LiquidAI/LFM2.5-2.6B-MLX` `4bit/`.
Check silent audio returns empty text/no language before Whisper; known English
speech yields text and en; LFM repairs a typo while preserving Tuesday/not Thursday.
Precision and model selection are fixed; model revisions need not be pinned.

For full FR-005 acceptance, use real recordings in English, Arabic, Chinese,
French, German, Italian, Japanese, Korean, Portuguese, and Spanish. Check detected
language and corrected meaning in each. Preserve names/numbers/negation/dates;
exact model wording is not specified. Do not label ten-language quality validated
merely because injected-code forwarding passed.

## Native application checks

Initial setup must prepare all model/tokenizer files and microphone, Accessibility,
Input Monitoring/event posting, and notification permissions. Runtime readiness
failure recovery and concurrent inference remain outside the product scope.
No LLM identity stub is used. No application identifiers are acquired.

| ID | Procedure | Expected result | Status |
|---|---|---|---|
| NATIVE-01 | Prepare, select a TextEdit field, double-tap Control, speak, double-tap again. | Real capture → local Silero/Whisper auto language → LFM minimal correction → clipboard/Command-V; verify actual inserted content. | not run |
| NATIVE-02 | Repeat different sentences; inspect UI during model loading/inference and try the shortcut during processing. | UI stays responsive; no overlapping recording; fresh input on each completed request. | not run |
| NATIVE-03 | Start in A, select B before stopping, then C before delivery. Also repeat with B unchanged. | Only the field selected at paste time receives text. | not run |
| NATIVE-04 | Stop with no editable field selected, then select a field and start another request. | First request discards without clipboard/paste; second starts capture rather than replaying old text. | not run |
| NATIVE-05 | Record silence and non-speech separately; use speech as the control. | Silero skips Whisper for no speech; no correction/clipboard/paste/notification; speech proceeds. | not run |
| NATIVE-06 | Exercise transcription/correction errors separately and delivery failures separately. | Inference failure notifies once, discards and rethrows; delivery failures do not produce inference notifications. No retry; fresh successful capture works afterward. Record injected versus actual failures. | not run |
| NATIVE-07 | After all assets are prepared, disconnect networking and relaunch; repeat successful speech and all ten-language probes. | Local loading/inference works without requests to model servers or audio/text transmission. Unsupported language discards with UI status. | not run |

Record actual observations in test_results.md. `.pasted` means events were posted,
not that a destination inserted text. Native focus/paste coverage is verified only
for tested fields/applications; no universal application compatibility is assumed.
