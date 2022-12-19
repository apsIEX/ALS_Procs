//File: Image_Tool4			Created: 6/98
// Jonathan Denlinger, JDDenlinger@lbl.gov
// with contributions from Eli Rotenberg, ERotenberg@lbl.gov and Aaron Bostwick
// v4.028 AB added AutoScaleInRange functions for profiles
// v 4.027 11/1/05 ER - consolidated imagetool5 marquee menus to one submenu
// v  4.026 4/14/04 ER - fixed rotate command.
// v  4.025  1/23/04 ER
//		added support for more color tables not just red and grey
// v 4.024  10/28/03 AB
//		Allow mutiple imagetools and stack windows
//		Supports Legacy Imagetool windows
//		kill datafolder on window close
//		Make initimagetool a function
//		Make all stack procs functions
//		Added stack_getdf(),getswn(df)
//		Added Removeallfromgraph(graphName) killallinfolder(df) which should perhaps be moved to WinUtils or WaveUtils
//		Changing slice direction preseves coursor locations
// 		Add wave name to title string
//		fix volume modify bug introduced by 4.023 fix
// v 4.023,  10/14/03 JD  
//     	fix 3D dataset naming to work for location in subfolders, e.g. root:SES:Load:
//version 4.022 Sep 2 2003 ER
//    	fixed bug with "?" button
//    	fixed bug with incorrect initial color setting
//version 4.021  June 17 2003 ER
//	 	Added "last Marquee" option to adjustCT for volumes
//	 	fixed bug where "Save Movie" required the cursors on the graph even if "full range" is selected
//          3/1/03  JD  - fix ImgModify bugs convert ResizeImg() to general image_util ImgResize()
// v 4.02,  2/21/03 JD 
//    	Added Export TabControl and rewrote export subroutines as separate button control functions
//	  	convert many proc to functions with getdf() routine to define folder
// v 4.01,  2/17/03 JD  
//     	Added Z-slice averaging: VolSlice() instead of ExtractSlice; SetSliceAvg(); 
//   	SetVariable SetZavg; and HairZ0 vs HairZ0_x
// v 4.00, Feb 2003 ER  - merged z tools into XY image window, added color options

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
// (12) Put back OS specific panel resize with new numbers
// (13) Eliminated Proc StackName( ), ImageName( ), ExportAction() -- use DoPrompt in function

#pragma rtGlobals=1		// Use modern global access method.
#pragma version = 4.02
#include <Cross Hair Cursors>
#include "List_util"
#include "Image_util"
#include "wav_util"
#include "volume"
#include "AutoScaleInRange"

menu "GraphMarquee"
	"-"
	submenu "ImageTool4"
		"AreaX"
		"Find_Edge"
		"Find_Peak"
		"ReGridXY"
		"AdjustCT"
		"Crop"
		"NormX"
		"NormY"
		"NormZ"
		"OffsetZ"
		"NoiseStats"
	end
end

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
	"New ImageTool",newimagetool("")
End

Proc ImageToolHelp()
	DoWindow/F ImageToolInfo
	if (V_flag==0)
		string txt
		NewNotebook/W=(100,100,570,400)/F=1/K=1/N=ImageToolInfo
		Notebook ImageToolinfo, showruler=0, backRGB=(45000,65535,65535)
		Notebook ImageToolinfo, fstyle=1, text="Image Tool 4\r"
		Notebook ImageToolinfo, fstyle=0, text="version 4.00, Feb2003 J. Denlinger\r"
		Notebook ImageToolinfo, fstyle=0, text="Contributions by Eli Rotenberg and Aaron Bostwick\r\r"
		
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
			txt+="   v4.02 - Added Export tab +rewrite subroutines(JD)\r"
			txt+="   v4.022 - Added \"Last Marquee\" option to color options for 3d volumes\r"	//!!ER
			txt+="   v4.023 - Fix 3d dataset internal referencing bug for subfolder location\r"	//JD
			txt+="   v4.024 - Added support for multiple imagetools (AB)\r" //ER added line
			txt+="   v4.025 - Added support for more color tables (ER)\r" //ER added line
			txt+="   v4.026 - Fixed rotate command"
			txt+="   v4.027 - Consolidated Marquee Menus"
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

function InitImageTool(df)
//---------
	string df
	string oldfol= getdatafolder(1)
	Silent 1
	NewDataFolder/O/S root:WinGlobals
	NewDataFolder/O/S $("root:WinGlobals:"+df)

	String/G S_TraceOffsetInfo		
	Variable/G hairTrigger
	// Dependencies
       SetFormula hairTrigger,"UpdateXYGlobals(S_TraceOffsetInfo)"
       Setdatafolder root:
	NewDataFolder/O/S $df		
		df="root:"+df+":"
		string/G imgnam, imgfldr, imgproc, imgproc_undo, exportn,datnam=""
		variable/G X0=0, Y0=0, D0
		variable/G nx=51, ny=51,center, width		
		variable/G xmin=0, xinc=1, xmax, ymin=0, yinc=1, ymax
		variable/G dmin0, dmax0, dmin=0, dmax=1
		variable/G numpass=1			//# of filter passes
		variable/G gamma=1, CTinvert=1
		variable /G autoscale=1
		make/o/n=(nx, ny) image,  image0,  image_undo	
		make/o/n=(nx) profileH, profileH_x=p
		make/o/n=(ny) profileV, profileV_y=p
		Make/O HairY0={0,0,NaN,Inf,-Inf}
		Make/O HairX0={-Inf,Inf,NaN,0,0}
		Make/O HairY1={0,0}, HairX1={-Inf,Inf}
		make/o/n=256 pmap=p

		make/o/n=(256,3) RedTemp_CT,  Gray_CT, Image_CT, himg_ct,vimg_ct
		make/o/n=(256,3,41) ALL_CT
		RedTemp_CT[][0]=min(p,176)*370
		RedTemp_CT[][1]=max(p-120,0)*482
		RedTemp_CT[][2]=max(p-190,0)*1000
		Gray_CT=p*256

		variable ii=0
		execute "loadct("+num2str(ii)+")"	//must execute once to ensure colors folder is created
		wave cct=root:colors:ct
		do
			execute "loadct("+num2str(ii)+")"
			ALL_CT[][][ii]=cct[p][q][ii]
			ii+=1
		while(ii<=40)
		
		variable/g  ColorOptions=1, LockColors, marquee_left=0, marquee_right=1,marquee_top=0,marquee_bottom=1 //!!ER
		
		//ImgModify -- create on the fly
		//variable/G x12_crop, y12_crop
		//variable/G x1_norm, x2_norm, y1_norm, y2_norm

		//3D specific
		make/o/n=10 profileZ, profileZ_x
		make/o/n=3 iz_sav={0,0,0}
		Make/O HairZ0={-Inf,0, Inf}, HairZ0_x={0,0,0}
		SetScale/P x 0,1E-7,"" HairZ0
		variable/G ndim=2, islice, nz, iz, Z0, islicedir=1
		variable/G nsliceavg=1			//**JD
		variable/G zmin, zinc, zmax, zstep=1
		string/G zunit=""
		string/G anim_menu= "Go;-;Ã Forward;  Backward;  Loop;-;Ã Single Pass;  Continuous;-;Ã Full Range;  Cursors;-;Save Movie"
		variable/G anim_dir=0, anim_loop=0, anim_range=0
		make/o/n=(2,2) h_img, v_img 	//**ER
		h_img=NaN							//**ER
		v_img=NaN							//**ER
		variable/g showImgSlices=1, vol_dmin, vol_dmax
		
		//print df
		// Dependencies
		//$(df+"pmap") := 255*(p/255)^$(df+"gamma")
		setformula $(df+"pmap") , "255*(p/255)^"+df+"gamma)"

		//pmap:=255*(p/255)^(10^gamma)       // log(Gamma) works best in range {-1,+1} with 0.1 increment
		//Image_CT:=dmin+RedTemp_CT[pmap[p]][q]*(dmax-dmin)/255
		
		//$(df+"Image_CT") :=RedTemp_CT[pmap[p]][q]	//  /255
		setformula $(df+"Image_CT") ,"RedTemp_CT[pmap[p]][q]"
		//$(df+"himg_ct")   :=RedTemp_CT[pmap[p]][q]
		setformula $(df+"himg_ct")  ,"RedTemp_CT[pmap[p]][q]"
		setformula $(df+"vimg_ct")  ,"RedTemp_CT[pmap[p]][q]"
		setformula $(df+"profileH") , "image("+df+"profileH_x)("+df+"Y0)"
		//$(df+"profileV"):=image($(df+"X0"))($(df+"profileV_y"))
		setformula $(df+"profileV"), "image("+df+"X0)("+df+"profileV_y)"
		//profileZ:=$datnam(root:ImageTool:X0)(root:ImageTool:Y0)(x)
		//$(df+"D0"):=$(df+"image")($(df+"X0"))($(df+"Y0"))
		setformula $(df+"D0") ,  df+"image)("+df+"X0)("+df+"Y0)"

		// Nice pretty initial image
		SetScale/I x -25,25,"" image, image0;  SetScale/I y -25,25,"" image, image0
		image=cos((pi/10)*sqrt(x^2+y^2+z^2))*cos( (2.5*pi)*atan2( y, x))
		SetScale/I y 50,100,"" image, image0

		image0=image; image_undo=image
		ImgInfo(Image)
		
	NewDataFolder/O/S $(df+"STACK")
//		make/o/n=10 line0, line1, line2
		variable/G xmin=0, xinc=1, ymin=0, yinc=1, dmin=0, dmax=1
		variable/G shift=0, offset=0, pinc=1
		string/G basen
	SetDataFolder root:
End

 
 function/S newimagetool( img )
//----------------
		string img
	//DoWindow/F ImageTool
		string df=uniquename("ImageTool",11,0)
		InitImageTool(df)
		Image_Tool("root:"+df+":")
		DoWindow/C $df
			
		SetProfiles()
		SetHairXY( "Check", 0, "", "" )
	
		//Resize Panel (OS specific)
		string os=IgorInfo(2)
		//**ER commented next lines out
		// JDD commented resize back in with new #s
		if (stringmatch(os[0,2],"Win"))
			MoveWindow/W=$df 341,146,824,608
		else	   //Mac
			//MoveWindow/W=ImageTool 341,146,993,639   
		endif
		
		AdjustCT() 
		SetWindow $df hook=imgHookFcn, hookevents=3
		
		string screen=IgorInfo(0)
		screen=StringByKey( "SCREEN1", screen, ":" )
		//print os, screen
		print df
		if(strlen(img)>0)
			NewImg(img)
		endif
		return df
		
end

 
Proc ShowImageTool( )
//----------------
	PauseUpdate; Silent 1
	DoWindow/F ImageTool
	if (V_flag==0)
		InitImageTool("ImageTool")
		Image_Tool("root:ImageTool:")
		DoWindow/C ImageTool
			
		SetProfiles()
		SetHairXY( "Check", 0, "", "" )
	
		//Resize Panel (OS specific)
		string os=IgorInfo(2)
		//**ER commented next lines out
		// JDD commented resize back in with new #s
		if (stringmatch(os[0,2],"Win"))
			MoveWindow/W=ImageTool 341,146,824,608
		else	   //Mac
			//MoveWindow/W=ImageTool 341,146,993,639   
		endif
		
		AdjustCT() 
		SetWindow imagetool hook=imgHookFcn, hookevents=3
		
		string screen=IgorInfo(0)
		screen=StringByKey( "SCREEN1", screen, ":" )
		//print os, screen
	endif
end

Function Image_Tool(df) : Graph
	String df
	PauseUpdate; Silent 1		// building window...
	String  fldrSav= GetDataFolder(1)
	SetDataFolder $df
		//NVAR X0=X0, Y0=Y0, D0=D0, nx=nx, ny=ny, nz=nz
		//NVAR zstep=zstep, nsliceavg=nsliceavg
		//SVAR anim_menu=anim_menu
		WAVE HairY0=HairY0, HairX0=HairX0, HairY1=HairY1, HairX1=HairX1
		WAVE profileH=profileH, profileH_x=profileH_x, profileV=profileV, profileV_y
		WAVE image=Image, Image_CT=Image_CT
	SetDataFolder $fldrSav
	string dfn=stringfromlist(1,df,":")
	Display /k=1 /W=(341,146,993,639) HairY0 vs HairX0 as dfn
	AppendToGraph/L=lineX profileH vs profileH_x
	AppendToGraph/B=lineY profileV_y vs profileV
	AppendToGraph/L=lineX HairX1 vs HairY1
	AppendToGraph/B=lineY HairY1 vs HairX1
	AppendImage Image
	ModifyImage Image cindex= Image_CT
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(65535,65532,16385)
	ModifyGraph rgb(HairY0)=(0,65535,65535),rgb(HairX1)=(0,65535,65535),rgb(HairY1)=(0,65535,65535)
	ModifyGraph quickdrag(HairY0)=0,quickdrag(HairX1)=0,quickdrag(HairY1)=0
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
	SetVariable setX0,limits={213,491,1},value=$(df+"X0")	//root:ImageTool:X0
	SetVariable setY0,pos={141,26},size={70,14},proc=SetHairXY,title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,limits={-6.00024,12,0.031972},value= $(df+"Y0")
	ValDisplay valD0,pos={214,26},size={61,14},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,limits={0,0,0},barmisc={0,1000}
		//ValDisplay valD0,value= D0			//can't use local variables
		execute "ValDisplay valD0,value="+df+"D0"	
	ValDisplay nptx,pos={281,26},size={45,14},title="Nx"
	ValDisplay nptx,help={"Number of horizontal pixels of current image."}
	ValDisplay nptx,limits={0,0,0},barmisc={0,1000}			//,value= nx
		execute "ValDisplay nptx,value="+df+"nx"
	ValDisplay npty,pos={328,26},size={46,14},title="Ny"
	ValDisplay npty,help={"Number of vertical pixels of current image."}
	ValDisplay npty,limits={0,0,0},barmisc={0,1000}		//,value=ny
		execute "ValDisplay npty,value="+df+"ny"
	ValDisplay nptz,pos={377,26},size={45,14},title="Nz"
	ValDisplay nptz,help={"Number of slices in 3D data set."}
	ValDisplay nptz,limits={0,0,0},barmisc={0,1000}			//,value= root:ImageTool:nz
	execute "ValDisplay nptz,value="+df+"nz"
	PopupMenu ImageUndo,pos={489,24},size={57,20},disable=1,proc=ImageUndo
	PopupMenu ImageUndo,help={"Undo last image modification or restore to original"}
	PopupMenu ImageUndo,mode=1,popvalue="Undo",value= #"\"Undo;Restore\""
	PopupMenu ImageProcess,pos={70,23},size={65,20},disable=1,proc=ImgModify,title="Modify"
	PopupMenu ImageProcess,help={"Image Modification:\rCrop & Norm Y optionally use a marquee box sub range.\rNorm X(Y),  Set X(Y)=0  use current crosshair location."}
	PopupMenu ImageProcess,mode=0,value= #"\"Crop;Transpose;Rotate;Resize;Rescale;Set X=0;Set Y=0;Norm X;Norm Y;Norm Z;Reflect X;Offset Z;Scale Z;Invert Z;Shift;Splice\""
	SetVariable setnumpass,pos={160,26},size={30,15},disable=1,title=" "
	SetVariable setnumpass,help={"# of passes to apply filter"}
	SetVariable setnumpass,limits={1,9,1},value= $(df+"numpass")
	PopupMenu popFilter,pos={192,24},size={55,20},disable=1,proc=PopFilter,title="Filter"
	PopupMenu popFilter,help={"Convolution -type image modification."}
	PopupMenu popFilter,mode=0,value= #"\"AvgX;AvgY;median;avg;gauss;min;max;NaNZapMedian;FindEdges;Point;Sharpen;SharpenMore;gradN;gradS;gradE;gradW;\""
	PopupMenu ImageAnalyze,pos={385,24},size={72,20},disable=1,proc=ImgAnalyze,title="Analyze"
	PopupMenu ImageAnalyze,help={"Image Analysis within a horizontal (X) range of the image selected by a marquee or A/B Cursors on the horizontal line profile.  Resulting (Area, Position, Width) waves are plotted in an new window with prompted-for names."}
	PopupMenu ImageAnalyze,mode=0,value= #"\"Area X;Find Edge;Fit Edge;Find Peak;Find Peak Max;-;Average Y;\""
	SetVariable setpinc,pos={270,26},size={38,15},disable=1,title=" "
	SetVariable setpinc,help={"Y-increment to stack"}
	SetVariable setpinc,limits={1,20,1},value= $(df+"STACK:pinc")
	Button Stack,pos={313,25},size={45,18},disable=1,proc=UpdateStack,title="Stack"
	Button Stack,help={"Extract spectra from current image and export to separate Stack_  plot window.  Uses current axes limits for extracting spectra."}
	
	SetVariable setgamma,pos={74,26},size={52,14},disable=1,title="g",limits={0.05,Inf,0.1}
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol",limits={0.1,Inf,0.1},value= $(df+"gamma")
	PopupMenu SelectCT,pos={153,23},size={43,20},disable=1,proc=SelectCT,title="CT"
	//PopupMenu SelectCT,mode=0,value= #"\"Grayscale;Red Temp;Invert;Rescale\""
	Popupmenu selectCT,mode=0,value="Invert;Rescale;"+colornameslist()
	Button ShowHelp,pos={44,3},size={18,22},proc=ShowWin,title="?"
	Button ShowHelp,help={"Show shortcut & version history notebook"}
	TabControl imgtab,pos={63,0},size={575,48},proc=imgTabProc,tabLabel(0)="info"
	TabControl imgtab,tabLabel(1)="process",tabLabel(2)="colors"
	TabControl imgtab,tabLabel(3)="volume",tabLabel(4)="export",value= 0
	SetVariable setZ0,pos={195,26},size={70,15},disable=1,proc=SelectSlice,title="Z"
	SetVariable setZ0,help={"Select/show  value of  current slice of 3D data set."}
	SetVariable setZ0,limits={0,206,1},value= $(df+"Z0")
	SetVariable setSlice,pos={131,25},size={45,15},disable=1,proc=SelectSlice,title=" "
	SetVariable setSlice,help={"Select 3D image slice index."}
	SetVariable setSlice,limits={0,206,1},value= $(df+"islice")
	Button SliceMinus,pos={117,24},size={12,16},disable=1,proc=StepSlice,title="<"
	Button SliceMinus,help={"Decrement image slice index."}
	Button SlicePlus,pos={177,24},size={12,16},disable=1,proc=StepSlice,title=">"
	Button SlicePlus,help={"Increment image slice index."}
	PopupMenu popAnim,pos={465,23},size={74,20},disable=1,proc=AnimateAction,title="Animate"
	PopupMenu popAnim,help={"Step thru slices of 3D data set"}
	PopupMenu popAnim,mode=0	//,value= "\""+$(df+"anim_menu")+"\""	//root:ImageTool:anim_menu	//#anim_menu
		execute "PopupMenu popAnim,value="+df+"anim_menu"
	PopupMenu popSlice,pos={71,21},size={42,20},disable=1,proc=SelectSliceDir
	PopupMenu popSlice,mode=1,popvalue="XY",value= #"\"XY;XZ;YZ\""
	SetVariable setZstep,pos={268,25},size={60,15},disable=1,title="step"
	SetVariable setZstep,limits={1,Inf,1},value= $(df+"zstep")
	SetVariable setZavg,pos={331,25},size={62,15},disable=1,title="navg",proc=SetSliceAvg		//**JD
	SetVariable setZavg,limits={1,Inf,2},value= $(df+"nsliceavg")
	PopupMenu VolModify,pos={394,23},size={65,20},disable=1,proc=VolModify,title="Modify"
	PopupMenu VolModify,mode=0,value= #"\"Crop;Resize;Rescale;Set Z=0;Norm Z;Shift;\""
	CheckBox ShowImgSlices,pos={547,25},size={78,14},disable=1,proc=ShowImgSliceCheck,title="Image Slices"
	CheckBox ShowImgSlices,value= 1

	CheckBox smartautoscale,pos={547,25},size={78,14},disable=1,title="Smart Scale Profiles?",variable = $(df+"autoscale")
	CheckBox smartautoscale,value= 1

	CheckBox lockColors,pos={219,26},size={80,14},disable=1,proc=ColorLockCheck,title="Lock colors?"
	CheckBox lockColors,value= 0
	PopupMenu colorOptions,pos={309,26},size={113,20},disable=1,proc=ColorOptionsProc,title="Set Colors By..."
	PopupMenu colorOptions,mode=0,value= #"\"2D images;All XYZ Data;Last Marquee\""  //!!ER
	Button exportprofile,pos={77,22},size={50,20},disable=1,title="Profile", proc=ExportProfileFct
	Button exportprofile,help={"Export X, Y or Z profile to a separate plot (name prompted for)."}
	Button exportimage,pos={137,22},size={50,20},disable=1,title="Image", proc=ExportImageFct
	Button exportimage,help={"Export current image or H or V slice to a separate window (name prompted for)."}
	Button exportvolume,pos={197,22},size={55,20},disable=1,title="Volume", proc=ExportVolumeFct
	Button exportvolume,help={"Export current (modified) volume to root (name prompted for)."}
	ValDisplay version,pos={595,1},size={35,14},fsize=9, title="v4.027",frame=0
	ValDisplay version,limits={0,0,0},barmisc={0,1000},value= #"0"
	SetWindow kwTopWin,hook=imgHookFcn,hookevents=3
EndMacro

//macro should not be saved when in 3d mode!  ER
Window ImageTool() : Graph
	PauseUpdate; Silent 1		// building window...
	String df=getdf1()
	String  fldrSav= GetDataFolder(1)
	SetDataFolder $df
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
	ModifyGraph quickdrag(HairY0)=0,quickdrag(HairX1)=0,quickdrag(HairY1)=0
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
	SetVariable setX0,limits={213,491,1},value= root:ImageTool:X0
	SetVariable setY0,pos={141,26},size={70,14},proc=SetHairXY,title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,limits={-6.00024,12,0.031972},value= root:ImageTool:Y0
	ValDisplay valD0,pos={214,26},size={61,14},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valD0,value= #"root:ImageTool:D0"
	ValDisplay nptx,pos={281,26},size={45,14},title="Nx"
	ValDisplay nptx,help={"Number of horizontal pixels of current image."}
	ValDisplay nptx,limits={0,0,0},barmisc={0,1000},value= root:ImageTool:nx
	ValDisplay npty,pos={328,26},size={46,14},title="Ny"
	ValDisplay npty,help={"Number of vertical pixels of current image."}
	ValDisplay npty,limits={0,0,0},barmisc={0,1000},value=root:ImageTool:ny
	ValDisplay nptz,pos={377,26},size={45,14},title="Nz"
	ValDisplay nptz,help={"Number of slices in 3D data set."}
	ValDisplay nptz,limits={0,0,0},barmisc={0,1000},value= root:ImageTool:nz
	PopupMenu ImageUndo,pos={489,24},size={57,20},disable=1,proc=ImageUndo
	PopupMenu ImageUndo,help={"Undo last image modification or restore to original"}
	PopupMenu ImageUndo,mode=1,popvalue="Undo",value= #"\"Undo;Restore\""
	PopupMenu ImageProcess,pos={70,23},size={65,20},disable=1,proc=ImgModify,title="Modify"
	PopupMenu ImageProcess,help={"Image Modification:\rCrop & Norm Y optionally use a marquee box sub range.\rNorm X(Y),  Set X(Y)=0  use current crosshair location."}
	PopupMenu ImageProcess,mode=0,value= #"\"Crop;Transpose;Rotate;Resize;Rescale;Set X=0;Set Y=0;Norm X;Norm Y;Norm Z;Reflect X;Offset Z;Scale Z;Invert Z;Shift;Splice\""
	SetVariable setnumpass,pos={160,26},size={30,15},disable=1,title=" "
	SetVariable setnumpass,help={"# of passes to apply filter"}
	SetVariable setnumpass,limits={1,9,1},value= $(df+"numpass")
	PopupMenu popFilter,pos={192,24},size={55,20},disable=1,proc=PopFilter,title="Filter"
	PopupMenu popFilter,help={"Convolution -type image modification."}
	PopupMenu popFilter,mode=0,value= #"\"AvgX;AvgY;median;avg;gauss;min;max;NaNZapMedian;FindEdges;Point;Sharpen;SharpenMore;gradN;gradS;gradE;gradW;\""
	PopupMenu ImageAnalyze,pos={385,24},size={72,20},disable=1,proc=ImgAnalyze,title="Analyze"
	PopupMenu ImageAnalyze,help={"Image Analysis within a horizontal (X) range of the image selected by a marquee or A/B Cursors on the horizontal line profile.  Resulting (Area, Position, Width) waves are plotted in an new window with prompted-for names."}
	PopupMenu ImageAnalyze,mode=0,value= #"\"Area X;Find Edge;Fit Edge;Find Peak;Find Peak Max;-;Average Y;\""
	SetVariable setpinc,pos={270,26},size={38,15},disable=1,title=" "
	SetVariable setpinc,help={"Y-increment to stack"}
	SetVariable setpinc,limits={1,20,1},value= $(df+"STACK:pinc")
	Button Stack,pos={313,25},size={45,18},disable=1,proc=UpdateStack,title="Stack"
	Button Stack,help={"Extract spectra from current image and export to separate Stack_  plot window.  Uses current axes limits for extracting spectra."}
	
	SetVariable setgamma,pos={74,26},size={52,14},disable=1,title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol",limits={0.1,Inf,0.1},value= $(df+"gamma")
	PopupMenu SelectCT,pos={153,23},size={43,20},disable=1,proc=SelectCT,title="CT"
	PopupMenu SelectCT,mode=0,value= #"\"Grayscale;Red Temp;Invert;Rescale\""
	Button ShowHelp,pos={44,3},size={18,22},proc=ShowWin,title="?"
	Button ShowHelp,help={"Show shortcut & version history notebook"}
	TabControl imgtab,pos={63,0},size={575,48},proc=imgTabProc,tabLabel(0)="info"
	TabControl imgtab,tabLabel(1)="process",tabLabel(2)="colors"
	TabControl imgtab,tabLabel(3)="volume",tabLabel(4)="export",value= 0
	SetVariable setZ0,pos={195,26},size={70,15},disable=1,proc=SelectSlice,title="Z"
	SetVariable setZ0,help={"Select/show  value of  current slice of 3D data set."}
	SetVariable setZ0,limits={0,206,1},value= $(df+"Z0")
	SetVariable setSlice,pos={131,25},size={45,15},disable=1,proc=SelectSlice,title=" "
	SetVariable setSlice,help={"Select 3D image slice index."}
	SetVariable setSlice,limits={0,206,1},value= $(df+"islice")
	Button SliceMinus,pos={117,24},size={12,16},disable=1,proc=StepSlice,title="<"
	Button SliceMinus,help={"Decrement image slice index."}
	Button SlicePlus,pos={177,24},size={12,16},disable=1,proc=StepSlice,title=">"
	Button SlicePlus,help={"Increment image slice index."}
	PopupMenu popAnim,pos={465,23},size={74,20},disable=1,proc=AnimateAction,title="Animate"
	PopupMenu popAnim,help={"Step thru slices of 3D data set"}
	PopupMenu popAnim,mode=0,value= "\""+$(df+"anim_menu")+"\""	//root:ImageTool:anim_menu			//			//#anim_menu
	PopupMenu popSlice,pos={71,21},size={42,20},disable=1,proc=SelectSliceDir
	PopupMenu popSlice,mode=1,popvalue="XY",value= #"\"XY;XZ;YZ\""
	SetVariable setZstep,pos={268,25},size={60,15},disable=1,title="step"
	SetVariable setZstep,limits={1,Inf,1},value= $(df+"zstep")
	SetVariable setZavg,pos={331,25},size={62,15},disable=1,title="navg",proc=SetSliceAvg		//**JD
	SetVariable setZavg,limits={1,Inf,2},value= $(df+"nsliceavg")
	PopupMenu VolModify,pos={394,23},size={65,20},disable=1,proc=VolModify,title="Modify"
	PopupMenu VolModify,mode=0,value= #"\"Crop;Resize;Rescale;Set Z=0;Norm Z;Shift;\""
	CheckBox ShowImgSlices,pos={547,25},size={78,14},disable=1,proc=ShowImgSliceCheck,title="Image Slices"
	CheckBox ShowImgSlices,value= 1
	CheckBox lockColors,pos={219,26},size={80,14},disable=1,proc=ColorLockCheck,title="Lock colors?"
	CheckBox lockColors,value= 0
	PopupMenu colorOptions,pos={309,26},size={113,20},disable=1,proc=ColorOptionsProc,title="Set Colors By..."
	PopupMenu colorOptions,mode=0,value= #"\"2D images;All XYZ Data;LastMarquee\""	//!!ER
	Button exportprofile,pos={77,22},size={50,20},disable=1,title="Profile", proc=ExportProfileFct
	Button exportprofile,help={"Export X, Y or Z profile to a separate plot (name prompted for)."}
	Button exportimage,pos={137,22},size={50,20},disable=1,title="Image", proc=ExportImageFct
	Button exportimage,help={"Export current image or H or V slice to a separate window (name prompted for)."}
	Button exportvolume,pos={197,22},size={55,20},disable=1,title="Volume", proc=ExportVolumeFct
	Button exportvolume,help={"Export current (modified) volume to root (name prompted for)."}
	ValDisplay version,pos={595,1},size={35,14},fsize=9, title="v4.028",frame=0  
	ValDisplay version,limits={0,0,0},barmisc={0,1000},value= #"0"
	SetWindow kwTopWin,hook=imgHookFcn,hookevents=3
EndMacro
//PopupMenu SelectZcursor,pos={331,22},size={48,20},disable=1,proc=Zaction,title="Opt"
//PopupMenu SelectZcursor,mode=0,value= #"\"Z = Csr(A)\""
//Button ExportImage,pos={4,26},size={56,18},proc=ExportAction,title="Export"
	


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
	String wn=StrVarOrDefault(getdf1()+"imgnam","")
	prompt wn, "new image, 2D array", popup, WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")
	
	string df=getdf1()
	$(df+"imgnam")=wn
	$(df+"imgfldr")=GetWavesDataFolder($wn, 1)
	$(df+"exporti_nam")=wn+"_"		// prepare export name
End

Function NewImg(ctrlName) : ButtonControl
//------------
	String ctrlName

// Popup Dialog image array selection
	string df=getdf()
	SVAR imgfldr=$(df+"imgfldr"), imgnam=$(df+"imgnam"), datnam=$(df+"datnam")
	//if (stringmatch(ctrlName, "LoadImg"))
	variable reset=2
	strswitch ( ctrlName)
	case "LoadImg":
		//PickImage( )
		String wn=StrVarOrDefault(df+"imgnam","")
		//put 3D first in list??
		prompt wn, "New array", popup, WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")
		prompt reset,"Reset cursors and scaling", popup "No;Yes"
		DoPrompt "Select 2D Image (or 3D volume)" wn , reset
		if (V_flag==1)
			abort		//cancelled
		endif
		imgnam=wn
		datnam=imgfldr+imgnam
		break
	default:
		datnam=ctrlName
		imgnam=datnam
		imgfldr=""
	endswitch
	SVAR exporti_nam=	$(df+"exporti_nam")
	exporti_nam=imgnam+"_"				// prepare export name
	PauseUpdate; Silent 1
	if(reset==2)
		execute "SetupImg(1)"	
	else 
		execute "SetupImg(0)"	
	endif	  //**ER
end

Function SetupImg(reset)		//**ER moved this out of newimg
//============
	variable reset
	silent 1; pauseupdate
	string df=getdf(), curr=GetDataFolder(1)
	string dfn=stringfromlist(1,df,":")
	SetDataFolder $df
		SVAR dwn=$(df+"datnam")
		// put "root:" in front of data wave name if not already present
		dwn = SelectString( StringMatch(dwn,"root:*"), "root:"+dwn, dwn)
		WAVE dw =  $dwn					//$("root:"+dwn)   v4.023 fix
		//WAVE dw =  $(df+"datnam")		// This doesn't work
		NVAR ndim=$(df+"ndim")
		WAVE h_img=h_img, v_img=v_img
		WAVE himg_ct=himg_ct, vimg_ct=vimg_ct
		WAVE profileZ=profileZ, HairZ0=HairZ0, HairZ0_x=HairZ0_x
		NVAR nz=nz, zmin=zmin, zmax=zmax, zinc=zinc
		WAVE Image=Image, Image0=Image0, Image_Undo=Image_Undo
		NVAR dmin=dmin, dmin0=dmin0, dmax=dmax, dmax0=dmax0
		SVAR imgnam=imgnam, imgproc=imgproc
		NVAR islice=islice,  iSliceDir=islicedir
		NVAR vol_dmin=vol_dmin, vol_dmax, vol_dmax
		NVAR showimgslices=showimgslices, Z0=Z0
	setdatafolder $curr
	dowindow/T $dfn ,dfn+":"+dwn
	ndim=WaveDims(  dw )	//$dwn )
//	print ndim
	//ndim=SelectNumber( DimSize( dw, 2)==0, 3, 2)
	//print NameOfWave($dwn), ndim, (DimSize( dw, 2)==0)
	string WaveNamList=TraceNameList(dfn, ";",1)+ImageNameList(dfn, ";")
	//  wavelist("*",";","WIN:ImageTool")  requires being in  datafolder of plotted arrays
	//print WaveNamList
	IF (ndim==3)
		islice=0
		 SelectSliceDir("", iSliceDir,"")
		//**ER added this block
		// Add Z-profile & Crosshair to Plot
		WaveStats/Q $dwn
		vol_dmin=v_min;  vol_dmax=v_max
		if  (FindListItem("profileZ",WaveNamList,";",0)<0)	
			 AppendToGraph/r=zy/t=zx profileZ
		endif
		if  (FindListItem("HairZ0",WaveNamList,";",0)<0)	
			 AppendToGraph/r=zy/t=zx HairZ0 vs HairZ0_x
		endif
		
		ModifyGraph freePos(zy)=0;DelayUpdate
		ModifyGraph freePos(zx)=0		
		ModifyGraph offset(HairZ0)={Z0,0}
		ModifyGraph rgb(profileZ)=(3,52428,1),rgb(HairZ0)=(3,52428,1)

		// Add (optional) volume slice images
		if (showimgslices)
			if  (FindListItem("h_img",WaveNamList,";",0)<0)
 				//h_img not already on window
				 appendimage/W=$dfn/L=imgh h_img								
			endif
			 ModifyGraph axisEnab(imgh)={0.50,0.72},freePos(imgh)=0,axisenab(left)={0.0, 0.45}
			 ModifyImage h_img,cindex=himg_ct
			if  (FindListItem("v_img",WaveNamList,";",0)<0)	
 				//v_img not already on window
				 appendimage/W=$dfn /B=imgv v_img								
			endif
			 ModifyGraph axisEnab(imgv)={0.5,0.72},freePos(imgv)=0,axisenab(bottom)={0.0, 0.45}
			 ModifyImage v_img,cindex=vimg_ct
			 modifygraph axisEnab(zy)={0.5,1},axisEnab(zx)={0.5,1}
		else
			// Remove slices if present & not wanted
			modifygraph axisEnab(left)={0,0.70}, axisEnab(bottom)={0.0, 0.70}
			//if  (FindListItem("h_img",wavelist("*",";","WIN:ImageTool"),";",0)>=0)  // must be in datafolder
			if  (FindListItem("h_img",WaveNamList,";",0)>=0)
				 removeimage/W=$dfn h_img								
			endif
			if  (FindListItem("v_img",WaveNamList,";",0)>=0)
				 removeimage/W=$dfn v_img								
			endif
			modifygraph axisEnab(zy)={0.75,1},axisEnab(zx)={0.75,1}

		endif
		modifygraph fsize=10
		TextBox/C/N=zinfo/X=25.00/Y=2.00/A=MT/E/F=2  "Z = \\{"+df+"Z0}  (\\{"+df+"islice})"
//**END OF BLOCK

		//nx=DimSize($datnam,0)
		//ny=DimSize($datnam,1)
		//nz=DimSize($datnam,2)
		//islice=0
		//make/n=(nx,ny)
		//duplicate/o $datnam Image,  Image0,  Image_undo
		//ExtractSlice( islice, $datnam, "root:ImageTool:Image", idir)
		//Duplicate/O Image, Image0, Image_Undo
	ELSE		//		2D only
		// Remove 3D only items (slices & Z-profile)
		if (FindListItem("h_img", WaveNamList,";",0)>=0)	
			removeimage/w=$dfn h_img										//**ER
		endif																		//**ER
		if (FindListItem("v_img", WaveNamList,";",0)>=0)	
			removeimage/w=$dfn v_img										//**ER
		endif						
		if (FindListItem("profileZ",WaveNamList,";",0)>=0)	
			removefromgraph/w=$dfn profileZ								//**ER
		endif																		//**ER
		if (FindListItem("HairZ0",WaveNamList,";",0)>=0)
			removefromgraph/w=$dfn HairZ0								//**ER
		endif																		//**ER
		modifygraph axisenab(left)={0.0, 0.70}, axisenab(left)={0.0, 0.70}
		modifygraph axisenab(bottom)={0.0, 0.70}, axisenab(bottom)={0.0, 0.70}
		TextBox/K/N=zinfo		//**JD
		
		nz=1; zmin=0; zmax=0; zinc=1; islice=0; islicedir=1
		//duplicate/o $datnam Image,  Image0,  Image_undo
		//print "just before duplicate", NameOfWave(dw), NameOfWave($dwn)
		//duplicate/O dw Image,  Image0,  Image_Undo   //doesn't work
		duplicate/O $dwn Image,  Image0,  Image_Undo
		// Remove dependencies to previous 3D data before loading
		//DoWindow/K ZProfile //not used anymore
//		profileZ=nan
	ENDIF	//**ER

	SetDataFolder $df
	ImgInfo(Image)			//creates variables in current folder
	SetDataFolder $curr

	//print dmin0, dmax0
	dmin=dmin0;  dmax=dmax0
	ModifyImage  Image cindex= Image_CT
	//ModifyImage  Image cindex= RedTemp_CT
	//SetScale/I x dmin0, dmax0,"" root:ImageTool:RedTemp_CT
	//print dmin, dmax, dmin0, dmax0
	AdjustCT()
	//print dmin, dmax, dmin0, dmax0
	if (reset)
		SetAxis/A
		SetHairXY( "Center", 0, "", "" )
 	endif
 	SetProfiles()	
 
	ReplaceText/N=title "\Z09"+imgnam
	imgproc=""
	//Label bottom WaveUnits(Image, 0)
	//Label left WaveUnits(Image, 1)
	UpdateImgSlices(0)		//**ER
	//SetDataFolder $curr
End

Function ShowImgSliceCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR sis=$(getdf()+"showImgSlices")
	sis=checked
	execute "setupimg(0)"
End

Function ColorLockCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR lc=$(getdf()+"lockColors")
	lc=checked
End

Function ColorOptionsProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR imgOpt=$(getdf()+"colorOptions")
	imgOpt=popnum
End


//**ER ADDED THIS
Function MakeImgSlices( df )
//================
	string df
	//WAVE image=$(df+"Image"), profileZ=$(df+"profileZ")
	//WAVE h_img=$(df+"h_img"), v_img=$(df+"v_img")
	string curr=GetdataFolder(1)
	SetDataFolder $df
		WAVE image=image, profileZ=profileZ
		WAVE h_img=h_img, v_img=v_img
		make/o/n=(dimsize(image,0),dimsize(profileZ,0)) h_img
		setscale/p x dimoffset(image,0),dimdelta(image,0),waveunits(image,0),h_img
		setscale/p y dimoffset(profileZ,0),dimdelta(profileZ,0),waveunits(profileZ,0), h_img
		 
		make/o/n=(dimsize(profileZ,0),dimsize(image,1)) v_img
		setscale/p y dimoffset(image,1),dimdelta(image,1),waveunits(image,1),v_img
		setscale/p x dimoffset(profileZ,0),dimdelta(profileZ,0),waveunits(profileZ,0), v_img
	SetDataFolder $curr
end

//**ER ADDED ENTIRE FUNCTION
function UpdateImgSlices(option)
//================
	variable option	//0=both, 1=H only, 2=V only
	//nvar y0=root:imagetool:y0,x0=root:imagetool:x0
	string df=getdf(), curr=GetDataFolder(1)
	string dfn=stringfromlist(1,df,":")
	SetDataFolder $df
		//NVAR ndim=$(df+"ndim"), islicedir=$(df+"islicedir")
		//WAVE image=$(df+"image"), h_img=$(df+"h_img"), v_img=$(df+"v_img")
		//SVAR  dn=$(df+"datnam")
		//WAVE vol=$dn
		NVAR ndim=ndim, islicedir=islicedir
		WAVE image=image, h_img=h_img, v_img=v_img
		SVAR  datnam=datnam
		WAVE vol=$datnam				//$("root:"+datnam)  v4.023 fix
		NVAR lc=lockColors
	SetDataFolder $curr
	//print datnam, NameOfWave(vol), WaveDims($datnam), WaveDims(vol)
	variable x0,y0
	string offst= stringbykey("offset(x)",traceinfo(dfn,"HairY0",0),"=")
	offst=offst[1,strlen(offst)-2]
	x0=str2num(StringFromList(0,offst,","))
	y0=str2num(StringFromList(1,offst,","))
	variable doH=(option==0)+(option==1)
	variable doV=(option==0)+(option==2)
	IF (ndim==3)		// could be checked before calling function
		variable py=(y0-dimoffset(image,1))/dimdelta(image,1)
		variable px=(x0-dimoffset(image,0))/dimdelta(image,0)
		//print x0,y0,px,py
		switch( islicedir )
		case 1:		//XY
			if(doH)
				h_img=vol[p][py][q]
			endif
			if(doV)
				v_img=vol[px][q][p]
			endif
			break
		case 2:		//XZ
			if(doH)
				h_img=vol[p][q][py]
			endif
			if(doV)
				v_img=vol[px][p][q]
			endif
			break
		case 3:		//YZ
			if(doH)
				h_img=vol[q][p][py]
			endif
			if(doV)
				v_img=vol[p][px][q]
			endif
			break
		endswitch
		if (lc==0)
			AdjustCT()
		endif
	ENDIF
end

Function SelectSliceDir(ctrlName,popNum,popStr) : PopupMenuControl
//--------------------
	String ctrlName
	Variable popNum
	String popStr

	PauseUpdate; Silent 1
	string df=getdf(), curr=GetDataFolder(1)
	string dfn=stringfromlist(1,df,":")
	SetDataFolder $df
		//string/G datnam=imgfldr+imgnam  // already defined?
		SVAR datnam=datnam		//$(df+"datnam")
		WAVE dw=$datnam			//$("root:"+datnam)   v4.023 fix
		WAVE profileZ=profileZ			//$(df+"profileZ")
		NVAR islicedir=islicedir, nsliceavg=nsliceavg
		NVAR nz=nz, zmin=zmin, zmax=zmax, zinc=zinc
		SVAR zunit=zunit
		NVAR X0=X0, Y0=Y0, Z0=Z0
		NVAR dmin=dmin, dmax=dmax, dmin0=dmin0, dmax0=dmax0
		NVAR lockColors=lockColors
		WAVE Image=Image
	SetDataFolder $curr
	variable odir=3-islicedir
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
	variable Z,X,Y
	//profileZ_x=zmin+p*zinc
	if (idir==0)	// YZ
		//profileZ:=dw(x)(X0)(Y0)    //"Can't use local variable in dependency"
		//  v4.023 fix -- remove "root:" prefix
		//execute df+"profileZ:=root:"+datnam+"(x)("+df+"X0)("+df+"Y0)"   
		execute df+"profileZ:="+datnam+"(x)("+df+"X0)("+df+"Y0)"   
		switch (odir)
			case 1:
				X=Z0;Y=Y0;Z=X0	
				break
			case 2:
				X=Y0;Y=Z0;Z=X0
				break
			case 0:
				X=X0;Y=Y0;Z=Z0
				break
		endswitch
	endif
	if (idir==1)	// XZ
		//profileZ:=dw(X0)(x)(Y0)
		execute df+"profileZ:="+datnam+"("+df+"X0)(x)("+df+"Y0)"   
		switch (odir)
			case 1:
				X=X0;Y=Y0;Z=Z0
				break
			case 0:
				X=Z0;Y=Y0;Z=X0
				break
			case 2:
				X=X0;Y=Z0;Z=Y0
				break
		endswitch
	endif
	if (idir==2)	// XY
		//profileZ:=dw(X0)(Y0)(x)
		execute df+"profileZ:="+datnam+"("+df+"X0)("+df+"Y0)(x)"   
		switch (odir)
			case 0:
				X=Z0;Y=X0;Z=Y0
				break
			case 1:
				X=X0;Y=Z0;Z=Y0
				break
			case 2:
				X=X0;Y=Y0;Z=Z0
				break
		endswitch
	endif

	// change control ranges
		//ShowWin( "ShowZProfile" )
	SetVariable setSlice limits={0, nz-1,1}
	SetVariable setZ0 limits={zmin, zmax, zinc}
	Label bottom WaveUnits(dw, idir)

	//SelectSlice("", trunc(nz/2), "", "" )
	SelectSlice("SetZ0", Z, "", "" )
	 
	 
	SetSliceAvg("",nsliceavg,"","")			//also calls SelectSlice()
	
	DoWindow/F $dfn
	Label bottom WaveUnits(Image, 0)
	Label left WaveUnits(Image, 1)
	SetDataFolder $df
	ImgInfo(Image)		//creates variable in current folder
	SetDataFolder $curr
	//SetHairXY( "Center", 0, "", "" )
	SetHairXY( "SetX0",X, "", "" )
	SetHairXY( "SetY0", Y, "", "" )
	dmin=dmin0;  dmax=dmax0
	if (lockColors==0)
		AdjustCT()
	endif
	//SetScale/I x dmin0, dmax0,"" root:ImageTool:RedTemp_CT
	SetProfiles()
	MakeImgSlices(df)
	UpdateImgSlices(0)
	//SetDataFolder $curr
End


Function SelectSlice(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	PauseUpdate; Silent 1
	string df=getdf(), curr=GetDataFolder(1)
	string dfn=stringfromlist(1,df,":")
	SetDataFolder $df
		NVAR Z0=Z0, zmin=zmin, zinc=zinc
		NVAR islice=islice, islicedir=islicedir, nsliceavg=nsliceavg
		NVAR lockColors=lockColors
		WAVE HairZ0=HairZ0
		SVAR datnam=datnam
		WAVE dw=$datnam			//$("root:"+datnam)  v4.023 fix
	SetDataFolder $curr 
	
	if (stringmatch(ctrlName, "SetZ0"))
		Z0=varNum
		islice=round( (Z0-zmin)/zinc )
	else
		islice=varNum
		Z0=zmin + islice*zinc
	endif
	//Cursor/P A, profileZ, islice
	variable str=strsearch(tracenamelist(dfn,";",1),"HairZ0",0)
	if(str>=0)
		ModifyGraph/W=$dfn offset(HairZ0)={Z0,0}
	endif
		
	//string datnam=imgfldr+imgnam
	//print datnam, islice, islicedir
	string opt = "/"+"XYZ"[3-islicedir]
		opt+= "/O="+df+"Image"
		opt+=  "/AVG="+num2str(nsliceavg) 
	VolSlice( dw, islice, opt )
	//ExtractSlice( islice, $datnam, "root:IMG:Image", 3-islicedir )
	//Duplicate/O Image Image0, Image_Undo

	//SetProfiles()	
	if (lockColors==0)
		AdjustCT()			// auto-rescale color table; always want on?
	endif
	//SetDataFolder $curr
End

Function StepSlice(ctrlName) : ButtonControl
//------------------
	String ctrlName
	
	string df=getdf()
	NVAR zstep=$(df+"zstep"), islice=$(df+"islice")
	variable dir=SelectNumber( stringmatch(ctrlName, "SlicePlus"), -1, 1)
	SelectSlice("", islice+dir*zstep, "", "" )
End


Function AnimateAction(ctrlName,popNum,popStr) : PopupMenuControl
//----------
	String ctrlName
	Variable popNum
	String popStr
	
	string df=getdf()
	SVAR newmenu=$(df+"anim_menu")
	NVAR anim_dir=$(df+"anim_dir"), anim_loop=$(df+"anim_loop"), anim_range=$(df+"anim_range")
	NVAR nz=$(df+"nz"), zstep=$(df+"zstep")
	print "popnum=",popnum
	IF ((popNum>=3)*(popNum<=11))
		//if ((popNum>=3)*(popNum<=5))
		switch( popNum )
		case 3:
		case 4:
		case 5:
			newmenu=ReplaceItemInList( 2, "Ã  "[popNum-3]+" Forward", newmenu, "" )
			newmenu=ReplaceItemInList( 3, " Ã "[popNum-3]+" Backward", newmenu, "" )
			newmenu=ReplaceItemInList( 4, "  Ã"[popNum-3]+" Loop", newmenu, "" )
			anim_dir=popNum-3
			break
		//endif
		//if ((popNum>=7)*(popNum<=8))
		case 7:
		case 8:
			newmenu=ReplaceItemInList( 6, "Ã  "[popNum-7]+" Single Pass", newmenu, "" )
			newmenu=ReplaceItemInList( 7, " Ã "[popNum-7]+" Continuous", newmenu, "" )
			anim_loop=popNum-7
			break
		//endif
		//if ((popNum>=10)*(popNum<=11))
		case 10:
		case 11:
			newmenu=ReplaceItemInList( 9, "Ã  "[popNum-10]+" Full Range", newmenu, "" )
			newmenu=ReplaceItemInList( 10, " Ã "[popNum-10]+" Cursors", newmenu, "" )
			anim_range=popNum-10
			break
		//endif
		endswitch
		//anim_menu=newmenu
		//string new_menu=newmenu
		//PopupMenu popAnim value=new_menu
		execute "PopupMenu popAnim value=\""+newmenu+"\""
	ELSE
		
		variable istart, iend, istep, idir=anim_dir
		//istart=SelectNumber( anim_range, 0, pcsr(A) )  //!!ER commented out and replaced with if endif
		//iend=SelectNumber( anim_range, nz-1, pcsr(B) )
		if(anim_range)
			istart=pcsr(A)
			iend=pcsr(B)
		else
			istart=0
			iend=nz-1
		endif
		
		istep=zstep * sign( iend-istart)
		
		variable imovie=0
		if (popNum==13)					//single pass SaveMovie
			anim_loop=0
			imovie=1
			popNum=1
		endif
		
		if (popNum==1)
			if (anim_loop==1)		// continuous
				DO
					Animate(istart, iend, istep, idir, imovie)
				WHILE(1)
			else								//single pass
				Animate(istart, iend, istep, idir, imovie)
			endif
		endif
	ENDIF
	return 1
End

Function Animate(istart, iend, istep, idir, imovie)
//----------
	variable istart, iend, istep, idir, imovie

	variable ii, nslice=abs((iend-istart)/istep)+1
	//print istart, iend, istep, nslice
	string df=getdf()
	SVAR dn=$(df+"datnam")
	string dfn=stringfromlist(1,df,":")
	if (imovie)
		DoWindow/F $dfn
		NewMovie/L/I
		//DoWindow/F Zprofile
	endif
	
	if ((idir==0)+(idir==2))			//Forward
		ii=0
		DO
			SelectSlice("", istart+ii*istep, "", "" )
			DoUpdate; Sleep/S 0.1
			if (imovie)
				Dowindow/F $dfn
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
			DoUpdate; Sleep/S 0.1
			if (imovie)
				Dowindow/F $dfn
				AddMovieFrame
				//Dowindow/F ZProfile
			endif
			ii+=1
		WHILE( ii<nslice )
	endif
	
	if (imovie)
		CloseMovie
	endif
	return nslice
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


Function SetProfiles()				//XY profiles
//-------------
	PauseUpdate; Silent 1
	string df=getdf()
	string curr=GetDataFolder(1)
	SetDataFolder $df
		WAVE profileH=profileH, profileH_x=profileH_x
		NVAR nx=nx, xmin=xmin, xmax=xmax, xinc=xinc
		WAVE profileV=profileV,profileV_y=profileV_y
		NVAR ny=ny, ymin=ymin, ymax=ymax, yinc=yinc
	SetDataFolder $curr
	
	Redimension/N=(nx) profileH, profileH_x
	profileH_x=xmin+p*xinc
//		profileH:=image(profileH_x)(root:ImageTool:Y0)
	
	Redimension/N=(ny) profileV, profileV_y
	profileV_y=ymin+p*yinc
//		profileV:=image(root:ImageTool:X0)(profileV_y)
	
	//ImageTool Window must be on top
	string dfn=stringfromlist(1,df,":")

	DoWindow/F $dfn
	SetVariable setX0 limits={min(xmin, xmax), max(xmin, xmax), abs(xinc)}
	SetVariable setY0 limits={min(ymin, ymax), max(ymin, ymax), abs(yinc)}
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

	String df=getdf()
	variable/C coffset=GetWaveOffset($(df+"HairY0"))
	variable xcur=REAL(coffset), ycur=(IMAG(coffset)), pcur
	NVAR xmin=$(df+"xmin"), xmax=$(df+"xmax")
	NVAR ymin=$(df+"ymin"), ymax=$(df+"ymax")
	//print "old: ", xcur, ycur
	if (cmpstr(ctrlName,"SetX0")==0)
		ModifyGraph offset(HairX1)={varNum, 0}
		ModifyGraph offset(HairY0)={varNum, ycur}
		//setdatafolder $df	
		//setdatafolder img	//**ER
		UpdateImgSlices(2)	//**ER
		//setdatafolder ::		//**ER
	endif
	if (cmpstr(ctrlName,"SetY0")==0)
		ModifyGraph offset(HairY1)={0, varNum}
		ModifyGraph offset(HairY0)={xcur, varNum}
		//setdatafolder $df	
		//setdatafolder img	//**ER
		UpdateImgSlices(1)	//**ER
		//setdatafolder ::		//**ER
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
		NVAR xinc=$(df+"xinc")
		pcur=round((xcur-xmin)/xinc)
		xcur=xmin+pcur*xinc
		ModifyGraph offset(HairX1)={xcur+sign(VarNum)*sign(xinc)*xinc, 0}
		ModifyGraph offset(HairY0)={xcur+sign(VarNum)*sign(xinc)*xinc, ycur}
	endif
	if (CmpStr(ctrlname,"stepUpDown")==0)
		NVAR yinc=$(df+"yinc")
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
		WAVE Image=$(df+"Image")
		Cursor/P A, profileH, round((xcur - DimOffset(Image, 0))/DimDelta(Image,0))
		Cursor/P B, profileV_y, round((ycur - DimOffset(Image, 1))/DimDelta(Image,1))
	endif
End

Function PopFilter(ctrlName,popNum,popStr) : PopupMenuControl
//================
	String ctrlName
	Variable popNum
	String popStr
	
	string df=getdf(), curr=GetDataFolder(1)
	SetDataFolder $df
		WAVE Image=Image, Image_Undo=Image_Undo
		SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
	SetDataFolder $curr
	
	string keyword=popStr
	variable size=3
	WAVE w=Image
	NVAR numpass=$(df+"numpass")
	
	if( CmpStr(keyword,"NaNZapMedian") == 0 )
		if( (WaveType(w) %& (2+4) ) == 0 )
			Abort "Integer image has no NANs to zap!"
			return 0
		endif
	endif

	 // Save current image to backup
	Duplicate/O Image Image_Undo

	imgproc_undo=imgproc
	imgproc+="+ "+keyword+num2istr(numpass)
	
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
		WHILE( ipass<numpass)
	else
		MatrixFilter/N=(size)/P=(numpass) $keyword, Image	
	ENDIF
	
	ReplaceText/N=title "\Z09"+imgnam+": "+imgproc

End

Function ImgModify(ctrlName, popNum,popStr) : PopupMenuControl
//------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate; Silent 1
	string df=getdf(), curr=GetDataFolder(1)
	
	SetDataFolder $df
	WAVE Image=Image, Image_undo=Image_Undo
	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
	NVAR nx=nx, ny=ny, X0=X0, Y0=Y0
	NVAR xmin=xmin, xmax=xmax, xinc=xinc, ymin=ymin, ymax=ymax, yinc=yinc
	NVAR lockColors=lockColors
	
	Duplicate/o Image Image_Undo
	imgproc_undo=imgproc
	
	variable/C coffset=GetWaveOffset($(df+"HairY0")), rngopt
	string opt
	string/G cmd
	variable ii
	
	//if (cmpstr(popStr,"Crop")==0)
	strswitch( popStr )
	case "Crop" :
		string/G x12_crop, y12_crop
		SVAR x12_crop=x12_crop, y12_crop=y12_crop
		string xrng=StrVarOrDefault(df+"x12_crop", "0,1" )
		string yrng=StrVarOrDefault(df+"y12_crop", "0,1" )
		rngopt=1
		//check for marquee
		GetMarquee/K left, bottom
		if (V_Flag==1)			//round to nearest data increment
			xrng=num2str( xinc*round(V_left/xinc))+","+num2str( xinc*round(V_right/xinc) )		
			yrng=num2str( yinc*round(V_bottom/yinc))+","+num2str( yinc*round(V_top/yinc) )
		else
			xrng=x12_crop; yrng=y12_crop
		endif
		//print "xyrng=", xrng, yrng
		
		string croprng=CropRange(xrng, yrng, rngopt)
		//print croprng, KeyStr( "", croprng)
		x12_crop=KeyStr( "X", croprng)
		y12_crop=KeyStr( "Y", croprng)
		
		
			//opt+="/X="+x12_crop+",/Y="+y12_crop
	
			//if (dim_crop==3)		// volume crop
			//	cmd="VolCrop(Image_Undo,  \""+opt+"\")"
				//VolCrop(, opt)
			//else
		opt="/O=Image"+croprng
		cmd="ImgCrop(Image_Undo, \""+opt+"\")"
		//ImgCrop(Image_Undo,  opt)
		print cmd
		execute cmd
			//Duplicate/O/R=(x1_crop,x2_crop)(y1_crop,y2_crop) Image_Undo, Image
			//endif
		if (lockColors==0)
			AdjustCT()
		endif
		break
	
	//if (cmpstr(popStr,"Transpose")==0)
	case "Transpose":
		MatrixTranspose Image
		ModifyGraph offset(HairY0)={IMAG(coffset), REAL(coffset)}
		ModifyGraph offset(HairX1)={IMAG(coffset), 0}
		ModifyGraph offset(HairY1)={0, REAL(coffset)}
		//print coffset, GetWaveOffset(root:IMG:HairY0)
		 SetAxis/A
		break
	
	//if (cmpstr(popStr,"Rotate")==0)
	case "Rotate":
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
		break
		
	//if (cmpstr(popStr,"Rescale")==0)
	case "Rescale":
		GetMarquee/K left, bottom
		if (V_Flag==1)
			variable/G x1_resize, x2_resize, y1_resize, y2_resize
			x1_resize=V_left; x2_resize=V_right
			y1_resize=V_bottom; y2_resize=V_top
			execute "RescaleImgBox()"
		else
			execute "RescaleImg()"
		endif
		break
		
	//if (cmpstr(popStr,"Set X=0")==0)
	case "Set X=0":
		SetScale/P x xmin-REAL(coffset), xinc,"" Image
		ModifyGraph offset(HairY0)={0, IMAG(coffset)}
		ModifyGraph offset(HairX1)={0, 0}
		break
	//if (cmpstr(popStr,"Set Y=0")==0)
	case "Set Y=0":
		SetScale/P y ymin-IMAG(coffset), yinc,"" Image
		ModifyGraph offset(HairY0)={REAL(coffset), 0}
		ModifyGraph offset(HairY1)={0, 0}
		break
		
	//if (cmpstr(popStr,"Norm X")==0)
	case "Norm X":
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
		//ConfirmYNorm(  )
		Variable y1=NumVarOrDefault(getdf()+"y1_norm", 0 )
		Variable y2=NumVarOrDefault(getdf()+"y2_norm", 1 )
		//Variable rngopt=1
		Prompt y1, "X Norm Y1"
		Prompt y2, "X Norm Y2"
		Prompt rngopt, "Norm X option:", popup, "None;Full Y"
		DoPrompt "X Norm Y-range", y1, y2, rngopt
		if (rngopt==2)
			GetAxis/Q left
			y1=V_min; y2=V_max
		endif
		Variable/G $(df+"y1_norm")=y1, $(df+"y2_norm")=y2
		NVAR y1_norm=y1_norm, y2_norm=y2_norm
		//Cursor/P A, profileH, x2pnt( Image, y1_norm) 
		//Cursor/P B, profileH, x2pnt( Image, y2_norm)
		
		make/o/n=(nx) xtmp
		SetScale/P x xmin, xinc, "" xtmp
		// different methods of normalizing? NormImg in image_util??
		xtmp = AREA2D( Image, 1, y1_norm, y2_norm, x )
		Image /= xtmp[p]
		if (lockColors==0)
			 AdjustCT()
		endif
		break
		
	//if (cmpstr(popStr,"Norm Y")==0)
	case "Norm Y":
		variable/G x1_norm, x2_norm
		GetMarquee/K bottom
		if (V_Flag==1)
			x1_norm=xinc*round(V_left/xinc)		//round to nearest data increment
			x2_norm=xinc*round(V_right/xinc)
		endif
		//ConfirmXNorm(  )
		variable x1=NumVarOrDefault(df+"x1_norm", 0 )
		variable x2=NumVarOrDefault(df+"x2_norm", 1 )
		//Variable rngopt=1
		Prompt x1, "Y Norm X1"
		Prompt x2, "Y Norm X2"
		Prompt rngopt, "Norm Y option:", popup, "None;Full X"
		DoPrompt "Y Normalize  X-Range" x1, x2, rngopt
		if (V_flag==1)
			abort
		endif
		if (rngopt==2)
			GetAxis/Q bottom 
			x1=V_min; x2=V_max
		endif
		Variable/G $(df+"x1_norm")=x1, $(df+"x2_norm")=x2
		NVAR x1_norm=x1_norm, x2_norm=x2_norm
		
		Cursor/P A, profileH, x2pnt( Image, x1_norm) 
		Cursor/P B, profileH, x2pnt( Image, x2_norm)
		
		make/o/n=(ny) ytmp
		SetScale/P x ymin, yinc, "" ytmp
		ytmp = AREA2D( Image, 0, x1_norm, x2_norm, x )
		Image /= ytmp[q]
		if(lockcolors==0)
			 AdjustCT()
		endif
		break
		
	//if (cmpstr(popStr,"Resize")==0)
	case "Resize":
		variable xyopt
		string xyval=StrVarOrDefault(df+"N_resize", "1,1" )
		prompt xyopt, "Nx, Ny Resize option:", popup, "Interp by N;Interp to Npts;Rebin by N;Thin by N"
		prompt xyval, "(Nx, Ny) or N [=Nx=Ny]"
		DoPrompt "Image Resize" xyopt, xyval
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
		String/G $(df+"N_resize")=xyval
		
		opt="/O=Image"+"/"+"IIRT"[xyopt-1]
		if (xyopt==2) 
			opt+="/NP"
		endif
		cmd="ImgResize(Image_Undo, \""+xyval+"\",\""+opt+"\")"
		print cmd
		execute cmd
		//execute "ResizeImg(  )"
		//SetScale/P x xmin-REAL(coffset), xinc,"" Image
		//ModifyGraph offset(HairY0)={0, IMAG(coffset)}
		break
		
	//if (cmpstr(popStr,"Reflect X")==0)
	case "Reflect X":
		Image=Image_Undo(x)[q]+Image_Undo(-x)[q] 
		if(lockColors==0)
			AdjustCT()
		endif
		break
		
	//if (cmpstr(popStr,"Offset Z")==0)
	case "Offset Z":
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
		break
		
	//if (cmpstr(popStr,"Norm Z")==0)
	case "Norm Z":
		GetMarquee/K left, bottom
		If (V_Flag==1)
			Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, imgtmp
			WaveStats/Q imgtmp
			Image=Image_Undo / V_avg
		else
			//WaveStats/Q Image
			variable normval=Image(X0)(Y0)
			Image=Image_Undo / normval
		endif
		if(lockColors==0)
			AdjustCT()
		endif
		break
		
	//if (cmpstr(popStr,"Invert Z")==0)
		case "Invert Z":
		Image=-Image_Undo
		if(lockColors==0)
			AdjustCT()
		endif
		break
		
	//if (cmpstr(popStr,"Shift")==0)
	case "Shift":
		// dialog to specify shift wave, if shift wave, X or Y, expansion
		//SetDataFolder $curr
		///PromptShift( )
		String shftwn=StrVarOrDefault(df+"shiftwn", "" )
		Variable dir=NumVarOrDefault(df+"shiftdir", 1 )
		Variable expand=NumVarOrDefault(df+"shift_expand", 1 )
		prompt shftwn, "Shift Wave Name", popup, WaveList("!*_x",";","DIMS:1")
		prompt dir, "Shift Direction", popup, "X;Y"
		prompt expand, "Output Range", popup, "Shrink;Average;Expand"
		DoPrompt "Shift Image array" shftwn, dir, expand
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
	
		String/G $(df+"shiftwn")=shftwn
		Variable/G $(df+"shiftdir")=dir-1, $(df+"shift_expand")=expand-2
		SVAR shiftwn=shiftwn
		NVAR shiftdir=shiftdir, shift_expand=shift_expand
		
		opt=SelectString(shiftdir==1, "/X","/Y" ) +"/O=Image/E="+num2str(shift_expand)
		cmd="ImgShift( Image_Undo, root:"+shiftwn+",\"" +opt+"\")"
		print cmd
		//ImgShift( Image_Undo, $shiftwn, "/O=Image/E="+num2str(shift_expand)
		execute cmd
		
		//print ang_rot
		//Imagerotate/A=(ang_rot)/E=Nan/O Image
		break
	endswitch

		//SetDataFolder $df
	ImgInfo( Image )
		//SetDataFolder $curr
 	SetProfiles()	
	SetHairXY( "Check", 0, "", "" )
	imgproc+="+ "+popStr			// update this after operation incase of intermediate macro Cancel
	ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	
	SetDataFolder $curr
End

Function VolModify(ctrlName, popNum,popStr) : PopupMenuControl
//================  for Image_Tool
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate; Silent 1
	string df=getdf1(), curr=GetDataFolder(1)
	NVAR ndim=$(df+"ndim")
	if (ndim<3)
		abort "Not 3-dimensional"
	endif
	
	SetDataFolder $df
	WAVE Image=Image, Image_undo=Image_Undo
	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
	SVAR datnam=datnam
	NVAR nx=nx, ny=ny, X0=X0, Y0=Y0
	NVAR xmin=xmin, xmax=xmax, xinc=xinc, ymin=ymin, ymax=ymax, yinc=yinc
	NVAR lockColors=lockColors
	
	//Duplicate/o Image Image_Undo
	//imgproc_undo=imgproc
	
	variable/C coffset=GetWaveOffset($(df+"HairZ0")), rngopt
	string opt
	string/G cmd
	variable ii
	
	string newvoln
	
	strswitch( popStr )
	case "Crop" :
		string/G x12_crop, y12_crop
		SVAR x12_crop=x12_crop, y12_crop=y12_crop
		string xrng=StrVarOrDefault(df+"x12_crop", "0,1" )
		string yrng=StrVarOrDefault(df+"y12_crop", "0,1" )
		rngopt=1
		//check for marquee
		GetMarquee/K left, bottom
		if (V_Flag==1)			//round to nearest data increment
			xrng=num2str( xinc*round(V_left/xinc))+","+num2str( xinc*round(V_right/xinc) )		
			yrng=num2str( yinc*round(V_bottom/yinc))+","+num2str( yinc*round(V_top/yinc) )
		else
			xrng=x12_crop; yrng=y12_crop
		endif
		//print "xyrng=", xrng, yrng
		//Depending on islicedir marquee gives XY, XZ or YZ ranges
		//could use csrs on Zproifle for further cropping
		string croprng=CropRange(xrng, yrng, rngopt)
		//print croprng, KeyStr( "", croprng)
		x12_crop=KeyStr( "X", croprng)
		y12_crop=KeyStr( "Y", croprng)
	
		newvoln=datnam+"c"
		prompt newvoln, "New Volume Name"
		DoPrompt "Crop Volume", newvoln
		if (v_flag==1)
			SetDataFolder $curr
			abort
		endif
			//if (dim_crop==3)		// volume crop
			//	cmd="VolCrop(Image_Undo,  \""+opt+"\")"
				//VolCrop(, opt)
			//else
		//opt="/O="+df+"Vol"+croprng
		opt="/O="+newvoln+croprng
		cmd="VolCrop("+datnam+", \""+opt+"\")"
		print cmd
		execute cmd
	
		SetDataFolder $curr
		NewImg( newvoln )		//new volume
		if (lockColors==0)
			//AdjustCT()
		endif
		break
		
	case "Resize":
		newvoln=datnam+"r"
		variable xyzopt=NumVarOrDefault(df+"vol_resize", 1 )
		string xyzval=StrVarOrDefault(df+"Nvol_resize", "1,1,1" )
		prompt xyzopt, "Nx, Ny Resize option:", popup, "Interp by N;Interp to Npts;Rebin by N;Thin by N"
		prompt xyzval, "(Nx, Ny) or N [=Nx=Ny]"
		prompt newvoln, "New volume name"
		DoPrompt "Volume Resize" newvoln, xyzopt, xyzval
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
		Variable/G $(df+"vol_resize")=xyzopt
		String/G $(df+"Nvol_resize")=xyzval
		
		opt="/"+"IIRT"[xyzopt-1]
		if (xyzopt==2) 
			opt+="/NP"
		endif
		opt+="/O="+newvoln
		cmd="VolResize("+datnam+", \""+xyzval+"\",\""+opt+"\")"
		print cmd
		execute cmd	
		
		SetDataFolder $curr
		NewImg( newvoln )		//new volume	
		break
		
	case "Rescale":
		
		cmd="VolRescale"
		print cmd
		//execute cmd
		break
		
	case "Set Z=0":
	
		SetScale/P x xmin-REAL(coffset), xinc,"" $datnam
		ModifyGraph offset(HairY0)={0, IMAG(coffset)}
		cmd="Set Z=0"
		print cmd
		//execute cmd
		break

	case "Norm Z":
		newvoln=datnam+"n"
		prompt newvoln, "New volume name"
		DoPrompt "Volume Normalize" newvoln
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
		NVAR islicedir=$(df+"islicedir")
		opt="/"+"ZYX"[islicedir-1]
		opt+="/O="+newvoln
		cmd="VolNorm( "+datnam+", \"" +opt+"\")"
		print cmd
		execute cmd
		SetDataFolder $curr
		NewImg( newvoln )		//new volume	
		// AdjustCT()
		break
		
	
	case "Shift":
		String shftwn=StrVarOrDefault(df+"shiftwn", "" )
		Variable dir=NumVarOrDefault(df+"shiftdir", 1 )
		Variable expand=NumVarOrDefault(df+"shift_expand", 1 )
		prompt shftwn, "Shift Wave Name", popup, WaveList("!*_x",";","DIMS:1")
		prompt dir, "Shift Direction", popup, "X;Y"
		prompt expand, "Output Range", popup, "Shrink;Average;Expand"
		DoPrompt "Shift Image array" shftwn, dir, expand
		if (V_flag==1)
			abort
		endif
	
		String/G $(df+"shiftwn")=shftwn
		Variable/G $(df+"shiftdir")=dir-1, $(df+"shift_expand")=expand-2
		SVAR shiftwn=shiftwn
		NVAR shiftdir=shiftdir, shift_expand=shift_expand
		
		opt=SelectString(shiftdir==1, "/X","/Y" ) +"/O=Image/E="+num2str(shift_expand)
		cmd="VolShift( "+datnam+", "+shiftwn+",\"" +opt+"\")"
		print cmd
		//ShiftImg( Image_Undo, $shiftwn, "/O=Image/E="+num2str(shift_expand)
		execute cmd
		
		SetDataFolder $curr
		NewImg( newvoln )		//new volume
		break
	endswitch

	//print cmd
	//execute cmd
	
	//ImgInfo( Image )
 	//SetProfiles()	
	//SetHairXY( "Check", 0, "", "" )
	//imgproc+="+ "+popStr			// update this after operation incase of intermediate macro Cancel
	//ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	
	SetDataFolder $curr
End

Proc DoneRotate(ctrlName) : ButtonControl
//--------------------
	String ctrlName

	GraphNormal
	RemoveFromGraph roty
	KillControl DoneRot
	variable/G ang_rot
	variable dx, dy, slope
	string df=getdf1()
	dx=($(df+"rotx")[1]-$(df+"rotx")[0])
	dy=($(df+"roty")[1]-$(df+"roty")[0])
	slope=dy/dx
	ang_rot=(180/pi)*atan2( dy/$(df+"yinc"), dx/$(df+"xinc"))-90
	print ang_rot, "deg (Pixel);", slope, WaveUnits($(df+"Image"), 1)+"/"+WaveUnits($(df+"Image"), 0)
	//DoRotate( Image, ang_rot, "Image")
	dorotate($(df+"image"),ang_rot)
End

//rotation, ang is in degrees
function doRotate(img,ang)
	wave img; variable ang
	duplicate/o img, img2,xp,yp
	variable ar=ang*pi/180
	variable xav=dimoffset(img,0) + dimdelta(img,0)*dimsize(img,0)/2
	variable yav=dimoffset(img,1) + dimdelta(img,1)*dimsize(img,1)/2
	xp=xav + cos(ar)*(x-xav) - sin(ar)*(y-yav)
	yp=yav + sin(ar)*(x-xav) + cos(ar)*(y-yav)	
	img2=interp2d(img,xp,yp)
	//img2=img(xp)(yp)  fast, inaccurate
	duplicate/o img2 img
end

Proc DoneShift(ctrlName) : ButtonControl
//--------------------
	String ctrlName

	GraphNormal
	RemoveFromGraph shifty
	KillControl DoneShift
	//call DoShift( Image, Shiftx, "Image")
End




Proc ConfirmNormC( axis, xr, yr )
//------------
	String axis=StrVarOrDefault(getdf1()+"axis_norm", "X" )
	Variable/C xr=Cmplx( NumVarOrDefault(getdf1()+"x1_norm", 0 ), NumVarOrDefault(getdf1()+"x2_norm", 1 ) )
	Variable/C yr=Cmplx( NumVarOrDefault(getdf1()+"y1_norm", 0 ), NumVarOrDefault(getdf1()+"y2_norm", 1 ) )
	Prompt axis, "Normalization Axis", popup, "X;Y;XY;YX"
	Prompt xr, "X axis range:"
	Prompt yr, "Y axis range:"
	
	string df=getdf1()
	String/G $(df+"axis_norm")=axis
	Variable/G $(df+"x1_norm")=REAL(xr), $(df+"x2_norm")=IMAG(xr)
	Variable/G $(df+"y1_norm")=REAL(yr), $(df+"y2_norm")=IMAG(yr)
End

Proc ConfirmNorm( axis, x1, x2, y1, y2 )
//------------
	String axis=StrVarOrDefault(getdf1()+"axis_norm", "X" )
	Variable x1=NumVarOrDefault(getdf1()+"x1_norm", 0 )
	Variable x2=NumVarOrDefault(getdf1()+"x2_norm", 1 )
	Variable y1=NumVarOrDefault(getdf1()+"y1_norm", 0 )
	Variable y2=NumVarOrDefault(getdf1()+"y2_norm", 1 )
	Prompt axis, "Normalization Axis", popup, "X;Y;XY;YX"
	
	string df=getdf1()
	String/G $(df+":axis_norm")=axis
	Variable/G $(df+"x1_norm")=x1, $(df+"x2_norm")=x2
	Variable/G $(df+"y1_norm")=y1, $(df+"y2_norm")=y2
End

//Obsolete with DoPrompt
//Proc ConfirmXNorm( x1, x2, opt )			// xrange
//------------
	Variable x1=NumVarOrDefault(getdf1()+"x1_norm", 0 )
	Variable x2=NumVarOrDefault(getdf1()+"x2_norm", 1 )
	Variable opt=1
	Prompt opt, "Norm Y option:", popup, "None;Full X"
	
	if (opt==2)
		GetAxis/Q bottom 
		x1=V_min; x2=V_max
	endif

	string df=getdf1()
	Variable/G $(df+"x1_norm")=x1, $(df+"x2_norm")=x2
End

//Obsolete with DoPrompt
//Proc ConfirmYNorm( y1, y2, opt )			// yrange
//------------
	Variable y1=NumVarOrDefault(getdf1()+"y1_norm", 0 )
	Variable y2=NumVarOrDefault(getdf1()+"y2_norm", 1 )
	Variable opt=1
	Prompt opt, "Norm X option:", popup, "None;Full Y"
	
	if (opt==2)
		GetAxis/Q left
		y1=V_min; y2=V_max
	endif
	string df=getdf1()
	Variable/G $(df+":y1_norm")=y1, $(df+"y2_norm")=y2
End

//Obsolete with DoPrompt
//Proc PromptShift( shftwn, dir, expand )			// Shift Wave parms
//------------
	String shftwn=StrVarOrDefault(getdf1()+"shiftwn", "" )
	Variable dir=NumVarOrDefault(getdf1()+"shiftdir", 1 )+1
	Variable expand=NumVarOrDefault(getdf1()+"shift_expand", 1 )+2
	prompt shftwn, "Shift Wave Name", popup, WaveList("!*_x",";","DIMS:1")
	prompt dir, "Shift Direction", popup, "X;Y"
	prompt expand, "Output Range", popup, "Shrink;Average;Expand[def]"
	
	string df=getdf1()
	String/G $(df+"shiftwn")=shftwn
	Variable/G $(df+"shiftdir")=dir-1, $(df+"shift_expand")=expand-2
End

Function/T PromptEdge( )			// Shift Wave parms
//======
	string df=getdf()
	String edgewn=StrVarOrDefault(df+"edgen", "" )
	Variable fitedge=NumVarOrDefault(df+"edgefit", 1 )+1
	Variable fitpos=NumVarOrDefault(df+"positionfit", 1 )+1
	prompt edgewn, "Output basename (_e, _w)"
	prompt fitedge, "Edge Detection", popup, "Find;Fit"
	prompt fitpos, "Post-fit Edge Postions", popup, "No;Linear;Quadratic"
	DoPrompt "Edge Position options" edgewn, fitedge, fitpos
	
	String/G $(df+"edgen")=edgewn
	Variable/G $(df+"edgefit")=fitedge-1, $(df+"positionfit")=fitpos-1
	return edgewn
End

Proc RescaleImg( xopt, xrang, yopt, yrang  )
//------------
	string xrang=num2str($(getdf1()+"xmin"))+", "+num2str($(getdf1()+"xmax"))+", "+num2str($(getdf1()+"xinc"))
	string yrang=num2str($(getdf1()+"ymin"))+", "+num2str($(getdf1()+"ymax"))+", "+num2str($(getdf1()+"yinc"))
	variable xopt, yopt
	prompt xrang, "X-values:  (min,inc) or (min,max) or (center, inc) or (val)"
	prompt yrang, "Y-values:  (min,inc) or (min,max)  or (center, inc) or (val)"
	prompt xopt, "X-axis Rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	prompt yopt, "Y-axis Rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	
	string df=getdf1(),  curr=GetDataFolder(1)
	SetDataFolder $df
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
			SetScale/I x vmin, str2num(StringFromList(1,xrang, ",")), "" Image
		endif
		if (xopt==4)
			SetScale/P x vmin-0.5*(nx-1)*vinc, vinc , "" Image
		endif
		if (xopt==5)
			coffset=GetWaveOffset($(df+"HairY0"))
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
			coffset=GetWaveOffset($(df+"HairY0"))
			SetScale/P y ymin-IMAG(coffset)+vmin, yinc,"" Image
			ModifyGraph offset(HairY0)={REAL(coffset), vmin}
		endif
	endif
	SetDataFolder curr
End

Proc RescaleImgBox( opt, xrang, yrang  )
//------------
	variable opt
	string xrang=num2str($(getdf1()+"x1_resize"))+", "+num2str($(getdf1()+"x2_resize"))
	string yrang=num2str($(getdf1()+"y1_resize"))+", "+num2str($(getdf1()+"y2_resize"))
	prompt xrang, "Marquee box X-values:  (left, right)"
	prompt yrang, "Marquee box Y-values:  (bottom, top)"
	prompt opt, "Marquee Box Axis Rescaling:", popup, "X only;Y only;X and Y"
	
	string df=getdf1(), curr=GetDataFolder(1)
	SetDataFolder $df
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
	string xyval=StrVarOrDefault(getdf1()+"N_resize", "1,1" )
	prompt xyopt, "Nx, Ny Resize option:", popup, "Interp by N;Interp to Npts;Rebin by N;Thin by N"
	prompt xyval, "(Nx, Ny) or N [=Nx=Ny]"
	
	// interpret xyval string
	variable xval=1, yval=1
	xval=str2num(StringFromList(0, xyval, ","))
	xval=SelectNumber(numtype(yval)==2, xval, 1)    //NaN for single value list
	yval=str2num(StringFromList(1, xyval, ","))
	yval=SelectNumber(numtype(yval)==2, yval, xval)    //NaN for single value list
	//print xval, yval
		
	string df=getdf1(), curr=GetDataFolder(1)
	SetDataFolder $df
	string/G N_resize=xyval
	variable/C coffset=GetWaveOffset($(df+"HairY0"))
	
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
	string df=getdf1(), curr=GetDataFolder(1)
	string opt, cmd, xrng
	SetDataFolder $df
//	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
//	NVAR nx=nx, ny=ny
	
//	Duplicate/o Image Image_Undo
//	imgproc_undo=imgproc
//	imgproc+="+ "+popStr
	
//	variable/C coffset=GetWaveOffset(root:IMG:HairY0)

	if (popNum<=5)				// get & confirm analysis X-range
		string/G x12_analyze
		//SVAR x12_analyze=x12_analyze
		xrng=StrVarOrDefault(df+"x12_analyze", "0,1" )
		//check for marquee
		GetMarquee/K left, bottom
		if (V_Flag==1)			//round to nearest data increment
			xrng=num2str( xinc*round(V_left/xinc))+","+num2str( xinc*round(V_right/xinc) )		
		else
			xrng=x12_analyze
		endif
		//print "xrng=", xrng
		xrng=AnalyzeXRange(xrng)
		x12_analyze=KeyStr( "X", xrng)
		variable x1, x2
		x1=NumFromList(0, x12_analyze, ",")
		x2=NumFromList(1, x12_analyze, ",")

		//Reposition AB cursors on X-profile to indicate range selected
		Cursor/P A, profileH, x2pnt( Image, x1) 
		Cursor/P B, profileH, x2pnt( Image, x2)	
	endif

	if (cmpstr(popStr,"Area X")==0)
		//string/G $(df+"arean")
		//string wn=PickStr( "Area Wave Name", $(df+"arean"), 0)
		//$(df+"arean")=wn
		string/G areaXnam=PickStr( "Avg Wave Name", "areax", 0)
		
		//SetDataFolder $curr
		//wn="root:"+wn
		areaXnam="root:"+areaXnam
		make/o/n=($(df+"ny")) $areaXnam
		SetScale/P x $(df+"ymin"), $(df+"yinc"), "" $areaXnam
		//WAVE areaXw=$areaXnam
		$areaXnam = AREA2D( $(df+"Image"),  0, x1,  x2, x )
		
		DoWindow/F Area_
		if (V_Flag==0)
			Display $areaXnam
			DoWindow/C Area_
			Area_Style("Area")
		else
			CheckDisplayed/W=Area_  $areaXnam
			if (V_Flag==0)
				Append $areaXnam
			endif
		endif
	endif
	
	if ((cmpstr(popStr,"Find Edge")==0) + (cmpstr(popStr,"Fit Edge")==0))

		//string wn=PickStr( "Edge Base Name", root:IMG:edgen, 0)
		//root:IMG:edgen=wn
		PromptEdge()		//selects edgen, edgefit=(0,1), positionfit=(0,1,2)
		string wn=$(df+"edgen")
		
		SetDataFolder curr
		string ctr=wn+"_e", wdth=wn+"_w"
		make/C/o/n=($(df+"ny")) $wn
		make/o/n=($(df+"ny")) $ctr, $wdth
		SetScale/P x $(df+"ymin"), $(df+"yinc"), WaveUnits($(df+"Image"),0) $wn,  $ctr, $wdth
		
		variable wfrac=0.15*SelectNumber($(df+"edgefit")==1, 1, -1)	// negative turns on fitting
		variable debug=0
		if (debug)
			iterate( $(df+"ny") )
				$wn = EDGE2D( $(df+"Image"),  x1,  x2, pnt2x($wn, i), wfrac )
				PauseUpdate
				ResumeUpdate
				print i
			loop
		else
			$wn = EDGE2D( $(df+"Image"),  x1,  x2, x, wfrac )
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
		
		variable fitpos=$(df+"positionfit")
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
		//string/G $(df+"peakn")
		//string wn=PickStr( "Peak Base Name", "peakn", 0)
		//$(df+"peakn")=wn
		string/G peakn=PickStr( "Peak Base Name", "pkn", 0)
		//string wn=peakn
		
		SetDataFolder curr
		string ctr=peakn+"_e", wdth=peakn+"_w"
		make/C/o/n=($(df+"ny")) $peakn
		make/o/n=($(df+"ny")) $ctr, $wdth
		SetScale/P x $(df+"ymin"), $(df+"yinc"), "" $peakn,  $ctr, $wdth
		$peakn = PEAK2D( $(df+"Image"),  x1,  x2,  x, pkmode )
		$ctr=REAL( $peakn )
		$wdth=IMAG( $peakn )
		
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
		//string/G avgYnam="avgy"	//$(df+"sumn")
		//string wn=PickStr( "Avg Wave Name", "avgy", 0)
		//avgYnam=wn
		
		string/G avgYnam=PickStr( "Avg Wave Name", "avgy", 0)
		//DoPrompt "Avg Wave Name", avgYnam
		//if (V_flag==0)
		//	abort
		//endif

		
		
		//wn="root:"+wn
//		make/o/n=($(df+"nx")) $wn
//		SetScale/P x $(df+"xmin"), $(df+"xinc"), "" $wn
//		iterate( $(df+"ny") )
//			$wn+=$(df+"Image")[p][i]
//		loop
//		$wn /= $(df+"ny")
		avgYnam="root:"+avgYnam
		opt="/X/O="+avgYnam		//+avgrng
		cmd="ImgAvg("+df+"Image, \""+opt+"\")"
		print cmd
		//ImgAvg(Image,  opt)
		//SetDataFolder $curr
		execute cmd
		
		DoWindow/F Sum_
		if (V_Flag==0)
			Display $avgYnam
			DoWindow/C Sum_
			Area_Style("Average")
		else
			CheckDisplayed/W=Sum_  $avgYnam
			if (V_Flag==0)
				Append $avgYnam
			endif
		endif
	endif

	SetDataFolder $curr
End

Function/T AnalyzeXRange( xrng )			// xrange
//=================
	string xrng
	prompt xrng, "x1, x2"
	DoPrompt "X Analysis Range" xrng

	return  "/X="+xrng
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

	string df=getdf1(), curr=GetDataFolder(1), stmp
	SetDataFolder $df
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
			//SetDataFolder $df
	ImgInfo( Image )
			//SetDataFolder $curr	
	SetProfiles()	
	SetHairXY( "Check", 0, "", "" )
	PopupMenu ImageUndo mode=1		//restore to first item
	SetDataFolder $curr
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
	//String thedf= "root:"+gname
	String thedf= "root:"+gname
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
	
	setvariable setx0,disable=(tab!=0)		//Info
	setvariable sety0,disable=(tab!=0)
	valdisplay valD0,disable=(tab!=0)
	valdisplay nptx,disable=(tab!=0)
	valdisplay npty,disable=(tab!=0)
	valdisplay nptz,disable=(tab!=0)
	
	popupmenu imageprocess, disable=(tab!=1)		//Process
	setvariable setnumpass,disable=(tab!=1)
	popupmenu popFilter, disable=(tab!=1)
	popupmenu imageAnalyze, disable=(tab!=1)
	button stack,disable=(tab!=1)
	setvariable setpinc,disable=(tab!=1)
	popupmenu imageUndo, disable=(tab!=1)

	setvariable setgamma,disable=(tab!=2)		//Colors
	popupmenu selectct, disable=(tab!=2)
	checkbox lockcolors,disable=(tab!=2)
	popupmenu colorOptions, disable=(tab!=2)
	checkbox smartautoscale,disable=(tab!=2)

	
	popupmenu popslice, disable=(tab!=3)		//Volume
	button sliceminus,disable=(tab!=3)
	button sliceplus,disable=(tab!=3)
	setvariable setslice,disable=(tab!=3)
	setvariable setZ0,disable=(tab!=3)
	setvariable setZstep,disable=(tab!=3)
	setvariable setZavg,disable=(tab!=3)		//**JD
	popupmenu volModify,disable=(tab!=3)
	popupmenu popAnim,disable=(tab!=3)
	checkbox ShowImgSlices, disable=(tab!=3)
	
	button exportprofile, disable=(tab!=4)		//Export
	button exportimage,disable=(tab!=4)
	button exportvolume,disable=(tab!=4)
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
//	string df=getdf()  window is not always on top when we get the kill event
	string df="root:"+stringbykey("WINDOW",s)+":"
	SVAR dn=$(df+"datnam")
	string dfn=stringfromlist(1,df,":")
	NVAR ndim=$(df+"ndim"), showImgSlices=$(df+"showImgSlices")

	modif=NumberByKey("modifiers", s) & 15			//mask out 5th bit (v6.023)
	//print modif
	if (StrSearch(s,"EVENT:mouse",0)>0)	// could check separately for mousedown & mouseup
		if (modif==3)		// 3 = "0011" =shift +mousedown
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
			ay=axisvalfrompixel(dfn,"left",mousey)
			ax=axisvalfrompixel(dfn,"bottom",mousex)	
			if(ndim==3)
				zy=axisvalfrompixel(dfn,"zy",mousey)
				zx=axisvalfrompixel(dfn,"zx",mousex)	
				zcur=REAL(GetWaveOffset($(df+"hairz0")))
				GetAxis/Q zx; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
				GetAxis/Q zy; zymin=min(V_max, V_min); zymax=max(V_min, V_max)
				//print zx, zcur
				 zx= SelectNumber((zx>zxmin)*(zx<zxmax)*(zy>zymin)*(zy<zymax), zcur, zx) 
				
				
			//	zy=axisvalfrompixel(dfn,"left",mousey)
			//	zx=axisvalfrompixel(dfn,"imgv",mousex)	
			//	GetAxis/Q imgv; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
			//	GetAxis/Q left; zymin=min(V_max, V_min); zymax=max(V_min, V_max)
			//	zx= SelectNumber((zx>zxmin)*(zx<zxmax)*(zy>zymin)*(zy<zymax), z1, zx) 
				wave w=$dn
			endif
			if (modif==9)			//9 = "1001" = cmd/ctrl+mousedown
				GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
				GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
				coffset=GetWaveOffset($(df+"HairY0"))
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
					
					//	ModifyGraph offset(HairY_V)={zx,ay}
					
					ModifyGraph offset(HairY0)={ax,ay}		// must be last updated for hairtrigger
					if ((ndim==3)*showImgSlices)
						//setdatafolder img	//**ER
						UpdateImgSlices(0)	//**ER
						//setdatafolder ::		//**ER
					endif
				endif
				NVAR autoscale=$(df+"autoscale")
				if(autoscale)
					doupdate
					AutoScaleInRange("lineX","bottom",1)
					AutoScaleInRange("left","liney",2)
				endif
				returnval=1
			endif
			if (modif==5)				// 5 = "0101" = option/alt +mousedown
				if((zx!=zcur)*(ndim==3))
					nvar isd=$(df+"islicedir")
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
					NVAR x0=$(df+"x0"), y0=$(df+"y0")
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
						NVAR xmin=$(df+"xmin"),  xinc=$(df+"xinc")
						pcur=round((x0-xmin)/xinc)
						x0=xmin+pcur*xinc
						ModifyGraph offset(HairX1)={x0+sign(dx)*sign(xinc)*xinc, 0}
						ModifyGraph offset(HairY0)={x0+sign(dx)*sign(xinc)*xinc, y0}
						if ((ndim==3)*showImgSlices)
							//setdatafolder img	//**ER
							UpdateImgSlices(2)	//**ER
							//setdatafolder ::		//**ER
						endif
					else	
						//dir="step"+SelectString( dy>0, "Down", "Up")
						//execute "SetHairXY( \"stepUpDown\", "+num2str(dy)+", \"\", \"\" )"
						NVAR ymin=$(df+"ymin"), yinc=$(df+"yinc")
						pcur=round((y0-ymin)/yinc)
						y0=ymin+pcur*yinc
						ModifyGraph offset(HairY1)={0,   y0+sign(dy)*sign(yinc)*yinc}
						ModifyGraph offset(HairY0)={x0, y0+sign(dy)*sign(yinc)*yinc}
						if ((ndim==3)*showImgSlices)
							//setdatafolder img	//**ER
							UpdateImgSlices(1)	//**ER
							//setdatafolder ::		//**ER
						endif
					endif
					//print dir, abs(dx/dy)
				endif
				returnval=2
			endif
		endif
		endif
	endif
	
	if (cmpstr(stringbykey("event",s),"kill")==0)
			//window killed, so kill data
			dowindow/f $dfn
			removeallfromgraph(dfn)
			string swn=getswn(df)
			
			
			dowindow/f $swn
			if(V_Flag)
				dowindow/k $swn
			endif
			if(datafolderexists(df+"STACK"))
				killallinfolder(df+"STACK")
				killdatafolder $(df+"STACK")
			endif
			killallinfolder(df)
			killdatafolder $df
			returnval=0
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
		NVAR Z0=$(getdf()+"Z0")
		variable dx= ax - Z0
		//print dx, mousex, Z0, ax
		string stepdir=SelectString( dx>0, "Minus", "Plus")
		execute "StepSlice(\"Slice"+stepdir+"\" )"
		returnval=2
	endif
	return returnval
end

Function AdjustCT() 	//: GraphMarquee
//==============
	string df=getdf(), curr=GetDataFolder(1)
	SetDataFolder $df
		WAVE image=image, Image_CT=image_CT
		NVAR ndim=ndim, dmin=dmin, dmax=dmax, CTinvert=CTinvert
	//SetDataFolder $curr
	//Variable/G root:V_min, root:V_max
	nvar ml=$(df+"marquee_left")		//!!ER next 4 lines
	nvar mr=$(df+"marquee_right")	
	nvar mb=$(df+"marquee_bottom")			
	nvar mt=$(df+"marquee_top")

	GetMarquee/K left, bottom
	If (V_Flag==1)
		Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, $(df+"imgtmp")
		ml=v_left; mr=v_right; mb=v_bottom; mt=v_top	//!!ER  store marquee values for next adjustct	
		WAVE imgtmp=$(df+"imgtmp")
		WaveStats/Q imgtmp
		variable px1, px2, py1, py2
		px1=(V_left-DimOffset( Image,0))/ DimDelta(Image,0)
		px2=(V_right-DimOffset(Image,0))/ DimDelta(Image,0)
		py1=(V_bottom-DimOffset(Image,1))/ DimDelta(Image,1)
		py2=(V_top-DimOffset(Image,1))/ DimDelta(Image,1)
		//ImageStats/M=1/G={px1,px2,py1,py2} $(df+"Image")	//requires Igor 4
		//print px1,px2,py1,py2, V_min, V_max
		killwaves/Z imgtmp
	else
		if (ndim==3)	//**ER
			NVAR coloroptions=coloroptions, showimgslices=showimgslices
			NVAR vol_dmin=vol_dmin, vol_dmax=vol_dmax
			WAVE h_img=h_img, v_img=v_img
			WAVE himg_ct=himg_ct, vimg_ct=vimg_ct
			//!!ER next if-else-endif
			if(coloroptions==1)	// independently for xy, h, v images
				if( showImgSlices)
					Wavestats/Q h_img; dosetscale(himg_ct, v_min, v_max, ctinvert)
					wavestats/Q v_img; dosetscale(vimg_ct, v_min, v_max, ctinvert)
				endif
				Wavestats/Q Image
			else
				if (coloroptions==2) //whole volume	
					//variable/G V_min, V_max			
					V_min=vol_dmin; V_max=vol_dmax
					if (showImgSlices)
						dosetscale( himg_ct, V_min, V_max, ctinvert)
						dosetscale( vimg_ct, V_min, V_max, ctinvert)
					endif
				else		//previous marquee value
					Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, $(df+"imgtmp")
					WAVE imgtmp=$(df+"imgtmp")
					WaveStats/Q imgtmp
				endif
			endif
		else				//**ER
			WaveStats/Q Image
			//ImageStats/M=1 root:IMG:Image		//requires Igor 4
		endif			//**ER
	endif
	
	dmin=V_min;  dmax=V_max
	dosetscale( Image_CT, V_min, V_max, CTinvert)
	
	SetDataFolder $curr
End

//**ER added this
Function dosetScale(wv, mn,mx,inv)	
//==============
	WAVE wv
	variable inv,mn,mx
	if(inv<0)
		SetScale/I x mx, mn,"" wv
	else
		SetScale/I x mn,mx,"" wv
	endif
end


Function SelectCT(ctrlName,popNum,popStr) : PopupMenuControl
//============
	String ctrlName
	Variable popNum
	String popStr
	
	string df=getdf(), curr=getdataFolder(1)
	string CTstr
	PauseUpdate
	switch( popNum )
//	case 1:
		//CTstr="Gray_CT[pmap[p]][q]"
//		CTstr="ALL_CT[pmap[p]][q][5]"
//		execute df+"Image_CT:="+df+CTstr
//		execute df+"Himg_CT:="+df+CTstr
//		execute df+"Vimg_CT:="+df+CTstr
//		break
//
//	case 2:
//		CTstr="RedTemp_CT[pmap[p]][q]"
//		execute df+"Image_CT:="+df+CTstr
//		execute df+"Himg_CT:="+df+CTstr
//		execute df+"Vimg_CT:="+df+CTstr
//		break
	case 1: 		//Invert
		setdataFolder $df
			NVAR CTinvert=CTinvert, gamma=gamma
			NVAR ndim=ndim, showImgSlices=showImgSlices
			NVAR dmin=dmin, dmax=dmax
			WAVE Image_CT=Image_CT, himg_CT=himg_CT, vimg_CT=vimg_CT
			WAVE h_img = h_img, v_img=v_img
		setdatafolder $curr
		CTinvert*=-1
		gamma=1/gamma
		if (CTinvert<0)
			PopupMenu SelectCT value="Ã Invert;Rescale;"+colornameslist()
			SetVariable setgamma limits={0.1,Inf,0.1}
			SetScale/I x dmax, dmin,"" Image_CT
		else
			PopupMenu SelectCT value="Invert;Rescale;"+colornameslist()
			SetVariable setgamma limits={0.1,Inf,0.1}
			SetScale/I x dmin, dmax,"" Image_CT
		endif
		if (showImgSlices*(ndim==3))
			Wavestats/Q h_img;    dosetscale( himg_ct, V_min, V_max, CTinvert)
			Wavestats/Q v_img;    dosetscale( vimg_ct, V_min, V_max, CTinvert)
		endif
		break
	case 2:		// Rescale
		AdjustCT()
		break
	default:
		CTstr="ALL_CT[pmap[p]][q]["+num2str(popnum-3) + "]"
		execute df+"Image_CT:="+df+CTstr
		execute df+"Himg_CT:="+df+CTstr
		execute df+"Vimg_CT:="+df+CTstr
		break

	endswitch
End

Function Crop()// : GraphMarquee
//--------------------
	if (stringmatch(Winname(0,1), "ImageTool*")==1)
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
		//ConfirmCrop( )
		string imgn=StringfromList(0, ImageNameList("", ";"))
		string opt="/O"		// overwrite
		opt+="/X="+x12_crop+",/Y="+y12_crop

		string cmd="ImgCrop("+imgn+", \""+opt+"\")"
		ImgCrop($imgn,  opt)
		print cmd
	endif
End

Function/S CropRange(xrng, yrng, rngopt)
//===============
	string xrng, yrng
	variable rngopt
	prompt xrng, "Crop X range (x1,x2)"
	prompt yrng, "Crop Y range (y1,y2)"
	prompt rngopt, "Range option", popup, "None;Full X;Full Y;Full Axes"
	DoPrompt "Crop Range" xrng, yrng, rngopt
	if (V_flag==1)	
		abort
	endif

	if ((rngopt==2)+(rngopt==4))
		GetAxis/Q bottom
		xrng=num2str(V_min)+","+num2str(V_max) 
	endif
	if ((rngopt==3)+(rngopt==4))
		GetAxis/Q left
		yrng=num2str(V_min)+","+num2str(V_max) 
	endif	
	return "/X="+xrng+"/Y="+yrng
End

Function NormX() //: GraphMarquee
//--------------------
	ImgModify("", 0,"Norm X")
End

Function NormY() //: GraphMarquee
//--------------------
	ImgModify("", 0,"Norm Y")
End

Function NormZ() //: GraphMarquee
//--------------------
	ImgModify("", 0,"Norm Z")
End

Function OffsetZ() // : GraphMarquee
//--------------------
	ImgModify("", 0,"Offset Z")
End

Proc AreaX() 
//: GraphMarquee
//--------------------
	ImgAnalyze("", 0,"Area X")
End

Proc Find_Edge() 
//: GraphMarquee
//--------------------
	ImgAnalyze("", 0, "Find Edge")
End

Proc  Find_Peak() 
//: GraphMarquee
//--------------------
	ImgAnalyze("", 0, "Find Peak")
End

//Obsolete with DoPrompt in function
//Proc ImageName( exportnam )
//------------
//	String exportnam=StrVarOrDefault( "root:IMG:exportn", root:IMG:imgnam )
//	prompt exportnam, "Export Image Name"
//	
//	string/G root:IMG:exportn=exportnam
//End

//Obsolete with use of each export subroutine as a function using DoPrompt for variables
//Function ExportAction(ctrlName) : ButtonControl
//--------------------
//	String ctrlName	
//	strswitch( ctrlName )
//		case "exportstack":
//			execute "ExportStack()" 
//			//execute "ExportStackFct()"   
//			break
//		case "exportprofile":
//			execute "ExportProfile()"
//			break
//		case "exportimage":
//			execute "ExportImage()"
//			break
//		case "exportvolume":
//			execute "ExportVolume()"
//			break
//	endswitch
//End

Function ExportStackFct(ctrlName) : ButtonControl
//======================
	String ctrlName
	
	String df=stack_getdf()
	String basen=StrVarOrDefault( df+"STACK:basen", "base")
	Prompt basen, "Stack base name"
	DoPrompt "Export Stack", basen
	if (V_flag==1)
		abort		// Cancel selected
	endif
	string/G $(df+"STACK:basen")=basen
	
	SetDataFolder root:

	SVAR imgn=$(df+"imgnam")
	NVAR shift=$(df+"STACK:shift"), offset=$(df+"STACK:offset")
	NVAR xmin=$(df+"STACK:xmin"), xinc=$(df+"STACK:xinc")
	
	string trace_lst=TraceNameList(getswn(df),";",1 )
	variable nt=ItemsInList(trace_lst,";")

	Display			// open empty plot
	PauseUpdate; Silent 1
	string tn, wn, tval, wnote
	variable ii=0, yval
	DO
		tn=df+"STACK:"+StrFromList(trace_lst, ii, ";")
		//print tn
		yval=NumberByKey( "VAL", note($tn), "=", ",")		// get y-axis value
		wn=basen+num2istr(ii)
		duplicate/o $tn $wn
		WAVE wv=$wn
		wv+=offset*ii
		SetScale/P x xmin+shift*ii, xinc,"" wv
		//SetScale/P x DimOffset($tn,0),DimDelta($tn,0),"" wv
		Write_Mod(wv, shift*ii, offset*ii, 1, 0, 0.5, 0, yval, imgn)
		AppendToGraph wv
		ii+=1
	WHILE( ii<nt )
	
	string winnam=(basen+"_Stack")
	DoWindow/F $winnam
	if (V_Flag==1)
		DoWindow/K $winnam
	endif
	DoWindow/C $winnam
End

Function ExportProfileFct( ctrlName ) : ButtonControl
//======================
	String ctrlName
	
	String df=getdf()
	string nam=StrVarOrDefault( df+"exportp_nam", "profil")
	variable opt=NumVarOrDefault( df+"exportp_opt", 1)
	variable plotopt=NumVarOrDefault( df+"exportp_plot", 1)
	prompt nam, "Export wave name"
	prompt opt, "Export option", popup, "X profile;Y profile;Z profile"
	prompt plotopt, "Plot option", popup, "Display;Append;None"
	DoPrompt "ExportProfile" nam, opt, plotopt
	if (V_flag==1)
		abort		// Cancel selected
	endif
	string/G  $(df+"exportp_nam")=nam
	variable/G  $(df+"exportp_opt")=opt,  $(df+"exportp_plot")=plotopt

	SetDataFolder root:
	PauseUpdate; Silent 1
	
	variable np
	switch( opt )
		case 1:		// horizontal X-profile
			np=numpnts( $(df+"profileH") )
			make/o/n=(np) $nam
			WAVE profil=$nam, profileH=$(df+"profileH")
			profil=profileH
			ScaleWave( profil, df+"profileH_x", 0, 0 )	
			break
		case 2:		// vertical Y-profile
			np=numpnts( $(df+"profileV") )
			make/o/n=(np) $nam
			WAVE profil=$nam, profileV=$(df+"profileV")
			profil=profileV
			ScaleWave( profil, df+"profileV_y", 0, 0 )
			break
		case 3:		// volume Z profile
			np=numpnts( $(df+"profileZ") )
			make/o/n=(np) $nam
			WAVE profil=$nam, profileZ=$(df+"profileZ")
			profil=profileZ			// already scaled
			break
	endswitch
		
	switch( plotopt )
		case 1:
			Display profil
			break
		case 2:
			DoWindow/F $WinName(1,1)		// next graph behind ImageTool
			AppendToGraph profil
			break
	endswitch
End

Function ExportImageFct(ctrlName) : ButtonControl
//======================
	String ctrlName
	
	String df=getdf()
	String nam=StrVarOrDefault( df+"exporti_nam", "img")
	variable opt=NumVarOrDefault( df+"exporti_opt", 1)
	variable plotopt=NumVarOrDefault( df+"exporti_plot", 1)
	prompt nam, "Export image name"
	prompt opt, "Image & Color Table options", popup, "Main Image;Horiz Slice;Vert Slice;Color Table only;"
	prompt plotopt, "Plot option", popup, "Display;Append to Plot;Append to Img/Vol;None"
	DoPrompt "ExportImage" nam, opt, plotopt
	if (V_flag==1)
		abort		// Cancel selected
	endif
	string/G $(df+"exporti_nam")=nam
	variable/G  $(df+"exporti_opt")=opt,  $(df+"exporti_plot")=plotopt
	
	SetDataFolder root:
	PauseUpdate; Silent 1
	variable left, right, bottom, top
	switch( opt )
		case 1:		// Main Image  (use graph axes subset)	
			GetAxis/Q bottom 
			left=V_min; right=V_max
			GetAxis/Q left
			bottom=V_min; top=V_max
			Duplicate/O/R=(left,right)(bottom,top) $(df+"Image"), $nam
			Duplicate/O $(df+"Image_CT") $(nam+"_CT")	
			break
		case 2:		// Horiz. Profile Slice & CT
			GetAxis/Q bottom
			left=v_min; right=v_max
			GetAxis/Q imgh
			bottom=v_min; top=v_max
			duplicate/O/R=(left,right)(bottom,top) $(df+"h_img") $nam
			break
		case 3:		// Vertical Profile Slice & CT
			GetAxis/Q imgv
			left=v_min; right=v_max
			GetAxis/Q left
			bottom=v_min; top=v_max
			duplicate/O/R=(left,right)(bottom,top) $(df+"v_img") $nam
			break
		case 4:		// Color Table  Only
			Duplicate/O $(df+"Image_CT") $(nam+"_CT")
			break
	endswitch
		
	switch( plotopt )
		case 1:
			display; appendimage $nam
			modifyimage $nam, cindex=$(nam+"_CT")
			break
		case 2:
			DoWindow/F $WinName(1,1)		// next window behind ImageTool
			appendimage $nam
			modifyimage $nam, cindex=$(nam+"_CT")
			break
		case 3:
			//Prompt for 2D or 3D array to append to (See SES loader)
			abort "Not implmented yet"
			break
	endswitch
End

Function ExportVolumeFct(ctrlName) : ButtonControl
//======================
	String ctrlName
	
	String df=getdf()
	NVAR ndim= $(df+"ndim")
	if (ndim<3)
		abort "Not 3-dimensional"
	endif
	 
	String nam=StrVarOrDefault( df+"exportv_nam", "vol")
	variable opt=NumVarOrDefault( df+"exportv_opt", 1)
	variable plotopt=NumVarOrDefault( df+"exportv_plot", 1)
	prompt nam, "Export volume name"
	prompt opt, "Volume options", popup, "Volume & CT;Volume-based Color Table only;"
	prompt plotopt, "Plot option", popup, "Display;Append to Img/Vol;None"
	DoPrompt "ExportImage" nam, opt, plotopt
	if (V_flag==1)
		abort		// Cancel selected
	endif
	string/G  $(df+"exportv_nam")=nam
	variable/G  $(df+"exportv_opt")=opt,  $(df+"exportv_plot")=plotopt
	
	SetDataFolder root:
	PauseUpdate; Silent 1
	
	switch( opt )
		case 1:		// Current  volume & orientation
			Duplicate/o $(df+"vol") $nam
			Duplicate/o $(df+"Image_CT") $(nam+"_CT")		// use current image CT
			break
		case 2:		// Color Table  Only
			Duplicate/o $(df+"Image_CT") $(nam+"_CT")
			break
	endswitch
		
	switch( plotopt )
		case 1:
			display; appendimage $nam		// will plot as image
			modifyimage $nam, cindex=$(nam+"_CT")		// use image CT??
			break
		case 2:
			//Prompt for 2D or 3D array to append to (See SES loader)
			abort "Not implmented yet"
			break
	endswitch
End


Function SetSliceAvg(ctrlName,varNum,varStr,varName) : SetVariableControl
//----------------------
	String ctrlName
	Variable varNum
	String varStr
	String varName


	string df=getdf(), curr=GetdataFolder(1)
	SetdataFolder $df
		NVAR nsliceavg=nsliceavg, islice=islice
		NVAR zinc=zinc
		WAVE HairZ0=HairZ0, HairZ0_x=HairZ0_x
	SetDataFolder $curr
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

	SelectSlice("", islice, "", "" )
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
	
	string df=getdf(), curr=GetDataFolder(1)
	string dfn=stringfromlist(1,df,":")
	string swn=getswn(df)
//	SetDataFolder root:IMG
	WAVE img=$(df+"Image")

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
	Duplicate/O/R=(x1,x2)(y1,y2) img, $(df+"Stack:Image")

	WAVE imgstack=$(df+"Stack:Image")
	NVAR pinc=$(df+"STACK:pinc")

	WaveStats/Q imgstack
//	print V_min, V_max
	variable/G $(df+"STACK:dmin")=V_min, $(df+"STACK:dmax")=V_max 
	
	string basen=df+"STACK:line"
	variable nw, nx, dir=0
	//nw=ItemsInList( Img2Waves( imgstack, basen, dir ), ";")
	nw=Image2Waves( imgstack, basen, dir, pinc )
	nx=DimSize($(df+"STACK:Image"), 0)
	variable/G $(df+"STACK:ymin")=y1, $(df+"STACK:yinc")=(y2-y1)/(nw-1)
	variable/G $(df+"STACK:xmin")=x1 , $(df+"STACK:xinc")=(x2-x1)/(nx-1)

	string trace_lst=""
	variable nt=0
	DoWindow/F $swn // Stack_
	if (V_flag==0)
		execute "Stack_()"
		dowindow /c $SWN
		If (!stringmatch( IgorInfo(2), "Macintosh") )
			//Display /W=(219,250,540,600)
			// Windows: scale window width smaller by 72/96Å0.75
			MoveWindow 219,250,219+(540-219)*0.7,600
		endif
	endif
	trace_lst=TraceNameList(swn,";",1 )
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
	
	SVAR imgnam=$(df+"imgnam")
	DoWindow/T $swn, swn+": "+imgnam
	
	NVAR dmax=$(df+"STACK:dmax"), dmin=$(df+"STACK:dmin")
	variable shiftinc=DimDelta(imgstack,0), offsetinc, exp
	offsetinc=0.1*(dmax-dmin)
	exp=10^floor( log(offsetinc) )
	offsetinc=round( offsetinc / exp) * exp
//	print offsetinc, exp
	SetVariable setshift limits={-Inf,Inf, shiftinc}
	SetVariable setoffset limits={-Inf,Inf, offsetinc}
	NVAR shift=$(df+"STACK:shift"),  offset=$(df+"STACK:offset")
	shift=0
	offset=offsetinc*(1-2*(offset<0))		//preserve previous sign of offset
	OffsetStack( shift, offset)
	
	SetDataFolder curr
End


Function SetOffset(ctrlName,varNum,varStr,varName) : SetVariableControl
//---------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string df=stack_getdf()
	NVAR shift =$(df+"STACK:shift")
	NVAR offset =$(df+"STACK:offset")
	if (cmpstr(ctrlName,"setShift")==0)
	
		shift = varNum
	else
		offset=varNum
	endif
	OffsetStack(shift,offset)
End

Function MoveCursor(ctrlName) : ButtonControl
//------------
	String ctrlName
	//root:IMG:STACK:offset=0.5*(root:IMG:STACK:dmax-root:IMG:STACK:dmin)
	//OffsetStack( root:IMG:STACK:shift, root:IMG:STACK:offset)
	string df=stack_getdf()
	string dfn=stringfromlist(1,df,":")
	variable xcur=xcsr(A), ycur
	if ( numtype(xcur)==0 ) 
		NVAR ymin=$(df+"STACK:ymin") 
		NVAR yinc= $(df+"STACK:yinc") 
		string wvn=CsrWave(A)
		ycur=ymin
		ycur +=yinc * str2num( wvn[4,strlen(wvn)-1] )
		DoWindow/F $dfn
		ModifyGraph offset(HairY0)={xcur, ycur}
		WAVE image = $(df+"Image")
		Cursor/P A, profileH, round((xcur - DimOffset(Image, 0))/DimDelta(Image,0))
		Cursor/P B, profileV_y, round((ycur - DimOffset(Image, 1))/DimDelta(Image,1))
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


// No longer necessary with DoPrompt feature inside a function
//Proc StackName( stacknam )
//------------
//	String stacknam=StrVarOrDefault( "root:IMG:STACK:basen", root:IMG:imgnam )
//	prompt stacknam, "Export Stack Base Name"
//	
//	string/G root:IMG:STACK:basen=stacknam
//End


Window Stack_() : Graph
	PauseUpdate; Silent 1		// building window...
	String df=getdf1(), fldrSav= GetDataFolder(1)

	SetDataFolder $(df+"STACK:")
	Display /K=1 /W=(219,250,540,600) line0 as "Stack_: BI"
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(32769,65535,32768)
	
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=2
	ModifyGraph mirror=1
	ModifyGraph minor=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph fSize=10
	ShowInfo
	ControlBar 21
	SetVariable setshift,pos={6,2},size={80,14},proc=SetOffset,title="shift"
	SetVariable setshift,help={"Incremental X shift of spectra."},fSize=10
	SetVariable setshift,limits={-Inf,Inf,0.002},value= $(df+"STACK:shift")
	SetVariable setoffset,pos={90,2},size={90,14},proc=SetOffset,title="offset"
	SetVariable setoffset,help={"Incremental Y offset of spectra."},fSize=10
	SetVariable setoffset,limits={-Inf,Inf,0.2},value= $(df+"STACK:offset")
	Button MoveImgCsr,pos={188,1},size={35,16},proc=MoveCursor,title="Csr"
	Button MoveImgCsr,help={"Reposition cross-hair in Image_Tool panel to the location of the A cursor placed in the Stack_ window."}
	Button ExportStack,pos={233,1},size={50,16},proc=ExportStackFct,title="Export"
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
	Label/Z right "Peak Width"
	SetAxis/Z/A/E=1 right
EndMacro


//function/s getdf()
static function/s getdf()					//static  can only be called by FUNCTONS (not macros) in this procedure
//override function/s getdf()
//=========
//get data folder from topmost window name
	//return ":"+winlist("*","","win:")+":"
	return "root:"+WinName(0,1)+":"
	//return "root:ImageTool:"
	//return "root:img:"
end

function/s getdf1()		//use non-static call from macros
	return getdf()
end

//=========
//get image tool data folder from topmost window name of a stack window, supports the lagacy STACK_->ImageTool
static function /S stack_getdf()
	string df = getdf()
	string dfn=stringfromlist(1,df,":")
	if(cmpstr(dfn,"STACK_")==0)
		return "root:ImageTool:"
	else
		variable snum
		sscanf dfn ,"STACK %i", snum
		return  "root:ImageTool"+num2istr(snum)+":"
	endif
end

///=====
//get the stack window name for a given imagetool df folder, supports the lagacy imagetool->STACK_.
static function /S getswn(df)
	string df
	string dfn=stringfromlist(1,df,":")
	if(cmpstr(dfn,"ImageTool")==0)
		return "STACK_"
	else
		variable snum
		sscanf dfn ,"ImageTool %i", snum
		return  "STACK"+num2istr(snum)
	endif
end


// remove all of the images and waves from a graph
Function Removeallfromgraph(graphName)
	String graphName						// name of a graph
	DoWindow/F $graphName
	string wl = tracenamelist(graphname,";",1)
	variable num=itemsinlist(wl,";")
	variable i
	for(i=0;i<num;i+=1)
		removefromgraph /W= $graphname /Z $(stringfromlist(i,wl,";"))
	endfor
	wl=imagenamelist(graphname,";")
	num= itemsinlist(wl,";")
	for(i=0;i<num;i+=1)
		removeimage /W= $graphname /Z $(stringfromlist(i,wl,";"))
	endfor
end

//kill all the variable, strings and waves in a data folder
// will kill dependencies up to ten deep
 function killallinfolder(df)
	string df
	string savefolder=getdatafolder(1)
	if(datafolderexists(df))
		setdatafolder(df)
		variable i=0,count
		do	
			killstrings /A/Z
			killvariables /A/Z
			killwaves /A/Z
			count = CountObjects(df,1)
			count +=  CountObjects(df,2)
			count +=  CountObjects(df,3)
			i+=1
		while(count*(i<10))
		setdatafolder(savefolder)
	endif
end

