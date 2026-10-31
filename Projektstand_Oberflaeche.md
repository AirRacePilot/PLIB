# PLIB - Stand (2026-10-31), Version 0.8.0

## Fertig
- Dunkles/helles Design (Neustart beim Umschalten), Menüband, scharfe Darstellung (4K), Schriftgröße-Menü
- Dialoge und Meldungen passen sich der Schriftgröße an; Suchleiste der Anleitung größer
- Sicherheit: DB-Passwort per Windows-DPAPI, ZIP-/Plugin-Prüfungen
- Plugin SolidCraft (STEP): Familien ZKS, SKS, SKM, USC, LKS, GST, STI
- Automatische 7-stellige Teilenummer ab 1000001; alte Nummern nur intern (Spalte alt_nr); Spalte "Nr" in der Teileliste ausgeblendet
- Hilfe (hilfe\hilfe.html) und Bedienungsanleitung (plib_hilfe.html) aktualisiert

- Rechtsklick auf Tabellenüberschriften: Spalten ein-/ausblenden (Teileliste je Klasse, Teilesuche global)
- CAD-Dateien heißen "Beschreibung #Teilenummer"
- Code aufgeteilt (Stand 1.1): plibutil (Hilfsfunktionen), plibdialogs (Eingabedialoge), plibdb (Datenbankzugriff, DbCtx), plibsearch (Teilesuche), plibicons (alle Symbole). Als Nächstes geplant: Solid-Edge-Anbindung, Import/Export in eigene Units

## Noch zu tun (Anwender)
- Alte Teilenummern umstellen: teilenummern_umstellen.sql in pgAdmin (Datenbank plib) ausführen, vorher Backup; oder in PLIB "Teile -> Alte Teilenummern auf 7-stellig umstellen"
- Installer bauen: plib_setup.iss (Projektordner) in Inno Setup öffnen, Strg+F9 -> setup\PLIB_Setup_<Version>.exe (Version steht in version.inc; plib.exe und DLLs aus dist\)
- Optional: Schrift IBM Plex Sans (TTF) in den Ordner fonts im Projektordner legen

## Später
- Englische Oberfläche und englische Anleitung (Version 2.x), Funktion T('...') + sprache_en.txt
- Optionale Prüfung der Teilenummer ohne Groß/Kleinschreibung

## Aufräumen
_zum_loeschen\ enthält Aussortiertes (alte dist-Stände, alte Installer, Zwischensicherungen); kann gelöscht werden.
backup\quelltext_1.1_20261030 ist der vollständige Quelltextstand von Version 1.1.
Offen für später: Teilenummern-Vergabe für mehrere gleichzeitige PostgreSQL-Benutzer über einen Zähler (Sequence) in der Datenbank.
