//-*-Igor-*-
// ###################################################################
//  Igor Pro - JEG Image Tools
// 
//  FILE: "JEG Zoom Graph"
//                                    created: 3/8/97 {3:23:17 AM} 
//                                last update: 8/11/97 {11:26:34 PM} 
//  Author: Jonathan Guyer
//  E-mail: <jguyer@his.com>
//     www: <http://www.his.com/~jguyer/>
//          
//  When multiple image frames are present (multiple pairs of axes),
//  the Expand and Shrink marquee routines don't work properly;
//  they scale all waves that fall between any bounds, not just the
//  ones that fall within the marquee. These routines correct this
//  discrepancy.
// 
//  modified by  rev reason
//  -------- --- --- -----------
//  3/8/97   JEG 1.0 original
// ###################################################################
// 

#pragma rtGlobals=1		// Use modern global access method.

// -----------Graph Marquee routines----------------------------------------

Function JEG_Expand() : GraphMarquee
	JEG_ZoomGraph(3,1)
End

Function JEG_HorizExpand() : GraphMarquee
	JEG_ZoomGraph(1,1)
End

Function JEG_VertExpand() : GraphMarquee
	JEG_ZoomGraph(2,1)
End

Function JEG_Shrink() : GraphMarquee
	JEG_ZoomGraph(3,0)
End

Function JEG_HorizShrink() : GraphMarquee
	JEG_ZoomGraph(1,0)
End

Function JEG_VertShrink() : GraphMarquee
	JEG_ZoomGraph(2,0)
End

// -----------Utilities-----------------------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_ZoomGraph" --
// 
//  Expand or shrink the waves which fall within the marquee.
//  Bit 0 of whichAxis indicates whether horizontal adjustment is to occur
//  Bit 1 of whichAxis indicates whether vertical adjustment is to occur
// 
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ZoomGraph(whichAxis,expand)
	Variable whichAxis, expand

	String theWave, theInfo
	
	GetMarquee
	
	if (V_flag)		// no sense in doing this if there was no marquee
	
		// Check each image
		String theList = ImageNameList("",";")
		Variable i = 0
		do
			theWave = GetStrFromList(theList, i, ";")
			if (strlen(theWave) <= 0)
				break
			endif
			i += 1
			
			theInfo = ImageInfo("",theWave,0)
			JEG_ZoomIfWithin(theInfo,whichAxis,expand)
		while (1)
		
		// Check each trace
		theList = TraceNameList("",";",1)
		i = 0
		do
			theWave = GetStrFromList(theList, i, ";")
			if (strlen(theWave) <= 0)
				break
			endif
			i += 1
			
			theInfo = TraceInfo("",theWave,0)
			JEG_ZoomIfWithin(theInfo,whichAxis,expand)
		while (1)
	endif
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_ZoomIfWithin" --
// 
//  Check the marquee agains the axes specified in theInfo.
//  If the axis specified by whichAxis and the marqee overlap, either
//  expand or contract that axis, according to the flag expand
// 
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_ZoomIfWithin(theInfo,whichAxis,expand)
	String theInfo
	Variable whichAxis,expand

	String Xaxis = JEG_StrByKey("XAXIS",theInfo,":",";")
	String Yaxis = JEG_StrByKey("YAXIS",theInfo,":",";")
		
	GetAxis/Q $Xaxis
	Variable Xmin = V_min
	Variable Xmax = V_max
	
	GetAxis/Q $Yaxis
	Variable Ymin = V_min
	Variable Ymax = V_max
	
	GetMarquee/K $Xaxis, $Yaxis
	
	// Check each corner of the marquee against each axis of the image
	
	Variable leftIn, rightIn, topIn, bottomIn, horizontalWrap, verticalWrap

	leftIn		= JEG_IsWithin(V_left, Xmin, Xmax)
	rightIn 	= JEG_IsWithin(V_right, Xmin, Xmax)
	topIn			= JEG_IsWithin(V_top, Ymin, Ymax)
	bottomIn	= JEG_IsWithin(V_bottom, Ymin, Ymax)

	// Check if marquee brackets the axis
	
	if (sign(V_left - Xmin) != sign(V_right - Xmax))
		horizontalWrap = !leftIn %& !rightIn
	else
		horizontalWrap = 0
	endif
	
	if (sign(V_bottom - Xmin) != sign(V_top - Xmax))
		verticalWrap = !bottomIn %& !topIn
	else
		verticalWrap = 0
	endif
	
	// If _any_ corner of the marquee is within the image, then scale that image's axes.
	// Also, if the marquee wraps the image...
	
	Variable scale
	if ((leftIn %| rightIn %| horizontalWrap) %& (topIn %| bottomIn %| verticalWrap))
		if (whichAxis %& 1)		// scale horizontal
			if (expand)
				SetAxis $Xaxis, V_left, V_right
			else
				scale = (Xmax - Xmin)/(V_right - V_left)
				SetAxis $Xaxis, (Xmin - V_left)*scale + Xmin, (Xmax - V_right)*scale + Xmax
			endif
		endif
		if (whichAxis %& 2)		// scale vertical
			if (expand)
				SetAxis $Yaxis, V_bottom, V_top
			else
				scale = (Ymax - Ymin)/(V_top - V_bottom)
				SetAxis $Yaxis, (Ymin - V_bottom)*scale + Ymin, (Ymax - V_top)*scale + Ymax
			endif
		endif
	endif
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_IsWithin" --
// 
//  Return TRUE if value lies between lowBound and highBound.
//  lowBound can be of greater magnitude than highBound
// 
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_IsWithin(value,lowBound,highBound)
	Variable value, lowBound, highBound

	Variable isWithin
	
	// If the signs are different, the point is decidedly between the limits
	// but if the signs are equal, it's possible for one to be positive and the other zero, 
	// which would still be "inside".
	if (sign(value - lowBound) != sign(value - highBound))
		isWithin = 1
	else
		if (((value == lowBound) %& (value > highBound)) %| ((value > lowBound) %& (value == highBound)))
			isWithin = 1
		else
			isWithin = 0
		endif
	endif
	return isWithin
End