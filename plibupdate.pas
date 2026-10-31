unit PlibUpdate;

{ Update-Pruefung von PLIB.

  Die Quelle (plib.ini, [Update] Quelle=) kann sein:
    - eine Textdatei (z. B. auf dem NAS, UNC-Pfad oder Laufwerk) mit den Zeilen
        Version=1.2
        Download=PLIB_Setup_1.2.exe        (Dateiname im selben Ordner, voller Pfad oder URL)
        Hinweis=Was ist neu ...            ("|" = Zeilenumbruch)
    - eine Internetadresse (http/https) auf eine solche Textdatei
    - die GitHub-Schnittstelle .../repos/<Benutzer>/<Repo>/releases/latest
      (funktioniert nur bei oeffentlichem Repository)
  Die Pruefung laeuft in einem eigenen Thread, damit PLIB beim Start nicht wartet. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils;

const
  GitHubDefaultSource = 'https://api.github.com/repos/AirRacePilot/PLIB/releases/latest';

type
  TUpdateInfo = record
    Ok: Boolean;            // Quelle gelesen
    Available: Boolean;     // neuere Version vorhanden
    Version: string;        // Version laut Quelle
    Notes: string;          // Hinweistext
    Download: string;       // Datei oder Adresse des Installers
    Error: string;          // Fehlermeldung, wenn nicht Ok
  end;

  TUpdateDoneEvent = procedure(const AInfo: TUpdateInfo; AManual: Boolean) of object;

{ Vergleicht Versionsnummern wie 1.10 und 1.9; <0, 0, >0 }
function CompareVersions(const A, B: string): Integer;

{ Liest die Quelle und vergleicht mit der laufenden Version }
procedure QueryUpdate(const ASource, ACurrent: string; out AInfo: TUpdateInfo);

{ Holt den Installer in den Temp-Ordner; Rueckgabe = lokale Datei ('' bei Fehler) }
function FetchInstaller(const ADownload: string; out AError: string): string;

{ Startet die Pruefung im Hintergrund; ADone wird im Hauptthread aufgerufen }
procedure StartUpdateCheck(const ASource, ACurrent: string; AManual: Boolean;
  ADone: TUpdateDoneEvent);

implementation

uses
  {$IFDEF WINDOWS}
  Windows, WinInet,
  {$ELSE}
  fphttpclient, opensslsockets,
  {$ENDIF}
  fpjson, jsonparser;

type
  TUpdateThread = class(TThread)
  private
    FSource, FCurrent: string;
    FManual: Boolean;
    FDone: TUpdateDoneEvent;
    FInfo: TUpdateInfo;
    procedure Deliver;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASource, ACurrent: string; AManual: Boolean;
      ADone: TUpdateDoneEvent);
  end;

function IsUrl(const S: string): Boolean;
begin
  Result := (Pos('http://', LowerCase(S)) = 1) or (Pos('https://', LowerCase(S)) = 1);
end;

function VersionPart(const S: string; AIndex: Integer): Integer;
var
  I, N, Start, Cnt: Integer;
begin
  Result := 0;
  Cnt := 0;
  Start := 1;
  for I := 1 to Length(S) + 1 do
    if (I > Length(S)) or (S[I] = '.') then
    begin
      if Cnt = AIndex then
      begin
        N := 0;
        // nur die fuehrenden Ziffern des Teils zaehlen ("2beta" -> 2)
        while (Start <= Length(S)) and (S[Start] in ['0'..'9']) do
        begin
          N := N * 10 + Ord(S[Start]) - Ord('0');
          Inc(Start);
        end;
        Result := N;
        Exit;
      end;
      Inc(Cnt);
      Start := I + 1;
    end;
end;

function CompareVersions(const A, B: string): Integer;
var
  I, X, Y: Integer;
begin
  Result := 0;
  for I := 0 to 5 do
  begin
    X := VersionPart(A, I);
    Y := VersionPart(B, I);
    if X <> Y then
    begin
      if X < Y then Result := -1 else Result := 1;
      Exit;
    end;
  end;
end;

{ Laedt eine Internetadresse in einen Stream.
  Windows: eingebaute Internetfunktion (WinINet), braucht keine eigene SSL-Bibliothek
  und nutzt die Zertifikate von Windows. Sonst: fphttpclient. }
procedure HttpToStream(const AUrl: string; AOut: TStream; ATimeoutMs: Integer);
{$IFDEF WINDOWS}
const
  cConnectTimeout = 2;     // INTERNET_OPTION_CONNECT_TIMEOUT
  cReceiveTimeout = 6;     // INTERNET_OPTION_RECEIVE_TIMEOUT
var
  hNet, hUrl: HINTERNET;
  Buf: array[0..8191] of Byte;
  Got, Status, Len, Idx, T: DWORD;
  A: AnsiString;
begin
  hNet := InternetOpenA('PLIB-Update', 0, nil, nil, 0);   // 0 = Proxy-Einstellung von Windows
  if hNet = nil then
    raise Exception.Create('Die Internetverbindung konnte nicht geoeffnet werden (Fehler ' +
      IntToStr(GetLastError) + ').');
  try
    T := ATimeoutMs;
    InternetSetOption(hNet, cConnectTimeout, @T, SizeOf(T));
    InternetSetOption(hNet, cReceiveTimeout, @T, SizeOf(T));
    A := AnsiString(AUrl);
    hUrl := InternetOpenUrlA(hNet, PAnsiChar(A), nil, 0,
      $80000000 or $04000000, 0);   // RELOAD | NO_CACHE_WRITE
    if hUrl = nil then
      raise Exception.Create('Die Adresse ist nicht erreichbar (Fehler ' +
        IntToStr(GetLastError) + ').');
    try
      Status := 0;
      Len := SizeOf(Status);
      Idx := 0;
      if HttpQueryInfoA(hUrl, 19 or $20000000, @Status, Len, Idx) and (Status <> 200) then
        raise Exception.Create('Der Server antwortet mit Status ' + IntToStr(Status) +
          IfThen(Status = 404, ' (nicht gefunden)', '') + '.');
      repeat
        Got := 0;
        if not InternetReadFile(hUrl, @Buf, SizeOf(Buf), Got) then
          raise Exception.Create('Lesefehler beim Herunterladen (Fehler ' +
            IntToStr(GetLastError) + ').');
        if Got > 0 then AOut.WriteBuffer(Buf, Got);
      until Got = 0;
    finally
      InternetCloseHandle(hUrl);
    end;
  finally
    InternetCloseHandle(hNet);
  end;
end;
{$ELSE}
var
  C: TFPHTTPClient;
begin
  C := TFPHTTPClient.Create(nil);
  try
    C.AllowRedirect := True;
    C.IOTimeout := ATimeoutMs;
    C.AddHeader('User-Agent', 'PLIB-Update');
    C.SimpleGet(AUrl, AOut);
  finally
    C.Free;
  end;
end;
{$ENDIF}

function HttpGetText(const AUrl: string): string;
var
  SS: TStringStream;
begin
  SS := TStringStream.Create('');
  try
    HttpToStream(AUrl, SS, 8000);
    Result := SS.DataString;
  finally
    SS.Free;
  end;
end;

function ResolveDownload(const ASource, ADownload: string): string;
var
  P: Integer;
begin
  Result := Trim(ADownload);
  if Result = '' then Exit;
  if IsUrl(Result) then Exit;
  // voller Pfad (Laufwerk, UNC, Unix)?
  if (Pos(':', Result) > 0) or (Result[1] in ['\', '/']) then Exit;
  // sonst relativ zur Quelle
  if IsUrl(ASource) then
  begin
    P := Length(ASource);
    while (P > 0) and (ASource[P] <> '/') do Dec(P);
    Result := Copy(ASource, 1, P) + Result;
  end
  else
    Result := ExtractFilePath(ASource) + Result;
end;

procedure ParseText(const ASource, AText: string; var AInfo: TUpdateInfo);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Text := AText;
    AInfo.Version := Trim(L.Values['Version']);
    AInfo.Download := ResolveDownload(ASource, L.Values['Download']);
    AInfo.Notes := StringReplace(Trim(L.Values['Hinweis']), '|', LineEnding, [rfReplaceAll]);
  finally
    L.Free;
  end;
end;

procedure ParseGitHub(const AText: string; var AInfo: TUpdateInfo);
var
  J: TJSONData;
  O, A: TJSONObject;
  Assets: TJSONArray;
  I: Integer;
  Name, Ext, Want: string;
begin
  J := GetJSON(AText);
  try
    if not (J is TJSONObject) then Exit;
    O := TJSONObject(J);
    AInfo.Version := Trim(O.Get('tag_name', ''));
    if (AInfo.Version <> '') and (AInfo.Version[1] in ['v', 'V']) then
      Delete(AInfo.Version, 1, 1);
    AInfo.Notes := Trim(O.Get('body', ''));
    {$IFDEF WINDOWS}
    Want := '.exe';
    {$ELSE}
    Want := '.dmg';
    {$ENDIF}
    if O.Find('assets') is TJSONArray then
    begin
      Assets := TJSONArray(O.Find('assets'));
      for I := 0 to Assets.Count - 1 do
        if Assets.Items[I] is TJSONObject then
        begin
          A := TJSONObject(Assets.Items[I]);
          Name := A.Get('name', '');
          Ext := LowerCase(ExtractFileExt(Name));
          if (Ext = Want) or ((Want = '.dmg') and (Ext = '.pkg')) then
          begin
            AInfo.Download := A.Get('browser_download_url', '');
            Break;
          end;
        end;
    end;
  finally
    J.Free;
  end;
end;

procedure QueryUpdate(const ASource, ACurrent: string; out AInfo: TUpdateInfo);
var
  Src, Txt: string;
  L: TStringList;
begin
  AInfo.Ok := False;
  AInfo.Available := False;
  AInfo.Version := '';
  AInfo.Notes := '';
  AInfo.Download := '';
  AInfo.Error := '';
  Src := Trim(ASource);
  if Src = '' then Src := GitHubDefaultSource;
  try
    if IsUrl(Src) then
      Txt := HttpGetText(Src)
    else
    begin
      L := TStringList.Create;
      try
        L.LoadFromFile(Src);
        Txt := L.Text;
      finally
        L.Free;
      end;
    end;
    if Pos('api.github.com', LowerCase(Src)) > 0 then
      ParseGitHub(Txt, AInfo)
    else
      ParseText(Src, Txt, AInfo);
    if AInfo.Version = '' then
    begin
      AInfo.Error := 'In der Update-Quelle steht keine Versionsnummer.';
      Exit;
    end;
    AInfo.Ok := True;
    AInfo.Available := CompareVersions(AInfo.Version, ACurrent) > 0;
  except
    on E: Exception do
    begin
      // Fehlertyp immer mit nennen: manche Netzwerkfehler haben keinen Text
      AInfo.Error := E.ClassName;
      if Trim(E.Message) <> '' then AInfo.Error := AInfo.Error + ': ' + E.Message;
      AInfo.Error := AInfo.Error + LineEnding + LineEnding + 'Quelle: ' + Src;
      if Pos('api.github.com', LowerCase(Src)) > 0 then
        AInfo.Error := AInfo.Error + LineEnding +
          '(GitHub liefert bei einem privaten Repository keine Daten. ' +
          'In plib.ini unter [Update] eine Quelle eintragen.)';
    end;
  end;
end;

function FetchInstaller(const ADownload: string; out AError: string): string;
var
  Target, Name: string;
  Src, Dst: TFileStream;
  P: Integer;
begin
  Result := '';
  AError := '';
  if Trim(ADownload) = '' then
  begin
    AError := 'In der Update-Quelle ist kein Installer angegeben.';
    Exit;
  end;
  try
    Name := ADownload;
    P := Pos('?', Name);
    if P > 0 then Name := Copy(Name, 1, P - 1);
    Name := ExtractFileName(StringReplace(Name, '/', PathDelim, [rfReplaceAll]));
    if Name = '' then Name := 'PLIB_Update.exe';
    Target := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'PLIB_Update_' + Name;
    if FileExists(Target) then SysUtils.DeleteFile(Target);
    if IsUrl(ADownload) then
    begin
      Dst := TFileStream.Create(Target, fmCreate);
      try
        HttpToStream(ADownload, Dst, 30000);
      finally
        Dst.Free;
      end;
    end
    else
    begin
      Src := TFileStream.Create(ADownload, fmOpenRead or fmShareDenyNone);
      try
        Dst := TFileStream.Create(Target, fmCreate);
        try
          Dst.CopyFrom(Src, 0);
        finally
          Dst.Free;
        end;
      finally
        Src.Free;
      end;
    end;
    if FileExists(Target) then Result := Target
    else AError := 'Der Installer konnte nicht gespeichert werden.';
  except
    on E: Exception do
    begin
      Result := '';
      AError := E.Message;
    end;
  end;
end;

{ ---------- Thread ---------- }

constructor TUpdateThread.Create(const ASource, ACurrent: string; AManual: Boolean;
  ADone: TUpdateDoneEvent);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSource := ASource;
  FCurrent := ACurrent;
  FManual := AManual;
  FDone := ADone;
end;

procedure TUpdateThread.Execute;
begin
  QueryUpdate(FSource, FCurrent, FInfo);
  if Assigned(FDone) then Synchronize(@Deliver);
end;

procedure TUpdateThread.Deliver;
begin
  FDone(FInfo, FManual);
end;

procedure StartUpdateCheck(const ASource, ACurrent: string; AManual: Boolean;
  ADone: TUpdateDoneEvent);
var
  T: TUpdateThread;
begin
  T := TUpdateThread.Create(ASource, ACurrent, AManual, ADone);
  T.Start;
end;

end.
