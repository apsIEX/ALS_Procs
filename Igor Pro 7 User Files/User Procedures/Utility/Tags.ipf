// File: Tags.ipf		Created: circa 1996
// Jonathan Denlinger, JDDenlinger@lbl.gov 

// 8/13/05 jdd - added additional wave text options in Legend_(); fix comma behavior
// 2/19/03 jdd - added STATIC function x2point() from wav_util.ipf
// 7/20/02 jdd added "at Cursor A Pos" option to tag placement
//  6/8/02  jdd  added multiple keys to legend procedure
//  12/26/01 jdd added customized legend procedure
//   2/19/00 jdd  Split off TagPrefs proc; other restructuring
//				   TagWaveAt merely calls TagWaves which has full functionality
//  12/99      jdd  Added Tag At Value option

#pragma rtGlobals=1		// Use modern global access method.
#include "List_util"		// ValFromList
#include "wav_util"		// x2point

//Proc 	TagPrefs(where, anchor, prefx,  postfx, fmt, arrow )
//Proc 	TagWaves(TagStr, which, TagAtStr,changeprefs)
//Proc 	TagWaveAt(TagStr, which, TagAtStr,changeprefs)
//Proc 	RemoveTags(prefx, which)
//Fct/T 	num2fstr( num, fmt )

menu "Plot"
	"-"
	"Tag Waves"
	"Tag Wave At"
	"Remove Tags"
	"Tag Prefs"
	"Legend", Legend_()
end


Proc TagPrefs(where, anchor, prefx,  postfx, fmt, arrow )
//---------------
	string prefx=	StrVarOrDefault("root:tag:prefix","" )
	string postfx=	StrVarOrDefault("root:tag:postfix","" )
	string fmt=		StrVarOrDefault("root:tag:format","%g")
	variable where=NumVarOrDefault("root:tag:wheretag",2)
	variable anchor=NumVarOrDefault("root:tag:anchortag",4)
	variable arrow=NumVarOrDefault("root:tag:arrowlen",5)
	prompt prefx, "Prefix string"
	prompt postfx, "Post-fix string"
	prompt where, "Tag placement", popup, "Start of Wave;End of Wave;Wave Max;Cursor A Pos"
	prompt anchor, "Tag anchor", popup, "Right Center;Middle Center;Left Center;Middle Bottom"
	prompt fmt, "Value format, e.g. '\Z09%5.3g'"
	prompt arrow, "arrow length (<0=down)"
	
	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:tag
		string/G prefix=prefx, postfix=postfx,  format=fmt
		variable/G wheretag=where, anchortag=anchor, arrowlen=arrow
	SetDataFolder curr
End

Proc TagWaves(TagStr, which, TagAtStr,changeprefs)
//---------------
// Tag all waves in top window using:
// (a) given start, increment values, or
// (b) name of Number ot Text list array
	string tagStr=	StrVarOrDefault("root:tag:tag_str","0,1")
	string which=	StrVarOrDefault("root:tag:whichwv","1,0")
	string tagAtStr=	StrVarOrDefault("root:tag:tagAt_str","")
	variable changeprefs=1
	prompt tagStr, "Label: List Wave 'NAME' or Note 'KEYWORD=' or 'Start, Incr'"
	prompt which, "Which Waves to label: Start, Incr [blank=all]"
	prompt tagAtStr, "Where: []=default or # List Wave 'NAME' or Note 'KEYWORD=' or'Start, Incr'"
	prompt changeprefs, "Change Preferences", popup, "No;Yes"
	
	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:tag
		string/G  tag_str=tagStr, whichwv=which, tagAt_Str=tagAtStr
	SetDataFolder curr
	
	if ((changeprefs==2)+(exists("root:tag:prefix")==0))
		TagPrefs()
	endif

	PauseUpdate; Silent 1
	string wvlst=TraceNameList("",";",1)
	variable ny=ItemsInList(wvlst, ";")
	
	// Decipher Tag label type:  ListWave"Name" or "KeyWord=" or "Start, Inc" or "Inc"
	string tagwn, noteKeywd
	variable tagtyp
	variable start=0, inc=1
	start=ValFromList( tagStr, 0,",")
	 if (numtype(start)==0)		//found a number
	 	inc=ValFromList( tagStr, 1,",")
	 	if (numtype( inc )!=0)			// invalid second number
	 	 	inc=start
	 	 	start=0
	 	endif
	 	//create wave with specified values
	 	make/o/n=(ny) tagw=start+inc*p
		tagwn="tagw"
		tagtyp=1
	 else
	 	if (strsearch( tagStr, "=", 1)>0) 
	 		noteKeywd=StringFromList(0, tagStr, "=")
	 		tagtyp=-1	
	 	else					// interpret as List Wave Name
		 	tagwn=tagStr
		 	tagtyp=WaveType( $tagwn )		//0=text (or non-existent), >0=numeric
	 	endif
	 endif
	//print tagwn, tagtyp, noteKeywd
	
	// Decipher TagAt location string
	string tagAtwn, noteAtKeywd
	variable tagAtTyp, tagAtVal
	start=ValFromList( tagAtStr, 0,",")
	IF (strlen( tagAtStr)==0)
		tagAtTyp=0			//use Start or End preferences in root:tag:where
	ELSE
	if (numtype(start)==0)		//found a number
	 	inc=ValFromList( tagStr, 1,",")
	 	inc=SelectNumber( numtype( inc )==0,  0, inc)		// invalid second number?
	 	//create wave with specified values
	 	make/o/n=(ny) tagAtw=start+inc*p
		tagAtwn="tagAtw"
		tagAtTyp=1
	 else
	 	if (strsearch( tagAtStr, "=", 1)>0) 
	 		noteAtKeywd=StringFromList(0, tagAtStr, "=")
	 		tagAttyp=-1	
	 	else					// interpret as List Wave Name
		 	tagAtwn=tagAtStr
		 	ny=numpnts($tagAtwn)
		 	tagAttyp=WaveType( $tagAtwn )		//0=text, >0=numeric
		 	if (tagAtTyp==0)
		 		Abort "Tag At Value List Wave NOT numeric!"
		 	endif
	 	endif
	 endif
	 ENDIF
	
	 // Determine label anchor (location offset)
	 string anchor=StringFromList(root:tag:anchortag-1,"LC;MC;RC;MB;")
	  print tagAtwn, tagAttyp, noteAtKeywd, anchor
	  
	// Determine which waves to label: 'Start,Inc' or 'Inc' or Name of SINGLE wave
	variable whichTyp=0
	start=ValFromList( which, 0,",")
	if (numtype(start)==0)		//found a number
	 	inc=ValFromList( which, 1,",")
	 	if (numtype( inc )!=0)			// invalid second number
	 	 	inc=start			// use first number as increment
	 	 	start=0
	 	endif
	 else
	 	start=0; inc=1
	 	if (exists(which)==1)		//interpret  as Wave Name
	 		whichTyp=1
	 	endif
	 endif
	 //print which, start, inc, ny, whichTyp

	string wvn, labl, tagn, xwvn, modlst, noteStr
	variable ii=start, xval, pval
	DO
		wvn=SelectString( whichTyp==0, which, StringFromList( ii, wvlst, ";"))
		//wvn=PossiblyQuotename( wvn )
		
		// assemble tag label:   -1=Keyword, 0=text wave, >0=number wave
		IF (tagtyp==-1)
			//modlst=ReadMod( $wvn )
			labl=StringByKey(noteKeywd, note( $wvn), "=", ",")
			labl=root:tag:prefix+labl+root:tag:postfix
		ELSE
			if (tagtyp==0)
				if ( exists(tagwn))
					labl=SelectString( exists(tagwn), "", root:tag:prefix+$tagwn[ii]+root:tag:postfix)
				else
					labl=" "
				endif
			else
				labl=root:tag:prefix+num2fstr($tagwn[ii], root:tag:format)+root:tag:postfix
			endif
		ENDIF
		
		// Tag proper location:  -1=Keyword number, 0=Start, End, >0=Number Wave
		IF (tagAtTyp==0)
			if (root:tag:wheretag==1)
				execute "xval=leftx("+wvn+")"		//need for quoted wave names
				//xval=leftx(wvn)
			else
			if (root:tag:wheretag==2)
				execute "xval=rightx("+wvn+")"
			else
			if (root:tag:wheretag==3)		// max
				WaveStats/Q $wvn
				xval=V_maxloc
			else				//cursor A position
				xval=xcsr(A)
			endif
			endif
			endif
			tagn="t"+SelectString( whichTyp==0, wvn,"")+num2istr(ii)
			Tag/K/N=$tagn
			Tag/N=$tagn/F=0/A=$anchor/L=0/Y=0/B=1 $wvn, xval, labl
		ELSE
			if (tagtyp==-1)
				xval=NumberByKey(noteAtKeywd, note($wvn), "=", ",")		//works for text?
			else
				xval=$tagAtwn[ii]
			endif
			xwvn=XWaveName("", wvn)
			pval=SelectNumber( strlen(xwvn)==0,  x2point($wvn, xwvn, xval), xval)
			//print ii, xval, pval, xwvn
			tagn="t"+SelectString( whichTyp==0, wvn,"")+"_"+num2istr(ii)
			if (numtype(pval)==0)		// skip if not a valid number
				Tag/K/N=$tagn
				Tag/N=$tagn/F=0/A=$anchor/L=2/X=0/Y=(root:tag:arrowlen)/B=1 $wvn, pval, labl
				// /B=1 (transparent),   /Z=1 (frozen)
			endif	
		ENDIF
		//print wvn, xval

		ii+=inc
	WHILE( ii<ny )
End

Proc TagWaveAt(TagStr, which, TagAtStr,changeprefs)
//---------------
// Tag SINGLE wave at multiple X-values from specified wave
	string tagStr=	StrVarOrDefault("root:tag:tag_str","0,1")
	string which
	string tagAtStr=StrVarOrDefault("root:tag:tagAt_str2","VAL")
	variable changeprefs=1
	prompt tagStr, "Label: List Wave 'NAME' or Note 'KEYWORD=' or 'Start, Incr'"
	prompt which, "Wave to tag", popup, WaveList("!*_x", ";", "WIN:")
	prompt tagAtStr, "Number List Wave 'NAME' or Note 'KEYWORD=' or'Start, Incr'"
	prompt changeprefs, "Change Preferences", popup, "No;Yes"
	
	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:tag
		string/G  tag_str=tagStr, tagAt_str2=tagAtStr
	SetDataFolder curr
	TagWaves(TagStr, which, TagAtStr, changeprefs)
End


Proc RemoveTags(prefx, which)
//----------------
	string  which="0,1", prefx="t"
	prompt which, "Which tags to remove: start, incr (, end) start [blank=all]"
	prompt prefx, "Tag type", popup, "t;t_;"+WaveList("!*_x", ";", "WIN:")

	PauseUpdate; Silent 1
	
	// Determine which waves to remove
	variable start=0, inc=1, iend=20
	start=ValFromList( which, 0,",")
	if (numtype(start)==0)		//found a number
	 	inc=ValFromList( which, 1,",")
	 	if (numtype( inc )==0)			//found second number
	 		iend=ValFromList( which, 2,",")
	 		iend=SelectNumber( numtype(iend)==0, 100, iend)
	 	else
	 	 	inc=start			// use first number as increment
	 	 	start=0
	 	endif
	 else
	 	start=0
	 endif

	string wvlst
	if (stringmatch(prefx[0],"t"))
		wvlst=TraceNameList("",";",1)
		iend=min( iend, ItemsInList(wvlst, ";"))
	else
		prefx="t"+prefx+"_"	
	endif
	print start, inc, iend, prefx
	
	string tagn
	variable ii=start
	DO
		tagn=prefx+num2istr(ii)
		Tag/K/N=$tagn
		ii+=inc
	WHILE( ii<iend )
End

Function/T num2fstr( num, fmt )
//===============
	variable num
	string fmt
	string out
	sprintf out, fmt, num
	return out
End

// also found in wav_util.ipf
Static Function x2point( w, xw, xval )
//=====================
// generalized x2pnt to include Y vs X wave plotting
// point value is a real number that can be trunc or rounded to an integer
// ** if not x-wave then returns x2pnt() which is an integer
	wave w
	string xw
	variable xval
	
	if (strlen(xw)==0)			//scaled y-wave; same as x2pnt
		if (numtype(xval)==0)
			return x2pnt(w, xval)		// integer value
		else
			return xval				//Nan or INF
		endif
	else
		if (stringmatch(xw[0],"_"))
			xw=NameOfWave(w)+xw
		endif
		//print xw, waveexists($xw)
		if (waveexists($xw))
			NewDataFolder/O root:tmp
			make/o/n=(numpnts($xw)) root:tmp:pxw=p
			return interp(xval, $xw, root:tmp:pxw)
		else
			return NAN
		endif
	endif
End

Proc Legend_(label, opt)
//---------------
// Tag all waves in top window using:
// (a) given start, increment values, or
// (b) name of Number ot Text list array
	string label=StrVarOrDefault("root:tag:leg_str","VAL")
	//string sep=	"-"  //StrVarOrDefault("root:tag:whichwv","1,0")
	variable opt=NumVarOrDefault("root:tag:leg_wvnopt",2)
	prompt label, "Label List(s): WAVENAME;KEYWORD=;START,INCR; etc"
	//prompt sep, "Separator string (between symbol & label)"
	prompt opt, "Wave Name in label?", popup, "without;with full;_ext only;_ext[0,2] only"
	
	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:tag
		string/G  leg_str=label	
		variable/G leg_wvnopt=opt
	SetDataFolder curr
	
	PauseUpdate; Silent 1
	string wvlst=TraceNameList("",";",1)		// Top Graph
	variable ny=ItemsInList(wvlst, ";")
	
	// Decipher legend label type:  ListWave"Name" or "KeyWord=" or "Start, Inc" or "Inc"
	string lblwn, noteKeywd, labeli
	variable lbltyp
	make/o/n=5/T root:tag:lbl_key
	make/o/n=5     root:tag:lbl_typ
	variable start=0, inc=1 
	variable ii=0, numlbl=ItemsInList( label,";")
	IF (numlbl>0)
	DO
		labeli=StringFromList(ii, label, ";")
		//print ii, numlbl, labeli
		 if (numtype(ValFromList( labeli, 0,","))==0)		//found a number
		 	start=ValFromList( labeli, 0,",")
		 	inc=ValFromList( labeli, 1,",")
		 	if (numtype( inc )!=0)			// invalid second number
		 	 	inc=start
		 	 	start=0
		 	endif
		 	//create wave with specified values
		 	make/o/n=(ny) lblw=start+inc*p
			root:tag:lbl_key[ii]="lblw"
			root:tag:lbl_typ[ii]=1
		 else		//string
		 	if (strsearch( labeli, "=", 1)>0) 
		 		root:tag:lbl_key[ii]=StringFromList(0, labeli, "=")
		 		root:tag:lbl_typ[ii]=-1	
		 	else					// interpret as List Wave Name
			 	root:tag:lbl_key[ii]=labeli
			 	lbltyp=WaveType( $labeli )
			 	root:tag:lbl_typ[ii]=lbltyp		//0=text (or non-existent), >0=numeric
		 	endif
		 endif
		//print lblwn, lbltyp, noteKeywd, ny
		ii+=1
	WHILE( ii<numlbl)
	ENDIF
	
	string wvn, labl=""
	variable jj=0, underscore
	string legstr="", wvtxt=""
	DO
		wvn=StringFromList( jj, wvlst, ";")
		legstr+="\s("+wvn+") "
		if (opt>1)
			if (opt==2)
				legstr+=wvn+SelectString(numlbl>0, "",", ")
			else
				//wvtxt=StringFromList( 1, wvn, "_")
				underscore=StrSearch( wvn, "_", inf, 1)			//search from end
				//wvtxt=SelectString(opt==4, wvtxt, wvtxt[0,2])
				wvtxt=SelectString(opt==4, wvn, wvn[underscore+1,underscore+3])
				print wvn, wvtxt, wvtxt[0,2]
				legstr+=wvtxt+SelectString(numlbl>0, "",", ")
			endif
		endif
		//legstr+=SelectString(numlbl>0, "",", ")
		
		IF (numlbl>0)
		ii=0
		DO
			// assemble legend label:   -1=Keyword, 0=text wave, >0=number wave
			IF (root:tag:lbl_typ[ii]==-1)
				labl=StringByKey(root:tag:lbl_key[ii], note( $wvn), "=", ",")
				//legstr+=root:tag:prefix+labl+root:tag:postfix
			ELSE
				if (root:tag:lbl_typ[ii]==0)
					labl=SelectString( exists(root:tag:lbl_key[ii]), "", $(root:tag:lbl_key[ii])[jj] )
					//labl=SelectString( exists(lblwn), "", $lblwn[ii] )
				else 
					labl=num2fstr($(root:tag:lbl_key[ii])[jj], StrVarOrDefault("root:tag:format","%g"))
					//labl=root:tag:prefix+num2fstr($tagwn[ii], root:tag:format)+root:tag:postfix
				endif
			ENDIF
			legstr+=labl
			ii+=1
			legstr+=SelectString(ii<numlbl, "",", ")
		WHILE(ii<numlbl)
		ENDIF
		jj+=1			//inc
		legstr+=SelectString( jj<ny, "", "\r")		// new line
	WHILE( jj<ny )
	Legend/J/F=0/S=3/H=14/A=MC legstr
End
