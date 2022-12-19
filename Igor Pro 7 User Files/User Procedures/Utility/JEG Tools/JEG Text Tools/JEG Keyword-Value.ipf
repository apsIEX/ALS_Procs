//-*-Igor-*-
// ###################################################################
// Igor Pro - JEG Image Tools
//
//	FILE: "JEG Keyword-Value"
//									  created: 8/9/96 {1:27:33 PM} 
//								  last update: 8/11/97 {11:27:33 PM} 
//	Author:	Jonathan Guyer
//  E-mail: <jguyer@his.com>
//     WWW: <http://www.his.com/~jguyer/>
//	
//	Description: 
//		Just like WaveMetrics' Keyword-Value routines, except two additional 
//		parameters are passed: a field separator and a record separator.
//		
//		Example: 
//		Nanoscope headers consist of keyworded records.  In Nanoscope II keywords 
//		are separated from values by " = ", but Nanoscope III uses ":".  In both, 
//		records are separated by knuckle-dragger carriage-return—line-feeds.
//		
//		For NSII, the scan size in nm is obtained by 
//			JEG_NumByKey("scan_sz", theHeader, " = ", crlf)
//		
//		For NSIII, the scan size is obtained by
//			JEG_AbortingStrByKey("\Scan size", theHeaders[imageNumber], ":", crlf)
//		and the string is converted to proper dimensions with JEG_ExtractDimensions()
// 
//	History
// 
//	modified by	 rev reason
//	-------- --- --- -----------
//	09/25/96 JEG 1.0 original
//  08/02/98 JEG 1.1 corrected parameter order for "replace" routines
// ###################################################################

// Mac users can delete this line if they get an error
#pragma version = 1.1

//
// -------------------------------------------------------------------------
//	 
// "JEG_StrByKey" --
//	
//  parses "key<:>value<;>key2<:>value2<;>"	list
//  Returns	the	string value string	given the corresponding	key
//   
//  <:>	is a field separator string	and	<;>	is a record	separator string
// -------------------------------------------------------------------------
//
Function/S JEG_StrByKey(key,list,fieldSep,recordSep)
	String key,list,fieldSep,recordSep
	
	key += fieldSep
	Variable pos= strsearch(list, key, 0)
	if( pos < 0 )
		return ""
	endif
	pos += strlen(key)
	Variable pos2= strsearch(list,recordSep,pos)
	if (pos2 == -1)				// this is the last value in list ?
		pos2 = strlen(list)
	endif
	return list[pos,pos2-1]
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_NumByKey" --
//	
//  parses "key<:>value<;>key2<:>value2<;>"	list
//  Returns	the	numeric	value of the string	given the corresponding	key, or	NaN
//  
//  <:>	is a field separator string	and	<;>	is a record	separator string
// -------------------------------------------------------------------------
//
Function/D JEG_NumByKey(key,list,fieldSep,recordSep)
	String key,list,fieldSep,recordSep
	
	String s= JEG_StrByKey(key,list,fieldSep,recordSep)
	if( strlen(s) == 0 )
		return NaN
	endif
	return str2num(s)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_AbortingNumByKey" --
//	
//  calls JEG_NumByKey and aborts if result is NaN (no valid value found)
//  otherwise returns the result
// -------------------------------------------------------------------------
//
Function JEG_AbortingNumByKey(key,list,fieldSep,recordSep)
	String key,list,fieldSep,recordSep
	
	Variable num = JEG_NumByKey(key,list,fieldSep,recordSep)
	if( numtype(num) != 0 )
		Abort "No valid value found for " + key + "! Quitting."
	else
		return num
	endif
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_AbortingStrByKey" --
//	
//  calls JEG_StrByKey and aborts if result is "" (no valid value found)
//  otherwise returns the result
// -------------------------------------------------------------------------
//
Function/S JEG_AbortingStrByKey(key,list,fieldSep,recordSep)
	String key,list,fieldSep,recordSep
	
	String s = JEG_StrByKey(key,list,fieldSep,recordSep)
	if( strlen(s) == 0 )
		Abort "No valid value found for " + key + "! Quitting."
	else
		return s
	endif
End


//
// -------------------------------------------------------------------------
//	 
// "JEG_ReplaceStrByKey" --
//	
//  Replaces "<key><:><str><;>" in the list, or adds it to the start of the list
//  
//  <:> is a field separator string and <;> is a record separator string
//  
//  list is usually a global string containing lots of settings,
//  each setting with a unique key.
//  Note: we ASSUME that key and str do not contain either the <:> or <;> strings
//  (if it does, the list is damaged). Any other character, however, is okay.
//  Returns the new list.
//  
//  Usage: listStr= JEG_ReplaceStrByKey(listStr,"DayOfWeek","Monday",":",";")
// -------------------------------------------------------------------------
//
Function/S JEG_ReplaceStrByKey(list,key,str,fieldSep,recordSep)	
	String list,key,str,fieldSep,recordSep

	key += fieldSep
	Variable pos2=0,pos= strsearch(list, key, 0)
	if( pos >= 0 )
		pos += strlen(key)
		pos2= strsearch(list,recordSep,pos)
		list[pos,pos2-1]=str
	else
		list[-1]=key+str+recordSep	| Last-In-First-Out
	endif
	return list
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_ReplaceNumByKey" --
//	
//  Replaces "<key><:><value><;>" in the list, or adds it to the start of the list
//  See ReplaceStrByKey
//  Returns the new list.
// 
//  Usage: listStr= JEG_ReplaceNumByKey(listStr,"angle of attack",3.14159/16,":",";")
// -------------------------------------------------------------------------
//
Function/S JEG_ReplaceNumByKey(list,key,num,fieldSep,recordSep)
	String list,key,fieldSep,recordSep
	Variable/D num
	
	String valueAsString
	sprintf valueAsString,"%.15g",num
	return JEG_ReplaceStrByKey(list,key,valueAsString,fieldSep,recordSep)
End

//
// -------------------------------------------------------------------------
//	 
// "JEG_DeleteByKey" --
//	
//  Removes "<key><:><str><;>" from the list, if it exists.
//  See ReplaceStrByKey
//  Returns the new list.
// 
//  Usage: listStr= JEG_DeleteByKey(listStr,"key to delete",":",";")
// -------------------------------------------------------------------------
//
Function/S JEG_DeleteByKey(list,key,fieldSep,recordSep)	
	String list,key,fieldSep,recordSep

	key += fieldSep
	Variable pos2,pos= strsearch(list, key, 0)
	if( pos >= 0 )
		pos2= strsearch(list,recordSep,pos)
		if( pos2 < 0 )
			pos2 = strlen(list)
		endif
		list[pos,pos2]=""
	endif
	return list
End
