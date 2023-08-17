program TakeABreak;

{$R *.dres}

uses
  Forms,
  Main in 'Main.pas' {Form1},
  App_Ops in 'E:\DUnits10\App_Ops.pas',
  Font_Ops in 'E:\DUnits10\Font_Ops.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
