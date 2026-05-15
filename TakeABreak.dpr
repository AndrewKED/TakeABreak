program TakeABreak;

{$R *.dres}

uses
  Forms,
  Main in 'Main.pas' {fMain},
  App_Ops in '..\..\DUnits12\App_Ops.pas',
  Font_Ops in '..\..\DUnits12\Font_Ops.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
