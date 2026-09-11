# Phase 0.5 User Checklist

Use Penpot as the primary design tool. Excalidraw is optional for rough navigation maps.

## Tasks

- [x] Confirm the Penpot project and local backup flow for `SwiftyCitizen`.
- [x] Define the primary navigation structure: Home, Study, Practice, Progress, and Settings.
- [x] Create the onboarding and test-configuration flow.
- [x] Create a flashcard-study flow.
- [x] Create a mock-test setup, test, and result flow.
- [x] Create a speech-practice and manual-fallback flow.
- [x] Create low-fidelity wireframes for Welcome, Test Configuration, Home Dashboard, Flashcard Study, Mock Test Setup, Mock Test, Mock Test Result, and Permission Fallback using the integrated `Wireframing kit v1.1` library.
- [x] Show the active test version and scoring rules before a mock test starts.
- [x] Show a clear fallback when microphone or speech recognition is unavailable.
- [x] Define one primary action for each screen.
- [x] Define empty, error, loading, and unavailable states where they apply.
- [x] Check the flows at a small iPhone viewport and finalize the last spacing/accessibility review.
  - Verified on the iPhone 17e simulator (390×844 pt): self-assessment buttons stack vertically at large Dynamic Type; test-configuration validation message fits; mock-test setup fits.
- [x] Export or back up the final Penpot file locally (`docs/plan/penpot/Screens.penpot`, kept outside git as local backup).

The project has already cleared the low-fidelity design gate for the first slice. The remaining items are final polish, accessibility review, and backup/export before the design phase is formally closed.

## Decisions to Make

- [x] Choose the final typography — **SF system defaults** (`.body`/`.headline`/`.title3` scales), decided 2026-09-10.
- [x] Choose the final color palette — **three themes** (Civic Navy, Paper & Emerald, Study Calm), user-selectable in Settings > Appearance and persisted via `@AppStorage("appThemeName")`. Semantic tokens (`AppPalette`) map per theme with light/dark variants.
- [x] Confirm whether Progress is a permanent tab in the first release — **yes**, permanent.
- [ ] Define the wording for the 65/20 eligibility explanation — draft proposed in `phase-0.5-design-spec.md` ("Decision Drafts"); confirm copy.
- [x] Decide whether audio playback belongs in Phase 1 or Phase 4 — **Phase 4**.
- [ ] Define how current-answer warnings appear without interrupting study — pattern drafted in `phase-0.5-design-spec.md` ("Decision Drafts"); confirm copy and trigger set.

## What to Send Back

Send these items before production UI implementation begins:

1. Penpot project link with view access, or exported design files if sharing a link is not possible.
2. Screenshots or exports of the Navigation and User Flows pages.
3. Screenshots or exports of the low-fidelity wireframes.
4. The selected typography and color palette, including hex values if available.
5. The decisions made from the Decisions to Make section.
6. Any unresolved questions or screens that felt ambiguous.
7. Confirmation that the files were backed up locally.

## Minimum Handoff

The minimum useful handoff is:

- Navigation flow.
- Onboarding flow.
- Flashcard flow.
- Mock test flow.
- Speech fallback flow.
- Wireframes for the eight listed screens.
- Typography and color decisions.
- Open questions.

Do not start production SwiftUI screens until this handoff has been reviewed against `phase-0.5-design-spec.md`.
