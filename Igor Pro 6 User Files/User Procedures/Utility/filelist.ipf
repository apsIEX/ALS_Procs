// File:  FileList    12/2/97 J. Denlinger

#pragma rtGlobals=1		// Use modern global access method.

//Fct/T 	FLParm( )			� parameter recall 
//Proc 	MakeFileList( )		� create text file wave list from selected file folder
//Fct 	GetFileNames( )
//Proc 	PlotList()			� load & plot simple 2-column files
//Proc 	ImageList()			� build matrix from 2-column files & image plot 

menu "Plot"
	"-"
	"MakeFileList/5"
	"PlotList/6"
	"ImageList/7"
end

Proc MakeFileList(  pathstr, matchStr1, matchStr2, filtyp, listw)
//---------------
	string pathstr=StrVarOrDefault("root:tmp:path_str","")
	string matchStr1=StrVarOrDefault("root:tmp:match_str1","")
	string matchStr2=StrVarOrDefault("root:tmp:match_str2","")
	string filtyp=StrVarOrDefault("root:tmp:fil_typ","TEXT")
	string listw=StrVarOrDefault("root:tmp:listwn","")
	prompt pathstr, "Folder Path (blank=dialog)"
	prompt matchStr1, "filename match string #1:"
	prompt matchStr2, "filename match string #2"
	prompt listw, "Name of text wave list, (*_lst)"
	prompt filtyp, "File Type"

	if (stringmatch(listw,"*_lst")==0)
		listw+="_lst"
	endif
		
	if (strlen(pathStr)==0)
		NewPath/O/Q/M="Select Data Folder" dpath
		PathInfo dpath			//S_path contains path string
		pathstr=S_path
	endif
	
	NewDataFolder/O/S root:tmp
		string/G path_str=pathstr, match_str1=matchstr1, match_str2=matchstr2
		string/G fil_typ=filtyp, listwn=listw
	SetDataFolder root:
	
	IF (strlen(pathStr)>0)
		variable nfiles
		variable/D sttim=datetime

		nfiles=GetFilenames( pathStr, matchStr1, matchStr2, "TEXT",  listw )
		print "Number of files=", nfiles, ", elapsed time=", datetime-sttim, " secs"
	
		string wnam=listw+"_"
		DoWindow/F $wnam
		make/o/N=(max(1,nfiles)) Sortw	//=nan
		//Sortw=nan
		if (V_flag==0)
			edit $listw, Sortw
			ModifyTable alignment($listw)=0
			DoWindow/C $wnam
		endif
	ENDIF
End

Function GetFileNames( path, str1, str2, filtyp, listw )
//================
// written using guts of StrFromList() fct, but doesnot require "List_util"
// uses Igor IndexedFile to generate full file list in folder
	string path, str1, str2, filtyp, listw
	
	NewPath/O/Q tmppath path
	string  separator=";", FLDRLIST, fnam
	FLDRLIST=IndexedFile(tmppath,-1,filtyp)
	
	make/O/T/N=200 $listw
	WAVE/T FLIST=$listw
	variable ii=0, indx=0, nf		//, totnf=ListLen(FLDRLIST,",")
	variable len=StrLen( FLDRLIST), offset1=0, offset2
	do
		offset2 = StrSearch( FLDRLIST, separator , offset1)
		fnam=FLDRLIST[ offset1, offset2-1]
		offset1=offset2+1
		if (strlen(fnam)==0)
			break
		endif
		if ((strsearch(fnam, str1,0)>=0)*(strsearch(fnam, str2,0)>=0))
			FLIST[indx]=fnam
			indx+=1
		endif
		ii+=1
	while (ii<999)
	nf=indx
	redimension/n=(nf) FLIST
	print "total number of files in folder=", ii
	return nf
End

Function/T GetFileList( path, str1, str2, filtyp )
//================
// written using guts of StrFromList() fct, but doesnot require "List_util"
// uses Igor IndexedFile to generate full file list in folder
	string path, str1, str2, filtyp
	
	NewPath/O/Q tmppath path
	string  separator=";", FLDRLIST, fnam
	FLDRLIST=IndexedFile(tmppath,-1,filtyp)
	
	string FLIST=""
	variable ii=0, indx=0, nf		//, totnf=ListLen(FLDRLIST,",")
	variable len=StrLen( FLDRLIST), offset1=0, offset2
	do
		offset2 = StrSearch( FLDRLIST, separator , offset1)
		fnam=FLDRLIST[ offset1, offset2-1]
		offset1=offset2+4
		if (strlen(fnam)==0)
			break
		endif
		if ((strsearch(fnam, str1,0)>=0)*(strsearch(fnam, str2,0)>=0))
			FLIST+=fnam+";"
			indx+=1
		endif
		ii+=1
	while (ii<999)
	nf=indx
	print "total number of files in folder=", ii
	return FLIST
End

Proc PlotList(pathstr, listw, disp,  ilog, xscale, fnam)
//------------------------
	string pathstr=StrVarOrDefault("root:tmp:path_str","")
	string listw=StrVarOrDefault("root:tmp:listwn","")
	variable  disp, ilog=1, xscale=2, fnam=2
	prompt pathstr, "Folder Path (blank=dialog)"
	prompt listw, "File List wave", popup, WaveList("*lst",";","")
	prompt disp, "Display mode", popup, "New Graph;Append to top"
	prompt ilog, "Intensity conversion", popup, "Regular;Log"
	prompt xscale, "Scale Y waves with X wave?", popup, "No;Yes"
	prompt fnam, "Wave Name", popup, "full file;strip extension;. to_"
	
	PauseUpdate; Silent 1
	string xlbl="Binding Energy (eV)", ylbl="Intensity (arb)"
	if (strlen(pathStr)==0)
		NewPath/O/Q/M="Select Data Folder containing file list" dpath
		PathInfo dpath			//S_path contains path string
		pathstr=S_path
	endif
	NewPath/O/Q tmppath pathstr
	
	NewDataFolder/O/S root:tmp
		string/G path_str=pathstr, listwn=listw
	SetDataFolder root:
	
	if (disp==1)
		display
	endif
	variable ii=0, nf=numpnts($listw), ipd
	string fn, wn, xwn
	DO
		fn=$listw[ii]
		if (mod(ii,20)==0)
			print "Loading ", ii, " of ", nf, ": ", fn
		endif
		LoadWave/G	/N/Q/P=tmppath fn
		wn=S_filename
		ipd=strsearch(S_filename,".",0)
		if (fnam==2)
			wn=S_Filename[0,ipd-1]
		endif
		if (fnam==3)
			wn[ipd,ipd]="_"
		endif
		if (ilog==2)
			wn+="_log"
		endif
		xwn=wn+"_x"
		duplicate/o wave0 $xwn
		duplicate/o wave1 $wn
		if (xscale==2)
			WaveStats/Q $xwn
			SetScale/I x V_min,V_max, ""  $wn
			killwaves $xwn
		//endif
		if (ilog==2)
			$wn=log($wn)
		endif

		//if (xscale==2)
			append $wn
		else
			append $wn vs $xwn
		endif

		ii+=1
	WHILE (ii<nf)
	if (disp==1)
		XPS_lst_Style(xlbl,ylbl)
		Legend/F=0
	endif

end

Proc ImageList(pathstr, listw, disp, ylbl,  xscale, ilog)
//------------------------
	string pathstr=StrVarOrDefault("root:tmp:path_str","")
	string listw=StrVarOrDefault("root:tmp:listwn","")
	string  ylbl="Ef"
	variable  disp, xscale=2 , ilog=1
	prompt pathstr, "Folder Path (blank=dialog)"
	prompt listw, "File List wave", popup, WaveList("*lst",";","")
	prompt disp, "Display mode", popup, "New image"
	prompt xscale, "Scale Y waves with X wave?", popup, "No;Yes"
	prompt ilog, "Intensity scale", popup, "Regular;Log"
	
	PauseUpdate; Silent 1
	string xlbl="Binding Energy (eV)"	//, ylbl=""
	if (strlen(pathStr)==0)
		NewPath/O/Q/M="Select Data Folder containing file list" dpath
		PathInfo dpath			//S_path contains path string
		pathstr=S_path
	endif
	NewPath/O/Q tmppath pathstr
	
	NewDataFolder/O/S root:tmp
		string/G path_str=pathstr, listwn=listw
	SetDataFolder root:
	
	if (disp==1)
		display
	endif

	//Name of output 2D array (replace 'lst' with 'im')
	variable nc=strlen(listw)
	string ow=listw[0,nc-4]+"im"
	
	variable ii=0, nf=numpnts($listw), nx	
	string wn, xwn
	DO
		LoadWave/G	/N/Q/P=tmppath $listw[ii]
		//wn=S_filename
		//duplicate/o wave1 $wn

		// create output wave using xscale/npt of first file		
		if (ii==0)
			//xwn=wn+"_x"
			//duplicate/o wave0 $xwn		
			nx=numpnts(wave1)
			make/o/n=(nx, nf) $ow
			if (xscale==2)
				WaveStats/Q wave0
				SetScale/I x V_min,V_max, ""  $ow
			endif
			//killwaves $xwn
		endif
		
		$ow[][ii]=wave1[p]
		ii+=1
	WHILE (ii<nf)
	
	if (ilog==2)
		string ow1=ow
		ow=ow1+"_log"
		Duplicate/o $ow1 $ow
		$ow=log($ow1)
	endif
	
	if (disp==1)
		appendimage $ow
		XPS_StyleGS(xlbl,ylbl)
		ModifyImage $ow ctab= {*,*,YellowHot,1}
	endif

end

Proc XPS_lst_Style(xlabel, ylabel) : GraphStyle
//------------------------
	string xlabel="Binding Energy (eV)", ylabel="Intensity (kHz)"
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z rgb[1]=(0,0,65535),rgb[2]=(3,52428,1),rgb[3]=(0,0,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=7,lblMargin(bottom)=4
	ModifyGraph/Z lblLatPos(bottom)=-1
	Label/Z left ylabel
	Label/Z bottom xlabel
EndMacro

Proc Img_Style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z lStyle=2
	ModifyGraph/Z rgb=(0,0,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror(left)=1,mirror(bottom)=0
	ModifyGraph/Z minor(left)=1,minor(bottom)=1
	ModifyGraph/Z sep(left)=8,sep(bottom)=8
	ModifyGraph/Z fSize(left)=12,fSize(bottom)=12
	ModifyGraph/Z lblMargin(left)=7,lblMargin(bottom)=4
	ModifyGraph/Z lblLatPos(bottom)=-1
	Label/Z bottom "Binding Energy (eV)"
EndMacro






