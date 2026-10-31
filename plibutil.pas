unit PlibUtil;

{ Allgemeine Hilfsfunktionen von PLIB ohne Bezug zum Hauptfenster:
  Pfade, Text und Zahlen, Suchbegriffe, Klassennummern, Dateien.
  (Ausgelagert aus mainunit.pas, Stand 1.1) }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, IniFiles, Forms, Controls, ExtCtrls;

type
  TStrArr = array of string;
  TSearchFilter = record
    Key, Op, Rhs: string;
  end;
  TFilterArr = array of TSearchFilter;
  TUnitRec = record
    Code, Quantity: string;
    Factor, Shift: Double;
  end;

var
  GUnits: array of TUnitRec;   // Einheiten-Cache fuer die Schnellsuche

function ExeDir: string;
function DataDir: string;
function ResDir: string;
function IniName: string;
{ Merkt sich Groesse und Lage eines Dialogfensters in plib.ini ([Dialoge]) und stellt sie
  beim naechsten Oeffnen wieder her. Aufruf einmal nach dem Setzen der Standardgroesse. }
procedure RememberDialog(AForm: TForm; const AKey: string);
function Fold(const S: string): string;
function MinInt(A, B: Integer): Integer;
function Levenshtein(const A, B: string): Integer;
function IsWordCh(C: Char): Boolean;
function TokenScore(const Tok, Text: string): Integer;
function ParseNum(const S: string; out V: Double): Boolean;
procedure ParseQuery(const Q: string; out Terms: TStrArr; out Filters: TFilterArr);
function ParseNumUnit(const S: string; out Num: Double; out UnitCode: string): Boolean;
function FindUnitRec(const ACode: string): Integer;
function NumSql(D: Double): string;
function ValidCode(const S: string): Boolean;
function ValidIcd(const S: string): Boolean;
function ShortenPath(const S: string; AMax: Integer): string;
procedure CopyFileStream(const ASrc, ADst: string);
procedure SplitBar(const S: string; AList: TStrings);
function JoinBar(AList: TStrings): string;
procedure MergeOrder(AMaster, ACur: TStringList);
function SafeFileName(const S: string): string;
function IsAbsPath(const P: string): Boolean;
function ClassNoGroup(const S: string; ALevel: Integer): Integer;
function ClassNoLevel(const S: string): Integer;
function ValidClassNo(const S: string): Boolean;
function MakeClassNo(const AParentNo: string; ALevel, AGroup: Integer): string;
function StatusIndex(const AStatus: string): Integer;
function IsCadExt(const AExt: string): Boolean;
function FindFileExt(const ADir, AExt: string): string;
function CopyFileSimple(const ASrc, ADst: string): Boolean;
function LikeEsc(const S: string): string;
function SqlFloat(D: Double): string;
procedure AddUnique(var Arr: TStrArr; const S: string);
function TermAlts(const T: string): TStrArr;
function CadLinkUrl(const S: string): string;

implementation

type
  TDlgMemory = class(TComponent)
  public
    Key: string;
    Shown: Boolean;
    procedure DoClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure DoShow(Sender: TObject);
  end;

{ Das Steuerelement, dessen Groesse der Teiler aendert (das direkt davor liegende) }
function SplitterNeighbour(ASpl: TSplitter): TControl;
var
  I: Integer;
  C: TControl;
  Par: TWinControl;
begin
  Result := nil;
  Par := ASpl.Parent;
  if Par = nil then Exit;
  for I := 0 to Par.ControlCount - 1 do
  begin
    C := Par.Controls[I];
    if (C = ASpl) or (C.Align <> ASpl.Align) or not C.Visible then Continue;
    case ASpl.Align of
      alLeft:   if Abs(C.Left + C.Width - ASpl.Left) <= 3 then Result := C;
      alRight:  if Abs(C.Left - (ASpl.Left + ASpl.Width)) <= 3 then Result := C;
      alTop:    if Abs(C.Top + C.Height - ASpl.Top) <= 3 then Result := C;
      alBottom: if Abs(C.Top - (ASpl.Top + ASpl.Height)) <= 3 then Result := C;
    end;
    if Result <> nil then Exit;
  end;
end;

{ Alle Teiler eines Fensters in der Reihenfolge ihrer Erzeugung }
procedure CollectSplitters(AForm: TForm; AList: TList);
var
  I: Integer;
begin
  for I := 0 to AForm.ComponentCount - 1 do
    if AForm.Components[I] is TSplitter then AList.Add(AForm.Components[I]);
end;

function SplitterSize(ASpl: TSplitter; AControl: TControl): Integer;
begin
  if ASpl.Align in [alLeft, alRight] then Result := AControl.Width
  else Result := AControl.Height;
end;

procedure TDlgMemory.DoClose(Sender: TObject; var CloseAction: TCloseAction);
var
  F: TForm;
  Ini: TIniFile;
  L: TList;
  I: Integer;
  C: TControl;
begin
  F := Sender as TForm;
  try
    Ini := TIniFile.Create(IniName);
    try
      if F.WindowState = wsNormal then
        Ini.WriteString('Dialoge', Key, Format('%d|%d|%d|%d', [F.Width, F.Height, F.Left, F.Top]));
      // Teilerstellungen (Groesse des Bereichs vor dem Teiler)
      L := TList.Create;
      try
        CollectSplitters(F, L);
        for I := 0 to L.Count - 1 do
        begin
          C := SplitterNeighbour(TSplitter(L[I]));
          if C <> nil then
            Ini.WriteInteger('Dialoge', Key + '.Teiler' + IntToStr(I), SplitterSize(TSplitter(L[I]), C));
        end;
      finally
        L.Free;
      end;
    finally
      Ini.Free;
    end;
  except
    // Speichern der Fenstergroesse darf nie stoeren
  end;
end;

procedure TDlgMemory.DoShow(Sender: TObject);
var
  F: TForm;
  Ini: TIniFile;
  L: TList;
  I, V, Maxi: Integer;
  C: TControl;
  Spl: TSplitter;
begin
  if Shown then Exit;
  Shown := True;
  F := Sender as TForm;
  try
    Ini := TIniFile.Create(IniName);
    L := TList.Create;
    try
      CollectSplitters(F, L);
      for I := 0 to L.Count - 1 do
      begin
        Spl := TSplitter(L[I]);
        V := Ini.ReadInteger('Dialoge', Key + '.Teiler' + IntToStr(I), -1);
        if V < 0 then Continue;
        C := SplitterNeighbour(Spl);
        if (C = nil) or (Spl.Parent = nil) then Continue;
        if Spl.Align in [alLeft, alRight] then Maxi := Spl.Parent.ClientWidth - 120
        else Maxi := Spl.Parent.ClientHeight - 120;
        if V > Maxi then V := Maxi;
        if V < 60 then V := 60;
        if Spl.Align in [alLeft, alRight] then C.Width := V else C.Height := V;
      end;
    finally
      L.Free;
      Ini.Free;
    end;
  except
    // fehlerhafte Eintraege ignorieren
  end;
end;

procedure RememberDialog(AForm: TForm; const AKey: string);
var
  Ini: TIniFile;
  S: string;
  P: array[0..3] of Integer;
  I, Pos1: Integer;
  M: TDlgMemory;
  WA: TRect;
begin
  if AForm = nil then Exit;
  M := TDlgMemory.Create(AForm);   // gehoert dem Fenster und verschwindet mit ihm
  M.Key := AKey;
  AForm.OnClose := @M.DoClose;
  AForm.OnShow := @M.DoShow;
  try
    Ini := TIniFile.Create(IniName);
    try
      S := Ini.ReadString('Dialoge', AKey, '');
    finally
      Ini.Free;
    end;
    if S = '' then Exit;
    for I := 0 to 3 do
    begin
      Pos1 := System.Pos('|', S);
      if Pos1 = 0 then Pos1 := Length(S) + 1;
      P[I] := StrToIntDef(Copy(S, 1, Pos1 - 1), -99999);
      Delete(S, 1, Pos1);
      if P[I] = -99999 then Exit;
    end;
    WA := Screen.WorkAreaRect;
    if P[0] < 300 then P[0] := 300;
    if P[1] < 200 then P[1] := 200;
    if P[0] > WA.Right - WA.Left then P[0] := WA.Right - WA.Left;
    if P[1] > WA.Bottom - WA.Top then P[1] := WA.Bottom - WA.Top;
    // Lage so begrenzen, dass das Fenster sichtbar bleibt (z. B. nach Monitorwechsel)
    if P[2] + P[0] > WA.Right then P[2] := WA.Right - P[0];
    if P[3] + P[1] > WA.Bottom then P[3] := WA.Bottom - P[1];
    if P[2] < WA.Left then P[2] := WA.Left;
    if P[3] < WA.Top then P[3] := WA.Top;
    AForm.Position := poDesigned;
    AForm.SetBounds(P[2], P[3], P[0], P[1]);
  except
    // fehlerhafte Eintraege einfach ignorieren
  end;
end;

{ Ordner des Programms (unter macOS: plib.app/Contents/MacOS/) }
function ExeDir: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

{ Beschreibbarer Ordner fuer plib.ini, Datenbank, Sicherungen und Protokoll.
  Windows: neben dem Programm (wie bisher).
  macOS: ~/Library/Application Support/PLIB/ (im App-Bundle darf nicht geschrieben werden) }
function DataDir: string;
begin
  {$IFDEF DARWIN}
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('HOME')) +
    'Library/Application Support/PLIB/';
  ForceDirectories(Result);
  {$ELSE}
  Result := ExeDir;
  {$ENDIF}
end;

{ Ordner fuer mitgelieferte Dateien (Hilfe, Klassenbaum-Vorlage).
  macOS: plib.app/Contents/Resources/, falls vorhanden, sonst neben dem Programm }
function ResDir: string;
{$IFDEF DARWIN}
var
  R: string;
{$ENDIF}
begin
  Result := ExeDir;
  {$IFDEF DARWIN}
  R := ExpandFileName(ExeDir + '../Resources');
  if DirectoryExists(R) then Result := IncludeTrailingPathDelimiter(R);
  {$ENDIF}
end;

function IniName: string;
begin
  Result := DataDir + 'plib.ini';
end;

{ Normalisiert Text: Umlaute aufloesen (UTF-8-Bytes), Kleinschreibung }
function Fold(const S: string): string;
begin
  Result := S;
  Result := StringReplace(Result, #$C3#$A4, 'ae', [rfReplaceAll]);
  Result := StringReplace(Result, #$C3#$B6, 'oe', [rfReplaceAll]);
  Result := StringReplace(Result, #$C3#$BC, 'ue', [rfReplaceAll]);
  Result := StringReplace(Result, #$C3#$84, 'ae', [rfReplaceAll]);
  Result := StringReplace(Result, #$C3#$96, 'oe', [rfReplaceAll]);
  Result := StringReplace(Result, #$C3#$9C, 'ue', [rfReplaceAll]);
  Result := StringReplace(Result, #$C3#$9F, 'ss', [rfReplaceAll]);
  Result := LowerCase(Result);
end;

function MinInt(A, B: Integer): Integer;
begin
  if A < B then Result := A else Result := B;
end;

{ Editierabstand (Tippfehler-Toleranz) }
function Levenshtein(const A, B: string): Integer;
var
  Prev, Cur: array of Integer;
  i, j, Cost: Integer;
begin
  SetLength(Prev, Length(B) + 1);
  SetLength(Cur, Length(B) + 1);
  for j := 0 to Length(B) do Prev[j] := j;
  for i := 1 to Length(A) do
  begin
    Cur[0] := i;
    for j := 1 to Length(B) do
    begin
      if A[i] = B[j] then Cost := 0 else Cost := 1;
      Cur[j] := MinInt(MinInt(Prev[j] + 1, Cur[j - 1] + 1), Prev[j - 1] + Cost);
    end;
    Prev := Copy(Cur, 0, Length(Cur));
  end;
  Result := Prev[Length(B)];
end;

function IsWordCh(C: Char): Boolean;
begin
  Result := (C in ['a'..'z', '0'..'9']) or (C >= #128);
end;

{ Wie gut passt ein Suchwort auf einen (normalisierten) Text?
  0 = gar nicht, 100 = ganzer Text identisch, 90 = ganzes Wort, 70 = Wortanfang,
  45 = Teilstring im Wort, 40 = Teilstring ueber Wortgrenzen, 25 = Tippfehler }
function TokenScore(const Tok, Text: string): Integer;
var
  i, St, L, Sc, MaxD: Integer;
  W: string;
begin
  Result := 0;
  if (Tok = '') or (Text = '') then Exit;
  if Text = Tok then
  begin
    Result := 100;
    Exit;
  end;
  L := Length(Text);
  i := 1;
  while i <= L do
  begin
    while (i <= L) and (not IsWordCh(Text[i])) do Inc(i);
    St := i;
    while (i <= L) and IsWordCh(Text[i]) do Inc(i);
    if i > St then
    begin
      W := Copy(Text, St, i - St);
      Sc := 0;
      if W = Tok then
        Sc := 90
      else if Pos(Tok, W) = 1 then
        Sc := 70
      else if Pos(Tok, W) > 1 then
        Sc := 45
      else if (Length(Tok) >= 4) and (Abs(Length(W) - Length(Tok)) <= 2) then
      begin
        MaxD := 1;
        if Length(Tok) >= 7 then MaxD := 2;
        if Levenshtein(Tok, W) <= MaxD then Sc := 25;
      end;
      if Sc > Result then Result := Sc;
      if Result >= 90 then Exit;
    end;
  end;
  if (Result = 0) and (Pos(Tok, Text) > 0) then Result := 40;
end;

function ParseNum(const S: string; out V: Double): Boolean;
var
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := TryStrToFloat(StringReplace(Trim(S), ',', '.', []), V, FS);
end;

{ Zerlegt die Anfrage: normale Woerter und Filter (Merkmal>=40, DN=8, werkstoff:stahl) }
procedure ParseQuery(const Q: string; out Terms: TStrArr; out Filters: TFilterArr);
var
  i, k, P, NT, NF: Integer;
  T, Op, Rhs: string;
  Toks: array of string;
  Cur: string;

  procedure AddTok;
  begin
    if Cur <> '' then
    begin
      SetLength(Toks, Length(Toks) + 1);
      Toks[High(Toks)] := Cur;
      Cur := '';
    end;
  end;

begin
  Terms := nil;
  Filters := nil;
  Toks := nil;
  Cur := '';
  for i := 1 to Length(Q) do
    if Q[i] = ' ' then AddTok else Cur := Cur + Q[i];
  AddTok;
  NT := 0;
  NF := 0;
  for i := 0 to High(Toks) do
  begin
    T := Toks[i];
    P := 0;
    for k := 1 to Length(T) do
      if T[k] in ['<', '>', '=', ':'] then
      begin
        P := k;
        Break;
      end;
    Rhs := '';
    Op := '';
    if P > 1 then
    begin
      Op := T[P];
      if (P < Length(T)) and (T[P + 1] = '=') and ((T[P] = '<') or (T[P] = '>')) then
        Op := Op + '=';
      Rhs := Copy(T, P + Length(Op), MaxInt);
    end;
    if (P > 1) and (Rhs <> '') then
    begin
      SetLength(Filters, NF + 1);
      Filters[NF].Key := Copy(T, 1, P - 1);
      Filters[NF].Op := Op;
      Filters[NF].Rhs := Rhs;
      Inc(NF);
    end
    else
    begin
      SetLength(Terms, NT + 1);
      Terms[NT] := T;
      Inc(NT);
    end;
  end;
end;

{ Zahl mit optionaler Einheit, z. B. '0,04m' oder '40' }
function ParseNumUnit(const S: string; out Num: Double; out UnitCode: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  UnitCode := '';
  Num := 0;
  i := 1;
  while (i <= Length(S)) and (S[i] in ['0'..'9', ',', '.', '-', '+']) do Inc(i);
  if i = 1 then Exit;
  if not ParseNum(Copy(S, 1, i - 1), Num) then Exit;
  UnitCode := Trim(Copy(S, i, MaxInt));
  Result := True;
end;

function FindUnitRec(const ACode: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(GUnits) do
    if LowerCase(GUnits[i].Code) = LowerCase(ACode) then
    begin
      Result := i;
      Exit;
    end;
end;

function NumSql(D: Double): string;
var
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := FloatToStrF(D, ffGeneral, 15, 0, FS);
end;

function ValidCode(const S: string): Boolean;
var
  i: Integer;
begin
  Result := (S <> '') and (Length(S) <= 40);
  if not Result then Exit;
  for i := 1 to Length(S) do
    if not (S[i] in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.']) then
    begin
      Result := False;
      Exit;
    end;
end;

function ValidIcd(const S: string): Boolean;
var
  i: Integer;
begin
  Result := (S = '') or (Length(S) = 4);
  if (not Result) or (S = '') then Exit;
  for i := 1 to 4 do
    if not (S[i] in ['0'..'9']) then
    begin
      Result := False;
      Exit;
    end;
end;

{ Kuerzt einen langen Pfad fuer die Anzeige: ...Ende des Pfades }
function ShortenPath(const S: string; AMax: Integer): string;
begin
  if Length(S) <= AMax then
    Result := S
  else
    Result := '...' + Copy(S, Length(S) - AMax + 4, AMax - 3);
end;

{ Kopiert eine Datei (auch wenn sie von SQLite geoeffnet ist) }
procedure CopyFileStream(const ASrc, ADst: string);
var
  Src, Dst: TFileStream;
begin
  Src := TFileStream.Create(ASrc, fmOpenRead or fmShareDenyNone);
  try
    Dst := TFileStream.Create(ADst, fmCreate);
    try
      Dst.CopyFrom(Src, 0);
    finally
      Dst.Free;
    end;
  finally
    Src.Free;
  end;
end;

procedure SplitBar(const S: string; AList: TStrings);
var
  i: Integer;
  Cur: string;
begin
  AList.Clear;
  Cur := '';
  for i := 1 to Length(S) do
    if S[i] = '|' then
    begin
      if Cur <> '' then AList.Add(Cur);
      Cur := '';
    end
    else
      Cur := Cur + S[i];
  if Cur <> '' then AList.Add(Cur);
end;

function JoinBar(AList: TStrings): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to AList.Count - 1 do
  begin
    if i > 0 then Result := Result + '|';
    Result := Result + StringReplace(AList[i], '|', '/', [rfReplaceAll]);
  end;
end;

{ Fuehrt die aktuelle Spaltenreihenfolge mit der gemerkten zusammen: Spalten, die in der
  aktuellen Tabelle fehlen (andere Klasse), behalten ihren Platz in der gemerkten Liste }
procedure MergeOrder(AMaster, ACur: TStringList);
var
  Res: TStringList;
  i, j, k, Pos0: Integer;
begin
  Res := TStringList.Create;
  try
    Res.AddStrings(ACur);
    for i := 0 to AMaster.Count - 1 do
      if Res.IndexOf(AMaster[i]) < 0 then
      begin
        Pos0 := 0;
        for j := i - 1 downto 0 do
        begin
          k := Res.IndexOf(AMaster[j]);
          if k >= 0 then
          begin
            Pos0 := k + 1;
            Break;
          end;
        end;
        Res.Insert(Pos0, AMaster[i]);
      end;
    AMaster.Assign(Res);
  finally
    Res.Free;
  end;
end;

{ Macht aus einem Text einen gueltigen Dateinamen }
function SafeFileName(const S: string): string;
const
  Reserved: array[0..21] of string = ('CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9');
var
  i: Integer;
  B: string;
begin
  Result := Trim(S);
  for i := 1 to Length(Result) do
    if (Result[i] in ['\', '/', ':', '*', '?', '"', '<', '>', '|']) or (Result[i] < ' ') then
      Result[i] := '_';
  // Windows: keine Punkte/Leerzeichen am Ende, keine Geraetenamen (CON, NUL, COM1 ...)
  while (Result <> '') and (Result[Length(Result)] in ['.', ' ']) do
    Delete(Result, Length(Result), 1);
  if Result = '' then Result := '_';
  B := UpperCase(Result);
  if Pos('.', B) > 0 then B := Copy(B, 1, Pos('.', B) - 1);
  for i := 0 to High(Reserved) do
    if B = Reserved[i] then
    begin
      Result := '_' + Result;
      Break;
    end;
end;

function IsAbsPath(const P: string): Boolean;
begin
  Result := (Length(P) > 1) and ((P[2] = ':') or (P[1] = '\') or (P[1] = '/'));
end;

{ Klassennummer AA.BB.CC.DD: AA = Fachbereich, BB = Warengruppe, CC = Produktgruppe,
  DD = Detailklasse. Jede Ebene 01 bis 99, 00 = Ebene nicht belegt. }
function ClassNoGroup(const S: string; ALevel: Integer): Integer;
begin
  Result := StrToIntDef(Copy(S, ALevel * 3 - 2, 2), -1);
end;

{ Ebene einer Klassennummer (1 bis 4), 0 bei ungueltiger Nummer }
function ClassNoLevel(const S: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 4 do
    if ClassNoGroup(S, i) > 0 then
    begin
      if Result <> i - 1 then
      begin
        Result := 0;   // Luecke, z. B. 10.00.01.00
        Exit;
      end;
      Result := i;
    end;
end;

function ValidClassNo(const S: string): Boolean;
var
  i: Integer;
begin
  Result := Length(S) = 11;
  if not Result then Exit;
  for i := 1 to 11 do
    if (i mod 3) = 0 then
    begin
      if S[i] <> '.' then Result := False;
    end
    else if not (S[i] in ['0'..'9']) then
      Result := False;
  if Result then Result := ClassNoLevel(S) > 0;
end;

{ Nummer aus den ersten ALevel-1 Gruppen von APrefix und der Gruppe AGroup }
function MakeClassNo(const AParentNo: string; ALevel, AGroup: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to 4 do
  begin
    if i > 1 then Result := Result + '.';
    if i < ALevel then
      Result := Result + Copy(AParentNo, i * 3 - 2, 2)
    else if i = ALevel then
      Result := Result + Format('%.2d', [AGroup])
    else
      Result := Result + '00';
  end;
end;

{ Status einer Klasse als Zahl: 0 in Arbeit, 1 freigegeben, 2 veraltet }
function StatusIndex(const AStatus: string): Integer;
begin
  if AStatus = 'freigegeben' then
    Result := 1
  else if AStatus = 'veraltet' then
    Result := 2
  else
    Result := 0;
end;

{ Pruefen und Maske schliessen }
function IsCadExt(const AExt: string): Boolean;
begin
  Result := Pos('|' + LowerCase(AExt) + '|',
    '|.par|.psm|.asm|.stp|.step|.igs|.iges|.x_t|.x_b|.sldprt|.sat|') > 0;
end;

function FindFileExt(const ADir, AExt: string): string;
var
  SR: TSearchRec;
  D: string;
begin
  Result := '';
  D := IncludeTrailingPathDelimiter(ADir);
  if FindFirst(D + '*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          if (SR.Attr and faDirectory) <> 0 then
            Result := FindFileExt(D + SR.Name, AExt)
          else if LowerCase(ExtractFileExt(SR.Name)) = AExt then
            Result := D + SR.Name;
        end;
      until (Result <> '') or (FindNext(SR) <> 0);
    finally
      FindClose(SR);
    end;
  end;
end;

function CopyFileSimple(const ASrc, ADst: string): Boolean;
var
  FS, FD: TFileStream;
begin
  Result := False;
  try
    FS := TFileStream.Create(ASrc, fmOpenRead or fmShareDenyNone);
    try
      FD := TFileStream.Create(ADst, fmCreate);
      try
        FD.CopyFrom(FS, 0);
        Result := True;
      finally
        FD.Free;
      end;
    finally
      FS.Free;
    end;
  except
    Result := False;
  end;
end;

function LikeEsc(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    if S[I] in ['\', '%', '_'] then Result := Result + '\';
    Result := Result + S[I];
  end;
end;

function SqlFloat(D: Double): string;
var
  S: string;
begin
  Str(D:0:9, S);
  Result := S;
end;

procedure AddUnique(var Arr: TStrArr; const S: string);
var
  K: Integer;
begin
  for K := 0 to High(Arr) do
    if Arr[K] = S then Exit;
  SetLength(Arr, Length(Arr) + 1);
  Arr[High(Arr)] := S;
end;

{ Schreibweisen eines Suchworts: wie getippt, ohne Umlaute (ae), mit Umlauten }
function TermAlts(const T: string): TStrArr;
var
  A, B: string;
begin
  Result := nil;
  AddUnique(Result, T);
  A := Fold(T);
  AddUnique(Result, A);
  B := StringReplace(A, 'ae', 'ä', [rfReplaceAll]);
  B := StringReplace(B, 'oe', 'ö', [rfReplaceAll]);
  B := StringReplace(B, 'ue', 'ü', [rfReplaceAll]);
  B := StringReplace(B, 'ss', 'ß', [rfReplaceAll]);
  AddUnique(Result, B);
end;

function CadLinkUrl(const S: string): string;
var
  T: string;
begin
  // nur http/https-Adressen werden geoeffnet
  Result := '';
  T := Trim(S);
  if T = '' then Exit;
  if Pos('://', T) = 0 then T := 'https://' + T;
  if (LowerCase(Copy(T, 1, 7)) <> 'http://') and (LowerCase(Copy(T, 1, 8)) <> 'https://') then Exit;
  Result := T;
end;

end.
