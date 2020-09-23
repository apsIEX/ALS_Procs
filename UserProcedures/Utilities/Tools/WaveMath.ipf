// File:  WaveMath
// Jonathan Denlinger (JDDenlinger@lbl.gov)
//
//    9/30/03  (1.4)  - fixed dest. wave such that it is not re-created each time
//   11/6/02 (1.3)   - fixed definition of WM_split and WM_sep variables
//   10/21/99 (1.2) - added popup for selecting pre-existing output wave; prevent gain of exactly zero
//    1/23/97 (1.1)  - created datfolder root:math for globals
//   11/30/96  (v1.0) - created

#pragma rtGlobals=1		// Use modern global access method.
#include "wav_util"		// uses ReadMod(), WriteMod()

//Proc 	ShowWaveMath()
//Fct 	SelectMathGraph() : 	PopupMenuControl
//Fct 	ApplyMath() : 			SetVariableControl
//Fct 	MakeScaledWave()
//Fct 	SelectOperation() : 		PopupMenuControl
//Fct 	ToggleAppend() : 		CheckBoxControl
//Proc 	SelectWave() : 			PopupMenuControl  -Fct had update problems of wave tmp
//Fct		InfoBox() : 				ButtonControl
//Win 	WaveMathPanel() : 		Panel

menu "Plot"
	//"-"
	"Show Wave Math!"+num2char(19)
end

Proc ShowWaveMath()
//---------------
//Macro InitModify()
	//NewDataFolder/O tmp
	NewDataFolder/O/S root:math
	string/G WM_graph=""
	variable/G WM_shift1=0, WM_off1=0, WM_gain1=1
	variable/G WM_shift2=0, WM_off2=0, WM_gain2=1
	variable/G WM_op=1, WM_append=0
	//variable/G WM_split=0.75, WM_sep=0.02
	String/G WM_waveA="<>", WM_waveB="<>", WM_destw="<none>"
	SetDataFolder root:
	DoWindow/F WaveMathPanel
	if (V_flag==0)
		WaveMathPanel()
		PopupMenu GraphMath,mode=1,popvalue="<none>"
		PopupMenu WaveA,mode=1,popvalue="<none>"
		PopupMenu WaveB,mode=2,popvalue="<none>"
	endif
End

Function SelectMathGraph(ctrlName,popNum,popStr) : PopupMenuControl
//================
	String ctrlName
	Variable popNum
	String popStr
	SVAR dwn=root:math:WM_destw, gnam=root:math:WM_graph

	gnam=popStr
	dwn="<none>"
	DoWindow/F $popStr
	DoWindow/F WaveMathPanel
End

Function ApplyMath(ctrlName,varNum,varStr,varName) : SetVariableControl
//==============
//
	String ctrlName
	Variable varNum
	String varStr, varName
		string fldrSav=GetDataFolder(1)
		SetDataFolder root:math
			
	NVAR shft1=WM_shift1, off1=WM_off1, scl1=WM_gain1
	NVAR shft2=WM_shift2, off2=WM_off2, scl2=WM_gain2
	NVAR op=WM_op, app=WM_append
	SVAR gnam=WM_graph, wnA=WM_waveA, wnB=WM_waveB, dwn=WM_destw
	 	SetDataFolder fldrSav
	 string wvnAx=XWaveName(gnam, wnA), wvnBx=XWaveName(gnam, wnB)
	WAVE wvA=$wnA, wvAx=$wvnAx
	WAVE wvB=$wnB, wvBx=$wvnBx
	
	shft1*=(abs(shft1)>1E-8)		//remove rounding error for near-zero value
	shft2*=(abs(shft2)>1E-8)	
	
	 scl1=SelectNumber(  scl1==0, scl1, 1E-8)		//prevent gain from being exactly zero
	 scl2=SelectNumber(  scl2==0, scl2, 1E-8)
	
	//print ctrlName, varNum, varStr, varName
 	//print "apply math:"+wnA+"--/+"[op-1]+wnB+"="+dwn
 	
 	//Modify input waves A & B; write mod to wave notes
 	string modlst, txt
 	variable shift0, offset0, gain0, val, lin, thk, clr
 	if (strsearch(ctrlName,"1", 0)>0)
 		modlst=ReadMod( wvA )	
	 		shift0=NumberByKey("Shift", modlst, "=", "," )
	 		offset0=NumberByKey("Offset", modlst, "=", "," )
		 	gain0=NumberByKey("Gain", modlst, "=", "," )
		 	lin=NumberByKey("Lin", modlst, "=", "," )
		 	thk=NumberByKey("Thk", modlst, "=", "," )
		 	clr=NumberByKey("Clr", modlst, "=", "," )
		 	val=NumberByKey("Val", modlst, "=", "," )
		 	txt=StringByKey("Txt", modlst, "=", "," )
		wvA = (scl1/gain0) * ( wvA - offset0) + off1
		if (exists("wvnAx")==1)
 			wvAx += (shft1-shift0)
 		else
 			SetScale/P x leftx(wvA)+(shft1-shift0), deltax(wvA), waveunits(wvA, 0) wvA
 		endif
 		WriteMod( wvA, shft1, off1, scl1, lin,thk,clr, val, txt )
 	endif
 	if (strsearch(ctrlName,"2", 0)>0)
 		//List2Wave( note(wvB), ",", "tmp" )
 		//ReadMod( wvB, "root:math:tmp")
		//Wave tmp=root:math:tmp
		modlst=ReadMod( wvB )	
	 		shift0=NumberByKey("Shift", modlst, "=", "," )
	 		offset0=NumberByKey("Offset", modlst, "=", "," )
		 	gain0=NumberByKey("Gain", modlst, "=", "," )
		 	lin=NumberByKey("Lin", modlst, "=", "," )
		 	thk=NumberByKey("Thk", modlst, "=", "," )
		 	clr=NumberByKey("Clr", modlst, "=", "," )
		 	val=NumberByKey("Val", modlst, "=", "," )
		 	txt=StringByKey("Txt", modlst, "=", "," )
		//print wnB, XWaveName("", wnB), tmp[0]
		wvB = (scl2/gain0) * ( wvB -offset0 ) + off2
		if (exists("wvnAx")==1)
 			wvBx += (shft2-shift0)
 		 else
 			SetScale/P x leftx(wvB)+(shft2-shift0), deltax(wvB), waveunits(wvB, 0) wvB
 		endif
 		WriteMod( wvB, shft2, off2, scl2, lin,thk,clr, val, txt )
 	endif
 	
 	//Destination Wave: check if it is specified, if it exists and length & scaling from wvA
 	 if (cmpstr(dwn,"<none>")==0)
		abort
	endif
 	if (stringmatch(ctrlName,"Destwv")+(exists(dwn)==0))
 		if (exists(dwn)==1)
 			string savnote=Note($dwn)
 			duplicate/o wvA $dwn
 			Note/K $dwn
 			Note $dwn, savnote				//preserve original note values
 			print "updating destw: "+dwn
 		else
 			duplicate/o wvA $dwn
			WriteMod( $dwn, 0, 0, 1, 0,0.5,0, 0, "" ) 
			print "creating new destw: "+dwn
 		endif
 		if (exists(wvnAx)==0)			//scaled A wave
		else
	 		MakeScaledWave( wvA, wvAx,  dwn )
	 	endif
 	endif
 	
 	WAVE dwv=$dwn
 	if (exists(wvnBx)==0)			//scaled B wave
	 	if (op==1) 
	 		dwv=wvA(x)-wvB(x)
	 	endif
	 	if (op==2) 
	 		dwv=(wvA(x) - wvB(x) )  / (wvA(x) + wvB(x) )
	 	endif
	 	if (op==3) 
	 		dwv=wvA(x) / wvB(x)
	 	endif
	 	if (op==4) 
	 		dwv=wvA(x) / wvB(x) -1.
	 	endif
	 	if (op==5) 
	 		dwv=wvA(x) + wvB(x)
	 	endif
	else
	 	if (op==1) 
	 		dwv=wvA - interp( x, wvBx, wvB )
	 	endif
	 	if (op==2) 
	 		dwv=(wvA - interp( x, wvBx, wvB ) ) / (wvA + interp( x, wvBx, wvB ) )
	 	endif
	 	if (op==3) 
	 		dwv=wvA / interp( x, wvBx, wvB )
	 	endif
	 	if (op==4) 
	 		dwv=wvA / interp( x, wvBx, wvB ) -1.
	 	endif
	 	if (op==5) 
	 		dwv=wvA + interp( x, wvBx, wvB )
	 	endif
 	endif
 	
 	//Set up dependency for destw = A op B?

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

Function SelectOperation(ctrlName,popNum,popStr) : PopupMenuControl
//=================
	String ctrlName
	Variable popNum
	String popStr

	NVAR op=root:math:WM_op
	op=popNum
	ApplyMath("",0,"","")
End

Function ToggleAppend(ctrlName,checked) : CheckBoxControl
//===============
	String ctrlName
	Variable checked
	NVAR app=root:math:WM_append
	app=checked	
End

Proc AppendMath(ctrlName,popNum,popStr) : PopupMenuControl
//=================================
	String ctrlName
	Variable popNum
	String popStr

	DoWindow/F $root:math:WM_graph
	 if (popNum==5)
 		AxisPref( )
 	else
 	//Check if displayed; append to plot if requested
 	CheckDisplayed/W=$root:math:WM_graph $root:math:WM_destw
 	if (V_flag==0)
	 	if (popNum==1)
	 		AppendToGraph $root:math:WM_destw
	 	else
	 	if (exists("root:math:WM_split")==0)
	 		AxisPref( )
	 	endif
	 	variable lower=root:math:WM_split-root:math:WM_sep, upper=root:math:WM_split+root:math:WM_sep
	 	if (popNum==2)
	 		AppendToGraph/L=above $root:math:WM_destw
	 		ModifyGraph axisEnab(left)={0,lower},axisEnab(above)={upper,1},freePos(above)=0
			ModifyGraph tick(above)=2,zero(above)=1, mirror(above)=2
	 	endif
	 	if (popNum==3)
	 		AppendToGraph/L=below $root:math:WM_destw
	 		ModifyGraph axisEnab(left)={upper,1},axisEnab(below)={0,lower},freePos(below)=0
			ModifyGraph tick(below)=2,zero(below)=1, mirror(below)=2
	 	endif
	 	endif
 	endif
 	if ((V_flag==1)*popNum==4))
 		RemoveFromGraph $root:math:WM_destw
 		ModifyGraph axisEnab(left)={0,1}
 	endif
	endif
End

Proc AxisPref( split, sep )
//----------------
	variable split=NumVarOrDefault("root:math:WM_split", 0.75)
	variable sep=NumVarOrDefault("root:math:WM_sep", 0.02)
	variable/G root:math:WM_split=split, root:math:WM_sep=sep
End

Function SelectWave(ctrlName,popNum,popStr) : PopupMenuControl
//==============
//Select A or B wave; read wave note and write to global variables
	String ctrlName
	Variable popNum
	String popStr
	//print ctrlName, popStr
	string modlst
	modlst=ReadMod( $popStr )	
	//ReadMod( $popstr, "root:math:tmp" )

	string fldrSav=GetDataFolder(1)
	SetDataFolder root:math
	SVAR wvnA=WM_waveA, wvnB=WM_WaveB, destwn=WM_destw
	StrSwitch( ctrlName )
	case "WaveOut":
		//if (cmpstr(ctrlName,"WaveOut")==0)
		variable match=( cmpstr(popStr, wvnA)==0 ) + (cmpstr(popStr, wvnB)==0 )
		//print match
		destwn=SelectString( match==0, "<none>", popstr)
		break
	case "WaveA":
		//if (cmpstr(ctrlName,"WaveA")==0)
		wvnA=popStr
		//modlst=ReadMod( $WM_waveA )
		//WM_shift1=tmp[0];WM_off1=tmp[1]; WM_gain1=tmp[2]
		NVAR shift1=WM_shift1, off1=WM_off1, gain1=WM_gain1
		shift1=NumberByKey("Shift", modlst, "=", "," )
		off1=NumberByKey("Offset", modlst, "=", "," )
		gain1=NumberByKey("Gain", modlst, "=", "," )
		SetDataFolder fldrSav
		ApplyMath("1",0,"","")
		break
	case "WaveB":
		wvnB=popStr
		//modlst=ReadMod( $WM_waveB )
		//WM_shift2=tmp[0]; WM_off2=tmp[1];WM_gain2=tmp[2]
		NVAR shift2=WM_shift2, off2=WM_off2, gain2=WM_gain2
		shift2=NumberByKey("Shift", modlst, "=", "," )
		off2=NumberByKey("Offset", modlst, "=", "," )
		gain2=NumberByKey("Gain", modlst, "=", "," )
		SetDataFolder fldrSav
		ApplyMath("2",0,"","")
	endswitch
	
	SetDataFolder root:
End


Function InfoBox(ctrlName) : ButtonControl
//--------------
	String ctrlName
	SVAR wnA=root:math:WM_waveA, wnB=root:math:WM_waveB, dwn=root:math:WM_destw
	NVAR op=root:math:WM_op
	//DoWindow/F  no graph global -- assume top graph
	string modlst

	string txt
	txt="\s("+wnA+") "+wnA+" : "
		modlst=ReadMod( $wnA )
		txt+=StringByKey("Shift", modlst, "=", "," )+", "
		txt+=StringByKey("Offset", modlst, "=", "," )+", "
		txt+=StringByKey("Gain", modlst, "=", "," )
	txt+="\r\s("+wnB+") "+wnB+" : "
		modlst=ReadMod( $wnB )
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

Window WaveMathPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(527,63,892,182) as "Wave Math"
	ModifyPanel cbRGB=(23387,34695,62194)
	SetDrawLayer UserBack
	SetDrawEnv fsize= 10
	DrawText 168,44,"shift"
	SetDrawEnv fsize= 10
	DrawText 230,43,"offset"
	SetDrawEnv fsize= 10
	DrawText 301,43,"gain"
	SetDrawEnv fsize= 10
	DrawText 322,20,"v1.4"
	PopupMenu GraphMath,pos={14,8},size={75,20},proc=SelectMathGraph,title="Graph"
	PopupMenu GraphMath,mode=1,popvalue="<none>",value= #"WinList(\"*\",\";\",\"WIN:1\")"
	PopupMenu WaveA,pos={14,44},size={146,20},proc=SelectWave,title="A"
	PopupMenu WaveA,mode=1,popvalue="<none>",value= #"WaveList(\"!*_x\", \";\", \"WIN:\"+root:math:WM_graph)"
	PopupMenu WaveB,pos={15,67},size={133,20},proc=SelectWave,title="B"
	PopupMenu WaveB,mode=2,popvalue="<none>",value= #"WaveList(\"!*_x\", \";\", \"WIN:\"+root:math:WM_graph)"
	SetVariable Shift1,pos={155,48},size={60,15},proc=ApplyMath,title=" "
	SetVariable Shift1,limits={-Inf,Inf,0.005},value= root:math:WM_shift1
	SetVariable Offset1,pos={222,46},size={60,15},proc=ApplyMath,title=" "
	SetVariable Offset1,value= root:math:WM_off1
	SetVariable Gain1,pos={287,46},size={60,15},proc=ApplyMath,title=" "
	SetVariable Gain1,limits={-Inf,Inf,0.01},value= root:math:WM_gain1
	SetVariable Shift2,pos={155,68},size={60,15},proc=ApplyMath,title=" "
	SetVariable Shift2,limits={-Inf,Inf,0.005},value= root:math:WM_shift2
	SetVariable Offset2,pos={221,69},size={60,15},proc=ApplyMath,title=" "
	SetVariable Offset2,value= root:math:WM_off2
	SetVariable Gain2,pos={288,68},size={60,15},proc=ApplyMath,title=" "
	SetVariable Gain2,limits={-Inf,Inf,0.01},value= root:math:WM_gain2
	SetVariable Destwv,pos={17,95},size={140,15},proc=ApplyMath,title=" Output"
	SetVariable Destwv,value= root:math:WM_destw
	PopupMenu Operation,pos={173,7},size={113,20},proc=SelectOperation,title="Operation"
	PopupMenu Operation,mode=5,popvalue="A - B",value= #"\"A - B;(A-B)/(A+B);A / B;A/B-1;A + B\""
	Button InfoBox,pos={271,92},size={70,20},proc=InfoBox,title="Add Info"
	PopupMenu AppendPop,pos={190,93},size={73,20},proc=AppendMath,title="Append"
	PopupMenu AppendPop,mode=0,value= #"\"to Graph;Above;Below;Remove;Axis Prefs\""
	PopupMenu WaveOut,pos={163,92},size={20,20},proc=SelectWave
	PopupMenu WaveOut,mode=0,value= #"WaveList(\"!*_x\", \";\", \"WIN:\"+root:math:WM_graph)"
EndMacro
