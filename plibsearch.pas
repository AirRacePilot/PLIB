unit PlibSearch;

{ Teilesuche: eigenes Fenster, sucht direkt in der Datenbank (Suchwoerter, Hersteller,
  Klasse, bis zu drei Merkmalfilter mit Vergleich und Einheit).

  Die Trefferliste ist eine Tabelle im Stil der Teileliste. Rechtsklick auf eine
  Ueberschrift blendet Spalten aus und ein (gespeichert in plib.ini, [Spalten] SucheAus);
  Linksklick auf eine Ueberschrift sortiert.

  Das Hauptfenster wird nur ueber TPartSearchHost angesprochen.
  (Ausgelagert aus mainunit.pas, Stand 1.1) }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Forms, Controls, StdCtrls, ExtCtrls, Grids, Menus, Graphics, LCLType,
  Clipbrd, IniFiles, SQLDB, PlibDb, PlibUtil, PlibViews;

type
  { Was die Teilesuche vom Hauptfenster braucht }
  TPartSearchHost = record
    Owner: TCustomForm;                                         // Hauptfenster
    CurClass: function: Int64 of object;                        // gewaehlte Klasse im Baum
    ShowPart: procedure(AClass, APart: Int64) of object;        // Teil im Hauptfenster zeigen
    OpenCad: TNotifyEvent;                                      // CAD-Datei des Teils oeffnen
    OpenLink: TNotifyEvent;                                     // CAD-Katalog-Link oeffnen
    Status: procedure(const AMsg: string) of object;            // Statuszeile
  end;

{ Oeffnet die Teilesuche (oder holt das offene Fenster nach vorne) }
procedure ShowPartSearch(const AHost: TPartSearchHost);

implementation

const
  BaseCols = 6;                 // feste Spalten; danach 3 Spalten fuer die Merkmalfilter
  ColTitles: array[0..BaseCols - 1] of string = ('Teilenummer', 'Beschreibung', 'Klasse',
    'Klassen-Nr.', 'Hersteller', 'Lieferant');
  SortCols: array[0..BaseCols - 1] of string = ('pt.part_number', 'pt.description', 'c.name',
    'c.class_no', 'pt.manufacturer', 's.name');
  OpCodes: array[0..5] of string = ('=', '>=', '<=', '>', '<', ':');
  OpTxt: array[0..5] of string = ('=', '>=', '<=', '>', '<', 'enthält');
  MaxHits = 500;

type
  TPartSearchForm = class(TForm)
  private
    FHost: TPartSearchHost;
    Ed, Manu: TEdit;
    ClsChk, AllChk: TCheckBox;
    Grid: TStringGrid;
    Info: TLabel;
    Pop, PopHead: TPopupMenu;
    Timer: TTimer;
    FProp, FOp: array[0..2] of TComboBox;
    FVal: array[0..2] of TEdit;
    PropIds, HitIds, HitCls: array of Int64;
    SortCol: Integer;
    SortDesc: Boolean;
    Hidden: TStringList;        // ausgeblendete feste Spalten (Ueberschriften)
    procedure BuildUi(ANames: TStrings);
    procedure LoadHidden;
    procedure SaveHidden;
    procedure AutoSizeCols;
    function SelIndex: Integer;
    function TermCond(const ATerm: string): string;
    function FilterCond(AProp: Int64; const AOp, AVal: string): string;
    procedure RunNow;
    procedure SearchChanged(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure Go(Sender: TObject);
    procedure DoOpenCad(Sender: TObject);
    procedure DoOpenLink(Sender: TObject);
    procedure CopyNo(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure HeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure GridDblClick(Sender: TObject);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure GridContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure HeadHide(Sender: TObject);
    procedure HeadToggle(Sender: TObject);
    procedure HeadShowAll(Sender: TObject);
    procedure SetHidden(const AName: string; AHide: Boolean);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyDown2(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose2(Sender: TObject; var CloseAction: TCloseAction);
  public
    constructor CreateSearch(const AHost: TPartSearchHost; ANames: TStrings;
      const AIds: array of Int64);
    destructor Destroy; override;
  end;

var
  GSearch: TPartSearchForm = nil;

{ ---------- Aufbau ---------- }

constructor TPartSearchForm.CreateSearch(const AHost: TPartSearchHost; ANames: TStrings;
  const AIds: array of Int64);
var
  I: Integer;
begin
  inherited CreateNew(Application);
  FHost := AHost;
  SetLength(PropIds, Length(AIds));
  for I := 0 to High(AIds) do PropIds[I] := AIds[I];
  Hidden := TStringList.Create;
  Hidden.CaseSensitive := False;
  LoadHidden;
  SortCol := -1;
  SortDesc := False;
  BuildUi(ANames);
end;

destructor TPartSearchForm.Destroy;
begin
  if GSearch = Self then GSearch := nil;
  Hidden.Free;
  inherited Destroy;
end;

procedure TPartSearchForm.BuildUi(ANames: TStrings);
var
  PT, PB: TPanel;
  Lb: TLabel;
  Bt: TButton;
  K, J: Integer;
  Mi: TMenuItem;

  procedure AddPop(const ACaption: string; AClick: TNotifyEvent);
  begin
    Mi := TMenuItem.Create(Pop);
    Mi.Caption := ACaption;
    Mi.OnClick := AClick;
    Pop.Items.Add(Mi);
  end;

begin
  Caption := 'Teilesuche';
  Tag := 7713;   // Layout wird bei grosser Schrift mitskaliert (FitDialogToFont)
  Position := poScreenCenter;
  Width := 1040;
  Height := 660;
  if FHost.Owner <> nil then
  begin
    PopupMode := pmExplicit;
    PopupParent := FHost.Owner;
  end;
  KeyPreview := True;
  OnKeyDown := @FormKeyDown2;
  OnClose := @FormClose2;

  PT := TPanel.Create(Self);
  PT.Parent := Self;
  PT.Align := alTop;
  PT.Height := 208;
  PT.BevelOuter := bvNone;
  PT.Caption := '';

  Lb := TLabel.Create(Self);
  Lb.Parent := PT;
  Lb.SetBounds(12, 16, 70, 20);
  Lb.Caption := 'Suchen:';
  Ed := TEdit.Create(Self);
  Ed.Parent := PT;
  Ed.SetBounds(90, 10, 540, 26);
  Ed.TextHint := 'Teilenummer, Beschreibung, Hersteller, Klasse, Merkmalwerte ...';
  ClsChk := TCheckBox.Create(Self);
  ClsChk.Parent := PT;
  ClsChk.SetBounds(650, 12, 360, 22);
  ClsChk.Caption := 'nur in der gewählten Klasse (mit Unterklassen)';

  Lb := TLabel.Create(Self);
  Lb.Parent := PT;
  Lb.SetBounds(12, 88, 600, 20);
  Lb.Font.Style := [fsBold];
  Lb.Caption := 'Merkmalfilter (optional):';
  Lb := TLabel.Create(Self);
  Lb.Parent := PT;
  Lb.SetBounds(12, 52, 75, 20);
  Lb.Caption := 'Hersteller:';
  Manu := TEdit.Create(Self);
  Manu.Parent := PT;
  Manu.SetBounds(90, 46, 210, 26);
  AllChk := TCheckBox.Create(Self);
  AllChk.Parent := PT;
  AllChk.SetBounds(320, 48, 400, 22);
  AllChk.Caption := 'alle Wörter müssen passen (sonst weich suchen)';
  AllChk.Checked := True;
  for K := 0 to 2 do
  begin
    FProp[K] := TComboBox.Create(Self);
    FProp[K].Parent := PT;
    FProp[K].Style := csDropDownList;
    FProp[K].SetBounds(90, 112 + K * 30, 300, 26);
    FProp[K].Items.Assign(ANames);
    FProp[K].ItemIndex := 0;
    FOp[K] := TComboBox.Create(Self);
    FOp[K].Parent := PT;
    FOp[K].Style := csDropDownList;
    FOp[K].SetBounds(400, 112 + K * 30, 90, 26);
    for J := 0 to 5 do FOp[K].Items.Add(OpTxt[J]);
    FOp[K].ItemIndex := 0;
    FVal[K] := TEdit.Create(Self);
    FVal[K].Parent := PT;
    FVal[K].SetBounds(500, 112 + K * 30, 190, 26);
  end;
  Lb := TLabel.Create(Self);
  Lb.Parent := PT;
  Lb.SetBounds(700, 114, 320, 60);
  Lb.WordWrap := True;
  Lb.Font.Color := clGrayText;
  Lb.Caption := 'Zahlen mit Einheit gehen auch, z. B. "<= 40mm" oder ">= 0,04m". ' +
    'Ohne Wert zeigt PLIB nur die Spalte des Merkmals.';
  Bt := TButton.Create(Self);
  Bt.Parent := PT;
  Bt.SetBounds(700, 172, 140, 28);
  Bt.Caption := 'Zurücksetzen';
  Bt.OnClick := @ResetClick;

  PB := TPanel.Create(Self);
  PB.Parent := Self;
  PB.Align := alBottom;
  PB.Height := 28;
  PB.BevelOuter := bvNone;
  PB.Caption := '';
  Info := TLabel.Create(Self);
  Info.Parent := PB;
  Info.SetBounds(10, 6, 900, 18);
  Info.Caption := 'Suchwort eingeben oder ein Merkmal mit Wert wählen. ' +
    'Rechtsklick auf eine Überschrift: Spalten ein-/ausblenden.';

  Grid := TStringGrid.Create(Self);
  Grid.Parent := Self;
  Grid.Align := alClient;
  Grid.FixedCols := 0;
  Grid.FixedRows := 1;
  Grid.RowCount := 1;
  Grid.ColCount := BaseCols + 3;
  Grid.Options := [goFixedHorzLine, goHorzLine, goRowSelect, goColSizing, goThumbTracking,
    goSmoothScroll];
  for K := 0 to BaseCols - 1 do Grid.Cells[K, 0] := ColTitles[K];
  StyleGrid(Grid);
  Grid.OnHeaderClick := @HeaderClick;
  Grid.OnDblClick := @GridDblClick;
  Grid.OnMouseDown := @GridMouseDown;
  Grid.OnContextPopup := @GridContextPopup;
  Grid.OnKeyDown := @GridKeyDown;

  Pop := TPopupMenu.Create(Self);
  AddPop('Im Hauptfenster anzeigen', @Go);
  AddPop('In Solid Edge öffnen', @DoOpenCad);
  AddPop('CAD-Katalog-Link öffnen', @DoOpenLink);
  AddPop('Teilenummer kopieren', @CopyNo);
  Grid.PopupMenu := Pop;
  PopHead := TPopupMenu.Create(Self);

  Timer := TTimer.Create(Self);
  Timer.Enabled := False;
  Timer.Interval := 350;
  Timer.OnTimer := @TimerTick;

  Ed.OnChange := @SearchChanged;
  Ed.OnKeyDown := @EditKeyDown;
  ClsChk.OnClick := @SearchChanged;
  AllChk.OnClick := @SearchChanged;
  Manu.OnChange := @SearchChanged;
  Manu.OnKeyDown := @EditKeyDown;
  for K := 0 to 2 do
  begin
    FProp[K].OnChange := @SearchChanged;
    FOp[K].OnChange := @SearchChanged;
    FVal[K].OnChange := @SearchChanged;
    FVal[K].OnKeyDown := @EditKeyDown;
  end;
  ActiveControl := Ed;
end;

{ ---------- Spalten: Breite, ein-/ausblenden ---------- }

procedure TPartSearchForm.LoadHidden;
var
  Ini: TIniFile;
begin
  Hidden.Clear;
  try
    Ini := TIniFile.Create(IniName);
    try
      SplitBar(Ini.ReadString('Spalten', 'SucheAus', ''), Hidden);
    finally
      Ini.Free;
    end;
  except
  end;
end;

procedure TPartSearchForm.SaveHidden;
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(IniName);
    try
      Ini.WriteString('Spalten', 'SucheAus', JoinBar(Hidden));
    finally
      Ini.Free;
    end;
  except
  end;
end;

{ Spaltenbreite nach Inhalt (erste 200 Zeilen), Zeilenhoehe nach Schrift; ausgeblendete
  Spalten und leere Merkmalspalten bekommen Breite 0 }
procedure TPartSearchForm.AutoSizeCols;
var
  C, R, W, TW, Lim, MaxW, H: Integer;
begin
  if Grid = nil then Exit;
  Grid.Canvas.Font.Assign(Grid.Font);
  H := Grid.Canvas.TextHeight('Ag');
  if H < 8 then H := 15;
  Grid.DefaultRowHeight := H * 17 div 10;
  Grid.RowHeights[0] := H * 2;
  MaxW := Grid.Canvas.TextWidth('0') * 60;
  Lim := Grid.RowCount - 1;
  if Lim > 200 then Lim := 200;
  for C := 0 to Grid.ColCount - 1 do
  begin
    if (Grid.Cells[C, 0] = '') or ((C < BaseCols) and (Hidden.IndexOf(Grid.Cells[C, 0]) >= 0)) then
    begin
      Grid.ColWidths[C] := 0;
      Continue;
    end;
    Grid.Canvas.Font.Style := [fsBold];
    W := Grid.Canvas.TextWidth(Grid.Cells[C, 0]) + H * 2;
    Grid.Canvas.Font.Style := [];
    for R := 1 to Lim do
    begin
      TW := Grid.Canvas.TextWidth(Grid.Cells[C, R]) + H + H div 2;
      if TW > W then W := TW;
    end;
    if W > MaxW then W := MaxW;
    Grid.ColWidths[C] := W;
  end;
end;

procedure TPartSearchForm.SetHidden(const AName: string; AHide: Boolean);
var
  I, Vis: Integer;
begin
  if AHide then
  begin
    Vis := 0;
    for I := 0 to Grid.ColCount - 1 do
      if (Grid.ColWidths[I] > 0) and (not SameText(Grid.Cells[I, 0], AName)) then Inc(Vis);
    if Vis = 0 then
    begin
      Info.Caption := 'Die letzte sichtbare Spalte bleibt stehen.';
      Exit;
    end;
    if Hidden.IndexOf(AName) < 0 then Hidden.Add(AName);
  end
  else
  begin
    I := Hidden.IndexOf(AName);
    if I >= 0 then Hidden.Delete(I);
  end;
  SaveHidden;
  AutoSizeCols;
end;

procedure TPartSearchForm.HeadHide(Sender: TObject);
begin
  SetHidden((Sender as TMenuItem).Hint, True);
end;

procedure TPartSearchForm.HeadToggle(Sender: TObject);
var
  Mi: TMenuItem;
begin
  Mi := Sender as TMenuItem;
  SetHidden(Mi.Hint, Mi.Checked);   // war angehakt: jetzt ausblenden; sonst einblenden
end;

procedure TPartSearchForm.HeadShowAll(Sender: TObject);
begin
  Hidden.Clear;
  SaveHidden;
  AutoSizeCols;
end;

procedure TPartSearchForm.GridContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  C, R, I: Integer;
  Nm: string;
  Mi: TMenuItem;
  Pt: TPoint;
begin
  if (MousePos.X < 0) or (MousePos.Y < 0) then Exit;   // Kontextmenue-Taste: Zeilenmenue
  Grid.MouseToCell(MousePos.X, MousePos.Y, C, R);
  if R <> 0 then Exit;                                  // Datenzeilen: Zeilenmenue
  Handled := True;
  PopHead.Items.Clear;
  if (C >= 0) and (C < BaseCols) then
  begin
    Nm := Grid.Cells[C, 0];
    Mi := TMenuItem.Create(PopHead);
    Mi.Caption := 'Spalte "' + Nm + '" ausblenden';
    Mi.Hint := Nm;
    Mi.OnClick := @HeadHide;
    PopHead.Items.Add(Mi);
    Mi := TMenuItem.Create(PopHead);
    Mi.Caption := '-';
    PopHead.Items.Add(Mi);
  end;
  for I := 0 to BaseCols - 1 do
  begin
    Mi := TMenuItem.Create(PopHead);
    Mi.Caption := ColTitles[I];
    Mi.Hint := ColTitles[I];
    Mi.Checked := Hidden.IndexOf(ColTitles[I]) < 0;
    Mi.OnClick := @HeadToggle;
    PopHead.Items.Add(Mi);
  end;
  Mi := TMenuItem.Create(PopHead);
  Mi.Caption := '-';
  PopHead.Items.Add(Mi);
  Mi := TMenuItem.Create(PopHead);
  Mi.Caption := 'Alle Spalten anzeigen';
  Mi.OnClick := @HeadShowAll;
  PopHead.Items.Add(Mi);
  Pt := Grid.ClientToScreen(MousePos);
  PopHead.PopUp(Pt.X, Pt.Y);
end;

{ ---------- Suche ---------- }

function TPartSearchForm.TermCond(const ATerm: string): string;
var
  Alts: TStrArr;
  I: Integer;
  X, Lop, One: string;
begin
  Alts := TermAlts(ATerm);
  Result := '';
  if DbCtx.IsPg then Lop := ' ILIKE ' else Lop := ' LIKE ';
  for I := 0 to High(Alts) do
  begin
    X := Lop + QuotedStr('%' + LikeEsc(Alts[I]) + '%') + ' ESCAPE ''\''';
    One := '(pt.part_number' + X +
      ' OR COALESCE(pt.description,'''')' + X +
      ' OR COALESCE(pt.manufacturer,'''')' + X +
      ' OR c.name' + X +
      ' OR c.code' + X +
      ' OR COALESCE(c.class_no,'''')' + X +
      ' OR COALESCE(s.name,'''')' + X +
      ' OR EXISTS(SELECT 1 FROM part_value pv LEFT JOIN enum_value e ON ' +
      'e.property_id=pv.property_id AND e.code=pv.value WHERE pv.part_id=pt.id AND ' +
      '(pv.value' + X + ' OR e.name' + X + '))' +
      ' OR EXISTS(SELECT 1 FROM search_term st WHERE st.class_id=c.id AND st.term' + X + '))';
    if Result <> '' then Result := Result + ' OR ';
    Result := Result + One;
  end;
  Result := '(' + Result + ')';
end;

function TPartSearchForm.FilterCond(AProp: Int64; const AOp, AVal: string): string;
var
  Num, B, Fac, Sh: Double;
  UnitCode, Qty, NumX, Lop, V, Cond, Pre, LeftX, CmpS, TextEq, Lk: string;
begin
  V := Trim(AVal);
  if DbCtx.IsPg then
    NumX := 'CASE WHEN pv.value ~ ''^-?[0-9]+([.,][0-9]+)?$'' THEN ' +
      'CAST(REPLACE(pv.value, '','', ''.'') AS DOUBLE PRECISION) END'
  else
    NumX := 'CASE WHEN TRIM(pv.value)<>'''' AND ' +
      'REPLACE(REPLACE(REPLACE(pv.value,''.'',''''),'','',''''),''-'','''') ' +
      'NOT GLOB ''*[^0-9]*'' THEN CAST(REPLACE(pv.value, '','', ''.'') AS REAL) END';
  if DbCtx.IsPg then Lop := ' ILIKE ' else Lop := ' LIKE ';
  Lk := Lop + QuotedStr('%' + LikeEsc(V) + '%') + ' ESCAPE ''\''';
  TextEq := '(UPPER(pv.value)=UPPER(' + QuotedStr(V) + ') OR UPPER(COALESCE(e.name,''''))=UPPER(' +
    QuotedStr(V) + '))';
  if AOp = ':' then
    Cond := '(pv.value' + Lk + ' OR e.name' + Lk + ')'
  else if not ParseNumUnit(V, Num, UnitCode) then
  begin
    if AOp = '=' then Cond := TextEq else Cond := '1=0';
  end
  else
  begin
    Pre := '';
    B := Num;
    LeftX := '(' + NumX + ')';
    Cond := '';
    if UnitCode <> '' then
    begin
      // Einheit angegeben: auf die Basiseinheit umrechnen (nur gleiche Groessenart)
      Qty := ScalarStr('SELECT COALESCE(quantity,'''') FROM unit WHERE LOWER(code)=' +
        QuotedStr(LowerCase(UnitCode)));
      if Qty = '' then
        Cond := '1=0'
      else
      begin
        if not ParseNum(ScalarStr('SELECT CAST(factor AS TEXT) FROM unit WHERE LOWER(code)=' +
          QuotedStr(LowerCase(UnitCode))), Fac) then Fac := 1;
        if not ParseNum(ScalarStr('SELECT CAST(COALESCE(shift,0) AS TEXT) FROM unit WHERE ' +
          'LOWER(code)=' + QuotedStr(LowerCase(UnitCode))), Sh) then Sh := 0;
        B := Num * Fac + Sh;
        Pre := 'u.quantity=' + QuotedStr(Qty) + ' AND ';
        LeftX := '((' + NumX + ')*COALESCE(u.factor,1)+COALESCE(u.shift,0))';
      end;
    end;
    if Cond = '' then
    begin
      if AOp = '=' then
        CmpS := 'ABS(' + LeftX + ' - (' + SqlFloat(B) + ')) < 0.000000001'
      else
        CmpS := LeftX + ' ' + AOp + ' (' + SqlFloat(B) + ')';
      Cond := '(' + Pre + CmpS + ')';
      if (AOp = '=') and (UnitCode = '') then Cond := '(' + Cond + ' OR ' + TextEq + ')';
    end;
  end;
  Result := 'EXISTS(SELECT 1 FROM part_value pv JOIN property p ON p.id=pv.property_id ' +
    'LEFT JOIN unit u ON u.id=p.unit_id LEFT JOIN enum_value e ON ' +
    'e.property_id=pv.property_id AND e.code=pv.value WHERE pv.part_id=pt.id AND ' +
    'pv.property_id=' + IntToStr(AProp) + ' AND ' + Cond + ')';
end;

procedure TPartSearchForm.RunNow;
var
  Terms: TStrArr;
  Txt, Cur, Where, Sel, OrdBy, No, Rel, Lop, Esc, Dir: string;
  I, K, N, OpIx: Integer;
  HasCrit: Boolean;
  Q: TSQLQuery;
  Tick: QWord;
  PropId, Cls: Int64;
begin
  Terms := nil;
  Txt := Trim(Ed.Text);
  Cur := '';
  for I := 1 to Length(Txt) + 1 do
  begin
    if (I > Length(Txt)) or (Txt[I] = ' ') then
    begin
      if (Cur <> '') and (Length(Terms) < 8) then
      begin
        SetLength(Terms, Length(Terms) + 1);
        Terms[High(Terms)] := Cur;
      end;
      Cur := '';
    end
    else
      Cur := Cur + Txt[I];
  end;

  if DbCtx.IsPg then Lop := ' ILIKE ' else Lop := ' LIKE ';
  Esc := ' ESCAPE ''\''';
  Where := '1=1';
  HasCrit := Length(Terms) > 0;
  if AllChk.Checked then
  begin
    for I := 0 to High(Terms) do Where := Where + ' AND ' + TermCond(Terms[I]);
  end
  else if Length(Terms) > 0 then
  begin
    // weich suchen: mindestens ein Wort muss passen, mehr Treffer stehen weiter oben
    Cur := '';
    for I := 0 to High(Terms) do
    begin
      if Cur <> '' then Cur := Cur + ' OR ';
      Cur := Cur + TermCond(Terms[I]);
    end;
    Where := Where + ' AND (' + Cur + ')';
  end;
  if Trim(Manu.Text) <> '' then
  begin
    HasCrit := True;
    Where := Where + ' AND COALESCE(pt.manufacturer,'''')' + Lop +
      QuotedStr('%' + LikeEsc(Trim(Manu.Text)) + '%') + Esc;
  end;
  Cls := 0;
  if Assigned(FHost.CurClass) then Cls := FHost.CurClass();
  if ClsChk.Checked and (Cls > 0) then
  begin
    HasCrit := True;
    No := RowStr('class', 'class_no', Cls);
    if ValidClassNo(No) then
      Where := Where + ' AND c.class_no LIKE ' +
        QuotedStr(Copy(No, 1, ClassNoLevel(No) * 3 - 1) + '%')
    else
      Where := Where + ' AND pt.class_id=' + IntToStr(Cls);
  end;

  Sel := 'SELECT pt.id, pt.class_id, pt.part_number, COALESCE(pt.description,''''), c.name, ' +
    'COALESCE(c.class_no,''''), COALESCE(pt.manufacturer,''''), COALESCE(s.name,'''')';
  for K := 0 to 2 do
  begin
    PropId := 0;
    if (FProp[K].ItemIndex > 0) and (FProp[K].ItemIndex <= High(PropIds)) then
      PropId := PropIds[FProp[K].ItemIndex];
    if PropId > 0 then
    begin
      if Trim(FVal[K].Text) <> '' then
      begin
        HasCrit := True;
        OpIx := FOp[K].ItemIndex;
        if (OpIx < 0) or (OpIx > 5) then OpIx := 0;
        Where := Where + ' AND ' + FilterCond(PropId, OpCodes[OpIx], FVal[K].Text);
      end;
      Sel := Sel + ', COALESCE((SELECT pv.value FROM part_value pv WHERE pv.part_id=pt.id ' +
        'AND pv.property_id=' + IntToStr(PropId) + ' LIMIT 1),'''')';
      Grid.Cells[BaseCols + K, 0] := FProp[K].Text;
    end
    else
    begin
      Sel := Sel + ', ''''';
      Grid.Cells[BaseCols + K, 0] := '';
    end;
  end;

  if not HasCrit then
  begin
    Grid.RowCount := 1;
    HitIds := nil;
    HitCls := nil;
    AutoSizeCols;
    Info.Caption := 'Suchwort eingeben, ein Merkmal mit Wert wählen oder ' +
      '"nur in gewählter Klasse" ankreuzen.';
    Exit;
  end;

  // Sortierung: nach angeklickter Spalte, sonst nach Trefferguete
  if (SortCol >= 0) and (SortCol < BaseCols) then
  begin
    if SortDesc then Dir := ' DESC' else Dir := '';
    OrdBy := SortCols[SortCol] + Dir + ', pt.part_number';
  end
  else if Length(Terms) > 0 then
  begin
    Rel := '0';
    if not AllChk.Checked then
      for I := 0 to High(Terms) do
        Rel := Rel + '+(CASE WHEN ' + TermCond(Terms[I]) + ' THEN 0 ELSE 10 END)';
    for I := 0 to High(Terms) do
      if I < 3 then
        Rel := Rel + '+(CASE WHEN pt.part_number' + Lop +
          QuotedStr(LikeEsc(Terms[I]) + '%') + Esc + ' THEN 0 WHEN pt.part_number' + Lop +
          QuotedStr('%' + LikeEsc(Terms[I]) + '%') + Esc + ' THEN 1 WHEN ' +
          'COALESCE(pt.description,'''')' + Lop + QuotedStr('%' + LikeEsc(Terms[I]) + '%') +
          Esc + ' THEN 2 ELSE 3 END)';
    OrdBy := Rel + ', pt.part_number';
  end
  else
    OrdBy := 'pt.part_number';

  Tick := GetTickCount64;
  Screen.Cursor := crHourGlass;
  Q := NewQuery;
  try
    try
      Q.SQL.Text := Sel + ' FROM part pt JOIN class c ON c.id=pt.class_id ' +
        'LEFT JOIN supplier s ON s.id=pt.supplier_id WHERE ' + Where +
        ' ORDER BY ' + OrdBy + ' LIMIT ' + IntToStr(MaxHits + 1);
      Q.Open;
      HitIds := nil;
      HitCls := nil;
      N := 0;
      Grid.BeginUpdate;
      try
        Grid.RowCount := 1;
        while not Q.EOF do
        begin
          if N >= MaxHits then
          begin
            Inc(N);
            Break;
          end;
          Grid.RowCount := N + 2;
          for K := 2 to 10 do Grid.Cells[K - 2, N + 1] := FieldText(Q.Fields[K]);
          SetLength(HitIds, N + 1);
          SetLength(HitCls, N + 1);
          HitIds[N] := Q.Fields[0].AsLargeInt;
          HitCls[N] := Q.Fields[1].AsLargeInt;
          Inc(N);
          Q.Next;
        end;
        AutoSizeCols;
      finally
        Grid.EndUpdate;
      end;
      Q.Close;
      if N > MaxHits then
        Info.Caption := 'Mehr als ' + IntToStr(MaxHits) + ' Treffer (die ersten ' +
          IntToStr(MaxHits) + ' werden gezeigt) - bitte die Suche eingrenzen.'
      else if N = 0 then
        Info.Caption := 'Keine Treffer.'
      else
        Info.Caption := IntToStr(N) + ' Treffer';
      Info.Caption := Info.Caption + '   (' + IntToStr(GetTickCount64 - Tick) + ' ms)';
      if Grid.RowCount > 1 then Grid.Row := 1;
    except
      on E: Exception do
      begin
        Info.Caption := 'Suchfehler: ' + E.Message;
        try
          DbCtx.Trans.RollbackRetaining;
        except
        end;
      end;
    end;
  finally
    Q.Free;
    Screen.Cursor := crDefault;
  end;
end;

{ ---------- Bedienung ---------- }

function TPartSearchForm.SelIndex: Integer;
begin
  Result := -1;
  if (Grid = nil) or (Grid.RowCount < 2) or (Grid.Row < 1) then Exit;
  Result := Grid.Row - 1;
  if Result > High(HitIds) then Result := -1;
end;

procedure TPartSearchForm.SearchChanged(Sender: TObject);
begin
  Timer.Enabled := False;
  Timer.Enabled := True;
end;

procedure TPartSearchForm.TimerTick(Sender: TObject);
begin
  Timer.Enabled := False;
  RunNow;
end;

procedure TPartSearchForm.Go(Sender: TObject);
var
  I: Integer;
begin
  I := SelIndex;
  if I < 0 then Exit;
  if Assigned(FHost.ShowPart) then FHost.ShowPart(HitCls[I], HitIds[I]);
end;

procedure TPartSearchForm.DoOpenCad(Sender: TObject);
begin
  if SelIndex < 0 then Exit;
  Go(nil);
  if Assigned(FHost.OpenCad) then FHost.OpenCad(nil);
end;

procedure TPartSearchForm.DoOpenLink(Sender: TObject);
begin
  if SelIndex < 0 then Exit;
  Go(nil);
  if Assigned(FHost.OpenLink) then FHost.OpenLink(nil);
end;

procedure TPartSearchForm.CopyNo(Sender: TObject);
var
  No: string;
begin
  if SelIndex < 0 then Exit;
  No := Grid.Cells[0, Grid.Row];
  Clipboard.AsText := No;
  if Assigned(FHost.Status) then FHost.Status('Teilenummer kopiert: ' + No);
end;

procedure TPartSearchForm.ResetClick(Sender: TObject);
var
  K: Integer;
begin
  Timer.Enabled := False;
  Ed.Text := '';
  Manu.Text := '';
  AllChk.Checked := True;
  ClsChk.Checked := False;
  for K := 0 to 2 do
  begin
    FProp[K].ItemIndex := 0;
    FOp[K].ItemIndex := 0;
    FVal[K].Text := '';
  end;
  SortCol := -1;
  SortDesc := False;
  Timer.Enabled := False;
  RunNow;
  Ed.SetFocus;
end;

procedure TPartSearchForm.HeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
begin
  if (not IsColumn) or (Index < 0) or (Index >= BaseCols) then Exit;
  if SortCol = Index then
    SortDesc := not SortDesc
  else
  begin
    SortCol := Index;
    SortDesc := False;
  end;
  RunNow;
end;

procedure TPartSearchForm.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  C, R: Integer;
begin
  if Button <> mbRight then Exit;
  Grid.MouseToCell(X, Y, C, R);
  if (R >= 1) and (R < Grid.RowCount) then Grid.Row := R;
end;

procedure TPartSearchForm.GridDblClick(Sender: TObject);
var
  P: TPoint;
  C, R: Integer;
begin
  P := Grid.ScreenToClient(Mouse.CursorPos);
  Grid.MouseToCell(P.X, P.Y, C, R);
  if R >= 1 then Go(nil);    // Doppelklick auf die Ueberschrift: nichts tun
end;

procedure TPartSearchForm.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Timer.Enabled := False;
    RunNow;
    Key := 0;
  end
  else if (Key = VK_DOWN) and (Grid.RowCount > 1) then
  begin
    Grid.SetFocus;
    if Grid.Row < 1 then Grid.Row := 1;
    Key := 0;
  end;
end;

procedure TPartSearchForm.GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Go(nil);
    Key := 0;
  end;
end;

procedure TPartSearchForm.FormKeyDown2(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    Close;
  end;
end;

procedure TPartSearchForm.FormClose2(Sender: TObject; var CloseAction: TCloseAction);
begin
  Timer.Enabled := False;
  CloseAction := caFree;
end;

{ ---------- Aufruf ---------- }

procedure ShowPartSearch(const AHost: TPartSearchHost);
var
  Q: TSQLQuery;
  Names: TStringList;
  Ids: array of Int64;
  J: Integer;
begin
  if GSearch <> nil then
  begin
    GSearch.Show;
    GSearch.BringToFront;
    GSearch.Ed.SetFocus;
    Exit;
  end;
  // Merkmale, die an Teilen vorkommen (sonst alle)
  Names := TStringList.Create;
  try
    Ids := nil;
    SetLength(Ids, 1);
    Ids[0] := 0;
    Names.Add('(kein Merkmal)');
    Q := NewQuery;
    try
      for J := 0 to 1 do
      begin
        if J = 0 then
          Q.SQL.Text := 'SELECT p.id, ' + NameSql('property', 'p.id', 'p.name') +
            ' FROM property p WHERE EXISTS(SELECT 1 FROM part_value pv WHERE ' +
            'pv.property_id=p.id) ORDER BY 2'
        else
          Q.SQL.Text := 'SELECT p.id, ' + NameSql('property', 'p.id', 'p.name') +
            ' FROM property p ORDER BY 2';
        Q.Open;
        while not Q.EOF do
        begin
          SetLength(Ids, Length(Ids) + 1);
          Ids[High(Ids)] := Q.Fields[0].AsLargeInt;
          Names.Add(FieldText(Q.Fields[1]));
          Q.Next;
        end;
        Q.Close;
        if Names.Count > 1 then Break;
      end;
    finally
      Q.Free;
    end;
    GSearch := TPartSearchForm.CreateSearch(AHost, Names, Ids);
  finally
    Names.Free;
  end;
  GSearch.Show;            // hier passt das Design die Groessen an die Schrift an
  GSearch.AutoSizeCols;    // danach Zeilenhoehe und Spaltenbreiten nach der echten Schrift
end;

end.
