// File: LoadSESdat		Modified from LoadSESwork: 1/28/05 
// Jonathan Denlinger, JDDenlinger@lbl.gov
//
//   future prompt for Z-scaling or read from .txt file
//  9/18/05  JD  Added Deglitch, Transpose & Rebin checkboxes on panel for during DAT file loading 
// 		--globals variables for remembering options & popup for deglitch settings 
//   2/6/05  fix "+1" index bug in updating folder
//  1/28/05 jdd (v1.2)  new file format for Work Folder files for SES v 1.2.2
// 1/1/03  jdd  (v1.1) fix up header read according to "workingfiles.txt"
//                                    rework plot preferences and LoadSESD


#pragma rtGlobals=1		// Use modern global access method.
#include "wav_util"
//#include "list_util"			//ReduceList()

Menu "Macros"
	"-"
	num2char(19)+" Load SES DAT Panel", ShowSESdatPanel()
End

// From:   workingfiles.txt  (1.2.2r1, 1/28/05):
//    variable        size                type
    Region          192                 TRegionRec
    Channels        4                   integer
    Slices          4                   integer
    Sweeps          4                   integer
    CountUnit       32                  array [0..31] of char;
    ChannelUnit     32                  array [0..31] of char;
    SliceUnit       32                  array [0..31] of char;
  // bytepos=300
    ChannelScale    8*Channels          array [0..Channels-1] of double;
    SliceScale      8*Slices            array [0..Slices-1] of double;
    Data            8*Slices*Channels   array [0..Slices-1] of array [0..Channels-1] of double;
    SumData         8*Channels          array [0..Channels-1] of double;

// From: instruments-types.txt   (SES 1.2.2 r1)
  TRegionRec = record

      Name : Char32;                     // region name
      ExcEnergy : double;                // excitation energy [eV]
      Kinetic : boolean;                 // kinetic or binding
      Fixed : boolean;                   // fixed or swept
      HighEnergy : double;               // high kinetic energy [eV]
      LowEnergy : double;                // low kinetic energy [eV]
      FixEnergy : double;                // fix mode kinetic energy [eV]
      EnergyStep : double;               // energy step [eV]
      StepTime : integer;                // step time [ms]
      UseRegionDetector : boolean;       // false indicates global detector
      DetectorRegion : TDetectorRec;     // regional detector
      LensMode : Char32;                 // lens mode
      PassEnergy : double;               // pass energy
      DriftRegion : boolean;             // drift region
      Grating : integer;                 // XES only
      Order : integer;                   // XES only
      Illumination : double;             // XES only
      Slit : double;                     // XES only
    end;

    TDetectorRec = record
      FirstXChannel : integer;
      LastXChannel : integer;
      FirstYChannel : integer;
      LastYChannel : integer;
      Slices : integer;
      ADCMode : boolean;
      ADCMask : integer;
      DiscLvl : integer;
    end;




// SES Work .DAT File structure  (****  OLD ****):
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
  



//Function/T ReadSESDhdr(fpath, fnam) -- .dat header
//Function/T ReadSESDdat(idialog) -- read data to wdata
//Function/T ReadSESDnfo(idialog) -- return filelist string
//Function ReadSESD(idialog)  -- read all .dat in folder (or list in .nfo) to wdatafull
//Function UpdateSESD(idialog) -- append additional nslices to wdatafull


Proc PlotSESDb(ctrlName) : ButtonControl
//---------------------
	String ctrlName
	
	string plotopt=""
	if (cmpstr(ctrlName,"Display")==0)
		plotopt="/D"
	endif
	if (cmpstr(ctrlName,"Append")==0)
		plotopt="/A"
	endif
	LoadSESD(plotopt)
End

Proc PlotSESDprefb(ctrlName) : ButtonControl
	String ctrlName
	PlotSESDprefs()
End

Proc PlotSESDprefs( namopt, dscal,  escal, xscal, iloadstep, imgtool)
//------------------------
	string namopt=StrVarOrDefault("root:SESdat:nameopt","/B")
	variable dscal=NumVarOrDefault("root:SESdat:dscale",4)
	variable escal=NumVarOrDefault("root:SESdat:escale",3)
	variable xscal=NumVarOrDefault("root:SESdat:xscale",2)
	variable imgtool=NumVarOrDefault("root:SESdat:autoload",1)
	variable iloadstep=NumVarOrDefault("root:SESdat:iprogstep",1)
		prompt namopt, "Wave Naming [/B=n/E/U/P=prefix/S=suffix]"
		prompt dscal, "Data intensity scaling", popup "Counts;kCts;Mcts;Cts/Sec;kHz;MHz"
		prompt escal, "Energy Scale", popup "KE;BE; -BE"
		prompt xscal, "Axis scaling", popup "Y vs X;Y(x)"
		prompt iloadstep, "Load Update increment", popup "1;5;10;20"
		prompt imgtool, "Preview", popup "Standard;2D/3D data to ImageTool"

	String curr= GetDataFolder(1)
	SetDataFolder root:SESdat:
		variable/G dscale=dscal, escale=escal, xscale=xscal, autoload=imgtool, iprogstep=iloadstep
		string/G nameopt=namopt
	
	SetDataFolder $curr
end
	
Proc LoadSESD( plotopt)
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
	string dwn=ExtractName( root:SESdat:filnam, root:SESdat:nameopt)
	if (strlen(dwn)==0)
		abort 
	endif
	//print "dwn=", dwn
	
	duplicate/o root:SESdat:wdata $("root:"+dwn)
	// Redimension & scaling done in LoadSESD()
	//Redimension/S  $("root:"+dwn)			//convert Unsigned INT32 to FP32 (single precision)
	
// (2) data scaling: Counts (default), kCounts (/1E3), Mcounts(1E6)    {/DS=3,6}
//                             Cts/Sec, kHz, MHz   (/(Dwell*Nsweep) )                {/Hz}
	variable cts=root:SESdat:dscale
	string dlbl=StringFromList( cts-1, "Counts;kCts;Mcts;Cts/sec;kHz;MHz" )
	variable rate=(cts>=4), dscl=mod(cts-1,3)
	if (cts>=4)
		//$dwn/=(root:SESdat:dwell*root:SESdat:nsweep)	
		$dwn/=(root:SESdat:dwell)			//nweeps encoded in to .dat file?
	endif
	if (dscl>0)		// cts-1=1,2 or 4,5 => kilo, mega
		$dwn/=1000^dscl
	endif

//  (3) energy scale:  as is (no change - for loading .pxt data)     {/KE, /BE, /BE=-1}
//                               KE, BE, -BE    (require hv, wfct)
	variable escal=root:SESdat:escale, xscal=root:SESdat:xscale
	variable hv=root:SESdat:ExcEnergy	//, wfct=root:SESdat:Wfct
	string xlbl=StringFromList( escal-1, "Kinetic Energy (eV);Binding Energy (eV);E-EF (eV)" )
	variable eoff=0, Estart=root:SESdat:MinEnergy, Eend=root:SESdat:MaxEnergy
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
	string txtstr=num2str(root:SESdat:Epass)+root:SESdat:LensMode[0]+root:SESdat:ScanMode[0]
	variable val=root:SESdat:ExcEnergy
	WriteMod($dwn, eoff, 0, 1, 0, 0.5, 0, val, txtstr)


// (4') Determine dimensions of data          1D, 2D, 2D to 3D, 3D		
// check accuracy of nx(enpts) and ny(nslice) variable read from 
	variable nx=DimSize( $dwn, 0), ny0=DimSize( $dwn, 1), nz=DimSize( $dwn, 2)
	variable ny=root:SESdat:nslice
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
				SESD_Style( xlbl, dlbl)
				ModifyGraph axThick=0.5
				ModifyGraph minor(left)=0, nticks(left)=3
			endif
			if (KeySet("A",plotopt))
				DoWindow/F $StringFromList(0, WinList("!*SES*", ";", "Win:1"))	
				append $dwn
				DoWindow/F SESdat_Panel		//helps for double-clicking when appending
			endif
			
		ELSE
			string ylbl=root:SESdat:sliceunit, titlestr=""
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
				GetZscaleSESD()					// popup dialog
				SetScale/P z root:SESdat:zstart, root:SESdat:zinc,root:SESdat:zunit, $dwn
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

Proc GetZscaleSESD( st, inc, unit )
//-----------------
	variable st=NumVarOrDefault("root:SES:zstart",0), inc=NumVarOrDefault("root:SES:zinc",1)
	string unit=StrVarOrDefault("root:SES:zunit","polar")
	prompt st, "Z start value"
	prompt inc, "Z increment"
	prompt unit, "Z-axis unit"
	variable/G root:SES:zstart=st, root:SES:zinc=inc
	string/G root:SES:zunit=unit
End

Function/T ReadSESDhdr(fpath, fnam)
//=================
// read SES Work binary file header
// saves values in root:SESdat folder variables
	string fpath, fnam
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESdat
	//SetDataFolder root:SESdat:
	String/G filnam=fnam, filpath=fpath
	
	Open/R refnum as filpath+filnam
		FStatus refnum
			if (debug)
				print  S_Filename, ", numbytes=", V_logEOF
			endif

//RegionRecord		
	// Region name	
	variable nbyt, ic, byt
	string/G RegionNam=String32( refnum )
		
	// Photon energy {FP8}
	variable /G  ExcEnergy		//FSetPos refnum, 256	
	FBinRead /F=5/B=3 refnum, ExcEnergy
	
	// Kinetic & Fixed mode flags  {LW4}
	variable /G  iKinetic, iFixed
	FBinRead /F=3/B=3 refnum, iKinetic
	FBinRead /F=3/B=3 refnum, iFixed			// 0=swept, 1=fixed
	string/G ScanMode=StringFromList(iFixed, "Swept;Fixed")
	
	// Energy Parms {Ei, Ef, Einc, Dwell}  {FP8}
	variable/G MinEnergy, MaxEnergy, CtrEnergy, EnergyStep, StepTime
	FBinRead/F=5/B=3  refnum, MaxEnergy
	FBinRead/F=5/B=3  refnum, MinEnergy
	FBinRead/F=5/B=3  refnum, CtrEnergy
	FBinRead/F=5/B=3  refnum, EnergyStep
	FBinRead/F=3/B=3  refnum, StepTime
	StepTime/=1000		//convert msec to sec
	
	// Region Detector
	variable/g  iRegDetect						//boolean
	FBinRead /F=3/B=3 refnum, iRegDetect	
	// DetectorRegionRecord
	string/G DetRegn=DetectorRegion(refnum)
	
	FSetPos refnum, 120	// LensMode {Transmission, Angular1, Angular2}
	string/G LensMode=String32( refnum )		//FSetPos refnum, 340 +256
	variable /g  LensModeIndex, Epass, EpassIndex, iDrift
	//FBinRead /F=3/B=3 refnum, LensModeIndex
	FBinRead /F=5/B=3 refnum, Epass				//FSetPos refnum, 600
	//FBinRead /F=3/B=3 refnum, EpassIndex
	//FBinRead /F=3/B=3 refnum, iDrift
//End RegionRecord

	//Missing an integer to read?
	//Fstatus refnum
	//Print V_filepos
	variable /g  nchan, nslice, nsweep
	FSetPos refnum, 192
	FBinRead /F=3/B=3 refnum, nchan	
	FBinRead /F=3/B=3 refnum, nslice
	FBinRead /F=3/B=3 refnum, nsweep

	// slice unit  string
	string/G CountUnit=String32( refnum )
	string/G ChannelUnit=String32( refnum )
	string/G SliceUnit=String32( refnum )
	
	//FSetPos refnum, 300  -- start of Energy Channel array
			
	Close refnum
	
	//assume one region
	Variable Ystart=0, Yend=1
	make/T/o/n=(19) infowav
		infowav[0]=filnam[0,strlen(filnam)-5]			// strip .DAT
		infowav[1]=LensMode
		infowav[2]=ScanMode
		infowav[3]=num2str(ExcEnergy); infowav[4]="RP"; infowav[5]="Ang"
		infowav[6]=num2str(Epass); infowav[7]="#"
		infowav[8]=num2str(MinEnergy); infowav[9]=num2str(MaxEnergy); 
		infowav[10]=num2str(1E-4*round(1E4*EnergyStep))
		infowav[11]=num2str(1E-3*round(1E3*StepTime)); infowav[12]=num2str(EpassIndex)
		infowav[13]="Temp"
		infowav[14]=num2str(nchan); 
		infowav[15]=num2str(nslice); 
		infowav[16]=num2str(nsweep)
		infowav[17]=ChannelUnit
		infowav[18]=SliceUnit
		//infowav[14]=num2str(Ystart); 
		//infowav[15]=num2str(Yend); 
				
	SetDataFolder root:
	return filnam
End




Function/T ReadSESDdat(idialog)
//=================
// read SES Work .DAT  binary file
	variable idialog
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESdat
	//SetDataFolder root:SESdat:
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
		ReadSESDhdr(filpath, filnam)			// already loaded if using panel
	endif
	//SetDataFolder root:
	//return filnam
	//abort
	
	SetDataFolder root:SESdat:
	//SVAR  filnam=filnam
	//SVAR  smode=sMode, skind=sKind
	//NVAR Epass=Epass, Estart=Estart, Eend=Eend, Einc=Einc, Dwell=Dwell, Nsweep=Nsweep
	NVAR nchan=nchan, nslice=nslice
	
	Open/R refnum as filpath+filnam
	//Energy (channel) scale
	FSetPos refnum, 300
	Make /o /D/N=(nchan) energyscale
	FBinRead/B=3 refnum, energyscale
	
	//Slice scale
	Make /o/D/N=(nslice) slicescale
	FBinRead/B=3 refnum, slicescale
	
	//Data
	Make /o /D/N=(nchan*nslice) wdata
	FBinRead/B=3 refnum, wdata
	
	//SumData  - angular
	Make /o /D/N=(nchan) sumdata
	FBinRead/B=3 refnum, sumdata
	
	Close refnum
	
	//Redimension & scaling
	Redimension/S wdata, sumdata		//convert to single precision
	Redimension/N=(nchan,nslice) wdata
	NVAR Estart=MinEnergy, Eend=MaxEnergy
	if (idialog>=0)		//skip scaling if idialog<0
		SetScale/I x Estart,Eend,"", wdata, sumdata
		if (nslice>1)
			WaveStats/Q slicescale
			SetScale/I y V_min,V_max,"", wdata
		endif
	endif
	
	// Post-processing options:
	// Deglitch spikes
	NVAR DatDeglitch=DatDeglitch
	SVAR DeglitchOpt=DeglitchOpt
	if (DatDeglitch)
		ImgDeglitch( wdata, "/O"+DeglitchOpt)
	endif
	
	// Rebin:  especially energy
	NVAR DatRebin=DatRebin
	SVAR xy_Rebin=xy_Rebin
	if (DatRebin)
		ImgResize( wdata, xy_Rebin, "/O/R")
	endif
	
	// Transpose
	NVAR DatTranspose=DatTranspose
	if (DatTranspose)
		MatrixTranspose wdata
	endif
	
	SetDataFolder root:
	return filnam
End

Function/T ReadSESDnfo(idialog)
//=================
	variable idialog
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESdat
	//SetDataFolder root:SESdat:
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

Function ReadSESD(idialog)
//=================
// read all files in working folder into wdatafull array
	variable idialog
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESdat
	//SetDataFolder root:SESdat:
	String/G filnam, filnfo, filpath
	
	string/G filelst
	string sep=","
	//filelst=ReadSESDnfo(idialog)		// comma-delimited
	sep=";"
	NewPath/O/Q SESdat, filpath
	//NewPath/O/Q/M="Select SES Work Folder" SESdat
	filelst=IndexedFile( SESdat, -1, ".dat")	
	variable/G nfile=ItemsInList(  filelst, sep)

	
	//Read first file; get XY scaling
	filnam=StringFromList(0, filelst, sep)
	if (debug)
		print "0: ", filnam
	endif
	ReadSESDdat(0)		//possible Rebin & transpose
	WAVE wdata=root:SESdat:wdata
	
	// Create full data set
	Duplicate/o wdata, root:SESdat:wdatafull
	WAVE wdatafull=root:SESdat:wdatafull
	if (nfile>1)
		//** Load Progress window **
		DoWindow /K LoadProgress
		NewPanel /K=1 /W=(344,223,603,329) as "Load Progress"
		DoWindow /C LoadProgress
		variable/G root:SESdat:progress
		NVAR progress = root:SESdat:progress, iprogstep=root:SES:iprogstep
		variable updatestep=NumFromList(iprogstep, "1;5;10;20",";")
		print updatestep
		SetDrawLayer UserBack
		SetDrawEnv fsize= 24
		DrawText 154,49,"of "+num2str(nfile-1)
		SetVariable progress,pos={20,20},size={125,28},title="Frame",fSize=20
		SetVariable progress,limits={-Inf,Inf,0},value= root:SESdat:progress,bodyWidth= 0
		ValDisplay valdisp0,pos={13,63},size={218,30},limits={0,nfile-1,0},barmisc={0,0}
		ValDisplay valdisp0,mode=3, value= #"root:SESdat:progress"
	
		NVAR nchan=root:SESdat:nchan, nslice=root:SESdat:nslice
		variable nchan1=nchan, nslice1=nslice
		NVAR DatRebin=root:SESdat:DatRebin
		if (datRebin==1)
			SVAR xy_Rebin=root:SESdat:xy_Rebin
			variable xrebin, yrebin
			xrebin=NumFromList(0, xy_Rebin,",")
			yrebin=NumFromList(1, xy_Rebin,",")
			nchan1=floor( nchan/xrebin)
			nslice1=floor(nslice/yrebin)
		endif
		NVAR DatTranspose=root:SESdat:DatTranspose
		//print nchan1, nslice1, nfile, DatTranspose
		if (DatTranspose==1)
			variable tmp=nchan1
			nchan1=nslice1
			nslice1=tmp
		endif
		// first wdata not loaded yet?
		//variable nchan1=DimSize( wdata,0), nslice1=DimSize(wdata,1)
		//print "Redimen:", nchan1, nslice1, nfile
		Redimension/N=(nchan1, nslice1, nfile) wdatafull
		variable timer_ref=startMStimer
		variable ii=1
		DO
			progress=ii
			if (mod(progress,updatestep)==0)
				DoUpdate
			endif
			filnam=StringFromList(ii, filelst, sep)
			if (debug)
				print ii, filnam
			endif
			ReadSESDdat(-1)				// skip XY scaled
			//ImgDeglitch( wdata, "/O")
			wdatafull[][][ii]=wdata[p][q]
			ii+=1
		WHILE(ii<nfile)
		variable millisec=stopMStimer(timer_ref) / 1000
		print "Load time:", millisec/1000, "secs = ", millisec/nfile, "msec per file"
			
		DoWindow /K LoadProgress
		KillVariables root:SESdat:progress
		
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

Function UpdateSESD(idialog)
//=================
	variable idialog
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESdat
	//SetDataFolder root:SESdat:
	String/G filnam, filnfo, filpath
	NVAR nchan=nchan, nslice=nslice
	WAVE wdatafull=wdatafull, wdata=wdata
	
	string/G filelst
	string sep=","
	//filelst=ReadSESDnfo(idialog)
	sep=";"
	NewPath/O/Q SESdat, filpath
	//NewPath/O/Q/M="Select SES Work Folder" SESdat
	filelst=IndexedFile( SESdat, -1, ".dat")	
	variable nfile1=ItemsInList(  filelst, sep)
	NVAR  nfile0=nfile		
	// nfile0 = dimsize( wdatafull, 2)
	
	variable nnewfiles = nfile1-nfile0
	print nnewfiles, nfile1, nfile0
	// Append to full data set
	if (nnewfiles>0)
	
	//** Load Progress window **
		DoWindow /K LoadProgress
		NewPanel /K=1 /W=(344,223,603,329) as "Load Progress"
		DoWindow /C LoadProgress
		variable/G root:SESdat:progress
		NVAR progress = root:SESdat:progress, iprogstep=root:SES:iprogstep
		variable updatestep=ceil(NumFromList(iprogstep, "1;5;10;20",";")/2)
		print updatestep
		SetDrawLayer UserBack
		SetDrawEnv fsize= 24
		DrawText 154,49,"of "+num2str(nnewfiles-1)
		SetVariable progress,pos={20,20},size={125,28},title="Frame",fSize=20
		SetVariable progress,limits={-Inf,Inf,0},value= root:SESdat:progress,bodyWidth= 0
		ValDisplay valdisp0,pos={13,63},size={218,30},limits={0,nnewfiles-1,0},barmisc={0,0}
		ValDisplay valdisp0,mode=3, value= #"root:SESdat:progress"
	
	
		//Possible rebin & transpose
		// Assume not setting changed in between initial load 
		variable nchan1=DimSize(wdatafull,0), nslice1=DimSize(wdatafull,1)
		//print nchan1, nslice1
		Redimension/N=(nchan1, nslice1, nfile1) wdatafull
		progress=0
		variable ii=nfile0 		//+1
		DO
			progress+=1
			if (mod(progress,updatestep)==0)
				DoUpdate
			endif
			filnam=StringFromList(ii, filelst,sep)
			//print filnam
			ReadSESDdat(-1)				// possible transpose & rebin involved
			//ImgDeglitch( wdata, "/O")
			wdatafull[][][ii]=wdata[p][q]
			ii+=1
		WHILE(ii<nfile1)
		
		DoWindow /K LoadProgress
		KillVariables root:SESdat:progress
		
		
		NVAR autoload=root:SESdat:autoload
		if ( autoload==1 )
			DoWindow/F ImageTool
			if (V_flag==1)
				Execute( "NewImg( \"root:SESdat:wdatafull\" )" )
				DoWindow/F SESdat_Panel
			endif	
		endif
	endif
	if (nnewfiles<0)
		// read from scratch
		ReadSESD(idialog)
	endif
	nfile0=nfile1
	return nnewfiles
End


		for (i=0; i<naxis2; i+=1)
			//if (mod(i,10)==0)
				progress=i
				DoUpdate
				//print i," / ",naxis2-1
			//endif
			loadSESdatextensionN(refnum,extediting,i,0)
			if(0*(xb==1)*(yb==1))					// no rebinning
				if(stringmatch(what2,"ses100_image")||stringmatch(what2,"Swept_Spectra*"))
					w3d[][][i]=wht[p][q][0]
				else			
					w3d[][][i]=wht[q][p][0]
				endif
			else
				variable i1,j1
				if(stringmatch(what2,"ses100_image")||stringmatch(what2,"Swept_Spectra*"))
					w3d[][][i]=0
					for(i1=0;i1<xb;i1+=1)
						for(j1=0;j1<yb;j1+=1)
							w3d[][][i] += wht[p*xb+i1][q*yb+j1]
						endfor
					endfor
				else
					//wnm[][][i]=binIt7(wht,xb,yb,p,q,1)				//speedup - Aaron
					w3d[][][i]=0
					for(i1=0;i1<xb;i1+=1)
						for(j1=0;j1<yb;j1+=1)
							w3d[][][i] += wht[q*xb+i1][p*yb+j1]
						endfor
					endfor
				endif
			endif
		endfor


Macro ShowSESdatPanel()
//-----------------
	DoWindow/F SESdat_Panel
	if (V_flag==0)
		NewDataFolder/O/S root:SESdat
		string/G filpath, filnam, filelst
		string/G folderList="Select New Folder;-;"
		variable/G  nchan, nslice, nfile, filnum	//, nregion
		variable/G Estart, Eend, Estep, Epass
		//variable/G Xstart, Xend, Ystart, Yend
		string/G skind, smode
		string/G wvnam	, nameopt="/B"			//, prefix=""
		variable/G nametyp=1, namenum=3
		variable/G  dscale=4, escale=3, xscale=2
		variable/G autoload=0, iprogstep=3		//1=1, 2=5, 3=10, 4=40
		variable/G DatDeglitch=0, glitchtyp=1, glitchline=nan, glitch_npass=1
		string/G DeglitchOpt=""
		variable/G DatTranspose=0, DatRebin=0
		string/G xy_Rebin="2,1"
		make/o/n=(18)/T infowav
		make/o/n=(20) data1D
		make/o/n=(20,20) wdata
		
		//	base=ExtractNameB( base, namtyp, namnum )   // need to put in loop for multiple regions
		//base=root:SES:skind[0]+base
		//wvnam:=WaveNameSES( filnam )
		SetDataFolder root:
		
		SESdat_Panel()
		
	endif
	CheckBox checkDeglitch value=root:SESdat:DatDeglitch	
	CheckBox checkTranspose value=root:SESdat:DatTranspose	
	CheckBox checkRebin value=root:SESdat:DatREbin	
End

Window SESdat_Panel() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:SESdat:
	Display /W=(543.6,71,715.2,388.4) wdata as "SESdat_Panel"
	AppendImage/T/R wdata
	ModifyImage wdata ctab= {*,*,Grays,0}
	SetDataFolder fldrSav0
	ModifyGraph cbRGB=(64512,62423,1327)
	ModifyGraph mirror=0
	ModifyGraph fSize=8
	ModifyGraph axOffset(right)=-1.6,axOffset(top)=-0.8
	Label top " "
	TextBox/N=text0/F=0/S=3/H=14/A=MT/E "\\{root:SESdat:filnam}: \\{root:SESdat:skind}, \\{root:SESdat:smode}"
	ControlBar 222
	PopupMenu popFolder,pos={11,1},size={108,24},proc=SelectFolderSESD,title="Data Folder"
	PopupMenu popFolder,mode=0,value= #"root:SESdat:folderList"
	SetVariable setlib,pos={11,23},size={246,16},title=" ",fSize=9
	SetVariable setlib,value= root:SESdat:filpath
	PopupMenu popup_file,pos={10,44},size={191,24},proc=SelectFileSESD,title="File"
	PopupMenu popup_file,mode=1,popvalue="Thetamap006_001.dat",value= #"root:SESdat:filelst"
	Button FileUpdate,pos={191,47},size={50,16},proc=UpdateFolderSESD,title="Update"
	SetVariable val_kind,pos={18,71},size={62,16},title=" "
	SetVariable val_kind,value= root:SESdat:LensMode
	SetVariable val_mode,pos={88,71},size={44,16},title=" "
	SetVariable val_mode,value= root:SESdat:ScanMode
	ValDisplay val_Ep,pos={142,71},size={50,15},title="Ep"
	ValDisplay val_Ep,limits={0,0,0},barmisc={0,1000},value= #"root:SESdat:Epass"
	ValDisplay val_Estart,pos={14,91},size={59,15},title="Ei"
	ValDisplay val_Estart,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estart,value= #"root:SESdat:MinEnergy"
	ValDisplay val_Eend,pos={77,91},size={59,15},title="Ef"
	ValDisplay val_Eend,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Eend,value= #"root:SESdat:MaxEnergy"
	ValDisplay val_Estep,pos={138,91},size={65,15},title="Einc"
	ValDisplay val_Estep,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_Estep,value= #"root:SESdat:EnergyStep"
	ValDisplay val_nslice,pos={177,130},size={66,15},title="# slice"
	ValDisplay val_nslice,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_nslice,value= #"root:SESdat:nslice"
	SetVariable set_hv,pos={12,109},size={75,16},proc=SetInputVarSES,title="hv"
	SetVariable set_hv,value= root:SESdat:ExcEnergy
	Button StepMinus,pos={79,195},size={20,18},proc=StepFileSESD,title="<<"
	Button StepPlus,pos={105,195},size={20,18},proc=StepFileSESD,title=">>"
	Button Display,pos={18,194},size={55,20},proc=PlotSESDb,title="Display"
	Button Append,pos={131,195},size={55,20},proc=PlotSESDb,title="Append"
	PopupMenu popupPreview,pos={198,196},size={24,24},proc=SetPreviewSESD
	PopupMenu popupPreview,mode=0,value= #"\"  2D/3D data to ImageTool\""
	ValDisplay val_dwell,pos={208,92},size={59,15},title="dwell"
	ValDisplay val_dwell,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_dwell,value= #"root:SESdat:StepTime"
	ValDisplay val_nswp,pos={204,71},size={49,15},title="iEp"
	ValDisplay val_nswp,limits={0,0,0},barmisc={0,1000}
	ValDisplay val_nswp,value= #"root:SESdat:EpassIndex"
	SetVariable wvnam,pos={19,173},size={110,16},title=" ",value= root:SESdat:wvnam
	ValDisplay val_nchan,pos={181,109},size={59,15},title="nchan"
	ValDisplay val_nchan,limits={0,0,0},barmisc={0,1000},value= #"root:SESdat:nchan"
	ValDisplay val_nfile,pos={61,130},size={59,15},title="nfile"
	ValDisplay val_nfile,limits={0,0,0},barmisc={0,1000},value= #"root:SESdat:nfile"
	SetVariable val_rgnnam,pos={101,110},size={61,16},title=" "
	SetVariable val_rgnnam,value= root:SESdat:regionnam
	ValDisplay version,pos={227,3},size={30,15},title="v1.2.3",frame=0
	ValDisplay version,limits={0,0,0},barmisc={0,1000},value= #"0"
	Button PlotPrefs,pos={160,171},size={55,20},proc=PlotSESDprefb,title="Prefs"
	CheckBox checkDeglitch,pos={15,153},size={57,14},proc=CheckLoadDat,title="Deglitch"
	CheckBox checkDeglitch,value= 1
	CheckBox checkTranspose,pos={83,153},size={68,14},proc=CheckLoadDat,title="Transpose"
	CheckBox checkTranspose,value= 0
	CheckBox checkRebin,pos={162,153},size={46,14},proc=CheckLoadDat,title="Rebin"
	CheckBox checkRebin,value= 0
	SetVariable val_Rebin,pos={215,153},size={35,16},title=" "
	SetVariable val_Rebin,value= root:SESdat:xy_Rebin
EndMacro
	//ValDisplay val_Nreg,pos={20,130},size={60,14},title="# region",fSize=10
	//ValDisplay val_Nreg,limits={0,0,0},barmisc={0,1000},value= #"root:SESdat:nregion"
	//SetVariable set_wfct,pos={108,186},size={80,14},proc=SetInputVarSES,title="wfct"
	//SetVariable set_wfct,fSize=10,limits={-Inf,Inf,1},value= root:SES:wfct
	//SetVariable set_ang1,pos={16,206},size={85,14},proc=SetInputVarSES,title="Ang1"
	//SetVariable set_ang1,fSize=10,limits={-Inf,Inf,1},value= root:SES:angoffset1
	//SetVariable set_ang2,pos={107,206},size={85,14},proc=SetInputVarSES,title="Ang2"
	//SetVariable set_ang2,fSize=10,limits={-Inf,Inf,1},value= root:SES:angoffset2
	//SetVariable wvnam,limits={-Inf,Inf,1},value= root:SESdat:wvnam
	//Button WvNamePrefs,pos={23,225},size={55,18},proc=NamingPrefsSES,title="Naming"
	
	
	
Function CheckLoadDat(ctrlName,checked) : CheckBoxControl
//=======================
	String ctrlName
	Variable checked
	
	SetDataFolder root:SESdat:
	
	if (cmpstr(ctrlName,"checkTranspose")==0)
		variable/G DatTranspose= checked
	endif
	if (cmpstr(ctrlName,"checkRebin")==0)
		variable/G DatRebin= checked
	endif
	if (cmpstr(ctrlName,"checkDeglitch")==0)
		NVAR DatDeglitch=root:SESdat:DatDeglitch
		DatDeglitch=checked
			//print DatDeglitch, checked
		if (DatDeglitch==1)
			NVAR glitchtyp=root:SESdat:glitchtyp
			NVAR glitchline=root:SESdat:glitchline
			NVAR glitch_npass=root:SESdat:glitch_npass
			Variable typ=NumVarOrDefault("glitchtyp", 1 )
			Variable nline=NumVarOrDefault("glitchline", nan )
			Variable npass=NumVarOrDefault("glitch_npass", 1 )
			prompt typ, "Glitch Type",popup, "Point 4-pt XY avg;Point X avg;Point Y avg;Column;Row"
			prompt nline, "specific column/row number (blank=auto)"
			prompt npass, "# passes"
			DoPrompt "Deglitch dat image" typ, nline, npass
			variable/G glitchtyp=typ, glitchline=nline, glitch_npass=npass
			//glitchtyp=typ; glitchline=nline; glitch_npass=npass
			
			//assemble glitchoption string
			SVAR DeglitchOpt=DeglitchOpt
			// glitch type
			string opt="", styp=""
			styp=SelectString( typ==2, styp, "/X")
			styp=SelectString( typ==3, styp, "/Y")
			styp=SelectString( typ==4, styp, "/XL")
			styp=SelectString( typ==5, styp, "/YL")
			opt+=styp
		
			//line number
			if (nline>0)
				opt+="="+num2str(nline)
			endif
			DeglitchOpt=opt
		endif
	endif
	SetDataFolder root:

End


Proc SelectFolderSESD(ctrlName,popNum,popStr) : PopupMenuControl
//-------------------
	String ctrlName
	Variable popNum
	String popStr
	
	SetDataFolder root:SESdat:
	//if (popNum==2)						//print "Summarize Folder"
	//	SummarizeSESfolder(filpath)
	//else
		if (popNum==1)						//print "Select Folder"
			NewPath/O/Q/M="Select SES Work Folder" SESdat				//dialog selection
			string/G filpath
			Pathinfo SESdat
			filpath=S_path
			folderList=folderList+filpath+";"
		endif
		if (popNum>2)							//print "Select Existing Folder"
			filpath=StringFromList(popNum-1,folderList)
			//print popNum, filpath
			NewPath/O/Q SESdat filpath
		endif
		filelst=IndexedFile( SESdat, -1, ".dat")	//+IndexedFile( SESdat, -1, ".txt")
		//string fullfilelst=IndexedFile( SESdat, -1, "????")	
		//filelst=ReduceList( fullfilelst, "*.dat" )  //+ReduceList( fullfilelist, "*.txt" )
		nfile=ItemsInList( filelst, ";")
	//endif
	SetDataFolder root:
	// Update filelist menu and reset to first file
	PopupMenu popup_file value=root:SESdat:filelst, mode=1
	SelectFileSESD("",1,"")
	ReadSESD(0)
		if ( root:SESdat:autoload==2 )
			DoWindow/F ImageTool
			if (V_flag==1)
				NewImg( "root:SESdat:wdatafull" )
				DoWindow/F SESdat_Panel
			endif	
		endif
End

Proc SelectFileSESD(ctrlName,popNum,popStr) : PopupMenuControl
//-----------------------------
	String ctrlName
	Variable popNum
	String popStr

	root:SESdat:filnum=popNum
	//root:SES:filnam=popStr
	root:SESdat:filnam=StringFromList(root:SESdat:filnum-1, root:SESdat:filelst, ";")
	string/G root:SESdat:wvnam=ExtractName( root:SESdat:filnam, root:SESdat:nameopt )
	ReadSESDhdr( root:SESdat:filpath, root:SESdat:filnam )

	//variable autoload=1
	//if (root:SES:autoload>0)				// Preview option
	PauseUpdate; Silent 1
	ReadSESDdat(0)
	string loadwn="root:SESdat:wdatafull"
		if (WaveDims($loadwn)==1)
			duplicate/o $loadwn root:SES:data1D
			 root:SESdat:data2D=nan
		endif
		if (WaveDims($loadwn)==2)    
			if ( root:SESdat:autoload==2 )		// Pipeline to data to Image_Tool
				DoWindow/F ImageTool
				if (V_flag==1)
					NewImg( loadwn )
					DoWindow/F SESdat_Panel
				endif	
				//root:SES:data1D=nan
				//execute "NewImg( \""+loadwn+"\" )"	// 
			else
				duplicate/o $loadwn root:SESdat:data2D
				variable nx=DimSize(root:SESdat:data2D, 0) , ny=DimSize(root:SESdat:data2D, 1)
				Redimension/N=(nx) root:SESdat:data1D
				CopyScales root:SESdat:data2D, root:SESdat:data1D
				root:SESdat:data1D=root:SESdat:data2D[p][ny/2]
			endif
		endif
		if (WaveDims($loadwn)==3)
			if ( root:SESdat:autoload==2 )
				DoWindow/F ImageTool
				if (V_flag==1)
					NewImg( loadwn )
					DoWindow/F SESdat_Panel
				endif	
			endif
		endif
	//endif
End

Proc StepFileSESD(ctrlName) : ButtonControl
//====================
	String ctrlName
	variable filnum=root:SESdat:filnum
	string filnam
	if (cmpstr(ctrlName,"StepMinus")==0)
		filnum=max(1, root:SESdat:filnum-1)
	endif
	if (cmpstr(ctrlName,"StepPlus")==0)
		filnum=min(root:SESdat:nfile, root:SESdat:filnum+1)
	endif
	filnam=StringFromList( filnum-1, root:SESdat:filelst, ";")
	PopupMenu popup_file mode=filnum
	SelectFileSESD( "", filnum, filnam )
End


Proc UpdateFolderSESD(ctrlName) : ButtonControl
//-----------------------
	String ctrlName

	UpdateSESD(0)
	//SetDataFolder root:SESdat:
	
	//filelst=IndexedFile( SESdat, -1, ".dat")	
	//filelist=ReduceList( fullfilelist, "*.pxt" )
	//nfile=ItemsInList( fileList, ";")
	PopupMenu popup_file value=root:SESdat:filelst		//#"root:SES:fileList"
	
	//StepFileSES("StepPlus") 		// increment file selection to next (N+1)
	//Jump to last slice
	SelectFileSESD( "", root:SESdat:nfile, "" )
	PopupMenu popup_file mode=root:SESdat:nfile
	//SetDataFolder root:
End

Proc SetPreviewSESD(ctrlName,popNum,popStr) : PopupMenuControl
//--------------
	String ctrlName
	Variable popNum
	String popStr

	root:SESdat:autoload=1-root:SESdat:autoload		// toggle on/off
	if (root:SESdat:autoload==1)
		PopupMenu popupPreview value="Ã  2D/3D data to ImageTool"
	else
		PopupMenu popupPreview value=" 2D/3D data to ImageTool"
	endif
End

Function/T WaveNameSESD( filenam )
//==================
//Options:
//  prefix, "Wave Name prefix"
//  namtyp,  "Full Prefix only;First N prefix characters;Last N prefix characters;Extension only;Remove . ;Convert . to _;"
//  namnum, "Number of prefix characters", popup, "1;2;3;4;5;6;7;8"
	string filenam
	
	//SVAR prefix0=root:SES:prefix 
	SVAR skind=root:SESdat:skind
	NVAR nametyp=root:SESdat:nametyp, namenum=root:SESdat:namenum
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
	//FBinRead/F=1/B=3 refnum, nbyt
	nbyt=8	
	str=PadString("",nbyt,0)		//0= C-style string
	FBinRead refnum, str
	FSetPos refnum, V_filepos+256
	return str
End

Static Function/T String32(refnum)
//=================
// 32 byte string
//  return up to first blank 
	variable refnum
	
	//Fstatus refnum		// V_filepos
	variable nbyt=32
	string str
	str=PadString("",nbyt,0)		//0= C-style string
	FBinRead refnum, str
	variable pos=strsearch(str,"",0)
	pos=SelectNumber(pos==-1, pos, 8)
	//FSetPos refnum, V_filepos+256
	return str[0,pos-1]
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

Function/T ReadSESDhdr_old(fpath, fnam)
//=================
// read SES Work binary file header
// saves values in root:SESdat folder variables
	string fpath, fnam
	variable debug=0			// programming flag
	Variable refnum
	
	NewDataFolder/O/S root:SESdat
	//SetDataFolder root:SESdat:
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

Proc SESD_Style(xlabel, ylabel) : GraphStyle
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

	