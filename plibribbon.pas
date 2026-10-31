unit PlibRibbon;

{ Menueband (Ribbon) fuer PLIB, Stufe 2.

  Eigenes Steuerelement: Reiter oben, darunter Gruppen mit grossen Knoepfen (Symbol + Text).
  Das Band hat keine eigenen Funktionen: jeder Eintrag ruft den OnClick eines vorhandenen
  Knopfes der alten Knopfleiste auf. Dadurch aendert sich an PLIB selbst nichts.

  Ein- und ausschalten: plib.ini
    [Ansicht]
    Menueband=ja       (nein = alte Knopfleiste)
  Doppelklick auf einen Reiter klappt das Band ein bzw. aus. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, Forms, Buttons, Contnrs, IniFiles, Types, LCLType,
  Menus, PlibTheme, PlibIcons, PlibWin;

type
  TRibbonItem = class
    Caption: string;
    Hint: string;
    Src: TSpeedButton;
    Glyph: TBitmap;
    Hi: TBitmap;          // scharf gezeichnetes Symbol (PlibIcons), erst beim ersten Zeichnen
    Kind: Integer;        // Symbolnummer wie MakeIcon, -1 = unbekannt
    R: TRect;
    destructor Destroy; override;
  end;

  TRibbonGroup = class
    Caption: string;
    Items: TObjectList;
    X0, X1: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TRibbonTab = class
    Caption: string;
    Groups: TObjectList;
    R: TRect;
    constructor Create;
    destructor Destroy; override;
  end;

  TPlibRibbon = class(TCustomControl)
  private
    FTabs: TObjectList;
    FActive: Integer;
    FHotTab: Integer;
    FHotItem: TRibbonItem;
    FDownItem: TRibbonItem;
    FCollapsed: Boolean;
    FTabH, FBodyH, FLineH, FIconSz, FItemW: Integer;
    FPal: TRibbonPalette;
    FMenuSrc: TMainMenu;
    FMenuR: array of TRect;
    FMenuItems: array of TMenuItem;
    FHotMenu: Integer;
    FBarHidden: Boolean;
    procedure SetActive(AValue: Integer);
    procedure UpdateHeight;
    function TabAt(X, Y: Integer): Integer;
    function ItemAt(X, Y: Integer): TRibbonItem;
    procedure LayoutBody;
    procedure LayoutMenus;
    function MenuAt(X, Y: Integer): Integer;
    function MenuCaption(AItem: TMenuItem): string;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure FontChanged(Sender: TObject); override;
    procedure ThemeChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddTab(const ACaption: string): Integer;
    function AddGroup(ATab: Integer; const ACaption: string): Integer;
    procedure AddItem(ATab, AGroup: Integer; const ACaption: string; ASrc: TSpeedButton);
    { Nach dem Fuellen aufrufen: berechnet die Groesse }
    procedure Finish;
    property ActiveTab: Integer read FActive write SetActive;
    { Hauptmenue, dessen Eintraege rechts in der Reiterleiste erscheinen }
    property MenuSource: TMainMenu read FMenuSrc write FMenuSrc;
  end;

function RibbonEnabled(const AIniFile: string): Boolean;
procedure RibbonSave(const AIniFile: string; AOn: Boolean);

implementation

function Sc(V: Integer): Integer;
begin
  Result := (V * Screen.PixelsPerInch + 48) div 96;
end;

{ ---------- Einstellung ---------- }

function RibbonEnabled(const AIniFile: string): Boolean;
var
  Ini: TIniFile;
begin
  Result := True;
  try
    Ini := TIniFile.Create(AIniFile);
    try
      Result := LowerCase(Trim(Ini.ReadString('Ansicht', 'Menueband', 'ja'))) <> 'nein';
    finally
      Ini.Free;
    end;
  except
  end;
end;

procedure RibbonSave(const AIniFile: string; AOn: Boolean);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(AIniFile);
  try
    if AOn then
      Ini.WriteString('Ansicht', 'Menueband', 'ja')
    else
      Ini.WriteString('Ansicht', 'Menueband', 'nein');
  finally
    Ini.Free;
  end;
end;

{ ---------- Modell ---------- }

destructor TRibbonItem.Destroy;
begin
  Glyph.Free;
  Hi.Free;
  inherited Destroy;
end;

constructor TRibbonGroup.Create;
begin
  inherited Create;
  Items := TObjectList.Create(True);
end;

destructor TRibbonGroup.Destroy;
begin
  Items.Free;
  inherited Destroy;
end;

constructor TRibbonTab.Create;
begin
  inherited Create;
  Groups := TObjectList.Create(True);
end;

destructor TRibbonTab.Destroy;
begin
  Groups.Free;
  inherited Destroy;
end;

{ ---------- Steuerelement ---------- }

constructor TPlibRibbon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTabs := TObjectList.Create(True);
  FActive := 0;
  FHotTab := -1;
  FHotMenu := -1;
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := False;   // sonst zeichnet Windows den Text ohne ClearType (unscharf)
  ParentFont := True;
  ShowHint := True;
  Align := alTop;
  ThemeRibbonPalette(FPal);
  ThemeAddListener(@ThemeChanged);
  FItemW := Sc(84);
  FIconSz := 32;
  Height := 100;
end;

destructor TPlibRibbon.Destroy;
begin
  ThemeRemoveListener(@ThemeChanged);
  FTabs.Free;
  inherited Destroy;
end;

function TPlibRibbon.AddTab(const ACaption: string): Integer;
var
  T: TRibbonTab;
begin
  T := TRibbonTab.Create;
  T.Caption := ACaption;
  Result := FTabs.Add(T);
end;

function TPlibRibbon.AddGroup(ATab: Integer; const ACaption: string): Integer;
var
  G: TRibbonGroup;
begin
  G := TRibbonGroup.Create;
  G.Caption := ACaption;
  Result := TRibbonTab(FTabs[ATab]).Groups.Add(G);
end;

procedure TPlibRibbon.AddItem(ATab, AGroup: Integer; const ACaption: string;
  ASrc: TSpeedButton);
var
  It: TRibbonItem;
  P: Integer;
begin
  It := TRibbonItem.Create;
  It.Caption := ACaption;
  It.Src := ASrc;
  It.Kind := ASrc.Tag - 1;
  It.Hint := ASrc.Hint;
  It.Glyph := TBitmap.Create;
  It.Glyph.Assign(ASrc.Glyph);
  It.Glyph.Transparent := True;
  if It.Glyph.Width > FIconSz then FIconSz := It.Glyph.Width;
  P := Pos(LineEnding, It.Hint);
  if P > 0 then
    It.Hint := Copy(It.Hint, 1, P - 1) + ' - ' + Copy(It.Hint, P + Length(LineEnding), MaxInt);
  TRibbonGroup(TRibbonTab(FTabs[ATab]).Groups[AGroup]).Items.Add(It);
end;

procedure TPlibRibbon.Finish;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Font);
    FLineH := Bmp.Canvas.TextHeight('Ag');
  finally
    Bmp.Free;
  end;
  FTabH := FLineH + Sc(14);
  // Symbolkachel + 3 Textzeilen + Gruppenname
  FBodyH := Sc(8) + (Sc(FIconSz) + Sc(10)) + Sc(4) + 3 * FLineH + Sc(6) + FLineH + Sc(6);
  UpdateHeight;
end;

procedure TPlibRibbon.UpdateHeight;
begin
  if FCollapsed then
    Height := FTabH + 1
  else
    Height := FTabH + FBodyH + 1;
  Invalidate;
end;

procedure TPlibRibbon.SetActive(AValue: Integer);
begin
  if (AValue < 0) or (AValue >= FTabs.Count) then Exit;
  FActive := AValue;
  FHotItem := nil;
  FDownItem := nil;
  Invalidate;
end;

{ Berechnet die Rechtecke der Reiter und der Eintraege des aktiven Reiters }
procedure TPlibRibbon.LayoutBody;
var
  I, J, K, X, W, IW, P: Integer;
  Cap, Wd: string;
  T: TRibbonTab;
  G: TRibbonGroup;
  It: TRibbonItem;
begin
  X := 8;
  for I := 0 to FTabs.Count - 1 do
  begin
    T := TRibbonTab(FTabs[I]);
    W := Canvas.TextWidth(T.Caption) + Sc(28);
    T.R := Rect(X, Sc(4), X + W, FTabH);
    Inc(X, W + 2);
  end;
  LayoutMenus;
  if (FActive < 0) or (FActive >= FTabs.Count) then Exit;
  T := TRibbonTab(FTabs[FActive]);
  X := 8;
  for J := 0 to T.Groups.Count - 1 do
  begin
    G := TRibbonGroup(T.Groups[J]);
    G.X0 := X;
    for K := 0 to G.Items.Count - 1 do
    begin
      It := TRibbonItem(G.Items[K]);
      // Breite: mindestens Standard, bei langem Wort breiter (kein abgeschnittener Text)
      IW := FItemW;
      Cap := StringReplace(It.Caption, LineEnding, ' ', [rfReplaceAll]);
      while Cap <> '' do
      begin
        P := Pos(' ', Cap);
        if P = 0 then
        begin
          Wd := Cap;
          Cap := '';
        end
        else
        begin
          Wd := Copy(Cap, 1, P - 1);
          Delete(Cap, 1, P);
        end;
        if Canvas.TextWidth(Wd) + Sc(12) > IW then IW := Canvas.TextWidth(Wd) + Sc(12);
      end;
      It.R := Rect(X, FTabH + 8, X + IW, FTabH + FBodyH - FLineH - 12);
      Inc(X, IW + 2);
    end;
    G.X1 := X + 4;
    X := G.X1 + 6;
  end;
end;

function TPlibRibbon.MenuCaption(AItem: TMenuItem): string;
begin
  Result := StringReplace(AItem.Caption, '&', '', [rfReplaceAll]);
end;

{ Die Eintraege des Hauptmenues rechts in der Reiterleiste, soweit Platz ist }
procedure TPlibRibbon.LayoutMenus;
var
  I, N, X, W, TabsEnd: Integer;
  It: TMenuItem;
begin
  SetLength(FMenuR, 0);
  SetLength(FMenuItems, 0);
  if FMenuSrc = nil then Exit;
  TabsEnd := 8;
  if FTabs.Count > 0 then TabsEnd := TRibbonTab(FTabs[FTabs.Count - 1]).R.Right + 16;
  N := 0;
  for I := 0 to FMenuSrc.Items.Count - 1 do
    if FMenuSrc.Items[I].Visible then Inc(N);
  SetLength(FMenuR, N);
  SetLength(FMenuItems, N);
  // von rechts nach links anordnen
  X := Width - 8;
  N := N - 1;
  for I := FMenuSrc.Items.Count - 1 downto 0 do
  begin
    It := FMenuSrc.Items[I];
    if not It.Visible then Continue;
    W := Canvas.TextWidth(MenuCaption(It)) + Sc(20);
    FMenuItems[N] := It;
    FMenuR[N] := Rect(X - W, Sc(4), X, FTabH);
    Dec(X, W);
    Dec(N);
  end;
  // passt nicht alles neben die Reiter: die linken Eintraege weglassen
  for I := 0 to High(FMenuR) do
    if FMenuR[I].Left < TabsEnd then FMenuR[I] := Rect(-1, -1, -1, -1);
end;

function TPlibRibbon.MenuAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FMenuR) do
    if PtInRect(FMenuR[I], Point(X, Y)) then
    begin
      Result := I;
      Exit;
    end;
end;

function TPlibRibbon.TabAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FTabs.Count - 1 do
    if PtInRect(TRibbonTab(FTabs[I]).R, Point(X, Y)) then
    begin
      Result := I;
      Exit;
    end;
end;

function TPlibRibbon.ItemAt(X, Y: Integer): TRibbonItem;
var
  J, K: Integer;
  T: TRibbonTab;
  G: TRibbonGroup;
  It: TRibbonItem;
begin
  Result := nil;
  if FCollapsed or (FActive < 0) or (FActive >= FTabs.Count) then Exit;
  T := TRibbonTab(FTabs[FActive]);
  for J := 0 to T.Groups.Count - 1 do
  begin
    G := TRibbonGroup(T.Groups[J]);
    for K := 0 to G.Items.Count - 1 do
    begin
      It := TRibbonItem(G.Items[K]);
      if PtInRect(It.R, Point(X, Y)) then
      begin
        Result := It;
        Exit;
      end;
    end;
  end;
end;

procedure TPlibRibbon.Paint;
var
  I, J, K, TX, TY, Sz, GW, GH: Integer;
  T: TRibbonTab;
  G: TRibbonGroup;
  It: TRibbonItem;
  Tile, TextR: TRect;
  Ts: TTextStyle;
  Hot, Down: Boolean;
begin
  Canvas.Font.Assign(Font);
  Canvas.Font.Quality := fqCleartype;
  if (not FBarHidden) and (FMenuSrc <> nil) then
  begin
    FBarHidden := True;
    HideMenuBar(GetParentForm(Self));   // die Menueleiste ersetzt das Band
  end;
  LayoutBody;
  with Canvas do
  begin
    Brush.Style := bsSolid;
    Pen.Style := psSolid;
    // Reiterleiste
    Brush.Color := FPal.Strip;
    FillRect(0, 0, Width, FTabH + 1);
    // Reiter
    for I := 0 to FTabs.Count - 1 do
    begin
      T := TRibbonTab(FTabs[I]);
      if I = FActive then
      begin
        Brush.Color := FPal.Body;
        Pen.Style := psClear;
        FillRect(T.R.Left, T.R.Top, T.R.Right, T.R.Bottom + 1);
        Pen.Style := psSolid;
        Pen.Color := FPal.Accent;
        Pen.Width := 2;
        MoveTo(T.R.Left, T.R.Top + 1);
        LineTo(T.R.Right, T.R.Top + 1);
        Pen.Width := 1;
        Font.Color := FPal.Text;
        Font.Style := [fsBold];
      end
      else
      begin
        if I = FHotTab then
        begin
          Brush.Color := FPal.Hover;
          FillRect(T.R.Left, T.R.Top, T.R.Right, T.R.Bottom);
        end;
        Font.Color := FPal.Muted;
        Font.Style := [];
      end;
      Brush.Style := bsClear;
      TX := T.R.Left + (T.R.Right - T.R.Left - TextWidth(T.Caption)) div 2;
      TY := T.R.Top + (T.R.Bottom - T.R.Top - TextHeight(T.Caption)) div 2 + 1;
      TextOut(TX, TY, T.Caption);
      Brush.Style := bsSolid;
    end;
    Font.Style := [];
    // Hauptmenue (rechts in der Reiterleiste)
    for I := 0 to High(FMenuR) do
    begin
      if FMenuR[I].Left < 0 then Continue;
      if I = FHotMenu then
      begin
        Brush.Color := FPal.Hover;
        FillRect(FMenuR[I].Left, FMenuR[I].Top, FMenuR[I].Right, FMenuR[I].Bottom);
        Font.Color := FPal.Text;
      end
      else
        Font.Color := FPal.Muted;
      Brush.Style := bsClear;
      TX := FMenuR[I].Left + (FMenuR[I].Right - FMenuR[I].Left - TextWidth(MenuCaption(FMenuItems[I]))) div 2;
      TY := FMenuR[I].Top + (FMenuR[I].Bottom - FMenuR[I].Top - TextHeight('Ag')) div 2 + 1;
      TextOut(TX, TY, MenuCaption(FMenuItems[I]));
      Brush.Style := bsSolid;
    end;
    // Rumpf
    if FCollapsed then
    begin
      Pen.Color := FPal.Line;
      MoveTo(0, FTabH);
      LineTo(Width, FTabH);
      Exit;
    end;
    Brush.Color := FPal.Body;
    FillRect(0, FTabH, Width, Height);
    Pen.Color := FPal.Line;
    MoveTo(0, FTabH);
    LineTo(Width, FTabH);
    MoveTo(0, Height - 1);
    LineTo(Width, Height - 1);
  end;

  if (FActive < 0) or (FActive >= FTabs.Count) then Exit;
  T := TRibbonTab(FTabs[FActive]);
  Sz := Sc(FIconSz) + Sc(10);
  for J := 0 to T.Groups.Count - 1 do
  begin
    G := TRibbonGroup(T.Groups[J]);
    for K := 0 to G.Items.Count - 1 do
    begin
      It := TRibbonItem(G.Items[K]);
      Hot := It = FHotItem;
      Down := Hot and (It = FDownItem);
      with Canvas do
      begin
        if It.Src.Enabled and (Hot or Down) then
        begin
          if Down then Brush.Color := FPal.Press else Brush.Color := FPal.Hover;
          Pen.Style := psClear;
          RoundRect(It.R.Left, It.R.Top, It.R.Right, It.R.Bottom, 8, 8);
          Pen.Style := psSolid;
        end;
        // Symbolkachel
        Tile := Rect(It.R.Left + (It.R.Right - It.R.Left - Sz) div 2, It.R.Top + 4,
          It.R.Left + (It.R.Right - It.R.Left - Sz) div 2 + Sz, It.R.Top + 4 + Sz);
        Brush.Color := FPal.Tile;
        Pen.Style := psClear;
        RoundRect(Tile.Left, Tile.Top, Tile.Right, Tile.Bottom, 8, 8);
        Pen.Style := psSolid;
        if (It.Hi = nil) and (It.Kind >= 0) then
        begin
          try
            It.Hi := MakeIconAA(It.Kind, Sc(FIconSz), FPal.Tile);
          except
            FreeAndNil(It.Hi);
          end;
        end;
        if It.Hi <> nil then
        begin
          Draw(Tile.Left + (Sz - It.Hi.Width) div 2, Tile.Top + (Sz - It.Hi.Height) div 2, It.Hi);
          GW := 0;
        end
        else
          GW := Sc(It.Glyph.Width);
        GH := Sc(It.Glyph.Height);
        if GW = 0 then
          // schon gezeichnet
        else if GW = It.Glyph.Width then
          Draw(Tile.Left + (Sz - GW) div 2, Tile.Top + (Sz - GH) div 2, It.Glyph)
        else
          StretchDraw(Rect(Tile.Left + (Sz - GW) div 2, Tile.Top + (Sz - GH) div 2,
            Tile.Left + (Sz - GW) div 2 + GW, Tile.Top + (Sz - GH) div 2 + GH), It.Glyph);
        // Text (mehrzeilig, zentriert)
        TextR := Rect(It.R.Left + 2, Tile.Bottom + 4, It.R.Right - 2, It.R.Bottom);
        Brush.Style := bsClear;
        if It.Src.Enabled then Font.Color := FPal.Text else Font.Color := FPal.Muted;
        Ts := TextStyle;
        Ts.Wordbreak := True;
        Ts.SingleLine := False;
        Ts.Alignment := taCenter;
        Ts.Layout := tlTop;
        Ts.Clipping := True;
        TextStyle := Ts;
        TextRect(TextR, TextR.Left, TextR.Top, It.Caption);
        Brush.Style := bsSolid;
      end;
    end;
    // Gruppenname und Trennlinie
    with Canvas do
    begin
      Brush.Style := bsClear;
      Font.Color := FPal.Muted;
      TX := G.X0 + (G.X1 - G.X0 - TextWidth(G.Caption)) div 2;
      if TX < G.X0 then TX := G.X0;
      TextOut(TX, FTabH + FBodyH - FLineH - 6, G.Caption);
      Brush.Style := bsSolid;
      Pen.Color := FPal.Line;
      MoveTo(G.X1 + 2, FTabH + 8);
      LineTo(G.X1 + 2, FTabH + FBodyH - 6);
    end;
  end;
end;

procedure TPlibRibbon.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Ti, Mi: Integer;
  Pt: TPoint;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then Exit;
  Mi := MenuAt(X, Y);
  if Mi >= 0 then
  begin
    MouseCapture := False;
    Pt := ClientToScreen(Point(FMenuR[Mi].Left, FMenuR[Mi].Bottom));
    ThemeMenuMode;
    PopupSubMenu(GetParentForm(Self), FMenuItems[Mi], Pt.X, Pt.Y);
    Exit;
  end;
  Ti := TabAt(X, Y);
  if Ti >= 0 then
  begin
    if ssDouble in Shift then
      FCollapsed := not FCollapsed
    else if FCollapsed then
      FCollapsed := False;
    SetActive(Ti);
    UpdateHeight;
    Exit;
  end;
  FDownItem := ItemAt(X, Y);
  Invalidate;
end;

procedure TPlibRibbon.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  It: TRibbonItem;
  Ti, Mi: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  Ti := TabAt(X, Y);
  It := ItemAt(X, Y);
  Mi := MenuAt(X, Y);
  if (Ti <> FHotTab) or (It <> FHotItem) or (Mi <> FHotMenu) then
  begin
    FHotMenu := Mi;
    FHotTab := Ti;
    FHotItem := It;
    if It <> nil then Hint := It.Hint else Hint := '';
    Application.CancelHint;
    Invalidate;
  end;
end;

procedure TPlibRibbon.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  It, Down: TRibbonItem;
begin
  inherited MouseUp(Button, Shift, X, Y);
  Down := FDownItem;
  FDownItem := nil;
  Invalidate;
  if (Button <> mbLeft) or (Down = nil) then Exit;
  It := ItemAt(X, Y);
  if (It = Down) and Down.Src.Enabled then Down.Src.Click;
end;

procedure TPlibRibbon.FontChanged(Sender: TObject);
begin
  inherited FontChanged(Sender);
  if FTabs.Count > 0 then Finish;    // Zeilenhoehe und Bandhoehe neu berechnen
end;

{ Design wurde umgeschaltet: Farben und Symbole neu }
procedure TPlibRibbon.ThemeChanged(Sender: TObject);
var
  I, J, K: Integer;
  G: TRibbonGroup;
begin
  ThemeRibbonPalette(FPal);
  for I := 0 to FTabs.Count - 1 do
    for J := 0 to TRibbonTab(FTabs[I]).Groups.Count - 1 do
    begin
      G := TRibbonGroup(TRibbonTab(FTabs[I]).Groups[J]);
      for K := 0 to G.Items.Count - 1 do
        FreeAndNil(TRibbonItem(G.Items[K]).Hi);
    end;
  Invalidate;
end;

procedure TPlibRibbon.MouseLeave;
begin
  inherited MouseLeave;
  if (FHotTab <> -1) or (FHotItem <> nil) or (FHotMenu <> -1) then
  begin
    FHotMenu := -1;
    FHotTab := -1;
    FHotItem := nil;
    FDownItem := nil;
    Invalidate;
  end;
end;

end.
