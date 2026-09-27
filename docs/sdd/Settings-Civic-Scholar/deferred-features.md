# Deferred Features — Settings: Civic Scholar

These rows are **presentation-only placeholders** in the current slice and carry **no backend logic**. They are documented here so a later slice can promote them to real features without re-specifying intent or state.

Source of truth for the shipped slice: `spec.md` and `design.md`.

---

## 1. Theme Palette — "Archive" grouping

**Current state:** Three themes already exist, persisted via `ThemeManager` (`@Observable`) in `UserDefaults` under key `appThemeName`. The Settings screen shows the theme picker.

**Placeholder now:** `AppearanceSection` renders a swatch with an `"Archive"` tag (presentation only; no navigation required).

**When promoted:**
- Decide whether "Archive" is a presentation grouping of previously-used themes or a new theme asset set. If new assets are needed, add them to the theme registry and follow the locked `CivicText` = **SF Pro Rounded** constraint (never bundle Stitch's Plus Jakarta Sans, never touch `Info.plist`).
- State management: continue using `ThemeManager` + `UserDefaults.appThemeName`. No new schema. If a dedicated palette model is introduced, keep it behind `ThemeManager` and migrate the storage key additively (do not refactor existing keys).

---

## 2. Card Text Sizing

**Current state:** None. No font-scale knob exists in the app.

**Placeholder now:** `AppearanceSection` shows a "Card Text Sizing" row with static copy (e.g. "Dignified Large"). No effect on rendering.

**When promoted:**
- Add `ThemeManager.cardTextScale` (enum, e.g. `medium` = 16pt base, `large` = 20pt base) + a `UserDefaults` storage key.
- Apply a **global relative scale factor** via `.environment(.custom)` / a font-scale modifier at the root — NOT an absolute point size, so it stays Dynamic-Type-safe and never clips at the largest accessibility sizes.
- State management: preference-type state → `ThemeManager` + `UserDefaults` (matches `sessionFeedbackEnabled`). No SwiftData model needed.
- Add a unit test asserting the scale mapping and a lower bound guard.

---

## 3. Streak Shield — milestone protection

**Current state:** `StudyProgressMetrics.streak` is a **derivable metric** that counts streak days; it has no persistence and no protection logic. No milestone-loss prevention exists.

**Placeholder now:** `AppearanceSection` shows "Streak Shield — Prevents milestone loss on busy days" with static `"1 active"` copy. No navigation, no behavior.

**When promoted (real feature):**
- New durable user state: a shield `on/off` flag + an expiry date. Decide persistence:
  - Simple on/off + expiry → `ThemeManager`/`UserDefaults` is sufficient.
  - Per-milestone expiry semantics → a new SwiftData `@Model`.
- Behavior: when the shield is active past its expiry, milestone loss is prevented. This must be wired into the existing milestone logic **once that logic exists**; until then the copy must not claim protection that isn't implemented.
- State management: preference/purchase-like state → persist (UserDefaults or new `@Model`), do NOT derive it from attempts.
- Tests (`StreakShieldTests`): assert on/off state and expiry logic (active before expiry, expired after).

---

## Notes for future slices
- All three live inside the composed `AppearanceSection` so they can be promoted or swapped without touching the config editor or reset behavior.
- Keep each promotion additive and keyed; do not refactor existing `ThemeManager` storage.
- Revisit these only when product confirms they are real features, not placeholder rows.
