//File: Image_Tool4			Created: 6/98
// Jonathan Denlinger, JDDenlinger@lbl.gov
// with contributions from Eli Rotenberg, ERotenberg@lbl.gov
//  Feb 2003 ER  - merged z tools into XY image window, added color options
//  2/17/03 JD  - (4.01) Added Z-slice averaging: VolSlice() instead of ExtractSlice; SetSliceAvg(); 
//                                  SetVariable SetZavg; and HairZ0 vs HairZ0_x

//Minor changes (you can delete these notes on new version)
// (0) deleted version notes for version 3
// (1) convert "getstrfromlist()" (won't compile) to Igor builtin "StringFromLis()" function
//         -- similarly I once wrote a StrFromList() function (in list_util.ipf) before Igor add theirs as a standard 
// (2) similarly replace "finditeminlist()" with Igor "(FindListItem()"
// (3) add /K=1 option to newnotebook (click kill with no dialog) for ImageToolHelp
// (4) commented out version 3 minor improvements in ImageTool Help; changed help wording to "quadrants"
// (5) converted "v4.00" textbox to a "ValDisplay" to be within the ControlBar
// (6) Volume: Opt pull down menu Z=Csr(A) probably not needed - comment out for now

// 2/17/03 jdd
// (7) Changed strsearch(..."hairz0") to strsearch(..."HairZ0") to get Zline cursor to respond
// (8) Changed dosetScale()	 from Proc to Function
// (9) Added showImgSlices check to imgHookFcn, i.e. if ((ndim==3)*showImgSlices)
// (10) Comment out  print "here", datnam  in NewImg()
//  (11) Added Zinfo textbox for ZMovie animate;  fct animate_slices() not needed

#pragma rtGlobals=1		// Use modern global access method.
#include <Cross Hair Cursors>
#include "List_util"
#include "Image_util"
#include "wav_util"
#include "volume"

//Proc	 	InitImageTool()
//Macro 		ShowImageTool( )
//Fct 		UpdateXYGlobals(tinfo)

//Window 	ImageTool()			 	: Graph
//Fct/T 		PickStr( promptstr, defaultstr, wvlst )	Ñ calls procedure 
//Proc 		Pick_Str( str1, str2 )			Ñ pops up dialog box
//Proc 		NewImg(ctrlName) 			: ButtonControl
//Proc 		PickImage( wn )
//Fct/T 		ImgInfo( image )
//Fct 		SetHairXY(ctrlName,varNum,varStr,varName) 	: SetVariableControl
//Proc 		ImgModify(ctrlName, popNum,popStr) : PopupMenuControl
//Proc 		PopFilter(ctrlName,popNum,popStr) 	: PopupMenuControl
//Proc 		ImageUndo(ctrlName,popNum,popStr) 	: PopupMenuControl
//Proc 		ImgAnalyze(ctrlName, popNum,popStr) : PopupMenuControl
//Fct 		AREA2D( img, axis, x1, x2, y0 )
//Fct/C  		EDGE2D( img, x1, x2, y0, wfrac )   Ñ return CMPLX(pos, width)
//Fct/C  		PEAK2D( img, x1, x2, y0 )			Ñ return CMPLX(pos, width)
//Proc 		SetProfiles()
//Proc 		AdjustCT()						: GraphMarquee
//Proc 		Crop() 									: GraphMarquee
//Proc 		NormY() 								: GraphMarquee
//Proc 		OffsetZ() 								: GraphMarquee
//Proc 		AreaX() 								: GraphMarquee
//Proc 		Find_Edge() 							: GraphMarquee
//Proc 		Find_Peak() 							: GraphMarquee
//Proc 		ExportAction(ctrlName) 				: ButtonControl
//Proc 		ExportImage( exportn, eopt, dopt )

//Window 	Stack_() 					: Graph
//Fct 		UpdateStack(ctrlName)					: ButtonControl
//Fct 		Image2Waves( img, basen, dir )
//Proc 		SetOffset(ctrlName,varNum,varStr,varName) 	: SetVariableControl
//Proc 		AutoOffset(ctrlName) 					: ButtonControl
//Fct 		OffsetStack( shift, offset )
//Proc 		ExportStack( basen ) 					

//Window 	ZProfile() 					: Graph

//Proc 		Area_Style() 				: GraphStyle
//Proc 		Edge_Style() 				: GraphStyle
//Proc 		Peak_Style() 				: GraphStyle

Menu "2D"
	"-"
	"Image Tool 4!"+num2char(19), ShowImageTool()
		help={"Show Image Processing GUI"}
End

Proc ImageToolHelp()
	DoWindow/F ImageToolInfo
	if (V_flag==0)
		string txt
		NewNotebook/W=(100,100,570,400)/F=1/K=1/N=ImageToolInfo
		Notebook ImageToolinfo, showruler=0, backRGB=(45000,65535,65535)
		Notebook ImageToolinfo, fstyle=1, text="Image Tool 4\r"
		Notebook ImageToolinfo, fstyle=0, text="version 4.00, Feb2003 J. Denlinger\r"
		Notebook ImageToolinfo, fstyle=0, text="Contributions be Eli Rotenberg\r\r"
		
		Notebook ImageToolinfo, fstyle=1, text="Mouse Shortcuts:\r"
		Notebook ImageToolinfo, fstyle=2, text="Image & Line Profile quadrants\r"
			txt="   Cmd/Ctrl + mouse = dynamic update of cross-hair position\r"
			txt+="   Opt/Alt + mouse = left/right/up/down step of cross-hair\r"
			txt+="   Shift + mouse = center cross-hair in image\r"
		Notebook ImageToolinfo, fstyle=0, text=txt
		Notebook ImageToolinfo, fstyle=2, text="Z-profile quadrant\r"
			txt="   Cmd/Ctrl + mouse = dynamic update of image slice z-value\r"
			txt+="   Opt/Alt + mouse = left/right step of image slice z-value\r"
		Notebook ImageToolinfo, fstyle=0, text=txt
		
		Notebook ImageToolinfo, fstyle=1, text="\rNew Features:\r"
			txt="   v4.00 - merge volume controls to XY window (ER), added options for colors\r"
			txt+="   v4.01 - Added Z-slice averaging option (JD)\r"
			//txt+="   v3.91 - Added new Resize using Marquee box range\r"
			//txt+="   v3.9 - OS (Mac/Win) specific panel sizes\r"
			//txt+="   v3.8 - Revamped & added interpolate to Resize image\r"
			//txt+="   v3.7 - Cross hair added to line profile plots\r"
			//txt+="   v3.5 - Added Invert CT; new Shift image modify option\r"
			//txt+="   v3.4 - New 3D animate features\r"
			//txt+="   v3.3 - This help window + step mouse actions\r"
			//txt+="   v3.2 - Export (Image/Profile) (Display/Append) options added\r"
			//txt+="   v3.1 - Color Table Gamma, Red Temp/Grayscale & Rescale controls\r"
			//txt+="   (er) - live update of cross-hair & z-slice with Cmd+mouse\r"
			//txt+="   v3.0 - 3D data set slicing & Z-profile control\r"
		Notebook ImageToolinfo, fstyle=0, text=txt
		
	endif
End

// *** Image Procs and Functions *****

Proc InitImageTool()
//---------
	Silent 1
	NewDataFolder/O/S root:WinGlobals
	NewDataFolder/O/S root:WinGlobals:ImageTool
		variable/G X0=0, Y0=0, D0
		String/G S_TraceOffsetInfo		
		Variable/G hairTrigger
		// Dependencies
		SetFormula hairTrigger,"UpdateXYGlobals(S_TraceOffsetInfo)"
		
	NewDataFolder/O/S root:IMG
		string/G imgnam, imgfldr, imgproc, imgproc_undo, exportn,datnam=""
		variable/G nx=51, ny=51,center, width		
		variable/G xmin=0, xinc=1, xmax, ymin=0, yinc=1, ymax
		variable/G dmin0, dmax0, dmin=0, dmax=1
		variable/G numpass=1			//# of filter passes
		variable/G gamma=1, CTinvert=1
		make/o/n=(nx, ny) image,  image0,  image_undo	
		make/o/n=(nx) profileH, profileH_x=p
		make/o/n=(ny) profileV, profileV_y=p
		Make/O HairY0={0,0,0,NaN,Inf,0,-Inf}
		Make/O HairX0={-Inf,0,Inf,NaN,0,0,0}
		Make/O HairY1={0,0,0}, HairX1={-Inf,0,Inf}
		make/o/n=256 pmap=p

		make/o/n=(256,3) RedTemp_CT,  Gray_CT, Image_CT, himg_ct,vimg_ct
		RedTemp_CT[][0]=min(p,176)*370
		RedTemp_CT[][1]=max(p-120,0)*482
		RedTemp_CT[][2]=max(p-190,0)*1000
		Gray_CT=p*256
		variable/g  ColorOptions, LockColors

		//3D specific
		make/o/n=10 profileZ, profileZ_x
		make/o/n=3 iz_sav={0,0,0}
		Make/O HairZ0={-Inf,0, Inf}, HairZ0_x={0,0,0}
		SetScale/P x 0,1E-7,"" HairZ0
		variable/G ndim=2, islice, nz, iz, Z0, islicedir=1
		variable/G nsliceavg=1			//**JD
		variable/G zmin, zinc, zmax, zstep=1
		string/G anim_menu= "Go;-;Ã Forward;  Backward;  Loop;-;Ã Single Pass;  Continuous;-;Ã Full Range;  Cursors;-;Save Movie"
		variable/G anim_dir=0, anim_loop=0, anim_range=0
		make/o/n=(2,2) h_img, v_img 	//**ER
		h_img=NaN							//**ER
		v_img=NaN							//**ER
		variable/g showImgSlices=1, vol_dmin, vol_dmax
		
		
		// Dependencies
		pmap:=255*(p/255)^gamma
		//pmap:=255*(p/255)^(10^gamma)       // log(Gamma) works best in range {-1,+1} with 0.1 increment
		//Image_CT:=dmin+RedTemp_CT[pmap[p]][q]*(dmax-dmin)/255
		Image_CT:=RedTemp_CT[pmap[p]][q]	//  /255
		himg_ct:=RedTemp_CT[pmap[p]][q]
		vimg_ct:=RedTemp_CT[pmap[p]][q]
		profileH:=image(profileH_x)(root:WinGlobals:ImageTool:Y0)
		profileV:=image(root:WinGlobals:ImageTool:X0)(profileV_y)
		//profileZ:=$datnam(root:WinGlobals:ImageTool:X0)(root:WinGlobals:ImageTool:Y0)(x)
		root:WinGlobals:ImageTool:D0:=root:IMG:image(root:WinGlobals:ImageTool:X0)(root:WinGlobals:ImageTool:Y0)

		// Nice pretty initial image
		SetScale/I x -25,25,"" image, image0;  SetScale/I y -25,25,"" image, image0
		image=cos((pi/10)*sqrt(x^2+y^2+z^2))*cos( (2.5*pi)*atan2( y, x))
		SetScale/I y 50,100,"" image, image0

		image0=image; image_undo=image
		ImgInfo(Image)
		
	NewDataFolder/O/S root:IMG:STACK
//		make/o/n=10 line0, line1, line2
		variable/G xmin=0, xinc=1, ymin=0, yinc=1, dmin=0, dmax=1
		variable/G shift=0, offset=0, pinc=1
		string/G basen
	SetDataFolder root:
End

 
Proc ShowImageTool( )
//----------------
	PauseUpdate; Silent 1
	DoWindow/F ImageTool
	if (V_flag==0)
		InitImageTool()
		ImageTool()	
		SetProfiles()
		SetHairXY( "Check", 0, "", "" )
	
		//Resize Panel (OS specific)
		string os=IgorInfo(2)
		//**ER commented next lines out
		//if (stringmatch(os[0,2],"Win"))
		//	MoveWindow/W=ImageTool 453, 143, 814, 540
		//else	   //Mac
		//	MoveWindow/W=ImageTool 453, 143, 932, 628
		//endif
		
		AdjustCT() 
		SetWindow imagetool hook=imgHookFcn, hookevents=3
		
		string screen=IgorInfo(0)
		screen=StringByKey( "SCREEN1", screen, ":" )
		print os, screen
	endif
end

Function/T PickStr( promptstr, defaultstr, wvlst )
//------------
	String promptstr, defaultstr
	variable wvlst
	String/G  PickStr0, Promptstr0=promptstr, DefaultStr0=defaultstr
	//string a=""
	if (wvlst==1)
		execute "Pick_Str( \"\", )"
	else
		execute "Pick_Str( , \"\" )"
	endif
	//execute cmd
	return PickStr0
End

Proc Pick_Str( str1, str2 )
//------------
	String str1=DefaultStr0, str2=DefaultStr0
	prompt str1, Promptstr0
	prompt str2, Promptstr0, popup, WaveList("!*_x",";","")
	Silent 1
	String/G PickStr0=str1+str2
End

Proc PickImage( wn )
//------------
	String wn=StrVarOrDefault("root:img:imgnam","")
	prompt wn, "new image, 2D array", popup, WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")
	
	root:img:imgnam=wn
	root:img:imgfldr=GetWavesDataFolder($wn, 1)
	root:img:exportn=wn+"_"		// prepare export name
End

Proc NewImg(ctrlName) : ButtonControl
//------------
	String ctrlName

// Popup Dialog image array selection
	string datnam
	if (stringmatch(ctrlName, "LoadImg"))
		PickImage( )
		datnam=root:IMG:imgfldr+root:IMG:imgnam
		//print "here",datnam
	else
		datnam=ctrlName
		root:img:imgnam=datnam
		root:img:imgfldr=""
	endif
//	root:IMG:imgnam=PickStr( "New image, 2D array", root:img:imgnam,1)
//	root:IMG:imgfldr=GetWavesDataFolder($root:IMG:imgnam, 1)
//	print img
	root:img:datnam=datnam
	PauseUpdate; Silent 1
	setupImg()  //**ER
end

proc setupImg()		//**ER moved this out of newimg
	silent 1; pauseupdate
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	
	ndim=SelectNumber( DimSize( $datnam, 2)==0, 3, 2)
	if (ndim==3)
		islice=0
		 SelectSliceDir("", iSliceDir,"")
//**ER added this block
		wavestats/q $datnam
		vol_dmin=v_min
		vol_dmax=v_max
		if  (FindListItem("profileZ",wavelist("*",";","WIN:ImageTool"),";",0)<0)	
			 append/r=zy/t=zx profilez
		endif
		if  (FindListItem("HairZ0",wavelist("*",";","WIN:ImageTool"),";",0)<0)	
			 append/r=zy/t=zx HairZ0 vs HairZ0_x
		endif
		
		ModifyGraph freePos(zy)=0;DelayUpdate
		ModifyGraph freePos(zx)=0		
		ModifyGraph offset(HairZ0)={Z0,0}
		ModifyGraph rgb(profileZ)=(3,52428,1),rgb(HairZ0)=(3,52428,1)

		if(showimgslices)
			if  (FindListItem("h_img",wavelist("*",";","WIN:ImageTool"),";",0)<0)
 				//h_img not already on window
				 appendimage/W=ImageTool/L=imgh h_img								
			endif
			 ModifyGraph axisEnab(imgh)={0.50,0.72},freePos(imgh)=0,axisenab(left)={0.0, 0.45}
			 ModifyImage h_img,cindex=himg_ct
			if  (FindListItem("v_img",wavelist("*",";","WIN:ImageTool"),";",0)<0)	
 				//v_img not already on window
				 appendimage/W=ImageTool/B=imgv v_img								
			endif
			 ModifyGraph axisEnab(imgv)={0.5,0.72},freePos(imgv)=0	,axisenab(bottom)={0.0, 0.45}
			 ModifyImage v_img,cindex=vimg_ct
			 modifygraph axisEnab(zy)={0.5,1},axisEnab(zx)={0.5,1}
		else
			modifygraph axisEnab(left)={0,0.70}, axisEnab(bottom)={0.0, 0.70}
			if  (FindListItem("h_img",wavelist("*",";","WIN:ImageTool"),";",0)>=0)
				 removeimage/W=ImageTool h_img								
			endif
			if  (FindListItem("v_img",wavelist("*",";","WIN:ImageTool"),";",0)>=0)
				 removeimage/W=ImageTool v_img								
			endif
			modifygraph axisEnab(zy)={0.75,1},axisEnab(zx)={0.75,1}

		endif
		modifygraph fsize=10
		TextBox/C/N=zinfo/X=25.00/Y=2.00/A=MT/E/F=2  "Z = \\{root:img:Z0}  (\\{root:img:islice})"
//**END OF BLOCK

		//nx=DimSize($datnam,0)
		//ny=DimSize($datnam,1)
		//nz=DimSize($datnam,2)
		//islice=0
		//make/n=(nx,ny)
		//duplicate/o $datnam Image,  Image0,  Image_undo
		//ExtractSlice( islice, $datnam, "root:IMG:Image", idir)
		//Duplicate/O Image, Image0, Image_Undo
	else		//**ER
		if (FindListItem("h_img",wavelist("*",";","WIN:ImageTool"),";",0)>=0)	//**ER
			removeimage/w=ImageTool h_img										//**ER
		endif																		//**ER
		if (FindListItem("v_img",wavelist("*",";","WIN:ImageTool"),";",0)>=0)	//**ER
			removeimage/w=ImageTool v_img										//**ER
		endif																		//**ER
		if (FindListItem("profileZ",wavelist("*",";","WIN:ImageTool"),";",0)>=0)	//**ER
			removefromgraph/w=ImageTool profileZ								//**ER
		endif																		//**ER
		if (FindListItem("HairZ0",wavelist("*",";","WIN:ImageTool"),";",0)>=0)	//**ER
			removefromgraph/w=ImageTool HairZ0								//**ER
		endif																		//**ER
		modifygraph axisenab(left)={0.0, 0.70}, axisenab(left)={0.0, 0.70}
		modifygraph axisenab(bottom)={0.0, 0.70}, axisenab(bottom)={0.0, 0.70}
		TextBox/K/N=zinfo		//**JD
		nz=1; zmin=0; zmax=0; zinc=1; islice=0; islicedir=1
		duplicate/o $datnam Image,  Image0,  Image_undo
		// Remove dependencies to previous 3D data before loading
		DoWindow/K ZProfile
//		profileZ=nan
	endif	//**ER
	
	SetAxis/A
	ImgInfo(Image)
	//print dmin0, dmax0
	variable/G dmin=dmin0, dmax=dmax0
	ModifyImage  Image cindex= Image_CT
	//ModifyImage  Image cindex= RedTemp_CT
	//SetScale/I x dmin0, dmax0,"" root:IMG:RedTemp_CT
	//print dmin, dmax, dmin0, dmax0
	AdjustCT()
	//print dmin, dmax, dmin0, dmax0

	SetHairXY( "Center", 0, "", "" )
 		SetProfiles()		
	
	ReplaceText/N=title "\Z09"+imgnam
	imgproc=""
	Label bottom WaveUnits(Image, 0)
	Label left WaveUnits(Image, 1)
	updateImgSlices(0)		//**ER
	SetDataFolder $curr
End

Function ShowImgSlicesProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	nvar sis=root:img:showImgSlices
	sis=checked
	execute "setupimg()"
End

Function ColorLockProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	nvar lc=root:img:lockColors
	lc=checked
End

Function ColorOptionsProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	nvar imgOpt=root:img:colorOptions
	imgOpt=popnum
End


//**ER ADDED THIS
//should be in :img: folder
proc MakeImgSlices()
	 make/o/n=(dimsize(image,0),dimsize(profilez,0)) h_img
	 setscale/p x dimoffset(image,0),dimdelta(image,0),waveunits(image,0),h_img
	 setscale/p y dimoffset(profilez,0),dimdelta(profilez,0),waveunits(profilez,0),h_img
	 
	 make/o/n=(dimsize(profilez,0),dimsize(image,1)) v_img
	 setscale/p y dimoffset(image,1),dimdelta(image,1),waveunits(image,1),v_img
	 setscale/p x dimoffset(profilez,0),dimdelta(profilez,0),waveunits(profilez,0),v_img
end

//**ER ADDED ENTIRE FUNCTION
//should be already in :img: folder 
function updateImgSlices(option)
	variable option	//0=both, 1=H only, 2=V only
	//nvar y0=root:winglobals:imagetool:y0,x0=root:winglobals:imagetool:x0
	nvar ndim=ndim,isd=islicedir
	wave image=image, h_img=h_img, v_img=v_img
	svar dn=datnam
	wave w=$dn
	variable x0,y0
	string offst= stringbykey("offset(x)",traceinfo("imagetool","HairY0",0),"=")
	offst=offst[1,strlen(offst)-2]
	x0=str2num(StringFromList(0,offst,","))
	y0=str2num(StringFromList(1,offst,","))
	variable doH=(option==0)+(option==1)
	variable doV=(option==0)+(option==2)
	if(ndim==3)
		variable py=(y0-dimoffset(image,1))/dimdelta(image,1)
		variable px=(x0-dimoffset(image,0))/dimdelta(image,0)
		//print x0,y0,px,py
		if(isd==1)	//XY
			if(doH)
				h_img=w[p][py][q]
			endif
			if(doV)
				v_img=w[px][q][p]
			endif
		endif
		if(isd==2)	//XZ
			if(doH)
				h_img=w[p][q][py]
			endif
			if(doV)
				v_img=w[px][p][q]
			endif
		endif
		if(isd==3)	//YZ
			if(doH)
				h_img=w[q][p][py]
			endif
			if(doV)
				v_img=w[p][px][q]
			endif
		endif
		nvar lc=lockColors
		if(lc==0)
			execute "adjustct()"
		endif
	endif
end

Proc SelectSliceDir(ctrlName,popNum,popStr) : PopupMenuControl
//--------------------
	String ctrlName
	Variable popNum
	String popStr

	PauseUpdate; Silent 1
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	
	string/G datnam=imgfldr+imgnam
	string zunit
	islicedir=popNum
	variable idir=3-islicedir
	nz=DimSize( $datnam, idir )
	zmin=DimOffset( $datnam, idir )
	zinc=DimDelta( $datnam, idir )
	zmax=zmin + (nz-1)*zinc
	zunit=Waveunits($datnam, idir)
	// Z profile
	Redimension/N=(nz) profileZ		//, profileZ_x
	SetScale/P x zmin, zinc, zunit profileZ
	//profileZ_x=zmin+p*zinc
	if (idir==0)	// YZ
		profileZ:=$datnam(x)(root:WinGlobals:ImageTool:X0)(root:WinGlobals:ImageTool:Y0)
	endif
	if (idir==1)	// XZ
		profileZ:=$datnam(root:WinGlobals:ImageTool:X0)(x)(root:WinGlobals:ImageTool:Y0)
	endif
	if (idir==2)	// XY
		profileZ:=$datnam(root:WinGlobals:ImageTool:X0)(root:WinGlobals:ImageTool:Y0)(x)
	endif
	
	// change control ranges
	//ShowWin( "ShowZProfile" )
	SetVariable setSlice limits={0, nz-1,1}
	SetVariable setZ0 limits={zmin, zmax, zinc}
	Label bottom WaveUnits($datnam, idir)

	SelectSlice("", trunc(nz/2), "", "" )
	
	DoWindow/F ImageTool
	Label bottom WaveUnits(Image, 0)
	Label left WaveUnits(Image, 1)
	ImgInfo(Image)
	SetHairXY( "Center", 0, "", "" )
	variable/G dmin=dmin0, dmax=dmax0
	if(lockColors==0)
		AdjustCT()
	endif
	//SetScale/I x dmin0, dmax0,"" root:IMG:RedTemp_CT
	SetProfiles()
	makeImgSlices() //**ER
	updateImgSlices(0)	//**ER
	SetDataFolder $curr
End


Proc SelectSlice(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	PauseUpdate; Silent 1
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	
	if (stringmatch(ctrlName, "SetZ0"))
		Z0=varNum
		islice=round( (Z0-zmin)/zinc )
	else
		islice=varNum
		Z0=zmin + islice*zinc
	endif
	//Cursor/P A, profileZ, islice
	variable str=strsearch(tracenamelist("ImageTool",";",1),"HairZ0",0)
	if(str>=0)
		ModifyGraph/w=imagetool offset(HairZ0)={Z0,0}
	endif
		
	string datnam=imgfldr+imgnam
	//print datnam, islice, islicedir

	VolSlice( $datnam, islice, "/"+"XYZ"[3-islicedir]+"/O=root:IMG:Image"+"/AVG="+num2str(root:IMG:nsliceavg))
	//ExtractSlice( islice, $datnam, "root:IMG:Image", 3-islicedir )
	//Duplicate/O Image Image0, Image_Undo

	//SetProfiles()	
	if (lockColors==0)
		AdjustCT()			// auto-rescale color table; always want on?
	endif
	
	SetDataFolder $curr
End

Proc StepSlice(ctrlName) : ButtonControl
//------------------
	String ctrlName
	
	variable step=root:IMg:zstep
	step*=SelectNumber( stringmatch(ctrlName, "SlicePlus"), -1, 1)
	SelectSlice("", root:IMG:islice+step, "", "" )
End

//** ER added this function	
function animate_slices()
	svar wv=:img:imgnam
	nvar isd=:img:islicedir
	nvar is=:img:islice
	variable nz; string wu
	switch(isd)	// numeric switch
		case 1:		// XY
			nz=dimsize($wv,2)
			wu=waveunits($wv,2)
			break
		case 2:		// XZ
			nz=dimsize($wv,1)
			wu=waveunits($wv,1)
			break
		case 3:		// YZ
			nz=dimsize($wv,0)
			wu=waveunits($wv,0)
			break
	endswitch
	dowindow/f imagetool
	newmovie/L
	string zl
	variable i
	nvar z0=:img:z0
	for(i=0; i<nz; i+=1)
		dowindow/f zprofile
		//selectslice("setslice",i,NUM2STR(i),":img:islice")
		execute "selectslice(\"setslice\"," + num2str(i)+",\"" + num2str(i) +"\", \":img:islice\")"
		setdatafolder root:
		dowindow/f imagetool
		sprintf zl,"%5.3f",z0
		TextBox/C/N=text1 "\JC("+num2str(is)+")\r"+zl+" "+wu
		addmovieframe	
	endfor
	closemovie
end



Proc AnimateAction(ctrlName,popNum,popStr) : PopupMenuControl
//----------
	String ctrlName
	Variable popNum
	String popStr
	
	string newmenu=root:img:anim_menu
	
	IF ((popNum>=3)*(popNum<=11))
		if ((popNum>=3)*(popNum<=5))
			newmenu=ReplaceItemInList( 2, "Ã  "[popNum-3]+" Forward", newmenu, "" )
			newmenu=ReplaceItemInList( 3, " Ã "[popNum-3]+" Backward", newmenu, "" )
			newmenu=ReplaceItemInList( 4, "  Ã"[popNum-3]+" Loop", newmenu, "" )
			root:img:anim_dir=popNum-3
		endif
		if ((popNum>=7)*(popNum<=8))
			newmenu=ReplaceItemInList( 6, "Ã  "[popNum-7]+" Single Pass", newmenu, "" )
			newmenu=ReplaceItemInList( 7, " Ã "[popNum-7]+" Continuous", newmenu, "" )
			root:img:anim_loop=popNum-7
		endif
		if ((popNum>=10)*(popNum<=11))
			newmenu=ReplaceItemInList( 9, "Ã  "[popNum-10]+" Full Range", newmenu, "" )
			newmenu=ReplaceItemInList( 10, " Ã "[popNum-10]+" Cursors", newmenu, "" )
			root:img:anim_range=popNum-10
		endif
		root:img:anim_menu=newmenu
		PopupMenu popAnim value=root:img:anim_menu
	ELSE
		
		variable istart, iend, istep, idir=root:IMG:anim_dir
		istart=SelectNumber( root:img:anim_range, 0, pcsr(A) )
		iend=SelectNumber( root:img:anim_range, root:IMG:nz-1, pcsr(B) )
		istep=root:IMG:zstep * sign( iend-istart)
		
		variable imovie=0
		if (popNum==13)					//single pass SaveMovie
			root:img:anim_loop=0
			imovie=1
			popNum=1
		endif
		
		if (popNum==1)
			if (root:img:anim_loop==1)		// continuous
				DO
					Animate(istart, iend, istep, idir, imovie)
				WHILE(1)
			else								//single pass
				Animate(istart, iend, istep, idir, imovie)
			endif
		endif
	ENDIF

End

Proc Animate(istart, iend, istep, idir, imovie)
//----------
	variable istart, iend, istep, idir, imovie

	variable ii, nslice=abs((iend-istart)/istep)+1
	//print istart, iend, istep, nslice
	
	if (imovie)
		DoWindow/F ImageTool
		NewMovie/L/I
		DoWindow/F Zprofile
	endif
	
	if ((idir==0)+(idir==2))			//Forward
		ii=0
		DO
			SelectSlice("", istart+ii*istep, "", "" )
			if (imovie)
				Dowindow/F ImageTool
				AddMovieFrame
				DoWindow/F ZProfile
			endif
			ii+=1
		WHILE( ii<nslice )
	endif
	
	if  ((idir==1)+(idir==2))			//Backward
		ii=0
		DO
			SelectSlice("", iend-ii*istep, "", "" )
			if (imovie)
				Dowindow/F ImageTool
				AddMovieFrame
				Dowindow/F ZProfile
			endif
			ii+=1
		WHILE( ii<nslice )
	endif
	
	if (imovie)
		CloseMovie
	endif

End


Function/T ImgInfo( image )
//================
// creates variables in current folder
// returns info string
	wave image
	variable/G nx, ny
	variable/G xmin, xinc, xmax, ymin, yinc, ymax, dmin0, dmax0
	nx=DimSize(image, 0); 	ny=DimSize(image, 1)
	xmin=DimOffset(image,0);  ymin=DimOffset(image,1);
	xinc=round(DimDelta(image,0) * 1E6) / 1E6	
	yinc=round(DimDelta(image,1)* 1E6) / 1E6
	xmax=xmin+xinc*(nx-1);	ymax=ymin+yinc*(ny-1);
	WaveStats/Q image
	dmin0=V_min;  dmax0=V_max
	string info="x: "+num2istr(nx)+", "+num2str(xmin)+", "+num2str(xinc)+", "+num2str(xmax)
	info+=    "\r y: "+num2istr(ny)+", "+num2str(ymin)+", "+num2str(yinc)+", "+num2str(ymax)
	info+=    "\r z: "+num2str(dmin0)+", "+num2str(dmax0)
	return info
End

Proc SetProfiles()				//XY profiles
//-------------
	PauseUpdate; Silent 1
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	
		Redimension/N=(nx) profileH, profileH_x
		profileH_x=xmin+p*xinc
//		profileH:=image(profileH_x)(root:WinGlobals:ImageTool:Y0)
		
		Redimension/N=(ny) profileV, profileV_y
		profileV_y=ymin+p*yinc
//		profileV:=image(root:WinGlobals:ImageTool:X0)(profileV_y)
		
		//ImageTool Window must be on top
		DoWindow/F ImageTool
		SetVariable setX0 limits={min(xmin, xmax), max(xmin, xmax), abs(xinc)}
		SetVariable setY0 limits={min(ymin, ymax), max(ymin, ymax), abs(yinc)}
		
	SetDataFolder $curr
End

Proc StepHair(ctrlName) 						//: ButtonControl
//-------------------
// step XYHair offset; automatically updates profiles
	String ctrlName
	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	variable xcur=REAL(coffset), ycur=(IMAG(coffset))
	
	PauseUpdate; Silent 1
	if (CmpStr(ctrlname,"stepRight")==0)
		ModifyGraph offset(HairY0)={xcur+root:IMG:xinc, ycur}
		ModifyGraph offset(HairX1)={xcur+root:IMG:xinc, 0}
	endif
	if (CmpStr(ctrlname,"stepLeft")==0)
		ModifyGraph offset(HairY0)={xcur-root:IMG:xinc, ycur}
		ModifyGraph offset(HairX1)={xcur-root:IMG:xinc, 0}
	endif
	if (CmpStr(ctrlname,"stepUp")==0)
		ModifyGraph offset(HairY0)={xcur, ycur+root:IMG:yinc}
		ModifyGraph offset(HairY1)={0, ycur+root:IMG:yinc}
	endif
	if (CmpStr(ctrlname,"stepDown")==0)
		ModifyGraph offset(HairY0)={xcur, ycur-root:IMG:yinc}
		ModifyGraph offset(HairY1)={0, ycur-root:IMG:yinc}
	endif
	//if (CmpStr(ctrlname,"center")==0)
	//	SetHairXY( "Center", 0, "", "" )
	//endif
End

Function SetHairXY(ctrlName,varNum,varStr,varName) : SetVariableControl
//=================================
//  reposition image cursor offset if X or Y value changed manually from display
//  new cursor offset automatically reupdates X0,Y0 and D0 display values
//  HairY0 must me updated last for UpdateXYGlobals to work properly
	String ctrlName
	Variable varNum
	String varStr
	String varName

	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	variable xcur=REAL(coffset), ycur=(IMAG(coffset)), pcur
	NVAR xmin=root:IMG:xmin, xmax=root:IMG:xmax
	NVAR ymin=root:IMG:ymin, ymax=root:IMG:ymax
	//print "old: ", xcur, ycur
	if (cmpstr(ctrlName,"SetX0")==0)
		ModifyGraph offset(HairX1)={varNum, 0}
		ModifyGraph offset(HairY0)={varNum, ycur}
		setdatafolder img	//**ER
		updateimgslices(2)	//**ER
		setdatafolder ::		//**ER
	endif
	if (cmpstr(ctrlName,"SetY0")==0)
		ModifyGraph offset(HairY1)={0, varNum}
		ModifyGraph offset(HairY0)={xcur, varNum}
		setdatafolder img	//**ER
		updateimgslices(1)	//**ER
		setdatafolder ::		//**ER
	endif
	if (cmpstr(ctrlName,"Check")==0)
//		print xmin,xmax, ymin,ymax
		if ((xcur<xmin)+(xcur>xmax))
			xcur=(xmin+xmax)/2
			ModifyGraph offset(HairX1)={ (xmin+xmax)/2, 0}
			ModifyGraph offset(HairY0)={ (xmin+xmax)/2, ycur}
		endif
		if ((ycur<ymin)+(ycur>ymax))
			ModifyGraph offset(HairY1)={ 0, (ymin+ymax)/2 }
			ModifyGraph offset(HairY0)={ xcur, (ymin+ymax)/2 }
		endif
	endif
	if (CmpStr(ctrlname,"stepLeftRight")==0)
		NVAR xinc=root:IMG:xinc
		pcur=round((xcur-xmin)/xinc)
		xcur=xmin+pcur*xinc
		ModifyGraph offset(HairX1)={xcur+sign(VarNum)*sign(xinc)*xinc, 0}
		ModifyGraph offset(HairY0)={xcur+sign(VarNum)*sign(xinc)*xinc, ycur}
	endif
	if (CmpStr(ctrlname,"stepUpDown")==0)
		NVAR yinc=root:IMG:yinc
		pcur=round((ycur-ymin)/yinc)
		ycur=ymin+pcur*yinc
		ModifyGraph offset(HairY1)={0,      ycur+sign(VarNum)*sign(yinc)*yinc}
		ModifyGraph offset(HairY0)={xcur, ycur+sign(VarNum)*sign(yinc)*yinc}
	endif
	if (cmpstr(ctrlName,"Center")==0)
		ModifyGraph offset(HairX1)={(xmin+xmax)/2, 0 }
		ModifyGraph offset(HairY1)={0, (ymin+ymax)/2 }
		ModifyGraph offset(HairY0)={(xmin+xmax)/2, (ymin+ymax)/2 }
	endif
	if (cmpstr(ctrlName,"ResetCursor")==0)
		Cursor/P A, profileH, round((xcur - DimOffset(root:IMG:Image, 0))/DimDelta(root:IMG:Image,0))
		Cursor/P B, profileV_y, round((ycur - DimOffset(root:IMG:Image, 1))/DimDelta(root:IMG:Image,1))
	endif
End

Function PopFilter(ctrlName,popNum,popStr) : PopupMenuControl
//================
	String ctrlName
	Variable popNum
	String popStr
	
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	
	string keyword=popStr
	variable size=3
	WAVE w=Image
	NVAR npass=root:IMG:numpass
	
	if( CmpStr(keyword,"NaNZapMedian") == 0 )
		if( (WaveType(w) %& (2+4) ) == 0 )
			Abort "Integer image has no NANs to zap!"
			return 0
		endif
	endif

	 // Save current image to backup
	Duplicate/o Image Image_Undo
	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
	imgproc_undo=imgproc
	imgproc+="+ "+keyword+num2istr(npass)
	
	if (popNum<=2)		// Custom Matrix filters
		if( CmpStr(keyword,"AvgX") == 0 )
			make/o CoefM={.25,.5,.25}					// 3x1 average
		endif
		if( CmpStr(keyword,"AvgY") == 0 )
			make/o CoefM={{.25},{.5},{.25}}			// 1x3 average
		endif
		
		variable ipass=0
		DO
			MatrixConvolve CoefM, Image
			ipass+=1
		WHILE( ipass<npass)
	else
		MatrixFilter/N=(size)/P=(npass) $keyword, Image	
	ENDIF
	
	ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	SetDataFolder curr
End

Proc ImgModify(ctrlName, popNum,popStr) : PopupMenuControl
//------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate; Silent 1
	string curr=GetDataFolder(1)
	
	SetDataFolder root:IMG
//	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
//	NVAR nx=nx, ny=ny
	
	Duplicate/o Image Image_Undo
	imgproc_undo=imgproc
	
	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	string opt
	string/G cmd
	
	if (cmpstr(popStr,"Crop")==0)
		string/G x12_crop, y12_crop
		GetMarquee/K left, bottom
		if (V_Flag==1)			//round to nearest data increment
			x12_crop=num2str( xinc*round(V_left/xinc))+","+num2str( xinc*round(V_right/xinc) )		
			y12_crop=num2str( yinc*round(V_bottom/yinc))+","+num2str( yinc*round(V_top/yinc) )
		endif
		ConfirmCrop( )
		opt="/O=Image"
		opt+="/X="+x12_crop+",/Y="+y12_crop
		if (dim_crop==3)		// volume crop
			cmd="VolCrop(Image_Undo,  \""+opt+"\")"
			//VolCrop(, opt)
		else
			cmd="ImgCrop(Image_Undo, \""+opt+"\")"
			ImgCrop(Image_Undo,  opt)
			//Duplicate/O/R=(x1_crop,x2_crop)(y1_crop,y2_crop) Image_Undo, Image
		endif
		print cmd
		if(lockColors==0)
			AdjustCT()
		endif
	endif
	if (cmpstr(popStr,"Transpose")==0)
		MatrixTranspose Image
		ModifyGraph offset(HairY0)={IMAG(coffset), REAL(coffset)}
		ModifyGraph offset(HairX1)={IMAG(coffset), 0}
		ModifyGraph offset(HairY1)={0, REAL(coffset)}
		//print coffset, GetWaveOffset(root:IMG:HairY0)
		 SetAxis/A
	endif
	if (cmpstr(popStr,"Rotate")==0)
		variable/G ang_rot
		
		// Call Rotate Dialog
		//  prompt for rotation angle value or graphical line definition option
		
		//IF (graphical)
			//Redimension/N=2 roty, rotx
			Make/O/N=2 roty, rotx
			GetMarquee/K left, bottom
			if (V_Flag==1)
				rotx={V_left, V_right}
				roty={V_bottom, V_top}
			else
				rotx=(xmin+xmax)/2
				roty={ymin, ymax}
			endif
			AppendToGraph roty vs rotx
			ModifyGraph rgb(roty)=(65535,65535,65535)
			Button DoneRot size={40,18},pos={8,50}, title="Done",  proc=DoneRotate
			GraphWaveEdit roty
			//Need a way to stop edit mode  (create a DONE button)
			// Does programming continue where left off?
			// Try GraphWaveDraw of a two-point line
			//RemoveFromGraph roty
			//KillControl DoneRot
			//Calculate angle
			//call RotateImg(  Image, ang_rot, "Image" )
		//ELSE
		
			//call RotateImg(  Image, ang_rot, "Image" )
		//ENDIF
		
		//print ang_rot
		//Imagerotate/A=(ang_rot)/E=Nan/O Image
	endif
	if (cmpstr(popStr,"Rescale")==0)
		GetMarquee/K left, bottom
		if (V_Flag==1)
			variable/G x1_resize, x2_resize, y1_resize, y2_resize
			x1_resize=V_left; x2_resize=V_right
			y1_resize=V_bottom; y2_resize=V_top
			RescaleImgBox( )
		else
			RescaleImg( )
		endif

	endif
	if (cmpstr(popStr,"Set X=0")==0)
		SetScale/P x xmin-REAL(coffset), xinc,"" Image
		ModifyGraph offset(HairY0)={0, IMAG(coffset)}
	endif
	if (cmpstr(popStr,"Set Y=0")==0)
		SetScale/P y ymin-IMAG(coffset), yinc,"" Image
		ModifyGraph offset(HairY0)={REAL(coffset), 0}
	endif
	if (cmpstr(popStr,"Norm X")==0)
		//make/o/n=(nx) tmp
		//tmp = ProfileH[p]
		//Smooth 3, tmp
		//Image /= tmp[p]
		// AdjustCT()
		variable/G y1_norm, y2_norm
		GetMarquee/K left
		if (V_Flag==1)
			y1_norm=yinc*round(V_bottom/yinc)		//round to nearest data increment
			y2_norm=yinc*round(V_top/yinc)
		endif
		ConfirmYNorm(  )
		//Cursor/P A, profileH, x2pnt( Image, y1_norm) 
		//Cursor/P B, profileH, x2pnt( Image, y2_norm)
		
		make/o/n=(nx) xtmp
		SetScale/P x xmin, xinc, "" xtmp
		xtmp = AREA2D( Image, 1, y1_norm, y2_norm, x )
		Image /= xtmp[p]
		if(lockColors==0)
			 AdjustCT()
		endif
	endif
	if (cmpstr(popStr,"Norm Y")==0)
		variable/G x1_norm, x2_norm
		GetMarquee/K bottom
		if (V_Flag==1)
			x1_norm=xinc*round(V_left/xinc)		//round to nearest data increment
			x2_norm=xinc*round(V_right/xinc)
		endif
		ConfirmXNorm(  )
		Cursor/P A, profileH, x2pnt( Image, x1_norm) 
		Cursor/P B, profileH, x2pnt( Image, x2_norm)
		
		make/o/n=(ny) ytmp
		SetScale/P x ymin, yinc, "" ytmp
		ytmp = AREA2D( Image, 0, x1_norm, x2_norm, x )
		Image /= ytmp[q]
		if(lockcolors==0)
			 AdjustCT()
		endif
	endif
	if (cmpstr(popStr,"Resize")==0)
		ResizeImg(  )
		//SetScale/P x xmin-REAL(coffset), xinc,"" Image
		//ModifyGraph offset(HairY0)={0, IMAG(coffset)}
	endif
	if (cmpstr(popStr,"Rebin X")==0)
		variable nx2=trunc(nx/2)
		xinc*=2
		Redimension/N=(nx2, ny) Image
		SetScale/P x xmin, xinc,"" Image
		variable ii
		DO
			Image[ii][]=( Image_Undo[2*ii][q]+Image_Undo[2*ii+1][q] )  //*0.5
			ii+=1
		WHILE( ii<nx2)
	endif
	if (cmpstr(popStr,"Rebin Y")==0)
		variable ny2=trunc(ny/2)
		yinc*=2
		Redimension/N=(nx, ny2) Image
		SetScale/P y ymin, yinc,"" Image
		variable ii
		DO
			Image[][ii]=( Image_Undo[p][2*ii]+Image_Undo[p][2*ii+1] )  //*0.5
			ii+=1
		WHILE( ii<ny2)
	endif
	if (cmpstr(popStr,"Reflect X")==0)
		Image=Image_Undo(x)[q]+Image_Undo(-x)[q] 
		if(lockColors==0)
			AdjustCT()
		endif
	endif
	if (cmpstr(popStr,"Offset Z")==0)
		GetMarquee/K left, bottom
		If (V_Flag==1)
			Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, imgtmp
			WaveStats/Q imgtmp
			Image=Image_Undo - V_avg
		else
			WaveStats/Q Image
			Image=Image_Undo - V_min
		endif
		if(lockColors==0)
			AdjustCT()
		endif
	endif
	if (cmpstr(popStr,"Norm Z")==0)
		GetMarquee/K left, bottom
		If (V_Flag==1)
			Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, imgtmp
			WaveStats/Q imgtmp
			Image=Image_Undo / V_avg
		else
			//WaveStats/Q Image
			variable normval=Image(root:WinGlobals:ImageTool:X0)(root:WinGlobals:ImageTool:Y0)
			Image=Image_Undo / normval
		endif
		if(lockColors==0)
			AdjustCT()
		endif
	endif
	if (cmpstr(popStr,"Invert Z")==0)
		Image=-Image_Undo
		if(lockColors==0)
			AdjustCT()
		endif
	endif
	if (cmpstr(popStr,"Shift")==0)
		// dialog to specify shift wave, if shift wave, X or Y, expansion
		SetDataFolder $curr
		PromptShift( )
		SetDataFolder root:img:
		string cmd="ShiftImg( Image_Undo, root:"+shiftwn+",\" /O=Image/E="+num2str(shift_expand)
		if (shiftdir==1)
			cmd+="/Y\")"
		else
			cmd+="\")"
		endif
		print cmd
		//ShiftImg( Image_Undo, $shiftwn, "/O=Image/E="+num2str(shift_expand)
		execute cmd
		
		//print ang_rot
		//Imagerotate/A=(ang_rot)/E=Nan/O Image
	endif

	
	ImgInfo( Image )
 	SetProfiles()	
	SetHairXY( "Check", 0, "", "" )
	imgproc+="+ "+popStr			// update this after operation incase of intermediate macro Cancel
	ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	
	SetDataFolder curr
End

Proc DoneRotate(ctrlName) : ButtonControl
//--------------------
	String ctrlName

	GraphNormal
	RemoveFromGraph roty
	KillControl DoneRot
	variable/G ang_rot
	variable dx, dy, slope
	dx=(rotx[1]-rotx[0])
	dy=(roty[1]-roty[0])
	slope=dy/dx
	ang_rot=(180/pi)*atan2( dy/yinc, dx/xinc)
	print ang_rot, "deg (Pixel);", slope, WaveUnits(Image, 1)+"/"+WaveUnits(Image, 0)
	//call DoRotate( Image, ang_rot, "Image")
End

Proc DoneShift(ctrlName) : ButtonControl
//--------------------
	String ctrlName

	GraphNormal
	RemoveFromGraph shifty
	KillControl DoneShift
	//call DoShift( Image, Shiftx, "Image")
End

Proc ConfirmCROP( xrng, yrng, opt, dim )
//------------
	string xrng=StrVarOrDefault("root:IMG:x12_crop", "0,1" )
	string yrng=StrVarOrDefault("root:IMG:y12_crop", "0,1" )
	variable opt=1
	variable dim=NumVarOrDefault("root:IMG:ndim", 2 )-1
	prompt opt, "Range option", popup, "None;Full X;Full Y;Full Axes"
	prompt dim, "Crop option", popup, "Image;Volume"
	
	if ((opt==2)+(opt==4))
		GetAxis/Q bottom
		xrng=num2str(V_min)+","+num2str(V_max) 
	endif
	if ((opt==3)+(opt==4))
		GetAxis/Q left
		yrng=num2str(V_min)+","+num2str(V_max) 
	endif
	String/G root:IMG:x12_crop=xrng, root:IMG:y12_crop=yrng
	Variable/G root:IMG:dim_crop=dim+1
End

Proc ConfirmCROP0( x1, x2, y1, y2, opt )
//------------
	Variable x1=NumVarOrDefault("root:IMG:x1_crop", 0 ), x2=NumVarOrDefault("root:IMG:x2_crop", 1 )
	Variable y1=NumVarOrDefault("root:IMG:y1_crop", 0 ), y2=NumVarOrDefault("root:IMG:y2_crop", 1 )
	variable opt=1
	prompt opt, "Range option", popup, "None;Full X;Full Y;Full Axes"
	
	if ((opt==2)+(opt==4))
		GetAxis/Q bottom 
		x1=V_min; x2=V_max
	endif
	if ((opt==3)+(opt==4))
		GetAxis/Q left
		y1=V_min; y2=V_max
	endif
	Variable/G root:IMG:x1_crop=x1, root:IMG:x2_crop=x2
	Variable/G root:IMG:y1_crop=y1, root:IMG:y2_crop=y2
End


Proc ConfirmNormC( axis, xr, yr )
//------------
	String axis=StrVarOrDefault("root:IMG:axis_norm", "X" )
	Variable/C xr=Cmplx( NumVarOrDefault("root:IMG:x1_norm", 0 ), NumVarOrDefault("root:IMG:x2_norm", 1 ) )
	Variable/C yr=Cmplx( NumVarOrDefault("root:IMG:y1_norm", 0 ), NumVarOrDefault("root:IMG:y2_norm", 1 ) )
	Prompt axis, "Normalization Axis", popup, "X;Y;XY;YX"
	Prompt xr, "X axis range:"
	Prompt yr, "Y axis range:"
	
	String/G root:IMG:axis_norm=axis
	Variable/G root:IMG:x1_norm=REAL(xr), root:IMG:x2_norm=IMAG(xr)
	Variable/G root:IMG:y1_norm=REAL(yr), root:IMG:y2_norm=IMAG(yr)
End

Proc ConfirmNorm( axis, x1, x2, y1, y2 )
//------------
	String axis=StrVarOrDefault("root:IMG:axis_norm", "X" )
	Variable x1=NumVarOrDefault("root:IMG:x1_norm", 0 )
	Variable x2=NumVarOrDefault("root:IMG:x2_norm", 1 )
	Variable y1=NumVarOrDefault("root:IMG:y1_norm", 0 )
	Variable y2=NumVarOrDefault("root:IMG:y2_norm", 1 )
	Prompt axis, "Normalization Axis", popup, "X;Y;XY;YX"
	
	String/G root:IMG:axis_norm=axis
	Variable/G root:IMG:x1_norm=x1, root:IMG:x2_norm=x2
	Variable/G root:IMG:y1_norm=y1, root:IMG:y2_norm=y2
End

Proc ConfirmXNorm( x1, x2, opt )			// xrange
//------------
	Variable x1=NumVarOrDefault("root:IMG:x1_norm", 0 )
	Variable x2=NumVarOrDefault("root:IMG:x2_norm", 1 )
	Variable opt=1
	Prompt opt, "Norm Y option:", popup, "None;Full X"
	
	if (opt==2)
		GetAxis/Q bottom 
		x1=V_min; x2=V_max
	endif

	
	Variable/G root:IMG:x1_norm=x1, root:IMG:x2_norm=x2
End

Proc ConfirmYNorm( y1, y2, opt )			// yrange
//------------
	Variable y1=NumVarOrDefault("root:IMG:y1_norm", 0 )
	Variable y2=NumVarOrDefault("root:IMG:y2_norm", 1 )
	Variable opt=1
	Prompt opt, "Norm X option:", popup, "None;Full Y"
	
	if (opt==2)
		GetAxis/Q left
		y1=V_min; y2=V_max
	endif
	Variable/G root:IMG:y1_norm=y1, root:IMG:y2_norm=y2
End

Proc PromptShift( shftwn, dir, expand )			// Shift Wave parms
//------------
	String shftwn=StrVarOrDefault("root:IMG:shiftwn", "" )
	Variable dir=NumVarOrDefault("root:IMG:shiftdir", 1 )+1
	Variable expand=NumVarOrDefault("root:IMG:shift_expand", 1 )+2
	prompt shftwn, "Shift Wave Name", popup, WaveList("!*_x",";","DIMS:1")
	prompt dir, "Shift Direction", popup, "X;Y"
	prompt expand, "Output Range", popup, "Shrink;Average;Expand[def]"
	
	
	String/G root:IMG:shiftwn=shftwn
	Variable/G root:IMG:shiftdir=dir-1, root:IMG:shift_expand=expand-2
End

Proc PromptEdge( edgewn, fitedge, fitpos )			// Shift Wave parms
//------------
	String edgewn=StrVarOrDefault("root:IMG:edgen", "" )
	Variable fitedge=NumVarOrDefault("root:IMG:edgefit", 1 )+1
	Variable fitpos=NumVarOrDefault("root:IMG:positionfit", 1 )+1
	prompt edgewn, "Output basename (_e, _w)"
	prompt fitedge, "Edge Detection", popup, "Find;Fit"
	prompt fitpos, "Post-fit Edge Postions", popup, "No;Linear;Quadratic"
	
	String/G root:IMG:edgen=edgewn
	Variable/G root:IMG:edgefit=fitedge-1, root:IMG:positionfit=fitpos-1
End

Proc RescaleImg( xopt, xrang, yopt, yrang  )
//------------
	string xrang=num2str(root:IMG:xmin)+", "+num2str(root:IMG:xmax)+", "+num2str(root:IMG:xinc)
	string yrang=num2str(root:IMG:ymin)+", "+num2str(root:IMG:ymax)+", "+num2str(root:IMG:yinc)
	variable xopt, yopt
	prompt xrang, "X-values:  (min,inc) or (min,max) or (center, inc) or (val)"
	prompt yrang, "Y-values:  (min,inc) or (min,max)  or (center, inc) or (val)"
	prompt xopt, "X-axis Rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	prompt yopt, "Y-axis Rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	variable nv, vmin, vinc, dv, pt
	variable/C coffset
	
	// globals will get updated later by ImgInfo()
	if (xopt>1) 
		vmin=str2num(StringFromList(0, xrang, ","))
		nv=ItemsInList(xrang,",")
		vinc=xinc
		if (nv>1) 
			vinc=str2num(StringFromList(nv-1, xrang, ","))
		endif
		if (xopt==2)
			SetScale/P x vmin, vinc , "" Image
		endif
		if (xopt==3) 
			SetScale/I x vmin, str2num(StringFromList(1,xrang ",")), "" Image
		endif
		if (xopt==4)
			SetScale/P x vmin-0.5*(nx-1)*vinc, vinc , "" Image
		endif
		if (xopt==5)
			coffset=GetWaveOffset(root:IMG:HairY0)
			SetScale/P x xmin-REAL(coffset)+vmin, xinc,"" Image
			ModifyGraph offset(HairY0)={vmin, IMAG(coffset)}
		endif
	endif
	if (yopt>1) 
		vmin=str2num(StringFromList(0, yrang, ","))
		nv=ItemsInList(yrang,",")
		vinc=yinc
		if (nv>1) 
			vinc=str2num(StringFromList(nv-1,yrang, ","))
		endif
		if (yopt==2)
			SetScale/P y vmin, vinc , "" Image
		endif
		if (yopt==3) 
			SetScale/I y vmin, str2num(StringFromList(1,yrang, ",")), "" Image
		endif
		if (yopt==4)
			SetScale/P y vmin-0.5*(ny-1)*vinc, vinc , "" Image
		endif
		if (yopt==5)
			coffset=GetWaveOffset(root:IMG:HairY0)
			SetScale/P y ymin-IMAG(coffset)+vmin, yinc,"" Image
			ModifyGraph offset(HairY0)={REAL(coffset), vmin}
		endif
	endif
	SetDataFolder curr
End

Proc RescaleImgBox( opt, xrang, yrang  )
//------------
	variable opt
	string xrang=num2str(root:IMG:x1_resize)+", "+num2str(root:IMG:x2_resize)
	string yrang=num2str(root:IMG:y1_resize)+", "+num2str(root:IMG:y2_resize)
	prompt xrang, "Marquee box X-values:  (left, right)"
	prompt yrang, "Marquee box Y-values:  (bottom, top)"
	prompt opt, "Marquee Box Axis Rescaling:", popup, "X only;Y only;X and Y"
	
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	variable  vmin, vinc, dv, p1, p2, v1, v2
	
	// globals will get updated later by ImgInfo()
	if ((opt==1)+(opt==3)) 
		v1=str2num(StringFromList(0, xrang, ",")); v2=str2num(StringFromList(1, xrang, ","))
		//p1=(x1_resize - DimOffset(image, 0))/DimDelta(image,0)
		//p2=(x2_resize - DimOffset(image, 0))/DimDelta(image,0)
		p1=(x1_resize - xmin)/xinc;   p2=(x2_resize -  xmin)/xinc
		vinc = (v2-v1) / (p2-p1)			
		//vinc=DimDelta(image,0) * (v2-v1)/(x2_resize-x1_resize)
		vmin = str2num(StringFromList(0, xrang, ",")) - vinc*p1
		print "X:", vmin, vinc, p1, p2
		SetScale/P x vmin, vinc , "" Image
		//Set cursors on X profile to range selected
		Cursor/P A, profileH, p1
		Cursor/P B, profileH, p2
	endif
	if (opt>1) 
		v1=str2num(StringFromList(0, yrang, ",")); v2=str2num(StringFromList(1, yrang, ","))
		p1=(y1_resize - ymin)/yinc;   p2=(y2_resize -  ymin)/yinc
		vinc = (v2-v1) / (p2-p1)	
		vmin = str2num(StringFromList(0, yrang, ",")) - vinc*p1
		SetScale/P y vmin, vinc , "" Image
		print "Y:", vmin, vinc, p1,p2
		//Set cursors on X profile to range selected
		Cursor/P A, profileV_y, p1
		Cursor/P B, profileV_y, p2
	endif
	SetDataFolder curr
End


Proc ResizeImg( xyopt, xyval )
//------------
// investigate ImageInterpolate (Igor 4) as option for making smaller 
	variable xyopt
	string xyval=StrVarOrDefault("root:IMG:N_resize", "1,1" )
	prompt xyopt, "Nx, Ny Resize option:", popup, "Interp by N;Interp to Npts;Rebin by N;Thin by N"
	prompt xyval, "(Nx, Ny) or N [=Nx=Ny]"
	
	// interpret xyval string
	variable xval=1, yval=1
	xval=str2num(StringFromList(0, xyval, ","))
	xval=SelectNumber(numtype(yval)==2, xval, 1)    //NaN for single value list
	yval=str2num(StringFromList(1, xyval, ","))
	yval=SelectNumber(numtype(yval)==2, yval, xval)    //NaN for single value list
	//print xval, yval
		
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	string/G N_resize=xyval
	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	
	// globals will get updated later by ImgInfo()
	variable nx2=nx, ny2=ny
	if (xyopt<=2)      //2D interpolate
		//nx2=SelectNumber(xyopt==1, xval, nx*xval)
		//ny2=SelectNumber(xyopt==1, yval, ny*yval)
		Duplicate/o Image tmp		//or use Image_Undo
		if (xyopt==1)
			nx2=round(nx*xval); ny2=round(ny*yval)
			xinc/=xval; yinc/=yval
			//print nx2, ny2, xinc, yinc
			Redimension/N=(nx2, ny2) Image
			SetScale/P x xmin, xinc,"" Image
			SetScale/P y ymin, yinc,"" Image
		endif
		if (xyopt==2)
			xval=round(xval); yval=round(yval)
			nx2=SelectNumber(xval==1, xval, nx)		// don't allow Nx2=1
			ny2=SelectNumber(yval==1, yval, ny)
			//print nx2, ny2
			Redimension/N=(nx2, ny2) Image
			SetScale/I x xmin, xmax,"" Image
			SetScale/I y ymin, ymax,"" Image
		endif
		Image=interp2D(tmp, x, y)
	endif
	if (xyopt>=3)		// Rebin (thin) X, then Y
		variable ii, jj
		nx2=round(nx/xval)
		//ny2=trunc(ny/yval)
		ny2=round(ny/yval)
		// print nx2, ny2
		if (xval>1) 
			Duplicate/o Image tmp
			xinc*=xval
			Redimension/N=(nx2, ny) Image
			SetScale/P x xmin, xinc,"" Image
			ii=0
			DO
				Image[ii][]=0
				if (xyopt==3)				// Rebin X
					jj=0
					Image[ii][]=0
					DO
						Image[ii][]+= tmp[xval*ii+jj][q]
						jj+=1
					WHILE( jj<xval )
					Image[ii][]/=xval
				endif
				if (xyopt==4)				// Thin X
					Image[ii][]+=tmp[xval*ii][q]
				endif
				ii+=1
			WHILE( ii<nx2)
		endif
		if (yval>1) 
			Duplicate/o Image tmp
			yinc*=yval
			Redimension/N=(nx2, ny2) Image
			SetScale/P y ymin, yinc,"" Image
			ii=0
			DO
				Image[][ii]=0
				if (xyopt==3)				// Rebin Y
					jj=0
					Image[][ii]=0
					DO
						Image[][ii]+= tmp[p][yval*ii+jj]
						jj+=1
					WHILE( jj<yval )
					Image[][ii]/=yval
				endif
				if (xyopt==4)				// Thin Y
					Image[][ii]+= tmp[p][yval*ii]
				endif
				ii+=1
			WHILE( ii<ny2)
		endif
	endif
	
	SetDataFolder curr
End


Proc ImgAnalyze(ctrlName, popNum,popStr) : PopupMenuControl
//------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate; Silent 1
	string curr=GetDataFolder(1)
	
	SetDataFolder root:IMG
//	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
//	NVAR nx=nx, ny=ny
	
//	Duplicate/o Image Image_Undo
//	imgproc_undo=imgproc
//	imgproc+="+ "+popStr
	
//	variable/C coffset=GetWaveOffset(root:IMG:HairY0)

	if (popNum<=5)				// get & confirm analysis X-range
		variable/G x1_analysis, x2_analysis
		GetMarquee/K bottom
		if (V_Flag==1)
			x1_analysis=xinc*round(V_left/xinc)		//round to nearest data increment
			x2_analysis=xinc*round(V_right/xinc)
		endif
		ConfirmXAnalysis( )
		Cursor/P A, profileH, x2pnt( Image, x1_analysis) 
		Cursor/P B, profileH, x2pnt( Image, x2_analysis)	
	endif
	
	if (cmpstr(popStr,"Area X")==0)
		string/G root:IMG:arean
		string wn=PickStr( "Area Wave Name", root:IMG:arean, 0)
		root:IMG:arean=wn
		
		SetDataFolder curr
		//wn="root:"+wn
		make/o/n=(root:IMG:ny) $wn
		SetScale/P x root:IMG:ymin, root:IMG:yinc, "" $wn
		$wn = AREA2D( root:IMG:Image,  0, root:IMG:x1_analysis,  root:IMG:x2_analysis, x )
		
		DoWindow/F Area_
		if (V_Flag==0)
			Display $wn
			DoWindow/C Area_
			Area_Style("Area")
		else
			CheckDisplayed/W=Area_  $wn
			if (V_Flag==0)
				Append $wn
			endif
		endif
	endif
	
	if ((cmpstr(popStr,"Find Edge")==0) + (cmpstr(popStr,"Fit Edge")==0))

		//string wn=PickStr( "Edge Base Name", root:IMG:edgen, 0)
		//root:IMG:edgen=wn
		PromptEdge()		//selects edgen, edgefit=(0,1), positionfit=(0,1,2)
		string wn=root:IMG:edgen
		
		SetDataFolder curr
		string ctr=wn+"_e", wdth=wn+"_w"
		make/C/o/n=(root:IMG:ny) $wn
		make/o/n=(root:IMG:ny) $ctr, $wdth
		SetScale/P x root:IMG:ymin, root:IMG:yinc, WaveUnits(root:IMG:Image,0) $wn,  $ctr, $wdth
		
		variable wfrac=0.15*SelectNumber(root:IMG:edgefit==1, 1, -1)	// negative turns on fitting
		variable debug=0
		if (debug)
			iterate( root:IMG:ny )
				$wn = EDGE2D( root:IMG:Image,  root:IMG:x1_analysis,  root:IMG:x2_analysis, pnt2x($wn, i), wfrac )
				PauseUpdate
				ResumeUpdate
				print i
			loop
		else
			$wn = EDGE2D( root:IMG:Image,  root:IMG:x1_analysis,  root:IMG:x2_analysis, x, wfrac )
		endif
		$ctr=REAL( $wn )
		$wdth=IMAG( $wn )
		
		DoWindow/F Edge_
		if (V_Flag==0)
			Display $ctr
			Append/L=wid $wdth
			DoWindow/C Edge_
			Edge_Style()
		else
			CheckDisplayed/W=Edge_  $ctr, $wdth
			if (V_Flag==0)
				Append $ctr
				Append/L=wid $wdth
				print ctr, wdth
				//ModifyGraph lstyle($wdth)=2, rgb($wdth)=(0,0,65535)
			endif
		endif
		ModifyGraph lstyle($wdth)=2, rgb($wdth)=(0,0,65535), mode($wdth)=4
		
		variable fitpos=root:IMG:positionfit
		if (fitpos>0)
			if (fitpos==1)		//linear
				CurveFit line $ctr /D
			else					// quadratic or allow higher?
				CurveFit poly 3, $ctr /D
			endif 
			ModifyGraph rgb($("fit_"+ctr))=(0,65535,0)
		endif
	endif
	
	variable pkmode=0
	if (cmpstr(popStr,"Find Peak Max")==0)
		pkmode=1
		popStr="Find Peak"
	endif

	if (cmpstr(popStr,"Find Peak")==0)
		string/G root:IMG:peakn
		string wn=PickStr( "Peak Base Name", root:IMG:peakn, 0)
		root:IMG:peakn=wn
		
		SetDataFolder curr
		string ctr=wn+"_e", wdth=wn+"_w"
		make/C/o/n=(root:IMG:ny) $wn
		make/o/n=(root:IMG:ny) $ctr, $wdth
		SetScale/P x root:IMG:ymin, root:IMG:yinc, "" $wn,  $ctr, $wdth
		$wn = PEAK2D( root:IMG:Image,  root:IMG:x1_analysis,  root:IMG:x2_analysis,  x, pkmode )
		$ctr=REAL( $wn )
		$wdth=IMAG( $wn )
		
		DoWindow/F Peak_
		if (V_Flag==0)
			Display $ctr
			Append/R $wdth
			DoWindow/C Peak_
			Peak_Style()
		else
			CheckDisplayed/W=Peak_  $ctr, $wdth
			if (V_Flag==0)
				Append $ctr
				Append/R $wdth
				print ctr, wdth
				//ModifyGraph lstyle($wdth)=2, rgb($wdth)=(0,0,65535)
			endif
		endif
		ModifyGraph lstyle($wdth)=2, rgb($wdth)=(0,0,65535), mode($wdth)=4
	endif
	
	if (cmpstr(popStr,"Fit Peak")==0)
		SetDataFolder curr
		DoAlert 0, "Fit peak not implemented yet"
	endif
	
	if (cmpstr(popStr,"Average Y")==0)
		string/G root:IMG:sumn
		string wn=PickStr( "Avg Wave Name", root:IMG:sumn, 0)
		root:IMG:sumn=wn
		
		SetDataFolder curr
		//wn="root:"+wn
		make/o/n=(root:IMG:nx) $wn
		SetScale/P x root:IMG:xmin, root:IMG:xinc, "" $wn
		iterate( root:IMG:ny )
			$wn+=root:IMG:Image[p][i]
		loop
		$wn /= root:IMG:ny
		
		DoWindow/F Sum_
		if (V_Flag==0)
			Display $wn
			DoWindow/C Sum_
			Area_Style("Average")
		else
			CheckDisplayed/W=Sum_  $wn
			if (V_Flag==0)
				Append $wn
			endif
		endif
	endif

	SetDataFolder curr
End

Proc ConfirmXAnalysis( x1, x2 )			// xrange
//------------
	Variable x1=NumVarOrDefault("root:IMG:x1_analysis", 0 )
	Variable x2=NumVarOrDefault("root:IMG:x2_analysis", 1 )
	
	Variable/G root:IMG:x1_analysis=x1, root:IMG:x2_analysis=x2
End

Function AREA2D( img, axis, x1, x2, y0 )
//====================
	wave img
	variable axis, x1, x2, y0
	
	axis*=(axis==1)		// make sure 0 or 1 only
	variable nx=DimSize( img, axis)
	make/O/n=(nx) tmp
	SetScale/P x DimOffset(img,axis), DimDelta(img,axis), "" tmp
	tmp=SelectNumber( axis, img(x)( y0), img(y0)(x) )
	
	return area( tmp, x1, x2)
End

Function/C  EDGE2D_( img, x1, x2, y0, wfrac )
//====================
//return complex value {edge postion, edgewidth}
// wfrac=fraction for width evalution (0-0.5), e.g. 0.1 for 10/90%
	wave img
	variable x1, x2, y0, wfrac
	
	variable nx=DimSize( img, 0)
	make/O/n=(nx) tmp
	CopyScales img, tmp
	tmp=img(x)( y0)
	EdgeStats/Q/F=(wfrac)/R=(x1, x2) tmp
	return CMPLX( V_edgeLoc2,  V_edgeDloc3_1 )
End

Function/C  EDGE2D( img, x1, x2, y0, wfrac )
//====================
//return complex value {edge postion, edgewidth}
	wave img
	variable x1, x2, y0, wfrac
	
	// extract 1D wave
	variable nx=DimSize( img, 0)
	make/O/n=(nx) root:tmp
	WAVE tmp=root:tmp
	CopyScales img, tmp
	tmp=img(x)( y0)
	
	// coef wave
	EdgeStats/Q/F=(abs(wfrac))/R=(x1, x2) tmp
	variable slope=(V_edgeLvl1-V_edgeLvl0)/(V_edgeLoc1-x1)
	make/O root:FEcoef={ V_edgeLoc2, V_edgeDloc3_1, -V_edgeAmp4_0, V_edgeLvl4, slope}
	WAVE FEcoef=root:FEcoef
	
	if (wfrac<0)		// do fit
		FEcoef[1]=FEcoef[1]/4.
		//FuncFit/Q/N Fermi_Fct FEcoef tmp(x1, x2) /D
		FuncFit/Q/N G_step root:FEcoef root:tmp(x1, x2) /D		// /N supresses updates
		return CMPLX( FEcoef[0],  FEcoef[1] )
	else
		return CMPLX( V_edgeLoc2,  V_edgeDloc3_1 )
	endif
End

function G_step(w, xx)
//====================
	wave w
	variable  xx
	variable dx=xx-w[0]
	return( w[3]+w[4]*dx*(dx<0)+w[2]*0.5*erfc(dx/(w[1]/1.66511)) )	
end

Function  Fermi_Fct( w, xx )
//====================
// no Gaussian broadening
	wave w
	variable xx
	variable dx=xx-w[0]
	return (w[3]+w[4]*dx*(dx<0)+ w[2]/(exp(dx/w[1])+1) )
End

Function/C  PEAK2D( img, x1, x2, y0, pkmode )
//====================
//return complex value {peak CENTROID postion, edgewidth}
	wave img
	variable x1, x2, y0, pkmode
	
// extract line profile
	variable nx=DimSize( img, 0)
	make/O/n=(nx) tmp
	CopyScales img, tmp
	tmp=img(x)( y0)
	WaveStats/Q/R=(x1, x2) tmp
//		PulseStats/Q/R=(x1, x2)/L=(V_max,V_min) tmp    ///B=3 boxcar average
	variable hwlvl=(V_max+V_min)/2, lxhw, rxhw
	FindLevel/Q/R=(x1, x2) tmp, hwlvl
		lxhw=V_levelX
	FindLevel/Q/R=(x2, x1) tmp, hwlvl
		rxhw=V_levelX
	variable pkpos, pkwidth
	//Average between  half-height positions OR Peak max location 
	pkpos=SelectNumber(pkmode, (lxhw+rxhw)/2, V_maxloc)				
	pkwidth=abs(rxhw-lxhw)			//Difference between  half-height positions
//		return CMPLX( (V_PulseLoc1+V_PulseLoc2)/2,  V_PulseWidth2_1 )
	return CMPLX( pkpos,  pkwidth )
End

Proc ImageUndo(ctrlName,popNum,popStr) : PopupMenuControl
//--------------------------------
	String ctrlName
	Variable popNum
	String popStr

	string curr=GetDataFolder(1), stmp
	SetDataFolder root:IMG
//	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
//	NVAR nx=nx, ny=ny
	PauseUpdate; Silent 1
	if (cmpstr(popStr,"Restore")==0)
		duplicate/o Image Image_Undo
		duplicate/o Image0 Image
		imgproc_undo=imgproc
		imgproc=""
		ReplaceText/N=title "\Z09"+imgnam
		 SetAxis/A
		 dmin=dmin0;  dmax=dmax0
		if(lockColors==0)
			AdjustCT()
		endif
//		 ModifyImage Image ctab= {*,*,YellowHot,0}
	endif
	if (cmpstr(popStr,"Undo")==0)		//swap Image and Image_Undo
		duplicate/o Image tmp
		duplicate/o Image_Undo Image
		duplicate/o tmp Image_Undo
		stmp=imgproc
		imgproc=imgproc_undo
		imgproc_undo=stmp
		ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
		if(lockColors==0)
			AdjustCT()
		endif
	endif
	ImgInfo( Image )	
	SetProfiles()	
	SetHairXY( "Check", 0, "", "" )
	PopupMenu ImageUndo mode=1		//restore to first item
	SetDataFolder curr
End

Function UpdateXYGlobals(tinfo)
//======================
// Copied from "UpdateHairGlobals" in <Cross Hair Cursors>
	String tinfo
	
	//print tinfo
	tinfo= ";"+tinfo
	
	String s= ";GRAPH:"
	Variable p0= StrSearch(tinfo,s,0),p1
	if( p0 < 0 )
		return 0
	endif
	p0 += strlen(s)
	p1= StrSearch(tinfo,";",p0)
	String gname= tinfo[p0,p1-1]
	String thedf= "root:WinGlobals:"+gname
	if( !DataFolderExists(thedf) )
		return 0
	endif
	
	s= ";TNAME:HairY"
	p0= StrSearch(tinfo,s,0)
	if( p0 < 0 )
		return 0
	endif
	p0 += strlen(s)
	p1= StrSearch(tinfo,";",p0)
	Variable n= str2num(tinfo[p0,p1-1])
	
	String dfSav= GetDataFolder(1)
	SetDataFolder thedf
	
	s= "XOFFSET:"
	p0=  StrSearch(tinfo,s,0)
	if( p0 >= 0 )
		p0 += strlen(s)
		p1= StrSearch(tinfo,";",p0)
		Variable/G $"X"+num2str(n)=str2num(tinfo[p0,p1-1])
	endif
	
	s= "YOFFSET:"
	p0=  StrSearch(tinfo,s,0)
	if( p0 >= 0 )
		p0 += strlen(s)
		p1= StrSearch(tinfo,";",p0)
		Variable/G $"Y"+num2str(n)=str2num(tinfo[p0,p1-1])
	endif
	
//	CreateUpdateZ(gname,n)
	
	SetDataFolder dfSav
end

Function imgTabProc(name,tab)
	String name
	Variable tab
	
	setvariable setx0,disable=(tab!=0)
	setvariable sety0,disable=(tab!=0)
	valdisplay valD0,disable=(tab!=0)
	valdisplay nptx,disable=(tab!=0)
	valdisplay npty,disable=(tab!=0)
	valdisplay nptz,disable=(tab!=0)
	
	popupmenu imageprocess, disable=(tab!=1)
	setvariable setnumpass,disable=(tab!=1)
	popupmenu popFilter, disable=(tab!=1)
	popupmenu imageAnalyze, disable=(tab!=1)
	button stack,disable=(tab!=1)
	setvariable setpinc,disable=(tab!=1)
	popupmenu imageUndo, disable=(tab!=1)

	setvariable setgamma,disable=(tab!=2)
	popupmenu selectct, disable=(tab!=2)
	checkbox lockcolors,disable=(tab!=2)
	popupmenu colorOptions, disable=(tab!=2)
	
	popupmenu popslice, disable=(tab!=3)
	button sliceminus,disable=(tab!=3)
	button sliceplus,disable=(tab!=3)
	setvariable setslice,disable=(tab!=3)
	setvariable setZ0,disable=(tab!=3)
	setvariable setZstep,disable=(tab!=3)
	setvariable setZavg,disable=(tab!=3)		//**JD
	popupmenu volModify,disable=(tab!=3)
	popupmenu popAnim,disable=(tab!=3)
	checkbox ShowImgSlices, disable=(tab!=3)
End

function imgHookfcn ( s )
//===============
//  CMD/CTRL key + mouse motion = dynamical update of cross-hair
//  OPT/ALT key + mouse motion =  left/right/up/down step  of cross-hair
// SHIFT key + mouse motion = bring cross-hair to center
// need to setwindow imagetool hook=imgHookFcn, hookevents=3 to imagetool window
//  Modifier bits:  0001=mousedown, 0010=shift  , 0100=option/alt, 1000=cmd/ctrl
	string s
	variable mousex,mousey,ax,ay, zx,zy,modif, returnval=0
	SVAR dn=root:img:datnam
	NVAR ndim=root:img:ndim, showImgSlices=root:img:showImgSlices

	modif=NumberByKey("modifiers", s)
	//print modif
	if (StrSearch(s,"EVENT:mouse",0)>0)	// could check separately for mousedown & mouseup
		if (modif==3)		// 3 = "0011" =shift +mousedown
			//execute "StepHair(\"center\")"
			execute "SetHairXY( \"Center\", 0, \"\", \"\" )" 
			returnval=3
		else
		if ((modif==9)+(modif==5))
		    // checking for "EVENT:mouse" event screens out "EVENT:modified" new to v4.05A
			variable axmin, axmax, aymin, aymax
			variable zxmin, zxmax, zymin, zymax
			variable xcur, ycur,zcur
			variable/C coffset
			mousex=NumberByKey("mousex", s)
			mousey=NumberByKey("mousey", s)
			ay=axisvalfrompixel("imagetool","left",mousey)
			ax=axisvalfrompixel("imagetool","bottom",mousex)	
			if(ndim==3)
				zy=axisvalfrompixel("imagetool","zy",mousey)
				zx=axisvalfrompixel("imagetool","zx",mousex)	
				zcur=REAL(GetWaveOffset(root:img:hairz0))
				GetAxis/Q zx; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
				GetAxis/Q zy; zymin=min(V_max, V_min); zymax=max(V_min, V_max)
				//print zx, zcur
				zx= SelectNumber((zx>zxmin)*(zx<zxmax)*(zy>zymin)*(zy<zymax), zcur, zx) 
				wave w=$dn
			endif
			if (modif==9)			//9 = "1001" = cmd/ctrl+mousedown
				GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
				GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
				coffset=GetWaveOffset(root:IMG:HairY0)
				xcur=REAL(coffset); ycur=(IMAG(coffset))
				//print ax,  axmax, axmin, ay, aymin, aymax
				ax= SelectNumber((ax>axmin)*(ax<axmax), xcur, ax) 
				ay= SelectNumber((ay>aymin)*(ay<aymax), ycur, ay) 
				//print ax,  axmax, axmin, ay, aymin, aymax
				If ((zx!=zcur)*(ndim==3))
					modifygraph offset(hairz0)={zx,0}
					execute "SelectSlice(\"SetZ0\"," + num2str(zx)+", \"\", \"\" )"
				else
					ModifyGraph offset(HairX1)={ax,0}
					ModifyGraph offset(HairY1)={0,ay}
					ModifyGraph offset(HairY0)={ax,ay}		// must be last updated for hairtrigger
					if ((ndim==3)*showImgSlices)
						setdatafolder img	//**ER
						updateimgslices(0)	//**ER
						setdatafolder ::		//**ER
					endif
				endif
				returnval=1
			endif
			if (modif==5)				// 5 = "0101" = option/alt +mousedown
				if((zx!=zcur)*(ndim==3))
					nvar isd=root:img:islicedir
					variable dz=dimdelta (w,2-(isd-1))
					if(zx>zcur)
						zx=selectnumber((zcur+dz)<zxmax,zcur,zcur+dz)
						modifygraph offset(hairz0)={zx,0}
					else
						zx=selectnumber((zcur-dz)>zxmin,zcur,zcur-dz)
						modifygraph offset(hairz0)={zx,0}
					endif
					execute "SelectSlice(\"SetZ0\"," + num2str(zx)+", \"\", \"\" )"
				else
					variable dx, dy, xrng, yrng, pcur
					//string dir
					NVAR x0=root:WinGlobals:imageTool:x0, y0=root:WinGlobals:imageTool:y0
					GetAxis/Q bottom	//; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
					dx= (ax - x0)/ abs(V_max-V_min)
					GetAxis/Q left		//; aymax=V_max
					dy= (ay - y0) / abs(V_max-V_min)
					// if cursor in X (Y) profiles plot use L/R (U/D)
					//print dy, dx, dy/dx, (ay>aymax),  (ax>axmax)
					//print dx, ax, x0, axmax
					//print dy, ay, y0, aymax
					if (((abs(dy/dx)>=1)))	// + (ay>aymax))*!(ax>axmax))
						//dir="step"+SelectString( dx>0, "Left", "Right")
						//execute "SetHairXY( \"stepLeftRight\", "+num2str(dx)+", \"\", \"\" )"
						NVAR xmin=root:IMG:xmin,  xinc=root:IMG:xinc
						pcur=round((x0-xmin)/xinc)
						x0=xmin+pcur*xinc
						ModifyGraph offset(HairX1)={x0+sign(dx)*sign(xinc)*xinc, 0}
						ModifyGraph offset(HairY0)={x0+sign(dx)*sign(xinc)*xinc, y0}
						if ((ndim==3)*showImgSlices)
							setdatafolder img	//**ER
							updateimgslices(2)	//**ER
							setdatafolder ::		//**ER
						endif
					else	
						//dir="step"+SelectString( dy>0, "Down", "Up")
						//execute "SetHairXY( \"stepUpDown\", "+num2str(dy)+", \"\", \"\" )"
						NVAR ymin=root:IMG:ymin, yinc=root:IMG:yinc
						pcur=round((y0-ymin)/yinc)
						y0=ymin+pcur*yinc
						ModifyGraph offset(HairY1)={0,   y0+sign(dy)*sign(yinc)*yinc}
						ModifyGraph offset(HairY0)={x0, y0+sign(dy)*sign(yinc)*yinc}
						if ((ndim==3)*showImgSlices)
							setdatafolder img	//**ER
							updateimgslices(1)	//**ER
							setdatafolder ::		//**ER
						endif
					endif
					//print dir, abs(dx/dy)
					//execute "StepHair(\"" +dir+"\")"
				endif
				returnval=2
			endif
		endif
		endif
	endif
	return returnval
end

function zHookFcn( s )
//============
//need to setwindow zprofile hook=zHookFcn, hookevents=3 to zprofile window
	string s
	variable ax, ap, mousex, modif, returnval=0
	modif=NumberByKey("modifiers", s)
	if ((modif==9)*(StrSearch(s,"EVENT:mouse",0) > 0)) 	 //9 = "1001" = cmd/ctrl+mousedown
		ap=pcsr(a)
		mousex=NumberByKey("mousex", s)
		ax=axisvalfrompixel("zprofile","bottom",mousex)
		//print ap, ax, mousex
		//Cursor a profilez, ax
		//if (ap!=pcsr(a))
			execute "SelectSlice(\"SetZ0\"," + num2str(ax)+", \"\", \"\" )"
		//endif
		returnval=1
	endif
	if ((modif==5)*(StrSearch(s,"EVENT:mouse",0) > 0))      // 5 = "0101" = option/alt +mousedown
		//ap=pcsr(a)
		mousex=NumberByKey("mousex", s)
		ax=axisvalfrompixel("zprofile","bottom",mousex)
		NVAR Z0=root:img:Z0
		variable dx= ax - Z0
		//print dx, mousex, Z0, ax
		string stepdir=SelectString( dx>0, "Minus", "Plus")
		execute "StepSlice(\"Slice"+stepdir+"\" )"
		returnval=2
	endif
	return returnval
end

Proc AdjustCT() : GraphMarquee
//--------------------
	string curr=GetDataFolder(1)
	SetDataFolder root:IMG
	//Variable/G root:V_min, root:V_max
	GetMarquee/K left, bottom
	If (V_Flag==1)
		Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) root:IMG:Image, root:IMG:imgtmp
		WaveStats/Q root:IMG:imgtmp
		variable px1, px2, py1, py2
		px1=(V_left-DimOffset(root:IMG:Image,0))/ DimDelta(root:IMG:Image,0)
		px2=(V_right-DimOffset(root:IMG:Image,0))/ DimDelta(root:IMG:Image,0)
		py1=(V_bottom-DimOffset(root:IMG:Image,1))/ DimDelta(root:IMG:Image,1)
		py2=(V_top-DimOffset(root:IMG:Image,1))/ DimDelta(root:IMG:Image,1)
		//ImageStats/M=1/G={px1,px2,py1,py2} root:IMG:Image	//requires Igor 4
		//print px1,px2,py1,py2, V_min, V_max
	else
		if(ndim==3)	//**ER
			if(coloroptions==1)	// independently for xy, h, v images
				if(root:img:showImgSlices)
					wavestats/q root:img:h_img; dosetscale(root:IMG:CTinvert, v_min, v_max, "root:img:himg_ct")
					wavestats/q root:img:v_img; dosetscale(root:IMG:CTinvert, v_min, v_max, "root:img:vimg_ct")
				endif
				wavestats/q root:img:image
			else
				variable/g v_min=vol_dmin, v_max=vol_dmax
				if(root:img:showImgSlices)
					dosetscale(root:IMG:CTinvert, v_min, v_max, "root:img:himg_ct")
					dosetscale(root:IMG:CTinvert, v_min, v_max, "root:img:vimg_ct")
				endif
			endif
		else				//**ER
			WaveStats/Q root:IMG:Image
			//ImageStats/M=1 root:IMG:Image		//requires Igor 4
		endif			//**ER
	endif
	variable/G root:IMG:dmin=V_min, root:IMG:dmax=V_max
	dosetscale(root:img:ctinvert, v_min, v_max, "root:img:image_ct")
	killwaves/Z root:IMG:imgtmp
	SetDataFolder $curr
End

//**ER added this
Function dosetScale(inv,mn,mx,wv)	
	variable inv,mn,mx
	string wv
	if(inv<0)
		SetScale/I x mx, mn,"" $wv
	else
		SetScale/I x mn,mx,"" $wv
	endif
end


Proc SelectCT(ctrlName,popNum,popStr) : PopupMenuControl
//--------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate
	if (popNum==1)
		root:IMG:Image_CT:=root:IMG:Gray_CT[pmap[p]][q]
		root:IMG:himg_ct:=root:IMG:Gray_CT[pmap[p]][q]
		root:IMG:vimg_ct:=root:IMG:Gray_CT[pmap[p]][q]
	else
	if (popNum==2)
		root:IMG:Image_CT:=root:IMG:RedTemp_CT[pmap[p]][q]
		root:IMG:himg_ct:=root:IMG:RedTemp_CT[pmap[p]][q]
		root:IMG:vimg_ct:=root:IMG:RedTemp_CT[pmap[p]][q]
	else
	if (popNum==3)
		root:IMG:CTinvert*=-1
		root:IMG:gamma=1/root:IMG:gamma
		if (root:IMG:CTinvert<0)
			PopupMenu SelectCT value="Grayscale;Red Temp;Ã Invert;Rescale"
			SetVariable setgamma limits={0.1,Inf,1}
			SetScale/I x root:IMG:dmax, root:IMG:dmin,"" root:IMG:Image_CT
		else
			PopupMenu SelectCT value="Grayscale;Red Temp;Invert;Rescale"
			SetVariable setgamma limits={0.1,Inf,0.1}
			SetScale/I x root:IMG:dmin, root:IMG:dmax,"" root:IMG:Image_CT
		endif
		if(root:img:showImgSlices)
			wavestats/q root:img:h_img; dosetscale(root:img:ctinvert, v_min, v_max, "root:img:himg_ct")
			wavestats/q root:img:v_img; dosetscale(root:img:ctinvert, v_min, v_max, "root:img:vimg_ct")
		endif
	else
		AdjustCT()		//Rescale
	endif
	endif
	endif
End

Proc Crop() : GraphMarquee
//--------------------
	if (stringmatch(Winname(0,1), "ImageTool")==1)
		ImgModify("", 0,"Crop")
	else
		string x12_crop, y12_crop
		GetMarquee/K left, bottom
		if (V_Flag==1)			//round to nearest data increment
			//x12_crop=num2str( xinc*round(V_left/xinc))+","+num2str( xinc*round(V_right/xinc) )		
			//y12_crop=num2str( yinc*round(V_bottom/yinc))+","+num2str( yinc*round(V_top/yinc) )
			x12_crop=num2str( V_left )+","+num2str( V_right )		
			y12_crop=num2str( V_bottom )+","+num2str( V_top )
		endif
		ConfirmCrop( )
		string imgn=StringfromList(0, ImageNameList("", ";"))
		string opt="/O"		// overwrite
		opt+="/X="+x12_crop+",/Y="+y12_crop

		string cmd="ImgCrop("+imgn+", \""+opt+"\")"
		ImgCrop($imgn,  opt)
		print cmd
	endif
End

Proc NormX() : GraphMarquee
//--------------------
	ImgModify("", 0,"Norm X")
End

Proc NormY() : GraphMarquee
//--------------------
	ImgModify("", 0,"Norm Y")
End

Proc NormZ() : GraphMarquee
//--------------------
	ImgModify("", 0,"Norm Z")
End

Proc OffsetZ() : GraphMarquee
//--------------------
	ImgModify("", 0,"Offset Z")
End

Proc AreaX() : GraphMarquee
//--------------------
	ImgAnalyze("", 0,"Area X")
End

Proc Find_Edge() : GraphMarquee
//--------------------
	ImgAnalyze("", 0, "Find Edge")
End

Proc Find_Peak() : GraphMarquee
//--------------------
	ImgAnalyze("", 0, "Find Peak")
End

Proc ImageName( exportnam )
//------------
	String exportnam=StrVarOrDefault( "root:IMG:exportn", root:IMG:imgnam )
	prompt exportnam, "Export Image Name"
	
	string/G root:IMG:exportn=exportnam
End

Proc ExportAction(ctrlName) : ButtonControl
//======================
	String ctrlName
	
	if (stringmatch(ctrlName,"ExportStack"))
		ExportStack(  )
	else
	if (stringmatch(ctrlName,"ExportVol"))
		ExportImage(,5,)			// export Z-profile
	else
		ExportImage()
	endif
	endif
End

Proc ExportImage( exportn, eopt, dopt )
//======================
	String exportn=StrVarOrDefault( "root:IMG:exportn", "")
	variable eopt=NumVarOrDefault( "root:IMG:exportopt", 1), dopt=NumVarOrDefault( "root:IMG:dispopt", 1)
	prompt eopt, "Export", popup, "Image & CT;Color Table only;X profile;Y profile;Z profile;H-Image&CT;V-Image&CT" [0,56+30*(:img:ndim==3)]//**ER
	prompt dopt, "Option", popup, "Display;Append;None"
	
	string/G root:IMG:exportn=exportn 
	variable/G root:IMG:exportopt=eopt, root:IMG:dispopt=dopt
	//NVAR dmin=root:IMG:dmin,dmax=root:IMG:dmax
	
	SetDataFolder root:
	PauseUpdate; Silent 1
	
	print eopt
	//**ER Added this block
	if (eopt>=6)
		//h or v slice image
		Duplicate/o root:IMG:Image_CT $(exportn+"_CT")
		if(eopt==6)
			GetAxis/Q bottom
			variable left=v_min, right=v_max
			GetAxis/Q imgh
			variable bottom=v_min,top=v_max
			duplicate/o/r=(left,right)(bottom,top) root:img:h_img $(exportn)
		else
			GetAxis/Q imgv
			variable left=v_min, right=v_max
			GetAxis/Q left
			variable bottom=v_min,top=v_max
			duplicate/o/r=(left,right)(bottom,top) root:img:v_img $(exportn)
		endif
		if (dopt<3)
			display; appendimage $exportn
			modifyimage $exportn, cindex=$(exportn+"_CT")
		endif
	endif
	//** END ER
	
	IF (eopt<=2)
		Duplicate/o root:IMG:Image_CT $(exportn+"_CT")
		if (eopt==1)
			//** use only subset from graph axes	
			GetAxis/Q bottom 
			variable left=V_min, right=V_max
			GetAxis/Q left
			variable bottom=V_min, top=V_max
			Duplicate/O/R=(left,right)(bottom,top) root:IMG:Image, $exportn
			
			if (dopt<3)
				Display; Appendimage $exportn
				execute "ModifyImage "+exportn+" cindex= "+exportn+"_CT"
			//	execute "ModifyImage "+exportn+" ctab= {"+num2str(dmin)+", "+num2str(dmax)+", YellowHot,0}"
			//	SetDataFolder root:
			//	ModifyImage newimg ctab= {dmin, dmax, YellowHot,0}   //doesn't work?	
				string titlestr=exportn+": "+num2istr(DimSize($exportn,0))+" x "+num2str(DimSize($exportn,1))
				Textbox/N=title/F=0/A=MT/E titlestr
				
				string winnam=exportn+"_Img"
				DoWindow/F $winnam
				if (V_Flag==1)
					DoWindow/K $winnam
				endif
				DoWindow/C $winnam
			endif
		endif
	//ELSE	//**ER
	ENDIF

	IF((eopt>=3)*(eopt<=5))	
			variable np
		if (eopt==5)		// Z profile
			np=numpnts( root:IMG:profileZ )
			make/o/n=(np) $exportn
			$exportn=root:IMG:profileZ			// already scaled
		else
			if (eopt==4)   		// vertical Y-profile
				np=numpnts( root:IMG:profileV )
				make/o/n=(np) $exportn
				$exportn=root:IMG:profileV
				ScaleWave( $exportn, "root:IMG:profileV_y", 0, 0 )
			else					// horizontal X-profile
				np=numpnts( root:IMG:profileH )
				make/o/n=(np) $exportn
				$exportn=root:IMG:profileH
				ScaleWave( $exportn, "root:IMG:profileH_x", 0, 0 )	
			endif
		endif
		
		if (dopt==1)
			Display $exportn
		else
			if (dopt==2)
				DoWindow/F $WinName(1,1)		// next graph behind ImageTool
				Append $exportn
			endif
		endif
	ENDIF
End

Proc ExportStack( basen )
//======================
	String basen=root:IMG:STACK:basen
	
	SetDataFolder root:
	root:IMG:STACK:basen=basen

	string imgn=root:IMG:imgnam
	variable shift=root:IMG:STACK:shift, offset=root:IMG:STACK:offset
	//variable xmin=root:IMG:STACK:xmin, xinc=root:IMG:STACK:xinc
	
//	string curr=GetDataFolder(1)
//	SetDataFolder root:IMG:STACK
	
	string trace_lst=TraceNameList("Stack_",";",1 )
	variable nt=ItemsInList(trace_lst,";")

	display
	PauseUpdate; Silent 1
	string tn, wn, tval, wnote
	variable ii=0, yval
	DO
		tn="root:IMG:STACK:"+StrFromList(trace_lst, ii, ";")
		yval=NumberByKey( "VAL", note($tn), "=", ",")		// get y-axis value
		wn=basen+num2istr(ii)
		duplicate/o $tn $wn
		$wn+=offset*ii
		//SetScale/P x xmin+shift*ii, xinc,"" wv
		SetScale/P x DimOffset($tn,0),DimDelta($tn,0),"" $wn
		Write_Mod($wn, shift*ii, offset*ii, 1, 0, 0.5, 0, yval, imgn)
		AppendToGraph $wn
		ii+=1
	WHILE( ii<nt )
	
	string winnam=(basen+"_Stack")
	DoWindow/F $winnam
	if (V_Flag==1)
		DoWindow/K $winnam
	endif
	DoWindow/C $winnam
	
//	SetDataFolder curr
End

Function ExportImageFct(ctrlName) : ButtonControl
//======================
	String ctrlName
	
	SetDataFolder root:
//	execute " ImageName()"		// Popup Dialog, put result in root:IMG:exportn
	SVAR exportn=root:IMG:exportn
	exportn=PickStr( "Export Image Name", exportn, 0 )
	
	NVAR dmin=root:IMG:dmin,dmax=root:IMG:dmax
	
	PauseUpdate; Silent 1
	WAVE img=root:IMG:Image
//** use only subset from graph axes	
	GetAxis/Q bottom 
	variable left=V_min, right=V_max
	GetAxis/Q left
	variable bottom=V_min, top=V_max
	Duplicate/O/R=(left,right)(bottom,top) img, $exportn
	WAVE newimg=$exportn
	
	display; appendimage newimg
	WAVE ct=root:IMG:Image_CT
	Duplicate/o ct $(exportn+"_CT")
	execute "ModifyImage "+exportn+" cindex= "+exportn+"_CT"
//	execute "ModifyImage "+exportn+" ctab= {"+num2str(dmin)+", "+num2str(dmax)+", YellowHot,0}"
//	SetDataFolder root:
//	ModifyImage newimg ctab= {dmin, dmax, YellowHot,0}   //doesn't work?	
	string titlestr=exportn+": "+num2istr(DimSize(newimg,0))+" x "+num2str(DimSize(newimg,1))
	Textbox/N=title/F=0/A=MT/E titlestr
	
	string winnam=exportn+"_Img"
	DoWindow/F $winnam
	if (V_Flag==1)
		DoWindow/K $winnam
	endif
	DoWindow/C $winnam
	
End

//macro should not be saved when in 3d mode!  ER
Window ImageTool() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:IMG:
	Display /W=(341,146,993,639) HairY0 vs HairX0 as "ImageTool"
	AppendToGraph/L=lineX profileH vs profileH_x
	AppendToGraph/B=lineY profileV_y vs profileV
	AppendToGraph/L=lineX HairX1 vs HairY1
	AppendToGraph/B=lineY HairY1 vs HairX1
	AppendImage Image
	ModifyImage Image cindex= Image_CT
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(65535,65532,16385)
	ModifyGraph rgb(HairY0)=(0,65535,65535),rgb(HairX1)=(0,65535,65535),rgb(HairY1)=(0,65535,65535)
	ModifyGraph quickdrag(HairY0)=1,quickdrag(HairX1)=1,quickdrag(HairY1)=1
	ModifyGraph offset(HairY0)={352,2.99988},offset(HairX1)={352,0},offset(HairY1)={0,2.99988}
	ModifyGraph mirror(left)=3,mirror(bottom)=3,mirror(lineX)=2,mirror(lineY)=2
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=8
	ModifyGraph fSize=10
	ModifyGraph lblPos(left)=53,lblPos(bottom)=38,lblPos(lineX)=54,lblPos(lineY)=39
	ModifyGraph lblLatPos(lineX)=1,lblLatPos(lineY)=8
	ModifyGraph freePos(lineX)=0
	ModifyGraph freePos(lineY)=0
	ModifyGraph axisEnab(left)={0,0.7}
	ModifyGraph axisEnab(bottom)={0,0.7}
	ModifyGraph axisEnab(lineX)={0.75,1}
	ModifyGraph axisEnab(lineY)={0.75,1}
	ShowInfo
	TextBox/N=title/F=0/A=MT/X=-4.28/Y=1.90/E "\\Z09image"
	ControlBar 50
	Button LoadImg,pos={4,3},size={40,22},proc=NewImg,title="Load"
	Button LoadImg,help={"Select 2D image array in memory to copy to the ImageTool Panel"}
	SetVariable setX0,pos={67,26},size={70,14},proc=SetHairXY,title="X"
	SetVariable setX0,help={"Cross hair X-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setX0,limits={213,491,1},value= root:WinGlobals:ImageTool:X0
	SetVariable setY0,pos={141,26},size={70,14},proc=SetHairXY,title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,limits={-6.00024,12,0.031972},value= root:WinGlobals:ImageTool:Y0
	ValDisplay valD0,pos={214,26},size={61,14},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valD0,value= #"root:WinGlobals:ImageTool:D0"
	ValDisplay nptx,pos={281,26},size={45,14},title="Nx"
	ValDisplay nptx,help={"Number of horizontal pixels of current image."}
	ValDisplay nptx,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nx"
	ValDisplay npty,pos={328,26},size={46,14},title="Ny"
	ValDisplay npty,help={"Number of vertical pixels of current image."}
	ValDisplay npty,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:ny"
	ValDisplay nptz,pos={377,26},size={45,14},title="Nz"
	ValDisplay nptz,help={"Number of slices in 3D data set."}
	ValDisplay nptz,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nz"
	PopupMenu ImageUndo,pos={489,24},size={57,20},disable=1,proc=ImageUndo
	PopupMenu ImageUndo,help={"Undo last image modification or restore to original"}
	PopupMenu ImageUndo,mode=1,popvalue="Undo",value= #"\"Undo;Restore\""
	PopupMenu ImageProcess,pos={70,23},size={65,20},disable=1,proc=ImgModify,title="Modify"
	PopupMenu ImageProcess,help={"Image Modification:\rCrop & Norm Y optionally use a marquee box sub range.\rNorm X(Y),  Set X(Y)=0  use current crosshair location."}
	PopupMenu ImageProcess,mode=0,value= #"\"Crop;Transpose;Rotate;Resize;Rescale;Set X=0;Set Y=0;Norm X;Norm Y;Norm Z;Reflect X;Offset Z;Scale Z;Invert Z;Shift;Splice\""
	SetVariable setnumpass,pos={160,26},size={30,15},disable=1,title=" "
	SetVariable setnumpass,help={"# of passes to apply filter"}
	SetVariable setnumpass,limits={1,9,1},value= root:IMG:numpass
	PopupMenu popFilter,pos={192,24},size={55,20},disable=1,proc=PopFilter,title="Filter"
	PopupMenu popFilter,help={"Convolution -type image modification."}
	PopupMenu popFilter,mode=0,value= #"\"AvgX;AvgY;median;avg;gauss;min;max;NaNZapMedian;FindEdges;Point;Sharpen;SharpenMore;gradN;gradS;gradE;gradW;\""
	PopupMenu ImageAnalyze,pos={385,24},size={72,20},disable=1,proc=ImgAnalyze,title="Analyze"
	PopupMenu ImageAnalyze,help={"Image Analysis within a horizontal (X) range of the image selected by a marquee or A/B Cursors on the horizontal line profile.  Resulting (Area, Position, Width) waves are plotted in an new window with prompted-for names."}
	PopupMenu ImageAnalyze,mode=0,value= #"\"Area X;Find Edge;Fit Edge;Find Peak;Find Peak Max;-;Average Y;\""
	SetVariable setpinc,pos={270,26},size={38,15},disable=1,title=" "
	SetVariable setpinc,help={"Y-increment to stack"}
	SetVariable setpinc,limits={1,20,1},value= root:IMG:STACK:pinc
	Button Stack,pos={313,25},size={45,18},disable=1,proc=UpdateStack,title="Stack"
	Button Stack,help={"Extract spectra from current image and export to separate Stack_  plot window.  Uses current axes limits for extracting spectra."}
	Button ExportImage,pos={4,26},size={56,18},proc=ExportAction,title="Export"
	Button ExportImage,help={"Export current image or profile to a separate window with a new name (prompted for)."}
	SetVariable setgamma,pos={74,26},size={52,14},disable=1,title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol",limits={0.1,Inf,0.1},value= root:IMG:gamma
	PopupMenu SelectCT,pos={153,23},size={43,20},disable=1,proc=SelectCT,title="CT"
	PopupMenu SelectCT,mode=0,value= #"\"Grayscale;Red Temp;Invert;Rescale\""
	Button ShowHelp,pos={44,3},size={18,22},proc=ShowWin,title="?"
	Button ShowHelp,help={"Show shortcut & version history notebook"}
	TabControl imgtab,pos={63,0},size={575,48},proc=imgTabProc,tabLabel(0)="info"
	TabControl imgtab,tabLabel(1)="process",tabLabel(2)="colors"
	TabControl imgtab,tabLabel(3)="volume",value= 0
	SetVariable setZ0,pos={195,26},size={70,15},disable=1,proc=SelectSlice,title="Z"
	SetVariable setZ0,help={"Select/show  value of  current slice of 3D data set."}
	SetVariable setZ0,limits={0,206,1},value= root:IMG:Z0
	SetVariable setSlice,pos={131,25},size={45,15},disable=1,proc=SelectSlice,title=" "
	SetVariable setSlice,help={"Select 3D image slice index."}
	SetVariable setSlice,limits={0,206,1},value= root:IMG:islice
	Button SliceMinus,pos={117,24},size={12,16},disable=1,proc=StepSlice,title="<"
	Button SliceMinus,help={"Decrement image slice index."}
	Button SlicePlus,pos={177,24},size={12,16},disable=1,proc=StepSlice,title=">"
	Button SlicePlus,help={"Increment image slice index."}
	PopupMenu popAnim,pos={465,23},size={74,20},disable=1,proc=AnimateAction,title="Animate"
	PopupMenu popAnim,help={"Step thru slices of 3D data set"}
	PopupMenu popAnim,mode=0,value= #"root:img:anim_menu"
	PopupMenu popSlice,pos={71,21},size={42,20},disable=1,proc=SelectSliceDir
	PopupMenu popSlice,mode=1,popvalue="XY",value= #"\"XY;XZ;YZ\""
	SetVariable setZstep,pos={268,25},size={60,15},disable=1,title="step"
	SetVariable setZstep,limits={1,Inf,1},value= root:IMG:zstep
	SetVariable setZavg,pos={331,25},size={62,15},disable=1,title="navg",proc=SetSliceAvg		//**JD
	SetVariable setZavg,limits={1,Inf,2},value= root:IMG:nsliceavg
	PopupMenu VolModify,pos={394,23},size={65,20},disable=1,proc=VolModify,title="Modify"
	PopupMenu VolModify,mode=0,value= #"\"Crop;Resize;Rescale;Set Z=0;Norm Z;Shift;\""
	CheckBox ShowImgSlices,pos={547,25},size={78,14},disable=1,proc=ShowImgSlicesProc,title="Image Slices"
	CheckBox ShowImgSlices,value= 1
	CheckBox lockColors,pos={219,26},size={80,14},disable=1,proc=ColorLockProc,title="Lock colors?"
	CheckBox lockColors,value= 0
	PopupMenu colorOptions,pos={309,26},size={113,20},disable=1,proc=ColorOptionsProc,title="Set Colors By..."
	PopupMenu colorOptions,mode=0,value= #"\"2D images;All XYZ Data\""
	SetWindow kwTopWin,hook=imgHookFcn,hookevents=3
	ValDisplay version,pos={600,1},size={30,14},fsize=9, title="v4.01",frame=0
	ValDisplay version,limits={0,0,0},barmisc={0,1000},value= #"0"
EndMacro
//PopupMenu SelectZcursor,pos={331,22},size={48,20},disable=1,proc=Zaction,title="Opt"
//PopupMenu SelectZcursor,mode=0,value= #"\"Z = Csr(A)\""

Window ImageTool2() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:IMG:
	Display /W=(364,102,843,587) HairY0 vs HairX0 as "ImageTool"
	AppendToGraph/L=lineX profileH vs profileH_x
	AppendToGraph/B=lineY profileV_y vs profileV
	AppendToGraph/L=lineX HairX1 vs HairY1
	AppendToGraph/B=lineY HairY1 vs HairX1
	AppendImage Image
	ModifyImage Image cindex= Image_CT
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(65535,65532,16385)
	ModifyGraph rgb(HairY0)=(0,65535,65535),rgb(HairX1)=(0,65535,65535),rgb(HairY1)=(0,65535,65535)
	ModifyGraph quickdrag(HairY0)=1,quickdrag(HairX1)=1,quickdrag(HairY1)=1
	ModifyGraph offset(HairY0)={0,75},offset(HairY1)={0,75}
	ModifyGraph mirror(left)=3,mirror(bottom)=3,mirror(lineX)=2,mirror(lineY)=2
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=8
	ModifyGraph fSize=10
	ModifyGraph lblPos(left)=53,lblPos(bottom)=38,lblPos(lineX)=54,lblPos(lineY)=39
	ModifyGraph lblLatPos(lineX)=1,lblLatPos(lineY)=8
	ModifyGraph freePos(lineX)=0
	ModifyGraph freePos(lineY)=0
	ModifyGraph axisEnab(left)={0,0.7}
	ModifyGraph axisEnab(bottom)={0,0.7}
	ModifyGraph axisEnab(lineX)={0.75,1}
	ModifyGraph axisEnab(lineY)={0.75,1}
	Cursor/P A profileH 50;Cursor/P B profileH 50
	ShowInfo
	TextBox/N=title/F=0/A=MT/X=-4.28/Y=1.90/E "\\Z09test_"
	TextBox/N=text0/F=0/X=104.13/Y=-15.00 "\\Z10v4.00"
	ShowTools
	ControlBar 47
	Button LoadImg,pos={4,3},size={40,22},proc=NewImg,title="Load"
	Button LoadImg,help={"Select 2D image array in memory to copy to the ImageTool Panel"}
	SetVariable setX0,pos={50,5},size={70,15},proc=SetHairXY,title="X"
	SetVariable setX0,help={"Cross hair X-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setX0,limits={-25,25,1},value= root:WinGlobals:ImageTool:X0
	SetVariable setY0,pos={126,5},size={70,15},proc=SetHairXY,title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,limits={50,100,1},value= root:WinGlobals:ImageTool:Y0
	ValDisplay valD0,pos={200,5},size={61,14},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valD0,value= #"root:WinGlobals:ImageTool:D0"
	ValDisplay nptx,pos={263,5},size={45,14},title="Nx"
	ValDisplay nptx,help={"Number of horizontal pixels of current image."}
	ValDisplay nptx,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nx"
	ValDisplay npty,pos={311,5},size={46,14},title="Ny"
	ValDisplay npty,help={"Number of vertical pixels of current image."}
	ValDisplay npty,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:ny"
	PopupMenu ImageUndo,pos={411,2},size={57,20},proc=ImageUndo
	PopupMenu ImageUndo,help={"Undo last image modification or restore to original"}
	PopupMenu ImageUndo,mode=1,popvalue="Undo",value= #"\"Undo;Restore\""
	PopupMenu ImageProcess,pos={53,24},size={65,20},proc=ImgModify,title="Modify"
	PopupMenu ImageProcess,help={"Image Modification:\rCrop & Norm Y optionally use a marquee box sub range.\rNorm X(Y),  Set X(Y)=0  use current crosshair location."}
	PopupMenu ImageProcess,mode=0,value= #"\"Crop;Transpose;Rotate;Resize;Rescale;Set X=0;Set Y=0;Norm X;Norm Y;Norm Z;Reflect X;Offset Z;Scale Z;Invert Z;Shift;Splice\""
	SetVariable setnumpass,pos={125,25},size={30,15},title=" "
	SetVariable setnumpass,help={"# of passes to apply filter"}
	SetVariable setnumpass,limits={1,9,1},value= root:IMG:numpass
	PopupMenu popFilter,pos={162,23},size={55,20},proc=PopFilter,title="Filter"
	PopupMenu popFilter,help={"Convolution -type image modification."}
	PopupMenu popFilter,mode=0,value= #"\"AvgX;AvgY;median;avg;gauss;min;max;NaNZapMedian;FindEdges;Point;Sharpen;SharpenMore;gradN;gradS;gradE;gradW;\""
	PopupMenu ImageAnalyze,pos={228,23},size={72,20},proc=ImgAnalyze,title="Analyze"
	PopupMenu ImageAnalyze,help={"Image Analysis within a horizontal (X) range of the image selected by a marquee or A/B Cursors on the horizontal line profile.  Resulting (Area, Position, Width) waves are plotted in an new window with prompted-for names."}
	PopupMenu ImageAnalyze,mode=0,value= #"\"Area X;Find Edge;Fit Edge;Find Peak;Find Peak Max;-;Average Y;\""
	SetVariable setpinc,pos={316,25},size={30,15},title=" "
	SetVariable setpinc,help={"Y-increment to stack"}
	SetVariable setpinc,limits={1,10,1},value= root:IMG:STACK:pinc
	Button Stack,pos={352,24},size={45,18},proc=UpdateStack,title="Stack"
	Button Stack,help={"Extract spectra from current image and export to separate Stack_  plot window.  Uses current axes limits for extracting spectra."}
	Button ExportImage,pos={411,24},size={56,18},proc=ExportAction,title="Export"
	Button ExportImage,help={"Export current image or profile to a separate window with a new name (prompted for)."}
	ValDisplay nptz,pos={360,5},size={46,14},title="Nz"
	ValDisplay nptz,help={"Number of slices in 3D data set."}
	ValDisplay nptz,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nz"
	SetVariable setgamma,pos={351,50},size={52,14},title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol",limits={0.1,Inf,0.1},value= root:IMG:gamma
	PopupMenu SelectCT,pos={405,51},size={43,20},proc=SelectCT,title="CT"
	PopupMenu SelectCT,mode=0,value= #"\"Grayscale;Red Temp;Invert;Rescale\""
	Button ShowZProfile,pos={27,27},size={16,16},proc=ShowWin,title="Z"
	Button ShowZProfile,help={"Show Z profile window& control for 3D volume data sets"}
	Button ShowHelp,pos={5,27},size={16,16},proc=ShowWin,title="?"
	Button ShowHelp,help={"Show shortcut & version history notebook"}
	SetWindow kwTopWin,hook=imgHookFcn,hookevents=3
EndMacro

Window ImageTool1() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:IMG:
	Display /W=(453,143,933,628) HairY0 vs HairX0 as "ImageTool"
	AppendToGraph/L=lineX profileH vs profileH_x	//**ER
	AppendToGraph/B=lineY profileV_y vs profileV	//**ER
	AppendToGraph/R=lineX HairX1 vs HairY1
	AppendToGraph/T=lineY HairY1 vs HairX1
	AppendImage image
	ModifyImage image cindex= Image_CT
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(65535,65532,16385)
	ModifyGraph rgb(HairY0)=(0,65535,65535),rgb(HairX1)=(0,65535,65535),rgb(HairY1)=(0,65535,65535)
	ModifyGraph quickdrag(HairY0)=1,quickdrag(HairX1)=1,quickdrag(HairY1)=1
	ModifyGraph mirror(left)=3,mirror(bottom)=3,mirror(lineX)=1,mirror(lineY)=1
	ModifyGraph minor(left)=1,minor(bottom)=1
	ModifyGraph sep(left)=8,sep(bottom)=8
	ModifyGraph fSize=10
	ModifyGraph lblPos(left)=53,lblPos(bottom)=38,lblPos(lineX)=54,lblPos(lineY)=39
	ModifyGraph lblLatPos(lineX)=1,lblLatPos(lineY)=8
	ModifyGraph freePos(lineX)=0
	ModifyGraph freePos(lineY)=0
	ModifyGraph axisEnab(left)={0,0.7}
	ModifyGraph axisEnab(bottom)={0,0.7}
	ModifyGraph axisEnab(lineX)={0.75,1}
	ModifyGraph axisEnab(lineY)={0.75,1}
	ModifyGraph mirror(lineY)=2,mirror(lineX)=2	//**ER

	Cursor/P A profileH 50;Cursor/P B profileH 50
	ShowInfo
	TextBox/N=title/F=0/A=MT/X=-4.28/Y=1.90/E "\\Z09Acrs_011"
	TextBox/N=text0/F=0/X=104.13/Y=-15 "\\Z10v4.00"
	ControlBar 47
	Button LoadImg,pos={4,3},size={40,22},proc=NewImg,title="Load"
	Button LoadImg,help={"Select 2D image array in memory to copy to the ImageTool Panel"}
	SetVariable setX0,pos={50,5},size={70,15},proc=SetHairXY,title="X"
	SetVariable setX0,help={"Cross hair X-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setX0,limits={99.5,100.5,0.02},value= root:WinGlobals:ImageTool:X0
	SetVariable setY0,pos={126,5},size={70,15},proc=SetHairXY,title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,limits={-3.78489,9.66926,0.106779},value= root:WinGlobals:ImageTool:Y0
	ValDisplay valD0,pos={200,5},size={61,14},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valD0,value= #"root:WinGlobals:ImageTool:D0"
	ValDisplay nptx,pos={263,5},size={45,14},title="Nx"
	ValDisplay nptx,help={"Number of horizontal pixels of current image."}
	ValDisplay nptx,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nx"
	ValDisplay npty,pos={311,5},size={46,14},title="Ny"
	ValDisplay npty,help={"Number of vertical pixels of current image."}
	ValDisplay npty,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:ny"
	PopupMenu ImageUndo,pos={411,2},size={57,20},proc=ImageUndo
	PopupMenu ImageUndo,help={"Undo last image modification or restore to original"}
	PopupMenu ImageUndo,mode=1,popvalue="Undo",value= #"\"Undo;Restore\""
	PopupMenu ImageProcess,pos={53,24},size={65,20},proc=ImgModify,title="Modify"
	PopupMenu ImageProcess,help={"Image Modification:\rCrop & Norm Y optionally use a marquee box sub range.\rNorm X(Y),  Set X(Y)=0  use current crosshair location."}
	PopupMenu ImageProcess,mode=0,value= #"\"Crop;Transpose;Rotate;Resize;Rescale;Set X=0;Set Y=0;Norm X;Norm Y;Norm Z;Reflect X;Offset Z;Scale Z;Invert Z;Shift;Splice\""
	SetVariable setnumpass,pos={125,25},size={30,15},title=" "
	SetVariable setnumpass,help={"# of passes to apply filter"}
	SetVariable setnumpass,limits={1,9,1},value= root:IMG:numpass
	PopupMenu popFilter,pos={162,23},size={55,20},proc=PopFilter,title="Filter"
	PopupMenu popFilter,help={"Convolution -type image modification."}
	PopupMenu popFilter,mode=0,value= #"\"AvgX;AvgY;median;avg;gauss;min;max;NaNZapMedian;FindEdges;Point;Sharpen;SharpenMore;gradN;gradS;gradE;gradW;\""
	PopupMenu ImageAnalyze,pos={228,23},size={72,20},proc=ImgAnalyze,title="Analyze"
	PopupMenu ImageAnalyze,help={"Image Analysis within a horizontal (X) range of the image selected by a marquee or A/B Cursors on the horizontal line profile.  Resulting (Area, Position, Width) waves are plotted in an new window with prompted-for names."}
	PopupMenu ImageAnalyze,mode=0,value= #"\"Area X;Find Edge;Fit Edge;Find Peak;Find Peak Max;-;Average Y;\""
	SetVariable setpinc,pos={316,25},size={30,15},title=" "
	SetVariable setpinc,help={"Y-increment to stack"}
	SetVariable setpinc,limits={1,10,1},value= root:IMG:STACK:pinc
	Button Stack,pos={352,24},size={45,18},proc=UpdateStack,title="Stack"
	Button Stack,help={"Extract spectra from current image and export to separate Stack_  plot window.  Uses current axes limits for extracting spectra."}
	Button ExportImage,pos={411,24},size={56,18},proc=ExportAction,title="Export"
	Button ExportImage,help={"Export current image or profile to a separate window with a new name (prompted for)."}
	ValDisplay nptz,pos={360,5},size={46,14},title="Nz"
	ValDisplay nptz,help={"Number of slices in 3D data set."}
	ValDisplay nptz,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nz"
	SetVariable setgamma,pos={351,50},size={52,14},title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol",limits={0.1,Inf,0.1},value= root:IMG:gamma
	PopupMenu SelectCT,pos={405,51},size={43,20},proc=SelectCT,title="CT"
	PopupMenu SelectCT,mode=0,value= #"\"Grayscale;Red Temp;Invert;Rescale\""
	Button ShowZProfile,pos={27,27},size={16,16},proc=ShowWin,title="Z"
	Button ShowZProfile,help={"Show Z profile window& control for 3D volume data sets"}
	Button ShowHelp,pos={5,27},size={16,16},proc=ShowWin,title="?"
	Button ShowHelp,help={"Show shortcut & version history notebook"}
	SetWindow kwTopWin,hook=imgHookFcn,hookevents=3
EndMacro

// 3D tools on 2D display
	ValDisplay nptx,pos={54,46},size={50,14},title="Nx"
	ValDisplay nptx,help={"Number of horizontal pixels of current image."},fSize=10
	ValDisplay nptx,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nx"
	ValDisplay npty,pos={110,46},size={50,14},title="Ny"
	ValDisplay npty,help={"Number of vertical pixels of current image."},fSize=10
	ValDisplay npty,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:ny"
	PopupMenu popSlice,pos={6,43},size={41,19},proc=SelectSliceDir
	PopupMenu popSlice,mode=1,popvalue="XY",value= #"\"XY;XZ;YZ\""
	ValDisplay nptz,pos={168,46},size={50,14},title="Nz"
	ValDisplay nptz,help={"Number of slices in 3D data set."},fSize=10
	ValDisplay nptz,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nz"
	SetVariable setZ0,pos={210,5},size={70,14},proc=SelectSlice,title="Z"
	SetVariable setZ0,help={"Select/show  value of  current slice of 3D data set."}
	SetVariable setZ0,fSize=10,limits={0,2,1},value= root:IMG:Z0
	SetVariable setSlice,pos={249,47},size={45,14},proc=SelectSlice,title=" "
	SetVariable setSlice,help={"Select 3D image slice index."},fSize=10
	SetVariable setSlice,limits={0,2,1},value= root:IMG:islice
	Button SliceMinus,pos={227,45},size={20,16},proc=StepSlice,title="<<"
	Button SliceMinus,help={"Decrement image slice index."}
	Button SlicePlus,pos={297,46},size={20,16},proc=StepSlice,title=">>"
	Button SlicePlus,help={"Increment image slice index."}
	PopupMenu popAnim,pos={324,46},size={78,19},proc=Animate,title="Animate"
	PopupMenu popAnim,help={"Step thru slices of 3D data set"}
	PopupMenu popAnim,mode=0,value= #"\"Forward;Back;Forward/Back;Back/Forward\""
	Button ExportVol,pos={409,46},size={63,18},title="Export3D"
	Button ExportVol,help={"Export current image to a separate window with a new name (prompted for)."}

Window ZProfile() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:IMG:
	Display /W=(57,309,416,527) profileZ,HairZ0 as "ZProfile"
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(64512,62423,1327)
	ModifyGraph rgb(HairZ0)=(577,43860,60159)
	ModifyGraph offset(HairZ0)={11.828,0}
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph minor=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	Cursor/P A profileZ 10;Cursor/P B profileZ 0
	ShowInfo
	ControlBar 44
	ValDisplay nptz,pos={76,5},size={45,14},title="Nz"
	ValDisplay nptz,help={"Number of slices in 3D data set."}
	ValDisplay nptz,limits={0,0,0},barmisc={0,1000},value= #"root:IMG:nz"
	SetVariable setZ0,pos={204,6},size={70,15},proc=SelectSlice,title="Z"
	SetVariable setZ0,help={"Select/show  value of  current slice of 3D data set."}
	SetVariable setZ0,limits={0,100,2},value= root:IMG:Z0
	SetVariable setSlice,pos={140,5},size={45,15},proc=SelectSlice,title=" "
	SetVariable setSlice,help={"Select 3D image slice index."}
	SetVariable setSlice,limits={0,50,1},value= root:IMG:islice
	Button SliceMinus,pos={126,4},size={12,16},proc=StepSlice,title="<"
	Button SliceMinus,help={"Decrement image slice index."}
	Button SlicePlus,pos={186,4},size={12,16},proc=StepSlice,title=">"
	Button SlicePlus,help={"Increment image slice index."}
	PopupMenu popAnim,pos={31,23},size={80,20},proc=AnimateAction,title="Animate"
	PopupMenu popAnim,help={"Step thru slices of 3D data set"}
	PopupMenu popAnim,mode=0,value= #"root:img:anim_menu"
	Button ExportVol,pos={283,4},size={50,18},proc=ExportAction,title="Export"
	Button ExportVol,help={"Export current image to a separate window with a new name (prompted for)."}
	PopupMenu popSlice,pos={32,3},size={43,20},proc=SelectSliceDir
	PopupMenu popSlice,mode=1,popvalue="XY",value= #"\"XY;XZ;YZ\""
	Button ShowXY,pos={2,4},size={24,16},proc=ShowWin,title="XY"
	PopupMenu SelectZcursor,pos={205,22},size={48,20},proc=Zaction,title="Opt"
	PopupMenu SelectZcursor,mode=0,value= #"\"Z = Csr(A)\""
	SetVariable setZstep,pos={126,25},size={60,15},title="step"
	SetVariable setZstep,limits={1,Inf,1},value= root:IMG:zstep
	PopupMenu VolModify,pos={264,23},size={69,20},proc=VolModify,title="Modify"
	PopupMenu VolModify,mode=0,value= #"\"Crop;Resize;Rescale;Set Z=0;Norm Z;Shift;\""
	SetWindow kwTopWin,hook=zHookFcn,hookevents=3
EndMacro

Proc SetSliceAvg(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName

	//NVAR navg=root:img:nsliceavg
	//NVAR zinc=root:img:zinc
	//WAVE HairZ0=root:img:HairZ0, HairZ0_x=root:img:HairZ0_x
	SetdataFolder root:img:
	nsliceavg=varNum
	if (nsliceavg==1)
		HairZ0={-Inf,0, Inf}; HairZ0_x={0,0,0}
	endif
	if (nsliceavg>1)
		variable x1, x2
		x1=-floor(nsliceavg/2)*zinc
		x2=x1+(nsliceavg-1)*zinc
		HairZ0={-Inf,Inf,-Inf,0, Inf,-Inf,Inf}; 
		HairZ0_x={x1,x1,0,0,0,x2,x2}
	endif
	SetDataFolder root:
	SelectSlice("", root:IMG:islice, "", "" )
End

Proc ShowWin(ctrlName) : ButtonControl
//--------------------
	String ctrlName
	if (stringmatch(ctrlName, "ShowZProfile"))
		DoWindow/F ZProfile
		if (V_flag==0)
			ZProfile()
			//SetWindow kwTopWin,hook=zHookFcn,hookevents=3
			If (!stringmatch( IgorInfo(2), "Macintosh") )
				//Display /W=(104,265,463,483) 
				// Windows: scale window width smaller by 72/96Å0.75
				MoveWindow 100,265,100+(463-104)*0.7,483
			endif
		endif
	else
	if (stringmatch(ctrlName, "ShowHelp"))
		ImageToolHelp()
	else
		DoWindow/F ImageTool
	endif
	endif
End

// *** Stack Procs and Functions *****

Function UpdateStack(ctrlName) : ButtonControl
//================
	String ctrlName
	
	string curr=GetDataFolder(1)
//	SetDataFolder root:IMG
	WAVE img=root:IMG:Image

//** use only subset from marquee or current graph axes	
	variable x1, x2, y1, y2
	GetMarquee/K left, bottom
	if (V_Flag==1)
		x1=V_left; x2=V_right
		y1=V_bottom; y2=V_top
	else
		GetAxis/Q bottom 
		x1=V_min; x2=V_max
		GetAxis/Q left
		y1=V_min; y2=V_max
	endif
	Duplicate/O/R=(x1,x2)(y1,y2) img, root:IMG:Stack:Image

	WAVE imgstack=root:IMG:Stack:Image
	NVAR pinc=root:IMG:STACK:pinc

	WaveStats/Q imgstack
//	print V_min, V_max
	variable/G root:IMG:STACK:dmin=V_min, root:IMG:STACK:dmax=V_max 
	
	string basen="root:IMG:STACK:line"
	variable nw, nx, dir=0
	//nw=ItemsInList( Img2Waves( imgstack, basen, dir ), ";")
	nw=Image2Waves( imgstack, basen, dir, pinc )
	nx=DimSize(root:IMG:STACK:Image, 0)
	variable/G root:IMG:STACK:ymin=y1, root:IMG:STACK:yinc=(y2-y1)/(nw-1)
	variable/G root:IMG:STACK:xmin=x1 , root:IMG:STACK:xinc=(x2-x1)/(nx-1)

	string trace_lst=""
	variable nt=0
	DoWindow/F Stack_
	if (V_flag==0)
		execute "Stack_()"
		If (!stringmatch( IgorInfo(2), "Macintosh") )
			//Display /W=(219,250,540,600)
			// Windows: scale window width smaller by 72/96Å0.75
			MoveWindow 219,250,219+(540-219)*0.7,600
		endif
	endif
	trace_lst=TraceNameList("Stack_",";",1 )
	nt=ItemsInList(trace_lst,";")
//	print nw, nt
	
	variable ii
	if (nw>nt)				//plot additional waves
		ii=nt
		DO
			AppendToGraph $(basen+num2istr(ii))
			ii+=1
		WHILE( ii<nw )
	endif
	
	if (nw<nt)				//remove extra waves
		ii=nw
		DO
//			RemoveFromGraph $(basen+num2istr(ii))
			RemoveFromGraph $StrFromList(trace_lst,ii, ";")
			ii+=1
		WHILE( ii<nt )
	endif
	
	SVAR imgnam=root:IMG:imgnam
	DoWindow/T Stack_,"STACK_: "+imgnam
	
	NVAR dmax=root:IMG:STACK:dmax, dmin=root:IMG:STACK:dmin
	variable shiftinc=DimDelta(imgstack,0), offsetinc, exp
	offsetinc=0.1*(dmax-dmin)
	exp=10^floor( log(offsetinc) )
	offsetinc=round( offsetinc / exp) * exp
//	print offsetinc, exp
	SetVariable setshift limits={-Inf,Inf, shiftinc}
	SetVariable setoffset limits={-Inf,Inf, offsetinc}
	NVAR shift=root:IMG:STACK:shift,  offset=root:IMG:STACK:offset
	shift=0
	offset=offsetinc*(1-2*(offset<0))		//preserve previous sign of offset
	OffsetStack( shift, offset)
	
	SetDataFolder curr
End


Proc SetOffset(ctrlName,varNum,varStr,varName) : SetVariableControl
//---------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	if (cmpstr(ctrlName,"setShift")==0)
		root:IMG:STACK:shift=varNum
	else
		root:IMG:STACK:offset=varNum
	endif
	
	OffsetStack( root:IMG:STACK:shift, root:IMG:STACK:offset)
End

Proc MoveCursor(ctrlName) : ButtonControl
//------------
	String ctrlName
	//root:IMG:STACK:offset=0.5*(root:IMG:STACK:dmax-root:IMG:STACK:dmin)
	//OffsetStack( root:IMG:STACK:shift, root:IMG:STACK:offset)
	variable xcur=xcsr(A), ycur
	if ( numtype(xcur)==0 ) 
	string wvn=CsrWave(A)
		ycur=root:IMG:STACK:ymin + root:IMG:STACK:yinc * str2num( wvn[4,strlen(wvn)-1] )
		DoWindow/F ImageTool
		ModifyGraph offset(HairY0)={xcur, ycur}
		Cursor/P A, profileH, round((xcur - DimOffset(root:IMG:Image, 0))/DimDelta(root:IMG:Image,0))
		Cursor/P B, profileV_y, round((ycur - DimOffset(root:IMG:Image, 1))/DimDelta(root:IMG:Image,1))
	endif
End

Function OffsetStack( shift, offset )
//================
	Variable shift, offset
	
	string trace_lst=TraceNameList("",";",1 )
	variable nt=ItemsInList(trace_lst,";")
//	print nt
	
	variable ii=0
	string wn, cmd
	DO
		wn=StrFromList(trace_lst, ii, ";")
		//print wn
		WAVE w=wn
//		ModifyGraph offset(wn)={ii*shift, ii*offset}
		cmd="ModifyGraph offset("+wn+")={"+num2str(ii*shift)+", "+num2str(ii*offset)+"}"
		execute cmd
		ii+=1
	WHILE( ii<nt )

	return nt
End

Proc StackName( stacknam )
//------------
	String stacknam=StrVarOrDefault( "root:IMG:STACK:basen", root:IMG:imgnam )
	prompt stacknam, "Export Stack Base Name"
	
	string/G root:IMG:STACK:basen=stacknam
End



Function ExportStackFct(ctrlName) : ButtonControl
//======================
	String ctrlName
	
//	execute "StackName()"		// Popup Dialog, put result in root:IMG:STACK:basen
	SVAR basen=root:IMG:STACK:basen
	basen=PickStr( "Export Stack Base Name", basen, 0 )
	SVAR imgn=root:IMG:imgnam
	
	NVAR shift=root:IMG:STACK:shift, offset=root:IMG:STACK:offset
	NVAR xmin=root:IMG:STACK:xmin, xinc=root:IMG:STACK:xinc
	
//	string curr=GetDataFolder(1)
//	SetDataFolder root:IMG:STACK
	
	string trace_lst=TraceNameList("Stack_",";",1 )
	variable nt=ItemsInList(trace_lst,";")

	display
	PauseUpdate; Silent 1
	string tn, wn, tval, wnote
	variable ii=0, yval
	DO
		tn="root:IMG:STACK:"+StrFromList(trace_lst, ii, ";")
		yval=NumberByKey( "VAL", note($tn), "=", ",")		// get y-axis value
		wn=basen+num2istr(ii)
		duplicate/o $tn $wn
		WAVE wv=$wn
		wv+=offset*ii
		//SetScale/P x xmin+shift*ii, xinc,"" wv
		SetScale/P x DimOffset($tn,0),DimDelta($tn,0),"" wv
		Write_Mod($wn, shift*ii, offset*ii, 1, 0, 0.5, 0, yval, imgn)
		//wnote=num2str(shift*ii)+","+num2str(offset*ii)+",1,0,1,0,"+tval
		//Note/K $wn
		//Note $wn wnote
		AppendToGraph $wn
		ii+=1
	WHILE( ii<nt )
	
	string winnam=(basen+"_Stack")
	DoWindow/F $winnam
	if (V_Flag==1)
		DoWindow/K $winnam
	endif
	DoWindow/C $winnam
	
//	SetDataFolder curr
End




Window Stack_() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:IMG:STACK:
	Display /W=(219,250,540,600) line0,line1,line2,line3,line4,line5,line6,line7,line8 as "STACK_: BI"
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(32769,65535,32768)
	ModifyGraph offset(line1)={0,0.2},offset(line2)={0,0.4},offset(line3)={0,0.6},offset(line4)={0,0.8}
	ModifyGraph offset(line5)={0,1},offset(line6)={0,1.2},offset(line7)={0,1.4},offset(line8)={0,1.6}
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=2
	ModifyGraph mirror=1
	ModifyGraph minor=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph fSize=10
	Cursor A line2 -0.0514998;Cursor B line0 0.144501
	ShowInfo
	ControlBar 21
	SetVariable setshift,pos={6,2},size={80,14},proc=SetOffset,title="shift"
	SetVariable setshift,help={"Incremental X shift of spectra."},fSize=10
	SetVariable setshift,limits={-Inf,Inf,0.002},value= root:IMG:STACK:shift
	SetVariable setoffset,pos={90,2},size={90,14},proc=SetOffset,title="offset"
	SetVariable setoffset,help={"Incremental Y offset of spectra."},fSize=10
	SetVariable setoffset,limits={-Inf,Inf,0.2},value= root:IMG:STACK:offset
	Button MoveImgCsr,pos={188,1},size={35,16},proc=MoveCursor,title="Csr"
	Button MoveImgCsr,help={"Reposition cross-hair in Image_Tool panel to the location of the A cursor placed in the Stack_ window."}
	Button ExportStack,pos={233,1},size={50,16},proc=ExportAction,title="Export"
	Button ExportStack,help={"Copy stack spectra to a new window with a specified basename.  Wave notes contain appropriate shift, offset, and Y-value information."}
EndMacro


Proc Area_Style(ylbl) : GraphStyle
	string ylbl
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z rgb[1]=(0,0,65535),rgb[2]=(0,65535,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=4
	Label/Z left ylbl
EndMacro


Proc Edge_Style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z mode[1]=4
	ModifyGraph/Z lStyle[1]=2
	ModifyGraph/Z rgb[1]=(0,0,65535),rgb[2]=(0,65535,0)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=8
	ModifyGraph/Z standoff(left)=0,standoff(bottom)=0
	ModifyGraph/Z axThick=0.5
	ModifyGraph/Z lblPos(left)=69,lblPos(wid)=68
	ModifyGraph/Z lblLatPos(wid)=2
	ModifyGraph/Z freePos(wid)=0
	ModifyGraph/Z axisEnab(left)={0,0.58}
	ModifyGraph/Z axisEnab(wid)={0.62,1}
	Label/Z left "Edge Position"
	Label/Z wid "Edge Width"
EndMacro

Proc Peak_Style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z mode[1]=4
	ModifyGraph/Z lStyle[1]=2
	ModifyGraph/Z rgb[1]=(0,0,65535)
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror(bottom)=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z sep=8
	ModifyGraph/Z fSize=12
	ModifyGraph/Z lblMargin(left)=17,lblMargin(right)=6
	ModifyGraph/Z lblLatPos(left)=-1
	Label/Z left "Peak Position"
	Label/Z right "Edge Width"
	SetAxis/Z/A/E=1 right
EndMacro

