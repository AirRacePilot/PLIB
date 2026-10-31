program plib_solidcraft_step;

{ PLIB-Plugin: erzeugt zu einem Normteil mit SolidCraft eine STEP-Datei.

  Aufruf (macht PLIB):  plib_solidcraft_step <anfrage.json> <ergebnis.json>

  Das Teil wird direkt in der obersten Ebene modelliert (kein Bauteil, keine Baugruppe), damit die
  STEP-Datei ein Einzelteil ist. Die Masse kommen aus den Merkmalswerten des Teils in PLIB:
    ZKS  (Zylinderschraube, ISO 4762)   DN, L, DK, K, SWI      Tiefe des Innensechskants = 0,5 * K
    SKS  (Sechskantschraube, ISO 4017/4014)   DN, L, SW, K
    SKM  (Sechskantmutter, ISO 4032/4035)     DN, SW, M
    USC  (Scheiben, ISO 7089/7090/7092/7093)  D1, D2, S
    LKS  (Linsenkopfschraube, ISO 7380-1)     DN, L, DK, K, SWI
    GST  (Gewindestifte, ISO 4026-4029)       DN, L, SWI   (Kuppenform je nach Klasse)
    STI  (Zylinderstifte, ISO 2338/8734)      DN, L
  Gewinde, Fasen und Rundungen werden nicht modelliert (in STEP ist das Gewinde ohnehin glatt). }

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, IniFiles, fpjson, jsonparser, Process;

var
  ResultFile: string;
  Vals: TJSONObject;          // Merkmalswerte aus der Anfrage (kann nil sein)
  Cmds: TStringList;          // SolidCraft-Befehle als fertiger JSON-Text
  Missing: string;            // fehlende Merkmale

{ ---------- Hilfen ---------- }

function Fmt(X: Double): string;
var
  FS: TFormatSettings;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Result := FormatFloat('0.####', X, FS);
  if Result = '-0' then Result := '0';
end;

procedure WriteResult(Ok: Boolean; const AFile, Msg: string; Reused: Boolean);
var
  O: TJSONObject;
  SL: TStringList;
begin
  O := TJSONObject.Create;
  try
    O.Booleans['ok'] := Ok;
    O.Strings['file'] := AFile;
    O.Booleans['reused'] := Reused;
    O.Strings['message'] := Msg;
    SL := TStringList.Create;
    try
      SL.Text := O.AsJSON;
      SL.SaveToFile(ResultFile);
    finally
      SL.Free;
    end;
  finally
    O.Free;
  end;
end;

{ Zahl zu einem Merkmalscode; Dezimalkomma wird akzeptiert. Fehlt sie, kommt der Code in Missing. }
function Need(const Code: string): Double;
var
  S: string;
  Err: Integer;
  V: Double;
begin
  Result := 0;
  S := '';
  if Vals <> nil then S := Trim(Vals.Get(Code, ''));
  S := StringReplace(S, ',', '.', [rfReplaceAll]);
  V := 0;
  if S <> '' then Val(S, V, Err) else Err := 1;
  if (Err <> 0) or (V <= 0) then
  begin
    if Missing <> '' then Missing := Missing + ', ';
    Missing := Missing + Code;
  end
  else
    Result := V;
end;

procedure AddCmd(const Name, Params: string);
begin
  Cmds.Add('{"command":"' + Name + '","params":{' + Params + '}}');
end;

{ Sechskant-Prisma (Schluesselweite AF) von Z0 bis Z1: Op = new, join oder cut }
procedure HexPrism(AF, Z0, Z1: Double; const Op: string);
var
  Dist: Double;
  Dir: string;
begin
  if Z1 >= Z0 then
  begin
    Dist := Z1 - Z0;
    Dir := 'positive';
  end
  else
  begin
    Dist := Z0 - Z1;
    Dir := 'negative';
  end;
  AddCmd('sketch.create', '"plane":"XY","offset":"' + Fmt(Z0) + ' mm"');
  AddCmd('sketch.polygon.circumscribed', '"center":[0,0],"radius":' + Fmt(AF / 2) + ',"sides":6');
  AddCmd('sketch.finish', '');
  AddCmd('solid.extrude', '"distance":"' + Fmt(Dist) + ' mm","direction":"' + Dir +
    '","operation":"' + Op + '"');
end;

{ Drehkoerper um die Z-Achse aus einem geschlossenen Umriss; RZ = r0, z0, r1, z1, ... }
procedure Revolved(const RZ: array of Double; const Op: string);
var
  I: Integer;
  S: string;
begin
  S := '';
  I := 0;
  while I + 1 <= High(RZ) do
  begin
    if S <> '' then S := S + ',';
    S := S + '[' + Fmt(RZ[I]) + ',' + Fmt(0 - RZ[I + 1]) + ']';
    Inc(I, 2);
  end;
  AddCmd('sketch.create', '"plane":"XZ"');
  AddCmd('sketch.line', '"points":[' + S + '],"closed":true');
  AddCmd('sketch.finish', '');
  AddCmd('solid.revolve', '"axis":"y","operation":"' + Op + '"');
end;

{ ---------- Bauvorschriften ---------- }

function Family(AChain: TJSONArray; const AClass: string): string;

  function Pick(const C: string): string;
  var
    U: string;
  begin
    U := UpperCase(C);
    Result := '';
    if Pos('ZKS_', U) = 1 then Result := 'ZKS'
    else if Pos('SKS_', U) = 1 then Result := 'SKS'
    else if Pos('SKM_', U) = 1 then Result := 'SKM'
    else if Pos('USC_', U) = 1 then Result := 'USC'
    else if Pos('LKS_', U) = 1 then Result := 'LKS'
    else if Pos('STI_', U) = 1 then Result := 'STI'
    else if Pos('GST_', U) = 1 then Result := 'GST' + Copy(U, 5, 4);
  end;

var
  I: Integer;
begin
  Result := Pick(AClass);
  if (Result = '') and (AChain <> nil) then
    for I := 0 to AChain.Count - 1 do
    begin
      Result := Pick(AChain.Strings[I]);
      if Result <> '' then Exit;
    end;
end;

procedure BuildPart(const Fam: string);
var
  DN, L, DK, K, SWI, SW, M, D1, D2, S, Tt, R0, Z, DP, C: Double;
begin
  if Fam = 'ZKS' then
  begin
    DN := Need('DN'); L := Need('L'); DK := Need('DK'); K := Need('K'); SWI := Need('SWI');
    if Missing <> '' then Exit;
    Revolved([0, -L, DN / 2, -L, DN / 2, 0, DK / 2, 0, DK / 2, K, 0, K], 'new');
    HexPrism(SWI, K, K - 0.5 * K, 'cut');
  end
  else if Fam = 'SKS' then
  begin
    DN := Need('DN'); L := Need('L'); SW := Need('SW'); K := Need('K');
    if Missing <> '' then Exit;
    HexPrism(SW, 0, K, 'new');
    Revolved([0, -L, DN / 2, -L, DN / 2, K / 2, 0, K / 2], 'join');
  end
  else if Fam = 'SKM' then
  begin
    DN := Need('DN'); SW := Need('SW'); M := Need('M');
    if Missing <> '' then Exit;
    HexPrism(SW, 0, M, 'new');
    AddCmd('solid.cylinder', '"diameter":"' + Fmt(DN) + ' mm","height":"' + Fmt(M + 2) +
      ' mm","base":[0,0,-1],"axis":[0,0,1],"operation":"cut"');
  end
  else if Fam = 'USC' then
  begin
    D1 := Need('D1'); D2 := Need('D2'); S := Need('S');
    if Missing <> '' then Exit;
    Revolved([D1 / 2, 0, D2 / 2, 0, D2 / 2, S, D1 / 2, S], 'new');
  end
  else if Fam = 'LKS' then
  begin
    DN := Need('DN'); L := Need('L'); DK := Need('DK'); K := Need('K'); SWI := Need('SWI');
    if Missing <> '' then Exit;
    // Linsenkopf vereinfacht: Rand bis 0,4 K, dann abgeflacht zur Oberseite
    Revolved([0, -L, DN / 2, -L, DN / 2, 0, DK / 2, 0, DK / 2, 0.4 * K, 0.3 * DK, K, 0, K], 'new');
    HexPrism(SWI, K, K - 0.6 * K, 'cut');
  end
  else if Copy(Fam, 1, 3) = 'GST' then
  begin
    DN := Need('DN'); L := Need('L'); SWI := Need('SWI');
    if Missing <> '' then Exit;
    R0 := DN / 2;
    Tt := SWI;
    if Tt > 0.6 * L then Tt := 0.6 * L;
    Z := 0.5 * DN;
    if Z > 0.6 * L then Z := 0.6 * L;
    if Fam = 'GST4027' then            // Kegelkuppe
      Revolved([0, -L, 0.1 * DN, -L, R0, -L + Z, R0, 0, 0, 0], 'new')
    else if Fam = 'GST4028' then       // Zapfen
    begin
      DP := 0.65 * DN;
      Revolved([0, -L, DP / 2, -L, DP / 2, -L + Z, R0, -L + Z, R0, 0, 0, 0], 'new');
    end
    else if Fam = 'GST4029' then       // Ringschneide (flache Mulde in der Mitte)
      Revolved([0, -L + 0.1 * DN, 0.3 * DN, -L + 0.1 * DN, 0.3 * DN, -L, R0, -L, R0, 0, 0, 0], 'new')
    else                               // Flaechenkuppe (4026)
      Revolved([0, -L, R0, -L, R0, 0, 0, 0], 'new');
    HexPrism(SWI, 0, -Tt, 'cut');
  end
  else if Fam = 'STI' then
  begin
    DN := Need('DN'); L := Need('L');
    if Missing <> '' then Exit;
    R0 := DN / 2;
    C := 0.1 * DN;
    if C > 0.2 * L then C := 0.2 * L;
    Revolved([0, 0, R0 - C, 0, R0, -C, R0, -L + C, R0 - C, -L, 0, -L], 'new');
  end;
end;

{ ---------- SolidCraft aufrufen ---------- }

function FindCli: string;
var
  Ini: TIniFile;
  C: string;
begin
  Result := '';
  C := ExtractFilePath(ParamStr(0)) + 'plugin.ini';
  if FileExists(C) then
  begin
    Ini := TIniFile.Create(C);
    try
      Result := Trim(Ini.ReadString('SolidCraft', 'Cli', ''));
    finally
      Ini.Free;
    end;
    if (Result <> '') and FileExists(Result) then Exit;
  end;
  Result := 'C:\Program Files\SolidCraft\solidcraft-cli.exe';
  if FileExists(Result) then Exit;
  Result := ExeSearch('solidcraft-cli.exe', GetEnvironmentVariable('PATH'));
end;

function RunCli(const Cli, Script, Target: string; out Output: string): Integer;
var
  P: TProcess;
  Buf: array[0..4095] of Byte;
  N: Integer;
  SS: TStringStream;
begin
  SS := TStringStream.Create('');
  P := TProcess.Create(nil);
  try
    P.Executable := Cli;
    P.Parameters.Add('run');
    P.Parameters.Add(Script);
    P.Parameters.Add('--out');
    P.Parameters.Add(Target);
    P.Parameters.Add('--quiet');
    P.Options := [poUsePipes, poStderrToOutput, poNoConsole];
    P.ShowWindow := swoHide;
    P.Execute;
    repeat
      N := P.Output.Read(Buf, SizeOf(Buf));
      if N > 0 then SS.Write(Buf, N);
    until N <= 0;
    P.WaitOnExit;
    Result := P.ExitStatus;
    Output := SS.DataString;
  finally
    P.Free;
    SS.Free;
  end;
end;

{ ---------- Ablauf ---------- }

procedure Run(const ReqFile: string);
var
  FS: TFileStream;
  Data: TJSONData;
  Req: TJSONObject;
  Chain: TJSONArray;
  Target, ClassCode, Fam, Cli, ScriptFile, Output, Body: string;
  Overwrite: Boolean;
  Node: TJSONData;
  I, Code: Integer;
  SL: TStringList;
begin
  FS := TFileStream.Create(ReqFile, fmOpenRead or fmShareDenyNone);
  try
    Data := GetJSON(FS);
  finally
    FS.Free;
  end;
  try
    if (Data = nil) or (Data.JSONType <> jtObject) then
    begin
      WriteResult(False, '', 'Die Anfrage von PLIB ist nicht lesbar.', False);
      Exit;
    end;
    Req := TJSONObject(Data);
    Target := Req.Get('target', '');
    ClassCode := Req.Get('class_code', '');
    Overwrite := Req.Get('overwrite', False);
    Chain := nil;
    Node := Req.Find('class_chain');
    if (Node <> nil) and (Node.JSONType = jtArray) then Chain := TJSONArray(Node);
    Vals := nil;
    Node := Req.Find('values');
    if (Node <> nil) and (Node.JSONType = jtObject) then Vals := TJSONObject(Node);

    if Target = '' then
    begin
      WriteResult(False, '', 'Die Anfrage enthaelt keine Zieldatei.', False);
      Exit;
    end;
    if FileExists(Target) and (not Overwrite) then
    begin
      WriteResult(True, Target, 'Vorhandene STEP-Datei wird verwendet.', True);
      Exit;
    end;

    Fam := Family(Chain, ClassCode);
    if Fam = '' then
    begin
      WriteResult(False, '', 'Fuer die Klasse ' + ClassCode + ' gibt es keine Bauvorschrift in diesem Plugin.', False);
      Exit;
    end;

    Cmds := TStringList.Create;
    try
      Missing := '';
      BuildPart(Fam);
      if Missing <> '' then
      begin
        WriteResult(False, '', 'Fuer dieses Teil fehlen Merkmalswerte (oder sie sind 0): ' + Missing, False);
        Exit;
      end;
      Body := '';
      for I := 0 to Cmds.Count - 1 do
      begin
        if I > 0 then Body := Body + ',' + LineEnding;
        Body := Body + Cmds[I];
      end;

      Cli := FindCli;
      if Cli = '' then
      begin
        WriteResult(False, '', 'solidcraft-cli.exe wurde nicht gefunden. Pfad in plugin.ini unter [SolidCraft] Cli= eintragen.', False);
        Exit;
      end;
      if not ForceDirectories(ExtractFileDir(Target)) then
      begin
        WriteResult(False, '', 'Der Zielordner konnte nicht angelegt werden: ' + ExtractFileDir(Target), False);
        Exit;
      end;

      ScriptFile := IncludeTrailingPathDelimiter(GetTempDir) + 'plib_sc_' + IntToStr(GetTickCount64) + '.json';
      SL := TStringList.Create;
      try
        SL.Text := '{"commands":[' + LineEnding + Body + LineEnding + ']}';
        SL.SaveToFile(ScriptFile);
      finally
        SL.Free;
      end;
      try
        Output := '';
        Code := RunCli(Cli, ScriptFile, Target, Output);
      finally
        DeleteFile(ScriptFile);
      end;
      if (Code <> 0) or (not FileExists(Target)) then
      begin
        Output := Trim(Output);
        if Length(Output) > 600 then Output := Copy(Output, 1, 600) + ' ...';
        WriteResult(False, '', 'SolidCraft hat die Datei nicht erzeugt (Rueckgabe ' + IntToStr(Code) + '). ' + Output, False);
        Exit;
      end;
      WriteResult(True, Target, 'STEP-Datei erzeugt.', False);
    finally
      Cmds.Free;
    end;
  finally
    Data.Free;
  end;
end;

begin
  if ParamCount < 2 then
  begin
    WriteLn('Aufruf: plib_solidcraft_step <anfrage.json> <ergebnis.json>');
    Halt(2);
  end;
  ResultFile := ParamStr(2);
  try
    Run(ParamStr(1));
  except
    on E: Exception do
      WriteResult(False, '', 'Fehler im Plugin: ' + E.Message, False);
  end;
end.
