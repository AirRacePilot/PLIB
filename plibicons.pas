unit PlibIcons;

{ Scharfe Symbole fuer das Menueband.

  Die Symbole aus MakeIcon (mainunit.pas) werden hier in hoher Aufloesung gezeichnet (Faktor 4
  groesser als noetig) und dann fein heruntergerechnet. Das ergibt glatte Kanten in jeder
  Bildschirmgroesse (4K, 150 %, 200 %), ohne zusaetzliche Pakete. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, IntfGraphics, GraphType, FPImage, LCLIntf, LCLType;

{ Symbol AKind (wie MakeIcon) in ATarget x ATarget Pixeln; Hintergrund ABg wird eingerechnet }
function MakeIconAA(AKind, ATarget: Integer; ABg: TColor): TBitmap;

{ Symbol AKind fuer Knopfleisten: ASize x ASize Pixel, transparenter Hintergrund (clFuchsia) }
function MakeIconGlyph(AKind, ASize: Integer): TBitmap;

function MakeTreeIcon(AGroup: Boolean; AStatus: Integer; ASize: Integer): TBitmap;

implementation

const
  SS = 4;   // Ueberabtastung

type
  { Zeichenflaeche, die alle Koordinaten mit dem Faktor F vergroessert }
  TIc = class
  private
    FC: TCanvas;
    FF: Double;
    FPen: TPen;
    FBrush: TBrush;
    FFont: TFont;
  public
    constructor Create(ACanvas: TCanvas; AF: Double);
    function W(V: Integer): Integer;
    procedure Rectangle(L, T, R, B: Integer);
    procedure Ellipse(L, T, R, B: Integer);
    procedure Line(X1, Y1, X2, Y2: Integer);
    procedure FillRect(L, T, R, B: Integer);
    procedure Polygon(const Pts: array of TPoint);
    procedure TextOut(X, Y: Integer; const S: string);
    property Pen: TPen read FPen;
    property Brush: TBrush read FBrush;
    property Font: TFont read FFont;
  end;

constructor TIc.Create(ACanvas: TCanvas; AF: Double);
begin
  inherited Create;
  FC := ACanvas;
  FF := AF;
  FPen := ACanvas.Pen;
  FBrush := ACanvas.Brush;
  FFont := ACanvas.Font;
end;

function TIc.W(V: Integer): Integer;
begin
  Result := Round(V * FF);
  if Result < 1 then Result := 1;
end;

procedure TIc.Rectangle(L, T, R, B: Integer);
begin
  FC.Rectangle(Round(L * FF), Round(T * FF), Round(R * FF), Round(B * FF));
end;

procedure TIc.Ellipse(L, T, R, B: Integer);
begin
  FC.Ellipse(Round(L * FF), Round(T * FF), Round(R * FF), Round(B * FF));
end;

procedure TIc.Line(X1, Y1, X2, Y2: Integer);
begin
  FC.Line(Round(X1 * FF), Round(Y1 * FF), Round(X2 * FF), Round(Y2 * FF));
end;

procedure TIc.FillRect(L, T, R, B: Integer);
begin
  FC.FillRect(Round(L * FF), Round(T * FF), Round(R * FF), Round(B * FF));
end;

procedure TIc.Polygon(const Pts: array of TPoint);
var
  A: array of TPoint;
  I: Integer;
begin
  SetLength(A, Length(Pts));
  for I := 0 to High(Pts) do
    A[I] := Point(Round(Pts[I].X * FF), Round(Pts[I].Y * FF));
  FC.Polygon(A);
end;

procedure TIc.TextOut(X, Y: Integer; const S: string);
begin
  FC.TextOut(Round(X * FF), Round(Y * FF), S);
end;

function MakeIconHiRes(AKind: Integer; F: Double): TBitmap;
const
  CDark = TColor($00604020);
  CBlue = TColor($00CC6600);
  CGreen = TColor($003C9600);
  CRed = TColor($001E1EC8);
  COrange = TColor($000096E6);
  CLight = TColor($00F6E8DC);
  CGray = TColor($00808080);
var
  C: TIc;
  r, y: Integer;

  procedure SetPen(AColor: TColor; AWidth: Integer);
  begin
    C.Pen.Color := AColor;
    C.Pen.Width := C.W(AWidth);
  end;

  procedure SetFill(AColor: TColor);
  begin
    C.Brush.Color := AColor;
  end;

  procedure Box(ALeft, ATop, ARight, ABottom: Integer);
  begin
    SetPen(CDark, 2);
    SetFill(CLight);
    C.Rectangle(ALeft, ATop, ARight, ABottom);
    C.Line(ALeft, ATop + 6, ARight, ATop + 6);
  end;

  procedure Hex;
  begin
    SetPen(CDark, 2);
    SetFill(CLight);
    C.Polygon([Point(14, 6), Point(24, 12), Point(24, 24), Point(14, 30),
      Point(4, 24), Point(4, 12)]);
    SetFill(clFuchsia);
    C.Ellipse(9, 13, 19, 23);
  end;

  procedure PlusBadge;
  begin
    SetPen(CGreen, 1);
    SetFill(CGreen);
    C.Ellipse(17, 0, 31, 14);
    SetPen(clWhite, 2);
    C.Line(24, 3, 24, 11);
    C.Line(20, 7, 28, 7);
  end;

  procedure CrossBadge;
  begin
    SetPen(CRed, 4);
    C.Line(17, 17, 29, 29);
    C.Line(29, 17, 17, 29);
  end;

  procedure Pencil;
  begin
    SetPen(COrange, 5);
    C.Line(15, 24, 26, 12);
    SetPen(CDark, 1);
    SetFill(CDark);
    C.Polygon([Point(10, 29), Point(12, 22), Point(17, 27)]);
  end;

  procedure Cube;
  begin
    SetPen(CDark, 2);
    SetFill(CLight);
    C.Polygon([Point(16, 3), Point(28, 9), Point(16, 15), Point(4, 9)]);
    SetFill(CBlue);
    C.Polygon([Point(4, 9), Point(16, 15), Point(16, 29), Point(4, 23)]);
    SetFill(TColor($00905020));
    C.Polygon([Point(16, 15), Point(28, 9), Point(28, 23), Point(16, 29)]);
  end;

  procedure ArrowBadge;
  begin
    SetPen(CGreen, 1);
    SetFill(CGreen);
    C.Ellipse(17, 0, 31, 14);
    SetPen(clWhite, 2);
    C.Line(20, 7, 26, 7);
    SetFill(clWhite);
    C.Polygon([Point(25, 3), Point(29, 7), Point(25, 11)]);
  end;

  procedure SparkBadge(ACx, ACy: Integer);
  begin
    SetPen(CDark, 1);
    SetFill(COrange);
    C.Polygon([Point(ACx, ACy - 6), Point(ACx + 2, ACy - 2), Point(ACx + 6, ACy),
      Point(ACx + 2, ACy + 2), Point(ACx, ACy + 6), Point(ACx - 2, ACy + 2),
      Point(ACx - 6, ACy), Point(ACx - 2, ACy - 2)]);
  end;

  procedure TagShape;
  begin
    SetPen(CDark, 2);
    SetFill(CLight);
    C.Polygon([Point(2, 10), Point(16, 10), Point(24, 18), Point(16, 26), Point(2, 26)]);
    SetPen(CDark, 1);
    SetFill(CBlue);
    C.Ellipse(5, 15, 10, 20);
  end;

  procedure Truck;
  begin
    SetPen(CDark, 2);
    SetFill(CLight);
    C.Rectangle(2, 9, 19, 22);
    SetFill(CBlue);
    C.Polygon([Point(19, 13), Point(25, 13), Point(30, 18), Point(30, 22),
      Point(19, 22)]);
    SetFill(CDark);
    C.Ellipse(5, 19, 13, 27);
    C.Ellipse(20, 19, 28, 27);
  end;

  procedure Ruler;
  var
    k: Integer;
  begin
    SetPen(CDark, 2);
    SetFill(CLight);
    C.Rectangle(2, 12, 28, 24);
    SetPen(CDark, 1);
    for k := 0 to 5 do
      C.Line(6 + k * 4, 12, 6 + k * 4, 17 + 2 * (k mod 2));
  end;

  procedure EnumList;
  var
    k, yy: Integer;
  begin
    for k := 0 to 2 do
    begin
      yy := 8 + k * 8;
      SetPen(CDark, 1);
      SetFill(COrange);
      C.Ellipse(3, yy, 9, yy + 6);
      SetPen(CDark, 2);
      C.Line(13, yy + 3, 25, yy + 3);
    end;
  end;

  procedure LensBadge;
  begin
    SetPen(CDark, 2);
    SetFill(clWhite);
    C.Ellipse(16, 0, 27, 11);
    SetPen(CDark, 3);
    C.Line(25, 9, 30, 14);
  end;

begin
  Result := TBitmap.Create;
  Result.SetSize(Round(32 * F), Round(32 * F));
  C := TIc.Create(Result.Canvas, F);
  C.Brush.Color := clFuchsia;
  C.FillRect(0, 0, 32, 32);
  case AKind of
    0: begin   // Suche: Lupe
         SetPen(CDark, 3);
         SetFill(CLight);
         C.Ellipse(3, 3, 20, 20);
         SetPen(CDark, 5);
         C.Line(18, 18, 28, 28);
       end;
    1: begin   // Neue Klasse
         Box(4, 8, 22, 28);
         PlusBadge;
       end;
    2: begin   // Klasse umbenennen
         Box(3, 8, 21, 28);
         Pencil;
       end;
    3: begin   // Klasse loeschen
         Box(3, 8, 21, 28);
         CrossBadge;
       end;
    4: begin   // Merkmale verwalten: Liste
         for r := 0 to 2 do
         begin
           y := 6 + r * 9;
           SetPen(CDark, 1);
           SetFill(CBlue);
           C.Rectangle(3, y, 10, y + 7);
           SetPen(CDark, 2);
           C.Line(14, y + 3, 29, y + 3);
         end;
       end;
    5: begin   // Merkmalkatalog: Buch
         SetPen(CDark, 2);
         SetFill(CLight);
         C.Rectangle(6, 3, 27, 29);
         SetFill(CBlue);
         C.Rectangle(6, 3, 12, 29);
         SetPen(CGray, 2);
         C.Line(16, 10, 24, 10);
         C.Line(16, 16, 24, 16);
         C.Line(16, 22, 24, 22);
       end;
    6: begin   // Lieferanten: Lastwagen
         SetPen(CDark, 2);
         SetFill(CLight);
         C.Rectangle(2, 9, 19, 22);
         SetFill(CBlue);
         C.Polygon([Point(19, 13), Point(25, 13), Point(30, 18), Point(30, 22),
           Point(19, 22)]);
         SetFill(CDark);
         C.Ellipse(5, 19, 13, 27);
         C.Ellipse(20, 19, 28, 27);
       end;
    7: begin   // Neues Teil: Mutter mit Plus
         Hex;
         PlusBadge;
       end;
    8: begin   // Werte bearbeiten: Tabelle mit Stift
         SetPen(CDark, 2);
         SetFill(CLight);
         C.Rectangle(2, 5, 23, 27);
         C.Line(2, 12, 23, 12);
         C.Line(2, 19, 23, 19);
         C.Line(11, 5, 11, 27);
         Pencil;
       end;
    9: begin   // Teil loeschen: Mutter mit Kreuz
         Hex;
         CrossBadge;
       end;
    10: begin  // Beschreibung / Status: Blatt mit Eselsohr
         SetPen(CDark, 2);
         SetFill(CLight);
         C.Polygon([Point(7, 3), Point(21, 3), Point(27, 9), Point(27, 29), Point(7, 29)]);
         SetFill(CBlue);
         C.Polygon([Point(21, 3), Point(21, 9), Point(27, 9)]);
         SetPen(CGray, 2);
         C.Line(11, 14, 23, 14);
         C.Line(11, 19, 23, 19);
         C.Line(11, 24, 19, 24);
       end;
    11: begin  // Datensprache: Globus
         SetPen(CDark, 2);
         SetFill(CLight);
         C.Ellipse(3, 3, 29, 29);
         C.Ellipse(11, 3, 21, 29);
         C.Line(3, 16, 29, 16);
         C.Line(6, 9, 26, 9);
         C.Line(6, 23, 26, 23);
       end;
    12: begin  // Klassenbild: Bild mit Berg und Sonne
         SetPen(CDark, 2);
         SetFill(CLight);
         C.Rectangle(3, 5, 29, 27);
         SetFill(CGreen);
         SetPen(CDark, 1);
         C.Polygon([Point(5, 25), Point(13, 13), Point(19, 21), Point(23, 16),
           Point(27, 25)]);
         SetFill(COrange);
         SetPen(COrange, 1);
         C.Ellipse(21, 8, 26, 13);
       end;
    13: begin  // Solid Edge: Wuerfel
         SetPen(CDark, 2);
         SetFill(CLight);
         C.Polygon([Point(16, 3), Point(28, 9), Point(16, 15), Point(4, 9)]);
         SetFill(CBlue);
         C.Polygon([Point(4, 9), Point(16, 15), Point(16, 29), Point(4, 23)]);
         SetFill(TColor($00905020));
         C.Polygon([Point(16, 15), Point(28, 9), Point(28, 23), Point(16, 29)]);
       end;
    14: begin  // Teil in Solid Edge oeffnen: Wuerfel mit Pfeil
         Cube;
         ArrowBadge;
       end;
    15: begin  // Eigenschaften schreiben: Wuerfel mit Stift
         Cube;
         Pencil;
       end;
    16: begin  // in Baugruppe einfuegen: Wuerfel mit Plus
         Cube;
         PlusBadge;
       end;
    17: begin  // Dokument in PLIB zeigen: Wuerfel mit Lupe
         Cube;
         LensBadge;
       end;
    18: begin  // Teil aus Vorlage erzeugen: Wuerfel mit Funke
         Cube;
         SparkBadge(24, 7);
       end;
    19: begin  // alle fehlenden Teile erzeugen: Wuerfel mit mehreren Funken
         Cube;
         SparkBadge(24, 7);
         SparkBadge(7, 21);
         SparkBadge(24, 24);
       end;
    20: begin  // Hilfe: Fragezeichen im Kreis
         SetPen(CDark, 2);
         SetFill(CBlue);
         C.Ellipse(2, 2, 30, 30);
         C.Brush.Style := bsClear;
         C.Font.Color := clWhite;
         C.Font.Style := [fsBold];
         C.Font.Size := Round(15 * F);
         C.TextOut(11, 4, '?');
         C.Brush.Style := bsSolid;
       end;
    21: begin  // Neues Merkmal: Etikett mit Plus
         TagShape;
         PlusBadge;
       end;
    22: begin  // Merkmal aendern: Etikett mit Stift
         TagShape;
         Pencil;
       end;
    23: begin  // Merkmal loeschen: Etikett mit Kreuz
         TagShape;
         CrossBadge;
       end;
    24: begin  // Der Klasse zuordnen: Etikett mit gruenem Pfeil
         TagShape;
         ArrowBadge;
       end;
    25: begin  // Aus der Klasse entfernen: Etikett mit rotem Pfeil nach links
         TagShape;
         SetPen(CRed, 1);
         SetFill(CRed);
         C.Ellipse(17, 0, 31, 14);
         SetPen(clWhite, 2);
         C.Line(21, 7, 28, 7);
         SetFill(clWhite);
         C.Polygon([Point(22, 3), Point(18, 7), Point(22, 11)]);
       end;
    26: begin  // Aufzaehlungswerte: Liste mit Punkten
         for r := 0 to 2 do
         begin
           y := 6 + r * 9;
           SetPen(CDark, 1);
           SetFill(COrange);
           C.Ellipse(3, y, 10, y + 7);
           SetPen(CDark, 2);
           C.Line(14, y + 3, 29, y + 3);
         end;
       end;
    27: begin  // Schliessen: roter Kreis mit weissem Kreuz
         SetPen(CDark, 2);
         SetFill(CRed);
         C.Ellipse(2, 2, 30, 30);
         SetPen(clWhite, 4);
         C.Line(10, 10, 22, 22);
         C.Line(22, 10, 10, 22);
       end;
    28: begin Truck; PlusBadge; end;
    29: begin Truck; Pencil; end;
    30: begin Truck; CrossBadge; end;
    31: begin  // Als Standard: Stern
         SetPen(CDark, 2);
         SetFill(COrange);
         C.Polygon([Point(16, 2), Point(20, 12), Point(30, 12), Point(22, 19),
           Point(25, 29), Point(16, 23), Point(7, 29), Point(10, 19),
           Point(2, 12), Point(12, 12)]);
       end;
    32: begin Ruler; PlusBadge; end;
    33: begin Ruler; Pencil; end;
    34: begin Ruler; CrossBadge; end;
    35: begin EnumList; PlusBadge; end;
    36: begin EnumList; Pencil; end;
    37: begin EnumList; CrossBadge; end;
    38: begin  // Anzeigen: gruener Kreis mit Pfeil
         SetPen(CDark, 2);
         SetFill(CGreen);
         C.Ellipse(2, 2, 30, 30);
         SetPen(clWhite, 3);
         C.Line(8, 16, 20, 16);
         SetFill(clWhite);
         C.Polygon([Point(18, 9), Point(26, 16), Point(18, 23)]);
       end;
  end;
  C.Free;
  Result.Transparent := True;
  Result.TransparentColor := clFuchsia;
end;

function MakeIconAA(AKind, ATarget: Integer; ABg: TColor): TBitmap;
var
  Hi: TBitmap;
  Img, Out_: TLazIntfImage;
  X, Y, DX, DY, N, SR, SG, SB, BgR, BgG, BgB, R, G, B: Integer;
  P: TFPColor;
  Cov: Double;
  Bg: Integer;
begin
  Result := nil;
  if ATarget < 8 then Exit;
  Hi := MakeIconHiRes(AKind, ATarget * SS / 32);
  try
    Img := Hi.CreateIntfImage;
    try
      Out_ := TLazIntfImage.Create(0, 0);
      Out_.DataDescription := GetDescriptionFromDevice(0, ATarget, ATarget);
      Bg := ColorToRGB(ABg);
      BgR := Bg and $FF;
      BgG := (Bg shr 8) and $FF;
      BgB := (Bg shr 16) and $FF;
      for Y := 0 to ATarget - 1 do
        for X := 0 to ATarget - 1 do
        begin
          N := 0;
          SR := 0;
          SG := 0;
          SB := 0;
          for DY := 0 to SS - 1 do
            for DX := 0 to SS - 1 do
            begin
              P := Img.Colors[X * SS + DX, Y * SS + DY];
              if not ((P.Red >= $FF00) and (P.Green <= $00FF) and (P.Blue >= $FF00)) then
              begin
                Inc(N);
                Inc(SR, P.Red shr 8);
                Inc(SG, P.Green shr 8);
                Inc(SB, P.Blue shr 8);
              end;
            end;
          if N = 0 then
          begin
            R := BgR;
            G := BgG;
            B := BgB;
          end
          else
          begin
            Cov := N / (SS * SS);
            R := Round(BgR * (1 - Cov) + (SR / N) * Cov);
            G := Round(BgG * (1 - Cov) + (SG / N) * Cov);
            B := Round(BgB * (1 - Cov) + (SB / N) * Cov);
          end;
          Out_.Colors[X, Y] := FPColor(R shl 8 or R, G shl 8 or G, B shl 8 or B, $FFFF);
        end;
      Result := TBitmap.Create;
      Result.LoadFromIntfImage(Out_);
    finally
      Img.Free;
      Out_.Free;
    end;
  finally
    Hi.Free;
  end;
end;

function MakeIconGlyph(AKind, ASize: Integer): TBitmap;
begin
  if ASize < 8 then ASize := 8;
  Result := MakeIconHiRes(AKind, ASize / 32);
end;

{ Symbol fuer den Klassenbaum: Ordner = Klasse mit Unterklassen,
  Blatt = Klasse ohne Unterklassen; Farbe = Status. Entworfen auf einem 16er-Raster und auf
  ASize Pixel hochgerechnet (grosse Monitore). }
function MakeTreeIcon(AGroup: Boolean; AStatus: Integer; ASize: Integer): TBitmap;
var
  C: TCanvas;
  Fill: TColor;

  function Z(V: Integer): Integer;
  begin
    Result := (V * ASize + 8) div 16;
  end;

begin
  case AStatus of
    1: Fill := TColor($0046A03C);   // gruen: freigegeben
    2: Fill := TColor($00B4B4B4);   // grau: veraltet
  else
    Fill := TColor($0030A8F0);      // orange: in Arbeit
  end;
  Result := TBitmap.Create;
  Result.SetSize(ASize, ASize);
  C := Result.Canvas;
  C.Brush.Color := clFuchsia;
  C.FillRect(0, 0, ASize, ASize);
  C.Pen.Width := ASize div 14;
  if C.Pen.Width < 1 then C.Pen.Width := 1;
  C.Pen.Color := TColor($00604020);
  C.Brush.Color := Fill;
  if AGroup then
  begin
    C.Polygon([Point(Z(1), Z(4)), Point(Z(6), Z(4)), Point(Z(8), Z(6)), Point(Z(15), Z(6)),
      Point(Z(15), Z(14)), Point(Z(1), Z(14))]);
    C.Pen.Color := clWhite;
    C.Line(Z(2), Z(8), Z(14), Z(8));
  end
  else
  begin
    C.Rectangle(Z(3), Z(2), Z(13), Z(14));
    C.Pen.Color := clWhite;
    C.Line(Z(5), Z(6), Z(11), Z(6));
    C.Line(Z(5), Z(9), Z(11), Z(9));
    C.Line(Z(5), Z(12), Z(9), Z(12));
  end;
  Result.Transparent := True;
  Result.TransparentColor := clFuchsia;
end;

end.
