# Phase 0.5 Design Specification

Status: Low-fidelity flow alignment is complete; accessibility review of the implemented screens is in progress, with high-fidelity polish and export backup still pending

This document is the repository-backed design source for Phase 0.5. It defines the first-release navigation, high-risk user flows, low-fidelity wireframes, visual direction, and interaction states before production UI implementation begins.

## Current Design Status

The current repository state includes the low-fidelity onboarding, flashcard, mock-test, and speech-fallback flows. The design work is sufficient to start the next implementation slice, but it is still intentionally incomplete as a final design handoff because typography, accessibility, and the final export backup still need a formal review.

The implemented screens were audited against the Accessibility Baseline below. The following concrete gaps were fixed in code: Dynamic Type support for `SessionSummaryView` and `WelcomeView` (now scrollable so text does not clip at large sizes), a 44-point touch target for the close control in `SessionProgressHeader`, a non-color selection indicator (checkmark) for review scopes, and explicit "Content unavailable" states in `StudyView` and `MockTestSetupView` when a question bank cannot load. Remaining accessibility work is the formal Dynamic Type and VoiceOver review on a small iPhone viewport and the high-fidelity pass.

## Design Principles

- Put the next useful study action first.
- Keep the current USCIS test configuration visible at decision points.
- Prefer calm, focused study surfaces over dashboard decoration.
- Treat official content as authoritative and generated aids as secondary.
- Make every core study action usable without a microphone or network connection.
- Use progressive disclosure: show the essential answer first, then supporting metadata.

## Navigation

```mermaid
flowchart TD
    Welcome --> Configuration
    Configuration --> Home
    Home --> Study
    Home --> Practice
    Home --> Progress
    Home --> Settings
    Study --> Flashcards
    Study --> TargetedReview
    Flashcards --> SessionSummary
    TargetedReview --> SessionSummary
    Practice --> MockSetup
    Practice --> OralPractice
    MockSetup --> MockTest
    MockTest --> MockResult
    OralPractice --> PermissionFallback
    Settings --> Configuration
    Settings --> ContentInfo
```

The primary navigation is Home, Study, Practice, Progress, and Settings. Welcome and Test Configuration are onboarding or modal flows, not permanent tabs.

## High-Risk Flows

### Flow A: First Run and Test Configuration

Goal: configure the correct study rules without presenting legal advice.

```mermaid
flowchart LR
    A[Welcome] --> B[Choose filing-date context]
    B --> C{65/20 eligible?}
    C -->|Yes| D[Confirm 65/20 study set]
    C -->|No| E[Confirm 2008 or 2025 rules]
    D --> F[Choose study language]
    E --> F
    F --> G[Home dashboard]
```

Required behaviors:

- Explain that the app is a study aid and does not determine legal eligibility.
- Show the resulting test version, question count, and passing score before confirmation.
- Allow the learner to edit the configuration later from Settings.
- Do not silently switch banks when the filing-date context changes.

### Flow B: Flashcard Study

Goal: learn one official question at a time with a low-friction loop.

```mermaid
flowchart LR
    A[Home] --> B[Start study]
    B --> C[Official question]
    C --> D[Reveal answer]
    D --> E[Self-assess]
    E --> F{More questions?}
    F -->|Yes| C
    F -->|No| G[Session summary]
```

Required behaviors:

- The question side shows the official wording and question number.
- The answer side shows official answers and answer cardinality.
- Self-assessment uses explicit labels such as Again, Hard, and Got it.
- Source or current-answer warnings are available without interrupting the study loop.
- A learner can exit and resume without losing the current session state.

### Flow C: Mock Test

Goal: simulate the oral civics test using the active official rules.

```mermaid
flowchart LR
    A[Practice] --> B[Mock test setup]
    B --> C[Confirm version and rules]
    C --> D[Question prompt]
    D --> E[Manual answer or optional transcript]
    E --> F[Record result]
    F --> G{Pass or fail threshold reached?}
    G -->|No| D
    G -->|Yes| H[Mock test result]
```

Required behaviors:

- The setup screen shows version, bank size, maximum questions, and passing score.
- The official simulation remains usable without speech recognition.
- Pause and exit are available without accidentally recording an answer.
- The result distinguishes app scoring from an actual USCIS decision.
- Missed questions link directly to targeted review.
- The targeted review of a missed question shows the learner's own answer (the one they gave) next to the official answer, so the comparison drives learning.
- Flow C must support selection-based answers — single-select and multi-select options — in addition to typed text (see `content-pipeline.md`).

### Flow D: Speech Permission and Fallback

Goal: make oral practice additive rather than a dependency.

```mermaid
flowchart LR
    A[Oral practice] --> B{Speech available?}
    B -->|Yes| C[Request microphone permission]
    B -->|No| F[Manual answer mode]
    C -->|Granted| D[Record and transcribe]
    C -->|Denied| F
    D --> E[Review transcript and confirm]
    F --> E
```

Required behaviors:

- Explain why microphone access is requested before the system prompt.
- Never block flashcards or manual mock tests when permission is denied.
- Show partial, empty, interrupted, and unavailable-transcription states.
- Let the learner confirm or correct the recognized result.

## Low-Fidelity Screen Notes

### Home Dashboard

```text
+--------------------------------+
| SwiftyCitizen          Settings|
| 2025 test | 20 questions | 12  |
|                                |
| Continue studying              |
| [  Start review             ]  |
|                                |
| Today                          |
| 12 reviewed     75% correct   |
|                                |
| Due next                       |
| 8 questions                   >|
|                                |
| Home  Study  Practice Progress|
+--------------------------------+
```

### Flashcard Study

```text
+--------------------------------+
| Close                 3 of 20  |
|                                |
| Question 12                    |
| What is the supreme law        |
| of the land?                   |
|                                |
|          [ Reveal answer ]     |
|                                |
| Home  Study  Practice Progress|
+--------------------------------+
```

After reveal, the primary action becomes the self-assessment control row. The official answer remains the visual focal point; source and dynamic-answer metadata sit below it.

### Mock Test Setup

```text
+--------------------------------+
| Mock test                      |
|                                |
| 2025 Civics Test               |
| Up to 20 questions             |
| Need 12 correct                |
|                                |
| Answer mode                    |
| ( ) Manual   ( ) Speech aid   |
|                                |
| [ Start mock test ]            |
+--------------------------------+
```

### Permission Fallback

```text
+--------------------------------+
| Speech practice                |
|                                |
| Microphone access is off.      |
| You can still practice by      |
| typing or answering aloud      |
| without automatic transcription.|
|                                |
| [ Use manual practice ]        |
| [ Open Settings ]              |
+--------------------------------+
```

## Visual Direction

The visual direction is civic, calm, and study-oriented rather than governmental or gamified.

| Token | Direction |
| --- | --- |
| Typography | A readable humanist sans-serif with strong number and question hierarchy |
| Primary color | Deep ink or navy for structure and trust |
| Accent color | Warm amber for active study actions and progress highlights |
| Success color | Accessible green paired with text, never color alone |
| Error color | Accessible red paired with text and an icon or label |
| Surface | Warm neutral background with high-contrast content surfaces |
| Shape | Restrained corner radius and consistent touch targets |
| Motion | Short, purposeful reveal and progress transitions; respect Reduce Motion |

Do not use color alone to communicate correctness, eligibility, or pass/fail status.

## Component Inventory

- `AppTabBar`
- `ConfigurationSummary`
- `PrimaryActionButton`
- `QuestionCard`
- `AnswerCard`
- `SelfAssessmentControl`
- `ProgressMeter`
- `SourceBadge`
- `CurrentAnswerNotice`
- `PermissionFallbackPanel`
- `SessionProgressHeader`
- `EmptyState`
- `ErrorState`

Each component needs default, pressed, disabled, loading, and accessibility states where applicable.

## Accessibility Baseline

- Support Dynamic Type without clipping question or answer text.
- Provide VoiceOver labels that include question number, state, and primary action.
- Keep touch targets at least 44 by 44 points.
- Pair color with text, icon, or shape for all status communication.
- Avoid auto-advancing after a learner reveals or answers a card.
- Respect Reduce Motion and provide a non-animated card transition.
- Keep the manual path available when microphone, speech assets, or network services are unavailable.
- Announce session progress without interrupting the answer content.

### Audit status against the implementation

Reviewed the shipped screens against the baseline on the current simulator target (iOS 27, iPhone 17e frame). Verified already-correct: VoiceOver labels for question number and primary actions, no auto-advance after reveal or answer, no motion-dependent transitions (inherent Reduce Motion support), and manual-answer paths never blocked. Fixed during this review: Dynamic Type clipping in `WelcomeView` and `SessionSummaryView` (now scrollable), the sub-44-point close control in `SessionProgressHeader`, color-only scope selection in `TargetedReviewView` (added a checkmark), and silent empty sessions when a bank fails to load (now explicit `Content unavailable` states). Added in the states pass: a validation error message in `TestConfigurationView` when Save is blocked, empty review-set states in `FlashcardSessionView` and `MockTestSessionView`, a zero-question footer in `TargetedReviewView`, and a scrollable content-unavailable state in `StudyView`. Loading states are not needed: banks are bundled JSON loaded synchronously. Small-viewport revision: audited against the iPhone 17e frame (390 pt width) by code inspection — `SelfAssessmentControl` now switches from a row of three buttons to a stacked layout at accessibility text sizes (≥ `.accessibility3`), `SessionProgressHeader` pins its progress text to one line with a minimum scale factor, and the Welcome primary action uses the large control size (≥ 44 pt target consistent with `PrimaryActionButton`). All content containers are scrollable or List-based; no fixed-width text frames remain. Remaining: a formal Dynamic Type / VoiceOver pass on the 420x900 high-fidelity frame and the high-fidelity prototypes.

## Prototype Checklist

- [x] Recreate the navigation flow in Penpot.
- [x] Create low-fidelity wireframes for Welcome, Configuration, Home, Flashcard, Mock Setup, Mock Test, Result, and Permission Fallback.
- [x] Define empty, error, loading, and unavailable states where they apply.
- [x] Review configuration visibility and oral-practice fallback on a small phone viewport.
- [ ] Create high-fidelity prototypes for Flows A-D.
- [ ] Export or back up the design files locally.
- [ ] Record accepted design decisions and unresolved questions in this document.

Penpot contains an initial generic pass (`WF - ...`) and a second pass built with the integrated `Wireframing kit v1.1` library. The kit-based boards are named `WF2 - Welcome`, `WF2 - Test Configuration`, `WF2 - Home Dashboard`, `WF2 - Flashcard Study`, `WF2 - Mock Test Setup`, `WF2 - Mock Test`, `WF2 - Mock Test Result`, and `WF2 - Permission Fallback`. They use a 420 by 900 mobile frame as the current review target. The `WF2 - ...` boards are the reference iteration.

The kit-based boards were rebuilt with relative child positioning after insertion. Their direct elements use a minimum 16-point frame margin, explicit text widths, and separated vertical blocks. The dashboard's review button intentionally sits inside its continuation card.

## Decision Drafts (pending product confirmation)

### 65/20 eligibility explanation

Candidate copy for the Settings 65/20 section and the mock-test-setup rules panel:

> Because you are 65 or older and have held a green card for 20 years or more, you qualify for the USCIS 65/20 special consideration. You study only the official 20-question 65/20 set. On test day the officer asks up to 10 of those questions, and you must answer at least 6 correctly to pass.

Facts come from `docs/plan/uscis-test-rules.md`; the numbers (10 asked, 6 correct) are the authoritative boundaries.

### Current-answer warnings without interrupting study

The mock-test evaluator is lenient by design (subset/partial acceptance for single-answer questions). A warning must be *available, explainable, and non-blocking*.

**Implementation scope (current slice) — Per-answer feedback + accepted-only warning:**

The mock test shows a minimal, non-blocking feedback indicator for **every** answer so nothing is hidden (this is study support, not a real exam). Feedback is layered on the evaluated question card:

- **All verdicts** (correct-exact, rejected, lenient-accepted): show their concise indicator inline ("Correct" / "Incorrect" / "Accepted: ...") and wait for a "Next" tap to advance — uniform manual advance for every verdict.
- All indicators are inline on the question card, never as an alert or sheet. Copy frames feedback as study guidance, not official grading.
- VoiceOver announces each notice after the question content, without truncating it (accessibility baseline).
- **Toggle flag:** a single `sessionFeedbackEnabled` setting (persisted, default `true`) controls whether any per-answer indicator renders. When disabled, the card shows only the question and the deck advances normally. This flag is a runtime/UX switch that can be turned off without code changes.

**Flow rule (uniform manual advance):** every verdict shows its indicator inline and waits for a "Next" tap to advance; when `sessionFeedbackEnabled` is off, the deck advances immediately with no indicator.

**Future refinement (next slice, gated on more work) — Rejected-but-close warning:**

- Later slices may extend the warning to cover answers that `evaluate()` **rejects** despite close text overlap (e.g. cardinality-2 questions where only 1 of 2 details was named). This requires a different copy ("Close — this only partially matches...") and a flow change so feedback is shown before advancing. Deferred until the accepted-only warning is validated.

### Answer evaluation: literal matcher + Apple Intelligence

The evaluator must stay **offline-first** (the spec's core rule is that every study action works without a microphone or network). Evaluation is layered:

- **Baseline (always available):** a pure, deterministic token-set matcher (`AnswerEvaluator`) compares normalized tokens against accepted official variants. It is lenient by design and never requires network or on-device ML. This remains the fallback path.
- **Enhancement (optional, when available):** Apple Intelligence may be used to evaluate answer quality **semantically** rather than only literally — e.g. recognizing that "the supreme law of the land" answers *What is the supreme law?* even when word order or phrasing differs from the literal variant. On-device models keep all data private; no answer text leaves the device.
- **Fallback contract:** whenever Apple Intelligence is unavailable, disabled, or a model is missing, the app must gracefully fall back to the literal matcher with no change in behavior or accuracy degradation the learner notices. Apple Intelligence is an enhancement, never a hard dependency.
- **Content integrity:** semantic evaluation must still trace to official content or the learner's own comparison — never to AI-generated distractors or AI "grading" of official answers. The app does not claim an AI score predicts immigration outcomes.

## Open Decisions

- [x] Final typography choice — SF system defaults.
- [x] Final color tokens and contrast verification — three user-selectable themes (Civic Navy default, Paper & Emerald, Study Calm) with semantic `AppPalette` tokens and light/dark variants, replaced the old `AppColor`/hardcoded reds.
- [x] Whether Progress is a tab or a Home destination in the first release — permanent tab.
- [ ] Exact wording for the 65/20 eligibility explanation after product review (draft in "Decision Drafts" above).
- [x] Whether audio playback belongs in Phase 1 or Phase 4 — Phase 4.
- [x] Current-answer warning scope — slice implements per-answer feedback for **all** verdicts (correct-exact, rejected, lenient-accepted) so nothing is hidden; only the lenient-accepted case pauses for a "Next" tap (non-advance rule). A `sessionFeedbackEnabled` flag toggles all indicators off. The rejected-but-close warning remains a future refinement.
- [x] Answer evaluation approach — baseline is a deterministic offline token-set matcher; Apple Intelligence semantic evaluation is an optional enhancement with mandatory offline fallback. Content always traces to official sources.
- [x] Missed questions should be reviewed showing the learner's own answer next to the official answer.
- [x] Question sets support Answer format variety (typed text, single-select, multi-select) beyond plain text.
