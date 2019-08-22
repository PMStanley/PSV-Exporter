unit PSVFormat;

//////////////////////////////////////////////////////////
//
// Copyright Peter Stanley
// https://github.com/PMStanley
//
//////////////////////////////////////////////////////////

// If you make any changes to this file be sure to send update to gothi at PS2Savetools.

interface

type

titleArray = array[0..19] of AnsiChar;

THeader = record
  magic : array[0..3] of AnsiChar;
  padding1 : integer;  //always 0x00000000
  salt : array [0..19] of byte;
  signature : array [0..19] of byte; //digital sig
  padding2 : integer; //always 0x00000000
  padding3 : integer; //always 0x00000000
  headerSize : integer; //always 0x0000002C in PS2, 0x00000014 in PS1. 
  saveType : integer; //0x00000002 PS2, 0x00000001 PS1
end;
PTHeader = ^THeader;

TPS2Header = record
  displaySize : integer; //PS3 will just round this up to the neaest 1024 boundry so just make it as good as possible
  sysPos : integer; //location in file of icon.sys
  sysSize : integer; //icon.sys size
  icon1Pos : integer; //position of 1st icon
  icon1Size : integer; //size of 1st icon
  icon2Pos : integer; //position of 2nd icon
  icon2Size : integer; //size of 2nd icon
  icon3Pos : integer; //position of 3rd icon
  icon3Size : integer; //size of 3rd icon
  numberOfFiles : integer;
end;
PTPS2Header = ^TPS2Header;


TPS2MainDirInfo = record
  CreateReserved: byte;
  CreateSecond : byte;
  CreateMinute : byte;
  CreateHour : byte;
  CreateDay : byte;
  CreateMonth: byte;
  CreateYear : word;
  ModReserved: byte;
  ModSecond : byte;
  ModMinute : byte;
  ModHour : byte;
  ModDays : byte;
  ModMonth: byte;
  ModYear : word;
  numberOfFilesInDir : integer; //this is likely to be number of files in dir + 2 ("." and "..")
  attribute : integer; //(8427 dir)
  filename : array[0..31] of AnsiChar;
end;
PTPS2MainDirInfo = ^TPS2MainDirInfo;

TPS2FileInfo = record
  CreateReserved: byte;
  CreateSecond : byte;
  CreateMinute : byte;
  CreateHour : byte;
  CreateDay : byte;
  CreateMonth: byte;
  CreateYear : word;
  ModReserved: byte;
  ModSecond : byte;
  ModMinute : byte;
  ModHour : byte;
  ModDay : byte;
  ModMonth: byte;
  ModYear : word;
  filesize : integer;
  attribute : integer; //(8497 file)
  filename : array[0..31] of AnsiChar; // 'Real' PSV files have junk in this after text.
  positionInFile : integer;
end;
PTPS2FileInfo = ^TPS2FileInfo;

TPS1Header = record
  saveSize : integer;
  startOfSaveData : integer;
  blockSize : integer; //always 0x00020000 (512). Block size?
  padding1 : integer; //always 0x00000000?
  padding2 : integer; //always 0x00000000?
  padding3 : integer; //always 0x00000000?
  padding4 : integer; //always 0x00000000?
  dataSize : integer; //save size repeated?
  unknown1 : integer; //always 0x03900000 (36867)?
  prodCode : array[0..19] of AnsiChar; //20 bytes, 0x00 filled & terminated
  padding6 : integer; //always 0x00000000?
  padding7 : integer; //always 0x00000000?
  padding8 : integer; //always 0x00000000?
end;
PTPS1Header = ^TPS1Header;

TPS1MCSHeader = packed record
  magic : integer; // = 81;
  dataSize : integer;
  positionInCard : word; // = $FFFF;
  prodCode : array[0..19] of AnsiChar;
  filler : array[0..96] of byte;
end;
PTPS1MCSHeader = ^TPS1MCSHeader;

TPS1FileInfo = record
  magic : array [0..1] of AnsiChar;
  iconDisplay : byte;
  blocksUsed : byte;
  title : array [0..31] of wideChar;
end;
PTPS1FileInfo = ^TPS1FileInfo;

TIconSys = record
    magic : array[0..3] of AnsiChar;
    padding1 : word; // 0000
    secondLineOffset : word;
    padding2 : integer; // 00000000
    transparencyVal : integer; // 0x00 (clear) to 0x80 (opaque)
    bgColourUpperLeft : array [0..15] of byte;
    bgColourUpperRight : array [0..15] of byte;
    bgColourLowerLeft : array [0..15] of byte;
    bgColourLowerRight : array [0..15] of byte;
    light1Direction : array [0..15] of byte;
    light2Direction : array [0..15] of byte;
    light3Direction : array [0..15] of byte;
    light1RGB : array [0..15] of byte;
    light2RGB : array [0..15] of byte;
    light3RGB : array [0..15] of byte;
    ambientLightRGB : array [0..15] of byte;
    title : array [0..67] of byte; // null terminated, S-JIS
    IconName : array [0..63] of AnsiChar; // null terminated, S-JIS
    copyIconName : array [0..63] of AnsiChar; // null terminated, S-JIS
    deleteIconName : array [0..63] of AnsiChar; // null terminated, S-JIS
    padding3 : array[0..511] of byte;
end;
PTIconSys = ^TIconSys;

implementation

end.
