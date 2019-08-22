{*******************************************************************************
*
*  TFileDrag Component - Adds support for dropping files from explorer onto a
*                        a Delphi form.
*
*  Copyright (c) 1996 - Erik C. Nielsen ( 72233.1314@compuserve.com )
*  All Rights Reserved
*
* **** Changes from V 1.0 ****
* 
* 1. Fixed several minor bugs, including not setting the enabled property 
*    properly in the constructor.  
*    
* 2. Removed the separate string lists for full name, file name, and extension.
*    Replaced with just one list with full name.  I had forgotten about the
*    Delphi functions ExtractFileExt and ExtractFileName which will get the
*    extension and name portions for you.
* 
*******************************************************************************}

unit filedrag;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ShellApi;

type
  TFileDrag = class(TComponent)
  private
    FNameWithPath: TStrings;
    FNumDropped: Integer;
    FEnabled: Boolean;
    FWndHandle: HWND;
    FDefProc: Pointer;
    FWndProcInstance: Pointer;
    FOnDrop: TNotifyEvent;
    FDropPt: TPoint;

    procedure DropFiles( hDropHandle: HDrop );
    procedure SetEnabled( Value: Boolean );
    procedure WndProc( var Msg: TMessage );
    procedure InitControl;
    procedure DestroyControl;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Files: TStrings read FNameWithPath;
    property FileCount: Integer read FNumDropped;
    property DropPoint: TPoint read FDropPt;
    property EnableDrop: Boolean read FEnabled write SetEnabled default True;
    property OnDrop: TNotifyEvent read FOnDrop write FOnDrop;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('System', [TFileDrag]);
end;

constructor TFileDrag.Create( AOwner: TComponent );
begin
   inherited Create( AOwner );
   FNumDropped := 0;
   FNameWithPath := TStringList.Create;
   FWndHandle := 0;

   FDropPt.X := 0;
   FDropPt.Y := 0;

   InitControl;
   SetEnabled( TRUE );
end;

destructor TFileDrag.Destroy;
begin
  DestroyControl;
  SetEnabled( FALSE );
  FNameWithPath.Free;
  inherited Destroy;
end;

procedure TFileDrag.InitControl;
var
  WinCtl: TWinControl;
begin
   if Owner is TWinControl then
    begin
      { Subclass the owner so this control can capture the WM_DROPFILES message }
      WinCtl := TWinControl( Owner );
      FWndHandle := WinCtl.Handle;
      FWndProcInstance := MakeObjectInstance( WndProc );
      FDefProc := Pointer( GetWindowLong( FWndHandle, GWL_WNDPROC ));
      SetWindowLong( FWndHandle, GWL_WNDPROC, Longint( FWndProcInstance ));
    end
   else
    FEnabled := False;
end;

procedure TFileDrag.DestroyControl;
begin
  if FWndHandle <> 0 then
   begin
     { Restore the original window procedure }
     SetWindowLong( FWndHandle, GWL_WNDPROC, Longint( FDefProc ));
     FreeObjectInstance(FWndProcInstance);
   end
end;

procedure TFileDrag.SetEnabled( Value: Boolean );
begin
  FEnabled := Value;
  { Call Win32 API to register the owner as being able to accept dropped files }
  DragAcceptFiles( FWndHandle, FEnabled );
end;

procedure TFileDrag.DropFiles( hDropHandle: HDrop );
var
  pszFileWithPath, pszFile, pszExt: PChar;
  iFile, iPos, iStrLen, iTempLen: Integer;
begin
  iStrLen := 128;
  pszFileWithPath := StrAlloc( iStrLen );
  iFile := 0;

  { Clear any existing strings from the string lists }
  FNameWithPath.Clear;

  { Retrieve the number of files being dropped }
  FNumDropped := DragQueryFile( hDropHandle, $FFFFFFFF, pszFile, iStrLen );

  {******************}
  { Added the following on August 26, 1997 }
  { Set the drop point }
  DragQueryPoint( hDropHandle, FDropPt );
  {******************}

  { Retrieve each file being dropped }
  while ( iFile < FNumDropped ) do
  begin
   { Get the length of this file name }
   iTempLen := DragQueryFile( hDropHandle, iFile, nil, 0 ) + 1;
   { If file length > current PChar, delete and allocate one large enough }
   if ( iTempLen > iStrLen ) then
     begin
       iStrLen := iTempLen;
       StrDispose( pszFileWithPath );
       pszFileWithPath := StrAlloc( iStrLen );
     end;
   { Get the fully qualified file name }
   DragQueryFile( hDropHandle, iFile, pszFileWithPath, iStrLen );
   FNameWithPath.Add( StrPas( pszFileWithPath ));
   Inc( iFile );
  end;

  StrDispose( pszFileWithPath );

  { This will result in the OnDrop method being called, if it is defined }
  if Assigned(FOnDrop) then
   begin
    FOnDrop(Self);
   end
end;

procedure TFileDrag.WndProc( var Msg: TMessage );
begin
   with Msg do
    begin
       { If message is drop files, process, otherwise call the original window procedure }
       if Msg = WM_DROPFILES then
           DropFiles( HDrop( wParam ))
       else
           Result := CallWindowProc( FDefProc, FWndHandle, Msg, WParam, LParam);
    end;
end;

end.
