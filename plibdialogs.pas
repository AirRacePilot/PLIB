unit PlibDialogs;

{ Einfache Standarddialoge von PLIB: Mehrfeld-Eingabe und Listenauswahl.
  (Ausgelagert aus mainunit.pas, Stand 1.1) }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Graphics, LCLIntf, LCLType, Forms, Controls, StdCtrls, ExtCtrls, PlibUtil;

function EditFieldsEx(const ACaption: string; const ALabels, ASpecs: array of string;
  var AValues: TStrArr; AFocus: Integer): Boolean;
function EditFields(const ACaption: string; const ALabels, ASpecs: array of string;
  var AValues: TStrArr): Boolean;
function PickIndex(const ACaption, APrompt: string; AItems: TStrings;
  ADefault: Integer): Integer;
{ Zeigt einen laengeren Text in einem Fenster mit Bildlauf (Groesse wird gemerkt) }
procedure InfoText(const ACaption, AText: string);
{ Update-Frage: 1 = jetzt installieren, 2 = spaeter, 3 = diese Version ueberspringen }
function AskUpdate(const ACaption, AText: string): Integer;

implementation

{ Mehrfeld-Eingabedialog. ASpecs je Feld: 'text', 'memo' oder 'combo:a;b;c' }
function EditFieldsEx(const ACaption: string; const ALabels, ASpecs: array of string;
  var AValues: TStrArr; AFocus: Integer): Boolean;
var
  F: TForm;
  i, Y: Integer;
  Lbl: TLabel;
  Ed: TEdit;
  Mm: TMemo;
  Cb: TComboBox;
  Chk: TCheckBox;
  B: TButton;
  Ctrls: array of TControl;
  Spec: string;
begin
  Result := False;
  SetLength(Ctrls, Length(ALabels));
  F := TForm.CreateNew(Application);
  try
    F.Caption := ACaption;
    F.Position := poScreenCenter;
    F.BorderStyle := bsDialog;
    F.Width := 560;
    Y := 10;
    for i := 0 to High(ALabels) do
    begin
      if ASpecs[i] = 'check' then
      begin
        // Kontrollkaestchen: die Beschriftung steht am Feld selbst
        Chk := TCheckBox.Create(F);
        Chk.Parent := F;
        Chk.SetBounds(12, Y, 530, 22);
        Chk.Caption := ALabels[i];
        Chk.Checked := AValues[i] = 'Ja';
        Ctrls[i] := Chk;
        Inc(Y, 32);
        Continue;
      end;
      Lbl := TLabel.Create(F);
      Lbl.Parent := F;
      Lbl.Left := 12;
      Lbl.Top := Y;
      Lbl.Caption := ALabels[i];
      Inc(Y, 18);
      Spec := ASpecs[i];
      if Spec = 'memo' then
      begin
        Mm := TMemo.Create(F);
        Mm.Parent := F;
        Mm.SetBounds(12, Y, 530, 70);
        Mm.ScrollBars := ssAutoVertical;
        Mm.Text := AValues[i];
        Ctrls[i] := Mm;
        Inc(Y, 78);
      end
      else if Copy(Spec, 1, 6) = 'combo:' then
      begin
        Cb := TComboBox.Create(F);
        Cb.Parent := F;
        Cb.SetBounds(12, Y, 530, 24);
        Cb.Style := csDropDownList;
        Cb.Items.Delimiter := ';';
        Cb.Items.StrictDelimiter := True;
        Cb.Items.DelimitedText := Copy(Spec, 7, MaxInt);
        Cb.ItemIndex := Cb.Items.IndexOf(AValues[i]);
        if Cb.ItemIndex < 0 then Cb.ItemIndex := 0;
        Ctrls[i] := Cb;
        Inc(Y, 32);
      end
      else
      begin
        Ed := TEdit.Create(F);
        Ed.Parent := F;
        Ed.SetBounds(12, Y, 530, 24);
        Ed.Text := AValues[i];
        if Spec = 'password' then Ed.PasswordChar := '*';
        Ctrls[i] := Ed;
        Inc(Y, 32);
      end;
    end;
    B := TButton.Create(F);
    B.Parent := F;
    B.Caption := 'OK';
    B.SetBounds(12, Y + 6, 100, 28);
    B.ModalResult := mrOk;
    B.Default := True;
    B := TButton.Create(F);
    B.Parent := F;
    B.Caption := 'Abbrechen';
    B.SetBounds(120, Y + 6, 100, 28);
    B.ModalResult := mrCancel;
    B.Cancel := True;
    F.ClientHeight := Y + 48;
    if Length(Ctrls) > 0 then
    begin
      if (AFocus < 0) or (AFocus > High(Ctrls)) then AFocus := 0;
      F.ActiveControl := TWinControl(Ctrls[AFocus]);
      if Ctrls[AFocus] is TEdit then TEdit(Ctrls[AFocus]).SelectAll;
    end;
    if F.ShowModal = mrOk then
    begin
      for i := 0 to High(ALabels) do
      begin
        if Ctrls[i] is TMemo then AValues[i] := TMemo(Ctrls[i]).Text
        else if Ctrls[i] is TComboBox then AValues[i] := TComboBox(Ctrls[i]).Text
        else if Ctrls[i] is TCheckBox then
        begin
          if TCheckBox(Ctrls[i]).Checked then AValues[i] := 'Ja' else AValues[i] := 'Nein';
        end
        else AValues[i] := TEdit(Ctrls[i]).Text;
      end;
      Result := True;
    end;
  finally
    F.Free;
  end;
end;

function EditFields(const ACaption: string; const ALabels, ASpecs: array of string;
  var AValues: TStrArr): Boolean;
begin
  Result := EditFieldsEx(ACaption, ALabels, ASpecs, AValues, 0);
end;

{ Einfache Listenauswahl; liefert den gewaehlten Index oder -1 }
function PickIndex(const ACaption, APrompt: string; AItems: TStrings;
  ADefault: Integer): Integer;
var
  F: TForm;
  Lbl: TLabel;
  LB: TListBox;
  PB: TPanel;
  B: TButton;
begin
  Result := -1;
  F := TForm.CreateNew(Application);
  try
    F.Caption := ACaption;
    F.Position := poScreenCenter;
    F.Width := 520;
    F.Height := 420;

    PB := TPanel.Create(F);
    PB.Parent := F;
    PB.Align := alBottom;
    PB.Height := 44;
    PB.BevelOuter := bvNone;
    PB.Caption := '';
    B := TButton.Create(F);
    B.Parent := PB;
    B.Caption := 'OK';
    B.SetBounds(8, 8, 100, 28);
    B.ModalResult := mrOk;
    B.Default := True;
    B := TButton.Create(F);
    B.Parent := PB;
    B.Caption := 'Abbrechen';
    B.SetBounds(116, 8, 100, 28);
    B.ModalResult := mrCancel;
    B.Cancel := True;

    Lbl := TLabel.Create(F);
    Lbl.Parent := F;
    Lbl.Align := alTop;
    Lbl.BorderSpacing.Around := 8;
    Lbl.WordWrap := True;
    Lbl.Caption := APrompt;

    LB := TListBox.Create(F);
    LB.Parent := F;
    LB.Align := alClient;
    LB.Items.Assign(AItems);
    if (ADefault >= 0) and (ADefault < LB.Items.Count) then
      LB.ItemIndex := ADefault
    else if LB.Items.Count > 0 then
      LB.ItemIndex := 0;
    if F.ShowModal = mrOk then Result := LB.ItemIndex;
  finally
    F.Free;
  end;
end;

{ Gemeinsames Textfenster: AButtons = Beschriftungen, Rueckgabe = Nummer des Knopfs (1..n),
  0 = Fenster geschlossen. Die Fenstergroesse richtet sich nach Text und Bildschirmskalierung;
  nur bei sehr langem Text erscheint ein Bildlauf. }
function TextDialog(const ACaption, AText, AKey: string; const AButtons: array of string): Integer;
var
  F: TForm;
  PB: TPanel;
  B: TButton;
  M: TMemo;
  Bmp: TBitmap;
  R: TRect;
  I, X, W, TextW, TextH, Mh, MaxH, Total: Integer;
  Bw: array of Integer;

  function Sc(N: Integer): Integer;
  begin
    Result := (N * Screen.PixelsPerInch + 48) div 96;
  end;

begin
  Result := 0;
  F := TForm.CreateNew(Application);
  try
    F.Caption := ACaption;
    F.Position := poScreenCenter;

    M := TMemo.Create(F);
    M.Parent := F;

    // Knopfbreiten nach Beschriftung
    Bmp := TBitmap.Create;
    try
      Bmp.SetSize(1, 1);
      Bmp.Canvas.Font.Assign(M.Font);
      SetLength(Bw, Length(AButtons));
      Total := 0;
      for I := 0 to High(AButtons) do
      begin
        Bw[I] := Bmp.Canvas.TextWidth(AButtons[I]) + Sc(72);
        if Bw[I] < Sc(130) then Bw[I] := Sc(130);
        Inc(Total, Bw[I] + Sc(10));
      end;
      W := Sc(640);
      if W < Total + Sc(20) then W := Total + Sc(20);
      // Texthoehe bei dieser Breite messen
      TextW := W - Sc(20) - Sc(34);          // Rand, Bildlaufleiste und Innenrand
      R := Rect(0, 0, TextW, 0);
      DrawText(Bmp.Canvas.Handle, PChar(AText), -1, R, DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
      TextH := R.Bottom - R.Top;
    finally
      Bmp.Free;
    end;
    Mh := TextH + Sc(28);
    MaxH := (Screen.WorkAreaRect.Bottom - Screen.WorkAreaRect.Top) * 75 div 100 - Sc(120);
    if Mh > MaxH then Mh := MaxH;
    if Mh < Sc(60) then Mh := Sc(60);

    PB := TPanel.Create(F);
    PB.Parent := F;
    PB.Align := alBottom;
    PB.Height := Sc(56);
    PB.BevelOuter := bvNone;
    PB.Caption := '';
    X := W - Total;
    for I := 0 to High(AButtons) do
    begin
      B := TButton.Create(F);
      B.Parent := PB;
      B.Caption := AButtons[I];
      B.SetBounds(X, Sc(10), Bw[I], Sc(34));
      B.ModalResult := 100 + I + 1;
      if I = 0 then B.Default := True;
      Inc(X, Bw[I] + Sc(10));
    end;

    M.Align := alClient;
    M.BorderSpacing.Around := Sc(10);
    M.ReadOnly := True;
    M.WordWrap := True;
    M.ScrollBars := ssAutoVertical;
    M.Text := AText;
    M.SelStart := 0;

    F.ClientWidth := W;
    F.ClientHeight := Mh + Sc(20) + Sc(56);

    I := F.ShowModal;
    if I > 100 then Result := I - 100;
  finally
    F.Free;
  end;
end;

procedure InfoText(const ACaption, AText: string);
begin
  TextDialog(ACaption, AText, 'Info', ['OK']);
end;

function AskUpdate(const ACaption, AText: string): Integer;
begin
  Result := TextDialog(ACaption, AText, 'UpdateFrage',
    ['Jetzt installieren', 'Später', 'Diese Version überspringen']);
  if Result = 0 then Result := 2;   // Fenster geschlossen = spaeter
end;

end.
