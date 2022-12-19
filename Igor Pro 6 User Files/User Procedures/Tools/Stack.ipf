// File:  Stack.ipf		
// Jonathan Denlinger (JDDenlinger@lbl.gov) 
// 
#pragma version = 4.01
//  7/28/08 (v4.01) -- add Offset Csr A-B average to value (for zeroing out bkg levels where too noisy for Csr pt value)
//  11/17/07 (v4.0) -- change startup to DoAlert message instead of confusing LinePrefs choice
//                             -- revamp ResetMenu; Fix ApplyTable s.t. AutoUpdate enabled as default
//				-- ScaleMenu: replace WaveStats A-B V-avg  with faverage or area options
//   7/8/06 (v3.8)  -- better trap GAIN values of {0,nan,inf}, e.g. do not change waves max=INF values
//   5/24/06  -- "/1" shortcut to popup Stack panel
//   9/10/04 (v3.7) -- add cursor A-B range option to ExpandMenu
//   7/15/04 (v3.6) 
//      -- try to trap all instances of cursor A/B not being set (so data doesn't get destroyed)
//   5/31/04  -- renamed StackPrefs to LinePrefs & made prefs dialog easier to guess at meaning
//  11/16/03 (v3.5)
//	   -- add  Csr A-B range avg option to ScaleMenu
//  9/30/03 (v3.4)
//	   -- add  CsrAonly option to ResetNotes and ClearOffsets
//	   -- add  hook function for simultaneous lilling of Panel and Table
//      -- add Sort Table by VAL & TXT columns 
//      -- created Igor style help file <JD Stack Help>
//  4/12/03  (v3.3)
//     -- added Stack Help and Preferences procedures to main menu
//     -- prefs for Line Style (-1 or not)  and for Line Thickness offset, i.e. "1"->0.5
//  3/26/03 (v3.2)  
//      -- negative LIN, THK & CLR values get skipped in ApplyTable and are set as default if no wavenote exists
//      -- move ClearOffsets() and ResetNotes() to ResetMenu on panel
// 2/18/03 -- added STATIC function List2TextW() & IndexOfWave() from List_util.ipf
//      -- added STATIC functions ReadMod() & WriteMod() from wav_util.ipf
//  8/4/04  (v 3.1)  --  trap Zero scale factors (abort); add Scale X option to Shift menu
//  1/31/02 ( v3.0) --  added button for update of current graph (faster than reselecting pull down menu)
//              -- added Cursor A only checkbox & restructured logic of Shift/Offset/Scale/Reset/Expand
//  1/1/02  -- make SHIFT, OFFSET, GAIN waves double precision & make WriteMod write with sprintf "%.9g"
//   12/26/01  (v2.2) --  added  Expand "Csr positions to values" option & Legend option to Tag menu
//  11/10/01   -- tweaked green and cyan to be darker, closer to defaults
//   3/8/01     -- added selective options to ResetNotes
//   8/30/00  (v2.1)  --  added AutoApply Table checkbox
//   2/19/00   -- reworked TagMenu & Tag procedures
//  12/27/99  -- Added TagAt(); Changed WaveNote to have keyword format (non-destructive of other notes)
//  renamed (2/00) from WaveMod (11/96)  

#pragma rtGlobals=1		// Use modern global access method.
#include "Tags"
//#include "List_Util"			// uses  List2Textw(), Wave2List() function
//#include "wav_util"		// ReadMod() & WriteMod() functions

//Macro 	ClearOffsets()
//Proc 	ShowStack()
//Fct 	SelectStackGraph() : 			PopupMenuControl 
//Fct 	ResetMod( w )
//Fct 	Mod2Table()
//Fct 	Table2Mod()
//Fct 	ApplyTable() : 			ButtonControl
//Proc 	CheckAutoApply(ctrlName,checked) : CheckBoxControl
//Fct 	AutoApplyFct(shift, offset, gain, lin, thk, clr, val, txt)
//Fct 	ColorStr( iclr )			{0..6}={black,red,blue,green,violet,bl/green,orange}
//Fct 	ShiftMenu() : 			PopupMenuControl
//Fct 	OffsetMenu() : 			PopupMenuControl
//Fct 	ScaleMenu() : 			PopupMenuControl
//Fct 	StyleMenu() : 			PopupMenuControl
//Fct 	ResetMenu() : 			PopupMenuControl
//Fct 	StackWaves() : 			PopupMenuControl
//Fct 	ExpandWaves() : 		PopupMenuControl
//Win 	StackTable() : 		Table
//Win 	StackPanel() : 		Panel
//Proc 	AddZeroline()

menu "Plot"
	"-"
	"Stack Panel & Table!"+num2char(19)+"/1", ShowStackPanel()
		help={"Stack plot manipulation; modifications are stored in individual wave notes"}
	"Stack Help", StackHelp()
	"Stack Prefs", StackLinePrefs()
	//"ClearOffsets"
	//	help={"Reset X,Y offsets on top graph so as to not confuse with Stack wave Shift/Offset"}
	//"ResetNotes"
	//	help={"Redefine individual wave notes to default (no physical resetting)"}
	"Add Zero line"
		help={"Append {-INF, INF} vs {0,0}; will not be hidden by wave shading"}
end

Proc StackHelp()
//  Rewrite this as an Igor Help file
	DoWindow/F Stack_Help
	if (V_flag==0)
		string txtstr
		NewNotebook/W=(100,100,590,650)/F=1/K=1/N=Stack_Help
		Notebook Stack_Help, showruler=0, backRGB=(45000,65535,65535)
		Notebook Stack_Help, fstyle=1, text="Stack Panel\r"
		Notebook Stack_Help, fstyle=0, text="version 3.4, Sep'03, J. Denlinger\r"
		
		Notebook Stack_Help, fstyle=1, text="Basic:\r"
		//read from file?
		txtstr="Stack Panel & Table allows traceable modification of 1D line plot data\r"
		txtstr+="by storing changes in each individual wave note in a keyword list format, e.g.\r"
		txtstr+="   \"MOD: Shift=0,Offset=0.2,Gain=1.5,Lin=0,Thk=0.5,Clr=2,Val=130.1,txtstr=Silicon\"\r"
		Notebook Stack_Help, fstyle=0, text=txtstr
		
		Notebook Stack_Help, fstyle=1, text="PANEL:\r"
		txtstr="The Stack PANEL <menus> contains many useful shortcuts and features including:\r"
		txtstr+="   <Plot> Selection of Active Graph\r"
		txtstr+="   <Shift> X-axis (scaled or x-wave) shifting (absolute, incremental, YMAX or CrsA position)\r"
		txtstr+="   <Shift> X-axis scaling (not stored in wavenote and thus not resettable!)\r"
		txtstr+="   <Offset> Data offsets (absolute, incremental, YMIN or CrsA position)\r"
		txtstr+="   <Scale> Data scaling (absolute, YMAX or CrsA position)\r"
		txtstr+="   <Waterfall> combination Shift and Offset operations \r"
		txtstr+="   <Waterfall> Solid Fill, Sort & Reverse Order options for stacking with hidden line effects\r"
		txtstr+="   <Expand> combination Offset and Scale operations\r"
		txtstr+="   (CsrA only) Toggle for application to ALL waves in graph or only to wave with Cursor A\r"
		txtstr+="   <Style> Automated Line Dash, Thickness and Color\r"
		txtstr+="   <Tag> Automated tagging of waves with VAL or txtstr fields or with an Arrow\r"
		txtstr+="   <Tag> Legend creation with VAL, txtstr or other wave info\r"
		txtstr+="   <Reset> Reset all or individual fields to defaults\r"
		txtstr+="   <Reset> Reset all or individual wavenote values (without change to data)\r"
		txtstr+="   <Reset> Clear all or individual wave 'ModifyGraph' offsets\r"
		//txtstr+="   Associated numeric value or text string\r"
		Notebook Stack_Help, fstyle=0, text=txtstr
		
		Notebook Stack_Help, fstyle=1, text="TABLE:\r"
		txtstr="The Stack TABLE provides a view of all MOD parameters of individual waves in a graph. \r"
		txtstr+="- Manual changes to the table can be applied to the graph by <ApplyTable> or \r"
		txtstr+="Automatically by enabling the checkbox next to <ApplyTable>. \r"
		txtstr+="- (Delay Update) in the table can be selected to allow multiple changes to the table "
		txtstr+="before automatically applying changes (click outside the table). \r"
		txtstr+="- The box next to <Plot> updates the Stack Table values for the current active graph. \r"
		Notebook Stack_Help, fstyle=0, text=txtstr
		
		Notebook Stack_Help, fstyle=1, text="Rules:\r"
		txtstr="- SCALE operations are peformed first before OFFSET operations.\r"
		txtstr+="- Stack is currently not Data Folder aware, i.e. all waves in the graph must be present "
		txtstr+="in the current selected folder.  Thus no graphs with waves from different subfolders.\r"
		txtstr+="- Negative LIN, THK and CLR values are skipped allowing independent modification.\r"
		txtstr+="- Igor graph XY offsets are also independent of Stack modifications.\r" 
		txtstr+="- LIN & THK values correspond to Igor values (pref. option of 0.5 offset to THK)\r"
		txtstr+="- CLR values (0-6) correspond to (black,red,blue,green,violet,cyan,orange)\r"
		txtstr+="- <Style> values correspond to (start wave #, cycle #)\r"
		txtstr+="- <Tag> preference selection for tag placment & arrow size\r"
		txtstr+="- Preferences available for MOD default values and THK mapping."
		Notebook Stack_Help, fstyle=0, text=txtstr
		
	endif
End

Proc StackLinePrefs(lineDef, ThkOpt)
//----------
	string lineDef=StrVarOrDefault( "root:Stack:LineDefault","Lin=-1,Thk=-1,Clr=-1")
	variable ThkOpt=NumVarOrDefault( "root:Stack:THKmap",2)
	prompt lineDef, "Line style defaults (-1=no change to manual settings)", popup,"Lin=-1,Thk=-1,Clr=-1;Lin=0,Thk=0.5,Clr=0"
	//prompt lineDef, "Stack Defaults", popup,"Shift=0,Offset=0,Gain=1,Lin=-1,Thk=-1,Clr=-1,Val=0,Txt= ;Shift=0,Offset=0,Gain=1,Lin=0,Thk=0.5,Clr=0,Val=0,Txt= "
	prompt thkOpt,"Line thickness mapping", popup, "standard;Subtract 0.5 for THK>0.5"
	string/G root:Stack:LineDefault=lineDef
	variable/G root:Stack:THKmap=ThkOpt
End

Proc AddZeroline()
//-----------------
// utility routine for stack plots with hidden line filling
	PauseUpdate; Silent 1
	make/o FEy={-INF,INF}, FEx={0,0}
	Note FEy, "Shift=0,Offset=0,Gain=1,Lin=1,Thk=0.5,Clr=-1,Val=NaN,Txt= "
	DoWindow/F $WinName(0,1)
	append FEy vs FEx
	ModifyGraph lstyle(FEy)=1
	ModifyGraph zero(bottom)=0		//turn off zero line interference
End

Proc ClearOffsets(wavn)
//-------------
	string wavn
	prompt wavn, "Waves", popup, "ALL;-;"+WaveList("!*_x",";","WIN:")
	variable singlewave=!stringmatch(wavn,"ALL")
	if ((singlewave)*(exists(wavn)!=1))
		abort "ClearOffsets: Wave does not exist"
	endif
	DoWindow/F $WinName(0,1)
	if (singlewave)
		execute "ModifyGraph offset("+wavn+")={0,0}"
	else
		ModifyGraph offset={0,0}
	endif
End

Proc ResetNotes(opt, wavn)
//-------------
	variable opt=2
	string wavn
	prompt opt, "Reset fields:", popup, "SHIFT;OFFSET;GAIN;SHIFT+OFFSET+GAIN;LIN+THK+CLR;ALL"
	prompt wavn, "Waves", popup, "ALL;-;"+WaveList("!*_x",";","WIN:")
	PauseUpdate; Silent 1
	//wave/T WNAM=root:WNAM
	//wave LIN=root:LIN, THK=root:THK, CLR=root:CLR

	variable singlewave=!stringmatch(wavn,"ALL")
	variable nw=SelectNumber(singlewave, numpnts(root:WNAM), 1)
	if ((singlewave)*(exists(wavn)!=1))
		abort "ResetNotes: Wave does not exist"
	endif
	variable shft, off, gain, lin, thk, clr, val
	string txt, modlst, wn
	variable i=0
	do
		wn=SelectString(singlewave,WNAM[i],  wavn )
		modlst=ReadMod($wn )
		//print modlst
		shft=SelectNumber( (opt==1)+(opt==4), NumberbyKey( "Shift", modlst, "=", ","), 0)
		off=SelectNumber( (opt==2)+(opt==4),NumberbyKey( "Offset", modlst, "=", ","), 0)
		gain=SelectNumber( (opt==3)+(opt==4),NumberbyKey( "Gain", modlst, "=", ","), 1)
		lin=SelectNumber( (opt==5)+(opt==6),NumberbyKey( "Lin", modlst, "=", ","), 0)
		thk=SelectNumber( (opt==5)+(opt==6),NumberbyKey( "Thk", modlst, "=", ","), 0.5)
		clr=SelectNumber( (opt==5)+(opt==6),NumberbyKey( "Clr", modlst, "=", ","), 0)
		val=SelectNumber( (opt==6),NumberbyKey( "Val", modlst, "=", ","), Nan)
		txt=SelectString( (opt==6),StringByKey( "Txt", modlst, "=", ","), "")
		//print shft, off, gain, lin, thk, clr, val, txt
		WriteMod( $wn,  shft,off,gain,  lin,thk,clr,  val, txt) 
 		i+=1 
 	while(i<nw)
 	Mod2Table()
End

Proc ShowStackPanel()
//--------------
// initialize globals in data folder and display Stack table and panel
	NewDataFolder/O/S root:Stack

	//SetDataFolder root:	
	DoWindow/F StackPanel
	if (V_flag==0)
		// create panel variables
		string/G graphnam="", whichstyle="0,1"
		variable/G shiftval=0, offsetval=0, gainval=1, styleval=1
		variable/G autoline=0, autocolor=0, hiddenlines=0
		variable/G AutoApply=1, CsrAonly=0, ThkMap=2
//		string/G LineDefault="Lin=-1,Thk=-1,Clr=-1"
		string/G LineDefault="Lin=0,Thk=0.5,Clr=0"
		StackPanel()
		CheckBox checkAuto,value=1   // cannot enable AutoApply until plot selected?  
		string msg="Stack OVERRIDES manually set linestyles settings.\r"
		msg+="Use LIN=-1,THK=-1 or CLR=-1 to NOTchange a manual setting.\r"
		msg+="Change linestyle DEFAULTS to -1 using Reset>LinePrefs."
		DoAlert 0, msg
//		StackLinePrefs()
	endif

	SetDataFolder root:	
	DoWindow/F StackTable
	if (V_flag==0)
		//create table waves
		make/T/O/n=10 WNAM="", WNAMX=""
		make/D/O/n=10 SHIFT=0, OFFSET=0, GAIN=1		// double-precision
		make/O/n=10 LIN=0, THK=1, CLR=0, VAL=NaN
		make/T/O/n=10 TXT=""
		StackTable()
		Check_Stack("checkAuto",1)       //enable AutoApply - needs to have target window defined
		root:Stack:AutoApply:=AutoApplyFct(root:SHIFT, root:OFFSET, root:GAIN, root:LIN, root:THK, root:CLR, root:VAL, root:TXT)
	endif

	SetWindow StackPanel hook=StackWinHook			//kill StackTable if StackPanel is killed
	SetWindow StackTable hook=StackWinHook			// and vice versa

	DoWindow/F StackPanel
End	

Function StackWinHook(infoStr)
//=============
// Hook function for simultaneous killing of StackPanel and StackTable
//  (/K=1) no kill dialog option also used for Panel and Table
	String infoStr
	//print infoStr
	String win= StringByKey("WINDOW",infoStr)
	String event= StringByKey("EVENT",infoStr)
	//print win, event
	if (stringmatch(win,"StackPanel")*stringmatch(event,"kill"))
		DoWindow/K StackTable
	endif
	if (stringmatch(win,"StackTable")*stringmatch(event,"kill"))
		DoWindow/K StackPanel
	endif
	return 0
End


Function SelectStackGraph(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr

	SVAR gnam=root:Stack:graphnam
	gnam = popStr
	DoWindow/F $popStr
	ShowInfo
	//SetDataFolder root:
	if (exists("root:Stack:LineDefault")==0)		//check for old experiments
		Execute "StackLinePrefs()"
		//print "creating LineDefault"
		//string/G root:Stack:LineDefault="Lin=-1,Thk=-1,Clr=-1"
	endif
	Mod2Table()
	DoWindow/F StackTable
	DoWindow/F StackPanel
	PopupMenu GraphPop mode=1
End

Static Function/T ReadMod( w )	
//============
	wave w
	string destwn
	string noteStr, modlst
	SVAR LineDefault=root:Stack:LineDefault
	noteStr=note(w)
	modlst=StringByKey( "MOD", noteStr, ":", "\r" )
	if (strlen(modlst)==0)					// no wave mod keywords
		//modlst=ReadMod_old(w)			// check for previous method of storing values
		//if (strlen(modlst)==0)		
	   		Note/K w
	   		//modlst="SHIFT=0,OFFSET=0,GAIN=1,LIN=0,THK=0.5,CLR=0,VAL=0,TXT= ;"
	   		//modlst="Shift=0,Offset=0,Gain=1,Lin=0,Thk=0.5,Clr=0,Val=0,Txt= "
	   		// new defaults with negative value Lin, Thk & Clr
	   		//modlst="Shift=0,Offset=0,Gain=1,Lin=-1,Thk=-1,Clr=-1,Val=0,Txt= "
	   		modlst="Shift=0,Offset=0,Gain=1,"+LineDefault+",Val=0,Txt= "
	   		Note w, "MOD:"+modlst+"\r"+noteStr		// pre-pend default
   		//endif
   	endif
	return modlst
End

Static Function/T WriteMod(w, shft, off, gain, lin,  thk, clr, val, txt)
//=============
	wave w
	variable shft, off, gain, lin, thk, clr, val
	string txt
	string notestr, modlst
	sprintf modlst, "Shift=%.9g,Offset=%.9g,Gain=%.9g", shft, off, gain
	modlst+=",Lin="+num2str(lin)+",Thk="+num2str(thk)+",Clr="+num2str(clr)
	modlst+=",Val="+num2str(val)+",Txt="+txt
	notestr=note(w)
	notestr=ReplaceStringByKey("MOD", notestr, modlst, ":", "\r")
   	Note/K w			//kill previous note
   	Note w, noteStr
   	return modlst
end


Function Mod2Table()
//==================
// read wavenotes from waves on graph; enter into table
	PauseUpdate; Silent 1
	SVAR gnam=root:Stack:graphnam
	WAVE/T WNAM=root:WNAM, WNAMX=root:WNAMX, TXT=root:TXT
	WAVE SHIFT=root:SHIFT, OFFSET=root:OFFSET, GAIN=root:GAIN
	WAVE LIN=root:LIN, THK=root:THK, CLR=root:CLR,  VAL=root:VAL
 	string wvlst=TraceNameList(gnam, ";", 1)
	variable nw=list2textw(wvlst,";","root:WNAM")
	//print nw, ItemsInlist(wvlst)
	redimension/n=(nw) WNAMX, SHIFT, OFFSET, GAIN, LIN, THK, CLR, VAL,TXT
	variable ii=0
	string modlst
	DO
		WNAM[ii]=WaveName(gnam, ii, 1 )
		WNAMX[ii]=XWaveName(gnam, WNAM[ii] )
		wave w=$WNAM[ii]
   	
   		modlst=ReadMod( w )	
	 	SHIFT[ii]	=NumberByKey("Shift", modlst, "=", "," )
	   	OFFSET[ii]	=NumberByKey("Offset", modlst, "=", "," )
	 	GAIN[ii]	=NumberByKey("Gain", modlst, "=", "," )
	 	LIN[ii]		=NumberByKey("Lin", modlst, "=", "," )
	 	THK[ii]		=NumberByKey("Thk", modlst, "=", "," )
	 	CLR[ii]		=NumberByKey("Clr", modlst, "=", "," )
	 	VAL[ii]		=NumberByKey("Val", modlst, "=", "," )
	 	TXT[ii]		=StringByKey("Txt", modlst, "=", "," )

 		ii+=1 
 	WHILE(ii<nw)
 	//print shift[0]
end

Function Table2Mod()					// Not used anywhere?
//==================
// write table values to wavenotes
	PauseUpdate; Silent 1
	wave/T WNAM=root:WNAM, TXT=root:TXT
	wave SHIFT=root:SHIFT, OFFSET=root:OFFSET, GAIN=root:GAIN
	wave LIN=root:LIN, THK=root:THK, CLR=root:CLR,  VAL=root:VAL
	variable nw=numpnts(WNAM)
	variable ii=0
	print OFFSET[0]*1E9
	DO
		SHIFT[ii]*=SelectNumber( abs(SHIFT[ii])<1E-7, 1, 0)		// remove rounding error near zero
		OFFSET[ii]*=SelectNumber( abs(OFFSET[ii])<1E-7, 1, 0)	
		WriteMod( $(WNAM[ii]), SHIFT[ii], OFFSET[ii], GAIN[ii], LIN[ii], THK[ii], CLR[ii], VAL[ii], TXT[ii] )
 		ii+=1 
 	WHILE(ii<nw)
 	print OFFSET[0]*1E9
end


Function ApplyTable(ctrlName) : ButtonControl
//==============
// write table values to wavenotes
	String ctrlName
	PauseUpdate; Silent 1
	WAVE/T WNAM=root:WNAM, WNAMX=root:WNAMX, TXT=root:TXT
	WAVE SHIFT=root:SHIFT, OFFSET=root:OFFSET, GAIN=root:GAIN
	WAVE LIN=root:LIN, THK=root:THK, CLR=root:CLR, VAL=root:VAL
	NVAR THKmap=root:Stack:THKmap
 	variable thkoff
	//NVAR autolin=root:Stack:autoline, autocolor=root:Stack:autocolor
	NVAR hlines=root:Stack:hiddenlines 
	variable nw=numpnts(WNAM)
	
	 SVAR gnam=root:Stack:graphnam
	 if (strlen(gnam)==0)
	 	return 0
	 endif

	string modlst
	variable ii=0, shft, offs, scl
	DO
		WAVE w=$WNAM[ii]
		WAVE wx=$WNAMX[ii]
			//List2Wave( note(iw), ",", "mod" )
		modlst=ReadMod( w )							// "root:Stack:modw" )
		//WAVE modw=root:Stack:modw
		shft=SHIFT[ii]-NumberByKey("SHIFT", modlst, "=", ",")			//modw[0]
		scl=GAIN[ii]/NumberByKey("GAIN", modlst, "=", ",")
		//print "Æshift: ",  SHIFT[ii]-NumberByKey("SHIFT", modlst, "=", ",")
		//print "Æoffset: ",  OFFSET[ii]-NumberByKey("OFFSET", modlst, "=", ",")
		//print "Ægain: ", GAIN[ii]-NumberByKey("GAIN", modlst, "=", ",")
		if (scl==0)
			abort  "zero scale factor!"
		endif
		
	//** Operation Order:  (1) remove current offset, (2) apply new gain, (3) add new offset
		w = scl * ( w - NumberByKey("OFFSET", modlst, "=", ",") ) + OFFSET[ii]
		if (exists(WNAMX[ii])==1)
 			wx += shft
 		else
 			SetScale/P x leftx(w)+shft, deltax(w), waveunits(w, 0) w
 		endif
 		
 		SHIFT[ii]*=SelectNumber( abs(SHIFT[ii])<1E-7, 1, 0)		// remove rounding error near zero
		OFFSET[ii]*=SelectNumber( abs(OFFSET[ii])<1E-7, 1, 0)	
 		WriteMod( w, SHIFT[ii], OFFSET[ii], GAIN[ii], LIN[ii], THK[ii], CLR[ii], VAL[ii], TXT[ii] ) 
 		// ** Make Shift, Offset , Gain agree in precision to WaveNote
 		// -- doesn't work because of inherent rounding errors (usage of single precision waves?)
 		//modlst=ReadMod( w )	
 		//SHIFT[ii] = NumberByKey("SHIFT", modlst, "=", ",")
 		//OFFSET[ii] = NumberByKey("OFFSET", modlst, "=", ",")
 		//GAIN[ii] = NumberByKey("GAIN", modlst, "=", ",")
 		//print "Æshift: ",  SHIFT[ii]-NumberByKey("SHIFT", modlst, "=", ",")
		//print "Æoffset: ",  OFFSET[ii]-NumberByKey("OFFSET", modlst, "=", ",")
		//print "Ægain: ", GAIN[ii]-NumberByKey("GAIN", modlst, "=", ",")
 		
 	//---DISPLAY Modification ---
 		//print NameOfWave(w)
// 		DoWindow/F $WinName(0,1)

 		DoWindow/F $gnam
 		//--Line STYLE
 			//ModifyGraph lstyle(w)=abs(LIN[i])  //cannot run macro in function
 		if (LIN[ii]>=0)
			execute "ModifyGraph lstyle("+PossiblyQuoteName(WNAM[ii])+")=abs("+num2istr(LIN[ii])+")"
		endif
 			//ModifyGraph lsize(iw)=0
 		//execute "ModifyGraph lsize("+PossiblyQuoteName(WNAM[ii])+")="+num2istr((sign(LIN[ii])+1)/2)
 		//--Line THICKNESS

 		if (THK[ii]>=0)
 			thkoff=0.5*(THKmap==2)*(THK[ii]>0.5)
			execute "ModifyGraph lsize("+PossiblyQuoteName(WNAM[ii])+")=abs("+num2str(THK[ii]-thkoff)+")"
		endif
 		//--Line COLOR  (or FILL Color for hiddenlines)
 		//if (hlines==1)
 		//	execute "ModifyGraph rgb("+PossiblyQuoteName(WNAM[ii])+")=("+ColorStr(CLR[ii])+")"
 		//else
 			execute "ModifyGraph hbFill("+PossiblyQuoteName(WNAM[ii])+")="+num2str(hlines*(CLR[ii]>=0))
 			
 		if (CLR[ii]>=0)
 			execute "ModifyGraph rgb("+PossiblyQuoteName(WNAM[ii])+")=("+ColorStr(CLR[ii])+")"
 		endif
 		//endif
 		
 		ii+=1 
 	WHILE(ii<nw)
end

Proc Check_Stack(ctrlName,checked) : CheckBoxControl
//==================
// (1) Toggle on/off dependency of ApplyTable to auto-update with modifications of Stack table columns
// Deselect "Delay Update" in table to updating for every individual entry modification
// Select "Delay Update" in table to update after cliking outside of table
// (2) Update Graph info to Stack Table
	String ctrlName
	Variable checked

	if (stringmatch( ctrlName, "*Update"))
		//perform SelectGraph operation on current graph
		SelectStackGraph("",0,root:Stack:graphnam)
		Checkbox checkUpdate value=0
	endif
	if (stringmatch( ctrlName, "*Auto"))
		variable/G root:Stack:AutoApply
		if (checked)
			// invoke dependency
			//SetFormula root:Stack:AutoApply, "AutoApplyFct(root:SHIFT, root:OFFSET, root:GAIN, root:LIN, root:THK, root:CLR, root:VAL, root:TXT)"
			root:Stack:AutoApply:=AutoApplyFct(root:SHIFT, root:OFFSET, root:GAIN, root:LIN, root:THK, root:CLR, root:VAL, root:TXT)
		else
			root:Stack:AutoApply=0
		endif
	endif
	if (stringmatch( ctrlName, "*CsrA"))
		variable/G root:Stack:CsrAonly=checked
	endif
End

Function AutoApplyFct(shift, offset, gain, lin, thk, clr, val, txt)
//==================
	Wave shift, offset, gain, lin, thk, clr, val, txt
	string winnam= WinName(0,64+16+4+2+1)
	SVAR graphnam=root:Stack:graphnam
	if (WinType(graphnam)==1)
		DoWindow/F $graphnam
		if (V_flag==1)
			ApplyTable("")
		endif
		//if (stringmatch(winnam, "StackTable"))
		//	DoWindow/F StackTable
		//endif
		DoWindow/F $winnam			//return to original top window
	endif
	return 1
End


Function/T ColorStr( iclr )
//==============
//return mapping of color index to RGB string
// Mapping:  0=black={0,0,0},  1=red={1,0,0}, 2=blue={0,0,1}, 3=green={0,0.5,0.069}
//                  4=violet={1,0,1},  5=blue-green={0,1,1},  6=orange={1,.67,0}
	variable iclr
	iclr=abs(iclr)
	string str
	make/o/n=3 root:Stack:clrw={0,0,0}
	WAVE clrw=root:Stack:clrw
	clrw[0]= (iclr==1)+(iclr==4) +(iclr==6)
	clrw[1]= (iclr==3)*0.5+(iclr==5)*0.5 +(iclr==6)*0.667
	clrw[2]= (iclr==2)+(iclr==4) +(iclr==5)+(iclr==3)*0.0690929
	clrw*=65535
	return Wave2List( clrw, ",", 0, 2 ) 
end

Static Function/S Wave2List( wav, sep, i1, i2 )
//=============================
// Convert number wave to separated string list
// from starting to ending indices
	wave wav
	string sep
	variable i1, i2
	
	variable np=numpnts(wav), i=0
	string strout=""
	i2=min(i2, np)
	do
		if (i>0)
			strout+=sep
		endif
		strout+=num2str( wav(i+i1) )
		i+=1
	while ((i+i1)<=i2)
	return strout
End

Function ShiftMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR csrAonly=root:Stack:csrAonly
	NVAR shiftval=root:Stack:shiftval
	WAVE/T WNAM=root:WNAM, WNAMX=root:WNAMX
	WAVE SHIFT=root:SHIFT
	
	variable ii=0, nw=numpnts(WNAM)
	if (csrAonly)
		ii=IndexOfWave( WNAM, CsrWave(A) )
		if (ii==-1)
			abort "Cursor A not set!"
			return 1
		endif
		nw=1
	endif

	if (popNum==1)		// Shift All by specified value
		if (csrAonly)
			SHIFT[ ii ]+=shiftval
		else
		 	SHIFT+=shiftval
		endif
	endif
	if (popNum==2)		// Incremental Shift of All waves by specified value
		if (csrAonly)
			SHIFT[ ii ]+=shiftval   // same as popNum==1
		else
		 	SHIFT+=shiftval*p		//additional (not absolute)
		endif
	endif
	if (popNum==3)		// Shift Ymax positions wave to specified value
		do
				//WAVE iw=$WNAM[ ii ]
			WaveStats/Q $WNAM[ ii ]   //iw
			if (exists(WNAMX[ ii ]))
				WAVE iwx=$WNAMX[ ii ]
				SHIFT[ ii ] += (shiftval -iwx[V_maxloc])
			else
				SHIFT[ ii ] += (shiftval -V_maxloc)
			endif
	 		ii+=1 
	 	while( ii<nw )
	endif
	if (popNum==5)		// Shift Csr A postions to Csr B value
		IF (exists(csrwave(B))==1)
			shiftval=hcsr(B)
			popStr+="="
			popNum=4
		ELSE
			abort "Cursor B not set!"
		ENDIF
	endif
	if (popNum==4)		// Shift Csr A positions to specified value
		IF (exists(csrwave(B))==1)
			if (csrAonly)
				SHIFT[ ii ] += (shiftval-hcsr(A))		//append (not overwrite)
			else
				SHIFT += (shiftval-hcsr(A))		//append (not overwrite)
			endif
		ELSE
			abort "Cursor A not set!"
		ENDIF
	endif
	if ((popNum==6)*(shiftval!=0))		// Scale X values by (non-zero) factor
		if (csrAonly)
			ScaleX( ii, shiftval)	
		else
			//ScaleX( -1, shiftval)	// all in table
			ii=0
			DO
				ScaleX( ii, shiftval)		
				ii+=1
			WHILE (ii<nw)	
		endif
	endif
	print "Shift "+popStr, shiftval

	ApplyTable(ctrlName)
End

Function ScaleX( ii, factor )
//===============
	variable ii, factor
	
	WAVE/T WNAM=root:WNAM, WNAMX=root:WNAMX
	WAVE w=$WNAM[ii]
	WAVE wx=$WNAMX[ii]
	
	if (exists(WNAMX[ii])==1)
 		wx *= factor
 	else
 		SetScale/P x leftx(w)*factor, deltax(w)*factor, waveunits(w, 0) w
 	endif
	// no record to be kept of X scaling(?)
End

Function OffsetMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR csrAonly=root:Stack:csrAonly
	NVAR offsetval=root:Stack:offsetval
	WAVE OFFSET=root:OFFSET
	WAVE/T WNAM=root:WNAM, WNAMX=root:WNAMX
	
	print "Offset "+popStr, offsetval
	variable xval
	
	variable ii=0, nw=numpnts(WNAM)
	if (csrAonly)
		ii=IndexOfWave( WNAM, CsrWave(A) )
		if (ii==-1)
			abort "Cursor A not set!"
			return 1
		endif
		nw=1
	endif
	
	if (popNum==1)		// Offset by specified value
		if (csrAonly)
			OFFSET[ ii ]+=offsetval
		else
			OFFSET+=offsetval
		endif
	endif
	if (popNum==2)		// Incremental Offset of All waves by specified value (part of Waterfall)	
		if (csrAonly)
			OFFSET[ ii ]+=offsetval		// same as first option
		else
			OFFSET+=offsetval*p		//additional (not absolute)
		endif
	endif
	if (popNum==3)		// Offset Ymin values of All wave to specified value
		do
			WaveStats/Q $WNAM[ ii ]
			OFFSET[ ii ] += (offsetval -V_min)
	 		ii+=1 
	 	while( ii<nw )
	endif
	if (popNum==4)		// Offset Csr A positions to specified value	
		IF (exists(csrwave(A))==1)
			xval=hcsr(A)
			do
				WAVE iw=$WNAM[ ii ]
				if (exists(WNAMX[ ii ]))
					WAVE iwx=$WNAMX[ ii ]
					OFFSET[ ii] += ( offsetval -interp(xval, iwx, iw) )
				else
					OFFSET[ ii] += ( offsetval - iw(xval) )
				endif
		 		ii+=1 
		 	while( ii<nw )
	 	ELSE
	 		abort "Cursor A not set!"
		ENDIF
	endif
	if ((popNum==5))		//Offset Csr A-Csr B Range Average/Area to specified value	
		IF ((exists(csrwave(A))==1)&(exists(csrwave(B))==1))
			string rng, fctcmd, cmd
			fctcmd="V_avg=faverage"
			NVAR Vavg=V_avg
			do
				WAVE iw=$WNAM[ ii ]
				if (exists(WNAMX[ ii ]))
					rng=num2str( pcsr(A) )+","+num2str( pcsr(B) )
					cmd=fctcmd+"XY("+WNAMX[ii]+","+WNAM[ii]+","+rng+")"
					execute cmd
//					print cmd, Vavg
					if (numtype(Vavg)==0)

						WAVE iwx=$WNAMX[ ii ]
						OFFSET[ ii] += ( offsetval -Vavg )		//	GAIN[ ii ] *= ( gainval / Vavg )
					else
						print WNAM[ii], WNAMX[ii], ", Vavg=",Vavg
					endif
				else
					rng=num2str(hcsr(A))+","+num2str(hcsr(B))
					cmd=fctcmd+"("+WNAM[ii]+","+rng+")"
					execute cmd
//					print cmd, Vavg
					OFFSET[ ii] += ( offsetval -Vavg )			//	GAIN[ ii ] *= ( gainval / Vavg )
				endif
		 		ii+=1 
		 	while( ii<nw )
		 ELSE
		 	abort "Cursor(s) not set!"
		 ENDIF
	endif

	ApplyTable(ctrlName)
End

Function ScaleMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR csrAonly=root:Stack:csrAonly
	NVAR gainval=root:Stack:gainval
	WAVE GAIN=root:GAIN
	WAVE/T WNAM=root:WNAM, WNAMX=root:WNAMX
	
	print "Scale "+popStr, gainval
	
	variable ii=0, nw=numpnts(WNAM), xval
	if (csrAonly)
		ii=IndexOfWave( WNAM, CsrWave(A) )
		if (ii==-1)
			abort "Cursor A not set!"
			return 1
		endif
		nw=1
	endif

	if (popNum==1)		// Scale All by specified value
		if (csrAonly)
			GAIN[ ii ]*=gainval
		else
			GAIN*=gainval
		endif
	endif
	if (popNum==3)		//  Scale Ymax to Cursor A value
		IF (exists(csrwave(A))==1)
			gainval=vcsr(A)
			if (numtype( gainval )!=0)
				abort "Cursor Value not set!"
				return 1
			endif
			popNum=2
		ELSE
	 		abort "Cursor A not set!"
		ENDIF
	endif
	if (popNum==2)		// Scale Ymax to specified value
		do
			WaveStats/Q $WNAM[ ii ]
			//GAIN[ ii ] *= SelectNumber( V_max==0, (gainval /V_max), 1)
			if (V_max!=0)
				GAIN[ ii ] *= ( gainval / V_max )
			else
				print WNAM[ii], WNAMX[ii], ", V_max=", V_max
			endif
	 		ii+=1 
	 	while( ii<nw )
	endif
	if (popNum==5)		//Scale Csr A positions to Csr A value	
		IF (exists(csrwave(A))==1)
			gainval=vcsr(A)
			popNum=4
		ELSE
	 		abort "Cursor A not set!"
		ENDIF
	endif
	if (popNum==4)		//Scale Csr A positions to specified value	
		IF (exists(csrwave(A))==1)
			xval=hcsr(A)
			variable vinterp
			do
				WAVE iw=$WNAM[ ii ]
				if (exists(WNAMX[ ii ]))
					WAVE iwx=$WNAMX[ ii ]
					vinterp=interp(xval, iwx, iw)
					//print WNAMX[ii], vinterp
					if (numtype(vinterp)==0)
						GAIN[ ii ] *= ( gainval / vinterp )
					else
						print WNAM[ii], WNAMX[ii], ", Csr(A)=", vinterp
					endif
				else
					GAIN[ ii ] *= ( gainval / iw(xval) )
				endif
				//print WNAMX[ii], vinterp, gainval, GAIN[ii]
				IF (GAIN[ii]==0)
					abort "zero GAIN:"+num2str(GAIN[ii])
				ENDIF
		 		ii+=1 
		 	while( ii<nw )
	 	ELSE
	 		abort "Cursor A not set!"
		ENDIF
	endif
	if ((popNum==6)+(popNum==7))		//Scale Csr A-Csr B Range Average/Area to specified value	
		IF ((exists(csrwave(A))==1)&(exists(csrwave(B))==1))
			//xval=hcsr(A)
//			string rng="/R=("+num2str(hcsr(A))+","+num2str(hcsr(B))+") ", cmd
			string rng, fctcmd, cmd
			fctcmd=SelectString( popNum==7, "V_avg=faverage", "V_avg=area")
			//variable pA, pB
			NVAR Vavg=V_avg
			do
				WAVE iw=$WNAM[ ii ]
				if (exists(WNAMX[ ii ]))
					//pA=x2pnt(iw,hcsr(A))
					//pB=x2pnt(iw,hcsr(B))
//					rng="/R=["+num2str( pcsr(A) )+","+num2str( pcsr(B) )+"] "
					rng=num2str( pcsr(A) )+","+num2str( pcsr(B) )
//					cmd="WaveStats/Q/R=["+rng+"] "+WNAM[ii]
//					execute "WaveStats/Q/R=["+rng+"]"+WNAM[ii]
					cmd=fctcmd+"XY("+WNAMX[ii]+","+WNAM[ii]+","+rng+")"
					execute cmd
//					print cmd, Vavg
					//WAVE iwx=$WNAMX[ ii ]
					//GAIN[ ii ] *= ( gainval /interp(xval, iwx, iw) )
					if (numtype(Vavg)==0)
						GAIN[ ii ] *= ( gainval / Vavg )
					else
						print WNAM[ii], WNAMX[ii], ", Vavg=",Vavg
					endif
				else
					rng=num2str(hcsr(A))+","+num2str(hcsr(B))
//					cmd="WaveStats/Q/R=("+rng+") "+WNAM[ii]
//					execute "WaveStats/Q/R=("+rng+")"+WNAM[ii]
					cmd=fctcmd+"("+WNAM[ii]+","+rng+")"
					execute cmd
//					print cmd, Vavg
					GAIN[ ii ] *= ( gainval / Vavg )
				endif
		 		ii+=1 
		 	while( ii<nw )
		 ELSE
		 	abort "Cursor(s) not set!"
		 ENDIF
	endif

	//ApplyTable(ctrlName)
End

Function StyleMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	WAVE LIN=root:LIN, CLR=root:CLR
	SVAR style=root:Stack:whichstyle
	variable irepeat, ioffset
	//ioffset=ValFromList( style, 0, ",")
	//irepeat=ValFromList( style, 1, ",")
	ioffset=str2num( StringFromList( 0, style, ","))
	irepeat=str2num( StringFromList(1,  style, ","))
	if (numtype(irepeat)!=0)
		irepeat=ioffset; ioffset=0
	endif
	//print ioffset, irepeat
	
	//print popNum
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

	ApplyTable(ctrlName)
End

Proc TagMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	//variable irepeat=trunc(root:Stack:styleval), ioffset
	//ioffset=trunc(10*(root:Stack:styleval-irepeat)+.001)
	//string which=num2istr(irepeat)+","+num2istr(ioffset) 
	string tagStr=StringFromList( popNum-1, "VAL;TXT;;VAL;TXT;" )
	string tagAtStr=StringFromList( popNum-1, ";;VAL;VAL;VAL;" )
	//print tagStr, ", At=", tagAtStr
	
	if (popNum<=5)
		if (exists("root:tag:prefix")==0)
			TagPrefs()
		endif
		TagWaves(tagStr, root:Stack:whichStyle, tagAtStr, 1)
	else
		if ((popNum==7)+(popNum==8))
			string tagprefix=StringFromList(popNum-7, "t;t_")
			RemoveTags( tagprefix, root:Stack:whichStyle )
		endif
		if (popNum==9)
			TagPrefs()
		endif
		if (popNum==11)
			Legend_()
		endif
	endif

	DoWindow/F $WinName(0,1)
End


Function ResetMenu(ctrlName,popNum,popStr) : PopupMenuControl
//==============
	String ctrlName
	Variable popNum
	String popStr
	
	WAVE SHIFT=root:SHIFT, OFFSET=root:OFFSET,  GAIN=root:GAIN
	WAVE LIN=root:LIN, THK=root:THK, CLR=root:CLR
	NVAR styleval=root:Stack:styleval
	variable irepeat=trunc(styleval), ioffset
	ioffset=trunc(10*(styleval-irepeat))
	
	NVAR csrAonly=root:Stack:csrAonly
	if (csrAonly)
		variable indx=IndexOfWave( WNAM, CsrWave(A) )
		if (indx==-1)
			abort "Cursor A not set!"
			return 1
		endif
		if (popNum==2)
			SHIFT[ indx ]=0
		endif
		if (popNum==3)
			OFFSET[ indx ]=0
		endif
		if (popNum==4)
			GAIN[ indx ]=1
		endif
		if ((popNum==5)+(popNum==1))
			SHIFT[ indx ]=0; OFFSET[ indx ]=0; GAIN[ indx ]=1
		endif
		
		if (popNum==6)
			LIN[ indx ]=0
		endif
		if (popNum==7)
			THK[ indx ]=1				// 0.5 previously
		endif
		if (popNum==8)
			CLR[ indx ]=0
		endif
		if ((popNum==9)+(popNum==1))
			LIN[ indx ]=0; THK[ indx ]=1; CLR[ indx ]=0
		endif
		if (popNum==10)
			LIN[ indx ]=-1; THK[ indx ]=-1; CLR[ indx ]=-1
		endif
		
		if (popNum==12)
			execute "ResetNotes(,\""+CsrWave(A) +"\")"		//reset CsrA wave only?
		endif
		if (popNum==13)
			execute "ClearOffsets()"	//reset CsrA wave only?
		endif
		if (popNum==12)
			LIN[ indx ]=-1; THK[ indx ]=-1; CLR[ indx ]=-1
		endif
	else
		if (popNum==2)
			SHIFT=0
		endif
		if (popNum==3)
			OFFSET=0
		endif
		if (popNum==4)
			GAIN=1
		endif
		if ((popNum==5)+(popNum==1))
			SHIFT=0; OFFSET=0; GAIN=1
		endif
		
		if (popNum==6)
			LIN=0
		endif
		if (popNum==7)
			THK=1
		endif
		if (popNum==8)
			CLR=0
		endif
		if ((popNum==9)+(popNum==1))
			LIN=0; THK=1; CLR=-0
		endif
		if (popNum==10)
			LIN=-1; THK=-1; CLR=-1
		endif
		
		if (popNum==12)
			execute "ResetNotes(,\"ALL\")"
		endif
		if (popNum==13)
			execute "ClearOffsets()"
		endif
	endif
	if (popNum==14)			// no immediate effect on table or plot
		execute "StackLinePrefs()"
	else
		ApplyTable(ctrlName)
	endif

End


Function StackWaves(ctrlName,popNum,popStr) : PopupMenuControl
//==============
// Combination of Shift and Offset
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR sval=root:Stack:shiftval, oval=root:Stack:offsetval,  hlines=root:Stack:hiddenlines
	WAVE SHIFT=root:SHIFT, OFFSET=root:OFFSET
	if (popNum==1)		//additional shift and stack
		SHIFT+=sval*p; OFFSET+=oval*p
		ApplyTable(ctrlName)
	endif
	if (popNum==2)		//absolute shift and stack
		SHIFT=sval*p; OFFSET=oval*p
		WaveStats/Q OFFSET
		if ((V_min<0)*(hlines==1)) 		// offset min negative value to zero
			OFFSET-=V_min
		endif
		ApplyTable(ctrlName)
	endif
	if ((popNum>=3)*(popNum<=5))
		SVAR gnam=root:Stack:graphnam
	 	DoWindow/F $gnam
		if (popNum==5)		// turn off fill mode
			ModifyGraph mode=0
			hlines=0
		else						// turn on hidden/solid fill lines
			ModifyGraph mode=7, hbfill=(popNum-2)		// turn on fill to zero mode (erase=1, solid=2)
			hlines=popNum-2
		endif
	endif
	
	if (popNum==6)		// reorder of trace by sort of VAL column (generalize to other columns?)
		WAVE/T WNAM=root:WNAM
		WAVE VAL=root:VAL, TXT=root:TXT
		variable  nw1=numpnts(WNAM)
		//Sort VAL, WNAM
		//Sort TXT, WNAM
		Sort {VAL,TXT}, WNAM
		if (nw1>1)
			SVAR gnam=root:Stack:graphnam
			DoWindow/F $gnam
			string wnamlst=Textw2List(WNAM,",",0,99)
			execute "ReorderTraces "+WNAM[0]+", {"+wnamlst+"}"
			Mod2Table()			// Refresh table
		endif
	endif
	
	if (popNum==7)		// reverse order of traces
		WAVE/T WNAM=root:WNAM
		variable  nw=numpnts(WNAM)
		if (nw>1)
			SVAR gnam=root:Stack:graphnam
			DoWindow/F $gnam
			variable ii=0
			DO
				ReorderTraces $WNAM[ii], { $WNAM[ii+1] }
				ii+=1
			WHILE(ii<nw-1)
			
			//string cmd="ReorderTraces "+WNAM[0]+", {"
			//variable ii=nw-1
			//DO
			//	cmd+=WNAM[ii]+","
			//	ii-=1
			//WHILE( ii>1)
			//cmd+=WNAM[1]+"}"

			//print cmd
			//execute cmd					// Reorder A, {Z, Y, ...,B}  //Can't handle too long of string
			Mod2Table()			// Refresh table
		endif
	endif

End

Function ExpandWaves(ctrlName,popNum,popStr) : PopupMenuControl
//================
//Combination of Offset and Gain
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR csrAonly=root:Stack:csrAonly
	NVAR gval=root:Stack:gainval, oval=root:Stack:offsetval
	WAVE GAIN=root:GAIN, OFFSET=root:OFFSET
	WAVE/T WNAM=root:WNAM,  WNAMX=root:WNAMX
	//NVAR Vmin=V_min, Vmax=V_max
	
	print "Expand "+popStr, oval, gval
	
	variable  ii=0, nw=numpnts(WNAM), ngain
	if (csrAonly)
		ii=IndexOfWave( WNAM, CsrWave(A) )
		if (ii==-1)
			abort "Cursor A not set!"
			return 1
		endif
		nw=1
	endif
	
	if (popNum==2)				//expand to Csr A wave range
		IF (exists(csrwave(A))==1)
			Wavestats/Q CsrWaveRef(A)
			gval=V_max; oval=V_min
		ELSE
	 		abort "Cursor A not set!"
		ENDIF
	endif
	if (popNum<=2)
		do
			WaveStats/Q $WNAM[ ii ]
			ngain=(gval-oval)/(V_max-V_min)
			//print WNAM[ii], WNAMX[ii], ", ngain=",ngain
			if (numtype(ngain)==0)
				GAIN[ ii ] *= ngain
				OFFSET[ ii ] = oval - ngain*(V_min-OFFSET[ ii ]) 		// assumes ApplyTable does GAIN first
			else
				print WNAM[ii], WNAMX[ii], ", ngain=", ngain
			endif	
		 	ii+=1 
		while( ii<nw )
	endif
	if (popNum==3)		// Expand cursor positions to values
		IF((exists(csrwave(A))==1)&(exists(csrwave(B))==1))
			variable x1=hcsr(A), x2=hcsr(B), v1, v2
			do
				WAVE iw=$WNAM[ ii ]
				if (exists(WNAMX[ ii ]))
					WAVE iwx=$WNAMX[ ii ]
					v1= interp(x1, iwx, iw); v1= interp(x1, iwx, iw)
				else
					v1=iw( x1 ); v2=iw( x2 )
				endif
				ngain=(gval-oval)/abs(v1-v2)			// sort into v_min, v_max?
				//print WNAM[ii], WNAMX[ii], ", ngain=",ngain
				if ((numtype(ngain)==0)*(ngain!=0))
					GAIN[ ii ] *= ngain
					OFFSET[ ii ] = oval - ngain*(min(v1,v2)-OFFSET[ ii ])		// assumes ApplyTable does GAIN first
				else
					print WNAM[ii], WNAMX[ii], ", ngain=", ngain
				endif
			 	ii+=1 
			while( ii<nw )
		ELSE
			abort "Cursor(s) not set!"
		ENDIF
	endif
	if (popNum==4)		// Expand min/max within cursor A-B range to values
		IF((exists(csrwave(A))==1)&(exists(csrwave(B))==1))
			//variable x1=hcsr(A), x2=hcsr(B), v1, v2
			string rng="/R=("+num2str(hcsr(A))+","+num2str(hcsr(B))+") ", cmd
			variable/G root:V_max, root:V_min
			NVAR vmax=root:V_max, vmin=root:V_min
			do
				rng="/R=["+num2str( pcsr(A) )+","+num2str( pcsr(B) )+"] "
				cmd="WaveStats/Q"+rng+WNAM[ii]
				execute "WaveStats/Q"+rng+WNAM[ii]
				//print cmd, V_max, V_min, Vmin, Vmax
				//print cmd, Vmax, Vmin
				ngain=(gval-oval)/(vmax-vmin)
				if ((numtype(ngain)==0)*(ngain!=0))
					GAIN[ ii ] *= ngain
					OFFSET[ ii ] = oval - ngain*(vmin-OFFSET[ ii ])
				else
					print WNAM[ii], WNAMX[ii], ", ngain=", ngain
				endif
			 	ii+=1 
			while( ii<nw )
		ELSE
			abort "Cursor(s) not set!"
		ENDIF
	endif
	
	ApplyTable(ctrlName)
End

// also found in List_Util.ipf
Static Function List2TextW( list, separator, outw )
//================================
// convert string list to string array (text wave)
	string list, separator, outw
	variable NL=ItemsInList( list, separator )
	make/O/T/n=(NL) $outw
	wave/T ow=$outw
	variable i=0, indx
	string istr, list2=list
	do
		ow[i]=StringFromList( i, list, separator )
		i+=1
	while (i<NL)
	return i
End

// also found in List_Util.ipf
Static Function IndexOfWave( wv, str )
//================================
// return index of text wave matching given string 
// (similar to built-in "FindListItem" for a STRING list)
	wave/T wv
	string str
	make/o/n=( max(numpnts(wv), 2) ) match=nan
	match=ABS( cmpstr(wv[p], str) )				// ABS(-1, 0=match, 1)
	FindLevel/P/Q match,0
	if (V_flag==0)
		return V_LevelX
	else
		return -1
	endif
	killwaves match
End




Window StackTable() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/K=1/W=(376,103,868,316) WNAM,WNAMX,SHIFT,OFFSET,GAIN,LIN,THK,CLR,VAL,TXT as "Stack Table"
	ModifyTable size=9,alignment=1,width(Point)=22,width(WNAM)=68,width(WNAMX)=60,width(SHIFT)=48
	ModifyTable width(OFFSET)=48,sigDigits(GAIN)=4,width(GAIN)=56,width(LIN)=22,width(THK)=22
	ModifyTable width(CLR)=22,width(VAL)=48,width(TXT)=60
EndMacro

Window StackPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /K=1/W=(635,375,929,512)
	ModifyPanel cbRGB=(65535,65535,0)
	SetDrawLayer UserBack
	DrawRRect 244,73,245,73
	SetDrawEnv fillfgc= (65535,16385,16385)
	DrawRRect 5,30,281,83
	SetDrawEnv fsize= 10
	DrawText 13,102,"v4.01"
	PopupMenu GraphPop,pos={21,4},size={100,19},proc=SelectStackGraph,title=""
	PopupMenu GraphPop,mode=1,popvalue="Graph0",value= #"WinList(\"!Load*\",\";\",\"WIN:1\")"
	PopupMenu GraphPop,help={"Active plot window selection"}
	Button ApplyButton,pos={202,6},size={78,19},proc=ApplyTable,title="ApplyTable"
	Button ApplyButton,help={"Modify traces & Write values from StackTable into Trace wave notes"}
	PopupMenu ShiftMenu,pos={20,37},size={59,19},proc=ShiftMenu,title="Shift  "
	PopupMenu ShiftMenu,mode=0,value= #"\"Shift by:;Incremental shift by:;YMAX Position(s) to:;Csr A Position(s) to:;Csr A to Csr B;Scale By:\""
	SetVariable shiftval,pos={19,60},size={75,17},title=" "
	SetVariable shiftval,help={"value used for horizontal SHIFT options"}
	SetVariable shiftval,limits={-Inf,Inf,1},value= root:Stack:shiftval
	SetVariable offsetval,pos={111,60},size={75,17},title=" "
	SetVariable offsetval,help={"value used for vertical OFFSET options"}
	SetVariable offsetval,limits={-Inf,Inf,1},value= root:Stack:offsetval
	PopupMenu OffsetMenu,pos={111,36},size={61,19},proc=OffsetMenu,title="Offset"
	PopupMenu OffsetMenu,mode=0,value= #"\"Offset by:;Incremental stack by:;YMIN value(s) to:;Csr A position(s) to:;Csr A-B average to:\""
	PopupMenu WaterFall,pos={45,86},size={84,19},proc=StackWaves,title="Waterfall"
	PopupMenu WaterFall,help={"combined use of SHIFT & OFFSET values"}
	PopupMenu WaterFall,mode=0,value= #"\"Additional;Absolute;Hidden Lines ON;Solid Fill ON;Hidden/Fill OFF;Sort By VAL/TXT;Reverse Order\""
	PopupMenu ScaleMenu,pos={202,36},size={62,19},proc=ScaleMenu,title="Scale "
	PopupMenu ScaleMenu,mode=0,value= #"\"Scale by:;YMAX value(s) to:;YMAX to CsrA value;Csr A position(s) to:;Csr A posns to Csr A val;Csr A-B average to:;Csr A-B area to:\""
	SetVariable gainval,pos={196,60},size={75,17},title=" "
	SetVariable gainval,help={"value used for data SCALING options"}
	SetVariable gainval,limits={-Inf,Inf,1},value= root:Stack:gainval
	PopupMenu ExpandMenu,pos={140,86},size={71,19},proc=ExpandWaves,title="Expand"
	PopupMenu ExpandMenu,help={"combined use of OFFSET & SCALE values"}
	PopupMenu ExpandMenu,mode=0,value= #"\"to values;to Csr A wave range;Csr A,B posns to values;Csr A-B range to values\""
	SetVariable styleval,pos={85,111},size={40,17},title=" "
	SetVariable styleval,help={"Start,  Inc  (or Inc) values for application of Style & Tag options"}
	SetVariable styleval,limits={0,Inf,0.1},value= root:Stack:whichstyle
	PopupMenu StyleMenu,pos={15,110},size={59,19},proc=StyleMenu,title="Style "
	PopupMenu StyleMenu,help={"Change Linestyle and/or Color of Wave Traces"}
	PopupMenu StyleMenu,mode=0,value= #"\"Auto Line;Auto Color;Line&Color;Solid/Dash:;Red/Black:;S/D & R/B:\""
	PopupMenu ResetMenu,pos={212,109},size={63,19},proc=ResetMenu,title="Reset "
	PopupMenu ResetMenu,mode=0,value= #"\"All;  Shift=0;  Offset=0;  Gain=1;S,O,G=0,0,1;  Line=0;  Thick=1;  Color=0;L,T,C=0,1,0;L,T,C=-1;-;Trace Note;XY offsets;Line Prefs\""
	PopupMenu ResetMenu,help={"Reset Table value(s) to defaults, OR just reset trace note value(s), OR clear graph XY offsets "}
	PopupMenu TagMenu,pos={129,110},size={47,19},proc=TagMenu,title="Tag"
	PopupMenu TagMenu,help={"Annotate Traces with Tags derived from VAL and TXT fields.  Tag 'At ' options show an Arrow head.  "}
	PopupMenu TagMenu,mode=0,value= #"\"with VAL;with TXT;Arrow at VAL;VAL at VAL;TXT at VAL;-;Remove 'with';Remove 'at';Prefs;-;Legend\""
	CheckBox checkAuto,pos={183,6},size={16,20},proc=Check_Stack,title=""
	CheckBox checkAuto,help={"Toggle auto-update of Table:   Select \"Delay Update\" in table to update only after clicking outside of table."},value=0
	CheckBox checkUpdate,pos={3,6},size={16,20},proc=Check_Stack,title=""
	CheckBox checkUpdate,help={"Refresh current graph info to Stack Table"},value=0
	CheckBox checkCsrA,pos={226,88},size={50,20},proc=Check_Stack,title="CsrA only"
	CheckBox checkCsrA,help={"Toggle selection of Cursor(A) wave only for Shift/Offset/Scale operations."},value=0
EndMacro
