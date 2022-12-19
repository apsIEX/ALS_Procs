// File: LoadSESb		Created: 12/99
// Jonathan Denlinger, JDDenlinger@lbl.gov

//  2/20/08 jdd (v2.01)  tweak folder summarize format
// 12/10/05 jdd (v2.0) Replace FileList PopMenu with ListBox (single row) selector
//                                -- rename many Procs with "LoadSES_" prefix 
//                                -- Add Check Version if using old panel & exercise SelectFolder 
//                                -- preliminary switch to load .dat files
// 2/1/05 (v1.8)  -- change ReadSEShdr to handle v1.15--> v1.2.2  "Aquisition Mode"  --> "Acquisition Mode"
//                    and  fix original error of FReadLine/N=1000  (multiple regions data files) 
//			added IT button for ImageTool instead of global preference
// 6/18/04  -- changed ImgResize option to conform to /O/D changes
// 9/27/03 (v1.7) added filesize to Summarize folder
//                         -- added image size rebin to import
// 2/21/03 jdd  moved version # from text box to value display in control bar; add GroupBoxes
//                         add OS specific load panel resize
// 9/11/02  jdd  convert all data to Single Precision (FP32); new 1.1.5 SES software stores
//                          transmission as UINT32 and Angular as UINT16
// 12/29/01 jdd  (v1.5) improved filelist updating when switching folders; 
//                           changed Cts/Sec to also divided by # energy points; added kCounts & kCts/Sec
//                           integrate SESpreview into Load_SESb_Panel
// 5/17/01  er (v1.4) convert "-" to "_" in extractname()for new version Scienta software naming
// 2/18/01 jdd (v1.3) added datafolder list memory; added dwell to front panel
// 9/22/00 jdd (v1.2) added prompt for Z scale input for 3D data sets
//				-- added Summarize folder to preview popup
// 6/10/00 jdd (v1.1) add Preview data option including pipeline to ImageTool 
// 6/00 jdd  added balloon help to menus; added append image to volume function

#pragma rtGlobals=1		// Use modern global access method.
#include "List_util"
#include "wav_util"		// WriteMod(), ExtractName()
#include "Image_Util"		//ImgResize( )	
#include "Volume"			// appendimg (to volume), VolResize
#include "LoadSESdat123"

// SES-100 Binary File structure (v1.1.5) 
//  -- saves *.pxt file in Igor packed experiment (template) format
//  contains a single binary wave (for a single region sequence)
// ** Wavenote contains header information:
//   Wave: VB_Fixed
//   Type: FP64   Size: 329120 bytes
//   Dim[0]:411 Units:eV Start: 88.7085 Delta: 0.00876042
//   Dim[1]:100 Units:deg Start: -7.86684 Delta: 0.150403
//   Note: 
//   --> [SES] added in v1.2.2
//   --> Version=1.2.2
//   Instrument=SES 2002-567
//   Location=HERS
//   User=Jonathan
//   Sample=UGe2
//   Comments=
//        --> (new blank line in v1.2.2)
//   Date=2/11/02
//   Time=4:02:39 AM
//   Detector Channels=471
//   Region Name=VB_Fixed
//   Excitation Energy=92
//   Energy Scale=Kinetic
//   Aquisition Mode=Fixed        -->  Acquisition Mode  (v1.2.2)
//      --> Center Energy =      (new line in v1.2.2)
//   Low Energy=88.4480753586606
//   High Energy=92.5519246413394
//   Energy Step=0.00876041652087167
//   Step Time=30
//   Detector First X-Channel=30
//   Detector Last X-Channel=440
//   Detector First Y-Channel=160
//   Detector Last Y-Channel=459
//   Number of Slices=100
//   Lens Mode=Angular
//   Pass Energy=50
//   Number of Sweeps=4
//   EndSES      --> blank line or "[Run Mode Information" in v1.2.2



//Contents:
//Proc  	LoadSES(disp, hv, wf, en, cts)
//Fct/T 	ReadSESb()
//Fct/T 	ReadSESHdr(fpath, fnam)
//Fct 		NextBlockPosSES(file, blocksize) -- not used
//Fct/T 	ExtractNameB( filenam, option, numchar )
//Proc 		LoadSESb_ShowInfo(wvn, opt)
//Fct/T 	SESInfoB( wv, opt )
//Macro	AddSESTitleB( Sample, filnum, Polar, Elev, Epass, WkFct, hv )
//Proc 	SummarizeSESLibrary()
//Proc 	SES_XPS_Style(xlabel, ylabel) 		: GraphStyle
//Proc 	GetZscale( st, inc, unit )

//Proc 	LoadSESb_ShowPanel()
//Wndw 	Load_SES()											: Panel
//Proc 	SelectLibSES(ctrlName) 							: ButtonControl
//Proc 	LoadSESb_SelectFile(ctrlName,popNum,popStr) 			: PopupMenuControl
//Proc 	LoadSESb_SetPop(ctrlName,popNum,popStr) 			: PopupMenuControl
//Proc 	LoadSESb_SetVar(ctrlName,varNum,varStr,varName) 	: SetVariableControl
//Proc 	PlotSES(ctrlName) 									: ButtonControl
//Proc 	SetPreview(ctrlName,popNum,popStr) 				: PopupMenuControl
//Wndw	 SESpreview() 										: Graph

menu "Plot"
	"-"
	"Load SES Panel!"+num2char(19), LoadSESb_ShowPanel() 
		help={"Show GUI Panel for automated loading SES data (binary Igor .pxt files)"}
	"Summarize SES Folder", LoadSESb_SummarizeFolder("")
		help={"Create a notebook with tabular header info from a folder of data"}
	"Load Binary SES file",  LoadSESb()
		help={"Load & plot single SES data file"}
	"Append SES spectrum/`",  LoadSESb(root:SES:dscale, root:SES:escale, root:SES:hv_, root:SES:wfct, root:SES:angoffset1, root:SES:angoffset2, root:SES:nametyp, root:SES:namenum, 2)
		help={"Load SES data file & append spectrum to top graph"}
	"Show SES info", LoadSESb_ShowInfo()
		help={"Show table of header info for specified data in memory"}
	"Add SES Graph title", AddSEStitleB()
		help={"Create customized title annotation for top graph"}
end

Proc PlotSESb_prefb(ctrlName) : ButtonControl
	String ctrlName
	PlotSESb_prefs()
	string/G root:SES:wvnam=root:SES:skind[0]+ExtractName( root:SES:filnam, root:SES:nameopt)
End

Proc PlotSESb_prefs( namopt, dscal,  escal, xscal, imgtool)
//------------------------
	string namopt=StrVarOrDefault("root:SES:nameopt","/B=-3")
	variable dscal=NumVarOrDefault("root:SES:dscale",6)
	variable escal=NumVarOrDefault("root:SES:escale",3)
	variable xscal=NumVarOrDefault("root:SES:xscale",2)
	variable imgtool=NumVarOrDefault("root:SES:autoload",1)
		prompt namopt, "Wave Naming [/B=n/E/U/P=prefix/S=suffix]"
		prompt dscal, "Data intensity scaling", popup "Counts;kCts;Mcts;Cts/Sec;kHz;MHz"
		prompt escal, "Energy Scale", popup "KE;BE; -BE"
		prompt xscal, "Axis scaling", popup "Y vs X;Y(x)"
		prompt imgtool, "Preview", popup "Standard;2D/3D data to ImageTool"

	String curr= GetDataFolder(1)
	SetDataFolder root:SES:
		variable/G dscale=dscal, escale=escal, xscale=xscal, autoload=imgtool
		string/G nameopt=namopt
	
	SetDataFolder $curr
end

//Proc LoadSESb( cts,  escal, hv, wf, angoff1, angoff2,  namtyp, namnum, plotopt)
Proc LoadSESb( cts,  escal, hv, plotopt)
//------------------------
	variable plotopt, cts=NumVarOrDefault("root:SES:dscale",1)
	//variable angoff1=NumVarOrDefault("root:SES:angoffset1",NaN), angoff2=NumVarOrDefault("root:SES:angoffset2",NaN)
	variable hv=NumVarOrDefault("root:SES:hv_",NaN)	//, wf=NumVarOrDefault("root:SES:wfct",0)
	variable namtyp=NumVarOrDefault("root:SES:nametyp",1), namnum=NumVarOrDefault("root:SES:namenum",1)
	variable escal=NumVarOrDefault("root:SES:escale",1)
		prompt cts, "Intensity option", popup "Counts;kCts; Cts/Sec;kCts/Sec"
		prompt plotopt, "Spectrum plot option", popup "Display;Append"
		//prompt angoff1, "Sample Angle(NaN for no offset):"
		//prompt angoff2, "Detector Angle Offset (NaN for no offset):"
		prompt hv, "Photon Energy (eV) [NaN=leave as KE scale]"
		//prompt wf, "Work Function (eV) [4.1, SES, 4/97]:"
		//prompt namtyp, "Wave Naming (derived from filename):", popup "Prefix only;Remove . ;Convert . to _;Extension only"
		//prompt namnum, "Number of prefix characters", popup "all;2;3;4;5;6;7;8"
		prompt escal, "Energy Scale interpretion", popup "KE;BE"

	variable dum=1
	
	silent 1; pauseupdate
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:SES
		//Variable/G angoffset1=angoff1, angoffset2=angoff2, hv_=hv, wfct=wf, nametyp=namtyp, namenum=namnum, dscale=cts, escale=escal
		Variable/G  hv_=hv,  dscale=cts, escale=escal
	SetDataFolder curr

//	string xlbl="Kinetic Energy (eV)", ylbl="Intensity (arb)"

//Load from binary files
	string base=ReadSESb(1-(plotopt<0))
	if (strlen(base)==0)
		abort 
	endif
	//base=ExtractNameB( base, namtyp, namnum )   // need to put in loop for multiple regions
	//base=root:SES:skind[0]+base
	//print "base=", base
		//base=WaveNameSES( base )
	//print "base=", base
	//Duplicate/O root:SES:infowav $(base+"_info")
	
	base=root:SES:wvnam

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
			nfiles=ItemsInList( wavelist("*",";",""))
			SetDataFolder $curr
			// get last wave in data folder in case previous one couldn't be purged
		string loadwv="root:SES:Load:"+PossiblyQuoteName(GetIndexedObjName("root:SES:Load",1 ,nfiles-1 ))
			//print loadwv, "///", dwn
		
		// variable nx0=DimSize( $dwn, 0), ny0=DimSize( $dwn, 1), nz=DimSize( $dwn, 2)
		 //ny0=SelectNumber( ny0==0, ny0, 1)
		 variable Ndim=WaveDims($loadwv)
		 //print "Ndims:", ndim
		IF( Ndim==1 )
			duplicate/o $loadwv $("root:"+dwn)	
			titlestr=dwn
		ELSE
		IF (Ndim==2)
			// also incorporate DeGlitch()
			titlestr=ImgResize( $loadwv, root:SES:srebin, "/R/D=root:"+dwn )
			ImgDeglitch( $("root:"+dwn),"/O")
		ELSE 	//Ndim==3
			titlestr=VolResize( $loadwv, root:SES:srebin+",1", "/R/D=root:"+dwn )	
			// ImgDeglitch( $("root:"+dwn), opt)
		ENDIF
		ENDIF
		
		//if (wavetype($("root:"+dwn))==96)		//96=UINT32, 80=UINT16
			//Redimension/D  $("root:"+dwn)			//convert Unsigned INT32 to FP64 (double precision)
			Redimension/S  $("root:"+dwn)			//convert Unsigned INT32 to FP32 (single precision)
		//endif
			//else
			//	dwn+="flux"
			//	duplicate/o $("root:SES:FLUX"+num2str(ireg)) $dwn
			//endif
		
		// (optional) rescale data to desired format
		//----------------------------
		ylbl=StringFromList( cts-1, "Counts;kCts;Cts/sec/chan;kHz/chan" )
		if (cts>=3)
			//$dwn/=(root:SES:dwell[ireg]*root:SES:nsweep[ireg]*root:SES:enpts[ireg])
			$dwn/=(root:SES:dwell[ireg]*root:SES:nsweep[ireg]*(root:SES:Xend[ireg]-root:SES:Xstart[ireg]+1))
		endif
		if (mod(cts,2)==0)		// cts=2 or 4 => kilo-
			$dwn/=1000
		endif
		
		// check accuracy of nx(enpts) and ny(nslice) variable read from 
             variable nx0=DimSize( $dwn, 0), ny0=DimSize( $dwn, 1), nz=DimSize( $dwn, 2)
           //  ny0=SelectNumber( ny0==0, ny0, 1)
             //print nx, nx0, ny, ny0
            // if (nx!=nx0)
	     //        	print "nx discrepancy: hdr=", nx, ",  data=", nx0
	     //        	nx=nx0
            // endif
             //if (ny0>0)
            //	if (ny!=ny0)
            // 		print "ny discrepancy: hdr=", ny, ",  data=", ny0
            // 		ny=ny0
            // 	endif
            // endif
		
		// (optional) offset x-scale to BE using specified photon energy & work function
		//---------------------------------
		
		eoff=0
		//if (numtype(wf)==0)		// skip if NaN or INF
		//	eoff=-wf
		//endif
		variable mode=1
		xlbl=StringFromList( escal-1, "Kinetic Energy (eV);Binding Energy (eV)" )
		//IF(mode==1)
		// File saved with KE values even if acquired in BE mode??  Not anymore 11/02
		if ((escal==2)*(numtype(hv)==0))		//shift by photon energy
			eoff+=-hv
		endif
		if (escal<3)		// escal==3 => as is (no change)
			//SetScale/P x root:SES:estart[ireg]+eoff, root:SES:estep[ireg], "", $dwn
			SetScale/I x root:SES:estart[ireg]+eoff, root:SES:eend[ireg]+eoff, "", $dwn
		endif
		//ELSE
		//ENDIF	
		
		// add to wavenote the offset
		//string txtstr=num2str(root:SES:Epass[ireg])+root:SES:skind[0]+(root:SES:smode[0])[0]
		string txtstr=root:SES:infowav[1]	//[0]
		//print txtstr
		//Note/K $dwn
		//Note $dwn, num2str(eoff)+",0,1,0,0.5,0,"+num2str(angoff1)+","+txtstr
		WriteMod($dwn, eoff, 0, 1, 0, 0.5, 0, hv, txtstr)
		
		IF (ny==1)							// single cycle: plot spectra only
			redimension/N=(nx) $dwn
			if (abs(plotopt)==1)
				display $dwn				//y vs x option?
				SES_XPS_Style( xlbl, ylbl)
			else
				DoWindow/F $StringFromList(0, WinList("!*SES*", ";", "Win:1"))	
				append $dwn
				DoWindow/F Load_SESb_Panel		//helps for double-clicking when appending
			endif
			
		ELSE
			IF (nz==0)								// 2D data set
				// (optional) offset y-scale to specified center value
				//------------------------------------
				//if ((numtype(angoff2)==0)*(numtype(angoff2)==0))		// skip if NaN or INF
				//	ylbl="Sample Angle (deg)"
				//	yoff=angoff1-angoff2
				//else
				//	ylbl="Analyzer Angle (deg)"
				//	yoff=0
				//endif
				//SetScale/P y root:SES:vstart-yoff, root:SES:vinc, "", $dwn
				//titlestr=ImgResize( $dwn, root:SES:srebin, "/R/O" )
				//print titlestr	
				//titlestr=dwn+": "+num2str(nx)+"x"+num2str(ny)+"="+num2str(nx*ny)
			ELSE					// 3D data set
				GetZscale()					// popup dialog
				SetScale/P z root:SES:zstart, root:SES:zinc,root:SES:zunit, $dwn
				//titlestr=dwn+": "+num2str(nx)+"x"+num2str(ny)+"x"+num2str(nz)
				//titlestr=VolResize( $dwn, root:SES:srebin+",1", "/R/O" )	
			ENDIF
			//print dwn
			if (abs(plotopt)==1)
				DoWindow/F $(dwn+"_")
				if (V_flag==0)
					display; appendimage $dwn
					Textbox/N=title/F=0/A=MT/E titlestr
					ModifyImage $dwn ctab= {*,*,YellowHot,0}
					Label left ylbl
					Label bottom xlbl
					DoWindow/C $(dwn+"_")
					if (nz>0)		//3D
						Vol_ControlBar()
					endif
				else
					Textbox/C/N=title/F=0/A=MT/E titlestr
				endif
			else						// Append Image means redimension image/vol array		
				AppendVol( , dwn )
				Killwaves/Z $dwn
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
	variable/G vstart=0, vinc=1, nslice=1, filesize=1
	string/G skind
	string/G sheader=""
	string sline		//, sheader
	Open/R file as filpath+filnam
		FStatus file
			if (debug)
				print  S_Filename, ", numbytes=", V_logEOF
			endif
			
		// -- get number of regions
		//FReadLine file, sline
		FReadLine/N=1000 file, sline
		//print strlen(sline)
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
	WAVE Xstart=Xstart, Xend=Xend,  Ystart=Ystart, Yend=Yend	
	
	
	// Jump to near the end & then search for text
		FSetPos file, V_logEOF-600
		
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
				FReadLine file, sline//
				//print jj, sline[0,strlen(sline)-2]
				sheader+=sline[0,strlen(sline)-2]+";"
				jj+=1
			WHILE(jj<25)
			//print sheader
			
			//-- extract variables from header keyword list
			smode[ii]=StringByKey("Aquisition Mode", sheader, "=")+StringByKey("Acquisition Mode", sheader, "=")
			skind=StringByKey("Lens Mode", sheader, "=")
				skind=SelectString( stringmatch( skind[0], "T"), skind, "Trans")
			estart[ii]=str2num( StringByKey("Low Energy", sheader, "=") )
			eend[ii]=str2num( StringByKey("High Energy", sheader, "=") )
			estep[ii]=str2num( StringByKey("Energy Step", sheader, "=") )*sign(eend[ii]-estart[ii])
			nsweep[ii]=str2num( StringByKey("Number of Sweeps", sheader, "=") )
			dwell[ii]=str2num( StringByKey("Step Time", sheader, "=") )	//*nsweep[ii]
			Xstart[ii]=str2num( StringByKey("Detector First X-Channel", sheader, "=") )
			Xend[ii]=str2num( StringByKey("Detector Last X-Channel", sheader, "=") )
			Ystart[ii]=str2num( StringByKey("Detector First Y-Channel", sheader, "=") )
			Yend[ii]=str2num( StringByKey("Detector Last Y-Channel", sheader, "=") )
			Epass[ii]=str2num( StringByKey("Pass Energy", sheader, "=") )
			nslice=str2num( StringByKey("Number of Slices", sheader, "=") )
			filesize=round(V_logEOF/1000)
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
		//infowav[1][ii]=skind; infowav[2][ii]=smode[ii]
		infowav[1][ii] = num2str(Epass[ii])+(skind[ii])[0]+(smode[ii])[0]
		infowav[2][ii] ="#"
		infowav[3][ii]=num2str(hv_); infowav[4][ii]="RP";
		 infowav[5][ii]="Theta"; infowav[6][ii]="Phi";infowav[7][ii]="Temp"
		infowav[8][ii]=num2str(Estart[ii]); infowav[9][ii]=num2str(Eend[ii]); 
		infowav[10][ii]=num2str(1E-4*round(1E4*Estep[ii]))
		infowav[11][ii]=num2str(1E-3*round(1E3*dwell[ii])); infowav[12][ii]=num2str(nsweep[ii])
		infowav[13][ii]=num2str(Ystart[ii]); infowav[14][ii]=num2str(Yend[ii]); infowav[15][ii]=num2str(nslice)
		infowav[16][ii]=num2str(filesize)+"K"
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
// if numchar <0, interpret as Last N characters of prefix
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
	if (numchar==1)			// all
		numchar=ipd
	endif
	prefix=SelectString( numchar<0, prefix[0, numchar-1], prefix[ipd+numchar, ipd-1])
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

Proc NamingPrefsSES(ctrlName) : ButtonControl
	String ctrlName
	
	WaveNamePrefsSES( )
End

Proc WaveNamePrefsSES( prefx, namtyp, namnum)
//------------------------
	string prefx=StrVarOrDefault("root:LOOM:prefix","")
	variable namtyp=NumVarOrDefault("root:SES:nametyp",1), namnum=NumVarOrDefault("root:SES:namenum",3)
	prompt prefx, "Manual Wave Name prefix"
	prompt namtyp, "Wave Naming (derived from filename):", popup, "Full Prefix only;First N prefix characters;Last N prefix characters;Manual prefix only;Extension only;Remove . ;Convert . to _;"
	prompt namnum, "Number of prefix characters", popup, "1;2;3;4;5;6;7;8"
	
	silent 1; pauseupdate
	String curr= GetDataFolder(1)
	NewDataFolder/O/S root:SES
		string/G prefix=prefx
		Variable/G nametyp=namtyp, namenum=namnum
	SetDataFolder curr
	
	root:SES:filnam=root:SES:filnam		// prompt wvnam global update
End

Function/T WaveNameSES( filenam )
//==================
//Options:
//  prefix, "Wave Name prefix"
//  namtyp,  "Full Prefix only;First N prefix characters;Last N prefix characters;Extension only;Remove . ;Convert . to _;"
//  namnum, "Number of prefix characters", popup, "1;2;3;4;5;6;7;8"
	string filenam
	
	//SVAR prefix0=root:SES:prefix 
	SVAR skind=root:SES:skind
	NVAR nametyp=root:SES:nametyp, namenum=root:SES:namenum
	//print skind, nametyp, namenum

	string prefix="", ext=""
	//prefix0=skind[0]
	//print prefix0
	variable ipd=strsearch(filenam,".",0)
	if (ipd<0)					//no period found
		ipd=strlen(filenam)
		prefix=filenam
		ext=""
	else
		prefix=filenam[0, ipd-1]
		ext=filenam[ipd+1,strlen(filenam)-1]
	endif
	
	//string basenam=prefix0, wvnam
	string basenam=skind[0], wvnam
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
	
	variable ihyphen=strsearch(basenam,"-", 0)		//works for only one occurence of "-"
	if (ihyphen>=0)
		basenam[ihyphen,ihyphen]="_"
	endif
	
	return basenam
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

Proc LoadSESb_ShowInfo(wvn, opt)
//-----------------
	string wvn=root:SES:filnam+"_info"
	variable opt
	prompt wvn, "SES file info wave", popup, WaveList("*_info",";","")
	prompt opt, "Display option", popup, "New Table;Append to topmost Table"
	if (opt==1)
		if (exists("root:SES:infonam")==0)
			//make/N=18/T/O root:SES:infonam
			List2Textw("filename,mode,slit,(hv),(R.P.),(Theta),(Phi),T(K),Ei,Ef,Estep,dwell,# sweep,Astart,Ainc,nslice,size,flux", ",", "root:SES:infonam")
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

Proc LoadSESb_SummarizeFolder( pathnam )
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
//	Notebook $Nbknam, fSize=9, margins={0,0,10.0*j }, backRGB=(65535,65534,49151), fStyle=1, showruler=0
	Notebook $Nbknam, fSize=9, margins={0,0,11.0*j }, backRGB=(60681,65535,65535), fStyle=1, showruler=1, pageMargins={28,54,28,54}
	Notebook $Nbknam, tabs={0.1*j,1.1*j,1.6*j, 2.0*j,2.4*j,2.9*j,3.5*j,3.9*j,4.5*j,5*j, 5.5*j, 6.0*j,6.5*j,7*j,7.5*j,8*j,8.5*j,9*j,9.5*j}
	Notebook $Nbknam, fstyle=1, text="\tfilename\tmode\tslit\thv\tR.P.\tTheta\tPhi\tT(K)\tEi\tEf\tEstep\tdwell\tnswp\tAi\tAinc\tnslice\tSize"

	string fnam, infostr
	variable ii=0
	DO
		fnam=StrFromList(filelst, ii, ";")
		ReadSESHdr( pathnam, fnam )
		//print Textw2List(root:SES:infowav, "", 0, 18)
		//root:SES:infowav[2] = root:SES:infowav[6]+(root:SES:infowav[1])[0]+"#"+(root:SES:infowav[2])[0]
		infostr="\r\t"+Textw2List(root:SES:infowav, "\t", 0, 16)
		NoteBook $Nbknam, fstyle=0, text=infostr			//SESInfoB()
		
		ii+=1
	WHILE(ii<numfil)

End


Proc SES_XPS_Style(xlabel, ylabel) : GraphStyle
//------------------------
	string xlabel="Binding Energy (eV)", ylabel="Intensity (kHz)"
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z rgb[1]=(0,0,65535),rgb[2]=(3,52428,1),rgb[3]=(0,0,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=2
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=7,lblMargin(bottom)=4
	ModifyGraph/Z lblLatPos(bottom)=-1
	ModifyGraph/Z axThick=0.5
	Label/Z left ylabel
	Label/Z bottom xlabel
EndMacro

//********  Load Panel ***************

Proc LoadSESb_ShowPanel()
//-----------------
	DoWindow/F Load_SESb_Panel
	if (V_flag==0)
		LoadSESb_Init()
		LoadSESb_Panel()	
			
		//Resize Panel (OS specific)
		string os=IgorInfo(2)
		if (stringmatch(os[0,2],"Win"))
			MoveWindow/W=LoadSESb_Panel 633,62,805,515
		else	   //Mac
			MoveWindow/W=LoadSESb_Panel 676,67,911,600
		endif
	endif
End

Proc LoadSESb_ShowPanel0()
//-----------------
	DoWindow/F Load_SESb_Panel
	if (V_flag==0)
		LoadSESb_Init()
		LoadSESb_Panel()	
			
		//Resize Panel (OS specific)
		string os=IgorInfo(2)
		if (stringmatch(os[0,2],"Win"))
			MoveWindow/W=Load_SESb_Panel 633,62,805,415
		else	   //Mac
			MoveWindow/W=Load_SESb_Panel 676,67,911,500
		endif
	endif
End

Proc LoadSESb_Init()
//-----------------
	NewDataFolder/O/S root:SES
	
		make/o/N=(5,2)/T fileListw		// for ListBox
		make/o/N=(5,2,2) fileSelectw
		Make/O/W/U fileColors= {{0,0,0},{43690,43690,43690},{0,0,0},{65535,0,0},{0,0,65535}}
		//Make/O/W/U fileColors= {{65535,65535,65535},{65535,0,0},{0,0,65535},{0,65535,65535}}
		//Make/O/W/U fileColors= {{52428,52428,52428},{65535,0,0},{0,0,65535},{0,65535,65535}}
		MatrixTranspose fileColors
	
		string/G filpath, filnam, fileList
		if (exists("folderList")!=2)
			string/G folderList="Select New Folder;Summarize Folder;-;"
		endif
		variable/G  filnum, numfiles, nregion, nslice
		Make/O/N=(20) Estart, Eend, Estep, Epass
		Make/O/N=(20) Xstart, Xend, Ystart, Yend
		string/G skind, smode0
		string/G LoadArrNam
		string/G wvnam, prefix=""
		//variable/G nametyp=1, namenum=3
		string/G nameopt="/B"
		variable/G hv_, wfct, angoffset1, angoffset2, dscale, escale
		variable/G autoload=0, NumDim=1
		string/G srebin="1,1"
		List2Textw("filename,mode,slit,(hv),(R.P.),(Theta),(Phi),T(K),Ei,Ef,Estep,dwell,# sweep,Astart,Ainc,nslice,size,flux", ",", "root:SES:infonam")
		make/o/n=(19)/T infowav
		make/o/n=(20) data1D
		make/o/n=(20,20) data2D
		
		//	base=ExtractNameB( base, namtyp, namnum )   // need to put in loop for multiple regions
		//base=root:SES:skind[0]+base
		SetDimLabel 2,1,foreColors,fileSelectw
		//wvnam:=WaveNameSES( filnam )
	SetDataFolder root:
End

Window LoadSESb_Panel() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:SES:
	Display /W=(697,95,932,628) data1D as "LoadSESb_Panel"
	AppendImage/T/R data2D
	ModifyImage data2D ctab= {*,*,Grays,0}
	SetDataFolder fldrSav0
	ModifyGraph cbRGB=(64512,62423,1327)
	ModifyGraph mirror=0
	ModifyGraph fSize=8
	ModifyGraph axOffset(right)=-1.6,axOffset(top)=-0.8
	Label top " "
	TextBox/N=text0/F=0/S=3/H=14/A=MT/E "\\{root:SES:filnam}: \\{root:SES:infowav[1]}, \\{root:SES:filesize}K"
	ControlBar 311
	GroupBox header,pos={8,120},size={221,84}
	GroupBox prefs,pos={9,209},size={218,71}
	PopupMenu popFolder,pos={11,1},size={94,20},proc=LoadSESb_SelectFolder,title="Data Folder"
	PopupMenu popFolder,mode=0,value= #"root:SES:folderList"
	SetVariable setlib,pos={7,24},size={225,15},title=" ",value= root:SES:filpath
	PopupMenu popup_file,pos={54,285},size={150,20},proc=LoadSESb_SelectFile,title="File"
	PopupMenu popup_file,mode=4,popvalue="Sr4310_0003.pxt",value= #"root:SES:fileList"
	Button FileUpdate,pos={146,3},size={50,16},proc=LoadSESb_UpdateFolder,title="Update"
	ListBox listSESfiles,pos={8,40},size={170,75},proc=LoadSESb_SelectFileLB,frame=4
	ListBox listSESfiles,listWave=root:SES:fileListw,selWave=root:SES:fileSelectw
	ListBox listSESfiles,colorWave=root:SES:fileColors,row= 1,mode= 4,widths={70,35}
	SetVariable val_kind,pos={21,124},size={61,15},title=" ",value= root:SES:skind
	SetVariable val_mode,pos={95,124},size={44,15},title=" ",value= root:SES:smode0
	ValDisplay val_Ep,pos={156,124},size={50,14},title="Ep"
	ValDisplay val_Ep,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Epass[0]"
	ValDisplay val_Estart,pos={14,144},size={59,14},title="Ei"
	ValDisplay val_Estart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estart,value= #"root:SES:Estart[0]"
	ValDisplay val_Eend,pos={77,144},size={59,14},title="Ef"
	ValDisplay val_Eend,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Eend[0]"
	ValDisplay val_Estep,pos={149,143},size={68,14},title="Einc"
	ValDisplay val_Estep,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Estep[0]"
	ValDisplay val_nslice,pos={146,163},size={66,14},title="# slice"
	ValDisplay val_nslice,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nslice"
	ValDisplay val_Nreg,pos={15,184},size={60,14},title="# region"
	ValDisplay val_Nreg,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nregion"
	SetVariable set_hv,pos={19,214},size={75,15},proc=LoadSESb_SetVar,title="hv"
	SetVariable set_hv,value= root:SES:hv_
	Button StepMinus,pos={87,256},size={20,18},proc=LoadSESb_StepFile,title="<<"
	Button StepPlus,pos={113,257},size={20,18},proc=LoadSESb_StepFile,title=">>"
	Button PlotButton1,pos={26,255},size={55,20},proc=PlotSES,title="Display"
	Button PlotButton2,pos={144,256},size={55,20},proc=PlotSES,title="Append"
	ValDisplay val_Astart,pos={14,163},size={55,14},title="Ai"
	ValDisplay val_Astart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Astart,value= #"root:SES:Ystart[0]"
	ValDisplay val_Aend,pos={79,164},size={55,14},title="Af"
	ValDisplay val_Aend,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Yend[0]"
	ValDisplay val_dwell,pos={152,183},size={59,14},title="dwell"
	ValDisplay val_dwell,limits={0,0,0},barmisc={0,1000},value= #"root:SES:dwell[0]"
	ValDisplay val_nswp,pos={85,183},size={59,14},title="nswp"
	ValDisplay val_nswp,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nsweep[0]"
	SetVariable wvnam,pos={22,236},size={120,15},title=" ",value= root:SES:wvnam
	Button PlotPrefs,pos={164,233},size={40,18},proc=PlotSESb_prefb,title="Prefs"
	SetVariable img_rebin,pos={117,215},size={90,15},title=" Img Rebin"
	SetVariable img_rebin,value= root:SES:srebin
	TitleBox version,pos={204,2},size={21,12},title="v2.0",fSize=9,frame=0,fStyle=2
EndMacro


Window Load_SESb_Panel() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:SES:
	Display /W=(673,85,914,497) data1D as "Load_SESb_Panel"
	AppendImage/T/R data2D
	ModifyImage data2D ctab= {*,*,Grays,0}
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(64512,62423,1327)
	ModifyGraph mirror=0
	ModifyGraph fSize=8
	ModifyGraph axOffset(right)=-1.6,axOffset(top)=-0.8
	Label top " "
	TextBox/N=text0/F=0/S=3/H=14/A=MT/E "\\{root:SES:filnam}: \\{root:SES:infowav[1]}, \\{root:SES:filesize}K"
	ControlBar 231
	GroupBox header,pos={8,67},size={221,84}
	GroupBox prefs,pos={9,156},size={218,71}
	PopupMenu popFolder,pos={11,1},size={94,20},proc=LoadSESb_SelectFolder,title="Data Folder"
	PopupMenu popFolder,mode=0,value= #"root:SES:folderList"
	SetVariable setlib,pos={7,24},size={225,15},title=" ",value= root:SES:filpath
	PopupMenu popup_file,pos={10,44},size={120,20},proc=LoadSESb_SelectFile,title="File"
	PopupMenu popup_file,mode=26,popvalue="uge026.pxt",value= #"root:SES:fileList"
	Button FileUpdate,pos={178,44},size={50,16},proc=LoadSESb_UpdateFolder,title="Update"
	SetVariable val_kind,pos={21,71},size={61,15},title=" ",value= root:SES:skind
	SetVariable val_mode,pos={95,71},size={44,15},title=" ",value= root:SES:smode0
	ValDisplay val_Ep,pos={156,71},size={50,14},title="Ep"
	ValDisplay val_Ep,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Epass[0]"
	ValDisplay val_Estart,pos={14,91},size={59,14},title="Ei"
	ValDisplay val_Estart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estart,value= #"root:SES:Estart[0]"
	ValDisplay val_Eend,pos={77,91},size={59,14},title="Ef"
	ValDisplay val_Eend,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Eend[0]"
	ValDisplay val_Estep,pos={149,90},size={68,14},title="Einc"
	ValDisplay val_Estep,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Estep[0]"
	ValDisplay val_nslice,pos={146,110},size={66,14},title="# slice"
	ValDisplay val_nslice,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nslice"
	ValDisplay val_Nreg,pos={15,131},size={60,14},title="# region"
	ValDisplay val_Nreg,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nregion"
	SetVariable set_hv,pos={19,161},size={75,15},proc=LoadSESb_SetVar,title="hv"
	SetVariable set_hv,value= root:SES:hv_
	Button StepMinus,pos={87,203},size={20,18},proc=LoadSESb_StepFile,title="<<"
	Button StepPlus,pos={113,204},size={20,18},proc=LoadSESb_StepFile,title=">>"
	Button PlotButton1,pos={26,202},size={55,20},proc=PlotSES,title="Display"
	Button PlotButton2,pos={144,203},size={55,20},proc=PlotSES,title="Append"
	ValDisplay val_Astart,pos={14,110},size={55,14},title="Ai"
	ValDisplay val_Astart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Astart,value= #"root:SES:Ystart[0]"
	ValDisplay val_Aend,pos={79,111},size={55,14},title="Af"
	ValDisplay val_Aend,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Yend[0]"
	ValDisplay val_dwell,pos={152,130},size={59,14},title="dwell"
	ValDisplay val_dwell,limits={0,0,0},barmisc={0,1000},value= #"root:SES:dwell[0]"
	ValDisplay val_nswp,pos={85,130},size={59,14},title="nswp"
	ValDisplay val_nswp,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nsweep[0]"
	SetVariable wvnam,pos={22,183},size={120,15},title=" ",value= root:SES:wvnam
	Button PlotPrefs,pos={164,180},size={40,18},proc=PlotSESb_prefb,title="Prefs"
	SetVariable img_rebin,pos={117,162},size={90,15},title=" Img Rebin"
	SetVariable img_rebin,value= root:SES:srebin
	TitleBox version,pos={204,2},size={25,14},title="v1.8",fSize=9,frame=0, fstyle=2
	SetDrawLayer UserFront
EndMacro

Window Load_SESb_Panel0() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(713,84,931,364)
	ModifyPanel cbRGB=(64512,62423,1327)
	SetDrawLayer UserBack
	SetDrawEnv fillfgc= (65495,2134,34028)
	DrawRRect 11,39,210,149
	SetDrawEnv fillpat= 5,fillfgc= (65495,2134,34028)
	DrawRRect 12,156,210,248
	PopupMenu popFolder,pos={10,0},size={97,19},proc=LoadSESb_SelectFolder,title="Data Folder"
	PopupMenu popFolder,mode=0,value= #"root:SES:folderList"
	SetVariable setlib,pos={12,21},size={195,14},title=" ",fSize=10
	SetVariable setlib,limits={-Inf,Inf,1},value= root:SES:filpath
	PopupMenu popup_file,pos={14,44},size={145,19},proc=LoadSESb_SelectFile,title="File"
	PopupMenu popup_file,mode=1,popvalue="cerhin-033.pxt",value= #"root:SES:fileList"
	Button FileUpdate,pos={156,45},size={50,16},proc=LoadSESb_UpdateFolder,title="Update"
	SetVariable val_kind,pos={18,71},size={61,14},title=" ",fSize=10
	SetVariable val_kind,limits={-Inf,Inf,1},value= root:SES:skind
	SetVariable val_mode,pos={88,71},size={44,14},title=" ",fSize=10
	SetVariable val_mode,limits={-Inf,Inf,1},value= root:SES:smode0
	ValDisplay val_Ep,pos={142,71},size={50,14},title="Ep",fSize=10
	ValDisplay val_Ep,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Epass[0]"
	ValDisplay val_Estart,pos={14,91},size={59,14},title="Ei",fSize=10
	ValDisplay val_Estart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estart,value= #"root:SES:Estart[0]"
	ValDisplay val_Eend,pos={77,91},size={59,14},title="Ef",fSize=10
	ValDisplay val_Eend,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Eend[0]"
	ValDisplay val_Estep,pos={138,91},size={65,14},title="Einc",fSize=10
	ValDisplay val_Estep,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Estep[0]"
	ValDisplay val_nslice,pos={141,110},size={66,14},title="# slice",fSize=10
	ValDisplay val_nslice,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nslice"
	ValDisplay val_Nreg,pos={20,130},size={60,14},title="# region",fSize=10
	ValDisplay val_Nreg,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nregion"
	PopupMenu popup_Cts,pos={32,161},size={72,19},proc=LoadSESb_SetPop
	PopupMenu popup_Cts,mode=2,popvalue="Cts/Sec",value= #"\"Counts;kCounts;Cts/Sec;kCts/Sec\""
	PopupMenu popup_Escale,pos={130,161},size={40,19},proc=LoadSESb_SetPop
	PopupMenu popup_Escale,mode=1,popvalue="KE",value= #"\"KE;BE\""
	SetVariable set_hv,pos={23,186},size={75,14},proc=LoadSESb_SetVar,title="hv"
	SetVariable set_hv,fSize=10,limits={-Inf,Inf,1},value= root:SES:hv_
	SetVariable set_wfct,pos={108,186},size={80,14},proc=LoadSESb_SetVar,title="wfct"
	SetVariable set_wfct,fSize=10,limits={-Inf,Inf,1},value= root:SES:wfct
	SetVariable set_ang1,pos={16,206},size={85,14},proc=LoadSESb_SetVar,title="Ang1"
	SetVariable set_ang1,fSize=10,limits={-Inf,Inf,1},value= root:SES:angoffset1
	SetVariable set_ang2,pos={107,206},size={85,14},proc=LoadSESb_SetVar,title="Ang2"
	SetVariable set_ang2,fSize=10,limits={-Inf,Inf,1},value= root:SES:angoffset2
	Button StepMinus,pos={74,252},size={20,18},proc=LoadSESb_StepFile,title="<<"
	Button StepPlus,pos={99,252},size={20,18},proc=LoadSESb_StepFile,title=">>"
	Button PlotButton1,pos={14,252},size={55,20},proc=PlotSES,title="Display"
	Button PlotButton2,pos={124,250},size={55,20},proc=PlotSES,title="Append"
	ValDisplay val_Astart,pos={14,110},size={55,14},title="Ai",fSize=10
	ValDisplay val_Astart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Astart,value= #"root:SES:Ystart[0]"
	ValDisplay val_Aend,pos={79,109},size={55,14},title="Af",fSize=10
	ValDisplay val_Aend,limits={0,0,0},barmisc={0,1000},value= #"root:SES:Yend[0]"
	PopupMenu popupPreview,pos={131,0},size={76,19},proc=LoadSESb_SetPreview,title="Preview"
	PopupMenu popupPreview,mode=0,value= #"\"No Preview;Show Preview;Data to ImageTool\""
	ValDisplay val_dwell,pos={147,130},size={59,14},title="dwell",fSize=10
	ValDisplay val_dwell,limits={0,0,0},barmisc={0,1000},value= #"root:SES:dwell[0]"
	ValDisplay val_nswp,pos={85,131},size={59,14},title="nswp",fSize=10
	ValDisplay val_nswp,limits={0,0,0},barmisc={0,1000},value= #"root:SES:nsweep[0]"
	SetVariable wvnam,pos={88,227},size={110,14},title=" ",fSize=10
	SetVariable wvnam,limits={-Inf,Inf,1},value= root:SES:wvnam
	Button WvNamePrefs,pos={23,225},size={55,18},proc=NamingPrefsSES,title="Naming"
EndMacro

Proc SelectSESfolder(ctrlName,popNum,popStr) : PopupMenuControl
//------------
	String ctrlName
	Variable popNum
	String popStr
	
	LoadSES_CheckVersion()
End

Function LoadSES_CheckVersion()
//=====================
	string/G root:SES:version="v2.0"
	SVAR version=root:SES:version
      ControlInfo/W=LoadSES_Panel version
     	string curr_ver=stringbykey("title", S_recreation,"=",",")
     	curr_ver=StringFromList(0, curr_ver, "\r")
      print "Current Panel version = " + curr_ver+";  Newest Panel version = "+version
	if (stringmatch(curr_ver, "\""+version+"\"")==0)
	      string alertstr="Using old version of LoadSESb_Panel ("+curr_ver+")."
	      alertstr+="\rNeed to close and reopen Panel ("+version+"). "
	      alertstr+="\r(This will preserve data folder list.)"
	      alertstr+="\rDO IT NOW?"
	      DoAlert 1, alertstr
	      if (V_flag==1)		//Yes
	      		DoWindow/K LoadSESb_Panel
	      		DoWindow/K Load_SESb_Panel
	      		execute "LoadSES_ShowPanel()"
	      endif
      endif
End


Proc LoadSESb_SelectFolder(ctrlName,popNum,popStr) : PopupMenuControl
//-------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate
	SetDataFolder root:SES:
	string fullfileList
	if (popNum==2)						//print "Summarize Folder"
		LoadSESb_SummarizeFolder(filpath)
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
		fullfileList=IndexedFile( SESdata, -1, "????")	
		fileList=fullfileList
		filelist=ReduceList( filelist, "!*.txt" )  // screen out extensions not desired
		numfiles=ItemsInList( fileList, ";")
		numfiles= List2Textw(fileList, ";","fileListw")
		Redimension/N=(numfiles,2) fileListw
		Redimension/N=(numfiles,2,2) fileSelectw
		//string fileTypeList=
		//SetDimLabel 2,1,foreColors,fileSelectw
		//fileListw[][1]="-CM"[ SpecTypeSES( filpath, fileListw[p][0]) ]
		fileListw[][1]=num2str( FileSizeSES( filpath, fileListw[p][0]) )+" K"
		fileSelectw[][][%forecolors]=SpecTypeSES( fileListw[p][0])+1
	endif
	SetDataFolder root:
	// Update filelist menu and reset to first file
	PopupMenu popup_file value=root:SES:fileList, mode=1
	//LoadSESb_SelectFile("",1,"")
End

Function SpecTypeSES( filnam )
//==================
// 0=other, 1=.pxt (packed Igor experiment), 2=.dat  (SES work file format), 3=.txt (dat summary)
	string filnam

	variable stype=0
	if (stringmatch( filnam[strlen(filnam)-4,inf], ".pxt")==1)
		stype=1
	endif
	if (stringmatch( filnam[strlen(filnam)-4,inf], ".dat")==1)
		stype=2
	endif
	if (stringmatch( filnam[strlen(filnam)-4,inf], ".txt")==1)
		stype=3
	endif
	return stype
End


Function FileSizeSES( filpath, filnam )
//==================
// 0=blank (aborted scan), 1=C (channeltron), 2=M (Mott)
	string filpath, filnam

	//variable stype=1
	//execute "GetFileFolderInfo/Q/Z/P="+filpath+" "+ filnam
	GetFileFolderInfo/Q/Z filpath+ filnam
	//NVAR V_logEOF=V_logEOF
	//print V_logEOF, filpath, filnam
	//stype=SelectNumber( V_logEOF<4000, stype, 0)
	//stype=SelectNumber( V_logEOF>10000, stype, 2)
	//return stype
	return round( V_logEOF/1000 )
End


Proc LoadSESb_UpdateFolder(ctrlName) : ButtonControl
//-----------------------
	String ctrlName

	SetDataFolder root:SES:
	
	fileList=IndexedFile( SESdata, -1, ".pxt")	
	//filelist=ReduceList( fullfilelist, "*.pxt" )
	numfiles=ItemsInList( fileList, ";")
	numfiles=List2Textw(fileList, ";","fileListw")
	Redimension/N=(numfiles,1,2) fileSelectw
	Redimension/N=(numfiles,2,2) fileSelectw
	PopupMenu popup_file value=root:SES:fileList		//#"root:SES:fileList"
	
	LoadSESb_StepFile("StepPlus") 		// increment file selection to next (N+1)
	
	SetDataFolder root:
End



Proc LoadSESb_SelectFile(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr

	root:SES:filnum=popNum
	//root:SES:filnam=popStr
	root:SES:filnam=StringFromList(root:SES:filnum-1, root:SES:fileList, ";")
	string/G root:SES:wvnam=root:SES:skind[0]+ExtractName( root:SES:filnam, root:SES:nameopt )
	ListBox listSESfiles selRow=popNum-1, row=max(0,popNum-3)
	
	
	variable datatyp=SpecTypeSES( root:SES:filnam )
	IF (datatyp==1)		// .pxt
		ReadSESHdr( root:SES:filpath, root:SES:filnam )
	
		
		//variable autoload=1
		//if (root:SES:autoload>0)				// Preview option
		PauseUpdate; Silent 1
			ReadSESb(0)
	
			string loadwn, curr
			variable nfiles
				curr=GetDataFolder(1)
				SetDataFolder root:SES:Load
				nfiles=itemsinlist( wavelist("*",";",""))
				SetDataFolder $curr
				//print nfiles
			loadwn="root:SES:Load:"+PossiblyQuoteName( GetIndexedObjName("root:SES:Load",1 ,nfiles-1 ))
			Redimension/S $loadwn
			variable Ndim=WaveDims($loadwn)
			variable/G root:SES:NumDim=Ndim
			string/G root:SES:LoadArrNam=loadwn
			//print loadwn, Ndim
			if (Ndim==1)
				duplicate/o $loadwn root:SES:data1D
				 root:SES:data2D=nan
			endif
			if (Ndim==2)    
				if ( root:SES:autoload==2 )		// Pipeline to data to Image_Tool
					DoWindow/F ImageTool
					if (V_flag==1)
						NewImg( loadwn )
						DoWindow/F Load_SESb_Panel
					endif	
					//root:SES:data1D=nan
					//execute "NewImg( \""+loadwn+"\" )"	// 
				else
					duplicate/o $loadwn root:SES:data2D
					variable nx=DimSize(root:SES:data2D, 0) , ny=DimSize(root:SES:data2D, 1)
					Redimension/N=(nx) root:SES:data1D
					CopyScales root:SES:data2D, root:SES:data1D
					root:SES:data1D=root:SES:data2D[p][ny/2]
				endif
			endif
			if (Ndim==3)
				if ( root:SES:autoload==2 )
					DoWindow/F ImageTool
					if (V_flag==1)
						NewImg( loadwn )
						DoWindow/F Load_SESb_Panel
					endif	
				endif
				root:SES:data1D=Nan
				root:SES:data2D=Nan
				print "nz=", DimSize( $loadwn, 2)
			endif
		ELSE
		IF (datatyp==2)		// .dat
			//print "file type = *.dat "
				ReadSESDhdr( root:SES:filpath, root:SES:filnam )

			//variable autoload=1
			//if (root:SES:autoload>0)				// Preview option
			PauseUpdate; Silent 1
			ReadSESDdat(0)
			string loadwn="root:SESdat:wdatafull"
				if (WaveDims($loadwn)==1)
					duplicate/o $loadwn root:SES:data1D
					 root:SES:data2D=nan
				endif
				if (WaveDims($loadwn)==2)    
					if ( root:SES:autoload==2 )		// Pipeline to data to Image_Tool
						DoWindow/F ImageTool
						if (V_flag==1)
							NewImg( loadwn )
							DoWindow/F LoadSESD_Panel
						endif	
						//root:SES:data1D=nan
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
							DoWindow/F LoadSESD_Panel
						endif	
					endif
				endif
		ELSE
			print "file type = not *.pxt or *.dat "
		ENDIF
		ENDIF
	//endif
End

Function TestLB(ctrlName,row,col,event) : ListBoxControl
//====================
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end
	print "event=", event, "row=", row	
End

Function LoadSESb_SelectFileLB(ctrlName,row,col,event) : ListBoxControl
//====================
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
					//5=cell select with shift key, 6=begin edit, 7=end
	//print "event=", event, "row=", row		
	PauseUpdate; Silent 1
	if ((event==4)) //+(event==10))    // mouse click or arrow up/down or 10=cmd ListBox
		NVAR filnum=root:SES:filnum
		SVAR filnam=root:SES:filnam, filpath=root:SES:filpath
		WAVE/T fileListw=root:SES:fileListw
		filnum=row
		filnam=fileListw[ row ]
		PopupMenu popup_file mode=row+1
		SVAR wvnam=root:SES:wvnam, skind=root:SES:skind, nameopt=root:SES:nameopt
		wvnam=skind[0]+ExtractName( filnam, nameopt )
		//print wvnam
		//root:SES:filnum=row
		//root:SES:filnam=root:fileListw[ row ]
//		PopupMenu popup_file mode=row+1
		//ReadSESHdr( root:SES:filpath, root:SES:filnam )
		
		variable datatyp=SpecTypeSES( filnam )
		IF (datatyp==1)		// .pxt
		
			ReadSESHdr( filpath, filnam )
			
				PauseUpdate; Silent 1
			ReadSESb(0)
	
			string loadwn, curr
			variable nfiles
				curr=GetDataFolder(1)
				SetDataFolder root:SES:Load
				nfiles=itemsinlist( wavelist("*",";",""))
				SetDataFolder $curr
				//print nfiles
			loadwn="root:SES:Load:"+PossiblyQuoteName( GetIndexedObjName("root:SES:Load",1 ,nfiles-1 ))
			Redimension/S $loadwn
			variable Ndim=WaveDims($loadwn)
			variable/G root:SES:NumDim=Ndim
			string/G root:SES:LoadArrNam=loadwn
			//print loadwn, Ndim
			NVAR autoload=root:SES:autoload
			WAVE data1D=root:SES:data1D, data2D=root:SES:data2D
			if (Ndim==1)
				duplicate/o $loadwn data1D
				data2D=nan
			endif
			if (Ndim==2)    
				if ( autoload==2 )		// Pipeline to data to Image_Tool
					DoWindow/F ImageTool
					if (V_flag==1)
						NewImg( loadwn )
						DoWindow/F LoadSESb_Panel
					endif	
					//root:SES:data1D=nan
					//execute "NewImg( \""+loadwn+"\" )"	// 
				else
					duplicate/o $loadwn data2D
					variable nx=DimSize(data2D, 0) , ny=DimSize(data2D, 1)
					Redimension/N=(nx) data1D
					CopyScales data2D, data1D
					data1D=data2D[p][ny/2]
				endif
			endif
			if (Ndim==3)
				if ( autoload==2 )
					DoWindow/F ImageTool
					if (V_flag==1)
						NewImg( loadwn )
						DoWindow/F LoadSESb_Panel
					endif	
				endif
				data1D=Nan
				data2D=Nan
				print "nz=", DimSize( $loadwn, 2)
			endif
		
		ELSEIF (datatyp==2)		// .dat
				print "file type = *.dat "
		ELSE
			print "file type = not *.pxt or *.dat "
		ENDIF
	endif

	return row
End


Function LoadSESb_StepFile(ctrlName) : ButtonControl
//====================
	String ctrlName
	NVAR filnum=root:SES:filnum, numfiles=root:SES:numfiles
	string filnam
	if (cmpstr(ctrlName,"StepMinus")==0)
		filnum=max(1, filnum-1)
	endif
	if (cmpstr(ctrlName,"StepPlus")==0)
		filnum=min(numfiles, filnum+1)
	endif
	SVAR fileList=root:SES:fileList
	WAVE fileListw=root:SES:fileListw
	filnam=StringFromList( filnum-1, fileList, ";")
	//filnam=fileListw[ filnum-1 ]
	PopupMenu popup_file mode=filnum
	ListBox listSESfiles selRow=filnum-1, row=max(0,filnum-3)
	print filnam, filnum
	DoUpdate						//** 10/13/03
	string cmd="LoadSESb_SelectFile( \"\", "+num2str(filnum)+", \""+filnam+"\" )"
	//print cmd
	execute cmd
	//LoadSESb_SelectFileLB( "", filnum-1, 1,1 )
	//TestLB( "", filnum-1, 1,1 )
End


Proc LoadSESb_SetPop(ctrlName,popNum,popStr) : PopupMenuControl
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

Proc LoadSESb_SetVar(ctrlName,varNum,varStr,varName) : SetVariableControl
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
	
	if (cmpstr(ctrlName,"PlotButton3")==0)	// pipeline to ImageTool
		if (root:SES:NumDim==1) 
			abort
		endif
		string arrnam="root:SES:data2D"
		if (root:SES:NumDim==3)
			//arrnam="root:SES:Load:"+PossiblyQuoteName( GetIndexedObjName("root:SES:Load",1 ,nfiles-1 ))
			arrnam=root:SES:LoadArrNam
		endif
		DoWindow/F ImageTool
		if (V_flag==1)
			NewImg( arrnam )
			DoWindow/F Load_SESb_Panel
		endif	
	else
		variable plotopt=-1							//negative means ReadSESB skips open dialog and uses current filename
		if (cmpstr(ctrlName,"PlotButton2")==0)	//Append
			plotopt=-2
		endif
		//LoadSESb(root:SES:dscale, root:SES:escale, root:SES:hv_, root:SES:wfct, root:SES:angoffset1, root:SES:angoffset2,  root:SES:nametyp, root:SES:namenum, plotopt)
		LoadSESb(root:SES:dscale, root:SES:escale, root:SES:hv_, plotopt)
	endif
End

Function PlotSESnew(ctrlName) : ButtonControl
//=======================
	String ctrlName
	
	SVAR wvnam=root:SES:wvnam
	
	string spec, basenam, ext, opt
	basenam=wvnam
	
	NVAR escale=root:SES:escale, dscale=root:SES:dscale
	NVAR CCchan=root:SES:CCchan, Mottchan=root:SES:Mottchan
	//SVAR CClist=root:SES:CClist, MottList=root:SES:MottList
	//string/G MottList="Sum;4-ML1;5-ML3;6-ML2;7-ML4;8-MR1;9-MR3;10-MR2;11-MR4"
	string MottExt="_MottSum;ML1;ML3;ML2;ML4;MR1;MR3;MR2;MR4"
	string plotopt=SelectString(  stringmatch(ctrlName, "Display*"), "/A", "/D")
	string escaleopt=SelectString(  escale==1, "/X", "")
	string dscaleopt=SelectString(  dscale>0, "", "/DS="+num2str(dscale))
	opt=plotopt+escaleopt+dscaleopt

	strswitch( ctrlName)
		case "DisplayCC":				// Display Channeltron spectrum in new window
		case "AppendCC":				// Append Channeltron spectrum to top graph
			spec=SelectString( CCchan>0, "SpectrumGroup1", "SpectrumChannel"+num2str(CCchan))
			ext=SelectString( CCchan>0, "", "_CC"+num2str(CCchan))
//			PlotSES_spec(spec, basenam+ext, opt)
			break
		case "DisplayMott":				// Display Mott spectrum in new window
		case "AppendMott":				// Append Mott spectrum to top graph
//			if (Mottchan==0)
//				CalcMottSum()
//			endif
			spec=SelectString( Mottchan>0, "MottSum", "SpectrumChannel"+num2str(Mottchan+3))
			ext=StringFromList( Mottchan, MottExt)
//			PlotSES_spec(spec, basenam+ext, opt)
			break
		//case "PlotMottAsy":				//Plot Mott Asymmetry Preview
		//	LoadSES_MottAsy("")
		//	break
		case "DisplayMottAsy":			// Create root waves & Plot Asymmetry;
//			CreateMOTTWaves("root:SES:SpectrumChannel", basenam)
			//NVAR ASYoffset=root:SES:ASYoffset, Sherman=root:SES:Sherman, ASYpercent=root:SES:ASYpercent
			//opt=SelectString( ASYoffset==1, "", "/Offset")
			//opt+="/Sherman="+num2str(Sherman)
			//opt+=SelectString( ASYpercent==1, "", "/P")	
//			CalcASY(basenam, ASYcalcopt() )
			
			//NVAR ASYsdev=root:SES:ASYsdev, ASYuniform=root:SES:ASYuniform
			//opt="/SDEV="+num2str(ASYsdev)
			//opt+=SelectString( ASYuniform==1, "", "/U")	
//			DisplayASY(basenam, "Energy (eV)", ASYaxisopt() )
			//SetAxisASY(basenam,  opt)
			break
	endswitch
End

Function PlotSES_Spec( specn, dwn, opt)
//============================
	String specn, dwn, opt

	//options
	//string dwn=KeyStr( "D", opt )
	if (strlen(dwn)==0 )
		dwn = specn			// root directory 
	endif
	
	//source wave in SES folder
	if (stringmatch( specn, "root:SES:*")==0)
		specn =  "root:SES:"+specn
	endif
	WAVE specw=$specn
	
	// create output data wave
	Duplicate/O  specw $dwn			// need root: prefix?
	WAVE dw=$dwn
	
	// Energy Axis:  optional reinterpolate to scaled array(s)
	variable escal=SelectNumber(KeySet("X", opt), 1, 0 ) 
	if (escal==1)	
		// increment varies due to rounding; reinterpolate data after scaling	 (method=2)
		ScaleWave( $dwn, "root:SES:Energy", 0, 2)		// 2 = reinterp method
	else
		Duplicate/O  specw $(dwn+"_x")
	endif
	
	// Data scaling
	string xlbl="Energy (eV)", ylbl="Counts"
	variable dscale, dgain
	if (KeySet("DS", opt) )
		dscale=KeyVal("DS", opt)
		ylbl=StringFromList(dscale, "Counts;kHz;MHz" )
		dgain=str2num( StringFromList(dscale, "1;1E-3;1E-6" ) )
		dw *= dgain
	endif
	
	// Display
	variable plotopt=KeySet("A", opt)		// 0=display, 1=append
	if (plotopt==0)
		if (escal==1)
			Display $dwn
		else
			Display $dwn vs $(dwn+"_x")
		endif	
//		PlotSES_Style( xlbl, ylbl)
		ShowInfo
	else
		DoWindow/F $StringFromList(0, WinList("!*SES*", ";", "Win:1"))
		if (escal==1)
			AppendToGraph $dwn
		else
			AppendToGraph $dwn vs $(dwn+"_x")
		endif
		DoWindow/F LoadSESb_Panel
	endif
End


Proc LoadSESb_SetPreview(ctrlName,popNum,popStr) : PopupMenuControl
//--------------
	String ctrlName
	Variable popNum
	String popStr

	root:SES:autoload=1-root:SES:autoload		// toggle on/off
	if (root:SES:autoload==1)
		PopupMenu popupPreview value="Ã  2D/3D data to ImageTool"
	else
		PopupMenu popupPreview value=" 2D/3D data to ImageTool"
	endif
End

Window SESpreview() : Graph
// ------ not used anymore --- integrated into Load_SESb_Panel
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


