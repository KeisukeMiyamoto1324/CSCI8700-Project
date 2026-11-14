# Description

Local AI Voice Typing Assistant is macOS software that turns speech into natural text and enters it into the application the user is using. It runs speech recognition and an LLM locally on Apple Silicon using MLX, without sending audio or text to external servers. It helps people who have difficulty typing and office assistants who create work documents.

# Goals

1. Help users create work documents with less time and effort.
2. Protect confidential information by keeping audio and text on the Mac.
3. Produce natural, accurate text while preserving the user's intended meaning.
4. Enter polished text into the active application without manual copying and pasting.

# Domain Model

## Actors

- User: A person using voice input, including an administrative office assistant.

## Objects

- Audio: Speech recorded from the user.
- Text: The base class for transcribed and corrected text.
- TranscribedText: Text produced from audio by local speech recognition.
- CorrectedText: Transcribed text corrected by a local LLM.
- Application: The application the user is using.
- TextField: An input field in an application where corrected text is entered.

# Functional Requirements

- **FR-001:** As an administrative office assistant, I want to start and stop voice recording by double-tapping the Control key and have my speech transcribed locally, so that I can create work documents efficiently while protecting confidential information.
- **FR-002:** As an administrative office assistant, I want the system to correct spelling errors and unnatural wording in my transcribed text locally, so that I can enter natural, accurate text that preserves my intended meaning.
- **FR-003:** As an administrative office assistant, I want the corrected text to be entered into the selected text field using the system clipboard and paste command, so that I can enter polished text into the active application without manually copying and pasting it.
- **FR-004:** The system shall use the same text-correction rules in every application. The destination application shall not change the corrected wording or format. Correction shall preserve the original language and intended meaning, fix spelling, grammar, and unnatural wording with minimal changes, and add no new information.
- **FR-005:** The system shall support voice input and text correction in English, Arabic, Chinese, French, German, Italian, Japanese, Korean, Portuguese, and Spanish. Transcription shall detect the language automatically and pass it to text correction. Speech detected in another language shall be discarded without correction or paste, with an unsupported-language status shown in the app.
- **FR-006:** The system shall insert the corrected text into the text field selected at paste time. If no editable field is selected or delivery fails, the system shall discard the undelivered text without retrying.
- **FR-007:** If transcription or text correction inference fails, the system shall display a macOS notification and discard the recording and all intermediate text.
- **FR-008:** For silent or otherwise non-speech audio, the system shall end recording without inserting text or taking further action.

# Acceptance Criteria

**AC-001: Enter corrected text using voice (FR-001, FR-002, FR-003)**

```gherkin
Feature: Local voice typing

  Scenario: Enter corrected text using voice
    Given the voice typing assistant is running with local models ready
    And the user has selected a text field in a document application
    When the user double-taps the Control key
    And speaks a sentence
    And double-taps the Control key again to stop recording
    Then the system transcribes the speech and corrects spelling errors locally
    And enters the corrected text into the selected text field
```

# Technical Constraints

Speech recognition shall use the 4-bit quantized MLX model
[`mlx-community/whisper-large-v3-turbo-4bit`](https://huggingface.co/mlx-community/whisper-large-v3-turbo-4bit)
(Whisper Large v3 Turbo), running locally on Apple Silicon. Model files are
prepared during initial setup; runtime transcription shall not send audio or
text to external servers.

Text correction shall use
[`LiquidAI/LFM2.5-2.6B-MLX`](https://huggingface.co/LiquidAI/LFM2.5-2.6B-MLX)
locally through MLX using its `4bit/` variant (4-bit quantization). Model
files are prepared during initial setup; runtime correction shall not send audio
or text to external servers.

Speech/non-speech detection shall use [Silero VAD](https://github.com/snakers4/silero-vad)
locally. When no speech is detected, Transcription shall return an empty string
without running Whisper inference, following FR-008.

The Control double-tap interval is 0.3 seconds, with no intervening keys or
other modifiers. New recording actions during inference are ignored.
Initial setup in the app downloads the required model/tokenizer files and obtains
permissions. After setup, runtime recording and inference use local assets only.
LFM correction runs at temperature 0 with a 4096-token output limit; empty or
incomplete output is an inference failure and shall not be pasted.

# Scope

Local models and required permissions are prepared during initial setup. Runtime handling of missing models or permissions, and concurrent operations, are outside this project’s scope.
