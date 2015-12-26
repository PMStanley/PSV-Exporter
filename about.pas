unit About;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ShellAPI;

  var
  saveCursor:TCursor;

type
  TAboutBox = class(TForm)
    Panel1: TPanel;
    ProgramIcon: TImage;
    ProductName: TLabel;
    Version: TLabel;
    Copyright: TLabel;
    lblWeb: TLabel;
    OKButton: TButton;
    lblEmail: TLabel;
    procedure lblWebMouseEnter(Sender: TObject);
    procedure lblEmailMouseEnter(Sender: TObject);
    procedure lblEmailMouseLeave(Sender: TObject);
    procedure lblWebMouseLeave(Sender: TObject);
    procedure lblWebClick(Sender: TObject);
    procedure lblEmailClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.dfm}

procedure TAboutBox.lblEmailClick(Sender: TObject);
var
  em_subject, em_mail : string;
begin
  em_subject := 'Email about PSV Exporter';
  em_mail := 'mailto:gothi@ps2savetools.com?subject=' + em_subject;
  //launch email program
  ShellExecute(Handle, 'open', PChar(em_mail), 0, 0, SW_SHOWNORMAL);
end;

procedure TAboutBox.lblEmailMouseEnter(Sender: TObject);
begin
  saveCursor := Screen.Cursor;
  screen.Cursor := crHandPoint;
end;

procedure TAboutBox.lblEmailMouseLeave(Sender: TObject);
begin
  screen.Cursor := saveCursor;
end;

procedure TAboutBox.lblWebClick(Sender: TObject);
begin
  //launch web browser
  ShellExecute(Handle, 'open', PChar('http://www.ps2savetools.com'), 0, 0, SW_SHOWNORMAL);
end;

procedure TAboutBox.lblWebMouseEnter(Sender: TObject);
begin
  saveCursor := Screen.Cursor;
  screen.Cursor := crHandPoint;
end;

procedure TAboutBox.lblWebMouseLeave(Sender: TObject);
begin
  screen.Cursor := saveCursor;
end;


end.
 
