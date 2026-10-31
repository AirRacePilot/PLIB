unit PlibDb;

{ Datenbankzugriff von PLIB (SQLite oder PostgreSQL).

  DbCtx haelt die aktive Verbindung; die Routinen darunter arbeiten immer mit ihr.
  So koennen alle Programmteile (Hauptfenster, Teilesuche, Import ...) dieselben
  Hilfsfunktionen benutzen, ohne das Hauptfenster zu kennen.
  (Ausgelagert aus mainunit.pas, Stand 1.1) }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, DB, SQLDB, PQConnection;

type
  { Ein Record (kein Objekt): immer vorhanden, muss nicht angelegt oder freigegeben werden }
  TPlibDbContext = record
    Conn: TSQLConnection;     // aktive Verbindung (gehoert dem Hauptfenster)
    Trans: TSQLTransaction;
    IsPg: Boolean;            // True: PostgreSQL, False: SQLite
    Batch: Boolean;           // True: Exec bestaetigt nicht nach jedem Befehl
    Lang: string;             // Anzeigesprache ('' = Grundsprache)
  end;

var
  DbCtx: TPlibDbContext;

{ Neue Abfrage auf der aktiven Verbindung (Aufrufer gibt sie frei) }
function NewQuery: TSQLQuery;

procedure Exec(const ASql: string);
{ Zwischenspeicher fuer Klassenwerte (RowStr('class',...)); spart Datenbank-Abfragen }
procedure ClassCacheClear;
function ScalarInt(const ASql: string): Int64;
function ScalarStr(const ASql: string): string;
function FieldText(AField: TField): string;
function NameSql(const AKind, AIdExpr, ANameExpr: string): string;
function RowStr(const ATable, ACol: string; AId: Int64): string;
function PkType: string;
function RealType: string;
function BlobType: string;
function DateSql: string;
function LastIdSql: string;
function Pad3Sql(const AExpr: string): string;
function InsIgnoreSql(const ATable, ACols, AVals: string): string;
function NewPgConnection(AOwner: TComponent; const AHost, APort, ADb, AUser,
  APass: string): TSQLConnection;

implementation

var
  GClassCache: TFPStringHashTable = nil;

procedure ClassCacheClear;
begin
  if GClassCache <> nil then GClassCache.Clear;
end;

function NewQuery: TSQLQuery;
begin
  Result := TSQLQuery.Create(nil);
  Result.DataBase := DbCtx.Conn;
  Result.Transaction := DbCtx.Trans;
end;


procedure Exec(const ASql: string);
begin
  try
    // Aenderungen an Klassen machen den Zwischenspeicher ungueltig
    if Pos('class', LowerCase(ASql)) > 0 then ClassCacheClear;
    DbCtx.Conn.ExecuteDirect(ASql);
    if Pos('class', LowerCase(ASql)) > 0 then ClassCacheClear;
    if not DbCtx.Batch then DbCtx.Trans.CommitRetaining;
  except
    DbCtx.Trans.RollbackRetaining;
    raise;
  end;
end;

function ScalarInt(const ASql: string): Int64;
var
  Q: TSQLQuery;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := ASql;
    Q.Open;
    Result := Q.Fields[0].AsLargeInt;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function ScalarStr(const ASql: string): string;
var
  Q: TSQLQuery;
begin
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := ASql;
    Q.Open;
    Result := FieldText(Q.Fields[0]);
    Q.Close;
  finally
    Q.Free;
  end;
end;

{ Liest den Feldinhalt direkt aus den Rohdaten; bei Memo-Feldern ueber den Stream,
  damit nie der Platzhalter '(MEMO)' herauskommt }
function FieldText(AField: TField): string;
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

{ SQL-Ausdruck fuer einen Namen in der gewaehlten Datensprache (Rueckfall: Grundname) }
function NameSql(const AKind, AIdExpr, ANameExpr: string): string;
begin
  if DbCtx.Lang = '' then
    Result := ANameExpr
  else
    Result := 'COALESCE((SELECT t.name FROM translation t WHERE t.kind=' + QuotedStr(AKind) +
      ' AND t.ref_id=' + AIdExpr + ' AND t.lang=' + QuotedStr(DbCtx.Lang) +
      ' AND t.name<>''''), ' + ANameExpr + ')';
end;

function RowStr(const ATable, ACol: string; AId: Int64): string;
var
  Key, V: string;
begin
  if ATable = 'class' then
  begin
    // Klassen aendern sich selten und werden oft abgefragt: nur einmal aus der Datenbank lesen
    if GClassCache = nil then GClassCache := TFPStringHashTable.Create;
    Key := ACol + '#' + IntToStr(AId);
    V := GClassCache[Key];
    if V <> '' then
    begin
      Result := Copy(V, 2, MaxInt);   // erstes Zeichen ist nur eine Markierung
      Exit;
    end;
    Result := ScalarStr(Format('SELECT COALESCE(CAST(%s AS TEXT),'''') FROM %s WHERE id=%d',
      [ACol, ATable, AId]));
    GClassCache[Key] := '#' + Result;
    Exit;
  end;
  Result := ScalarStr(Format('SELECT COALESCE(CAST(%s AS TEXT),'''') FROM %s WHERE id=%d',
    [ACol, ATable, AId]));
end;

function PkType: string;
begin
  if DbCtx.IsPg then Result := 'SERIAL PRIMARY KEY'
  else Result := 'INTEGER PRIMARY KEY AUTOINCREMENT';
end;

function RealType: string;
begin
  if DbCtx.IsPg then Result := 'DOUBLE PRECISION' else Result := 'REAL';
end;

function BlobType: string;
begin
  if DbCtx.IsPg then Result := 'BYTEA' else Result := 'BLOB';
end;

function DateSql: string;
begin
  if DbCtx.IsPg then Result := 'to_char(CURRENT_DATE, ''YYYY-MM-DD'')'
  else Result := 'date(''now'')';
end;

function LastIdSql: string;
begin
  if DbCtx.IsPg then Result := 'SELECT lastval()'
  else Result := 'SELECT last_insert_rowid()';
end;

function Pad3Sql(const AExpr: string): string;
begin
  if DbCtx.IsPg then Result := 'lpad(CAST(' + AExpr + ' AS TEXT), 3, ''0'')'
  else Result := 'printf(''%03d'', ' + AExpr + ')';
end;

function InsIgnoreSql(const ATable, ACols, AVals: string): string;
begin
  if DbCtx.IsPg then
    Result := 'INSERT INTO ' + ATable + '(' + ACols + ') VALUES(' + AVals +
      ') ON CONFLICT DO NOTHING'
  else
    Result := 'INSERT OR IGNORE INTO ' + ATable + '(' + ACols + ') VALUES(' + AVals + ')';
end;

function NewPgConnection(AOwner: TComponent; const AHost, APort, ADb, AUser,
  APass: string): TSQLConnection;
var
  C: TPQConnection;
begin
  C := TPQConnection.Create(AOwner);
  C.HostName := AHost;
  C.DatabaseName := ADb;
  C.UserName := AUser;
  C.Password := APass;
  C.CharSet := 'UTF8';
  C.Params.Add('port=' + APort);
  Result := C;
end;

end.
