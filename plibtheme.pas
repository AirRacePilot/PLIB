unit PlibTheme;

{ Dunkles Design fuer PLIB (Stufe 1): Farben, Schrift, flache Knoepfe.

  Das Design wird nur in dieser Unit angewendet. Aus- und einschalten: plib.ini
    [Ansicht]
    Design=dunkel      (oder: hell = PLIB wie bisher)

  ThemeInit wird einmal beim Start aufgerufen. Danach wird jedes Fenster (Hauptfenster, Dialoge,
  freie Bereiche) beim Anzeigen automatisch eingefaerbt. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, Forms, ExtCtrls, StdCtrls, ComCtrls, Grids,
  Buttons, IniFiles, PlibWin;

{ Liest die Einstellung und schaltet das Design ein (falls "dunkel") }
procedure ThemeInit(const AIniFile: string);

{ Ist das dunkle Design aktiv? }
function ThemeDark: Boolean;

{ Speichert die Einstellung; sie gilt ab dem naechsten Start }
procedure ThemeSave(const AIniFile: string; ADark: Boolean);

type
  TRibbonPalette = record
    Strip, Body, Text, Muted, Accent, Line, Hover, Press, Tile: TColor;
    RowA, RowB, Head, Sel, SelText: TColor;
  end;

{ Farben fuer das Menueband (hell oder dunkel je nach Design) }
procedure ThemeRibbonPalette(out P: TRibbonPalette);

{ Steuerelemente, die ihre Farben zwischengespeichert haben (z. B. das Menueband), melden sich an }
procedure ThemeAddListener(AEvent: TNotifyEvent);
procedure ThemeRemoveListener(AEvent: TNotifyEvent);

{ Schriftgroesse in Punkt (0 = Windows-Vorgabe); die Aenderung wirkt sofort und wird gespeichert }
function ThemeFontSize: Integer;
procedure ThemeSetFontSize(const AIniFile: string; ASize: Integer);

{ Faerbt ein Fenster samt allen Elementen ein (bei hellem Design ohne Wirkung) }
procedure ThemeApplyForm(AForm: TCustomForm);

{ Stellt den Menuemodus (dunkel/hell) fuer Popup-Menues erneut ein }
procedure ThemeMenuMode;

{ Farben fuer eigene Zeichnungen; im hellen Design die bisherigen Werte }
function ThemeTextColor: TColor;      // normaler Text
function ThemeOkColor: TColor;        // freigegeben
function ThemeMutedColor: TColor;     // veraltet / unauffaellig

implementation

{$IFDEF WINDOWS}
uses
  Windows;
{$ENDIF}

type
  THook = class
    procedure FormVisible(Sender: TObject; AForm: TCustomForm);
    procedure StatusDraw(StatusBar: TStatusBar; Panel: TStatusPanel; const ARect: TRect);
  end;

var
  GDark: Boolean = False;
  GHook: THook = nil;
  GPlex: Boolean = False;
  GFontSize: Integer = 0;     // 0 = Windows-Vorgabe
  GListeners: array of TNotifyEvent;

var
  CBg, CPanel, CInput, CText, CMuted, CAccent, CAccentDk, CTitle, CLine, COk: TColor;

procedure InitPalette;
begin
  CBg := RGBToColor(30, 34, 48);
  CPanel := RGBToColor(38, 43, 58);
  CInput := RGBToColor(24, 27, 38);
  CText := RGBToColor(223, 227, 238);
  CMuted := RGBToColor(138, 146, 168);
  CAccent := RGBToColor(61, 139, 253);
  CAccentDk := RGBToColor(38, 92, 178);
  CTitle := RGBToColor(47, 54, 80);
  CLine := RGBToColor(58, 64, 84);
  COk := RGBToColor(120, 205, 130);
end;

function ThemeDark: Boolean;
begin
  Result := GDark;
end;

function ThemeTextColor: TColor;
begin
  if GDark then Result := CText else Result := clWindowText;
end;

function ThemeOkColor: TColor;
begin
  if GDark then Result := COk else Result := TColor($00286E00);
end;

function ThemeMutedColor: TColor;
begin
  if GDark then Result := CMuted else Result := clGray;
end;

{$IFDEF WINDOWS}
type
  TDwmSet = function(H: HWND; Attr: DWORD; P: Pointer; Size: DWORD): LongInt; stdcall;
  TSetWinTheme = function(H: HWND; Name, List: PWideChar): LongInt; stdcall;
  TPrefMode = function(Mode: Integer): Integer; stdcall;
  TFlushMenu = procedure; stdcall;

procedure WinAppMode(AMode: Integer);
var
  H: THandle;
  P: TPrefMode;
  Fl: TFlushMenu;
  I: Integer;
  W: WideString;
begin
  try
    H := LoadLibrary('uxtheme.dll');
    if H = 0 then Exit;
    // Ordinal 135: SetPreferredAppMode (Windows 10 ab 1903); 2 = dunkel erzwingen
    P := TPrefMode(GetProcAddress(H, PChar(PtrUInt(135))));
    if Assigned(P) then P(AMode);
    // Ordinal 136: FlushMenuThemes - bereits gezeichnete Menues sofort neu einfaerben
    Fl := TFlushMenu(GetProcAddress(H, PChar(PtrUInt(136))));
    if Assigned(Fl) then Fl();
    // Windows mitteilen, dass sich das Farbschema geaendert hat (wie beim Umschalten in den
    // Windows-Einstellungen), damit auch Ausklappmenues neu gezeichnet werden
    W := 'ImmersiveColorSet';
    for I := 0 to Screen.FormCount - 1 do
      if Screen.Forms[I].HandleAllocated then
      begin
        SendMessage(Screen.Forms[I].Handle, $001A, 0, LPARAM(PWideChar(W)));  // WM_SETTINGCHANGE
        SendMessage(Screen.Forms[I].Handle, $031A, 0, 0);                    // WM_THEMECHANGED
      end;
    if Assigned(Fl) then Fl();
  except
  end;
end;

procedure WinDarkAppMode;
begin
  WinAppMode(2);
end;

procedure WinDarkTitle(AForm: TCustomForm);
var
  H: THandle;
  F: TDwmSet;
  V: LongInt;
begin
  try
    H := LoadLibrary('dwmapi.dll');
    if H = 0 then Exit;
    F := TDwmSet(GetProcAddress(H, 'DwmSetWindowAttribute'));
    if not Assigned(F) then Exit;
    V := 1;
    if F(AForm.Handle, 20, @V, SizeOf(V)) <> 0 then
      F(AForm.Handle, 19, @V, SizeOf(V));
  except
  end;
end;

procedure WinDarkControl(AControl: TWinControl);
var
  H: THandle;
  F: TSetWinTheme;
begin
  try
    H := LoadLibrary('uxtheme.dll');
    if H = 0 then Exit;
    F := TSetWinTheme(GetProcAddress(H, 'SetWindowTheme'));
    if Assigned(F) then F(AControl.Handle, 'DarkMode_Explorer', nil);
  except
  end;
end;
{$ENDIF}

procedure ThemeControl(C: TControl);
var
  I: Integer;
begin
  { --- Containerarten --- }
  if C is TCustomPanel then
  begin
    if C.Color = TColor($00DCC8B4) then
      C.Color := CTitle            // Titelleiste/Griff der Bereiche (dockunit)
    else if C.Color <> clHighlight then
      C.Color := CPanel;
    C.Font.Color := CText;
  end
  else if C is TCustomLabel then
  begin
    if (C.Font.Color = clGrayText) or (C.Font.Color = clGray) then
      C.Font.Color := CMuted
    else
      C.Font.Color := CText;
  end
  else if C is TCustomEdit then
  begin
    C.Color := CInput;
    C.Font.Color := CText;
  end
  else if C is TCustomComboBox then
  begin
    C.Color := CInput;
    C.Font.Color := CText;
  end
  else if C is TCustomListBox then
  begin
    C.Color := CInput;
    C.Font.Color := CText;
  end
  else if C is TTreeView then
  begin
    C.Color := CInput;
    C.Font.Color := CText;
    // Windows-Themenzeichnung ignoriert die Textfarbe -> unlesbar auf dunklem Grund
    TTreeView(C).Options := TTreeView(C).Options - [tvoThemedDraw];
    TTreeView(C).SelectionColor := CAccentDk;
    TTreeView(C).TreeLineColor := CLine;
  end
  else if C is TCustomListView then
  begin
    C.Color := CInput;
    C.Font.Color := CText;
  end
  else if C is TStringGrid then
  begin
    C.Color := CInput;
    C.Font.Color := CText;
    TStringGrid(C).FixedColor := CTitle;
    TStringGrid(C).GridLineColor := CLine;
    TStringGrid(C).SelectedColor := CAccentDk;
    TStringGrid(C).AlternateColor := CInput;
  end
  else if C is TCustomCheckBox then
    C.Font.Color := CText
  else if C is TCustomGroupBox then
  begin
    C.Color := CPanel;
    C.Font.Color := CText;
  end
  else if C is TScrollBox then
  begin
    C.Color := CPanel;
  end
  else if C is TSplitter then
    C.Color := CLine
  else if C is TStatusBar then
  begin
    // Die Windows-Statusleiste ignoriert die Schriftfarbe: Felder selbst zeichnen
    C.Color := CTitle;
    C.Font.Color := CText;
    if GHook <> nil then
    begin
      for I := 0 to TStatusBar(C).Panels.Count - 1 do
        TStatusBar(C).Panels[I].Style := psOwnerDraw;
      TStatusBar(C).OnDrawPanel := @GHook.StatusDraw;
      SetStatusBarBack(TStatusBar(C), CTitle);
    end;
  end
  else if C is TSpeedButton then
    TSpeedButton(C).Flat := True;

  { --- Windows: dunkle Rollbalken usw. --- }
  {$IFDEF WINDOWS}
  if (C is TTreeView) or (C is TCustomListView) or (C is TStringGrid) or
     (C is TCustomListBox) or (C is TCustomMemo) or (C is TScrollBox) or
     (C is TCustomComboBox) or (C is TButton) then
    WinDarkControl(TWinControl(C));
  {$ENDIF}

  if C is TWinControl then
    for I := 0 to TWinControl(C).ControlCount - 1 do
      ThemeControl(TWinControl(C).Controls[I]);
end;

procedure ThemeAddListener(AEvent: TNotifyEvent);
begin
  SetLength(GListeners, Length(GListeners) + 1);
  GListeners[High(GListeners)] := AEvent;
end;

procedure ThemeRemoveListener(AEvent: TNotifyEvent);
var
  I, J: Integer;
begin
  for I := High(GListeners) downto 0 do
    if (TMethod(GListeners[I]).Code = TMethod(AEvent).Code) and
       (TMethod(GListeners[I]).Data = TMethod(AEvent).Data) then
    begin
      for J := I to High(GListeners) - 1 do
        GListeners[J] := GListeners[J + 1];
      SetLength(GListeners, Length(GListeners) - 1);
    end;
end;

function ThemeFontSize: Integer;
begin
  Result := GFontSize;
end;

procedure ThemeSetFontSize(const AIniFile: string; ASize: Integer);
var
  Ini: TIniFile;
  I: Integer;
begin
  if (ASize <> 0) and ((ASize < 7) or (ASize > 24)) then Exit;
  GFontSize := ASize;
  try
    Ini := TIniFile.Create(AIniFile);
    try
      Ini.WriteInteger('Ansicht', 'Schriftgroesse', ASize);
    finally
      Ini.Free;
    end;
  except
  end;
  for I := 0 to Screen.FormCount - 1 do
    Screen.Forms[I].Font.Size := ASize;
end;

procedure ThemeRibbonPalette(out P: TRibbonPalette);
begin
  if GDark then
  begin
    P.Strip := CBg;
    P.Body := CPanel;
    P.Text := CText;
    P.Muted := CMuted;
    P.Accent := CAccent;
    P.Line := CLine;
    P.Hover := RGBToColor(52, 60, 86);
    P.Press := CAccentDk;
    P.Tile := RGBToColor(226, 231, 242);
    P.RowA := CInput;
    P.RowB := RGBToColor(30, 34, 47);
    P.Head := CTitle;
    P.Sel := CAccentDk;
    P.SelText := RGBToColor(255, 255, 255);
  end
  else
  begin
    P.Strip := RGBToColor(232, 234, 240);
    P.Body := RGBToColor(248, 249, 252);
    P.Text := RGBToColor(30, 34, 48);
    P.Muted := RGBToColor(110, 116, 132);
    P.Accent := RGBToColor(0, 102, 204);
    P.Line := RGBToColor(205, 208, 218);
    P.Hover := RGBToColor(222, 232, 248);
    P.Press := RGBToColor(190, 212, 244);
    P.Tile := RGBToColor(255, 255, 255);
    P.RowA := RGBToColor(255, 255, 255);
    P.RowB := RGBToColor(246, 247, 250);
    P.Head := RGBToColor(232, 234, 240);
    P.Sel := RGBToColor(190, 212, 244);
    P.SelText := RGBToColor(20, 24, 36);
  end;
end;

{ Skaliert ein Dialogfenster samt Inhalt, wenn die Schrift groesser als die Vorgabe (9 pt) ist.
  Die Dialoge sind mit festen Pixelmassen gebaut; ohne Anpassung wird der Text abgeschnitten. }
type
  TCtlAccess = class(TControl);

procedure ScaleDialogControl(C: TControl; Mul, Dv: Integer);
var
  I: Integer;
  Sz: Integer;
begin
  case C.Align of
    alTop, alBottom: C.Height := C.Height * Mul div Dv;
    alLeft, alRight: C.Width := C.Width * Mul div Dv;
    alClient: ;
  else
    C.SetBounds(C.Left * Mul div Dv, C.Top * Mul div Dv,
      C.Width * Mul div Dv, C.Height * Mul div Dv);
  end;
  if not TCtlAccess(C).ParentFont then
  begin
    Sz := C.Font.Size;
    if Sz > 0 then C.Font.Size := Sz * GFontSize div 9;
  end;
  if C is TStringGrid then
  begin
    for I := 0 to TStringGrid(C).ColCount - 1 do
      TStringGrid(C).ColWidths[I] := TStringGrid(C).ColWidths[I] * Mul div Dv;
    TStringGrid(C).DefaultRowHeight := TStringGrid(C).DefaultRowHeight * Mul div Dv;
  end
  else if C is TListView then
    for I := 0 to TListView(C).Columns.Count - 1 do
      TListView(C).Columns[I].Width := TListView(C).Columns[I].Width * Mul div Dv;
  if C is TWinControl then
    for I := 0 to TWinControl(C).ControlCount - 1 do
      if TWinControl(C).Controls[I] <> nil then
        ScaleDialogControl(TWinControl(C).Controls[I], Mul, Dv);
end;

procedure FitDialogToFont(AForm: TCustomForm);
var
  M: TComponent;
  I, Sz, Mul, Dv: Integer;
  Mon: TMonitor;
begin
  Sz := GFontSize;
  if Sz <= 0 then Sz := 9;
  // Layout-Faktor: gewaehlte Schrift in Pixeln / Schrift der Entwurfsgroesse (9 pt bei 96 dpi = 12 px)
  Mul := Sz * Screen.PixelsPerInch;
  Dv := 9 * 96;
  if (Mul <= Dv) or (AForm = Application.MainForm) then Exit;
  if (not (AForm.BorderStyle in [bsDialog, bsSingle, bsToolWindow])) and (AForm.Tag <> 7713) then Exit;
  // Meldungsfenster der LCL (ShowMessage/MessageDlg) bestimmen ihre Groesse selbst
  for I := 0 to AForm.ControlCount - 1 do
    if AForm.Controls[I] is TBitBtn then Exit;
  if AForm.FindComponent('plib_fit') <> nil then Exit;   // nur einmal je Fenster
  M := TComponent.Create(AForm);
  M.Name := 'plib_fit';
  AForm.DisableAutoSizing;
  try
    for I := 0 to AForm.ControlCount - 1 do
      try
        if AForm.Controls[I] <> nil then ScaleDialogControl(AForm.Controls[I], Mul, Dv);
      except
      end;
    AForm.ClientWidth := AForm.ClientWidth * Mul div Dv;
    AForm.ClientHeight := AForm.ClientHeight * Mul div Dv;
  finally
    AForm.EnableAutoSizing;
  end;
  // wieder in die Bildschirmmitte (Monitor kann nil sein, solange das Fenster kein Handle hat)
  try
    Mon := AForm.Monitor;
    if Mon = nil then Mon := Screen.PrimaryMonitor;
    if Mon <> nil then
    begin
      AForm.Left := Mon.WorkareaRect.Left + (Mon.WorkareaRect.Right - Mon.WorkareaRect.Left - AForm.Width) div 2;
      AForm.Top := Mon.WorkareaRect.Top + (Mon.WorkareaRect.Bottom - Mon.WorkareaRect.Top - AForm.Height) div 2;
    end;
  except
  end;
end;

{ TBitBtn (Meldungsfenster der LCL) bleibt im dunklen Design hell; ein normaler Knopf wird dunkel }
procedure ReplaceBitBtns(AForm: TCustomForm);
var
  I: Integer;
  Old: TBitBtn;
  Nw: TButton;
  List: TList;
begin
  if AForm = Application.MainForm then Exit;
  List := TList.Create;
  try
    for I := 0 to AForm.ControlCount - 1 do
      if (AForm.Controls[I] is TBitBtn) and AForm.Controls[I].Visible and
         (AForm.Controls[I].Parent = AForm) then
        List.Add(AForm.Controls[I]);
    for I := 0 to List.Count - 1 do
    begin
      try
      Old := TBitBtn(List[I]);
      Nw := TButton.Create(AForm);
      Nw.Parent := AForm;
      Nw.SetBounds(Old.Left, Old.Top, Old.Width, Old.Height);
      Nw.Caption := Old.Caption;
      Nw.ModalResult := Old.ModalResult;
      Nw.Default := Old.Default;
      Nw.Cancel := Old.Cancel;
      Nw.Anchors := Old.Anchors;
      Nw.TabOrder := Old.TabOrder;
      Nw.OnClick := Old.OnClick;
      Nw.Font.Assign(Old.Font);
      Old.Default := False;
      Old.Cancel := False;
      Old.Visible := False;
      if Nw.Default then AForm.ActiveControl := Nw;
      except
      end;
    end;
  finally
    List.Free;
  end;
end;

procedure ThemeApplyForm(AForm: TCustomForm);
begin
  if AForm = nil then Exit;
  if (GFontSize > 0) and (AForm.Font.Size <> GFontSize) then AForm.Font.Size := GFontSize;
  try
    FitDialogToFont(AForm);
  except
  end;
  if not GDark then Exit;
  try
    AForm.Color := CBg;
    AForm.Font.Color := CText;
    if GPlex or (Screen.Fonts.IndexOf('IBM Plex Sans') >= 0) then
      AForm.Font.Name := 'IBM Plex Sans';
    try
      ReplaceBitBtns(AForm);
    except
    end;
    ThemeControl(AForm);
    {$IFDEF WINDOWS}
    WinDarkTitle(AForm);
    {$ENDIF}
    SetCaptionColors(AForm, CBg, CText);
    AForm.Invalidate;
  except
    // Das Design darf PLIB nie am Starten hindern.
  end;
end;

procedure THook.StatusDraw(StatusBar: TStatusBar; Panel: TStatusPanel; const ARect: TRect);
var
  Cv: TCanvas;
  TH: Integer;
begin
  Cv := StatusBar.Canvas;
  Cv.Font.Assign(StatusBar.Font);
  Cv.Font.Color := CText;
  Cv.Font.Quality := fqCleartype;
  Cv.Brush.Color := CTitle;
  Cv.FillRect(ARect);
  Cv.Pen.Color := CLine;
  Cv.MoveTo(ARect.Right - 1, ARect.Top + 3);
  Cv.LineTo(ARect.Right - 1, ARect.Bottom - 3);
  Cv.Brush.Style := bsClear;
  TH := Cv.TextHeight('Ag');
  Cv.TextRect(ARect, ARect.Left + 8, ARect.Top + (ARect.Bottom - ARect.Top - TH) div 2, Panel.Text);
  Cv.Brush.Style := bsSolid;
end;

procedure THook.FormVisible(Sender: TObject; AForm: TCustomForm);
begin
  if (AForm <> nil) and AForm.Visible then ThemeApplyForm(AForm);
end;

procedure ThemeInit(const AIniFile: string);
var
  Ini: TIniFile;
  S: string;
begin
  InitPalette;
  S := 'dunkel';
  try
    Ini := TIniFile.Create(AIniFile);
    try
      S := LowerCase(Trim(Ini.ReadString('Ansicht', 'Design', 'dunkel')));
      GFontSize := Ini.ReadInteger('Ansicht', 'Schriftgroesse', 10);
      if (GFontSize < 7) or (GFontSize > 24) then GFontSize := 0;
    finally
      Ini.Free;
    end;
  except
  end;
  // Mitgelieferte Schrift (Ordner fonts neben der plib.exe), nur fuer PLIB geladen
  GPlex := LoadPrivateFont(ExtractFilePath(ParamStr(0)) + 'fonts' + PathDelim + 'IBMPlexSans-Regular.ttf');
  if GPlex then
    LoadPrivateFont(ExtractFilePath(ParamStr(0)) + 'fonts' + PathDelim + 'IBMPlexSans-Bold.ttf');
  GDark := S <> 'hell';
  {$IFDEF WINDOWS}
  if not GDark then WinAppMode(3);    // Menues hell erzwingen, auch wenn Windows dunkel eingestellt ist
  {$ENDIF}
  if (not GDark) and (GFontSize = 0) then Exit;
  if GHook = nil then
  begin
    GHook := THook.Create;
    Screen.AddHandlerFormVisibleChanged(@GHook.FormVisible);
  end;
  if not GDark then Exit;
  {$IFDEF WINDOWS}
  WinDarkAppMode;
  {$ENDIF}
  if GHook = nil then
  begin
    GHook := THook.Create;
    Screen.AddHandlerFormVisibleChanged(@GHook.FormVisible);
  end;
end;

procedure ThemeMenuMode;
begin
  {$IFDEF WINDOWS}
  if GDark then WinAppMode(2) else WinAppMode(3);
  {$ENDIF}
end;

procedure ThemeSave(const AIniFile: string; ADark: Boolean);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(AIniFile);
  try
    if ADark then
      Ini.WriteString('Ansicht', 'Design', 'dunkel')
    else
      Ini.WriteString('Ansicht', 'Design', 'hell');
  finally
    Ini.Free;
  end;
end;

end.
