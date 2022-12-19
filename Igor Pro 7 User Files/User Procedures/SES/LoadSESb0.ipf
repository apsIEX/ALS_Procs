// File: LoadSESb		Created: 12/99
// Jonathan Denlinger, JDDenlinger@lbl.gov
// 6/00 jdd  added balloon help to menus; added append image to volume function
// 6/10/00 jdd add Preview data option including pipeline to ImageTool 
// 9/22/00 jdd added prompt for Z scale input for 3D data sets
				added Summarize folder to preview popup
// 2/18/01 jdd added datafolder list memory; added dwell to front panel
// 5/17/01  er  convert "-" to "_" in extractname()for new version Scienta software naming

#pragma rtGlobals=1		// Use modern global access method.
#include "List_util"
#include "Volume"		// appendimg (to volume)

// SES-100 Binary File structure:  
//  -- saves *.pxt file in Igor packed experiment (template) format
//  contains a single binary wave (for a single region sequence)

//Contents:
//Proc  LoadSES(disp, hv, wf, en, cts)
//Fct/T 	ReadSESB()
//Fct/T 	ReadSESHdr(fpath, fnam)
//Fct 	NextBlockPosSES(file, blocksize) -- not used
//Fct/T 	ExtractNameB( filenam, option, numchar )
//Proc 	ShowSESInfo(wvn, opt)
//Fct/T 	SESInfoB( wv, opt )
//Macro	AddSESTitleB( Sample, filnum, Polar, Elev, Epass, WkFct, hv )
//Proc 	SummarizeSESLibrary()
//Proc 	SES_XPS_Style(xlabel, ylabel) 		: GraphStyle
//Proc 	GetZscale( st, inc, unit )

//Proc 	ShowLoadSESPanel()
//Wndw 	Load_SES()											: Panel
//Proc 	SelectLibSES(ctrlName) 							: ButtonControl
//Proc 	SelectFileSES(ctrlName,popNum,popStr) 			: PopupMenuControl
//Proc 	SetInputPopSES(ctrlName,popNum,popStr) 			: PopupMenuControl
//Proc 	SetInputVarSES(ctrlName,varNum,varStr,varName) 	: SetVariableControl
//Proc 	PlotSES(ctrlName) 									: ButtonControl
//Proc 	SetPreview(ctrlName,popNum,popStr) 				: PopupMenuControl
//Wndw	 SESpreview() 										: Graph

menu "Plot"
	"-"
	"Load SES Panel!"+num2char(19), ShowLoadSESPanel() 
		help={"Show GUI Panel for automated loading SES data (binary Igor .pxt files)"}
	"Summarize SES Folder", SummarizeSESFolder("")
		help={"Create a notebook with tabular header info from a folder of data"}
	"Load Binary SES file",  LoadSESb()
		help={"Load & plot single SES data file"}
	"Append SES spectrum/`",  LoadSESb(root:SES:dscale, root:SES:escale, root:SES:hv_, root:SES:wfct, root:SES:angoffset1, root:SES:angoffset2, root:SES:nametyp, root:SES:namenum, 2)
		help={"Load SES data file & append spectrum to top graph"}
	"Show SES info", ShowSESinfo()
		help={"Show table of header info for specified data in memory"}
	"Add SES Graph title", AddSEStitleB()
		help={"Create customized title annotation for top graph"}
end

Proc LoadSESb( cts,  escal, hv, wf, angoff1, angoff2,  namtyp, namnum, plotopt)
//------------------------
	variable plotopt, cts=NumVarOrDefault("root:SES:dscale",1)
	variable angoff1=NumVarOrDefault("root:SES:angoffset1",NaN), angoff2=NumVarOrDefault("root:SES:angoffset2",NaN)
	variable hv=NumVarOrDefault("root:SES:hv_",NaN), wf=NumVarOrDefault("root:SES:wfct",0)
	variable namtyp=NumVarOrDefault("root:SES:nametyp",1), namnum=NumVarOrDefault("root:SES:namenum",1)
	variable escal=NumVarOrDefault("root:SES:escale",1)
		prompt cts, "Intensity option", popup "Counts;Cts/Sec;Cts/Flux;Flux only"
		prompt plotopt, "Spectrum plot option", popup "Display;Append"
		prompt angoff1, "Sample Angle(NaN for no offset):"
		prompt angoff2, "Detector Angle Offset (NaN for no offset):"
		prompt hv, "Photon Energy (eV) [NaN=leave as KE scale]"
		prompt wf, "Work Function (eV) [4.1, SES, 4/97]:"
		prompt namtyp, "Wave Naming (derived from filename):", popup "Prefix only;Remove . ;Convert . to _;Extension only"
		prompt namnum, "Number of prefix characters", popup "all;2;3;4;5;6;7;8"
		prompt escal, "Energy Scale interpretion", popup "KE;BE"

	variable dum=1
	
	silent 1; pauseupdate
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:SES
		Variable/G angoffset1=angoff1, angoffset2=angoff2, hv_=hv, wfct=wf, nametyp=namtyp, namenum=namnum, dscale=cts, escale=escal
	SetDataFolder curr

//	string xlbl="Kinetic Energy (eV)", ylbl="Intensity (arb)"

//Load from binary files
	string base=ReadSESb(1-(plotopt<0))
	if (strlen(base)==0)
		abort 
	endif
	base=ExtractNameB( base, namtyp, namnum )   // need to put in loop for multiple regions
	base=root:SES:skind[0]+base
	print "base=", base
	//Duplicate/O root:SES:infowav $(base+"_info")

//	variable doimage=(disp==1)+(disp==2), dospectra=(disp==2)
	string  dwn, xwn, ywn=base+"_y"
	//duplicate/o root:SES:ANGLE $ywn
	
	string titlestr, wlst, winnam, xlbl, ylbl
	variable nx, ny=root:SES:nslice, nregion=root:SES:nregion
	string eunit, yunit
	variable ireg=0, eoff, yoff
	DO
		nx=root:SES:enpts[ireg]
		if (nregion==1)
			dwn=base
		else
			dwn=base+num2str(ireg)
		endif
		//if (cts<4)
			variable nfiles
			curr=GetDataFolder(1)
			SetDataFolder root:SES:Load
			nfiles=itemsinlist( wavelist("*",";",""))
			SetDataFolder $curr
			// get last wave in data folder in case previous one couldn't be purged
		string loadwv=GetIndexedObjName("root:SES:Load",1 ,nfiles-1 )
			print loadwv, "///", dwn
		duplicate/o $("root:SES:Load:"+loadwv) $("root:"+dwn)
			//else
			//	dwn+="flux"
			//	duplicate/o $("root:SES:FLUX"+num2str(ireg)) $dwn
			//endif
		
		// (optional) rescale data to desired format
		//----------------------------
		ylbl="Counts"
		if (cts>=2)
			ylbl="Cts/Sec"
			$dwn/=(root:SES:dwell[ireg]*root:SES:nsweep[ireg])
		endif
		if (cts==3)				// flux has been integrated the same dwell & sweeps as data
			ylbl="cts/flux"
			$dwn/=$("root:SES:FLUX"+num2str(ireg))
		endif
		
		// check accuracy of nx(enpts) and ny(nslice) variable read from 
             variable nx0=DimSize( $dwn, 0), ny0=DimSize( $dwn, 1), nz=DimSize( $dwn, 2)
             ny0=SelectNumber( ny0==0, ny0, 1)
             //print nx, nx0, ny, ny0
             if (nx!=nx0)
	             	print "nx discrepancy: hdr=", nx, ",  data=", nx0
	             	nx=nx0
             endif
             //if (ny0>0)
            	if (ny!=ny0)
             		print "ny discrepancy: hdr=", ny, ",  data=", ny0
             		ny=ny0
             	endif
            // endif
		
		// (optional) offset x-scale to BE using specified photon energy & work function
		//---------------------------------
		// File saved with KE values even if acquired in BE mode
		eoff=0;  	//eunit="KE"; 
		variable mode=1		//1=KE, 2=BE
		IF(mode==1)
			xlbl="Kinetic Energy (eV)"
			if ((escal==2)*(numtype(hv)==0))		//data stored as KE; only offset by  WorkFct
				root:SES:estart+=-hv			// I prefer negative BEs
				root:SES:eend+=-hv
				//root:SES:estep*=-1
				//eunit="BE"
				xlbl="Binding Energy (eV)"
				if (numtype(wf)==0)		// skip if NaN or INF
					eoff=wf
					root:SES:estart+=wf			// I prefer negative BEs
					root:SES:eend+=wf
				endif
			else
				eoff=0
			endif
			//SetScale/P x root:SES:estart[ireg], root:SES:estep[ireg], "", $dwn
			SetScale/I x root:SES:estart[ireg], root:SES:eend[ireg], "", $dwn
		ELSE
			xlbl="Kinetic Energy (eV)"
			if (escal==2)					//data stored as BE; only offset by  WorkFct
				//print "here"
				root:SES:estart*=-1			// I prefer negative BEs
				root:SES:estep*=-1
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
			SetScale/P x root:SES:estart[ireg]+eoff, root:SES:estep[ireg], "BE", $dwn
		ENDIF	
		
		// add to wavenote the offset
		//Note/K $dwn
		//Note $dwn, num2str(eoff)+",0,1,0,1,0,"+num2str(angoff1)
		
		IF (ny==1)							// single cycle: plot spectra only
			redimension/N=(nx) $dwn
			if (abs(plotopt)==1)
				display $dwn				//y vs x option?
				SES_XPS_Style( xlbl, ylbl)
			else
				DoWindow/F $WinName(0,1)
				append $dwn
				DoWindow/F Load_SESb_Panel		//helps for double-clicking when appending
			endif
			
		ELSE
			IF (nz==0)								// 2D data set
				// (optional) offset y-scale to specified center value
				//------------------------------------
				if ((numtype(angoff2)==0)*(numtype(angoff2)==0))		// skip if NaN or INF
					ylbl="Sample Angle (deg)"
					yoff=angoff1-angoff2
				else
					ylbl="Analyzer Angle (deg)"
					yoff=0
				endif
				//SetScale/P y root:SES:vstart-yoff, root:SES:vinc, "", $dwn
				titlestr=dwn+": "+num2str(nx)+"x"+num2str(ny)+"="+num2str(nx*ny)
				
			ELSE					// 3D data set
				GetZscale()					// popup dialog
				SetScale/P z root:SES:zstart, root:SES:zinc,root:SES:zunit, $dwn
				titlestr=dwn+": "+num2str(nx)+"x"+num2str(ny)+"x"+num2str(nz)
			ENDIF
			print dwn
			if (abs(plotopt)==1)
				DoWindow/F $(dwn+"_")
				if (V_flag==0)
					display; appendimage $dwn
					Textbox/N=title/F=0/A=MT/E titlestr
					ModifyImage $dwn ctab= {*,*,YellowHot,0}
					Label left ylbl
					Label bottom xlbl
					DoWindow/C $(dwn+"_")
				endif
			else				// Append Image means redimesion image on top graph
				AppendImg( , dwn )
			endif
		ENDIF
		
		ireg+=1
	WHILE( ireg<nregion)
	
	//print SESInfoB($base,0)

	//DeleteWaveList( S_Wavenames )
end



Function/T ReadSEShdr(fpath, fnam)
//=================
// read SES binary file header (actually ASCII text at the end)
// saves values in root:SES folder variables
	string fpath, fnam
	variable debug=0			// programming flag
	Variable file
	
	NewDataFolder/O/S root:SES
	//SetDataFolder root:SES:
	String/G filnam=fnam, filpath=fpath
	
	variable/G nregion=1	
	//variable/G kind
	variable/G vstart=0, vinc=1, nslice=1
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
	WAVE Astart=Astart, Aend=Aend	
	
	
	// Jump to near the end & then search for text
		FSetPos file, V_logEOF-500
		
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
			WHILE(jj<1000)
			//FStatus file
			//print V_logEOF, V_FilePos, V_logEOF-V_FilePos
			
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
				skind=SelectString( stringmatch( skind[0], "T"), skind, "Trans")
			estart[ii]=str2num( StringByKey("Low Energy", sheader, "=") )
			eend[ii]=str2num( StringByKey("High Energy", sheader, "=") )
			estep[ii]=str2num( StringByKey("Energy Step", sheader, "=") )*sign(eend[ii]-estart[ii])
			nsweep[ii]=str2num( StringByKey("Number of Sweeps", sheader, "=") )
			dwell[ii]=str2num( StringByKey("Step Time", sheader, "=") )	//*nsweep[ii]
			Astart[ii]=str2num( StringByKey("Detector First Y-Channel", sheader, "=") )
			Aend[ii]=str2num( StringByKey("Detector Last Y-Channel", sheader, "=") )
			Epass[ii]=str2num( StringByKey("Pass Energy", sheader, "=") )
			nslice=str2num( StringByKey("Number of Slices", sheader, "=") )
			hv_=str2num( StringByKey("Excitation Energy", sheader, "=") )
			
			enpts[ii]=round((eend[ii]-estart[ii])/estep[ii]+1)
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
		infowav[0][ii]=filnam[0,strlen(filnam)-5]
		infowav[1][ii]=skind; infowav[2][ii]=smode[ii]
		infowav[3][ii]=num2str(hv_); infowav[4][ii]="R.P."; infowav[5][ii]="Polar"
		infowav[6][ii]=num2str(Epass[ii]); infowav[7][ii]="Slit#"
		infowav[8][ii]=num2str(Estart[ii]); infowav[9][ii]=num2str(Eend[ii]); infowav[10][ii]=num2str(Estep[ii])
		infowav[11][ii]=num2str(1E-3*round(1E3*dwell[ii])); infowav[12][ii]=num2str(nsweep[ii])
		infowav[13][ii]="Temp"
		infowav[14][ii]=num2str(Astart[ii]); infowav[15][ii]=num2str(Aend[ii]); infowav[16][ii]=num2str(nslice)
		infowav[17][ii]=StrFromList("no;yes",iflux,";")		//num2str(iflux)
		ii+=1
	WHILE(ii<nregion)
	
	SetDataFolder root:
	return filnam
End


Function/T ReadSESb(idialog)
//=================
// read SES binary file
// determines the number cycles (angle, space) and number of regions (per cycle)
// saves values in root:SES folder variables
	variable idialog
	variable debug=0			// programming flag
	//Variable file
	
	SVAR filpath=root:SES:filpath, filnam=root:SES:filnam
	
	NewDataFolder/O/S root:SES:Load
	KillWaves/A/Z						// purge before loading new
	//variable numLoadw=CountObjects("root:SES:Load", 1)
	//string wvlst=GetIndexedObjName("root:SES:Load",1 ,0 )
	
	string file_path=filpath
	if (idialog>0)
		variable file
		Open/D/R/T="????"  file			//open file dialog only
		filnam=S_filename
		//print S_filename
		
		// extract filpath from full file name
		// and return short filename for wave renaming
		string delim=":"                 //"\:"[cmpstr(IgorInfo(2), "Macintosh")==0]
		variable nch=strlen(filnam), jj
		jj=nch-1
		DO 
			if (cmpstr( filnam[jj], delim)==0)
				break
			endif
			jj-=1
		WHILE( jj>0)
		file_path=filnam[0, jj]
		filnam=filnam[jj+1, nch-1]
		//print filpath, "// ", filnam
	endif
	
	LoadData/O/Q file_path+filnam
	
	SetDataFolder root:
	return filnam
End

Function NextBlockPosSES(file, blocksize)			//not currently
//=====================
	variable file, blocksize
	variable blocknum			
	FStatus file
	return blocksize*ceil(V_filePos/blocksize) 
End

Function/T ExtractNameB( filenam, option, numchar )
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
	//return prefix+suffix
	
	//string start=prefix+suffix, answer=""
	//variable ii=0,lim=strlen(start)
	// do    //new scienta software version: convert "-" in filename to "_"
	// 	answer+=SelectString( cmpstr(start[ii],"-")==0, start[ii], "_")
	//	ii+=1
	//while(ii<lim)
	
	//new Scienta software version: convert "-" in filename to "_"
	string answer=prefix+suffix
	variable ihyphen=strsearch(answer,"-", 0)		//works for only one occurence of "-"
	if (ihyphen>=0)
		answer[ihyphen,ihyphen]="_"
	endif
 
	return answer
End

Proc GetZscale( st, inc, unit )
//-----------------
	variable st=NumVarOrDefault("root:SES:zstart",0), inc=NumVarOrDefault("root:SES:zinc",1)
	string unit=StrVarOrDefault("root:SES:zunit","polar")
	prompt st, "Z start value"
	prompt inc, "Z increment"
	prompt unit, "Z-axis unit"
	variable/G root:SES:zstart=st, root:SES:zinc=inc
	string/G root:SES:zunit=unit
End

Proc ShowSESinfo(wvn, opt)
//-----------------
	string wvn=root:SES:filnam+"_info"
	variable opt
	prompt wvn, "SES file info wave", popup, WaveList("*_info",";","")
	prompt opt, "Display option", popup, "New Table;Append to topmost Table"
	if (opt==1)
		if (exists("root:SES:infonam")==0)
			//make/N=18/T/O root:SES:infonam
			List2Textw("filename,kind,mode,(hv),(R.P.),(Polar),Epass,Slit #,Ei,Ef,Estep,dwell,# sweep,T(K),Astart,Ainc,nslice,flux", ",", "root:SES:infonam")
		endif
		edit root:SES:infonam, $wvn
	else
		DoWindow/F $WinName(0, 2)
		append $wvn
	endif
End

Function/T SESinfoB( wv, opt )
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
			if (exists("SES_info")==0)
				make/o/T/N=15 SES_info
				SES_info={"start","final","incr","range","resolution","hv","gate (ms)","#scans","Epass","pressure","CIS/CFS BE","mesh current","start beam curr.","end beam curr.","max counts (Hz)"}
			endif
			edit SES_info, info as base+"_info"
		endif
	else
		if (opt==1)
			print str
		endif
	endif
	return str
end

Proc AddSESTitleB( Sample, WinNam, filnum, Temp, hv, slits, Polr, Azim, Ep, WFct )
//----------------
	string Sample=StrVarOrDefault("root:SES:Sample0","A\\B1\\MB\\B2\\M")
	string WinNam=StrVarOrDefault("root:SES:title0","TITLE"), filnum=StrVarOrDefault("root:SES:filnum0","000-009")
	string Polr=num2str( NumVarOrDefault("root:SES:angoffset1",0)), Azim=StrVarOrDefault("root:SES:Azimuth","0")
	variable Ep=root:SES:Epass[0], Wfct=NumVarOrDefault("root:SES:Wfct",4.35)
	string hv=num2str(NumVarOrDefault("root:SES:hv_",30)), slits=StrVarOrDefault("root:SES:slit","10")
	variable Temp=NumVarOrDefault("root:SES:TempK",30)
	prompt WinNam, "Title/Window Name  (<>=no change)"
	prompt slits, "Mono Slits or Res. Power"
	
	PauseUpdate; Silent 1
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:SES
		String/G Sample0=Sample, title0=WinNam, filnum0=filnum, Azimuth=Azim		//, hv_=hv	//, Polar=Polr, 
		Variable/G Wfct0=Wfct, TempK=Temp, angoffset1=str2num(Polr), hv_=str2num(hv)
		Epass[0]=Ep
	SetDataFolder curr
		//root:SES:sampleSav=sample
		//root:SES:titleSav=WinNam
		//root:SES:filnumSav=filnum
		//root:SES:polarSav=polr
		//root:SES:elevSav=elev
		//root:SES:EpassSav=Epass
		//root:SES:WFct=Wkfct
		//root:SES:hvSav=hv
	
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

Proc SummarizeSESFolder( pathnam )
//----------------
// reads scan info from each file in a specified (dialog) SES data folder 
//    and prints the info to an Igor Notebook which than can then be used as is
//    or imported (saved/pasted) into a spreadsheet
	string pathnam

	//PauseUpdate;
	Silent 1	
	if (strlen(pathnam)==0)
		NewPath/O/Q/M="Select SES Data Folder" DataLibrary				//dialog selection
		Pathinfo DataLibrary
		pathnam=S_path
	endif
	variable nfolder=ItemsInList(pathnam, ":")            //FolderSep()) same on both Mac & PC
	string libnam=StrFromList(pathnam, nfolder-1, ":")
	if (nfolder>=2)
		libnam=StrFromList(pathnam, nfolder-2, ":") +"_"+libnam 
	endif
	if (char2num(libnam[0])<65)		//non-alpha first character
		libnam="N"+libnam
	endif
	//print pathnam, libnam
	
	NewPath/O/Q DataLibrary pathnam
	string filelst=IndexedFile( DataLibrary, -1, ".pxt")		//"*.pxt"
	variable numfil=ItemsInList(filelst, ";")
	print "# files=", numfil		//,  filelst
	
	string Nbknam=libnam
	NewNotebook/W=(10,50,725,250)/F=1/N=$Nbknam
	variable j=72		//pts per inch
	Notebook $Nbknam, fSize=9, margins={0,0,10.0*j }, backRGB=(65535,65534,49151), fStyle=1, showruler=0
	Notebook $Nbknam, tabs={1.1*j,1.9*j, 2.5*j,3*j,3.5*j,4*j,4.5*j,5*j, 5.5*j, 6.0*j,6.5*j,7.1*j,7.5*j,8*j,8.5*j,9*j}
	Notebook $Nbknam, text="filename\tkind\tmode\thv\tR.P.\tPolar\tEpass\tSlit#\tEi\tEf\tEstep\tdwell\tnswp\tT(K)\tAi\tAinc\tnslice"
	// need space here for next line to work
	Notebook $Nbknam, fStyle=0

	string fnam, infostr
	variable ii=0
	DO
		fnam=StrFromList(filelst, ii, ";")
		ReadSESHdr( pathnam, fnam )
		//print Textw2List(root:SES:infowav, "", 0, 18)
		infostr="\r"+Textw2List(root:SES:infowav, "\t", 0, 16)
		NoteBook $Nbknam, text=infostr			//SESInfoB()
		
		ii+=1
	WHILE(ii<numfil)

End


Proc SES_XPS_Style(xlabel, ylabel) : GraphStyle
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

//********  Load Panel ***************

Proc ShowLoadSESPanel()
//-----------------
	DoWindow/F Load_SESb_Panel
	if (V_flag==0)
		NewDataFolder/O/S root:SES
		string/G filpath, filnam, fileList
		string/G folderList="Select New Folder;Summarize Folder;-;"
		variable/G  filnum, numfiles, nregion, nslice
		Make/O/N=(20) Estart, Eend, Estep, Epass
		Make/O/N=(20) Astart, Aend
		string/G skind, smode0
		variable/G hv_, wfct, angoffset1, angoffset2, dscale, escale
		variable/G autoload=0
		make/o/n=(20) data1D
		make/o/n=(20,20) data2D
		
		SetDataFolder root:
		
		Load_SESb_Panel()	
	endif
End

Window Load_SESb_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(737,55,955,315)
	ModifyPanel cbRGB=(64512,62423,1327)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (65495,2134,34028)
	DrawRRect 11,39,210,149
	SetDrawEnv fillpat= 5,fillfgc= (65495,2134,34028)
	DrawRRect 12,228,208,156
	PopupMenu popFolder,pos={10,0},size={97,19},proc=SelectFolderSES,title="Data Folder"
	PopupMenu popFolder,mode=0,value= #"root:SES:folderList"
	SetVariable setlib,pos={12,21},size={195,14},title=" ",fSize=10
	SetVariable setlib,limits={-Inf,Inf,1},value= root:SES:filpath
	PopupMenu popup_file,pos={14,44},size={123,19},proc=SelectFileSES,title="File"
	PopupMenu popup_file,mode=14,popvalue="LRS_004.pxt",value= #"root:SES:fileList\t\t"
	Button FileUpdate,pos={156,45},size={50,16},proc=UpdateFolderSES,title="Update"
	SetVariable val_kind,pos={18,71},size={61,14},title=" ",fSize=10
	SetVariable val_kind,limits={-Inf,Inf,1},value= root:SES:skind
	SetVariable val_mode,pos={88,71},size={44,14},title=" ",fSize=10
	SetVariable val_mode,limits={-Inf,Inf,1},value= root:SES:smode0
	ValDisplay val_Ep,pos={142,71},size={50,14},title="Ep",fSize=10
	ValDisplay val_Ep,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Epass[0]"
	ValDisplay val_Estart,pos={14,91},size={59,14},title="Ei",fSize=10
	ValDisplay val_Estart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estart,value= #"root:SES:Estart[0]"
	ValDisplay val_Eend,pos={76,91},size={59,14},title="Ef",fSize=10
	ValDisplay val_Eend,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Eend[0]"
	ValDisplay val_Estep,pos={138,91},size={65,14},title="Einc",fSize=10
	ValDisplay val_Estep,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Estep[0]"
	ValDisplay val_nslice,pos={141,109},size={66,14},title="# slice",fSize=10
	ValDisplay val_nslice,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nslice"
	ValDisplay val_Nreg,pos={20,130},size={60,14},title="# region",fSize=10
	ValDisplay val_Nreg,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nregion"
	PopupMenu popup_Cts,pos={32,161},size={72,19},proc=SetInputPopSES
	PopupMenu popup_Cts,mode=2,popvalue="Cts/Sec",value= #"\"Counts;Cts/Sec;Cts/Flux;Flux only\""
	PopupMenu popup_Escale,pos={130,161},size={40,19},proc=SetInputPopSES
	PopupMenu popup_Escale,mode=2,popvalue="BE",value= #"\"KE;BE\""
	SetVariable set_hv,pos={23,186},size={75,14},proc=SetInputVarSES,title="hv"
	SetVariable set_hv,fSize=10,limits={-Inf,Inf,1},value= root:SES:hv_
	SetVariable set_wfct,pos={108,186},size={80,14},proc=SetInputVarSES,title="wfct"
	SetVariable set_wfct,fSize=10,limits={-Inf,Inf,1},value= root:SES:wfct
	SetVariable set_ang1,pos={16,206},size={85,14},proc=SetInputVarSES,title="Ang1"
	SetVariable set_ang1,fSize=10,limits={-Inf,Inf,1},value= root:SES:angoffset1
	SetVariable set_ang2,pos={107,206},size={85,14},proc=SetInputVarSES,title="Ang2"
	SetVariable set_ang2,fSize=10,limits={-Inf,Inf,1},value= root:SES:angoffset2
	Button StepMinus,pos={74,234},size={20,18},proc=StepFileSES,title="<<"
	Button StepPlus,pos={98,234},size={20,18},proc=StepFileSES,title=">>"
	Button PlotButton1,pos={13,233},size={55,20},proc=PlotSES,title="Display"
	Button PlotButton2,pos={123,233},size={55,20},proc=PlotSES,title="Append"
	ValDisplay val_Astart,pos={14,110},size={55,14},title="Ai",fSize=10
	ValDisplay val_Astart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Astart,value= #"root:SES:Astart[0]"
	ValDisplay val_Aend,pos={78,109},size={55,14},title="Af",fSize=10
	ValDisplay val_Aend,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Aend[0]"
	PopupMenu popupPreview,pos={131,0},size={76,19},proc=SetPreviewSES,title="Preview"
	PopupMenu popupPreview,mode=0,value= #"\"No Preview;Show Preview;Data to ImageTool\""
	ValDisplay val_dwell,pos={143,129},size={59,14},title="dwell",fSize=10
	ValDisplay val_dwell,limits={0,0,0},barmisc={0,1000},value= #"root:SES:dwell[0]"
EndMacro

Proc SelectFolderSES_(ctrlName) : ButtonControl
//-----------------------
	String ctrlName

	SetDataFolder root:SES:
	
	if (stringmatch(ctrlName, "SetFolder"))
		NewPath/O/Q/M="Select SES Data Folder" SESDataLibrary				//dialog selection
		string/G filpath
		Pathinfo SESDataLibrary
		filpath=S_path
		
		NewPath/O/Q SESDataLibrary filpath
	endif
		// else the call is from the 'Update button' - refresh file list
	fileList=IndexedFile( SESDataLibrary, -1, ".pxt")
	numfiles=ItemsInList( fileList, ";")
	PopupMenu popup_file value=root:SES:fileList		//#"root:SES:fileList"
	
	if (stringmatch(ctrlName, "FileUpdate"))
		StepFileSES("StepPlus") 		// increment file selection to next (N+1)
	endif
	SetDataFolder root:
End

Proc SelectFolderSES(ctrlName,popNum,popStr) : PopupMenuControl
//-------------------
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder root:SES:
	if (popNum==2)						//print "Summarize Folder"
		SummarizeSESfolder(filpath)
	else
		if (popNum==1)						//print "Select Folder"
			NewPath/O/Q/M="Select SES Data Library" SESdata				//dialog selection
			string/G filpath
			Pathinfo SESdata
			filpath=S_path
			folderList=folderList+filpath+";"
		endif
		if (popNum>3)							//print "Select Existing Folder"
			filpath=StringFromList(popNum-1,folderList)
			//print popNum, filpath
			NewPath/O/Q SESdata filpath
		endif
		fileList=IndexedFile( SESdata, -1, ".pxt")	
		//filelist=ReduceList( fullfilelist, "*.pxt" )
		numfiles=ItemsInList( fileList, ";")
	endif
	SetDataFolder root:
End


Proc UpdateFolderSES(ctrlName) : ButtonControl
//-----------------------
	String ctrlName

	SetDataFolder root:SES:
	
	fileList=IndexedFile( SESdata, -1, ".pxt")	
	//filelist=ReduceList( fullfilelist, "*.pxt" )
	numfiles=ItemsInList( fileList, ";")
	PopupMenu popup_file value=root:SES:fileList		//#"root:SES:fileList"
	
	//StepFileSES("StepPlus") 		// increment file selection to next (N+1)
	
	SetDataFolder root:
End

Proc SelectFileSES(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr

	root:SES:filnam=popStr
	root:SES:filnum=popNum
	ReadSESHdr( root:SES:filpath, root:SES:filnam )
	
	//variable autoload=1
	if (root:SES:autoload>0)				// Preview option
	PauseUpdate; Silent 1
		ReadSESb(0)
		string loadwn, curr
			variable nfiles
			curr=GetDataFolder(1)
			SetDataFolder root:SES:Load
			nfiles=itemsinlist( wavelist("*",";",""))
			SetDataFolder $curr
			//print nfiles
		loadwn="root:SES:Load:"+GetIndexedObjName("root:SES:Load",1 ,nfiles-1 )
		if (WaveDims($loadwn)==1)
			duplicate/o $loadwn root:SES:data1D
			 root:SES:data2D=nan
		endif
		if (WaveDims($loadwn)==2)    
			if ( root:SES:autoload==2 )		// Pipeline to data to Image_Tool
				DoWindow/F ImageTool
				if (V_flag==1)
					NewImg( loadwn )
					DoWindow/F Load_SESb_Panel
				endif	
				//execute "NewImg( \""+loadwn+"\" )"	// 
			else
				duplicate/o $loadwn root:SES:data2D
				variable nx=DimSize(root:SES:data2D, 0) , ny=DimSize(root:SES:data2D, 1)
				Redimension/N=(nx) root:SES:data1D
				CopyScales root:SES:data2D, root:SES:data1D
				root:SES:data1D=root:SES:data2D[p][ny/2]
			endif
		endif
		if (WaveDims($loadwn)==3)
			if ( root:SES:autoload==2 )
				DoWindow/F ImageTool
				if (V_flag==1)
					NewImg( loadwn )
					DoWindow/F Load_SESb_Panel
				endif	
			endif
		endif
	endif
End

Proc StepFileSES(ctrlName) : ButtonControl
//====================
	String ctrlName
	variable filnum
	string filnam
	if (cmpstr(ctrlName,"StepMinus")==0)
		filnum=max(1, root:SES:filnum-1)
	endif
	if (cmpstr(ctrlName,"StepPlus")==0)
		filnum=min(root:SES:numfiles, root:SES:filnum+1)
	endif
	filnam=StringFromList( filnum-1, root:SES:fileList, ";")
	PopupMenu popup_file mode=filnum
	SelectFileSES( "", filnum, filnam )
End


Proc SetInputPopSES(ctrlName,popNum,popStr) : PopupMenuControl
//---------------------------------
	String ctrlName
	Variable popNum
	String popStr

	if (cmpstr(ctrlName,"popup_cts")==0)
		root:SES:dscale= popNum
	endif
	if (cmpstr(ctrlName,"popup_escale")==0)
		root:SES:escale= popNum
	endif
End

Proc SetInputVarSES(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	if (cmpstr(ctrlName,"set_hv")==0)
		root:SES:hv_= varNum
	endif
	if (cmpstr(ctrlName,"set_wfct")==0)
		root:SES:wfct= varNum
	endif
	if (cmpstr(ctrlName,"set_ang1")==0)
		root:SES:angoffset1= varNum
	endif
	if (cmpstr(ctrlName,"set_ang2")==0)
		root:SES:angoffset2= varNum
	endif
End

Proc PlotSES(ctrlName) : ButtonControl
//---------------------
	String ctrlName
	
	variable plotopt=-1							//negative means ReadSESB skips open dialog and uses current filename
	if (cmpstr(ctrlName,"PlotButton2")==0)
		plotopt=-2
	endif
	LoadSESb(root:SES:dscale, root:SES:escale, root:SES:hv_, root:SES:wfct, root:SES:angoffset1, root:SES:angoffset2, 1, 1, plotopt)
End

Proc SetPreviewSES(ctrlName,popNum,popStr) : PopupMenuControl
//--------------
	String ctrlName
	Variable popNum
	String popStr

	root:SES:autoload=popNum-1
	if (popNum==2)
		DoWindow/F SESpreview
		if (V_flag==0)
			SESpreview()
		endif
	endif

End

Window SESpreview() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:SES:
	Display /W=(230,75,582,314) data1D
	AppendImage/R/T data2D
	ModifyImage data2D ctab= {*,*,Grays,0}
	SetDataFolder fldrSav
	ModifyGraph lSize=0.5
	ModifyGraph mirror(left)=0,mirror(bottom)=0
	ModifyGraph lblLatPos(right)=-1
	Textbox/N=text0/F=0/S=3/H=14/A=MT/X=2.56/Y=2.51/E "\\{root:SES:filnam}: \\{root:SES:skind}, \\{root:SES:smode0}"
EndMacro


