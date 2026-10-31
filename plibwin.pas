unit PlibWin;

{ Kleine Windows-Helfer fuer das Design (auf anderen Systemen ohne Wirkung):
  - Untermenue eines Hauptmenues als Popup an einer Stelle oeffnen
  - Hauptmenueleiste des Fensters ausblenden (die Eintraege zeigt das Menueband)
  - Titelleiste in den Farben des Designs (Windows 11)
  - Schriftdatei nur fuer PLIB laden }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Menus, Forms, Graphics, Controls, base64;

procedure PopupSubMenu(AForm: TCustomForm; AItem: TMenuItem; AScreenX, AScreenY: Integer);
procedure HideMenuBar(AForm: TCustomForm);
procedure SetCaptionColors(AForm: TCustomForm; ABack, AText: TColor);
function LoadPrivateFont(const AFile: string): Boolean;
{ Passwort fuer das aktuelle Windows-Konto verschluesseln (DPAPI) bzw. entschluesseln.
  Ergebnis Base64; nur derselbe Windows-Benutzer auf demselben Rechner kann es wieder lesen.
  Auf anderen Systemen: ProtectStr liefert '' (nicht verfuegbar), UnprotectStr False. }
function ProtectStr(const S: string): string;
function UnprotectStr(const B64: string; out S: string): Boolean;
{ Statusleiste ohne Windows-Designdarstellung, damit die Hintergrundfarbe gilt }
procedure SetStatusBarBack(ABar: TWinControl; AColor: TColor);
{ Textblock zur Pruefung der Bildschirmschaerfe (DPI-Bewusstsein, Skalierung) }
function DpiInfo(AForm: TCustomForm): string;

implementation

{$IFDEF WINDOWS}
uses
  Windows;

type
  TPlibBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PPlibBlob = ^TPlibBlob;

function PlibCryptProtect(pDataIn: PPlibBlob; szDesc: PWideChar; pEntropy: PPlibBlob;
  pvReserved, pPrompt: Pointer; dwFlags: DWORD; pDataOut: PPlibBlob): BOOL;
  stdcall; external 'crypt32.dll' name 'CryptProtectData';
function PlibCryptUnprotect(pDataIn: PPlibBlob; ppszDesc: Pointer; pEntropy: PPlibBlob;
  pvReserved, pPrompt: Pointer; dwFlags: DWORD; pDataOut: PPlibBlob): BOOL;
  stdcall; external 'crypt32.dll' name 'CryptUnprotectData';

const
  PlibEntropy: string = 'PLIB-Teilebibliothek';
  CRYPTPROTECT_UI_FORBIDDEN = 1;

function ProtectStr(const S: string): string;
var
  InB, OutB, Ent: TPlibBlob;
  Raw: string;
begin
  Result := '';
  if S = '' then Exit;
  InB.cbData := Length(S);
  InB.pbData := PByte(PChar(S));
  Ent.cbData := Length(PlibEntropy);
  Ent.pbData := PByte(PChar(PlibEntropy));
  OutB.cbData := 0;
  OutB.pbData := nil;
  if not PlibCryptProtect(@InB, nil, @Ent, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @OutB) then Exit;
  try
    SetLength(Raw, OutB.cbData);
    if OutB.cbData > 0 then Move(OutB.pbData^, Raw[1], OutB.cbData);
    Result := EncodeStringBase64(Raw);
  finally
    LocalFree(HLOCAL(OutB.pbData));
  end;
end;

function UnprotectStr(const B64: string; out S: string): Boolean;
var
  InB, OutB, Ent: TPlibBlob;
  Raw: string;
begin
  Result := False;
  S := '';
  if B64 = '' then Exit;
  try
    Raw := DecodeStringBase64(B64);
  except
    Exit;
  end;
  if Raw = '' then Exit;
  InB.cbData := Length(Raw);
  InB.pbData := PByte(PChar(Raw));
  Ent.cbData := Length(PlibEntropy);
  Ent.pbData := PByte(PChar(PlibEntropy));
  OutB.cbData := 0;
  OutB.pbData := nil;
  if not PlibCryptUnprotect(@InB, nil, @Ent, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @OutB) then Exit;
  try
    SetLength(S, OutB.cbData);
    if OutB.cbData > 0 then Move(OutB.pbData^, S[1], OutB.cbData);
    // Klartext im Speicher des Systems ueberschreiben, bevor er freigegeben wird
    if OutB.cbData > 0 then FillChar(OutB.pbData^, OutB.cbData, 0);
    Result := True;
  finally
    LocalFree(HLOCAL(OutB.pbData));
  end;
end;

function AddFontResourceExW(lpszFilename: PWideChar; fl: DWORD; pdv: Pointer): LongInt;
  stdcall; external 'gdi32.dll' name 'AddFontResourceExW';

type
  TDwmSet = function(H: HWND; Attr: DWORD; P: Pointer; Size: DWORD): LongInt; stdcall;

{ Sucht den Menueeintrag, dessen Windows-Kennung ID ist. Die Position im Windows-Menue zaehlt
  nur sichtbare Eintraege. }
function FindById(AParent: TMenuItem; AId: UINT): TMenuItem;
var
  I, Pos_: Integer;
  C, F: TMenuItem;
begin
  Result := nil;
  Pos_ := 0;
  for I := 0 to AParent.Count - 1 do
  begin
    C := AParent.Items[I];
    if not C.Visible then Continue;
    if C.Count > 0 then
    begin
      F := FindById(C, AId);
      if F <> nil then
      begin
        Result := F;
        Exit;
      end;
    end
    else if GetMenuItemID(AParent.Handle, Pos_) = AId then
    begin
      Result := C;
      Exit;
    end;
    Inc(Pos_);
  end;
end;

procedure PopupSubMenu(AForm: TCustomForm; AItem: TMenuItem; AScreenX, AScreenY: Integer);
var
  Cmd: UINT;
  Hit: TMenuItem;
begin
  if (AForm = nil) or (AItem = nil) or (AItem.Count = 0) then Exit;
  try
    // Kennung zurueckgeben lassen und den Eintrag selbst ausloesen (die Menueleiste ist ausgeblendet)
    Cmd := UINT(Windows.TrackPopupMenu(AItem.Handle,
      TPM_LEFTALIGN or TPM_TOPALIGN or TPM_LEFTBUTTON or TPM_RETURNCMD,
      AScreenX, AScreenY, 0, AForm.Handle, nil));
    if Cmd = 0 then Exit;
    Hit := FindById(AItem, Cmd);
    if (Hit <> nil) and Hit.Enabled then Hit.Click;
  except
  end;
end;

procedure HideMenuBar(AForm: TCustomForm);
begin
  try
    if AForm.HandleAllocated then Windows.SetMenu(AForm.Handle, 0);
  except
  end;
end;

procedure SetCaptionColors(AForm: TCustomForm; ABack, AText: TColor);
var
  H: THandle;
  F: TDwmSet;
  V: DWORD;
begin
  try
    H := LoadLibrary('dwmapi.dll');
    if H = 0 then Exit;
    F := TDwmSet(GetProcAddress(H, 'DwmSetWindowAttribute'));
    if not Assigned(F) then Exit;
    V := DWORD(ColorToRGB(ABack));
    F(AForm.Handle, 35, @V, SizeOf(V));   // Titelleiste
    F(AForm.Handle, 34, @V, SizeOf(V));   // Rahmen
    V := DWORD(ColorToRGB(AText));
    F(AForm.Handle, 36, @V, SizeOf(V));   // Titeltext
  except
  end;
end;

type
  TSetWinTheme2 = function(H: HWND; Name, List: PWideChar): LongInt; stdcall;

procedure SetStatusBarBack(ABar: TWinControl; AColor: TColor);
var
  H: THandle;
  F: TSetWinTheme2;
begin
  try
    H := LoadLibrary('uxtheme.dll');
    if H <> 0 then
    begin
      F := TSetWinTheme2(GetProcAddress(H, 'SetWindowTheme'));
      if Assigned(F) then F(ABar.Handle, '', '');
    end;
    SendMessage(ABar.Handle, $2001, 0, LPARAM(ColorToRGB(AColor)));   // SB_SETBKCOLOR
  except
  end;
end;

type
  TIsAware = function: BOOL; stdcall;
  TGetDpiWin = function(H: HWND): UINT; stdcall;
  TGetDpiCtx = function: THandle; stdcall;
  TGetAwareCtx = function(H: THandle): Integer; stdcall;

function DpiInfo(AForm: TCustomForm): string;
var
  H: THandle;
  A: TIsAware;
  GW: TGetDpiWin;
  GC: TGetAwareCtx;
  GT: TGetDpiCtx;
  S: string;
begin
  Result := '';
  try
    H := LoadLibrary('user32.dll');
    S := 'unbekannt';
    A := TIsAware(GetProcAddress(H, 'IsProcessDPIAware'));
    if Assigned(A) then
      if A() then S := 'ja' else S := 'NEIN (Windows streckt das Fenster -> unscharf)';
    Result := 'Prozess DPI-bewusst: ' + S + LineEnding;
    GW := TGetDpiWin(GetProcAddress(H, 'GetDpiForWindow'));
    if Assigned(GW) and AForm.HandleAllocated then
      Result := Result + 'DPI dieses Fensters (Windows): ' + IntToStr(GW(AForm.Handle)) + LineEnding;
    GT := TGetDpiCtx(GetProcAddress(H, 'GetThreadDpiAwarenessContext'));
    GC := TGetAwareCtx(GetProcAddress(H, 'GetAwarenessFromDpiAwarenessContext'));
    if Assigned(GT) and Assigned(GC) then
      Result := Result + 'Awareness-Stufe: ' + IntToStr(GC(GT())) +
        ' (0 = keine, 1 = System, 2 = pro Monitor)' + LineEnding;
  except
    on E: Exception do Result := Result + 'Fehler: ' + E.Message + LineEnding;
  end;
end;

function LoadPrivateFont(const AFile: string): Boolean;
var
  W: WideString;
begin
  Result := False;
  try
    W := UTF8Decode(AFile);
    Result := AddFontResourceExW(PWideChar(W), $10, nil) > 0;   // FR_PRIVATE
  except
  end;
end;
{$ELSE}
procedure PopupSubMenu(AForm: TCustomForm; AItem: TMenuItem; AScreenX, AScreenY: Integer);
begin
end;

procedure HideMenuBar(AForm: TCustomForm);
begin
end;

procedure SetCaptionColors(AForm: TCustomForm; ABack, AText: TColor);
begin
end;

function LoadPrivateFont(const AFile: string): Boolean;
begin
  Result := False;
end;

function DpiInfo(AForm: TCustomForm): string;
begin
  Result := '';
end;

procedure SetStatusBarBack(ABar: TWinControl; AColor: TColor);
begin
end;

function ProtectStr(const S: string): string;
begin
  Result := '';
end;

function UnprotectStr(const B64: string; out S: string): Boolean;
begin
  S := '';
  Result := False;
end;

{$ENDIF}

end.
