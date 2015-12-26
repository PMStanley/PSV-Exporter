unit PSVClass;

interface
uses
classes, ComCtrls, sysUtils, Dialogs, Controls, strUtils;

type

TPSVFile = class
  private
  psvFile : TMemoryStream;
  fileList : Tlist;
  mainDirName : string;
  PS2File : boolean;
  function listFiles : boolean;
  procedure PS2Buttons(enabled : boolean);
  public
  procedure Clear;
  function loadFile(filename : string): boolean;
  function extractAFile(item : integer; destination : string): boolean;
  function extractAllFiles(destination : string): boolean;
  function getDirName : string;
  function extractPS1Save(destination: string): boolean;
  function cleanString (input : AnsiString): AnsiString;
  function CleanFileName(const InputString: AnsiString): AnsiString;
  constructor Create;
  Destructor Destroy;
end;

implementation

uses PSVFormat, main;

{ PSVFile }

procedure TPSVFile.Clear;
var
  x : integer;
  fileInfo : PTPS2FileInfo;
  ps1Info : PTPS1Header;
begin
  psvFile.Clear;
  if PS2File then begin
    for x := fileList.Count -1 downto 0 do begin
      fileInfo := fileList.Items[x];
      dispose(fileInfo);
      fileList.Delete(x);
    end;
  end else begin
    for x := fileList.Count -1 downto 0 do begin
      ps1Info := fileList.Items[x];
      dispose(ps1Info);
      fileList.Delete(x);
    end;
  end;
  fileList.Clear;
end;

constructor TPSVFile.Create;
begin
  psvFile := TMemoryStream.Create;
  fileList := Tlist.Create;
end;

destructor TPSVFile.Destroy;
begin
  Clear;
  psvFile.Free;
  fileList.Free;
end;

function  TPSVFile.extractAFile(item: integer; destination: string): boolean;
var
  FS : TMemoryStream;
  fileInfo : PTPS2FileInfo;
  dialogResult : integer;
begin
  FS := TMemoryStream.Create;
  fileInfo := fileList.Items[item];
  FS.SetSize(fileInfo^.filesize);
  PSVFile.Position := fileInfo^.positionInFile;
  //stream copying hates 0 size so skip if filesize := 0
  if fileInfo.filesize > 0  then begin
  FS.CopyFrom(PSVFile, FS.Size);
  end;
  if fileExists(destination) then begin
  dialogResult := MessageDlg('File already exists, overwrite?', mtConfirmation, [mbYes, mbNo], 0, mbYes);
      if (dialogResult = mrCancel) or (dialogResult = mrNo) then begin
        Result := False;
        FS.Free;
        Exit;
      end;
  end;

  FS.SaveToFile(destination);
  FS.Free;
  result := True;
end;

function TPSVFile.extractAllFiles(destination: string): boolean;
var
  FS : TMemoryStream;
  fileInfo : PTPS2FileInfo;
  x : integer;
  dialogResult : integer;
begin
  FS := TMemoryStream.Create;
  for x := 0 to fileList.Count - 1 do begin
    fileInfo := fileList.Items[x];
    FS.SetSize(fileInfo^.filesize);
    PSVFile.Position := fileInfo^.positionInFile;
    //stream copying hates 0 size so skip if filesize := 0
    if fileInfo.filesize > 0  then begin
      FS.CopyFrom(PSVFile, FS.Size);
    end;
    if not DirectoryExists(destination + '\' + CleanFileName(mainDirName)) then begin
      CreateDir(destination + '\' + CleanFileName(mainDirName));
    end;
    if fileExists(destination + '\' + CleanFileName(mainDirName) + '\' + CleanFileName(fileInfo^.filename)) then begin
      dialogResult := MessageDlg(destination + '\' + CleanFileName(mainDirName) + '\' + CleanFileName(fileInfo^.filename) + sLineBreak + 'already exists, overwrite?', mtConfirmation, [mbYes, mbNo], 0, mbYes);
      if (dialogResult = mrCancel) or (dialogResult = mrNo) then begin
        Result := False;
        FS.Free;
        Continue;
      end;
  end;
    FS.SaveToFile(destination + '\' + CleanFileName(mainDirName) + '\' + CleanFileName(fileInfo^.filename));
    FS.Clear;
  end;
  FS.Free;
  result := True;
end;

function TPSVFile.extractPS1Save(destination: string): boolean;
var
  FS : TMemoryStream;
  PS1Header : PTPS1Header;
  MCSHeader : PTPS1MCSHeader;
  xorByte, xorResult : byte;
  i : integer;
  dialogResult : integer;
begin
  PS1Header := fileList.Items[0];
  new(MCSHeader);
  MCSHeader^.magic := 81;
  MCSHeader^.dataSize := PS1Header^.saveSize;
  MCSHeader^.positionInCard := $FFFF;
  MCSHeader^.prodCode := PS1Header^.prodCode;
  FillChar(MCSHeader^.filler, SizeOf(MCSHeader^.filler), 0);
  FS := TMemoryStream.Create;
  if lowerCase(ExtractFileExt(destination)) = '.mcs' then  begin
    FS.Write(MCSHeader^, sizeof(MCSHeader^));
    FS.Position := 0;
    xorResult := 0;
    for I := 0 to 126 do begin
      FS.Read(xorByte, sizeof(xorByte));
      xorResult := xorResult xor xorByte;
    end;
    FS.Write(xorResult, sizeof(xorResult));
  end;
  PSVFile.Position := PS1Header^.startOfSaveData;
  FS.CopyFrom(PSVFile, PS1Header^.saveSize);
  if fileExists(destination) then begin
      dialogResult := MessageDlg(destination + sLineBreak + 'already exists, overwrite?', mtConfirmation, [mbYes, mbNo], 0, mbYes);
      if (dialogResult = mrCancel) or (dialogResult = mrNo) then begin
        Result := False;
        FS.Free;
        dispose(MCSHeader);
        exit;
      end;
  end;
  FS.SaveToFile(destination);
  FS.Free;
  dispose(MCSHeader);
  Result := True;

end;

function TPSVFile.getDirName: string;
begin
  result := mainDirName;
end;

function TPSVFile.listFiles : boolean;
var
  header : PTHeader;
  PS2Header : PTPS2Header;
  PS1Header : PTPS1Header;
  mainDirInfo : PTPS2MainDirInfo;
  fileInfo : PTPS2FileInfo;
  ps1FileInfo : PTPS1FileInfo;
  magicString : String;
  x : integer;
  NewItem : TListItem;
  created : string;
  modified : string;
begin
  psvFile.position := 0;
  new(header);
  psvFile.Read(header^, sizeof(header^));
  magicString := header^.magic[3] + header^.magic[2] + header^.magic[1];
  //exit if not PSV file
  if magicString <> 'PSV' then begin
    dispose(header);
    result := False;
    Exit;
  end;
  if header.saveType = 2 then begin
   //PS2 file
   PS2File := True;
   PS2Buttons(True);
   //get PS2 header
  new(PS2Header);
  psvFile.Read(PS2Header^, sizeof(PS2Header^));
  //get maindirinfo
  new(mainDirInfo);
  psvFile.Read(mainDirInfo^, sizeof(MainDirInfo^));
  mainDirName := mainDirInfo^.filename;
  //add files to the list
  for x := 0 to PS2header^.numberOfFiles -1 do begin
    fileInfo := new(PTPS2FileInfo);
    psvFile.Read(fileInfo^, sizeOf(fileInfo^));
    fileList.Add(fileInfo);
    newItem := nil;
    newItem := form1.ListView1.Items.Add;
    newItem.Caption := fileInfo^.filename;
    newItem.SubItems.Add(intToStr(fileInfo^.filesize));
    //Creation date
    created := '';
    if fileInfo^.CreateHours < 10 then begin
      created := created + '0';
    end;
    created := created + intToStr(fileInfo^.CreateHours) + ':';
    if fileInfo^.CreateMinutes < 10 then begin
      created := created + '0';
    end;
    created := created + intToStr(fileInfo^.CreateMinutes)
      {+ ':' + intToStr(fileInfo^.CreateSeconds)} + ' ' + intToStr(fileInfo^.CreateDays)
      + '/' + intToStr(fileInfo^.CreateMonths) + '/' + intToStr(fileInfo^.CreateYear);
    newItem.SubItems.Add(created);
    //modifed date
    modified := '';
    if fileInfo^.ModHours < 10 then begin
      modified := modified + '0';
    end;
    modified := modified + intToStr(fileInfo^.ModHours) + ':';
    if fileInfo^.ModMinutes < 10 then begin
      modified := modified + '0';
    end;
    modified := modified + intToStr(fileInfo^.ModMinutes)
      {+ ':' + intToStr(fileInfo^.ModSeconds)} + ' ' + intToStr(fileInfo^.ModDays)
      + '/' + intToStr(fileInfo^.ModMonths) + '/' + intToStr(fileInfo^.ModYear);
    newItem.SubItems.Add(modified);
  end;
  dispose(mainDirInfo);
  //showmessage(intToStr(header^.unknown6));
  dispose(header);
  dispose(PS2Header);
  result := True;
  end else begin
    //PS1 file
    PS2File := False;
    PS2Buttons(False);
    new(PS1Header);
    psvFile.Read(PS1Header^, sizeof(PS1Header^));
    //new(PS1FileInfo);
    //psvFile.Read(PS1FileInfo^, sizeof(PS1FileInfo^));
    newItem := nil;
    newItem := form1.ListView1.Items.Add;
    newItem.Caption := PS1Header^.prodCode;
    //newItem.Caption := WideStringtoString(PS1FileInfo.title, 1252);
    newItem.SubItems.Add(intToStr(PS1Header.saveSize div 8192) + ' block(s)');
    fileList.Add(PS1header);
    dispose(header);
    Result := True;
  end;
end;

function TPSVFile.loadFile(filename: string): boolean;
begin
  Clear;
  psvFile.LoadFromFile(fileName);
  if listFiles then begin
    result := True;
  end else begin
    result := False;
  end;
end;

procedure TPSVFile.PS2Buttons(enabled: boolean);
begin
  if enabled then begin
  //PS2 only
    Form1.btnSaveFile.Enabled := True;
    Form1.btnExtractAll.Enabled := True;
    Form1.btnSavePS1.Enabled := False;
    Form1.MainMenu1.Items[0].Items[1].Enabled := True;
    Form1.MainMenu1.Items[0].Items[2].Enabled := True;
    Form1.MainMenu1.Items[0].Items[3].Enabled := False;
    Form1.PopupMenu1.Items[0].Visible := True;
    Form1.PopupMenu1.Items[1].Visible := True;
    Form1.PopupMenu1.Items[2].Visible := False;
  end else begin
  //PS1 only
    Form1.btnSaveFile.Enabled := False;
    Form1.btnExtractAll.Enabled := False;
    Form1.btnSavePS1.Enabled := True;
    Form1.MainMenu1.Items[0].Items[1].Enabled := False;
    Form1.MainMenu1.Items[0].Items[2].Enabled := False;
    Form1.MainMenu1.Items[0].Items[3].Enabled := True;
    Form1.PopupMenu1.Items[0].Visible := False;
    Form1.PopupMenu1.Items[1].Visible := False;
    Form1.PopupMenu1.Items[2].Visible := True;
  end;
end;

function TPSVFile.cleanString (input : Ansistring): Ansistring;
begin
	//'*'(0x2a), '/'(0x2f), and '?'(0x3f)
	while AnsiPos('*', input) > 0 do begin
		AnsiReplaceStr(input,'*', ' ');
	end;
	while AnsiPos('/', input) > 0 do begin
		AnsiReplaceStr(input,'/', ' ');
	end;
	while AnsiPos('?', input) > 0 do begin
		AnsiReplaceStr(input,'?', ' ');
	end;
  while AnsiPos(':', input) > 0 do begin
		AnsiReplaceStr(input,':', ' ');
	end;
  while AnsiPos('\', input) > 0 do begin
		AnsiReplaceStr(input,'\', ' ');
	end;
  while AnsiPos('"', input) > 0 do begin
		AnsiReplaceStr(input,'"', ' ');
	end;
  while AnsiPos('<', input) > 0 do begin
		AnsiReplaceStr(input,'<', ' ');
	end;
  while AnsiPos('>', input) > 0 do begin
		AnsiReplaceStr(input,'>', ' ');
	end;
  while AnsiPos('|', input) > 0 do begin
		AnsiReplaceStr(input,'|', ' ');
	end;
	result := input;
end;

function TPSVFile.CleanFileName(const InputString: AnsiString): Ansistring;
var
  i: integer;
  ResultWithSpaces: Ansistring;
begin

  ResultWithSpaces := InputString;

  for i := 1 to Length(ResultWithSpaces) do
  begin
    // These chars are invalid in file names.
    case ResultWithSpaces[i] of
      '/', '\', ':', '*', '?', '"', '|':
        // Use a * to indicate a duplicate space so we can remove
        // them at the end.
        {$WARNINGS OFF} // W1047 Unsafe code 'String index to var param'
        if (i > 1) and
          ((ResultWithSpaces[i - 1] = ' ') or (ResultWithSpaces[i - 1] = '*')) then
          ResultWithSpaces[i] := '*'
        else
          ResultWithSpaces[i] := ' ';

        {$WARNINGS ON}
    end;
  end;

  // A * indicates duplicate spaces.  Remove them.
  result := ReplaceStr(ResultWithSpaces, '*', '');

  // Also trim any leading or trailing spaces
  result := Trim(Result);

  if result = '' then
  begin
    raise(Exception.Create('Resulting FileName was empty Input string was: '
      + InputString));
  end;
end;

end.
