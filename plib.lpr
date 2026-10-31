program plib;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  PlibDpi,    // muss vor Interfaces/Forms stehen (DPI-bewusst, scharf auf 4K)
  Interfaces, // LCL-Widgetset
  Forms, MainUnit;

{$R *.res}

begin
  RequireDerivedFormResource := False;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
