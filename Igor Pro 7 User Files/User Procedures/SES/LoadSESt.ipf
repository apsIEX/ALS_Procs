// File: LoadSESt		Created: 12/99, J. D. Denlinger
// Adapted from LoadScienta

#pragma rtGlobals=1		// Use modern global access method.
#include "List_util"

// SESt-100 Text File (*.txt) structure:  
//  -- saves *.pxt file in Igor packed experiment format

//Contents:
//Proc  LoadSESt(disp, hv, wf, en, cts)
//Fct/T 	ReadSESt()
//Fct/T 	ReadSEStHdr(fpath, fnam)
//Fct 	NextBlockPos(file, blocksize)
//Fct/T 	ExtractNameBt( filenam, option, numchar )
//Proc 	ShowSEStInfo(wvn, opt)
//Fct/T 	SEStInfoB( wv, opt )
//Macro	AddSEStTitleB( Sample, filnum, Polar, Elev, Epass, WkFct, hv )
//Proc 	SummarizeFolder()
//Proc 	XPS_Style(xlabel, ylabel) 		: GraphStyle
//Wndw 	FluxMonitor()					: Graph

//Proc 	ShowLoadPanel()
//Wndw 	Load_SESt()									: Panel
//Proc 	SelectLib(ctrlName) 							: ButtonControl
//Proc 	SelectFile(ctrlName,popNum,popStr) 			: PopupMenuControl
//Proc 	SetInputPop(ctrlName,popNum,popStr) 			: PopupMenuControl
//Proc 	SetInput(ctrlName,varNum,varStr,varName) 	: SetVariableControl
//Proc 	PlotSESt(ctrlName) 							: ButtonControl

menu "Plot"
	"-"
	"Load Binary SESt file",  LoadSESt()
	"Append SESt spectrum/`",  LoadSESt(root:SESt:dscale, root:SESt:escale, root:SESt:hv_, root:SESt:wfct, root:SESt:angoffset1, root:SESt:angoffset2, root:SESt:nametyp, root:SESt:namenum, 2)
	"Add Graph title", AddSEStitleB()
	"Show SESt info", ShowSEStinfo()
	"Summarize Folder"
	"ShowLoadPanel"
end

Proc LoadSESt( cts,  escal, hv, wf, angoff1, angoff2,  namtyp, namnum, plotopt)
//------------------------
	variable plotopt, cts=NumVarOrDefault("root:SESt:dscale",1)
	variable angoff1=NumVarOrDefault("root:SESt:angoffset1",NaN), angoff2=NumVarOrDefault("root:SESt:angoffset2",NaN)
	variable hv=NumVarOrDefault("root:SESt:hv_",NaN), wf=NumVarOrDefault("root:SESt:wfct",0)
	variable namtyp=NumVarOrDefault("root:SESt:nametyp",1), namnum=NumVarOrDefault("root:SESt:namenum",1)
	variable escal=NumVarOrDefault("root:SESt:escale",1)
		prompt cts, "Intensity option", popup "Counts;Cts/Sec;Cts/Flux;Flux only"
		prompt plotopt, "Spectrum plot option", popup "Display;Append"
		prompt angoff1, "Sample Angle(NaN for no offset):"
		prompt angoff2, "Detector Angle Offset (NaN for no offset):"
		prompt hv, "Photon Energy (eV) [NaN=leave as KE scale]"
		prompt wf, "Work Function (eV) [4.1, SESt, 4/97]:"
		prompt namtyp, "Wave Naming (derived from filename):", popup "Prefix only;Remove . ;Convert . to _;Extension only"
		prompt namnum, "Number of prefix characters", popup "all;2;3;4;5;6;7;8"
		prompt escal, "Energy Scale interpretion", popup "KE;BE"

	variable dum=1
	
	silent 1; pauseupdate
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:SESt
		Variable/G angoffset1=angoff1, angoffset2=angoff2, hv_=hv, wfct=wf, nametyp=namtyp, namenum=namnum, dscale=cts, escale=escal
	SetDataFolder curr

//	string xlbl="Kinetic Energy (eV)", ylbl="Intensity (arb)"

//Load from binary files
	string base=ReadSESt(1-(plotopt<0))
	if (strlen(base)==0)
		abort 
	endif
	base=ExtractNameBt( base, namtyp, namnum )   // need to put in loop for multiple regions
	base=root:SES:skind[0]+base
	Duplicate/O root:SESt:infowav $(base+"_info")

//	variable doimage=(disp==1)+(disp==2), dospectra=(disp==2)
	string  dwn, xwn, ywn=base+"_y"
	//duplicate/o root:SESt:ANGLE $ywn
	
	string titlestr, wlst, winnam, xlbl, ylbl
	variable nx, ny=root:SESt:nloop, nregion=root:SESt:nregion
	string eunit, yunit
	variable ireg=0, eoff, yoff
	DO
		nx=root:SESt:enpts[ireg]
		if (nregion==1)
			dwn=base
		else
			dwn=base+num2str(ireg)
		endif
		print base
		if (cts<4)
			duplicate/o $("root:SESt:DAT"+num2str(ireg)) $dwn
		else
			dwn+="flux"
			duplicate/o $("root:SESt:FLUX"+num2str(ireg)) $dwn
		endif
		
		// (optional) rescale data to desired format
		//----------------------------
		ylbl="Counts"
		if (cts>=2)
			ylbl="cts/Sec"
			$dwn/=(root:SESt:dwell[ireg]*root:SESt:nsweep[ireg])
		endif
		if (cts==3)				// flux has been integrated the same dwell & sweeps as data
			ylbl="cts/flux"
			$dwn/=$("root:SESt:FLUX"+num2str(ireg))
		endif
		
		// (optional) offset x-scale to BE using specified photon energy & work function
		//---------------------------------
		eoff=0;  	//eunit="KE"; 
		variable mode=1		//1=KE, 2=BE
		IF(mode==1)
		xlbl="Kinetic Energy (eV)"
		if ((escal==2)*(numtype(hv)==0))		//data stored as KE; only offset by  WorkFct
			root:SESt:estart+=-hv			// I prefer negative BEs
			root:SESt:eend+=-hv
			//root:SESt:estep*=-1
			//eunit="BE"
			xlbl="Binding Energy (eV)"
			if (numtype(wf)==0)		// skip if NaN or INF
				eoff=wf
				root:SESt:estart+=wf			// I prefer negative BEs
				root:SESt:eend+=wf
			endif
		else
			eoff=0
		endif
		SetScale/P x root:SESt:estart[ireg], root:SESt:estep[ireg], "", $dwn
		ELSE
		xlbl="Kinetic Energy (eV)"
		if (escal==2)					//data stored as BE; only offset by  WorkFct
			//print "here"
			root:SESt:estart*=-1			// I prefer negative BEs
			root:SESt:estep*=-1
			//eunit="BE"
			xlbl="Binding Energy (eV)"
			if (numtype(wf)==0)		// skip if NaN or INF
				eoff=wf
			endif
		else
			if (numtype(hv)==0)		// skip if NaN or INF
				eoff=-(hv-wf)
				//eunit="BE"
			endif
		endif
		SetScale/P x root:SESt:estart[ireg]+eoff, root:SESt:estep[ireg], "", $dwn
		ENDIF	
		
		// add to wavenote the offset
		Note/K $dwn
		Note $dwn, num2str(eoff)+",0,1,0,1,0,"+num2str(angoff1)
		
		if (ny==1)							// single cycle: plot spectra only
			redimension/N=(nx) $dwn
			if (abs(plotopt)==1)
				display $dwn				//y vs x option?
				SESt_XPS_StyleB( xlbl, ylbl)
			else
				DoWindow/F $WinName(0,1)
				append $dwn
			endif
			
		else									// 2D data set
			// (optional) offset y-scale to specified center value
			//------------------------------------
			if ((numtype(angoff2)==0)*(numtype(angoff2)==0))		// skip if NaN or INF
				ylbl="Sample Angle (deg)"
				yoff=angoff1-angoff2
			else
				ylbl="Analyzer Angle (deg)"
				yoff=0
			endif
			if (root:SESt:kind==73)		//CIS
				ylbl="Photon Energy (eV)"
				yoff=0			//read in hv_start
			endif
			SetScale/P y root:SESt:vstart-yoff, root:SESt:vinc, "", $dwn
			
			DoWindow/F $(dwn+"_")
			if (V_flag==0)
				titlestr=dwn+": "+num2str(nx)+"x"+num2str(ny)+"="+num2str(nx*ny)
				display; appendimage $dwn
				Textbox/N=title/F=0/A=MT/E titlestr
				ModifyImage $dwn ctab= {*,*,YellowHot,0}
				Label left ylbl
				Label bottom xlbl
				DoWindow/C $(dwn+"_")
			endif
		endif
		
		ireg+=1
	WHILE( ireg<nregion)
	
	print SEStInfoB($base,0)

	//DeleteWaveList( S_Wavenames )
end

Function/T ReadSESthdr(fpath, fnam)
//=================
// read SESt text file SPECIFIC and REGIONS header
// saves values in root:SESt folder variables
	string fpath, fnam
	variable debug=0			// programming flag
	Variable file
	
	NewDataFolder/O/S root:SESt
	//SetDataFolder root:SESt:
	String/G filnam=fnam, filpath=fpath
	
	variable/G nregion=1	
	//variable/G kind
	variable/G vstart=0, vinc=1, nloop=1
	string/G skind
	string/G sheader=""
	string sline		//, sheader
	Open/R file as filpath+filnam
		FStatus file
			if (debug)
				print  S_Filename, ", numbytes=", V_logEOF
			endif
			
		// -- get number of regions
		FReadLine file, sline
		if (strsearch(sline, "[Info]",0)>=0)
			FReadLine file, sline
			//print StringByKey( "Number of Regions", sline[0,strlen(sline)-1], "=")
			nregion=str2num( StringByKey( "Number of Regions", sline, "=" ) )  //[0,strlen(sline)-2]
		else
			nregion=1
		endif
		
	
	// ----- Read region info from [REGION #] blocks  -------
	//, iEp, Epass, mode
	//variable/G estart, eend, estep, dwell, nsweep
	variable/G hv_
	make/o/T/n=10 smode
	make/o/n=10 iEp, Epass, mode, estart, eend, estep, dwell, nsweep, enpts
	WAVE/T smode=smode
	WAVE iEp=iEp, mode=mode, estart=estart, eend=eend, estep=estep, dwell=dwell, nsweep=nsweep, enpts=enpts
		
		variable ii=0, val
		DO
			//-- find Region ii+1 start
		 	variable jj=0
			 DO
				FReadLine file, sline
				//if (strsearch(sline, "[Region "+num2str(ii+1)+"]",0)>=0)
				if (strsearch(sline, "Location=",0)>=0)
					//print "r", jj, sline
					break
				endif
				//print "r", jj, sline
				jj+=1
			WHILE(jj<200)
			
			//-- load header lines into string
			 jj=0
			 DO
				FReadLine file, sline
				//print jj, sline[0,strlen(sline)-2]
				sheader+=sline[0,strlen(sline)-2]+";"
				jj+=1
			WHILE(jj<24)
			//print sheader
			
			//-- extract variables from header keyword list
			smode[ii]=StringByKey("Aquisition Mode", sheader, "=")
			skind=StringByKey("Lens Mode", sheader, "=")
			estart[ii]=str2num( StringByKey("Low Energy", sheader, "=") )
			eend[ii]=str2num( StringByKey("High Energy", sheader, "=") )
			estep[ii]=str2num( StringByKey("Energy Step", sheader, "=") )*sign(eend[ii]-estart[ii])
			nsweep[ii]=str2num( StringByKey("Number of Sweeps", sheader, "=") )
			dwell[ii]=str2num( StringByKey("Step Time", sheader, "=") )	//*nsweep[ii]
			Epass[ii]=str2num( StringByKey("Pass Energy", sheader, "=") )
			nloop=str2num( StringByKey("Number of Slices", sheader, "=") )
			hv_=str2num( StringByKey("Excitation Energy", sheader, "=") )
			
			enpts[ii]=(eend[ii]-estart[ii])/estep[ii]+1
			//smode[ii]=StrFromList("Fixed;Swept;Stepped", mode[ii], ";")
				if (debug)
					print ii,": E: start, stop, step, Np, dwell, nsweep, mode, Ep=", estart[ii], eend[ii], estep[ii], enpts[ii], dwell[ii], nsweep[ii], smode[ii], Epass[ii]
				endif
			ii+=1
		WHILE(ii<nregion)
	Close file
	string/G smode0=smode[0]
	//abort
	
	variable/G  iflux=0
	
	//--- write info wave
	if (nregion>1)
		make/T/o/n=(18,nregion) infowav
	else
		make/T/o/n=(18) infowav
	endif
		//infowav={filnam, skind, smode,"hv","slits","Polar",num2str(Ep),"Slit#",num2tr(Estart)
	//string/G smode0=smode[0]
	ii=0
	DO
		infowav[0][ii]=filnam; infowav[1][ii]=skind; infowav[2][ii]=smode[ii]
		infowav[3][ii]=num2str(hv_); infowav[4][ii]="R.P."; infowav[5][ii]="Polar"
		infowav[6][ii]=num2str(Epass[ii]); infowav[7][ii]="Slit#"
		infowav[8][ii]=num2str(Estart[ii]); infowav[9][ii]=num2str(Eend[ii]); infowav[10][ii]=num2str(Estep[ii])
		infowav[11][ii]=num2str(1E-3*round(1E3*dwell[ii])); infowav[12][ii]=num2str(nsweep[ii])
		infowav[13][ii]="Temp"
		infowav[14][ii]=num2str(vstart); infowav[15][ii]=num2str(Vinc); infowav[16][ii]=num2str(nloop)
		infowav[17][ii]=StrFromList("no;yes",iflux,";")		//num2str(iflux)
		ii+=1
	WHILE(ii<nregion)
	
	SetDataFolder root:
	return filnam
End

Function/T ReadSESt(idialog)
//=================
// read SESt binary file
// determines the number cycles (angle, space) and number of regions (per cycle)
// saves values in root:SESt folder variables
	variable idialog
	variable debug=0			// programming flag
	Variable file
	
	SetDataFolder root:SESt:
	String/G filnam, filpath
	
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
	print filpath+":, "+filnam
	if (strlen(filnam)==0)
		return ""
	endif	
	string basenam=filnam
	variable ipd=strsearch(filnam,".",0)
	if (ipd>0)
		basenam=filnam[0,ipd-1]
	endif
	print basenam
	
	// ----- Read header  -------
	print ReadSESthdr( filpath, filnam )
	
	// ----- Read data from RESULTS  -------
	//variable/G npts
	//make/o/n=10 npts
	
		variable  ireg=0, iloop=0, ix, dval, nextblock			// loop over  region
		//DO
			LoadWave/G/M/A=$basenam  filpath+filnam
		//	ireg+=1
		//WHILE( ireg<nregion)
	//Close file
	//scale image
	// duplicate root:SESt:infowav root:+"basenam"+"_info"
	// or put into waveNote string
	
	SetDataFolder root:
	return filnam
End

Function NextBlockPos(file, blocksize)
//=====================
	variable file, blocksize
	variable blocknum			
	FStatus file
	return blocksize*ceil(V_filePos/blocksize) 
End

Function/T ExtractNameBt( filenam, option, numchar )
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

Proc ShowSEStinfo(wvn, opt)
//-----------------
	string wvn=root:SESt:filnam+"_info"
	variable opt
	prompt wvn, "SESt file info wave", popup, WaveList("*_info",";","")
	prompt opt, "Display option", popup, "New Table;Append to topmost Table"
	if (opt==1)
		if (exists("root:SESt:infonam")==0)
			//make/N=18/T/O root:SESt:infonam
			List2Textw("filename,kind,mode,(hv),(R.P.),(Polar),Epass,Slit #,Ei,Ef,Estep,dwell,# sweep,T(K),Astart,Ainc,nloop,flux", ",", "root:SESt:infonam")
		endif
		edit root:SESt:infonam, $wvn
	else
		DoWindow/F $WinName(0, 2)
		append $wvn
	endif
End

Function/T SEStinfoB( wv, opt )
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
			if (exists("SESt_info")==0)
				make/o/T/N=15 SESt_info
				SESt_info={"start","final","incr","range","resolution","hv","gate (ms)","#scans","Epass","pressure","CIS/CFS BE","mesh current","start beam curr.","end beam curr.","max counts (Hz)"}
			endif
			edit SESt_info, info as base+"_info"
		endif
	else
		if (opt==1)
			print str
		endif
	endif
	return str
end

Proc AddSEStTitleB( Sample, WinNam, filnum, Temp, hv, slits, Polr, Azim, Ep, WFct )
//----------------
	string Sample=StrVarOrDefault("root:SESt:Sample0","A\\B1\\MB\\B2\\M")
	string WinNam=StrVarOrDefault("root:SESt:title0","TITLE"), filnum=StrVarOrDefault("root:SESt:filnum0","000-009")
	string Polr=num2str( NumVarOrDefault("root:SESt:angoffset1",0)), Azim=StrVarOrDefault("root:SESt:Azimuth","0")
	variable Ep=root:SESt:Epass[0], Wfct=NumVarOrDefault("root:SESt:Wfct",4.35)
	string hv=num2str(NumVarOrDefault("root:SESt:hv_",30)), slits=StrVarOrDefault("root:SESt:slit","10")
	variable Temp=NumVarOrDefault("root:SESt:TempK",30)
	prompt WinNam, "Title/Window Name  (<>=no change)"
	prompt slits, "Mono Slits or Res. Power"
	
	PauseUpdate; Silent 1
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:SESt
		String/G Sample0=Sample, title0=WinNam, filnum0=filnum, Azimuth=Azim		//, hv_=hv	//, Polar=Polr, 
		Variable/G Wfct0=Wfct, TempK=Temp, angoffset1=str2num(Polr), hv_=str2num(hv)
		Epass[0]=Ep
	SetDataFolder curr
		//root:SESt:sampleSav=sample
		//root:SESt:titleSav=WinNam
		//root:SESt:filnumSav=filnum
		//root:SESt:polarSav=polr
		//root:SESt:elevSav=elev
		//root:SESt:EpassSav=Epass
		//root:SESt:WFct=Wkfct
		//root:SESt:hvSav=hv
	
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

Proc SummarizeFolder()
//----------------
// reads scan info from each file in a specified (dialog) SESt data folder 
//    and prints the info to an Igor Notebook which than can then be used as is
//    or imported (saved/pasted) into a spreadsheet

	//PauseUpdate;
	Silent 1	
	NewPath/O/Q/M="Select SESt Data Folder" DataLibrary				//dialog selection
	string pathnam, libnam, regionpath
	Pathinfo DataLibrary
	pathnam=S_path
	//regionpath=pathnam+"REGIONS:"
	variable nfolder=ItemsInList(pathnam, FolderSep())
	libnam=StrFromList(pathnam, nfolder-1, FolderSep())
	print pathnam, libnam
	
	NewPath/O/Q DataLibrary pathnam
	string filelst=IndexedFile( DataLibrary, -1, "????")		//"*.txt"
	variable numfil=ItemsInList(filelst, ";")
	print "# files=", numfil		//,  filelst
	
	string Nbknam=libnam+"_"
	NewNotebook/F=1/N=$Nbknam
	variable j=72		//pts per inch
	Notebook $Nbknam, fSize=9, margins={0,0,10.0*j }, backRGB=(65535,65534,49151), fStyle=1
	Notebook $Nbknam, tabs={1*j,1.5*j,2*j, 2.5*j,3*j,3.5*j,4*j,4.5*j,5*j, 5.5*j, 6.0*j,6.6*j,7*j,7.5*j,8*j,8.5*j,9*j}
	Notebook $Nbknam, text="filename\tkind\tmode\thv\tR.P.\tPolar\tEpass\tSlit#\tEi\tEf\tEstep\tdwell\tnswp\tT(K)\tAi\tAinc\tnloop\tflux"
	Notebook $Nbknam, fStyle=0

	string fnam, infostr
	variable ii=0
	DO
		fnam=StrFromList(filelst, ii, ";")
		ReadSEStHdr( pathnam, fnam )
		//print Textw2List(root:SESt:infowav, "", 0, 18)
		infostr="\r"+Textw2List(root:SESt:infowav, "\t", 0, 17)
		NoteBook $Nbknam, text=infostr			//SEStInfoB()
		
		ii+=1
	WHILE(ii<numfil)

End

Proc SESt_XPS_StyleB(xlabel, ylabel) : GraphStyle
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

Window FluxMonitor() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:SESt:
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


Proc ShowLoadPanel()
//-----------------

	DoWindow/F Load_SESt
	if (V_flag==0)
		NewDataFolder/O/S root:SESt
		string/G filpath, filnam, fileList
		variable/G  filnum, numfiles, nregion, nloop
		Make/O/N=(20) Estart, Eend, Estep, Epass
		string/G skind, smode0
		variable/G hv_, wfct, angoffset1, angoffset2, dscale, escale
		SetDataFolder root:
		
		Load_SESt()	
	endif
End

Window Load_SESt() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(722,99,939,360)
	ModifyPanel cbRGB=(65535,19662,42605)
	SetDrawLayer UserBack
	DrawText 76,18,"Data Folder"
	SetDrawEnv fillfgc= (65495,2134,34028)
	DrawRRect 6,39,205,140
	SetDrawEnv fillpat= 5,fillfgc= (65495,2134,34028)
	DrawRRect 7,144,203,221
	Button button0,pos={12,1},size={30,16},proc=SelectLib,title="Set"
	SetVariable setlib,pos={12,20},size={190,14},title=" ",fSize=10
	SetVariable setlib,limits={-Inf,Inf,1},value= root:SESt:filpath
	PopupMenu popup_file,pos={14,44},size={132,19},proc=SelectFile,title="File"
	PopupMenu popup_file,mode=24,popvalue="Test_047.pxp",value= #"root:SESt:fileList\t\t"
	SetVariable val_kind,pos={18,71},size={65,17},title=" "
	SetVariable val_kind,limits={-Inf,Inf,1},value= root:SESt:skind
	SetVariable val_mode,pos={92,71},size={50,17},title=" "
	SetVariable val_mode,limits={-Inf,Inf,1},value= root:SESt:smode0
	ValDisplay val_Ep,pos={147,71},size={50,17},title="Ep"
	ValDisplay val_Ep,limits={0,0,0},barmisc={0,1000},value= #"root:SESt:Epass[0]"
	ValDisplay val_Estart,pos={14,92},size={55,17},title="Ei"
	ValDisplay val_Estart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estart,value= #"root:SESt:Estart[0]"
	ValDisplay val_Eend,pos={72,92},size={55,17},title="Ef"
	ValDisplay val_Eend,limits={0,0,0},barmisc={0,1000},value= #"root:SESt:Eend[0]"
	ValDisplay val_Estep,pos={130,92},size={70,17},title="Einc"
	ValDisplay val_Estep,limits={0,0,0},barmisc={0,1000},value= #"root:SESt:Estep[0]"
	ValDisplay val_Nloop,pos={29,116},size={65,17},title="# slice"
	ValDisplay val_Nloop,limits={0,0,0},barmisc={0,1000},value= #"root:SESt:nloop"
	ValDisplay val_Nreg,pos={106,116},size={75,17},title="# region"
	ValDisplay val_Nreg,limits={0,0,0},barmisc={0,1000},value= #"root:SESt:nregion"
	PopupMenu popup_Cts,pos={32,152},size={68,19},proc=SetInputPop
	PopupMenu popup_Cts,mode=1,popvalue="Counts",value= #"\"Counts;Cts/Sec;Cts/Flux;Flux only\""
	PopupMenu popup_Escale,pos={130,152},size={40,19},proc=SetInputPop
	PopupMenu popup_Escale,mode=1,popvalue="KE",value= #"\"KE;BE\""
	SetVariable set_hv,pos={23,178},size={75,17},proc=SetInput,title="hv"
	SetVariable set_hv,limits={-Inf,Inf,1},value= root:SESt:hv_
	SetVariable set_wfct,pos={108,176},size={80,17},proc=SetInput,title="wfct"
	SetVariable set_wfct,limits={-Inf,Inf,1},value= root:SESt:wfct
	SetVariable set_ang1,pos={16,197},size={85,17},proc=SetInput,title="Ang1"
	SetVariable set_ang1,limits={-Inf,Inf,1},value= root:SESt:angoffset1
	SetVariable set_ang2,pos={107,197},size={85,17},proc=SetInput,title="Ang2"
	SetVariable set_ang2,limits={-Inf,Inf,1},value= root:SESt:angoffset2
	Button StepMinus,pos={15,229},size={20,18},proc=StepFile,title="<<"
	Button StepPlus,pos={40,229},size={20,18},proc=StepFile,title=">>"
	Button PlotButton1,pos={73,228},size={55,20},proc=PlotSESt,title="Display"
	Button PlotButton2,pos={137,228},size={55,20},proc=PlotSESt,title="Append"
EndMacro

Proc SelectLib(ctrlName) : ButtonControl
//-----------------------
	String ctrlName

	SetDataFolder root:SESt:
	
	NewPath/O/Q/M="Select SESt (Text) Data Folder" DataLibrary				//dialog selection
	string/G filpath
	string libnam, regionpath
	Pathinfo DataLibrary
	filpath=S_path
	//regionpath=filpath+"REGIONS:"
	//variable nfolder=ItemsInList(pathnam, FolderSep())
	//libnam=StrFromList(pathnam, nfolder-1, FolderSep())
	//print pathnam, regionpath, libnam
	
	NewPath/O/Q DataLibrary filpath
	fileList=IndexedFile( DataLibrary, -1, "????")		//".txt"
	numfiles=ItemsInList( fileList, ";")
	PopupMenu popup_file value=root:SESt:fileList		//#"root:SESt:fileList"
	//PopupMenu popup_file value=IndexedFile( DataLibrary, -1, "????")
	
	SetDataFolder root:
End

Proc SelectFile(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr

	root:SESt:filnam=popStr
	root:SESt:filnum=popNum
	ReadSEStHdr( root:SESt:filpath, root:SESt:filnam )
End

Proc StepFile(ctrlName) : ButtonControl
//====================
	String ctrlName
	if (cmpstr(ctrlName,"StepMinus")==0)
		root:SESt:filnum=max(1, root:SESt:filnum-1)
	endif
	if (cmpstr(ctrlName,"StepPlus")==0)
		root:SESt:filnum=min(root:SESt:numfiles, root:SESt:filnum+1)
	endif
	root:SESt:filnam=StringFromList( root:SESt:filnum-1, root:SESt:fileList, ";")
	PopupMenu popup_file mode=root:SESt:filnum
	ReadSEStHdr( root:SESt:filpath, root:SESt:filnam )
End


Proc SetInputPop(ctrlName,popNum,popStr) : PopupMenuControl
//---------------------------------
	String ctrlName
	Variable popNum
	String popStr

	if (cmpstr(ctrlName,"popup_cts")==0)
		root:SESt:dscale= popNum
	endif
	if (cmpstr(ctrlName,"popup_escale")==0)
		root:SESt:escale= popNum
	endif
End

Proc SetInput(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	if (cmpstr(ctrlName,"set_hv")==0)
		root:SESt:hv_= varNum
	endif
	if (cmpstr(ctrlName,"set_wfct")==0)
		root:SESt:wfct= varNum
	endif
	if (cmpstr(ctrlName,"set_ang1")==0)
		root:SESt:angoffset1= varNum
	endif
	if (cmpstr(ctrlName,"set_ang2")==0)
		root:SESt:angoffset2= varNum
	endif
End

Proc PlotSESt(ctrlName) : ButtonControl
//---------------------
	String ctrlName
	
	variable plotopt=-1							//negative means ReadSESt skips open dialog and uses current filename
	if (cmpstr(ctrlName,"PlotButton2")==0)
		plotopt=-2
	endif
	LoadSESt(root:SESt:dscale, root:SESt:escale, root:SESt:hv_, root:SESt:wfct, root:SESt:angoffset1, root:SESt:angoffset2, 1, 1, plotopt)
End


