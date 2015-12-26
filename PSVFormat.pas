unit PSVFormat;

// If you make any changes to this file be sure to send update to gothi at PS2Savetools.

interface

type

titleArray = array[0..19] of AnsiChar;

THeader = record
  magic : array[0..3] of AnsiChar;
  unknown1 : integer;  //always 0x00000000?
  Signature : array [0..39] of byte; //digital signature
  unknown2 : integer; //always 0x00000000?
  unknown3 : integer; //always 0x00000000?
  unknown4 : integer; //always 0x0000002C in PS2, 0x00000014 in PS1. Perhaps size of following section including next int...
  saveType : integer; //0x00000002 appears to be PS2, 0x00000001 is PS1?
end;
PTHeader = ^THeader;

TPS2Header = record
  unknown6 : integer; //related to amount of icons? Possibly 2 words or even 4 bytes.
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
  CreateSeconds : byte;
  CreateMinutes : byte;
  CreateHours : byte;
  CreateDays : byte;
  CreateMonths: byte;
  CreateYear : word;
  ModReserved: byte;
  ModSeconds : byte;
  ModMinutes : byte;
  ModHours : byte;
  ModDays : byte;
  ModMonths: byte;
  ModYear : word;
  filesize : integer;
  attribute : integer; //(8427 dir)
  filename : array[0..31] of AnsiChar;
end;
PTPS2MainDirInfo = ^TPS2MainDirInfo;

TPS2FileInfo = record
  CreateReserved: byte;
  CreateSeconds : byte;
  CreateMinutes : byte;
  CreateHours : byte;
  CreateDays : byte;
  CreateMonths: byte;
  CreateYear : word;
  ModReserved: byte;
  ModSeconds : byte;
  ModMinutes : byte;
  ModHours : byte;
  ModDays : byte;
  ModMonths: byte;
  ModYear : word;
  filesize : integer;
  attribute : integer; //(8497 file)
  filename : array[0..31] of AnsiChar;
  //alt format
  //filename : array[0..23] of char;
  //unknown1 : integer; //constant in first entry, unique to ps2 in others?
  //unknown2 : integer; //constant per entry?
  positionInFile : integer;
end;
PTPS2FileInfo = ^TPS2FileInfo;

TPS1Header = record
  saveSize : integer;
  startOfSaveData : integer;
  unknown1 : integer; //always 0x00020000 (512). Block size?
  unknown2 : integer; //always 0x00000000?
  unknown3 : integer; //always 0x00000000?
  unknown4 : integer; //always 0x00000000?
  unknown5 : integer; //always 0x00000000?
  dataSize : integer; //save size repeated?
  unknown7 : integer; //always 0x00000000?
  prodCode : titleArray;
  unknown8 : integer; //always 0x00000000?
  unknown9 : integer; //always 0x00000000?
  unknown10 : integer; //always 0x00000000?
end;
PTPS1Header = ^TPS1Header;

TPS1MCSHeader = record
  magic : integer; // = 81;
  dataSize : integer;
  positionInCard : word; // = $FFFF;
  prodCode : titleArray;
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

implementation

end.
