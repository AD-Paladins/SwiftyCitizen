# Flow: Flashcards

The flashcard flow is the base study loop: one official question at a time, reveal the answer, self-assess, advance. It is also the rendering host for targeted-review decks and for missed questions from the mock-test result.

## Quick path

1. Study tab → Flashcards (or Targeted review, or a missed-questions link).
2. Question shows → `Reveal answer` → official answers appear.
3. Self-assess: Again / Hard / Got it → next question.
4. Last question → `SessionSummaryView` → done.

## Details

| Topic | Decision |
| --- | --- |
| Entry points | `FlashcardSessionView` is pushed from `StudyView` (mode `.flashcards`), from `TargetedReviewView` (mode `.targetedReview`, custom deck, optional resume), and from `MockTestResultView` (missed question deck) |
| State machine | `FlashcardState` — pure struct: `currentIndex`, `isRevealed`, `attempts` |
| Persistence | `StudySession(mode:)` + `QuestionAttempt(assessment:)` per answer |
| Version source | `configuration.selectedTestVersion` → `QuestionBankLoader` |

## State machine

`FlashcardState` drives the whole session and is testable without UI.

```mermaid
flowchart LR
    A[Question] --> B{Revealed?}
    B -->|no| C[Reveal answer]
    C --> D[self-assess]
    D --> E{More questions?}
    E -->|yes| A
    E -->|no| F[Session summary]
```

- `reveal()` sets `isRevealed`; no auto-advance.
- `assess(_ assessment:)` records the attempt, advances `currentIndex`, resets `isRevealed`.
- `seek(to:)` and `restore(attempts:)` support resuming an interrupted session.
- Questions are selected with order preserved from the bank unless `shuffleQuestions` is enabled in settings, in which case they are shuffled via `ExamEngine.selectQuestions(from:maximum:shuffleEnabled:)`.

### Resume

`StudySession.resumeState(deckQuestions:)` rebuilds a `FlashcardState` from the persisted deck order (`deckStableIDs`) and answered attempts, then seeks to the saved `currentIndex`. `FlashcardSessionView` starts from a resumed state when a resume session is passed in; otherwise it builds a fresh state and creates a new `StudySession`.

### Resume

`StudySession.resumeState(deckQuestions:)` rebuilds a `FlashcardState` from the persisted deck order (`deckStableIDs`) and answered attempts, then seeks to the saved `currentIndex`. `FlashcardSessionView` starts from a resumed state when a resume session is passed in; otherwise it builds a fresh state and creates a new `StudySession`.

## Data flow

```mermaid
flowchart TD
    A[StudySession.attempts] --> B[QuestionAttempt]
    B --> C[save via modelContext]
    C --> D[StudyProgressMetrics]
    D --> E[Home dashboard Today / Due next]
```

## Gotchas

- The relationship `StudySession.attempts` is an unordered to-many; resume and metrics never assume attempt order (tests use dictionary/set lookups, not indices).
- Self-assessment is learner-reported and never presented as a passing score; "Got it" rate is labeled as a rate, not accuracy.
- `QuestionAttempt` uses a `rawValue` string for `SelfAssessment`; unknown values decode to nil and are skipped by metrics.
- Exiting without answers deletes the session; exiting after answers marks it ended (`endedAt`).
- When rendering a missed-questions deck (`.targetedReview` from `MockTestResultView`), the official answer is shown; showing the learner's own wrong answer alongside it is a planned enhancement that requires pairing `QuestionAttempt.answerText` with its question (see `flow-targeted-review.md`).

## Checklist

- [ ] Flashcard deck loads from the selected version's bank.
- [ ] Reveal does not auto-advance.
- [ ] Each assessment persists one `QuestionAttempt` on the session.
- [ ] Interrupted sessions resume to the saved position.
- [ ] Summary shows per-assessment counts.
- [ ] Dashboard Today/Due figures change after assessment.
- [ ] Missed-question review renders the learner's own answer next to the official answer.