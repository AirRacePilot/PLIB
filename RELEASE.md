# Neue Version veröffentlichen

Die Versionsnummer steht nur in **`version.inc`** (z. B. `'0.8.1'`, mit Anführungszeichen).
Programm, Installer und Update-Prüfung lesen sie von dort.

## Ablauf

1. **Nummer erhöhen:** `version.inc` ändern (z. B. `'0.8.0'` → `'0.8.1'`).
2. **Release-Build** in Lazarus (Modus *Release*, ohne Debug-Info), dann die neue `plib.exe` nach `dist\` kopieren (dort liegen auch die DLLs). Bilder, Hilfe, Icon und Plugin liegen im Projektordner.
3. **Installer bauen:** `plib_setup.iss` mit Inno Setup übersetzen. Ergebnis: `setup\PLIB_Setup_<Version>.exe`.
4. **Testen:** Installer auf einem Rechner ausführen, Programm starten, Hilfe → *Über …* zeigt die neue Nummer.
5. **Änderungen speichern:** `git add .`, `git commit -m "PLIB <Version>"`, `git push`.
6. **Release auf GitHub:** *Releases → Draft a new release*, Tag `v<Version>` (z. B. `v0.8.1`), Beschreibung = „Was ist neu“, den Installer als Datei anhängen, veröffentlichen.
7. **Update für Testrechner (Textdatei-Quelle):** `update.txt` und den Installer in den Update-Ordner auf dem NAS legen:

       Version=0.8.1
       Download=PLIB_Setup_0.8.1.exe
       Hinweis=Was ist neu|Zweite Zeile

## Update-Quelle in `plib.ini`

    [Update]
    Quelle=\\NAS\Freigabe\PLIB_Update\update.txt
    AutoPruefen=1

- Leere `Quelle` = GitHub-Releases (funktioniert nur bei öffentlichem Repository).
- `AutoPruefen=0` schaltet die Prüfung beim Start ab.
- Die Prüfung vergleicht Zahlen: `0.8.10` ist neuer als `0.8.9`.

## Nicht ins Repository

`plib.ini` (Serveradresse, Benutzer, Passwort) und `plib.sqlite3` stehen in der `.gitignore`.
Eine Vorlage ohne persönliche Daten: `plib.ini.beispiel`.
