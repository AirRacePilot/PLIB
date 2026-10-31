unit PlibViews;

{ Stufe 3: Klassenbaum und Tabellen im Stil des Menuebands (eigene Zeichnung).

  Die Steuerelemente und ihr Verhalten bleiben unveraendert; nur das Zeichnen wird ersetzt:
  Tabellen mit Kopfzeile, Zebrastreifen, Auswahlzeile und Zellrand; Baum mit hoeheren Zeilen
  und gleicher Auswahlfarbe. Aufruf einmal pro Steuerelement: StyleGrid / StyleTree. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, Forms, Grids, ComCtrls, Types, PlibTheme;

procedure StyleGrid(G: TStringGrid);
procedure StyleTree(T: TTreeView);

{ Spalten der Tabellen ueber ihre Ueberschrift ansprechen }
function ColIdx(AGrid: TStringGrid; const AName: string): Integer;
procedure HideColsByName(AGrid: TStringGrid; AHidden: TStringList);
function CellBy(AGrid: TStringGrid; const AName: string; ARow: Integer): string;

implementation

type
  THelper = class
    procedure DrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect;
      aState: TGridDrawState);
  end;

var
  Helper: THelper = nil;

procedure THelper.DrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
var
  G: TStringGrid;
  C: TCanvas;
  P: TRibbonPalette;
  R: TRect;
  Ts: TTextStyle;
  Head: Boolean;
begin
  G := Sender as TStringGrid;
  C := G.Canvas;
  ThemeRibbonPalette(P);
  Head := aRow < G.FixedRows;
  // Schrift nur bei Bedarf neu zuweisen (sonst pro Zelle ein neues Schriftobjekt)
  if (C.Font.Name <> G.Font.Name) or (C.Font.Height <> G.Font.Height) or
     (C.Font.Quality <> G.Font.Quality) then C.Font.Assign(G.Font);
  C.Font.Style := [];
  if Head then
  begin
    C.Brush.Color := P.Head;
    C.Font.Color := P.Text;
    C.Font.Style := [fsBold];
  end
  else if gdSelected in aState then
  begin
    C.Brush.Color := P.Sel;
    C.Font.Color := P.SelText;
  end
  else
  begin
    if Odd(aRow) then C.Brush.Color := P.RowB else C.Brush.Color := P.RowA;
    C.Font.Color := P.Text;
  end;
  C.Brush.Style := bsSolid;
  C.FillRect(aRect);
  // feine Linien: unten, bei der Kopfzeile auch rechts
  C.Pen.Color := P.Line;
  C.Pen.Style := psSolid;
  C.Pen.Width := 1;
  C.MoveTo(aRect.Left, aRect.Bottom - 1);
  C.LineTo(aRect.Right, aRect.Bottom - 1);
  if Head then
  begin
    C.MoveTo(aRect.Right - 1, aRect.Top + 4);
    C.LineTo(aRect.Right - 1, aRect.Bottom - 4);
  end;
  R := Rect(aRect.Left + 8, aRect.Top, aRect.Right - 6, aRect.Bottom - 1);
  Ts := C.TextStyle;
  Ts.Layout := tlCenter;
  Ts.Alignment := taLeftJustify;
  Ts.SingleLine := True;
  Ts.EndEllipsis := True;
  Ts.Clipping := True;
  C.TextStyle := Ts;
  C.Brush.Style := bsClear;
  C.TextRect(R, R.Left, R.Top, G.Cells[aCol, aRow]);
  C.Brush.Style := bsSolid;
end;

procedure StyleGrid(G: TStringGrid);
var
  I: Integer;
begin
  if G = nil then Exit;
  if Helper = nil then Helper := THelper.Create;
  G.DefaultDrawing := False;
  G.Font.Quality := fqCleartype;
  G.OnDrawCell := @Helper.DrawCell;
  G.DefaultRowHeight := (26 * Screen.PixelsPerInch + 48) div 96;
  for I := 0 to G.FixedRows - 1 do
    G.RowHeights[I] := (30 * Screen.PixelsPerInch + 48) div 96;
  G.FocusRectVisible := False;
  G.Flat := True;
end;

procedure StyleTree(T: TTreeView);
var
  P: TRibbonPalette;
begin
  if T = nil then Exit;
  ThemeRibbonPalette(P);
  T.DefaultItemHeight := (26 * Screen.PixelsPerInch + 48) div 96;
  T.SelectionColor := P.Sel;
  T.SelectionFontColor := P.SelText;
  T.SelectionFontColorUsed := True;
end;

{ Spaltennummer einer Tabelle ueber den Namen der Ueberschrift (-1 = nicht vorhanden) }
function ColIdx(AGrid: TStringGrid; const AName: string): Integer;
var
  c: Integer;
begin
  Result := -1;
  for c := 0 to AGrid.ColCount - 1 do
    if SameText(AGrid.Cells[c, 0], AName) then
    begin
      Result := c;
      Exit;
    end;
end;

{ Setzt die Breite ausgeblendeter Spalten auf 0 (die Spalte bleibt fuer PLIB vorhanden) }
procedure HideColsByName(AGrid: TStringGrid; AHidden: TStringList);
var
  c, N: Integer;
begin
  if (AGrid = nil) or (AHidden = nil) then Exit;
  N := 0;   // Spalten, die sichtbar blieben
  for c := 0 to AGrid.ColCount - 1 do
    if (AGrid.ColWidths[c] > 0) and (AHidden.IndexOf(AGrid.Cells[c, 0]) < 0) then Inc(N);
  if N = 0 then Exit;   // mindestens eine Spalte bleibt sichtbar
  for c := 0 to AGrid.ColCount - 1 do
    if AHidden.IndexOf(AGrid.Cells[c, 0]) >= 0 then
      AGrid.ColWidths[c] := 0;
end;

{ Zellinhalt einer Zeile in der Spalte mit dieser Ueberschrift }
function CellBy(AGrid: TStringGrid; const AName: string; ARow: Integer): string;
var
  c: Integer;
begin
  Result := '';
  c := ColIdx(AGrid, AName);
  if (c >= 0) and (ARow >= 0) and (ARow < AGrid.RowCount) then
    Result := AGrid.Cells[c, ARow];
end;

end.
