# i18n tooling

Read-only helpers for the localization catalog (`SwiftyCitizen/Localizable.xcstrings`).
Nothing here writes to the catalog or the Swift sources — they only inspect.

## `verify.py`

Checks that every dotted-name localization key referenced in the app's Swift
exists in the catalog with a non-empty value.

### Run it

```sh
python3 docs/i18n-tooling/verify.py
```

The catalog and source paths are resolved relative to the repo root from the
script's own location, so it works from any working directory (run it from the
repo root, or from inside `docs/i18n-tooling/` — same result).

### What it flags

```
Claves con punto referenciadas en el Swift: 33
Claves en el catálogo: 224
SF Symbols detectados (exentos): 32
Fuera de catálogo y no icono (revisar): 1
   REVIEW: info.circle
Vacías (en catálogo sin valor): 0
```

- **Fuera de catálogo y no icono (REVIEW)** — a dotted literal used as a key but
  missing from the catalog and not recognized as an SF Symbol. Inspect each one;
  it's either a real missing key or an icon name the heuristic missed.
- **Vacías (EMPTY)** — a key present in the catalog with an empty/blank value.

### How it decides a key vs. an icon

A string literal with a dot is treated as a localization key unless it looks
like an SF Symbol:

- passed directly to an icon parameter (`systemName`, `systemImage`, `yourImage`,
  `image`), including ternaries like `systemImage: cond ? "a" : "b"`; or
- the value of a `case .x:` switch that is **not** already in the catalog (localization
  keys are always in the catalog; icon names never are).

This is a heuristic, not a guarantee. The REVIEW list is the manual checkpoint —
if a flagged key is actually an icon name, add its parameter to `ICON_PARAMS`
near the top of `verify.py`.

## Files

| File | Purpose |
|------|---------|
| `verify.py` | Detect missing/empty referenced keys (read-only). |
| `referenced-keys.json` | Snapshot of dotted literals found in Swift (reference data). |
| `NOTAS.md` | Session notes from when this tooling was built. |
