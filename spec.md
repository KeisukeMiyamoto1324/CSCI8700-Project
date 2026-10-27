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

- **FR-001:** As an administrative office assistant, I want to start and stop voice recording with a keyboard shortcut that I set and have my speech transcribed locally, so that I can create work documents efficiently while protecting confidential information.
- **FR-002:** As an administrative office assistant, I want the system to correct spelling errors and unnatural wording in my transcribed text locally, so that I can enter natural, accurate text that preserves my intended meaning.
- **FR-003:** As an administrative office assistant, I want the corrected text to be entered directly into the selected text field, so that I can enter polished text into the active application without manually copying and pasting it.
- **FR-004:** As a user, I want the system to adjust the text's format and writing style based on the application I am using, so that the text fits that application.
- **FR-005:** The system shall support voice input and text correction in English, Arabic, Chinese, French, German, Italian, Japanese, Korean, Portuguese, and Spanish.
- **FR-006:** The system shall insert the corrected text into the text field selected when recording stops, even if the selected field changes during recording.

# Acceptance Criteria

**AC-001: Enter corrected text using voice (FR-001, FR-002, FR-003)**

```gherkin
Feature: Local voice typing

  Scenario: Enter corrected text using voice
    Given the voice typing assistant is running with local models ready
    And the user has selected a text field in a document application
    When the user presses the recording shortcut
    And speaks a sentence
    And presses the shortcut again to stop recording
    Then the system transcribes the speech and corrects spelling errors locally
    And enters the corrected text into the selected text field
```
