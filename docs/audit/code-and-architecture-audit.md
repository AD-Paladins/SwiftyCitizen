# SwiftyCitizen Code & Architecture Audit

Last audited: September 19, 2026.

## Scope

Audited the full app (32 source files, 7 test files) for layering, dead code, doc/code drift, and test coverage. The app is an offline-first SwiftUI + SwiftData study aid with a one-directional content → pure domain → persistence → views flow.

## Findings

### Architecture / layering — strong

- No `Core/Domain/` file imports `SwiftUI` or `SwiftData`; the Foundation-only rule holds across every pure type.
- ⚠️ `SwiftyCitizen/Core/Persistence/Models/StudySession.swift:54` — `resumeState()` builds a pure-domain `FlashcardState`, restores attempts, and seeks to position. That is resume *business logic* living inside a `@Model`, which contradicts the AGENTS.md rule that models "never contain business rules." It is not an import cycle (FlashcardState is Foundation-only), but it is the one place where persistence and domain logic blur. Move it into `StudyDomain` or a dedicated `SessionResume` helper.

### Dead code — none

- `ExamEngine` declares two `selectQuestions` overloads; both are live: the closure variant (`ExamEngine.swift:4`) feeds `makeState`, and the `shuffleEnabled:` Bool variant (`:29`) is called from `FlashcardSessionView.swift:383`. Minor duplication smell, not removable without touching a call site.

### Doc/code alignment — honest

- Distractor cap (max 4), the `sessionFeedbackEnabled` persistence key, and uniform manual advance are all present in code and match the docs. No drift on the claims spot-checked.

### Test coverage — real gaps

- Tests use different filenames than sources, so the scoring/selection core (`AnswerEvaluator`, `MockTestState`, `ReviewDeckBuilder`) is well covered. The following have no dedicated unit test file: `StudyDomain`, `QuestionContent`, `TestConfiguration`, `OnboardingConfiguration`.

## Roadmap items (this audit)

1. Close the accessibility gap (VoiceOver + Dynamic Type on a real iPhone; code-level audit already done).
2. Move `StudySession.resumeState()` out of the `@Model` into `StudyDomain`/a helper to honor the layering rule cleanly.
3. Add 3–4 thin tests for `StudyDomain`, `QuestionContent`, `TestConfiguration`, `OnboardingConfiguration` — cheap, high-value coverage on the untested core.
4. Address the deferred mock-test findings (≥2s incorrect feedback, skip/see-answer affordance) once Phase 0.5 closes.

## Lifecycle

This file is a working note. **Delete it after all four items above are complete**, then fold any durable decisions into `docs/plan/current-status.md` and the relevant `docs/architecture/` document in the same work unit.
