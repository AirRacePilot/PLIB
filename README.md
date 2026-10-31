# PLIB – Parts Library / Teilebibliothek

[English](#english) · [Deutsch](#deutsch)

---

<a id="english"></a>
## English

PLIB is a Windows desktop application for managing a library of standard and purchased parts. It follows the ideas of the standards ISO 13584 (PLIB) and IEC 61360: parts are organised in classes (part families), classes inherit properties, and every part carries values for these properties.

PLIB is written in Free Pascal with Lazarus.

### Features

- Class tree with inherited properties, parts and property values
- Part search across all classes (<kbd>Ctrl</kbd>+<kbd>F</kbd>), class suggestions and search terms
- Automatic 7-digit part numbers starting at 1000001
- Suppliers, units and identifiers
- Database: SQLite (single user) or PostgreSQL, e.g. on a NAS (several computers)
- Solid Edge integration and CAD catalogues; CAD files are named `Description #PartNumber`
- Plugin interface, including a SolidCraft plugin that generates STEP models (families ZKS, SKS, SKM, USC, LKS, GST, STI)
- Light and dark theme, ribbon bar, sharp rendering on 4K displays, adjustable font size
- Database password protected with Windows DPAPI
- Built-in user manual (<kbd>F1</kbd>)

The user interface and manual are currently in German. An English interface is planned for version 2.x.

### Building from source

1. Install [Lazarus](https://www.lazarus-ide.org/) (64-bit, Windows).
2. Install the Lazarus package **FrameViewer09** (HtmlViewer), e.g. via the Online Package Manager.
3. Open `plib.lpi` in Lazarus and build the project (<kbd>Shift</kbd>+<kbd>F9</kbd>).
4. The program needs the DLLs in the project folder (`sqlite3.dll`, `libpq.dll` and its dependencies) next to `plib.exe`.

The SolidCraft plugin is a separate project: `plugins/solidcraft_step/plib_solidcraft_step.lpi`.

To build the installer, open `plib_setup.iss` in [Inno Setup](https://jrsoftware.org/isinfo.php).

### Project structure

| Path | Content |
|---|---|
| `plib.lpi`, `plib.lpr` | Lazarus project |
| `mainunit.pas/.lfm` | Main window |
| `plib*.pas` | Units: database, search, dialogs, theme, ribbon, icons, helpers |
| `pluginhost.pas` | Plugin interface |
| `plugins/` | Plugins (SolidCraft STEP) |
| `hilfe/`, `plib_hilfe.html` | Help and user manual |
| `PLIB_Erweiterung/` | Python prototype: standard part → SolidCraft → STEP |
| `plib_setup.iss` | Inno Setup installer script |

### License

Copyright © 2026 Frank Mergl

PLIB is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 as published by the Free Software Foundation. It is distributed WITHOUT ANY WARRANTY. See [LICENSE](LICENSE) for details.

Third-party libraries included as DLLs are subject to their own licenses (see [Third-party components](#third-party)).

---

<a id="deutsch"></a>
## Deutsch

PLIB ist ein Windows-Programm zur Verwaltung einer Bibliothek von Norm- und Kaufteilen. Es folgt der Idee der Normenreihe ISO 13584 (PLIB) und IEC 61360: Teile werden in Klassen (Teilefamilien) geordnet, Klassen vererben Merkmale, und jedes Teil trägt Werte für diese Merkmale.

PLIB ist in Free Pascal mit Lazarus geschrieben.

### Funktionen

- Klassenbaum mit vererbten Merkmalen, Teilen und Merkmalswerten
- Teilesuche über alle Klassen (<kbd>Strg</kbd>+<kbd>F</kbd>), Klassenvorschlag und Suchbegriffe
- Automatische 7-stellige Teilenummern ab 1000001
- Lieferanten, Einheiten und Kennungen
- Datenbank: SQLite (Einzelplatz) oder PostgreSQL, z. B. auf einem NAS (mehrere Rechner)
- Solid-Edge-Anbindung und CAD-Kataloge; CAD-Dateien heißen `Beschreibung #Teilenummer`
- Plugin-Schnittstelle, u. a. ein SolidCraft-Plugin, das STEP-Modelle erzeugt (Familien ZKS, SKS, SKM, USC, LKS, GST, STI)
- Helles und dunkles Design, Menüband, scharfe Darstellung auf 4K-Bildschirmen, einstellbare Schriftgröße
- Datenbank-Passwort per Windows-DPAPI geschützt
- Eingebaute Bedienungsanleitung (<kbd>F1</kbd>)

Oberfläche und Anleitung sind derzeit deutsch. Eine englische Oberfläche ist für Version 2.x geplant.

### Aus dem Quelltext bauen

1. [Lazarus](https://www.lazarus-ide.org/) installieren (64 Bit, Windows).
2. Das Lazarus-Paket **FrameViewer09** (HtmlViewer) installieren, z. B. über den Online Package Manager.
3. `plib.lpi` in Lazarus öffnen und das Projekt erstellen (<kbd>Umschalt</kbd>+<kbd>F9</kbd>).
4. Das Programm braucht die DLLs aus dem Projektordner (`sqlite3.dll`, `libpq.dll` und deren Abhängigkeiten) neben der `plib.exe`.

Das SolidCraft-Plugin ist ein eigenes Projekt: `plugins/solidcraft_step/plib_solidcraft_step.lpi`.

Für den Installer `plib_setup.iss` in [Inno Setup](https://jrsoftware.org/isinfo.php) öffnen.

### Projektaufbau

| Pfad | Inhalt |
|---|---|
| `plib.lpi`, `plib.lpr` | Lazarus-Projekt |
| `mainunit.pas/.lfm` | Hauptfenster |
| `plib*.pas` | Units: Datenbank, Suche, Dialoge, Design, Menüband, Symbole, Hilfsfunktionen |
| `pluginhost.pas` | Plugin-Schnittstelle |
| `plugins/` | Plugins (SolidCraft STEP) |
| `hilfe/`, `plib_hilfe.html` | Hilfe und Bedienungsanleitung |
| `PLIB_Erweiterung/` | Python-Prototyp: Normteil → SolidCraft → STEP |
| `plib_setup.iss` | Inno-Setup-Skript für den Installer |

### Lizenz

Copyright © 2026 Frank Mergl

PLIB ist freie Software: Sie darf unter den Bedingungen der GNU General Public License Version 3, veröffentlicht von der Free Software Foundation, weitergegeben und verändert werden. Sie wird OHNE JEDE GEWÄHRLEISTUNG bereitgestellt. Einzelheiten in [LICENSE](LICENSE) (rechtlich verbindlich ist der englische Originaltext).

Mitgelieferte Fremdbibliotheken (DLLs) unterliegen ihren eigenen Lizenzen (siehe [Third-party components](#third-party)).

---

<a id="third-party"></a>
## Third-party components / Fremdkomponenten

| Component | License |
|---|---|
| [SQLite](https://sqlite.org/) (`sqlite3.dll`) | Public Domain |
| [PostgreSQL libpq](https://www.postgresql.org/) (`libpq.dll`) | PostgreSQL License |
| [OpenSSL](https://www.openssl.org/) (`libssl-3-x64.dll`, `libcrypto-3-x64.dll`) | Apache License 2.0 |
| [GNU libiconv](https://www.gnu.org/software/libiconv/) (`libiconv-2.dll`) | LGPL 2.1 or later |
| [GNU gettext libintl](https://www.gnu.org/software/gettext/) (`libintl-9.dll`) | LGPL 2.1 or later |
| [LZ4](https://github.com/lz4/lz4) (`liblz4.dll`) | BSD 2-Clause |
| [Zstandard](https://github.com/facebook/zstd) (`libzstd.dll`) | BSD 3-Clause |
| [MinGW-w64 winpthreads](https://www.mingw-w64.org/) (`libwinpthread-1.dll`) | MIT / BSD |
| [Lazarus LCL](https://www.lazarus-ide.org/) | LGPL with static linking exception |
| [HtmlViewer / FrameViewer09](https://github.com/BerndGabriel/HtmlViewer) | MIT |
