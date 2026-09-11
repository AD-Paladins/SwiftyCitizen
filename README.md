# SwiftyCitizen

An offline-first iOS study app for the USCIS naturalization civics test, built with SwiftUI and SwiftData.

SwiftyCitizen helps a learner study the official questions, practice answers aloud, and measure progress — without an account, a backend, or generative AI. It is a **study aid only**. It does not determine immigration eligibility, and it never presents generated content as an official USCIS question or answer.

## Features

- **Three selectable themes** (Civic Navy, Paper & Emerald, Study Calm) with semantic palette tokens and light/dark variants. Changing the theme in Settings re-renders the whole app live.
- **Flashcards** — reveal the official answer, self-assess (Again / Hard / Got it), advance.
- **Targeted review** — focus on due, unanswered, or weak questions computed from persisted attempt history; resume an interrupted session.
- **Mock test** — simulate the official civics test with the selected version's rules: fixed bank size, passing score, and early pass/fail. Answers are typed and evaluated deterministically (speech is a later phase).
- **Progress dashboard** — today's review count, "Got it" rate, and remaining questions, computed from real data.
- **Local persistence** — configuration, sessions, and attempts are stored on-device via SwiftData; everything survives a relaunch without a network connection.

## Architecture

The app is organized in layers so that scoring, selection, and content logic stay testable without SwiftUI or SwiftData:

```
content (bundled JSON)  →  pure domain (Foundation only)  →  persistence (SwiftData)  →  views (SwiftUI)
```

- **Pure files** (`AnswerEvaluator`, `FlashcardState`, `ReviewDeckBuilder`, `StudyProgressMetrics`, `ExamEngine`, `MockTestState`, `QuestionContent`, `StudyDomain`, ...) import only `Foundation`. They hold all business rules and can be unit-tested in isolation.
- **`@Model` files** (`SavedOnboardingConfiguration`, `StudySession`, `QuestionAttempt`) store learner state; they never contain business rules.
- **Views** drive pure state machines and hold no scoring or selection logic.

One-directional flow: content → pure domain → persistence → views. A pure type never imports a view or a `@Model`.

## Content and rules

Official question banks are bundled JSON, validated at load time:

| Bank | Version | Size | Source |
| --- | --- | --- | --- |
| `uscis-2008.json` | 2008 | 100 | Official 2008 civics test |
| `uscis-2025.json` | 2025 | 128 | Official 2025 civics test |
| `uscis-65-20.json` | 65/20 | 20 | *Derived* from the 2008 bank via a manifest |

The app distinguishes 2008, 2025, and 65/20 configurations and never mixes them. The filing-date rule selects the version; the 65/20 special consideration selects the designated subset. Scoring follows each version's official rules (e.g. 2025 asks 20 questions, 12 correct to pass).

## Getting started

Requirements: Xcode 27, iOS 27.0 target, simulator iPhone 17e.

```bash
# Build
xcodebuild build -project SwiftyCitizen.xcodeproj \
  -scheme SwiftyCitizen \
  -destination 'platform=iOS Simulator,id=11E7E98A-D558-4E53-B211-CB4ACD1FBB38'

# Test (46 tests across 4 suites)
xcodebuild test -project SwiftyCitizen.xcodeproj \
  -scheme SwiftyCitizen \
  -destination 'platform=iOS Simulator,id=11E7E98A-D558-4E53-B211-CB4ACD1FBB38' \
  -parallel-testing-enabled NO \
  -only-testing:SwiftyCitizenTests
```

New `.swift` files under `SwiftyCitizen/` and `SwiftyCitizenTests/` are picked up automatically (`PBXFileSystemSynchronizedRootGroup`); do not edit `project.pbxproj` manually.

## Project layout

```
SwiftyCitizen/            App shell, views, theme, and pure domain types
SwiftyCitizen/Resources/QuestionBanks/   Bundled official question banks
SwiftyCitizenTests/      Pure-logic unit tests (exam, study, targeted review, content)
docs/plan/               Product plan, design spec, screen inventory, USCIS rules
docs/architecture/       Implementation docs: flows, persistence, content, dependencies
```

## Where to read next

- **Product direction** — `docs/plan/product-plan.md` (phases, scope), `docs/plan/screen-inventory.md` (screen responsibilities).
- **Authoritative rules** — `docs/plan/uscis-test-rules.md`.
- **How the code works** — `docs/architecture/README.md` (reading order), then `flow-flashcards.md`, `flow-mock-test.md`, `data-and-persistence.md`, `content-pipeline.md`, `dependencies.md`.
- **Current state and next slice** — `docs/plan/current-status.md`.

## Status

The content foundation, onboarding, dashboard, flashcards, targeted review, mock test, settings, themes, and accessibility pass are implemented. The design spec's remaining items (final high-fidelity direction, formal Dynamic Type / VoiceOver review) are documented as pending. Planned next work includes showing the learner's own answer in missed-question review and supporting single-select / multi-select answers in addition to typed text.

## License / note

SwiftyCitizen is a study aid. Official USCIS questions and answers remain the property of the U.S. government; this app does not make legal claims and never replaces official guidance.
