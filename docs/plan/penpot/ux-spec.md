Te lo dejo en formato lista para Penpot: nombres de boards, textos exactos, tokens y orden visual para cada pantalla, sin inventar reglas de elegibilidad ni lenguaje legal.

## Versión Penpot-ready

### Boards a crear
- HF - Design Tokens
- HF - Welcome
- HF - Test Configuration
- HF - Home Dashboard
- HF - Flashcard Study
- HF - Mock Test Setup
- HF - Mock Test
- HF - Mock Test Result
- HF - Permission Fallback

### Frame base
- 420 x 900
- Mobile-first
- Match the current WF2 iteration, but in high-fidelity styling

---

## 1) Tokens de diseño

### Color palette
- Ink / primary: #0B1F3A
- Navy support: #163F6B
- Warm amber accent: #E7A940
- Success green: #2F7C5D
- Error red: #C94A45
- Warm neutral background: #F5F1EA
- Surface white: #FFFFFF
- Border / divider: #D7CFC5
- Muted text: #587180
- Body text: #243647

### Typography
- Display / hero: 32px, 700
- Section heading: 24px, 700
- Card title: 18px, 700
- Body / content: 16px, 400
- Label / metadata: 14px, 600
- Helper / status: 12px, 600

### Spacing
- 8 / 12 / 16 / 20 / 24 / 32

### Radius
- 14 / 18 / 20 / 24

### Rules
- Minimum touch target: 44x44 pt
- No color-only pass/fail or eligibility state
- Keep text accessible for Dynamic Type
- Avoid clipping question or answer text

---

## 2) Board by board

### HF - Design Tokens
Contenido:
- Title: “SwiftyCitizen tokens”
- Subtitle: “Color, type, and spacing scale”
- Palette swatches with hex labels
- Typography samples by role
- Spacing examples
- Include contrast-safe text labels

---

### HF - Welcome
Layout:
- Full warm neutral background
- Dark navy hero area at top
- Title: “Welcome”
- Body: “Build confidence with a calm, offline study flow for the USCIS civics test.”
- Secondary note: “This app is for study support only and does not determine immigration eligibility.”
- Primary CTA: “Set up your test”

Visual:
- Hero block: #0B1F3A
- CTA button: #E7A940
- Action text: #0B1F3A
- Secondary note in muted gray

---

### HF - Test Configuration
Header:
- “Test configuration”

Sections:
1. Filing date
   - Label: “N-400 filing date”
   - Value: “October 20, 2025”
   - Hint: “This sets the applicable civics rules.”

2. Selected study set
   - Label: “Selected study set”
   - Value: “2025 civics test”
   - Meta: “20 questions • 12 to pass”

3. 65/20 special consideration
   - Label: “65/20 special consideration”
   - Toggle state: off/on

4. Study support
   - Label: “Study support”
   - Value: “English”

5. Study aid notice
   - Title: “Study aid notice”
   - Copy: “This app helps you study. It does not determine legal eligibility.”

Primary CTA:
- “Continue”

Design rule:
- Current rules remain visible before confirmation

---

### HF - Home Dashboard
Top area:
- dark navy top band
- “SwiftyCitizen”
- “Settings” in top-right

Status card:
- “Current test”
- “2025 test”
- “20 questions • 12 to pass”

CTA card:
- “Continue studying”

Today card:
- “Today”
- “12 reviewed”
- “75% correct”

Due next card:
- “Due next”
- “8 questions”
- arrow to the right

Bottom tab nav:
- Home, Study, Practice, Progress
- Home selected with soft neutral fill

---

### HF - Flashcard Study
Header:
- “Close”
- “3 of 20”

Question card:
- Label: “Question 12”
- Question text: “What is the supreme law of the land?”

CTA:
- “Reveal answer”

Below:
- explanatory helper text:
  - “Official answer and answer count are shown after reveal.”

Post-reveal state:
- official answer is the main focus
- self-assessment row:
  - Again
  - Hard
  - Got it

Design rule:
- Keep official answer dominant; source metadata secondary

---

### HF - Mock Test Setup
Title:
- “Mock test”

Summary card:
- “2025 civics test”
- “Up to 20 questions”
- “Need 12 correct to pass”
- “Answer mode: Manual or speech aid”

Options:
- “Manual”
- “Speech aid”

CTA:
- “Start mock test”

---

### HF - Mock Test
Header:
- “Pause”
- “7 of 20”

Prompt card:
- Label: “Question 7”
- Prompt: “Who is the Commander in Chief of the military?”

Answer field:
- “Type your answer”

Actions:
- Primary: “Submit”
- Secondary: “Skip”

Design rule:
- Large enough to remain readable at small viewport and accessible with Dynamic Type

---

### HF - Mock Test Result
Hero card:
- badge: “PASS”
- line: “12 / 20 correct”
- subtext: “This app score is not an official USCIS decision.”

Summary card:
- “Result summary”
- “Passed: 12/20”
- “Needed: 12 correct”

Review card:
- “Missed questions”
- text: “Review 8 missed questions in your study queue.”

Primary CTA:
- “Review missed questions”

---

### HF - Permission Fallback
Title:
- “Speech practice”

Main copy:
- “Microphone access is off.”
- “You can still practice by typing your answer or answering aloud without automatic transcription.”

Actions:
- Primary: “Use manual practice”
- Secondary: “Open Settings”

Warning panel:
- Title: “No automatic transcript”
- Copy: “Speech recognition can be unavailable or denied. The study flow still works without it.”

This must use large text, icon or border, and text labels — not color alone.

---

## 3) Estados por pantalla
Agregar estos estados donde aplique:

- Welcome:
  - default
  - loading (if content check is pending)
- Test Configuration:
  - default
  - validation error
  - 65/20 selected
- Home:
  - empty state
  - progress summary
- Flashcard:
  - question
  - reveal
  - self-assess
- Mock Test Setup:
  - default
  - unavailable speech mode
- Mock Test:
  - active
  - skipped
  - review state
- Result:
  - pass
  - fail
- Permission Fallback:
  - denied
  - unavailable
  - manual fallback

Implemented in code (2026-09-10): states are defined where they apply in the first release. Loading does not apply: the banks are bundled JSON loaded synchronously. Empty: Home (no sessions / all caught up / nothing due), Progress, Flashcard (empty review set), Mock Test (empty bank). Unavailable: Study, Mock Test Setup, Mock Test Session. Error: Test Configuration shows the validation message. Zero-question scope footer in Targeted Review. Speech states (unavailable speech mode, Permission Fallback) remain pending until the speech phase / Phase 4.

---

## 4) Open questions finales
- Exact wording for the 65/20 explanation, before design signoff
- Whether Progress is a tab or a Home destination in the first release
- Whether audio playback stays out of Phase 1 and only in Phase 4

---

## 5) Short diff vs WF2
- Stronger hierarchy and contrast
- Clearer pass/fail, reveal, and fallback states
- More explicit use of typography and spacing
- Better mobile accessibility and touch target sizing
- Current USCIS config remains visible at decision points
- No legal or eligibility claim implied by UI color alone

Si querés, te lo convierto ahora en una versión aún más precisa tipo “spec por pantalla” con:
- texto exacto
- jerarquía tipográfica
- spacing por bloque
- componente por componente
- listo para pasar a Penpot o a SwiftUI.