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

1. ✅ Done (commit `3e51fde`): `resumeState()` moved to `StudyDomain.resumeFlashcardState(deckStableIDs:currentIndex:attempts:deckQuestions:)`; `StudySession` @Model is now pure persistence with no resume logic.
2. ✅ Added 3–4 thin tests for `StudyDomain`, `QuestionContent`, `TestConfiguration`, `OnboardingConfiguration` — cheap, high-value coverage on the untested core.
3. ✅ Deferred mock-test findings resolved: uniform manual advance removes the "too brief" incorrect feedback; official-answer reveal covers "see the real answer". Added a "Skip this question" defer-to-review affordance for wrong answers (MockTestState.skip() + MockTestResultView skipped section).
4. ⏸️ Deferred, lowest priority (Phase 0.5 closed September 21, 2026): close the accessibility gap (VoiceOver + Dynamic Type via **simulator + UI tests**; no real iPhone available). Code-level audit complete; simulator-based `performAccessibilityAudit()` coverage and Dynamic Type reflow verification via DeviceHub are the target. This item is no longer part of the 0.5 closure. **Detailed how-to below — this is an immediate next task (see `docs/plan/current-status.md`).**

### Item 4 — how to extend `AccessibilityAuditTests` (detailed, for a future session)

**Where.** Everything lives in `SwiftyCitizenUITests/AccessibilityAuditTests.swift`. The skill `skills/xcode27-accessibility/SKILL.md` (+ `references/commands.md`, `references/gotchas.md`) holds the exact `simctl`/`devicectl` commands and the audit snippet — read it first.

**Current state (verified 2026-11-01).** The file already contains:
- `completeOnboardingIfNeeded(_:)` — a **public** helper that automates onboarding so UI tests can reach the tab bar: tap "Set up your test" → toggle the disclaimer switch (`app.switches[\"I understand this is a study aid, not legal advice\"]`) → tap the language cell (button `Study support`, or static text `Choose a language`) then `English` → tap `Save`. Reuse it in every new test.
- `launchAndEnsureHome()` — launches, runs the helper, asserts the Home tab exists.
- Four tests — `testHomeTab`, `testStudyTab`, `testPracticeTab`, `testProgressTab` — each navigates to a tab and calls `try app.performAccessibilityAudit()` (all categories).

So the four **tab landing screens** are covered at **default Dynamic Type / standard contrast**. What is NOT yet covered: deeper sub-screens, max Dynamic Type reflow, increased-contrast mode, and VoiceOver focus order.

**Baseline pass/fail is UNVERIFIED.** On 2026-11-01 the UI-test run failed at the **infrastructure** level (xcodebuild's cloned simulator timed out on its lockdown service; the runner was killed before any test executed). That is not a test failure — see the gotcha below. A future session must first get a clean run before trusting or extending.

#### Step 0 (do FIRST): get a clean UI-test run
Exact symptom of the infra failure (no test actually ran):
```
iOSSimulator: 📱<DVTiPhoneSimulator …, Clone 1 of iPhone 17e, …> unable to connect to "com.apple.instruments.deviceservice.lockdown" - timed out after 120 seconds
SwiftyCitizenUITests-Runner (…) encountered an error (Test crashed with signal kill before establishing connection.)
** TEST FAILED **
```
Workaround, in order:
1. Boot exactly one stable simulator and pin the destination to it (don't let xcodebuild clone a cold device):
   ```bash
   xcrun simctl shutdown all
   xcrun simctl boot A92546BF-B817-4ECA-B936-110C20A3488A   # iPhone 17e
   xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen \
     -destination 'platform=iOS Simulator,id=A92546BF-B817-4ECA-B936-110C20A3488A' \
     -only-testing:SwiftyCitizenUITests/AccessibilityAuditTests
   ```
2. If a `Clone N of iPhone` appears and fails: list and delete stale clones (`xcrun simctl list devices | grep -i clone`, then `xcrun simctl delete <clone-udid>`), ensure only the one stable device is booted, retry.
3. If lockdown stays stuck: on Xcode 27 `killall -9 Simulator` does nothing (the app was renamed). Use Device Hub right-click → "Shut Down" on the device, or restart the CoreSimulator service, then re-boot and retry.
4. Context (skill gotchas): Xcode 26.x broke UI tests + Accessibility Inspector on iOS 26+; this project targets Xcode 27 — assume fixed, but betas shift, so always run before trusting.

#### Step 1: add deeper sub-screen audits
`performAccessibilityAudit()` only sees the **current** screen, so each distinct screen/state needs its own navigate-then-audit. Reuse `completeOnboardingIfNeeded(_:)`. Add one test per screen:
- **Mock-test session:** tab "Practice" → mock-test row (`practiceMockTest`) → "Start mock test" (`mocktestSetupStartMockTest`). Audit the question card + input; then enter a clearly-wrong answer, tap "Record answer" (`mocktestSessionRecordAnswer`), and audit the feedback + reveal + skip state.
- **Flashcard session:** tab "Study" → flashcards entry → audit the question card, the revealed-answer state, and the self-assessment control.
- **Targeted review detail:** tab "Study" → a scope (Due / Unanswered / Needs work) → audit the deck list.
- **Settings / Test configuration:** Settings → audit the form and the inline validation-error state.

#### Step 2: Dynamic Type at max size (reflow)
The code-level contrast audit is done; reflow at max size is not yet tested. Set the size live (no relaunch), then re-audit each key screen for clipping, and screenshot to compare:
```bash
xcrun simctl ui booted content_size extra-extra-extra-large   # largest
# … run the audits / navigate …
xcrun simctl io booted screenshot maxdt.png
xcrun simctl ui booted content_size large                     # reset after
```
In-test you can scope the audit: `try app.performAccessibilityAudit(for: [.dynamicType, .textClipped]) { false }`.

#### Step 3: increased-contrast mode
```bash
xcrun simctl ui booted increase_contrast enabled
# … re-audit .contrast on each screen, screenshot …
xcrun simctl ui booted increase_contrast disabled
```

#### Step 4: VoiceOver — do NOT fake it on the simulator
Per the skill hard rule, VoiceOver is **not reliable on the simulator** (Device Hub's toggle reports doing nothing; the WWDC26 XCTest API is buggy in betas). On the simulator you can only check element detection + descriptions: `try app.performAccessibilityAudit(for: [.elementDetection, .sufficientElementDescription])`. Focus order and live announcement order remain a **real-iPhone-only** check — document it as such; never claim a VoiceOver pass from the simulator.

#### Rules (from the skill)
- One audit per distinct screen/state; navigate first, then audit.
- Never disable a whole category to reach green — filter accepted issues individually in the handler with a comment on why: `performAccessibilityAudit(for: [.contrast]) { issue in /* return true only for a documented, accepted finding */ false }`.
- Contrast ratios: body 4.5:1, large text 3:1.
- Read-only SwiftUI env values (`colorSchemeContrast`, `accessibilityReduceMotion`, …) are ignored at runtime — drive contrast/Dynamic Type through the simulator setting, not `.environment()`.

#### Definition of done for item 4
- [ ] Clean UI-test run achieved (Step 0) with the four existing tab tests green.
- [ ] Sub-screen audits added (mock-test session incl. wrong-answer state, flashcard session, targeted review, settings).
- [ ] Dynamic Type max-size pass (`.dynamicType`/`.textClipped`) on key screens — no clipping.
- [ ] Increased-contrast pass (`.contrast`) on key screens.
- [ ] VoiceOver documented as real-device-only; simulator checks limited to element detection + descriptions.
- [ ] Mark this item ✅ and update `docs/plan/current-status.md`; when all four audit items are done, delete this file per its Lifecycle note.

## Lifecycle

This file is a working note. **Delete it after all four items above are complete**, then fold any durable decisions into `docs/plan/current-status.md` and the relevant `docs/architecture/` document in the same work unit. Item 4 is deferred (simulator-only), so the file stays open until the simulator-based accessibility audit runs or is explicitly retired.
