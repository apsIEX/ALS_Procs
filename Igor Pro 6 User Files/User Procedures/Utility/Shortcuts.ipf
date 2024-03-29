// File:  Shortcuts		created: ~1998
// Jonathan Denlinger, JDDenlinger@lbl.gov 

//  3/8/09 jdd -- add Det. Angle () lable to axis_lst()
// 12/14/08 jdd -- added character code for Angstrom character in axis_lst(), e.g. char2num("�")=-127/-59 (Mac/PC
// 12/9/08 jdd -- added degree versions of trig functions
// 8/30/08 jdd -- revamp GraphAxes & ImageAxes into single PlotAxes()
//  6/18/04  jdd -- converted GraphAxes & Image Axes to functions; make axis_list() STATIC function
//  5/26/01  jdd  -- added dispi( img ) with _CT colortable if exists
//  5/10/01  jdd 	-- updated GraphAxes & ImageAxes to allow adding new items to 
//                                   a single global list of axis labels;  uses axis_list() function

#pragma rtGlobals=1		// Use modern global access method.

menu "Graph"
	"Plot Axes"
//	"Graph Axes"
//	"Image Axes"
	"Zero Lines"
	"Std Axis Labels"
	"Thin And Black"
	submenu "ShortCuts"
		"dispx{ yw } -- Display yw vs yw_x"
		"appx{ yw } --  Append yw vs yw_x"
		"editx{ yw } --  Edit yw, yw_x"
		"dupx{ yw, ext } -- Duplicate yw vs yw_x"
		"dispi{ img } -- Display image with ctab=*_CT"
		"appi{ img } -- Append image with ctab=*_CT"
		"sdf{ subfolder } -- SetDataFolder root:subfolder"
		"root{}--SetDataFolder root:"
	end
	"Std_Lyt"
end

menu "Misc"
	"Surface Plotter", CreateSurfer
end

proc FixAll()
	FixAxes()
	ThinAndBlack()
end

static function/T axis_list()
//===============
	if (exists("root:PLOT:axis_lst")==0)
		NewDataFolder/O root:PLOT
		String/G root:PLOT:axis_lst
		SVAR liststr=root:PLOT:axis_lst
		// ASCII extended character set (ascii-table.com)
		//   Angstrom:  IBM PC dec=143, hex = 8F, uni-code=U+00C5 
		//  Angstrom: Apple PC dec =129 , hex=81, uni-code=U+00C5 
		//  Degree:  IBM PC  dec=167, hex=A7, uni-code=U+00BA
		// Degree:  Apple, dec= 161, hex=A1, uni-code=U+00BA
// Decimal to Hex:	�printf  "%X\r", 143   --> 8F
		variable macOS =  Stringmatch(IgorInfo(2),"Macintosh")			// 0=WIndows
		string ANG=SelectString( macOS, num2char(-59), num2char(-127))		// PC/Mac Angstrom character
//		string DEG=SelectString( macOS, num2char(-__), num2char(-95))		//degree character
// �printf  "%X\r", -127    --> FFFFFF81
// �printf  "%X\r", -59    -->   FFFFFFC5
// �printf  "%X\r", -95    -->  FFFFFFA1
		liststr="-;Intensity (Arb. Units);Intensity (kHz);-;"
		liststr+="Binding Energy (eV);Kinetic Energy (eV);Photon Energy (eV);E-E\BF\M (eV);-;"
		liststr+="Temperature (K);time (sec);time (min);"
		liststr+="Polar Angle (deg);Azimuth Angle (deg);Elevation Angle (deg);Det. Angle (deg);Det. Angle (pixel);-;"
		liststr+="k\BX\M ("+ANG+"\S-1\M);k\By\M ("+ANG+"\S-1\M);k\BZ\M ("+ANG+"\S-1\M);X (�m);Y (�m);-;"
	else
		SVAR liststr=root:PLOT:axis_lst
	endif
	return liststr	
end

function GraphAxes()		//(ylblpop, ylbl, xlblpop, xlbl, std, fontsize)
//=================
	variable std=1, fontsize=1
	string xlbl="", ylbl=""
	string  xlblpop=StrVarOrDefault("root:PLOT:xlabel","x"), ylblpop=StrVarOrDefault("root:PLOT:ylabel","y")
	prompt std,"Operations Performed:", popup,"Ticks Inside;Axis Thick=0.5;Mirror On, No Ticks (Left);Minor Tick off( Left);"
	prompt fontsize, "Font Size", popup, "Auto (10);12"
	prompt ylblpop, "Y (left) label", popup, axis_list()
	prompt ylbl, "Y label (add to list)"
	prompt xlblpop, "X (bottom) label", popup, axis_list()
	prompt xlbl, "X label (add to list)"
	DoPrompt "Graph Axes", ylblpop, ylbl, xlblpop, xlbl, std, fontsize
	PauseUpdate; Silent 1
	
	NewDataFolder/O root:PLOT
	String/G root:PLOT:xlabel, root:PLOT:ylabel
	SVAR xlabel=root:PLOT:xlabel, ylabel=root:PLOT:ylabel
	SVAR axis_lst=root:PLOT:axis_lst
	
	if (strlen(xlbl)==0)
		xlabel=xlblpop
	else
		xlabel=xlbl
		axis_lst+=xlbl+";"
	endif
	if (strlen(ylbl)==0)
		ylabel=ylblpop
	else
		ylabel=ylbl
		axis_lst+=ylbl+";"
	endif
	
	Label left ylabel
	Label bottom xlabel
	
	PauseUpdate; Silent 1
	ModifyGraph tick=2, minor=1, sep=8
	ModifyGraph fSize=12*(fontsize==2)
	ModifyGraph axThick=0.5
	
	ModifyGraph mirror(bottom)=1
	ModifyGraph minor(left)=0
	ModifyGraph mirror(left)=2
end

function ImageAxes([x,y])	
//=============
	string x, y
	variable fontsize, std=1
	
	NewDataFolder/O root:PLOT
	String/G root:PLOT:xlabel, root:PLOT:ylabel
	SVAR xlabel=root:PLOT:xlabel, ylabel=root:PLOT:ylabel
	SVAR axis_lst=root:PLOT:axis_lst	
	
	if (ParamIsDefault(x))
		x=xlabel
	endif
	if (ParamIsDefault(y))
		y=ylabel
	endif

//  Skip dialog if either x & y axis labels specified
	IF (ParamIsDefault(x) && ParamIsDefault(y))	
		string  xpop=StrVarOrDefault("root:PLOT:xlabel","x"), ypop=StrVarOrDefault("root:PLOT:ylabel","y")
		print xpop, ypop
		prompt fontsize, "Font Size", popup, "Auto (10);12"
		prompt std,"Operations Performed:", popup,"Ticks Outside;Axis Thick=0.5;Mirror On, No Ticks;Axis Standoff=0;Minor Tick off"
		prompt ypop, "Y (left) label", popup, axis_list()
		prompt y, "Y label (add to list)"
		prompt xpop, "X (bottom) label", popup, axis_list()
		prompt x, "X label (add to list)"
		DoPrompt "Image Axes" ypop, y, xpop, x, std, fontsize
	ENDIF

//  Screen out dashes	
	x=SelectString( stringMatch(x,"-"), x, "")
	y=SelectString( stringMatch(y,"-"), y, "")
// Write globals & update label list if item is new
	if (strlen(x)==0)
		xlabel=xpop
	else
		xlabel=x
		if (WhichListItem( x, axis_list())<0)
			axis_lst=x+";"+axis_lst
//			axis_lst+=x+";"
		endif
	endif
	if (strlen(y)==0)
		ylabel=ypop
	else
		ylabel=y
		if (WhichListItem( y, axis_list())<0)	
			axis_lst=y+";"+axis_lst
		endif
	endif

// Apply labels to top plot	
	Label left "\u#2"	+ylabel		//manual override to suppress axis units from being displayed on axis
	Label bottom "\u#2"+xlabel
// Apply standard image formatting
	PauseUpdate; Silent 1
	ModifyGraph tick=0, minor=0, sep=8
	ModifyGraph fSize=12*(fontsize==2)
	ModifyGraph mirror(bottom)=2
	ModifyGraph mirror(left)=2
	ModifyGraph axThick=0.5,standoff=0
// Print command to history that can be reused	
	print "ImageAxes(x=\""+xlabel+"\", y=\""+ylabel+"\")"
end

function PlotAxes([x,y,s])	
//=============
	string x, y,s
	variable fontsize, std=1
	
	NewDataFolder/O root:PLOT
	String/G root:PLOT:xlabel, root:PLOT:ylabel, root:PLOT:style
	SVAR xlabel=root:PLOT:xlabel, ylabel=root:PLOT:ylabel
	SVAR style=root:PLOT:style	
	SVAR axis_lst=root:PLOT:axis_lst	
	
	if (ParamIsDefault(x))
		x=xlabel
	endif
	if (ParamIsDefault(y))
		y=ylabel
	endif
	if (ParamIsDefault(s))
		s=StrVarOrDefault("root:PLOT:style","Img_Style")	
	endif

	

//  Skip dialog if either x & y axis labels specified
	IF (ParamIsDefault(x) && ParamIsDefault(y))	
		string  xpop=StrVarOrDefault("root:PLOT:xlabel","x"), ypop=StrVarOrDefault("root:PLOT:ylabel","y")
		x = SelectString( WhichListItem( x, axis_list())<0, "", x)
		y = SelectString( WhichListItem( y, axis_list())<0, "", y)
		prompt fontsize, "Font Size", popup, "Auto (10);12"
		prompt s,"Graph Style:", popup, MacroList("*_Style",";","")
		prompt ypop, "Y (left) label", popup, axis_list()
		prompt y, "Y label (add to list)"
		prompt xpop, "X (bottom) label", popup, axis_list()
		prompt x, "X label (add to list)"
		DoPrompt "Image Axes" ypop, y, xpop, x, s, fontsize
	ENDIF

//  Screen out dashes	
	x=SelectString( stringMatch(x,"-"), x, "")
	y=SelectString( stringMatch(y,"-"), y, "")
// Write globals & update label list if item is new
	if (strlen(x)==0)
		xlabel=xpop
	else
		xlabel=x
		if (WhichListItem( x, axis_list())<0)
			axis_lst=x+";"+axis_lst
//			axis_lst+=x+";"
		endif
	endif
	if (strlen(y)==0)
		ylabel=ypop
	else
		ylabel=y
		if (WhichListItem( y, axis_list())<0)	
			axis_lst=y+";"+axis_lst
		endif
	endif
	style=s+SelectString(strsearch(s, "_Style",0)<0, "","_Style")

// Apply labels to top plot	
	Label left "\u#2"	+ylabel		//manual override to suppress axis units from being displayed on axis
	Label bottom "\u#2"+xlabel
// Apply Style format
	execute style+"()"
	ModifyGraph fSize=12*(fontsize==2)

// Print command to history that can be reused	
	variable pp=strsearch(s, "_", 0)
	if (stringmatch(style[0,pp-1],"Img"))		// Default style format
		print "PlotAxes(x=\""+xlabel+"\", y=\""+ylabel+"\")"
	else
		print "PlotAxes(x=\""+xlabel+"\", y=\""+ylabel+"\", s=\""+style[0,pp-1]+"\")"
	endif
end

Proc Img_Style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z mirror(bottom)=2
	ModifyGraph/Z mirror(left)=2
	ModifyGraph/Z tick=0, minor=0, sep=8
	ModifyGraph/Z axThick=0.5,standoff=0
EndMacro

Proc Graph_Style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z mirror(bottom)=2
	ModifyGraph/Z mirror(left)=2
	ModifyGraph minor(left)=0
	ModifyGraph/Z tick=2, minor=1, sep=8
	ModifyGraph/Z axThick=0.5
EndMacro


proc FixAxes()
	PauseUpdate; Silent 1
	ModifyGraph tick=2, minor=1, sep=8
	ModifyGraph fSize=12
	ModifyGraph mirror=1
	ModifyGraph mirror(left)=2,minor(left)=0

end

proc ZeroLines()
	ModifyGraph zero=2
end

proc ThinAndBlack()
	ModifyGraph rgb=(0,0,0), lsize=0.01
end

function/T dupx( yw, ext )
//===========
	wave yw
	string ext
	string xwn=NameOfWave( yw )+"_x"
	string ywn2, xwn2
	ywn2=NameOfWave( yw )+ext
	xwn2=ywn2+"_x"
	duplicate/o yw $ywn2
	duplicate/o $xwn $xwn2
	return "Created: "+ywn2+" vs "+xwn2
end

function dispx( yw )
//===========
	wave yw
	string xwn=NameOfWave( yw )+"_x"
	display yw vs $xwn
end

function appx( yw )
//==========
	wave yw
	string xwn=NameOfWave(yw)+"_x"
	if (WinType(Winname(0,3))==1)
		 AppendToGraph yw vs $xwn
	else
		AppendToTable  $xwn, yw
	endif
end

function editx( yw )
//==========
	wave yw
	string xwn=NameOfWave( yw )+"_x"
	edit $xwn, yw
end

Proc Std_Lyt(win1, win2, win3)
//----------------
	string win1, win2, win3
	prompt win1, "Graph 1 (left):", popup, WinList("*",";","WIN:1")
	prompt win2, "Graph 2 (middle/right):", popup, WinList("*",";","WIN:1")
	prompt win3, "Graph 3 (right):", popup, "_none_;"+WinList("*",";","WIN:1")
	PauseUpdate; Silent 1
	if (cmpstr(win3,"_none_")==0)		//only two graphs
		Layout/C=1 $win1, $win2
		Dual_Lyt_Style()
	else
		Layout/C=1 $win1, $win2, $win3
		Three_Lyt_Style()	
	endif
End

Proc Dual_Lyt_Style() : LayoutStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyLayout/Z frame=0,trans=1
	ModifyLayout/Z left[0]=124,top[0]=119,width[0]=252,height[0]=396
	ModifyLayout/Z left[1]=378,top[1]=119,width[1]=252,height[1]=396
EndMacro

Proc Three_Lyt_Style() : LayoutStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyLayout/Z frame=0,trans=1
	ModifyLayout/Z left[0]=42,top[0]=123,width[0]=234,height[0]=396
	ModifyLayout/Z left[1]=276,top[1]=121,width[1]=234,height[1]=396
	ModifyLayout/Z left[2]=500,top[2]=123,width[2]=234,height[2]=396
EndMacro

Function root()
	SetDataFolder root:
End

Function sdf(subf)
	string subf
	SetDataFolder $("root:"+subf)
End

Window FunctionBrowser() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(348,93,579,242)
	SetDrawLayer UserBack
	PopupMenu popProcList,pos={31,17},size={70,19},title="Graphs"
	PopupMenu popProcList,mode=1,value= #"FunctionList(\"*\",\";\",\"KIND:2,SUBTYPE:Graph\")"
	PopupMenu popButtonList,pos={32,41},size={149,19},title="Buttons"
	PopupMenu popButtonList,mode=1,value= #"FunctionList(\"*\",\";\",\"KIND:2,SUBTYPE:ButtonControl\")"
	PopupMenu popPopupList,pos={39,83},size={181,19},title="Popup"
	PopupMenu popPopupList,mode=1,value= #"FunctionList(\"*\",\";\",\"KIND:2,SUBTYPE:PopupMenuControl\")"
	PopupMenu popSetVarList,pos={37,62},size={135,19},title="SetVar"
	PopupMenu popSetVarList,mode=1,value= #"FunctionList(\"*\",\";\",\"KIND:2,SUBTYPE:SetVariableControl\")"
	PopupMenu popMarqueeList,pos={24,106},size={155,19},title="Marquee"
	PopupMenu popMarqueeList,mode=1,value= #"FunctionList(\"*\",\";\",\"KIND:2,SUBTYPE:GraphMarquee\")"
EndMacro


Function sind( deg )
	variable deg
	variable d2r= pi/180
	return sin( deg*d2r )
End

Function cosd( deg )
	variable deg
	variable d2r= pi/180
	return cos( deg*d2r )
End

Function tand( deg )
	variable deg
	variable d2r= pi/180
	return tan( deg*d2r )
End

Function asind( val )
	variable val
	variable r2d=180/pi
	return r2d*asin( val )
End

Function acosd( val )
	variable val
	variable r2d=180/pi
	return r2d*acos( val )
End

Function atand( val )
	variable val
	variable r2d=180/pi
	return r2d*atan( val )
End

Function/C csrvector( )
	variable dx=hcsr(B)-hcsr(A), dy=vcsr(B)-vcsr(A)
	variable dist=sqrt(dx^2+dy^2), ang=180/pi*atan2(dy, dx)
//	ang = atand(dy/dx)
//	print dx, dy
	return CMPLX( dist, ang )
End