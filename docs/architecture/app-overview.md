# App Overview

SwiftyCitizen is a SwiftUI + SwiftData app. The root decides between onboarding and the tab shell, and every study flow follows the same shape: load a question deck, drive a pure state machine, persist a session and its attempts.

## Entry point

`SwiftyCitizenApp.swift` creates a shared `ModelContainer` (schema: `SavedOnboardingConfiguration`, `StudySession`, `QuestionAttempt`, `Bookmark`) and injects it via `.modelContainer(sharedModelContainer)`. It also injects two app-wide coordinators via `.environment()`: `PendingNavigation` (Home deep-link to a review scope) and `SessionActivityCoordinator` (tab-switch guard). See [Global state](#global-state-coordinators).

`ContentView` decides the root:

- First launch (no persisted configuration): `NavigationStack { WelcomeView() }`.
- Configured: `MainTabView(configuration:)`.

## Tab root

`MainTabView` holds a `TabView` with four tabs defined in `AppTab`:

| Tab | Title | System image | Root view |
| --- | --- | --- | --- |
| home | Home | house | `HomeDashboardView` |
| study | Study | book | `StudyView` |
| practice | Practice | mic | `PracticeView` |
| progress | Progress | chart.bar | `ProgressTabView` (placeholder empty state) |

`HomeDashboardView` receives a `@Binding selectedTab` so its cards (`Start review`, due-next) can switch the user to the Study tab programmatically. It also opens the Bookmarked scope: on tap it sets `PendingNavigation.reviewScope = .bookmarked` and selects the Study tab.

## Global state (coordinators)

Two `@MainActor @Observable` coordinators live in `App/AppCoordination.swift` and are injected once at the app root; screens read them via `@Environment`. They mirror the `ThemeManager` pattern.

- `PendingNavigation` — carries a one-shot deep link (`reviewScope: ReviewScope?`). Home sets it and switches to Study; `StudyView` pushes `.targetedReview` onto its `NavigationStack(path:)` (fresh tab via `.onAppear`, cached tab via `.onChange`), and `TargetedReviewView` consumes it on appear and clears it.
- `SessionActivityCoordinator` — `private(set) isActive`. Every session view (`FlashcardSessionView` for flashcards + targeted review, `MockTestSessionView`) marks itself active on appear and inactive on disappear, and dismisses itself when the coordinator flips to inactive. `MainTabView` observes `isActive` in an `.onChange(of: selectedTab)` guard: while a session is active it reverts the selection (keeping the session visible) and shows a confirm alert; on confirm it deactivates the session (which self-dismisses) and navigates to the target tab.

## Navigation map

```mermaid
flowchart TD
    ContentView -->|no config| WelcomeView
    ContentView -->|config| MainTabView
    MainTabView --> HomeDashboardView
    MainTabView --> StudyView
    MainTabView --> PracticeView
    MainTabView --> ProgressTabView
    HomeDashboardView --> SettingsView
    SettingsView --> TestConfigurationView
    StudyView --> FlashcardSessionView
    StudyView --> TargetedReviewView
    TargetedReviewView --> FlashcardSessionView
    PracticeView --> MockTestSetupView
    MockTestSetupView --> MockTestSessionView
    MockTestSessionView --> MockTestResultView
    MockTestResultView --> FlashcardSessionView
```

`SettingsView` edits the persisted configuration in place via `TestConfigurationView`. Its reset is scoped: `Reset local progress` deletes only `QuestionAttempt` rows, preserving the saved configuration and filing date (`resetSpacedRepetition`). `WelcomeView` and `TestConfigurationView` are the only non-tab flows.

## Layer boundaries

| Layer | Files | Rules |
| --- | --- | --- |
| Screens | `*View.swift` | Read resolution logic from pure types, never contain scoring/selection logic |
| App shell | `SwiftyCitizenApp`, `ContentView`, `MainTabView` | Wire entry points; no business rules |
| Persisted state | `@Model` types | Store learner state only; reference content by stable IDs |
| Pure domain | `AnswerEvaluator`, `FlashcardState`, `ReviewDeckBuilder`, `StudyProgressMetrics`, `ExamEngine`, `MockTestState`, `OnboardingConfiguration`, `TestConfiguration`, `QuestionContent`, `StudyDomain` | No SwiftUI, no SwiftData |
| Content source | `QuestionBankLoader` + bundled JSON | Authoritative official content, validated at load |

## A study flow, generally

1. The entry screen loads `[QuestionContent]` from `QuestionBankLoader` (or builds one for the scope).
2. A pure state machine (`FlashcardState` / `MockTestState`) is created in the view's `init` from the deck.
3. The view drives the state machine with user actions (reveal, assess, submit).
4. On each answer the view appends a `QuestionAttempt` to the session's `StudySession` and saves via `modelContext`.
5. When complete, the view calls `finishSession()` which sets `endedAt` and dismisses.

The configuration (`OnboardingConfiguration`) arrives at every screen via plain value pass-down from the tab root; it is never re-read from the store per screen.

## Related

- `docs/architecture/data-and-persistence.md` → model lifecycle.
- `docs/architecture/dependencies.md` → file-level dependency map.