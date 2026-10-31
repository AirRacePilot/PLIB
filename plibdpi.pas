unit PlibDpi;

{ Schaltet PLIB auf "DPI-bewusst": Windows streckt das Fenster dann nicht mehr als Bild
  (unscharf auf 4K-Monitoren mit 150 % / 200 % Skalierung), sondern PLIB zeichnet selbst scharf.

  Muss als ERSTE Unit in der uses-Liste von plib.lpr stehen (vor Interfaces/Forms).
  Abschalten: plib.ini
    [Ansicht]
    Hochaufloesend=nein }

{$mode objfpc}{$H+}

interface

implementation

{$IFDEF WINDOWS}
uses
  Windows, SysUtils, IniFiles;

type
  TSetDpiAware = function: BOOL; stdcall;

procedure Enable;
var
  Ini: TIniFile;
  On_: Boolean;
  H: THandle;
  F: TSetDpiAware;
begin
  On_ := True;
  try
    Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'plib.ini');
    try
      On_ := LowerCase(Trim(Ini.ReadString('Ansicht', 'Hochaufloesend', 'ja'))) <> 'nein';
    finally
      Ini.Free;
    end;
  except
  end;
  if not On_ then Exit;
  H := LoadLibrary('user32.dll');
  if H = 0 then Exit;
  F := TSetDpiAware(GetProcAddress(H, 'SetProcessDPIAware'));
  if Assigned(F) then F();
end;

initialization
  Enable;
{$ENDIF}

end.
