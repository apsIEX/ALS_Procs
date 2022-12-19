// File: Binary.ipf     Created 12/99  JDD
// 2/00  jd  added table row selection & partial table read for long files
//   ?  jd  add Search feature for different number types

#pragma rtGlobals=1		// Use modern global access method.


Macro ShowBinaryPanel()
//-----------------
	DoWindow/F Binary_Panel
	if (V_flag==0)
		NewDataFolder/O/S root:BIN
		string/G filnam
		variable/G  ifile, numbytes			//, ncolumn=8
		Make/O/N=(20,8)/B/U Byte
		Make/O/N=(80)/B/U      Byt
		Make/O/N=(20,8)/T        Char
		Make/O/N=(20,2)/W/U  Word
		Make/O/N=(20,1)/I/U    Long
		Make/O/N=(20,2)/R       Float
		Make/O/N=(20,1)/D       Double
		variable/G bytorder=1, bytoffset=0, offsetincr=1, tablerow=0, nrow=0
		variable/G floatoffset=0
		Make/O/N=4 EightByte, TwoWord
		variable/G byteval, wordval, longval, floatval, doubleval
		variable/G byterow		//double-precision
		string/G charval, tablerange="0,999"
		variable/G tablemin=0, tablemax=1000, tableincr=1000
		variable/G searchtype=1, searchval
		string/G searchstr
		
		//set up Dependencies
		//FourByte:=Byte[p+bytoffset]
		//charval:=num2char(Byte[p+bytoffset])
		//TwoWord:=FourByte[2*p]+256*FourByte[2*p+1]		//byte order
		//longval:=TwoWord[0]+65536*TwoWord[1]
		//byterow:=byteoffset/4
		tablerow := (bytoffset-tablemin)/8
		
		SetDataFolder root:
		
		Binary_Panel()	
	endif
End

Proc ShowByteTable(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/F Byte_Table
	if (V_flag==0)
		Byte_Table()
	endif
End

Window Binary_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(380,349,710,492)
	ModifyPanel cbRGB=(577,43860,60159)
	SetDrawLayer UserBack
	DrawRRect 317,95,14,49
	Button OpenFile,pos={14,6},size={50,17},proc=OpenBinFile,title="Open"
	ValDisplay valnumbyt,pos={213,8},size={109,14},title="# bytes",fSize=9
	ValDisplay valnumbyt,limits={0,0,0},barmisc={0,1000},value= #"root:BIN:numbytes"
	SetVariable filnamdisp,pos={70,8},size={140,14},title=" ",fSize=10
	SetVariable filnamdisp,limits={-Inf,Inf,1},value= root:BIN:filnam
	SetVariable setBytOffset,pos={16,102},size={131,14},proc=ReadBin,title="Byte Offset"
	SetVariable setBytOffset,fSize=10,limits={0,Inf,1},value= root:BIN:bytoffset
	SetVariable setTableRow,pos={48,120},size={98,14},proc=SetTableRow,title="row"
	SetVariable setTableRow,fSize=10,limits={0,Inf,1},value= root:BIN:tablerow
	ValDisplay valbyte,pos={18,55},size={60,14},title="byte",fSize=10
	ValDisplay valbyte,limits={0,0,0},barmisc={0,1000},value= #"root:bin:byteval"
	ValDisplay valword,pos={86,54},size={76,14},title="word",fSize=10
	ValDisplay valword,limits={0,0,0},barmisc={0,1000},value= #"root:bin:wordval"
	ValDisplay vallong,pos={206,54},size={103,14},title="long",fSize=10
	ValDisplay vallong,limits={0,0,0},barmisc={0,1000},value= #"root:bin:longval"
	ValDisplay valfloat,pos={85,74},size={104,14},title="float",fSize=10
	ValDisplay valfloat,limits={0,0,0},barmisc={0,1000},value= #"root:bin:floatval"
	SetVariable valchar,pos={18,73},size={60,14},title="char",fSize=10
	SetVariable valchar,limits={-Inf,Inf,1},value= root:BIN:charval
	ValDisplay valfloat64,pos={193,74},size={116,14},title="double",fSize=10
	ValDisplay valfloat64,limits={0,0,0},barmisc={0,1000}
	ValDisplay valfloat64,value= #"root:bin:doubleval"
	SetVariable setOffsetIncr,pos={151,101},size={60,14},proc=SetOffsetIncr,title=" Inc"
	SetVariable setOffsetIncr,fSize=10,limits={0,Inf,1},value= root:BIN:OffsetIncr
	PopupMenu popIncr,pos={217,99},size={63,19},proc=PopByteIncr
	PopupMenu popIncr,mode=1,popvalue="1 Byte",value= #"\"1 Byte;1 Char;2 Word;4 Long;4 Float;8 Double\""
	Button ShowTable,pos={17,26},size={45,17},proc=ShowByteTable,title="Table"
	SetVariable setrange,pos={88,28},size={128,14},proc=SetTableRange,title=" "
	SetVariable setrange,fSize=10,limits={-Inf,Inf,1},value= root:BIN:tablerange
	Button DecrTableRng,pos={69,27},size={15,16},proc=IncrTableRange,title="<"
	Button IncrTableRng,pos={218,27},size={15,16},proc=IncrTableRange,title=">"
	SetVariable setfloatoffset,pos={237,28},size={84,14},proc=SetFloatOffset,title="floatoffset"
	SetVariable setfloatoffset,fSize=10,limits={0,7,1},value= K19
	SetVariable searchstr,pos={167,122},size={70,14},title=" ",fSize=10
	SetVariable searchstr,limits={-Inf,Inf,1},value= root:BIN:searchstr
	Button GoFind,pos={244,121},size={50,16},proc=Search,title="Search"
EndMacro



Proc PopByteIncr(ctrlName,popNum,popStr) : PopupMenuControl
//---------------
	String ctrlName
	Variable popNum
	String popStr

	variable incr=str2num( popStr[0] )
	SetOffsetIncr("", incr, "", "")
	root:BIN:SearchType=popNum
End

Function SetOffsetIncr(ctrlName,varNum,varStr,varName) : SetVariableControl
//================
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	NVAR offsetincr=root:BIN:offsetincr
	offsetincr=varNum

	SetVariable setBytOffset limits={0,Inf, varNum}
End


Function SetTableRow(ctrlName,varNum,varStr,varName) : SetVariableControl
//===================
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR tablemin=root:BIN:tablemin
	ReadBin(ctrlName,8*varNum+tablemin,varStr,varName)
	//NVAR bytoffset=root:BIN:bytoffset		//row=root:BIN:tablerow,  
	//bytoffset=8*varNum
	//root:BIN:tablerow:=root:BIN:bytoffset/8		//preset dependence
End


Function OpenBinFile(ctrlName) : ButtonControl
//================
	String ctrlName
	SetDataFolder root:BIN:
	NVAR ifile=ifile
	NVAR numbytes=numbytes, ncolumn=ncolumn
	NVAR tablemin=tablemin, tablemax=tablemax
	SVAR filnam=filnam
	
	if (stringmatch(ctrlName,"OpenFile"))
		Open/R/T="????" ifile
			FStatus ifile
			numbytes=V_logEOF
			filnam=S_filename
			
		ReadByteTable( tablemin, tablemax)
		
		//Leave Open for manual searching via panel
		//change Open button to Close
		Button OpenFile title="Close", rename=CloseFile

	else		//close
		Close ifile
		Button CloseFile title="Open",rename=OpenFile
		filnam=""
		numbytes=0
	endif
	SetDataFolder root:
End

Proc SetTableRange(ctrlName,varNum,varStr,varName) : SetVariableControl
//=================
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	SetDataFolder root:BIN:
	variable tmin, tmax
	tmin=round(Str2num( StringFromList( 0, varStr, ",") ))
	tmax=round(Str2num( StringFromList( 1, varStr, ",") ))
	
	if ((tmin!=tablemin)+(tmax!=tablemax))		//range changed
		tablemin=tmin
		tablemax=tmax
		tableincr=tablemax-tablemin+1
		FStatus ifile				// valid open file
		if (V_flag>0)
			ReadByteTable(tablemin, tablemax)
			ConvertBytes(floatoffset )
		endif
	endif
	tablerange=num2str(tablemin)+","+num2str(tablemax)
	//root:BIN:tablerange=num2str(root:BIN:tablemin)+","+num2str(root:BIN:tablemax)
	
	SetDataFolder root:
End


Function IncrTableRange(ctrlName) : ButtonControl
//==================
	String ctrlName
	SetDataFolder root:BIN:
	SVAR tablerange=tablerange
	NVAR numbytes=numbytes
	variable tmin,tmax, tincr
	tmin=round(Str2num( StringFromList( 0, tablerange, ",") ))
	tmax=round(Str2num( StringFromList( 1, tablerange, ",") ))
	tincr=tmax-tmin+1
	if (stringmatch(ctrlName, "DecrTableRng"))
		tmin-=tincr
		tmin=SelectNumber(tmin<0, tmin, 0)
		tmax=tmin+tincr-1
	else
		tmax+=tincr
		tmax=SelectNumber(tmax>numbytes, tmax, numbytes)
		tmin=tmax-tincr+1
	endif
	tablerange=num2str(tmin)+","+num2str(tmax)
	//SetVariable setrange, value= root:BIN:tablerange	
	SetDataFolder root:
End

Function ReadByteTable(imin, imax)
//================
//read range of file into Byte Table & convert to Char
// check imax with # bytes in file
	variable imin, imax

	string curr=GetDataFolder(1)
	SetDataFolder root:BIN:
	NVAR numbytes=numbytes, nrow=nrow
	NVAR ifile=ifile
	imin*=(imin>0)		// no negative
	imin=8*floor(imin/8)
	imax=8*ceil(imax/8+1)
	imax=SelectNumber(imax<numbytes, numbytes-1, imax)
	imax=8*floor(imax/8)
	print imin, imax
	
	variable nbytes=imax-imin
	nrow=nbytes/8
	WAVE Byte=Byte
	Redimension/N=(nrow, 8) Byte
	variable ii=0, byteval
	FSetPos ifile, imin
	 DO
		FBinRead/F=1/B=3 ifile, byteval
		Byte[floor(ii/8)][mod(ii,8)]=byteval
		ii+=1
	WHILE(ii<nbytes)
	
	// convert ot ASCII character
	WAVE/T Char=Char
	Redimension/N=(nrow,8) Char
	Char=num2char( Byte )
		
	SetDataFolder $curr
End



Function ReadBin(ctrlName,varNum,varStr,varName) : SetVariableControl
//================
//read open binary file using offset provided (use SetPos)
//display values in byte, char, word, float and float64 forms
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	string curr=GetDataFolder(1)
	SetDataFolder root:BIN:
	NVAR ifile=ifile, bytoffset=bytoffset
	NVAR byteval=byteval, wordval=wordval, longval=longval
	NVAR floatval=floatval, doubleval=doubleval
	SVAR charval=charval
	
	bytoffset=varNum
	
	//Read byte & char
	FSetPos ifile, bytoffset
	FBinRead/F=1/B=3/U ifile, byteval
	charval=num2char(byteval)
	
	FSetPos ifile, bytoffset
	FBinRead/F=2/B=3/U ifile, wordval
	
	FSetPos ifile, bytoffset
	FBinRead/F=3/B=3/U ifile, longval
	
	FSetPos ifile, bytoffset
	FBinRead/F=4/B=3 ifile, floatval
	
	FSetPos ifile, bytoffset
	FBinRead/F=5/B=3 ifile, doubleval

	SetDataFolder $curr
End

Function Search(ctrlName) : ButtonControl
//==================
	String ctrlName
	
	SetDataFolder root:BIN:
	NVAR bytoffset=bytoffset, numbytes=numbytes
	NVAR type=SearchType, ifile=ifile
	SVAR str=SearchStr
	variable searchval, binval, found=0
	searchval=SelectNumber( type==2, str2num( str ), char2num( str) )
	variable ii=bytoffset+1, imax=numbytes-8		//start search at current offset+1
	DO
		FSetPos ifile, ii
		if (type<=2)		//byte, char
			FBinRead/F=1/B=3/U ifile, binval
		endif
		if (type==3)		//word 2
			FBinRead/F=2/B=3/U ifile, binval
		endif
		if (type==4)		//long 4
			FBinRead/F=2/B=3/U ifile, binval
		endif
		if (type==5)		//float
			FBinRead/F=4/B=3 ifile, binval
		endif
		if (type==6)		//double
			FBinRead/F=5/B=3 ifile, binval
		endif
		if (binval==searchval)
			found=1
			break
		endif
		
		ii+=1
	WHILE( ii<imax)
	ReadBin("", ii, "", "")
	
	//update table range??
	if (found)
		variable jj
		NVAR tmin=tablemin, tmax=tablemax, tincr=tableincr
		SVAR trange=tablerange
		jj=trunc((ii-tmin)/tincr)
		jj-=(jj<0)	//direction dependence
		//print jj, tmin, tincr
		if (jj!=0)
			tmin=tmin+jj*tincr
			tmax=tmin+tincr-1
			trange=num2str(tmin)+", "+num2str(tmax)
			ReadByteTable( tmin, tmax )
		endif
	endif
	
	DoUpdate
	//bytoffset=ii
	//DoAlert 0, SelectString( found, "Not Found", "Found")
	
	SetDataFolder root:
End


Function SetFloatOffset(ctrlName,varNum,varStr,varName) : SetVariableControl
//==================
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR floatoffset=root:BIN:floatoffset
	//print floatoffset, varNum
	if (varNum!=floatoffset)
		floatoffset=varNum
		ConvertBytes( floatoffset )
	endif
End

Function ConvertBytes( offset )
//============
	variable offset
	
	string curr=GetDataFolder(1)
	SetDataFolder root:BIN:
	NVAR nrow=nrow
	WAVE Byte=Byte, Byt=Byt
	WAVE Word=Word, Long=Long
	WAVE Float=Float, Double=Double
	
	// copy bytes to 1-D array
	Redimension/N=(nrow*8)/U/B Byt
	Byt=Byte[floor(p/8)][mod(p,8)]
	
	//Word, 2-byte,16-bit
	Redimension/N=(nrow,4)/U/I Word
	Word=Byt[offset+8*p+2*q]+256*Byt[offset+8*p+2*q+1]		//+8*(Byt[offset+8*p+4*q+2]+8*Byt[offset+8*p+4*q+3]))
	//Word=Byte[p][4*q]+8*(Byte[p][4*q+1]+8*(Byte[p][4*q+2]+8*Byte[p][4*q+3]))
	
	//Long word, 4-byte, 32-bit
	Redimension/N=(nrow,2)/U/D Long
	Long=Word[p][2*q]+65536*Word[p][2*q+1]
	
	Redimension/N=(nrow,2) Float
	Float=long2float( Long )
	
	Redimension/N=(nrow,1)/D Double
	Double=long2double( Long[p][1] )
	
	SetDataFolder $curr
End


Function/T LoadBIN(ctrlName) : ButtonControl
	String ctrlName
//Function/T ReadBIN(idialog)
//=================
// read binary file header
//	variable idialog

	NewDataFolder/O/S root:BIN
	SVAR filpath=filpath, filnam=filnam
	WAVE Byte=Byte, Byt=Byt, Word=Word, Long=Long, Float=Float
	WAVE/T Char=Char
	
	NVAR numbytes=numbytes
	
	variable file
	Open/R file
		FStatus file
		numbytes=V_logEOF
		filnam=S_filename
		//print numbytes, V_logEOF
		
		Redimension/N=(numbytes) Byte
		variable ii=0, byteval
		 DO
			FBinRead/F=1/B=2 file, byteval
			Byte[ii]=byteval
			ii+=1
		WHILE(ii<numbytes)
	Close file
	
	variable nrow=ceil(numbytes/4)
	Duplicate/O Byte Byt
	redimension/N=(4,nrow) Byt
	MatrixTranspose Byt
	
	// ASCI character
	Redimension/N=(nrow,4) Char
	Char=num2char( Byt )
	
	//16-bit word / integer
	Redimension/N=(nrow,2) Word
	Word=Byt[p][2*q]+256*Byt[p][2*q+1]
	
	//32-bit integer/real
	Redimension/N=(nrow,1) Long
	Long=Word[p][0]+65536*Word[p][1]
		
	SetDataFolder root:
	return filnam
End


Window Byte_Table() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:BIN:
	Edit/W=(6,76,1007,289) Byte,Char,Word,Long,Float,Double
	ModifyTable size=9,width(Point)=38,alignment(Byte)=1,width(Byte)=26,alignment(Char)=1
	ModifyTable width(Char)=26,width(Word)=40,width(Long)=74,alignment(Float)=1,format(Float)=3
	ModifyTable digits(Float)=5,width(Float)=62,alignment(Double)=1,format(Double)=3
	ModifyTable width(Double)=64
	SetDataFolder fldrSav
EndMacro

function long2float( longw )
//==============
	variable longw
	
	//string bitstr, cmd
	//sprintf   bitstr, "%b", longw
	//printf  "%31b", longw
	//cmd="sprintf bitstr, \"%31b\", longw"
	//execute cmd
	
	variable signbit, exponent, mantissa
	variable smask=2^31, mmask=(2^23-1), emask=(smask-1 - mmask)
	//printf  "%31b", smask
	//printf  "%31b", emask
	//printf  "%31b", mmask
	
	signbit=(longw %& smask)/2^31
	
	exponent=(longw %& emask)/2^23
	exponent-=127
	
	mantissa=(longw %& mmask)/2^23
	mantissa+=1.0
	
	//print  signbit, exponent, mantissa
	
	variable floatval
	floatval=(-1)^signbit * mantissa * 2^exponent
	return floatval
end

function long2double( long1	)		//, long2 )
//==============
// initially ignore long2 (lower bits) - don't need precision
	variable long1		//, long2
	
	//string bitstr, cmd
	//sprintf   bitstr, "%b", longw
	//printf  "%31b", longw
	//cmd="sprintf bitstr, \"%31b\", longw"
	//execute cmd
	
	variable signbit, exponent, mantissa
	variable smask=2^31, mmask=(2^20-1), emask=(smask-1 - mmask)
	//printf  "%32b", smask
	//printf  "%32b", emask
	//printf  "%32b", mmask
	
	signbit=(long1 %& smask)/2^31
	
	exponent=(long1 %& emask)/2^20
	exponent-=1023
	
	mantissa=(long1 %& mmask)/2^20
	mantissa+=1.0
	
	//print  signbit, exponent, mantissa
	
	variable doubleval
	doubleval=(-1)^signbit * mantissa * 2^exponent
	return doubleval
end