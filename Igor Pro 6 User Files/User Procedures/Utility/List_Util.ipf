//File: List_util		Created: ??
// Jonathan Denlinger, JDDenlinger@lbl.gov

// 8/18/05  jdd added KeyValDef() and KeyStrDef()
// 4/7/02    jdd   added "NumFromList" with parameter order as StringFromList
// 3/1/01    jdd   added "!*" option to ReduceList()
// 10/00       jdd   added  "ReplaceItemInList"
// 12/99       jdd   added "ReduceList"
// 5/15/99	jdd   "ListLen" superceded by builtin "ItemsInList"
//                           "IndexOfWave" can be retired usingin built-in "FindListItem"
//				   tweak Textw2List

#pragma rtGlobals=1		// Use modern global access method.

Menu "Macros"
	"-"
	SubMenu "List Functions"
	help={"A 'list' is Text string delimited by a 'sep'arator character"}
		"StrFromList{ list, i, sep }"		//, print StrFromList( list, i, sep )
			help={"USE StringFromList; return i-th string from list"}
		"ValFromList{  list, i, sep }"	//, print ValFromList(  list, i, sep )
			help={"return i-th value from list"}
		"NumFromList{ i, list, sep}"
			help={"return i-th value from list"}
		"Textw2List{ txtwav, sep, i1, i2 }"	//, print Textw2List( txtwav, sep, i1, i2 )
			help={"return list from text_wave [i1,i2]"}
		"Wave2List{ wav, sep, i1, i2 }"		//, print Wave2List( wav, sep, i1, i2 )
			help={"return list from value_wave[i1,i2]"}
		"List2TextW{ list, separator, outw }"	//, List2TextW( list, separator, outw )
			help={"create text_wave from list"}
		"List2Wave{ list, separator, outw }"		//, List2Wave( list, separator, outw )
			help={"create value_wave from list"}
//		"ListLen{ list, sep }"					//, print ListLen( list )
//			help={"return length of list"}
		"IndexOfWave{ wv, matchstr }"			//, print IndexOfWave( wv, str )
			help={"return index of text_wave that equals 'matchstr'"}
		"ReduceList{ list, matchstr }"
			help={"return sublist containing substring (*=wildcard)"}
		"ReplaceItemInList{n, itemstr, list,  separator}"
			help={"return newlist with  replaced item string"}
		"fct  KeySet{ key, str}"
		"fct  KeyVal{ key, str}"
		"fct\T  KeyStr{ key, str}"
		"fct  DisplayList{ wlist, opt=[\A\WIN=winnam]}"
			help={"Plot list of waves or images"}
	End
End

Function/T FolderSep()
//===============
// returns system dependent folder delimiter
// actually, Igor for Win internally uses ":" also instead of "/"
	variable sys=(cmpstr(IgorInfo(2),"Macintosh")==0)		// 1=Mac, 0=Win
	//return "/:"[sys,sys]
	return ":"
End

Function/S StrFromList(list, n, separator)
//==================================
// same as GetStrFromList in <Strings as Lists>
// same as new built-in function:  StringFromList( n, list [, sep] )
// list is a sequence of separated strings optionally with a separator at the end
// n index starts from zero 
	String list, separator
	Variable n
	return StringFromList( n, list, separator )
End

Function/S StrFromList_(list, n, separator)
//================================== old version
// same as GetStrFromList in <Strings as Lists>
// list is a sequence of separated strings optionally with a separator at the end
// n index starts from zero 
	String list, separator
	Variable n
	
	Variable offset1, offset2, len
	offset1 = 0
	do
		offset2 = StrSearch(list, separator , offset1)
		if (offset2 == -1)
			offset2= strlen(list)	// so that trailing separator is not needed
		endif
		if (n == 0)
			return list[offset1, offset2-1]
		endif
		n -= 1
		offset1 = offset2+1
	while (n >= 0)
	return ""
End

Function ValFromList(list, n, separator)
//==============================
// conversion of StrFromList to a number
	String list, separator
	Variable n					// return nth item in list
	//return str2num( StrFromList( list, n, separator )  )
	return str2num( StringFromList( n, list, separator )  )
End

Function NumFromList(n, list, separator)
//==============================
// conversion of StrFromList to a number
	String list, separator
	Variable n					// return nth item in list
	//return str2num( StrFromList( list, n, separator )  )
	return str2num( StringFromList( n, list, separator )  )
End

Function/S Textw2List( txtwav, sep, i1, i2 )
//================================
// Convert string array to a separated string list
// from starting to ending indices
	wave/T txtwav
	string sep
	variable i1, i2
	
	variable np=numpnts(txtwav), i=0
	string strout=""
	i2=min(i2, np-1)
	if (i2>=i1)
		DO
			if (i>0)
				strout+=sep
			endif
			strout+=txtwav(i+i1)
			i+=1
		WHILE ((i+i1)<=i2)
	endif
	return strout
End

Function/S Wave2List( wav, sep, i1, i2 )
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

Function List2TextW( list, separator, outw )
//================================
// convert string list to string array (text wave)
// fastest version using new built-in function StringFromList()
	string list, separator, outw
	variable NL=ItemsInList( list, separator )
	make/O/T/n=(NL) $outw
	wave/T ow=$outw
	variable i=0, indx
	string istr, list2=list
	//variable itimer=StartMSTimer
	do
		ow[i]=StringFromList( i, list, separator )   //fastest
		//ow[i]=StrFromList_( list, i, separator )   //slowest
		i+=1
	while (i<NL)
	//print StopMSTimer(itimer)/1E3, " msec"
	return i
End

Function List2TextW_( list, separator, outw )
//================================  old version
// convert string list to string array (text wave)
// much faster than using old StrFromList()
// slightly slower than using new built-in StringFromList()
	string list, separator, outw
	variable NL=ItemsInList( list, separator )
	make/O/T/n=(NL) $outw
	wave/T ow=$outw
	variable i=0, indx
	string istr, list2=list
		variable itimer=StartMSTimer
	do
		//istr=StrFromList( list, i, separator )   //slowest
		indx=strsearch(list2, separator, 0)
		if (indx == -1)
			indx= strlen(list)	// so that trailing separator is not needed
		endif
		istr=list2[0,indx-1]
		if (strlen(istr)==0) 
			break
		endif
		ow[i]=istr
		
		list2=list2[indx+1, strlen(list2)]	
		i+=1
	while (i<NL)
	//redimension/N=(i) ow
	print StopMSTimer(itimer)/1E3, " msec"
	return i
End

Function List2Wave( list, separator, outw )
//================================
// convert string list to string array (text wave)
	string list, separator, outw
	List2TextW( list, separator, "txtw" )
	wave/T tw=$"txtw"
	variable np=numpnts(tw)
	make/o/n=(np) $outw
	wave ow=$outw
	ow=str2num( tw[p] )
	return np
End

//Function ListLen( list, separator )
////================================
//// return number of items in string list  (same as built-in "ItemsInList")
//	string list, separator
//	if (strlen(list)==0)
//		return 0
//	endif
//	variable i=0, pos=-1
//	do
//		pos=StrSearch( list,  separator, pos+1 )
//		if (pos == -1)
//			break
//		endif
//		i+=1
//	while (i<500)
//	// add 1 if last character is NOT a separator
//	return  i + ( cmpstr( list[ strlen(list)-1], separator)!=0)
//End

Function IndexOfWave( wv, str )
//================================
// return index of text wave matching given string 
// (same as built-in "FindListItem" for a string list)
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

Function/T ReduceList( liststr, matchstr )
//=============================
// creates subset of full list matching selected string
// must use wildcards (*) - using stringmatch function
// Alternately use (!*xyz) to return list items that do NOT match the rest of matchStr.
// no wildcards if using strsearch function
//
	string liststr, matchstr
	string outlist="", sep=";", str
	
	variable notmatch=0
	if (stringmatch(matchstr[0],"!*"))
		notmatch=1
		print matchstr
		matchstr=matchstr[1,inf]
		print matchstr
	endif
	//print nitems
	variable nitems=ItemsInList(liststr), ii=0, keep
	DO
		str=StringFromList( ii, liststr)
		// can also insert LowerStr( str ) and/or LowerStr(matchstr) for better matching
		//outlist+=SelectString( strsearch( str, matchstr, 0) >0 , "", str+";")
		keep=abs(notmatch - stringmatch( str, matchstr))	// 0=(0-0) or (1-1)
		outlist+=SelectString( keep,"", str+";")
		ii+=1
	WHILE(ii<nitems)
	//print ItemsInList(outlist)
	return  outlist
end

Function/T ReplaceItemInList(n, itemstr, list,  separator)
//==============================
// replace n-th item in list & return modified list
	Variable n
	String itemstr, list, separator
	string newlist
	
	separator=SelectString( strlen(separator),";", separator)
	//slow method conversion to textwave

	Variable offset1, offset2, len=strlen(list)
	offset1 = 0
	do
		offset2 = StrSearch(list, separator , offset1)
		if (offset2 == -1)
			offset2= len 	// so that trailing separator is not needed
		endif
		if (n == 0)
			break
		endif
		n -= 1
		offset1 = offset2+1
	while (n >= 0)
	newlist=list[0,offset1-1]+itemstr+list[offset2, len-1]
	return newlist
End


Function KeySet( key, str )
//===================
	string key, str
	key=LowerStr(key); str=LowerStr(str)
	variable set=stringmatch( str, "*/"+key+"*" )
	// keyword NOT set if "/K=0" used
	set=SelectNumber( KeyVal( key, str)==0, set, 0)
	return set
end

Function KeyVal( key, str )
//===================
	string key, str
	return NumberByKey( key, str, "=", "/")
end

Function/T KeyStr( key, str )
//===================
	string key, str
	return StringByKey( key, str, "=", "/")
end

Function KeyValDef( key, str, def_val )
//===================
	string key, str
	variable def_val
	variable key_val=NumberByKey( key, str, "=", "/")
	return SelectNumber( numtype(key_val)==2, key_val, def_val)
end

Function/T KeyStrDef( key, str, def_str )
//===================
	string key, str, def_str
	string key_str=StringByKey( key, str, "=", "/")
	return SelectString( strlen(key_str)==0, key_str, def_str)
end

Function DisplayList( wlist, opt)
//================
// Plot a list of waves or images
// Options: /A - append only
//              /WIN=window_name
	string wlist, opt
	
	variable nw=ItemsInList( wlist )
	string winnam=KeyStr("WIN", opt)
	if (strlen(winnam)>0)
		DoWindow/F $winnam
		if (V_flag==0)			// window exists
			Display
			DoWindow/C $winnam
		endif
	else
		if (KeySet("A", opt ))		//Append
			winnam=WinName(0,1)
			DoWindow/F $winnam
		else
			Display
		endif	
	endif

	
	string wvn=StringFromList(0, wlist )
	variable ndim=WaveDims( $wvn )
	variable ii=0
	DO
		wvn=StringFromList(ii, wlist )
		if (ndim==2)
			AppendImage $wvn
		else
			AppendToGraph $wvn
		endif
		ii+=1
	WHILE( ii<nw)
	return nw
end