// File: LoadSESlens		Created: 12/99
// Jonathan Denlinger, JDDenlinger@lbl.gov
// 5/10/00  jd  use separate datapathname from LoadSXF
// 1/18/01 jdd  changed 'DataFolder' button to pop menu with 
//                        folder history for rapid switching
// 2/26/01 jdd  change 'type' field to 'grating' for folder summary
// 4/24/01 jdd  added check boxes to raw data plot to toggle zero on axes
// 5/3/01  jdd   added advanced wave naming preferences 
// 12/28/01 jdd  (v1.5) added normalization preview to main panel
//                            improved filelist updating when switching folders                  

#pragma rtGlobals=1		// Use modern global access method.
#include "List_util"
#include "wav_util"

// Beamline 8 LENS Data File (*.txt) structure: 
// *.esc  Ñ energy scan   (long header, n-column: hv, chan0, chan1, ... )
// *.usc  Ñundulator scan (same format)

//Contents:
//Proc  LoadLENS(disp, hv, wf, en, cts)
//Fct/T 	ReadLENS()
//Fct/T 	ReadLENSHdr(fpath, fnam)
//Fct/T 	NormLENS()
//Fct/T 	ExtractNameLENS( filenam, option, numchar )
//Proc 	ShowLENSInfo(wvn, opt)
//Fct/T 	LENSInfoB( wv, opt )
//Macro	AddLENSTitle( Sample, filnum, Polar, Elev, Epass, WkFct, hv )
//Proc 	SummarizeLENSFolder()
//Proc 	XPS_Style(xlabel, ylabel) 		: GraphStyle
//Wndw 	FluxMonitor()					: Graph

//Proc 	ShowLoadLENSPanel()
//Wndw 	Load_LENS_Panel()								: Graph
//Proc 	SelectFolderLENS(ctrlName) 							: ButtonControl
//Proc 	SelectFileLENS(ctrlName,popNum,popStr) 			: PopupMenuControl
//Proc 	SetInputPopLENS(ctrlName,popNum,popStr) 			: PopupMenuControl
//Proc 	SetInputVarLENS(ctrlName,varNum,varStr,varName) 	: SetVariableControl
//Proc 	PlotLENS(ctrlName) 							: ButtonControl
//Fct 	CheckZero(ctrlName,checked) 					: CheckBoxControl

menu "Plot"
	"-"
	"Load LENS Panel!"+num2char(19),  ShowLoadLENSPanel()
		help={"Show GUI Panel for automated loading Mono data (.usc files)"}
	"Summarize LENS Folder",  SummarizeLENSFolder("")
		help={"Create a notebook with tabular header info from a folder of data"}
	"Load LENS file",  LoadLENS()
		help={"Load & plot single LENS data file"}
	"Append LENS spectrum/`",  LoadLENS(root:LENS:dscale, root:LENS:escale, root:LENS:hv_, root:LENS:wfct, root:LENS:angoffset1, root:LENS:angoffset2, root:LENS:nametyp, root:LENS:namenum, 2)
		help={"Load LENS data file & append spectrum to top graph"}
	"Show LENS info", ShowLENSinfo()
		help={"Show table of header info for specified data in memory"}
	"Add LENS Graph title", AddLENStitle()
		help={"Create customized title annotation for top graph"}
end

Proc LoadLENS(  plotopt, plotchn, normchn,  escal, label )
//------------------------
	string label=StrVarOrDefault("root:LENS:chanlist","io,tey,fy")
	variable plotopt
	variable plotchn=NumVarOrDefault("root:LENS:plotchan",1), normchn=NumVarOrDefault("root:LENS:normchan",1)
	variable escal=NumVarOrDefault("root:LENS:escale",1)
		prompt label, "Channel extensions"
		prompt plotopt, "Spectrum plot option", popup "Display;Append"
		prompt plotchn, "Plot channel:", popup "0;1;2;3;4;5"
		prompt normchn, "Normalization channel", popup "None;0;1;2;3;4;5"
		prompt escal, "Energy Scale interpretion", popup "vs X;scaled"

	variable dum=1
	
	silent 1; pauseupdate
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:LENS
		String/G chanlist=label
		Variable/G plotchan=plotchn, normchan=normchn, escale=escal
	SetDataFolder curr

	string xlbl="Kinetic Energy (eV)", ylbl
	ylbl=StringFromList(root:LENS:plotchan, root:LENS:chanlist, ";")

// Load  data
	string filenam=ReadLENS(1-(plotopt<0))
	if (strlen(filenam)==0)
		abort 
	endif
	//base=ExtractNameLENS( base, namtyp, namnum )   // need to put in loop for multiple regions


	string base, datachan, nrmchan
	base=WaveNameLENS( filenam )		// or root:LENS:filnam
	//wvn=root:LENS:wvnam
	
//  copy raw data
//	variable ii=0
//	DO
//		ext=StringFromList( ii, root:LENS:chanlist, ";")
//		base="root:LENS:chan"+num2str(ii)
//		Duplicate/O  $wvn $(base+ext)
//		ii+=1
//	WHILE( ii< root:LENS:nchan)
	
// create normalized plot wave
	datachan="root:LENS:chan"+num2str(root:LENS:plotchan)
	Duplicate/O  $datachan $base
	if (root:LENS:normchan>=0)
		nrmchan="root:LENS:chan"+num2str(root:LENS:normchan)
		$base/=$nrmchan
		ylbl+=" / "+StringFromList(root:LENS:normchan, root:LENS:chanlist, ";")
	endif

// optional reinterpolate to scaled array(s)
	//if (escal==1)	
		// increment varies due to rounding; reinterpolate data after scaling	 (method=2)
	//	ScaleWave( $base, "root:LENS:hv", 0, 2)		// 2 = reinterp method
	//else
		Duplicate/O  $(datachan+"_x") $(base+"_x")
	//endif	
	
	
// Display
	if (abs(plotopt)==1)
		//if (escal==1)
		//	display $base
		//else
			display $base vs $(base+"_x")
		//endif	
		LENS_Style( xlbl, ylbl)
		ShowInfo
	else
		DoWindow/F $StringFromList(0, WinList("!*LENS*", ";", "Win:1"))
		//if (escal==1)
		//	append $base
		//else
			append $base vs $(base+"_x")
		//endif
		DoWindow/F Load_LENS_Panel
	endif

	//DeleteWaveList( S_Wavenames )
end

Function/T ReadLENShdr(fpath, fnam)
//=================
// saves values in root:LENS folder variables
	string fpath, fnam
	string sline		//, hdrlst
	variable file, ii, isp
	variable debug=0			// programming flag
	string/G hdrlst
	
	NewDataFolder/O/S root:LENS
	//SetDataFolder root:LENS:
	String/G filnam=fnam, filpath=fpath
	SVAR LensMode=LensMode, Epass=Epass, chanlist=chanlist
	NVAR nchan=nchan
	//SVAR slits=slits, comment=comment, basenam=basenam
	//NVAR hv_start=hv_start, hv_end=hv_end, hv_inc=hv_inc
	//NVAR dwell=dwell, nchan=nchan
	//SVAR date_=date_, endtime=endtime, grating=grating
	//NVAR harmonic=harmonic

	Open/R file as filpath+filnam
		FStatus file
			if (debug)
				print  S_Filename, ", numbytes=", V_logEOF
			endif
		//Skip first line:  [Global]
		
		FReadLine file, sline		// Line 1:  [Global]
		FReadLine file, sline		// Line 2:  LensMode=
			LensMode=StringByKey("LensMode", sline, "=")
		FReadLine file, sline		// Line 3:  Pass Energies=
		FReadLine file, sline		// Line 4:  [Epass]
			Epass=sline[1, strlen(sline)-3]

		ii=0
		chanlist=""
		string lens, tmp
		DO
			FReadLine file, sline	// Line 5+2*ii:  XXX Kinetic Energy=
			if (strlen(sline)==0)
				break
			endif
			lens=StringFromList(0, sline, "K")
			lens=lens[0,strlen(lens)-2]
			isp=strsearch(lens," ",0)
			if (isp>0)					//remove space if found
				tmp=lens
				lens=tmp[0, isp-1]+tmp[isp+1,strlen(tmp)-1]
			endif
			//print lens, "//", sline
			chanlist+=lens+";"
			FReadLine file, sline	// Line 5+2*ii:  XXX Voltage=
			ii+=1
		WHILE( ii<10 )		// end of file
		//print ii
		nchan=ii
		
		Close file
	SetDataFolder root:
	return filnam
End

Function/T ReadLENS(idialog)
//=================
// read LENS binary file
// determines the number cycles (angle, space) and number of regions (per cycle)
// saves values in root:LENS folder variables
	variable idialog
	variable debug=0			// programming flag
	Variable file
	
	SetDataFolder root:LENS:
	String/G filnam, filpath
	NVAR nchan=nchan
	
	if (idialog)
		if (cmpstr(Igorinfo(2),"Macintosh")==0)
			Open/R file				// open file dialog for reading; select from any subfolder
		else
			Open/R/T=".txt" file				// avoid default type of .txt on  Windows
		endif
			FStatus file
			filnam=S_Filename
			filpath=S_Path
		Close file
		if (strlen(filnam)==0)
			return filnam
		endif			
		
		//variable ptr=strsearch(S_path, FolderSep(),strlen(S_path)-11)		// strip off last folder to get library folder path
		//filpath=S_path[0,ptr]
	endif
	//print filpath+":, "+filnam
	if (strlen(filnam)==0)
		return ""
	endif	
	string/G basenam=filnam
	variable ipd=strsearch(filnam,".",0)
	if (ipd>0)
		basenam=filnam[0,ipd-1]
	endif
	//print basenam
	
	// ----- Read header  -------
	//print ReadLENShdr( filpath, filnam )
	
	// ----- Read data block as a matrix  -------
	//LoadWave/Q/G/M/N=wave  filpath+filnam
	string sline
	Open/R file as filpath+filnam
		FReadLine file, sline		// Line 1:  [Global]
		FReadLine file, sline		// Line 2:  LensMode=
		FReadLine file, sline		// Line 3:  Pass Energies=
		FReadLine file, sline		// Line 4:  [Epass]

		variable ii=0, ieq
		string kelist, vlist
		DO
			FReadLine file, sline	// Line 5+2*ii:  XXX Kinetic Energy=
			//print sline
			if (strlen(sline)==0)
				break
			endif
				ieq=strsearch(sline,"=",0)
				kelist=sline[ieq+1, strlen(sline)-2]
				//kelist=StringByKey("Kinetic Energy", sline, "=","\r")
				List2Wave(kelist,";","chan"+num2str(ii)+"_x")
				//print kelist
			FReadLine file, sline	// Line 5+2*ii:  XXX Voltage=
				ieq=strsearch(sline,"=",0)
				vlist=sline[ieq+1, strlen(sline)-2]
				List2Wave(vlist,";","chan"+num2str(ii))
				//vlist=StringByKey("Voltage", sline, "=","\r")
				//print vlist
			ii+=1
		WHILE( ii<nchan )		// end of file
		//print ii
		//nchan=ii
		

	Close file
	SetDataFolder root:
	return filnam
	abort
	
	// Extract channels
	ii=0
	DO
		WAVE chan=$("chan"+num2str(ii))
		//Redimension/N=(nx) chan
		//chan=wave0[p][ii+1]
		ii+=1
	WHILE( ii<nchan )
		
	WAVE wave0=wave0		//root:LENS:
	variable nx, ny
	nx=DimSize( wave0, 0)		
	ny=DimSize( wave0, 1)
	nchan=ny-1
	
	WAVE hv=hv
	Redimension/N=(nx) hv
	hv=wave0[p][0]
		

	// duplicate root:LENS:infowav root:+"basenam"+"_info"
	// or put into waveNote string
	
	SetDataFolder root:
	//return basenam
	return filnam
End

Function/T NormLENS()
//===============
// return normalization string label
	Silent 1; PauseUpdate
	NVAR plotchan=root:LENS:plotchan, normchan=root:LENS:normchan
	SVAR chanlist=root:LENS:chanlist
	WAVE normdat=root:LENS:normdat
	WAVE normdat_x=root:LENS:normdat_x
	string  ylbl
	ylbl=StringFromList(plotchan, chanlist, ";")
	WAVE datachan=$("root:LENS:chan"+num2str(plotchan))
	WAVE datachanx=$("root:LENS:chan"+num2str(plotchan)+"_x")
	Duplicate/O  datachan normdat
	Duplicate/O  datachanx normdat_x
	//if (normchan>=0)
	//	WAVE nrmchan=$("root:LENS:chan"+num2str(normchan))
	//	normdat/= nrmchan
	//	ylbl+=" / "+StringFromList(normchan, chanlist, ";")
	//endif
	//Duplicate/O root:LENS:hv root:LENS:normdat
	//root:LENS:normdat = $datacham / SelectNumber( root:LENS:normchan>=0, 1, $nrmchan )
	return ylbl
end

Function/T ExtractNameLENS( filenam, option, numchar )
//==================
// return substring from DOS 8.3 filename acoording to option
// 1=prefix only; 2=remove . ; 3=convert . to _; 4=extension only
// 'numchar' specifies the # of prefix characters to use
	string filenam
	variable option, numchar
	string prefix="", suffix=""
	//variable nc=strlen(filenam)
	variable ipd=strsearch(filenam,".",0)

	if (ipd<0)					//no period found
		ipd=strlen(filenam)
		prefix=filenam
		option=1
	else
		prefix=filenam[0, ipd-1]
		suffix=filenam[ipd+1,strlen(filenam)-1]
	endif
	if (numchar<2)			// all
		numchar=ipd
	endif
	prefix=prefix[0, numchar-1]
	if (option==1)
		suffix=""
	endif
	if (option==3)
		prefix=prefix+"_"
	endif
	if (option==4)
		prefix=""
	endif
	return prefix+suffix
End


Proc ShowLENSinfo(wvn, opt)
//-----------------
	string wvn=root:LENS:filnam+"_info"
	variable opt
	prompt wvn, "LENS file info wave", popup, WaveList("*_info",";","")
	prompt opt, "Display option", popup, "New Table;Append to topmost Table"
	if (opt==1)
		if (exists("root:LENS:infonam")==0)
			//make/N=18/T/O root:LENS:infonam
			List2Textw("filename=,type=, hv0=, hv1=, hv_inc=, dwell=, comment=", ",",  "root:LENS:infonam")
		endif
		edit root:LENS:infonam, root:LENS:infowav
		ModifyTable alignment(root:LENS:infowav)=0
	else
		DoWindow/F $WinName(0, 2)
		append $wvn
	endif
End

Function/T LENSinfoB( wv, opt )
//====================
//returns text string with specific file information
//options:  0-return string only, 1-also print to history, 2-display table of all info
	wave wv
	variable opt
	string base=NameOfWave(wv)
	variable ptr=strsearch(base,"_",0)
	if (ptr>0)
		base=base[0,ptr-1]
	endif
	WAVE/T info=$(base+"_info")
	
	string str=base+": "
	str+="hv="+info[3]
	str+="; resol="+info[4]
	str+="; Ep="+info[6]
	str+="; dwell="+info[12]+"x"+info[11]+" s"
	
	//Energy scale
	//WAVE xw=$(base+"_x"), raw=$(base+"_raw")
	//WaveStats/Q xw
	//variable incr=abs(round((xw[1]-xw[0])*1E4)/1E4)
	str+="; rng=("+info[8]+","+info[9]+","+info[10]+")"
	WaveStats/Q wv
	//or just use info[14]
	str+="; max="+num2str(V_max/1000)+""+info[18]
	
	//Io fluctuation
	//	WAVE mesh=$(base+"_mesh")
	//	WaveStats/Q mesh
	//	variable fluc=trunc(1000*(V_max-V_min)/V_avg)/10
	//	str+="; ÆIo="+num2str(fluc)+"%"
	if (opt==2)
		DoWindow/F $(base+"_info")
		if (V_Flag==0) 
			if (exists("LENS_info")==0)
				make/o/T/N=15 LENS_info
				LENS_info={"start","final","incr","range","resolution","hv","gate (ms)","#scans","Epass","pressure","CIS/CFS BE","mesh current","start beam curr.","end beam curr.","max counts (Hz)"}
			endif
			edit LENS_info, info as base+"_info"
		endif
	else
		if (opt==1)
			print str
		endif
	endif
	return str
end

Proc AddLENSTitle( Sample, WinNam, filnum, Temp, hv, slits, Polr, Azim, Ep, WFct )
//----------------
	string Sample=StrVarOrDefault("root:LENS:Sample0","A\\B1\\MB\\B2\\M")
	string WinNam=StrVarOrDefault("root:LENS:title0","TITLE"), filnum=StrVarOrDefault("root:LENS:filnum0","000-009")
	string Polr=num2str( NumVarOrDefault("root:LENS:angoffset1",0)), Azim=StrVarOrDefault("root:LENS:Azimuth","0")
	variable Ep=root:LENS:Epass[0], Wfct=NumVarOrDefault("root:LENS:Wfct",4.35)
	string hv=num2str(NumVarOrDefault("root:LENS:hv_",30)), slits=StrVarOrDefault("root:LENS:slit","10")
	variable Temp=NumVarOrDefault("root:LENS:TempK",30)
	prompt WinNam, "Title/Window Name  (<>=no change)"
	prompt slits, "Mono Slits or Res. Power"
	
	PauseUpdate; Silent 1
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:LENS
		String/G Sample0=Sample, title0=WinNam, filnum0=filnum, Azimuth=Azim		//, hv_=hv	//, Polar=Polr, 
		Variable/G Wfct0=Wfct, TempK=Temp, angoffset1=str2num(Polr), hv_=str2num(hv)
		Epass[0]=Ep
	SetDataFolder curr
		//root:LENS:sampleSav=sample
		//root:LENS:titleSav=WinNam
		//root:LENS:filnumSav=filnum
		//root:LENS:polarSav=polr
		//root:LENS:elevSav=elev
		//root:LENS:EpassSav=Epass
		//root:LENS:WFct=Wkfct
		//root:LENS:hvSav=hv
	
	string titlestr="\\JC\\[0"+Sample+", "+WinNam+ ", ("+filnum+")"
	titlestr+="\rhv="+hv+" eV ("+ slits +"), Polar="+Polr+", Azim="+Azim+","
	titlestr+="Ep="+num2str(Ep)+", WF="+num2str(WFct)+", T="+num2str(Temp)+"K"
	Textbox/K/N=title
	Textbox/N=title/F=0/A=MT/E titlestr
	
	if (strlen(WinNam)>0)
		variable ic=StrSearch(WinNam, " ", 0)
		if (ic>0)
			WinNam[ic,ic]="_"
		endif
		DoWindow/C $WinNam
		execute "DoWindow/C "+WinNam
	endif
	
End

Proc SummarizeLENSFolder(ctrlName) : ButtonControl
//----------------
// reads scan info from each file in a specified (dialog) LENS data folder 
//    and prints the info to an Igor Notebook which than can then be used as is
//    or imported (saved/pasted) into a spreadsheet
	string ctrlName
	//PauseUpdate;
	Silent 1	
	
	string pathnam, libnam, Nbknam
	if (strlen(ctrlName)>5)
		pathnam=ctrlName
	else
		NewPath/O/Q/M="Select LENS Data Folder" LENSdata			//dialog selection
		Pathinfo LENSdata
		pathnam=S_path
	endif
	
	variable nfolder=ItemsInList(pathnam, ":")
	libnam=StrFromList(pathnam, nfolder-1, ":")
	if (nfolder>1)
		libnam=StrFromList(pathnam, nfolder-2,":")+"_"+libnam
	endif
	if (nfolder>2)
		libnam=StrFromList(pathnam, nfolder-3,":")+"_"+libnam
	endif
	Nbknam=CleanupName("LENS"+ libnam, 0)
	//print pathnam, libnam
	
	NewPath/O/Q LENSdata pathnam
	string fullfilelst=IndexedFile( LENSdata, -1, "????")
	string filelst=ReduceList( fullfilelst, "*.*sc" )
	variable numfil=ItemsInList(filelst, ";")
	print "# files=", numfil		//,  filelst
	
	NewNotebook/F=1/N=$Nbknam
	variable j=72		//pts per inch
	Notebook $Nbknam, fSize=9, margins={0,0,10.0*j }, backRGB=(65535,65534,49151)
	Notebook $Nbknam, tabs={1.0*j,2.25*j, 2.8*j, 3.25*j,3.625*j,4.*j, 4.5*j,5.0*j,5.8*j,6.75*j,7.75*j,8.5*j}
	Notebook $Nbknam,  fStyle=1, text="filename\tsample\tslits\tgrat\thv0\thv1\tinc\tdwell\tdate\ttime\tcomment"

	string fnam, infostr
	variable ii=0
	DO
		fnam=StrFromList(filelst, ii, ";")
		ReadLENSHdr( pathnam, fnam )
		//print Textw2List(root:LENS:infowav, "", 0, 18)
		infostr="\r"+Textw2List(root:LENS:infowav, "\t", 0, 10)
		NoteBook $Nbknam, fStyle=0, text=infostr 			//LENSInfoB()
		
		ii+=1
	WHILE(ii<numfil)

End

Proc LENS_Style(xlabel, ylabel) : GraphStyle
//------------------------
	string xlabel="Binding Energy (eV)", ylabel="Intensity (kHz)"
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z rgb[1]=(0,0,65535),rgb[2]=(3,52428,1),rgb[3]=(0,0,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=2
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=0
	ModifyGraph/Z lblMargin(left)=7,lblMargin(bottom)=4
	ModifyGraph/Z lblLatPos(bottom)=-1
	Label/Z left ylabel
	Label/Z bottom xlabel
EndMacro

Window FluxMonitorLENS() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LENS:
	Display /W=(594,57,942,244) FLUX0
	AppendToGraph/R FLUX0
	SetDataFolder fldrSav
	ModifyGraph rgb(FLUX0#1)=(0,0,54272)
	ModifyGraph tick(left)=2,tick(bottom)=2
	ModifyGraph mirror(bottom)=1
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph fSize(left)=12,fSize(bottom)=12
	SetAxis/A/E=1 right
EndMacro

//********  Load Panel ***************


Proc ShowLoadLENSPanel()
//-----------------

	DoWindow/F Load_LENS_Panel
	if (V_flag==0)
		// Create variables
		NewDataFolder/O/S root:LENS
			string/G filpath, filnam="", fileList, basenam
			string/G folderList="Select New Folder;Summarize Folder;-;"
			variable/G  filnum, numfiles			
			string/G LensMode="LensMode", Epass="10", chanlist, slits, comment
			variable/G nchan=3, hv_start=0, hv_end=1, hv_inc=1, dwell=1
			string/G wvnam, prefix	//, chanlist
			variable/G nametyp, namenum, normext
			variable/G plotchan=1, normchan=0, escale=0
			string/G date_, endtime, grating
			variable/G harmonic=Nan
			string/G normlabel=""
			
			make/o/n=7/T chanlistw:=StringFromList( p, chanlist, ";")
			make/o/n=10 chan0, chan1, chan2, chan3, chan4, chan5, chan6, chan7
			make/o/n=10 chan0_x=p, chan1_x=p, chan2_x=p, chan3_x=p, chan4_x=p, chan5_x=p, chan6_x=p, chan7_x=p
			make/o/n=10 normdat, normdat_x
		SetDataFolder root:
		
		Load_LENS_Panel()
		
		//Initialize variables & panel
		NewDataFolder/O/S root:LENS
		      prefix=""; nametyp=1; namenum=8
			chanlist="1,2,3,4,5,6,7"; normext=1
			escale=1; PopupMenu popup_escale mode=escale
			plotchan=1; PopupMenu popup_plot mode=plotchan+1
			normchan=0; PopupMenu popup_norm mode=normchan+2
			
			wvnam:=WaveNameLENS( filnam )
		SetDataFolder root:
			
	endif
End

Window Load_LENS_Panel() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LENS:
	Display /W=(633,58,860,492) normdat vs normdat_x as "Load_LENS_Panel"
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(64512,62423,1327)
	ModifyGraph tick=2
	ModifyGraph mirror=2
	Label left "\\{root:LENS:normlabel}"
	Label bottom "Kinetic Energy (eV)"
	Textbox/N=text0/F=0/S=3/H=14/A=MT/X=3.45/Y=3.31/E "\\{root:LENS:wvnam}"
	ControlBar 266
	PopupMenu popFolder,pos={10,0},size={97,19},proc=SelectFolderLENS,title="Data Folder"
	PopupMenu popFolder,mode=0,value= #"root:LENS:folderList"
	SetVariable setlib,pos={10,22},size={205,14},title=" ",fSize=9
	SetVariable setlib,limits={-Inf,Inf,1},value= root:LENS:filpath
	PopupMenu popup_file,pos={7,43},size={107,19},proc=SelectFileLENS,title="File"
	PopupMenu popup_file,mode=15,popvalue="7T002.txt",value= #"root:LENS:filelist"
	Button FileUpdate,pos={156,45},size={55,16},proc=UpdateFolderLENS,title="Update"
	SetVariable val_comment,pos={12,84},size={199,14},title="Voltages",fSize=9
	SetVariable val_comment,limits={-Inf,Inf,1},value= root:LENS:chanlist
	ValDisplay val_hv0,pos={14,102},size={56,14},title="hv:",fSize=9
	ValDisplay val_hv0,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:hv_start"
	ValDisplay val_dwell,pos={15,120},size={80,14},title="Dwell",fSize=9
	ValDisplay val_dwell,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:dwell"
	PopupMenu popup_escale,pos={141,220},size={67,19},proc=SetInputPopLENS
	PopupMenu popup_escale,mode=1,popvalue="Scaled",value= #"\"Scaled;vs X\""
	Button StepMinus,pos={61,247},size={20,16},proc=StepFileLENS,title="<<"
	Button StepPlus,pos={86,247},size={20,16},proc=StepFileLENS,title=">>"
	Button PlotDisplay,pos={14,222},size={55,16},proc=PlotLENS,title="Display"
	Button PlotAppend,pos={78,222},size={55,16},proc=PlotLENS,title="Append"
	ValDisplay val_hv1,pos={76,102},size={56,14},title="to",fSize=9
	ValDisplay val_hv1,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:hv_end"
	ValDisplay val_hvinc,pos={139,102},size={56,14},title="inc",fSize=9
	ValDisplay val_hvinc,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:hv_inc"
	SetVariable wvname,pos={96,178},size={105,14},title=" ",fSize=9
	SetVariable wvname,limits={-Inf,Inf,1},value= root:LENS:wvnam
	PopupMenu popup_norm,pos={130,197},size={72,19},proc=SetInputPopLENS,title="Norm"
	PopupMenu popup_norm,mode=2,popvalue="0",value= #"\"None;0;1;2;2;3;4;5\""
	PopupMenu popup_plot,pos={20,199},size={76,19},proc=SetInputPopLENS,title="Plot"
	PopupMenu popup_plot,mode=4,popvalue="LV2",value= #"root:LENS:chanlist"
	ValDisplay val_nchan,pos={143,119},size={50,14},title="# chan",fSize=9
	ValDisplay val_nchan,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:nchan"
	Button PlotRaw,pos={141,247},size={70,16},proc=PlotLENS,title="Raw Data"
	SetVariable val_sample,pos={14,67},size={110,14},title="mode",fSize=9
	SetVariable val_sample,limits={-Inf,Inf,1},value= root:LENS:LensMode
	SetVariable val_slits,pos={130,66},size={80,14},title="Epass",fSize=9
	SetVariable val_slits,limits={-Inf,Inf,1},value= root:LENS:Epass
	SetVariable val_grating,pos={14,136},size={90,14},title="grating",fSize=9
	SetVariable val_grating,limits={-Inf,Inf,1},value= root:LENS:grating
	ValDisplay val_harmonic,pos={114,136},size={90,14},title="Und. Harmonic",fSize=9
	ValDisplay val_harmonic,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_harmonic,value= #"root:LENS:harmonic"
	SetVariable val_date,pos={15,153},size={90,14},title="date",fSize=9
	SetVariable val_date,limits={-Inf,Inf,1},value= root:LENS:date_
	SetVariable val_endtime,pos={115,153},size={95,14},title="time",fSize=9
	SetVariable val_endtime,limits={-Inf,Inf,1},value= root:LENS:endtime
	Button WaveNamePrefs,pos={28,178},size={55,16},proc=NamingPrefs,title="Naming"
EndMacro

Window Load_LENS_Panel0() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(533,94,761,375)
	ModifyPanel cbRGB=(64512,62423,1327)
	SetDrawLayer UserBack
	SetDrawEnv fillpat= 3,fillfgc= (65495,2134,34028)
	DrawRRect 218,39,5,173
	SetDrawEnv fillpat= 5,fillfgc= (65495,2134,34028)
	DrawRRect 216,173,9,244
	SetDrawEnv fsize= 10
	DrawText 182,17,"v 1.4"
	SetDrawEnv fillfgc= (65495,2134,34028)
	SetDrawEnv save
	PopupMenu popFolder,pos={10,0},size={99,20},proc=SelectFolderLENS,title="Data Folder"
	PopupMenu popFolder,mode=0,value= #"root:LENS:folderList"
	SetVariable setlib,pos={10,22},size={205,15},title=" ",fSize=9
	SetVariable setlib,limits={-Inf,Inf,1},value= root:LENS:filpath
	PopupMenu popup_file,pos={7,43},size={145,20},proc=SelectFileLENS,title="File"
	PopupMenu popup_file,mode=19,popvalue="cal0911024.usc",value= #"root:LENS:fileList\t\t"
	Button FileUpdate,pos={156,45},size={55,16},proc=UpdateFolderLENS,title="Update"
	SetVariable val_comment,pos={12,84},size={199,15},title=" comment",fSize=9
	SetVariable val_comment,limits={-Inf,Inf,1},value= root:LENS:comment
	ValDisplay val_hv0,pos={14,102},size={56,14},title="hv:",fSize=9
	ValDisplay val_hv0,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:hv_start"
	ValDisplay val_dwell,pos={15,120},size={80,14},title="Dwell",fSize=9
	ValDisplay val_dwell,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:dwell"
	PopupMenu popup_escale,pos={141,220},size={69,20},proc=SetInputPopLENS
	PopupMenu popup_escale,mode=1,popvalue="Scaled",value= #"\"Scaled;vs X\""
	Button StepMinus,pos={61,247},size={20,16},proc=StepFileLENS,title="<<"
	Button StepPlus,pos={86,247},size={20,16},proc=StepFileLENS,title=">>"
	Button PlotDisplay,pos={14,222},size={55,16},proc=PlotLENS,title="Display"
	Button PlotAppend,pos={78,222},size={55,16},proc=PlotLENS,title="Append"
	ValDisplay val_hv1,pos={76,102},size={56,14},title="to",fSize=9
	ValDisplay val_hv1,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:hv_end"
	ValDisplay val_hvinc,pos={139,102},size={56,14},title="inc",fSize=9
	ValDisplay val_hvinc,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:hv_inc"
	SetVariable wvname,pos={96,178},size={105,15},title=" ",fSize=9
	SetVariable wvname,limits={-Inf,Inf,1},value= root:LENS:wvnam
	PopupMenu popup_norm,pos={101,198},size={92,20},proc=SetInputPopLENS,title="Norm"
	PopupMenu popup_norm,mode=1,popvalue="None",value= #"\"None;0;1;2;2;3;4;5\""
	PopupMenu popup_plot,pos={20,199},size={60,20},proc=SetInputPopLENS,title="Plot"
	PopupMenu popup_plot,mode=1,popvalue="0",value= #"\"0;1;2;3;4;5\""
	ValDisplay val_nchan,pos={143,119},size={50,14},title="# chan",fSize=9
	ValDisplay val_nchan,limits={0,0,0},barmisc={0,1000},value= #"root:LENS:nchan"
	Button PlotRaw,pos={156,248},size={60,16},proc=PlotLENS,title="Preview"
	SetVariable val_sample,pos={14,67},size={110,15},title="sample",fSize=9
	SetVariable val_sample,limits={-Inf,Inf,1},value= root:LENS:sample
	SetVariable val_slits,pos={130,66},size={80,15},title=" slits",fSize=9
	SetVariable val_slits,limits={-Inf,Inf,1},value= root:LENS:slits
	SetVariable val_grating,pos={14,136},size={90,15},title="grating",fSize=9
	SetVariable val_grating,limits={-Inf,Inf,1},value= root:LENS:grating
	ValDisplay val_harmonic,pos={114,136},size={90,14},title="Und. Harmonic",fSize=9
	ValDisplay val_harmonic,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_harmonic,value= #"root:LENS:harmonic"
	SetVariable val_date,pos={15,153},size={90,15},title="date",fSize=9
	SetVariable val_date,limits={-Inf,Inf,1},value= root:LENS:date_
	SetVariable val_endtime,pos={115,153},size={95,15},title="time",fSize=9
	SetVariable val_endtime,limits={-Inf,Inf,1},value= root:LENS:endtime
	Button WaveNamePrefs,pos={28,178},size={55,16},proc=NamingPrefs,title="Naming"
EndMacro


Window RawLENS_1() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LENS:
	Display /W=(348.75,50.75,639.75,265.25) chan0 vs hv
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(65280,65280,0)
	ModifyGraph grid(bottom)=1
	ModifyGraph tick=2
	ModifyGraph mirror=2
	ModifyGraph minor=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph lblPos(left)=47
	ModifyGraph lblLatPos(left)=-1
	Label left "0 : \\{root:LENS:chanlistw[0]}"
	Label bottom "Photon Energy (eV)"
	TextBox/N=title/F=0/A=MT/X=4.59/Y=2.73/E "\\JC\\{root:LENS:comment[0,44]}"
	AppendText "dwell= \\{root:LENS:dwell} sec, \\{root:LENS:filnam}"
	ControlBar 24
	CheckBox zero_left,pos={15,3},size={24,14},proc=CheckZero,title="0",value= 0
EndMacro

Window RawLENS_2() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LENS:
	Display /W=(302,67,593,357) chan0 vs hv
	AppendToGraph/L=ch1 chan1 vs hv
	SetDataFolder fldrSav
	ModifyGraph grid(bottom)=1
	ModifyGraph tick(left)=2,tick(bottom)=2
	ModifyGraph zero(ch1)=1
	ModifyGraph mirror=2
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph lblPos(left)=47,lblPos(ch1)=51
	ModifyGraph lblLatPos(left)=-1,lblLatPos(ch1)=-2
	ModifyGraph freePos(ch1)=0
	ModifyGraph axisEnab(left)={0,0.48}
	ModifyGraph axisEnab(ch1)={0.52,1}
	Label left "0 : \\{root:LENS:chanlistw[0]}"
	Label bottom "Photon Energy (eV)"
	Label ch1 "1 : \\{root:LENS:chanlistw[1]}"
	Textbox/N=title/F=0/A=MT/X=4.59/Y=2.73/E "\\JC\\{root:LENS:comment[0,44]}"
	AppendText "dwell= \\{root:LENS:dwell} sec, \\{root:LENS:filnam}"
	ControlBar 24
	ModifyGraph cbRGB=(65280,65280,0)
	CheckBox zero_left,pos={15,3},size={30,20},proc=CheckZero,title="0",value=0
	CheckBox zero_ch1,pos={53,3},size={30,20},proc=CheckZero,title="1",value=0
EndMacro

Window RawLENS_3() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LENS:
	Display /W=(238.5,63.5,510,414.5) chan0 vs hv
	AppendToGraph/L=ch1 chan1 vs hv
	AppendToGraph/L=ch2 chan2 vs hv
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(65280,65280,0)
	ModifyGraph grid(bottom)=1
	ModifyGraph tick(left)=2,tick(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph lblPos(left)=47,lblPos(ch1)=51,lblPos(ch2)=51
	ModifyGraph lblLatPos(left)=-1,lblLatPos(ch1)=-2,lblLatPos(ch2)=-3
	ModifyGraph freePos(ch1)=0
	ModifyGraph freePos(ch2)=0
	ModifyGraph axisEnab(left)={0,0.32}
	ModifyGraph axisEnab(ch1)={0.34,0.64}
	ModifyGraph axisEnab(ch2)={0.66,1}
	Label left "0 : \\{root:LENS:chanlistw[0]}"
	Label bottom "Photon Energy (eV)"
	Label ch1 "1 : \\{root:LENS:chanlistw[1]}"
	Label ch2 "2 : \\{root:LENS:chanlistw[2]}"
	Textbox/N=title/F=0/A=MT/X=6.08/Y=2.28/E "\\JC\\{root:LENS:comment[0,44]}"
	AppendText "dwell= \\{root:LENS:dwell} sec, \\{root:LENS:filnam}"
	ControlBar 24
	CheckBox zero_left,pos={15,3},size={30,20},proc=CheckZero,title="0",value=0
	CheckBox zero_ch1,pos={53,3},size={30,20},proc=CheckZero,title="1",value=0
	CheckBox zero_ch2,pos={89,3},size={30,20},proc=CheckZero,title="2",value=0
EndMacro


Window RawLENS_4() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LENS:
	Display /W=(284,60,567,426) chan0 vs hv
	AppendToGraph/L=ch1 chan1 vs hv
	AppendToGraph/L=ch2 chan2 vs hv
	AppendToGraph/L=ch3 chan3 vs hv
	SetDataFolder fldrSav
	ModifyGraph grid(bottom)=1
	ModifyGraph tick(left)=2,tick(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph lblPos(left)=47,lblPos(ch1)=51,lblPos(ch2)=51,lblPos(ch3)=52
	ModifyGraph lblLatPos(left)=-1,lblLatPos(ch1)=-2,lblLatPos(ch2)=-3,lblLatPos(ch3)=-2
	ModifyGraph freePos(ch1)=0
	ModifyGraph freePos(ch2)=0
	ModifyGraph freePos(ch3)=0
	ModifyGraph axisEnab(left)={0,0.24}
	ModifyGraph axisEnab(ch1)={0.26,0.49}
	ModifyGraph axisEnab(ch2)={0.51,0.74}
	ModifyGraph axisEnab(ch3)={0.76,1}
	Label left "0 : \\{root:LENS:chanlistw[0]}"
	Label bottom "Photon Energy (eV)"
	Label ch1 "1 : \\{root:LENS:chanlistw[1]}"
	Label ch2 "2 : \\{root:LENS:chanlistw[2]}"
	Label ch3 "3 : \\{root:LENS:chanlistw[3]}"
	Textbox/N=title/F=0/A=MT/X=4.59/Y=2.73/E "\\JC\\{root:LENS:comment[0,44]}"
	AppendText "dwell= \\{root:LENS:dwell} sec, \\{root:LENS:filnam}"
	ControlBar 24
	ModifyGraph cbRGB=(65280,65280,0)
	CheckBox zero_left,pos={15,3},size={30,20},proc=CheckZero,title="0",value=0
	CheckBox zero_ch1,pos={53,3},size={30,20},proc=CheckZero,title="1",value=0
	CheckBox zero_ch2,pos={89,3},size={30,20},proc=CheckZero,title="2",value=0
	CheckBox zero_ch3,pos={125,3},size={30,20},proc=CheckZero,title="3",value=0
EndMacro

Window RawLENS_5() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LENS:
	Display /W=(284,60,567,426) chan0 vs chan0_x
	AppendToGraph/L=ch1 chan1 vs chan1_x
	AppendToGraph/L=ch2 chan2 vs chan2_x
	AppendToGraph/L=ch3 chan3 vs chan3_x
	AppendToGraph/L=ch4 chan4 vs chan4_x
	SetDataFolder fldrSav
	ModifyGraph grid(bottom)=1
	ModifyGraph tick(left)=2,tick(bottom)=2
	ModifyGraph mirror=2
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph lblPos(left)=47,lblPos(ch1)=51,lblPos(ch2)=51,lblPos(ch3)=52, lblPos(ch4)=52
	ModifyGraph lblLatPos(left)=-1,lblLatPos(ch1)=-2,lblLatPos(ch2)=-3,lblLatPos(ch3)=-2, lblLatPos(ch4)=-2
	ModifyGraph freePos(ch1)=0
	ModifyGraph freePos(ch2)=0
	ModifyGraph freePos(ch3)=0
	ModifyGraph freePos(ch4)=0
	ModifyGraph axisEnab(left)={0,0.19}
	ModifyGraph axisEnab(ch1)={0.21,0.39}
	ModifyGraph axisEnab(ch2)={0.41,0.59}
	ModifyGraph axisEnab(ch3)={0.61,0.79}
	ModifyGraph axisEnab(ch4)={0.81,1}
	Label left "0 : \\{root:LENS:chanlistw[0]}"
	Label bottom "Photon Energy (eV)"
	Label ch1 "1 : \\{root:LENS:chanlistw[1]}"
	Label ch2 "2 : \\{root:LENS:chanlistw[2]}"
	Label ch3 "3 : \\{root:LENS:chanlistw[3]}"
	Label ch4 "4 : \\{root:LENS:chanlistw[4]}"
	Textbox/N=title/F=0/A=MT/X=4.59/Y=2.73/E "\\JC\\{root:LENS:comment[0,44]}"
	AppendText "dwell= \\{root:LENS:dwell} sec, \\{root:LENS:filnam}"
	ControlBar 24
	ModifyGraph cbRGB=(65280,65280,0)
	CheckBox zero_left,pos={15,3},size={30,20},proc=CheckZero,title="0",value=0
	CheckBox zero_ch1,pos={53,3},size={30,20},proc=CheckZero,title="1",value=0
	CheckBox zero_ch2,pos={89,3},size={30,20},proc=CheckZero,title="2",value=0
	CheckBox zero_ch3,pos={125,3},size={30,20},proc=CheckZero,title="3",value=0
	CheckBox zero_ch4,pos={161,3},size={30,20},proc=CheckZero,title="4",value=0
EndMacro

Proc SelectFolderLENS(ctrlName,popNum,popStr) : PopupMenuControl
//-------------------
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder root:LENS:
	if (popNum==2)						//print "Summarize Folder"
		SummarizeLENSfolder(filpath)
	else
		if (popNum==1)						//print "Select Folder"
			NewPath/O/Q/M="Select LENS Data Library" LENSdata				//dialog selection
			string/G filpath
			Pathinfo LENSdata
			filpath=S_path 
			folderList=folderList+filpath+";"
		endif
		if (popNum>3)							//print "Select Existing Folder"
			filpath=StringFromList(popNum-1,folderList)
			//print popNum, filpath
			NewPath/O/Q LENSdata filpath
		endif
		string fullfileList=IndexedFile( LENSdata, -1, "????")
		//string fullfileList=IndexedFile( LENSdata, -1, ".txt")
		//filelist=ReduceList( fullfilelist, "*.txt" )
		filelist=fullfileList
		//filelist=ReduceList( fullfilelist, "*.e*" )+ReduceList( fullfilelist, "*.u*" )
		numfiles=ItemsInList( fileList, ";")
	endif
	SetDataFolder root:
	
	//Update filelist popup menu & reset entry to top & read header & data
	root:LENS:filnum=1
	PopupMenu popup_file value=root:LENS:filelist, mode=root:LENS:filnum
	root:LENS:filnam=StringFromList( root:LENS:filnum-1, root:LENS:fileList, ";")
	ReadLENSHdr( root:LENS:filpath, root:LENS:filnam )
	ReadLENS( 0 )
	root:LENS:normlabel=NormLENS()
End


Proc UpdateFolderLENS(ctrlName) : ButtonControl
//-----------------------
	String ctrlName

	SetDataFolder root:LENS:
	
	string fullfileList=IndexedFile( LENSdata, -1, "????")		//".i##, .o##, .r##"
	filelist=ReduceList( fullfilelist, "*.txt" )
	numfiles=ItemsInList( fileList, ";")
	PopupMenu popup_file value=root:LENS:fileList		//#"root:LENS:fileList"
	
	StepFileLENS("StepPlus")
	
	SetDataFolder root:
End


Proc SelectFileLENS(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr

	root:LENS:filnam=popStr
	root:LENS:filnum=popNum
	ReadLENSHdr( root:LENS:filpath, root:LENS:filnam )
	ReadLENS( 0 )
	root:LENS:normlabel=NormLENS()
End

Proc StepFileLENS(ctrlName) : ButtonControl
//====================
	String ctrlName
	if (cmpstr(ctrlName,"StepMinus")==0)
		root:LENS:filnum=max(1, root:LENS:filnum-1)
	endif
	if (cmpstr(ctrlName,"StepPlus")==0)
		root:LENS:filnum=min(root:LENS:numfiles, root:LENS:filnum+1)
	endif
	root:LENS:filnam=StringFromList( root:LENS:filnum-1, root:LENS:fileList, ";")
	PopupMenu popup_file mode=root:LENS:filnum
	ReadLENSHdr( root:LENS:filpath, root:LENS:filnam )
	ReadLENS( 0 )
	root:LENS:normlabel=NormLENS()
End


Proc SetInputPopLENS(ctrlName,popNum,popStr) : PopupMenuControl
//---------------------------------
	String ctrlName
	Variable popNum
	String popStr

	if (cmpstr(ctrlName,"popup_plot")==0)
		root:LENS:plotchan= popNum-1
		root:LENS:filnam=root:LENS:filnam		// prompt wvnam global update
		root:LENS:normlabel=NormLENS()
	endif
	if (cmpstr(ctrlName,"popup_norm")==0)
		root:LENS:normchan= popNum-2
		root:LENS:wvnam:=WaveNameLENS( root:LENS:filnam)	
		root:LENS:filnam=root:LENS:filnam		// prompt wvnam global update
		root:LENS:normlabel=NormLENS()
	endif
	if (cmpstr(ctrlName,"popup_escale")==0)
		root:LENS:escale= popNum
	endif
End

Proc SetInputVarLENS(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	if (cmpstr(ctrlName,"val_label")==0)
		root:LENS:chanlist= varStr
		//root:LENS:chanlistw:=StringFromList( p, root:LENS:chanlist, ";")
	endif
End

Proc PlotLENS(ctrlName) : ButtonControl
//---------------------
	String ctrlName
	
	if (cmpstr(ctrlName,"PlotRaw")==0)
		string winnam="RawLENS_"+num2str(root:LENS:nchan)
		DoWindow/F $winnam
		if (V_flag==0)
			execute winnam+"()"
		endif
	else
		variable plotopt=-1							//negative means ReadLENSt skips open dialog and uLENS current filename
		if (cmpstr(ctrlName,"PlotAppend")==0)
			plotopt=-2
		endif
		LoadLENS(plotopt, root:LENS:plotchan, root:LENS:normchan, root:LENS:escale, root:LENS:chanlist)
	endif
End

Function CheckZero(ctrlName,checked) : CheckBoxControl
//======================
	String ctrlName
	Variable checked
	
	string axis=ctrlName[5,10]
	if (checked)
		SetAxis/A/E=1 $axis
	else
		SetAxis/A/E=0 $axis
	endif
End

Proc NamingPrefs(ctrlName) : ButtonControl
	String ctrlName
	
	WaveNamePrefs( )
End


Proc WaveNamePrefs(prefx, namtyp, namnum, chanext, nrmext)
//------------------------
	string prefx=StrVarOrDefault("root:LENS:prefix","")
	variable namtyp=NumVarOrDefault("root:LENS:nametyp",1), namnum=NumVarOrDefault("root:LENS:namenum",3)
	string chanext=StrVarOrDefault("root:LENS:chanlist","io,tey,fy")
	variable nrmext=NumVarOrDefault("root:LENS:normext",1)
	prompt prefx, "Wave Name prefix"
	prompt namtyp, "Wave Naming (derived from filename):", popup, "Full Prefix only;First N prefix characters;Last N prefix characters;Prefix only;Extension only;Remove . ;Convert . to _;"
	prompt namnum, "Number of prefix characters", popup, "1;2;3;4;5;6;7;8"
	prompt chanext, "Channel extension labels, ex: io,tey,fy"
	prompt nrmext, "Normalization name extension", popup, "No extension;Channel+n"
	
	silent 1; pauseupdate
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:LENS
		string/G prefix=prefx, chanlist=chanext
		Variable/G nametyp=namtyp, namenum=namnum, normext=nrmext
	SetDataFolder curr
	
	root:LENS:filnam=root:LENS:filnam		// prompt wvnam global update
End

Function/T WaveNameLENS( filenam )
//==================
//Options:
//  prefix, "Wave Name prefix"
//  namtyp,  "Full Prefix only;First N prefix characters;Last N prefix characters;Extension only;Remove . ;Convert . to _;"
//  namnum, "Number of prefix characters", popup, "1;2;3;4;5;6;7;8"
//  chanext, "Channel extension labels, ex: io,tey,fy"
//  nrmext, "Normalization name extension", popup, "No extension;Channel+n"
	string filenam
	
	SVAR prefix0=root:LENS:prefix 
	NVAR nametyp=root:LENS:nametyp, namenum=root:LENS:namenum
	NVAR plotchan=root:LENS:plotchan
	SVAR chanlist=root:LENS:chanlist
	NVAR normchan=root:LENS:normchan, normext=root:LENS:normext

	string prefix="", ext=""
	variable ipd=strsearch(filenam,".",0)
	if (ipd<0)					//no period found
		ipd=strlen(filenam)
		prefix=filenam
		ext=""
	else
		prefix=filenam[0, ipd-1]
		ext=filenam[ipd+1,strlen(filenam)-1]
	endif
	
	string basenam=prefix0, wvnam
	if (nametyp==1)
		basenam+=prefix
	endif
	if (nametyp==2)	
		basenam+=prefix[0,namenum-1]
	endif
	if (nametyp==3)
		basenam+=prefix[ipd-namenum, ipd-1]
	endif
	if (nametyp==4)
		basenam+=ext
	endif
	if (nametyp==5)
		basenam+=prefix+ext
	endif
	if (nametyp==6)
		basenam+=prefix+"_"+ext
	endif
	
	wvnam=basenam+StringFromList(plotchan, chanlist, ";")
	if (normchan>=0) 		// normalization channel selected
		wvnam=SelectString( normext==2, basenam, wvnam+"n")
	endif
	return wvnam
End




