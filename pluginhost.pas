unit PluginHost;

{ Plugin-Anbindung fuer PLIB.

  Ein Plugin ist ein eigenes Programm in einem Unterordner des Ordners "plugins" neben der plib.exe.
  Beschrieben wird es durch die Datei plugin.ini in diesem Unterordner:

    [Plugin]
    Name=STEP-Modell erzeugen (SolidCraft)
    Programm=plib_solidcraft_step.exe
    Klassen=ZKS_4762,SKS_4017        (leer = fuer alle Klassen)

  Aufruf des Programms:  <programm> <anfrage.json> <ergebnis.json>

  Die Anfrage (JSON) enthaelt Teilenummer, Beschreibung, Klassencode, die Klassenkette bis zur
  Wurzel, alle Merkmalswerte (Merkmalscode -> Wert, Dezimalkomma wie gespeichert), deren Einheiten,
  die gewuenschte Zieldatei und ob eine vorhandene Datei ueberschrieben werden soll.
  Das Ergebnis (JSON) meldet ok (true/false), file (Zieldatei), reused (vorhandene Datei benutzt)
  und message (Text fuer die Statuszeile bzw. die Fehlermeldung). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, fpjson, jsonparser, Process;

type
  TPluginInfo = record
    Name: string;      // Text im Menue
    Exe: string;       // voller Pfad des Programms
    Dir: string;       // Ordner des Plugins (mit Pfadtrenner am Ende)
    Classes: string;   // ,CODE1,CODE2,  in Grossbuchstaben; ,, = alle Klassen
  end;
  TPluginInfos = array of TPluginInfo;

{ Liest alle Plugins aus dem Ordner; Plugins ohne vorhandenes Programm werden uebergangen }
function LoadPlugins(const APluginDir: string): TPluginInfos;

{ Ist das Plugin fuer eine der Klassen der Kette (Klasse des Teils und ihre Oberklassen) gedacht? }
function PluginAcceptsChain(const P: TPluginInfo; AChain: TStrings): Boolean;

{ Baut die Anfrage; ACodes, AVals und AUnits sind gleich lang (Merkmalscode, Wert, Einheit) }
function BuildPluginRequest(const APartNo, ADesc, AClassCode: string;
  AChain, ACodes, AVals, AUnits: TStrings; const ATarget: string;
  AOverwrite: Boolean): string;

{ Startet das Plugin, wartet auf sein Ende und liest das Ergebnis }
function RunPlugin(const P: TPluginInfo; const ARequest: string;
  out AFile, AMessage: string; out AReused: Boolean): Boolean;

implementation

function LoadPlugins(const APluginDir: string): TPluginInfos;
var
  SR: TSearchRec;
  Root, Dir, IniName, Prog, Cls: string;
  Ini: TIniFile;
  P: TPluginInfo;
  N: Integer;
begin
  Result := nil;
  N := 0;
  if not DirectoryExists(APluginDir) then Exit;
  Root := IncludeTrailingPathDelimiter(APluginDir);
  if FindFirst(Root + '*', faDirectory, SR) <> 0 then Exit;
  try
    repeat
      if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        Dir := IncludeTrailingPathDelimiter(Root + SR.Name);
        IniName := Dir + 'plugin.ini';
        if FileExists(IniName) then
        begin
          Ini := TIniFile.Create(IniName);
          try
            Prog := Trim(Ini.ReadString('Plugin', 'Programm', ''));
            P.Name := Trim(Ini.ReadString('Plugin', 'Name', SR.Name));
            Cls := Trim(Ini.ReadString('Plugin', 'Klassen', ''));
          finally
            Ini.Free;
          end;
          P.Dir := Dir;
          P.Exe := Dir + Prog;
          P.Classes := ',' + UpperCase(StringReplace(Cls, ' ', '', [rfReplaceAll])) + ',';
          if (Prog <> '') and FileExists(P.Exe) then
          begin
            SetLength(Result, N + 1);
            Result[N] := P;
            Inc(N);
          end;
        end;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

function PluginAcceptsChain(const P: TPluginInfo; AChain: TStrings): Boolean;
var
  I: Integer;
begin
  Result := P.Classes = ',,';
  if Result then Exit;
  for I := 0 to AChain.Count - 1 do
    if Pos(',' + UpperCase(Trim(AChain[I])) + ',', P.Classes) > 0 then
    begin
      Result := True;
      Exit;
    end;
end;

function BuildPluginRequest(const APartNo, ADesc, AClassCode: string;
  AChain, ACodes, AVals, AUnits: TStrings; const ATarget: string;
  AOverwrite: Boolean): string;
var
  O, V, U: TJSONObject;
  A: TJSONArray;
  I: Integer;
begin
  O := TJSONObject.Create;
  try
    O.Strings['part_number'] := APartNo;
    O.Strings['description'] := ADesc;
    O.Strings['class_code'] := AClassCode;
    A := TJSONArray.Create;
    for I := 0 to AChain.Count - 1 do
      A.Add(AChain[I]);
    O.Add('class_chain', A);
    V := TJSONObject.Create;
    U := TJSONObject.Create;
    for I := 0 to ACodes.Count - 1 do
    begin
      V.Strings[ACodes[I]] := AVals[I];
      U.Strings[ACodes[I]] := AUnits[I];
    end;
    O.Add('values', V);
    O.Add('units', U);
    O.Strings['target'] := ATarget;
    O.Booleans['overwrite'] := AOverwrite;
    Result := O.AsJSON;
  finally
    O.Free;
  end;
end;

function RunPlugin(const P: TPluginInfo; const ARequest: string;
  out AFile, AMessage: string; out AReused: Boolean): Boolean;
var
  Tmp, ReqFile, ResFile: string;
  Proc: TProcess;
  SL: TStringList;
  FS: TFileStream;
  Data: TJSONData;
  Obj: TJSONObject;
begin
  Result := False;
  AFile := '';
  AMessage := '';
  AReused := False;
  Tmp := IncludeTrailingPathDelimiter(GetTempDir) + 'plib_plugin_' + IntToStr(GetTickCount64);
  ReqFile := Tmp + '_anfrage.json';
  ResFile := Tmp + '_ergebnis.json';
  if FileExists(ResFile) then DeleteFile(ResFile);
  SL := TStringList.Create;
  try
    SL.Text := ARequest;
    SL.SaveToFile(ReqFile);
  finally
    SL.Free;
  end;

  Proc := TProcess.Create(nil);
  try
    Proc.Executable := P.Exe;
    Proc.Parameters.Add(ReqFile);
    Proc.Parameters.Add(ResFile);
    Proc.CurrentDirectory := ExcludeTrailingPathDelimiter(P.Dir);
    Proc.Options := [poWaitOnExit, poNoConsole];
    Proc.ShowWindow := swoHide;
    try
      Proc.Execute;
    except
      on E: Exception do
      begin
        AMessage := 'Das Plugin konnte nicht gestartet werden: ' + E.Message;
        DeleteFile(ReqFile);
        Exit;
      end;
    end;
  finally
    Proc.Free;
  end;

  if not FileExists(ResFile) then
  begin
    AMessage := 'Das Plugin hat kein Ergebnis geliefert.';
    DeleteFile(ReqFile);
    Exit;
  end;
  Data := nil;
  try
    FS := TFileStream.Create(ResFile, fmOpenRead or fmShareDenyNone);
    try
      Data := GetJSON(FS);
    finally
      FS.Free;
    end;
    if (Data <> nil) and (Data.JSONType = jtObject) then
    begin
      Obj := TJSONObject(Data);
      Result := Obj.Get('ok', False);
      AFile := Obj.Get('file', '');
      AMessage := Obj.Get('message', '');
      AReused := Obj.Get('reused', False);
    end
    else
      AMessage := 'Das Ergebnis des Plugins ist nicht lesbar.';
  except
    on E: Exception do
    begin
      Result := False;
      AMessage := 'Das Ergebnis des Plugins ist nicht lesbar: ' + E.Message;
    end;
  end;
  Data.Free;
  DeleteFile(ReqFile);
  DeleteFile(ResFile);
end;

end.
