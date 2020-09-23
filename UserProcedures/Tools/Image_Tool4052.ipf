//File: Image_Tool4			Created: 6/98
// Jonathan Denlinger (JD), Advanced Light Source, JDDenlinger@lbl.gov
// with contributions from Eli Rotenberg (ER), ERotenberg@lbl.gov 
//   & Aaron Bostwick (AB), ABostwick@lbl.gov
//
#pragma version = 4.052
// 1/24/10 jdd -- Add back ColorTables and use Eli's newer('08) ColorNameL() loading of all_ct array into ColorTables folder
//                          instead of my previous ALL_CT array in each ImageTool folder
// v4.051   6/10/09 JD add "root:"+PossiblyQuoteName(dwn) to NewImg() & SetupImg()
// v4.050   5/3/09  Add in David Fournier (UBC) "EDCs over Path" tab
//                   3/11/09 JD add Vert Slice Transpose to ExportImage
//                  3/7/09  JD  -- fix CTinvert interpretation in dosetscale() as below
//  v4.043 12/1/08   JD  -- redefine CTinvert: 0=normal, 1=invert (selectCT)
//         		 3/10/08 JD allow Analyze Fit Position to post-fit to any order polynomial
//  v4.042  2/19/08 JD  fix VolModify>Rescale & Set X=0, Y=0, Z=0 account for displayed orientation
//  v4.041   2/11/08 JD  fix VolModify>Shift popup dialog (two letter direction specifier)
//                                         fix image export CT and 3D->2D wavenote (header) info
//                                         initial gamma=0.5 default
//  v4.04     1/30/08  JD add Append (to top Graph) option to ExportStackFct popup
//    					also add checkbox to fix offset for subsequent IT Stack updates
//  v4.039a 4/15/07 comment out link to 'colortables.ipf' -- only needs file User Procedures:ColorTables:IDL_CT.itx
//  v4.039  3/3/06 fw added Avg Z to VolModify (& VolAvg to Volume5.ipf)
//  v4.038  12/11/05 incorporate (er v4.027, 11/1/05) consolidation of GraphMarquee items to one submenu
//                  -- eliminate 1 line GraphMarquee definitions; reorder marquee menu items
//                10/17/05 jdd  add rotation center option to ImgRotate (use lower left corner of marquee)
//                10/9/05 JD fix Export Z profile scaling;  save img export volappen/concat nam
//  v4.037  9/17/05 JD added ImgDeglitch to Process popup
//  v4.036  7/25/05 JD change Volume Reorder to be Transpose using new VolTranspose fct
//  v4.035  6/26/05 JD change HairX1={-inf,0,inf} to {-inf,inf} to allow proper profileH scaling; same for Y1
// v 4.034  5/20/04 JD
//           add image concatenate to ExportImage options; added new demoImage and demoVol
//           5/17/04 JD: convert option /O=destw to /D=destw to match image_util &Volume changes
//		  5/30/04 rewrite RescaleBox; move & rewrite RescaleImg() to image_util (works 2D & 3D)
//                            renamed some *Stack functions to  Stack* for easier grouping
//                            convert imgAnalyze to Function, eliminate PickStr, ...
// v 4.033, 5/15/04  incorporate (v4.024, 10/28/03 AB) changes:
//		Allow mutiple imagetools and stack windows; support Legacy Imagetool windows
//		kill datafolder on window close
//		Make initimagetool & all stack procs into functions
//		add stack_getdf(),getswn(df)
//		Added Removeallfromgraph(graphName) killallinfolder(df) which should perhaps be moved to WinUtils or WaveUtils
//		Changing slice direction preseves cursor locations
// 		Add wave name to title string
//		fix volume modify bug introduced by 4.023 fix
// v 4.032, 5/10/04  incorporate (v4.025, 1/23/04 ER) support for IDL color tables 
//           JD: include CT wave note during export for CT Controls adjustment
// v 4.031, 2/22/04 JD  fix bug in Find peak variables
// v 4.03,  11/28/03 JD  
//     	        added working Image Rotation to ImgModify (also v4.026, 4/14/04 ER); convert RescaleImg to function; 
//		added Rotate & Reorder to VolModify; implemented Export Image append to Volume/Img
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
#include <Cross Hair Cursors>
#include "List_util"
#include "Image_util"
#include "wav_util"
#include "volume", version>=5.11
#include "colortables"   // all_ct array loaded in colortable folder 

//Proc	 	InitImageTool()
//Macro 		ShowImageTool( )
//Fct 		UpdateXYGlobals(tinfo)

//Window 	ImageTool()			 	: Graph
//Fct/T 		PickStr( promptstr, defaultstr, wvlst )	� calls procedure 
//Proc 		Pick_Str( str1, str2 )			� pops up dialog box
//Proc 		NewImg(ctrlName) 			: ButtonControl
//Proc 		PickImage( wn )
//Fct/T 		ImgInfo( image )
//Fct 		SetHairXY(ctrlName,varNum,varStr,varName) 	: SetVariableControl
//Proc 		ImgModify(ctrlName, popNum,popStr) : PopupMenuControl
//Proc 		PopFilter(ctrlName,popNum,popStr) 	: PopupMenuControl
//Proc 		ImageUndo(ctrlName,popNum,popStr) 	: PopupMenuControl
//Proc 		ImgAnalyze(ctrlName, popNum,popStr) : PopupMenuControl
//Fct 		AREA2D( img, axis, x1, x2, y0 )
//Fct/C  		EDGE2D( img, x1, x2, y0, wfrac )   � return CMPLX(pos, width)
//Fct/C  		PEAK2D( img, x1, x2, y0 )			� return CMPLX(pos, width)
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
//Fct 		StackUpdate(ctrlName)					: ButtonControl
//Fct 		Image2Waves( img, basen, dir )
//Proc 		SetOffset(ctrlName,varNum,varStr,varName) 	: SetVariableControl
//Proc 		AutoOffset(ctrlName) 					: ButtonControl
//Fct 		StackOffset( shift, offset )
//Proc 		ExportStack( basen ) 					

//Window 	ZProfile() 					: Graph

//Proc 		Area_Style() 				: GraphStyle
//Proc 		Edge_Style() 				: GraphStyle
//Proc 		Peak_Style() 				: GraphStyle

Menu "2D"
	"-"
	"Image Tool 4!"+num2char(19)+"/2", ShowImageTool()
		help={"Show Image Processing GUI"}
	"New ImageTool",NewImageTool("")
	"demoImage"
End

Menu "3D"
	"demoVol"
End

menu "GraphMarquee"
	"-"
	submenu "ImageTool4"
		"AdjustCT"
		"Crop"
		"Norm X [select Y-range]", ImgModify("", 0,"Norm X")
		"Norm Y [Select X-range]", ImgModify("", 0,"Norm Y")
		"Scale Data Max=1", ImgModify("", 0,"Norm D")
		"Offset Data Min=0", ImgModify("", 0,"Offset D")
//		submenu "Norm"
//			"X [select Y-range]", ImgModify("", 0,"Norm X")
//			"Y [Select X-range]", ImgModify("", 0,"Norm Y")
//			"Scale Data Max=1", ImgModify("", 0,"Norm D")
//			"Offset Data Min=0", ImgModify("", 0,"Offset D")
//		end
		"-"
		"AreaX", ImgAnalyze("", 0,"Area X")
		"Find Edge", ImgAnalyze("", 0, "Find Edge")
		"Find Peak", ImgAnalyze("", 0, "Find Peak")
	end
end

//Function NormX()// : GraphMarquee
//--------------------
//	ImgModify("", 0,"Norm X")
//End

//Function NormY() : GraphMarquee
//--------------------
//	ImgModify("", 0,"Norm Y")
//End

//Function NormD() : GraphMarquee
//--------------------
//	ImgModify("", 0,"Norm D")
//End

//Function OffsetD() : GraphMarquee
//--------------------
//	ImgModify("", 0,"Offset D")
//End

//Proc AreaX() : GraphMarquee
//--------------------
//	ImgAnalyze("", 0,"Area X")
//End

//Proc Find_Edge() : GraphMarquee
//--------------------
//	ImgAnalyze("", 0, "Find Edge")
//End

//Proc  Find_Peak() : GraphMarquee
//--------------------
//	ImgAnalyze("", 0, "Find Peak")
//End



Proc ImageToolHelp()
	DoWindow/F ImageToolInfo
	if (V_flag==0)
		string htxt
		NewNotebook/W=(100,100,570,400)/F=1/K=1/N=ImageToolInfo
		Notebook ImageToolinfo, showruler=0, backRGB=(45000,65535,65535)
		Notebook ImageToolinfo, fstyle=1, text="Image Tool 4\r"
		Notebook ImageToolinfo, fstyle=0, text="version 4.00, Feb2003 J. Denlinger\r"
		Notebook ImageToolinfo, fstyle=0, text="Contributions by Eli Rotenberg\r\r"
		
		Notebook ImageToolinfo, fstyle=1, text="Mouse Shortcuts:\r"
		Notebook ImageToolinfo, fstyle=2, text="Image & Line Profile quadrants\r"
			htxt="   Cmd/Ctrl + mouse = dynamic update of cross-hair position\r"
			htxt+="   Opt/Alt + mouse = left/right/up/down step of cross-hair\r"
			htxt+="   Shift + mouse = center cross-hair in image\r"
		Notebook ImageToolinfo, fstyle=0, text=htxt
		Notebook ImageToolinfo, fstyle=2, text="Z-profile quadrant\r"
			htxt="   Cmd/Ctrl + mouse = dynamic update of image slice z-value\r"
			htxt+="   Opt/Alt + mouse = left/right step of image slice z-value\r"
		Notebook ImageToolinfo, fstyle=0, text=htxt
		
		Notebook ImageToolinfo, fstyle=1, text="\rNew Features:\r"
			htxt=  "    v4.05- add EDC over path Tab from UBC/D.Fournier\r"
			htxt+=  "    v4.043- post-fit Analyze to any order polynomial\r"
			htxt+= "    v4.042- fix VolModify>Rescale & SetX=0, ...; to recognize plot orientation\r"
			htxt+="    v4.041- fix VolModify>Shift; fix image export wavenote; dafault gamma=0.5\r"
			htxt+="    v4.04 - add Append (to top Graph) option to ExportStackFct popup\r"
			htxt+="   v4.034 - Added image concatenate export; new demo image/vol (JD)\r"
			htxt+="   v4.033 - Added support for multiple imagetools (AB)\r"
			htxt+="   v4.032 -  Added support for more color tables (ER)\r"
			htxt+="   v4.03 - Added Image Rotation to Process\r"	//JD
			htxt+="   v4.023 - Fix 3d dataset internal referencing bug for subfolder location\r"	//JD
			htxt+="   v4.022 - Added \"Last Marquee\" option to color options for 3d volumes\r"	//!!ER
			htxt+="   v4.02 - Added Export tab +rewrite subroutines(JD)\r"
			htxt+="   v4.01 - Added Z-slice averaging option (JD)\r"
			htxt+="   v4.00 - merge volume controls to XY window (ER), added options for colors\r"
			//htxt+="   v3.91 - Added new Resize using Marquee box range\r"
			//htxt+="   v3.9 - OS (Mac/Win) specific panel sizes\r"
			//htxt+="   v3.8 - Revamped & added interpolate to Resize image\r"
			//htxt+="   v3.7 - Cross hair added to line profile plots\r"
			//htxt+="   v3.5 - Added Invert CT; new Shift image modify option\r"
			//htxt+="   v3.4 - New 3D animate features\r"
			//htxt+="   v3.3 - This help window + step mouse actions\r"
			//htxt+="   v3.2 - Export (Image/Profile) (Display/Append) options added\r"
			//htxt+="   v3.1 - Color Table Gamma, Red Temp/Grayscale & Rescale controls\r"
			//htxt+="   (er) - live update of cross-hair & z-slice with Cmd+mouse\r"
			//htxt+="   v3.0 - 3D data set slicing & Z-profile control\r"
		Notebook ImageToolinfo, fstyle=0, text=htxt
		
	endif
End

// *** Image Procs and Functions *****

Function InitImageTool(df)
//===============
	string df
	
	string oldfol= getdatafolder(1)
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
		variable/G nx=111, ny=101,center, width		
		variable/G xmin=0, xinc=1, xmax, ymin=0, yinc=1, ymax
		variable/G dmin0, dmax0, dmin=0, dmax=1
		variable/G numpass=1			//# of filter passes
		variable/G gamma=0.5, CTinvert=0
		make/o/n=(nx, ny) image,  image0,  image_undo	
		make/o/n=(nx) profileH, profileH_x=p
		make/o/n=(ny) profileV, profileV_y=p
		Make/O HairY0={0,0,0,NaN,Inf,0,-Inf}
		Make/O HairX0={-Inf,0,Inf,NaN,0,0,0}
		Make/O HairY1={0,0}, HairX1={-Inf,Inf}
		make/o/n=256 pmap=p
		Make/o/T/N=5 axisLabels=""

		//ColorTable
		make/o/n=(256,3) Image_CT, himg_ct,vimg_ct
		IF (DataFolderExists("root:colors")==0)
			execute "colorNameL()"			//can't call procedure from function, so execute
	//		ColorNamesList()		// eill give error if variable root:colors:s_colorNL does not already exist
		ENDIF
			string/G CTnam="Red Temperature"

		variable oldCTload
		IF (oldCTload)		
			make/o/n=(256,3,43) ALL_CT
				//make/o/n=(256,3) RedTemp_CT,  Gray_CT
				//RedTemp_CT[][0]=min(p,176)*370
				//RedTemp_CT[][1]=max(p-120,0)*482
				//RedTemp_CT[][2]=max(p-190,0)*1000
				//Gray_CT=p*256
			
			//IDL color tables (ER) -load all 40 into one big array
			// (JD) load complete binary array; Do not need root:colors subfolder
			string/G CTnam="Red Temperature"
			variable refnum
			Open/Z/R/P=Igor refnum as ":User Procedures:Utility:IDL_CT.itx"	
			//print V_flag
			if (V_flag==0)		//opened - exists
				Close refnum
				LoadWave/T/Q/O/P=Igor ":User Procedures:Utility:IDL_CT.itx"	// -> ALL_CT
			else
				Open/Z/R/P=Igor refnum as ":User Procedures:ColorTables:IDL_CT.itx"	
				if (V_flag==0)		//opened - exists
					Close refnum
					LoadWave/T/Q/O/P=Igor ":User Procedures:ColorTables:IDL_CT.itx"	// -> ALL_CT
				else
					LoadWave/T/Q/O/P=Igor "IDL_CT.itx"		//will popup dialog for user to serach fo file
				endif
	//			make/o/n=(256,3,41) ALL_CT
	//			variable ii=0
	//			execute "loadct("+num2str(ii)+")"	//must execute once to ensure colors folder is created
	//			WAVE CCT=root:colors:CT
	//			do
	//				execute "loadct("+num2str(ii)+")"
	//				ALL_CT[][][ii]=CCT[p][q][ii]
	//				ii+=1
	//			while(ii<=40)
			endif
		ENDIF
		
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
		string/G anim_menu= "Go;-;� Forward;  Backward;  Loop;-;� Single Pass;  Continuous;-;� Full Range;  Cursors;-;Save Movie"
		variable/G anim_dir=0, anim_loop=0, anim_range=0
		make/o/n=(2,2) h_img, v_img 	//**ER
		h_img=NaN							//**ER
		v_img=NaN							//**ER
		variable/g showImgSlices=1, vol_dmin, vol_dmax
		
		// Dependencies
		//pmap:=255*(p/255)^gamma\
		setformula $(df+"pmap") , "255*(p/255)^"+df+"gamma)"
		//pmap:=255*(p/255)^(10^gamma)       // log(Gamma) works best in range {-1,+1} with 0.1 increment
		//Image_CT:=dmin+RedTemp_CT[pmap[p]][q]*(dmax-dmin)/255
		//SelectCT("",3+3,"")    //"Red Temperature"
			CTnam="Red Temperature"
			//CTstr="ALL_CT[pmap[p]][q][3]"
			//execute df+"Image_CT:="+df+CTstr
			//execute df+"Himg_CT:="+df+CTstr
			//execute df+"Vimg_CT:="+df+CTstr
//			setformula $(df+"Image_CT") , df+"ALL_CT[pmap[p]][q][3]"
//			setformula $(df+"Himg_CT") , df+"ALL_CT[pmap[p]][q][3]"
//			setformula $(df+"Vimg_CT") , df+"ALL_CT[pmap[p]][q][3]"
//		SelectCT("",3,"")			//cannot call because window not defined yet & getdf() won't work
		string CTstr="root:colors:all_ct[pmap[p]][q][3]"		//3=RedTemperature
		setformula $(df+"Image_CT"), CTstr
		setformula $(df+"Himg_CT"), CTstr
		setformula $(df+"Vimg_CT"), CTstr
		//Image_CT:=RedTemp_CT[pmap[p]][q]	//  /255
		//himg_ct:=RedTemp_CT[pmap[p]][q]
		//vimg_ct:=RedTemp_CT[pmap[p]][q]
		//setformula $(df+"himg_ct")  ,"RedTemp_CT[pmap[p]][q]"
		//setformula $(df+"vimg_ct")  ,"RedTemp_CT[pmap[p]][q]"

		
		setformula $(df+"profileH") , "image("+df+"profileH_x)("+df+"Y0)"
		setformula $(df+"profileV"), "image("+df+"X0)("+df+"profileV_y)"
		setformula $(df+"D0") ,  df+"image)("+df+"X0)("+df+"Y0)"
		//profileH:=image(profileH_x)(root:ImageTool:Y0)
		//profileV:=image(root:ImageTool:X0)(profileV_y)
		//profileZ:=$datnam(root:ImageTool:X0)(root:ImageTool:Y0)(x)
		//root:ImageTool:D0:=root:ImageTool:image(root:ImageTool:X0)(root:ImageTool:Y0)

		// Nice pretty initial image	
			SetScale/I x -25,25,"" image, image0;  
			SetScale/I y -25,25,"" image, image0
			image=cos((pi/10)*sqrt(x^2+y^2+z^2))*cos( (2.5*pi)*atan2( y, x))
			SetScale/I x -15,15,"" image, image0
		
		//Duplicate/O image image0, image_undo

		image0=image; image_undo=image
		ImgInfo(Image)
		
	NewDataFolder/O/S $(df+"STACK")
//		make/o/n=10 line0, line1, line2
		variable/G xmin=0, xinc=1, ymin=0, yinc=1, dmin=0, dmax=1
		variable/G shift=0, offset=0, pinc=1
		variable/G fixoffset=0			// added v4.04
		string/G basen="base"
	SetDataFolder root:
	//print GetDataFolder(1)
	//DemoImage( )
	//NewImg( "root:demo2D" )
	//KillWaves/Z demo2D
End

Function demoImage( )			//image )
//==============
// image suitable for demonstating key features
	make/O/N=(101,81) root:demo2D
	wave im=root:demo2D
	
	SetScale/I x -25,25,"" im
	SetScale/I y -25,25,"" im
		//image=cos((pi/10)*sqrt(x^2+y^2+z^2))*cos( (2.5*pi)*atan2( y, x))   //old
		//im=exp(-(((abs(x)-15-0.005*y^2)^2)/(10-0.01*y^2)))  //Left-Right arcs
		im=exp(-(((-x-15-0.005*y^2)^2)/(10-0.01*y^2)))  //Left arc
		im+=0.1*erfc((x-15-0.005*abs(y)^1.75)/(2-0.002*y^2))  //Right arc step
		im+=+exp(-(((abs(y)-15-0.2*x^2)^2)/(20-0.02*x^2)))   //Top-Bottom arcs
		im+=0.05*(1+cos((pi/2)*sqrt(x^2+y^2)))*exp(-(x^2+y^2)/50) //Central circles
		im+=gnoise(0.005)+0.01
	SetScale/I x -15,15,"" im
	IMGwriteNote( im, "Binding Energy (eV)", "Angle (deg)")
	SetDimLabel 0,-1, 'Binding Energy (eV)', im
	SetDimLabel 1,-1, 'Angle (deg)', im
	NewImg( "root:demo2D" )
End


Function demoVol( )
//==============
// image suitable for demonstating key features
	make/O/N=(81,61,41)  root:demo3D
	wave vol=root:demo3D
	
	SetScale/I x -25,25,"" vol
	SetScale/I y -25,25,"" vol
	SetScale/I z -15,15,"" vol
		//vol=exp(-(((abs(x)-15-0.005*y^2-0.01*z^2)^2)/(10-0.01*y^2)))  //Left-Right arcs
		vol=exp(-(((-x-15-0.005*y^2)^2)/(10-0.01*y^2)))  //Left arc
		vol+=0.1*erfc((x-15-0.005*abs(y)^1.75-0.01*z^2)/(2-0.002*y^2))  //Right arc step
		vol+=+exp(-(((abs(y)-15-0.2*x^2+0.1*z^2)^2)/(20-0.02*x^2)))   //Top-Bottom arcs
		vol+=0.1*(1+cos((pi/2)*sqrt(x^2+y^2+z^2)))*exp(-(x^2+y^2-0.5*z^2)/50) //Central circles
	SetScale/I x -15,15,"" vol
	SetScale/I z 20,50,"" vol
	//VOLwriteNote(imw, "Energy", "angle", "Photon Energy (eV)")
	SetDimLabel 0,-1, 'Binding Energy (eV)', vol
	SetDimLabel 1,-1, 'Angle (deg)', vol
	SetDimLabel 2,-1, 'Photon Energy (eV)', vol
	NewImg( "demo3D" )
End

Function/S ShowImageTool()
//==================
	string df ="ImageTool"
	DoWindow/F ImageTool
		if (V_flag==0)
			ShowImageTool_( df, "" )
		endif
	return df
End

 Function/S NewImageTool( imgn )
//=================
	string imgn		// initial image to load
	string df=uniquename("ImageTool",11,0)
	return ShowImageTool_( df, imgn )
End

Function/S ShowImageTool_( df, imgn )
//==================
	string df, imgn
	df=SelectString( strlen(df)==0, df, "ImageTool")

	InitImageTool(df)
	Image_Tool("root:"+df+":")
	DoWindow/C $df
		
	SetProfiles()
	SetHairXY( "Check", 0, "", "" )

	//Resize Panel (OS specific)
	string os=IgorInfo(2)
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
	
	//load initial image
	if (strlen(imgn)>0)
		NewImg(imgn)
	else						//default test image
		DemoImage()
		//NewImg( "root:demo2D" )
		KillWaves/Z root:demo2D
	endif
	return df
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
	string dfn=StringFromList(1,df,":")
	Display /W=(341,146,993,639) HairY0 vs HairX0 as dfn
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
	PopupMenu ImageProcess,mode=0,value= #"\"Crop;Transpose;Rotate;Resize;Rescale;Set X=0;Set Y=0;Shift;Reflect X;-;Norm X;Norm Y;Norm D;Offset D;Invert D;Deglitch\""
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
	Button Stack,pos={313,25},size={45,18},disable=1,proc=StackUpdate,title="Stack"
	Button Stack,help={"Extract spectra from current image and export to separate Stack_  plot window.  Uses current axes limits for extracting spectra."}
	
	SetVariable setgamma,pos={74,26},size={52,14},disable=1,title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol",limits={0.05,Inf,0.05},value= $(df+"gamma")
	PopupMenu SelectCT,pos={153,23},size={43,20},disable=1,proc=SelectCT,title="CT"
	//PopupMenu SelectCT,mode=0,value= #"\"Grayscale;Red Temp;Invert;Rescale\""
	//Popupmenu selectCT,mode=0,value="Invert;Rescale;"+colornameslist()     //ER
	Popupmenu selectCT,mode=0,value="Invert;Rescale;"+CTnamelist(2)         //JD
	Button ShowHelp,pos={44,3},size={18,22},proc=ShowWin,title="?"
	Button ShowHelp,help={"Show shortcut & version history notebook"}
	TabControl imgtab,pos={63,0},size={575,48},proc=imgTabProc,tabLabel(0)="info"
	TabControl imgtab,tabLabel(1)="process",tabLabel(2)="colors"
	TabControl imgtab,tabLabel(3)="volume",tabLabel(4)="export",value= 0
	///////
	if (exists("AddEDCpathTab2ITpanel"))
		execute "AddEDCpathTab2ITpanel()"				// Code in Procedure_EDC.ipf (David Fournier, UBC)
	endif
	///////
	SetVariable setZ0,pos={197,26},size={70,15},disable=1,proc=SelectSlice,title="Z"
	SetVariable setZ0,help={"Select/show  value of  current slice of 3D data set."}
	SetVariable setZ0,limits={0,206,1},value= $(df+"Z0")
	SetVariable setSlice,pos={135,25},size={45,15},disable=1,proc=SelectSlice,title=" "
	SetVariable setSlice,help={"Select 3D image slice index."}
	SetVariable setSlice,limits={0,206,1},value= $(df+"islice")
	Button SliceMinus,pos={121,24},size={12,16},disable=1,proc=StepSlice,title="<"
	Button SliceMinus,help={"Decrement image slice index."}
	Button SlicePlus,pos={181,24},size={12,16},disable=1,proc=StepSlice,title=">"
	Button SlicePlus,help={"Increment image slice index."}
	PopupMenu popAnim,pos={465,23},size={74,20},disable=1,proc=AnimateAction,title="Animate"
	PopupMenu popAnim,help={"Step thru slices of 3D data set"}
	PopupMenu popAnim,mode=0	//,value= "\""+$(df+"anim_menu")+"\""	//root:ImageTool:anim_menu	//#anim_menu
		execute "PopupMenu popAnim,value="+df+"anim_menu"
	PopupMenu popSlice,pos={65,21},size={42,20},disable=1,proc=SelectSliceDir
	PopupMenu popSlice,mode=1,popvalue="XY/Z",value= #"\"XY/Z;XZ/Y;YZ/X\""
	SetVariable setZstep,pos={268,25},size={60,15},disable=1,title="step"
	SetVariable setZstep,limits={1,Inf,1},value= $(df+"zstep")
	SetVariable setZavg,pos={331,25},size={62,15},disable=1,title="navg",proc=SetSliceAvg		//**JD
	SetVariable setZavg,limits={1,Inf,2},value= $(df+"nsliceavg")
	PopupMenu VolModify,pos={394,23},size={65,20},disable=1,proc=VolModify,title="Modify"
	PopupMenu VolModify,mode=0,value= #"\"Crop;Rotate;Resize;Transpose;Rescale;Set X=0;Set Y=0;Set Z=0;Norm Z;Avg Z (to img);Shift;\""
	CheckBox ShowImgSlices,pos={547,25},size={78,14},disable=1,proc=ShowImgSliceCheck,title="Image Slices"
	CheckBox ShowImgSlices,value= 1
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
	TitleBox version,pos={10,28},size={35,14},fsize=9, title="v4.050",frame=0, fstyle=2
	
	SetWindow kwTopWin,hook=imgHookFcn,hookevents=3
EndMacro


// not used  anymore by img Analyze
//Function/T PickStr( promptstr, defaultstr, wvlst )
//=============
	String promptstr, defaultstr
	variable wvlst
	String/G  PickStr0, Promptstr0=promptstr, DefaultStr0=defaultstr
	//string a=""
	string str=defaultstr
	if (wvlst==1)
		//execute "Pick_Str( \"\", )"
		prompt str, promptstr, popup, WaveList("!*_x",";","")
	else
		//execute "Pick_Str( , \"\" )"
		prompt str, promptstr
	endif
	DoPrompt "Pick String",  str
	//execute cmd
	Pickstr0=str
	return str
End

//Obsolete with DoPrompt
//Proc Pick_Str( str1, str2 )
//------------
	String str1=DefaultStr0, str2=DefaultStr0
	prompt str1, Promptstr0
	prompt str2, Promptstr0, popup, WaveList("!*_x",";","")
	Silent 1
	String/G PickStr0=str1+str2
End

//Obsolete with DoPrompt
//Proc PickImage( wn )
//------------
	String wn=StrVarOrDefault(getdf1()+"imgnam","")
	prompt wn, "new image, 2D array", popup, WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")
	
	string df=getdf1()
	$(df+"imgnam")=wn
	$(df+"imgfldr")=GetWavesDataFolder($wn, 1)
	$(df+"exporti_nam")=wn+"_"		// prepare export name
End

Function NewImg(ctrlName) : ButtonControl
//============
	String ctrlName

// Popup Dialog image array selection
	string df=getdf()
	SVAR imgfldr=$(df+"imgfldr"), imgnam=$(df+"imgnam"), datnam=$(df+"datnam")
	//if (stringmatch(ctrlName, "LoadImg"))
	strswitch ( ctrlName)
	case "LoadImg":
		//PickImage( )
		String wn=StrVarOrDefault(df+"imgnam","")
		//put 3D first in list??
		prompt wn, "new array", popup, WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")
		DoPrompt "Select 2D Image (or 3D volume)" wn
		if (V_flag==1)
			abort		//cancelled
		endif
		imgnam=wn
		imgfldr=GetWavesDataFolder($imgnam, 1)
		datnam=imgfldr+PossiblyQuoteName(imgnam)
		break
	default:
		datnam=ctrlName
		imgnam=datnam
		imgfldr=GetWavesDataFolder($imgnam, 1)
	endswitch
//		print datnam,imgnam,imgfldr
	SVAR exporti_nam=	$(df+"exporti_nam")
	exporti_nam=imgnam+"_"				// prepare export name
	PauseUpdate; Silent 1
	execute "SetupImg()"		  //**ER
	NVAR ndim=$(df+"ndim")
end

Function SetupImg()		//**ER moved this out of newimg
//============
	silent 1; pauseupdate
	string df=getdf(), curr=GetDataFolder(1)
	string dfn=StringFromList(1,df,":")
	SetDataFolder $df
		SVAR dwn=$(df+"datnam")
		// put "root:" in front of data wave name if not already present
		dwn = SelectString( StringMatch(dwn,"root:*"), "root:"+PossiblyQuoteName(dwn), dwn)  //6/10/09 jdd
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
		WAVE axisLabels=axisLabels
	setdatafolder $curr
	
	DoWindow/T $dfn ,dfn+":"+dwn

	string xlbl="x", ylbl="y", zlbl="z"
	ndim=WaveDims(  dw )	//$dwn )
	//print "SetupImg, ndim", ndim, dwn, dfn
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
		Z0=(zmin+zmax)/2
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
				 appendimage/W=$dfn/B=imgv v_img								
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

		zlbl=GetDimLabel( dw, 2, -1)
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
//		print dwn, exists( PossiblyQuoteName(dwn)), NameOfWave(dw), exists( dwn)
//		execute "duplicate/O "+PossiblyQuoteName(dwn)+" Image,  Image0,  Image_Undo"
		duplicate/O dw Image,  Image0,  Image_Undo

		// Remove dependencies to previous 3D data before loading
		//DoWindow/K ZProfile //not used anymore
//		profileZ=nan
	ENDIF	//**ER
	xlbl=GetDimLabel( dw, 0, -1)
	ylbl=GetDimLabel( dw, 1, -1)
	SetDimLabel 0,-1,$xlbl, Image,  Image0,  Image_Undo
	SetDimLabel 0,-1,$ylbl, Image,  Image0,  Image_Undo

	SetAxis/A
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

	SetHairXY( "Center", 0, "", "" )
 	SetProfiles()	
 
	ReplaceText/N=title "\Z09"+imgnam
	imgproc=""
	//string xlbl="x", ylbl="y", imnote
	//imNote=IMGreadNote( $imgnam )
	//xlbl=StringByKey("XAXIS", imnote,"=", ",")
	//ylbl=StringByKey("YAXIS", imnote,"=", ",")
	//xlbl=GetDimLabel( $imgnam, 0, -1)
	//ylbl=GetDimLabel( $imgnam, 1, -1)
	//print imNote, xlbl,  ylbl
	Label bottom xlbl
	Label left ylbl
	UpdateImgSlices(0)		//**ER
	//SetDataFolder $curr
End

Function ShowImgSliceCheck(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR sis=$(getdf()+"showImgSlices")
	sis=checked
	execute "setupimg()"
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
	string dfn=StringFromList(1,df,":")
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
	string dfn=StringFromList(1,df,":")
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
	if (idir==0)	// YZ-X
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
	if (idir==1)	// XZ-Y
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
	if (idir==2)	// XY-Z
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
	//Label bottom WaveUnits(dw, idir)

	//SelectSlice("", trunc(nz/2), "", "" )
	SelectSlice("SetZ0", Z, "", "" )
	SetSliceAvg("",nsliceavg,"","")			//also calls SelectSlice()
	
	DoWindow/F $dfn
	//Label bottom WaveUnits(Image, 0)
	//Label left WaveUnits(Image, 1)
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
	string dfn=StringFromList(1,df,":")
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
		opt+= "/D="+df+"Image"
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
			newmenu=ReplaceItemInList( 2, "�  "[popNum-3]+" Forward", newmenu, "" )
			newmenu=ReplaceItemInList( 3, " � "[popNum-3]+" Backward", newmenu, "" )
			newmenu=ReplaceItemInList( 4, "  �"[popNum-3]+" Loop", newmenu, "" )
			anim_dir=popNum-3
			break
		//endif
		//if ((popNum>=7)*(popNum<=8))
		case 7:
		case 8:
			newmenu=ReplaceItemInList( 6, "�  "[popNum-7]+" Single Pass", newmenu, "" )
			newmenu=ReplaceItemInList( 7, " � "[popNum-7]+" Continuous", newmenu, "" )
			anim_loop=popNum-7
			break
		//endif
		//if ((popNum>=10)*(popNum<=11))
		case 10:
		case 11:
			newmenu=ReplaceItemInList( 9, "�  "[popNum-10]+" Full Range", newmenu, "" )
			newmenu=ReplaceItemInList( 10, " � "[popNum-10]+" Cursors", newmenu, "" )
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
//=============
	variable istart, iend, istep, idir, imovie

	variable ii, nslice=abs((iend-istart)/istep)+1
	//print istart, iend, istep, nslice
	string df=getdf()
	SVAR dn=$(df+"datnam")
	string dfn=StringFromList(1,df,":")
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
//==============
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
	string dfn=StringFromList(1,df,":")
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
//========================
//	Crop -- ImgCrop( img, op t)
//	Transpose -- bulit-in MatrixTranspose
//	Rotate -- ImgRotate( img, ang, opt )    
//		-- (optional) Marquee diagonal angle definition
//		-- (optional) dynamic line end drag  angle definition
//	Rescale -- ImgRescale( img, range, opt )
//		-- (optional) Marquee corner values of interest
//	Set X=0, Set Y=0
//	NormX, NormY -- Area2D( img, )
//	Resize  -- ImgResize( img, opt )
//	ReflectX, OffsetD, NormD
//	Shift -- ImgShift( img, shiftw, opt )
//       DeGlitch -- ImgDeglitch( img, opt )
//
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
	string/G cmd=""
	variable ii
	string xrng, yrng
	
	strswitch( popStr )
	case "Crop" :
			//string/G x12_crop, y12_crop
			//SVAR x12_crop=x12_crop, y12_crop=y12_crop
		//check for marquee
		xrng=ImgRange(0, df+"x12_crop")
		yrng=imgRange(1, df+"y12_crop")
		//print "xyz rng=", xrng, yrng
		prompt xrng, "X range (x1,x2); blank =full vol X range"
		prompt yrng, "Y range (y1,y2); blank =full vol Y range"
		DoPrompt "Crop Image", xrng, yrng
		if (v_flag==1)
			SetDataFolder $curr
			abort
		endif
		string/G $(df+"x12_crop")=xrng		// save globals
		string/G $(df+"y12_crop")=yrng
		string croprng=""		//Key string
		croprng+=SelectString(strlen(xrng)==0, "/X="+xrng, "")
		croprng+=SelectString(strlen(yrng)==0, "/Y="+yrng, "")

	// Execute local image command within Image_Tool		
		opt=croprng+"/D=Image"
		cmd="ImgCrop(Image_Undo, \""+opt+"\")"
		execute cmd
		//ImgCrop(Image_Undo,  opt)
		//print cmd
	// return image command for use outside of Image_Tool
		opt="/D=+c"+croprng
		cmd="ImgCrop("+imgnam+", \""+opt+"\")"		// Overwrite version of command for export
			//Duplicate/O/R=(x1_crop,x2_crop)(y1_crop,y2_crop) Image_Undo, Image
			//endif
		if (lockColors==0)
			AdjustCT()
		endif
		break
	
	case "Transpose":
		MatrixTranspose Image
		cmd="MatrixTranspose "+ imgnam		// for execution outside of ImageTool
		//readjust crosshair
		ModifyGraph offset(HairY0)={IMAG(coffset), REAL(coffset)}
		ModifyGraph offset(HairX1)={IMAG(coffset), 0}
		ModifyGraph offset(HairY1)={0, REAL(coffset)}
		//print coffset, GetWaveOffset(root:IMG:HairY0)
		 SetAxis/A
		 
		 //Update X-Y labels
		 //print GetDimLabel(image,0,-1), GetDimLabel(image,1,-1)
		 Label bottom GetDimLabel(image,0,-1)
		 Label left GetDimLabel(image,1,-1)
		break
	
	case "Rotate":
		Variable angle=NumVarOrDefault(df+"rot_ang", 0 )
		Variable rotdir=NumVarOrDefault(df+"rot_dir", 1 )
		String rotctr=StrVarOrDefault(df+"rot_ctr", "0,0" )
		Variable newaxes=NumVarOrDefault(df+"rot_axes", 1 )
		// determine an angle from marquee aspect ratio (if exists)
		GetMarquee/K left, bottom
		if (V_Flag==1)
			//variable dx, dy
			//dx=abs(V_right-V_left)
			//dy=abs(V_top-V_bottom)
			//angle=(180/pi)*atan2( dy/yinc, dx/xinc)
			variable slope=abs( (V_top-V_bottom)/(V_right-V_left) )
			angle=(180/pi)*atan(slope)
			angle=min(angle, 90-angle)
			rotctr=num2str(V_left)+","+num2str(V_bottom)
		endif
	
		//  prompt for rotation angle value or graphical line definition option
		variable mode
		prompt angle, "Rotation Angle (deg)"
		prompt rotdir, "Rotation Direction", popup, "CW;CCW"
		prompt rotctr, "Rotation Center (x,y)"
		prompt newaxes, "Output Axes", popup, "Expand;Fixed"
		prompt mode, "Angle Selection", popup, "Manual;Interactive"
		DoPrompt "Image Rotation" mode, angle, rotdir, rotctr, newaxes
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
		variable/G $(df+"rot_ang")=angle, $(df+"rot_dir")=rotdir, $(df+"rot_axes")=newaxes
		string/G $(df+"rot_ctr")=rotctr
		//variable rotctr_x=NumFromList( 0, rotctr, ","), rotctr_y=NumFromList( 1, rotctr, ",")

		IF (mode==2)
			//Redimension/N=2 roty, rotx
			Make/O/N=2 roty, rotx
			//GetMarquee/K left, bottom
			if (V_Flag==1)
				rotx={V_left, V_right}
				roty={V_bottom, V_top}
			else
				rotx=(xmin+xmax)/2
				roty={ymin, ymax}
			endif
			AppendToGraph roty vs rotx
			ModifyGraph rgb(roty)=(65535,65535,0)		//yellow
			Button DoneRot size={40,18},pos={8,50}, title="Done",  proc=DoneRotate
			GraphWaveEdit roty
			abort
			//need to finish up after pressing DONE button
		ENDIF
		
		angle=(1-2*(rotdir==2))*angle			//SelectNumber(rotdir==1,-1,1)*angle
	// Execute local image command within Image_Tool		
		opt="/D=Image" + SelectString(newaxes==2, "", "/F")
		if  ((strlen(rotctr)>0)*(stringmatch(rotctr,"0,0")==0) )
			opt+="/C="+rotctr
		endif
		cmd="ImgRotate( Image_Undo, "+num2str(angle)+ ",\"" +opt+"\")"
		execute cmd
		
	// return image command for use outside of Image_Tool
		opt=SelectString(newaxes==2, "", "/F")
		if  ((strlen(rotctr)>0)*(stringmatch(rotctr,"0,0")==0) )
			opt+="/C="+rotctr
		endif
		opt+="/D=+r"
		cmd="ImgRotate( Image, "+num2str(angle)+ ",\"" +opt+"\")"
		//ImgRotate(  Image, angle, "/D=Image" )
		
		//Imagerotate/A=(angle)/E=(Nan)/O Image
		break
		
	case "Rescale":
		GetMarquee left, bottom
		if (V_Flag==1)
			string/G x12_rescale=num2str(V_left)+","+num2str(V_right)
			string/G y12_rescale=num2str(V_bottom)+","+num2str(V_top)
			cmd=RescaleBox()
			//SetMarquee  left, top, right, bottom
			//SetMarquee  x1, y2, x2, y1
			//execute "ImgRescaleBox()"
		else
			variable xopt=NumVarOrDefault(df+"xopt_rescale",1)
			variable yopt=NumVarOrDefault(df+"yopt_rescale",1)
			NVAR xmin=xmin, xmax=xmax, xinc=xinc
			NVAR ymin=ymin, ymax=ymax, yinc=yinc
			string xrang=num2str(xmin)+", "+num2str(xmax)+", "+num2str(xinc)
			string yrang=num2str(ymin)+", "+num2str(ymax)+", "+num2str(yinc)
			string rng="/X="+xrang+"/Y="+yrang
			prompt rng, "Ranges (min,max,inc) (min,max) (min,inc) or (val)"
			prompt xopt, "X rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
			prompt yopt, "Y rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
			DoPrompt "Image rescale" rng, xopt, yopt
				if (V_flag==1)
					SetDataFolder $curr
					abort
				endif
			variable/G $(df+"xopt_rescale")=xopt, $(df+"yopt_rescale")=yopt
			opt=StringFromList( xopt-2, "/XP;/XI;/XC;/XCSR")
			opt+=StringFromList( yopt-2, "/YP;/YI;/YC;/YCSR")
			cmd=ImgRescale( $(df+"Image"), rng, opt  )
			
			// return image command for use outside of Image_Tool
			cmd="ImgRescale( "+imgnam+", "+rng+", "+opt+")"
			//cmd=ImgRescale0()
			//execute "ImgRescale()"
		endif
		break
		
	case "Set X=0":
		cmd="SetScale/P x "+num2str(xmin-REAL(coffset))+","+num2str( xinc)+",\"\" Image"
		SetScale/P x xmin-REAL(coffset), xinc,"" Image
		ModifyGraph offset(HairY0)={0, IMAG(coffset)}
		ModifyGraph offset(HairX1)={0, 0}
		break

	case "Set Y=0":
		cmd="SetScale/P y "+num2str(ymin-IMAG(coffset))+","+num2str( yinc)+",\"\" Image"
		SetScale/P y ymin-IMAG(coffset), yinc,"" Image
		ModifyGraph offset(HairY0)={REAL(coffset), 0}
		ModifyGraph offset(HairY1)={0, 0}
		break
		
	case "Norm X":
		rngopt=1
		yrng=ImgRange( 1, df+"y12_norm")
		Prompt yrng, "X Norm:  y1,y2"
		Prompt rngopt, "Norm X option:", popup, "None;Full Y"
		DoPrompt "X Norm Y-range", yrng, rngopt
			if (rngopt==2)
				yrng=ImgRange( 1, "image")  //or "axes"
			endif
			string/G $(df+"y12_norm")=yrng
			if (V_flag==1)
				SetDataFolder $curr
				abort
			endif
		variable y1, y2
		y1=NumFromList(0, yrng,",")
		y2=NumFromList(1, yrng,",")

		//Cursor/P A, profileV_y, x2pnt( Image, y1) 
		//Cursor/P B, profileV_y, x2pnt( Image, y2)
		
		make/o/n=(nx) xtmp
		SetScale/P x xmin, xinc, "" xtmp
		// different methods of normalizing? NormImg in image_util??
		xtmp = AREA2D( Image, 1, y1, y2, x )
		Image /= xtmp[p]
		cmd="Image /= xtmp[p]"
		if (lockColors==0)
			 AdjustCT()
		endif
		break
		
	case "Norm Y":
		rngopt=1
		xrng=ImgRange( 0, df+"x12_norm")
		Prompt xrng, "Y Norm:  x1,x2"
		Prompt rngopt, "Norm X option:", popup, "None;Full X"
		DoPrompt "Y Norm X-range", xrng, rngopt
			if (rngopt==2)
				xrng=ImgRange( 0, "image")  //or "axes"
			endif
			string/G $(df+"x12_norm")=xrng
			if (V_flag==1)
				SetDataFolder $curr
				abort
			endif
		variable x1, x2
		x1=NumFromList(0, xrng,",")
		x2=NumFromList(1, xrng,",")

		Cursor/P A, profileH, x2pnt( Image, x1) 
		Cursor/P B, profileH, x2pnt( Image, x2)
		
		make/o/n=(ny) ytmp
		SetScale/P x ymin, yinc,  ytmp
		ytmp = AREA2D( Image, 0, x1, x2, x )
		Image /= ytmp[q]
		cmd="Image /= ytmp[q]"
		if(lockcolors==0)
			 AdjustCT()
		endif
		break
		
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
		
		opt="/D=Image"+"/"+"IIRT"[xyopt-1]+SelectString(xyopt==2, "", "/NP")
		cmd="ImgResize(Image_Undo, \""+xyval+"\",\""+opt+"\")"
		execute cmd
		opt="/O"+"/"+"IIRT"[xyopt-1]+SelectString(xyopt==2, "", "/NP")
		cmd="ImgResize(Image, \""+xyval+"\",\""+opt+"\")"
		//execute "ResizeImg(  )"
		//SetScale/P x xmin-REAL(coffset), xinc,"" Image
		//ModifyGraph offset(HairY0)={0, IMAG(coffset)}
		break
		
	case "Reflect X":
		// future option to expand image to make output truly symmetric about X=0
		cmd="Duplicate/O Image Image_Undo; Image=Image_Undo(x)[q]+Image_Undo(-x)[q] "
		Image=Image_Undo(x)[q]+Image_Undo(-x)[q] 
		if(lockColors==0)
			AdjustCT()
		endif
		break
		
	case "Offset D":
		variable offsetval
		GetMarquee/K left, bottom
		If (V_Flag==1)
			Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, imgtmp
			WaveStats/Q imgtmp
			offsetval=V_avg
		else
			WaveStats/Q Image
			offsetval= V_min
		endif
		Image=Image_Undo - offsetval
		cmd="Image -="+num2str(offsetval)
		if(lockColors==0)
			AdjustCT()
		endif
		break
		
	case "Norm D":
		variable normval
		GetMarquee/K left, bottom
		If (V_Flag==1)
			Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, imgtmp
			WaveStats/Q imgtmp
			normval= V_avg
		else
			//WaveStats/Q Image
			normval=Image(X0)(Y0)
		endif
		cmd="Image/="+num2str(normval)
		Image=Image_Undo / normval
		if(lockColors==0)
			AdjustCT()
		endif
		break
		
	case "Invert D":
		cmd="Image*=-1"
		Image=-Image_Undo
		if(lockColors==0)
			AdjustCT()
		endif
		break
		
	case "Shift":
		// dialog to specify shift wave, if shift wave, X or Y, expansion
		SetDataFolder $curr
		///PromptShift( )
		String shftwn=StrVarOrDefault(df+"shiftwn", "" )
		Variable dir=NumVarOrDefault(df+"shiftdir", 1 )+1
		Variable expand=NumVarOrDefault(df+"shift_expand", 1 )
		prompt shftwn, "Shift Wave Name", popup, "Linear 45;Interactive Linear;-;"+WaveList("!*_x",";","DIMS:1")
		prompt dir, "Shift Direction", popup, "X(y);Y(x)"
		prompt expand, "Output Range", popup, "Shrink;Average;Expand"
		DoPrompt "Shift Image array" shftwn, dir, expand
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
		SetDataFolder $df
		
		if (stringmatch(shftwn,"Linear 45") )
		
		
		endif
		if (stringmatch(shftwn,"Interactive Linear") )
		
		
		endif
		
	
		String/G $(df+"shiftwn")=shftwn
		Variable/G $(df+"shiftdir")=dir-1, $(df+"shift_expand")=expand-2
		SVAR shiftwn=shiftwn
		NVAR shiftdir=shiftdir, shift_expand=shift_expand
		
		opt=SelectString(shiftdir==1, "/X","/Y" ) +"/D=Image/E="+num2str(shift_expand)
		cmd="ImgShift( Image_Undo, root:"+shiftwn+",\"" +opt+"\")"
		execute cmd
		//print cmd
		//ImgShift( Image_Undo, $shiftwn, "/D=Image/E="+num2str(shift_expand)
		opt=SelectString(shiftdir==1, "/X","/Y" ) +"/O/E="+num2str(shift_expand)
		cmd="ImgShift( Image, root:"+shiftwn+",\"" +opt+"\")"
		
		//print ang_rot
		//Imagerotate/A=(ang_rot)/E=Nan/O Image
		break
		
	case "Deglitch":
		Variable typ=NumVarOrDefault(df+"glitchtyp", 1 )
		Variable nline=NumVarOrDefault(df+"glitchline", nan )
		Variable npass=NumVarOrDefault(df+"glitch_npass", 1 )
		prompt typ, "Glitch Type",popup, "Point 4-pt XY avg;Point X avg;Point Y avg;Column;Row;Auto-Line"
		prompt nline, "specific column/row number (blank=auto)"
		prompt npass, "# passes"
		DoPrompt "Deglitch image" typ, nline, npass
		variable/G $(df+"glitchtyp")=typ, $(df+"glitchline")=nline, $(df+"glitch_npass")=npass
		
		opt="/O"		//overwrite image
		
		// glitch type
		string styp=""
		styp=SelectString( typ==2, styp, "/X")
		styp=SelectString( typ==3, styp, "/Y")
		styp=SelectString( typ==4, styp, "/XL")
		styp=SelectString( typ==5, styp, "/YL")
		styp=SelectString( typ==6, styp, "/L")
		opt+=styp
	
		//line number
		if (nline>0)
			opt+="="+num2str(nline)
		endif
		
		cmd="ImgDeGlitch( Image, \"" +opt+"\")"
		
		ii=0
		DO
			execute cmd
			ii+=1
		WHILE(ii<npass)
		
		//print ImgDeGlitch( Image, 
	
		break
	endswitch

		//SetDataFolder $df
	ImgInfo( Image )
		//SetDataFolder $curr
 	SetProfiles()	
	SetHairXY( "Check", 0, "", "" )
	imgproc+="+ "+popStr			// update this after operation incase of intermediate macro Cancel
	ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	//print "Image Modify: ", cmd
	print  cmd
	
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
	NVAR xmin=xmin, xmax=xmax, xinc=xinc    // store in arrays instead of variables 
	NVAR ymin=ymin, ymax=ymax, yinc=yinc	// for easier indexing
	NVAR zmin=zmin, zmax=zmax, zinc=zinc
	NVAR lockColors=lockColors
	NVAR islicedir=islicedir			// for interpreting Set X=0, Y=0, Z=0
	
	//Duplicate/o Image Image_Undo
	//imgproc_undo=imgproc
	
	variable/C coffset, rngopt
	variable voffset
	string svoldir
	string opt
	string cmd
	variable ii
	
	string newvoln
	
	strswitch( popStr )
	case "Crop" :
		string/G x12_crop, y12_crop
		SVAR x12_crop=x12_crop, y12_crop=y12_crop
		//string xrng=StrVarOrDefault(df+"x12_crop", "0,1" )
		//string yrng=StrVarOrDefault(df+"y12_crop", "0,1" )
		string xrng, yrng, zrng=""
		//check for marquee
		xrng=ImgRange(0, df+"x12_crop")
		yrng=imgRange(1, df+"y12_crop")
		if (stringmatch(CsrWave(A),"profileZ")*stringmatch(CsrWave(B),"profileZ"))
			zrng=num2str(xcsr(A))+","+num2str(xcsr(B))
		endif
		print "xyz rng=", xrng, yrng, zrng
		//Depending on islicedir marquee gives XY, XZ or YZ ranges
		//could use csrs on Zprofile for further cropping
		//string croprng=CropRange(xrng, yrng)		//, rngopt)
		//print croprng, KeyStr( "", croprng)
		//x12_crop=KeyStr( "X", croprng)
		//y12_crop=KeyStr( "Y", croprng)
	
		newvoln=datnam+"c"
		prompt xrng, "X range (x1,x2); blank =full vol X range"
		prompt yrng, "Y range (y1,y2); blank =full vol Y range"
		prompt zrng, "Z range (z1,z2); blank =full vol Z range"
		prompt newvoln, "New Volume Name"
		DoPrompt "Crop Volume", newvoln, xrng, yrng, zrng
		if (v_flag==1)
			SetDataFolder $curr
			abort
		endif
		x12_crop=xrng		// save globals
		y12_crop=yrng
		string croprng=""		//Key string
		croprng+=SelectString(strlen(xrng)==0, "/X="+xrng, "")
		croprng+=SelectString(strlen(yrng)==0, "/Y="+yrng, "")
		croprng+=SelectString(strlen(zrng)==0, "/Z="+zrng, "")
		
			//if (dim_crop==3)		// volume crop
			//	cmd="VolCrop(Image_Undo,  \""+opt+"\")"
				//VolCrop(, opt)
			//else
		//opt="/D="+df+"Vol"+croprng
		//opt="/D=root:"+newvoln+croprng
		//cmd="VolCrop(root:"+datnam+", \""+opt+"\")"
		opt="/D="+newvoln+croprng
		cmd="VolCrop("+datnam+", \""+opt+"\")"
		print cmd
		execute cmd
	
		SetDataFolder $curr
		NewImg( newvoln )		//new volume
		if (lockColors==0)
			//AdjustCT()
		endif
		break
		
	case "Rotate":
		newvoln=datnam+"r"
		Variable angle=NumVarOrDefault(df+"rot_ang", 0 )
		Variable rotdir=NumVarOrDefault(df+"rot_dir", 1 )
		Variable newaxes=NumVarOrDefault(df+"rot_axes", 1 )
		// determine an angle from marquee aspect ratio (if exists)
		GetMarquee/K left, bottom
		if (V_Flag==1)
			//variable dx, dy
			//dx=abs(V_right-V_left)
			//dy=abs(V_top-V_bottom)
			//angle=(180/pi)*atan2( dy/yinc, dx/xinc)
			variable slope=abs( (V_top-V_bottom)/(V_right-V_left) )
			angle=(180/pi)*atan(slope)
			angle=min(angle, 90-angle)
		endif
	
		//  prompt for rotation angle value or graphical line definition option
		variable mode
		prompt angle, "Rotation Angle (deg)"
		prompt rotdir, "Rotation Direction", popup, "CW;CCW"
		prompt newaxes, "Output Axes", popup, "Expand;Fixed"
		prompt mode, "Angle Selection", popup, "Manual;Interactive"
		prompt newvoln, "New volume name"
		DoPrompt "Volume Rotation" newvoln, mode, angle, rotdir, newaxes
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
		variable/G $(df+"rot_ang")=angle, $(df+"rot_dir")=rotdir, $(df+"rot_axes")=newaxes
		
		IF (mode==2)
			//Redimension/N=2 roty, rotx
			Make/O/N=2 roty, rotx
			//GetMarquee/K left, bottom
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
			abort
				//need to finish up after pressing DONE button

			//angle= 
		ENDIF
		
		angle=(1-2*(rotdir==2))*angle			//SelectNumber(rotdir==1,-1,1)*angle	
		opt="/D="+newvoln + SelectString(newaxes==2, "", "/F")
		cmd="VolRotate("+datnam+", "+num2str(angle)+ ",\"" +opt+"\")"
		execute cmd
		
		SetDataFolder $curr
		NewImg( newvoln )		//new volume
		//Imagerotate/A=(angle)/E=(Nan)/O Image
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
		//opt+="/D=root:"+newvoln
		//cmd="VolResize(root:"+datnam+", \""+xyzval+"\",\""+opt+"\")"
		opt+="/D="+newvoln
		cmd="VolResize("+datnam+", \""+xyzval+"\",\""+opt+"\")"
		print cmd
		execute cmd	
		
		SetDataFolder $curr
		NewImg( newvoln )		//new volume	
		break
		
	case "Rescale":
		variable xopt=NumVarOrDefault(df+"xopt_rescale",1)
		variable yopt=NumVarOrDefault(df+"yopt_rescale",1)
		variable zopt=NumVarOrDefault(df+"zopt_rescale",1)
		//NVAR xmin=xmin, xmax=xmax, xinc=xinc			//already done above
		//NVAR ymin=ymin, ymax=ymax, yinc=yinc
		//NVAR zmin=zmin, zmax=zmax, zinc=zinc
		string xrang=num2str(xmin)+", "+num2str(xmax)+", "+num2str(xinc)
		string yrang=num2str(ymin)+", "+num2str(ymax)+", "+num2str(yinc)
		string zrang=num2str(zmin)+", "+num2str(zmax)+", "+num2str(zinc)
//		string xrang=num2str(DimOffset($datnam,1))+", "+num2str(DimSize($datnam,1))+", "+num2str(DimDelta($datnam,1))
		string allrng="/X="+xrang+"/Y="+yrang+"/Z="+zrang
		prompt allrng, "Ranges (min,max,inc) (min,max) (min,inc) or (val)"
		prompt xopt, "X rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;ZeroVal, inc;Cursor=val"
		prompt yopt, "Y rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;ZeroVal, inc;Cursor=val"
		prompt zopt, "Z rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;ZeroVal, inc;Cursor=val"
		DoPrompt "Volume rescale" allrng, xopt, yopt, zopt
			if (V_flag==1)
				SetDataFolder $curr
				abort
			endif
		variable/G $(df+"xopt_rescale")=xopt, $(df+"yopt_rescale")=yopt, $(df+"zopt_rescale")=zopt
		// remap displayed direction to actual volume direction
		string rng
		switch( islicedir )
			case 1:			// XY/Z
				rng  =SelectString( xopt>1, "", "/X="+KeyStr( "X", allrng) )
				rng+=SelectString( yopt>1, "", "/Y="+KeyStr( "Y", allrng) )
				rng+=SelectString( zopt>1, "", "/Z="+KeyStr( "Z", allrng) )
				opt=StringFromList( xopt-2, "/XP;/XI;/XC;/XZ;/XCSR")
				opt+=StringFromList( yopt-2, "/YP;/YI;/YC;/YZ;/YCSR")
				opt+=StringFromList( zopt-2, "/ZP;/ZI;/ZC;/ZZ;/ZCSR")
				break
			case 2:			// XZ/Y
				rng  =SelectString( xopt>1, "", "/X="+KeyStr( "X", allrng) )
				rng+=SelectString( yopt>1, "", "/Z="+KeyStr( "Y", allrng) )
				rng+=SelectString( zopt>1, "", "/Y="+KeyStr( "Z", allrng) )
				opt=StringFromList( xopt-2, "/XP;/XI;/XC;/XZ;/XCSR")
				opt+=StringFromList( yopt-2, "/ZP;/ZI;/ZC;/ZZ;/ZCSR")
				opt+=StringFromList( zopt-2, "/YP;/YI;/YC;/YZ;/YCSR")
				break
			case 3:			// YZ/X
				rng  =SelectString( xopt>1, "", "/Y="+KeyStr( "X", allrng) )	
				rng+=SelectString( yopt>1, "", "/Z="+KeyStr( "Y", allrng) )
				rng+=SelectString( zopt>1, "", "/X="+KeyStr( "Z", allrng) )
				opt =StringFromList( xopt-2, "/YP;/YI;/YC;/YZ;/YCSR")
				opt+=StringFromList( yopt-2, "/ZP;/ZI;/ZC;/ZZ;/ZCSR")
				opt+=StringFromList( zopt-2, "/XP;/XI;/XC;/XZ;/XCSR")
				break
		endswitch
		
		SetDataFolder $curr
		print "VolRescale("+datnam+", \""+rng+"\",  \""+opt+"\" )"
		cmd=VolRescale( $datnam, rng, opt  )   //identical to ImgRescale()
		//need to update zmin, zinc, zmax & profileZ
		//?reload same data - wipesout record of other changes?
		NewImg( datnam )	
		//print datnam
		//execute cmd
		break
		
	// v4.42 add smarts to interpret Set X=0, Y=0, Z=0 according to displayed orientation
	case "Set X=0":
	case "Set Y=0":
	case "Set Z=0":
		// determine appropriate hair cursor value
		// identify actual volume direction according to display
		variable vmin, vinc
		strswitch (popStr )
			case "Set X=0":
				coffset=GetWaveOffset($(df+"HairY0"))
				voffset=REAL(coffset)
				xmin=xmin-voffset	
				svoldir="XXY"[islicedir-1]
				vmin=xmin; vinc=xinc
				break
			case "Set Y=0":
				coffset=GetWaveOffset($(df+"HairY0"))
				voffset=IMAG(coffset)
				ymin=ymin-voffset	
				svoldir="YZZ"[islicedir-1]
				vmin=zmin; vinc=zinc
				break
			case "Set Z=0":
				coffset=GetWaveOffset($(df+"HairZ0"))
				voffset=REAL(coffset)
				zmin=zmin-voffset	
				svoldir="ZYX"[islicedir-1]
				vmin=zmin; vinc=zinc
				break
		endswitch
//		print coffset
		
		// rescale volume direction


		strswitch (svoldir)
			case "x":
//				VolRescale( $datnam, "/X="+num2str(voffset), "/XZ")
//					print "VolRescale("+datnam+", \""+rng+"\",  \""+opt+"\" )"
//				cmd=VolRescale( $datnam, rng, opt  )   //identical to ImgRescale()
//				cmd="SetScale/P x "+num2str(vmin)+", "+num2str( vinc)+", "+datnam
				break
			case "y":
//				VolRescale( $datnam, "/Y=val", "/YZ")
//				cmd="SetScale/P y "+num2str(vmin)+", "+num2str( vinc)+", "+datnam
				break
			case "z":
//				VolRescale( $datnam, "/Z=val", "/ZZ")
//				cmd="SetScale/P z "+num2str(vmin)+", "+num2str( vinc)+", "+datnam
				break
		endswitch
		cmd="VolRescale("+datnam+", \"/"+svoldir+"="+num2str(voffset)+"\", \"/"+svoldir+"Z\")"
		print cmd
		execute cmd
		cmd="SetScale/P "+LowerStr(svoldir)+" "+num2str(vmin)+", "+num2str( vinc)+", "+datnam
		
		// reset scale of images and slices
		strswitch (popStr )
			case "Set X=0":

				SetScale/P x xmin, xinc, image, h_img		//profileH vs ProfileHx
				ModifyGraph offset(HairY0)={0, IMAG(coffset)}
				ModifyGraph offset(HairX1)={0, 0}
				SetProfiles()	
				break
			case "Set Y=0":

				SetScale/P y ymin, yinc, image, v_img		//profileV_y vs ProfileV
				ModifyGraph offset(HairY0)={REAL(coffset), 0}
				ModifyGraph offset(HairY1)={0, 0}
				SetProfiles()
				break
			case "Set Z=0":
	
				SetScale/P x zmin, zinc, profileZ
				ModifyGraph offset(HairZ0)={0, 0}
//				SetProfiles()
				break
		endswitch
		
//		SelectSliceDir(ctrlName,popNum,popStr)		// update slices, etc.
		NewImg( datnam )	
		break
		
	case "Transpose":
		newvoln=datnam+"t"
		variable reorder=NumVarOrDefault(df+"vol_reorder", 1)
		//string neworder=StrVarOrDefault(df+"vol_reorder", "XYZ" )
		//prompt neworder, "New dimension order", popup, "XY/Z;YX/Z;XZ/Y;YX/Z;ZX/Y;YZ/X;ZY/X"
		prompt reorder, "reorder (swap) axes", popup,"X<>Y;X<>Z;Y<>Z;X<>YZ;Z<>XY"
		prompt newvoln, "New volume name"
		DoPrompt "Volume Resize" newvoln, reorder		//neword
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
		//String/G $(df+"vol_reorder")=neworder
		Variable/G $(df+"vol_reorder")=reorder
		
		string ordr=SelectString(reorder==2, "YXZ", "ZYX")		// 1=X<>Y, 2=X<>Z
		ordr=SelectString(reorder==3, ordr, "XZY")
		opt="/"+ordr
		//opt="/"+neworder[0,1]+neworder[3]
		opt+="/D="+newvoln
		cmd="VolTranspose("+datnam+",  \""+opt+"\")"     // new faster function
		//cmd="VolReorder("+datnam+",  \""+opt+"\")"
		//print cmd
		execute cmd	
		
		SetDataFolder $curr
		NewImg( newvoln )		//new volume	
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
		//opt+="/D=root:"+newvoln
		//cmd="VolNorm( root:"+datnam+", \"" +opt+"\")"
		opt+="/D="+newvoln
		cmd="VolNorm("+datnam+", \"" +opt+"\")"
		print cmd
		execute cmd
		SetDataFolder $curr
		NewImg( newvoln )		//new volume	
		// AdjustCT()
		break
		
	case "Avg Z (to img)":					// F. Wang 3/3/06
		newvoln=datnam+"av"
		prompt newvoln, "New wave name"
		DoPrompt "Volume Avg" newvoln
		if (V_flag==1)
			SetDataFolder $curr
			abort
		endif
		NVAR islicedir=$(df+"islicedir")
		opt="/"+"ZYX"[islicedir-1]
		//opt+="/D=root:"+newvoln
		//cmd="VolNorm( root:"+datnam+", \"" +opt+"\")"
		opt+="/D="+newvoln
		cmd="VolAvg("+datnam+", \"" +opt+"\")"
		print cmd
		execute cmd
		SetDataFolder $curr
		NewImg( newvoln )		//new volume	
		// AdjustCT()
		break
		
	
	case "Shift":
		SetDataFolder $curr
		newvoln=datnam+"s"
		String shftwn=StrVarOrDefault(df+"shiftwn", "" )
		Variable shftdir=NumVarOrDefault(df+"shiftdir", 1 )
		Variable expand=NumVarOrDefault(df+"shift_expand", 1 )
		prompt shftwn, "Shift Wave Name", popup, WaveList("!*_x",";","DIMS:1")  // need to be in root: folder
		prompt shftdir, "Shift Direction & Dependence", popup, "X(y);X(z);Y(x);Y(z);Z(x);Z(y)"
		prompt expand, "Output Range", popup, "Shrink;Average;Expand"
		DoPrompt "Shift 3D volume array" shftwn, shftdir, expand
			String/G $(df+"shiftwn")=shftwn
			Variable/G $(df+"shiftdir")=shftdir, $(df+"shift_expand")=expand
			if (V_flag==1)
				abort
			endif

//		opt=SelectString(shftdir==2, "/X","/Y" ) 		// 1=X, 2=Y
		opt="/"+StringFromList( shftdir, "notused;XY;XZ;YX;YZ;ZX;ZY")
		opt+="/D="+newvoln	
		opt+="/E="+num2str(expand-2)				// -1, 0, 1
		cmd="VolShift("+datnam+", root:"+shftwn+",\"" +opt+"\")"
		print cmd
		execute cmd
		
		NewImg( newvoln )		//new volume
		break
	endswitch

	print cmd
	//execute cmd
	
	//ImgInfo( Image )
 	//SetProfiles()	
	//SetHairXY( "Check", 0, "", "" )
	//imgproc+="+ "+popStr			// update this after operation incase of intermediate macro Cancel
	//ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	
	SetDataFolder $curr
End

Function/T RescaleBox()
//===========
	string df=getdf1(), curr=GetDataFolder(1)
	SetDataFolder $df
	SVAR x12_rescale=$(df+"x12_rescale"),  y12_rescale=$(df+"y12_rescale")
	//variable opt=NumVarOrDefault(df+"XY_rescaleM",3)
	string Mrng_curr="/X="+x12_rescale+"/Y="+y12_rescale
	string xrang=StrVarOrdefault(df+"x12_rescaleM","0,1")		//num2str(x1_resize)+", "+num2str(x2_resize)
	string yrang=StrVarOrdefault(df+"y12_rescaleM","0,1")		//num2str(y1_resize)+", "+num2str(y2_resize)
	string Mrng_new="/X="+xrang+"/Y="+yrang
	//string Mrng_new=StrVarOrdefault(df+"xy12_rescaleM","/X=0,1/Y=0,1")
	prompt Mrng_curr, "Current Marquee range:"
	prompt Mrng_new, "New Marquee range: (blank=no change)"
	//prompt opt, "Marquee Box Axis Rescaling:", popup, "X only;Y only;X and Y"
	DoPrompt "Image Rescale of Marquee corners" Mrng_curr, Mrng_new		//, opt
	if (V_flag==1)
		SetDataFolder root:  //$curr
		abort
	endif
	//variable/G $(df+"XY_rescaleM")=opt
	string/G $(df+"x12_rescaleM")=KeyStr("X", Mrng_new)
	string/G $(df+"y12_rescaleM")=KeyStr("Y", Mrng_new)
	
	string arrn="image"		//ImageTool
	WAVE image=$arrn
	variable  v1cur, v2cur, p1, p2, vmincur, vinccur
	variable v1new, v2new, vminnew, vincnew
	
	string cmd, fullcmd="", idir, irngcur, irngnew
	variable i
	FOR (i=0;i<2;i+=1)
		cmd=""
		idir="xyzt"[i]
		irngcur=KeyStr(idir, Mrng_curr)
		irngnew=KeyStr(idir, Mrng_new)
		if (strlen(irngnew)>0)
			cmd="SetScale/P "+idir+" "
			v1new=NumFromList(0, irngnew, ",")
			v2new=NumFromList(1, irngnew, ",")
			v1cur=NumFromList(0, irngcur, ",")
			v2cur=NumFromList(1, irngcur, ",")
			vmincur=DimOffset(image,i)
			vinccur=DimDelta(image,i)
			p1=(v1cur - vmincur)/vinccur  
			p2=(v2cur -  vmincur)/vinccur
			vincnew = (v2new-v1new) / (p2-p1)	
			//print p1, p2, vincnew
			vminnew= v1new - vincnew*p1
			cmd+=num2str(vminnew)+", "+num2str(vincnew)+" , \"\" "+arrn+"; "
		endif
		if (strlen(cmd)>0)
			execute cmd
			fullcmd+=cmd
		endif
	ENDFOR
	// globals will get updated later by ImgInfo()
//	if ((opt==1)+(opt==3)) 
//		NVAR xmin=xmin, xinc=xinc
//		v1=str2num(StringFromList(0, xrang, ",")); v2=str2num(StringFromList(1, xrang, ","))
		//p1=(x1_resize - DimOffset(image, 0))/DimDelta(image,0)
		//p2=(x2_resize - DimOffset(image, 0))/DimDelta(image,0)
//		p1=(x1_resize - xmin)/xinc;   p2=(x2_resize -  xmin)/xinc
//		vinc = (v2-v1) / (p2-p1)			
		//vinc=DimDelta(image,0) * (v2-v1)/(x2_resize-x1_resize)
//		vmin = str2num(StringFromList(0, xrang, ",")) - vinc*p1
		//print "X:", vmin, vinc, p1, p2
//		SetScale/P x vmin, vinc , "" Image
//		cmd+="SetScale/P x "+num2str(vmin)+", "+num2str(vinc)+" , \"\" Image; "
		//Set cursors on X profile to range selected
//		Cursor/P A, profileH, p1
//		Cursor/P B, profileH, p2
//	endif
//	if (opt>1) 
//		NVAR ymin=ymin, yinc=yinc
//		v1=str2num(StringFromList(0, yrang, ",")); v2=str2num(StringFromList(1, yrang, ","))
//		p1=(y1_resize - ymin)/yinc;   p2=(y2_resize -  ymin)/yinc
//		vinc = (v2-v1) / (p2-p1)	
//		vmin = str2num(StringFromList(0, yrang, ",")) - vinc*p1
//		SetScale/P y vmin, vinc , "" Image
//		cmd+="SetScale/P y "+num2str(vmin)+", "+num2str(vinc)+" , \"\" Image"
		//print "Y:", vmin, vinc, p1,p2
		//Set cursors on X profile to range selected
//		Cursor/P A, profileV_y, p1
//		Cursor/P B, profileV_y, p2
//	endif
	SetDataFolder curr
	return fullcmd
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
	//dx=(rotx[1]-rotx[0])
	//dy=(roty[1]-roty[0])
	//slope=dy/dx
	slope=dx/dy				// vertical line is zero degree rotation
	//ang_rot=(180/pi)*atan2( dy/yinc, dx/xinc)
	//ang_rot=(180/pi)*atan2( dx/xinc, dy/yinc)
	ang_rot=-(180/pi)*atan(slope)
	//ang_rot=min(ang_rot, 90-ang_rot)
	//print ang_rot, "deg (Pixel);", slope, WaveUnits($(df+"Image"), 1)+"/"+WaveUnits($(df+"Image"), 0)
	print ang_rot, "deg (Pixel); slope=", slope  //, WaveUnits(Image, 1)+"/"+WaveUnits(Image, 0)
	
	string opt
	opt="/D=Image"
	cmd="ImgRotate( Image_Undo, "+num2str(ang_rot)+ ",\"" +opt+"\")"
	print cmd
	execute cmd
	SetDataFolder root:
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
	ImgShift( Imag_Undo, Shiftx, "/D=Image")
End

Function ImgAnalyze(ctrlName, popNum,popStr) : PopupMenuControl
//------------------------
	String ctrlName
	Variable popNum
	String popStr
	
	PauseUpdate; Silent 1
	string df=getdf(), curr=GetDataFolder(1)
	string opt, cmd, xrng
	SetDataFolder $df
//	SVAR imgnam=imgnam, imgproc=imgproc, imgproc_undo=imgproc_undo
	NVAR nx=nx, xmin=xmin, xinc=xinc
	NVAR ny=ny, ymin=ymin, yinc=yinc
	
//	Duplicate/o Image Image_Undo
//	imgproc_undo=imgproc
//	imgproc+="+ "+popStr
	
//	variable/C coffset=GetWaveOffset(root:IMG:HairY0)
	//print df, curr
	if (popNum<=5)				// get & confirm analysis X-range
		xrng=ImgRange( 0, df+"x12_analyze")
		prompt xrng, "x1, x2"
		DoPrompt "X Analysis Range" xrng
		string/G $(df+"x12_analyze")=xrng
			if (V_flag==1)
				SetDataFolder $curr
				abort
			endif

		variable x1, x2
		x1=NumFromList(0, xrng, ",")
		x2=NumFromList(1, xrng, ",")

		//Reposition AB cursors on X-profile to indicate range selected
		Cursor/P A, profileH, x2pnt( Image, x1) 
		Cursor/P B, profileH, x2pnt( Image, x2)	
	endif


	if (cmpstr(popStr,"Area X")==0)
		//include marquee/range prompt?
		string areaXn=StrVarOrDefault(df+"areaXwn","xarea")
		prompt areaXn, "Avg Wave name"
		DoPrompt "Area X", areaXn
			if (V_flag==1)
				abort
			endif
		string/G $(df+"areaXwn")=areaXn
		
		SetDataFolder $curr
		//areaXn="root:"+areaXn
		make/o/n=(ny) $areaXn
		SetScale/P x ymin, yinc,  $areaXn
		WAVE areaXw=$areaXn
		areaXw = AREA2D( $(df+"Image"),  0, x1,  x2, x )
		
		DoWindow/F Area_
		if (V_Flag==0)
			Display areaXw
			DoWindow/C Area_
			execute "Area_Style(\"Area\")"
		else
			CheckDisplayed/W=Area_  areaXw
			if (V_Flag==0)
				AppendToGraph areaXw
			endif
		endif
	endif
	
	if ((cmpstr(popStr,"Find Edge")==0) + (cmpstr(popStr,"Fit Edge")==0))
		String edgewn=StrVarOrDefault(df+"edgen", "fe" )
		Variable fitedge=NumVarOrDefault(df+"edgefit", 1 )
		Variable fitpos=NumVarOrDefault(df+"positionfit", 1 )
		prompt edgewn, "Output basename (_e, _w)"
		prompt fitedge, "Edge Detection", popup, "Find;Fit"
		prompt fitpos, "Post-fit Edge Postions with polynomial (0=None, 1=linear, ...)"
		DoPrompt "Edge Position options" edgewn, fitedge, fitpos
		String/G $(df+"edgen")=edgewn
		Variable/G $(df+"edgefit")=fitedge, $(df+"positionfit")=fitpos
			if (V_flag==1)
				abort
			endif
		
		
		//string wn=$(df+"edgen")
		
		SetDataFolder $curr
		string ctrn=edgewn+"_e", wdthn=edgewn+"_w"
		make/C/o/n=(ny) $edgewn
		make/o/n=(ny) $ctrn, $wdthn
		WAVE/C edgew=$edgewn
		WAVE ctr=$ctrn, wdth=$wdthn
		SetScale/P x ymin, yinc, edgew,  ctr, wdth
		
		variable wfrac=0.15*SelectNumber(fitedge==2, 1, -1)	// negative turns on fitting
		variable debug=0
		if (debug)
			variable i
			FOR( i=0; i<ny; i+=1)
				edgew = EDGE2D( $(df+"Image"),  x1,  x2, pnt2x(edgew, i), wfrac )
				PauseUpdate
				ResumeUpdate
				print i
			ENDFOR
		else
			edgew = EDGE2D( $(df+"Image"),  x1,  x2, x, wfrac )
		endif
		ctr=REAL( edgew )
		wdth=IMAG( edgew )
		
		DoWindow/F Edge_
		if (V_Flag==0)
			Display ctr
			AppendToGraph/L=wid wdth
			DoWindow/C Edge_
			execute "Peak_Style(\"Edge\")"
		else
			CheckDisplayed/W=Edge_  ctr, wdth
			if (V_Flag==0)
				AppendToGraph ctr
				AppendToGraph/L=wid wdth
				//print ctr, wdth
				//ModifyGraph lstyle($wdth)=2, rgb($wdth)=(0,0,65535)
			endif
		endif
		ModifyGraph lstyle($wdthn)=2, rgb($wdthn)=(0,0,65535), mode($wdthn)=4 //, marker($wdthn)=19
		
		if (fitpos>0)
			if (fitpos==1)		//linear
				CurveFit line ctr /D
			else					// quadratic or allow higher?
				string fitcmd="CurveFit poly "+num2str(fitpos)+", "+NameOfWave(ctr)+" /D"
				print fitcmd
				execute fitcmd
			endif 
			//WAVE fit_ctr=$("fit_"+ctrn)
			ModifyGraph rgb($("fit_"+ctrn))=(0,65535,0)
		endif
	endif
	
	variable pkmode=0
	if (cmpstr(popStr,"Find Peak Max")==0)
		pkmode=1
		popStr="Find Peak"
	endif

	if (cmpstr(popStr,"Find Peak")==0)
		string peakn=StrVarOrDefault(df+"peakn","pk")
		prompt peakn, "Peak Base Name"
		DoPrompt "Find Peak", peakn
			if (V_flag==1)
				abort
			endif
		String/G $(df+"peakn")=peakn
		
		ctrn=peakn+"_e", wdthn=peakn+"_w"
		SetDataFolder $curr
		make/C/o/n=(ny) $peakn
		make/o/n=(ny) $ctrn, $wdthn
		WAVE/C pkw=$peakn
		WAVE ctr=$ctrn, wdth=$wdthn
		SetScale/P x ymin, yinc, pkw,  ctr, wdth
		pkw = PEAK2D( $(df+"Image"),  x1,  x2,  x, pkmode )
		ctr=REAL( pkw )
		wdth=IMAG( pkw )
		
		DoWindow/F Peak_
		if (V_Flag==0)
			Display ctr
			AppendToGraph/L=wid wdth
			DoWindow/C Peak_
			execute "Peak_Style(\"Peak\")"
		else
			CheckDisplayed/W=Peak_  ctr, wdth
			if (V_Flag==0)
				AppendToGraph ctr
				AppendToGraph/L=wid wdth
				//print ctr, wdth
				//ModifyGraph lstyle(wdth)=2, rgb(wdth)=(0,0,65535)
			endif
		endif
		ModifyGraph lstyle($wdthn)=2, rgb($wdthn)=(0,0,65535), mode($wdthn)=4
	endif
	
	if (cmpstr(popStr,"Fit Peak")==0)
		SetDataFolder $curr
		DoAlert 0, "Fit peak not implemented yet"
	endif
	
	if (cmpstr(popStr,"Average Y")==0)
		string avgYn=StrVarOrDefault(df+"avgYwn","avgy")
		prompt avgYn, "Avg Wave Name"
		DoPrompt "Average Y", avgYn
			if (V_flag==1)
				abort
			endif
		string/G $(df+"avgYwn")=avgYn

		avgYn="root:"+avgYn
		opt="/X/D="+avgYn		//+avgrng
		cmd="ImgAvg("+df+"Image, \""+opt+"\")"
		print cmd
		//ImgAvg(Image,  opt)
		//SetDataFolder $curr
		execute cmd
		
		DoWindow/F Sum_
		if (V_Flag==0)
			Display $avgYn
			DoWindow/C Sum_
			execute "Area_Style(\"Average\")"
		else
			CheckDisplayed/W=Sum_  $avgYn
			if (V_Flag==0)
				AppendToGraph $avgYn
			endif
		endif
	endif

	SetDataFolder $curr
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

Function ImgTabProc(name,tab)
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

	if (exists("AddEDCpathTab2ITpanel"))
		button addpoint, disable=(tab!=5) 		//EDCs over path (Add from David Fournier)
		button rempoint, disable=(tab!=5)
		button resetkpath, disable=(tab!=5)
		popupmenu path, disable=(tab!=5)
		button edcspath, disable=(tab!=5)
		button edcspoints, disable=(tab!=5)
	endif	
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
	string dfn=StringFromList(1,df,":")
	NVAR ndim=$(df+"ndim"), showImgSlices=$(df+"showImgSlices")

	modif=NumberByKey("modifiers", s) & 15			//mask out 5th bit (v6.023)
	//print modif, "ndim=", ndim
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
					ModifyGraph offset(HairY0)={ax,ay}		// must be last updated for hairtrigger
					if ((ndim==3)*showImgSlices)
						//setdatafolder img	//**ER
						UpdateImgSlices(0)	//**ER
						//setdatafolder ::		//**ER
					endif
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
					NVAR x0=root:imageTool:x0, y0=root:imageTool:y0
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
			DoWindow/f $dfn
			removeallfromgraph(dfn)
			string swn=getswn(df)
			
			
			DoWindow/f $swn
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
	If (V_Flag==1)			//get stats on subrange of image
		variable method=1
		if (method==0)		// imgtmp creation method
			Duplicate/O/R=(V_left,V_right)(V_bottom,V_top) Image, $(df+"imgtmp")
			ml=v_left; mr=v_right; mb=v_bottom; mt=v_top	//!!ER  store marquee values for next adjustct	
			WAVE imgtmp=$(df+"imgtmp")
			WaveStats/Q imgtmp
			killwaves/Z imgtmp
		else			//ImageStats method
			//  pixel ordering of p(V_left)<p(V_right) required  so must convert to pixels
			//   since marquee left/right dependent on sign of axis delta AND axis reverse checkbox
			variable p1, p2, q1, q2
			p1=(V_left-DimOffset( image,0))/ DimDelta(image,0)
			p2=(V_right-DimOffset(image,0))/ DimDelta(image,0)
			q1=(V_bottom-DimOffset(image,1))/ DimDelta(image,1)
			q2=(V_top-DimOffset(image,1))/ DimDelta(image,1)
			ImageStats/M=1/G={min(p1,p2),max(p1,p2),min(q1,q2),max(q1,q2)} image
			//print p1,p2,q1,q2, V_min, V_max
		endif
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
// changed invert option to be 0=no, 1=yes
	WAVE wv
	variable inv,mn,mx
	if(inv>0)
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
	print df, curr
	string CTstr
	PauseUpdate
	switch( popNum )
//	case 1:
//		CTstr="Gray_CT[pmap[p]][q]"
//		execute df+"Image_CT:="+df+CTstr
//		execute df+"Himg_CT:="+df+CTstr
//		execute df+"Vimg_CT:="+df+CTstr
//		break

//	case 2:
//		CTstr="RedTemp_CT[pmap[p]][q]"
//		execute df+"Image_CT:="+df+CTstr
//		execute df+"Himg_CT:="+df+CTstr
//		execute df+"Vimg_CT:="+df+CTstr
//		break

	case 1: 		//Invert
		setdataFolder $df
			//SVAR CTnam=CTnam
			NVAR CTinvert=CTinvert, gamma=gamma
			NVAR ndim=ndim, showImgSlices=showImgSlices
			NVAR dmin=dmin, dmax=dmax
			WAVE Image_CT=Image_CT, himg_CT=himg_CT, vimg_CT=vimg_CT
			WAVE h_img = h_img, v_img=v_img
		setdatafolder $curr
//		CTinvert*=-1
		CTinvert=1-CTinvert		// 0=no, 1=invert  (12/1/08)
//		gamma=1/gamma
		if (CTinvert==1)
			PopupMenu SelectCT value="� Invert;Rescale;"+CTnameList(2) //colornameslist()
//			SetVariable setgamma limits={0.1,Inf,0.1}
			SetScale/I x dmax, dmin,"" Image_CT
		else
			PopupMenu SelectCT value="Invert;Rescale;"+CTnameList(2) //colornameslist()
			SetVariable setgamma limits={0.1,Inf,0.1}
			SetScale/I x dmin, dmax,"" Image_CT
		endif
		if (showImgSlices*(ndim==3))
			Wavestats/Q h_img;    dosetscale( himg_ct, V_min, V_max, CTinvert)
			Wavestats/Q v_img;    dosetscale( vimg_ct, V_min, V_max, CTinvert)
		endif
		//CTwriteNote( Image_CT, CTnam, gamma, CTinvert)  //or do at export only
		break
	case 2:		// Rescale
		AdjustCT()
		break
	default:
		SVAR CTnam=$(df+"CTnam")
		WAVE pmap=$(df+"pmap")
		NVAR CTinvert=$(df+"CTinvert")
		NVAR gamma=$(df+"gamma")
//		CTstr="ALL_CT[pmap[p][q]["+num2str(popnum-3) + "]"
		CTstr="root:colors:all_ct[pmap[p]][q]["+num2str(popnum-3) + "]"
//		CTstr="root:colors:all_ct[pmap[CTinvert*(255-p)+CTinvert==0)*p]][q]["+num2str(popnum-3) + "]"
		
		// new location for ALL_CT:  in root:color:all_ct instead of in each ImageTool folder
//		CTstr="root:colors:all_ct[pmap[invertct*(255-p)+invertct==0)*p]][q][whichCT]"
		setformula $(df+"pmap") , "255*(p/255)^"+df+"gamma)"		// should be already done elsewhere
		setformula $(df+"Image_CT"), CTstr
		setformula $(df+"Himg_CT"), CTstr
		setformula $(df+"Vimg_CT"), CTstr
		
//		execute df+"Image_CT:="+df+CTstr
//		execute df+"Himg_CT:="+df+CTstr
//		execute df+"Vimg_CT:="+df+CTstr
		CTnam=SelectString(strlen(popStr)==0, popStr, StringFromList(popnum-3, CTnameList(2)) )
		//CTwriteNote( Image_CT, CTnam, gamma, CTinvert)  //also Himg_CT, Vimg_CT?
		break

	endswitch
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
	Variable plotopt=NumVarOrDefault( df+"STACK:plotopt", 1)
	Prompt basen, "Stack base name"
	Prompt plotopt, "Plot option", popup, "New Graph;Append to Top Graph"
	DoPrompt "Export Stack", basen, plotopt
	if (V_flag==1)
		abort		// Cancel selected
	endif
	string/G $(df+"STACK:basen")=basen
	variable/G $(df+"STACK:plotopt")=plotopt
	
	print plotopt
	
	SetDataFolder root:

	SVAR imgn=$(df+"imgnam")
	NVAR shift=$(df+"STACK:shift"), offset=$(df+"STACK:offset")
	NVAR xmin=$(df+"STACK:xmin"), xinc=$(df+"STACK:xinc")
	string shortimgn=imgn[strsearch(imgn, ":",50,3)+1,50]  //strip of (sub)folder(s)
	
	string trace_lst=TraceNameList(getswn(df),";",1 )
	variable nt=ItemsInList(trace_lst,";")

	If (plotopt==1)
		Display			// open empty plot
	else	
		// Select top graph: after Stack_ & avoid ImageTool window	
		string topgraph=StringFromList(1, WinList("!ImageTool*", ";","WIN:1"))
		DoWindow/F $topgraph		// Top graph for appending
	endif
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
		Write_Mod(wv, shift*ii, offset*ii, 1, 0, 0.5, 0, yval, shortimgn)
		AppendToGraph wv
		ii+=1
	WHILE( ii<nt )
	
	If (plotopt==1)		// give window a name if new
		string winnam=(basen+"_Stack")
		DoWindow/F $winnam
		if (V_Flag==1)
			DoWindow/K $winnam
		endif
		DoWindow/C $winnam
	endif
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
			CopyScales/P profileZ, profil
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
	NVAR ndim=$(df+"ndim")
	String nam=StrVarOrDefault( df+"exporti_nam", "im")
	variable opt=NumVarOrDefault( df+"exporti_opt", 1)
	variable plotopt=NumVarOrDefault( df+"exporti_plot", 2)
	prompt nam, "Export image name"
	//if (ndim==3)
		prompt opt, "Image & Color Table options", popup, "Main Image;Horiz Slice;Vert Slice;Vert Slice Transpose;Main CT only;"
	//else
	//	prompt opt, "Image & Color Table options", popup, "Image & CT;CT only;"
	//endif
	prompt plotopt, "Plot option", popup, "None;Display;Append to Plot;Append to Img/Vol;Concatenate"
	DoPrompt "ExportImage" nam, opt, plotopt
	if (V_flag==1)
		abort		// Cancel selected
	endif
	string/G $(df+"exporti_nam")=nam
	variable/G  $(df+"exporti_opt")=opt,  $(df+"exporti_plot")=plotopt
	
	//add wave note to CT wave for export (or do at each modification)
	setdataFolder $df
		SVAR CTnam=CTnam
		NVAR CTinvert=CTinvert, gamma=gamma
		CTwriteNote( image_CT, CTnam, gamma, CTinvert) // should be done at init & CT changes	
		CTwriteNote( himg_CT, CTnam, gamma, CTinvert) // should be done at init & CT changes	
		CTwriteNote( vimg_CT, CTnam, gamma, CTinvert)	// should be done at init & CT changes
	//setdatafolder $curr
	
	SetDataFolder root:
	string cmd=""
	if (plotopt>=4)			// append to img/vol or image concatenate
//		string outn=nam
		nam="tmp"
	endif
	
	string CTwnam
	variable left, right, bottom, top
	opt=SelectNumber(ndim==2, opt, 1)		// no slice images for 2D
	switch( opt )
		case 1:		// Main Image  (use graph axes subset)	
			GetAxis/Q bottom 
			left=V_min; right=V_max
			GetAxis/Q left
			bottom=V_min; top=V_max
			Duplicate/O/R=(left,right)(bottom,top) $(df+"Image"), $nam
			cmd="Duplicate/O "+df+"Image "+nam+"; "			//add subset later
				CTwnam="Image_CT"
				
			break
		case 2:		// Horiz. Profile Slice & CT
			GetAxis/Q bottom
			left=v_min; right=v_max
			GetAxis/Q imgh
			bottom=v_min; top=v_max
			duplicate/O/R=(left,right)(bottom,top) $(df+"h_img") $nam
			cmd="Duplicate/O "+df+"h_img "+nam+"; "
				CTwnam="himg_CT"
				
			break
		case 3:		// Vertical Profile Slice & CT
		case 4:		// Vertical Profile Slice & CT + transpose
			GetAxis/Q imgv
			left=v_min; right=v_max
			GetAxis/Q left
			bottom=v_min; top=v_max
			duplicate/O/R=(left,right)(bottom,top) $(df+"v_img") $nam
			cmd="Duplicate/O "+df+"v_img "+nam+"; "	
				CTwnam="vimg_CT"
				
			if (opt==4)
				MatrixTranspose $nam
			endif
				
			break
		case 5:		// Color Table  Only
			NVAR exporti_opt=$(df+"exporti_opt")
			exporti_opt=1		//reset back to main image
			plotopt=5			//no new plot
			break
	endswitch
	// Color Table
	if (plotopt<=3)
		Duplicate/O $(df+CTwnam) $(nam+"_CT")	
		cmd+="Duplicate/O "+df+CTwnam+" "+nam+"_CT"
//		CTwriteNote( $(nam+"_CT"), CTnam, gamma, CTinvert)		//not necessary if not is in original IT CTs
	endif
	print cmd
	
	// Copy wavenote from original 3D array to exported 2D image, e.g. file header info
//	if (ndim==3)
//		SVAR origvol = $(df+"imgnam")
//		print origvol, note($origvol )
//		Note/K $nam;  Note $nam, note(vol )
//	else
		// 2D images get duplicated therby passing along original wavenote info
//	endif
	
	string outn=StrVarOrDefault( df+"exporti_nam2", "")
	switch( plotopt )
		//case 1:  //no action
		case 2:		//new plot
			display; appendimage $nam
			modifyimage $nam, cindex=$(nam+"_CT")
			break
		case 3:  		// append to top plot
			DoWindow/F $WinName(1,1)		// next window behind ImageTool
			appendimage $nam
			modifyimage $nam, cindex=$(nam+"_CT")
			break
		case 4:		//append slice to existing array
			//Prompt for 2D or 3D array to append to (See SES loader)
			//string voln=StringFromList(0, ImageNameList("",";"))
			prompt outn, "base 3D or 2D array", popup, " --3D --;"+WaveList("!*_CT",";","DIMS:3")+"-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
			DoPrompt "Volume append (to Z dir)", outn
			string/G $(df+"exporti_nam2")=outn
			WAVE vol=$outn, tmp=$nam
			VolAppend( vol, tmp, "/Z")
			cmd="VolAppend("+outn+", "+nam+", /Z)"	
			print cmd
			KillWaves/Z tmp
			break
		case 5:			//concatenate
			string concat_dir=StrVarOrDefault( df+"exporti_concat", "X")
			prompt concat_dir, "Direction", popup, "X (right);Y (top)"
			prompt outn, "base 2D array", popup, WaveList("!*_CT",";","DIMS:2")
			DoPrompt "Image Concatenate", outn, concat_dir
			string/G $(df+"exporti_nam2")=outn
			WAVE imA=$outn, tmp=$nam
			ImgConcat( imA, tmp, "/O/"+concat_dir[0])
			cmd="ImgConcat("+outn+", "+nam+", /O/"+concat_dir[0]+")"	
			print cmd
			KillWaves/Z tmp
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
			SVAR voln=$(df+"imgnam")
			Duplicate/o $voln $nam
			Duplicate/o $(df+"Image_CT") $(nam+"_CT")		// use current image CT
			break
		case 2:		// Color Table  Only
			Duplicate/o $(df+"Image_CT") $(nam+"_CT")
			break
	endswitch
		// Color Table
	//if (plotopt<=2)
	//	Duplicate/O $(df+CTwnam) $(nam+"_CT")	
	//	cmd+="Duplicate/O "+df+CTwnam+" "+nam+"_CT"
	//endif
	//print cmd
		
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
				// Windows: scale window width smaller by 72/96�0.75
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

Function StackUpdate(ctrlName) : ButtonControl
//================
	String ctrlName
	
	string df=getdf(), curr=GetDataFolder(1)
	string dfn=StringFromList(1,df,":")			//not used
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
	variable/G $(df+"STACK:fixoffset")
	//variables {shift, offset, pinc, fixoffset} predefined in InitImageTool

	string trace_lst=""
	variable nt=0
	DoWindow/F  $swn
	if (V_flag==0)
		execute "Stack_()"
		DoWindow /C $swn		//change name
		If (!stringmatch( IgorInfo(2), "Macintosh") )
			//Display /W=(219,250,540,600)
			// Windows: scale window width smaller by 72/96�0.75
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
	NVAR shift=$(df+"STACK:shift"),  offset=$(df+"STACK:offset")
	NVAR fixoffset=$(df+"STACK:fixoffset")

	if (fixoffset==0)	
		variable shiftinc=DimDelta(imgstack,0), offsetinc, exp
		offsetinc=0.1*(dmax-dmin)
		exp=10^floor( log(offsetinc) )
		offsetinc=round( offsetinc / exp) * exp
	//	print offsetinc, exp
		SetVariable setshift limits={-Inf,Inf, shiftinc}
		SetVariable setoffset limits={-Inf,Inf, offsetinc}
		shift=0
		offset=offsetinc*(1-2*(offset<0))		//preserve previous sign of offset
	else
		//do not recalculate new shift and offset values 
	endif
	StackOffset( shift, offset)
	
	SetDataFolder curr
End


Function SetOffset(ctrlName,varNum,varStr,varName) : SetVariableControl
//==============
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	string df=stack_getdf()
	NVAR shift =$(df+"STACK:shift")
	NVAR offset =$(df+"STACK:offset")
	if (cmpstr(ctrlName,"setShift")==0)
		shift=varNum
	else
		offset=varNum
	endif
	StackOffset( shift, offset)
End

Function StackSetHairXY(ctrlName) : ButtonControl
//===============
	String ctrlName
	//root:IMG:STACK:offset=0.5*(root:IMG:STACK:dmax-root:IMG:STACK:dmin)
	//StackOffset( root:IMG:STACK:shift, root:IMG:STACK:offset)
	string df=stack_getdf()
	string dfn=StringFromList(1,df,":")
	variable xcur=xcsr(A), ycur
	if ( numtype(xcur)==0 ) 
		NVAR ymin=$(df+"STACK:ymin") 
		NVAR yinc= $(df+"STACK:yinc") 
		string wvn=CsrWave(A)
		ycur = ymin+yinc * str2num( wvn[4,strlen(wvn)-1] )
		DoWindow/F $dfn
		ModifyGraph offset(HairY0)={xcur, ycur}
		ModifyGraph offset(HairX1)={xcur, 0 }
		ModifyGraph offset(HairY1)={0, ycur }
		//WAVE image = $(df+"Image")
		//Cursor/P A, profileH, round((xcur - DimOffset(Image, 0))/DimDelta(Image,0))
		//Cursor/P B, profileV_y, round((ycur - DimOffset(Image, 1))/DimDelta(Image,1))
	endif
End

Function StackOffset( shift, offset )
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


Window Stack_() : Graph
	PauseUpdate; Silent 1		// building window...
	String df=getdf1(), fldrSav= GetDataFolder(1)
	SetDataFolder $(df+"STACK:")
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
	SetVariable setshift,limits={-Inf,Inf,0.002},value= $(df+"STACK:shift")
	SetVariable setoffset,pos={90,2},size={90,14},proc=SetOffset,title="offset"
	SetVariable setoffset,help={"Incremental Y offset of spectra."},fSize=10
	SetVariable setoffset,limits={-Inf,Inf,0.2},value= $(df+"STACK:offset")
	CheckBox checkFixOffset,pos={184,3},size={16,14},title=""
	CheckBox checkFixOffset,variable= $(df+"STACK:fixoffset")
	CheckBox checkFixOffset help={"fix shift & offset value for subsequent IT stack updates"}
	Button MoveImgCsr,pos={211,1},size={35,16},proc=StackSetHairXY,title="Csr"
	Button MoveImgCsr,help={"Reposition cross-hair in Image_Tool panel to the location of the A cursor placed in the Stack_ window."}
	Button ExportStack,pos={252,1},size={50,16},proc=ExportStackFct,title="Export"
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


Proc Peak_Style(ylbl) : GraphStyle
	string ylbl
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
	ModifyGraph/Z lblPos(left)=40,lblPos(wid)=40
	ModifyGraph/Z lblLatPos(wid)=2
	ModifyGraph/Z freePos(wid)=0
	ModifyGraph/Z axisEnab(left)={0,0.58}
	ModifyGraph/Z axisEnab(wid)={0.62,1}
	Label/Z left ylbl+" Posn"
	Label/Z wid ylbl+" Width"
EndMacro

function/s getdf1()		//use non-static call from macros
	return getdf()
end

static function/s getdf()				//static  can only be called by FUNCTONS (not macros) in this procedure
//override function/s getdf()
//==========
//get data folder from topmost window name
	//return ":"+winlist("*","","win:")+":"
	return "root:"+WinName(0,1)+":"
	//return "root:ImageTool:"
	//return "root:img:"
end

static function /S stack_getdf()
//==========
//get image tool data folder from topmost window name of a stack window, 
// supports the legacy STACK_->ImageTool
	string df = getdf()
	string dfn=StringFromList(1,df,":")
	if(cmpstr(dfn,"STACK_")==0)
		return "root:ImageTool:"
	else
		variable snum
		sscanf dfn ,"STACK %i", snum
		return  "root:ImageTool"+num2istr(snum)+":"
	endif
end

static function /S getswn(df)
///==========
//get the stack window name for a given imagetool df folder, 
//  supports the legacy imagetool->STACK_.
	string df
	string dfn=StringFromList(1,df,":")
	if(cmpstr(dfn,"ImageTool")==0)
		return "STACK_"
	else
		variable snum
		sscanf dfn ,"ImageTool %i", snum
		return  "STACK"+num2istr(snum)
	endif
end


Function RemoveAllFromGraph(graphName)
// =====================
// remove all of the images and waves from a graph
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


 function KillAllinFolder(df)
 //===============
 //kill all the variable, strings and waves in a data folder
// will kill dependencies up to ten deep
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



