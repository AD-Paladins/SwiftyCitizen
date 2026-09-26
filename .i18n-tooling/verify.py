#!/usr/bin/env python3
"""Verifica que toda clave de localización referenciada en el Swift del app
exista en el catálogo con valor no vacío. No toca el catálogo ni el código:
solo lee.

Lógica: una literal con punto es una clave de localización salvo que sea un
SF Symbol. Los SF Symbols se detectan por posición (argumentos de icono) o por
ser el valor de un `case`/retorno que NO esté ya en el catálogo — las claves de
localización siempre están en el catálogo, los nombres de icono nunca lo."""
import json, re, pathlib

CATALOG = "SwiftyCitizen/Localizable.xcstrings"
SRC = "SwiftyCitizen"

# Parameters that hold SF Symbol icon names (never localization keys).
ICON_PARAMS = ("systemName", "systemImage", "yourImage", "image")

DOTTED = re.compile(r'"([a-zA-Z][\w.-]+(?:\.[a-zA-Z][\w-]+)+)"')


def load_catalog():
    d = json.load(open(CATALOG, encoding="utf-8"))
    result = {}
    for key, entry in d.get("strings", {}).items():
        try:
            result[key] = entry["localizations"]["en"]["stringUnit"]["value"]
        except KeyError:
            result[key] = None
    return result


def icon_arg_values(text):
    """Dotted-name literals passed directly to an icon parameter, including
    ternaries (systemImage: cond ? "a" : "b"). The slice stops at the next
    comma, closing paren or newline so sibling arguments on the same line
    (image: "x", label: String(localized: "key")) and bare variable
    arguments (systemName: someVar) are never mistaken for symbols."""
    values = []
    param_re = re.compile(r'(?:' + '|'.join(ICON_PARAMS) + r')\s*:')
    for pm in param_re.finditer(text):
        start = pm.end()
        end = len(text)
        for i in range(start, len(text)):
            if text[i] in ",)\n":
                end = i
                break
        values.extend(DOTTED.findall(text[start:end]))
    return values


def switch_icon_values(text):
    """Values returned by `case .x:` switches. A case value is an SF Symbol
    only when it is NOT a localization key — and localization keys are always
    present in the catalog, icon names never are."""
    out = []
    for cm in re.finditer(r'case \.\w+\s*:\s*\n?\s*"([a-zA-Z][\w.-]+(?:\.[a-zA-Z][\w-]+)+)"', text):
        out.append(cm.group(1))
    return out


def main():
    catalog = load_catalog()

    sf_symbols = set()
    used = {}  # dotted literal -> files that reference it
    for path in pathlib.Path(SRC).rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        sf_symbols.update(icon_arg_values(text))
        for v in switch_icon_values(text):
            if v not in catalog:  # case value that is a key stays referenced
                sf_symbols.add(v)
        for m in DOTTED.finditer(text):
            used.setdefault(m.group(1), []).append(path.name)

    missing = [k for k in sorted(used) if k not in catalog and k not in sf_symbols]
    empty = [k for k in sorted(used) if k in catalog and (not catalog[k] or catalog[k].strip() == "")]
    print(f"Claves con punto referenciadas en el Swift: {len(used)}")
    print(f"Claves en el catálogo: {len(catalog)}")
    print(f"SF Symbols detectados (exentos): {len(sf_symbols)}")
    print(f"Fuera de catálogo y no icono (revisar): {len(missing)}")
    for k in missing:
        print("   REVIEW:", k)
    print(f"Vacías (en catálogo sin valor): {len(empty)}")
    for k in empty:
        print("   EMPTY:", k)


if __name__ == "__main__":
    main()
