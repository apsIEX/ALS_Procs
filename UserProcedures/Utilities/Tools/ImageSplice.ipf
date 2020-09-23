// File:  ImageSplice		10/00  
// Jonathan Denlinger, JDDenlinger@lbl.gov 
// adapted from Tile

#pragma rtGlobals=1		// Use modern global access method.
#include "List_Util"			// uses List2Wave(), List2Textw() functions
#include "Tags"

//Macro 	ClearOffsets()
//Proc 	ShowTile()
//Fct 	SelectTileGraph() : 			PopupMenuControl
//Fct 	ReadMod( w )
//Fct 	WriteMod(w, val1, val2, val3, styl1, styl2, styl3, mode)
//Fct 	ResetMod( w )
//Fct 	Mod2Table()
//Fct 	Table2Mod()
//Fct 	ApplyImgTable() : 			ButtonControl
//Proc 	CheckAutoApply(ctrlName,checked) : CheckBoxControl
//Fct 	AutoApplyFct(shift, offset, gain, lin, thk, clr, val, txt)
//Fct 	ColorStr( iclr )			{0..6}={black,red,blue,green,violet,bl/green,orange}
//Fct 	ShiftMenu() : 			PopupMenuControl
//Fct 	OffsetMenu() : 			PopupMenuControl
//Fct 	ScaleMenu() : 			PopupMenuControl
//Fct 	StyleMenu() : 			PopupMenuControl
//Fct 	ResetMenu() : 			PopupMenuControl
//Fct 	TileWaves() : 			PopupMenuControl
//Fct 	ExpandWaves() : 		PopupMenuControl
//Win 	TileTable() : 		Table
//Win 	TilePanel() : 		Panel
//Proc 	AddZeroline()

menu "2D"
	"-"
	"Tile Panel & Table!"+num2char(19), ShowTilePanel()
		help={"Tile plot manipulation; modifications are stored in individual wave notes"}
	"ClearOffsets"
		help={"Reset X,Y offsets on top graph so as to not confuse with Tile wave Shift/Offset"}
	"Reset Img Notes"
		help={"Redefine individual image notes to default (no physical resetting)"}
	"Add Zero line"
		help={"Append {-INF, INF} vs {0,0}; will not be hidden by wave shading"}
end

Proc AddZeroline()
//-----------------
// utility routine for stack plots with hidden line filling
	PauseUpdate; Silent 1
	make/o FEy={-INF,INF}, FEx={0,0}
	Note FEy, "0,0,1, 1, 0.5, -1, NaN"
	DoWindow/F $WinName(0,1)
	append FEy vs FEx
	ModifyGraph lstyle(FEy)=1
	ModifyGraph zero(bottom)=0		//turn off zero line interference
End

Proc ClearOffsets()
//-------------
	DoWindow/F $WinName(0,1)
	ModifyGraph offset={0,0}
End

Proc ResetImgNotes()
//-------------
	PauseUpdate; Silent 1
	variable nw=numpnts(root:imNAM)
	string im, modlst, txt
	variable ii=0, val
	DO
		modlst=ReadImgNote( $imNAM[ii] )
		val=NumberByKey("Val", modlst, "=", "," )
	 	txt=StringByKey("Txt", modlst, "=", "," )
		WriteImgNote($imNAM[ii],0, 0, 0, 1, val, txt)
 		ii+=1 
 	WHILE(ii<nw)
 	ImgNote2Table()
End

Proc ShowTilePanel()
//--------------
// initialize globals in data folder and display Tile table and panel
	NewDataFolder/O/S root:Tile

	//SetDataFolder root:	
	DoWindow/F TilePanel
	if (V_flag==0)
		// create panel variables
		string/G winnam="", whichstyle="0,1"
		variable/G xshiftval=0, yshiftval=0, zoffsetval=0, zgainval=1	//, styleval=1
		//variable/G autoline=0, autocolor=0, hiddenlines=0
		variable/G AutoImgApply=0
		
		TilePanel()
		CheckBox checkAuto,value=0
	endif
	
	SetDataFolder root:	
	DoWindow/F TileTable
	if (V_flag==0)
		//create table waves
		make/T/O/n=10 imNAM=""
		make/O/n=10 xSHIFT=0, ySHIFT=0, zOFFSET=0, zGAIN=1,  imVAL=NaN	//LIN=0, THK=1, CLR=0,
		make/T/O/n=10 imTXT=""
		TileTable()
	endif

	DoWindow/F TilePanel
End	

Function SelectTileGraph(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr

	SVAR winnam=root:Tile:winnam
	winnam = popStr
	DoWindow/F $popStr
	ShowInfo
	ImgNote2Table()
	DoWindow/F TileTable
	DoWindow/F TilePanel
	PopupMenu WinPop mode=1
End

Function/T ReadImgNote( w )		//, destwn )
//============
	wave w
	string destwn
	string noteStr, modlst
	noteStr=note(w)
	modlst=StringByKey( "IMG", noteStr, ":", "\r" )
	if (strlen(modlst)==0)					// no wave mod keywords
   		Note/K w
   		//modlst="xSHIFT=0,zOFFSET=0,zGAIN=1,LIN=0,THK=0.5,CLR=0,VAL=0,TXT= ;"
   		modlst="xShift=0,yShift=0,zOffset=0,zGain=1,Val=0,Txt= "
   		Note w, "IMG:"+modlst+"\r"+noteStr		// pre-pend default
   		print modlst
   	endif
	return modlst
	//print noteStr
	//string moddef="MOD:xSHIFT=0,zOFFSET=0,zGAIN=1,LIN=0,THK=0.5,CLR=0,imVAL=0,imTXT= ;"
	//string moddef="MOD=0,0,1;STYLE=0,0.5,0;imVAL=0,imTXT= ;"
	//string styledef="STYLE:lin=0,thk=0.5,clr=0;"
	//string annodef="ANNO:val=0,txt= ;"
End

Function/T ReadMod_old( w )		//, destwn )
//============
	wave w
	string destwn
	string noteStr, modlst=""
	noteStr=note(w)
	if (strlen(noteStr)>0)
		variable shft, off, gain, lin, thk, clr, val
		shft=ValFromList( noteStr, 0, ",")
		if (numtype(shft)==0)					// no wave mod keywords
			off=ValFromList( noteStr, 1, ",")
			gain=ValFromList( noteStr, 2, ",")
			lin=ValFromList( noteStr,3, ",")
			thk=ValFromList( noteStr, 4, ",")
			clr=ValFromList( noteStr, 5, ",")
			val=ValFromList( noteStr, 6, ",")
	   		Note/K w								// remove old values (and everything else?)
			//modlst=WriteMod(w, shft, off, gain, lin,  thk, clr, val,"")
	   	endif
   	endif
	return modlst
End

Function/T WriteImgNote(w,xshft, yshft, zoff, zgain, val, txt)
//=============
	wave w
	variable xshft, yshft, zoff, zgain, val
	string txt
	string notestr, modlst
	//modlst="xSHIFT="+num2str(shft)+",zOFFSET="+num2str(off)+",zGAIN="+num2str(gain)
	//modlst+=",LIN="+num2str(lin)+",THK="+num2str(thk)+",CLR="+num2str(clr)
	//modlst+=",imVAL="+num2str(val)+",imTXT="+txt
	modlst="xShift="+num2str(xshft)+",yShift="+num2str(yshft)
	modlst+=",zOffset="+num2str(zoff)+",zGain="+num2str(zgain)
	modlst+=",Val="+num2str(val)+",Txt="+txt
	notestr=note(w)
	notestr=ReplaceStringByKey("IMG", notestr, modlst, ":", "\r")
   	Note/K w			//kill previous note
   	Note w, noteStr
   	return modlst
end


Function ImgNote2Table()
//==================
// read wavenotes from waves on graph; enter into table
	PauseUpdate; Silent 1
	SVAR winnam=root:Tile:winnam
	WAVE/T imNAM=root:imNAM, imTXT=root:imTXT
	WAVE xSHIFT=root:xSHIFT, ySHIFT=root:ySHIFT
	WAVE zOFFSET=root:zOFFSET, zGAIN=root:zGAIN,  imVAL=root:imVAL
 	string imlst=ImageNameList(winnam, ";")
	variable nw	=list2textw(imlst,";","root:imNAM")
	//print imlst, nw
	redimension/n=(nw) imNAM, xSHIFT, ySHIFT, zOFFSET, zGAIN, imVAL, imTXT
	variable ii=0
	string modlst
	DO
		//imNAM[ii]=WaveName(winnam, ii, 1 )
		wave w=$imNAM[ii]
   	
   		modlst=ReadImgNote( w )	
	 	xSHIFT[ii]	=NumberByKey("xShift", modlst, "=", "," )
	 	ySHIFT[ii]	=NumberByKey("yShift", modlst, "=", "," )
	   	zOFFSET[ii]	=NumberByKey("zOffset", modlst, "=", "," )
	 	zGAIN[ii]	=NumberByKey("zGain", modlst, "=", "," )
	 	imVAL[ii]	=NumberByKey("Val", modlst, "=", "," )
	 	imTXT[ii]	=StringByKey("Txt", modlst, "=", "," )

 		ii+=1 
 	WHILE(ii<nw)
 	//print xshift[0]
end

Function Table2Mod()					// Not used anywhere?
//==================
// write table values to wavenotes
	PauseUpdate; Silent 1
	wave/T imNAM=root:imNAM, imTXT=root:imTXT
	wave xSHIFT=root:xSHIFT, zOFFSET=root:zOFFSET, zGAIN=root:zGAIN
	wave LIN=root:LIN, THK=root:THK, CLR=root:CLR,  imVAL=root:imVAL
	variable nw=numpnts(imNAM)
	variable ii=0
	print zOFFSET[0]*1E9
	DO
		xSHIFT[ii]*=SelectNumber( abs(xSHIFT[ii])<1E-7, 1, 0)		// remove rounding error near zero
		zOFFSET[ii]*=SelectNumber( abs(zOFFSET[ii])<1E-7, 1, 0)	
		//WriteMod( $(imNAM[ii]), xSHIFT[ii], zOFFSET[ii], zGAIN[ii], LIN[ii], THK[ii], CLR[ii], imVAL[ii], imTXT[ii] )
 		ii+=1 
 	WHILE(ii<nw)
 	print zOFFSET[0]*1E9
end


Function ApplyImgTable(ctrlName) : ButtonControl
//==============
// write table values to wavenotes
	String ctrlName
	PauseUpdate; Silent 1
	WAVE/T imNAM=root:imNAM, imTXT=root:imTXT
	WAVE xSHIFT=root:xSHIFT, ySHIFT=root:ySHIFT, zOFFSET=root:zOFFSET, zGAIN=root:zGAIN
	WAVE imVAL=root:imVAL
	//NVAR autolin=root:Tile:autoline, autocolor=root:Tile:autocolor
	//NVAR hlines=root:Tile:hiddenlines 
	variable nw=numpnts(imNAM)

	string modlst
	variable ii=0, xshft, yshft, zoff, zscl
	DO
		WAVE w=$imNAM[ii]
		modlst=ReadImgNote( w )
		xshft=xSHIFT[ii]-NumberByKey("xSHIFT", modlst, "=", ",")
		yshft=ySHIFT[ii]-NumberByKey("ySHIFT", modlst, "=", ",")
		zscl=zGAIN[ii]/NumberByKey("zGAIN", modlst, "=", ",")
		
	//** Operation Order:  (1) remove current offset, (2) apply new gain, (3) add new offset
		w = zscl * ( w - NumberByKey("zOFFSET", modlst, "=", ",") ) + zOFFSET[ii]
		variable x0, xinc, y0, yinc
		x0=DimOffset( w, 0 );  xinc=DimDelta( w, 0 )
		y0=DimOffset( w, 1 );  yinc=DimDelta( w, 1 )
 		SetScale/P x x0+xshft, xinc, WaveUnits(w, 0) w
 		SetScale/P y y0+yshft, yinc, WaveUnits(w, 1) w
 		
 		xSHIFT[ii]*=SelectNumber( abs(xSHIFT[ii])<1E-7, 1, 0)		// remove rounding error near zero
 		ySHIFT[ii]*=SelectNumber( abs(ySHIFT[ii])<1E-7, 1, 0)		// remove rounding error near zero
		zOFFSET[ii]*=SelectNumber( abs(zOFFSET[ii])<1E-7, 1, 0)	
 		WriteImgNote( w, xSHIFT[ii],  ySHIFT[ii], zOFFSET[ii], zGAIN[ii], imVAL[ii], imTXT[ii] ) 
 		
 	//---DISPLAY Modification ---
 		//print NameOfWave(w)
 		DoWindow/F $WinName(0,1)
 		SVAR winnam=root:Tile:winnam
 		DoWindow/F $winnam
 		//--Line STYLE
 			//ModifyGraph lstyle(w)=abs(LIN[i])  //cannot run macro in function
		//execute "ModifyGraph lstyle("+PossiblyQuoteName(imNAM[ii])+")=abs("+num2istr(LIN[ii])+")"
 			//ModifyGraph lsize(iw)=0
 		//execute "ModifyGraph lsize("+PossiblyQuoteName(imNAM[ii])+")="+num2istr((sign(LIN[ii])+1)/2)
 		//--Line THICKNESS
		//execute "ModifyGraph lsize("+PossiblyQuoteName(imNAM[ii])+")=abs("+num2str(THK[ii])+")"
 		//--Line COLOR  (or FILL Color for hiddenlines)
 		//if (hlines==1)
 		//	execute "ModifyGraph rgb("+PossiblyQuoteName(imNAM[ii])+")=("+ColorStr(CLR[ii])+")"
 		//else
 		//	execute "ModifyGraph hbFill("+PossiblyQuoteName(imNAM[ii])+")="+num2str(hlines*(CLR[ii]>=0))
 		//	execute "ModifyGraph rgb("+PossiblyQuoteName(imNAM[ii])+")=("+ColorStr(CLR[ii])+")"
 		//endif
 		
 		ii+=1 
 	WHILE(ii<nw)
end

Proc CheckImgAutoApply(ctrlName,checked) : CheckBoxControl
//==================
// Toggle on/off dependency of ApplyImgTable to auto-update with modifications of Tile table columns
// Deselect "Delay Update" in table to updating for every individual entry modification
// Select "Delay Update" in table to update after clicking outside of table
	String ctrlName
	Variable checked

	variable/G root:Tile:AutoImgApply
	if (checked)
		// invoke dependency
		root:Tile:AutoImgApply:=AutoImgApplyFct(root:xSHIFT, root:ySHIFT, root:zOFFSET, root:zGAIN, root:imVAL, root:imTXT)
	else
		root:Tile:AutoImgApply=0
	endif
End

Function AutoImgApplyFct(xshift, yshift, zoffset, zgain, val, txt)
//==================
	Wave xshift, yshift, zoffset, zgain, val, txt
	string winnam= WinName(0,64+16+4+2+1)
	ApplyImgTable("")
	//if (stringmatch(winnam, "TileTable"))
	//	DoWindow/F TileTable
	//endif
	DoWindow/F $winnam			//return to original top window
	return 1
End


Function/T ColorStr( iclr )
//==============
//return mapping of color index to RGB string
// Mapping:  0=black={0,0,0},  1=red={1,0,0}, 2=blue={0,0,1}, 3=green={0,1,0}
//                  4=violet={1,0,1},  5=blue-green={0,1,1},  6=orange={1,.67,0}
	variable iclr
	iclr=abs(iclr)
	string str
	make/o/n=3 root:Tile:clrw={0,0,0}
	WAVE clrw=root:Tile:clrw
	clrw[0]= (iclr==1)+(iclr==4) +(iclr==6)
	clrw[1]= (iclr==3)+(iclr==5) +(iclr==6)*0.667
	clrw[2]= (iclr==2)+(iclr==4) +(iclr==5)
	clrw*=65535
	return Wave2List( clrw, ",", 0, 2 ) 
end

Function ShiftMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	variable nw, ii, indx
	string cwn
	
	IF (stringmatch(ctrlName, "xShift"))
		NVAR xshiftval=root:Tile:xshiftval
		WAVE/T imNAM=root:imNAM
		WAVE xSHIFT=root:xSHIFT
		
		if (popNum==1)		// Shift All by specified value
			xSHIFT+=xshiftval
		endif
		if (popNum==2)		// Incremental Shift of All waves by specified value
			xSHIFT+=xshiftval*p		//additional (not absolute)
		endif
		if (popNum==3)		// Shift Ymax positions wave to specified value
			nw=numpnts(imNAM)
			ii=0
			DO
				WaveStats/Q $imNAM[ii]
				xSHIFT[ii] += (xshiftval -V_maxloc)
		 		ii+=1 
		 	WHILE(ii<nw)
		endif
		if (popNum==5)		// Shift Csr A wave to Csr B value
			xshiftval=hcsr(B)
			popStr+="="
			popNum=4
		endif
		print "xShift "+popStr, xshiftval
		if (popNum==4)		// Shift Csr A wave to specified value
			cwn=CsrWave(A)
			indx=IndexOfWave( imNAM, cwn )
			xSHIFT[ indx ] += (xshiftval-hcsr(A))		//append (not overwrite)
		endif
	ENDIF
	
	IF (stringmatch(ctrlName, "yShift"))
		NVAR yshiftval=root:Tile:yshiftval
		WAVE/T imNAM=root:imNAM
		WAVE ySHIFT=root:ySHIFT
		
		if (popNum==1)		// Shift All by specified value
			ySHIFT+=yshiftval
		endif
		if (popNum==2)		// Incremental Shift of All waves by specified value
			ySHIFT+=yshiftval*p		//additional (not absolute)
		endif
		if (popNum==3)		// Shift Ymax positions wave to specified value
			nw=numpnts(imNAM)
			ii=0
			DO
				WaveStats/Q $imNAM[ii]
				ySHIFT[ii] += (yshiftval -V_maxloc)
		 		ii+=1 
		 	WHILE(ii<nw)
		endif
		if (popNum==5)		// Shift Csr A wave to Csr B value
			yshiftval=hcsr(B)
			popStr+="="
			popNum=4
		endif
		print "yShift "+popStr, yshiftval
		if (popNum==4)		// Shift Csr A wave to specified value
			cwn=CsrWave(A)
			indx=IndexOfWave( imNAM, cwn )
			ySHIFT[ indx ] += (yshiftval-hcsr(A))		//append (not overwrite)
		endif
	ENDIF

	ApplyImgTable(ctrlName)
End

Function OffsetMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR offsetval=root:Tile:offsetval
	WAVE zOFFSET=root:zOFFSET
	WAVE/T imNAM=root:imNAM, imNAMX=root:imNAMX
	
	print "Offset "+popStr, offsetval
	
	variable nw=numpnts(imNAM), i=0
	if (popNum==1)		// Offset All by specified value
		zOFFSET+=offsetval
	endif
	if (popNum==2)		// Incremental Offset of All waves by specified value (part of Waterfall)	
		zOFFSET+=offsetval*p		//additional (not absolute)
	endif
	if (popNum==3)		// Offset Ymin positions wave to specified value
		do
			WaveStats/Q $imNAM[i]
			zOFFSET[i] += (offsetval -V_min)
	 		i+=1 
	 	while(i<nw)
	endif
	if (popNum==4)		// Offset Csr A wave by specified value
		variable indx=IndexOfWave( imNAM, CsrWave(A) )
		zOFFSET[ indx ] += offsetval						//append (not overwrite)
	endif
	if (popNum==5)		// Offset Csr A positions to specified value	
		variable xval=hcsr(A)
		do
			WAVE iw=$imNAM[i]
			if (exists(imNAMX[i]))
				WAVE iwx=$imNAMX[i]
				zOFFSET[i] += ( offsetval -interp(xval, iwx, iw) )
			else
				zOFFSET[i] += ( offsetval - iw(xval) )
			endif
	 		i+=1 
	 	while(i<nw)
	endif

	ApplyImgTable(ctrlName)
End

Function ScaleMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR gainval=root:Tile:gainval
	WAVE zGAIN=root:zGAIN
	WAVE/T imNAM=root:imNAM, imNAMX=root:imNAMX
	
	print "Scale "+popStr, gainval
	
	if (popNum==1)		// Scale All by specified value
		zGAIN*=gainval
	endif
	if (popNum==3)		//  Scale Ymax to Cursor A value
		gainval=vcsr(A)
		if (numtype( gainval )!=0)
			abort "Cursor Value not set!"
			return 1
		endif
		popNum=2
	endif
	variable nw=numpnts(imNAM), i=0
	if (popNum==2)		// Scale Ymax to specified value
		do
			WaveStats/Q $imNAM[i]
			zGAIN[i] *= (gainval /V_max)
	 		i+=1 
	 	while(i<nw)
	endif
	if (popNum==4)		// Scale Csr A wave by specified value
		variable indx=IndexOfWave( imNAM, CsrWave(A) )
		zGAIN[ indx ] *= gainval				//append (not overwrite)
	endif
	if (popNum==6)		//Scale Csr A positions to Csr A value	
		gainval=vcsr(A)
		popNum=5
	endif
	if (popNum==5)		//Scale Csr A positions to specified value	
		variable xval=hcsr(A)
		do
			WAVE iw=$imNAM[i]
			if (exists(imNAMX[i]))
				WAVE iwx=$imNAMX[i]
				zGAIN[i] *= ( gainval /interp(xval, iwx, iw) )
			else
				zGAIN[i] *= ( gainval / iw(xval) )
			endif
	 		i+=1 
	 	while(i<nw)
	endif

	ApplyImgTable(ctrlName)
End

Function StyleMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	WAVE LIN=root:LIN, CLR=root:CLR
	SVAR style=root:Tile:whichstyle
	variable irepeat, ioffset
	ioffset=ValFromList( style, 0, ",")
	irepeat=ValFromList( style, 1, ",")
	if (numtype(irepeat)!=0)
		irepeat=ioffset; ioffset=0
	endif
	print ioffset, irepeat
	
	print popNum
	if ((popNum==1)+(popNum==3))
		LIN=mod(p, min(irepeat+9*(irepeat==1),9) )
	endif
	if ((popNum==2)+(popNum==3))
		CLR=mod(p, min(irepeat+7*(irepeat==1),7) )
	endif
	if ((popNum==4)+(popNum==6))
		LIN=1-(mod(p-ioffset,irepeat)==0)
	endif
	if ((popNum==5)+(popNum==6))
		CLR=(mod(p-ioffset,irepeat)==0)
	endif

	ApplyImgTable(ctrlName)
End

Proc TagMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	//variable irepeat=trunc(root:Tile:styleval), ioffset
	//ioffset=trunc(10*(root:Tile:styleval-irepeat)+.001)
	//string which=num2istr(irepeat)+","+num2istr(ioffset) 
	string tagStr=StringFromList( popNum-1, "imVAL;imTXT;;imVAL;imTXT;" )
	string tagAtStr=StringFromList( popNum-1, ";;imVAL;imVAL;imVAL;" )
	//print tagStr, ", At=", tagAtStr
	
	if (popNum<=5)
		if (exists("root:tag:prefix")==0)
			TagPrefs()
		endif
		TagWaves(tagStr, root:Tile:whichStyle, tagAtStr, 1)
	else
		if ((popNum==7)+(popNum==8))
			string tagprefix=StringFromList(popNum-7, "t;t_")
			RemoveTags( tagprefix, root:Tile:whichStyle )
		endif
		if (popNum==9)
			TagPrefs()
		endif
	endif

	DoWindow/F $WinName(0,1)
End


Function ResetMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	WAVE xSHIFT=root:xSHIFT, ySHIFT=root:ySHIFT
	WAVE zOFFSET=root:zOFFSET,  zGAIN=root:zGAIN
	
	if ((popNum==2)+(popNum==1))
		xSHIFT=0
	endif
	if ((popNum==3)+(popNum==1))
		ySHIFT=0
	endif
	if ((popNum==4)+(popNum==1))
		zOFFSET=0
	endif
	if ((popNum==5)+(popNum==1))
		zGAIN=1
	endif

	ApplyImgTable(ctrlName)
End


Function TileImages(ctrlName,popNum,popStr) : PopupMenuControl
//==============
// Combination of Shift and Offset
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR xval=root:Tile:xshiftval, yval=root:Tile:yshiftval
	WAVE xSHIFT=root:xSHIFT, ySHIFT=root:ySHIFT
	
	variable nw, ii
	if (popNum==1)		//additional shift and stack
		xSHIFT+=xval*p; ySHIFT+=yval*p
		ApplyImgTable(ctrlName)
	endif
	if (popNum==2)		//absolute shift and stack
		xSHIFT=xval*p; ySHIFT=yval*p
		ApplyImgTable(ctrlName)
	endif
	if (popNum==3)		// Transpose Images
		WAVE/T imNAM=root:imNAM
		nw=numpnts(imNAM)
		string notestr, modlst, xstr, ystr
		variable x_val, y_val
		if (nw>1)
			ii=0
			DO
				MatrixTranspose $imNAM[ii]
				//Swap  X & Yshift info
					notestr=note($imNAM[ii] )
					//print notestr
					x_val=NumberByKey("IMG:xShift", notestr, "=", "," )
		 			y_val=NumberByKey("yShift", notestr, "=", "," )
		 			notestr=ReplaceNumberByKey( "IMG:xShift", notestr, y_val, "=", ",")
		 			notestr=ReplaceNumberByKey("yShift", notestr, x_val, "=", ",")
		 			//print x_val, y_val, notestr
	   				Note/K $imNAM[ii];  Note $imNAM[ii], noteStr
   				// or
   				//modlst=ReadImgNote( $imNAM[ii] )
				//xval=StringByKey("xShift", modlst, "=", "," )
	 			//yval=StringByKey("yShift", modlst, "=", "," )
   				//zoff=NumberByKey("zOffset", modlst, "=", "," )
	 			//zgain=NumberByKey("zGain", modlst, "=", "," )
	 			//val=NumberByKey("Val", modlst, "=", "," )
	 			//txt=StringByKey("Txt", modlst, "=", "," )
				//WriteImgNote($imNAM[ii],yval, xval, zoff, zgain, val, txt)
				ii+=1
			WHILE(ii<nw)
			variable/G root:Tile:tmpval=xval; NVAR tmpval=root:Tile:tmpval
			xval=yval; yval=tmpval
			ImgNote2Table()			// Refresh table
		endif
	endif

	if (popNum==6)		// reverse order of traces
		WAVE/T imNAM=root:imNAM
		nw=numpnts(imNAM)
		if (nw>1)
			SVAR winnam=root:Tile:winnam
			DoWindow/F $winnam
			ii=0
			DO
				ReorderTraces $imNAM[ii], { $imNAM[ii+1] }
				ii+=1
			WHILE(ii<nw-1)
			
			//string cmd="ReorderTraces "+imNAM[0]+", {"
			//variable ii=nw-1
			//DO
			//	cmd+=imNAM[ii]+","
			//	ii-=1
			//WHILE( ii>1)
			//cmd+=imNAM[1]+"}"

			//print cmd
			//execute cmd					// Reorder A, {Z, Y, ...,B}  //Can't handle too long of string
			ImgNote2Table()			// Refresh table
		endif
	endif
End

Function ExpandWaves(ctrlName,popNum,popStr) : PopupMenuControl
//================
//Combination of Offset and Gain
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR gval=root:Tile:gainval, oval=root:Tile:offsetval
	WAVE zGAIN=root:zGAIN, zOFFSET=root:zOFFSET
	WAVE/T imNAM=root:imNAM
	if (popNum==2)				//expand to Csr A wave range
		Wavestats/Q CsrWaveRef(A)
		gval=V_max; oval=V_min
	endif
	variable nw=numpnts(imNAM), i=0, ngain
	do
		WaveStats/Q $imNAM[i]
		ngain=(gval-oval)/(V_max-V_min)
		zGAIN[i] *= ngain
		zOFFSET[i] = oval - ngain*(V_min-zOFFSET[i]) 		// assumes ApplyImgTable does zGAIN first
	 	i+=1 
	while(i<nw)
	ApplyImgTable(ctrlName)
End

Window TileTable() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(486,88,912,301) imNAM,xSHIFT,ySHIFT,zOFFSET,zGAIN,imVAL,imTXT as "Tile Table"
	ModifyTable size=9,alignment=1,width(Point)=22,width(imNAM)=68,width(xSHIFT)=48
	ModifyTable width(ySHIFT)=48,width(zOFFSET)=48,sigDigits(zGAIN)=4,width(zGAIN)=56
	ModifyTable width(imVAL)=48,width(imTXT)=60
EndMacro

Window TilePanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(606,346,955,482)
	ModifyPanel cbRGB=(65535,65535,0)
	ShowTools
	SetDrawLayer UserBack
	DrawRRect 244,73,245,73
	SetDrawEnv fillfgc= (65535,16385,16385)
	DrawRRect 5,30,157,83
	SetDrawEnv fsize= 10
	DrawText 13,102,"v1.0"
	SetDrawEnv fillfgc= (65535,16385,16385)
	DrawRRect 162,30,314,83
	PopupMenu WinPop,pos={11,6},size={119,19},proc=SelectTileGraph,title="Win:"
	PopupMenu WinPop,mode=1,popvalue="im01_Img",value= #"WinList(\"*\",\";\",\"WIN:1\")"
	Button ApplyButton,pos={201,6},size={78,19},proc=ApplyImgTable,title="ApplyTable"
	Button ApplyButton,help={"Modify traces & Write values from TileTable into Trace wave notes"}
	PopupMenu xShift,pos={9,36},size={70,19},proc=ShiftMenu,title="X shift  "
	PopupMenu xShift,mode=0,value= #"\"Shift All by:;Incremental shift by:;zMAX Positions to:;Csr Wave A Pos to:;Csr AÑ>B\""
	SetVariable xshiftval,pos={11,60},size={66,17},title=" "
	SetVariable xshiftval,help={"value used for horizontal SHIFT options"}
	SetVariable xshiftval,limits={-Inf,Inf,1},value= root:Tile:xshiftval
	SetVariable offsetval,pos={168,59},size={67,17},title=" "
	SetVariable offsetval,help={"value used for vertical OFFSET options"}
	SetVariable offsetval,limits={-Inf,Inf,1},value= root:Tile:zoffsetval
	PopupMenu zOffsetMenu,pos={166,34},size={71,19},proc=OffsetMenu,title="Z offset"
	PopupMenu zOffsetMenu,mode=0,value= #"\"Offset All by:;Incremental stack by:;YMIN values to:;Csr A wave by:;Csr A positions to:\""
	PopupMenu TileMenu,pos={57,87},size={47,19},proc=TileImages,title="Tile"
	PopupMenu TileMenu,help={"combined use of SHIFT & OFFSET values"}
	PopupMenu TileMenu,mode=0,value= #"\"Additional;Absolute;Transpose All\""
	PopupMenu zScaleMenu,pos={239,34},size={72,19},proc=ScaleMenu,title="Z scale "
	PopupMenu zScaleMenu,mode=0,value= #"\"Scale All by:;YMAX values to:;YMAX to CsrA value;Csr A wave by:;Csr A positions to:;Csr A posns to Csr A val\""
	SetVariable gainval,pos={239,59},size={70,17},title=" "
	SetVariable gainval,help={"value used for data SCALING options"}
	SetVariable gainval,limits={-Inf,Inf,1},value= root:Tile:zgainval
	PopupMenu SpliceMenu,pos={164,86},size={63,19},proc=ExpandWaves,title="Splice"
	PopupMenu SpliceMenu,help={"combined use of OFFSET & SCALE values"}
	PopupMenu SpliceMenu,mode=0,value= #"\"to values;to Csr A wave range\""
	SetVariable styleval,pos={85,111},size={40,17},title=" "
	SetVariable styleval,help={"Start,  Inc  (or Inc) values for application of Style & Tag options"}
	SetVariable styleval,limits={0,Inf,0.1},value= root:Tile:whichstyle
	PopupMenu StyleMenu,pos={23,110},size={59,19},proc=StyleMenu,title="Style "
	PopupMenu StyleMenu,help={"Change Linestyle and/or Color of Wave Traces"}
	PopupMenu StyleMenu,mode=0,value= #"\"Auto Line;Auto Color;Line&Color;Solid/Dash:;Red/Black:;S/D & R/B:\""
	PopupMenu ResetMenu,pos={212,108},size={63,19},proc=ResetMenu,title="Reset "
	PopupMenu ResetMenu,mode=0,value= #"\"All;xShift=0;yShift=0;zOffset=0;zGain=1;\""
	PopupMenu TagMenu,pos={129,110},size={47,19},proc=TagMenu,title="Tag"
	PopupMenu TagMenu,help={"Annotate Traces with Tags derived from VAL and TXT fields.  Tag 'At ' options show an Arrow head.  "}
	PopupMenu TagMenu,mode=0,value= #"\"with VAL;with TXT;Arrow at VAL;VAL at VAL;TXT at VAL;-;Remove 'with';Remove' at';Prefs\""
	CheckBox checkAuto,pos={183,6},size={16,20},proc=CheckImgAutoApply,title=""
	CheckBox checkAuto,help={"Toggle auto-update of Table:   Select \"Delay Update\" in table to update only after clicking outside of table."},value=0
	PopupMenu yShift,pos={83,36},size={70,19},proc=ShiftMenu,title="Y shift  "
	PopupMenu yShift,mode=0,value= #"\"Shift All by:;Incremental shift by:;zMAX Positions to:;Csr Wave A Pos to:;Csr AÑ>B\""
	SetVariable yshiftval,pos={81,60},size={66,17},title=" "
	SetVariable yshiftval,help={"value used for horizontal SHIFT options"}
	SetVariable yshiftval,limits={-Inf,Inf,1},value= root:Tile:yshiftval
EndMacro
