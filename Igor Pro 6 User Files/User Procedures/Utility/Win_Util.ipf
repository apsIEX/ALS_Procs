//file: Win_Util		created: 1/97 J. Denlinger
// 11/23/02   JDD Added WinPanel

#pragma rtGlobals=1		// Use modern global access method.
#include "List_util"

//Proc 	CycleWin()
//Fct 	Win( winnam )

Menu "Macros"
	"-"
	Submenu "Window procs"
		"WinPanel"
		"Push Top Graph/1",  CycleWin(1,1)
		"Pop Bottom Graph/2",  CycleWin(-1,1)
		"Push Top Table/3",  CycleWin(1,2)
		"Pop Bottom Table/4",  CycleWin(-1,2)
		"Cycle Window", CycleWin()
		"fct Win winnam "
	End
End

Proc CycleWin(dir, typ)
//----------
//bring last graph window in list to front
	variable dir, typ
	prompt dir, "Window Direction", popup, "Push Top to Bottom;Pop Bottom to Top"
	prompt typ, "Window Type", popup, "Graph;Table"
	
	if (dir==1)
		DoWindow/B $WinName(0, typ)
		DoWindow/F $WinName(0, typ)
	else
		string winlst=WinList("*",";","WIN:"+num2str(typ))
		variable nwin=ItemsInList(winlst)
		DoWindow/F $WinName(nwin-1, typ)
	endif
End

Function Win( winnam )
//=============
// bring window to front; if not present create anew
	string winnam
	DoWindow/F $winnam
	if (V_flag==0) 
		execute winnam+"()"
	endif
	return V_flag
End

Window WinPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(589,51,932,189)
	ModifyPanel cbRGB=(65535,32764,16385)
	PopupMenu popGraph,pos={7,5},size={114,20},proc=WinSelect,title="Graph"
	PopupMenu popGraph,mode=1,popvalue="",value= #"WinList(\"!Load*\",\";\",\"WIN:1\")"
	PopupMenu popTable,pos={11,29},size={127,20},proc=WinSelect,title="Table"
	PopupMenu popTable,mode=1,popvalue="",value= #"WinList(\"!Load*\",\";\",\"WIN:2\")"
	PopupMenu popNbk,pos={16,53},size={125,20},proc=WinSelect,title="Nbk"
	PopupMenu popNbk,mode=1,popvalue="",value= #"WinList(\"!Load*\",\";\",\"WIN:16\")"
	PopupMenu popPanel,pos={6,79},size={129,20},proc=WinSelect,title="Panel"
	PopupMenu popPanel,mode=4,popvalue="",value= #"WinList(\"Load*\",\";\",\"WIN:1\")+WinList(\"!Load*\",\";\",\"WIN:64\")"
	PopupMenu popProc_1,pos={10,104},size={126,20},proc=ProcSelect,title="Proc"
	PopupMenu popProc_1,mode=1,popvalue="",value= #"WinList(\"!Load*\",\";\",\"WIN:128\")"
	Button WinLst,pos={240,104},size={60,20},proc=WindowLst,title="WinList"
EndMacro

Function WinSelect(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	DoWindow/F $popStr
End

Function ProcSelect(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	variable iext=strsearch(popStr, ".ipf", 0)
	string procstr=SelectString(iext>0, popStr, popStr[0,iext-1])
	print procstr
	DisplayProcedure procStr
End


Function WindowLst(ctrlName) : ButtonControl
	String ctrlName
	
	String txtstr
	DoWindow/F WindowList
	if (V_flag==0)
		NewNotebook/F=0/K=1/N=WindowList/W=(50,50,250,400)
	else
		Notebook WindowList selection={startOfFile, endOfFile}, text=""			//erase current
	endif
	txtstr="-- GRAPH --\r"+WinList("!Load*","\r","WIN:1")
	txtstr+="\r-- TABLE --\r"+WinList("!Load*","\r","WIN:2")
	txtstr+="\r-- NOTEBOOK --\r"+WinList("!Load*","\r","WIN:16")
	txtstr+="\r-- PANEL --\r"+WinList("!Load*","\r","WIN:64")
	txtstr+="\r-- PROCS --\r"+WinList("!Load*","\r","WIN:128")
	Notebook WindowList text=txtstr
End
