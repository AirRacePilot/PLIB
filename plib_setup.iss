; Inno Setup Skript fuer PLIB - Teilebibliothek
; Vor dem Compilieren: plib.exe und DLLs liegen im Ordner "dist" (Release-Build), alles andere im Projektordner.
; In Inno Setup oeffnen und mit Strg+F9 compilieren; das Ergebnis liegt in setup\PLIB_Setup_<Version>.exe.
#define AppName "PLIB Teilebibliothek"
; Die Versionsnummer steht nur in version.inc (z. B. '0.8.0'); die Anfuehrungszeichen werden entfernt
#define VerHandle FileOpen("version.inc")
#define VerLine Trim(FileRead(VerHandle))
#expr FileClose(VerHandle)
#define AppVersion Copy(VerLine, 2, Len(VerLine) - 2)
#define AppExe "plib.exe"

[Setup]
AppId={{6B1F2C54-5E0A-4C1B-9D3E-7A4F0B2C9E11}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Frank Mergl
AppCopyright=© 2026 Frank Mergl
VersionInfoVersion={#AppVersion}.0
DefaultDirName={autopf}\PLIB
DefaultGroupName=PLIB
DisableProgramGroupPage=yes
OutputDir=setup
OutputBaseFilename=PLIB_Setup_{#AppVersion}
SetupIconFile=icon\plib.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; PLIB schreibt plib.ini, Datenbank, Sitzung und Fehlerlog neben die plib.exe.
; Deshalb Installation pro Benutzer (landet unter %LOCALAPPDATA%\Programs\PLIB, beschreibbar, ohne Admin).
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "Symbol auf dem Desktop anlegen"; GroupDescription: "Zusätzliche Symbole:"

[Files]
Source: "dist\{#AppExe}"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "hilfe\*"; DestDir: "{app}\hilfe"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "plib_hilfe.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "klassenbilder\*"; DestDir: "{app}\klassenbilder"; Flags: ignoreversion
Source: "modellbau_klassenbaum.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "normteile.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "icon\plib.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "plugins\solidcraft_step\plib_solidcraft_step.exe"; DestDir: "{app}\plugins\solidcraft_step"; Flags: ignoreversion skipifsourcedoesntexist
Source: "plugins\solidcraft_step\plugin.ini"; DestDir: "{app}\plugins\solidcraft_step"; Flags: ignoreversion skipifsourcedoesntexist
Source: "fonts\*"; DestDir: "{app}\fonts"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{autoprograms}\PLIB"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\plib.ico"
Name: "{autoprograms}\PLIB Bedienungsanleitung"; Filename: "{app}\plib_hilfe.html"
Name: "{autodesktop}\PLIB"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\plib.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "PLIB jetzt starten"; Flags: nowait postinstall skipifsilent
