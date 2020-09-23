// File:  Image_Tile		10/00  
// Jonathan Denlinger, JDDenlinger@lbl.gov 
// adapted from Tile

#pragma rtGlobals=1		// Use modern global access method.
#include "List_Util"			// uses List2Wave(), List2Textw() functions
#include "Tags"

//Macro 	ClearOffsets()
//Proc 	ResetImgNotes()
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
//Fct 	ImgShiftMenu() : 			PopupMenuControl
//Fct 	ImgOffsetMenu() : 			PopupMenuControl
//Fct 	ImgScaleMenu() : 			PopupMenuControl
//Fct 	StyleMenu() : 			PopupMenuControl
//Fct 	ImgResetMenu() : 			PopupMenuControl
//Fct 	ImgTileMenu() : 			PopupMenuControl
//Fct 	Expand_Waves() : 		PopupMenuControl
//Win 	TileTable() : 		Table
//Win 	TilePanel() : 		Panel

menu "2D"
	"-"
	"Tile Panel & Table!"+num2char(19), ShowTilePanel()
		help={"Tile plot manipulation; modifications are stored in individual wave notes"}
	"Reset Img Notes"
		help={"Redefine individual image notes to default (no physical resetting)"}
	"Splice Images", ImgSplice()
		help={"Splice two images together"}
end


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
		string/G winnam="", whichstyle="0,1", tilevalstr="2,2"
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


Function ImgShiftMenu(ctrlName,popNum,popStr) : PopupMenuControl
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

Function ImgOffsetMenu(ctrlName,popNum,popStr) : PopupMenuControl
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

Function ImgScaleMenu(ctrlName,popNum,popStr) : PopupMenuControl
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

Function Style_Menu(ctrlName,popNum,popStr) : PopupMenuControl
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

Proc ImgTagMenu(ctrlName,popNum,popStr) : PopupMenuControl
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
		if (exists("root:Tile:pretag")==0)
			ImgTagPrefs()
		endif
		//TagImages(tagStr, root:Tile:tilevalstr, tagAtStr, 1)
		DoWindow/F $root:Tile:winnam
		variable x0, dx, y0, dy
		GetAxis/Q left; y0=V_min; dy=V_max-V_min
		GetAxis/Q bottom; x0=V_min; dx=V_max-V_min
		
		//SVAR tilestr=root:Tile:tilevalstr
		variable m,n
		m=ValFromList(root:Tile:tilevalstr, 0, ",")
		n=ValFromList( root:Tile:tilevalstr, 1, ",")
		n=SelectNumber( numtype(n)==2, n, 1)
		variable nw=numpnts(imNAM), ii=0, xx, yy
		string imn
		DO
			imn=imNAM[ii]
			xx=1-(DimOffset( $imn, 0) - x0)/dx
			yy=1-(DimOffset( $imn, 1) - y0)/dy
			print xx, yy
			Textbox/K/N=$("it"+num2str(ii))
			//TextBox/N=$("it"+num2str(ii))/F=0/X=(100*xx)/Y=(100*yy) num2str(imVAL[ii])
			TextBox/B=1/N=$("it"+num2str(ii))/F=0/X=(100*xx)/Y=(100*yy) "\\K(64512,62423,1327)"+num2str(imVAL[ii])
			ii+=1
		WHILE(ii<nw)
	else
		if ((popNum==7)+(popNum==8))
			string tagprefix=StringFromList(popNum-7, "it;it_")
			Remove ImgTags( tagprefix, root:Tile:whichStyle )
		endif
		if (popNum==9)
			ImgTagPrefs()
		endif
	endif

	DoWindow/F $WinName(0,1)
End

Proc ImgTagPrefs(where1, where2, prefx,  postfx, fmt, color )
//---------------
	string prefx=	StrVarOrDefault("root:Tile:prefix","" )
	string postfx=	StrVarOrDefault("root:Tile:postfix","" )
	string fmt=		StrVarOrDefault("root:Tile:format","%g")
	variable where1=NumVarOrDefault("root:Tile:wheretag",1)
	variable where2=NumVarOrDefault("root:Tile:wheretag",1)
	variable color=NumVarOrDefault("root:Tile:tagcolor",1)
	prompt prefx, "Prefix string"
	prompt postfx, "Post-fix string"
	prompt where1, "Tag placement", popup, "Left;Center;Right"
	prompt where2, "Tag placement", popup, "Top;Middle;Bottom"
	prompt fmt, "Value format, e.g. '\Z09%5.3g'"
	prompt color, "Tag color", popup, "Black-on-white;White-on-Transparent"
	
	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:Tile
		string/G pretag=prefx, posttag=postfx,  tagformat=fmt
		variable/G wheretag1=where1, wheretag2=where2, tagcolor=color
	SetDataFolder curr
End



Function ImgResetMenu(ctrlName,popNum,popStr) : PopupMenuControl
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


Function ImgTileMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
// Combination of Shift and Offset
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR xval=root:Tile:xshiftval, yval=root:Tile:yshiftval
	SVAR tilestr=root:Tile:tilevalstr
	WAVE xSHIFT=root:xSHIFT, ySHIFT=root:ySHIFT
	
	variable nw, ii, m, n
	if (popNum==1)		//additional shift and stack
		xSHIFT+=xval*p; ySHIFT+=yval*p
		ApplyImgTable(ctrlName)
	endif
	if (popNum==2)		//absolute shift and stack
		xSHIFT=xval*p; ySHIFT=yval*p
		ApplyImgTable(ctrlName)
	endif
	if (popNum==3)		//auto-tile m x n
		m=ValFromList( tilestr, 0, ",")
		n=ValFromList( tilestr, 1, ",")
		n=SelectNumber( numtype(n)==2, n, 1)
		// use first image for reference
		WAVE/T imNAM=root:imNAM
		nw=numpnts(imNAM)
		
		//string imNAM0=imNAM[0]
		WAVE im0=$imNAM[0]
		xval=(DimSize(im0, 0)-1)*DimDelta(im0, 0)
		yval=(DimSize(im0, 1)-1)*DimDelta(im0, 1)
		//print im0, xval, yval
		xSHIFT=xval*mod(p, m)*sign(m)
		ySHIFT=yval*trunc(p/abs(m))*sign(n)
		ApplyImgTable(ctrlName)
	endif
	if (popNum==4)		// Transpose Images
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

Function Expand_Waves(ctrlName,popNum,popStr) : PopupMenuControl
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
	PopupMenu WinPop,pos={11,6},size={103,19},proc=SelectTileGraph,title="Win:"
	PopupMenu WinPop,mode=1,popvalue="Graph1",value= #"WinList(\"*\",\";\",\"WIN:1\")"
	Button ApplyButton,pos={201,6},size={78,19},proc=ApplyImgTable,title="ApplyTable"
	Button ApplyButton,help={"Modify traces & Write values from TileTable into Trace wave notes"}
	PopupMenu xShift,pos={9,36},size={70,19},proc=ImgShiftMenu,title="X shift  "
	PopupMenu xShift,mode=0,value= #"\"Shift All by:;Incremental shift by:;zMAX Positions to:;Csr Wave A Pos to:;Csr AÑ>B\""
	SetVariable xshiftval,pos={11,60},size={66,17},title=" "
	SetVariable xshiftval,help={"value used for horizontal SHIFT options"}
	SetVariable xshiftval,limits={-Inf,Inf,1},value= root:Tile:xshiftval
	SetVariable offsetval,pos={168,59},size={67,17},title=" "
	SetVariable offsetval,help={"value used for vertical OFFSET options"}
	SetVariable offsetval,limits={-Inf,Inf,1},value= root:Tile:zoffsetval
	PopupMenu zOffsetMenu,pos={166,34},size={71,19},proc=ImgOffsetMenu,title="Z offset"
	PopupMenu zOffsetMenu,mode=0,value= #"\"Offset All by:;Incremental stack by:;YMIN values to:;Csr A wave by:;Csr A positions to:\""
	PopupMenu TileMenu,pos={57,87},size={47,19},proc=ImgTileMenu,title="Tile"
	PopupMenu TileMenu,help={"combined use of SHIFT & OFFSET values"}
	PopupMenu TileMenu,mode=0,value= #"\"Addt'l Shift;Absolute Shift;Tile m x n;Transpose All\""
	PopupMenu zScaleMenu,pos={239,34},size={72,19},proc=ImgScaleMenu,title="Z scale "
	PopupMenu zScaleMenu,mode=0,value= #"\"Scale All by:;YMAX values to:;YMAX to CsrA value;Csr A wave by:;Csr A positions to:;Csr A posns to Csr A val\""
	SetVariable gainval,pos={239,59},size={70,17},title=" "
	SetVariable gainval,help={"value used for data SCALING options"}
	SetVariable gainval,limits={-Inf,Inf,1},value= root:Tile:zgainval
	PopupMenu SpliceMenu,pos={164,86},size={63,19},proc=ExpandWaves,title="Splice"
	PopupMenu SpliceMenu,help={"combined use of OFFSET & SCALE values"}
	PopupMenu SpliceMenu,mode=0,value= #"\"to values;to Csr A wave range\""
	SetVariable tileval,pos={112,88},size={40,17},title=" "
	SetVariable tileval,help={"Start,  Inc  (or Inc) values for application of Style & Tag options"}
	SetVariable tileval,limits={0,Inf,0.1},value= root:Tile:tilevalstr
	PopupMenu StyleMenu,pos={23,110},size={59,19},proc=Style_Menu,title="Style "
	PopupMenu StyleMenu,help={"Change Linestyle and/or Color of Wave Traces"}
	PopupMenu StyleMenu,mode=0,value= #"\"\""
	PopupMenu ResetMenu,pos={212,108},size={63,19},proc=ImgResetMenu,title="Reset "
	PopupMenu ResetMenu,mode=0,value= #"\"All;xShift=0;yShift=0;zOffset=0;zGain=1;\""
	PopupMenu TagMenu,pos={129,110},size={47,19},proc=ImgTagMenu,title="Tag"
	PopupMenu TagMenu,help={"Annotate Traces with Tags derived from VAL and TXT fields.  Tag 'At ' options show an Arrow head.  "}
	PopupMenu TagMenu,mode=0,value= #"\"with VAL;with TXT;Arrow at VAL;VAL at VAL;TXT at VAL;-;Remove 'with';Remove' at';Prefs\""
	CheckBox checkAuto,pos={183,6},size={16,20},proc=CheckImgAutoApply,title=""
	CheckBox checkAuto,help={"Toggle auto-update of Table:   Select \"Delay Update\" in table to update only after clicking outside of table."},value=0
	PopupMenu yShift,pos={83,36},size={70,19},proc=ImgShiftMenu,title="Y shift  "
	PopupMenu yShift,mode=0,value= #"\"Shift All by:;Incremental shift by:;zMAX Positions to:;Csr Wave A Pos to:;Csr AÑ>B\""
	SetVariable yshiftval,pos={81,60},size={66,17},title=" "
	SetVariable yshiftval,help={"value used for horizontal SHIFT options"}
	SetVariable yshiftval,limits={-Inf,Inf,1},value= root:Tile:yshiftval
EndMacro


Macro ImgSplice( imAnam, optA, imBnam, optB, imCnam, optC, ovlapmode, dopt )
//------------------------
	string imAnam=StrVarOrDefault("root:SPLICE:imgAnam", ""), optA=StrVarOrDefault("root:SPLICE:Aopts", "")
	string imBnam=StrVarOrDefault("root:SPLICE:imgBnam", ""), optB=StrVarOrDefault("root:SPLICE:Bopts", "")
	string imCnam=StrVarOrDefault("root:SPLICE:imgCnam", ""), optC=StrVarOrDefault("root:SPLICE:Copts", "")
	variable ovlapmode=NumVarOrDefault("root:SPLICE:overlap", 0)
	variable dopt=1
	prompt imAnam, "Image A", popup, WaveList("*",";","DIMS:2")
	prompt imBnam, "Image B", popup, WaveList("*",";","DIMS:2")
	prompt imCnam, "Output image name, <>='A_B' "
	prompt optA, "A opts: 'X=min,max;Y=min,max;Z=1;Xoff=0"
	prompt optB, "B opts: 'X=min,max;Y=min,max;Z=1;Xoff=0"
	prompt optC, "Output opts: 'X=min,max,inc;Y=min,max,inc"
	prompt ovlapmode, "Overlap region", popup, "Splice at Middle;Average;Linear Weight"
	prompt dopt, "New Display", popup, "No;Yes" 
	
	NewDataFolder/O/S root:SPLICE
		string/G imgAnam=imAnam, imgBnam=imBnam, imgCnam=imCnam
		string/G Aopts=optA, Bopts=optB, Copts=optC
		variable/G overlap=ovlapmode
	SetDataFolder root:

	optC+=";MODE="+num2str(ovlapmode)
	string cmd="Splice("+imAnam+",\""+optA+"\","+imBnam+",\""+optB+"\",\""+imCnam+"\",\""+optC+"\")"
	print cmd
	variable/C cnpt
	cnpt=Splice( $imAnam, optA, $imBnam, optB, imCnam, optC )
	print "Created: "+imCnam+"  (", Real(cnpt), "x", Imag(cnpt), ")"
	
	if (dopt==2)
		display; appendimage $imCnam
	endif
End


function/C Splice( imA, optA, imB, optB, imCnam, optC )
//========================================
// Overlap MODE: 1=splice at midvalue, 2=average, 3(4)=linear weighting along X(Y)
// Debugging: (MODE).1=return wtA, (MODE).2=return wtB
	wave imA, imB
	string optA, optB, imCnam, optC
	
	NewDataFolder/O root:SPLICE
	
	// check validity/dimension of imA, imB
	if ((WaveDims(imA)!=2)+ WaveDims(imB)!=2))
		return CMPLX(0,0)
	endif
	
	variable eps=1E-3
	// extract Xrange, Yrange, increments, nx, ny from images
	// write values to variable/ waves for debugging
	make/o root:SPLICE:AXr={DimOffset(imA,0), 1,DimDelta(imA,0), DimSize(imA,0)}
	make/o root:SPLICE:AYr={DimOffset(imA,1), 1,DimDelta(imA,1), DimSize(imA,1)}
	make/o root:SPLICE:BXr={DimOffset(imB,0), 1,DimDelta(imA,0), DimSize(imB,0)}
	make/o root:SPLICE:BYr={DimOffset(imB,1), 1,DimDelta(imA,1), DimSize(imB,1)}
	WAVE AXr=root:SPLICE:AXr, AYr=root:SPLICE:AYr
	WAVE BXr=root:SPLICE:BXr, BYr=root:SPLICE:BYr
	AXr[1]=AXr[0]+AXr[2]*(AXr[3]-1)-eps
	AYr[1]=AYr[0]+AYr[2]*(AYr[3]-1)-eps
	BXr[1]=BXr[0]+BXr[2]*(BXr[3]-1)-eps
	BYr[1]=BYr[0]+BYr[2]*(BYr[3]-1)-eps
	
	
	//extract desired Xrange, Yrange, Intensity, Xoffset from optA, optB
	string AXrng=StringByKey("X", optA, "="), AYrng=StringByKey("Y", optA, "=")
	variable AZ=NumberByKey("Z", optA, "="), AXoff=NumberByKey("XOFF", optA, "=")
	string BXrng=StringByKey("X", optB, "="), BYrng=StringByKey("Y", optB, "=")
	variable BZ=NumberByKey("Z", optB, "="), BXoff=NumberByKey("XOFF", optB, "=")
	//Perform offset at Widget level to visually see effect??
	
	//Defaults
	AZ=SelectNumber(numtype(AZ)==2, AZ, 1)		// default if not present (NaN)
	BZ=SelectNumber(numtype(BZ)==2, BZ, 1)
	AXoff=SelectNumber(numtype(AXoff)==2, AXoff, 0)	
	BXoff=SelectNumber(numtype(BXoff)==2, BXoff, 0)
	
	//Add offsets to Xranges:
	AXr[0]+=AXoff;   AXr[1]+=AXoff
	BXr[0]+=BXoff;  BXr[1]+=BXoff
	
	// Full range of image if not specified
	AXrng=SelectString(strlen(AXrng)==0, AXrng, Wave2List( AXr, ",", 0, 1 ))
	AYrng=SelectString(strlen(AYrng)==0, AYrng, Wave2List( AYr, ",", 0, 1 ))
	BXrng=SelectString(strlen(BXrng)==0, BXrng,Wave2List( BXr, ",", 0, 1 ))
	BYrng=SelectString(strlen(BYrng)==0, BYrng,Wave2List( BYr, ",", 0, 1 ))
	
	//Determine Full A+B desired range with min increment
	// treat case that increment overshoots max value
	make/o root:SPLICE:ABXr={min(AXr[0],BXr[0]), max(AXr[1],BXr[1]), min(AXr[2],BXr[2])}
	make/o root:SPLICE:ABYr={min(AYr[0],BYr[0]), max(AYr[1],BYr[1]), min(AYr[2],BYr[2])}
	WAVE ABXr=root:SPLICE:ABXr, ABYr=root:SPLICE:ABYr
	print "X-range:", ABXr[0], ABXr[1]
	
	//Determine Overlap A-B range 
	make/o root:SPLICE:OXr={max(AXr[0],BXr[0]), min(AXr[1],BXr[1])}
	make/o root:SPLICE:OYr={max(AYr[0],BYr[0]), min(AYr[1],BYr[1])}
	WAVE OXr=root:SPLICE:OXr, OYr=root:SPLICE:OYr
	print "X-overlap:", OXr[0], OXr[1]
	
	//extract Xrange, Yrange,  overlapmode, from optC
	variable overlap=NumberByKey("MODE", optC, "=")
	string CXrng=StringByKey("X", optC, "="), CYrng=StringByKey("Y", optC, "=")
	//Defaults
	overlap=SelectNumber(numtype(overlap)==2, overlap, 0)		// default if not specified (NaN)
	// Full A+B range of image if not specified
	CXrng=SelectString(strlen(CXrng)==0, CXrng, Wave2List( ABXr, ",", 0, 2 ))
	CYrng=SelectString(strlen(CYrng)==0, CYrng, Wave2List( ABYr, ",", 0, 2 ))

	List2Wave( CXrng,",", "root:SPLICE:CXr" )
	List2Wave( CYrng,",", "root:SPLICE:CYr" )
	WAVE CXr=root:SPLICE:CXr, CYr=root:SPLICE:CYr
	//calculate nx, ny
	variable CXnp, CYnp
	CXnp=round(abs(CXr[1]-CXr[0])/CXr[2]) + 1
	CYnp=round(abs(CYr[1]-CYr[0])/CYr[2]) + 1
	
	//create output image, scale axes
	imCnam=SelectString(strlen(imCnam)==0, imCnam, "tmp")
	Make/O/N=(CXnp, CYnp) $imCnam
	WAVE imC=$imCnam
	//SetScale/P x CXr[0], CXr[2], "" imC
	//SetScale/P y CYr[0], CYr[2], "" imC
	SetScale/I x CXr[0], CXr[1], "" imC
	SetScale/I y CYr[0], CYr[1], "" imC
	
	//Create A & B weighting images
	Duplicate/o imC, root:SPLICE:wtA, root:SPLICE:wtB
	WAVE wtA= root:SPLICE:wtA, wtB= root:SPLICE:wtB
	
	variable debug=trunc(10*(overlap-trunc(overlap)))
	//debug=1
	overlap=trunc(overlap)
	if (overlap==1)	//Splice at midway
		//shrink A and B ranges
		AXr[1]=0.5*(OXr[0]+OXr[1])		//covers all cases?
		BXr[0]=0.5*(OXr[0]+OXr[1])
	endif
	wtA=AZ*RNG(AXr,x)*RNG(AYr,y)
	wtB=BZ*RNG(BXr,x)*RNG(BYr,y)
	if (overlap==2)		//Average
		wtA*=SelectNumber( RNG(OXr,x)*RNG(OYr,y),1, 0.5 )
		wtB*=SelectNumber( RNG(OXr,x)*RNG(OYr,y),1, 0.5 )
	endif
	if (overlap==3)		//Fractional linear weighting along X
		wtA*=SelectNumber( RNG(OXr,x)*RNG(OYr,y),1, 1-FRAC(OXr,x) )
		wtB*=SelectNumber( RNG(OXr,x)*RNG(OYr,y),1, FRAC(OXr,x) )
	endif
	if (overlap==4)		//Fractional linear weighting along Y
		wtA*=SelectNumber( RNG(OXr,x)*RNG(OYr,y),1, 1-FRAC(OYr,y) )
		wtB*=SelectNumber( RNG(OXr,x)*RNG(OYr,y),1, FRAC(OYr,y) )
	endif
	
	//interpolate with appropriate weighting
	if (debug>0)
		imC=SelectNumber( debug-1, wtA, wtB)
	else
		imC=0
		imC=wtA(x)(y)*imA(x-Axoff)(y) + wtB(x)(y)*imB(x-Bxoff)(y)
	endif

	return CMPLX(CXnp, CYnp)
end

function RNG( wrang, val )
//===================
// return 0(1) if val is outside (inside) range specified by wrang={min, max, ..}
	wave wrang
	variable val
	return(val>=wrang[0])*(val<=wrang[1])
end

function FRAC( wrang, val )
//===================
// return 0(frac) if val is outside (inside) range specified by wrang={min, max, ..}
// frac=fractional distance from lower limit
	wave wrang
	variable val
	variable frac=(val>=wrang[0])*(val<=wrang[1])
	if (frac==1)		//within range
		frac=abs((val-wrang[0])/(wrang[1]-wrang[0]))
	endif
	return frac
end

Window SpliceTable() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:SPLICE:
	Edit/W=(177,89,857,254) AXr,BXr,OXr,ABXr,CXr,BYr,AYr,OYr,ABYr,CYr
	ModifyTable width(Point)=16,width(AXr)=66,width(BXr)=68,width(OXr)=60,width(ABXr)=60
	ModifyTable width(CXr)=60,width(BYr)=62,width(AYr)=66,width(OYr)=66,width(ABYr)=68
	ModifyTable width(CYr)=50
	SetDataFolder fldrSav
EndMacro
