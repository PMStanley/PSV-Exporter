program PSVExporter;

uses
  Forms,
  main in 'main.pas' {Form1},
  PSVFormat in 'PSVFormat.pas',
  PSVClass in 'PSVClass.pas',
  about in 'about.pas' {AboutBox},
  options in 'options.pas' {OptionsForm},
  BrowseForFolderU in 'BrowseForFolderU.pas',
  ElAES in 'ElAES.pas',
  myLZAri in 'myLZAri.pas',
  maxFormat in 'maxFormat.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'PSV Exporter';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TOptionsForm, OptionsForm);
  Application.Run;
end.
