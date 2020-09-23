// File:  ImageMath    10/00 JDD
//  adapted from WaveMath
// Changes: 

#pragma rtGlobals=1		// Use modern global access method.
#include "image_util"		// uses Img_Info(), ReadImgNote(), WriteimgNote()

//Proc 	ShowImageMath()
//Fct 	SelectMathGraph() : 	PopupMenuControl
//Fct 	ApplyImgMath() : 			SetVariableControl
//Fct 	MakeScaledWave()
//Fct 	SelectOperation() : 		PopupMenuControl
//Fct 	ToggleAppend() : 		CheckBoxControl
//Proc 	SelectWave() : 			PopupMenuControl  -Fct had update problems of wave tmp
//Fct		InfoBox() : 				ButtonControl
//Win 	ImageMathPanel() : 		Panel

menu "2D"
	"-"
	"Show Image Math!"+num2char(19)
end

Proc ShowImageMath()
//---------------
//Macro InitModify()
	//NewDataFolder/O tmp
	NewDataFolder/O/S root:imgmath
	//string/G winnam=""
	//variable/G xshift1=0, yshift1=0, zoff1=0, zgain1=1
	//variable/G xshift2=0, yshift2=0, zoff2=0, zgain2=1
	variable/G rad_polmask=0
	variable/G op=1, append_opt=0
	String/G opstr="A-B"
	String/G imNamA="<>", imNamB="<>"	//, imNamC="<none>"
	make/o/n=(50,50) imA, imB, imC
	imA=cos((pi/10)*(x-25))
	imB=cos((pi/10)*(y-25))
	imC=imA-imB
	NewDataFolder/O/S root:imgmath:imA
		Img_Info( root:imgmath:imA, "/VAR=root:imgmath:imA" )
		variable/G xshift=0, yshift=0, zoff=0, zgain=1
	NewDataFolder/O/S root:imgmath:imB
		Img_Info( root:imgmath:imB, "/VAR=root:imgmath:imB" )
		variable/G xshift=0, yshift=0, zoff=0, zgain=1
	NewDataFolder/O/S root:imgmath:imC
		Img_Info( root:imgmath:imC, "/VAR=root:imgmath:imC" )
		variable/G xshift=0, yshift=0, zoff=0, zgain=1
	
	SetDataFolder root:
	DoWindow/F ImageMathPanel
	if (V_flag==0)
		ImageMathPanel()
		ModifyImage imA ctab= {*,*,Grays,0}
		ModifyImage imB ctab= {*,*,Grays,0}
		ModifyImage imC ctab= {*,*,Grays,0}
	endif
End

Function SelectMathWin(ctrlName,popNum,popStr) : PopupMenuControl
//================
	String ctrlName
	Variable popNum
	String popStr
	SVAR dwn=root:imgmath:imNamC, gnam=root:imgmath:winnam

	gnam=popStr
	dwn="<none>"
	DoWindow/F $popStr
	DoWindow/F ImageMathPanel
End

Function ApplyImgMath(ctrlName,varNum,varStr,varName) : SetVariableControl
//==============
//
	String ctrlName
	Variable varNum
	String varStr, varName
		string fldrSav=GetDataFolder(1)

	NVAR  zoffA=root:imgmath:imA:zoff,  zgainA=root:imgmath:imA:zgain
	NVAR  zoffB=root:imgmath:imB:zoff, zgainB=root:imgmath:imB:zgain
	NVAR  dminC=root:imgmath:imC:dmin, dmaxC=root:imgmath:imC:dmax
	SetDataFolder root:imgmath
	NVAR op=op
	WAVE imA=imA, imB=imB, imC=imC

	// Create destination image

 	if (op==1) 
 		//imC=imA-imB
 		imC=(zgainA*imA-zoffA) - (zgainB*imB-zoffB)
 	endif
 	if (op==2) 
 		imC=(imA - imB )  / (imA + imB )
 	endif
 	if (op==3) 
 		//imC=imA[p][q] / imB[p][q]
 		imC=imA/ imB
 		
 	endif
 	if (op==4) 
 		//imC=imA / imB -1.
 		//imC=(zgainA*imA+zoffA)/(zgainB*imB+zoffB)
 		imC=(imA+zoffA)/(imB+zoffB)
 	endif
 	if (op==5) 
 		imC=imA + imB
 	endif
 	WaveStats/Q imC
 	dminC=V_min
 	dmaxC=V_max
	SetDataFolder $fldrSav
End

Function ApplyImgMath0(ctrlName,varNum,varStr,varName) : SetVariableControl
//==============
//
	String ctrlName
	Variable varNum
	String varStr, varName
		string fldrSav=GetDataFolder(1)
		SetDataFolder root:imgmath
			
	NVAR xshft1=xshift1, yshft1=yshift1, zoff1=zoff1, zscl1=zgain1
	NVAR xshft2=xshift2, yshft2=yshift2, zoff2=zoff2, zscl2=zgain2
	NVAR op=op, app=append_opt
	SVAR gnam=winnam, imnA=imNamA, imnB=imNamB, imnC=imNamC
	 	SetDataFolder fldrSav
	// string wvnAx=XWaveName(gnam, imnA), wvnBx=XWaveName(gnam, imnB)
	WAVE imA=$imnA, imB=$imnB
	
	xshft1*=(abs(xshft1)>1E-8); yshft1*=(abs(yshft1)>1E-8)		//remove rounding error for near-zero value
	xshft2*=(abs(xshft2)>1E-8); yshft2*=(abs(yshft2)>1E-8)	
	
	 zscl1=SelectNumber(  zscl1==0, zscl1, 1E-8)		//prevent gain from being exactly zero
	 zscl2=SelectNumber(  zscl2==0, zscl2, 1E-8)
	
	//print ctrlName, varNum, varStr, varName
 	//print "apply math:"+imnA+"--/+"[op-1]+imnB+"="+dwn
 	
 	//Modify input waves A & B; write mod to wave notes
 	string modlst, txt
 	variable xshift0, yshift0, zoffset0, zgain0, val
 	if (strsearch(ctrlName,"1", 0)>0)
 		modlst=ReadImgNote( imA )	
	 		xshift0=NumberByKey("xShift", modlst, "=", "," )
	 		yshift0=NumberByKey("yShift", modlst, "=", "," )
	 		zoffset0=NumberByKey("zOffset", modlst, "=", "," )
		 	zgain0=NumberByKey("zGain", modlst, "=", "," )
		 	val=NumberByKey("Val", modlst, "=", "," )
		 	txt=StringByKey("Txt", modlst, "=", "," )
		imA = (zscl1/zgain0) * ( imA - zoffset0) + zoff1
 		SetScale/P x DimOffset(imA,0)+(xshft1-xshift0), DimDelta(imA,0), waveunits(imA, 0) imA
 		SetScale/P y DimOffset(imA,1)+(yshft1-yshift0), DimDelta(imA,0), waveunits(imA, 0) imA
 		WriteImgNote( imA, xshft1, yshft1, zoff1, zscl1, val, txt )
 	endif
 	if (strsearch(ctrlName,"2", 0)>0)
 		//List2Wave( note(imB), ",", "tmp" )
 		//ReadImgNote( imB, "root:imgmath:tmp")
		//Wave tmp=root:imgmath:tmp
		modlst=ReadImgNote( imB )	
	 		xshift0=NumberByKey("xShift", modlst, "=", "," )
	 		yshift0=NumberByKey("yShift", modlst, "=", "," )
	 		zoffset0=NumberByKey("zOffset", modlst, "=", "," )
		 	zgain0=NumberByKey("zGain", modlst, "=", "," )
		 	val=NumberByKey("Val", modlst, "=", "," )
		 	txt=StringByKey("Txt", modlst, "=", "," )
		//print imnB, XWaveName("", imnB), tmp[0]
		imB = (zscl2/zgain0) * ( imB -zoffset0 ) + zoff2
		SetScale/P x DimOffset(imB,0)+(xshft2-xshift0), DimDelta(imB,0), waveunits(imB, 0) imB
 		SetScale/P y DimOffset(imB,1)+(yshft2-yshift0), DimDelta(imB,0), waveunits(imB, 0) imB
 		WriteImgNote( imB, xshft2, yshft2, zoff2, zscl2, val, txt )
 	endif
 	
 	//Destination Wave: check if exists and right length & scaling
 	//     if not create
 	if (cmpstr(imnC,"<none>")==0)
		abort
	endif
	// Create destination image
	variable nx, ny
	nx=DimSize( imA,0); ny=DimSize(imA,1)
	make/o/N=(nx,ny) $imnC
	//duplicate/o imA $imnC
 	WAVE imC=$imnC
 	if (1)			//same image sizes
	 	if (op==1) 
	 		imC=imA-imB
	 	endif
	 	if (op==2) 
	 		imC=(imA - imB )  / (imA + imB )
	 	endif
	 	if (op==3) 
	 		//imC=imA[p][q] / imB[p][q]
	 		imC=imA/ imB
	 	endif
	 	if (op==4) 
	 		imC=imA / imB -1.
	 	endif
	 	if (op==5) 
	 		imC=imA + imB
	 	endif
	else
	 	if (op==1) 
	 		imC=imA - interp( x, imBx, imB )
	 	endif
	 	if (op==2) 
	 		imC=(imA - interp( x, imBx, imB ) ) / (imA + interp( x, imBx, imB ) )
	 	endif
	 	if (op==3) 
	 		imC=imA / interp( x, imBx, imB )
	 	endif
	 	if (op==4) 
	 		imC=imA / interp( x, imBx, imB ) -1.
	 	endif
	 	if (op==5) 
	 		imC=imA + interp( x, imBx, imB )
	 	endif
 	endif
 	Img_Info( root:imgmath:imC, "/VAR=root:imgmath:imC" )
End

Function MakeScaledWave( refw, refwx,  outwn )
//==================
//creates scaled output wave based on y & x reference waves
// scaling assumes x-wave is monotonic increasing
	wave refw, refwx
	string outwn
	duplicate/o refw $outwn
	WaveStats/Q refwx
	SetScale/I x V_min, V_max,"" $outwn
	Note/K $outwn
	Note $outwn, "0,0,1,0,1,0,0"	
End

Proc SelectOperation(ctrlName,popNum,popStr) : PopupMenuControl
//=================
	String ctrlName
	Variable popNum
	String popStr

	string fldrSav=GetDataFolder(1)
	SetDataFolder root:imgmath
	//NVAR op=op
	//SVAR opstr=opstr
	//WAVE imA=imA, imB=imB, imC=imC
	op=popNum
	opstr=popStr
	
	Textbox/C/N=imCop "\\{root:imgmath:opstr}"
	 if (op==1) 
 		imC:=imA-imB
 	endif
 	if (op==2) 
 		imC:=(imA - imB )  / (imA + imB )
 	endif
 	if (op==3) 
 		//imC=imA[p][q] / imB[p][q]
 		imC:=imA/ imB
 		
 	endif
 	if (op==4) 
 		//imC:=imA / imB -1.
 		imC:=(imA+root:imgmath:imA:zoff)/(imB+root:imgmath:imB:zoff)
 		Textbox/C/N=imCop "\\{root:imgmath:opstr}: a,b=\\{root:imgmath:imA:zoff}, \\{root:imgmath:imB:zoff}"
 	endif
 	if (op==5) 
 		imC:=imA + imB
 	endif
 	Img_Info( root:imgmath:imC, "/VAR=root:imgmath:imC" )
	//ApplyImgMath("",0,"","")
End

Function ToggleAppend(ctrlName,checked) : CheckBoxControl
//===============
	String ctrlName
	Variable checked
	NVAR app=root:imgmath:append_opt
	app=checked	
End

Proc AppendMath(ctrlName,popNum,popStr) : PopupMenuControl
//=================================
	String ctrlName
	Variable popNum
	String popStr

	//DoWindow/F $root:imgmath:winnam
 	//Check if displayed; append to plot if requested
 	//CheckDisplayed/W=$root:imgmath:winnam $root:imgmath:imNamC
 	if (V_flag==0)
	 	if (popNum==1)
	 		AppendToGraph $root:imgmath:imNamC
	 	endif
	 	if (popNum==2)
	 		AppendToGraph/L=above $root:imgmath:imNamC
	 		ModifyGraph axisEnab(left)={0,0.73},axisEnab(above)={0.77,1},freePos(above)=0
			ModifyGraph tick(above)=2,zero(above)=1, mirror(above)=2
	 	endif
	 	if (popNum==3)
	 		AppendToGraph/L=below $root:imgmath:imNamC
	 		ModifyGraph axisEnab(left)={0.27,1},axisEnab(below)={0,0.23},freePos(below)=0
			ModifyGraph tick(below)=2,zero(below)=1, mirror(below)=2
	 	endif
 	endif
 	if ((V_flag==1)*popNum==4))
 		RemoveFromGraph $root:imgmath:imNamC
 		ModifyGraph axisEnab(left)={0,1}
 	endif
End

Proc SelectImage(ctrlName,popNum,popStr) : PopupMenuControl
//==============
//Select A or B wave; read wave note and write to global variables
	String ctrlName
	Variable popNum
	String popStr
	//print ctrlName, popStr
	string modlst
	//modlst=ReadImgNote( $popStr )	
	//ReadImgNote( $popstr, "root:imgmath:tmp" )

	string fldrSav=GetDataFolder(1)
	
	if (cmpstr(ctrlName,"WaveOut")==0)
		variable match=( cmpstr(popStr, imNamA)==0 ) + (cmpstr(popStr, imNamB)==0 )
		print match
		imNamC=SelectString( match==0, "<none>", popstr)
	else
		if (cmpstr(ctrlName,"ImageA")==0)
			duplicate/o $popStr root:imgmath:imA
			Redimension/S root:imgmath:imA
			modlst=ReadImgNote( $popStr )	
			//SetDataFolder root:imgmath
			Img_Info($popStr, "/VAR=root:imgmath:imA")
			root:imgmath:imNamA=popStr
			SetDataFolder root:imgmath:imA
			xshift=NumberByKey("xShift", modlst, "=", "," )
			yshift=NumberByKey("yShift", modlst, "=", "," )
			zoff=NumberByKey("zOffset", modlst, "=", "," )
			zgain=NumberByKey("zGain", modlst, "=", "," )
			
			Redimension/N=(nx, ny) root:imgmath:imC
			SetDataFolder fldrSav
			ModifyImage imA ctab= {*,*,Grays,0}
			ModifyImage imC ctab= {*,*,Grays,0}
			
			//ApplyImgMath("1",0,"","")
		else
			duplicate/o $popStr root:imgmath:imB
			Redimension/S root:imgmath:imB
			modlst=ReadImgNote( $popStr )	
			//SetDataFolder root:imgmath
			Img_Info( $popStr, "/VAR=root:imgmath:imB")
			root:imgmath:imNamB=popStr
			SetDataFolder root:imgmath:imB
			xshift=NumberByKey("xShift", modlst, "=", "," )
			yshift=NumberByKey("yShift", modlst, "=", "," )
			zoff=NumberByKey("zOffset", modlst, "=", "," )
			zgain=NumberByKey("zGain", modlst, "=", "," )

			SetDataFolder fldrSav
			ModifyImage imB ctab= {*,*,Grays,0}
			//ApplyImgMath("2",0,"","")
		endif
	endif
	//SetDataFolder root:
End

Function SelectWavef(ctrlName,popNum,popStr) : PopupMenuControl
//==============
//Select A or B wave; read wave note and write to global variables
	String ctrlName
	Variable popNum
	String popStr
	//print ctrlName, popStr
	
	string modlst
	if (cmpstr(ctrlName,"WaveA")==0)
		NVAR shft1=xshift1, off1=zoff1, scl1=zgain1
		SVAR imnA=imNamA
		WAVE wvA=$imnA 
		imnA=popStr
		// ReadImgNote( wvA, "tmp" )
		//WAVE tmp=tmp
		//shft1=tmp[0]; off1=tmp[1]; scl1=tmp[2]
		modlst=ReadImgNote( wvA )
		shft1=NumberByKey("Shift", modlst, "=", "," )
		off1=NumberByKey("Offset", modlst, "=", "," )
		scl1=NumberByKey("Gain", modlst, "=", "," )
		ApplyImgMath("1",0,"","")
	else
		NVAR shft2=xshift2, off2=zoff2, scl2=zgain2
		SVAR imnB=imNamB
		WAVE wvB=$imnB
		imnB=popStr
		//ReadImgNote( wvB, "tmp" )
		//WAVE tmp=tmp
		//shft2=tmp[0]; off2=tmp[1]; scl2=tmp[2]
		modlst=ReadImgNote( wvB )
		shft2=NumberByKey("Shift", modlst, "=", "," )
		off2=NumberByKey("Offset", modlst, "=", "," )
		scl2=NumberByKey("Gain", modlst, "=", "," )
		ApplyImgMath("2",0,"","")
	endif
End

Function InfoBox(ctrlName) : ButtonControl
//--------------
	String ctrlName
	SVAR imnA=root:imgmath:imNamA, imnB=root:imgmath:imNamB, dwn=root:imgmath:imNamC
	NVAR op=root:imgmath:op
	//DoWindow/F  no graph global -- assume top graph
	string modlst

	string txt
	txt="\s("+imnA+") "+imnA+" : "
		modlst=ReadImgNote( $imnA )
		txt+=StringByKey("Shift", modlst, "=", "," )+", "
		txt+=StringByKey("Offset", modlst, "=", "," )+", "
		txt+=StringByKey("Gain", modlst, "=", "," )
	txt+="\r\s("+imnB+") "+imnB+" : "
		modlst=ReadImgNote( $imnB )
		txt+=StringByKey("Shift", modlst, "=", "," )+", "
		txt+=StringByKey("Offset", modlst, "=", "," )+", "
		txt+=StringByKey("Gain", modlst, "=", "," )
	txt+="\r\s("+dwn+") "+dwn+" = A"+"--//"[op-1]+"B"
	if (op==2)
		txt+="/(A+B)"
	endif
	if (op==4)
		txt+="-1"
	endif
	//print txt
	TextBox/K/N=MathInfo
	TextBox/N=MathInfo/F=0/A=LT txt
	
End

Window ImageMathPanel() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(309.75,63.5,798,346.25) as "Image Math"
	AppendImage :imgmath:imA
	ModifyImage imA ctab= {*,*,Grays,0}
	AppendImage/B=xB/L=yB :imgmath:imB
	ModifyImage imB ctab= {*,*,Grays,0}
	AppendImage/B=xC/L=yC :imgmath:imC
	ModifyImage imC ctab= {0.93350887298584,4,Grays,0}
	ModifyGraph cbRGB=(577,43860,60159)
	ModifyGraph mirror=0
	ModifyGraph nticks(yB)=0,nticks(yC)=0
	ModifyGraph fSize=9
	ModifyGraph standoff(left)=0,standoff(bottom)=0
	ModifyGraph axOffset(left)=-4.28571
	ModifyGraph axThick=0.5
	ModifyGraph lblPos(left)=29,lblPos(bottom)=3
	ModifyGraph freePos(yB)={0,xB}
	ModifyGraph freePos(xB)=0
	ModifyGraph freePos(yC)={0,xC}
	ModifyGraph freePos(xC)=0
	ModifyGraph axisEnab(bottom)={0,0.32}
	ModifyGraph axisEnab(xB)={0.33,0.66}
	ModifyGraph axisEnab(xC)={0.67,1}
	Textbox/N=imAnam/F=0/S=3/H=14/A=MT/X=-30.22/Y=2.84/E "\\{root:imgmath:imA:imgnam}"
	Textbox/N=imBnam/F=0/S=3/H=14/A=MT/X=-1.20/Y=2.27/E "\\{root:imgmath:imB:imgnam}"
	Textbox/N=imCop/F=0/S=3/H=14/A=MT/X=29.81/Y=2.19/E
	AppendText "\\{root:imgmath:opstr}: a,b=\\{root:imgmath:imA:zoff}, \\{root:imgmath:imB:zoff}"
	ShowTools
	ControlBar 119
	PopupMenu ImageA,pos={47,6},size={85,21},proc=SelectImage,title="A:"
	PopupMenu ImageA,mode=5,popvalue="cu17",value= #"WaveList(\"!*_x\", \";\", \"DIMS:2\")"
	PopupMenu ImageB,pos={155,6},size={85,21},proc=SelectImage,title="B:"
	PopupMenu ImageB,mode=6,popvalue="cu20",value= #"WaveList(\"!*_x\", \";\", \"DIMS:2\")"
	SetVariable zOffset1,pos={26,44},size={100,16},proc=ApplyImgMath,title=" offset"
	SetVariable zOffset1,fSize=9,limits={-Inf,Inf,1},value= root:imgmath:imA:zoff
	SetVariable zGain1,pos={36,59},size={90,16},proc=ApplyImgMath,title="gain"
	SetVariable zGain1,fSize=9,limits={-Inf,Inf,0.01},value= root:imgmath:imA:zgain
	SetVariable zOffset2,pos={171,44},size={60,16},proc=ApplyImgMath,title=" "
	SetVariable zOffset2,fSize=9,limits={-Inf,Inf,1},value= root:imgmath:imB:zoff
	SetVariable zGain2,pos={171,60},size={60,16},proc=ApplyImgMath,title=" ",fSize=9
	SetVariable zGain2,limits={-Inf,Inf,0.01},value= root:imgmath:imB:zgain
	PopupMenu Operation,pos={268,7},size={122,21},proc=SelectOperation,title="C ="
	PopupMenu Operation,mode=4,popvalue="(A+a)/(B+b)",value= #"\"A - B;(A-B)/(A+B);A / B;(A+a)/(B+b);A + B\""
	Button ExportImg,pos={307,48},size={50,18},proc=ExportImgMathAction,title="Export"
	ValDisplay nxA,pos={63,26},size={25,16},fSize=9,frame=0
	ValDisplay nxA,limits={0,0,0},barmisc={0,1000},value= #"root:imgmath:imA:nx"
	ValDisplay nyA,pos={87,26},size={35,16},title=" x",fSize=9,frame=0
	ValDisplay nyA,limits={0,0,0},barmisc={0,1000},value= #"root:imgmath:imA:ny"
	ValDisplay nxB,pos={165,26},size={25,16},fSize=9,frame=0
	ValDisplay nxB,limits={0,0,0},barmisc={0,1000},value= #"root:imgmath:imB:nx"
	ValDisplay nyB,pos={189,26},size={35,16},title=" x",fSize=9,frame=0
	ValDisplay nyB,limits={0,0,0},barmisc={0,1000},value= #"root:imgmath:imB:ny"
	SetVariable dminA,pos={30,79},size={50,16},proc=Adjust_CT,title=" ",fSize=9
	SetVariable dminA,limits={-Inf,Inf,1},value= root:imgmath:imA:dmin
	SetVariable dmaxA,pos={81,79},size={50,16},proc=Adjust_CT,title=" ",fSize=9
	SetVariable dmaxA,limits={-Inf,Inf,1},value= root:imgmath:imA:dmax
	SetVariable dminB,pos={153,80},size={50,16},proc=Adjust_CT,title=" ",fSize=9
	SetVariable dminB,limits={-Inf,Inf,1},value= root:imgmath:imB:dmin
	SetVariable dmaxB,pos={204,80},size={50,16},proc=Adjust_CT,title=" ",fSize=9
	SetVariable dmaxB,limits={-Inf,Inf,1},value= root:imgmath:imB:dmax
	PopupMenu popA,pos={61,94},size={59,21},proc=ImgMathFilter,title="Filter"
	PopupMenu popA,mode=0,value= #"\"Autoscale;PolarMask\""
	PopupMenu popB,pos={176,95},size={59,21},proc=ImgMathFilter,title="Filter"
	PopupMenu popB,mode=0,value= #"\"Autoscale;PolarMask\""
	SetVariable dminC,pos={282,79},size={50,16},proc=Adjust_CT,title=" ",fSize=9
	SetVariable dminC,limits={-Inf,Inf,1},value= root:imgmath:imC:dmin
	SetVariable dmaxC,pos={334,79},size={50,16},proc=Adjust_CT,title=" ",fSize=9
	SetVariable dmaxC,limits={-Inf,Inf,1},value= root:imgmath:imC:dmax
	PopupMenu popC,pos={305,95},size={59,21},proc=ImgMathFilter,title="Filter"
	PopupMenu popC,mode=0,value= #"\"Autoscale;PolarMask\""
	SetVariable setvar0,pos={397,8},size={70,16},title="rad",fSize=9
	SetVariable setvar0,limits={-Inf,Inf,1},value= root:imgmath:rad_polmask
EndMacro


Proc ExportImgMathAction(ctrlName) : ButtonControl
//======================
	String ctrlName
	
	//if (stringmatch(ctrlName,"ExportImg"))
		ExportImgMath(  )			//prompt for export name & options
	//endif
End

Proc ExportImgMath( exportn, eopt, dopt )
//======================
	String exportn=StrVarOrDefault( "root:IMGMATH:exportn", "")
	variable eopt=NumVarOrDefault( "root:IMGMATH:exportopt", 1), dopt=NumVarOrDefault( "root:IMGMATH:dispopt", 1)
	prompt eopt, "Export", popup, "Image C"
	prompt dopt, "Option", popup, "Display C;Display A,B,C;Append C"
	
	string/G root:IMGMATH:exportn=exportn 
	variable/G root:IMGMATH:exportopt=eopt, root:IMGMATH:dispopt=dopt
	//NVAR dmin=root:IMGMATH:dmin,dmax=root:IMGMATH:dmax
	
	SetDataFolder root:
	PauseUpdate; Silent 1
	

		//Duplicate/o root:imgmath:ImC_CT $(exportn+"_CT")
			//** use only subset from graph axes	
			GetAxis/Q xC 
			variable left=V_min, right=V_max
			GetAxis/Q yC
			variable bottom=V_min, top=V_max
			Duplicate/O/R=(left,right)(bottom,top) root:imgmath:ImC, $exportn
			
			string imgnote="IMGMATH:OP="+root:imgmath:opstr
			imgnote+=",A="+root:imgmath:imNamA+",B="+root:imgmath:imNamB
			if (root:imgmath:op==4)
				imgnote+=",a="+ num2str(root:imgmath:imA:zoff)+",b="+num2str(root:imgmath:imB:zoff)
			endif
			Note $exportn, imgnote
			
		if (dopt==1)
			variable dmin=root:imgmath:imC:dmin, dmax=root:imgmath:imC:dmax
			Display; Appendimage $exportn
			//execute "ModifyImage "+exportn+" cindex= "+exportn+"_CT"
			execute "ModifyImage "+exportn+" ctab= {"+num2str(dmin)+", "+num2str(dmax)+", Grays,0}"
		//	SetDataFolder root:
		//	ModifyImage newimg ctab= {dmin, dmax, YellowHot,0}   //doesn't work?	
			//string titlestr=exportn+": "+num2istr(DimSize($exportn,0))+" x "+num2str(DimSize($exportn,1))
			string titlestr=root:imgmath:opstr
			if (root:imgmath:op==4)
				titlestr+= ", a,b="+num2str(root:imgmath:imA:zoff)+","+num2str(root:imgmath:imB:zoff)
			endif
			Textbox/N=title/F=0/A=MT/E titlestr
			
			string winnam=exportn+"_"
			DoWindow/F $winnam
			if (V_Flag==1)
				DoWindow/K $winnam
			endif
			DoWindow/C $winnam
		endif
		if (dopt==2)
			Display /W=(301.5,50.75,789.75,333.5)
			AppendImage $root:imgmath:imNamA
			ModifyImage $root:imgmath:imNamA ctab= {root:imgmath:imA:dmin,root:imgmath:imA:dmax,Grays,0}
			AppendImage/B=xB/L=yB $root:imgmath:imNamB
			ModifyImage $root:imgmath:imNamB ctab= {root:imgmath:imB:dmin,root:imgmath:imB:dmax,Grays,0}
			AppendImage/B=xC/L=yC $exportn
			ModifyImage $exportn ctab= {root:imgmath:imC:dmin,root:imgmath:imC:dmax,Grays,0}
			Textbox/N=imAnam/F=0/S=3/H=14/A=MT/X=-30.22/Y=2.84/E "A: "+root:imgmath:imNamA
			Textbox/N=imBnam/F=0/S=3/H=14/A=MT/X=-1.20/Y=2.27/E "B: "+root:imgmath:imNamB
			Textbox/N=imCnam/F=0/S=3/H=14/A=MT/X=29.81/Y=2.19/E exportn+"="+root:imgmath:opstr
			if (root:imgmath:op==4)
				AppendText/N=imCnam "\JCa,b="+num2str(root:imgmath:imA:zoff)+","+num2str(root:imgmath:imB:zoff)
			endif

			ImageMathStyle()
		//	SetDataFolder root:
		//	ModifyImage newimg ctab= {dmin, dmax, YellowHot,0}   //doesn't work?	
			//string titlestr=exportn+": "+num2istr(DimSize($exportn,0))+" x "+num2str(DimSize($exportn,1))
			string titlestr=root:imgmath:opstr
			//Textbox/N=title/F=0/A=MT/E titlestr
			
			string winnam=exportn+"_"
			DoWindow/F $winnam
			if (V_Flag==1)
				DoWindow/K $winnam
			endif
			DoWindow/C $winnam
		endif
End




Function Adjust_CT(ctrlName,varNum,varStr,varName) : SetVariableControl
//===============
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	if (stringmatch( ctrlName, "*A"))
		NVAR dmin=root:imgmath:imA:dmin, dmax=root:imgmath:imA:dmax
		WAVE im=root:imgmath:imA
		ModifyImage imA ctab={dmin, dmax, Grays, 0}
	endif
	if (stringmatch( ctrlName, "*B"))
		NVAR dmin=root:imgmath:imB:dmin, dmax=root:imgmath:imB:dmax
		WAVE im=root:imgmath:imB
		ModifyImage imB ctab={dmin, dmax, Grays, 0}
	endif
	if (stringmatch( ctrlName, "*C"))
		NVAR dmin=root:imgmath:imC:dmin, dmax=root:imgmath:imC:dmax
		WAVE im=root:imgmath:imC
		ModifyImage imC ctab={dmin, dmax, Grays, 0}
	endif
	//ModifyImage im ctab={dmin, dmax, Grays, 0}
End

Function ImgMathFilter(ctrlName,popNum,popStr) : PopupMenuControl
//===================================
	String ctrlName
	Variable popNum
	String popStr
	
	string imgnam="im"+ctrlName[strlen(ctrlName)-1]		// imA, imB or imC
	string cmd
	if (popNum==1)
		//ModifyImage imA, ctab={*,*,Grays, 0}
		cmd="ModifyImage "+imgnam+", ctab={*,*,Grays, 0}"
		print cmd
		execute cmd 
		Img_Info( $("root:imgmath:"+imgnam), "/VAR=root:imgmath:"+imgnam )
	endif
	if (popNum==2)
		NVAR rad=root:imgmath:rad_polmask
		//Polar_Mask( root:imgmath:imA, "/RAD="+num2str(root:imgmath:rad_polmask) )
		cmd="Polar_Mask( root:imgmath:"+imgnam+", \"/RAD="+num2str(rad)+"\" )"
		print cmd
		execute cmd
		Img_Info( $("root:imgmath:"+imgnam), "/VAR=root:imgmath:"+imgnam )
	endif

End


Proc ImageMathStyle() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z cbRGB=(577,43860,60159)
	ModifyGraph/Z mirror=0
	ModifyGraph/Z nticks(yB)=0,nticks(yC)=0
	ModifyGraph/Z fSize=9
	ModifyGraph/Z standoff(left)=0,standoff(bottom)=0
	ModifyGraph/Z axOffset(left)=-4.28571
	ModifyGraph/Z axThick=0.5
	ModifyGraph/Z lblPos(left)=29,lblPos(bottom)=3
	ModifyGraph/Z freePos(yB)={0,xB}
	ModifyGraph/Z freePos(xB)=0
	ModifyGraph/Z freePos(yC)={0,xC}
	ModifyGraph/Z freePos(xC)=0
	ModifyGraph/Z axisEnab(bottom)={0,0.32}
	ModifyGraph/Z axisEnab(xB)={0.33,0.66}
	ModifyGraph/Z axisEnab(xC)={0.67,1}
EndMacro