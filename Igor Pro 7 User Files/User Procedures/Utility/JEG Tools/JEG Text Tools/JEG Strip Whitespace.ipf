//-*-Igor-*-
// ###################################################################
// Igor Pro - JEG Image Tools
//
//	FILE: "JEG Strip Whitespace"
//									  created: 9/25/96 {4:02:51 PM} 
//								  last update: 10/30/98 {11:31:41 PM} 
//	Author:	Jonathan Guyer
//  E-mail: <jguyer@his.com>
//     WWW: <http://www.his.com/~jguyer/>
//	
//	Description: 
//		Eliminates leading and trailing whitespace (defined by user; pass " \t" 
//		for spaces and tabs) and replaces runs of whitespace with a single space 
//		character.
// 
//	History
// 
//	modified by	 rev reason
//	-------- --- --- -----------
//	09/25/96 JEG 1.0 original
//  10/30/98 JEG 1.1 made proc name for consistent with others
// ###################################################################

#pragma rtGlobals=1		// Use modern global access method.


//
// -------------------------------------------------------------------------
//	 
// "JEG_StripWhitespace"	--
//	
//	Convert	runs whitespace	into a single space
//	Leading	and	trailing whitespace	are	removed	altogether
//	
//	Example:   JEGStripWhitespace("	 \t	This  is my\tstring	 ",	" \t")
//			   returns:	"This is my	string"
//	
//	Pass " \t\r\n" to remove carriage returns and linefeeds, too
// -------------------------------------------------------------------------
//
Function/S JEG_StripWhitespace(s, whiteSpace)
	String s
	String whiteSpace
	
	Variable	i = 0
	Variable	j
	Variable	sLen = strlen(s)
	String		outString = ""
	
	do
		if ( strsearch(whiteSpace,s[i],0) < 0 )		// not whitespace
			outString += s[i]
			i += 1
		else
			j = i
			do
				j+=1
			while ( (j < sLen) %& (strsearch(whiteSpace,s[j],0) >= 0) )
			if (( i != 0 ) %& ( j != sLen ))	
				outString += " "	// replace run of whitespace with single space
			endif					// strip leading and trailing whitespace	
			i = j
		endif
	while ( i < sLen )
	
	return outString
end