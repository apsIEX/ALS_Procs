#pragma rtGlobals=1		// Use modern global access method.

// Mac users can delete this line if they get an error
#pragma version = 1.1

#include "JEG Strip Whitespace"

// ###################################################################
// Igor Pro - JEG Image Tools
//
//	FILE: "JEG Extract Dimensions"
//									  created: 9/25/96 {3:45:24 PM} 
//								  last update: 10/30/98 {11:33:31 PM} 
//	Author:	Jonathan Guyer
//  E-mail: <jguyer@his.com>
//     WWW: <http://www.his.com/~jguyer/>
//	
//	Description: 
//		Given a string containing a dimensioned number, sets two globals in the 
//		current data folder: V_dimensionValue is the numerical value and 
//		S_dimensionString is (dur) the dimension string.  SI prefixes are 
//		extracted from the dimension string and the value is adjusted 
//		accordingly (not all prefixes are included, but they're easy to add).
//		
//		Example: JEG_ExtractDimensions("43.234 nm")
//		Result:		V_dimensionValue = 4.3234E-08
//					S_dimensionString = "m"
// 
//	History
// 
//	modified by	 rev reason
//	-------- --- --- -----------
//	09/25/96 JEG 1.0 original
//	10/08/96 JEG 1.1 Fixed bug in parsing of "~" prefix for 10^-6
//  10/30/98 JEG 1.2 made name consistent with others
// ###################################################################

//
// -------------------------------------------------------------------------
//   
// "JEG_ExtractDimensions" --
//  
//  Processes input string s consisting of a numerical value followed by 
//  whitespace (spaces and tabs) followed by it's dimension
//  Anything after the dimension is ignored.
//         
// Results:
//  Numerical value is placed in global variable V_dimensionValue
//  Data dimension is placed in global string S_dimensionString
//  If S_dimensionString is prefixed with an SI prefix letter ("n","m","k", etc.) 
//  that prefix is extracted and V_dimensionValue is multiplied by the appropriate 
//  amount.
//  
//  Example:   JEG_ExtractDimensions("43.236 nm")
//  Result:    V_dimensionValue    = 4.3236e-8
//             S_dimensionString   = "m"
// -------------------------------------------------------------------------
//
Function JEG_ExtractDimensions(s)
	String s
	
	s = JEG_StripWhitespace(s," \t")
	Variable/G V_dimensionValue
	String/G S_dimensionString
	V_dimensionValue = str2num(s)
	Variable startOfUnit = strsearch(s," ",0) + 1
	Variable endOfUnit = strsearch(s," ",startOfUnit) - 1
	if (endOfUnit < startOfUnit)
		endOfUnit = strlen(s)
	endif
	s = s[startOfUnit,endOfUnit]
	if ((strlen(s) == 0) %| (strlen(s) == 1))
		S_dimensionString = s
	else
		// determine the dimension prefix
		startOfUnit = 1
		do			// Case Construction (III-41)
			if (cmpstr(s[0],"p")==0)	// pico
				V_dimensionValue *= 10^-12
				break
			endif
			if (cmpstr(s[0],"n")==0)	// nano
				V_dimensionValue *= 10^-9
				break
			endif
			if ((cmpstr(s[0],"�")==0) %| (cmpstr(s[0],"~")==0)) // micro
										// knuckle-dragger Nanoscope can't do �
				V_dimensionValue *= 10^-6
				break
			endif
			if (cmpstr(s[0],"m")==0)	// milli
				V_dimensionValue *= 10^-3
				break
			endif
			if (cmpstr(s[0],"c")==0)	// centi
				V_dimensionValue *= 10^-2
				break
			endif
			if (cmpstr(s[0],"k")==0)	// kilo
				V_dimensionValue *= 10^3
				break
			endif
			if (cmpstr(s[0],"M")==0)	// mega
				V_dimensionValue *= 10^6
				break
			endif
			// Others?
			// default
			startOfUnit = 0
		while (0)
		S_dimensionString = s[startOfUnit,strlen(s)]	// clip off dimension prefix
	endif
End
