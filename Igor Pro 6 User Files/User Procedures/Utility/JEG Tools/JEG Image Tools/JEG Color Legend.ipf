#pragma rtGlobals=1		// Use modern global access method.

#pragma version = 3.04

#include "JEG Extract Dimensions" version >= 1.1
#include "JEG Keyword-Value"
#include <NumInList>
#include <strings as lists>
#include <StrMatchList>

//-*-Igor-*-
// ###################################################################
//  Igor Pro - JEG Image Tools
// 
//  FILE: "JEG Color Legend"
//                                    created: 9/26/96 {6:23:37 PM} 
//                                last update: 12/16/97 {1:26:19 AM} 
//  Author: Jonathan Guyer
//  E-mail: <jguyer@his.com>
//     WWW: <http://www.his.com/~jguyer/>
//	
//	Description: 
//		Appends a scale bar for the data dimension of image waves
//		Controls at the top of the graph allow live adjustment of
//		data range and color table
//		
//		As of version 2.0, uses a particular interpretation of data dimension
//		scaling. Specifically, if the wave is of integral type, then
//		the data dimension max and min are taken to correspond to the full
//		range of the appropriate integer size, e.g., an 8 bit unsigned integer
//		wave with data dimension full scale of 0�16 nm would scale each data 
//		unit to 0.0625 nm and a value of 256 would correspond to 16 nm.
//		
//		As of version 3.0, allows offsetting upper or lower threshold to zero.
//		Preferences panel allows user customization of layout.
//		No longer assumes the image is displayed left vs. bottom.
//		Supports traces which are displayed with a color as f(z) of another wave.
//		Renamed from "JEG Z-Legend"
//		Properly determines bounds of complex waves
//
//	History
// 
//	modified by	  rev  reason
//	-------- --- ----- -----------
//	09/26/96 JEG 1.0.0 original
//  12/15/96 JEG 2.0.0 Color index waves & integral wave scaling
//  3/2/97   JEG 3.0.0 Zero offset, preferences panel, & f(z) traces
//  12/7/97  JEG 3.0.1 fixed bug in horizontal legends & swapXY 
//                     more robust panels
//  12/14/97 JEG 3.0.2 fixed bug in Graph->Remove->Color legend
//  12/14/97 JEG 3.0.3 fixed fatal bug in JEG_EnsureColorLegendPrefs()
//  12/15/97 JEG 3.0.4 further fixes to Graph->Remove->Color legend,
//                     fixed unmatched Set/GetDataFolder,
//                     added JEG_RefreshColorLegendLinks()
// ###################################################################

Menu "Append to Graph"
	"Color legend�",JEG_AddColorLegend()
	help = {"Append a scale bar for the data dimension of an image."}
End

Menu "Graph"
	Submenu "Remove"
		"Color legend", JEG_ZapColorLegendPrompt()
		help = {"Remove color legend scale and expand image to fill window"}
	End
End

Menu "Misc"
	"Color legend preferences�", JEG_DisplayColorLegendPrefs()
	help = {"Modify the display parameters for color legends"}
End

// -----------Access Routines-----------------------------------------------

//
// -------------------------------------------------------------------------
//   
// "JEG_AddColorLegend" --
//  
//  Prompts for image or f(z) trace wave, if necessary, 
//  and calls JEG_AddColorLegend2Graph()
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> support f(z) traces
// -------------------------------------------------------------------------
//
Proc JEG_AddColorLegend( imageName )
	String imageName
	Prompt imageName, "Apply color legend to: ", popup, JEG_EligibleForLegendList()
	
	Silent 1

	JEG_AddColorLegend2Graph(imageName, 1, 1)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_AddColorLegend2Graph" --
//	
//	Appends	data dimension scale bar to	designated image in	graph
//	and	adds controls to adjust	image display to top of	graph
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> display of legend and controls is optional
// -------------------------------------------------------------------------
//
Function JEG_AddColorLegend2Graph(imageName, showLegend, showControls)
	String imageName
	Variable showLegend
	Variable showControls
	if (strlen(imageName))
		String legendName = JEG_MakeColorLegend(imageName,showLegend)	
		if (showControls)
			JEG_AddColorLegendControls(legendName)
		endif
	endif	
End

// -------------------------------------------------------------------------
// 
// "JEG_DisplayColorLegendPrefs" --
// 
//  Create Color Legend pref panel, or bring to front
// 
// --Version--Author------------------Changes-------------------------------
//    3.0.1    <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Proc JEG_DisplayColorLegendPrefs()

	if (strlen(WinList("JEG_ColorLegendPrefPanel",";","")) != 0)
		DoWindow/F JEG_ColorLegendPrefPanel
	else
		JEG_ColorLegendPrefs()
	
		// Rename it so we can find it again
		DoWindow/C JEG_ColorLegendPrefPanel
	endif
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_MakeColorLegend" --
//	
//	Create a legend	wave for the data dimension	of imageName and append	it
//	to the graph, adjusting	the	graph as necessary to make it fit
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> enable zero offset, user preferences, and f(z) traces
// -------------------------------------------------------------------------
//
Function/S JEG_MakeColorLegend(imageName,showLegend)
	String imageName
	Variable showLegend

	JEG_EnsureColorLegendPrefs()
	
	String dfSav= GetDataFolder(1)
	
	SetDataFolder root:Packages:'JEG Color Legend'
	NewDataFolder/O   'Color Index Waves'
	
	// Get a new, unique datafolder for this legend
	String legendName = UniqueName("legend",11,0)
	NewDataFolder/S $legendName
	
	Variable/G useIndexWave = 0

	String/G theGraphName = WinName(0,1)
	String/G theImageName = imageName
	String/G theColorTable	
	String/G units	

	Variable/G upper,lower
	
	Variable/G reverseTable = 0
	
	// Scale the legend the same as the image color scale
	
	// flag for whether imageName refers to a f(z) trace
	Variable/G imageIsTrace
	imageIsTrace = (FindItemInList(imageName,TraceNameList("",";",1),";",0) >= 0)

	// flag for whether imageName refers to a contour
	Variable/G imageIsContour
	imageIsContour = (FindItemInList(imageName,ContourNameList("",";"),";",0) >= 0)

	// allow for possibility of non-integral scaling of integral waves
	Variable/G zScale = 1
	
	// allow for offsetting one threshold to zero
	Variable/G zOffset = 0
	Variable/G zeroSelect = 0		// don't offset by default
	
	// flag for whether the scale-bar is actually displayed
	// we may just have controls for modifying the image
	Variable/G displayed = showLegend
	
	JEG_SetFullScale(1)
	
	String theImageInfo
	
	if (imageIsTrace)
		theImageInfo = TraceInfo("",imageName,0)
	else 
		if (imageIsContour)
			theImageInfo = ContourInfo("",imageName,0)
		else
			theImageInfo = ImageInfo("",imageName,0)
		endif	
	endif	
	
	// NOTE: Don't change layout here; use the Misc->'Color legend Preferences�' panel

	NVAR imageWidth			= ::Preferences:imageWidth
	NVAR imageVertical		= ::Preferences:imageVertical
	NVAR imageHorizontal	= ::Preferences:imageHorizontal
	NVAR barHeight			= ::Preferences:barHeight
	NVAR barWidth			= ::Preferences:barWidth
	NVAR barVertical		= ::Preferences:barVertical
	NVAR barHorizontal		= ::Preferences:barHorizontal

	NVAR verticalLegend		= ::Preferences:verticalLegend
	NVAR labelSide			= ::Preferences:labelSide
	
	// v3.0.1 - Added to deal with swapped axes
	
	String tag = "swapXY="
	String recreation = WinRecreation("",1)
	Variable/G swapXY = strsearch(recreation,tag,0)
	if (swapXY < 0)
		swapXY = 0
	else
		// Is there ever a reason for this not to be one digit?
		swapXY = str2num(recreation[swapXY+strlen(tag)])
	endif

	swapXY = (verticalLegend == swapXY)
	
	if (swapXY)
		Make/O/N=(100,1) ColorLegend
		SetScale/I x,lower,upper,units ColorLegend

		// Automatic updating
		Execute "ColorLegend := (x - zOffset) / zScale"
	else
		Make/O/N=(1,100) ColorLegend
		SetScale/I y,lower,upper,units ColorLegend

		// Automatic updating
		Execute "ColorLegend := (y - zOffset) / zScale"
	endif

	if (showLegend)
		ModifyGraph axisEnab($JEG_StrByKey("YAXIS",theImageInfo,":",";")) = {imageVertical, imageVertical + imageWidth}
		ModifyGraph axisEnab($JEG_StrByKey("XAXIS",theImageInfo,":",";")) = {imageHorizontal, imageHorizontal + imageWidth}
		ModifyGraph mirror=0
		ModifyGraph margin(right) = 53
	
		// NOTE: prel 0�1 is top to bottom, but axis 0�1 is bottom to top
		
		// Fake image frame
		SetDrawLayer ProgAxes
		SetDrawEnv xcoord=prel, ycoord=prel, fillpat=0, linethick = 1
		DrawPoly imageHorizontal, 1 - imageWidth - imageVertical, 1, 1, {0,0}
		DrawPoly/A {imageWidth,0,imageWidth,imageWidth,0,imageWidth,0,0}

		if (verticalLegend)
			if (labelSide)	// right side
				AppendImage /R=ColorLegendRight/B=ColorLegendBottom ColorLegend
				ModifyGraph nticks(ColorLegendBottom)=0,axThick(ColorLegendBottom)=0
				ModifyGraph axisEnab(ColorLegendRight)={barVertical,barVertical + barHeight}
				ModifyGraph axisEnab(ColorLegendBottom)={barHorizontal,barHorizontal + barWidth}
				ModifyGraph freePos(ColorLegendRight)={0.5,ColorLegendBottom}
				Label ColorLegendRight " "	// No axis label; Igor appends units to a tick label
			else
				AppendImage /L=ColorLegendLeft/B=ColorLegendBottom ColorLegend
				ModifyGraph nticks(ColorLegendBottom)=0,axThick(ColorLegendBottom)=0
				ModifyGraph axisEnab(ColorLegendLeft)={barVertical,barVertical + barHeight}
				ModifyGraph axisEnab(ColorLegendBottom)={barHorizontal,barHorizontal + barWidth}
				ModifyGraph freePos(ColorLegendLeft)={-0.5,ColorLegendBottom}
				Label ColorLegendLeft " "	// No axis label; Igor appends units to a tick label
			endif
		else
			if (labelSide)	// top side
				AppendImage /L=ColorLegendLeft/T=ColorLegendTop ColorLegend
				ModifyGraph nticks(ColorLegendLeft)=0,axThick(ColorLegendLeft)=0
				ModifyGraph axisEnab(ColorLegendTop)={barHorizontal,barHorizontal + barWidth}
				ModifyGraph axisEnab(ColorLegendLeft)={barVertical,barVertical + barHeight}
				ModifyGraph freePos(ColorLegendTop)={0.5,ColorLegendLeft}
				Label ColorLegendTop " "	// No axis label; Igor appends units to a tick label
			else
				AppendImage /L=ColorLegendLeft/B=ColorLegendBottom ColorLegend
				ModifyGraph nticks(ColorLegendLeft)=0,axThick(ColorLegendLeft)=0
				ModifyGraph axisEnab(ColorLegendBottom)={barHorizontal,barHorizontal + barWidth}
				ModifyGraph axisEnab(ColorLegendLeft)={barVertical,barVertical + barHeight}
				ModifyGraph freePos(ColorLegendBottom)={-0.5,ColorLegendLeft}
				Label ColorLegendBottom " "	// No axis label; Igor appends units to a tick label
			endif
		endif

		// Fake legend frame
		SetDrawEnv xcoord=prel, ycoord=prel, fillpat=0, linethick = 1
		DrawPoly barHorizontal, 1 - barVertical, 1, 1, {0,0}
		DrawPoly/A {barWidth,0,barWidth,-barHeight,0,-barHeight,0,0}
	endif	
	
	SetDataFolder dfSav
	
	return legendName
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ZapColorLegendPrompt" --
// 
//  Prompt user for input to JEG_ZapColorLegend
// 
// Results:
//  See JEG_ZapColorLegend
// 
// --Version--Author------------------Changes-------------------------------
//    3.0.2     <jguyer@his.com> original
// -------------------------------------------------------------------------
// 
Proc JEG_ZapColorLegendPrompt(killControls, legendName)
	Variable	killControls
	String		legendName
	Prompt killControls, "Remove controls: ", popup "no;yes"
	Prompt legendName, "Color legend to remove: ", popup JEG_ColorLegendList("",";")
		
	JEG_ZapColorLegend(killControls - 1, legendName)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_ZapColorLegend" --
//	
//	Eliminate the color legend and, if desired, the controls that go with it
//	
// --Version--Author------------------Changes-------------------------------
//    3.0.2	  <j-guyer@nwu.edu>  original
//    3.0.4   <jguyer@his.com>   fixed bug (unmatched Set/GetDataFolder)
// -------------------------------------------------------------------------
//
Function JEG_ZapColorLegend(killControls, legendName)
	Variable	killControls
	String		legendName
	
	String legendPath = "root:Packages:'JEG Color Legend':" + legendName
	
	String dfSav = GetDataFolder(1)
	SetDataFolder $legendPath

	// Stop displaying data dimension scale-bar, if it exists
	
	if (FindItemInList("ColorLegend",ImageNameList("",";"),";",0) >= 0)
	
		RemoveImage ColorLegend
		
		ModifyGraph axisEnab={0,1}, margin=0
		
		SetDrawLayer/K ProgAxes		// This wipes everything else in ProgAxes, too
		
	endif
	
	if (killControls)	
	
		// Kill controls

		ControlBar 0
		KillControl $("upper_" + legendName)
		KillControl $("lower_" + legendName)
		KillControl $("full_" + legendName)
		KillControl $("color_" + legendName)
		KillControl $("reverse_" + legendName)
		KillControl $("scale_" + legendName)
		KillControl $("zeroUpper_" + legendName)
		KillControl $("zeroLower_" + legendName)
		KillControl $("delete_" + legendName)
		
		// Kill the legend
		
		NVAR useIndexWave = useIndexWave
		
		if (useIndexWave)
			KillWaves/Z ColorLegend
			KillVariables/A
			KillStrings/A
		else
			KillDataFolder $(legendPath)
		endif

	else
		// Controls still exist, but the scale-bar isn't displayed
		
		NVAR displayed = displayed
		displayed = 0
	endif
	
	SetDataFolder dfSav
End

// -----------Utilities-----------------------------------------------------

//
// -------------------------------------------------------------------------
//	 
// "JEG_AdjustLimits" --
//	
//	Change the displayed range of both the image and its legend
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> enable zero offset, color table reversal, and f(z) traces
//    3.01	<dima@cmliris.harvard.edu> fixed bug for user color tables (set scale for correct dimention)
// -------------------------------------------------------------------------
//
Function JEG_AdjustLimits()
	// Assumes already located in proper color legend data folder

	NVAR upper = upper
	NVAR lower = lower
	NVAR zScale = zScale
	NVAR zOffset = zOffset
	
	SVAR theGraphName = theGraphName
	SVAR theImageName = theImageName
	
	Wave ColorLegend = ColorLegend
	
	SVAR theColorTable = theColorTable
	SVAR units = units
	
	NVAR reverseTable = reverseTable
	NVAR useIndexWave = useIndexWave
	NVAR displayed = displayed
	NVAR imageIsTrace = imageIsTrace
	NVAR imageIsContour = imageIsContour
	NVAR swapXY = swapXY
	
	if (imageIsTrace)
		Wave theImage = TraceNameToWaveRef(theGraphName,theImageName)
	else 
		if (imageIsContour)
			Wave theImage = ContourNameToWaveRef(theGraphName,theImageName)
		else
			Wave theImage = ImageNameToWaveRef(theGraphName,theImageName)
		endif
	endif

	// JEG 3.0.1	Added swapXY clauses
	
	if (swapXY)
		SetScale/I x lower,upper,units ColorLegend
	else
		SetScale/I y lower,upper,units ColorLegend
	endif

	if (useIndexWave)		// never true for f(z) trace
		if (swapXY)
			if (reverseTable)
				SetScale/I y (upper - zOffset) / zScale, (lower - zOffset) / zScale,units 'Color Index Wave'
			else
				SetScale/I y (lower - zOffset) / zScale - zOffset, (upper - zOffset) / zScale,units 'Color Index Wave'
			endif
		else
			if (reverseTable)
				SetScale/I x (upper - zOffset) / zScale, (lower - zOffset) / zScale,units 'Color Index Wave'
			else
				SetScale/I x (lower - zOffset) / zScale - zOffset, (upper - zOffset) / zScale,units 'Color Index Wave'
			endif
		endif
		
		if (imageIsContour)
			ModifyContour $(theImageName) cIndexLines = 'Color Index Wave'
		else
			ModifyImage $(theImageName) cindex = 'Color Index Wave'
		endif
		
		if (displayed)
			ModifyImage ColorLegend cindex = 'Color Index Wave'
		endif
	else
		if (imageIsTrace)
			SVAR FofZWave = FofZWave
			if (reverseTable)
				ModifyGraph zColor($(theImageName))={$(FofZWave),(upper/zScale) - zOffset,(lower/zScale) - zOffset,$(theColorTable)}
			else
				ModifyGraph zColor($(theImageName))={$(FofZWave),(lower/zScale) - zOffset,(upper/zScale) - zOffset,$(theColorTable)}
			endif
		else 
			if (imageIsContour)
				ModifyContour $(theImageName) ctablines = {(lower - zOffset)/zScale,(upper - zOffset)/zScale,$(theColorTable),reverseTable}
			else
				ModifyImage $(theImageName) ctab= {(lower - zOffset)/zScale,(upper - zOffset)/zScale,$(theColorTable),reverseTable}
			endif
		endif
		
		// ??? What if there's more than one ColorLegend?
		if (displayed)
			ModifyImage ColorLegend ctab= {*,*,$(theColorTable),reverseTable}
		endif
	endif
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_AdjustScaling" --
//	
//	Apply or remove	integral scaling from the wave
//	
// Side	effects:
//	increment of data range	controls is	modified as	is appearance of units throughout
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    2.0     <j-guyer@nwu.edu> enable integral scaling
//    3.0     <j-guyer@nwu.edu> support f(z) traces
// -------------------------------------------------------------------------
//
Function JEG_AdjustScaling(ctrlName,checked) : CheckBoxControl
	String ctrlName		// Must be "scale_" + legendName
	Variable checked	// 1 if checked (apply scaling), 0 if not

							// strip leading "scale_"
	String legendName = ctrlName[6,strlen(ctrlName)-1]
	String legendPath = "root:Packages:'JEG Color Legend':" + legendName
	String dfSav = GetDataFolder(1)
	SetDataFolder $legendPath

	NVAR zScale = zScale
	NVAR upper = upper
	NVAR lower = lower
	SVAR theGraphName = theGraphName
	SVAR theImageName = theImageName
	SVAR units = units
	NVAR imageIsTrace = imageIsTrace
	NVAR imageIsContour = imageIsContour

	if (imageIsTrace)
		SVAR FofZWave = FofZWave
		Wave theImage = TraceNameToWaveRef(theGraphName,theImageName)
	else 
		if (imageIsContour)
			Wave theImage = ContourNameToWaveRef(theGraphName,theImageName)
		else
			Wave theImage = ImageNameToWaveRef(theGraphName,theImageName)
		endif
	endif
	
	String setUpper = "upper_" + legendName
	String setLower = "lower_" + legendName

	upper /= zScale		// undo old scaling
	lower /= zScale
	
	// Apply integral scaling only if wave is integral type, scaling exists, and box is checked
	// Otherwise, apply no scaling, but apply units if wave is float and scaling exists
	// To get units in non-scaled integral wave, check the scaling box and apply data dimension 
	// wave scaling equal to the full data range, e.g., an 8 bit unsigned integer wave could get 
	// data min range of 0 and data max range of 256 and a units string appropriate to whatever 
	// one integral unit is.
	
	zScale = 1
	units = ""
	
	if (JEG_WaveIsIntegral(theImage))
		if (checked %& JEG_WaveIsScaled(theImage))	// never true for f(z) traces
			String theWaveInfo = WaveInfo(theImage,0)
			
			String fullScale = JEG_StrByKey("FULLSCALE",theWaveInfo,":",";")
			zScale  = str2num(GetStrFromList(fullScale,2,","))			// data max full scale 
			zScale -= str2num(GetStrFromList(fullScale,1,","))			// data min full scale
			zScale /= 2^mod(JEG_NumByKey("NUMTYPE",theWaveInfo,":",";"), 64)		// 2^8, 2^16, or 2^32
			
			upper *= zScale		// apply new scaling
			lower *= zScale
			
			units = WaveUnits(theImage,-1)
		endif
	else	// wave is a float
		if (imageIsTrace)
			units = WaveUnits($(FofZWave),-1)		
		else
			if (JEG_WaveIsScaled(theImage))
				units = WaveUnits(theImage,-1)
			endif
		endif
	endif
	
	JEG_SetSteps(legendName)

	JEG_AdjustLimits()
	
	SetDataFolder dfSav
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_ColorIndexWaves" --
//	
//	Constructs a list of the "stock" color tables, plus any additional
//	color index	waves placed in	"root:Packages:'JEG	Color Legend':'Color Index Waves'"
//	
// --Version--Author------------------Changes-------------------------------
//    2.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> disable color index waves for f(z) traces
// -------------------------------------------------------------------------
//
Function/S JEG_ColorIndexWaves(imageIsTrace)
	Variable imageIsTrace
	
	String	colorIndexWaves = "Grays;Rainbow;YellowHot;BlueHot;BlueRedGreen;RedWhiteBlue;PlanetEarth;Terrain;"

	String	colorIndexPath = "root:Packages:'JEG Color Legend':'Color Index Waves'"
	String	indexName
	
	Variable index = 0
	do
		indexName = GetIndexedObjName(colorIndexPath,1,index)
		if (strlen( indexName ) == 0)
			break
		endif
		
		if (imageIsTrace)	// f(z) traces can't deal with color index waves
			colorIndexWaves += "\\M0:(:"	// inactive in menu
		endif
		
		colorIndexWaves += indexName + ";"
		index += 1
	while (1)
	
	return colorIndexWaves
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ColorLegendList" --
// 
//  List color legends in top graph
// 
// Results:
//  List of names
//  
// --Version--Author------------------Changes-------------------------------
//    3.0.2     <jguyer@his.com> original
//    3.0.4     <jguyer@his.com> changed mechanism 
//                               old preserved as JEG_OldColorLegendList()
// -------------------------------------------------------------------------
//
Function/S JEG_ColorLegendList(graphNameStr,separatorStr)
	String graphNameStr
	String separatorStr
		
	String colorLegendList = ""
	String colorLegendPath = "root:Packages:'JEG Color Legend':"

	if (DataFolderExists(colorLegendPath))
		Variable folderCount = CountObjects(colorLegendPath,4)

		String legendName
		String graphName
		
		if (strlen(graphNameStr) == 0)
			graphNameStr = WinName(0,1)
		endif

		do 
			legendName = GetIndexedObjName(colorLegendPath,4,folderCount - 1)
			graphName = colorLegendPath + legendName + ":theGraphName"
			folderCount -= 1
			if (exists(graphName) == 2)
				SVAR theName = $graphName
				if (cmpstr(graphNameStr,theName) == 0)
					// prepend because we're counting down in indices
					colorLegendList = legendName + ";" + colorLegendList
				endif
			endif
		while (folderCount > 0)
	endif
	
	return colorLegendList
End


// 
// -------------------------------------------------------------------------
// 
// "JEG_OldColorLegendList" --
// 
//  Obsolete. Replaced by JEG_ColorLegendList
// 
// --Version--Author------------------Changes-------------------------------
//    3.0.2     <jguyer@his.com> original
// -------------------------------------------------------------------------
// 
Function/S JEG_OldColorLegendList(graphNameStr,separatorStr)
	String graphNameStr
	String separatorStr
	
	String imageList = ImageNameList(graphNameStr,separatorStr)
	
	String colorLegendList = ""
	
	Variable index = 0
	String item
	do
		item = GetStrFromList(imageList,index,separatorStr)
		index += 1
		
		if (strlen(item) > 0)
			Wave theImage = ImageNameToWaveRef(graphNameStr,item)
			String thePath = GetWavesDataFolder(theImage,1)
			if (StrMatch("root:Packages:'JEG Color Legend':*",thePath)==0)
				colorLegendList += GetWavesDataFolder(theImage,0) + separatorStr
			endif
		endif
	while (strlen(item) > 0)
	
	return colorLegendList
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ComplexBounds" --
// 
//  WaveStats doesn't give us the right thing for complex waves
//  so we manually calculate the min and max if the wave is complex,
//  otherwise, we use WaveStats
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ComplexBounds(theImage,theBounds)
	Wave theImage
	Wave theBounds

	String numType
	numType = WaveInfo(theImage,0)
	numType = JEG_StrByKey("NUMTYPE",numType,":",";")
	if (str2num(numType) %& 0x01)	// Complex
		Variable xpts = DimSize(theImage,0)
		Variable ypts = DimSize(theImage,1)
		
		Variable value
		theBounds[0] = INF
		theBounds[1] = 0
	
		Variable i = 0
		Variable j = 0
		do
			do
				value = magsqr(theImage[i][j])
				theBounds[0] = min(theBounds[0], value)
				theBounds[1] = max(theBounds[1], value)
				i += 1
			while (i < xpts)
			j += 1
		while (j < ypts)
		
		// no sense doing these square roots until we need to
		theBounds[0] = sqrt(theBounds[0])
		theBounds[1] = sqrt(theBounds[1])
	else
		WaveStats/Q theImage
		theBounds[0] = V_min
		theBounds[1] = V_max
	endif
		
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_EligibleForLegendList" --
// 
//  Returns a menu-appropriate list of images and f(z) traces in the current
//  window.
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function/S JEG_EligibleForLegendList()
	
	String imageList = ImageNameList("",";")
	
	String theList = imageList
	
	String contourList = ContourNameList("",";")
	
	if ((strlen(theList) > 0) %& (strlen(contourList) > 0))
		theList += "-;"
	endif
	theList += contourList

	String traceList = TraceNameList("",";",1)
	String zColorTraceList = ""
	
	String zColor = ""
	String item = ""
	Variable index = 0
	do
		item = GetStrFromList(traceList,index,";")
		index += 1
		
		if (strlen(item) > 0)
			zColor = JEG_StrByKey("RECREATION",TraceInfo("",item,0),":",";")
			zColor = JEG_StrByKey("zColor(x)",zColor,"=",";")
			if (cmpstr(zColor,"0"))
				zColorTraceList += item + ";"
			endif
		endif
	while (strlen(item) > 0)

	if (strlen(zColorTraceList) > 0)
		if (strlen(theList) > 0)
			theList += "-;"
		endif
		
//		if ((strlen(imageList) > 0) %| cmpstr(GetStrFromList(zColorTraceList,1,";"),""))
//			theList += "\\M0:(:Trace:;"
//		endif
		
		theList += zColorTraceList

//		if (cmpstr(GetStrFromList(imageList,1,";"),""))
//			theList = "\\M0:(:Image:;" + theList
//		endif
	endif
	
	return theList
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_EnsureColorLegendPrefs" --
// 
//  Establishes preferences for the color legend layout in the
//  following priority:
//  
//  	Existing preferences for this experiment
//  	Global preferences in the file ":JEG Color Legend Prefs"
//  	Hardcoded defaults
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
//    3.0.3   <jguyer@his.com>  fixed fatal bug when defaults didn't exist 
//    							before loading from file 
// -------------------------------------------------------------------------
// 
Function JEG_EnsureColorLegendPrefs()

	if (DataFolderExists("root:Packages:'JEG Color Legend':Preferences"))
		String dfSav = GetDataFolder(1)
		SetDataFolder root:Packages:'JEG Color Legend':Preferences
		
		Variable somethingWrong = (exists("imageWidth") != 2)
		somethingWrong = somethingWrong %| (exists("imageVertical") != 2)
		somethingWrong = somethingWrong %| (exists("imageHorizontal") != 2)
		somethingWrong = somethingWrong %| (exists("barHeight") != 2)
		somethingWrong = somethingWrong %| (exists("barWidth") != 2)
		somethingWrong = somethingWrong %| (exists("barVertical") != 2)
		somethingWrong = somethingWrong %| (exists("barHorizontal") != 2)
		somethingWrong = somethingWrong %| (exists("verticalLegend") != 2)
		somethingWrong = somethingWrong %| (exists("labelSide") != 2)
		somethingWrong = somethingWrong %| (exists("labelRotation") != 2)

		if (somethingWrong)
			DoAlert 0, "The color legend preferences are corrupted. Restoring defaults."
			JEG_DefaultColorLegendProc("")
		endif
				
		SetDataFolder dfSav
	else
		// v3.0.3
		// assign hard-coded defaults first, to be sure that everything exists
		JEG_DefaultColorLegendProc("")

		// Read global preferences, if they exist
		
		Variable prefFile
		Open/Z/R/P=Igor/C="IGR0"/T="IPRF" prefFile as "JEG Color Legend Prefs"
		
		if (V_flag == 0)		// A prefs file exists
			JEG_LoadColorLegendPrefs(prefFile)
		endif
	endif
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_Integer2Real" --
// 
//  Converts an integral wave with JEG Color Legend's peculiar data dimension
//  scaling to a real wave
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_Integer2Real(w)
	Wave w
	
	if (JEG_WaveIsIntegral(w))
		String theWaveInfo = WaveInfo(w,0)
		Variable zScale
		
		String fullScale = JEG_StrByKey("FULLSCALE",theWaveInfo,":",";")
		zScale  = str2num(GetStrFromList(fullScale,2,","))			// data max full scale 
		zScale -= str2num(GetStrFromList(fullScale,1,","))			// data min full scale
		zScale /= 2^JEG_NumByKey("NUMTYPE",theWaveInfo,":",";")		// 2^8, 2^16, or 2^32
		
		Redimension/D w
		
		w *= zScale		// apply new scaling
	endif
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_RefreshColorLegendLinks" --
// 
//  Updates the links between Color Legends and their graphs.
//  These links will break if the user renames the graphs
// 
// --Version--Author------------------Changes-------------------------------
//    3.0.4     <jguyer@his.com> original
// -------------------------------------------------------------------------
// 
Function JEG_RefreshColorLegendLinks()
	String colorLegendList = ""
	String colorLegendPath = "root:Packages:'JEG Color Legend':"

	if (DataFolderExists(colorLegendPath))
		Variable folderCount = CountObjects(colorLegendPath,4)

		String legendName
		String graphName
		String newGraphName
		String graphs
		String notice
		
		Variable graphCount
		
		do 
			legendName = GetIndexedObjName(colorLegendPath,4,folderCount - 1)
			graphName = colorLegendPath + legendName + ":theGraphName"
			folderCount -= 1
			if (exists(graphName) == 2)
				SVAR theName = $graphName
				
				ControlInfo/W=$theName $("delete_" + legendName)
				
				if (V_Flag != 1)
					// link is broken, so must reconnect
					
					graphs = WinList("*", ";", "WIN:1")
					graphCount = NumInList(graphs, ";") - 1
					
					do 
						newGraphName = GetStrFromList(graphs, graphCount, ";") 
						graphCount -= 1
						
						ControlInfo/W=$newGraphName $("delete_" + legendName)

						if (V_Flag == 1)
							notice = "Updating link for '" + legendName
							notice += "' from '" + theName 
							notice += "' to '" + newGraphName + "'"
							print notice
							
							theName = newGraphName
							break
						endif
					while (graphCount >= 0)
				endif
			endif
		while (folderCount > 0)
	endif
End


//
// -------------------------------------------------------------------------
//	 
// "JEG_SetFullScale"	--
//	
//	Adjusts necessary parameters to encompass full data scale
//  of image or wave.
//  Assumes already located in the proper legend data folder
//	
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Function JEG_SetFullScale(keepOldScaling)
	Variable keepOldScaling

	SVAR theGraphName = theGraphName
	SVAR theImageName = theImageName
	SVAR theColorTable = theColorTable
	
	NVAR zScale = zScale
	NVAR upper = upper
	NVAR lower = lower 
	SVAR units = units
	
	NVAR reverseTable = reverseTable
							   
	NVAR imageIsTrace = imageIsTrace	
	NVAR imageIsContour = imageIsContour			   

	String theImageInfo
	
	String lowerStr = ""
	String upperStr = ""
	
	if (imageIsTrace)
		SVAR FofZWave = FofZWave

		if (keepOldScaling)					   
			String zColor
			theImageInfo = TraceInfo("",theImageName,0)
			zColor = JEG_StrByKey("RECREATION",theImageInfo,":",";")
			zColor = JEG_StrByKey("zColor(x)",zColor,"=",";")
			zColor = zColor[1,strlen(zColor)-2]		// clip off "{" and "}"
							   
			FofZWave = GetWavesDataFolder($GetStrFromList(zColor,0,","),2)
			lowerStr = GetStrFromList(zColor,1,",")
			upperStr = GetStrFromList(zColor,2,",")
			theColorTable = GetStrFromList(zColor,3,",")
		endif

		units = WaveUnits($(FofZWave),-1)
		WaveStats/Q $(FofZWave)
		if (keepOldScaling %& cmpstr(lowerStr,"*"))
			lower = str2num(lowerStr)
		else
			lower = V_min
		endif
		if (keepOldScaling %& cmpstr(upperStr,"*"))
			upper = str2num(upperStr)
		else
			upper = V_max
		endif
	else
		if (imageIsContour)
			Wave theImage = ContourNameToWaveRef("",theImageName)
		else
			Wave theImage = ImageNameToWaveRef("",theImageName)
		endif

		if (keepOldScaling)					   
			theImageInfo = ImageInfo("",theImageName,0)
	
			String ctab
			ctab = JEG_StrByKey("RECREATION",theImageInfo,":",";")
			if (imageIsContour)
				ctab = JEG_StrByKey("ctablines",ctab,"=",";")
			else
				ctab = JEG_StrByKey("ctab",ctab,"= ",";")	// note the space!!!
			endif
			ctab = ctab[1,strlen(ctab)-2]		// clip off "{" and "}"
	
			// What about cindex???�
		
			lowerStr = GetStrFromList(ctab,0,",")
			upperStr = GetStrFromList(ctab,1,",")
			theColorTable = GetStrFromList(ctab,2,",")
			reverseTable = str2num(GetStrFromList(ctab,3,","))
		endif
		
		Make/O/N=2 theBounds

		JEG_ComplexBounds(theImage,theBounds)
		
		if (keepOldScaling %& cmpstr(lowerStr,"*"))
			lower = str2num(lowerStr)
		else
			lower = theBounds[0] * zScale
		endif
		if (keepOldScaling %& cmpstr(upperStr,"*"))
			upper = str2num(upperStr)
		else
			upper = theBounds[1] * zScale
		endif

		units = WaveUnits(theImage,-1)
	endif

	KillWaves theBounds

	// Turn off zeroOffsetting
	NVAR zOffset = zOffset
	zOffset = 0

	JEG_SetSteps(GetDataFolder(0))

End

//
// -------------------------------------------------------------------------
//	 
// "JEG_SetSteps"	--
//	
//	Changes the SetVariable control stepsize to ~1% of range
//	Assumes already in proper data folder
//	
// --Version--Author------------------Changes-------------------------------
//    3.1     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//

Function JEG_SetSteps(legendName)
	String legendName
	SVAR theGraphName = theGraphName
	SVAR theImageName = theImageName
	SVAR units = units
	NVAR imageIsTrace = imageIsTrace
	NVAR imageIsContour = imageIsContour
	NVAR zScale = zScale
	
	Variable theMin, theMax

	if (imageIsTrace)
		SVAR FofZWave = FofZWave
		Wave theImage = TraceNameToWaveRef(theGraphName,theImageName)
	else 
		if (imageIsContour)
			Wave theImage = ContourNameToWaveRef(theGraphName,theImageName)
		else
			Wave theImage = ImageNameToWaveRef(theGraphName,theImageName)
		endif
	endif

	if (imageIsTrace)
		SVAR FofZWave = FofZWave
		WaveStats/Q $(FofZWave)
		theMin = V_min
		theMax = V_max
	else
		Make/O/N=2 theBounds

		JEG_ComplexBounds(theImage,theBounds)
		
		theMin = theBounds[0]
		theMax = theBounds[1]
		
		KillWaves theBounds
	endif
	
	Variable mantissa = log((theMax - theMin) * 0.01 * zScale)
	Variable characteristic = floor(mantissa)
	mantissa = abs(mantissa - characteristic)
	
	Variable increment = 10^characteristic * round(10^mantissa)


	// No sense incrementing integral waves by less than their resolution
	if (JEG_WaveIsIntegral(theImage))
		increment = Max(increment, zScale)		
	endif

	String setUpper = "upper_" + legendName
	String setLower = "lower_" + legendName

	SetVariable $(setUpper),limits={-INF,INF,increment},value=upper,format="% 6.3g "+units
	SetVariable $(setLower),limits={-INF,INF,increment},value=lower,format="% 6.3g "+units

End

//
// -------------------------------------------------------------------------
//	 
// "JEG_WaveIsIntegral"	--
//	
//	Returns	true if	w consists of 8, 16, or 32 bit integers
//	
// --Version--Author------------------Changes-------------------------------
//    2.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Function JEG_WaveIsIntegral(w)
	Wave w

	String theWaveInfo = WaveInfo(w,0)
	return ((JEG_NumByKey("NUMTYPE",theWaveInfo,":",";") %& (0x08 %| 0x10 %| 0x20)) != 0)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_WaveIsScaled" --
//	
//	Returns	true if	scaling	has	been applied to	the	data dimension of w
//	
// --Version--Author------------------Changes-------------------------------
//    2.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Function JEG_WaveIsScaled(w)
	Wave w

	String theWaveInfo = WaveInfo(w,0)
	return (str2num(GetStrFromList(JEG_StrByKey("FULLSCALE",theWaveInfo,":",";"),0,",")))
End

// -----------Preference File I/O-------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_LoadColorLegendPrefs" --
// 
//  Load color legend layout preferences from the file pointed to by
//  the file reference number prefFil
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_LoadColorLegendPrefs(prefFile)
	Variable prefFile

	FStatus prefFile
	if (!V_Flag)			// Invalid file refeference
		return 0
	endif

	String dfSav = GetDataFolder(1)

	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S 'JEG Color Legend'
	NewDataFolder/O/S Preferences
	
	String prefType = "0123456789012345"	// String must already be long enough
	FBinRead prefFile, prefType
	
	if (cmpstr(prefType,"JEG Color Legend") != 0)
		Close prefFile
		Abort "This file is not a JEG Color Legend preferences file"
	else
		Variable version
		FBinRead prefFile, version	// Ignore for now; we might need it later
	
		NVAR imageWidth = imageWidth
		FBinRead prefFile, imageWidth
		
		NVAR imageVertical = imageVertical
		FBinRead prefFile, imageVertical
		
		NVAR imageHorizontal = imageHorizontal
		FBinRead prefFile, imageHorizontal
		
		NVAR barHeight = barHeight
		FBinRead prefFile, barHeight
	
		NVAR barWidth = barWidth
		FBinRead prefFile, barWidth
	
		NVAR barVertical = barVertical
		FBinRead prefFile, barVertical
		
		NVAR barHorizontal = barHorizontal
		FBinRead prefFile, barHorizontal
		
		NVAR verticalLegend	= verticalLegend
		FBinRead prefFile, verticalLegend
	
		NVAR labelSide	= labelSide
		FBinRead prefFile, labelSide
	
		NVAR labelRotation	= labelRotation
		FBinRead prefFile, labelRotation

		Close prefFile
		
		JEG_ColorLegendConfigUpdate()
	endif
	
	SetDataFolder dfSav
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_StoreColorLegendPrefs" --
// 
//  Save color legend layout preferences to the file pointed to by
//  the file reference number prefFil
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_StoreColorLegendPrefs(prefFile)
	Variable prefFile
	
	FStatus prefFile
	if (!V_Flag)			// Invalid file refeference
		return 0
	endif

	String dfSav = GetDataFolder(1)

	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S 'JEG Color Legend'
	NewDataFolder/O/S Preferences
	
	String prefType = "JEG Color Legend"
	FBinWrite prefFile, prefType		// To distinguish from any other preference files

	Variable version = 3.01
	FBinWrite prefFile, version			// Preference file version

	NVAR imageWidth = imageWidth
	FBinWrite prefFile, imageWidth
	
	NVAR imageVertical = imageVertical
	FBinWrite prefFile, imageVertical
	
	NVAR imageHorizontal = imageHorizontal
	FBinWrite prefFile, imageHorizontal
	
	NVAR barHeight = barHeight
	FBinWrite prefFile, barHeight

	NVAR barWidth = barWidth
	FBinWrite prefFile, barWidth

	NVAR barVertical = barVertical
	FBinWrite prefFile, barVertical
	
	NVAR barHorizontal = barHorizontal
	FBinWrite prefFile, barHorizontal
	
	NVAR verticalLegend	= verticalLegend
	FBinWrite prefFile, verticalLegend

	NVAR labelSide	= labelSide
	FBinWrite prefFile, labelSide

	NVAR labelRotation	= labelRotation
	FBinWrite prefFile, labelRotation

	Close prefFile

	SetDataFolder dfSav
End

// -----------Panels & Controls---------------------------------------------

//
// -------------------------------------------------------------------------
//	 
// "JEG_AddColorLegendControls"	--
//	
//	Add	controls to	top	of graph to	adjust data	range, color coding, and scaling
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> enable zero offset
// -------------------------------------------------------------------------
//
Function JEG_AddColorLegendControls(legendName)
	String legendName
	String dfSav= GetDataFolder(1)
	String legendPath = "root:Packages:'JEG Color Legend':" + legendName
	SetDataFolder $legendPath
	
	SVAR theGraphName = theGraphName
	SVAR theImageName = theImageName
	
	Wave theImage = ImageNameToWaveRef(theGraphName,theImageName)
	SVAR theColorTable = theColorTable
	
	NVAR imageIsTrace = imageIsTrace
	
	NVAR reverseTable = reverseTable
	
	ControlBar 38
	String setUpper = "upper_" + legendName
	String setLower = "lower_" + legendName
	String fullRange = "full_" + legendName
	String colorTable = "color_" + legendName
	String useScaling = "scale_" + legendName
	String zeroUpper = "zeroUpper_" + legendName
	String zeroLower = "zeroLower_" + legendName
	String reverseBox = "reverse_" + legendName
	String deleteZ = "delete_" + legendName
	
	// SetVariable controller for lower z limit
	SetVariable $(setLower),pos={89,19},size={168,17},title="lower z:"
	SetVariable $(setLower),font = "Monaco", proc=JEG_SetLowerProc
	SetVariable $(setLower),help={"Adjust the lower threshold of the image display and its scale-bar."}
	
	// SetVariable controller for upper z limit
	SetVariable $(setUpper),pos={89,1},size={168,17},title="upper z:"
	SetVariable $(setUpper),font = "Monaco", proc=JEG_SetUpperProc
	SetVariable $(setUpper),help={"Adjust the upper threshold of the image display and its scale-bar."}
	
	// Return display to full data range
	Button $(fullRange),pos={3,1},size={80,18},title="Full Range", proc=JEG_FullScaleProc
	Button $(fullRange),help={"Restore the image thresholds to the full limits of the data."}
	
	// Offset upper limit to zero
	CheckBox $(zeroUpper),pos={260,0},size={61,20},title="set to"
	CheckBox $(zeroUpper),proc=JEG_OffsetZeroProc
	CheckBox $(zeroUpper),help={"Offset the upper threshold to zero."}

	// Offset lower limit to zero
	CheckBox $(zeroLower),pos={260,18},size={58,17},title=" zero"
	CheckBox $(zeroLower),proc=JEG_OffsetZeroProc
	CheckBox $(zeroLower),help={"Offset the lower threshold to zero."}
	
	// Change color table of image _and_ scale bar
	if (imageIsTrace)
		PopupMenu $(colorTable) value=JEG_ColorIndexWaves(1)
	else
		PopupMenu $(colorTable) value=JEG_ColorIndexWaves(0)
	endif
	PopupMenu $(colorTable) popvalue=theColorTable, pos={329,1}, proc=JEG_ColorTableProc
	PopupMenu $(colorTable) help={"Set the colors used to display the image and its scale-bar."}
	
	// Reverse color table
	CheckBox $(reverseBox),pos={327,19},size={73,18},title="Reverse"
	CheckBox $(reverseBox),value=reverseTable, proc=JEG_ReverseTableProc
	CheckBox $(reverseBox),help={"Reverse the color table used to display the image and its scale-bar."}

	// Adjust integer values by dimensional scaling
	Variable doScaling = JEG_WaveIsIntegral(theImage) %& JEG_WaveIsScaled(theImage)
	doScaling = doScaling %& !imageIsTrace
	if (doScaling)
		CheckBox $(useScaling),pos={403,20},size={125,15},title="Integer scaling"
		CheckBox $(useScaling),value=1,proc=JEG_AdjustScaling
		CheckBox $(useScaling),help={"Apply non-integral scaling to the data dimension of integer waves."}
	endif
	
	Button $(deleteZ),pos={11,20},size={65,16},title="Delete�",proc=JEG_DeleteColorLegendProc
	Button $(deleteZ),help={"Delete the color legend and, if desired, its controls"}

	// !!! Several controls are affected by this call
	JEG_AdjustScaling(useScaling,doScaling)
	
	SetDataFolder dfSav
End

//
// -------------------------------------------------------------------------
//   
// "JEG_ColorLegendPrefs" --
//  
//  Panel to adjust display parameters for a color legend
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Proc JEG_ColorLegendPrefs()
	PauseUpdate; Silent 1		// building window...
	
	NewPanel /W=(98,43,684,518) as "Color legend display preferences"
	ModifyPanel cbRGB=(65535,60076,49151)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (49151,60031,65535)
	DrawRect 102,63,452,413
	SetDrawEnv fillfgc= (49151,60031,65535)
	DrawRect 497,134,473,323
	SetDrawEnv arrow= 3
	DrawLine 516,134,516,322
	SetDrawEnv arrow= 3
	DrawLine 486,322,486,432
	SetDrawEnv arrow= 1
	DrawLine 525,289,496,289
	DrawLine 500,134,528,134
	DrawLine 500,322,528,322
	SetDrawEnv arrow= 3
	DrawLine 79,50,508,50
	DrawRect 275,42,307,59
	SetDrawEnv textxjust= 1,textyjust= 2
	DrawText 291,45,"1.00"
	SetDrawEnv fsize= 18
	DrawText 254,242,"Image"
	SetDrawEnv fsize= 18,textrot= 90
	DrawText 477,278,"Color legend"
	SetDrawEnv arrow= 3
	DrawLine 102,367,451,367
	SetDrawEnv arrow= 3
	DrawLine 153,63,153,412
	SetDrawEnv linepat= 3,fillpat= 0
	DrawRect 78,2,510,434
	SetDrawEnv arrow= 3
	DrawLine 472,289,78,289
	SetDrawEnv arrow= 2
	DrawLine 77,367,58,367
	SetDrawEnv arrow= 1
	DrawLine 153,462,153,433
	SetDrawEnv arrow= 2
	DrawLine 77,367,66,367
	SetDrawEnv fsize= 14,fstyle= 2,textxjust= 1,textyjust= 2
	DrawText 297,449,"All dimensions are plot-relative"

	JEG_EnsureColorLegendPrefs()
	
	SetVariable barWidth pos={530,281},size={50,15},title=" "
	SetVariable barWidth limits={0,1,0.01},proc=JEG_ColorBarWidthProc
	SetVariable barWidth value= root:Packages:'JEG Color Legend':Preferences:barWidth
	SetVariable barWidth help={"Width of the color legend bar"}

	SetVariable barHeight,pos={502,223},size={50,15},title=" "
	SetVariable barHeight,limits={0,1,0.01},proc=JEG_ColorBarLengthProc
	SetVariable barHeight,value= root:Packages:'JEG Color Legend':Preferences:barHeight
	SetVariable barHeight,help={"Length of the color legend bar"}

	SetVariable barVertical,pos={468,368},size={50,15},title=" "
	SetVariable barVertical,limits={0,1,0.01},proc=JEG_ColorBarVerticalProc
	SetVariable barVertical,value= root:Packages:'JEG Color Legend':Preferences:barVertical
	SetVariable barVertical,help={"Offset of color legend bar from the bottom of the plot"}

	SetVariable barHorizontal,pos={260,282},size={50,15},title=" "
	SetVariable barHorizontal,limits={0,1,0.01},proc=JEG_ColorBarHorizontalProc
	SetVariable barHorizontal,value= root:Packages:'JEG Color Legend':Preferences:barHorizontal
	SetVariable barHorizontal,help={"Offset of color legend bar from the left edge of the plot"}

	SetVariable imageWidth,pos={261,360},size={50,15},title=" "
	SetVariable imageWidth,limits={0,1,0.01},proc=JEG_ImageWidthProc
	SetVariable imageWidth,value= root:Packages:'JEG Color Legend':Preferences:imageWidth
	SetVariable imageWidth,help={"Width of the image"}

	SetVariable imageHorizontal,pos={4,360},size={50,15},title=" "
	SetVariable imageHorizontal,limits={0,1,0.01},proc=JEG_ImageHorizontalProc
	SetVariable imageHorizontal,value= root:Packages:'JEG Color Legend':Preferences:imageHorizontal
	SetVariable imageHorizontal,help={"Offset of the image from the left edge of the plot"}

	SetVariable imageVertical,pos={132,416},size={50,15},title=" "
	SetVariable imageVertical,limits={0,1,0.01},proc=JEG_ImageVerticalProc
	SetVariable imageVertical,value= root:Packages:'JEG Color Legend':Preferences:imageVertical
	SetVariable imageVertical,help={"Offset of the image from the bottom of the plot"}

	Button capturePrefs,pos={6,17},size={65,20},proc=JEG_CaptureColorLegendProc,title="Capture"
	Button capturePrefs,help={"Capture these layout settings for new experiments"}

	Button revertToSaved,pos={6,41},size={65,20},proc=JEG_RevertColorLegendProc,title="Revert"
	Button revertToSaved,help={"Revert layout settings to those saved in file \":JEG Color Legend prefs\""}

	Button restoreDefaults,pos={6,146},size={65,20},proc=JEG_DefaultColorLegendProc,title="Defaults"
	Button restoreDefaults,help={"Restore layout settings to the hard-coded defaults"}

	Button configure,pos={466,104},size={70,20},title="Legend�",proc=JEG_ConfigureColorLegendProc
	Button configure,help={"Change color legend configuration"}

	Button savePrefs,pos={6,79},size={65,20},proc=JEG_SaveColorLegendProc,title="Save�"
	Button savePrefs,help={"Save these layout settings in a preference file"}
	
	Button loadPrefs,pos={6,103},size={65,20},proc=JEG_LoadColorLegendProc,title="Load�"
	Button loadPrefs,help={"Load layout settings from a preference file"}

	// Just to reinforce to the user that the image remains proportional
	ValDisplay imageHeight,pos={137,215},size={36,15},limits={0,1,0},barmisc={0,1000}
	ValDisplay imageHeight,value= root:Packages:'JEG Color Legend':Preferences:imageWidth
	String s = "Height of the image. Always equal to its width.\r"
	s += "To change the proportions of the image, use 'ModifyGraph height={Aspect,n}', etc."
	ValDisplay imageHeight,help={s}
End

//
// -------------------------------------------------------------------------
//   
// "JEG_ColorLegendConfig" --
//  
//  Sub-panel to adjust configuration of color legend
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Proc JEG_ColorLegendConfig()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(150,50,444,314) as "Color Legend Configuration"
	ModifyPanel cbRGB=(65535,60076,49151)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (49151,60031,65535)
	DrawRect 35,45,210,69
	SetDrawEnv fsize= 18,textyjust= 2
	DrawText 60,49,"Horizontal Legend"
	SetDrawEnv fillfgc= (49151,60031,65535)
	DrawRect 184,82,208,238
	SetDrawEnv fsize= 18,textyjust= 2,textrot= 90
	DrawText 187,89,"Vertical Legend"

	JEG_EnsureColorLegendPrefs()
	
	Variable vertLegend = root:Packages:'JEG Color Legend':Preferences:verticalLegend
	Variable labelSide = root:Packages:'JEG Color Legend':Preferences:labelSide
	
	CheckBox VerticalLegend,pos={188,215},size={16,20},title="",proc=JEG_VerticalLegendProc
	CheckBox VerticalLegend,value=vertLegend
	
	CheckBox HorizontalLegend,pos={41,47},size={16,20},title="",proc=JEG_HorizontalLegendProc
	CheckBox HorizontalLegend,value=(!vertLegend)

	CheckBox TopLabel,pos={89,8},size={65,30},title="Top\rLabels",proc=JEG_TopLabelProc
	CheckBox TopLabel,value=(!vertLegend %& labelSide)

	CheckBox BottomLabel,pos={89,75},size={67,30},title="Bottom\rLabels",proc=JEG_BottomLabelProc
	CheckBox BottomLabel,value=(!vertLegend %& !labelSide)

	CheckBox LeftLabel,pos={116,145},size={65,30},title="Left\rLabels",proc=JEG_LeftLabelProc
	CheckBox LeftLabel,value=(vertLegend %& !labelSide)

	CheckBox RightLabel,pos={212,145},size={65,30},title="Right\rLabels",proc=JEG_RightLabelProc
	CheckBox RightLabel,value=(vertLegend %& labelSide)

	PopupMenu LabelOrientation,pos={9,198},size={160,19},title="Label Rotation"
	PopupMenu LabelOrientation,proc=JEG_ColorLegendRotationProc
	PopupMenu LabelOrientation,mode=round((root:Packages:'JEG Color Legend':Preferences:labelRotation + 180)/90)
	PopupMenu LabelOrientation,value= #"\" -90�;     0�;   90�; 180�;\""
EndMacro

// -----------SetVariable Procs---------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_ImageHorizontalProc" --
// 
//  Adjustment procedure for the image horizontal position
//  
//  Ensures that sum of imageWidth and imageHorizontal remains <= 1.0
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ImageHorizontalProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the image width and the bar horizontal position can't exceed 1.0

	NVAR imageWidth = root:Packages:'JEG Color Legend':Preferences:imageWidth
	
	imageWidth = Min(imageWidth,1-varNum)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ImageVerticalProc" --
// 
//  Adjustment procedure for the image vertical position
//  
//  Ensures that sum of imageWidth and imageVertical remains <= 1.0
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ImageVerticalProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the image width and the image vertical position can't exceed 1.0

	NVAR imageWidth = root:Packages:'JEG Color Legend':Preferences:imageWidth
	
	imageWidth = Min(imageWidth,1-varNum)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ImageWidthProc" --
// 
//  Adjustment procedure for the image width
//  
//  Ensures that sum of imageWidth and imageHorizontal remains <= 1.0
//	AND that the sum of imageWidth and imageVertical remains <= 1.0
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ImageWidthProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName
	Variable	varNum
	String		varStr
	String		varName
	
	// The sum of the image width and the image vertical can't exceed 1.0
	
	NVAR imageHorizontal = root:Packages:'JEG Color Legend':Preferences:imageHorizontal
	NVAR imageVertical = root:Packages:'JEG Color Legend':Preferences:imageVertical
	
	imageHorizontal = Min(imageHorizontal,1-varNum)
	imageVertical = Min(imageVertical,1-varNum)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_SetLowerProc" --
//	
//	Adjust the lower bound of the display range
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> enable zero offset
// -------------------------------------------------------------------------
//
Function JEG_SetLowerProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName	// Must be "lower_" + legendName
	Variable varNum
	String varStr	// ignored
	String varName	// ignored
														// strip leading "lower_"
	String legendPath = "root:Packages:'JEG Color Legend':" + ctrlName[6,strlen(ctrlName)-1]
	String dfSav = GetDataFolder(1)
	SetDataFolder $legendPath

	NVAR lower = lower
	NVAR zeroSelect = zeroSelect
	NVAR zOffset = zOffset
	
	if (zeroSelect == 1)		// In case the lower threshold is zeroed,
		lower = 0				// changes to the lower threshold offset
		zOffset -= varNum		// the band, but leave it the same width...
	else
		lower = varNum			// ...otherwise, change the threshold
	endif
	
	JEG_AdjustLimits()
	
	SetDataFolder dfSav
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_SetUpperProc" --
//	
//	Adjust the upper bound of the display range
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> enable zero offset
// -------------------------------------------------------------------------
//
Function JEG_SetUpperProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName	// Must be "upper_" + legendName
	Variable varNum
	String varStr	// ignored
	String varName	// ignored
														// strip leading "upper_"
	String legendPath = "root:Packages:'JEG Color Legend':" + ctrlName[6,strlen(ctrlName)-1]
	String dfSav = GetDataFolder(1)
	SetDataFolder $legendPath

	NVAR upper = upper
	NVAR zeroSelect = zeroSelect
	NVAR zOffset = zOffset
	
	if (zeroSelect == 2)		// In case the upper threshold is zeroed,
		upper = 0				// changes to the upper threshold offset
		zOffset -= varNum		// the band, but leave it the same width...
	else
		upper = varNum			// ...otherwise, change the threshold
	endif

	JEG_AdjustLimits()
	
	SetDataFolder dfSav
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ColorBarHorizontalProc" --
// 
//  Adjustment procedure for the color legend elevation
//  
//  Ensures that sum of barWidth and barHorizontal remains <= 1.0
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ColorBarHorizontalProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the bar width and the bar horizontal position can't exceed 1.0

	NVAR barWidth = root:Packages:'JEG Color Legend':Preferences:barWidth
	
	barWidth = Min(barWidth,1-varNum)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ColorBarLengthProc" --
// 
//  Adjustment procedure for the color legend length
//  
//  Ensures that sum of barHeight and barVertical remains <= 1.0
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ColorBarLengthProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the bar length and the bar vertical position can't exceed 1.0
	
	NVAR barVertical = root:Packages:'JEG Color Legend':Preferences:barVertical
	
	barVertical = Min(barVertical,1-varNum)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ColorBarVerticalProc" --
// 
//  Adjustment procedure for the color legend vertical position
//  
//  Ensures that sum of barHeight and barVertical remains <= 1.0
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ColorBarVerticalProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName	// ignored
	Variable	varNum
	String		varStr		// ignored
	String		varName		// ignored
	
	// The sum of the bar length and the bar vertical position can't exceed 1.0

	NVAR barHeight = root:Packages:'JEG Color Legend':Preferences:barHeight
	
	barHeight = Min(barHeight,1-varNum)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ColorBarWidthProc" --
// 
//  Adjustment procedure for the color legend width
//  
//  Ensures that sum of barWidth and barHorizontal remains <= 1.0
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ColorBarWidthProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String		ctrlName
	Variable	varNum
	String		varStr
	String		varName
	
	// The sum of the bar length and the bar vertical position can't exceed 1.0
	
	NVAR barHorizontal = root:Packages:'JEG Color Legend':Preferences:barHorizontal
	
	barHorizontal = Min(barHorizontal,1-varNum)
End

// -----------Button Procs--------------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_CaptureColorLegendProc" --
// 
//  Saves the user's color legend layout preferences to "JEG Color Legend Prefs"
//  in the Igor folder. These prefs will be automatically loaded by new
//  experiments which use the "JEG Color Legend" package.
// 
// Side effects:
//  Creates a file "JEG Color Legend Prefs" in the Igor folder
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_CaptureColorLegendProc(ctrlName) : ButtonControl
	String ctrlName		// ignored
	
	Variable prefFile
	Open/P=Igor/C="IGR0"/T="IPRF" prefFile as "JEG Color Legend Prefs"
	
	JEG_StoreColorLegendPrefs(prefFile)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ConfigureColorLegendProc" --
// 
//  Configure layout of color legend itself
// 
// --Version--Author------------------Changes-------------------------------
//    3.0.0    <j-guyer@nwu.edu> original
//    3.0.1    <j-guyer@nwu.edu> don't create multiple panels
// -------------------------------------------------------------------------
// 
Proc JEG_ConfigureColorLegendProc(ctrlName) : ButtonControl
	String ctrlName		// ignored

	if (strlen(WinList("JEG_ConfigureColorLegendPanel",";","")) != 0)
		DoWindow/F JEG_ConfigureColorLegendPanel
	else
		JEG_ColorLegendConfig()
	
		// Rename it so we can find it again
		DoWindow/C JEG_ConfigureColorLegendPanel
	endif
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_DefaultColorLegendProc" --
// 
//  Set color legend layout to my preferences
//  No need to change the code now; users can set their own preferences
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_DefaultColorLegendProc(ctrlName) : ButtonControl
	String ctrlName		// ignored
	String dfSav = GetDataFolder(1)

	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S 'JEG Color Legend'
	NewDataFolder/O/S Preferences
	
	// No need to mess with these; 
	// use the Misc->'Color legend preferences�' 
	// control panel to set your own prefs
			
	Variable/G imageWidth		= 0.94
	Variable/G imageVertical	= 0.00
	Variable/G imageHorizontal	= 0.00
	Variable/G barHeight		= 0.40
	Variable/G barWidth			= 0.03
	Variable/G barVertical		= 0.27
	Variable/G barHorizontal	= 0.97
	
	Variable/G verticalLegend	= 1
	Variable/G labelSide		= 1		// 1 is right on vertical and top on horizontal
	Variable/G labelRotation	= 0
	
	JEG_ColorLegendConfigUpdate()
	
	SetDataFolder dfSav
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_ColorLegendConfigUpdate" --
//	
//	If the Color Legend configuration panel is already open, update
//  it's controls to reflect current values
//	
// --Version--Author------------------Changes-------------------------------
//    3.0.1     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Function JEG_ColorLegendConfigUpdate()
	if (strlen(WinList("JEG_ConfigureColorLegendPanel",";","")) != 0)
		NVAR vertLegend = root:Packages:'JEG Color Legend':Preferences:verticalLegend
		NVAR labelSide = root:Packages:'JEG Color Legend':Preferences:labelSide
		NVAR labelRotation = root:Packages:'JEG Color Legend':Preferences:labelRotation
		
		CheckBox VerticalLegend,value=vertLegend,win=JEG_ConfigureColorLegendPanel
		CheckBox HorizontalLegend,value=(!vertLegend),win=JEG_ConfigureColorLegendPanel
		CheckBox TopLabel,value=(!vertLegend %& labelSide),win=JEG_ConfigureColorLegendPanel
		CheckBox BottomLabel,value=(!vertLegend %& !labelSide),win=JEG_ConfigureColorLegendPanel
		CheckBox LeftLabel,value=(vertLegend %& !labelSide),win=JEG_ConfigureColorLegendPanel
		CheckBox RightLabel,value=(vertLegend %& labelSide),win=JEG_ConfigureColorLegendPanel
		PopupMenu LabelOrientation,mode=round((labelRotation + 180)/90),win=JEG_ConfigureColorLegendPanel
	endif
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_DeleteColorLegendProc" --
//	
//	Delete the data dimension scale-bar and, if desired, its controls
//	
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Function JEG_DeleteColorLegendProc(ctrlName) : ButtonControl
	String ctrlName		// must be "delete_" + legendName

						// strip leading "delete_"
	String legendName = ctrlName[7,strlen(ctrlName)-1]
	
	DoAlert 2, "Delete the controls along with the data dimension scale-bar?"
	Variable killControls = V_Flag
	
	if (killControls == 3)		// User cancelled
		return 0
	endif
	
	JEG_ZapColorLegend(killControls==1,legendName)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_FullScaleProc" --
//	
//	Restore	the	displayed  range to	the	full data range	of the image
//	Leaves scaling intact
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    3.0     <j-guyer@nwu.edu> enable zero offset & f(z) traces
// -------------------------------------------------------------------------
//
Function JEG_FullScaleProc(ctrlName) : ButtonControl
	String ctrlName
	// ctrlName must be "full_" + legendName
	
						// strip leading "full_"
	String legendName = ctrlName[5,strlen(ctrlName)-1]
	String legendPath = "root:Packages:'JEG Color Legend':" + legendName
	String dfSav = GetDataFolder(1)
	SetDataFolder $legendPath
	
	JEG_SetFullScale(0)

	// Turn off zeroOffsetting
	CheckBox $("zeroUpper_"+legendName), value=0
	CheckBox $("zeroLower_"+legendName), value=0
	
	JEG_AdjustLimits()
	
	SetDataFolder dfSav
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_LoadColorLegendProc" --
// 
//  Load color legend layout preferences from a preferences file
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_LoadColorLegendProc(ctrlName) : ButtonControl
	String ctrlName		// ignored
	
	Variable prefFile
	Open/R/C="IGR0"/T="IPRF"/M="Select a Color Legend preference file" prefFile
	
	JEG_LoadColorLegendPrefs(prefFile)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_RevertColorLegendProc" --
// 
//  Revert the color legend layout preferences to those last saved in 
//  ":Igor Pro Folder:JEG Color Legend Prefs"
//  If it doesn't exist, asks the user if they want the defaults
//  If not, leaves the settings alone
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_RevertColorLegendProc(ctrlName) : ButtonControl
	String ctrlName		// ignored
	
	Variable prefFile
	Open/Z/R/P=Igor/C="IGR0"/T="IPRF" prefFile as "JEG Color Legend Prefs"
	
	if (V_Flag == 0)		// A prefs file exists
		JEG_LoadColorLegendPrefs(prefFile)
	else					// See if user wants the defaults
		DoAlert 1, "No preferences file exists.\rUse defaults?"
		
		if (V_Flag == 1)
			JEG_DefaultColorLegendProc("")
		endif
	endif
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_SaveColorLegendProc" --
// 
//  Saves the user's color legend layout preferences to a preferences file
// 
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_SaveColorLegendProc(ctrlName) : ButtonControl
	String ctrlName		// ignored
	
	Variable prefFile
	Open/C="IGR0"/T="IPRF"/M="Save Color Legend preferences as" prefFile as "Color Legend Prefs"
	
	JEG_StoreColorLegendPrefs(prefFile)
End

// -----------CheckBox Procs------------------------------------------------

//
// -------------------------------------------------------------------------
//	 
// "JEG_OffsetZeroProc" --
//	
//	Adjust the selected threshold to zero
//	
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Function JEG_OffsetZeroProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	// ctrlName must be "zeroUpper_" or "zeroLower_"+ legendName
	Variable checked	// 1 if checked (offset to zero), 0 if not
	
						// strip leading "zero?????_"
	String legendName = ctrlName[10,strlen(ctrlName)-1]
	String legendPath = "root:Packages:'JEG Color Legend':" + legendName
	String dfSav = GetDataFolder(1)
	SetDataFolder $legendPath

	NVAR upper = upper
	NVAR lower = lower
	NVAR zOffset = zOffset
	NVAR zeroSelect = zeroSelect // 0 for neither, 1 for lower, 2 for upper
	
	if (cmpstr("zeroUpper",ctrlName[0,8])==0)
		if (checked)
			zeroSelect = 2
			
			lower -= zOffset
			zOffset -= upper
			lower += zOffset
			upper = 0

			// Upper and lower zero offset are mutually exclusive
			CheckBox $("zeroLower_"+legendName), value=0
		else
			zeroSelect = 0
			
			upper -= zOffset
			lower -= zOffset
			zOffset = 0
		endif
	else 
		if (cmpstr("zeroLower",ctrlName[0,8])==0)
			if (checked)
				zeroSelect = 1
				
				upper -= zOffset
				zOffset -= lower
				upper += zOffset
				lower = 0
				
				// Upper and lower zero offset are mutually exclusive
				CheckBox $("zeroUpper_"+legendName), value=0
			else
				zeroSelect = 0
				
				upper -= zOffset
				lower -= zOffset
				zOffset = 0
			endif
		else
			DoAlert 0, ctrlName[0,8] + " is a bogus check-box type, dude"
			SetDataFolder dfSav
			return 0
		endif
	endif
	
	JEG_AdjustLimits()
	
	SetDataFolder dfSav
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_ReverseTableProc" --
//	
//	Reverse the color table or index wave used to display the image
//	
// --Version--Author------------------Changes-------------------------------
//    3.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
//
Function JEG_ReverseTableProc(ctrlName,checked) : CheckBoxControl
	String ctrlName		// Must be "reverse_" + legendName
	Variable checked
										// strip leading "reverse_"
	String legendPath = "root:Packages:'JEG Color Legend':" + ctrlName[8,strlen(ctrlName)-1]
	String dfSav = GetDataFolder(1)
	SetDataFolder $legendPath
	
	NVAR reverseTable = reverseTable
	reverseTable = checked
	
	JEG_AdjustLimits()
	
	SetDataFolder dfSav
End

// -----------PopupMenu Procs-----------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_ColorLegendRotationProc" --
// 
//  Set the rotation value for the color legend labels
// -------------------------------------------------------------------------
// 
Function JEG_ColorLegendRotationProc(ctrlName,popNum,popStr) : PopupMenuControl
	String		ctrlName	// ignored
	Variable	popNum		// ignored
	String		popStr
	
	NVAR labelRotation = root:Packages:'JEG Color Legend':Preferences:labelRotation
	labelRotation = str2num(popStr)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_ColorTableProc"	--
//	
//	Change the color table or index	wave used to display the image
//	
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
//    2.0     <j-guyer@nwu.edu> color index waves
// -------------------------------------------------------------------------
//
Function JEG_ColorTableProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName	// Must be "color_" + legendName
	Variable popNum
	String popStr	// Name of the color table or color index wave
	
														// strip leading "color_"
	String legendPath = "root:Packages:'JEG Color Legend':" + ctrlName[6,strlen(ctrlName)-1]
	String dfSav = GetDataFolder(1)
	SetDataFolder $legendPath
	
	SVAR theColorTable = theColorTable
	theColorTable = popStr
	
	NVAR useIndexWave = useIndexWave
	if (popNum <= 8)	// It's a color table
		useIndexWave = 0
	else					// It's a color index wave
		useIndexWave = 1
		Duplicate/O ::'Color Index Waves':$popStr 'Color Index Wave'
	endif
	
	JEG_AdjustLimits()
	
	SetDataFolder dfSav
End

// -----------CheckBox Procs------------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_HorizontalLegendProc" --
// 
//  Set color legend in horizontal orientation
// -------------------------------------------------------------------------
// 
Function JEG_HorizontalLegendProc(ctrlName,checked) : CheckBoxControl
	String ctrlName	 // ignored
	Variable checked
	
	NVAR verticalLegend = root:Packages:'JEG Color Legend':Preferences:verticalLegend
	NVAR labelSide = root:Packages:'JEG Color Legend':Preferences:labelSide
	
	if (checked)		
		CheckBox TopLabel value = labelSide
		CheckBox BottomLabel value = !labelSide
		
		verticalLegend = 0
		CheckBox VerticalLegend value = 0
		CheckBox RightLabel value = 0
		CheckBox LeftLabel value = 0
	else
		CheckBox TopLabel value = 0
		CheckBox BottomLabel value = 0
		
		verticalLegend = 1
		CheckBox VerticalLegend value = 1
		CheckBox RightLabel value = labelSide
		CheckBox LeftLabel value = !labelSide
	endif
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_VerticalLegendProc" --
// 
//  Set color legend in vertical orientation
// -------------------------------------------------------------------------
// 
Function JEG_VerticalLegendProc(ctrlName,checked) : CheckBoxControl
	String ctrlName	 // ignored
	Variable checked
	
	NVAR verticalLegend = root:Packages:'JEG Color Legend':Preferences:verticalLegend
	NVAR labelSide = root:Packages:'JEG Color Legend':Preferences:labelSide
	
	if (checked)		
		CheckBox RightLabel value = labelSide
		CheckBox LeftLabel value = !labelSide
		
		verticalLegend = 1
		CheckBox HorizontalLegend value = 0
		CheckBox TopLabel value = 0
		CheckBox BottomLabel value = 0
	else
		CheckBox RightLabel value = 0
		CheckBox LeftLabel value = 0
		
		verticalLegend = 0
		CheckBox HorizontalLegend value = 1
		CheckBox TopLabel value = labelSide
		CheckBox BottomLabel value = !labelSide
	endif
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_RightLabelProc" --
// 
//  Set labels to right side of a vertical color legend
// -------------------------------------------------------------------------
// 
Function JEG_RightLabelProc(ctrlName,checked) : CheckBoxControl
	String ctrlName	 // ignored
	Variable checked
	
	NVAR labelSide = root:Packages:'JEG Color Legend':Preferences:labelSide
	
	labelSide = checked
	
	CheckBox VerticalLegend value = 1

	JEG_VerticalLegendProc("",1)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_LeftLabelProc" --
// 
//  Set labels to left side of a vertical color legend
// -------------------------------------------------------------------------
// 
Function JEG_LeftLabelProc(ctrlName,checked) : CheckBoxControl
	String ctrlName	 // ignored
	Variable checked
	
	NVAR labelSide = root:Packages:'JEG Color Legend':Preferences:labelSide
	
	labelSide = !checked
	
	CheckBox VerticalLegend value = 1

	JEG_VerticalLegendProc("",1)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_TopLabelProc" --
// 
//  Set top labels on a horizontal color legend
// -------------------------------------------------------------------------
// 
Function JEG_TopLabelProc(ctrlName,checked) : CheckBoxControl
	String ctrlName	 // ignored
	Variable checked
	
	NVAR labelSide = root:Packages:'JEG Color Legend':Preferences:labelSide
	
	labelSide = checked
	
	CheckBox HorizontalLegend value = 1

	JEG_HorizontalLegendProc("",1)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_BottomLabelProc" --
// 
//  Set bottom labels on a horizontal color legend
// -------------------------------------------------------------------------
// 
Function JEG_BottomLabelProc(ctrlName,checked) : CheckBoxControl
	String ctrlName	 // ignored
	Variable checked
	
	NVAR labelSide = root:Packages:'JEG Color Legend':Preferences:labelSide
	
	labelSide = !checked
	
	CheckBox HorizontalLegend value = 1
	
	JEG_HorizontalLegendProc("",1)
End
