# SwiftyCitizen Screen Inventory

This document defines the first screen-level scope. It lists responsibilities and user actions only; it does not define visual design or implementation details.

## Navigation Model

The first release should use a tab-based root navigation with a small number of focused flows:

- **Home**: current study state and next action.
- **Study**: flashcards and targeted review.
- **Practice**: oral practice and mock tests.
- **Progress**: history and learning metrics.
- **Settings**: test configuration, language, permissions, and content information.

## Screens and Responsibilities

| Screen | Purpose | Core functionality | Phase |
| --- | --- | --- | --- |
| Welcome | Explain the app and start configuration | Start setup, show study-aid disclaimer, continue without an account | 1 |
| Test Configuration | Select the applicable study rules | Enter or confirm N-400 filing date, select test version, choose 65/20 eligibility, select study language | 1 |
| Home Dashboard | Provide a clear next action | Show due questions, recent accuracy, current session entry point, and configuration summary | 1 |
| Flashcard Study | Learn official questions and answers | Show question, reveal answer, play optional audio, mark self-assessment, move to next question | 1 |
| Targeted Review | Focus on weak or unanswered content | Filter by due, incorrect, unanswered, topic, and test version; start a review session | 1 / 3 |
| Session Summary | Close a study session | Show questions reviewed, self-assessment trend, weak topics, and next recommended action | 1 |
| Oral Practice | Practice answering aloud without exam pressure | Read or display the official question, record or transcribe an answer, show transcript, let learner confirm result | 4 |
| Mock Test Setup | Configure a simulated interview | Confirm test version, question count, audio behavior, and start test | 2 |
| Mock Test | Simulate the official oral civics test | Ask questions in order, track correct/incorrect answers, apply early pass/fail rules, allow pause and exit | 2 / 4 |
| Mock Test Result | Explain the simulation outcome | Show score, pass/fail according to selected rules, missed questions with the learner's own answers, and review action | 2 |
| Progress | Make improvement visible | Show attempts, accuracy, coverage, streak, due questions, and performance by topic | 1 / 3 |
| Question Detail | Inspect one question's learning history | Show official wording, answer variants, topic, attempts, and current-answer warning when applicable | 1 / 3 |
| Settings | Manage preferences and app behavior | Edit test configuration, language, audio, accessibility, notifications, and reset local progress | 1 / 4 |
| Content Information | Establish source and update trust | Show test version, source URL, verification date, content revision, and current-answer notice | 0 / 1 |
| Permissions and Availability | Handle optional platform capabilities | Explain microphone and speech permissions, unavailable speech services, and fallback to manual practice | 4 |

## First Release Boundaries

- The root experience must lead to studying, not to a marketing or AI feature screen.
- A learner must be able to study without granting microphone access.
- A learner must be able to complete a mock test without speech recognition when the service is unavailable.
- Test configuration must remain visible enough to prevent practicing the wrong USCIS test version.
- AI-generated summaries, if introduced later, belong in the session summary as optional content and must never replace official questions or answers.

## Screen Acceptance Checklist

- [ ] Every screen has one primary action.
- [ ] Every screen has an empty, loading, error, and unavailable-capability state where applicable.
- [ ] Back, cancel, pause, and resume behavior is defined for active sessions.
- [ ] Test version and 65/20 configuration are visible before starting a mock test.
- [ ] VoiceOver labels and Dynamic Type behavior are specified before implementation.
- [ ] Official content and generated study aids are visually distinguishable.
