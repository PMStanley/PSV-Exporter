unit PSVClass;

//////////////////////////////////////////////////////////
//
// Copyright Peter Stanley
// https://github.com/PMStanley
//
//////////////////////////////////////////////////////////

interface
uses
classes, ComCtrls, sysUtils, Dialogs, Controls, strUtils, ElAES, Windows, Hash, PSVFormat, maxFormat;

type

TPS2File = record
  fileMeta : TPS2FileInfo;
  theFile : TMemoryStream;
end;
PTPS2File = ^TPS2File;


TPS2Save = record
  PSVHeader : THeader;
  PS2Header : TPS2Header;
  PS2DirInfo : TPS2MainDirInfo;
  files : TList;  //list of TPS2File
  iconSys : TIconSys;
  usesOneIcon : boolean;
end;
PTPS2Save = ^TPS2Save;

TPS1Save = record
  PSVHeader : THeader;
  PS1header : TPS1Header;
  PS1File : TMemoryStream;
end;
PTPS1Save = ^TPS1Save;


byteArray16 = array[0..15] of Byte;
byteArray20 = array[0..19] of Byte;
byteArray32 = array[0..31] of Byte;
byteArray64 = array[0..63] of Byte;

TPSVFile = class
  private
  PS2Save : TPS2Save;
  PS1Save : TPS1Save;
  psvFile : TMemoryStream;
  mainDirName : string;
  PS2File : boolean;
  function listFiles : boolean;
  procedure PS2Buttons(enabled : boolean);
  public
  procedure Clear;
  function getPS1ProdCode: string;
  function loadFile(filename : string): boolean;
  function extractAFile(item : integer; destination : string): boolean;
  function extractAllFiles(destination : string): boolean;
  function getDirName : string;
  function extractPS1Save(destination: string): boolean;
  function cleanString (input : AnsiString): AnsiString;
  function CleanFileName(const InputString: AnsiString): AnsiString;
  procedure stringToArray16(text: string; var bArray: byteArray16);
  procedure stringToArray20(text: string; var bArray: byteArray20);
  procedure stringToArray64(text: string; var bArray: byteArray64);
  function byteArray16ToString(bArray : byteArray16): string;
  function byteArray20ToString(bArray : byteArray20): string;
  function byteArray32ToString(bArray : byteArray32): string;
  function byteArray64ToString(bArray: byteArray64): string;
  function byteArray16ToTAESKey128(bArray: byteArray16): TAESKey128;
  Function binToHex(Const bin: Array Of Byte): String;
  function TAESKey128ToString(bArray: TAESKey128): string;
  procedure updateSignature(fileName: string);
  function xorArray(bArray1 : byteArray16; bArray2: byteArray16): byteArray16;
  function xorWithByte(buf: byteArray64; aByte: byte; length: Integer): byteArray64;
  function StringToHex(S: String): string;
  function makePSVFileName(mainDirName: string): String;
  function savePSVFile(location: string): boolean;
  function saveUsesOneIcon(iconSysFile: TIconSys): boolean;
  function ImportMaxFile(fileName: string): boolean;
  function ImportPS1MCSFile(fileName: string): boolean;
  function StringToByte(aByte  : string) : byte;
  function StringToWord(aWord  : string) : word;
  function exportARMaxSave(fileName : String): boolean;
  constructor Create;
  Destructor Destroy;
end;

implementation

uses main;

{ PSVFile }

procedure TPSVFile.Clear;
var
  x : integer;
  fileInfo : PTPS2File;
  ps1Info : PTPS1Header;
begin
  PSVFile.Clear;
  if PS2File then begin
    for x := PS2Save.files.Count -1 downto 0 do begin
      fileInfo := PS2Save.files.Items[x];
      fileInfo^.theFile.Clear;
      fileInfo^.theFile.Free;
      dispose(fileInfo);
      PS2Save.files.Delete(x);
    end;
  end else begin
    PS1Save.PS1File.Clear;
  end;
end;

constructor TPSVFile.Create;
begin
  psvFile := TMemoryStream.Create;
  PS2Save.files := Tlist.Create;
  PS1Save.PS1File := TMemoryStream.Create;
end;

destructor TPSVFile.Destroy;
begin
  Clear;
  psvFile.Free;
  PS2Save.files.Free;
  PS1Save.PS1File.Free;
end;

function  TPSVFile.extractAFile(item: integer; destination: string): boolean;
var
  aPS2File : PTPS2File;
  dialogResult : integer;
begin
  aPS2File := PS2Save.files.Items[item];
  if fileExists(destination) then begin
  dialogResult := MessageDlg('File already exists, overwrite?', mtConfirmation, [mbYes, mbNo], 0, mbYes);
      if (dialogResult = mrCancel) or (dialogResult = mrNo) then begin
        Result := False;
        Exit;
      end;
  end;

  aPS2File.theFile.SaveToFile(destination);
  result := True;
end;

function TPSVFile.extractAllFiles(destination: string): boolean;
var
  aPS2File : PTPS2File;
  x : integer;
  dialogResult : integer;
  errorMessage: string;
begin
  for x := 0 to PS2Save.files.Count - 1 do begin
    aPS2File := PS2Save.files.Items[x];
    aPS2File.theFile.Position := 0;

    if fileExists(destination + '\' + CleanFileName(mainDirName)) then  begin
      errorMessage :=  'Unable to create directory because a file with the same name exists.';
      errorMessage := errorMessage + sLineBreak + sLineBreak;
      errorMessage := errorMessage + 'Please rename the file called "' + CleanFileName(mainDirName) + '" and try again.';
      showMessage(errorMessage);
      exit;
    end;


    if not DirectoryExists(destination + '\' + CleanFileName(mainDirName)) then begin
      //showmessage('creating folder ' + destination + '\' + CleanFileName(mainDirName));
      CreateDir(destination + '\' + CleanFileName(mainDirName));
    end;
    if fileExists(destination + '\' + CleanFileName(mainDirName) + '\' + CleanFileName(aPS2File.fileMeta.filename)) then begin
      dialogResult := MessageDlg(destination + '\' + CleanFileName(mainDirName) + '\' + CleanFileName(aPS2File.fileMeta.filename) + sLineBreak + 'already exists, overwrite?', mtConfirmation, [mbYes, mbNo], 0, mbYes);
      if (dialogResult = mrCancel) or (dialogResult = mrNo) then begin
        Result := False;
        Continue;
      end;
  end;
    aPS2File.theFile.SaveToFile(destination + '\' + CleanFileName(mainDirName) + '\' + CleanFileName(aPS2File.fileMeta.filename));
  end;
  showMessage('Files extracted to ' + sLineBreak + destination + '\' + CleanFileName(mainDirName));
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
  new(MCSHeader);
  MCSHeader^.magic := 81;
  MCSHeader^.dataSize := PS1Save.PS1header.saveSize; 
  MCSHeader^.positionInCard := $FFFF;
  for i := 0 to 19 do begin
    MCSHeader^.prodCode[i] := PS1Save.PS1header.prodCode[i];
  end;

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

  PS1Save.PS1File.Position := 0;
  FS.CopyFrom(PS1Save.PS1File, PS1Save.PS1File.Size);
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
  magicString : String;
  x : integer;
  NewItem : TListItem;
  created : string;
  modified : string;
  aPS2File : PTPS2File;
  currentPos : int64;
  i : integer;
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
   psvFile.position := 0;
   psvFile.Read(PS2Save.PSVHeader, sizeof(PS2Save.PSVHeader));

   //PS2 file
   PS2File := True;
   PS2Buttons(True);
   psvFile.Read(PS2Save.PS2Header, sizeOf(PS2Save.PS2Header));
   psvFile.Read(PS2Save.PS2DirInfo, sizeof(PS2Save.PS2DirInfo));
   mainDirName :=  PS2Save.PS2DirInfo.filename;

  //add files to the list
  for x := 0 to PS2Save.PS2Header.numberOfFiles -1 do begin
    new(aPS2File);
    psvFile.Read(aPS2File^.fileMeta, sizeOf(aPS2File^.fileMeta));
    currentPos := psvFile.Position;
    psvFile.Position := aPS2File^.fileMeta.positionInFile;
    aPS2File^.theFile := TMemoryStream.Create;
    aPS2File^.theFile.CopyFrom(psvFile, aPS2File^.fileMeta.filesize);
    if aPS2File^.fileMeta.filename = 'icon.sys' then begin
      aPS2File^.theFile.Position := 0;
      aPS2File^.theFile.Read(PS2Save.iconSys, sizeOf(PS2Save.iconSys));
    end;
    psvFile.Position := currentPOS;
    PS2Save.files.Add(aPS2File);

    newItem := nil;
    newItem := form1.ListView1.Items.Add;
    newItem.Caption := aPS2File^.fileMeta.filename;
    newItem.SubItems.Add(intToStr(aPS2File^.fileMeta.filesize));
    //Creation date
    created := '';
    if aPS2File^.fileMeta.CreateHour < 10 then begin
      created := created + '0';
    end;
    created := created + intToStr(aPS2File^.fileMeta.CreateHour) + ':';
    if aPS2File^.fileMeta.CreateMinute < 10 then begin
      created := created + '0';
    end;
    created := created + intToStr(aPS2File^.fileMeta.CreateMinute)
      {+ ':' + intToStr(fileInfo^.CreateSeconds)} + ' ' + intToStr(aPS2File^.fileMeta.CreateDay)
      + '/' + intToStr(aPS2File^.fileMeta.CreateMonth) + '/' + intToStr(aPS2File^.fileMeta.CreateYear);
    newItem.SubItems.Add(created);
    //modifed date
    modified := '';
    if aPS2File^.fileMeta.ModHour < 10 then begin
      modified := modified + '0';
    end;
    modified := modified + intToStr(aPS2File^.fileMeta.ModHour) + ':';
    if aPS2File^.fileMeta.ModMinute < 10 then begin
      modified := modified + '0';
    end;
    modified := modified + intToStr(aPS2File^.fileMeta.ModMinute)
      {+ ':' + intToStr(fileInfo^.ModSeconds)} + ' ' + intToStr(aPS2File^.fileMeta.ModDay)
      + '/' + intToStr(aPS2File^.fileMeta.ModMonth) + '/' + intToStr(aPS2File^.fileMeta.ModYear);
    newItem.SubItems.Add(modified);
  end;

  dispose(header);

  result := True;
  end else begin
    //PS1 file
    PS2File := False;
    PS2Buttons(False);
    psvFile.Position := 0;
    psvFile.Read(PS1Save.PSVHeader, sizeOf(PS1Save.PSVheader));
    psvFile.Read(PS1Save.PS1header, sizeOf(PS1Save.PS1header));

    newItem := nil;
    newItem := form1.ListView1.Items.Add;
    newItem.Caption := PS1Save.PS1header.prodCode;
    mainDirName := PS1Save.PS1header.prodCode;
    newItem.SubItems.Add(intToStr(PS1Save.PS1header.saveSize div 8192) + ' block(s)');
    psvfile.Position := PS1Save.PS1header.startOfSaveData;
    PS1Save.PS1File.Clear;
    PS1Save.PS1File.CopyFrom(psvFile, PS1Save.PS1header.saveSize);
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
    Form1.btSaveAsPSV.Enabled := True;
    Form1.btnSavePS1.Enabled := False;
    Form1.btnExportAsMax.Enabled := True;
    Form1.MainMenu1.Items[0].Items[4].Enabled := True;
    Form1.MainMenu1.Items[0].Items[5].Enabled := True;
    Form1.MainMenu1.Items[0].Items[6].Enabled := True;
    Form1.MainMenu1.Items[0].Items[8].Enabled := False;
    Form1.MainMenu1.Items[0].Items[10].Enabled := True;
    Form1.PopupMenu1.Items[0].Visible := True;
    Form1.PopupMenu1.Items[1].Visible := True;
    Form1.PopupMenu1.Items[2].Visible := False;
  end else begin
  //PS1 only
    Form1.btnSaveFile.Enabled := False;
    Form1.btnExtractAll.Enabled := False;
    Form1.btnSavePS1.Enabled := True;
    Form1.btSaveAsPSV.Enabled := True;
    Form1.btnExportAsMax.Enabled := False;
    Form1.MainMenu1.Items[0].Items[4].Enabled := False;
    Form1.MainMenu1.Items[0].Items[5].Enabled := False;
    Form1.MainMenu1.Items[0].Items[6].Enabled := False;
    Form1.MainMenu1.Items[0].Items[8].Enabled := True;
    Form1.MainMenu1.Items[0].Items[10].Enabled := True;
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

procedure TPSVFile.stringToArray16(text: string; var bArray: byteArray16);
var
  x, y :integer;
begin
  y := 1;
  for x := 0 to 15 do begin
    bArray[x] := StrToInt('0x' + midStr(text,y, 2));
    y := y + 2;
  end;
end;

procedure TPSVFile.stringToArray20(text: string; var bArray: byteArray20);
var
  x, y :integer;
begin
  y := 1;
  for x := 0 to 19 do begin
    bArray[x] := StrToInt('0x' + midStr(text,y, 2));
    y := y + 2;
  end;
end;

procedure TPSVFile.stringToArray64(text: string; var bArray: byteArray64);
var
  x, y :integer;
begin
  y := 1;
  for x := 0 to 63 do begin
    bArray[x] := StrToInt('0x' + midStr(text,y, 2));
    y := y + 2;
  end;
end;

function TPSVFile.StringToByte(aByte  : string) : byte;
begin
  Result := strToInt(aByte);
end;

function TPSVFile.StringToWord(aWord  : string) : word;
begin
  Result := strToInt(aWord);
end;

procedure TPSVFile.updateSignature(fileName: string);
var
  ivRaw : string;
  key0Raw : string;
  key1Raw : string;
  iv : byteArray16;
  key0 : byteArray16;
  key1 : byteArray16;
  salt : byteArray64;
  work_buf : byteArray20;
  work_buf2 : byteArray16;
  salt_seed : byteArray20; //saltSeed on PS1 uses only 16 bytes, PS2 uses 20
  psvType : Byte;
  dest : TMemoryStream;
  source : TMemoryStream;
  saltSeedPS1 :  byteArray16;
  saltSeedPS2 :  byteArray20;
  clearSalt : byteArray16;
  encryptedSalt : byteArray16;
  key1AES : TAESKey128;
  x : integer;
  ps1Salt : byteArray32;
  salt32 : byteArray32;
  xoredSalt : byteArray16;
  xoredEncryptedSalt : byteArray16;
  salt20 : byteArray20;
  salt64 : byteArray64;
  byteXoredSalt64 : byteArray64;
  newXoredSalt64 : byteArray64;
  tempMem : TMemoryStream;
  filler :    byteArray20;
  buf : array of byte;
  totalsize : integer;
  HashSHA1: THashSHA1;
  HashSHA12: THashSHA1;
  laidPaid : byteArray16;
  xoredKey0 : byteArray16;
  salt64Stream : TMemoryStream;
  xoredKeyAES : TAESKey128;
  aDest : TmemoryStream;
  ivBuffer : TAESBuffer;
  newSaltSeed : byteArray20;
  aPS2File : PTPS2File;
  baseAddress : integer;
  aFileName, iconName : String;
  copyIconName, deleteIconName : String;
begin
  stringToArray16('B30FFEEDB7DC5EB7133DA60D1B6B2CDC', iv);
  stringToArray16('FA72CEEF59B4D2989F111913287F51C7', key0);
  stringToArray16('AB5ABC9FC1F49DE6A051DBAEFA518859', key1);
  stringToArray16('107000000200000110700003ff000001', laidPaid);
  stringToArray20('7777772e70733273617665746f6f6c732e636f6d', newSaltSeed);


  FillChar(salt, 64*SizeOf(Byte), 0);
  FillChar(work_buf, 20*SizeOf(Byte), $FF);
  FillChar(salt64, 64*SizeOf(Byte), 0);
  FillChar(filler, 20*SizeOf(Byte), 0);

  key1AES := byteArray16ToTAESKey128(key1);

  if not PS2File then begin
   //PS1
    for x := 0 to 15 do begin
      PS1Save.PSVHeader.salt[x] := newSaltSeed[x];
    end;

    dest := TMemoryStream.Create();
    source := TMemoryStream.Create();
    source.Write(PS1Save.PSVHeader.salt, 16);
    source.Position := 0;
    DecryptAESStreamECB(source, source.size, key1AES, dest);
    dest.position := 0;
    x := dest.Read(clearSalt, dest.size);
    source.position := 0;
    dest.clear;
    EncryptAESStreamECB(source, source.size, key1AES, dest);
    dest.position := 0;
    x := dest.Read(encryptedSalt, dest.size);

    for x := 0 to 15 do begin
      ps1Salt[x] := clearSalt[x];
    end;
    for x := 0 to 15 do begin
      ps1Salt[x + 16] :=  encryptedSalt[x];
    end;

    dest.Free;
    source.Free;

   xoredSalt := xorArray(clearSalt, iv);

    for x := 0 to 3 do begin
      work_buf[x] := PS1Save.PSVHeader.salt[x + 16];
    end;


    for x := 0 to 15 do begin
      work_buf2[x] := work_buf[x];
    end;
    xoredEncryptedSalt := xorArray(encryptedSalt, work_buf2);


    for x := 0 to 15 do begin
      salt32[x] := xoredSalt[x];
    end;
    for x := 0 to 15 do begin
      salt32[x + 16] :=  xoredEncryptedSalt[x];
    end;

     for x := 0 to 19 do begin
      salt20[x] := salt32[x];
    end;

    for x := 0 to 19 do begin
     salt64[x] := salt20[x]
    end;

  end else begin
    //PS2

    for x := 0 to 19 do begin
    PS2Save.PSVHeader.salt[x] := newSaltSeed[x];
    end;


    xoredKey0 := xorArray(key0, laidPaid);

    salt64Stream := TmemoryStream.Create;


    for x := 0 to sizeOf(saltSeedPS2) - 1 do begin
      salt[x] :=  newSaltSeed[x];

    end;

    salt64Stream.Write(salt, sizeOf(salt));

    xoredKeyAES :=  byteArray16ToTAESKey128(xoredKey0);

    aDest := TMemoryStream.Create;

    for x := 0 to 15 do begin
      ivBuffer[x] := iv[x];
    end;

    salt64Stream.position := 0;
    DecryptAESStreamCBC(salt64Stream, salt64Stream.size, xoredKeyAES, ivBuffer, aDest);

    aDest.Position := 0;
    aDest.read(salt64, aDest.Size);
    aDest.Free;

    for x := 20 to 63 do begin
     salt64[x] := $0;
    end;

    salt64Stream.Free;
  end;

  byteXoredSalt64 := xorWithByte(salt64, $36, 64);

  HashSHA1 := THashSHA1.Create;
  HashSHA1.Update(byteXoredSalt64, sizeof(byteXoredSalt64));


  tempMem := TMemoryStream.Create;

  if PS2File then begin
    tempMem.Write(PS2Save.PSVHeader, sizeOf(PS2Save.PSVHeader));
    tempMem.Write(PS2Save.PS2Header, sizeof(PS2Save.PS2Header));
    tempMem.Write(PS2Save.PS2DirInfo, sizeOf(PS2Save.PS2DirInfo));
      baseAddress := tempMem.Position;
      baseAddress := baseAddress + (sizeOf(TPS2FileInfo) * PS2Save.files.Count);
      for x := 0 to PS2Save.files.Count -1 do begin

        aPS2File := PS2Save.files.Items[x];
        aPS2File.fileMeta.positionInFile := baseAddress;
        tempMem.Write(aPS2File.fileMeta, sizeOf(aPS2File.fileMeta));

        aFileName :=  aPS2File.fileMeta.filename;
        iconName := PS2Save.iconSys.IconName;
        copyIconName := PS2Save.iconSys.copyIconName;
        deleteIconName := PS2Save.iconSys.deleteIconName;

        if aFileName = 'icon.sys' then begin
          PS2Save.PS2Header.sysPos  := baseAddress;
          PS2Save.PS2Header.sysSize := aPS2File.fileMeta.filesize;
        end;
        if aFileName = iconName then begin
          PS2Save.PS2Header.icon1Pos := baseAddress;
          PS2Save.PS2Header.icon1Size := aPS2File.fileMeta.filesize;
        end;
        if aFileName = copyIconName then begin
          PS2Save.PS2Header.icon2Pos := baseAddress;
          PS2Save.PS2Header.icon2Size := aPS2File.fileMeta.filesize;
        end;
        if aFileName = deleteIconName then begin
          PS2Save.PS2Header.icon3Pos := baseAddress;
          PS2Save.PS2Header.icon3Size := aPS2File.fileMeta.filesize;
        end;

        baseAddress := baseAddress + aPS2File.fileMeta.filesize;
      end;
      for x := 0 to PS2Save.files.Count -1 do begin
        aPS2File := PS2Save.files.Items[x];
        aPS2File.theFile.Position := 0;
        tempMem.CopyFrom(aPS2File.theFile, aPS2File.theFile.Size);
      end;

      tempMem.Position := 64;
      tempMem.Write(PS2Save.PS2Header, sizeof(PS2Save.PS2Header));
      tempMem.Position := 0;
  end else begin
    tempMem.Write(PS1Save.PSVHeader, sizeOf(PS1Save.PSVHeader));
    PS1Save.PS1header.startOfSaveData := tempMem.Position + sizeOf(PS1Save.PS1header);
    tempMem.Write(PS1Save.PS1header, sizeOf(PS1Save.PS1header));
    PS1Save.PS1File.Position := 0;
    tempMem.CopyFrom(PS1Save.PS1File, PS1Save.PS1File.Size);
    tempMem.Position := 0;
  end;

  tempMem.Position := 28;
  x := tempMem.write(filler, sizeOf(filler));
  tempMem.Position := 0;
  setLength(buf, tempMem.Size);
  tempMem.Read(Pointer(buf)^, length(buf));;
  HashSHA1.Update(Pointer(buf)^, length(buf));
  newXoredSalt64 := xorWithByte(byteXoredSalt64, $6A, 64);

  HashSHA12 := THashSHA1.Create;
  HashSHA12.Update(newXoredSalt64, sizeof(newXoredSalt64));
  HashSHA12.Update(HashSHA1.HashAsBytes, Length(HashSHA1.HashAsBytes));

  tempMem.Position := 28;
  x := tempMem.Write(HashSHA12.HashAsBytes, length(HashSHA12.HashAsBytes));

  tempMem.Position := 0;
  tempMem.SaveToFile(fileName);
  tempMem.Free;
  HashSHA1.Reset;
  HashSHA12.Reset;
  showmessage('Saved as' + sLineBreak + fileName);
end;



Function TPSVFile.binToHex(Const bin: Array Of Byte): String;
Const
  HexSymbols = '0123456789ABCDEF';
Var
  I: Integer;
Begin
  SetLength(Result, 2 * Length(bin));
  For I := 0 To Length(bin) - 1 Do
  Begin
    Result[1 + 2 * I + 0] := HexSymbols[1 + bin[I] Shr 4];
    Result[1 + 2 * I + 1] := HexSymbols[1 + bin[I] And $0F];
  End;
End;

function TPSVFile.byteArray16ToString(bArray: byteArray16): string;
var
  x : integer;
  temp: string;
begin
  for x := 0 to 15 do begin
    temp := temp+uppercase(inttoHex(bArray[x], 2));
  end;
  result := temp;
end;

function TPSVFile.TAESKey128ToString(bArray: TAESKey128): string;
var
  x : integer;
  temp: string;
begin
  for x := 0 to 15 do begin
    temp := temp+uppercase(inttoHex(bArray[x], 2));
  end;
  result := temp;
end;

function TPSVFile.byteArray20ToString(bArray: byteArray20): string;
var
  x : integer;
  temp: string;
begin
  for x := 0 to 19 do begin
    temp := temp+uppercase(inttoHex(bArray[x], 2));
  end;
  result := temp;
end;

function TPSVFile.byteArray32ToString(bArray: byteArray32): string;
var
  x : integer;
  temp: string;
begin
  for x := 0 to 31 do begin
    temp := temp+uppercase(inttoHex(bArray[x], 2));
  end;
  result := temp;
end;

function TPSVFile.byteArray64ToString(bArray: byteArray64): string;
var
  x : integer;
  temp: string;
begin
  for x := 0 to 63 do begin
    temp := temp+uppercase(inttoHex(bArray[x], 2));
  end;
  result := temp;
end;

function TPSVFile.byteArray16ToTAESKey128(bArray: byteArray16): TAESKey128;
var
  x : integer;
  temp : TAESKey128;
begin
  for x := 0 to 15 do begin
    temp[x] := bArray[x]
  end;
  result := temp;
end;

function TPSVFile.xorArray(bArray1 : byteArray16; bArray2: byteArray16): byteArray16;
var
  i : integer;
  theResult: byteArray16;
begin
    for i := 0 to 16 do begin
        theResult[i] := bArray1[i] xor bArray2[i];
    end;
    result := theResult
end;

function TPSVFile.xorWithByte(buf: byteArray64; aByte: byte; length: Integer): byteArray64;
var
  i : integer;
  theResult : byteArray64;
begin
   for i := 0 to length do begin
     theResult[i] := buf[i] xor aByte;
   end;
   result := theResult;

end;

function TPSVFile.StringToHex(S: String): string;
var I: Integer;
begin
  Result:= '';
  for I := 1 to length (S) do
    Result:= Result+IntToHex(ord(S[i]),2);
end;

function TPSVFile.makePSVFileName(mainDirName: string): String;
var
  dirName : string;
  descriptionText : string;
begin
  dirName := copy(mainDirName, 1, 12);
  descriptionText := copy(mainDirName, 13, length(mainDirName) - 12);
  descriptionText := StringToHex(descriptionText);

  result := dirName + descriptionText;

end;

function TPSVFile.savePSVFile(location: string): boolean;
var
  psvFileName : string;
  dialogResult : integer;
begin
  if PS2File then  begin
    psvFileName := makePSVFileName(PS2Save.PS2DirInfo.filename) + '.PSV';
  end else begin
    psvFileName := makePSVFileName(PS1Save.PS1header.prodCode) + '.PSV';
  end;

  if not DirectoryExists(location) then begin
      CreateDir(location);
  end;

  if fileExists(location + '\' + psvFileName) then begin
    dialogResult := MessageDlg(location + '\' + psvFileName + sLineBreak + 'already exists, overwrite?', mtConfirmation, [mbYes, mbNo], 0, mbYes);
    if (dialogResult = mrCancel) or (dialogResult = mrNo) then begin
      Result := False;
      Exit;
    end;
  end;
    updateSignature(location + '\' + psvFileName);
    Result := true;
end;

function TPSVFile.getPS1ProdCode: string;
var
  prodCode : String;
begin
  prodCode := PS1Save.PS1header.prodCode;
  result  := prodCode;
end;

function TPSVFile.saveUsesOneIcon(iconSysFile: TIconSys): boolean;
var
  standardIconName : String;
  copyIconName : String;
  deleteIconName : String;
begin
  standardIconName := iconSysFile.IconName;
  copyIconName := iconSysFile.copyIconName;
  deleteIconName := iconSysFile.deleteIconName;

  if (standardIconName = copyIconName) and (copyIconName = deleteIconName) then begin
    Result := True;
  end else begin
    Result := False;
  end;

end;

function TPSVFile.ImportMaxFile(fileName: string): boolean;
var
  maxFile : TMaxSave;
  x, i : integer;
  newSaltSeed : byteArray20;
  fileDate : Integer;
  modifiedDateTime : TDateTime;
  temp : string;
  aPS2File : PTPS2File;
  NewItem : TListItem;
  created : string;
  modified : string;
  tempName : nameArray;
  fileSizes : integer;
begin
  Clear;
  PS2File := True;

  fileSizes := 0;

  stringToArray20('7777772e70733273617665746f6f6c732e636f6d', newSaltSeed);
  maxFile := TMaxSave.Create;
  maxFile.loadSave(fileName);
  //PSV Header
  PS2Save.PSVHeader.magic[0]  := AnsiChar($0);
  PS2Save.PSVHeader.magic[1]  := AnsiChar($56);
  PS2Save.PSVHeader.magic[2]  := AnsiChar($53);
  PS2Save.PSVHeader.magic[3]  := AnsiChar($50);
  PS2Save.PSVHeader.padding1 := 0;
  for x := 0 to 19 do begin
    PS2Save.PSVHeader.salt[x] := newSaltSeed[x];
  end;

  FillChar(PS2Save.PSVHeader.signature, 20*SizeOf(Byte), 0);
  PS2Save.PSVHeader.padding2 := 0;
  PS2Save.PSVHeader.padding3 := 0;
  PS2Save.PSVHeader.headerSize := $2C;
  PS2Save.PSVHeader.saveType := 2;

  //PS2 Header
  PS2Save.PS2Header.displaySize := 0;
  PS2Save.PS2Header.sysPos := 0;
  PS2Save.PS2Header.sysSize := 964;
  PS2Save.PS2Header.icon1Pos := 0;
  PS2Save.PS2Header.icon1Size := 0;
  PS2Save.PS2Header.icon2Pos := 0;
  PS2Save.PS2Header.icon2Size := 0;
  PS2Save.PS2Header.icon3Pos := 0;
  PS2Save.PS2Header.icon3Size := 0;
  PS2Save.PS2Header.numberOfFiles := maxFile.numFiles;

  fileDate :=  fileAge(fileName);

  //PS2 Main Dir
  PS2Save.PS2DirInfo.CreateReserved := 0;
  modifiedDateTime := FileDateToDateTime(fileDate);
  DateTimeToString(temp, 'ss', modifiedDateTime);
  PS2Save.PS2DirInfo.CreateSecond := StringToByte(temp);
  DateTimeToString(temp, 'nn', modifiedDateTime);
  PS2Save.PS2DirInfo.CreateMinute := StringToByte(temp);
  DateTimeToString(temp, 'hh', modifiedDateTime);
  PS2Save.PS2DirInfo.CreateHour := StringToByte(temp);
  DateTimeToString(temp, 'dd', modifiedDateTime);
  PS2Save.PS2DirInfo.CreateDay := StringToByte(temp);
  DateTimeToString(temp, 'mm', modifiedDateTime);
  PS2Save.PS2DirInfo.CreateMonth := StringToByte(temp);
  DateTimeToString(temp, 'yyyy', modifiedDateTime);
  PS2Save.PS2DirInfo.CreateYear := StringToWord(temp);

  PS2Save.PS2DirInfo.ModReserved := PS2Save.PS2DirInfo.CreateReserved;
  PS2Save.PS2DirInfo.ModSecond := PS2Save.PS2DirInfo.CreateSecond;
  PS2Save.PS2DirInfo.ModMinute := PS2Save.PS2DirInfo.CreateMinute;
  PS2Save.PS2DirInfo.ModHour := PS2Save.PS2DirInfo.CreateHour;
  PS2Save.PS2DirInfo.ModDays := PS2Save.PS2DirInfo.CreateDay;
  PS2Save.PS2DirInfo.ModMonth := PS2Save.PS2DirInfo.CreateMonth;
  PS2Save.PS2DirInfo.ModYear := PS2Save.PS2DirInfo.CreateYear;

  PS2Save.PS2DirInfo.numberOfFilesInDir := MaxFile.numFiles + 2;
  PS2Save.PS2DirInfo.attribute := $8427;

  tempName := MaxFile.getHeaderDirname2;
  FillChar(PS2Save.PS2DirInfo.filename, 32*SizeOf(Byte), 0);

  for x := 0 to Length(tempName) -1 do begin
     PS2Save.PS2DirInfo.filename[x] := tempName[x];
  end;
  mainDirName :=  PS2Save.PS2DirInfo.filename;

  for x := 0 to MaxFile.numFiles -1 do begin
      new(aPS2File);
      aPS2File.fileMeta.CreateReserved := PS2Save.PS2DirInfo.CreateReserved;
      aPS2File.fileMeta.CreateSecond := PS2Save.PS2DirInfo.CreateSecond;
      aPS2File.fileMeta.CreateMinute := PS2Save.PS2DirInfo.CreateMinute;
      aPS2File.fileMeta.CreateHour := PS2Save.PS2DirInfo.CreateHour;
      aPS2File.fileMeta.CreateDay := PS2Save.PS2DirInfo.CreateDay;
      aPS2File.fileMeta.CreateMonth := PS2Save.PS2DirInfo.CreateMonth;
      aPS2File.fileMeta.CreateYear := PS2Save.PS2DirInfo.CreateYear;

      aPS2File.fileMeta.ModReserved := aPS2File.fileMeta.CreateReserved;
      aPS2File.fileMeta.ModSecond := aPS2File.fileMeta.CreateSecond;
      aPS2File.fileMeta.ModMinute := aPS2File.fileMeta.CreateMinute;
      aPS2File.fileMeta.ModHour := aPS2File.fileMeta.CreateHour;
      aPS2File.fileMeta.ModDay := aPS2File.fileMeta.CreateDay;
      aPS2File.fileMeta.ModMonth := aPS2File.fileMeta.CreateMonth;
      aPS2File.fileMeta.ModYear := aPS2File.fileMeta.CreateYear;

      aPS2File.theFile := TMemoryStream.Create;
      maxFile.ExtractFiletoStream(x + 1, TStream(aPS2File.theFile));
      aPS2File.theFile.Position := 0;

      aPS2File.fileMeta.attribute := $8497;
      aPS2File.fileMeta.filesize := aPS2File.theFile.Size;
      fileSizes := fileSizes + aPS2File.theFile.Size;

      FillChar(aPS2File.fileMeta.filename, 32*SizeOf(Byte), 0);
      tempName := MaxFile.getFileNameforFile(x);

      for i := 0 to length(tempName) -1 do begin
        aPS2File.fileMeta.filename[i] := tempName[i];
      end;

      aPS2File.fileMeta.positionInFile := 0;

      PS2Save.files.Add(aPS2File);

      if aPS2File.fileMeta.filename = 'icon.sys' then begin
        aPS2File.theFile.Read(PS2Save.iconSys, sizeOf(PS2Save.iconSys));
        aPS2File.theFile.Position := 0;
      end;

    newItem := nil;
    newItem := form1.ListView1.Items.Add;
    newItem.Caption := aPS2File^.fileMeta.filename;
    newItem.SubItems.Add(intToStr(aPS2File^.fileMeta.filesize));
    //Creation date
    created := '';
    if aPS2File^.fileMeta.CreateHour < 10 then begin
      created := created + '0';
    end;
    created := created + intToStr(aPS2File^.fileMeta.CreateHour) + ':';
    if aPS2File^.fileMeta.CreateMinute < 10 then begin
      created := created + '0';
    end;
    created := created + intToStr(aPS2File^.fileMeta.CreateMinute)
      {+ ':' + intToStr(fileInfo^.CreateSeconds)} + ' ' + intToStr(aPS2File^.fileMeta.CreateDay)
      + '/' + intToStr(aPS2File^.fileMeta.CreateMonth) + '/' + intToStr(aPS2File^.fileMeta.CreateYear);
    newItem.SubItems.Add(created);
    //modifed date
    modified := '';
    if aPS2File^.fileMeta.ModHour < 10 then begin
      modified := modified + '0';
    end;
    modified := modified + intToStr(aPS2File^.fileMeta.ModHour) + ':';
    if aPS2File^.fileMeta.ModMinute < 10 then begin
      modified := modified + '0';
    end;
    modified := modified + intToStr(aPS2File^.fileMeta.ModMinute)
      {+ ':' + intToStr(fileInfo^.ModSeconds)} + ' ' + intToStr(aPS2File^.fileMeta.ModDay)
      + '/' + intToStr(aPS2File^.fileMeta.ModMonth) + '/' + intToStr(aPS2File^.fileMeta.ModYear);
    newItem.SubItems.Add(modified);

  end;

  while fileSizes mod 1024 <> 0 do begin
   fileSizes := fileSizes + 1;
  end;

  PS2Save.PS2Header.displaySize := fileSizes;
  maxFile.Destroy;
  PS2Buttons(true);
  Result := True;
end;

function TPSVFile.ImportPS1MCSFile(fileName: string): boolean;
var
  x : integer;
  NewItem : TListItem;
  mcsFile : TMemoryStream;
  newSaltSeed :  byteArray20;
  MCSHeader : TPS1MCSHeader;
  xorVal : byte;

begin
  Clear;
  PS2File := False;

  stringToArray20('7777772e70733273617665746f6f6c732e636f6d', newSaltSeed);

  PS1Save.PSVHeader.magic[0]  := AnsiChar($0);
  PS1Save.PSVHeader.magic[1]  := AnsiChar($56);
  PS1Save.PSVHeader.magic[2]  := AnsiChar($53);
  PS1Save.PSVHeader.magic[3]  := AnsiChar($50);
  PS1Save.PSVHeader.padding1 := 0;
  for x := 0 to 19 do begin
    PS1Save.PSVHeader.salt[x] := newSaltSeed[x];
  end;

  FillChar(PS1Save.PSVHeader.signature, 20*SizeOf(Byte), 0);
  PS1Save.PSVHeader.padding2 := 0;
  PS1Save.PSVHeader.padding3 := 0;
  PS1Save.PSVHeader.headerSize := $14;
  PS1Save.PSVHeader.saveType := 1;

  mcsFile := TMemoryStream.Create;
  mcsFile.LoadFromFile(fileName);
  mcsFile.Position := 0;

  mcsFile.Read(MCSHeader, sizeOf(MCSHeader));
  mcsFile.Read(xorVal, sizeOf(xorval));

  PS1Save.PS1File.CopyFrom(mcsFile, mcsFile.Size - mcsFile.Position);

  PS1Save.PS1header.saveSize := MCSHeader.dataSize;
  PS1Save.PS1header.startOfSaveData := 0;
  PS1Save.PS1header.blockSize := 512;
  FillChar(PS1Save.PS1header.padding1, SizeOf(Integer), 0);
  FillChar(PS1Save.PS1header.padding2, SizeOf(Integer), 0);
  FillChar(PS1Save.PS1header.padding3, SizeOf(Integer), 0);
  FillChar(PS1Save.PS1header.padding4, SizeOf(Integer), 0);
  PS1Save.PS1header.dataSize := PS1Save.PS1header.saveSize;
  PS1Save.PS1header.unknown1 := 36867;
  for x := 0 to 19 do begin
    PS1Save.PS1header.prodCode[x] := MCSHeader.prodCode[x];
  end;

  FillChar(PS1Save.PS1header.padding6, SizeOf(Integer), 0);
  FillChar(PS1Save.PS1header.padding7, SizeOf(Integer), 0);
  FillChar(PS1Save.PS1header.padding8, SizeOf(Integer), 0);

  newItem := nil;
  newItem := form1.ListView1.Items.Add;
  newItem.Caption := PS1Save.PS1header.prodCode;
  mainDirName := PS1Save.PS1header.prodCode;
  newItem.SubItems.Add(intToStr(PS1Save.PS1header.saveSize  div 8192) + ' block(s)');
  mcsFile.Free;

  PS2Buttons(False);

  Result := True;
end;

function TPSVFile.exportARMaxSave(fileName : String): boolean;
var
  maxFile : TMaxSave;
  x : integer;
  aPS2File : PTPS2File;
  dialogResult : integer;
begin

  if fileExists(fileName) then begin
    dialogResult := MessageDlg(fileName + sLineBreak + 'already exists, overwrite?', mtConfirmation, [mbYes, mbNo], 0, mbYes);
    if (dialogResult = mrCancel) or (dialogResult = mrNo) then begin
      Result := False;
      Exit;
    end;
  end;

  maxFile := TMaxSave.Create;

  for x := 0 to PS2Save.files.Count -1 do begin
    aPS2File := PS2Save.files.Items[x];
    aPS2File.theFile.Position := 0;
    maxFile.addFileFromStream(aPS2File^.theFile, aPS2File^.fileMeta.filename);
  end;

  maxFile.setHeaderDirName(PS2Save.PS2DirInfo.filename);
  maxFile.saveMaxFile(fileName);
  maxFile.Destroy;
  showMessage('Exported PS2 Save to ' + sLineBreak + fileName);
  Result := True;
end;


end.
