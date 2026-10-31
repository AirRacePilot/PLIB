unit DockUnit;

{ Einfaches Andock-System (ohne Zusatzpakete) fuer die PLIB-Oberflaeche.

  Bereiche ("Panes") liegen in einem Teilungsbaum: jeder Knoten ist entweder
  ein Bereich oder eine Teilung (nebeneinander / uebereinander) mit Trennlinie.
  Der Benutzer zieht einen Bereich an seiner Titelleiste:
    - auf den Rand eines anderen Bereichs: dort andocken (links/rechts/oben/unten)
    - in die Mitte eines anderen Bereichs: Plaetze tauschen
    - an den Rand des Arbeitsbereichs: ueber die ganze Breite/Hoehe andocken
    - ausserhalb des Hauptfensters: frei schwebendes Fenster
  Die Knopfleiste laesst sich an ihrem Griff an jeden Fensterrand setzen
  oder frei schweben lassen.
  Die Aufteilung wird in der INI-Datei gespeichert. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Types, Menus, Buttons, Forms, Controls,
  Graphics, ExtCtrls, StdCtrls;

type
  TPaneState = (dsDocked, dsFloating, dsHidden);
  TDropZone = (dzNone, dzLeft, dzRight, dzTop, dzBottom, dzCenter, dzFloat);
  TToolEdge = (teTop, teBottom, teLeft, teRight);

  TPaneDock = class;
  TPaneNode = class;

  TPaneItem = class
  public
    Name, Title: string;
    Index: Integer;
    Box: TPanel;          // Rahmen: Titelleiste + Inhalt
    TitleBar: TPanel;
    BtnClose: TSpeedButton;
    Popup: TPopupMenu;
    State: TPaneState;
    FloatForm: TForm;
    FloatL, FloatT, FloatW, FloatH: Integer;
    Node: TPaneNode;
  end;

  TPaneNode = class
  public
    Parent, A, B: TPaneNode;
    Pane: TPaneItem;      // Blatt, wenn <> nil
    Horiz: Boolean;       // True: A links, B rechts; False: A oben, B unten
    Ratio: Double;        // Anteil von A
    Host: TPanel;
    Spl: TSplitter;
  end;

  TPaneDock = class
  private
    FForm: TForm;
    FWork: TPanel;
    FStatus: TControl;
    FParking: TPanel;
    FRootHost: TPanel;
    FRoot: TPaneNode;
    FPanes: TList;
    FDefault: string;
    FDefaultHidden: string;
    FBuilt: Boolean;
    FRebuilding: Boolean;
    FOk: Boolean;
    FOnChange: TNotifyEvent;
    // Ziehen
    FDragPane: TPaneItem;
    FDragTool: Boolean;
    FDragActive: Boolean;
    FDragStart: TPoint;
    FOldCursor: TCursor;
    FDropZone: TDropZone;
    FDropTarget: TPaneItem;
    FDropRoot: Boolean;
    FToolEdgeDrop: TToolEdge;
    FFrame: array[0..3] of TPanel;
    FPendPane: TPaneItem;
    FPendZone: TDropZone;
    FPendTarget: TPaneItem;
    FPendRoot: Boolean;
    FPendEdge: TToolEdge;
    FPendTool: Boolean;
    FPendPt: TPoint;
    // Knopfleiste
    FTool: TFlowPanel;
    FGrip: TPanel;
    FToolForm: TForm;
    FToolHidden: Boolean;
    FToolEdge: TToolEdge;
    FToolFloating: Boolean;
    FToolVisible: Boolean;
    FToolFL, FToolFT, FToolFW, FToolFH: Integer;

    function NewLeaf(P: TPaneItem): TPaneNode;
    procedure ReplaceNode(Old, New: TPaneNode);
    procedure Detach(P: TPaneItem);
    procedure InsertBeside(P: TPaneItem; T: TPaneNode; Zone: TDropZone);
    procedure InsertAtRoot(P: TPaneItem; Zone: TDropZone);
    procedure FreeTree(N: TPaneNode);
    procedure ClearModel;
    procedure ClearHosts(N: TPaneNode);
    procedure CaptureRatios(N: TPaneNode);
    procedure ApplyRatios(N: TPaneNode; W, H: Integer);
    function NodeToStr(N: TPaneNode): string;
    function ParseNode(const S: string; var I: Integer; AParent: TPaneNode): TPaneNode;
    function MakeHost(N: TPaneNode; AParent: TWinControl; AAlign: TAlign;
      ASize, W, H: Integer): TPanel;
    function FindPane(const AName: string): TPaneItem;
    procedure ParseLayout(const S: string);
    procedure EnsureFloat(P: TPaneItem);
    procedure FloatPane(P: TPaneItem; X, Y: Integer);
    procedure DoChange;
    // Ereignisse
    procedure TitleDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure TitleMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TitleUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure CloseClick(Sender: TObject);
    procedure PopClose(Sender: TObject);
    procedure PopFloat(Sender: TObject);
    procedure PopDock(Sender: TObject);
    procedure SplitMoved(Sender: TObject);
    procedure WorkResize(Sender: TObject);
    procedure FloatClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure ToolFormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure DoDrop(Data: PtrInt);
    // Ziel bestimmen und anzeigen
    procedure UpdateDropTarget(const P: TPoint);
    procedure UpdateToolTarget(const P: TPoint);
    procedure ShowFrame(const R: TRect);
    procedure HideFrame;
    procedure EndDrag(ADrop: Boolean);
    // Knopfleiste
    procedure SetToolOrient(AVert: Boolean);
    procedure ApplyToolbar;
    procedure SetToolbarVisible(AValue: Boolean);
    procedure SetToolbarHidden(AValue: Boolean);
  public
    constructor Create(AForm: TForm; AWork: TPanel);
    destructor Destroy; override;
    function AddPane(const AName, ATitle: string; AContent: TControl): TPaneItem;
    procedure SetTitle(const AName, ATitle: string);
    procedure AttachToolbar(ATool: TFlowPanel; AStatus: TControl);
    procedure Rebuild;
    procedure ResetDefault;
    procedure LoadFromIni(Ini: TIniFile; const ASection: string);
    procedure SaveToIni(Ini: TIniFile; const ASection: string);
    function PaneVisible(const AName: string): Boolean;
    procedure SetPaneVisible(const AName: string; AShow: Boolean);
    function PaneCount: Integer;
    function PaneAt(AIndex: Integer): TPaneItem;
    property DefaultLayout: string read FDefault write FDefault;
    property DefaultHidden: string read FDefaultHidden write FDefaultHidden;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property ToolbarVisible: Boolean read FToolVisible write SetToolbarVisible;
    { True = alte Knopfleiste bleibt unsichtbar (ein Menueband ersetzt sie) }
    property ToolbarHidden: Boolean read FToolHidden write SetToolbarHidden;
  end;

implementation

const
  SplSize = 6;
  EdgeBand = 32;
  ToolColWidth = 112;

{ ---------- Anlegen ---------- }

constructor TPaneDock.Create(AForm: TForm; AWork: TPanel);
var
  I: Integer;
begin
  inherited Create;
  FForm := AForm;
  FWork := AWork;
  FPanes := TList.Create;
  FToolEdge := teTop;
  FToolVisible := True;
  FToolFW := 560;
  FToolFH := 110;
  FDefault := '';
  // unsichtbarer Parkplatz fuer Bereiche, die gerade nirgends andocken
  FParking := TPanel.Create(FForm);
  FParking.Parent := FForm;
  FParking.Visible := False;
  FParking.Caption := '';
  FParking.SetBounds(0, 0, 10, 10);
  // Rahmen fuer die Zielanzeige beim Ziehen
  for I := 0 to 3 do
  begin
    FFrame[I] := TPanel.Create(FForm);
    FFrame[I].Parent := FForm;
    FFrame[I].BevelOuter := bvNone;
    FFrame[I].Caption := '';
    FFrame[I].ParentColor := False;
    FFrame[I].Color := clHighlight;
    FFrame[I].Visible := False;
  end;
  FWork.OnResize := @WorkResize;
end;

destructor TPaneDock.Destroy;
var
  I: Integer;
begin
  Application.RemoveAsyncCalls(Self);
  FOnChange := nil;
  if FWork <> nil then FWork.OnResize := nil;
  FreeTree(FRoot);
  FRoot := nil;
  for I := 0 to FPanes.Count - 1 do
    TPaneItem(FPanes[I]).Free;
  FPanes.Free;
  inherited Destroy;
end;

function TPaneDock.AddPane(const AName, ATitle: string;
  AContent: TControl): TPaneItem;
var
  Mi: TMenuItem;
begin
  Result := TPaneItem.Create;
  Result.Name := AName;
  Result.Title := ATitle;
  Result.Index := FPanes.Count;
  Result.State := dsDocked;
  FPanes.Add(Result);

  Result.Box := TPanel.Create(FForm);
  Result.Box.Caption := '';
  Result.Box.BevelOuter := bvNone;
  Result.Box.Parent := FParking;
  Result.Box.Align := alClient;

  Result.TitleBar := TPanel.Create(FForm);
  Result.TitleBar.Parent := Result.Box;
  Result.TitleBar.Align := alTop;
  Result.TitleBar.Height := 22;
  Result.TitleBar.BevelOuter := bvNone;
  Result.TitleBar.Alignment := taLeftJustify;
  Result.TitleBar.Caption := ' ' + ATitle;
  Result.TitleBar.ParentColor := False;
  Result.TitleBar.Color := TColor($00DCC8B4);
  Result.TitleBar.ParentFont := False;
  Result.TitleBar.Font.Style := [fsBold];
  Result.TitleBar.Cursor := crSizeAll;
  Result.TitleBar.Hint := 'Mit der Maus ziehen, um den Bereich umzusetzen ' +
    '(an den Rand eines anderen Bereichs, oder aus dem Fenster heraus ' +
    'zum Schweben). Rechtsklick: Menü.';
  Result.TitleBar.ShowHint := True;
  Result.TitleBar.Tag := Result.Index;
  Result.TitleBar.OnMouseDown := @TitleDown;
  Result.TitleBar.OnMouseMove := @TitleMove;
  Result.TitleBar.OnMouseUp := @TitleUp;

  Result.BtnClose := TSpeedButton.Create(FForm);
  Result.BtnClose.Parent := Result.TitleBar;
  Result.BtnClose.Align := alRight;
  Result.BtnClose.Width := 22;
  Result.BtnClose.Flat := True;
  Result.BtnClose.Caption := 'x';
  Result.BtnClose.Hint := 'Bereich schließen (Ansicht, Bereiche: wieder einblenden)';
  Result.BtnClose.ShowHint := True;
  Result.BtnClose.Tag := Result.Index;
  Result.BtnClose.OnClick := @CloseClick;

  Result.Popup := TPopupMenu.Create(FForm);
  Mi := TMenuItem.Create(FForm);
  Mi.Caption := 'Schließen';
  Mi.Tag := Result.Index;
  Mi.OnClick := @PopClose;
  Result.Popup.Items.Add(Mi);
  Mi := TMenuItem.Create(FForm);
  Mi.Caption := 'Als schwebendes Fenster lösen';
  Mi.Tag := Result.Index;
  Mi.OnClick := @PopFloat;
  Result.Popup.Items.Add(Mi);
  Mi := TMenuItem.Create(FForm);
  Mi.Caption := 'Am rechten Rand andocken';
  Mi.Tag := Result.Index;
  Mi.OnClick := @PopDock;
  Result.Popup.Items.Add(Mi);
  Result.TitleBar.PopupMenu := Result.Popup;

  AContent.Parent := Result.Box;
  AContent.Align := alClient;
end;

procedure TPaneDock.SetTitle(const AName, ATitle: string);
var
  P: TPaneItem;
begin
  P := FindPane(AName);
  if P = nil then Exit;
  P.Title := ATitle;
  P.TitleBar.Caption := ' ' + ATitle;
  if P.FloatForm <> nil then P.FloatForm.Caption := ATitle;
end;

function TPaneDock.FindPane(const AName: string): TPaneItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FPanes.Count - 1 do
    if SameText(TPaneItem(FPanes[I]).Name, AName) then
    begin
      Result := TPaneItem(FPanes[I]);
      Exit;
    end;
end;

function TPaneDock.PaneCount: Integer;
begin
  Result := FPanes.Count;
end;

function TPaneDock.PaneAt(AIndex: Integer): TPaneItem;
begin
  Result := TPaneItem(FPanes[AIndex]);
end;

function TPaneDock.PaneVisible(const AName: string): Boolean;
var
  P: TPaneItem;
begin
  P := FindPane(AName);
  Result := (P <> nil) and (P.State <> dsHidden);
end;

procedure TPaneDock.DoChange;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

{ ---------- Modell: Baum ---------- }

function TPaneDock.NewLeaf(P: TPaneItem): TPaneNode;
begin
  Result := TPaneNode.Create;
  Result.Pane := P;
  Result.Ratio := 0.5;
  P.Node := Result;
  P.State := dsDocked;
end;

procedure TPaneDock.ReplaceNode(Old, New: TPaneNode);
begin
  New.Parent := Old.Parent;
  if Old.Parent = nil then
    FRoot := New
  else if Old.Parent.A = Old then
    Old.Parent.A := New
  else
    Old.Parent.B := New;
end;

procedure TPaneDock.Detach(P: TPaneItem);
var
  N, Par, Sib: TPaneNode;
begin
  N := P.Node;
  if N = nil then Exit;
  Par := N.Parent;
  if Par = nil then
    FRoot := nil
  else
  begin
    if Par.A = N then Sib := Par.B else Sib := Par.A;
    ReplaceNode(Par, Sib);
    Par.Free;
  end;
  N.Free;
  P.Node := nil;
end;

procedure TPaneDock.InsertBeside(P: TPaneItem; T: TPaneNode; Zone: TDropZone);
var
  Sp, Leaf: TPaneNode;
begin
  Leaf := NewLeaf(P);
  Sp := TPaneNode.Create;
  ReplaceNode(T, Sp);
  Sp.Horiz := Zone in [dzLeft, dzRight];
  Sp.Ratio := 0.5;
  if Zone in [dzLeft, dzTop] then
  begin
    Sp.A := Leaf;
    Sp.B := T;
  end
  else
  begin
    Sp.A := T;
    Sp.B := Leaf;
  end;
  Leaf.Parent := Sp;
  T.Parent := Sp;
end;

procedure TPaneDock.InsertAtRoot(P: TPaneItem; Zone: TDropZone);
var
  Sp, Leaf, OldRoot: TPaneNode;
begin
  Leaf := NewLeaf(P);
  if FRoot = nil then
  begin
    FRoot := Leaf;
    Exit;
  end;
  OldRoot := FRoot;
  Sp := TPaneNode.Create;
  Sp.Horiz := Zone in [dzLeft, dzRight];
  if Zone in [dzLeft, dzTop] then
  begin
    Sp.Ratio := 0.4;
    Sp.A := Leaf;
    Sp.B := OldRoot;
  end
  else
  begin
    Sp.Ratio := 0.6;
    Sp.A := OldRoot;
    Sp.B := Leaf;
  end;
  Leaf.Parent := Sp;
  OldRoot.Parent := Sp;
  Sp.Parent := nil;
  FRoot := Sp;
end;

procedure TPaneDock.FreeTree(N: TPaneNode);
begin
  if N = nil then Exit;
  FreeTree(N.A);
  FreeTree(N.B);
  N.Free;
end;

procedure TPaneDock.ClearModel;
var
  I: Integer;
begin
  FreeTree(FRoot);
  FRoot := nil;
  for I := 0 to FPanes.Count - 1 do
    TPaneItem(FPanes[I]).Node := nil;
end;

procedure TPaneDock.ClearHosts(N: TPaneNode);
begin
  if N = nil then Exit;
  N.Host := nil;
  N.Spl := nil;
  ClearHosts(N.A);
  ClearHosts(N.B);
end;

{ Anteile aus den tatsaechlichen Groessen lesen }
procedure TPaneDock.CaptureRatios(N: TPaneNode);
var
  Sa, Sb: Integer;
begin
  if (N = nil) or (N.Pane <> nil) then Exit;
  if (N.A <> nil) and (N.B <> nil) and (N.A.Host <> nil) and (N.B.Host <> nil) then
  begin
    if N.Horiz then
    begin
      Sa := N.A.Host.Width;
      Sb := N.B.Host.Width;
    end
    else
    begin
      Sa := N.A.Host.Height;
      Sb := N.B.Host.Height;
    end;
    if (Sa > 20) and (Sb > 20) then
      N.Ratio := Sa / (Sa + Sb);
  end;
  CaptureRatios(N.A);
  CaptureRatios(N.B);
end;

procedure TPaneDock.ApplyRatios(N: TPaneNode; W, H: Integer);
var
  Sa: Integer;
begin
  if (N = nil) or (N.Pane <> nil) then Exit;
  if (N.A = nil) or (N.B = nil) or (N.A.Host = nil) or (N.B.Host = nil) then Exit;
  if N.Horiz then
  begin
    Sa := Round((W - SplSize) * N.Ratio);
    if Sa < 50 then Sa := 50;
    if Sa > W - SplSize - 50 then Sa := W - SplSize - 50;
    if Sa < 10 then Exit;
    N.A.Host.Width := Sa;
    ApplyRatios(N.A, Sa, H);
    ApplyRatios(N.B, W - Sa - SplSize, H);
  end
  else
  begin
    Sa := Round((H - SplSize) * N.Ratio);
    if Sa < 50 then Sa := 50;
    if Sa > H - SplSize - 50 then Sa := H - SplSize - 50;
    if Sa < 10 then Exit;
    N.A.Host.Height := Sa;
    ApplyRatios(N.A, W, Sa);
    ApplyRatios(N.B, W, H - Sa - SplSize);
  end;
end;

{ ---------- Speichern / Laden als Text ---------- }

function TPaneDock.NodeToStr(N: TPaneNode): string;
var
  C: string;
begin
  Result := '';
  if N = nil then Exit;
  if N.Pane <> nil then
    Result := N.Pane.Name
  else
  begin
    if N.Horiz then C := 'H' else C := 'V';
    Result := C + IntToStr(Round(N.Ratio * 1000)) + '(' + NodeToStr(N.A) + ',' +
      NodeToStr(N.B) + ')';
  end;
end;

function TPaneDock.ParseNode(const S: string; var I: Integer;
  AParent: TPaneNode): TPaneNode;
var
  Start, V: Integer;
  Id: string;
  P: TPaneItem;
begin
  Result := nil;
  if I > Length(S) then
  begin
    FOk := False;
    Exit;
  end;
  if (S[I] in ['H', 'V']) and (I < Length(S)) and (S[I + 1] in ['0'..'9']) then
  begin
    Result := TPaneNode.Create;
    Result.Parent := AParent;
    Result.Horiz := S[I] = 'H';
    Inc(I);
    Start := I;
    while (I <= Length(S)) and (S[I] in ['0'..'9']) do Inc(I);
    V := StrToIntDef(Copy(S, Start, I - Start), 500);
    if V < 100 then V := 100;
    if V > 900 then V := 900;
    Result.Ratio := V / 1000;
    if (I > Length(S)) or (S[I] <> '(') then
    begin
      FOk := False;
      Exit;
    end;
    Inc(I);
    Result.A := ParseNode(S, I, Result);
    if (not FOk) or (I > Length(S)) or (S[I] <> ',') then
    begin
      FOk := False;
      Exit;
    end;
    Inc(I);
    Result.B := ParseNode(S, I, Result);
    if (not FOk) or (I > Length(S)) or (S[I] <> ')') then
    begin
      FOk := False;
      Exit;
    end;
    Inc(I);
  end
  else
  begin
    Start := I;
    while (I <= Length(S)) and not (S[I] in ['(', ')', ',']) do Inc(I);
    Id := Copy(S, Start, I - Start);
    P := FindPane(Id);
    if (P = nil) or (P.Node <> nil) then
    begin
      FOk := False;
      Exit;
    end;
    Result := NewLeaf(P);
    Result.Parent := AParent;
  end;
end;

procedure TPaneDock.ParseLayout(const S: string);
var
  I: Integer;
begin
  ClearModel;
  FOk := True;
  I := 1;
  FRoot := ParseNode(S, I, nil);
  if (not FOk) or (I <= Length(S)) then
  begin
    ClearModel;
    FOk := False;
  end;
end;

procedure TPaneDock.ResetDefault;
var
  I: Integer;
begin
  ParseLayout(FDefault);
  for I := 0 to FPanes.Count - 1 do
    if TPaneItem(FPanes[I]).Node = nil then
    begin
      if Pos(',' + LowerCase(TPaneItem(FPanes[I]).Name) + ',',
        ',' + LowerCase(FDefaultHidden) + ',') > 0 then
        TPaneItem(FPanes[I]).State := dsHidden
      else
        InsertAtRoot(TPaneItem(FPanes[I]), dzRight);
    end;
  FToolEdge := teTop;
  FToolFloating := False;
  FToolVisible := True;
end;

procedure TPaneDock.LoadFromIni(Ini: TIniFile; const ASection: string);
var
  S, Item, Nm: string;
  List, Parts: TStringList;
  I: Integer;
  P: TPaneItem;
begin
  ResetDefault;
  for I := 0 to FPanes.Count - 1 do
    if TPaneItem(FPanes[I]).Node <> nil then
      TPaneItem(FPanes[I]).State := dsDocked;
  if Ini.ValueExists(ASection, 'Layout') then
  begin
    S := Ini.ReadString(ASection, 'Layout', '');
    if S = '' then
      ClearModel
    else
    begin
      ParseLayout(S);
      if not FOk then ResetDefault;
    end;
    for I := 0 to FPanes.Count - 1 do
      if TPaneItem(FPanes[I]).Node <> nil then
        TPaneItem(FPanes[I]).State := dsDocked
      else
        TPaneItem(FPanes[I]).State := dsHidden;
    List := TStringList.Create;
    Parts := TStringList.Create;
    try
      // schwebende Bereiche: name,links,oben,breite,hoehe | ...
      List.Delimiter := '|';
      List.StrictDelimiter := True;
      List.DelimitedText := Ini.ReadString(ASection, 'Float', '');
      for I := 0 to List.Count - 1 do
      begin
        Item := List[I];
        Parts.Clear;
        Parts.Delimiter := ',';
        Parts.StrictDelimiter := True;
        Parts.DelimitedText := Item;
        if Parts.Count < 5 then Continue;
        Nm := Parts[0];
        P := FindPane(Nm);
        if (P <> nil) and (P.Node = nil) then
        begin
          P.State := dsFloating;
          P.FloatL := StrToIntDef(Parts[1], 100);
          P.FloatT := StrToIntDef(Parts[2], 100);
          P.FloatW := StrToIntDef(Parts[3], 360);
          P.FloatH := StrToIntDef(Parts[4], 300);
        end;
      end;
    finally
      Parts.Free;
      List.Free;
    end;
  end;
  // Bereiche, die nirgends verzeichnet sind und nicht ausgeblendet waren
  case Ini.ReadInteger(ASection, 'ToolEdge', 0) of
    1: FToolEdge := teBottom;
    2: FToolEdge := teLeft;
    3: FToolEdge := teRight;
  else
    FToolEdge := teTop;
  end;
  FToolFloating := Ini.ReadBool(ASection, 'ToolFloating', False);
  FToolVisible := Ini.ReadBool(ASection, 'ToolVisible', True);
  FToolFL := Ini.ReadInteger(ASection, 'ToolLeft', 100);
  FToolFT := Ini.ReadInteger(ASection, 'ToolTop', 100);
  FToolFW := Ini.ReadInteger(ASection, 'ToolWidth', 560);
  FToolFH := Ini.ReadInteger(ASection, 'ToolHeight', 110);
  if FToolFW < 100 then FToolFW := 560;
  if FToolFH < 40 then FToolFH := 110;
end;

procedure TPaneDock.SaveToIni(Ini: TIniFile; const ASection: string);
var
  I: Integer;
  P: TPaneItem;
  Fl: string;
begin
  CaptureRatios(FRoot);
  Ini.WriteString(ASection, 'Layout', NodeToStr(FRoot));
  Fl := '';
  for I := 0 to FPanes.Count - 1 do
  begin
    P := TPaneItem(FPanes[I]);
    if (P.State = dsFloating) and (P.FloatForm <> nil) then
    begin
      P.FloatL := P.FloatForm.Left;
      P.FloatT := P.FloatForm.Top;
      P.FloatW := P.FloatForm.Width;
      P.FloatH := P.FloatForm.Height;
    end;
    if P.State = dsFloating then
    begin
      if Fl <> '' then Fl := Fl + '|';
      Fl := Fl + Format('%s,%d,%d,%d,%d', [P.Name, P.FloatL, P.FloatT, P.FloatW,
        P.FloatH]);
    end;
  end;
  Ini.WriteString(ASection, 'Float', Fl);
  if FToolFloating and (FToolForm <> nil) then
  begin
    FToolFL := FToolForm.Left;
    FToolFT := FToolForm.Top;
    FToolFW := FToolForm.Width;
    FToolFH := FToolForm.Height;
  end;
  Ini.WriteInteger(ASection, 'ToolEdge', Ord(FToolEdge));
  Ini.WriteBool(ASection, 'ToolFloating', FToolFloating);
  Ini.WriteBool(ASection, 'ToolVisible', FToolVisible);
  Ini.WriteInteger(ASection, 'ToolLeft', FToolFL);
  Ini.WriteInteger(ASection, 'ToolTop', FToolFT);
  Ini.WriteInteger(ASection, 'ToolWidth', FToolFW);
  Ini.WriteInteger(ASection, 'ToolHeight', FToolFH);
end;

{ ---------- Aufbau der Oberflaeche aus dem Baum ---------- }

function TPaneDock.MakeHost(N: TPaneNode; AParent: TWinControl; AAlign: TAlign;
  ASize, W, H: Integer): TPanel;
var
  Wa, Ha: Integer;
  Sp: TSplitter;
begin
  Result := TPanel.Create(FForm);
  Result.Caption := '';
  Result.BevelOuter := bvNone;
  Result.Parent := AParent;
  Result.Align := AAlign;
  if AAlign = alLeft then
  begin
    Result.Left := 0;
    Result.Width := ASize;
  end
  else if AAlign = alTop then
  begin
    Result.Top := 0;
    Result.Height := ASize;
  end;
  N.Host := Result;
  if N.Pane <> nil then
  begin
    N.Pane.Box.Parent := Result;
    N.Pane.Box.Align := alClient;
    N.Pane.Box.Visible := True;
  end
  else if (N.A <> nil) and (N.B <> nil) then
  begin
    if N.Horiz then
    begin
      Wa := Round((W - SplSize) * N.Ratio);
      if Wa < 50 then Wa := 50;
      if Wa > W - SplSize - 50 then Wa := W - SplSize - 50;
      if Wa < 10 then Wa := 10;
      MakeHost(N.A, Result, alLeft, Wa, Wa, H);
      Sp := TSplitter.Create(FForm);
      Sp.Parent := Result;
      Sp.Align := alLeft;
      Sp.Left := Wa;
      Sp.Width := SplSize;
      Sp.Beveled := True;
      Sp.MinSize := 50;
      Sp.OnMoved := @SplitMoved;
      N.Spl := Sp;
      MakeHost(N.B, Result, alClient, 0, W - Wa - SplSize, H);
    end
    else
    begin
      Ha := Round((H - SplSize) * N.Ratio);
      if Ha < 50 then Ha := 50;
      if Ha > H - SplSize - 50 then Ha := H - SplSize - 50;
      if Ha < 10 then Ha := 10;
      MakeHost(N.A, Result, alTop, Ha, W, Ha);
      Sp := TSplitter.Create(FForm);
      Sp.Parent := Result;
      Sp.Align := alTop;
      Sp.Top := Ha;
      Sp.Height := SplSize;
      Sp.Beveled := True;
      Sp.MinSize := 50;
      Sp.OnMoved := @SplitMoved;
      N.Spl := Sp;
      MakeHost(N.B, Result, alClient, 0, W, H - Ha - SplSize);
    end;
  end;
end;

procedure TPaneDock.Rebuild;
var
  I: Integer;
  P: TPaneItem;
begin
  if FRebuilding then Exit;
  FRebuilding := True;
  try
    FForm.DisableAlign;
    try
      // Bereiche aus den alten Rahmen herausnehmen
      for I := 0 to FPanes.Count - 1 do
      begin
        P := TPaneItem(FPanes[I]);
        case P.State of
          dsDocked:
            begin
              if (P.FloatForm <> nil) and P.FloatForm.Visible then P.FloatForm.Hide;
              P.Box.Parent := FParking;
            end;
          dsHidden:
            begin
              if (P.FloatForm <> nil) and P.FloatForm.Visible then P.FloatForm.Hide;
              P.Box.Parent := FParking;
            end;
          dsFloating:
            // darf nicht mit den alten Rahmen freigegeben werden
            if (P.FloatForm = nil) or (P.Box.Parent <> P.FloatForm) then
              P.Box.Parent := FParking;
        end;
      end;
      if FRootHost <> nil then
      begin
        ClearHosts(FRoot);
        FRootHost.Free;
        FRootHost := nil;
      end;
      if FRoot <> nil then
        FRootHost := MakeHost(FRoot, FWork, alClient, 0, FWork.ClientWidth,
          FWork.ClientHeight);
      for I := 0 to FPanes.Count - 1 do
      begin
        P := TPaneItem(FPanes[I]);
        if P.State = dsFloating then EnsureFloat(P);
      end;
    finally
      FForm.EnableAlign;
    end;
    ApplyToolbar;
    FBuilt := FWork.ClientWidth > 200;
  finally
    FRebuilding := False;
  end;
  DoChange;
end;

procedure TPaneDock.EnsureFloat(P: TPaneItem);
var
  Created, Placed: Boolean;
  L, T, W, H: Integer;
begin
  Created := P.FloatForm = nil;
  if Created then
  begin
    P.FloatForm := TForm.CreateNew(FForm);
    P.FloatForm.BorderStyle := bsSizeToolWin;
    P.FloatForm.PopupMode := pmExplicit;
    P.FloatForm.PopupParent := FForm;
    P.FloatForm.Tag := P.Index;
    P.FloatForm.OnClose := @FloatClose;
  end;
  P.FloatForm.Caption := P.Title;
  Placed := P.Box.Parent <> P.FloatForm;
  if Placed then
  begin
    P.Box.Parent := P.FloatForm;
    P.Box.Align := alClient;
    P.Box.Visible := True;
  end;
  if Created or Placed then
  begin
    W := P.FloatW;
    H := P.FloatH;
    L := P.FloatL;
    T := P.FloatT;
    if W < 160 then W := 360;
    if H < 100 then H := 300;
    if L > Screen.Width - 80 then L := Screen.Width - W - 20;
    if T > Screen.Height - 80 then T := Screen.Height - H - 60;
    if L < 0 then L := 0;
    if T < 0 then T := 0;
    P.FloatForm.SetBounds(L, T, W, H);
  end;
  if not P.FloatForm.Visible then P.FloatForm.Show;
end;

procedure TPaneDock.FloatPane(P: TPaneItem; X, Y: Integer);
begin
  if P.State = dsDocked then
  begin
    P.FloatW := P.Box.Width + 6;
    P.FloatH := P.Box.Height + 6;
    Detach(P);
  end;
  P.State := dsFloating;
  P.FloatL := X;
  P.FloatT := Y;
  if (P.FloatForm <> nil) and (P.Box.Parent = P.FloatForm) then
    P.FloatForm.SetBounds(X, Y, P.FloatForm.Width, P.FloatForm.Height);
  Rebuild;
end;

procedure TPaneDock.SetPaneVisible(const AName: string; AShow: Boolean);
var
  P: TPaneItem;
begin
  P := FindPane(AName);
  if P = nil then Exit;
  CaptureRatios(FRoot);
  if AShow then
  begin
    if P.State <> dsHidden then Exit;
    InsertAtRoot(P, dzRight);
  end
  else
  begin
    if P.State = dsHidden then Exit;
    if P.State = dsDocked then Detach(P);
    P.State := dsHidden;
  end;
  Rebuild;
end;

{ ---------- Ereignisse der Bereiche ---------- }

procedure TPaneDock.SplitMoved(Sender: TObject);
begin
  CaptureRatios(FRoot);
end;

procedure TPaneDock.WorkResize(Sender: TObject);
begin
  if (not FBuilt) or FRebuilding or (FRoot = nil) then Exit;
  ApplyRatios(FRoot, FWork.ClientWidth, FWork.ClientHeight);
end;

procedure TPaneDock.FloatClose(Sender: TObject; var CloseAction: TCloseAction);
var
  P: TPaneItem;
begin
  CloseAction := caHide;
  P := TPaneItem(FPanes[(Sender as TForm).Tag]);
  P.FloatL := P.FloatForm.Left;
  P.FloatT := P.FloatForm.Top;
  P.FloatW := P.FloatForm.Width;
  P.FloatH := P.FloatForm.Height;
  P.State := dsHidden;
  DoChange;
end;

procedure TPaneDock.CloseClick(Sender: TObject);
var
  P: TPaneItem;
begin
  P := TPaneItem(FPanes[(Sender as TControl).Tag]);
  Application.QueueAsyncCall(@DoDrop, -1 - P.Index);
end;

procedure TPaneDock.PopClose(Sender: TObject);
begin
  Application.QueueAsyncCall(@DoDrop, -1 - (Sender as TMenuItem).Tag);
end;

procedure TPaneDock.PopFloat(Sender: TObject);
begin
  Application.QueueAsyncCall(@DoDrop, -101 - (Sender as TMenuItem).Tag);
end;

procedure TPaneDock.PopDock(Sender: TObject);
begin
  Application.QueueAsyncCall(@DoDrop, -201 - (Sender as TMenuItem).Tag);
end;

{ ---------- Ziehen mit der Maus ---------- }

procedure TPaneDock.TitleDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then Exit;
  if Sender = FGrip then
  begin
    FDragTool := True;
    FDragPane := nil;
  end
  else
  begin
    FDragTool := False;
    FDragPane := TPaneItem(FPanes[(Sender as TControl).Tag]);
  end;
  FDragActive := False;
  FDragStart := Mouse.CursorPos;
  SetCaptureControl(Sender as TControl);
end;

procedure TPaneDock.TitleMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if (FDragPane = nil) and (not FDragTool) then Exit;
  if not (ssLeft in Shift) then Exit;
  P := Mouse.CursorPos;
  if not FDragActive then
  begin
    if (Abs(P.X - FDragStart.X) < 6) and (Abs(P.Y - FDragStart.Y) < 6) then Exit;
    FDragActive := True;
    FOldCursor := Screen.Cursor;
    Screen.Cursor := crSizeAll;
  end;
  if FDragTool then
    UpdateToolTarget(P)
  else
    UpdateDropTarget(P);
end;

procedure TPaneDock.TitleUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (FDragPane = nil) and (not FDragTool) then Exit;
  SetCaptureControl(nil);
  EndDrag(Button = mbLeft);
end;

procedure TPaneDock.EndDrag(ADrop: Boolean);
begin
  HideFrame;
  if FDragActive then Screen.Cursor := FOldCursor;
  if ADrop and FDragActive then
  begin
    FPendTool := FDragTool;
    FPendPane := FDragPane;
    FPendZone := FDropZone;
    FPendTarget := FDropTarget;
    FPendRoot := FDropRoot;
    FPendEdge := FToolEdgeDrop;
    FPendPt := Mouse.CursorPos;
    if FDropZone <> dzNone then
      Application.QueueAsyncCall(@DoDrop, 0);
  end;
  FDragActive := False;
  FDragPane := nil;
  FDragTool := False;
  FDropZone := dzNone;
end;

procedure TPaneDock.ShowFrame(const R: TRect);
var
  I: Integer;
begin
  FFrame[0].SetBounds(R.Left, R.Top, R.Right - R.Left, 4);
  FFrame[1].SetBounds(R.Left, R.Bottom - 4, R.Right - R.Left, 4);
  FFrame[2].SetBounds(R.Left, R.Top, 4, R.Bottom - R.Top);
  FFrame[3].SetBounds(R.Right - 4, R.Top, 4, R.Bottom - R.Top);
  for I := 0 to 3 do
  begin
    FFrame[I].Visible := True;
    FFrame[I].BringToFront;
  end;
end;

procedure TPaneDock.HideFrame;
var
  I: Integer;
begin
  for I := 0 to 3 do FFrame[I].Visible := False;
end;

function ZoneRect(AZone: TDropZone; W, H: Integer): TRect;
begin
  case AZone of
    dzLeft: Result := Rect(0, 0, W div 2, H);
    dzRight: Result := Rect(W div 2, 0, W, H);
    dzTop: Result := Rect(0, 0, W, H div 2);
    dzBottom: Result := Rect(0, H div 2, W, H);
  else
    Result := Rect(0, 0, W, H);
  end;
end;

procedure TPaneDock.UpdateDropTarget(const P: TPoint);
var
  I: Integer;
  Pn: TPaneItem;
  Q, Tl, Br: TPoint;
  R: TRect;
  Wp: TPoint;
  W, H: Integer;
  Z: TDropZone;
  OnlyMe: Boolean;
begin
  FDropZone := dzNone;
  FDropTarget := nil;
  FDropRoot := False;
  HideFrame;
  W := FWork.ClientWidth;
  H := FWork.ClientHeight;
  Wp := FWork.ScreenToClient(P);
  OnlyMe := (FRoot <> nil) and (FRoot.Pane = FDragPane);
  if PtInRect(Rect(0, 0, W, H), Wp) then
  begin
    if FRoot = nil then
    begin
      FDropRoot := True;
      FDropZone := dzRight;
      R := Rect(0, 0, W, H);
    end
    else if OnlyMe then
      Exit
    else
    begin
      Z := dzNone;
      if Wp.X < EdgeBand then Z := dzLeft
      else if Wp.X >= W - EdgeBand then Z := dzRight
      else if Wp.Y < EdgeBand then Z := dzTop
      else if Wp.Y >= H - EdgeBand then Z := dzBottom;
      if Z <> dzNone then
      begin
        FDropRoot := True;
        FDropZone := Z;
        R := ZoneRect(Z, W, H);
        // schmaler Streifen am Rand statt der halben Flaeche
        case Z of
          dzLeft: R.Right := W div 4;
          dzRight: R.Left := W - W div 4;
          dzTop: R.Bottom := H div 4;
          dzBottom: R.Top := H - H div 4;
        end;
      end
      else
      begin
        for I := 0 to FPanes.Count - 1 do
        begin
          Pn := TPaneItem(FPanes[I]);
          if (Pn = FDragPane) or (Pn.State <> dsDocked) then Continue;
          Q := Pn.Box.ScreenToClient(P);
          if (Q.X < 0) or (Q.Y < 0) or (Q.X >= Pn.Box.Width) or
            (Q.Y >= Pn.Box.Height) then Continue;
          if Q.X < Pn.Box.Width div 4 then Z := dzLeft
          else if Q.X >= Pn.Box.Width - Pn.Box.Width div 4 then Z := dzRight
          else if Q.Y < Pn.Box.Height div 4 then Z := dzTop
          else if Q.Y >= Pn.Box.Height - Pn.Box.Height div 4 then Z := dzBottom
          else Z := dzCenter;
          if (Z = dzCenter) and (FDragPane.State <> dsDocked) then Z := dzRight;
          FDropTarget := Pn;
          FDropZone := Z;
          R := ZoneRect(Z, Pn.Box.Width, Pn.Box.Height);
          Tl := FForm.ScreenToClient(Pn.Box.ClientToScreen(Point(R.Left, R.Top)));
          Br := FForm.ScreenToClient(Pn.Box.ClientToScreen(Point(R.Right, R.Bottom)));
          ShowFrame(Rect(Tl.X, Tl.Y, Br.X, Br.Y));
          Exit;
        end;
        Exit;
      end;
    end;
    Tl := FForm.ScreenToClient(FWork.ClientToScreen(Point(R.Left, R.Top)));
    Br := FForm.ScreenToClient(FWork.ClientToScreen(Point(R.Right, R.Bottom)));
    ShowFrame(Rect(Tl.X, Tl.Y, Br.X, Br.Y));
  end
  else if not PtInRect(FForm.BoundsRect, P) then
    FDropZone := dzFloat;
end;

procedure TPaneDock.UpdateToolTarget(const P: TPoint);
var
  Pf: TPoint;
  W, H, DT, DB, DL, DR, M: Integer;
  E: TToolEdge;
begin
  FDropZone := dzNone;
  HideFrame;
  if not PtInRect(FForm.BoundsRect, P) then
  begin
    FDropZone := dzFloat;
    Exit;
  end;
  Pf := FForm.ScreenToClient(P);
  W := FForm.ClientWidth;
  H := FForm.ClientHeight;
  DT := Pf.Y;
  DB := H - Pf.Y;
  DL := Pf.X;
  DR := W - Pf.X;
  M := DT;
  E := teTop;
  if DB < M then begin M := DB; E := teBottom; end;
  if DL < M then begin M := DL; E := teLeft; end;
  if DR < M then begin M := DR; E := teRight; end;
  if M > 90 then Exit;
  FDropZone := dzCenter;
  FToolEdgeDrop := E;
  case E of
    teTop: ShowFrame(Rect(0, 0, W, 56));
    teBottom: ShowFrame(Rect(0, H - 56, W, H));
    teLeft: ShowFrame(Rect(0, 0, 120, H));
    teRight: ShowFrame(Rect(W - 120, 0, W, H));
  end;
end;

{ Fuehrt Ablegen und Menuebefehle aus. Data = 0: Ablegen; negativ: Befehle }
procedure TPaneDock.DoDrop(Data: PtrInt);
var
  P, T: TPaneItem;
  Tmp: TPaneNode;
  Idx: Integer;
  Pt: TPoint;
begin
  CaptureRatios(FRoot);
  if Data < 0 then
  begin
    if Data <= -201 then
    begin
      Idx := -201 - Data;
      P := TPaneItem(FPanes[Idx]);
      if P.State <> dsDocked then
      begin
        CaptureRatios(FRoot);
        InsertAtRoot(P, dzRight);
        Rebuild;
      end;
    end
    else if Data <= -101 then
    begin
      Idx := -101 - Data;
      P := TPaneItem(FPanes[Idx]);
      if P.State = dsDocked then
      begin
        Pt := P.Box.ClientToScreen(Point(30, 30));
        FloatPane(P, Pt.X, Pt.Y);
      end;
    end
    else
    begin
      Idx := -1 - Data;
      SetPaneVisible(TPaneItem(FPanes[Idx]).Name, False);
    end;
    Exit;
  end;

  if FPendTool then
  begin
    if FPendZone = dzFloat then
    begin
      FToolFloating := True;
      FToolFL := FPendPt.X - 40;
      FToolFT := FPendPt.Y - 10;
    end
    else
    begin
      FToolFloating := False;
      FToolEdge := FPendEdge;
    end;
    FToolVisible := True;
    ApplyToolbar;
    DoChange;
    Exit;
  end;

  P := FPendPane;
  if P = nil then Exit;
  case FPendZone of
    dzFloat:
      FloatPane(P, FPendPt.X - 60, FPendPt.Y - 10);
    dzLeft, dzRight, dzTop, dzBottom:
      begin
        if P.State = dsDocked then Detach(P);
        if FPendRoot or (FPendTarget = nil) or (FPendTarget.Node = nil) then
          InsertAtRoot(P, FPendZone)
        else
          InsertBeside(P, FPendTarget.Node, FPendZone);
        Rebuild;
      end;
    dzCenter:
      begin
        T := FPendTarget;
        if (T <> nil) and (T.Node <> nil) and (P.Node <> nil) then
        begin
          Tmp := P.Node;
          P.Node := T.Node;
          T.Node := Tmp;
          P.Node.Pane := P;
          T.Node.Pane := T;
          Rebuild;
        end;
      end;
  end;
end;

{ ---------- Knopfleiste ---------- }

procedure TPaneDock.AttachToolbar(ATool: TFlowPanel; AStatus: TControl);
begin
  FTool := ATool;
  FStatus := AStatus;
  FGrip := TPanel.Create(FForm);
  FGrip.Parent := FTool;
  FGrip.BevelOuter := bvRaised;
  FGrip.Caption := '::';
  FGrip.ParentColor := False;
  FGrip.Color := TColor($00DCC8B4);
  FGrip.Width := 12;
  FGrip.Height := 44;
  FGrip.Cursor := crSizeAll;
  FGrip.Hint := 'Knopfleiste verschieben: ziehen und an einem Fensterrand ablegen, ' +
    'oder aus dem Fenster heraus ziehen (frei schwebend).';
  FGrip.ShowHint := True;
  FGrip.OnMouseDown := @TitleDown;
  FGrip.OnMouseMove := @TitleMove;
  FGrip.OnMouseUp := @TitleUp;
end;

procedure TPaneDock.SetToolOrient(AVert: Boolean);
var
  I: Integer;
  C: TControl;
begin
  if FTool = nil then Exit;
  for I := 0 to FTool.ControlCount - 1 do
  begin
    C := FTool.Controls[I];
    if C = FGrip then
    begin
      if AVert then
      begin
        C.Width := 100;
        C.Height := 10;
      end
      else
      begin
        C.Width := 12;
        C.Height := 44;
      end;
    end
    else if C is TBevel then
    begin
      if AVert then
      begin
        C.Width := 100;
        C.Height := 8;
      end
      else
      begin
        C.Width := 12;
        C.Height := 44;
      end;
    end;
  end;
end;

procedure TPaneDock.ToolFormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caHide;
  FToolVisible := False;
  DoChange;
end;

procedure TPaneDock.ApplyToolbar;
var
  L, T, W, H: Integer;
begin
  if FTool = nil then Exit;
  if FToolHidden then
  begin
    if FToolForm <> nil then FToolForm.Hide;
    FTool.Visible := False;
    Exit;
  end;
  if FToolFloating then
  begin
    if FToolForm = nil then
    begin
      FToolForm := TForm.CreateNew(FForm);
      FToolForm.BorderStyle := bsSizeToolWin;
      FToolForm.PopupMode := pmExplicit;
      FToolForm.PopupParent := FForm;
      FToolForm.Caption := 'Knopfleiste';
      FToolForm.OnClose := @ToolFormClose;
    end;
    if FTool.Parent <> FToolForm then
    begin
      FTool.AutoSize := False;
      FTool.Parent := FToolForm;
      FTool.Align := alClient;
      FTool.Visible := True;
      SetToolOrient(False);
      L := FToolFL;
      T := FToolFT;
      W := FToolFW;
      H := FToolFH;
      if L > Screen.Width - 80 then L := 100;
      if T > Screen.Height - 80 then T := 100;
      if L < 0 then L := 0;
      if T < 0 then T := 0;
      FToolForm.SetBounds(L, T, W, H);
    end;
    if FToolVisible then
    begin
      if not FToolForm.Visible then FToolForm.Show;
    end
    else
      FToolForm.Hide;
  end
  else
  begin
    if (FToolForm <> nil) and FToolForm.Visible then FToolForm.Hide;
    FTool.AutoSize := False;
    FTool.Parent := FForm;
    case FToolEdge of
      teTop:
        begin
          FTool.Align := alTop;
          SetToolOrient(False);
          FTool.AutoSize := True;
        end;
      teBottom:
        begin
          FTool.Align := alBottom;
          SetToolOrient(False);
          FTool.AutoSize := True;
          if FStatus <> nil then FTool.Top := FStatus.Top - 1;
        end;
      teLeft:
        begin
          FTool.Width := ToolColWidth;
          FTool.Align := alLeft;
          SetToolOrient(True);
        end;
      teRight:
        begin
          FTool.Width := ToolColWidth;
          FTool.Align := alRight;
          SetToolOrient(True);
        end;
    end;
    FTool.Visible := FToolVisible;
  end;
end;

procedure TPaneDock.SetToolbarVisible(AValue: Boolean);
begin
  FToolVisible := AValue;
  ApplyToolbar;
end;

procedure TPaneDock.SetToolbarHidden(AValue: Boolean);
begin
  FToolHidden := AValue;
  ApplyToolbar;
end;

end.
