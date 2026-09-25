#!/usr/bin/env python3
"""Verifica que toda clave con punto usada en el Swift del app exista en el
catálogo con valor no vacío. No toca el catálogo ni el código: solo lee."""
import json, re, pathlib

CATALOG = "SwiftyCitizen/Localizable.xcstrings"
SRC = "SwiftyCitizen"

def load_catalog():
    d = json.load(open(CATALOG, encoding="utf-8"))
    out = {}
    def walk(node):
        if isinstance(node, dict):
            if "stringUnit" in node:
                su = node["stringUnit"]
                val = su.get("value")
                # first non-empty wins (en source)
                if val is not None and val != "":
                    pass
            for v in node.values():
                walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)
    # Simpler: extract every en stringUnit value keyed by position is hard; instead
    # read the raw structure: strings dict -> each entry has localizations.en.stringUnit.value
    strings = d.get("strings", {})
    result = {}
    for key, entry in strings.items():
        val = None
        try:
            val = entry["localizations"]["en"]["stringUnit"]["value"]
        except KeyError:
            pass
        result[key] = val
    return result

def main():
    catalog = load_catalog()
    # Extract every dotted-key literal, then drop SF Symbols (systemImage: values).
    dotted = re.compile(r'"([a-zA-Z][\w.-]+(?:\.[a-zA-Z][\w-]+)+)"')
    sf_symbols = set()
    used = {}
    for path in pathlib.Path(SRC).rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        # SF Symbols: a dotted literal following systemName:/systemImage:
        for m in re.finditer(r'(?:systemName|systemImage):\s*"([a-zA-Z][\w.-]+(?:\.[a-zA-Z][\w-]+)+)"', text):
            sf_symbols.add(m.group(1))
        for m in dotted.finditer(text):
            key = m.group(1)
            used.setdefault(key, []).append(path.name)
    used = {k: v for k, v in used.items() if k not in sf_symbols}

    missing = []
    empty = []
    for key in sorted(used):
        if key not in catalog:
            missing.append(key)
        elif not catalog[key] or catalog[key].strip() == "":
            empty.append(key)

    print(f"Claves con punto referenciadas en el Swift: {len(used)}")
    print(f"Claves en el catálogo: {len(catalog)}")
    print(f"Faltantes (referenciadas, no en catálogo): {len(missing)}")
    for k in missing:
        print("   MISSING:", k)
    print(f"Vacías (en catálogo sin valor): {len(empty)}")
    for k in empty:
        print("   EMPTY:", k)
    # Also: catalog keys never referenced (informational)
    referenced = set(used)
    unused = [k for k in catalog if k not in referenced]
    print(f"Claves en catálogo pero no referenciadas: {len(unused)}")
    for k in sorted(unused)[:40]:
        print("   UNUSED:", k)

if __name__ == "__main__":
    main()
