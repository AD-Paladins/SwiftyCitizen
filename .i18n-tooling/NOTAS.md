# Memoria de sesión — i18n SwiftyCitizen (localización de cadenas)

**Estado:** trabajo en progreso. El usuario perdió confianza porque el catálogo
`Localizable.xcstrings` quedó con claves mal formadas / vacías. Se va a REINICIAR
el trabajo desde un commit limpio.

## Qué hicimos (chronology)
1. Exploración de i18n → decisión: opción 2, claves manuales `screen.feature.element`,
   inglés primero, español en sub-ronda posterior. Strings de dominio (nombres de
   versión/idioma/tema) se dejan inline en archivos Foundation (regla acordada).
2. Slice Home ya commiteado aparte como `5b156d9` "feat(i18n): localize Home screen".
3. Batches A–D: localizar Practice/MockTest, Study, Progress, Settings,
   Configuration, App. Todo en una rama `feat/i18n-localization` (base origin/main).

## EL BUG RAÍZ (lo importante)
El generador `/tmp/localize.py` (ahora en `.i18n-tooling/localize.py`) al principio
escribía entradas **mal formadas**: ponía `stringUnit` en la raíz de la entrada en vez
de dentro de `localizations.en.stringUnit.value`. Xcode no leía el valor → claves
vacías o "mal formadas" en el editor.

Estructura CORRECTA que debe producir el generador:
```json
"key": {
  "localizations": {
    "en": {
      "stringUnit": { "state": "new", "value": "Texto inglés" }
    }
  }
}
```
(Nota: usar `"state": "new"` para el idioma fuente, NO "translated".)

Commiteado roto = `6bde1a6`. El working tree llegó a estar correcto tras reejecutar,
pero Xcode podía mostrar caché vieja y el usuario seguía viendo roto.

## Evidencia clave (verificada con scripts, no a ciegas)
- Escaneo riguroso de claves referenciadas en el código (quitando SF Symbols por
  `systemName:`/`systemImage:`): las claves reales SÍ tienen valor; las "faltantes"
  eran SF Symbols (no son claves).
- Defecto real fuera del patrón de puntos: `Official answer` en
  `Shared/UI/Components.swift:34` (texto duro, no clave).
- Cadenas en inglés que NO deben localizarse ahora: nombres de dominio
  (`English`, `Spanish study support`, `2008/2025 civics test`, `65/20 special
  consideration`, `Civic Navy`, `Paper & Emerald`, `Study Calm`), internos/símbolos
  (`uscis-2008`, `json`, interpolaciones `\(streak)`), y los 5 tips del Home por
  confirmar.

## Scripts / artefactos guardados (en el repo, NO en /tmp)
- `.i18n-tooling/localize.py` — generador (con fix de estructura).
- `.i18n-tooling/committed-6bde1a6.xcstrings` — catálogo commiteado roto (referencia).
- `.i18n-tooling/working-tree-current.xcstrings` — último working tree.
- `.i18n-tooling/referenced-keys.json` — claves reales referenciadas por el código.

## DECISIÓN tomada por el usuario
Reiniciar desde commit limpio (origin/main) donde todos los textos están en las vistas,
y rehacer la localización con un generador correcto. Si vuelve a fallar: no insistir,
volver al commit anterior con los textos originales.

## Comandos verificados (Xcode 27, iOS 27, sim iPhone 17e id 9CC72DE8-...)
- Build: `xcodebuild build -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139'`
- Tests: `xcodebuild test -project SwiftyCitizen.xcodeproj -scheme SwiftyCitizen -destination 'platform=iOS Simulator,id=9CC72DE8-ED58-4D07-B736-C9B4B6750139' -parallel-testing-enabled NO -only-testing:SwiftyCitizenTests`

## Pendiente
- Reiniciar catálogo + vistas desde origin/main.
- Generador correcto → reconstruir catálogo completo.
- Verificar en disco: cada clave referenciada tiene valor no vacío (0 vacías).
- Localizar restantes cadenas de vistas (tabs, feedback, Components, tips) si el usuario confirma alcance.
- Commit único + push + PR (instrucción original del usuario).
