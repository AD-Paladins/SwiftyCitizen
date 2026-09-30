# SDD Design: Progress Display Selectable in MockTestSessionView

## Overview
Extender el selector de progreso (contador en nav bar ↔ barra de progreso lineal) que ya existe en `FlashcardSessionView` a `MockTestSessionView`. El cambio reutiliza `FlashcardHeaderStyle`, `SessionProgressHeader` y las keys de localización existentes, sin tocar dominio ni persistencia.

## Files to Modify

| File | Change |
|------|--------|
| `SwiftyCitizen/Features/Practice/MockTestSessionView.swift` | Agregar `@State headerStyle`, picker segmentado, `ProgressView` condicional, toolbar trailing counter, `progressFraction` computado |
| `docs/architecture/flow-mock-test.md` | Actualizar: anotar que ahora expone selector de progreso (misma regla que flashcards) |
| `docs/plan/current-status.md` | Registrar completado bajo "Completed" con referencia a este change |

## Implementation Details

### 1. MockTestSessionView.swift

**Nuevos state:**
```swift
@State private var headerStyle: FlashcardHeaderStyle = .navBarCounter
```

**Progress fraction (computado, 1-based):**
```swift
private var progressFraction: Double {
    let total = state.maximumQuestionsAsked
    guard total > 0 else { return 0 }
    return Double(min(state.currentIndex + 1, total)) / Double(total)
}
```
*Nota: `state.maximumQuestionsAsked` es el total configurado (p.ej. 20), y `state.currentIndex` es 0-based. `state.progressText` ya devuelve `"\(currentIndex + 1) of \(maximumQuestionsAsked)"`.*

**Picker segmentado (debajo de `SessionProgressHeader`, igual que flashcards):**
```swift
Picker("studyFlashcardHeaderStyle", selection: $headerStyle) {
    ForEach(FlashcardHeaderStyle.allCases, id: \.self) { style in
        Text(style.label).tag(style)
    }
}
.pickerStyle(.segmented)
.padding(.horizontal, 20)
.padding(.top, 12)
```

**ProgressView condicional (solo cuando `.progressBar`):**
```swift
if headerStyle == .progressBar {
    ProgressView(value: progressFraction)
        .progressViewStyle(.linear)
        .tint(palette.primary)
        .accessibilityLabel("studyFlashcardHeaderProgress")
}
```

**Toolbar trailing counter (solo cuando `.navBarCounter`):**
```swift
if headerStyle == .navBarCounter {
    ToolbarItem(placement: .topBarTrailing) {
        Text(state.progressText)
            .font(.headline)
            .monospacedDigit()
            .accessibilityLabel("\(String(localized: "studyFlashcardProgressPrefix"))\(state.progressText)")
    }
}
```

### 2. Localization

Reutilizar keys existentes (ya en `FlashcardSessionView`):
- `studyFlashcardHeaderStyle` — label del picker
- `studyFlashcardHeaderNavBar` — "Nav Bar"
- `studyFlashcardHeaderProgress` — "Progress Bar"
- `studyFlashcardProgressPrefix` — "Progress " (para accessibility)

*Nota: estas keys actualmente no están en `Localizable.xcstrings` pero `String(localized:)` devuelve la key si falta; se añadirán al final del change si faltan.*

### 3. Architecture doc update (`flow-mock-test.md`)

En la tabla de detalles, agregar fila:
| Topic | Decision |
| --- | --- |
| Progress display | Selectable: nav bar counter (default) or linear progress bar, via segmented picker — identical to flashcard session (`FlashcardHeaderStyle`, `SessionProgressHeader`) |

En Checklist, agregar:
- [ ] Mock test session shows selectable progress display (counter / bar) matching flashcards UX.

## Testing

- Ejecutar suite completa: `xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139' -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests`
- No tests nuevos requeridos (cambio visual; `MockTestStateTests` cubre la lógica de progreso).

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| `progressFraction` desalineado con `progressText` | Usar misma fórmula 1-based: `(currentIndex + 1) / maximumQuestionsAsked` |
| Colisión nav bar (título + close + counter) | Flashcards lo usa sin problemas; mock test tiene mismo layout (`navigationTitle("mocktestSessionTitle")` + leading close) |
| Accessibility | Reutiliza key `studyFlashcardHeaderProgress` ya auditada en flashcards |

## Ponytail Notes

- No persistir preferencia (flashcards tampoco lo hace).
- No tocar `MockTestState` ni `StudySession`/`StudyDomain`.
- No nueva localización (keys existentes reutilizables).
- Un solo PR desde rama `feat/progressDisplay-mocktest` (conventional commit).