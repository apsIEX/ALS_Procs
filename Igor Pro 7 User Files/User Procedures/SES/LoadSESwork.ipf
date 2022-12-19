// File: LoadSESwork		Created: 10/02 
// Jonathan Denlinger, JDDenlinger@lbl.gov
// 1/1/03  jdd  (v1.1) fix up header read according to "workingfiles.txt"
//                                    rework plot preferences and LoadSESW

#pragma rtGlobals=1		// Use modern global access method.
#include "wav_util"
//#include "list_util"			//ReduceList()

// SES Work .DAT File structure:
// RegionRecord
//     	byte 0, 1-nbyt = nbyt, regionnam[nbyt]	  : ShortString;
//		256 - photon {FP64}     : double;
//		264 - ikinetic {LW4}   : boolean;
//		268 - ifixed {LW4}  : boolean;
//		272 - energy parms[4]  {FP64}   : double;
//  UseRegionDetector  : boolean;
// DetectorRegion     : TDetectorRegion;
//    	340, 341-nbyt = nbyt, skind[nbyt]   LensModeName   : ShortString;
//   LensModeIndex      : integer;
//   PassEnergy         : integer;
//   PassEnergyIndex    : integer;
//   	600, 604 - Epass?, ?? {LW4}
//  Data:
//   	616, 620 - # channels, #slices {LW4}  : integer;
//		624-633 - slice unit string {deg}   : string[10];
//		634  - energyscale [nchan]  {FP64}  :double;
//		634+8*nchan - slicescale [nslice]  {FP64}
//		634+8*nchan+8*nslice - wdata [nchan*nslice]  {FP64}

// specification from workingfiles.txt & GDStypes.txt
//
Specification for working files
-------------------------------

Version 1.1 : Ses-1.1.5 : 2002.03.13
Author: Henrik Ohman <henrik.ohman@gammadata.se>

Use this specification to write your own routines to save and or display
spectra. Examples of how it can be implemented can be found in
'ses-exe\Sequence.pas' in the SaveSpectrum procedure.

region<i>.nfo - saved in Ses.exe : Sequence.pas : TSequence.RegionReady()

  filenameslength : integer;    // length of upcoming string
  filenames       : string;     // comma separated string of file names
  sweep           : integer;    // the sweep number for this region
  positions       : integer;    // number of positions - used in (2)
  points 	  : integer;    // number of points - used in (1) and (2)
  positionunit    : string[10]; // scale unit for positions
  pointunit       : string[10]; // scale unit for points
  positionscale   : array [0..positions-1] of double;
  pointscale      : array [0..points-1] of double;

region<i>[-<j>[-<k>]].dat - saved in SESInstrument.dll when a region is finished.

  regionrecord  : TRegionRecord; //the record for the region
  channels      : integer;	 //number of channels
  slices        : integer;	 //number of slices
  sliceunit     : string[10];	 //(mm|deg|..)
  energyscale   : array [0..channels-1] of double;
  slicescale    : array [0..slices-1] of double;
  Data          : array [0..slices-1][0..channels-1] of double;
  
 TRegionRecord = record
    Name               : ShortString;
    ExcEnergy          : double;
    Kinetic            : boolean;
    Fixed              : boolean;
    MinEnergy          : double;
    MaxEnergy          : double;
    EnergyStep         : double;
    StepTime           : double;
    UseRegionDetector  : boolean;
    DetectorRegion     : TDetectorRegion;
    LensModeName       : ShortString;
    LensModeIndex      : integer;
    PassEnergy         : integer;
    PassEnergyIndex    : integer;
    DriftRegion        : boolean;
  end;
  PRegionRecord = ^TRegionRecord;
  
 TDetectorRegion = record
    FirstXChannel    : integer;
    LastXChannel     : integer;
    FirstYChannel    : integer;
    LastYChannel     : integer;
    NOSlices         : integer;
    ADCMode          : boolean;
    ADCMask          : integer;
    DiscLvl          : integer;
  end;
  PDetectorRegion = ^TDetectorRegion;




//Function/T ReadSESWhdr(fpath, fnam) -- .dat header
//Function/T ReadSESWdat(idialog) -- read data to wdata
//Function/T ReadSESWnfo(idialog) -- return filelist string
//Function ReadSESW(idialog)  -- read all .dat in folder (or list in .nfo) to wdatafull
//Function UpdateSESW(idialog) -- append additional nslices to wdatafull


Proc PlotSESWb(ctrlName) : ButtonControl
//---------------------
	String ctrlName
	
	string plotopt=""
	if (cmpstr(ctrlName,"Display")==0)
		plotopt="/D"
	endif
	if (cmpstr(ctrlName,"Append")==0)
		plotopt="/A"
	endif
	LoadSESW(plotopt)
End

Proc PlotSESWprefb(ctrlName) : ButtonControl
	String ctrlName
	PlotSESWprefs()
End

Proc PlotSESWprefs( namopt, dscal,  escal, xscal, imgtool)
//------------------------
	string namopt=StrVarOrDefault("root:SESwork:nameopt","/B")
	variable dscal=NumVarOrDefault("root:SESwork:dscale",4)
	variable escal=NumVarOrDefault("root:SESwork:escale",3)
	variable xscal=NumVarOrDefault("root:SESwork:xscale",2)
	variable imgtool=NumVarOrDefault("root:SESwork:autoload",1)
		prompt namopt, "Wave Naming [/B=n/E/U/P=prefix/S=suffix]"
		prompt dscal, "Data intensity scaling", popup "Counts;kCts;Mcts;Cts/Sec;kHz;MHz"
		prompt escal, "Energy Scale", popup "KE;BE; -BE"
		prompt xscal, "Axis scaling", popup "Y vs X;Y(x)"
		prompt imgtool, "Preview", popup "Standard;2D/3D data to ImageTool"

	String curr= GetDataFolder(1)
	SetDataFolder root:SESwork:
		variable/G dscale=dscal, escale=escal, xscale=xscal, autoload=imgtool
		string/G nameopt=namopt
	
	SetDataFolder $curr
end
	
Proc LoadSESW( plotopt)
//-----------------
// options:
//         (1) wavenam: naming options  {ExtractName():  /B=nch, /E}
//		(2) data scale: Counts (default), kCounts (/1E3), Mcounts(1E6)    {/DS=3,6}
//                                  Cts/Sec, kHz, MHz   (/(Dwell*Nsweep) )                {/Hz}
//         (3) energy scale:  as is (no change - for loading .pxt data)     {/KE, /BE, /BE=-1}
//                                  KE, BE, -BE    (require hv, wfct)
//          (4) plotting:  Display, Append, or none (default) ;   axis labels    {/D, /A or /P=1,2}
//                             1D, 2D, 2D to 3D, 3D
	string plotopt
	prompt plotopt, "Plot option", popup "Display;Append"
	
	silent 1; pauseupdate
	//String curr= GetDataFolder(1)

//	string xlbl="Kinetic Energy (eV)", ylbl="Intensity (arb)"

// (1) wavenam: naming options  {ExtractName():  /B=nch, /E}
	string dwn=ExtractName( root:SESwork:filnam, root:SESwork:nameopt)
	if (strlen(dwn)==0)
		abort 
	endif
	//print "dwn=", dwn
	
	duplicate/o root:SESwork:wdata $("root:"+dwn)
	// Redimension & scaling done in LoadSESW()
	//Redimension/S  $("root:"+dwn)			//convert Unsigned INT32 to FP32 (single precision)
	
// (2) data scaling: Counts (default), kCounts (/1E3), Mcounts(1E6)    {/DS=3,6}
//                             Cts/Sec, kHz, MHz   (/(Dwell*Nsweep) )                {/Hz}
	variable cts=root:SESwork:dscale
	string dlbl=StringFromList( cts-1, "Counts;kCts;Mcts;Cts/sec;kHz;MHz" )
	variable rate=(cts>=4), dscl=mod(cts-1,3)
	if (cts>=4)
		//$dwn/=(root:SESwork:dwell*root:SESwork:nsweep)	
		$dwn/=(root:SESwork:dwell)			//nweeps encoded in to .dat file?
	endif
	if (dscl>0)		// cts-1=1,2 or 4,5 => kilo, mega
		$dwn/=1000^dscl
	endif

//  (3) energy scale:  as is (no change - for loading .pxt data)     {/KE, /BE, /BE=-1}
//                               KE, BE, -BE    (require hv, wfct)
	variable escal=root:SESwork:escale, xscal=root:SESwork:xscale
	variable hv=root:SESwork:ExcEnergy	//, wfct=root:SESwork:Wfct
	string xlbl=StringFromList( escal-1, "Kinetic Energy (eV);Binding Energy (eV);E-EF (eV)" )
	variable eoff=0, Estart=root:SESwork:MinEnergy, Eend=root:SESwork:MaxEnergy
		//if (numtype(wf)==0)		// skip if NaN or INF
		//	eoff=-wf
		//endif
	if (xscal==2)
		if (escal==2)		//+BE
			Estart=hv-Estart;  Eend=hv-Eend; 
		endif
		if (escal==3)		// -BE
			Estart=-hv+Estart;  Eend=-hv+Eend; 
		endif
		SetScale/I x Estart, Eend, "", $dwn
	else						// Y vs X
	
	
	
	endif
	
// (3') add to wavenote the offset
	string txtstr=num2str(root:SESwork:Epass)+root:SESwork:LensMode[0]+root:SESwork:ScanMode[0]
	variable val=root:SESwork:ExcEnergy
	WriteMod($dwn, eoff, 0, 1, 0, 0.5, 0, val, txtstr)


// (4') Determine dimensions of data          1D, 2D, 2D to 3D, 3D		
// check accuracy of nx(enpts) and ny(nslice) variable read from 
	variable nx=DimSize( $dwn, 0), ny0=DimSize( $dwn, 1), nz=DimSize( $dwn, 2)
	variable ny=root:SESwork:nslice
	ny0=SelectNumber( ny0==0, ny0, 1)
	if (ny!=ny0)
		print "ny discrepancy: hdr=", ny, ",  data=", ny0
		ny=ny0
	endif
//  (4) plotting:  Display, Append, or none (default) ;   axis labels    {/D, /A or /P=1,2}
	if (strlen(plotopt)>0)  				//    /D or /A
		IF (ny==1)							// single cycle: plot spectra only
			redimension/N=(nx) $dwn
			if (KeySet("D",plotopt))
				display $dwn				//y vs x option?
				SESW_Style( xlbl, dlbl)
				ModifyGraph axThick=0.5
				ModifyGraph minor(left)=0, nticks(left)=3
			endif
			if (KeySet("A",plotopt))
				DoWindow/F $StringFromList(0, WinList("!*SES*", ";", "Win:1"))	
				append $dwn
				DoWindow/F SESwork_Panel		//helps for double-clicking when appending
			endif
			
		ELSE
			string ylbl=root:SESwork:sliceunit, titlestr=""
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
				titlestr=dwn+": "+num2str(nx)+"x"+num2str(ny)+"="+num2str(nx*ny)
				
			ELSE					// 3D data set
				GetZscaleSESW()					// popup dialog
				SetScale/P z root:SESwork:zstart, root:SESwork:zinc,root:SESwork:zunit, $dwn
				titlestr=dwn+": "+num2str(nx)+"x"+num2str(ny)+"x"+num2str(nz)
			ENDIF
			//print dwn
			if (KeySet("D",plotopt))
				DoWindow/F $(dwn+"_")
				if (V_flag==0)
					display; appendimage $dwn
					Textbox/N=title/F=0/A=MT/E titlestr
					ModifyImage $dwn ctab= {*,*,YellowHot,0}
					Label left ylbl
					Label bottom xlbl
					DoWindow/C $(dwn+"_")
				endif
			endif
			if (KeySet("A",plotopt))		 // Append Image means redimension image/vol array		
				AppendVol( , dwn )
				Killwaves/Z $dwn
			endif
		ENDIF
		
	endif

end

Proc GetZscaleSESW( st, inc, unit )
//-----------------
	variable st=NumVarOrDefault("root:SES:zstart",0), inc=NumVarOrDefault("root:SES:zinc",1)
	string unit=StrVarOrDefault("root:SES:zunit","polar")
	prompt st, "Z start value"
	prompt inc, "Z increment"
	prompt unit, "Z-axis unit"
	variable/G root:SES:zstart=st, root:SES:zinc=inc
	string/G root:SES:zunit=unit
End

Function/T ReadSESWhdr(fpath, fnam)
//=================
// read SES Work binary file header
// saves values in root:SESwork folder variables
	string fpath, fnam
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESwork
	//SetDataFolder root:SESwork:
	String/G filnam=fnam, filpath=fpath
	
	Open/R refnum as filpath+filnam
		FStatus refnum
			if (debug)
				print  S_Filename, ", numbytes=", V_logEOF
			endif

//RegionRecord		
	// Region name	
	variable nbyt, ic, byt
	string/G regionnam=ShortString( refnum )
		
	// Photon energy {FP8}
	variable /G  ExcEnergy		//FSetPos refnum, 256	
	FBinRead /F=5/B=3 refnum, ExcEnergy
	
	// Kinetic & Fixed mode flags  {LW4}
	variable /G  ikinetic, ifixed
	FBinRead /F=3/B=3 refnum, ikinetic
	FBinRead /F=3/B=3 refnum, ifixed			// 0=swept, 1=fixed
	string/G ScanMode=StringFromList(ifixed, "Swept;Fixed")
	
	// Energy Parms {Ei, Ef, Einc, Dwell}  {FP8}
	variable/G MinEnergy, MaxEnergy, EnergyStep, StepTime
	FBinRead/F=5/B=3  refnum, MinEnergy
	FBinRead/F=5/B=3  refnum, MaxEnergy
	FBinRead/F=5/B=3  refnum, EnergyStep
	FBinRead/F=5/B=3  refnum, StepTime
	
	// Region Detector
	variable/g  iRegDetect						//boolean
	FBinRead /F=3/B=3 refnum, iRegDetect	
	// DetectorRegionRecord
	string/G DetRegn=DetectorRegion(refnum)
	
	FSetPos refnum, 340
	// LensMode {Transmission, Angular1, Angular2}
	string/G LensMode=ShortString( refnum )		//FSetPos refnum, 340 +256
	variable /g  LensModeIndex, Epass, EpassIndex, iDrift
	FBinRead /F=3/B=3 refnum, LensModeIndex
	FBinRead /F=3/B=3 refnum, Epass				//FSetPos refnum, 600
	FBinRead /F=3/B=3 refnum, EpassIndex
	FBinRead /F=3/B=3 refnum, iDrift
//End RegionRecord
	//Missing an integer to read?
	//Fstatus refnum
	//Print V_filepos
	FSetPos refnum, 616
	// # (energy) channels & # (angle) slices  {LW4}
	variable /g  nchan, nslice
	FBinRead /F=3/B=3 refnum, nchan		//	FSetPos refnum, 616
	FBinRead /F=3/B=3 refnum, nslice

	// slice unit  string
	string/G sliceunit=""
	sliceunit=PadString("",10,0)
	FBinRead refnum, sliceunit			//FSetPos refnum, 624
			
	Close refnum
	
	//assume one region
	Variable Ystart=0, Yend=1
	make/T/o/n=(18) infowav
		infowav[0]=filnam[0,strlen(filnam)-5]			// strip .DAT
		infowav[1]=LensMode
		infowav[2]=ScanMode
		infowav[3]=num2str(ExcEnergy); infowav[4]="RP"; infowav[5]="Ang"
		infowav[6]=num2str(Epass); infowav[7]="#"
		infowav[8]=num2str(MinEnergy); infowav[9]=num2str(MaxEnergy); 
		infowav[10]=num2str(1E-4*round(1E4*EnergyStep))
		infowav[11]=num2str(1E-3*round(1E3*StepTime)); infowav[12]=num2str(EpassIndex)
		infowav[13]="Temp"
		infowav[14]=num2str(Ystart); infowav[15]=num2str(Yend); 
		infowav[16]=num2str(nslice)
		infowav[17]=sliceunit
				
	SetDataFolder root:
	return filnam
End




Function/T ReadSESWdat(idialog)
//=================
// read SES Work .DAT  binary file
	variable idialog
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESwork
	//SetDataFolder root:SESwork:
	String/G filnam, filpath
	
	if (idialog>0)
		if (cmpstr(Igorinfo(2),"Macintosh")==0)
			Open/R/M="Open .dat file"  refnum				// open file dialog for reading; select from any subfolder
		else
			Open/R/T=".dat" refnum				// avoid default type of .txt on  Windows
		endif
			FStatus refnum
			filnam=S_Filename
			filpath=S_Path
		Close refnum
		if (strlen(filnam)==0)
			return filnam
		endif			
		
		//variable ptr=strsearch(S_path, FolderSep(),strlen(S_path)-11)		// strip off last folder to get library folder path
		//filpath=S_path[0,ptr]
	endif
	//print filpath+", "+filnam
	if (strlen(filnam)==0)
		return ""
	endif	
	
	if (idialog>=0)		//skip header read if idialog<0
		ReadSESWhdr(filpath, filnam)			// already loaded if using panel
	endif
	//SetDataFolder root:
	//return filnam
	//abort
	
	SetDataFolder root:SESwork:
	//SVAR  filnam=filnam
	//SVAR  smode=sMode, skind=sKind
	//NVAR Epass=Epass, Estart=Estart, Eend=Eend, Einc=Einc, Dwell=Dwell, Nsweep=Nsweep
	NVAR nchan=nchan, nslice=nslice
	
	Open/R refnum as filpath+filnam
	//Energy scale
	FSetPos refnum, 634
	Make /o /D/N=(nchan) energyscale
	FBinRead/B=3 refnum, energyscale
	
	//Slice scale
	Make /o/D/N=(nslice) slicescale
	FBinRead/B=3 refnum, slicescale
	
	//Data
	Make /o /D/N=(nchan*nslice) wdata
	FBinRead/B=3 refnum, wdata
	
	Close refnum
	
	//Redimension & scaling
	Redimension/S wdata		//convert to single precision
	Redimension/N=(nchan,nslice) wdata
	NVAR Estart=MinEnergy, Eend=MaxEnergy
	if (idialog>=0)		//skip scaling if idialog<0
		SetScale/I x Estart,Eend,"", wdata
		if (nslice>1)
			WaveStats/Q slicescale
			SetScale/I y V_min,V_max,"", wdata
		endif
	endif
	
	SetDataFolder root:
	return filnam
End

Function/T ReadSESWnfo(idialog)
//=================
	variable idialog
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESwork
	//SetDataFolder root:SESwork:
	String/G filnfo, filpath
	
	if (idialog)
		if (cmpstr(Igorinfo(2),"Macintosh")==0)
			Open/R/M="Open .nfo file" refnum				// open file dialog for reading; select from any subfolder
		else
			Open/R/T=".nfo" refnum				// avoid default type of .txt on  Windows
		endif
			FStatus refnum
			filnfo=S_Filename
			filpath=S_Path
	endif
	//print filpath+", "+filnam
	if (strlen(filnfo)==0)
		return ""
	endif	
	
	//Read filelist
	variable nbyt, ic, byt
	string filelist
	FBinRead/F=3/B=3 refnum, nbyt				// byte
	ic=0
	filelist=""
	DO
		FBinRead/F=1/B=3 refnum, byt
		filelist+=num2char(byt)
		ic+=1
	WHILE(ic<nbyt)	
	//variable/G numfiles =ItemsInList(  filelist, ",")

	Close refnum
	return filelist
End

Function ReadSESW(idialog)
//=================
// read all files in working folder into wdatafull array
	variable idialog
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESwork
	//SetDataFolder root:SESwork:
	String/G filnam, filnfo, filpath
	
	string/G filelst
	string sep=","
	//filelst=ReadSESWnfo(idialog)		// comma-delimited
	sep=";"
	NewPath/O/Q SESwork, filpath
	//NewPath/O/Q/M="Select SES Work Folder" SESwork
	filelst=IndexedFile( SESwork, -1, ".dat")	
	variable/G nfile=ItemsInList(  filelst, sep)
	
	//Read first file; get XY scaling
	filnam=StringFromList(0, filelst, sep)
	if (debug)
		print "0: ", filnam
	endif
	ReadSESWdat(0)
	WAVE wdata=root:SESwork:wdata
	
	// Create full data set
	Duplicate/o wdata, root:SESwork:wdatafull
	WAVE wdatafull=root:SESwork:wdatafull
	if (nfile>1)
		NVAR nchan=root:SESwork:nchan, nslice=root:SESwork:nslice
		//print nchan, nslice, nfile
		Redimension/N=(nchan, nslice, nfile) wdatafull
		variable ii=1
		DO
			filnam=StringFromList(ii, filelst, sep)
			if (debug)
				print ii, filnam
			endif
			ReadSESWdat(-1)				// skip XY scaled
			wdatafull[][][ii]=wdata[p][q]
			ii+=1
		WHILE(ii<nfile)
	endif
	
	//Remove single dimensions
	if (nslice==1)
		if (nfile==1)
	//		Redimension/N=(nchan) wdatafull
		else
	//		Redimension/N=(nchan, nfile) wdatafull
		endif
	endif	
	
	return nfile
End

Function UpdateSESW(idialog)
//=================
	variable idialog
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESwork
	//SetDataFolder root:SESwork:
	String/G filnam, filnfo, filpath
	NVAR nchan=nchan, nslice=nslice
	WAVE wdatafull=wdatafull, wdata=wdata
	
	string/G filelst
	string sep=","
	//filelst=ReadSESWnfo(idialog)
	sep=";"
	NewPath/O/Q SESwork, filpath
	//NewPath/O/Q/M="Select SES Work Folder" SESwork
	filelst=IndexedFile( SESwork, -1, ".dat")	
	variable nfile1=ItemsInList(  filelst, sep)
	NVAR  nfile0=nfile		
	// nfile0 = dimsize( wdatafull, 2)
	
	variable nnewfiles = nfile1-nfile0
	print nnewfiles, nfile1, nfile0
	// Append to full data set
	if (nnewfiles>0)
		Redimension/N=(nchan, nslice, nfile1) wdatafull
		variable ii=nfile0+1
		DO
			filnam=StringFromList(ii, filelst,sep)
			//print filnam
			ReadSESWdat(-1)				// skip XY scaled
			wdatafull[][][ii]=wdata[p][q]
			ii+=1
		WHILE(ii<nfile1)
		NVAR autoload=root:SESwork:autoload
		if ( autoload==1 )
			DoWindow/F ImageTool
			if (V_flag==1)
				Execute( "NewImg( \"root:SESwork:wdatafull\" )" )
				DoWindow/F SESwork_Panel
			endif	
		endif
	endif
	if (nnewfiles<0)
		// read from scratch
		ReadSESW(idialog)
	endif
	nfile0=nfile1
	return nnewfiles
End

Macro ShowSESworkPanel()
//-----------------
	DoWindow/F SESwork_Panel
	if (V_flag==0)
		NewDataFolder/O/S root:SESwork
		string/G filpath, filnam, filelst
		string/G folderList="Select New Folder;-;"
		variable/G  nchan, nslice, nfile, filnum	//, nregion
		variable/G Estart, Eend, Estep, Epass
		//variable/G Xstart, Xend, Ystart, Yend
		string/G skind, smode
		string/G wvnam	, nameopt="/B"			//, prefix=""
		variable/G nametyp=1, namenum=3
		variable/G  dscale=4, escale=3, xscale=2
		variable/G autoload=0
		make/o/n=(18)/T infowav
		make/o/n=(20) data1D
		make/o/n=(20,20) wdata
		
		//	base=ExtractNameB( base, namtyp, namnum )   // need to put in loop for multiple regions
		//base=root:SES:skind[0]+base
		//wvnam:=WaveNameSES( filnam )
		SetDataFolder root:
		
		SESwork_Panel()	
	endif
End

Window SESwork_Panel() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:SESwork:
	Display /W=(660,46,934,464) wdata as "SESwork_Panel"
	AppendImage/T/R wdata
	ModifyImage wdata ctab= {*,*,Grays,0}
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(64512,62423,1327)
	ModifyGraph mirror=0
	ModifyGraph fSize=8
	ModifyGraph axOffset(right)=-1.6,axOffset(top)=-0.8
	Label top " "
	TextBox/N=text0/F=0/S=3/H=14/A=MT/E "\\{root:SESwork:filnam}: \\{root:SESwork:skind}, \\{root:SESwork:smode}"
	ControlBar 222
	PopupMenu popFolder,pos={11,1},size={103,20},proc=SelectFolderSESW,title="Work Folder"
	PopupMenu popFolder,mode=0,value= #"root:SESwork:folderList"
	SetVariable setlib,pos={11,23},size={246,15},title=" ",fSize=9
	SetVariable setlib,value= root:SESwork:filpath
	PopupMenu popup_file,pos={10,44},size={131,20},proc=SelectFileSESW,title="File"
	PopupMenu popup_file,mode=237,popvalue="LV_00030.dat",value= #"root:SESwork:filelst"
	Button FileUpdate,pos={191,47},size={50,16},proc=UpdateFolderSESW,title="Update"
	SetVariable val_kind,pos={18,71},size={62,15},title=" "
	SetVariable val_kind,value= root:SESwork:LensMode
	SetVariable val_mode,pos={88,71},size={44,15},title=" "
	SetVariable val_mode,value= root:SESwork:ScanMode
	ValDisplay val_Ep,pos={142,71},size={50,14},title="Ep"
	ValDisplay val_Ep,limits={0,0,0},barmisc={0,1000},value= #"root:SESwork:Epass"
	ValDisplay val_Estart,pos={14,91},size={59,14},title="Ei"
	ValDisplay val_Estart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estart,value= #"root:SESwork:MinEnergy"
	ValDisplay val_Eend,pos={77,91},size={59,14},title="Ef"
	ValDisplay val_Eend,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Eend,value= #"root:SESwork:MaxEnergy"
	ValDisplay val_Estep,pos={138,91},size={65,14},title="Einc"
	ValDisplay val_Estep,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estep,value= #"root:SESwork:EnergyStep"
	ValDisplay val_nslice,pos={177,130},size={66,14},title="# slice"
	ValDisplay val_nslice,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_nslice,value= #"root:SESwork:nslice"
	SetVariable set_hv,pos={12,109},size={75,15},proc=SetInputVarSES,title="hv"
	SetVariable set_hv,value= root:SESwork:ExcEnergy
	Button StepMinus,pos={79,195},size={20,18},proc=StepFileSESW,title="<<"
	Button StepPlus,pos={105,195},size={20,18},proc=StepFileSESW,title=">>"
	Button Display,pos={18,194},size={55,20},proc=PlotSESWb,title="Display"
	Button Append,pos={131,195},size={55,20},proc=PlotSESWb,title="Append"
	PopupMenu popupPreview,pos={198,196},size={20,20},proc=SetPreviewSESW
	PopupMenu popupPreview,mode=0,value= #"\"  2D/3D data to ImageTool\""
	ValDisplay val_dwell,pos={208,92},size={59,14},title="dwell"
	ValDisplay val_dwell,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_dwell,value= #"root:SESwork:StepTime"
	ValDisplay val_nswp,pos={204,71},size={49,14},title="iEp"
	ValDisplay val_nswp,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_nswp,value= #"root:SESwork:EpassIndex"
	SetVariable wvnam,pos={19,173},size={110,15},title=" ",value= root:SESwork:wvnam
	ValDisplay val_nchan,pos={181,109},size={59,14},title="nchan"
	ValDisplay val_nchan,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_nchan,value= #"root:SESwork:nchan"
	ValDisplay val_nfile,pos={22,146},size={59,14},title="nfile"
	ValDisplay val_nfile,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_nfile,value= #"root:SESwork:nfile"
	SetVariable val_rgnnam,pos={101,110},size={61,15},title=" "
	SetVariable val_rgnnam,value= root:SESwork:regionnam
	ValDisplay version,pos={227,3},size={25,14},title="v1.1",frame=0
	ValDisplay version,limits={0,0,0},barmisc={0,1000}
	Button PlotPrefs,pos={160,171},size={55,20},proc=PlotSESWprefb,title="Prefs"
EndMacro
	//ValDisplay val_Nreg,pos={20,130},size={60,14},title="# region",fSize=10
	//ValDisplay val_Nreg,limits={0,0,0},barmisc={0,1000},value= #"root:SESwork:nregion"
	//SetVariable set_wfct,pos={108,186},size={80,14},proc=SetInputVarSES,title="wfct"
	//SetVariable set_wfct,fSize=10,limits={-Inf,Inf,1},value= root:SES:wfct
	//SetVariable set_ang1,pos={16,206},size={85,14},proc=SetInputVarSES,title="Ang1"
	//SetVariable set_ang1,fSize=10,limits={-Inf,Inf,1},value= root:SES:angoffset1
	//SetVariable set_ang2,pos={107,206},size={85,14},proc=SetInputVarSES,title="Ang2"
	//SetVariable set_ang2,fSize=10,limits={-Inf,Inf,1},value= root:SES:angoffset2
	//SetVariable wvnam,limits={-Inf,Inf,1},value= root:SESwork:wvnam
	//Button WvNamePrefs,pos={23,225},size={55,18},proc=NamingPrefsSES,title="Naming"


Proc SelectFolderSESW(ctrlName,popNum,popStr) : PopupMenuControl
//-------------------
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder root:SESwork:
	//if (popNum==2)						//print "Summarize Folder"
	//	SummarizeSESfolder(filpath)
	//else
		if (popNum==1)						//print "Select Folder"
			NewPath/O/Q/M="Select SES Work Folder" SESwork				//dialog selection
			string/G filpath
			Pathinfo SESwork
			filpath=S_path
			folderList=folderList+filpath+";"
		endif
		if (popNum>2)							//print "Select Existing Folder"
			filpath=StringFromList(popNum-1,folderList)
			//print popNum, filpath
			NewPath/O/Q SESwork filpath
		endif
		filelst=IndexedFile( SESwork, -1, ".dat")	//+IndexedFile( SESwork, -1, ".txt")
		//string fullfilelst=IndexedFile( SESwork, -1, "????")	
		//filelst=ReduceList( fullfilelst, "*.dat" )  //+ReduceList( fullfilelist, "*.txt" )
		nfile=ItemsInList( filelst, ";")
	//endif
	SetDataFolder root:
	// Update filelist menu and reset to first file
	PopupMenu popup_file value=root:SESwork:filelst, mode=1
	SelectFileSESW("",1,"")
	ReadSESW(0)
		if ( root:SESwork:autoload==1 )
			DoWindow/F ImageTool
			if (V_flag==1)
				NewImg( "root:SESwork:wdatafull" )
				DoWindow/F SESwork_Panel
			endif	
		endif
End

Proc SelectFileSESW(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr

	root:SESwork:filnum=popNum
	//root:SES:filnam=popStr
	root:SESwork:filnam=StringFromList(root:SESwork:filnum-1, root:SESwork:filelst, ";")
	string/G root:SESwork:wvnam=ExtractName( root:SESwork:filnam, root:SESwork:nameopt )
	ReadSESWhdr( root:SESwork:filpath, root:SESwork:filnam )
	
	//variable autoload=1
	//if (root:SES:autoload>0)				// Preview option
	PauseUpdate; Silent 1
		ReadSESWdat(0)
	string loadwn="root:SESwork:wdatafull"
		if (WaveDims($loadwn)==1)
			duplicate/o $loadwn root:SES:data1D
			 root:SESwork:data2D=nan
		endif
		if (WaveDims($loadwn)==2)    
			if ( root:SESwork:autoload==2 )		// Pipeline to data to Image_Tool
				DoWindow/F ImageTool
				if (V_flag==1)
					NewImg( loadwn )
					DoWindow/F SESwork_Panel
				endif	
				//root:SES:data1D=nan
				//execute "NewImg( \""+loadwn+"\" )"	// 
			else
				duplicate/o $loadwn root:SESwork:data2D
				variable nx=DimSize(root:SESwork:data2D, 0) , ny=DimSize(root:SESwork:data2D, 1)
				Redimension/N=(nx) root:SESwork:data1D
				CopyScales root:SESwork:data2D, root:SESwork:data1D
				root:SESwork:data1D=root:SESwork:data2D[p][ny/2]
			endif
		endif
		if (WaveDims($loadwn)==3)
			if ( root:SESwork:autoload==2 )
				DoWindow/F ImageTool
				if (V_flag==1)
					NewImg( loadwn )
					DoWindow/F SESwork_Panel
				endif	
			endif
		endif
	//endif
End

Proc StepFileSESW(ctrlName) : ButtonControl
//====================
	String ctrlName
	variable filnum=root:SESwork:filnum
	string filnam
	if (cmpstr(ctrlName,"StepMinus")==0)
		filnum=max(1, root:SESwork:filnum-1)
	endif
	if (cmpstr(ctrlName,"StepPlus")==0)
		filnum=min(root:SESwork:nfile, root:SESwork:filnum+1)
	endif
	filnam=StringFromList( filnum-1, root:SESwork:filelst, ";")
	PopupMenu popup_file mode=filnum
	SelectFileSESW( "", filnum, filnam )
End


Proc UpdateFolderSESW(ctrlName) : ButtonControl
//-----------------------
	String ctrlName

	UpdateSESW(0)
	//SetDataFolder root:SESwork:
	
	//filelst=IndexedFile( SESwork, -1, ".dat")	
	//filelist=ReduceList( fullfilelist, "*.pxt" )
	//nfile=ItemsInList( fileList, ";")
	PopupMenu popup_file value=root:SESwork:filelst		//#"root:SES:fileList"
	
	//StepFileSES("StepPlus") 		// increment file selection to next (N+1)
	//Jump to last slice
	SelectFileSESW( "", root:SESwork:nfile, "" )
	PopupMenu popup_file mode=root:SESwork:nfile
	//SetDataFolder root:
End

Proc SetPreviewSESW(ctrlName,popNum,popStr) : PopupMenuControl
//--------------
	String ctrlName
	Variable popNum
	String popStr

	root:SESwork:autoload=1-root:SESwork:autoload		// toggle on/off
	if (root:SESwork:autoload==1)
		PopupMenu popupPreview value="Ã  2D/3D data to ImageTool"
	else
		PopupMenu popupPreview value=" 2D/3D data to ImageTool"
	endif
End

Function/T WaveNameSESW( filenam )
//==================
//Options:
//  prefix, "Wave Name prefix"
//  namtyp,  "Full Prefix only;First N prefix characters;Last N prefix characters;Extension only;Remove . ;Convert . to _;"
//  namnum, "Number of prefix characters", popup, "1;2;3;4;5;6;7;8"
	string filenam
	
	//SVAR prefix0=root:SES:prefix 
	SVAR skind=root:SESwork:skind
	NVAR nametyp=root:SESwork:nametyp, namenum=root:SESwork:namenum
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



Static Function/T ShortString(refnum)
//=================
// format nbyt, chars 1, nbyt
//  advance file position by 256 total bytes  
	variable refnum
	
	Fstatus refnum		// V_filepos
	variable nbyt
	string str
	FBinRead/F=1/B=3 refnum, nbyt	
	str=PadString("",nbyt,0)		//0= C-style string
	FBinRead refnum, str
	FSetPos refnum, V_filepos+256
	return str
End

Static Function/T DetectorRegion(refnum)
//=================
// TDetectorRegion = record
//    FirstXChannel    : integer;
//    LastXChannel     : integer;
//    FirstYChannel    : integer;
//    LastYChannel     : integer;
//    NOSlices         : integer;
 //   ADCMode          : boolean; (also LW-4 bytes)
//    ADCMask          : integer;
 //   DiscLvl          : integer;
	variable refnum
	
	string varlst="X0;X1;Y0;Y1;Nslices;ADCmode;ADCmask;DiscLvl;"
	variable val, ii=0
	string str=""
	DO
		FBinRead/F=3/B=3 refnum, val	
		str+=StringFromList(ii, varlst)+"="+num2str(val)+";"
		ii+=1
	WHILE(ii<8)
	return str
End

Function/T ReadSESWhdr_old(fpath, fnam)
//=================
// read SES Work binary file header
// saves values in root:SESwork folder variables
	string fpath, fnam
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESwork
	//SetDataFolder root:SESwork:
	String/G filnam=fnam, filpath=fpath
	
	Open/R refnum as filpath+filnam
		FStatus refnum
			if (debug)
				print  S_Filename, ", numbytes=", V_logEOF
			endif

//RegionRecord		
	// Region name	
	variable nbyt, ic, byt
	string/G regionnam
	FBinRead/F=1/B=3 refnum, nbyt				// byte
	ic=0
	regionnam=PadString("",nbyt,0)
	FBinRead refnum, regionnam
	//DO
	//	FBinRead/F=1/B=3 refnum, byt
	//	regionnam+=num2char(byt)
	//	ic+=1
	//WHILE(ic<nbyt)
	
	// Photon energy {FP8}
	FSetPos refnum, 256
	variable /g  photon
	FBinRead /F=5/B=3 refnum, photon
	
	// Kinetic & Fixed mode flags  {LW4}
	variable /g  ikinetic, ifixed
	string/G smode
	FBinRead /F=3/B=3 refnum, ikinetic
	FBinRead /F=3/B=3 refnum, ifixed			// 0=swept, 1=fixed
	smode=StringFromList(ifixed, "Swept;Fixed")
	
	// Energy Parms {Ei, Ef, Einc, Dwell}  {FP8}
	//make /o/N=4 /D energyparms
	//FBinRead/B=3  refnum, energyparms
	variable/G Estart, Eend, Estep, Dwell
	FBinRead/F=5/B=3  refnum, Estart
	FBinRead/F=5/B=3  refnum, Eend
	FBinRead/F=5/B=3  refnum, Estep
	FBinRead/F=5/B=3  refnum, Dwell
	
	// Mode {Transmission, Angular1, Angular2}
		//variable nbyt, ic, byt
	string/G skind
	FSetPos refnum, 340
	FBinRead/F=1/B=3 refnum, nbyt				// byte
	//ic=0
	skind=PadString("",nbyt,0)
	FBinRead refnum, skind
	//DO
	//	FBinRead/F=1/B=3 refnum, byt
	//	skind+=num2char(byt)
	//	ic+=1
	//WHILE(ic<nbyt)
	
	// Epass & nsweep  {LW4}  ??
	FSetPos refnum, 600
	variable /g  Epass, nsweep
	FBinRead /F=3/B=3 refnum, Epass
	Fbinread /F=3/B=3 refnum, nsweep

	// # (energy) channels & # (angle) slices  {LW4}
	FSetPos refnum, 616
	variable /g  nchan, nslice
	FBinRead /F=3/B=3 refnum, nchan
	FBinRead /F=3/B=3 refnum, nslice

	// slice unit  string
	//FSetPos refnum, 624
	string/G sliceunit
	//ic=0; 
	//nbyt=10
	sliceunit=PadString("",10,0)
	FBinRead refnum, sliceunit
	//DO
	//	FBinRead/F=1/B=3 refnum, byt
	//	if (byt==0)
	//		break
	//	else
	//		sliceunit+=num2char(byt)
	//	endif
	//	ic+=1
	//WHILE(ic<nbyt)
			
	Close refnum
	
	//assume one region
	Variable Ystart=0, Yend=1
	make/T/o/n=(18) infowav
		infowav[0]=filnam[0,strlen(filnam)-5]			// strip .DAT
		infowav[1]=skind
		infowav[2]=smode
		infowav[3]=num2str(photon); infowav[4]="RP"; infowav[5]="Ang"
		infowav[6]=num2str(Epass); infowav[7]="#"
		infowav[8]=num2str(Estart); infowav[9]=num2str(Eend); 
		infowav[10]=num2str(1E-4*round(1E4*Estep))
		infowav[11]=num2str(1E-3*round(1E3*dwell)); infowav[12]=num2str(nsweep)
		infowav[13]="Temp"
		infowav[14]=num2str(Ystart); infowav[15]=num2str(Yend); 
		infowav[16]=num2str(nslice)
		infowav[17]=sliceunit
				
	SetDataFolder root:
	return filnam
End

Proc SESW_Style(xlabel, ylabel) : GraphStyle
//------------------------
	string xlabel="Binding Energy (eV)", ylabel="Intensity (kHz)"
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z rgb[1]=(0,0,65535),rgb[2]=(3,52428,1),rgb[3]=(0,0,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=1
	ModifyGraph/Z mirror(left)=2
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=7,lblMargin(bottom)=4
	ModifyGraph/Z lblLatPos(bottom)=-1
	Label/Z left ylabel
	Label/Z bottom xlabel
EndMacro

	