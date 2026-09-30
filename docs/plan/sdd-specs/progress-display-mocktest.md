# SDD Spec: Progress Display Selectable in MockTestSessionView

## Description
Extender el selector de progreso selectable (contador/barra) que ya existe en `FlashcardSessionView` a `MockTestSessionView`. Esto garantiza consistencia de UX entre los flujos de estudio (flashcards y mock tests) al permitir al usuario ver el progreso de su sesión de estudio sin necesidad de avanzar manualmente.

## Goals
- Que `MockTestSessionView` muestre un indicador de progreso (barra o contador) que refleje el avance de la sesión de estudio.
- Que el diseño sea idéntico al de `FlashcardSessionView` (misma estética, misma integración con `SessionProgressHeader`).
- Que no requiera cambios en el dominio (`StudySession`, `StudyDomain`) ni en la persistencia.

## Acceptance Criteria
- [ ] `MockTestSessionView` tiene un picker segmentado (`.segmented`) para seleccionar el tipo de progreso (contador vs barra).
- [ ] Cuando se selecciona "barra", aparece una `ProgressView` condicional que muestra el avance (ej. "X de Y" o barra lineal).
- [ ] Cuando se selecciona "contador", aparece un contador en la barra superior (como en `FlashcardSessionView`).
- [ ] El texto de progreso se integra con `SessionProgressHeader` (misma key: `studyFlashcardProgressPrefix`).
- [ ] Todos los textos de localización se mantienen en `SwiftyCitizen/Localizable.xcstrings`.
- [ ] Se ejecuta la suite de tests existente (`SwiftyCitizenTests`) sin errores.

## Out of Scope
- No persistir preferencias de progreso (se maneja en memoria de sesión).
- Modificar `StudySession` / `StudyDomain` / SwiftData.
- Crear nuevos tests de UI específicos (los existentes en `MockTestStateTests` son suficientes).
- Cambios en la arquitectura de flujo de estudio (solo añadir selector visual).

## Risks
- Alinear el cálculo de `progressFraction` con el de `FlashcardSessionView` (ambos deben ser 1-based: índice actual / total).
- Evitar colisiones con el layout de la barra de navegación en `MockTestSessionView`.
- Asegurar que la accessibility sea adecuada (VoiceOver ya audita en flashcards).

## Implementation Notes
- Reutilizar `FlashcardHeaderStyle` y `SessionProgressHeader`.
- Usar la misma estructura de picker que en `FlashcardSessionView`.
- El cambio es mínimo (ponytail) — solo añadir estado y UI ligero.
