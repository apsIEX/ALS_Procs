//-*-Igor-*-
// ###################################################################
//  Igor Pro - JEG Image Tools
// 
//  FILE: "JEG Scale-Bar"
//                                    created: 3/3/97 {12:32:15 PM} 
//                                last update: 8/11/97 {11:25:18 PM} 
//  Author: Jonathan Guyer
//  E-mail: <jguyer@his.com>
//     WWW: <http://www.his.com/~jguyer/>
//          
//  Appends a scale bar to an image in the current graph
//  (works for traces, too). Scale bar configuration is
//  entirely configurable with the "Misc->Scale-bar preferences�"
//  panel.
//  
// ###################################################################
// 

#pragma rtGlobals=1		// Use modern global access method.

#include "JEG Keyword-Value"

Menu "Append to Graph"
	"Scale bar�",JEG_AddScaleBar()
	help = {"Append a scale bar for the x or y dimension of an image."}
End

Menu "Misc"
	"Scale-bar preferences�", JEG_ScaleBarPrefs()
	help = {"Modify the display parameters for scale-bars"}
End

// -----------Access Routines-----------------------------------------------

//
// -------------------------------------------------------------------------
//   
// "JEG_AddScaleBar" --
//  
//  Prompts for image wave, if necessary, and calls JEG_AddXYScaleBar2Graph()
// -------------------------------------------------------------------------
//
Proc JEG_AddScaleBar( parallelTo, IsWhite )
	String parallelTo
	Prompt parallelTo, "Parallel to: ", popup, AxisList("")
	variable IsWhite	
	Prompt IsWhite, "Color: ", popup, "White; Black"

	IsWhite = mod(IsWhite,2);
	JEG_MakeScaleBar( parallelTo, IsWhite)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_MakeScaleBar" --
//	
//	Create a "nice" scale bar for the X or Y dimension and append it
//	to the graph.
// -------------------------------------------------------------------------
//
//	05.04.98		Changed to default white color by DV
//
Function JEG_MakeScaleBar(parallelTo, IsWhite)
	String parallelTo
	variable IsWhite
	
	// NOTE: Don't change layout here; use the Misc->'Scale-bar preferences�' panel
	
	JEG_EnsureScaleBarPrefs()

	String dfSav = GetDataFolder(1)
	
	SetDataFolder root:Packages:'JEG Scale-Bar'
	
	NVAR widgetLength		= widgetLength		// Size (plot units) of widgets at end of scale-bar
	NVAR widgetThickness	= widgetThickness	// pixels
	NVAR niceLength			= niceLength		// Approximate fraction of axis length for scale-bar
	NVAR barThickness		= barThickness		// pixels
	NVAR niceResolution		= niceResolution	// Higher (integer) values give higher resolutions
	NVAR XBarXOffset		= XBarXOffset		// Offset (fraction of axis length) from plot edge for horizontal bar, parallel to bar
	NVAR XBarYOffset		= XBarYOffset		// Offset (plot units) from plot edge for horizontal bar, perpendicular to bar
	NVAR XBarLabelOffset	= XBarLabelOffset	// Offset (plot units) of label from horizontal bar, perpendicular to bar
	NVAR YBarYOffset		= YBarYOffset		// Offset (fraction of axis length) from plot edge for vertical bar, parallel to bar
	NVAR YBarXOffset		= YBarXOffset		// Offset (plot units) from plot edge for vertical bar, perpendicular to bar
	NVAR YBarLabelOffset	= YBarLabelOffset	// Offset (plot units) of label from vertical bar, perpendicular to bar
	NVAR labelRotation		= labelRotation		// Vertical bar label rotation, (0�3) for (0�,90�,180�,-90�)
	
	GetAxis/Q $parallelTo
	
	if (V_flag)
		return 0
	endif
	
	Variable theEdge = V_min
	
	Variable axisLength = (V_max - V_min)
	Variable barLength = axisLength * niceLength
	
	// Find a "nice" value near barLength
	
	Variable mantissa = log(barLength)
	Variable characteristic = floor(mantissa)
	mantissa = abs(mantissa - characteristic)
	
	barLength = 10^characteristic * round((10^mantissa) * niceResolution) / niceResolution
	
	// Figure out the orientation of the axis
	
	String theGraphName = WinName(0,1)
	String axInfo = AxisInfo(theGraphName,parallelTo)
	String axType = JEG_StrByKey("AXTYPE",axInfo,":",";")
	String axUnits = JEG_StrByKey("UNITS",axInfo,":",";")
	
	Variable verticalAxis
	if (!cmpstr(axType,"top") %| !cmpstr(axType,"bottom"))
		verticalAxis = 0
	else if (!cmpstr("left") %| !cmpstr("right"))
		verticalAxis = 1
	endif
	
	SetDrawLayer ProgAxes
	
	// Draw the scale-bar and label as a grouped object

	SetDrawEnv gstart
	
	Variable barX0, barX1, barY0, barY1
	
	String barLabel
	if (strlen(axUnits) == 0)
		sprintf barLabel, "%5g", barLength
	else
		if (niceResolution > 1)
			Variable labelPrecision = 1
			// Adds 1 if niceResolution will give more than 1 decimal place
			labelPrecision += (mod(10 / niceResolution,1) > 0)
			// We want a maximum of 3 digits, but less if decimal is 0
			labelPrecision -= mod(characteristic,3)
			// Correction for values < 1
			labelPrecision -= 3 * (characteristic < 0)
			labelPrecision = max(labelPrecision,0)
			sprintf barLabel, "%.*W1P%s" labelPrecision, barLength, axUnits
		else
			sprintf barLabel, "%.0W1P%s", barLength, axUnits
		endif
	endif

	
//	05.04.98		Changed to default white color below - DV

	variable color= 65280*IsWhite
			
	if (verticalAxis)
	
		barX0 = YBarXOffset
		barX1 = barX0
		barY0 = theEdge + YBarYOffset * axisLength
		barY1 = barY0 + barLength
		
		// Draw the scale-bar as a grouped object
	
		SetDrawEnv gstart

			SetDrawEnv linethick = barThickness, xcoord = prel, ycoord = $parallelTo, linefgc= (color,color,color)
			DrawLine barX0, barY0, barX1, barY1	
			
			SetDrawEnv linethick = widgetThickness, xcoord = prel, ycoord = $parallelTo, linefgc=  (color,color,color)
			DrawLine barX0 - widgetLength / 2, barY0, barX0 + widgetLength / 2, barY0
			
			SetDrawEnv linethick = widgetThickness, xcoord = prel, ycoord = $parallelTo, linefgc=  (color,color,color)
			DrawLine barX1 - widgetLength / 2, barY1, barX1 + widgetLength / 2, barY1
			
		SetDrawEnv gstop

		SetDrawEnv xcoord = prel, ycoord = $parallelTo
		SetDrawEnv textxjust = 1, textyjust = 1, textrot = labelRotation, fstyle = 1, textrgb= (color,color,color)
		DrawText barX0 + YBarLabelOffset, (barY0 + barY1)/2, barLabel
	else
		barX0 = theEdge + XBarXOffset * axisLength
		barX1 = barX0 + barLength
		barY0 = 1 - XBarYOffset
		barY1 = barY0
		
		// Draw the scale-bar as a grouped object
	
		SetDrawEnv gstart
	
			SetDrawEnv linethick = barThickness, xcoord = $parallelTo, ycoord = prel, linefgc=  (color,color,color)
			DrawLine barX0, barY0, barX1, barY1
			
			SetDrawEnv linethick = widgetThickness, xcoord = $parallelTo, ycoord = prel, linefgc=  (color,color,color)
			DrawLine barX0, barY0 - widgetLength / 2, barX0, barY0 + widgetLength / 2
	
			SetDrawEnv linethick = widgetThickness, xcoord = $parallelTo, ycoord = prel, linefgc=  (color,color,color)
			DrawLine barX1, barY1 - widgetLength / 2, barX1, barY1 + widgetLength / 2
			
		SetDrawEnv gstop

		SetDrawEnv xcoord = $parallelTo, ycoord = prel
		SetDrawEnv textxjust = 1, textyjust = 1, textrot = 0, fstyle = 1, textrgb=  (color,color,color)
		DrawText (barX0 + barX1)/2, barY0 - XBarLabelOffset, barLabel


	endif	

	SetDrawEnv gstop

	SetDataFolder dfSav
End

// -----------Utilities-----------------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_EnsureScaleBarPrefs" --
// 
//  Establishes preferences for the scale bar layout in the
//  following priority:
//  
//  	Existing preferences for this experiment
//  	Global preferences in the file ":JEG Scale-Bar Prefs"
//  	Hardcoded defaults
// -------------------------------------------------------------------------
// 
Function JEG_EnsureScaleBarPrefs()

	if (DataFolderExists("root:Packages:'JEG Scale-Bar'"))
		String dfSav = GetDataFolder(1)
		SetDataFolder root:Packages:'JEG Scale-Bar'
		
		Variable somethingWrong = (exists("widgetLength") != 2)
		somethingWrong = somethingWrong %| (exists("widgetThickness") != 2)
		somethingWrong = somethingWrong %| (exists("niceLength") != 2)
		somethingWrong = somethingWrong %| (exists("barThickness") != 2)
		somethingWrong = somethingWrong %| (exists("niceResolution") != 2)
		somethingWrong = somethingWrong %| (exists("XBarXOffset") != 2)
		somethingWrong = somethingWrong %| (exists("XBarYOffset") != 2)
		somethingWrong = somethingWrong %| (exists("XBarLabelOffset") != 2)
		somethingWrong = somethingWrong %| (exists("YBarYOffset") != 2)
		somethingWrong = somethingWrong %| (exists("YBarXOffset") != 2)
		somethingWrong = somethingWrong %| (exists("YBarLabelOffset") != 2)
		somethingWrong = somethingWrong %| (exists("labelRotation") != 2)

		if (somethingWrong)
			DoAlert 0, "The scale-bar preferences are corrupted. Restoring defaults."
			JEG_DefaultScaleBarProc("")
		endif
				
		SetDataFolder dfSav
	else
		
		// Read global preferences, if they exist
		
		Variable prefFile
		Open/Z/R/P=Igor/C="IGR0"/T="IPRF" prefFile as "JEG Scale-Bar Prefs"
		
		if (V_flag == 0)		// A prefs file exists
			JEG_LoadScaleBarPrefs(prefFile)
		else					// Use the defaults
			JEG_DefaultScaleBarProc("")
		endif
	endif
End

// -----------Panels & Controls---------------------------------------------

//
// -------------------------------------------------------------------------
//   
// "JEG_ScaleBarPrefs" --
//  
//  Panel to adjust display parameters for a scale-bar
// -------------------------------------------------------------------------
//
Proc JEG_ScaleBarPrefs()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(98,43,706,518) as "Scale-bar display preferences"
	ModifyPanel cbRGB=(65535,60076,49151)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (49151,60031,65535)
	DrawRect 102,413,478,37
	SetDrawEnv fsize= 18
	DrawText 257,231,"Image"
	SetDrawEnv linepat= 3,fillpat= 0
	DrawRect 78,2,510,434
	SetDrawEnv arrow= 2
	DrawLine 188,82,173,82
	SetDrawEnv gstart
	SetDrawEnv linethick= 3
	DrawLine 191,104,258,104
	SetDrawEnv linethick= 3
	DrawLine 190,96,190,112
	SetDrawEnv linethick= 3
	DrawLine 258,96,258,112
	SetDrawEnv gstop
	DrawLine 189,93,189,55
	DrawLine 191,93,191,80
	DrawLine 259,93,259,55
	SetDrawEnv arrow= 1
	DrawLine 207,82,192,82
	SetDrawEnv arrow= 2
	DrawLine 188,65,165,65
	SetDrawEnv arrow= 1
	DrawLine 283,65,260,65
	DrawLine 178,103,187,103
	DrawLine 178,105,187,105
	DrawLine 261,113,326,113
	SetDrawEnv arrow= 2
	DrawLine 180,103,180,88
	SetDrawEnv arrow= 1
	DrawLine 180,120,180,105
	DrawLine 261,95,326,95
	SetDrawEnv arrow= 2
	DrawLine 291,94,291,76
	SetDrawEnv arrow= 1
	DrawLine 291,132,291,114
	SetDrawEnv gstart
	SetDrawEnv linethick= 3
	DrawLine 190,350,257,350
	SetDrawEnv linethick= 3
	DrawLine 189,342,189,358
	SetDrawEnv linethick= 3
	DrawLine 257,342,257,358
	SetDrawEnv gstop
	DrawText 207,375,"10 �m"
	DrawLine 260,350,336,350
	DrawLine 243,368,296,368
	SetDrawEnv fstyle= 2
	DrawText 119,104,"pixels"
	SetDrawEnv arrow= 2
	DrawLine 277,349,277,331
	SetDrawEnv arrow= 1
	DrawLine 277,387,277,369
	SetDrawEnv arrow= 3
	DrawLine 324,432,324,350
	SetDrawEnv arrow= 3
	DrawLine 187,350,102,350
	SetDrawEnv textrot= 90
	DrawText 395,341,"10 �m"
	SetDrawEnv arrow= 3
	DrawLine 382,412,382,363
	SetDrawEnv arrow= 3
	DrawLine 382,260,79,260
	SetDrawEnv gstart
	SetDrawEnv linethick= 3
	DrawLine 374,361,390,361
	SetDrawEnv linethick= 3
	DrawLine 382,360,382,293
	SetDrawEnv linethick= 3
	DrawLine 374,291,390,291
	SetDrawEnv gstop
	DrawLine 382,288,382,230
	DrawLine 401,304,401,230
	SetDrawEnv arrow= 1
	DrawLine 422,260,402,260

	JEG_EnsureScaleBarPrefs()
	
	// Scale-bar dimensions
	
	SetVariable widgetLength,pos={274,97},size={50,15},proc=JEG_WidgetLengthProc,title=" "
	SetVariable widgetLength,limits={0,1,0.01}
	SetVariable widgetLength,value= root:Packages:'JEG Scale-Bar':widgetLength
	SetVariable widgetLength,help={"Scale-bar widget length, in plot-relative units"}

	SetVariable widgetThickness,pos={119,75},size={50,15},title=" "
	SetVariable widgetThickness,limits={0,INF,0.25}
	SetVariable widgetThickness,value= root:Packages:'JEG Scale-Bar':widgetThickness
	SetVariable widgetThickness,help={"Scale-bar widget thickness, in pixels"}

	SetVariable barLength,pos={200,58},size={50,15},title=" "
	SetVariable barLength,limits={0,1,0.01}
	SetVariable barLength,value= root:Packages:'JEG Scale-Bar':niceLength
	SetVariable barLength,help={"Approximate scale-bar length, as a fraction of the parallel axis length"}

	SetVariable barThickness,pos={119,106},size={50,15},title=" "
	SetVariable barThickness,limits={0,INF,0.25}
	SetVariable barThickness,value= root:Packages:'JEG Scale-Bar':barThickness
	SetVariable barThickness,help={"Scale-bar thickness, in pixels"}
	
	DrawText 199,133,"1/"
	DrawText 179,151,"\"nice\" resolution"
	SetVariable niceResolution,pos={211,119},size={38,15},title=" "
	SetVariable niceResolution,limits={1,INF,1}
	SetVariable niceResolution,value= root:Packages:'JEG Scale-Bar':niceResolution
	SetVariable niceResolution,help={"Resolution of what constitutes a \"nice\" scale-bar length, e.g., 1/4 will give bar lengths of 225 and 7.75; 1/1 will give bar lengths of 200 and 8"}

	// Horizontal scale-bar positioning parameters
	
	SetVariable XBarXOffset,pos={121,343},size={50,15},title=" "
	SetVariable XBarXOffset,limits={0,1,0.01}
	SetVariable XBarXOffset,value= root:Packages:'JEG Scale-Bar':XBarXOffset
	SetVariable XBarXOffset,help={"Offset of a horizontal scale-bar from the left edge of the image, as a fraction of the parallel axis length"}

	SetVariable XBarYOffset,pos={305,382},size={50,15},proc=JEG_ScaleBarOffsetProc,title=" "
	SetVariable XBarYOffset,limits={0,1,0.01}
	SetVariable XBarYOffset,value= root:Packages:'JEG Scale-Bar':XBarYOffset
	SetVariable XBarYOffset,help={"Offset of a horizontal scale-bar from the bottom edge of the plot, in plot-relative units"}

	SetVariable XBarLabelOffset,pos={262,352},size={50,15},proc=JEG_XBarLabelOffsetProc,title=" "
	SetVariable XBarLabelOffset,limits={-1,1,0.01}
	SetVariable XBarLabelOffset,value= root:Packages:'JEG Scale-Bar':XBarLabelOffset
	SetVariable XBarLabelOffset,help={"Offset of the label center from horizontal scale-bars, in plot-relative units.\rPositive values are above the bar, negative values are below."}
	
	// Vertical scale-bar positioning parameters
	
	SetVariable YBarXOffset,pos={221,253},size={50,15},proc=JEG_ScaleBarOffsetProc,title=" "
	SetVariable YBarXOffset,limits={0,1,0.01}
	SetVariable YBarXOffset,value= root:Packages:'JEG Scale-Bar':YBarXOffset
	SetVariable YBarXOffset,help={"Offset of a vertical scale-bar from the left edge of the plot, in plot-relative units"}

	SetVariable YBarYOffset,pos={364,380},size={50,15},title=" "
	SetVariable YBarYOffset,limits={0,1,0.01}
	SetVariable YBarYOffset,value= root:Packages:'JEG Scale-Bar':YBarYOffset
	SetVariable YBarYOffset,help={"Offset of a vertical scale-bar from the bottom edge of the image, as a fraction of the parallel axis length"}

	SetVariable YBarLabelOffset,pos={425,253},size={50,15},proc=JEG_YBarLabelOffsetProc,title=" "
	SetVariable YBarLabelOffset,limits={-1,1,0.01}
	SetVariable YBarLabelOffset,value= root:Packages:'JEG Scale-Bar':YBarLabelOffset
	SetVariable YBarLabelOffset,help={"Offset of the label center from vertical scale-bars, in plot-relative units.\rPositive values are to the right of the bar, negative values are to the left."}

	PopupMenu YBarLabelRotation,pos={412,315},size={39,19},proc=JEG_YBarRotationProc
	PopupMenu YBarLabelRotation,mode=round((root:Packages:'JEG Scale-Bar':labelRotation + 180)/90)
	PopupMenu YBarLabelRotation,value= #"\" -90�;     0�;   90�; 180�;\""
	PopupMenu YBarLabelRotation,help={"Rotation of the label for vertical scale-bars"}
	
	// Buttons
	
	Button capturePrefs,pos={526,17},size={65,20},proc=JEG_CaptureScaleBarProc,title="Capture"
	Button capturePrefs,help={"Capture these layout settings for new experiments"}

	Button revertToSaved,pos={526,41},size={65,20},proc=JEG_RevertScaleBarProc,title="Revert"
	Button revertToSaved,help={"Revert layout settings to those saved in file \":JEG Scale-Bar prefs\""}

	Button restoreDefaults,pos={526,66},size={65,20},proc=JEG_DefaultScaleBarProc,title="Defaults"
	Button restoreDefaults,help={"Restore layout settings to the hard-coded defaults"}

EndMacro

// -----------SetVariable Procs---------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_ScaleBarOffsetProc" --
// 
//  Adjustment procedure for position of scale-bar perpendicular to its length
//  
//  Ensures that sum of XBarYOffset and (widgetLength/2) remains <= 1.0
//  AND that (widgetLength/2) remains <= XBarYOffset
//  AND that the sum of YBarXOffset and (widgetLength/2) remains <= 1.0
//  AND that (widgetLength/2) remains <= YBarXOffset
// -------------------------------------------------------------------------
// 
Function JEG_ScaleBarOffsetProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the perpendicular offset and half the widget length can't exceed 1.0
	
	NVAR widgetLength = root:Packages:'JEG Scale-Bar':widgetLength
	
	widgetLength = 2 * Min(widgetLength / 2, 1-varNum)
	widgetLength = 2 * Min(widgetLength / 2, varNum)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_WidgetLengthProc" --
// 
//  Adjustment procedure for the image width
//  
//  Ensures that sum of XBarYOffset and (widgetLength/2) remains <= 1.0
//  		   AND that XBarYOffset remains >= (widgetLength/2)
//  AND that the sum of YBarXOffset and (widgetLength/2) remains <= 1.0
//  		   AND that YBarXOffset remains >= (widgetLength/2)
// -------------------------------------------------------------------------
// 
Function JEG_WidgetLengthProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the perpendicular offset and half the widget length can't exceed 1.0
	
	NVAR XBarYOffset = root:Packages:'JEG Scale-Bar':XBarYOffset
	NVAR YBarXOffset = root:Packages:'JEG Scale-Bar':YBarXOffset
	
	XBarYOffset = Min(XBarYOffset,1 - varNum/2)
	XBarYOffset = Max(XBarYOffset,varNum/2)
	YBarXOffset = Min(YBarXOffset,1 - varNum/2)
	YBarXOffset = Max(YBarXOffset,varNum/2)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_XBarLabelOffsetProc" --
// 
//  Adjustment procedure for horizontal scale-bar label position
//  
//  Ensures that sum of XBarYOffset and XBarLabelOffset remains <= 1.0
// -------------------------------------------------------------------------
// 
Function JEG_XBarLabelOffsetProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the perpendicular offset and half the widget length can't exceed 1.0
	
	NVAR XBarYOffset = root:Packages:'JEG Scale-Bar':XBarYOffset
	
	XBarYOffset = Min(XBarYOffset, 1-varNum)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_YBarLabelOffsetProc" --
// 
//  Adjustment procedure for vertical scale-bar label position
//  
//  Ensures that sum of YBarXOffset and YBarLabelOffset remains <= 1.0
// -------------------------------------------------------------------------
// 
Function JEG_YBarLabelOffsetProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the perpendicular offset and half the widget length can't exceed 1.0
	
	NVAR YBarXOffset = root:Packages:'JEG Scale-Bar':YBarXOffset
	
	YBarXOffset = Min(YBarXOffset, 1-varNum)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_YBarRotationProc" --
// 
//  Set the rotation value for vertical scale-bar labels
// -------------------------------------------------------------------------
// 
Function JEG_YBarRotationProc(ctrlName,popNum,popStr) : PopupMenuControl
	String		ctrlName	// ignored
	Variable	popNum		// ignored
	String		popStr
	
	NVAR labelRotation = root:Packages:'JEG Scale-Bar':labelRotation
	labelRotation = str2num(popStr)
End

// -----------Button Procs--------------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_CaptureScaleBarProc" --
// 
//  Saves the user's scale-bar layout preferences to a preferences file
// 
// Side effects:
//  Creates a file "JEG Scale-Bar Prefs" in the Igor folder
// -------------------------------------------------------------------------
// 
Function JEG_CaptureScaleBarProc(ctrlName) : ButtonControl
	String ctrlName		// ignored
	
	Variable prefFile
	Open/P=Igor/C="IGR0"/T="IPRF" prefFile as "JEG Scale-Bar Prefs"
	
	String dfSav = GetDataFolder(1)

	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S 'JEG Scale-Bar'

	Variable version = 1.0
	FBinWrite prefFile, version			// Preference file version

	NVAR widgetLength = widgetLength
	FBinWrite prefFile, widgetLength
	
	NVAR widgetThickness = widgetThickness
	FBinWrite prefFile, widgetThickness
	
	NVAR niceLength = niceLength
	FBinWrite prefFile, niceLength
	
	NVAR barThickness = barThickness
	FBinWrite prefFile, barThickness

	NVAR niceResolution = niceResolution
	FBinWrite prefFile, niceResolution

	NVAR XBarXOffset = XBarXOffset
	FBinWrite prefFile, XBarXOffset
	
	NVAR XBarYOffset = XBarYOffset
	FBinWrite prefFile, XBarYOffset
	
	NVAR XBarLabelOffset = XBarLabelOffset
	FBinWrite prefFile, XBarLabelOffset
	
	NVAR YBarYOffset = YBarYOffset
	FBinWrite prefFile, YBarYOffset

	NVAR YBarXOffset = YBarXOffset
	FBinWrite prefFile, YBarXOffset

	NVAR YBarLabelOffset = YBarLabelOffset
	FBinWrite prefFile, YBarLabelOffset
	
	NVAR labelRotation = labelRotation
	FBinWrite prefFile, labelRotation
	
	Close prefFile

	SetDataFolder dfSav
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_DefaultScaleBarProc" --
// 
//  Set scale bar layout to my preferences
//  No need to change the code; users can set their own preferences
// -------------------------------------------------------------------------
// 
Function JEG_DefaultScaleBarProc(ctrlName) : ButtonControl
	String ctrlName		// ignored

	String dfSav = GetDataFolder(1)

	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S 'JEG Scale-Bar'
	
	// No need to mess with these; 
	// use the Misc->'Scale-bar preferences�' 
	// control panel to set your own prefs
			
	Variable/G widgetLength		= 0.02		// Size (plot units) of widgets at end of scale-bar
	Variable/G widgetThickness	= 2			// pixels
	Variable/G niceLength		= 0.2		// Approximate fraction of axis length for scale-bar
	Variable/G barThickness		= 2			// pixels
	Variable/G niceResolution	= 1			// Higher (integer) values give higher resolutions
	Variable/G XBarXOffset		= 0.1		// Offset (fraction of axis length) from plot edge for horizontal bar, parallel to bar
	Variable/G XBarYOffset		= 0.08		// Offset (plot units) from plot edge for horizontal bar, perpendicular to bar
	Variable/G XBarLabelOffset	= -0.03		// Offset (plot units) of label from horizontal bar, perpendicular to bar
	Variable/G YBarYOffset		= 0.1		// Offset (fraction of axis length) from plot edge for vertical bar, parallel to bar
	Variable/G YBarXOffset		= 0.08		// Offset (plot units) from plot edge for vertical bar, perpendicular to bar
	Variable/G YBarLabelOffset	= -0.03		// Offset (plot units) of label from vertical bar, perpendicular to bar
	Variable/G labelRotation	= 90		// Vertical bar label rotation, (0�,90�,180�,-90�)
	
	if (cmpstr(ctrlName,""))	// we were actually called by the preference panel
		PopupMenu YBarLabelRotation,mode=round((labelRotation + 180)/90)
		ControlUpdate YBarLabelRotation
	endif

	SetDataFolder dfSav
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_LoadScaleBarPrefs" --
// 
//  Load scale-bar layout preferences from the file pointed to by
//  the file reference number prefFil
// -------------------------------------------------------------------------
// 
Function JEG_LoadScaleBarPrefs(prefFile)
	Variable prefFile
	
	String dfSav = GetDataFolder(1)

	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S 'JEG Scale-Bar'

	Variable version
	FBinRead prefFile, version	// Ignore for now; we might need it later

	NVAR widgetLength = widgetLength
	FBinRead prefFile, widgetLength
	
	NVAR widgetThickness = widgetThickness
	FBinRead prefFile, widgetThickness
	
	NVAR niceLength = niceLength
	FBinRead prefFile, niceLength
	
	NVAR barThickness = barThickness
	FBinRead prefFile, barThickness

	NVAR niceResolution = niceResolution
	FBinRead prefFile, niceResolution

	NVAR XBarXOffset = XBarXOffset
	FBinRead prefFile, XBarXOffset
	
	NVAR XBarYOffset = XBarYOffset
	FBinRead prefFile, XBarYOffset
	
	NVAR XBarLabelOffset = XBarLabelOffset
	FBinRead prefFile, XBarLabelOffset
	
	NVAR YBarYOffset = YBarYOffset
	FBinRead prefFile, YBarYOffset

	NVAR YBarXOffset = YBarXOffset
	FBinRead prefFile, YBarXOffset

	NVAR YBarLabelOffset = YBarLabelOffset
	FBinRead prefFile, YBarLabelOffset
	
	NVAR labelRotation = labelRotation
	FBinRead prefFile, labelRotation
	
	Close prefFile
	
	PopupMenu YBarLabelRotation,mode=round((labelRotation + 180)/90)
	ControlUpdate YBarLabelRotation

	SetDataFolder dfSav
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_RevertScaleBarProc" --
// 
//  Revert the scale-bar layout preferences to those last saved in 
//  ":Igor Pro Folder:JEG Scale-Bar Prefs"
//  If it doesn't exist, asks the user if they want the defaults
//  If not, leaves the settings alone
// -------------------------------------------------------------------------
// 
Function JEG_RevertScaleBarProc(ctrlName) : ButtonControl
	String ctrlName		// ignored
	
	Variable prefFile
	Open/Z/R/P=Igor/C="IGR0"/T="IPRF" prefFile as "JEG Scale-Bar Prefs"
	
	if (V_Flag == 0)		// A prefs file exists
		JEG_LoadScaleBarPrefs(prefFile)
	else					// See if user wants the defaults
		DoAlert 1, "No preferences file exists.\rUse defaults?"
		
		if (V_Flag == 1)
			JEG_DefaultScaleBarProc("")
		endif
	endif
End

