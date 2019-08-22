unit myLZAri;

//Hacked version of LZAri.pas by
//Hacked to use TMemoryStream instead of files.

interface

uses
classes, dialogs, sysutils, windows;

//procedure decode(length : integer; origSize : integer; data : TMemorystream);
procedure decode(length : integer; var data : TMemorystream; var outData : TMemoryStream);
procedure startDecode;
function GetBit: integer;
procedure StartModel;
function DecodeChar:integer;
function DecodePosition:integer;
function BinarySearchSym(x: cardinal): integer;
procedure UpdateModel(sym: integer);
function BinarySearchPos(x: Cardinal):integer;
function encode(var dataIn : TMemoryStream; var outFile : TMemoryStream): Cardinal; //result = compressed bytes
procedure InitTree;
procedure InsertNode(r: integer);
procedure EncodeChar(ch: integer);
procedure EncodePosition(position: integer);
procedure DeleteNode(p: integer);  // Delete node p from tree
procedure EncodeEnd;
procedure FlushBitBuffer;
procedure PutBit(bit: integer);
procedure Output(bit: integer);



const
  N =	4096;  // size of ring buffer
  F = 60;    // upper limit for match_length
  THRESHOLD	= 2;     { encode string into position and length
			         if match_length is greater than this }
  NUL	=	N;	// index for root of binary search trees
  M   =  15;
{	Q1 (= 2 to the M) must be sufficiently large, but not so
	large as the unsigned long 4 * Q1 * (Q1 - 1) overflows.  }
  Q1      =   (1 shl M);
  Q2      =   (2 * Q1);
  Q3      =   (3 * Q1);
  Q4      =   (4 * Q1);
  MAX_CUM =   (Q1 - 1);

  N_CHAR  =   (256 - THRESHOLD + F);

  type
    Ttext_buf = array[0..N + F - 1] of byte;
    Ptext_buf = ^Ttext_buf;


var
  buffer, mask : cardinal;
  writes : cardinal;
  textsize: Cardinal;
  codesize: Cardinal;
  printcount: cardinal;
  theData, outFileBuf : TMemoryStream;
  PutBitbufferPutBit: Cardinal = 0;
  PutBitmaskPutBit: Cardinal = 128;
  Bytesleft: Cardinal;
  text_buf: array[0..N + F - 1] of byte;{ ring buffer of size N,w ith extra F-1 bytes
			                     to facilitate string comparison }
  match_position, match_length: integer;  { of longest match.  These are set by the
			                       InsertNode() procedure. }
     { These constitute binary search trees. }
  lson:array[0..N + 1] of integer;   //left children
  rson:array[0..N + 257] of integer; //right children
  dad: array[0..N + 1] of integer;   //parents
  low: Cardinal = 0;
  high: cardinal = Q4;
  value: cardinal = 0;
  shifts: integer = 0;  // counts for magnifying low and high around Q2
  char_to_sym: array[0..N_CHAR] of integer;
  sym_to_char: array[0..N_CHAR + 1] of integer;

  sym_freq: array[0..N_CHAR + 1] of integer;  // frequency for symbols
  sym_cum: array[0..N_CHAR + 1] of integer;   // cumulative freq for symbols
  position_cum: array[0..N + 1] of integer;   // cumulative freq for positions


implementation

function encode(var dataIn : TMemoryStream; var outFile : TMemoryStream): Cardinal; //result = compressed bytes
var
   i, {c,} len, r, s, last_match_length: integer;
    c: byte;
   BytesRead:integer;
begin
     writes := 0;
     buffer := 0;
     mask := 0;
     textsize := 0;
     printcount := 0;

datain.Position := 0;
outFile.Position := 0;
     PutBitbufferPutBit:= 0;
     PutBitmaskPutBit:= 128;

     //GetBitmaskGetBit:= 0;
     //GetBitbuffergetbit:= 0;

     codesize := 0;
     printcount := 0;


     //Ready the variables
     low := 0;
     high := Q4;
     value := 0;
     shifts := 0;  // counts for magnifying low and high around Q2

     //if the filesize is 0 then the compressed size is 0
     Result := 0;


     textsize := dataIn.Size;
     //outFile.Write(textSize, sizeof(integer));
     bytesleft := dataIn.Size;

     if textsize = 0 then
        Exit;

 outFileBuf := TMemoryStream.Create;
     textsize := 0;
     StartModel();
     InitTree();
     s := 0;
     r := N - F;
     for i := s to r-1 do
         text_buf[i] := ord(' ');

     for len := 0 to F-1 do
         begin
              //ReadBuffer(c,bytesread);
              bytesRead := dataIn.Read(c, sizeof(byte));
              if BytesRead <= 0 then
                 break;

              text_buf[r + len] := c;
         end;
     textsize := len;
     for i := 1 to F do
         InsertNode(r - i);
     InsertNode(r);
     repeat
           if match_length > len then
              match_length := len;
           if match_length <= THRESHOLD then
              begin
                   match_length := 1;
                   EncodeChar(text_buf[r]);
              end
           else
               begin
                    EncodeChar(255 - THRESHOLD + match_length);
                    EncodePosition(match_position - 1);
               end;
           last_match_length := match_length;

           for i := 0 to last_match_length-1 do
           begin
                //readbuffer(c,bytesread);
                bytesread := dataIn.Read(c, sizeof(byte));
                if BytesRead <=0 then
                   break;

                DeleteNode(s);
                text_buf[s] := c;
                if s < F - 1 then
                   text_buf[s + N] := c;
                s := (s + 1) and (N - 1);
                r := (r + 1) and (N - 1);
                InsertNode(r);
           end;
           textsize := textsize+i;
           //if textsize > printcount then
            //  begin
                  // writeln(textsize);
           //        printcount := printcount + 1024;
            //  end;
           while i < last_match_length do
           begin
                inc(i);
                DeleteNode(s);
                s := (s + 1) and (N - 1);
                r := (r + 1) and (N - 1);
                Dec(len);
                if len >= 1 then
                   InsertNode(r);
           end;
     until len <=0;
     EncodeEnd();

     //compressed size
     //write the bytes that are still in the buffer
     //WriteBuffer(true,1);
     //dispose(inbuffer);
     //dispose(outbuffer);
     //showmessage(inttostr(outFileBuf.size));
     outFileBuf.Position := 0;
     //outFile.CopyFrom(outFileBuf, outFileBuf.Size);
     outFile.LoadFromStream(outFileBuf);
     outFile.Position := 0;
     outFileBuf.Free;
     Result := codesize;
end;

//procedure decode(length : integer; origSize : integer; data : TMemorystream; outData : TMemoryStream);
procedure decode(length : integer; var data : TMemorystream; var outData : TMemoryStream);

var
  i, j, k, r, c: integer;
  count: Cardinal;
begin
     writes := 0;
     buffer := 0;
     mask := 0;
     textsize := 0;
     printcount := 0;

     //Ready the varialbles
     low := 0;
     high := Q4;
     value := 0;
     shifts := 0;  // counts for magnifying low and high around Q2

     textsize := length;


  //data.Position := 0;
  theData := TMemoryStream.Create;
  //thedata.LoadFromStream(data);
  theData.CopyFrom(data, data.Size - data.Position);
  theData.Position := 0;
  //showMessage('startDecode');
  //outData := TMemorySTream.Create;
  startDecode;
  //showMessage('startModel');
  startModel;

  for i := 0 to  N - F-1 do begin
         text_buf[i] := ord(' ');
  end;
  //showMessage('passed loop');
     r := N - F;
     count := 0;
     while count < textSize do
     begin
          //OutputDebugString(PChar('count = ' + IntToStr(count) + ', textSize = ' + IntToStr(textSize)));
          c := DecodeChar;
          if c < 256 then
             begin

                  outData.Write(c, sizeof(byte));
                  inc(writes);
                  text_buf[r] := byte(c);
                  inc(r);
                  r := r and (N - 1);
                  inc(count);
             end
          else
              begin

                   i := (r - DecodePosition - 1) and (N - 1);
                   j := c - 255 + THRESHOLD;
                   for k := 0 to j-1 do
                       begin
                            c := text_buf[(i + k) and (N - 1)];
                            outData.Write(c, sizeof(byte));
                            inc(writes);
                            text_buf[r] := byte(c);
                            inc(r);
                            r := r and (N - 1);
                            inc(count);
                       end;
              end;
         // if count > printcount then
          //   begin

                  //aqui e um bom lugar para meter o onprogress
          //        printcount := printcount + 1024;
          //   end;
	end;
        //write the bytes that are still in the buffer
       // WriteBuffer(true,1);
      //  dispose(InBuffer);
      //  dispose(outbuffer);
      //showmessage('textsize =' + inttostr(textsize) + ', origsize=' + inttostr(length) + ', writes=' + inttostr(writes));
      //outData.SaveToFile('C:\testdata.bin');
      outData.Position := 0;
      theData.Free;
end;

procedure startDecode;
var
  i:integer;
begin
  for i := 0 to M + 2-1 do begin
    value := 2 * value + GetBit;
  end;
end;

function GetBit: integer;  // Get one bit (0 or 1)
begin
  mask := mask shr 1;

    if mask = 0 then begin
      theData.Read(buffer, sizeof(byte));
      mask := 128;
    end;
  Result := Integer((buffer and mask) <> 0);
end;

procedure StartModel;  // Initialize model
var
  ch, sym, i: integer;
begin
     sym_cum[N_CHAR] := 0;
     for sym := N_CHAR downto 1 do
         begin
              ch := sym - 1;
              char_to_sym[ch] := sym;
              sym_to_char[sym] := ch;
              sym_freq[sym] := 1;
              sym_cum[sym - 1] := sym_cum[sym] + sym_freq[sym];
	 end;
     sym_freq[0] := 0;  // sentinel (!= sym_freq[1])
     position_cum[N] := 0;
     for i := N downto 1 do
         position_cum[i - 1] := trunc(position_cum[i] + 10000 / (i + 200));
         //position_cum[i - 1] := position_cum[i] + 10000 div (i + 200);
			// empirical distribution function (quite tentative)
			// Please devise a better mechanism!
end;

function DecodeChar:integer;
var
   sym, ch: integer;
   range: Cardinal;
begin
     range := high - low;
     sym := BinarySearchSym( trunc(((value - low + 1) * sym_cum[0] - 1) / range));
     high := Trunc(low + (range * sym_cum[sym - 1]) / sym_cum[0]);
     low :=  Trunc(low +  ((range * sym_cum[sym    ]) / sym_cum[0]));
     while 1=1 do
     begin
          if low >= Q2 then
             begin
                  value := value - Q2;
                  low := low - Q2;
                  high := high - Q2;
             end
          else
              if (low >= Q1) and (high <= Q3) then
                 begin
                      value := value - Q1;
                      low := low - Q1;
                      high := high - Q1;
                 end
          else
              if high > Q2 then
                 break;
          low := low+low;
          high := high+high;
          value := 2 * value + GetBit;
     end;
     ch := sym_to_char[sym];
     UpdateModel(sym);
     Result := ch;
end;

function DecodePosition:integer;
var
   position: integer;
   range: Cardinal;
begin
     range := high - low;
     position := BinarySearchPos(Trunc (((value - low + 1) * position_cum[0] - 1) / range));
     high := Trunc(low + (range * position_cum[position    ]) / position_cum[0]);
     low := Trunc(low + ((range * position_cum[position + 1]) / position_cum[0]));

     while 1=1 do
     begin
          if low >= Q2 then
             begin
                  value := value - Q2;
                  low := low - Q2;
                  high := high - Q2;
	     end
          else
              if (low >= Q1) and (high <= Q3) then
                 begin
			value := value - Q1;
                        low := low - Q1;
                        high := high - Q1;
                 end
          else
              if high > Q2 then
                 break;
          low := low + low;
          high := high + high;
          value := 2 * value + GetBit;
     end;
     Result := position;
end;

function BinarySearchPos(x: Cardinal):integer;
	{  0 if x >= position_cum[1],
	   N - 1 if position_cum[N] > x,
	   i such that position_cum[i] > x >= position_cum[i + 1] otherwise }
var i, j, k: integer;
begin
     i := 1;
     j := N;
     while i < j do
     begin
          k := Trunc((i + j) / 2);
          if position_cum[k] > x then
             i := k + 1
          else
              j := k;
     end;
     Result := i - 1;
end;

procedure UpdateModel(sym: integer);
var i, c, ch_i, ch_sym: integer;
begin
     if (sym_cum[0] >= MAX_CUM) then
        begin
             c := 0;
             for i := N_CHAR downto 0+1 do
                 begin
                      sym_cum[i] := c;
                      sym_freq[i] := (sym_freq[i] + 1) shr 1;
                      c := c + sym_freq[i];
		 end;
		sym_cum[0] := c;
	end;
       i := sym;
       while (sym_freq[i] = sym_freq[i - 1]) do dec(i);

       if i < sym then
          begin
               ch_i := sym_to_char[i];
               ch_sym := sym_to_char[sym];
	       sym_to_char[i] := ch_sym;
               sym_to_char[sym] := ch_i;
	       char_to_sym[ch_i] := sym;
               char_to_sym[ch_sym] := i;
          end;
       inc(sym_freq[i]);
       Dec(i);
       while ( i>=0 ) do
       begin
            inc(sym_cum[i]);
            dec(i);
       end;
end;

function BinarySearchSym(x: cardinal): integer;
	{ 1      if x >= sym_cum[1],
	   N_CHAR if sym_cum[N_CHAR] > x,
	   i such that sym_cum[i - 1] > x >= sym_cum[i] otherwise }
var
   i, j, k: integer;
begin
     i := 1;
     j := N_CHAR;
     while i < j do
     begin
          k := Trunc((i + j) / 2);
          if sym_cum[k] > x then
             i := k + 1
          else
              j := k;
     end;
     Result :=  i;
end;

procedure InitTree;  // Initialize trees
var i:integer;
begin
	{ For i = 0 to N - 1, rson[i] and lson[i] will be the right and
	   left children of node i.  These nodes need not be initialized.
	   Also, dad[i] is the parent of node i.  These are initialized to
	   NUL (= N), which stands for 'not used.'
	   For i = 0 to 255, rson[N + i + 1] is the root of the tree
	   for strings that begin with character i.  These are initialized
	   to NUL.  Note there are 256 trees. }

	for i := N + 1 to N + 256 do
            rson[i] := NUL;	// root
	for i := 0 to N-1 do
            dad[i] := NUL;	// node
end;

procedure InsertNode(r: integer);
         { Inserts string of length F, text_buf[r..r+F-1], into one of the
	   trees (text_buf[r]'th tree) and returns the longest-match position
	   and length via the global variables match_position and match_length.
	   If match_length = F, then removes the old node in favor of the new
	   one, because the old one will be deleted sooner.
	   Note r plays double role, as tree node and position in buffer. }
var
   i, p, cmp, temp: integer;
   key: Ptext_buf;
begin
	cmp := 1;
        key := @text_buf[r];
        p := N + 1 + key^[0];
	rson[r] := NUL;
        lson[r] := NUL;
        match_length := 0;
        while 1=1 do
        begin
             if cmp >= 0 then
                begin
                     if rson[p] <> NUL then
                        p := rson[p]
                     else
                         begin
                              rson[p] := r;
                              dad[r] := p;
                              Exit;
                         end;
                end
             else
                 begin
                      if lson[p] <> NUL then
                         p := lson[p]
                      else
                          begin
                               lson[p] := r;
                               dad[r] := p;
                               Exit;
                          end;
		end;
             for i := 1 to  F-1 do
                 begin
                      cmp := key^[i] - text_buf[p + i];
                      if cmp <> 0 then
                         break;
                 end;
             if i > THRESHOLD then
                begin
                     if i > match_length then
                        begin
                             match_position := (r - p) and (N - 1);
                             match_length := i;
                             if match_length >= F then
                                break;
                        end
                     else
                         if i = match_length then
                            begin
                                 temp := (r - p) and (N - 1);
				 if  temp < match_position then
                                     match_position := temp;
			    end;
                end;
	end;
	dad[r] := dad[p];
        lson[r] := lson[p];
        rson[r] := rson[p];
	dad[lson[p]] := r;
        dad[rson[p]] := r;
	if rson[dad[p]] = p then
           rson[dad[p]] := r
	else
            lson[dad[p]] := r;
	dad[p] := NUL;  // remove p
end;

procedure EncodeChar(ch: integer);
var
   sym: integer;
   range: cardinal;
begin
     sym := char_to_sym[ch];
     range := high - low;
     high := Trunc(low + (range * sym_cum[sym - 1]) / sym_cum[0]);
     low :=  Trunc(low + ((range * sym_cum[sym    ]) / sym_cum[0]));
     while 1=1 do
     begin
          if high <= Q2 then
             Output(0)
          else
              if low >= Q2 then
                 begin
                      Output(1);
                      low := low - Q2;
                      high := high - Q2;
                 end
          else
              if (low >= Q1) and (high <= Q3) then
                 begin
                      inc(shifts);
                      low := low-Q1;
                      high := high-Q1;
                 end
          else
              break;
          low := low+low;
          high := high+high;
     end;
     UpdateModel(sym);
end;

procedure EncodePosition(position: integer);
var
   range: Cardinal;
begin
     range := high - low;
     high := Trunc(low + (range * position_cum[position    ]) / position_cum[0]);
     low := Trunc(low +  ((range * position_cum[position + 1]) / position_cum[0]));
     while 1=1 do
     begin
          if high <= Q2 then
             Output(0)
          else
              if low >= Q2 then
                 begin
                      Output(1);
                      low := low-Q2;
                      high := high-Q2;
                 end
          else
              if (low >= Q1) and (high <= Q3) then
                 begin
                      inc(shifts);
                      low := low-Q1;
                      high := high-Q1;
                 end
          else
              break;
          low := low+low;
          high := high+high;
     end;
end;

procedure DeleteNode(p: integer);  // Delete node p from tree
var q: integer;
begin
     if dad[p] = NUL then // not in tree
        Exit;
     if rson[p] = NUL then
        q := lson[p]
     else
         if lson[p] = NUL then
            q := rson[p]
     else
         begin
              q := lson[p];
              if rson[q] <> NUL  then
                 begin
                      repeat
                            q := rson[q];
                      until rson[q] = NUL;
                      rson[dad[q]] := lson[q];
                      dad[lson[q]] := dad[q];
                      lson[q] := lson[p];
                      dad[lson[p]] := q;
                 end;
              rson[q] := rson[p];
              dad[rson[p]] := q;
	end;
     dad[q] := dad[p];
     if rson[dad[p]] = p then
        rson[dad[p]] := q
     else
         lson[dad[p]] := q;
     dad[p] := NUL;
end;

procedure EncodeEnd;
begin
     inc(shifts);
     if low < Q1 then
        Output(0)
     else
         Output(1);
     FlushBitBuffer;  //* flush bits remaining in buffer */
end;

procedure FlushBitBuffer;  // Send remaining bits
var i: integer;
begin
     for i := 0 to 7-1 do
         PutBit(0);
end;

procedure PutBit(bit: integer);  // Output one bit (bit = 0,1)
//const
//     bufferPutBit: Cardinal = 0;
//     maskPutBit: Cardinal = 128;
begin
     if Boolean(bit) then
        PutBitbufferPutBit := PutBitbufferPutBit or PutBitmaskPutBit;
     PutBitmaskPutBit := PutBitmaskPutBit shr 1;
     if PutBitmaskPutBit= 0 then
        begin
             //writebuffer(false,Byte(PutBitbufferputbit));
             outFileBuf.Write(Byte(PutBitbufferputbit), sizeof(byte));
             PutBitbufferPutBit := 0;
             PutBitmaskPutBit := 128;
             inc(codesize);
	end;
end;

procedure Output(bit: integer);  // Output 1 bit, followed by its complements
begin
     PutBit(bit);
     while (shifts > 0) do
     begin
          dec(shifts);
          PutBit(Integer(not Boolean(bit)));
     end;
end;

end.
