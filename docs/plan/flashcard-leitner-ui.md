# Flashcard Leitner UI — Recovery & Continuation Document

> **Purpose:** This is the recovery source of truth for the flashcard Leitner UI work. It exists so the
> work can be recovered if the agent/session context is lost (the previous agent died mid-Slice 4 while
> restyling the flashcard session against the Stitch designs). Read this first, then continue from the
> slice marked `IN PROGRESS` / `PENDING`.
>
> **Authoritative facts live in code.** This doc records *where* things are and *what state* they are in;
> always re-read the referenced files before editing. If this doc and the code disagree, the code wins —
> update this doc.

## 1. What this work is

Phase 3 of the product plan ("Retention and Accessibility") adds a transparent spaced-repetition
scheduler driven by learner self-assessment. The first piece of that is the **Leitner layer on
flashcards**: a 5-box scheduler, box tracking in the flashcard state, persistence/resume, and finally the
UI that restyles the flashcard session against the Stitch designs ("App Ciudadanía USA").

The work is split into slices. Slices 1–3 are the **domain** (pure, tested, no SwiftUI). Slices 4–6 are the
**UI** (restyle the existing `FlashcardSessionView` components against Stitch). As of 2026-09-30 the domain
(slices 1–3) and the UI restyle (slices 4–6) are both implemented; see the slice table below.

## 2. Where the code lives

| Area | Path |
| --- | --- |
| Leitner scheduler (pure) | `SwiftyCitizen/Core/Domain/LeitnerScheduler.swift` |
| Flashcard state + box tracking | `SwiftyCitizen/Core/Domain/FlashcardState.swift` |
| Session screen (to restyle) | `SwiftyCitizen/Features/Study/FlashcardSessionView.swift` |
| Leitner scheduler tests | `SwiftyCitizenTests/Domain/LeitnerSchedulerTests.swift` |
| Leitner flashcard tests | `SwiftyCitizenTests/Domain/FlashcardLeitnerTests.swift` |
| Leitner persistence tests | `SwiftyCitizenTests/Domain/FlashcardLeitnerPersistenceTests.swift` |

All domain files are `import Foundation` only (SwiftData-free, SwiftUI-free) so they stay unit-testable.
`FlashcardSessionView.swift` is the only file that needs restyling; it contains every session component:
`SessionProgressHeader`, `FlashcardSessionHeader`, `QuestionCard`, `AnswerCard`, `SourceBadge`,
`SelfAssessmentControl`, and `FlashcardSessionView`.

## 3. Slice-by-slice status

| Slice | Name | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Núcleo Leitner (`LeitnerScheduler`) | **DONE** | `LeitnerScheduler.swift` + `LeitnerSchedulerTests.swift` |
| 2 | Box derivation/track in `FlashcardState` | **DONE** | `FlashcardState.boxes`, `assess()`, `currentBox` + `FlashcardLeitnerTests.swift` |
| 3 | Persistence + resume Leitner | **DONE** | `FlashcardAttemptRecord.boxLevel`, `restore(attempts:)`, `FlashcardLeitnerPersistenceTests.swift` |
| 4 | Nav bar + progress bar (envoltura) | **DONE** | `FlashcardSessionHeader`: close X + "Card N of M" + `ProgressView` |
| 5 | UI Question State | **DONE** (2026-09-30) | `QuestionCard` restyled: ID prefix, topic w/ icon, headline question, `cardStyle()` |
| 6 | UI Answered State + Leitner buttons | **DONE** (2026-09-30) | `AnswerCard` (verified header + `cardStyle()`) + `SelfAssessmentControl` (box level, live intervals, "Mastered") |
| — | Build + tests + final verification | **DONE** (2026-09-30) | 172 tests pass; app compiles |

Notes:
- Slice 4's "audio" item is **out of scope** (audio is Phase 4, deferred). Do not implement audio here.
- The domain slices (1–3) are complete and tested. The UI restyle (slices 4–6) matches the Stitch designs
  using the existing design tokens (`CivicText`, `Space`, `CardStyle`, `AppPalette`) — no domain behavior changed.
- **Follow-ups still open** (deliberately not implemented): audio (`volume_up`), "Traducir (ES)" / Spanish
  per-question content, bookmark (`bookmark_border`), and the "Civics Insight" explanation card — all need
  data or a later phase. See §10.

## 4. Domain model facts (preserve these — do not regress)

- **`LeitnerScheduler`** — 5 boxes (`maxBox = 5`). Intervals per box (index 0 == box 1):
  `[0, 1d, 3d, 7d, 14d]`. Transitions: `again → box 1`, `hard → box − 1` (min 1), `gotIt → box + 1` (max 5).
  A miss (`again`) drops the card to box 1. Pure date math; no networking, no scoring model.
- **`FlashcardState.boxes`** — `[stableID: Int]`, stable cards start in box 1. `currentBox` is the box of the
  question in view. `assess(_:)` updates the box and (for `hard`/`gotIt`) appends a
  `FlashcardAttemptRecord` with its `boxLevel`.
- **`SelfAssessment`** — enum values `again`, `hard`, `gotIt`. The UI currently labels them Again / Hard /
  Got it; Stitch may use "Again / Hard / Mastered". **Open question (see §9): which labels does the Stitch
  design use, and should the box level be shown visibly?**
- **`again` re-presents without advancing** and records no attempt; `hard`/`gotIt` mark the card, advance,
  and record. Only the final confirmation counts. Retries do not pollute `gotItRate`.
- **Self-assessment is learner-reported** and must never be presented as a passing/exam-accuracy score.
- **Resume:** `FlashcardState.restore(attempts:)` replays attempts and lets the last box win per card.
  `FlashcardSessionView` resumes via `resumeFlashcardState(deckStableIDs:currentIndex:attempts:deckQuestions:)`.

## 5. Stitch design reference (source of truth for the restyle)

Project: **"App Ciudadanía USA"**, Stitch project ID **`13329010267888174190`**. Read screens with
`tools.stitch.get_screen({ name })`. The two interactive (HTML) designs are:

| Screen | Resource name (`name` arg) |
| --- | --- |
| Flashcards – Question State | `projects/13329010267888174190/screens/dee5fca427414a89a3f8d2b941419b4b` |
| Flashcards – Active Study Session (answered) | `projects/13329010267888174190/screens/f984d29848554909a1516872253f7301` |

Screenshot-only screens (fallback if HTML is unavailable):
- `projects/13329010267888174190/screens/13444306807646877948` — "Flashcards.png"
- `projects/13329010267888174190/screens/13444306807646879218` — "Flashcards-answered.png"

> **Gotcha:** the HTML/screenshot download URLs Stitch returns are signed and **expire**. Do not copy them
> into this doc. Always re-fetch via `get_screen` in the current session. The screen resource names above
> are stable and safe to record here.

Design decisions that constrain the restyle (from `docs/plan/design-redesign-plan.md`):
- Use **SF Pro Rounded** natively (`CivicText` helper → `.system(design: .rounded)`). No font bundling, no
  `Info.plist` edits. Stitch's "Plus Jakarta Sans" is intentionally NOT used.
- Align the existing `paperEmerald` theme to the Stitch tokens (colors already aligned — see decision log in
  `current-status.md`).
- Paint `palette.canvas` as background; `surface` cards sit visibly elevated.
- Use `Space` (xs/sm/md/lg/xl/2xl) and `CivicText` scale for spacing/typography instead of hardcoded values.

## 6. How to continue (step by step)

As of 2026-09-30, slices 1–6 and build/tests are DONE. If you are reading this after a context loss, verify
each slice against the code in §2 before assuming it is implemented (re-read `FlashcardSessionView.swift`).

If a slice turns out NOT to be implemented, here is how to finish it:

1. **Read the Stitch designs** in this session:
   ```
   tools.stitch.get_screen({ name: "projects/13329010267888174190/screens/dee5fca427414a89a3f8d2b941419b4b" })
   tools.stitch.get_screen({ name: "projects/13329010267888174190/screens/f984d29848554909a1516872253f7301" })
   ```
   The HTML download URLs are signed and expire — re-fetch via `get_screen` each session. Confirm against the
   screenshot-only screens ("Flashcards.png", "Flashcards-answered.png") if the HTML is unavailable.

2. **Slice 4** — `FlashcardSessionHeader`: close X + "Card N of M" counter + linear `ProgressView`. The
   functional requirements are met. A deeper structural restyle to Stitch's exact top bar (back arrow + person
   icon) is optional; keep the progress bar (better UX than the design's text-only counter).

3. **Slice 5** — `QuestionCard`: ID prefix (`studyFlashcardQuestionPrefix` + `stableID`), topic with a small
   icon, official question as headline, `cardStyle()`. Keep the answer-input field shown only when not revealed.

4. **Slice 6** — `AnswerCard` + `SelfAssessmentControl`: "Official answer" header (verified icon) + variants;
   then the Leitner buttons. Map `gotIt` → `studyFlashcardMasteredLabel` ("Mastered") at UI level (do NOT rename
   the `.gotIt` enum case — its rawValue backs persistence). Show `state.currentBox` as
   `studyFlashcardLeitnerBoxPrefix` + box number. Compute each button's interval from `LeitnerScheduler`:
   `again` → `studyFlashcardAgainInterval` ("< 1 min"); `hard`/`mastered` →
   `String(format: studyFlashcardIntervalFormat, days)`.

5. **Build + tests** — run §7 before declaring done. 172 tests must still pass; do not regress the domain.

Ordering advice (from the previous agent, still correct): slice 5 (Question State) is the dense core — give it
the most care. Each slice should be its own work-unit commit on the feature branch.

## 7. Verified build & test commands

Xcode 27, deployment target iOS 27.0, simulator iPhone 17e (destination id `9CC72DE8-ED58-4D07-B736-C9B4B6750139`).
New `.swift` files under `SwiftyCitizen/` and `SwiftyCitizenTests/` are auto-picked up (`PBXFileSystemSynchronizedRootGroup`); do not edit `project.pbxproj`.

- Build:
  ```
  xcodebuild build -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen \
    -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139'
  ```
- Tests (narrow, flashcard-only):
  ```
  xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen \
    -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139' \
    -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests
  ```
- On simulator: `./run-simulator.sh` (opens DeviceHub).

## 8. Non-goals (do not add)

- No audio (Phase 4).
- No AI-generated content; official answers stay authoritative.
- No schema changes for the box level (it lives in `FlashcardState.boxes` / `FlashcardAttemptRecord.boxLevel`).
- No presenting self-assessment as an exam score.

## 9. Open questions — RESOLVED (2026-09-30)

Both were answered by reading the Stitch designs and implemented:

1. **Button labels** → "Again / Hard / **Mastered**". Implemented via `studyFlashcardMasteredLabel` at UI level;
   the `.gotIt` enum case and its persistence rawValue are unchanged.
2. **Box visibility** → shown as "Leitner box N" (`studyFlashcardLeitnerBoxPrefix` + `state.currentBox`).

## 10. Deliberately deferred (follow-ups, not bugs)

These appear in the Stitch designs but need data or a later phase — do NOT implement without their prerequisites:

- **Audio** (`volume_up` on question/answer) — Phase 4.
- **"Traducir (ES)" / Spanish per-question explanations** — needs Spanish content in `QuestionContent` (Phase 3).
- **Bookmark** (`bookmark_border`) — no model/support yet.
- **"Civics Insight" card** (lightbulb explanation) — needs an insight/explanation field on the question; do not
  fabricate content.

## 11. Session log

- **2026-09-30** — Recovery doc created (`docs/plan/flashcard-leitner-ui.md`) + pointer in `product-plan.md` Phase 3
  + Engram mirror (`flashcard-leitner-ui`, obs #113). Then implemented the UI restyle that the previous agent had
  prepped localization keys for but never wired:
  - `QuestionCard`: ID prefix, topic w/ icon, headline question, `cardStyle()`.
  - `AnswerCard`: verified "Official answer" header, `cardStyle()`.
  - `SelfAssessmentControl`: "Leitner box N" indicator, live interval labels per grade, "Mastered" label.
  - Placeholder switched to `studyFlashcardOptionalPractice`.
  - No domain changes; `.gotIt` enum/rawValue untouched. **172 tests pass.**
