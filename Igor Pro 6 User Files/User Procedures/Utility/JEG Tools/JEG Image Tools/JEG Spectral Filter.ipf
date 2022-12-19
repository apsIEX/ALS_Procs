//-*-Igor-*-
// ###################################################################
//  Igor Pro - JEG Image Tools
// 
//  FILE: "JEG Spectral Filter"
//                                    created: 3/7/97 {10:27:35 PM} 
//                                last update: 8/11/97 {11:26:05 PM} 
//  Author: Jonathan Guyer
//  E-mail: <jguyer@his.com>
//     WWW: <http://www.his.com/~jguyer/>
//          
//  Routine for graphically performing spectral image filtering
//  Based on WaveMetrics' ImageMagPhase package
//  
//  To activate, select Graph->"Apply Spectral Filter…"
//  Options are given to work on a copy of the image and to retain an "undo"
//  matrix to allow backing up one step. Opting not to do either saves a 
//  tremendous amount of memory, but you're obviously climbing without a rope.
//  
//  Drag a marquee in the "Spectral Filter" window and then select "JEG_PassFilter"
//  or "JEG_StopFilter" from the marquee menu. The Spectral Filter's magnitude and
//  the working image will be automatically updated to reflect the change.
//  Select "JEG_UndoLastFilter" from the marquee menu (drag a new marquee, if necessary)
//  to return to the last step (assuming you opted to keep an "undo" matrix).
//  
//  "JEG Zoom Image" may prove useful in conjunction with this package
//          
//  modified by  rev reason
//  -------- --- --- -----------
//  3/7/97   JEG 1.0 original
// ###################################################################
// 

#include <Autosize Images>
#include <Strings as Lists>
#include "JEG Keyword-Value"
#include "JEG Color Legend" version >= 3.0

#pragma rtGlobals= 1

menu "Graph"
	"Apply Spectral Filter…", JEG_ApplySpectralFilter()
End

JEG_EnsureGrayScales()

// -----------Access Routines-----------------------------------------------

Proc  JEG_ApplySpectralFilter(imageName,workOnCopy,keepUndo) //,filterInPlace)
	String imageName
	Prompt imageName,"Image wave:", Popup ImageNameList("",";")
	Variable workOnCopy
	Prompt workOnCopy,"Work on copy of image:", Popup "Yes;No;"
	Variable keepUndo
	Prompt keepUndo,"Keep an \"undo\" matrix:", Popup "Yes;No;"
//	Variable filterInPlace
//	Prompt filterInPlace,"Filter in place:", Popup "No;Yes;"

	print JEG_MakeSpectralFilter(imageName,mod(workOnCopy,2),mod(keepUndo,2),0)
end

// 
// -------------------------------------------------------------------------
// 
// "JEG_MakeSpectralFilter" --
// 
//  Create a spectral filter for the image associated with imageName.
//  If workOnCopy is TRUE, the image is duplicated and the duplicate displayed
//  If keepUndo is TRUE, an undo matrix is kept of the FFT, allowing the user
//  to back up one filtering step
// 
//	If your original image is complex (will this ever be true?), 
//	zero will automatically be in the center
//	Note: in all cases the dc component (zero freq in x and y) is zeroed so it does not
//	overwhelm the rest of the data. 
//	(only in the displayed Spectral Filter magnitude image; the actual FFT keeps its dc component)
//	
// Side effects:
//  A data folder is created, containing as many as three waves the size of
//  the source image
// 
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function/S JEG_MakeSpectralFilter(imageName,workOnCopy,keepUndo,filterInPlace)
	String imageName
	Variable workOnCopy
	Variable keepUndo
	Variable filterInPlace
	
	filterInPlace = 0		// No support for in-place filtering right now
	
	// Remember input for next time
	String dfSav= GetDataFolder(1);
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S 'JEG Spectral Filter'
	
	// Get a new, unique datafolder for this filter
	String filterName = UniqueName("filter",11,0)
	NewDataFolder/S $filterName
	
	Wave originalImage = ImageNameToWaveRef("",imageName)
	String/G originalImagePath= GetWavesDataFolder(originalImage,2)
	String/G workingImage
	Variable/G storeUndo = keepUndo
	
	// FFT<->IFFT will trash the original image scaling (turning everything into seconds)
	// so we store it here for safe keeping
	Make/N=(2,2) scaleWave
	CopyScales originalImage, scaleWave
	
	if (filterInPlace)
		workingImage = originalImagePath
	else
		if (workOnCopy)
			workingImage = NameOfWave(originalImage)
			workingImage = PossiblyQuoteName(workingImage + "(F)")
			workingImage = GetWavesDataFolder(originalImage,1) + workingImage
			Duplicate/O originalImage, $workingImage
			Display; AppendImage $workingImage
			DoAutoSizeImage(0,1)
		else
			workingImage = originalImagePath
		endif
	endif
		
	Wave w = $workingImage
	
	if (filterInPlace)
		Wave rmag = workingImage
	else
		Duplicate/O w,Filter
		Wave rmag= Filter
	endif
	
	if( WaveType(w) %& 4 )			// original data doubles?
		if( (DimSize(w,0) %& 1) )	
			Redimension/C rmag		// force data to complex if num rows is odd. (requirement of fft)
		endif
	else
		if( (DimSize(w,0) %& 1) )	// force data to complex if num rows is odd. (requirement of fft)
			Redimension/S/C rmag	// S in case it was an integer
		else
			Redimension/S rmag		// S in case it was an integer
		endif
	endif
	
	FFT rmag						// rmag may or may not be real
	Wave/C cmag= rmag				// at times mag will be real and complex; pick one

	if (filterInPlace)
		// ??? figure out what to do
	else
		CheckDisplayed/A cmag
		if( V_Flag == 0 )
			Display as imageName + " Spectral Filter";
			AppendImage cmag;
			DoAutoSizeImage(0,1)
			JEG_AddColorLegend2Graph("Filter",0,1)
			AutoPositionWindow/E
		endif
	endif
	
	SetDataFolder dfSav
	
	return filterName
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_SpectralFilter" --
// 
//  Called by the marqee routines. If stopFilter is true, the marquee'd area in
//  the actual FFT wave is set to zero; if false, everything but the marquee'd 
//  area is set to zero.
//  Once zeroed, the FFT wave is copied back to the working image and IFFT is
//  performed to obtain the filtered image.
// 
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_SpectralFilter(stopFilter)
	Variable stopFilter
	
	GetMarquee	
	if (!V_flag)
		Abort "There was no marquee defined"
	endif

	if (!(FindItemInList("Filter", ImageNameList("",";"), ";", 0) >= 0))
		Abort "The marquee is not located in an image filter"
	endif

	Wave theMag = ImageNameToWaveRef("","Filter")

	String theInfo = ImageInfo("","Filter", 0)
	
	String Xaxis = JEG_StrByKey("XAXIS",theInfo,":",";")
	String Yaxis = JEG_StrByKey("YAXIS",theInfo,":",";")
	
	GetMarquee $Xaxis, $Yaxis
	
	// It's unclear whether it's supposed to, but Igor doesn't clip p and q indexes
	// to stay within the wave (actually, I think it does clip q), so we do it manually
	
	Variable leftBound		= (V_left - DimOffset(theMag, 0)) / DimDelta(theMag,0)
	leftBound				= JEG_Bracket(leftBound, 0, DimSize(theMag,0))
	Variable rightBound		= (V_right - DimOffset(theMag, 0)) / DimDelta(theMag,0)
	rightBound				= JEG_Bracket(rightBound, 0, DimSize(theMag,0))
	Variable topBound		= (V_top - DimOffset(theMag, 1)) / DimDelta(theMag,1)
	topBound				= JEG_Bracket(topBound, 0, DimSize(theMag,1))
	Variable bottomBound	= (V_bottom - DimOffset(theMag, 1)) / DimDelta(theMag,1)
	bottomBound				= JEG_Bracket(bottomBound, 0, DimSize(theMag,1))
	
	String dfSav = GetDataFolder(1)
	SetDataFolder GetWavesDataFolder(theMag,1)
	
	Wave/C Filter = Filter
	
	NVAR storeUndo = storeUndo
	
	if (storeUndo)
		Duplicate/O Filter, undoMatrix
	endif
	
	if (stopFilter)
		Filter[leftBound,rightBound][bottomBound,topBound] = 0
	else
		if (storeUndo)
			Filter = 0
			Filter[leftBound,rightBound][bottomBound,topBound] = undoMatrix[p][q]
		else
			Filter[ ,leftBound-1][] = 0
			Filter[rightBound + 1, ][] = 0
			Filter[leftBound,rightBound][ ,bottomBound-1] = 0
			Filter[leftBound,rightBound][topBound + 1, ] = 0
		endif
	endif
		
	SVAR workingImage = workingImage
	Duplicate/O/C Filter, $workingImage
	Wave/C imageWave = $workingImage
	
	IFFT imageWave
	
	// FFT<->IFFT trashes the units (turns everything into Hz & seconds)
	// so we restore them from scaleWave, where we saved them
	Wave scaleWave = scaleWave
	CopyScales scaleWave, imageWave

	SetDataFolder dfSav
End

// -----------Graph Marquee routines----------------------------------------

// 
// -------------------------------------------------------------------------
// 
// "JEG_PassFilter" --
// 
//  Filter out everything but the marquee'd region
//  
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_PassFilter() : GraphMarquee
	JEG_SpectralFilter(0)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_StopFilter" --
// 
//  Filter out the marquee'd region
//  
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_StopFilter() : GraphMarquee
	JEG_SpectralFilter(1)
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_UndoLastFilter" --
// 
//  Restore the filter's FFT wave to it's previous state and then
//  regenerate the Spectral Filter magnitude and the working image
// 
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_UndoLastFilter() : GraphMarquee
	if (!(FindItemInList("Filter", ImageNameList("",";"), ";", 0) >= 0))
		Abort "The marquee is not located in an image filter"
	endif

	Wave theMag = ImageNameToWaveRef("","Filter")

	String dfSav = GetDataFolder(1)
	SetDataFolder GetWavesDataFolder(theMag,1)
	
	NVAR storeUndo = storeUndo
	
	// We can't very well undo if there's no saved "undo" matrix
	if (!storeUndo)
		Abort "You're screwed, dude"
	endif

	Wave/C undoMatrix = undoMatrix
	
	// Restore Filter to its previous state
	Duplicate/O undoMatrix, Filter
	
	// Restore the working image to its previous state
	SVAR workingImage = workingImage
	Duplicate/O/C Filter, $workingImage
	Wave/C imageWave = $workingImage
	
	IFFT imageWave
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_Bracket" --
// 
//  Nudge value to be within lowBracket and highBracket
//  
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_Bracket(value, lowBracket, highBracket)
	Variable value, lowBracket, highBracket
	
	value = Max(value, lowBracket)
	value = Min(value, highBracket)
	
	return value
End

// 
// -------------------------------------------------------------------------
// 
// "JEG_EnsureGrayScales" --
// 
//  Ensure that JEG Color Legend has log() and sqrt() gray-scale color
//  index waves for our use
//  
// --Version--Author------------------Changes-------------------------------
//    1.0     <j-guyer@nwu.edu> original
// -------------------------------------------------------------------------
// 
Function JEG_EnsureGrayScales()
	String dfSav = GetDataFolder(1)
	
	NewDataFolder/O/S root:Packages
	NewDataFolder/O/S 'JEG Color Legend'
	NewDataFolder/O/S 'Color Index Waves'
	
	if (exists("logGrays") != 1)
		Make/W/U/N=(10000,3) logGrays	// We need a pretty big wave to get decent resolution
		SetScale/I x 10^-4, 10, logGrays
		logGrays = 65535 * (log(x) + 4) / 5
	endif
	
	if (exists("sqrtGrays") != 1)
		Make/W/U/N=(1000,3) sqrtGrays
		sqrtGrays = 65535 * sqrt(x / 1000)
	endif
	
	SetDataFolder dfSav
End

