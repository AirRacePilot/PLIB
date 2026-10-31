#!/usr/bin/env python3
"""Normteil -> SolidCraft-Skript (JSON) -> STEP.

Baut das Teil direkt in der obersten Ebene (kein Bauteil/keine Baugruppe), damit Solid Edge
die STEP-Datei ohne Rueckfrage als Einzelteil oeffnet.

Aufruf:
  normteil_step.py <familie> <groesse> [laenge] --out datei.step [--cli pfad/solidcraft-cli]
Familien: socket_head_cap_screw (DIN 912), hex_bolt (DIN 933), hex_nut (DIN 934), washer (DIN 125)

Masse: ISO-Tabellen aus der SolidCraft-Bibliothek (ISO 4762, 4017, 4032, 7089).
Abweichende DIN-Werte koennen in OVERRIDES eingetragen werden.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

# Gewinde: Groesse -> Nenndurchmesser
D = {"M2": 2.0, "M2.5": 2.5, "M3": 3.0, "M4": 4.0, "M5": 5.0, "M6": 6.0, "M8": 8.0, "M10": 10.0,
     "M12": 12.0, "M14": 14.0, "M16": 16.0, "M20": 20.0, "M24": 24.0, "M30": 30.0}

# ISO 4762 (DIN 912): Kopfdurchmesser dk, Kopfhoehe k, Schluesselweite s, Tiefe t
SHCS = {"M2": (3.8, 2.0, 1.5, 1.0), "M2.5": (4.5, 2.5, 2.0, 1.1), "M3": (5.5, 3.0, 2.5, 1.3),
        "M4": (7.0, 4.0, 3.0, 2.0), "M5": (8.5, 5.0, 4.0, 2.5), "M6": (10.0, 6.0, 5.0, 3.0),
        "M8": (13.0, 8.0, 6.0, 4.0), "M10": (16.0, 10.0, 8.0, 5.0), "M12": (18.0, 12.0, 10.0, 6.0),
        "M14": (21.0, 14.0, 12.0, 7.0), "M16": (24.0, 16.0, 14.0, 8.0), "M20": (30.0, 20.0, 17.0, 10.0),
        "M24": (36.0, 24.0, 19.0, 12.0), "M30": (45.0, 30.0, 22.0, 15.5)}

# ISO 4017 (DIN 933): Schluesselweite s, Kopfhoehe k
HEX_BOLT = {"M2": (4.0, 1.4), "M2.5": (5.0, 1.7), "M3": (5.5, 2.0), "M4": (7.0, 2.8), "M5": (8.0, 3.5),
            "M6": (10.0, 4.0), "M8": (13.0, 5.3), "M10": (16.0, 6.4), "M12": (18.0, 7.5),
            "M14": (21.0, 8.8), "M16": (24.0, 10.0), "M20": (30.0, 12.5), "M24": (36.0, 15.0),
            "M30": (46.0, 18.7)}

# ISO 4032 (DIN 934): Schluesselweite s, Hoehe m
HEX_NUT = {"M2": (4.0, 1.6), "M2.5": (5.0, 2.0), "M3": (5.5, 2.4), "M4": (7.0, 3.2), "M5": (8.0, 4.7),
           "M6": (10.0, 5.2), "M8": (13.0, 6.8), "M10": (16.0, 8.4), "M12": (18.0, 10.8),
           "M14": (21.0, 12.8), "M16": (24.0, 14.8), "M20": (30.0, 18.0), "M24": (36.0, 21.5),
           "M30": (46.0, 25.6)}

# ISO 7089 (DIN 125): Innen-, Aussendurchmesser, Dicke
WASHER = {"M2": (2.2, 5.0, 0.3), "M2.5": (2.7, 6.0, 0.5), "M3": (3.2, 7.0, 0.5), "M4": (4.3, 9.0, 0.8),
          "M5": (5.3, 10.0, 1.0), "M6": (6.4, 12.0, 1.6), "M8": (8.4, 16.0, 1.6), "M10": (10.5, 20.0, 2.0),
          "M12": (13.0, 24.0, 2.5), "M14": (15.0, 28.0, 2.5), "M16": (17.0, 30.0, 3.0),
          "M20": (21.0, 37.0, 3.0), "M24": (25.0, 44.0, 4.0), "M30": (31.0, 56.0, 4.0)}

# Hier eigene DIN-Werte eintragen, z. B. OVERRIDES[("hex_bolt", "M10")] = (17.0, 6.4)
OVERRIDES = {}


def cmd(name, **params):
    return {"command": name, "params": params}


def hex_prism(af, z0, z1, op):
    dist, direction = (z1 - z0, "positive") if z1 >= z0 else (z0 - z1, "negative")
    return [
        cmd("sketch.create", plane="XY", offset=f"{z0} mm"),
        cmd("sketch.polygon.circumscribed", center=[0, 0], radius=af / 2.0, sides=6),
        cmd("sketch.finish"),
        cmd("solid.extrude", distance=f"{dist} mm", direction=direction, operation=op),
    ]


def revolved(points_rz, op):
    pts = [[r, -z] for r, z in points_rz]  # Skizze auf XZ: y = -z
    return [
        cmd("sketch.create", plane="XZ"),
        cmd("sketch.line", points=pts, closed=True),
        cmd("sketch.finish"),
        cmd("solid.revolve", axis="y", operation=op),
    ]


def default_length(d):
    for l in (4, 5, 6, 8, 10, 12, 16, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 80, 90, 100):
        if l >= 2.5 * d:
            return float(l)
    return 100.0


def lookup(table, family, size):
    if (family, size) in OVERRIDES:
        return OVERRIDES[(family, size)]
    if size not in table:
        raise SystemExit(f"Groesse {size} nicht in der Tabelle fuer {family}")
    return table[size]


def build(family, size, length=None):
    d = D.get(size)
    if d is None:
        raise SystemExit(f"Unbekannte Groesse {size}")
    if family == "socket_head_cap_screw":
        dk, k, s, t = lookup(SHCS, family, size)
        n = length or default_length(d)
        c = revolved([(0, -n), (d / 2, -n), (d / 2, 0), (dk / 2, 0), (dk / 2, k), (0, k)], "new")
        return c + hex_prism(s, k, k - t, "cut")
    if family == "hex_bolt":
        s, k = lookup(HEX_BOLT, family, size)
        n = length or default_length(d)
        c = hex_prism(s, 0.0, k, "new")
        return c + revolved([(0, -n), (d / 2, -n), (d / 2, k / 2), (0, k / 2)], "join")
    if family == "hex_nut":
        s, m = lookup(HEX_NUT, family, size)
        c = hex_prism(s, 0.0, m, "new")
        c.append(cmd("solid.cylinder", diameter=f"{d} mm", height=f"{m + 2} mm", base=[0, 0, -1],
                     axis=[0, 0, 1], operation="cut"))
        return c
    if family == "washer":
        di, do, h = lookup(WASHER, family, size)
        return revolved([(di / 2, 0), (do / 2, 0), (do / 2, h), (di / 2, h)], "new")
    raise SystemExit(f"Unbekannte Familie {family}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("family")
    ap.add_argument("size")
    ap.add_argument("length", nargs="?", type=float)
    ap.add_argument("--out", required=True)
    ap.add_argument("--cli", default="solidcraft-cli")
    ap.add_argument("--keep-script", help="Skript (JSON) zusaetzlich hier speichern")
    a = ap.parse_args()

    script = {"commands": build(a.family, a.size, a.length)}
    if a.keep_script:
        with open(a.keep_script, "w") as f:
            json.dump(script, f, indent=1)
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(script, f)
        path = f.name
    try:
        r = subprocess.run([a.cli, "run", path, "--out", a.out, "--quiet"], capture_output=True, text=True)
    finally:
        os.unlink(path)
    if r.returncode != 0:
        sys.stderr.write(r.stderr or r.stdout)
        sys.exit(r.returncode)
    print(f"OK: {a.out}")


if __name__ == "__main__":
    main()
