unit ClassSuggest;

{ Klassenvorschlag fuer neue Artikel (ohne KI).

  Dieses Modul kennt weder die Oberflaeche noch die Suche (MainUnit). Es liest nur aus
  der Datenbank und liefert eine nach Punkten sortierte Liste von Klassen mit Begruendung.
  Gespeichert wird hier nichts: der Benutzer bestaetigt die Klasse, die Historie schreibt
  das Hauptprogramm.

  Die Vorschlagslogik ist austauschbar: TClassSuggester ist eine abstrakte Schnittstelle,
  TPointsSuggester ist die Punkte-Umsetzung. Eine KI-Variante koennte spaeter als weitere
  Ableitung daneben stehen, ohne dass sich das Hauptprogramm aendert.

  Punkte (Tabelle suggest_weight, im Programm aenderbar):
    AEHNLICH      je aehnlichem Artikel
    AEHNLICH_MAX  so viele aehnliche Artikel zaehlen hoechstens
    NORM          Norm stimmt ueberein (z. B. DIN933)
    MATERIAL      Werkstoff stimmt ueberein
    BEGRIFF       Suchbegriff aus Bezeichnung/Beschreibung (mal Gewichtung / 10)
    MERKMAL       je uebereinstimmendem Merkmalswert
    HISTORIE      fruehere Zuordnung mit aehnlichem Text }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, LazUTF8;

type
  TSuggestInput = record
    Description: string;    // Bezeichnung / Beschreibung des neuen Artikels
    Manufacturer: string;
    Supplier: string;
    Extra: string;          // weitere Texte, z. B. schon eingegebene Merkmalswerte
  end;

  TSuggestItem = record
    ClassId: Int64;
    ClassNo, ClassName: string;
    Points: Integer;
    Reasons: string;        // eine Begruendung je Zeile
  end;
  TSuggestItems = array of TSuggestItem;

  TSuggestResult = record
    Items: TSuggestItems;   // absteigend nach Punkten
    HasMatch: Boolean;      // mindestens eine brauchbare Klasse gefunden
    NewParentId: Int64;     // Oberklasse fuer eine neue Klasse (0 = Hauptklasse)
    Tokens: string;         // erkannte Begriffe, zur Anzeige
  end;

  TClassSuggester = class
  protected
    FConn: TSQLConnection;
    FTrans: TSQLTransaction;
  public
    constructor Create(AConn: TSQLConnection; ATrans: TSQLTransaction);
    function Name: string; virtual; abstract;
    function Suggest(const AInput: TSuggestInput): TSuggestResult; virtual; abstract;
  end;

  TPointsSuggester = class(TClassSuggester)
  private
    FIds: array of Int64;
    FPts: array of Integer;
    FWhy: array of string;
    WAehnlich, WAehnlichMax, WNorm, WMaterial, WBegriff, WMerkmal, WHistorie: Integer;
    function Fld(AField: TField): string;
    procedure LoadWeights;
    procedure AddPoints(AClass: Int64; APoints: Integer; const AReason: string);
    function IndexOfClass(AClass: Int64): Integer;
    procedure ByTerms(ATokens: TStringList; const AFull: string);
    procedure ByNorm(ATokens: TStringList);
    procedure BySimilar(ATokens: TStringList);
    procedure ByValues(ATokens: TStringList);
    procedure ByMaterial(ATokens: TStringList);
    procedure ByHistory(ATokens: TStringList);
  public
    function Name: string; override;
    function Suggest(const AInput: TSuggestInput): TSuggestResult; override;
  end;

{ Text vergleichbar machen: Grossbuchstaben, ae/oe/ue/ss statt Umlauten }
function NormText(const S: string): string;
{ zerlegt einen Text in Begriffe (DIN 933 -> DIN933, M6x20 -> M6 und 20) }
procedure TokenizeText(const S: string; ATokens: TStringList);
{ Ebene (1 bis 4) einer Klassennummer AA.BB.CC.DD, 0 wenn ungueltig }
function ClassNoLevelOf(const S: string): Integer;

implementation

function NormText(const S: string): string;
begin
  Result := UTF8UpperCase(S);
  Result := StringReplace(Result, 'Ä', 'AE', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ö', 'OE', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ü', 'UE', [rfReplaceAll]);
  Result := StringReplace(Result, 'ß', 'SS', [rfReplaceAll]);
  Result := StringReplace(Result, 'ẞ', 'SS', [rfReplaceAll]);
  Result := Trim(Result);
end;

function ClassNoLevelOf(const S: string): Integer;
var
  i, G, Last: Integer;
begin
  Result := 0;
  if Length(S) <> 11 then Exit;
  Last := 0;
  for i := 1 to 4 do
  begin
    G := StrToIntDef(Copy(S, i * 3 - 2, 2), -1);
    if G < 0 then
    begin
      Result := 0;
      Exit;
    end;
    if G > 0 then
    begin
      if Last <> i - 1 then
      begin
        Result := 0;
        Exit;
      end;
      Last := i;
    end;
  end;
  Result := Last;
end;

procedure AddTok(AList: TStringList; const T: string);
var
  X: string;
begin
  X := T;
  while (X <> '') and (X[1] in ['.', '-', '+']) do Delete(X, 1, 1);
  while (X <> '') and (X[Length(X)] in ['.', '-', '+']) do Delete(X, Length(X), 1);
  if Length(X) < 2 then Exit;
  if AList.IndexOf(X) < 0 then AList.Add(X);
end;

procedure TokenizeText(const S: string; ATokens: TStringList);
var
  N, Cur, Prev, Part, Base: string;
  Raw: TStringList;
  i, p, k: Integer;
  Pieces: TStringList;
begin
  ATokens.Clear;
  N := NormText(S);
  // Trennzeichen durch Leerzeichen ersetzen (Punkt und Minus bleiben: 8.8, A2-70)
  for i := 1 to Length(N) do
    if N[i] in [#9, #10, #13, ',', ';', ':', '(', ')', '[', ']', '{', '}', '/', '\', '|',
      '*', '"', '#', '=', '<', '>', '!', '?', '&', '~', '_'] then
      N[i] := ' ';
  Raw := TStringList.Create;
  Pieces := TStringList.Create;
  try
    Raw.Delimiter := ' ';
    Raw.StrictDelimiter := True;
    Raw.DelimitedText := N;
    Prev := '';
    for i := 0 to Raw.Count - 1 do
    begin
      Cur := Trim(Raw[i]);
      if Cur = '' then Continue;
      // DIN 933 / ISO 4017 / EN 10088 getrennt geschrieben
      if ((Prev = 'DIN') or (Prev = 'ISO') or (Prev = 'EN') or (Prev = 'DINEN') or
        (Prev = 'DIN-EN')) and (Cur[1] in ['0'..'9']) then
      begin
        Base := Cur;
        AddTok(ATokens, Prev + Base);
        p := Pos('-', Base);
        if p > 1 then AddTok(ATokens, Prev + Copy(Base, 1, p - 1));
      end;
      // M6X20 oder M6X20X5: Gewinde und Mase einzeln
      if (Cur[1] = 'M') and (Length(Cur) > 2) and (Cur[2] in ['0'..'9']) and
        (Pos('X', Cur) > 0) then
      begin
        Pieces.Clear;
        Pieces.Delimiter := 'X';
        Pieces.StrictDelimiter := True;
        Pieces.DelimitedText := Cur;
        for k := 0 to Pieces.Count - 1 do
        begin
          Part := Pieces[k];
          if (Part <> '') and ((k > 0) or (Part[1] = 'M')) then AddTok(ATokens, Part);
        end;
      end
      else
      begin
        AddTok(ATokens, Cur);
        // DIN933-1 -> auch DIN933
        if ((Copy(Cur, 1, 3) = 'DIN') or (Copy(Cur, 1, 3) = 'ISO')) and
          (Pos('-', Cur) > 0) then
          AddTok(ATokens, Copy(Cur, 1, Pos('-', Cur) - 1));
      end;
      Prev := Cur;
    end;
  finally
    Pieces.Free;
    Raw.Free;
  end;
end;

function IsNormToken(const T: string): Boolean;
begin
  Result := (Length(T) >= 5) and
    (((Copy(T, 1, 3) = 'DIN') and (T[4] in ['0'..'9'])) or
     ((Copy(T, 1, 3) = 'ISO') and (T[4] in ['0'..'9'])) or
     ((Copy(T, 1, 2) = 'EN') and (T[3] in ['0'..'9'])));
end;

{ nur Zeichen, die in einem LIKE-Muster unbedenklich sind }
function SqlSafe(const T: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(T) do
    if T[i] in ['A'..'Z', '0'..'9', '.', '-', '+'] then Result := Result + T[i];
end;

{ ---------- TClassSuggester ---------- }

constructor TClassSuggester.Create(AConn: TSQLConnection; ATrans: TSQLTransaction);
begin
  inherited Create;
  FConn := AConn;
  FTrans := ATrans;
end;

{ ---------- TPointsSuggester ---------- }

function TPointsSuggester.Name: string;
begin
  Result := 'Punktesystem (ohne KI)';
end;

function TPointsSuggester.Fld(AField: TField): string;
var
  SS: TStringStream;
begin
  Result := '';
  if AField.IsNull then Exit;
  if AField.DataType in [ftMemo, ftWideMemo, ftFmtMemo, ftBlob] then
  begin
    SS := TStringStream.Create('');
    try
      TBlobField(AField).SaveToStream(SS);
      Result := SS.DataString;
    finally
      SS.Free;
    end;
  end
  else
    Result := AField.AsString;
end;

procedure TPointsSuggester.LoadWeights;
var
  Q: TSQLQuery;
  K: string;
  V: Integer;
begin
  WAehnlich := 10;
  WAehnlichMax := 20;
  WNorm := 20;
  WMaterial := 15;
  WBegriff := 10;
  WMerkmal := 5;
  WHistorie := 10;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConn;
    Q.Transaction := FTrans;
    Q.SQL.Text := 'SELECT wkey, points FROM suggest_weight';
    Q.Open;
    while not Q.EOF do
    begin
      K := Fld(Q.Fields[0]);
      V := Q.Fields[1].AsInteger;
      if K = 'AEHNLICH' then WAehnlich := V
      else if K = 'AEHNLICH_MAX' then WAehnlichMax := V
      else if K = 'NORM' then WNorm := V
      else if K = 'MATERIAL' then WMaterial := V
      else if K = 'BEGRIFF' then WBegriff := V
      else if K = 'MERKMAL' then WMerkmal := V
      else if K = 'HISTORIE' then WHistorie := V;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TPointsSuggester.IndexOfClass(AClass: Int64): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(FIds) do
    if FIds[i] = AClass then
    begin
      Result := i;
      Exit;
    end;
end;

procedure TPointsSuggester.AddPoints(AClass: Int64; APoints: Integer;
  const AReason: string);
var
  i: Integer;
begin
  if (AClass = 0) or (APoints <= 0) then Exit;
  i := IndexOfClass(AClass);
  if i < 0 then
  begin
    i := Length(FIds);
    SetLength(FIds, i + 1);
    SetLength(FPts, i + 1);
    SetLength(FWhy, i + 1);
    FIds[i] := AClass;
    FPts[i] := 0;
    FWhy[i] := '';
  end;
  FPts[i] := FPts[i] + APoints;
  if AReason <> '' then
  begin
    if FWhy[i] <> '' then FWhy[i] := FWhy[i] + LineEnding;
    FWhy[i] := FWhy[i] + AReason + ' (+' + IntToStr(APoints) + ')';
  end;
end;

{ Suchbegriffe der Klassen (Tabelle search_term) }
procedure TPointsSuggester.ByTerms(ATokens: TStringList; const AFull: string);
var
  Q: TSQLQuery;
  T, Tk: string;
  W, i: Integer;
  Hit: Boolean;
  Cls: Int64;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConn;
    Q.Transaction := FTrans;
    Q.SQL.Text := 'SELECT term, class_id, weight FROM search_term';
    Q.Open;
    while not Q.EOF do
    begin
      T := NormText(Fld(Q.Fields[0]));
      Cls := Q.Fields[1].AsLargeInt;
      W := Q.Fields[2].AsInteger;
      Hit := False;
      if T <> '' then
      begin
        if ATokens.IndexOf(T) >= 0 then
          Hit := True
        else if (Pos(' ', T) > 0) and (Pos(T, AFull) > 0) then
          Hit := True   // mehrteiliger Begriff im Text
        else if Length(T) >= 5 then
          // Begriff steckt in einem zusammengesetzten Wort (Sechskantschraube -> Schraube)
          for i := 0 to ATokens.Count - 1 do
          begin
            Tk := ATokens[i];
            if (Length(Tk) > Length(T)) and (Pos(T, Tk) > 0) then
            begin
              Hit := True;
              Break;
            end;
          end;
      end;
      if Hit then
        AddPoints(Cls, (WBegriff * W) div 10, 'Suchbegriff „' + T + '“');
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

{ Normen wie DIN933 mit dem Merkmal NORM der vorhandenen Artikel vergleichen }
procedure TPointsSuggester.ByNorm(ATokens: TStringList);
var
  Q: TSQLQuery;
  i: Integer;
  Tk: string;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConn;
    Q.Transaction := FTrans;
    for i := 0 to ATokens.Count - 1 do
    begin
      Tk := SqlSafe(ATokens[i]);
      if (Tk = '') or not IsNormToken(Tk) then Continue;
      Q.SQL.Text := 'SELECT pt.class_id, COUNT(*) FROM part_value pv ' +
        'JOIN property p ON p.id=pv.property_id JOIN part pt ON pt.id=pv.part_id ' +
        'WHERE p.code=''NORM'' AND REPLACE(UPPER(pv.value),'' '','''') LIKE ''%' + Tk + '%'' ' +
        'GROUP BY pt.class_id';
      Q.Open;
      while not Q.EOF do
      begin
        AddPoints(Q.Fields[0].AsLargeInt, WNorm,
          'Norm ' + Tk + ' bei ' + IntToStr(Q.Fields[1].AsLargeInt) + ' Artikel(n)');
        Q.Next;
      end;
      Q.Close;
    end;
  finally
    Q.Free;
  end;
end;

{ Aehnliche Artikel: Bezeichnung/Teilenummer enthalten dieselben Begriffe }
procedure TPointsSuggester.BySimilar(ATokens: TStringList);
type
  TRow = record
    Cls: Int64;
    Score: Integer;
  end;
var
  Q: TSQLQuery;
  Cond, Txt: string;
  Use: TStringList;
  Rows: array of TRow;
  Order: TStringList;
  i, n, Sc, Need, Taken, Idx: Integer;
  Cnt: array of Integer;
  Cls: array of Int64;
  c, k: Integer;
begin
  Use := TStringList.Create;
  Order := TStringList.Create;
  try
    for i := 0 to ATokens.Count - 1 do
      if (Length(ATokens[i]) >= 3) and (SqlSafe(ATokens[i]) = ATokens[i]) and
        (Use.Count < 8) then
        Use.Add(ATokens[i]);
    if Use.Count = 0 then Exit;
    Cond := '';
    for i := 0 to Use.Count - 1 do
    begin
      if Cond <> '' then Cond := Cond + ' OR ';
      Cond := Cond + 'UPPER(COALESCE(pt.description,'''') || '' '' || pt.part_number) LIKE ''%' +
        Use[i] + '%''';
    end;
    Q := TSQLQuery.Create(nil);
    try
      Q.DataBase := FConn;
      Q.Transaction := FTrans;
      Q.SQL.Text := 'SELECT pt.class_id, UPPER(COALESCE(pt.description,'''') || '' '' || ' +
        'pt.part_number) FROM part pt WHERE ' + Cond + ' LIMIT 1000';
      Q.Open;
      n := 0;
      while not Q.EOF do
      begin
        Txt := Fld(Q.Fields[1]);
        Sc := 0;
        for i := 0 to Use.Count - 1 do
          if Pos(Use[i], Txt) > 0 then Inc(Sc);
        SetLength(Rows, n + 1);
        Rows[n].Cls := Q.Fields[0].AsLargeInt;
        Rows[n].Score := Sc;
        Inc(n);
        Q.Next;
      end;
      Q.Close;
    finally
      Q.Free;
    end;
    // beste Treffer zuerst (Sortierschluessel: 100 - Punkte, laufende Nummer)
    for i := 0 to n - 1 do
      Order.AddObject(Format('%.3d_%.6d', [100 - Rows[i].Score, i]), TObject(PtrInt(i)));
    Order.Sort;
    if Use.Count >= 2 then Need := 2 else Need := 1;
    Taken := 0;
    SetLength(Cnt, 0);
    SetLength(Cls, 0);
    for i := 0 to Order.Count - 1 do
    begin
      if Taken >= WAehnlichMax then Break;
      Idx := PtrInt(Order.Objects[i]);
      if Rows[Idx].Score < Need then Break;
      Inc(Taken);
      c := -1;
      for k := 0 to High(Cls) do
        if Cls[k] = Rows[Idx].Cls then c := k;
      if c < 0 then
      begin
        c := Length(Cls);
        SetLength(Cls, c + 1);
        SetLength(Cnt, c + 1);
        Cls[c] := Rows[Idx].Cls;
        Cnt[c] := 0;
      end;
      Inc(Cnt[c]);
    end;
    for c := 0 to High(Cls) do
      AddPoints(Cls[c], Cnt[c] * WAehnlich,
        IntToStr(Cnt[c]) + ' ähnliche(r) Artikel in dieser Klasse');
  finally
    Order.Free;
    Use.Free;
  end;
end;

{ Merkmalswerte wie M6 oder 8.8, die bei Artikeln einer Klasse vorkommen }
procedure TPointsSuggester.ByValues(ATokens: TStringList);
var
  Q: TSQLQuery;
  InList, Tk: string;
  i, c, k: Integer;
  Cls: array of Int64;
  Cnt: array of Integer;
  Vals: array of string;
  Cid: Int64;
begin
  InList := '';
  for i := 0 to ATokens.Count - 1 do
  begin
    Tk := ATokens[i];
    if (SqlSafe(Tk) <> Tk) or IsNormToken(Tk) then Continue;
    if InList <> '' then InList := InList + ',';
    InList := InList + '''' + Tk + '''';
  end;
  if InList = '' then Exit;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConn;
    Q.Transaction := FTrans;
    Q.SQL.Text := 'SELECT pt.class_id, UPPER(pv.value) FROM part_value pv ' +
      'JOIN part pt ON pt.id=pv.part_id WHERE UPPER(pv.value) IN (' + InList + ') ' +
      'GROUP BY pt.class_id, UPPER(pv.value)';
    Q.Open;
    while not Q.EOF do
    begin
      Cid := Q.Fields[0].AsLargeInt;
      c := -1;
      for k := 0 to High(Cls) do
        if Cls[k] = Cid then c := k;
      if c < 0 then
      begin
        c := Length(Cls);
        SetLength(Cls, c + 1);
        SetLength(Cnt, c + 1);
        SetLength(Vals, c + 1);
        Cls[c] := Cid;
        Cnt[c] := 0;
        Vals[c] := '';
      end;
      if Cnt[c] < 4 then   // hoechstens 4 Werte je Klasse, sonst zaehlen Zahlen zu stark
      begin
        Inc(Cnt[c]);
        if Vals[c] <> '' then Vals[c] := Vals[c] + ', ';
        Vals[c] := Vals[c] + Fld(Q.Fields[1]);
      end;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  for c := 0 to High(Cls) do
    AddPoints(Cls[c], Cnt[c] * WMerkmal, 'Merkmalswerte stimmen überein: ' + Vals[c]);
end;

{ Werkstoff: nur als Zugabe fuer Klassen, die schon aus anderen Gruenden in Frage kommen }
procedure TPointsSuggester.ByMaterial(ATokens: TStringList);
var
  Q: TSQLQuery;
  Cond, Txt, Tk: string;
  Use: TStringList;
  i, idx: Integer;
  Cid: Int64;
  Done: TStringList;
begin
  if Length(FIds) = 0 then Exit;
  Use := TStringList.Create;
  Done := TStringList.Create;
  try
    for i := 0 to ATokens.Count - 1 do
      if (Length(ATokens[i]) >= 4) and (SqlSafe(ATokens[i]) = ATokens[i]) and
        (not IsNormToken(ATokens[i])) and (Use.Count < 8) then
        Use.Add(ATokens[i]);
    if Use.Count = 0 then Exit;
    Cond := '';
    for i := 0 to Use.Count - 1 do
    begin
      if Cond <> '' then Cond := Cond + ' OR ';
      Cond := Cond + 'UPPER(pv.value) LIKE ''%' + Use[i] + '%''';
    end;
    Q := TSQLQuery.Create(nil);
    try
      Q.DataBase := FConn;
      Q.Transaction := FTrans;
      Q.SQL.Text := 'SELECT pt.class_id, UPPER(pv.value) FROM part_value pv ' +
        'JOIN property p ON p.id=pv.property_id JOIN part pt ON pt.id=pv.part_id ' +
        'WHERE p.code=''WERKSTOFF'' AND (' + Cond + ') GROUP BY pt.class_id, UPPER(pv.value)';
      Q.Open;
      while not Q.EOF do
      begin
        Cid := Q.Fields[0].AsLargeInt;
        Txt := NormText(Fld(Q.Fields[1]));
        idx := IndexOfClass(Cid);
        if idx >= 0 then
          for i := 0 to Use.Count - 1 do
          begin
            Tk := Use[i];
            if (Pos(Tk, Txt) > 0) and (Done.IndexOf(IntToStr(Cid) + '/' + Tk) < 0) then
            begin
              Done.Add(IntToStr(Cid) + '/' + Tk);
              AddPoints(Cid, WMaterial, 'Werkstoff ' + Tk);
            end;
          end;
        Q.Next;
      end;
      Q.Close;
    finally
      Q.Free;
    end;
  finally
    Done.Free;
    Use.Free;
  end;
end;

{ fruehere Zuordnungen des Benutzers (Tabelle suggest_history) }
procedure TPointsSuggester.ByHistory(ATokens: TStringList);
var
  Q: TSQLQuery;
  H: TStringList;
  i, Common, Need: Integer;
  Cid: Int64;
  Cls: array of Int64;
  Cnt: array of Integer;
  c, k: Integer;
begin
  H := TStringList.Create;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConn;
    Q.Transaction := FTrans;
    Q.SQL.Text := 'SELECT chosen_class_id, article_text FROM suggest_history ' +
      'WHERE chosen_class_id IS NOT NULL ORDER BY id DESC LIMIT 2000';
    Q.Open;
    while not Q.EOF do
    begin
      Cid := Q.Fields[0].AsLargeInt;
      TokenizeText(Fld(Q.Fields[1]), H);
      Common := 0;
      for i := 0 to H.Count - 1 do
        if ATokens.IndexOf(H[i]) >= 0 then Inc(Common);
      if ATokens.Count <= 2 then Need := 1 else Need := 2;
      if Common >= Need then
      begin
        c := -1;
        for k := 0 to High(Cls) do
          if Cls[k] = Cid then c := k;
        if c < 0 then
        begin
          c := Length(Cls);
          SetLength(Cls, c + 1);
          SetLength(Cnt, c + 1);
          Cls[c] := Cid;
          Cnt[c] := 0;
        end;
        if Cnt[c] < 3 then Inc(Cnt[c]);
      end;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
    H.Free;
  end;
  for c := 0 to High(Cls) do
    AddPoints(Cls[c], Cnt[c] * WHistorie,
      IntToStr(Cnt[c]) + ' frühere Zuordnung(en) mit ähnlichem Text');
end;

function TPointsSuggester.Suggest(const AInput: TSuggestInput): TSuggestResult;
var
  Tokens: TStringList;
  Full: string;
  Q: TSQLQuery;
  Ids: string;
  i, j, n, Bi: Integer;
  Cid: Int64;
  Tmp: TSuggestItem;
  Lv: Integer;
begin
  Result.Items := nil;
  Result.HasMatch := False;
  Result.NewParentId := 0;
  Result.Tokens := '';
  FIds := nil;
  FPts := nil;
  FWhy := nil;
  LoadWeights;
  Tokens := TStringList.Create;
  try
    Full := AInput.Description + ' ' + AInput.Manufacturer + ' ' + AInput.Supplier + ' ' +
      AInput.Extra;
    TokenizeText(Full, Tokens);
    Result.Tokens := StringReplace(Trim(Tokens.Text), LineEnding, ', ', [rfReplaceAll]);
    if Result.Tokens <> '' then
      while (Result.Tokens <> '') and (Result.Tokens[Length(Result.Tokens)] in [',', ' ']) do
        Delete(Result.Tokens, Length(Result.Tokens), 1);
    if Tokens.Count = 0 then Exit;

    ByTerms(Tokens, NormText(Full));
    ByNorm(Tokens);
    BySimilar(Tokens);
    ByValues(Tokens);
    ByMaterial(Tokens);
    ByHistory(Tokens);
  finally
    Tokens.Free;
  end;
  if Length(FIds) = 0 then Exit;

  // Klassennummer und Name zu den gefundenen Klassen holen
  Ids := '';
  for i := 0 to High(FIds) do
  begin
    if Ids <> '' then Ids := Ids + ',';
    Ids := Ids + IntToStr(FIds[i]);
  end;
  n := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := FConn;
    Q.Transaction := FTrans;
    Q.SQL.Text := 'SELECT id, COALESCE(class_no,''''), name FROM class WHERE id IN (' + Ids + ')';
    Q.Open;
    while not Q.EOF do
    begin
      Cid := Q.Fields[0].AsLargeInt;
      i := IndexOfClass(Cid);
      if i >= 0 then
      begin
        SetLength(Result.Items, n + 1);
        Result.Items[n].ClassId := Cid;
        Result.Items[n].ClassNo := Fld(Q.Fields[1]);
        Result.Items[n].ClassName := Fld(Q.Fields[2]);
        Result.Items[n].Points := FPts[i];
        Result.Items[n].Reasons := FWhy[i];
        Inc(n);
      end;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  // absteigend nach Punkten, bei Gleichstand die allgemeinere Klasse zuerst
  for i := 0 to n - 2 do
  begin
    Bi := i;
    for j := i + 1 to n - 1 do
      if (Result.Items[j].Points > Result.Items[Bi].Points) or
        ((Result.Items[j].Points = Result.Items[Bi].Points) and
         (Result.Items[j].ClassNo < Result.Items[Bi].ClassNo)) then
        Bi := j;
    if Bi <> i then
    begin
      Tmp := Result.Items[i];
      Result.Items[i] := Result.Items[Bi];
      Result.Items[Bi] := Tmp;
    end;
  end;
  if n > 8 then SetLength(Result.Items, 8);
  if n = 0 then Exit;
  Result.HasMatch := Result.Items[0].Points >= WBegriff;

  // Oberklasse fuer eine moegliche neue Klasse: die beste Klasse, ausser sie ist
  // schon auf der 4. Ebene, dann deren Oberklasse
  Lv := ClassNoLevelOf(Result.Items[0].ClassNo);
  if Lv >= 4 then
  begin
    Q := TSQLQuery.Create(nil);
    try
      Q.DataBase := FConn;
      Q.Transaction := FTrans;
      Q.SQL.Text := 'SELECT COALESCE(parent_id,0) FROM class WHERE id=' +
        IntToStr(Result.Items[0].ClassId);
      Q.Open;
      Result.NewParentId := Q.Fields[0].AsLargeInt;
      Q.Close;
    finally
      Q.Free;
    end;
  end
  else
    Result.NewParentId := Result.Items[0].ClassId;
end;

end.
