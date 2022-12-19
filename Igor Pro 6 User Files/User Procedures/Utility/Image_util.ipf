//File: image_util   
// Jonathan Denlinger, JDDenlinger@lbl.gov

#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.27

//1/28/10 jdd  -- move CT control bar stuff to separate procedure CT_Control.ipf
// 1/24/10 jdd -- make use of Eli's newer('08) ColorNameL() loading of all_ct array into ColorTables folder
//1/16/10 jdd -- Add "Rainbow light;Purple-Yellow" to CTnameList()
// 8/6/09 jdd -- XYarr2img - precalculate Gaussian img to interpolate for 6X faster calc
// 6/9/08 jdd -- add skip NaN gaps to XYarr2img function
// 4/24/09 jdd -- add two more colors to CTnamelist()
// 11/23/08  jdd  -- redefine CTinvert: -1=auto, 0=normal, 1=invert
// 8/30/08 jdd -- (v5.2) add fct OutputName() for interpreting suffixes in "/D=" option string
//  2/19/08  jdd -- add /XZ  "zero" option to ImgRescale()
// 11/18/07 -- add XYarr2img function
// 11/16/07 jdd add auto-detect CT inversion to CTsetScale()
// 4/16/07 jdd Add img axis plotting options to dispi(); cut link to old procedures TV.ipf
// 2/18/07 jdd Add ImgClr2bw() - sum 3 layers of 8-bit color image to single-precision BW image
// 12/11/05  --take care of GraphMarquee menu items: Crop, ReGridXY
// 10/17/05 jdd  add /C rotation center option to ImgRotate() input
//10/14/05 jdd improve DeGlitch find algorithm and add marquee region selection
// 8/2/05  jdd create ImgDeglitch() and Menu proc DeGlitchImg()
// 7/30/05 jdd allow CT_make option to CT_controls (if no CT is used); Fix up inverting CT
// 6/20/04 jdd moved dispi() & appi() from Shortcuts.ipf
// 6/19/04 jdd add CTmake for one-line creation of fully-specified color table
// 5/30/04 jdd rewrite RescaleImg to RescaleArr() & ImgRescale()
// 5/29/04 jdd move Crop marquee from ImageTool & make work for 2 & 3 dim indep. of ImageTool
// 5/18/04 jdd copy & tweak ImgConcat() from Image_Splice
// 5/17/04 jdd change /O dual purpose option into /O (overwrite) or /D=destw (consistent with Igor routines)
// 5/09/04 jdd added CT_Controls stuff (move to separate ipf?; combine with ImageTool AdjustCT)
// 11/23/03 jdd added ImgRotate(); streamline ImgShift code
// 9/28/03  jdd modified ImgResize(); returns "outnam: nx x ny" string
// 3/1/03  jdd added ImgResize()
// 11/10/02 jdd revised ImgCrop, ImgNorm
// 7/8/02  jdd added ImgCrop
// 5/25/01 jdd added ShiftImg --> ImgShift
// 6/7/00 jdd added balloon help
// 2/20/00 jdd  Image2Waves export Keyword MOD list

#include <Keyword-Value>		// for gridding to contour
//#include "TV"  //for Waves2Img (AXISW) --> now IMG_AXIS()
#include "list_util"   // for KeyStr()
#include  <Cross Hair Cursors>
#include "colortables"  
#include "CT_Control"

//Fct/T 	ImgRange( dir )
//Fct/T 	ColorTableStr(win, imgn)
//Macro ReplotAsPICT(img, xscal, yscal)
//Proc 	Waves2Img( wvlst, refwv, yrng, imgn, dopt, trans, offset)
//Fct 	Img2Waves( img, basen, dir )
//Fct/T	ScaleImg( img, xwn, ywn)	--// scaled 2D image wave based on x & y reference waves
//Proc 	ReGridToContour(plot,nx, ny, dopt)
//Proc 	NormImg(img, indx, nrmimg, dopt)
//Fct 	AvgImg( img, indx, outw)
//Fct 	MaxImg( img, indx, outw)
//Fct/C 	ReinterpImg (img, xscal, yscal, outimgn)
//Proc 	FilterImg(img,  typ, nrm,npt, npass, dopt)
//fct 	CUTMX( m, indx, xy )
//fct 	EXTRACTMX( m, indx, xy, ow )
//fct 	CHECKDIM( w, dim )
//fct/C 	ExtractImg( newimg )
//Proc 	ReGridXY( img, outn, xwn, ywn, xrng, yrng, xinc, yinc,  dopt ) : GraphMarquee
//Fct/T 	ShiftImg( img, shiftw, opt)

Menu "2D"
	"-"
	"CT Control Bar", CT_ControlBar()
		help={"Add temporary Color Table controls  to image graph"}
	"Add CrossHair"
		help={"Append Cross Hair to top graph; click & drag dynamically displays X, Y values"}
	"Remove CrossHair"
	"Deglitch Img"
		help={"Remove pixel or line defect from image using WaveStats V_max"}
	"-"
	Submenu "Advanced Image"
		"Waves2Img"
			help={"Merge list of waves to a 2D array; use specified y-axis scaling parameters OR create _x, _y n+1 axis using wave note values for y-axis"}
		"ReGridToContour"
			help={"modified from WaveMetric's AppendImageToContour"}
		"NormImg"
			help={"Normalize 2D image array by Avg (or Max) X (or Y) line in image"}
		"FilterImg"
			help={"Divide or subtract image by smoothed version of image"}
		"ReGridXY"
			help={"Reinterpolate image to to specifed uniform grid X, Y ranges (marquee box option)"}
		"ReplotAsPICT"
			help={"Reinterpolate image in top window to finer density PICT image & display with top window graph style"}
		"Remove Legend Ctrls", JEG_ZapColorLegendControls()
			help={"Remove JEG Legend Ctrls"}
		"XYarr 2 img", XYarr2img()
			help={"Remove JEG Legend Ctrls"}
	End
	Submenu "Image Functions"
		"fct\S Img2Waves Img, basen, dir"
			help={"Extract wave set from 2D array; use image scaling for x-axis and y-value in wave note"}
		"fct Image2Waves Img, basen, dir, inc"
			help={"Extract wave set from 2D array; use image scaling for x-axis and y-value in wave note; specify x-axis increment"}
		"fct\S ColorTableStr win, imgn"
			help={"return ColorTable info string"}
		"fct ImgCrop  img, opt"
			help={"Crop 2D image wave using specified x & y ranges; opt= /D=newimg/O /X=x1,x2 /Y=y1,y2"}
		"fct ImgResize img, xyval, opt "
			help={"Resize 2D image using nx,ny scale factors; opt= /D=newimg/O /Interp/Rebin/Thin/NP"}
		"fct ImgNorm img, opt"
			help={"divide by average lineprofile along specified direction"}
		"fct ImgAvg img, opt"
			help={"1D average  lineprofile along specified direction"}
		"fct\S ImgDeglitch img, opt"
			help={"remove point or line glitches in image"}
		"fct ScaleImg  img, xwn, ywn"
			help={"Scale 2D image wave using specified x & y wave names; scaling assumes monotonic increasing x,y arrays"}
		"fct MaxImg img, indx, outw"
			help={"1D maximum of lineprofile along specified direction"}
		"fct\C ReinterpImg img, xscal, yscal, outimgn"
			help={" reinterpolation of 2D array for specified scale factors"}
		"fct ExtractImg newimgnam"
			help={"extract subset of image in top graph using current plot axes or marquee box"}
		"fct\S ImgRange dir "
			help={"return string containing 'min,max,inc' for specified scaled image axis"}
		"fct\S ReadImgNote  w "
			help={"read IMG note containing xSHIFT,ySHIFT, zOFFSET,zGAIN, VAL, TXT"}
		"fct\S WriteImgNote  w,xshft, yshft, zoff, zgain, val, txt"
			help={"assemble & write IMG note"}
		"fct CUTMX m, indx, xy"
		"fct EXTRACTMX  m, indx, xy, nw "
		"fct CHECKDIM w, dim"
	End	
end

Menu "GraphMarquee"
	"-"
	submenu "Misc"
		//"Crop"
		"2D: ReGridXY"	, ReGridXY()
	end
end

Menu "Load Waves"
	"LoadRGB2gray"
end


//Menu "Graph"
//	Submenu "Remove"
//		"Color legend Controls", JEG_ZapColorLegendControls()
//		help = {"Remove color legend controls only"}
//	End
//End



function dispi( img,  [x, y, o, a] )
//===========
// dispi( im )	
//  		plot im vs {im_x, im_y} if axis arrays exist
//		else: plot im with axis scaling 
// dispi( im, x=xw, y=yw )
//   	plot im vs {xw, yw}		if axis arrays are (M+1,N+1) length
//	or   plot im vs {x1, y1}		creates (M+1,N+1) arays from (M,N) arrays
// Looks for existence of im_CT color table array
//  a=1 -- append to top graph
//  o="options"
	wave img, x, y
	string o			//option string
	variable a		// append option
	
	string imgn=NameOfWave( img )
	string CTwn=imgn+"_CT"
	
	if (ParamIsDefault(a) || (a==0) )
		Display
	endif				// else Append
	
	// Check for supplied image axes  
	if( ParamIsDefault(x) && ParamIsDefault(y) )
		//check for existence of image axis arrays (_x, _y)
		string xwn=imgn+"_x", ywn=imgn+"_y"

		if ( exists(xwn)&&exists(ywn) )
			WAVE xw=$xwn, yw=$ywn	
			appendimage img vs { xw, yw }	
		else
			appendimage img		//Plot scaled image
		endif
	else
		variable imgnx=DimSize(img, 0), imgny=DimSize(img,1)
		variable nx=DimSize(x, 0), ny=DimSize(y,0)
		if ( (nx==imgnx+1)&&(ny==imgny+1) )
			appendimage img vs { x, y }
		elseif ( (nx==imgnx)&&(ny==imgny) )
			string x1n=NameOfWave(x)+"1", y1n=NameOfWave(y)+"1"
			IMG_AXIS( x, x1n, 1 )		//make M+1 array
			IMG_AXIS( y, y1n, 1 )		//make N+1 array
			WAVE x1=$x1n, y1=$y1n	
			appendimage img vs { x1, y1 }
		endif
	endif

	if (exists(CTwn))
		execute "ModifyImage "+imgn+" cindex="+CTwn
		//ModifyImage img cindex=$CTwn
	else
		print "No color table with name: "+CTwn
		
		variable CTnum=1
		variable action=2, gamma=1, invert=1
		prompt action, "Create index CT ("+CTwn+")?", popup, "No;Yes"
		prompt CTnum, "Color Table", popup,  CTnamelist(2)		//requires image_util
		prompt gamma, "Gamma"
		prompt invert, "Invert?", popup, "No;Yes"
		DoPrompt "CT does not exist" action, CTnum, gamma, invert
		if (action==2)
			string opt="/CT="+num2str(CTnum-1)
			opt+=SelectString(gamma!=1, "", "/gamma="+num2str(gamma))
			opt+=SelectString( invert==2, "", "/invert")
			opt+="/P"		//plot
			CTmake( img,opt)
			//execute "ModifyImage "+imgn+" cindex="+CTwn
		endif
	endif
end


function dispi_old( img )
//===========
	wave img
	string imgn=NameOfWave( img )
	string CTwn=imgn+"_CT"
	display;appendimage img
	if (exists(CTwn))
		execute "ModifyImage "+imgn+" cindex="+CTwn
		//ModifyImage img cindex=$CTwn
	else
		print "No color table with name: "+CTwn
		
		variable CTnum=1
		variable action=2, gamma=1, invert=1
		prompt action, "Create index CT ("+CTwn+")?", popup, "No;Yes"
		prompt CTnum, "Color Table", popup,  CTnamelist(2)		//requires image_util
		prompt gamma, "Gamma"
		prompt invert, "Invert?", popup, "No;Yes"
		DoPrompt "CT does not exist" action, CTnum, gamma, invert
		if (action==2)
			string opt="/CT="+num2str(CTnum-1)
			opt+=SelectString(gamma!=1, "", "/gamma="+num2str(gamma))
			opt+=SelectString( invert==2, "", "/invert")
			opt+="/P"		//plot
			CTmake( img,opt)
			//execute "ModifyImage "+imgn+" cindex="+CTwn
		endif
	endif
end

function appi( img )
//===========
	wave img
	dispi( img, a=1 )
end


function appi_old( img )
//===========
	wave img
	string imgn=NameOfWave( img )
	string CT=imgn+"_CT"
	appendimage img
	if (exists(CT))
		execute "ModifyImage "+imgn+" cindex="+CT
		//ModifyImage img cindex=$CT
	else
		print "No color table with name: "+CT
		//abort "No color table with name: "+CT
	endif
end

static function IMG_AXIS( wv, ow, opt )
//==================
// create N±1 wave for image plots axes
// allows wave overwriting, i.e. ow="wv"
	wave wv
	string ow
	variable opt
	Duplicate/O wv w
	variable np=numpnts( w ), np2
	
	np2=SelectNumber( opt>=0, np-1, np+1 )
	make/o/n=(np2) $ow
	WAVE owv=$ow
	
	if (opt>=0)					// N+1
		owv[1,np-1]=(w[p-1]+w[p])/2
		owv[0]=owv[1] - (w[1]-w[0])
		owv[np]=owv[np-1]+(w[np-1]-w[np-2])
	else							// N-1
		owv=(w[p]+w[p+1])/2
	endif
	Killwaves w
	return np2
end

Function/S Img_Info( image, opt )
//================
//  returns info string 
// Options: /VAR - creates global variables in current folder
//               /EXT=ext - extension to add to global variable names
	wave image
	string opt
	string imgnam_=NameOfWave(image)
	variable nx_, xmin_, xmax_, xinc_
	variable ny_, ymin_, ymax_, yinc_
	variable dmin_, dmax_
	nx_=DimSize(image, 0); 	ny_=DimSize(image, 1)
	xmin_=DimOffset(image,0);  ymin_=DimOffset(image,1);
	xinc_=round(DimDelta(image,0) * 1E6) / 1E6	
	yinc_=round(DimDelta(image,1)* 1E6) / 1E6
	xmax_=xmin_+xinc_*(nx_-1);	ymax_=ymin_+yinc_*(ny_-1);
	WaveStats/Q image
	dmin_=V_min;  dmax_=V_max
	string info="img="+imgnam_+";nx="+num2istr(nx_)+";ny="+num2istr(ny_)
	info+=";xmin="+num2str(xmin_)+";xmax="+num2str(xmax_)+";xinc="+num2str(xinc_)
	info+=";ymin="+num2str(ymin_)+";ymax="+num2str(ymax_)+";yinc="+num2str(yinc_)
	info+=";dmin="+num2str(dmin_)+";dmax="+num2str(dmax_)
	string fldrSav, fldr=KeyStr("VAR", opt)
	if (strlen(fldr)>0)
		fldrSav=GetDataFolder(1)
		NewDataFolder/O/S $fldr
		string/G imgnam=imgnam_
		variable/G nx=nx_, xmin=xmin_, xmax=xmax_, xinc=xinc_
		variable/G ny=ny_, ymin=ymin_, ymax=ymax_, yinc=yinc_
		variable/G dmin=dmin_, dmax=dmax_
		SetDataFolder $fldrSav
	endif
	
	return info
End

Function/S ReadImgNote( w )		//, destwn )
//============
	wave w
	string destwn
	string noteStr, modlst
	noteStr=note(w)
	modlst=StringByKey( "IMG", noteStr, ":", "\r" )
	if (strlen(modlst)==0)					// no wave mod keywords
   		Note/K w
   		//modlst="xSHIFT=0,zOFFSET=0,zGAIN=1,LIN=0,THK=0.5,CLR=0,VAL=0,TXT= ;"
   		modlst="xShift=0,yShift=0,zOffset=0,zGain=1,Val=0,Txt= "
   		Note w, "IMG:"+modlst+"\r"+noteStr		// pre-pend default
   		print modlst
   	endif
	return modlst
	//print noteStr
	//string moddef="MOD:xSHIFT=0,zOFFSET=0,zGAIN=1,LIN=0,THK=0.5,CLR=0,imVAL=0,imTXT= ;"
	//string moddef="MOD=0,0,1;STYLE=0,0.5,0;imVAL=0,imTXT= ;"
	//string styledef="STYLE:lin=0,thk=0.5,clr=0;"
	//string annodef="ANNO:val=0,txt= ;"
End


Function/S WriteImgNote(w,xshft, yshft, zoff, zgain, val, txt)
//=============
	wave w
	variable xshft, yshft, zoff, zgain, val
	string txt
	string notestr, modlst
	//modlst="xSHIFT="+num2str(shft)+",zOFFSET="+num2str(off)+",zGAIN="+num2str(gain)
	//modlst+=",LIN="+num2str(lin)+",THK="+num2str(thk)+",CLR="+num2str(clr)
	//modlst+=",imVAL="+num2str(val)+",imTXT="+txt
	modlst="xShift="+num2str(xshft)+",yShift="+num2str(yshft)
	modlst+=",zOffset="+num2str(zoff)+",zGain="+num2str(zgain)
	modlst+=",Val="+num2str(val)+",Txt="+txt
	notestr=note(w)
	notestr=ReplaceStringByKey("IMG", notestr, modlst, ":", "\r")
   	Note/K w			//kill previous note
   	Note w, noteStr
   	return modlst
end


Function/S ImgRange( dir, defalt )
//==============
//  return  "min,max" range string for specific direction of top image in top graph
//  (1) use corners of marquee box if present, or
//  (2) if no marquee, use default option: (a) axes, (b) image, or (c) global pair string
//        (a)  "" or "axis":   use graph axes limits
//	     (b) "image":  use image limits
//       (c)  global pair string (if exists)- create if doesn't exist (subfolders must already exist)
//  use image inc(rement) for rounding of range limits
	variable dir								// select direction, 0=X, 1=Y
	string defalt
	
	//get increment from top graph image for rounding range
	string imgn=ImageNameList("",";")
	imgn=StringFromList(0, imgn, ";")				// use first image for range
	variable inc=DimDelta($imgn,dir), x1, x2
		x1=DimOffset($imgn,dir)
		x2=x1+inc*(DimSize($imgn,dir)-1)
	string rngstr=num2str(x1)+","+num2str(x2)
	inc=abs(inc)
	
	if (WinType(WinName(0, 87))!=1)		// top window not  a graph
		return "Nan,Nan"
	else
		GetMarquee left, bottom
	endif
	//print V_flag
	if (V_flag==1)							// use Marquee range
		if (dir==0)
			x1=inc*round(V_left/inc)		//round to nearest data increment
			x2=inc*round(V_right/inc)
		else
			x1=inc*round(V_bottom/inc)
			x2=inc*round(V_top/inc)	
		endif
		rngstr=num2str(x1)+","+num2str(x2)
	else	
		if ((strlen(defalt)==0)+stringmatch(defalt,"axis"))			// use Axes ranges (allows manual zoom)
			if (dir==0)
				GetAxis/Q bottom
				x1=inc*(V_min/inc+0.5)		//round to nearest data increment
				x2=inc*(V_max/inc-0.5)
			else
				GetAxis/Q left
				//x1=inc*round(1000*(V_min/inc+0.5))/1000
				x1=inc*(V_min/inc+0.5)
				x2=inc*(V_max/inc-0.5)	
			endif
			rngstr=num2str(x1)+","+num2str(x2)
		elseif (stringmatch(defalt,"image"))	
			//already computed
		else			//global
			rngstr=StrVarOrDefault(defalt, rngstr)
		endif
		if (stringmatch(defalt,"blank"))
			rngstr=""
		endif	
	endif
	return rngstr
End


Function/S ImgAxisNam(win, imgn, which)
//=================
	string  win, imgn
	variable which
	if (strlen(imgn)==0)
		imgn=ImageNameList(win, ";")
		//imgn=imgn[0, strlen(imgn)-2]				//assumes only one image
		imgn=imgn[0, strsearch(imgn, ";", 0)-1]	// assumes first image in window
	endif
	string AXISN=SelectString( which, "XWAVE:", "YWAVE:")
	
	string infostr=ImageInfo( win, imgn, 0 )
	variable i1, i2
	i1=strsearch(infostr, AXISN, 0)+6;   i2=strsearch(infostr, ";", i1)-1
	//print i1, i2
	return infostr[i1, i2]
end



Proc ReplotAsPICT(img, xscal, yscal)
//--------------
// Reinterpolate image to finer density; copy to clipboard, then to internal PICT image
// replot with graph style from top graph
	string img
	variable xscal=NumVarOrDefault("root:tmp:xrescal", 2), yscal=NumVarOrDefault("root:tmp:yrescal", 2)
	prompt img, "Image to replot as PICT", popup, ImageNameList("",";")   //WaveList("*",";","WIN:")
	prompt xscal, "X reinterpolation factor", popup, "1X;2X;4X;8X;16X"
	prompt yscal, "Y reinterpolation factor", popup, "1X;2X;4X;8X;16X"
	
	NewDataFolder/O root:tmp
	variable/G root:tmp:xrescal=xscal, root:tmp:yrescal=yscal
	
	PauseUpdate; Silent 1
// Reinterpolate to finer pixels
	variable/C nxy2
	nxy2=ReinterpImg( $img, 2^(xscal-1), 2^(yscal-1), "root:tmp:im")
	print nxy2
	//variable nx=DimSize($img,0), ny=DimSize($img,1)

// Gather info on topmost graph (colortable; size; labels?)
	string wname=WinName(0,1)
	// -- color table
	string CTstr=ImageInfo("", img, 0 )
	variable i1, i2
	i1=strsearch(CTstr, "RECREATION:", 0)+11;  i2=strsearch(CTstr, ";", i1)-1
	CTstr=CTstr[i1, i2]
		//print i1, i2, CTstr
		//string CTstr=ColorTableStr("", img)
		
	// -- Window recreation  
	//string styleproc=WinName(0,1)+"Style"
	//DoWindow/R/S=$styleproc $WinName(0,1)		//works alright; but need to recompile after use
	string WinRecStr = WinRecreation(wname, 0)

	//-- axis limits  (one pixel larger range than image x, y scale limits)
	GetAxis/Q bottom
	variable xmin=V_min, xmax=V_max
	GetAxis/Q left
	variable ymin=V_min, ymax=V_max
	
	//ModifyGraph info  - nothing useful
	//string xinfo=AxisInfo("","bottom"), yLabel=AxisInfo("","left")
	//i1=strsearch(xinfo, "??:", 0)+11;   i2=strsearch(xinfo, ";", i1)-1
	//xinfo=xinfo[i1, i2]
	//i1=strsearch(yinfo, "??:", 0)+11;   i2=strsearch(yinfo, ";", i1)-1
	//yinfo=yLabel[i1, i2]

	// -- graph size
	GetWindow kwTopWin psize
	variable Gwidth=V_right-V_left, Gheight=V_bottom-V_top
		//print V_left, V_right-V_left, V_top,  V_bottom-V_top
//(optional)
	//GetWindow kwTopWin wavelist		// creates 3-col textwave W_WaveList
	//str=TraceInfo()						// get display info on each wave in wavelist

//Plot new image without axes
		//display; appendimage root:tmp:im
		//ModifyGraph  axThick=0, margin=1			// zero pixel margins not allowed
	NewImage/F/S=0  root:tmp:im
		//ModifyGraph width=nx2,height=ny2				// (1) force to smallest size w/ 1 pixel borders
	ModifyGraph width=Gwidth, height=Gheight	// (2) save as destination size; better pixel accuracy? 
	execute "ModifyImage im "+CTstr				// use same color table

//Export image to Clipboard  as 1X Bitmap PICT
	//SavePICT/O/P=Igor/E=-4/B=(ScreenResolution) as "Img1X"
	SavePICT/E=-4/B=(ScreenResolution) as "Clipboard"	
	DoWindow/K $WinName(0,1)		//topmost - no need to rename
	//(Optional) Remove temporary image 
	Killwaves/Z root:tmp:im

// Reload bitmap PICT from Clipboard
	string imgpct=img+"PCT"
	//LoadPICT/O/Q/P=Igor "Img1X", $imgpct	
	LoadPICT/O/Q "Clipboard", $imgpct	
	
// Create 2-pt array with XY range for axes
	string imgxy=img+"XY"
	Make/o $imgxy={ymin, ymax};  SetScale/I x xmin, xmax,"" $imgxy
	
// Execute Window recreation line-by-line
// skip "Window...", "Pause...", "AppendImage..", "ModifyImage...", "End..."
	variable p0, p1, p2
	p0=strsearch(WinRecStr, "Display", 0)  //Execute Display command line
		//p0=strsearch(WinRecStr, ")", p0) 
	p1=strsearch(WinRecStr, "\r", p0)
		//if ((p1-p0)>3)
		//	execute "Append "+WinRecStr[p0+1,p1-1]
		//endif
	print WinRecStr[p0,p1-1]
	execute WinRecStr[p0,p1-1]

	AppendToGraph $imgxy							//need plotted first for axis labeling
	//ModifyGraph lsize($imgxy)=0,msize($imgxy)=0		// make dummy line/points invisible
	p0=p1+1
	do
		p1= strsearch(WinRecStr, "\r", p0)
		//print p0, p1, (strsearch(WinRecStr,"End", p0) <p1 )
		if ( (p1 == -1) + (strsearch(WinRecStr,"End", p0) <p1 ) )
			break
		endif
		p2=strsearch(WinRecStr,"Image", p0)
		//if ( (p2!=-1)*(p2 <p1) )
		//else
		if ( (p2==-1) + (p2>p1) )			// skip "Appendimage..", "ModifyImage..." lines
			print WinRecStr[p0,p1-1]
			execute WinRecStr[p0,p1-1]
		endif
		p0= p1+1
	while(1)

	ModifyGraph mirror=2
	ModifyGraph width=(Gwidth),height=(Gheight)			//Fix size to original
	ModifyGraph mode($imgxy)=0,lsize($imgxy)=0		// make dummy line/points invisible
	
	//Recall style preferences and labels from original plot
	SetAxis bottom xmin, xmax			// redundant to autoscaling with dummy line, but
	SetAxis left ymin, ymax				//   keeps limits fixed if larger range object overplotted
	//if (exists(styleproc)==5)
	//	Execute styleproc+"()"			// copy graph style if saved
	//endif

// Add PICT to back layer with scale factor
	variable xscl, yscl
	//xscl=Gwidth/nx2;  yscl=Gheight/ny2		//(1) 
	xscl=1; yscl=1								//(2) scaling done before image save
	//	print xscl, yscl
	SetDrawLayer/K ProgBack				//erase
	SetDrawEnv xcoord=prel, ycoord=prel

		//DrawPICT -1/nx2, -1/ny2, xscl, yscl, $imgpct 	//(1)
		//print nx2, ny2, -1/nx2, -1/ny2
	DrawPICT -1/Gwidth, -1/Gheight, xscl, yscl, $imgpct 	//(2)
		print Gwidth, Gheight, -1/Gwidth, -1/Gheight
		//DrawPICT 0, 0, xscl, yscl, $imgpct 
	
		//SetDrawEnv xcoord=abs, ycoord=abs
		//DrawPICT 55, 10, xscl, yscl, $imgpct 
		//SetDrawLayer UserFront
		//GraphNormal 							//redundant?
	if (Wintype(wname+"PCT")==0)
		DoWindow/C  $(wname+"PCT")
	endif
End

Proc AddCrossHair()
//---------------
	if (exists("XHair")==0)
		make/o XHair={-INF,0,INF, nan, 0,0,0}, YHAIR={0,0,0,nan,-INF,0,INF}
	endif
	PauseUpdate; Silent 1
	variable xmid, ymid
	GetAxis/Q left
	ymid=(V_min+V_max)/2
	GetAxis/Q bottom
	xmid=(V_min+V_max)/2
	CheckDisplayed YHair
	if (V_Flag==0)
			AppendToGraph YHair vs XHair
	Endif 
	ModifyGraph offset(YHair)={xmid, ymid}
	ModifyGraph rgb(YHair)=(65535,65535,65535), lstyle(YHair)=1
End

Proc RemoveCrossHair()
//------------------
	CheckDisplayed YHair
	if (V_Flag==1)
		RemoveFromGraph YHair
	Endif 
End

Function Crop() //: GraphMarquee
//==============
	if (stringmatch(Winname(0,1), "ImageTool*")==1)
		//string df=getdf1()		//requires ImageTool (bad?)
		string df=getdf()
		//execute "df=getdf1()"
		NVAR numdim=$(df+"ndim")
		print df, numdim
		if (numdim==3)
			//VolModify("", 0,"Crop")		//requires ImageTool (bad?)
			execute "VolModify(\"\", 0,\"Crop\")"
		else
			//ImgModify("", 0,"Crop")		//requires ImageTool (bad?)
			execute "ImgModify(\"\", 0,\"Crop\")"
		endif
	else
		string imgn=StringfromList(0, ImageNameList("", ";"))
		variable ndim=WaveDims($imgn)
		string newimgn=GetWavesDataFolder($imgn,0)+":"+imgn+"c"
		string xrng, yrng, zrng=""
		variable newplot=2
		xrng=ImgRange(0, "axis")		//marquee or axes limits (not image limits)
		yrng=ImgRange(1, "axis")
		prompt newimgn, "New Image Name, (default=*c, same=overwrite)"
		prompt xrng, "X range (x1,x2); blank =full range"
		prompt yrng, "Y range (y1,y2); blank =full range"
		prompt newplot, "New image plot", popup,"No;Yes;to ImageTool"
		if (ndim==3)
			prompt zrng, "Z range (z1,z2); blank =full range"
			DoPrompt "Crop Volume", newimgn, xrng, yrng, zrng, newplot
		else
			DoPrompt "Crop Image", newimgn, xrng, yrng, newplot
		endif
		if (v_flag==1)
			abort
		endif
		string opt=""
		opt+=SelectString(strlen(newimgn)==0, "/D="+newimgn, "")
		opt+=SelectString(strlen(xrng)==0, "/X="+xrng, "")
		opt+=SelectString(strlen(yrng)==0, "/Y="+yrng, "")
		if (ndim==3)
			opt+=SelectString(strlen(zrng)==0, "/Z="+zrng, "")
		endif
		opt+=SelectString(newplot==2, "", "/P")
		opt+=SelectString(newplot==3, "", "/IT")
		string cmd
		if (ndim==3)
			cmd="VolCrop("+imgn+", \""+opt+"\")"
		else
			cmd="ImgCrop("+imgn+", \""+opt+"\")"
		endif
		execute cmd
		//ImgCrop($imgn,  opt)
		print cmd
	endif
End

static function/s getdf()				//static  can only be called by FUNCTONS (not macros) in this procedure
//override function/s getdf()
//==========
//get data folder from topmost window name
	//return ":"+winlist("*","","win:")+":"
	return "root:"+WinName(0,1)+":"
	//return "root:ImageTool:"
	//return "root:img:"
end



Function/S CropRange(xrng, yrng)		//, rngopt)
//===============
	string xrng, yrng
	variable rngopt
	prompt xrng, "Crop X range (x1,x2); blank =full image X range"
	prompt yrng, "Crop Y range (y1,y2); blank =full image Y range"
	//prompt rngopt, "Range option", popup, "None;Full X;Full Y;Full Axes"
	DoPrompt "Crop Range" xrng, yrng	//, rngopt
	if (V_flag==1)	
		abort
	endif

	string keystr=""
	keystr+=SelectString(strlen(xrng)==0, "/X="+xrng, "")
	keystr+=SelectString(strlen(yrng)==0, "/Y="+yrng, "")
	return keystr
	
	//if ((rngopt==2)+(rngopt==4))
	//	GetAxis/Q bottom
	//	xrng=num2str(V_min)+","+num2str(V_max) 
	//endif
	//if ((rngopt==3)+(rngopt==4))
	//	GetAxis/Q left
	//	yrng=num2str(V_min)+","+num2str(V_max) 
	//endif	
	//return "/X="+xrng+"/Y="+yrng
End


Function/S ImgCrop( img, opt )
//================
// Crop subregion of image
// options: 
//     output:  img+"c" (default),  or  /D=outputwavename, or  /O (overwrite),
//     range:    /X=x1,x2     /Y=y1, y2    (optional for each axis; default=start, end)
//     plot:    /P  (display new image)
//    fct returns "CROP: newimgn; nx, ny" information string
	wave img
	string opt
	string imgn=NameOfWave(img)
	//string imgn=GetWavesDataFolder(img,0)+":"+NameOfWave(img)   //fullname necessaary?
	
	//output image
//	string newimgn=KeyStr("D", opt)
	string newimgn=OutputName( imgn, KeyStr("D", opt), "c" )
	variable overwrite=KeySet("O", opt)+stringmatch(imgn,newimgn)

//	if ((strlen(newimgn)==0)+overwrite)
//		newimgn=imgn+"c"
//	endif
//	if (stringmatch(newimgn[0],"+"))		// add suffix
//		newimgn=imgn+newimgn[1,9]
//	endif
//	if (stringmatch(newimgn[0],"_"))		// add suffix with undescore spacer
//		newimgn=imgn+newimgn
//	endif
	
	// crop range
	string xrng=KeyStr("X", opt), yrng=KeyStr("Y", opt)
	//print xrng, yrng
	variable x1, x2, y1, y2
	if (strlen(xrng)==0)
		x1=DimOffset(img,0); x2=x1+DimDelta(img,0)*(DimSize(img,0)-1)
	else
		x1=NumFromList(0, xrng,","); x2=NumFromList(1, xrng,","); 
	endif
	if (strlen(yrng)==0)
		y1=DimOffset(img,1); y2=y1+DimDelta(img,1)*(DimSize(img,1)-1)
	else
		y1=NumFromList(0, yrng,","); y2=NumFromList(1, yrng,","); 
	endif
	//******
	Duplicate/O/R=(x1,x2)(y1,y2) img, $newimgn
	//******
	WAVE newimgw=$newimgn
	string str=num2str(DimSize(newimgl,0))+","+num2str(DimSize(newimg,1))
	
	if (overwrite)
		Duplicate/O newimgw, img
		Killwaves/Z newimgw
		newimgn=NameOfWave(img)
	else
		if (KeySet("P",opt))
			Display; appendimage newimgw
			//ColorTable
			string CTwnam=imgn+"_CT"
			if (exists(CTwnam)==1)
				Duplicate/O $CTwnam $(newimgn+"_CT")
				//Modifyimage newimg cindex=$(newimgn+"_CT")
				execute "Modifyimage "+newimgn+" cindex="+newimgn+"_CT"
				//execute "Modifyimage "+newimgn+" cindex="+CTwnam
			endif	
		endif
	endif
	if (KeySet("IT",opt))
		string ITlst=winlist("ImageTool*",";","WIN:1")
		if (strlen(ITlst)==0)
			//NewImageTool(outn)
			//ShowImageTool_( "", newimgn )		//requires ImageTool (bad?)
			execute "ShowImageTool_( \"\", "+newimgn+" )"
		else		//use top ImageTool
			DoWindow/F $StringFromList(0, ITlst)
			//NewImg( newimgn )		//requires ImageTool (bad?)
			execute "NewImg( "+newimgn+" )"
		endif
	endif
	
	return "CROP: "+newimgn+";"+str
End

Function/S ImgResize( img, xyval, opt )		//xyopt, xyval )
//==============
//	xyval = (Nx, Ny) or N [=Nx=Ny]
// options:  
//     output:  img+"r" (default),   or  /D=outputwavename, or  /O (overwrite)
//     xyopt:    /I (Interp), /R (Rebin) , /T (thin)
//     nopt:   /NP  (interpret xyval as Npts instead of scale factor) - interp only
// investigate ImageInterpolate (Igor 4) as option for making smaller 
	WAVE img
	//variable xyopt
	string xyval, opt	//=StrVarOrDefault(getdf()+"N_resize", "1,1" )
	//prompt xyopt, "Nx, Ny Resize option:", popup, "Interp by N;Interp to Npts;Rebin by N;Thin by N"
	//prompt xyval, "(Nx, Ny) or N [=Nx=Ny]"
	string imgn=NameOfWave(img)
	
	//output image
	string newimgn=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(imgn,newimgn)
	if ((strlen(newimgn)==0)+overwrite)
		newimgn=imgn+"r"
	endif	
	
	variable nx=DimSize( img, 0), ny=DimSize( img, 1)
	if (stringmatch(xyval,"1,1"))		//no change requested
		if (overwrite)
			newimgn=NameOfWave(img)
		else
			duplicate/o img $newimgn
		endif
		return newimgn+": "+num2str(nx)+" x "+num2str(ny)+" (no change)"	//NameOfWave(img)
		
	endif
	
	// interpret xyval string
	variable xval=1, yval=1
	xval=str2num(StringFromList(0, xyval, ","))
	xval=SelectNumber(numtype(yval)==2, xval, 1)    //NaN for single value list
	yval=str2num(StringFromList(1, xyval, ","))
	yval=SelectNumber(numtype(yval)==2, yval, xval)    //NaN for single value list
	//print xval, yval
	
	variable  xyopt=0*KeySet("I", opt)+1*KeySet("R", opt)+2*KeySet("T", opt)
	//string df=getdf(), curr=GetDataFolder(1)
	//SetDataFolder $df
	//string/G N_resize=xyval
	//variable/C coffset=GetWaveOffset($(df+"HairY0"))
	
	// globals will get updated later by ImgInfo()
	//input image info

	variable xmin=DimOffset( img, 0), ymin=DimOffset( img, 1)
	variable xinc=DimDelta( img, 0), yinc=DimDelta( img, 1)
	variable nx2=nx, ny2=ny
	string sizestr
	
	switch( xyopt )
	case 0:		//2D interpolate    
		//nx2=SelectNumber(xyopt==1, xval, nx*xval)
		//ny2=SelectNumber(xyopt==1, yval, ny*yval)
		variable nopt=KeySet("NP", opt)		// 0 = scale factors
		if (nopt==1)
			xval=round(xval); yval=round(yval)
			nx2=SelectNumber(xval==1, xval, nx)		// don't allow Nx2=1
			ny2=SelectNumber(yval==1, yval, ny)
			//print nx2, ny2
			Make/O/N=(nx2, ny2) $newimgn
			WAVE newimg=$newimgn
			SetScale/I x xmin, xmin+(nx-1)*xinc,"" newimg
			SetScale/I y ymin, ymin+(ny-1)*yinc,"" newimg
			sizestr=num2str(nx2)+" x "+num2str(ny2)
		else		// scale factors
			nx2=round(nx*xval) - 1*(mod(nx,2))
			ny2=round(ny*yval)- 1*(mod(ny,2))
			xinc/=xval; yinc/=yval
			//print nx2, ny2, xinc, yinc
			Make/O/N=(nx2, ny2) $newimgn
			WAVE newimg=$newimgn
			SetScale/P x xmin, xinc,"" newimg
			SetScale/P y ymin, yinc,"" newimg
			sizestr=num2str(nx2)+"("+num2str(xval)+")"
			sizestr+=" x "+num2str(ny2)+"("+num2str(yval)+")"
		endif
		newimg=interp2D(img, x, y)
		break
	case 1:		// Rebin  X, then Y
	case 2:		// Thin X, then Y
	//if (xyopt>=3)		
		variable ii, jj
		nx2=round(nx/xval)
		//ny2=trunc(ny/yval)
		ny2=round(ny/yval)
		// print nx2, ny2
		if (xval>1) 
			xinc*=xval
			Make/O/N=(nx2, ny) $(newimgn+"x")
			WAVE newimgx=$(newimgn+"x")
			SetScale/P x xmin, xinc,"" newimgx
			SetScale/P y ymin, yinc,"" newimgx
			ii=0
			DO
				newimgx[ii][]=0
				if (xyopt==1)				// Rebin X
					jj=0
					newimgx[ii][]=0
					DO
						newimgx[ii][]+= img[xval*ii+jj][q]
						jj+=1
					WHILE( jj<xval )
					newimgx[ii][]/=xval
				endif
				if (xyopt==2)				// Thin X
					newimgx[ii][]+=img[xval*ii][q]
				endif
				ii+=1
			WHILE( ii<nx2)
			sizestr=num2str(nx2)+"("+num2str(xval)+")"
		else
			Duplicate/O img $(newimgn+"x")
			WAVE newimgx=$(newimgn+"x")
			sizestr=num2str(nx2)
		endif
		if (yval>1) 
			yinc*=yval
			Make/O/N=(nx2, ny2) $newimgn
			WAVE newimg=$newimgn
			SetScale/P x xmin, xinc,"" newimg
			SetScale/P y ymin, yinc,"" newimg
			ii=0
			DO
				newimg[][ii]=0
				if (xyopt==1)				// Rebin Y
					jj=0
					newimg[][ii]=0
					DO
						newimg[][ii]+= newimgx[p][yval*ii+jj]
						jj+=1
					WHILE( jj<yval )
					newimg[][ii]/=yval
				endif
				if (xyopt==2)				// Thin Y
					newimg[][ii]+= newimgx[p][yval*ii]
				endif
				ii+=1
			WHILE( ii<ny2)
			sizestr+=" x "+num2str(ny2)+"("+num2str(yval)+")"
		else
			Duplicate/O newimgx $newimgn
			WAVE newimg=$newimgn
			sizestr+=" x "+num2str(ny2)
		endif
		Killwaves/Z newimgx
		break
	endswitch
	
	if (overwrite)
		Duplicate/O newimg img
		Killwaves/Z newimg
		newimgn=NameOfWave(img)
	endif
	
	//SetDataFolder curr
	return newimgn+": "+sizestr
End

Function/T ImgRescale( arr, rng, opt )
//==============
//     rng = "/X=val"  or "/X=val1,val2" or "/X=val1,val2,val3"
// options:
//    /XP, /YP   -- min, inc  pointscaling
//    /XI, /YI      -- min,max inclusive range
//    /XC, /YC    -- center, inc
//    /XZ , /YZ  -- val offset (,inc)  : resets val to zero
//    /XCSR, /YCSR  -- offset  cursor position -> val
// also works for directions Z, T
	WAVE arr
	string rng, opt
	
	string arrn=NameOfWave(arr)
	
//	string newimgn=OutputName( imgn, KeyStr("D", opt), "n" )
	
	variable nv, np, vmin, vinc, dv, pt
	variable/C coffset
	string xcmd="", ycmd=""		//, sv1, sv2
	string df
	string cmd, fullcmd="",  idir, irng, sv1, sv2
	variable ndim=WaveDims(arr), i
	FOR( i=0; i<ndim;  i+=1)
		cmd=""
		idir="xyzt"[i]
		irng=KeyStr(idir, rng)
		if (strlen(irng)>0)
			sv1=StringFromList(0, irng, ",")	
			nv=ItemsInList( irng,",")
			if (KeySet(idir+"P", opt) )		// point scaling: min, inc
				cmd="SetScale/P "+idir+" "
				sv2=StringFromList(nv-1, irng, ",")
			endif
			if (KeySet(idir+"I", opt) )		// inclusive: min, max
				cmd="SetScale/I "+idir+" "
				sv2=StringFromList(1, irng, ",")
			endif
			if (KeySet(idir+"C", opt) )		// center, inc
				cmd="SetScale/P "+idir+" "
				sv2=SelectString( nv==1, StringFromList(nv-1, irng, ","), num2str(DimDelta(arr, i)) )
				np=DimSize(arr, i)
				sv1=num2str( str2num(sv1)-0.5*(np-1)*str2num(sv2) )
			endif
			if (KeySet(idir+"Z", opt) )		// reset VAL to zero == shift scale (+ optional specify new INC)
				cmd="SetScale/P "+idir+" "
				sv1=num2str( DimOffset(arr, i) - str2num(sv1) )			// min' = min - VAL
				sv2=SelectString( nv==1, StringFromList(nv-1, irng, ","), num2str(DimDelta(arr, i)) )		//Inc
			endif
			if (KeySet(idir+"CSR", opt) )		// cursor=val 
				cmd="SetScale/P "+idir+" "
				//df=getdf1()										//requires ImageTool
				execute "df=getdf1()"	
				coffset=GetWaveOffset($(df+"HairY0"))		// need graph on top
				if (i==0)		//X
					ModifyGraph offset(HairY0)={str2num(sv1), IMAG(coffset)}
					sv1=num2str( DimOffset(arr,0)-REAL(coffset)+ str2num(sv1) )
				else				//Y
					ModifyGraph offset(HairY0)={REAL(coffset), str2num(sv1)}
					sv1=num2str( DimOffset(arr,1)-IMAG(coffset)+ str2num(sv1) )
				endif
				sv2=num2str(DimDelta(arr,i))
			endif
		endif
		if (strlen(cmd)>0)
			cmd+=sv1+", "+sv2+" , \"\" "+arrn+"; "
			execute cmd
			fullcmd+=cmd
		endif
	ENDFOR
	
	//SetDataFolder $curr
	//return xcmd+SelectString( (xopt>1)*(yopt>1), "", "\r  ")+ycmd
	return fullcmd
End

Function/T ArrRescale( )
//==============
	string arrn=StringFromList(0, imageNameList("",";"))
	WAVE arr=$arrn
	variable ndim=WaveDims( arr )
	// full range values
	variable i , v1, v2, vinc, np
	string rng="", idir
	FOR (i=0;i<ndim;i+=1)
		idir="XYZT"[i]
		v1=DimOffset(arr,i); vinc=DimDelta(arr,i); np=DimSize(arr,i)
		v2=v1+vinc*(np-1)
		rng+="/"+idir+"="+num2str(v1)+","+num2str(v2)+","+num2str(vinc)
	ENDFOR
	//print rng
	//prompt for options
	variable xopt=0, yopt=0, zopt=0, topt=0
	prompt arrn, "Array to rescale", popup, WaveList("!*_CT",";","WIN:")
	prompt rng, "Ranges (min,max,inc) (min,max) (min,inc) or (val)"
	prompt xopt, "X rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	prompt yopt, "Y rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"	
	switch(ndim)
		case 2:	
			DoPrompt "Image rescale" arrn, rng, xopt, yopt
			break
		case 3:	
			prompt zopt, "Z rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
			DoPrompt "Volume rescale" arrn, rng, xopt, yopt, zopt
			break
		case 4:		
			prompt zopt, "Z rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
			prompt topt, "T rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
			DoPrompt "4D Volume rescale" arrn, rng, xopt, yopt, zopt, topt				
	endswitch
		if (v_flag==1)
			return ""
		endif
	string opt=""
	opt+=StringFromList( xopt-2, "/XP;/XI;/XC;/XCSR")
	opt+=StringFromList( yopt-2, "/YP;/YI;/YC;/YCSR")
	opt+=StringFromList( zopt-2, "/ZP;/ZI;/ZC;/ZCSR")
	opt+=StringFromList( topt-2, "/TP;/TI;/TC;/TCSR")

	string cmd
	//if (ndim==3)
	//	cmd="VolRescale("+arrn+", "+rng+", "+opt+")"
	//	VolRescale( arr, rng, opt)
	//else
		cmd="ImgRescale("+arrn+", "+rng+", "+opt+")"
		print cmd
		print ImgRescale( arr, rng, opt)
	//endif
	return cmd
End

Function/T ImgRescale0( )
//==============
	string df		//=getdf1()			//requires Image_Tool
	execute "df=getdf1()"
	string curr=GetDataFolder(1)
	SetDataFolder $df
	NVAR nx=nx, xmin=xmin, xmax=xmax, xinc=xinc
	NVAR ny=ny, ymin=ymin, ymax=ymax, yinc=yinc
	string xrang=num2str(xmin)+", "+num2str(xmax)+", "+num2str(xinc)
	string yrang=num2str(ymin)+", "+num2str(ymax)+", "+num2str(yinc)
	variable xopt=NumVarOrDefault(df+"xopt_rescale",1)
	variable yopt=NumVarOrDefault(df+"yopt_rescale",1)
	prompt xrang, "X-values:  (min,inc) or (min,max) or (center, inc) or (val)"
	prompt yrang, "Y-values:  (min,inc) or (min,max)  or (center, inc) or (val)"
	prompt xopt, "X-axis Rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	prompt yopt, "Y-axis Rescaling:", popup, "No Change;Min, Inc;Min, Max;Center, Inc;Cursor=val"
	DoPrompt "Image Rescale" xopt, xrang, yopt, yrang
	if (V_flag==1)
		SetDataFolder $curr
		abort
	endif
	variable/G $(df+"xopt_rescale")=xopt, $(df+"yopt_rescale")=yopt
	//string/G $(df+"x12_rescale")=xrang, $(df+"y12_rescale")=yrang
	
	variable nv, vmin, vinc, dv, pt
	variable/C coffset
	
	string xcmd="", ycmd="", sv1, sv2
	// globals will get updated later by ImgInfo()
	if (xopt>1) 
		sv1=StringFromList(0, xrang, ",")		//min
		//vmin=str2num(StringFromList(0, xrang, ","))
		nv=ItemsInList(xrang,",")
		sv2=SelectString(nv>1, num2str(xinc), StringFromList(nv-1, xrang, ","))   //inc or max
		//vinc=xinc
		if (nv>1) 
			vinc=str2num(StringFromList(nv-1, xrang, ","))
		endif
		switch( xopt )
		case 2:			//Min, Inc
			xcmd="SetScale/P x "
			sv2=StringFromList(nv-1, xrang, ",")
			//SetScale/P x vmin, vinc , "" Image
			break
		case 3: 			//Min, Max
			xcmd="SetScale/I x "
			sv2=StringFromList(1, xrang, ",")
			//SetScale/I x vmin, str2num(StringFromList(1,xrang, ",")), "" Image
			break
		case 4:			//Center, Inc
			xcmd="SetScale/P x "
			sv2=StringFromList(nv-1, xrang, ",")
			sv1=num2str( str2num(sv1)-0.5*(nx-1)*str2num(sv2) )
			//SetScale/P x vmin-0.5*(nx-1)*vinc, vinc , "" Image
			break
		case 5:			// Cursor=val
			xcmd="SetScale/P x "
			coffset=GetWaveOffset($(df+"HairY0"))
			ModifyGraph offset(HairY0)={str2num(sv1), IMAG(coffset)}
			sv1=num2str( xmin-REAL(coffset)+ str2num(sv1) )
			sv2=num2str(xinc)
			//SetScale/P x xmin-REAL(coffset)+vmin, xinc,"" Image
		endswitch
		xcmd+=sv1+", "+sv2+" , \"\" Image; "
		execute xcmd
	endif
	if (yopt>1) 
		sv1=StringFromList(0, yrang, ",")		//min
		nv=ItemsInList(yrang,",")
		sv2=SelectString(nv>1, num2str(yinc), StringFromList(nv-1, yrang, ","))   //inc or max
		if (nv>1) 
			vinc=str2num(StringFromList(nv-1,yrang, ","))
		endif
		switch( yopt )
		case 2:			//Min, Inc
			ycmd="SetScale/P y "
			sv2=StringFromList(nv-1, yrang, ",")
			break
		case 3: 			//Min, Max 
			ycmd="SetScale/I y "
			sv2=StringFromList(1, yrang, ",")
			break
		case 4:			//Center, Inc
			ycmd="SetScale/P y "
			sv2=StringFromList(nv-1, yrang, ",")
			sv1=num2str( str2num(sv1)-0.5*(ny-1)*str2num(sv2) )
			break
		case 5:			// Cursor=val
			ycmd="SetScale/P y "
			coffset=GetWaveOffset($(df+"HairY0"))
			ModifyGraph offset(HairY0)={REAL(coffset), str2num(sv1)}
			sv1=num2str( ymin-IMAG(coffset)+ str2num(sv1) )
			sv2=num2str(yinc)
			//SetScale/P y ymin-IMAG(coffset)+vmin, yinc,"" Image
		endswitch
		ycmd+=sv1+", "+sv2+" , \"\" Image; "
		execute ycmd
	endif
	SetDataFolder $curr
	//return xcmd+SelectString( (xopt>1)*(yopt>1), "", "\r  ")+ycmd
	return xcmd+ycmd
End


Function/S ImgNorm( img, opt )
//================
// Normalize image along selected direction by average value defined range
// Future:  other methods:  divide by edge profile;  plot norm wave
// options: 
//     output:  img+"_nrm" (default),  or  /O=outputwavename, or /O (overwrite)
//     direction:    /X (default) or  /Y 
//     range:        /R=y1,y2  or x1,x2   (default = full range)
//     plot:    /P  (display new image)
	wave img
	string opt
	string imgn=NameOfWave(img)	
	
	//output image
//	string newimgn=KeyStr("D", opt)
	string newimgn=OutputName( imgn, KeyStr("D", opt), "n" )
	variable overwrite=KeySet("O", opt)+stringmatch(imgn,newimgn)
//	if ((strlen(newimgn)==0)+overwrite)
//		newimgn=imgn+"_nrm"
//	endif
	
	//direction
	variable  idir=0*KeySet("X", opt)+1*KeySet("Y", opt)
	variable NP=DimSize(img, idir)
	
	//orthogonal range to average
	string rng=KeyStr("R", opt)
	variable r1, r2, idir2=1-idir
	if (strlen(rng)==0)
		r1=DimOffset(img,idir2); r2=r1+DimDelta(img,idir2)*(DimSize(img,idir2)-1)
	else
		r1=NumFromList(0, rng,","); r2=NumFromList(1, rng,","); 
	endif
	
	// Temporary  line profile & normalization arrays
	NewDataFolder/O root:tmp
	Make/O/N=(DimSize(img, idir2)) root:tmp:line
	WAVE line=root:tmp:line
	SetScale/P x DimOffset(img,idir2), DimDelta(img,idir2), "" line
	Make/O/N=(NP) root:tmp:nrmw
	WAVE nrmw=root:tmp:nrmw
	SetScale/P x DimOffset(img,idir), DimDelta(img,idir), "" nrmw
	
	variable ii=0
	DO
		//line=SelectNumber( idir, img(x)( y0), img(y0)(x) )
		line=SelectNumber( idir2, img[p][ii], img[ii][p] )
		WaveStats/Q/R=(r1,r2) line
		nrmw[ii]=V_avg						// or V_max
	
		ii+=1
	WHILE( ii<NP)
	
	Duplicate/O img, $newimgn
	WAVE newimg=$newimgn
	if (idir==0)
		newimg=img/nrmw[p]
	endif
	if (idir==1)
		newimg=img/nrmw[q]
	endif

	if (overwrite)
		Duplicate/O newimg, img
		Killwaves/Z newimg
		newimgn=NameOfWave(img)
	else
		if (KeySet("P",opt))
			Display; appendimage newimg
		endif
	endif
	
	return "NORM "+"XY"[idir]+" "+newimgn+": "+num2str(NP)
End

Function/S ImgAvg( img, opt )
//================
// Average image along selected direction by average value defined range
// Future:  other methods:  divide by edge profile;  plot norm wave
// options: 
//     output:  img+"_av" (default),   or  /D=outputwavename,  or /O (overwrite)
//     direction:    /X (default) or  /Y 
//     range:        /R=y1,y2  or x1,x2   (default = full range)
//     plot:    /P  (display new image)
	wave img
	string opt
	
	//output array name
	//variable overwrite    -- no overwrite option since output is 1D
	string imgn=NameOfWave(img), avgn=KeyStr("D", opt)
	if ((strlen(avgn)==0)+stringmatch(imgn,avgn))
		avgn=NameOfWave(img)+"_av"
		//overwrite=KeySet("O", opt)
	endif
	
	//direction
	variable  idir=0*KeySet("X", opt)+1*KeySet("Y", opt)
	variable nav=DimSize(img, idir), n2av=DimSize(img, 1-idir)
	//create output 1D array
	make/o/n=(nav) $avgn
	WAVE avg=$avgn
	
	//mask
	variable imask, maskval
	string maskn=KeyStr("M", opt)
	imask=KeySet("M", opt)*(strlen(maskn)>0)		//key set AND value given
	imask*=(exists(maskn)==1)		//wave exists
	//future: multiply image by mask; use image to create mask
	if (imask)
		WAVE mask=$maskn
		NewDataFolder/O root:tmp
		Make/O/N=(nav) root:tmp:masksum
		WAVE masksum=root:tmp:masksum
		// perform mask sum loop
		variable jj
		DO
			if (idir==0)
				masksum+=mask[p][jj]
			else
				masksum+=mask[jj][p]
			endif
			jj+=1
		WHILE(jj<n2av)
	endif
	
	//orthogonal range to average
	//string rng=KeyStr("R", opt)
	//variable r1, r2, idir2=1-idir
	//if (strlen(rng)==0)
	//	r1=DimOffset(img,idir2); r2=r1+DimDelta(img,idir2)*(DimSize(img,idir2)-1)
	//else
	//	r1=NumFromList(0, rng,","); r2=NumFromList(1, rng,","); 
	//endif

	//variable nx=DimSize(img, 0), ny=DimSize(img,1)
	// perform image sum loop
	variable ii
	DO
		if (idir==0)
			avg+=img[p][ii]
		else
			avg+=img[ii][p]
		endif
		ii+=1
	WHILE(ii<n2av)
	
	//normalize by value or masksum
	if (imask)
		avg/=masksum[p]
	else
		avg/=n2av
	endif

	//scale identical to original image
	SetScale/P x DimOffset(img,idir), DimDelta(img,idir),WaveUnits(img,idir) avg
	
	if (KeySet("P",opt))
		Display avg
	endif
	
	return avgn			// or return error message
End



Function/S ScaleImg( img, xwn, ywn)
//==================
// scaled 2D image wave based on x & y reference waves
// scaling assumes x,y-waves are monotonic increasing
// if wx or wy statr with "_" then treat as extensions to im name
	wave img
	string xwn, ywn
	//prompt img, "Image to scale", popup, ImageNameList("",";")
	//prompt wx, "X wave", popup, WaveList("*",";","")
	//prompt wy, "Y wave", popup, WaveList("*",";","")
	//PauseUpdate; Silent 1
	string imgn=NameOfWave(img)
	if (cmpstr(xwn[0],"_")==0)
		xwn=imgn+xwn
	endif
	if (cmpstr(ywn[0],"_")==0)
		ywn=imgn+ywn
	endif
	
	// Incorrect for monotonic Decreasing X or Y waves
	//WaveStats/Q $xwn
	//SetScale/I x V_min, V_max, WaveUnits($xwn, 0) img
	//WaveStats/Q $ywn
	//SetScale/I y V_min, V_max, WaveUnits($ywn, 0) img
	
	WAVE xw=$xwn, yw=$ywn
	// error accumulation due to last digits of increment?
	//SetScale/P x xw[0],  xw[1]-xw[0], WaveUnits(xw, 0) img
	//SetScale/P y yw[0],  yw[1]-yw[0], WaveUnits(yw, 0) img
	SetScale/I x xw[0],  xw[numpnts(xw)-1], WaveUnits(xw, 0) img
	SetScale/I y yw[0],  yw[numpnts(yw)-1], WaveUnits(yw, 0) img
	
	//Possible return value to detect if x or y wave is uniform monotonic	
	//Create complex function that returns {min, inc} is uniform & {min, NaN} if not uniform
	return "no error"
End



function CUTMX( m, indx, xy )
//=============================
// delete row or column from 2D matrix
// xy=0 cut row, xy=1 cut column
	wave m			//2D matrix
	variable indx, xy
	//function already checks if m is a wave
	if (WaveDims(m)!=2)
		//return 0
		abort "wave is not a 2D matrix"
	endif
	variable nx=DimSize( m, 0 ), ny=DimSize( m, 1 )
	if (xy==0)
		if (indx>=nx)
			abort "specified row larger than dimension"
			//return 0
		endif
		m[indx,*][]=m[p+1][q]
		redimension/n=(nx-1,ny) m
		Print "Deleted row ", indx, "of ",nx
	else
		if (indx>=ny)
			abort "specified column larger than dimension"
			//return 0
		endif
		m[][indx,*]=m[p][q+1]
		redimension/n=(nx,ny-1) m
		Print "Deleted column ", indx, "of ",ny
	endif
	return 1
end

function EXTRACTMX( m, indx, xy, ow )
//=================================
// extract row or column from 2D matrix to output wave $ow
	wave m
	string  ow
	variable indx, xy
	if (WaveDims(m)!=2)
		abort "wave is not a 2D matrix"
	endif
	variable nx=DimSize( m, 0 ), ny=DimSize( m, 1 )
	print nx, ny
	if (xy==0)
		if (indx>=nx)
			abort "specified row larger than dimension"
		endif
		make/o/n=(ny) $ow
		wave w=$ow
		SetScale/P x, DimOffset(m,1), DimDelta(m,1), GetDimLabel(m,1,0)  w 
		w[]=m[indx][p]
		return ny
	else
		if (indx>=ny)
			abort "specified column larger than dimension"
		endif
		make/o/n=(nx) $ow
		wave w=$ow
		SetScale/P x, DimOffset(m,0), DimDelta(m,0), GetDimLabel(m,0,0)  w 
		w[]=m[p][indx]
		return nx
	endif
end

function CHECKDIM( w, dim )
//====================
	wave w
	variable dim
	if (WaveDims(w)!=dim)
		abort "wave is not a "+num2istr(dim)+"-D matrix"
	endif
	return 1
end

Proc ReGridToContour(plot,nx, ny, image, dopt)
//-------------------------
// modified from WaveMetric's AppendImageToContour
	String plot, image
	Variable nx=20, ny=20, dopt=2
	Prompt plot,"contour plot",popup,ContourNameList("",";")
	Prompt nx,"number of rows for image"
	Prompt ny,"number of columns for image"
	Prompt image, "Output image name [blank=auto]"
	Prompt dopt, "Display image", popup, "Append to contour;Display new;none"

	Silent 1;PauseUpdate
	String info=ContourInfo("",plot,0)
	String haxis= StrByKey("XAXIS",info)
	String vaxis= StrByKey("YAXIS",info)
	String xwave= StrByKey("XWAVE",info)
	String ywave= StrByKey("YWAVE",info)
	String zwave= StrByKey("ZWAVE",info)
	String flags= StrByKey("AXISFLAGS",info)
	String type=StrByKey("DATAFORMAT",info)
	Variable doContourZ= CmpStr(type,"XYZ") == 0
	// Make matrix that spans displayed X and Y
	if (strlen(image)==0)
		image=zwave
		image=CleanupName(image+"Image",1)	// not necessarily a unique name
	endif
	//if( doContourZ )
		
	Make/O/N=(nx,ny) $image				// overwrite
	GetAxis/Q $haxis
	SetScale/I x, V_min, V_max, "",$image
	GetAxis/Q $vaxis
	SetScale/I y, V_min, V_max, "",$image
	$image= ContourZ("",plot,0,x,y)
		
	//else // Matrix contour
	//	if( (strlen(xwave) + strlen(ywave)) > 0)	// these grid waves won't work with images
	//		Abort "Can't append image because contour grid wave(s) don't work with image plots."
	//	endif
	//endif
	if (dopt==1)
		CheckDisplayed $image
		if (V_flag==0)
			String cmd
			sprintf cmd,"AppendImage%s %s",flags,PossiblyQuoteName(image)
			Execute cmd
		endif
	endif
	if (dopt==2)
		DoWindow/F $(image+"_")
		if (V_flag==0)
			String cmd
			sprintf cmd,"Display; AppendImage%s %s",flags,PossiblyQuoteName(image)
			Execute cmd
			ModifyImage $image ctab= {*,*,YellowHot,0}
			DoWindow/C $(image+"_")
		endif
	endif
End


Proc Waves2Img( wvlst, imgn, refwv, yrng, dopt, trans, offset_, yinterp, gridopt)
//------------------------------
// Merge list of waves to a 2D array;
// use specified y-axis scaling parameters OR
// create _x, _y n+1 axis using wave note values for y-axis
	string wvlst, refwv 
	string yrng=	StrVarOrDefault("root:img:yrange","0,1")
	string imgn=	StrVarOrDefault("root:img:imgnm","out")
	variable dopt=	NumVarOrDefault("root:img:dispopt",1)
	variable trans=	NumVarOrDefault("root:img:transp",2)
	variable offset_=	NumVarOrDefault("root:img:offsetopt",2)
	variable yinterp=	NumVarOrDefault("root:img:yreinterp",2)
	variable gridopt=	NumVarOrDefault("root:img:grid_opt",2)
	prompt wvlst, "WaveList", popup, "TopGraph;"+StringList("*_lst",";")	//+WinList("*",";","WIN:1")
	prompt refwv, "Reference Wave for X-axis", popup, TraceNameList("",";",1)
	prompt yrng, "Y Scaling: start,incr (VAL or TXT =use wavenote)"
	prompt imgn, "Output image name"
	prompt dopt, "Display Image", popup, "Yes;No"
	prompt trans, "Transpose Image", popup, "Yes;No"
	prompt offset_, "Remove Offset by Cursor(A)", popup, "Yes;No"
	prompt yinterp, "Y reinterpolation factor", popup, "1X;2X;4X;8X;16X"
	prompt gridopt, "Grid option", popup, "Plot vs X,Y;Reinterp to uniform grid"

	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:img
		string/G yrange=yrng, imgnm=imgn
		variable/G dispopt=dopt, transp=trans, offsetopt=offset_, yreinterp=yinterp, grid_opt=gridopt
	SetDataFolder curr

	PauseUpdate; Silent 1
	// check if input wvlst is a Window name or "TopGraph"
	DoWindow/F $wvlst
	if ((V_flag==1)+stringmatch(wvlst, "TopGraph"))
		wvlst=TraceNameList("",";",1)
	endif
	variable ny=ItemsInLIst(wvlst, ";")

	variable nx=numpnts($refwv)
	print nx, ny
	
	make/o/n=(nx, ny) $imgn
	
	variable irreg=(stringmatch(yrng,"VAL")+stringmatch(yrng,"TXT"))
	if (irreg)   			//non-uniform (irregular) axis increment
		string xwn=imgn+"_x", ywn=imgn+"_y"
		make/o/n=(nx) $xwn=pnt2x( $refwv, p)
		//xtmp=DimOffset($refwv,0)+p*DimDelta($refwv,0)
		make/o/n=(ny) $ywn 
		CopyScales/P $refwv, $imgn
	else			// image scaling
		CopyScales/P $refwv, $imgn
		SetScale/P y, ValFromList(yrng,0,","), ValFromList(yrng,1,","), "" $imgn
	endif
	
	string wvn, modlst
	variable idx=0, offval=0
	do
		wvn=StrFromList( wvlst, idx, ";")
		if (offset_==1)
			offval=$wvn( hcsr(A) )
		endif
		//$imgn[][idx]=$wvn[p] - offval
		$imgn()[idx]=$wvn(x) - offval
		if (irreg)
			modlst=StringByKey( "MOD", note($wvn), ":", "\r" )
			$ywn[idx]=NumberByKey(yrng, modlst, "=", "," )
			//$ywn[idx]=ValFromList( note($wvn), 6, ",")
		endif
		idx+=1
	while( idx<ny )
	
// Reinterpolate to finer pixels
	variable/C nxy
	variable yscale=2^(yinterp-1)
	nxy=ReinterpImg( $imgn, 1, yscale, imgn )		//overwrite
	if (irreg)
		make/o/n=(ny) root:tmp:pw0=p
		make/o/n=(yscale*ny) root:tmp:pw1=p/yscale, root:tmp:yw
		root:tmp:yw=interp(root:tmp:pw1, root:tmp:pw0, $("root:"+ywn) )
		Duplicate/O root:tmp:yw $ywn 
	endif
		
// Could make use of reinterpolation to putback onto a regular grid
	
	if (trans==1)
		MatrixTranspose $imgn
		if (irreg)
			AXISW($xwn, "tmp", 1)   	//creates n+1 wave
			AXISW($ywn, xwn, 1)   	//creates nx+1 wave
			Duplicate/O tmp $ywn
		endif
	else
		if (irreg)
			AXISW($xwn, xwn, 1)   	//creates nx+1 wave
			AXISW($ywn, ywn, 1)   	//creates ny+1 wave
		endif
	endif
	
	if (irreg*(gridopt==2))
		ReGridXY( imgn, "root:tmp:im", xwn, ywn, "", "",  0 )
		Duplicate/O root:tmp:im, $imgn
	endif

	if (dopt==1)
		DoWindow/F $(imgn+"_")
		if (V_flag==0)
			if (irreg*(gridopt==1))
				display; appendimage $imgn vs {$xwn, $ywn}
			else
				display; appendimage $imgn
			endif
			ModifyGraph mirror=2
			ModifyImage $imgn ctab= {*,*,YellowHot,0}
			DoWindow/C $(imgn+"_")
		endif
	endif

End

Function/S Img2Waves( img, basen, dir )
//================
// Extract wave set from 2D array
// use image scaling for x-axis and y-value in wave note
// For dir=1, transpose image first
	Wave img
	String basen
	Variable dir
	
	Duplicate/O img tmp
	WAVE tmp=tmp
	if (abs(dir)==1)
		MatrixTranspose tmp
	endif
	
	variable nx=DimSize(tmp, 0), ny=DimSize(tmp,1)
//	print nx, ny
	string linen, wvlst=""
	variable ii=0
	DO
		linen=basen+num2str(ii)
		Make/o/n=(nx) $linen
		WAVE line=$linen	
		CopyScales img, line		// preserves increment direction
		line=tmp[p][ii]
		Note/K line			//initialize WaveNote
   		Note line, "0,0,1, 0, 1, 0,"+num2str( DimOffset(tmp,1)+ii*DimDelta(tmp,1))
   		wvlst+=linen+";"
		ii+=1
	WHILE( ii<ny)
	Killwaves tmp
	
	if (dir<0)		// display option
		//PlotList(wvlst, "", 1, "", "", basen+"_stack")
	endif
	return wvlst
End

Function Image2Waves( img, basen, dir, inc )
//================
// Extract wave set from 2D array
// use image scaling for x-axis and y-value in wave note
// For dir=1, transpose image first
// specify output x-axis increment of wave set
	Wave img
	String basen
	Variable dir, inc
	inc=round( max(inc,1) )
	variable nx=DimSize(img, 0), ny=DimSize(img,1)
//	print nx, ny
	string linen, imgn=NameOfWave( img )
	variable ii=0, val
	if (dir==0)
		ny=round(ny/inc)
		//print nx, ny, inc
		DO
			linen=basen+num2str(ii)
			Make/o/n=(nx) $linen
			WAVE line=$linen	
			//CopyScales img, line
			SetScale/P x  DimOffset(img,0), DimDelta(img,0), WaveUnits(img,0) line
			line=img[p][ii*inc]
			val=DimOffset(img,1)+ii*inc*DimDelta(img,1)
			Write_Mod( line, 0,0,1,0,1,0, val, imgn )
	   		//print ii, ii*inc, val
			ii+=1
		WHILE( ii<ny)
		return ny
	else
		nx=round(nx/inc)
		//print nx, ny, inc
		DO
			linen=basen+num2str(ii)
			Make/o/n=(ny) $linen
			WAVE line=$linen	
			//CopyScales img, line
			SetScale/P x  DimOffset(img,1), DimDelta(img,1), WaveUnits(img,1) line
			line=img[ii*inc][p]
			val=DimOffset(img,0)+ii*inc*DimDelta(img,0)
			Write_Mod( line, 0,0,1,0,1,0, val, imgn )
	   		//print ii, ii*inc, val, note(line)
			ii+=1
		WHILE( ii<nx)
		return nx
	endif
End

Function/S Write_Mod(w, shft, off, gain, lin,  thk, clr, val, txt)
//=============
// repeat of WaveMod function in "Stack" so that Stack.ipf does not need to be called
	wave w
	variable shft, off, gain, lin, thk, clr, val
	string txt
	string notestr, modlst
	modlst="Shift="+num2str(shft)+",Offset="+num2str(off)+",Gain="+num2str(gain)
	modlst+=",Lin="+num2str(lin)+",Thk="+num2str(thk)+",Clr="+num2str(clr)
	modlst+=",Val="+num2str(val)+",Txt="+txt
	notestr=note(w)
	notestr=ReplaceStringByKey("MOD", notestr, modlst, ":", "\r")
   	Note/K w			//kill previous note
   	Note w, noteStr
   	return modlst
end


Proc NormImg(img, nrm, method, indx, dopt, dopt2)
//--------------
// Normalize 2D image array by Avg (or Max) X (or Y) line in image
	string img, nrm
	variable method, indx, dopt=2, dopt2=1
	prompt img, "Image to normalize",popup,ImageNameList("",";")
	prompt nrm, "Output name [blank=*_nrm]"
	prompt method, "Divide by line profiles'",popup, "Avg;Max;"
	prompt indx, "Line direction",popup, "Y;X"
	prompt dopt, "Display new Image", popup, "No;Yes"
	prompt dopt2, "Display normalization array", popup, "No;Yes"

	indx-=1
	string avgnm=img+"_av"+num2istr(indx)
	if (strlen(nrm)==0) 
		nrm=img+"_nrm"+num2istr(indx)
	endif
	variable np
	if (method==1)
		np=AVGIMG($ img, indx, avgnm)
	else
		np=MAXIMG($ img, indx, avgnm)
	endif
	//print np
	duplicate/o $img $nrm
	string cmd=nrm+"="+img+"/("+avgnm
	if (indx==1)
		cmd+="[q]+1E-6)"
		//$nrm=$img/($avgnm[q]+.01)
	else
		cmd+="[p]+1E-6)"
		//$nrm=$img/($avgnm[p]+.01)
	endif
	//print cmd
	execute cmd
	
	if (dopt==2)
		string titlestr=nrm+": "+"YX"[indx-1]+" normalized, /avg along " +"XY"[indx-1]
		DoWindow/F $(nrm+"_")
		if (V_flag==0)
			display; appendimage $nrm
			ModifyGraph mirror=2
			ModifyImage $nrm ctab= {*,*,YellowHot,0}
			DoWindow/C $(nrm+"_")
		else
			Textbox/K/N=title
		endif
		Textbox/N=title/F=0/A=MT/E titlestr
	endif
	
	if (dopt2==2)
		display $avgnm
	endif
End

Function AvgImg( img, indx, outw)
//=================
// returns 1D average of profiles of image in specified direction: 0=X, 1=Y
	wave img
	variable indx
	string outw
	
	variable nx=DimSize(img, 0), ny=DimSize(img,1)
	variable ii
	if (indx==0)
		make/o/n=(nx) $outw
		WAVE avg=$outw
		DO
			avg+=img[p][ii]
			ii+=1
		WHILE(ii<ny)
		avg/=ny
	else
		make/o/n=(ny) $outw
		WAVE avg=$outw
		DO
			avg+=img[ii][p]
			ii+=1
		WHILE(ii<nx)
		avg/=nx
	endif

	SetScale/P x DimOffset(img,indx), DimDelta(img,indx),WaveUnits(img,indx) avg
	return nx*(indx==0)+ny*(indx==1)
End

Function MaxImg( img, indx, outw)
//=================
// returns 1D Maximum of line profiles of image in specified direction: 0=X, 1=Y
	wave img
	variable indx
	string outw
	
	variable nx=DimSize(img, 0), ny=DimSize(img,1)
	NewDataFolder/O root:tmp
	variable ii=0
	if (indx==0)
		make/o/n=(nx) $outw
		make/o/n=(ny) root:tmp:yline
		WAVE maxw=$outw, yline=root:tmp:yline
		DO
			yline=img[ii][p]
			WaveStats/Q yline
			maxw[ii]=V_max
			ii+=1
		WHILE(ii<nx)
	else
		make/o/n=(ny) $outw
		make/o/n=(nx) root:tmp:xline
		WAVE maxw=$outw, xline=root:tmp:xline
		DO
			xline=img[p][ii]
			WaveStats/Q xline
			maxw[ii]=V_max
			ii+=1
		WHILE(ii<ny)
	endif

	SetScale/P x DimOffset(img,indx), DimDelta(img,indx),WaveUnits(img,indx) maxw
	return nx*(indx==0)+ny*(indx==1)
End

Function/C ReinterpImg(img, xscal, yscal, outimgn)
//=================
// Reinterpolation of 2D image using interp2D (requires MDinterpolator Igor Extension)
// -- interpolation to smaller dimensions is allowed
// -- overwriting of original is allowed
	wave img
	variable xscal, yscal
	string outimgn
	
	string imgn=NameOfWave(img)
	variable eps=1e-9

	if ((xscal==1)*(yscal==1))		//skip interpolation if 1x1 rebinning
		if (stringmatch(imgn, outimgn)==0)			//output name not equal to input name
			Duplicate/O img $outimgn
		endif
	else
		NewDataFolder/O root:tmp
		variable nx=DimSize(img,0), ny=DimSize(img,1)
		variable nx2=round(xscal*nx), ny2=round( yscal*ny )
		Make/O/N=(nx2, ny2) root:tmp:imgtmp
		WAVE imgtmp=root:tmp:imgtmp
		
		variable x1= DimOffset(img,0), y1= DimOffset(img,1)
		variable x2=x1+(nx-1)*DimDelta(img,0), y2=y1+(ny-1)*DimDelta(img,1)
		y2+=1E-6*(y2<y1)
		SetScale/I x  x1+eps, x2-eps, "" imgtmp
		SetScale/I y  y1+eps, y2-eps, "" imgtmp
		imgtmp=interp2D( img, x, y )		//requires MDinterpolator Igor Extension
		//print x1, x2, y1, y2
		
		Duplicate/O imgtmp $outimgn
	endif
	return cmplx( nx2, ny2 )
End



Proc FilterImg(img,  typ, nrm,dopt,npt, npass)
//--------------
// Divide or subtract image by smoothed version of image
	string img, nrm
	variable npt=5, npass=5, typ=1, dopt
	prompt img, "Image to filter",popup,ImageNameList("",";")
	prompt nrm, "Output name [blank=*_rat,_dif]"
	prompt typ, "Enhancement",popup, "Ratio; Difference"
	prompt npt, "N-point smoothing [3,5,..]",popup, " ; ;3; ;5; ;7"
	prompt npass, "# passes"
	prompt dopt, "Display Image", popup, "Yes;No"
	
	PauseUpdate; Silent 1
	string smo=img+"_sm"
	if (strlen(nrm)==0) 
		if (typ==1)
			nrm=img+"_rat"
		else
			nrm=img+"_dif"
		endif
	endif
	
	duplicate/o $img $smo, $nrm
	MatrixFilter/N=(npt)/P=(npass) avg $smo
	if (typ==1)
		$nrm=$img/$smo
	else
		$nrm=$img-$smo
	endif
	
	if (dopt==1)
		string titlestr=nrm+": HighPass Filter, I"+"/-"[typ-1]+"<I,"+num2istr(npt)+","+num2istr(npass)+">"
		DoWindow/F $(nrm+"_")
		if (V_flag==0)
			display; appendimage $nrm
			ModifyGraph mirror=2
			if (typ==1)
				ModifyImage $nrm ctab= {0.9,1.1,YellowHot,0}
			else
				ModifyImage $nrm ctab= {*,*,YellowHot,0}
			endif
			DoWindow/C $(nrm+"_")
		else
			Textbox/K/N=title
		endif
		Textbox/N=title/F=0/A=MT/E titlestr
	endif
End

Function/C ExtractImg( newimgnam )
//==================
//copy subset of image (using marquee or graph axes) to new image
//rounds actual marquee or axis limits to nearest pixel value
//hence no interpolation,but uses interp2D
	string newimgnam
	
//determine image in top graph
	string imgnam=imagenamelist("",",")
	imgnam=imgnam[0,strlen(imgnam)-2]
	WAVE img=ImageNameToWaveRef("", imgnam )
	
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
	//print x1,x2,y1,y2
	
	//Duplicate carries along dependencies
	//Duplicate/O/R=(x1,x2)(y1,y2) img, $newimgnam
	
	variable p1=x2pnt(img,x1), p2=x2pnt(img,x2)
	variable q1=round( (y1-DimOffset(img,1))/DimDelta(img,1) )
	variable q2=round( (y2-DimOffset(img,1))/DimDelta(img,1) )
	variable nx=abs(p2-p1)+1, ny=abs(q2-q1)+1
	
	Make/O/N=(nx,ny) $newimgnam
	WAVE newimg=$newimgnam
	
	x1=pnt2x(img,p1)
	x2=pnt2x(img,p2)
	y1=DimOffset(img,1)+q1*DimDelta(img,1)
	y2=DimOffset(img,1)+q2*DimDelta(img,1)
	//print x1,x2,y1,y2
	SetScale/I x x1,x2,WaveUnits(img,0) newimg
	SetScale/I y y1,y2,WaveUnits(img,1) newimg
	//newimg=img[p+p1][q+q1]
	newimg=interp2D(img, x, y)		//requires MDinterpolator Igor Extension
	
	//return CMPLX( DimSize(newimg, 0), DimSize(newimg, 1) )
	return CMPLX(nx, ny)
End


Proc ReGridXY( imgn, outn, xwn, ywn, xrng, yrng,  dopt )  
//---------------
// Reinterpolate image to to specifed uniform grid X, Y ranges (marquee box option)
// No marquee selection; reinterpolates entire image 
	string imgn, outn=StrVarOrDefault( "root:tmp:outgrid", "_2")
	string xwn=ImgAxisNam("","",0), ywn=ImgAxisNam("","",1) 
	variable dopt=1
	string xrng=ImgRange(0), yrng=ImgRange(1)
	prompt imgn, "Image vs X,Y to convert", popup, WaveList("*", ";", "WIN:,DIMS:2")
	prompt outn, "Output image name or extension (_2)"
	prompt xrng, "output X range (min,max,inc)"
	prompt yrng, "ouput Y range (min,max,inc)"
	prompt xwn, "Image X-axis, ()=none"
	prompt ywn, "Image Y-axis ()=none"
	prompt dopt, "Display new plot", popup, "Yes;No"
	
	NewDataFolder/O root:tmp
	string/G root:tmp:outgrid=outn
	PauseUpdate;Silent 1
	
//Check for marquee; subset selection of image
// obtained from ImgRange() function
	variable nx0=DimSize ($imgn, 0 ), ny0=DimSize( $imgn, 1)
	variable x1, x2, xinc, nx, y1, y2, yinc, ny
	if (strlen(xrng)>0)
		x1=ValFromList(xrng, 0,",")
		x2=ValFromList(xrng, 1,",")
		xinc=ValFromList(xrng, 2,",")
	else					//use full range of image // uses x/y waves??
		x1=$xwn[0]
		x2=$xwn[nx0-1]
		xinc=(x2-x1)/(nx0-1)
	endif
	nx=round( (x2-x1)/xinc + 1)
		
	if (strlen(yrng)>0)
		y1=ValFromList(yrng, 0,",")
		y2=ValFromList(yrng, 1,",")
		yinc=ValFromList(yrng, 2,",")
	else					//use full range of image
		y1=$ywn[0]
		y2=$ywn[ny0-1]
		yinc=(y2-y1)/(ny0-1)
	endif
	ny=round( (y2-y1)/yinc + 1)
	print x1, x2, xinc, nx
	print y1, y2, yinc, ny
	//*** add or subtract epsilon to  x/y limits to prevent interpolation to Nan when outside range
	//*** check precisely limits of x/y axis waves and selected range
	
// Create new image & polar/elev arrays	; set Kx-Ky regular grid scaling
	if (cmpstr(outn[0], "_")==0)
		outn=imgn+outn
	endif	
	Make/O/N=(nx, ny) $outn
	Setscale/I x x1, x2, "" $outn
	Setscale/I y y1, y2, "" $outn
	print "Created: ", outn, "(", nx, "x", ny, ") Æxy=", xinc, yinc

// Copy source image & remove any x-y scaling	
	Duplicate/O $imgn, root:tmp:im
	//Duplicate/O/R=(x1,x2)(y1,y2) $imgn, root:tmp:im   //image not scaled
	SetScale/P x 0,1,"" root:tmp:im			// remove point scaling
	SetScale/P y 0,1,"" root:tmp:im
	
// Create N-point X and Y arrays for interpolation from display N+1 X and y axis waves
	if (nx0!=AXISW( $xwn, "root:tmp:imgxw", -1))
		abort "Mismatch in X-axis wave dimensions!"
	endif
	if (ny0!=AXISW( $ywn, "root:tmp:imgyw", -1))
		abort "Mismatch in Y-axis wave dimensions!"
	endif
	//*** check precisely limits of x/y axis waves and selected range to identify interp probelms
	//print x1,  
	
//Create point arrays for interpolation
	Make/o/N=(nx0) root:tmp:pxw=p
	Make/o/N=(ny0) root:tmp:pyw=p

// Calculate fractional point values (optional)
//	Make/o/N=(nx0) xxx=interp(x, root:tmp:imgxw, root:tmp:pxw)
//	Make/o/N=(ny0) yyy=interp(x, root:tmp:imgyw, root:tmp:pyw)
//	$outn=interp2D( root:tmp:im, pxw_x), pyw_y )
//	all in one interpolation command without intermediate array;
//  interp2D requires MDinterpolator Igor Extension
	$outn=interp2D( root:tmp:im, interp(x, root:tmp:imgxw, root:tmp:pxw), interp(y, root:Tmp:imgyw, root:tmp:pyw) )
	
	if (dopt==1)
		// get color table info from top graph(?)
		string CTstr=ColorTableStr("", imgn)		//may not work if not proper top graph
		display; appendimage $outn
		//ModifyGraph width={Plan,1,bottom,left}
		Label bottom "Kx (1/)"
		Label left "Ky (1/)"
		string titlestr="\JC"+outn+": "+num2str(nx)+" x "+num2str(ny)
		Textbox/N=title/F=0/A=MT/E titlestr
		//worry about changes w/o display
		if (strlen(CTstr)>0) 
			execute "ModifyImage "+outn+" "+CTstr
		else
			string ctable=imgn+"_CT"
			if (exists(ctable)==0)
				//ctable="YellowHot"
				ModifyImage $outn ctab= {*,*,YellowHot,0}
			else
				ModifyImage $outn cindex=$ctable
			endif
		endif
	endif

End



//Proc JEG_ZapColorLegendControls(legendName)
//====================
	//Variable	killControls
//	String		legendName
//	Prompt legendName, "Color legend to remove: ", popup JEG_ColorLegendList("",";")
	
//	String legendPath = "root:Packages:'JEG Color Legend':" + legendName
	
//	String dfSav = GetDataFolder(1)
//	SetDataFolder $legendPath
	
		// Kill controls

//		ControlBar 0
//		KillControl $("upper_" + legendName)
//		KillControl $("lower_" + legendName)
//		KillControl $("full_" + legendName)
//		KillControl $("color_" + legendName)
//		KillControl $("reverse_" + legendName)
//		KillControl $("scale_" + legendName)
//		KillControl $("zeroUpper_" + legendName)
//		KillControl $("zeroLower_" + legendName)
//		KillControl $("delete_" + legendName)
		
	
//	SetDataFolder dfSav
//End


Function/S ShiftImg( img, shiftw, opt)
	wave img, shiftw
	string opt
	return ImgShift( img, shiftw, opt)
end

Function/S ImgShift( img, shiftw, opt)
//=================
// Subtraction shifts image according to specified wave (subtraction)
// Options:
//    Shift wave: /XW=x_shiftwn or /XW - shift_x  (default=scaled shift wave)
//    Direction:  /Y - yaxis shift (default=xaxis)
//    Output:     img_sx or img_sy   (default suffix), or 
//                     /D=outwn,  /D=+suffix, /D=_suffix  (specify fullname or just suffix)
//                     /O (overwrite original image)
//    Output dimension:  /E=expand  (-1=shrink, 0=avg, 1=expand)
//
	wave img, shiftw
	string opt
	
	string imgn=NameOfWave(img), shiftn=NameOfWave(shiftw)
// axis to shift:
	variable idir=SelectNumber(KeySet("Y",opt), 0, 1)		//0=X , 1=Y
// shift wave scaling
	variable V_scaled=SelectNumber(KeySet("XW",opt), 1, 0)	//0=xwave, 1=scaled
	string shiftxn=KeyStr("XW",opt)
	shiftxn=SelectString(strlen(shiftxn)==0, shiftxn, shiftn+"_x")
// axis range expansion  (-1, 0, 1)
	variable V_expand=SelectNumber(KeySet("E",opt), 1, KeyVal("E",opt) )		//1=default
	V_expand=SelectNumber(numtype(V_expand)==0, 1, V_expand) 
	
//output image
//	string newimgn=KeyStr("D", opt)
	string newimgn=OutputName( imgn, KeyStr("D", opt), "_s"+"xy"[idir] )
	variable overwrite=KeySet("O", opt)+stringmatch(imgn,newimgn)
//	if ((strlen(newimgn)==0)+overwrite)
//		newimgn=imgn+"_s"+"xy"[idir]
//	endif
	
// original image parameters:
	variable nx0, xmin0, xmax0, xinc0
	variable ny0, ymin0, ymax0, yinc0
	nx0=DimSize(img, 0); 	ny0=DimSize(img, 1)
	xmin0=DimOffset(img,0);  ymin0=DimOffset(img,1);
	xinc0=round(DimDelta(img,0) * 1E6) / 1E6	
	yinc0=round(DimDelta(img,1)* 1E6) / 1E6
	xmax0=xmin0+xinc0*(nx0-1);	ymax0=ymin0+yinc0*(ny0-1);

// shift wave stats
	variable nx, xmin, xmax, xinc
	variable ny, ymin, ymax, yinc
	string size=StringFromList( V_expand+1, "shrink;avg;expand")
	
	if (idir==0)		// X
		RangeAfterShift( shiftw, V_expand, xmin0, xmax0, xmin, xmax )  //=> xmin, xmax 
		nx=round((xmax-xmin)/xinc0)+1
		xmax=xmin+xinc0*(nx-1)
		//print "x "+size+": ", xmin, xmax, nx
		ny=ny0;  ymin=ymin0
	else  // Y
		RangeAfterShift( shiftw, V_expand, ymin0, ymax0, ymin, ymax )  //=> ymin, ymax 
		ny=round((ymax-ymin)/yinc0)+1
		ymax=ymin+yinc0*(ny-1)
		//print "y "+size+": ", ymin, ymax, ny
		nx=nx0;  xmin=xmin0
	endif
	
	//create output image
	Make/O/N=(nx,ny) $newimgn
	WAVE newimg=$newimgn
	SetScale/P x xmin, xinc0,WaveUnits(img,0) newimg
	SetScale/P y ymin, yinc0,WaveUnits(img,1) newimg

	//generate low-level command
	string cmd=newimgn+"=interp2D("+imgn+", x"
	if (idir==0)
		cmd+=SelectString(V_scaled, "+interp(y,"+shiftxn+","+shiftn+")" , "+"+shiftn+"(y)")
		cmd+=",y )"
	else
		cmd+=", y"
		cmd+=SelectString(V_scaled, "+interp(x,"+shiftxn+","+shiftn+"))" , "+"+shiftn+"(x))")
	endif

	//******** low-level interpolation
	if (V_scaled)
		if (idir==0)
			newimg=interp2D(img, x+shiftw(y), y)		
		else
			newimg=interp2D(img, x, y+shiftw(x))	
		endif
	else
		WAVE shiftx=$shiftxn
		if (idir==0)
			newimg=interp2D(img, x+interp(y, shiftx, shiftw), y)		
		else
			newimg=interp2D(img, x, y+interp(x, shiftx, shiftw))	
		endif
	endif
	//********	
	
	if (overwrite)
		Duplicate/O newimg, img
		Killwaves/Z newimg
		newimgn=NameOfWave(img)
	endif

	if (KeySet("P",opt))		//optional new plot
		Display; appendimage newimg
	endif
	
	return cmd
End

Proc DeglitchImg(imgn,  typ, outn,dopt,nline, npass, roi)
//--------------
	string imgn, outn="/O"
	variable nline=Nan, npass=1, typ=1, dopt
	string roi=ImgRange(0,"blank")+","+ImgRange(1,"blank")
	prompt imgn, "Image to deglitch",popup,ImageNameList("",";")
	prompt outn, "Output name [/O=overwrite, blank=*_dg]"
	prompt typ, "Glitch Type",popup, "Point 4-pt XY avg;Point X avg;Point Y avg;Column;Row;Auto-Line"
	prompt nline, "specific column/row number (blank=auto)"
	prompt npass, "# passes"
	prompt dopt, "Display New Image", popup, "No;Yes"
	prompt roi, "Region of interest (blank=full range)"
	
	PauseUpdate; Silent 1
	string opt=""
	
	// Possibly defined ROI from marquee on top graph
	//GetMarquee/K left, bottom
	//if (V_Flag==1)
	//	opt="/ROI="+num2str(V_left)+","++num2str(V_right)+","++num2str(V_bottom)+","++num2str(V_top)
	//endif
	if (strlen(roi)>2))
		opt="/ROI="+roi
	endif

	// output name
	if (stringmatch(outn, "/O")==1)
		opt+=outn
	else
	if (strlen(outn)>0)
		opt+="/D="+outn
	endif
	endif
	
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
	
	variable ii=0
	DO
		opt+=SelectString((dopt==2)*(ii==npass-1), "", "/P")
		print ImgDeglitch( $imgn, opt)
		ii+=1
	WHILE(ii<npass)
	
	// plot option
	//opt+=SelectString(dopt==2, "", "/P")
	//print opt
	//print ImgDeglitch( $imgn, opt)
End

Function/S ImgDeglitch( img, opt)
//=================
// Remove Glitch point or line from image by averaging neighbor points
// Determine Glitch POINT location from Maximum value point
// Options:
//    Method:   /A=#  (default=1) Auto-detect # of spikes (multiple passes) 
//           /XL, /YL  (auto-detect line glitch)
//           /XL=nx, /YL=ny  (specified line #)
//           /X, /Y, /XY (default)  - average along X or Y or 4-pt XY
//     Region of Interest (ROI):
//	    /ROI =x0,x1, y0,y1    (default = full image range)  
//    Output:      img_dg (default), or /D=outwn, or /O (overwrite)
//
	wave img
	string opt
	
	string imgn=NameOfWave(img)
//average direction:
	variable avgdir=2
	   	avgdir=SelectNumber(KeySet("X",opt), avgdir, 0)		//0=X , 1=Y, 2=XY
	   	avgdir=SelectNumber(KeySet("Y",opt), avgdir, 1)
// complete line deglitch
	variable lindir=2, linenum=nan
	   	lindir=SelectNumber(KeySet("XL",opt), lindir, 0)		//0=X , 1=Y, -1=X or Y (auto-detect)
	   	lindir=SelectNumber(KeySet("YL",opt), lindir, 1)	
	   	lindir=SelectNumber(KeySet("L",opt), lindir, -1)	

//output image
	string newimgn=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(imgn,newimgn)
	if ((strlen(newimgn)==0)+overwrite)
		newimgn=imgn+"_dg"
	endif
	
//create output image
	if (overwrite)			//Operate on original
		//Duplicate/O newimg, img
		//Killwaves/Z newimg
		newimgn=NameOfWave(img)     //GetWavesDataFolder( img, 4 )
	else
		Duplicate/O img $newimgn 
	endif
	WAVE newimg=$newimgn
	
//generate low-level command
	string cmd=newimgn
	

	if (lindir==0)
		linenum=KeyVal("XL",opt)
	endif
	if (lindir==1)
		linenum=KeyVal("YL",opt)
	endif
// If specific line or pixel not specifiec (auto) then find glitch by:
	if (numtype(linenum)==2)		//nan  --> auto find

// Highlight glitch by subtracting smoothed image from original	
		NewDataFolder/O root:tmp
		Duplicate/O img root:tmp:img_dif
		WAVE img_dif= root:tmp:img_dif
		ImageFilter/N=3 avg img_dif
		img_dif = img[p][q] - img_dif[p][q]

		variable px=nan, py=nan, av
		
		string roi=KeyStr("ROI", opt)
		if (strlen(roi)>0)
			execute "ImageStats/GS={"+roi+"} root:tmp:img_dif"
			print "ImageStats/GS={"+roi+"} root:tmp:img_dif"
			//print V_maxRowLoc, V_maxColLoc
		else
			//Wavestats img_dif		// V_MaxRowLoc in scaled units
			//px=(V_MaxRowLoc - DimOffset(img, 0))/DimDelta(img,0)
			//py=(V_MaxColLoc - DimOffset(img, 1))/DimDelta(img,1)
			execute "ImageStats root:tmp:img_dif"
			//ImageStats img_dif		// V_MaxRowLoc in pixels
		endif
		NVAR MaxRowLoc =V_MaxRowLoc , MaxColLoc=V_MaxColLoc
		px=MaxRowLoc ;  py=MaxColLoc
		//print px, py
	endif
	
//line deglitch
	if (lindir<2)
		if (lindir== -1)		// figure out if a row or column
			ImgAvg( img_dif, "/X/D=root:tmp:avgrow" )			//sum along Y
			ImgAvg( img_dif, "/Y/D=root:tmp:avgcol" )			//sum along X
			WAVE avgrow=root:tmp:avgrow, avgcol=root:tmp:avgcol
			variable rowmax, colmax
			WaveStats/Q avgrow; rowmax=V_max
			Wavestats/Q avgcol; colmax=V_max
			lindir=SelectNumber( colmax > rowmax, 0, 1 )
			//recompute px or py from WaveStats rather than relying on img_dif stats
		endif
	
		if (lindir==0)	//X
			//linenum=KeyVal("XL",opt)
			if (numtype(linenum)==2)		//nan
				linenum=px
			endif
			cmd=newimgn+"["+num2str(linenum)+"][]=0.5*("
			cmd+=imgn+"["+num2str(linenum-1)+"][q] + "+imgn+"["+num2str(linenum+1)+"][q])"
			newimg[linenum][]=0.5*(img[linenum-1][q] + img[linenum+1][q] ) 
		else  	//lindir=1, Y
			//linenum=KeyVal("YL",opt)
			if (numtype(linenum)==2)		//nan
				linenum=py
			endif
			cmd=newimgn+"[]["+num2str(linenum)+"]=0.5*("
			cmd+=imgn+"[p]["+num2str(linenum-1)+"] + "+imgn+"[p]["+num2str(linenum+1)+"])"
			newimg[][linenum]=0.5*(img[p][linenum-1] + img[p][linenum+1] ) 
		endif
		//print "py=", linenum, img[px][py], newimg[px][py]
		
// point deglitch
	else
//		Wavestats/Q img
//		px=(V_MaxRowLoc - DimOffset(img, 0))/DimDelta(img,0)
//		py=(V_MaxColLoc - DimOffset(img, 1))/DimDelta(img,1)
		
		cmd=newimgn+"["+num2str(px)+"]["+num2str(py)+"]="
		//perfrom average of neighboring points (worry about edges?)
		switch (avgdir)
		case 0:		//X
			cmd+="0.5*("+imgn+"["+num2str(px-1)+"]["+num2str(py)+"] "
			cmd+="+ "+imgn+"["+num2str(px+1)+"]["+num2str(py)+"])"
			//newimg[px][py]=0.5*(img[px-1][py] + img[px+1][py] ) 			//doesn't work
			execute newimgn+"["+num2str(px)+"]["+num2str(py)+"]="+num2str(av)
			print img[px-1][py], img[px][py] ,  img[px+1][py] , av, newimg[px][py]
			break
		case 1:	       //Y
			cmd+="0.5*("+imgn+"["+num2str(px)+"]["+num2str(py-1)+"] "
			cmd+="+ "+imgn+"["+num2str(px)+"]["+num2str(py+1)+"])"
			newimg[px][py]=0.5*(img[px][py-1] + img[px][py+1] ) 
			//newimg[px][py]=0.5*(img[p][q-1] + img[p][q+1] )
			print img[px][py-1], img[px][py] ,  img[px][py+1], newimg[px][py]
			break
		case 2:		//4-pt XY
			cmd+="0.25*("+imgn+"["+num2str(px-1)+"]["+num2str(py)+"] "
			cmd+="+ "+imgn+"["+num2str(px+1)+"]["+num2str(py)+"] "
			cmd+="+ "+imgn+"["+num2str(px)+"]["+num2str(py-1)+"] "
			cmd+="+ "+imgn+"["+num2str(px)+"]["+num2str(py+1)+"])"
			newimg[px][py]=img4ptavg( img, px, py )
			//newimg[px][py]=0.25*(img[px-1][py] + img[px+1][py] +img[px][py-1] + img[px][py+1] ) 
		endswitch
//		execute cmd 
		
		//print px, py, V_max, newimg[px][py], avgdir
	endif
	
	
	//if (overwrite)
	//	Duplicate/O newimg, img
	//	Killwaves/Z newimg
	//	newimgn=NameOfWave(img)
	//endif

	if (KeySet("P",opt))		//optional new plot
		Display; appendimage newimg
	endif
	
	return cmd
End

function img4ptavg( img, px, py )
//==============
	wave img
	variable px, py
	return 0.25*(img[px-1][py] + img[px+1][py] +img[px][py-1] + img[px][py+1] ) 
end


function/S RangeAfterShift( shiftw, mode, min0, max0, min1, max1 )
//=====================
// pass-by-reference changes min1, max1
	wave shiftw
	variable mode, min0, max0, &min1, &max1
	WaveStats/Q shiftw
	switch (mode)
	case 1:		//expand
		min1=min0-V_max
		max1=max0-V_min
		break
	case -1:	//shrink
		min1=min0-V_min 	//+(V_max-V_min)
		max1=max0-V_max 	//-(V_max-V_min)
		break
	case 0:		//avg
		min1=min0-V_avg
		max1=max0-V_avg
	endswitch
	
	if (min1>max1)
		switchval(min1,max1)
	endif
	return num2str(min1)+","+num2str(max1)
end

Function/S ImgRotate( img, ang, opt)
//=================
// Rotates image by specified angle (degrees)
// Options:
//    Output:      img_r (default), or /D=outw, or /O (overwrite)
//    Outside domain value:  Nan (default of inter2D)
//    Output size:  /F (fixed axes, no resize) (default=recalculate expanded) 
//    Method:  /M=num  (1=Igor ImageRotate+duplicate; 2= ImageRotate / Overwrite; 3=interp2D, 4= ER dorotate)
//    Rotation center:   /C=x0,y0  (default = "0,0")  -- works for method 3 only so far
//         +RangeAfterRotation not aware of center shift(?)
//
	wave img
	variable ang
	string opt
	
	string imgn=NameOfWave(img)
		// axis range expansion  (-1, 0, 1)
	variable newaxes=SelectNumber(KeySet("F",opt), 1, 0 )		//1=default
		//V_expand=SelectNumber(numtype(V_expand)==0, 1, V_expand) 
	//output image
	string newimgn=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(imgn,newimgn)
	if ((strlen(newimgn)==0)+overwrite)
		newimgn=imgn+"_rot"
	endif
	
// rotation center
	string rotctr=KeyStr("C", opt )
	variable rotctr_x=NumFromList( 0, rotctr, ","), rotctr_y=NumFromList( 1, rotctr, ",")
	rotctr_x=SelectNumber( numtype(rotctr_x)==2, rotctr_x, 0 )			// 0 if Nan
	rotctr_y=SelectNumber( numtype(rotctr_y)==2, rotctr_y, 0 )			// 0 if Nan
	print rotctr_x, rotctr_y
	
// original image parameters:
	variable nx0, xmin0, xmax0, xinc0
	variable ny0, ymin0, ymax0, yinc0
	nx0=DimSize(img, 0); 	ny0=DimSize(img, 1)
	xmin0=DimOffset(img,0);  ymin0=DimOffset(img,1);
	xinc0=round(DimDelta(img,0) * 1E6) / 1E6	
	yinc0=round(DimDelta(img,1)* 1E6) / 1E6
	xmax0=xmin0+xinc0*(nx0-1);    ymax0=ymin0+yinc0*(ny0-1)

// offset original image by desired rotation center	
	if ( (rotctr_x!=0)*(rotctr_y!=0) )
		xmin0=xmin0 - rotctr_x
		ymin0=ymin0 - rotctr_y
		SetScale/P x xmin0, xinc0, img
		SetScale/P y ymin0, yinc0, img
	endif

// determine output image range; keep increments constant
	variable nx, xmin, xmax
	variable ny, ymin, ymax
	
	string cmd
	variable method=SelectNumber( KeySet("M",opt), 3, KeyVal("M", opt))	
		
	// 1=Igor ImageRotate+duplicate; 2= ImageRotate / Overwrite; 3=interp2D, 4= ER dorotate
	variable tnum=StartMSTimer
	switch( method )
		//intensity offset introduced by ImageRotate??
		//  angle>0 is CCW contrary to help file  (Igor v4 - check v5)
	case 1:
		ang=-ang
		print ang
		cmd="ImageRotate/S/A="+num2str(ang)+" "+imgn
		execute cmd
		//ImageRotate/S/A=(ang) img			//  option /S requires >Igor 4.07
		//ImageRotate/A=(-ang)/E=(Nan) img			// output=M_RotatedImage
		//Duplicate/O M_Rotatedimage $newimgn
		//Rename	M_Rotatedimage newimg		//cannot overwrite if newimg exists
		//execute "Rename M_Rotatedimage "+newimgn
		cmd+="; Duplicate/O M_Rotatedimage "
		if (overwrite)
			Duplicate/O M_Rotatedimage, img
			cmd+=imgn
			newimgn=imgn
		else
			Duplicate/O M_Rotatedimage $newimgn
			cmd+=newimgn
		endif
		WAVE newimg=$newimgn
		break
	case 2:
		cmd="ImageRotate/S/A="+num2str(ang)
		if (overwrite)
			ImageRotate/S/O/A=(ang) img			  //overwrite original
			newimgn=imgn
			cmd+="/O"
		else
			Duplicate/O img $newimgn
			WAVE newimg=$newimgn
			ImageRotate/S/O/A=(ang)/E=(Nan) newimg		 // overwrite duplicate
		endif
		cmd+=" "+imgn
		break
	case 3:
		// newaxes=0 calculates for zero angle rotation
		RangeAfterRotation(ang*newaxes, xmin0, xmax0, ymin0, ymax0, xmin, xmax, ymin, ymax)
		nx=round((xmax-xmin)/xinc0)+1
		xmax=xmin+xinc0*(nx-1)
			//print "x expand: ", xminr, xmaxr, nxr
		ny=round((ymax-ymin)/yinc0)+1
		ymax=ymin+yinc0*(ny-1)
			//print "y expand: ", yminr, ymaxr, nyr
		
		// create output image
		Make/O/N=(nx,ny) $newimgn
		WAVE newimg=$newimgn
		SetScale/P x xmin, xinc0,WaveUnits(img,0) newimg
		SetScale/P y ymin, yinc0,WaveUnits(img,1) newimg
	
		//generate low-level command (degrees)
		cmd=newimgn+"=interp2D("+imgn
			cmd+=", rot_x( x, y, "+num2str(-ang)+")"
			cmd+=", rot_y( x, y, "+num2str(-ang)+") )"
		
		//execute rotated interpolation
		variable angrad=ang*pi/180
		newimg=interp2D(img, rot_x( x, y, -angrad), rot_y( x, y, -angrad))	
		
		// correct by rotation center	
		if ( (rotctr_x!=0)*(rotctr_y!=0) )
			xmin=xmin + rotctr_x
			ymin=ymin + rotctr_y
			SetScale/P x xmin, xinc0, newimg
			SetScale/P y ymin, yinc0, newimg
		endif
		
		if (overwrite)
			Duplicate/O newimg, img
			Killwaves/Z newimg
			newimgn=imgn
		endif	
		break
	case 4:      	// ER ImageTool v4.026 "dorotate" method 
		// rotate about avg center coordinate; output has same axis as input, e.g. /F behavior
		//use intermediate X,Y arrays => 5-6% faster than method 3
		duplicate/o img, $newimgn, xp, yp
		WAVE newimg=$newimgn, xp=xp, yp=yp
		variable ar=ang*pi/180
		variable xav=dimoffset(img,0) + dimdelta(img,0)*dimsize(img,0)/2
		variable yav=dimoffset(img,1) + dimdelta(img,1)*dimsize(img,1)/2
		xp=xav + cos(ar)*(x-xav) - sin(ar)*(y-yav)
		yp=yav + sin(ar)*(x-xav) + cos(ar)*(y-yav)

		newimg=interp2d(img, xp, yp)
		//newimg=img(xp)(yp)  //fast, inaccurate
		//duplicate/o img2 img
		if (overwrite)
			Duplicate/O newimg, img
			Killwaves/Z newimg
			newimgn=imgn
		endif
		Killwaves/Z xp, yp	
		cmd = "doRotate("+imgn+","+num2str(ang)+")"
	
	endswitch
	print "Method=", method, ",", StopMSTimer( tnum )*1E-3, " ms"
	
	// put back offset of original image by desired rotation center	
	if ( (rotctr_x!=0)*(rotctr_y!=0) )
		xmin0=xmin0 + rotctr_x
		ymin0=ymin0 + rotctr_y
		SetScale/P x xmin0, xinc0, img
		SetScale/P y ymin0, yinc0, img
	endif
	
	// optional new plot
	if (KeySet("P",opt))
		Display; appendimage newimg
		//use colortable?
	endif
	//print cmd
	return cmd
End

//ER function
//function rotate_XY(angrad, x, y, xr, yr)
//=====================
// pass-by-reference changes xr, yr
//	variable angrad, x, y, &xr, &yr
//	xr=cos(angrad)*x+sin(angrad)*y
//	yr=-sin(angrad)*x+cos(angrad)*y
//end

Function rot_x( x, y, angrad)
	variable x, y, angrad
	//angrad*=pi/180
	return x*cos(angrad)+y*sin(angrad)
end

Function rot_y( x, y, angrad)
	variable x, y, angrad
	//angrad*=pi/180
	return -x*sin(angrad)+y*cos(angrad)
end

//ER function
function/S RangeAfterRotation(ang, xmin, xmax, ymin, ymax, xminr, xmaxr, yminr, ymaxr)
//=====================
// pass-by-reference changes ()r variables
	variable ang,xmin,xmax,ymin,ymax,&xminr,&xmaxr,&yminr,&ymaxr
	//four corners of image:  0=LL, 1=LR, 2=UR, 3=UL
	variable x0=xmin,x1=xmax,x2=xmax,x3=xmin
	variable y0=ymin,y1=ymin,y2=ymax,y3=ymax
	variable x0r,x1r,x2r,x3r
	variable y0r,y1r,y2r,y3r
	ang*=pi/180
	x0r=rot_x(x0,y0, ang);  y0r=rot_y(x0,y0, ang)
	x1r=rot_x(x1,y1, ang);  y1r=rot_y(x1,y1, ang)
	x2r=rot_x(x2,y2, ang);  y2r=rot_y(x2,y2, ang)
	x3r=rot_x(x3,y3, ang);  y3r=rot_y(x3,y3, ang)
	//rotate_XY(ang, x0,y0, x0r,y0r)
	//rotate_XY(ang, x1,y1, x1r,y1r)
	//rotate_XY(ang, x2,y2, x2r,y2r)
	//rotate_XY(ang, x3,y3, x3r,y3r)
	xminr=min(min(x0r,x1r),min(x2r,x3r))
	yminr=min(min(y0r,y1r),min(y2r,y3r))
	xmaxr=max(max(x0r,x1r),max(x2r,x3r))
	ymaxr=max(max(y0r,y1r),max(y2r,y3r))
	if (xmin>xmax)
		switchval(xminr,xmaxr)
	endif
	if (ymin>ymax)
		switchval(yminr,ymaxr)
	endif
	return num2str(xminr)+","+num2str(xmaxr)+", "+num2str(yminr)+","+num2str(ymaxr)
end

//ER function
function switchval(x,y)
	variable &x,&y
	variable temp
	temp=x
	x=y
	y=temp
end



Function DivideImg( imA, imB, imCn, optstr )
//================
//  creates imC = imA/imB
	wave imA, imB
	string imCn, optstr
	
	variable offA=0, offB=0
	Duplicate/O imA $imCn
	//variable nx=DimSize(imA,0), ny=DimSize(imA,1)
	//make/o/N=(nx, ny) $imCn
	Wave imC=$imCn
	Redimension/S  imC
	imC=(imA-offA)/(imB-offB)


End

Function TileImages1( winnam, nx, ny )
//==============
	string winnam
	variable nx, ny
	
	
End

function/S ImgConcat( imA, imB, opt )
//========================================
// append  image B to image A in either /X or /Y directions
// use offset & scaling of imA; ignore imB scaling
// Options:  
//    Output:      img_r (default), or /D=outw, or /O (overwrite)
//    Direction: /X (left-to-right), /Y (bottom-to-top)
//    Intensity rescaling:
//         /AZ=val, /BZ=val intensity rescaling for either A or B
//          /BZ=A - rescale <B> to <A> (<>=average), or /AZ=B
//           /M=method  1=built-in Igor Concatenate function
//          /P  - plot output image
	wave imA, imB
	string opt
	
	string imAn=NameOfWave(imA), imBn=NameOfWave(imB)
	// check validity/dimension of imA, imB
	if ((WaveDims(imA)!=2)+ (WaveDims(imB)!=2))
		return "ERROR (ImgConcat): input not 2D images"
	endif
	
	//determine output wave
	string newimgn=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(imAn,newimgn)+2*stringmatch(imBn,newimgn)
	if ((strlen(newimgn)==0)+overwrite) 
		newimgn=imAn+"_"+imBn
		newimgn=CleanUpName( newimgn, 1)		//correct  length if too long?
	endif
	
	
	variable spliceDir=KeySet("Y", opt)		// /X is default
	variable Cnx, Cny
	
	variable method=SelectNumber(KeySet("M", opt), 1, KeyVal("M", opt)	)	
	switch( method)				//  1=by hand, 2=built-in cmd,
	case 1:
		//intensity rescaling
		variable Ascl=SelectNumber(KeySet("AZ", opt), 1, KeyVal("AZ", opt))
		variable Bscl=SelectNumber(KeySet("BZ", opt), 1, KeyVal("BZ", opt))
		variable A_avg, B_avg
		if (stringmatch(KeyStr("BZ",opt),"A") )		//rescale B to match A average intensity
			Wavestats/Q imA
			A_avg=V_avg * Ascl
			Wavestats/Q imB
			B_avg=V_avg
			Bscl=A_avg/B_avg
		endif
		if (stringmatch(KeyStr("AZ",opt),"B") )		//rescale A to match B average intensity
			Wavestats/Q imB
			B_avg=V_avg * Bscl
			Wavestats/Q imA
			A_avg=V_avg
			Ascl=B_avg/A_avg
		endif
		Ascl=SelectNumber(numtype(Ascl==2), Ascl,1)  //extra validity check
		Bscl=SelectNumber(numtype(Bscl==2), Bscl,1)
		
		//New dimensions
		variable Anx=DimSize(imA,0), Any=DimSize(imA,1)

		if (splicedir==0)				// X
			Cnx=Anx+DimSize(imB,0)
			Cny=Any
		else								//Y
			Cnx=Anx
			Cny=Any+DimSize(imB,1)
		endif	
	
		//create output image, scale axes
		//imCnam=SelectString(strlen(imCnam)==0, imCnam, "tmp")
		Make/O/N=(Cnx, Cny) $newimgn
		WAVE imC=$newimgn
		SetScale/P x DimOffset(imA,0), DimDelta(imA,0), "" imC
		SetScale/P y DimOffset(imA,1), DimDelta(imA,1), "" imC
		
		// append point wise
		imC[0, Anx-1][0,Any-1] = Ascl*imA[p][q]
		if (splicedir==0)				// X
			imC[Anx,Cnx-1][0,Any-1] = Bscl*imB[p-Anx][q]
		else								//Y
			imC[0,Anx-1][Any,Cny-1] = Bscl*imB[p][q-Any]
		endif
		break
	case 2:
		if (splicedir==0)				// X
			MatrixTranspose ImA		//or duplicate to temporary intermediat images A', B'
			MatrixTranspose imB
			Concatenate/NP/O {imB, imA}, $newimgn    
			//WAVE imC=$newimgn
			MatrixTranspose $newimgn    //ImC
			MatrixTranspose imA
			MatrixTranspose ImB
		else								//Y
			Concatenate/NP/O {imB, imA}, $newimgn    //why have to reverse order??
		endif
		WAVE imC=$newimgn	
		Cnx=DimSize(imC,0)
		Cny=DimSize(imC,1)	
	
		break	
	endswitch
	
	if (overwrite)			//optional overwrite
		if (overwrite==2)
			Duplicate/O imC, imB
			newimgn=imBn
		else
			Duplicate/O imC, imA
			newimgn=imAn
		endif
		Killwaves/Z imC
	endif	
	
	if (KeySet("P",opt))		//optional new plot
		Display; appendimage imC
		// default; use imA colorTable  -- but imA needs to be plotted?
		// check for existence of "_CT" wave
		string CTnam=imAn+"_CT"
		print CTnam
		if (exists(CTnam)==1)
			//Modifyimage imC cindex=$CTnam		//or duplicate to imC_CT
			execute "Modifyimage "+newimgn+" cindex="+CTnam
		endif
	endif
	
	//return CMPLX(Cnx, Cny)		//return new dimensions
	return num2str(Cnx)+","+num2str( Cny)		//return new dimensions
end



Function Polar_Mask( image, opt) //MAX=maxx, MIN=minn, VALUE=val, $
//   PIXELS=pix, RAD=rn, PHIRANGE=phir
//==================================================
//Convert values within a square grid but outside 
//the convex hull (circle) of polar data points. The default is 0.0.
//if keyword_set(wh) then $
//    if wh then im =(im+max(im) * $
//      (1- (shift(dist(nps+1,nps+1),(nps+1)/2,(nps+1)/2) lt (nps+1)/2)) <max(ps) )
// Options:
//    
//on_error,2
	Wave image
	string opt
	
//s=size(image)
	variable nx=DimSize(image, 0), ny=DimSize(image,1)

//if s(0) ne 2 then message, 'Image not 2 dimensional'
//if s(1) ne s(2) then message, 'Image not square'

//create circular 2D mask
	// determine mask radius
	variable nr=(min(nx,ny)-1)/2
	variable rad=KeyVal("RAD", opt)
	rad=SelectNumber( numtype(rad)==0, 0, rad)
	rad=SelectNumber( rad>0, nr+rad, rad)
	
	// determine center
	variable cx=nx/2, cy=ny/2
	variable ctr=KeyVal("CTR", opt)
	
	//create mask
	make/o/n=(nx,ny) mask
	mask=( sqrt((p-cx)^2+(q-cy)^2) <rad )
	
//if keyword_set(pix) eq 0 then pix=0
//sh=shift( dist(s(1),s(1)), nr, nr )
//mask=sh+pix lt nr 	; 0 outside, 1 inside
//if keyword_set(rn) then mask = mask * (sh gt rn)

//;add azimuth range mask
//if keyword_set(phir) then begin
//   t=range2d(s(1),-1,1,polar=-1)
//   t=vrotate( t, 180+phir(0), /polar)
//   tt=reform(t(1,*,*))+180.+phir(0)    ; extract azimuth angle part [-180, 180]
//   ;tt=tt+360.*(tt<phir(0))
//   ;if phir(0) ge 0 then tt=(tt+360.) mod 360. ; convert to [0, 360]
//   mask=mask*(tt le phir(1)) * (tt ge phir(0))
//endif

//determine value of mask region
	variable value=Nan, val
	val=KeyVal("VAL", opt)
	value=SelectNumber(numtype(val)==0, Nan, val ) 
	//value=SelectNumber(KeySet("MAX", opt), value, V_max)
	//value=SelectNumber(KeySet("MIN", opt), value, V_min)
//if keyword_set(minn) then value=min(image(where(mask eq 1)))
	print value
	image=SelectNumber(mask, value, image)
	//WaveStats/Q image
	

//return, image*mask + (1-mask)*value
	return value
end


function reftest()
	string imCTwn="im_CT"
	//string str
	variable a, b, str
	print PassByRef( $imCTwn, a, b )
	print str, a, b

end

Function/S PassByRef(w,  v1, v2)
//=============
	WAVE w
	//string &str			//Pass-By-Reference
	//variable &str			//Pass-By-Reference
	variable &v1, &v2			//Pass-By-Reference
	return num2str(v1)+num2str(v2)
end








Function CTselect0(ctrlName,popNum,popStr) : PopupMenuControl
//==================
	String ctrlName
	Variable popNum
	String popStr
	
	//update globals CT identity
	string winnam=WinName(0,1)
	string curr=getdatafolder(1)
	SetDataFolder $"root:WinGlobals:"+winnam
	
	switch( popNum )
	case -1:			//Invert
		SVAR imCTwnam=imCTwnam  //root:colors:imCTwnam
		WAVE imCTw=$(curr+imCTwnam)
		NVAR LUTgamma=LUTgamma, CTinvert=CTinvert 
		SVAR currCTname=currCTname  
		NVAR currCTnum=currCTnum
		CTinvert=1-CTinvert		//should have used 0=no, 1=invert
//		LUTgamma=1/LUTgamma
		//switch CT wave scaling limits (irregardless of absolute min/max)
		variable CTmin, CTmax
		CTmin=DimOffset(imCTw,0)
		CTmax=CTmin+DimDelta(imCTw,0)*(DimSize(imCTw,0)-1)
		//print CTinvert, CTmin, CTmax, LUTgamma
		SetScale/I x CTmax, CTmin,"" imCTw
		//CTsetScale( imCTw, CTmin, CTmax, CTinvert )
		PopupMenu CTpop mode=(currCTnum+1)
		
		//update gamma & CT
		SetDataFolder $curr
		 //CTadjGamma("", LUTgamma,1)
		 execute "ValDisplay GammaVal value="+num2str(LUTgamma)
//		 Slider GammaSlide value=log(LUTgamma)
//		 Slider GammaSlide limits={0.05,SelectNumber(CTinvert==1, 20,2),0.05}
		 CTwriteNote(imCTw, currCTname, LUTgamma, CTinvert)
//		CTadjGamma("",log(LUTgamma),1)
		break
	default:
	
		NVAR currCTnum=currCTnum    //root:colors:currCTnum
		currCTnum=popNum-1		
		SVAR currCTname=currCTname   //root:colors:currCTname
		currCTname=popStr
		if (strlen(popStr)==0)
			//SVAR CTnamelst=root:colors:CTnamelst
			currCTname=StringFromList(currCTnum, CTnamelist(2)) 
		endif
		//print currCTnum, currCTname
	
		// load CT wave from file
			//execute "loadct(" +   num2str(popnum-1)    +    ")"
			//string fname=num2str(ctn)+"."+root:colors:colorTableNames[ctn]
			//string fname=SelectString(popNum<=10, "", "0")+currCTname  // extra zero prefix
		string fname=StringFromList(currCTnum, CTnamelist(1)) 
		//print fname
		//string df=getdatafolder(1)
		//SetDatafolder root:colors
//		LoadWave/T/O/Q/P=ColorTablePath fname		//no longer load from  individual CT file
		//SetDatafolder $df
		WAVE LUT=LUT, CT=CT	//root:colors:LUT, CT=root:colors:CT
		WAVE ALL_CT=root:colors:all_ct
		SVAR imCTwnam=imCTwnam  //root:colors:imCTwnam
		NVAR LUTgamma=LUTgamma, CTinvert=CTinvert    //root:colors:LUTgamma, CTinvert=root:colors:CTinvert
		SetDataFolder $curr
	
		//Update image CT (if called from popmenu selection)
		if (stringmatch(ctrlName, "CTpop"))
			//WAVE imCTw=$imCTwnam
			WAVE imCTw=$(curr+imCTwnam)
//			imCTw=CT[ LUT[p] ][q]	
//		      ImageTool5:  "root:colors:all_ct[pmap[invertct*(255-p)+(invertct==0)*p]][q][whichCTh]"
			 imCTw=ALL_CT[LUT[CTinvert*(255-p)+(CTinvert==0)*p]][q][currCTnum]
//			 CT=ALL_CT[p][q][currCTnum]		//local CT array in graph folder - does nothing
			CTwriteNote(imCTw, currCTname, LUTgamma, CTinvert)
		endif
	endswitch
	//Convert to  cindex method if set for built-in Igor CT
	//SetDataFolder $curr
End

Function CTadjust() 	//: GraphMarquee
//==============
// generic adjustment of index color table scaling
// should work independent of Image_Tool & CT_controls
// only needs to know if CT inverted => preserve min<max or max<min relation	
	string imlst=ImageNameList("",";")		//WaveList("*",";","Win:,DIMS:3")
	string imgn=StringFromList(0,imlst)
	if (!exists(imgn))
			abort "no 2D array in top graph"
	endif
	WAVE imgw=$imgn
	
	// get image 'colorindex' CT wave name 
	string imCTwn
	imCTwn=StringByKey( "cindex", colorTableStr("",imgn), "=", "," )
	if (strlen(imCTwn)>0)
		if (stringmatch(imCTwn[0]," "))
			imCTwn= imCTwn[1,strlen(imCTwn)-1]		//strip off initial space (after =)
		endif
	else
		abort "Using Igor built-in Color Table: "+colorTableStr("",imgn)
	endif
	WAVE imCTw=$imCTwn
	
	//determine if CT scale inverted (test scale increment)
	variable CTmin=DimOffset(imCTw,0), CTmax
	variable invert=(DimDelta(imCTw,0)<0)    // negative increment => 1 = invert

	// determine marquee (ROI) min/max
	GetMarquee/K left, bottom
	If (V_Flag==1)
		//pixel ordering of p(V_left)<p(V_right) required for ImageStats so must convert to pixels
		//   since marquee left/right dependent on sign of axis delta AND axis reverse checkbox
			//ImageStats/M=1/GS={V_left,V_right,V_bottom,V_top} imgw
			//print V_left,V_right,V_bottom,V_top, V_min, V_max
		variable p1, p2, q1, q2
		p1=(V_left-DimOffset( imgw,0))/ DimDelta(imgw,0)
		p2=(V_right-DimOffset(imgw,0))/ DimDelta(imgw,0)
		q1=(V_bottom-DimOffset(imgw,1))/ DimDelta(imgw,1)
		q2=(V_top-DimOffset(imgw,1))/ DimDelta(imgw,1)
		ImageStats/M=1/G={min(p1,p2),max(p1,p2),min(q1,q2),max(q1,q2)} imgw
		//print p1,p2,q1,q2, V_min, V_max
		CTsetscale( imCTw, V_min, V_max, invert)
	endif
		
End

Function CTrescale0(ctrlName,checked) : CheckBoxControl
//=================
	String ctrlName
	Variable checked
	
	variable invert
	variable method=2
	if (method==1)
		string imlst=ImageNameList("",";")		//WaveList("*",";","Win:,DIMS:3")
		string imgn=StringFromList(0,imlst)
		//if (!exists(imgn))
		//		abort "no 2D array in top graph"
		//endif
		WAVE imgw=$imgn
		
		// get image 'colorindex' CT wave name 
		string imCTwn
		imCTwn=StringByKey( "cindex", colorTableStr("",imgn), "=", "," )
		if (strlen(imCTwn)>0)
			if (stringmatch(imCTwn[0]," "))
				imCTwn= imCTwn[1,strlen(imCTwn)-1]		//strip off initial space (after =)
			endif
		else
			abort "Using Igor built-in Color Table: "+colorTableStr("",imgn)
		endif
		WAVE imCTw=$imCTwn
		
		//determine if CT scale inverted (test scale increment)
		variable CTmin=DimOffset(imCTw,0), CTmax
		invert=sign(DimDelta(imCTw,0))    // SelectNumber( DimDelta(imCTw,0)>0, -1, 1)
	else
		// Alternate to above:  assume control bar already created globals & 2D image valid
		WAVE imgw=$StringFromList(0,ImageNameList("",";")	)   //top graph, top image
		SVAR imCTwnam=$("root:WinGlobals:"+WinName(0,1)+":imCTwnam")
		WAVE imCTw=$imCTwnam
		NVAR CTinvert=$("root:WinGlobals:"+WinName(0,1)+":CTinvert")
		invert=CTinvert
	endif

	// determine marquee (ROI) min/max
	GetMarquee/K left, bottom
	If (V_Flag==1)
		//pixel ordering of p(V_left)<p(V_right) required for ImageStats so must convert to pixels
		//   since marquee left/right dependent on sign of axis delta AND axis reverse checkbox
			//ImageStats/M=1/GS={V_left,V_right,V_bottom,V_top} imgw
			//print V_left,V_right,V_bottom,V_top, V_min, V_max
		variable p1, p2, q1, q2
		p1=(V_left-DimOffset( imgw,0))/ DimDelta(imgw,0)
		p2=(V_right-DimOffset(imgw,0))/ DimDelta(imgw,0)
		q1=(V_bottom-DimOffset(imgw,1))/ DimDelta(imgw,1)
		q2=(V_top-DimOffset(imgw,1))/ DimDelta(imgw,1)
		ImageStats/M=1/G={min(p1,p2),max(p1,p2),min(q1,q2),max(q1,q2)} imgw
		//print p1,p2,q1,q2, V_min, V_max
		CTsetscale( imCTw, V_min, V_max, invert)
	else		//no marquee, rescale full image
		ImageStats/M=1 imgw
		//print p1,p2,q1,q2, V_min, V_max
		CTsetscale( imCTw, V_min, V_max, invert)
	endif
	
	Checkbox CTrescale value=0
End


Function CTsetScale(CTw, mn, mx, invert)	
//==============
// scale index Color Table to min/max subject to reverse scale
// invert :  -1 = auto-detect for invert value from CT wavenote  
//                0 = normal
//                1 = reverse (min, max)
	WAVE CTw
	variable invert, mn, mx
	
	// should this auto detect CTinvert from CT wave note?
	if (invert < 0)
		string CTstr=CTreadnote( CTw )
		invert=str2num(StringByKey( "invert", CTstr, "=", "," ) )
	endif
	if (invert==1)
		SetScale/I x mx, mn,"" CTw
	else
		SetScale/I x mn,mx,"" CTw
	endif
end



//Function/S CTreadNote(CTw, CTnam, gamma, invert)




Function/S IMGreadNote(imw)
//=============
	WAVE imw
	//string &CTnam						//Pass-By-Reference
	//variable &gamma, &invert			//Pass-By-Reference
	
	string noteStr, imlst
	noteStr=note(imw)
	//print "notestr:", noteStr, NameOfWave(CTw)
	imlst=StringByKey( "IMG", noteStr, ":", "\r" )
	if (strlen(imlst)==0)					// no keywords present in wave note
		imlst=IMGwriteNote( imw, "x", "y")
   	endif
	return imlst

End

Function/S IMGwriteNote(imw, xlbl, ylbl)
//=============
	WAVE imw
	string xlbl, ylbl			
	
	string notestr, imlst
	imlst="XAXIS="+xlbl+",YAXIS="+ylbl
	notestr=note(imw)
	notestr=ReplaceStringByKey("IMG", notestr, imlst, ":", "\r")
   	Note/K imw			//kill previous note
   	Note imw, noteStr
   	return imlst
End


Function ImgAxes( )	//ylblpop, ylbl, xlblpop, xlbl, std, fontsize)
//===========
	//variable fontsize, std=1
	string imlst=ImageNameList("",";")		//WaveList("*",";","Win:,DIMS:3")
	string imgn=StringFromList(0,imlst)
	if (!exists(imgn))
			abort "no 2D array in top graph"
	endif
	WAVE imgw=$imgn

	string label_lst=axis_list()
	SVAR axis_lst=root:PLOT:axis_lst
	string imNote=IMGreadNote( imgw)
	string xlblnew="", ylblnew=""
	string xlbl="", ylbl=""
	xlbl=StringByKey("XAXIS", imNote, "=", "," )
	ylbl=StringByKey("YAXIS", imNote, "=", "," )
	//string xlbl=""	//=StrVarOrDefault("root:IMG:xlabel","x")
	//string ylbl=""	//=StrVarOrDefault("root:IMG:ylabel","y")
	//xlbl=xlbl
	//ylbl=ylbl
	if (WhichListItem(xlbl, label_lst)==-1)		// not found
		xlblnew=xlbl
	endif
	if (WhichListItem(ylbl, label_lst)==-1)		// not found
		ylblnew=ylbl
	endif
	//prompt fontsize, "Font Size", popup, "Auto (10);12"
	//prompt std,"Operations Performed:", popup,"Ticks Outside;Axis Thick=0.5;Mirror On, No Ticks;Axis Standoff=0;Minor Tick off"
	prompt ylbl, "Y (left) label", popup,label_lst
	prompt ylblnew, "Y label (add to list)"
	prompt xlbl, "X (bottom) label", popup, label_lst
	prompt xlblnew, "X label (add to list)"
	DoPrompt "Image Axis Labeling", ylbl, ylblnew, xlbl, xlblnew
	if (V_flag==1)		//cancel selected
		abort
	endif
	
	if (strlen(xlblnew)==0)
		//xlbl=xlbl
	else
		xlbl=xlblnew
		if (WhichListItem(xlblnew, label_lst)==-1)		// check if new label already in list
			axis_lst+=xlblnew+";"
		endif
	endif
	if (strlen(ylblnew)==0)
		//ylbl=ylbl
	else
		ylbl=ylblnew
		if (WhichListItem(ylblnew, label_lst)==-1)	
			axis_lst+=ylblnew+";"
		endif
	endif
	IMGwriteNote( imgw, xlbl, ylbl )
	
	DoWindow/F $WinName(0,1)
	Label left ylbl
	Label bottom xlbl
end

function/T axis_list()
//===============
	if (exists("root:PLOT:axis_lst")==0)
		NewDataFolder/O root:PLOT
		String/G root:PLOT:axis_lst
		SVAR liststr=root:PLOT:axis_lst
		liststr=" ;-;Intensity (Arb. Units);Intensity (kHz);-;"
		liststr+="Binding Energy (eV);Kinetic Energy (eV);Photon Energy (eV);E-E\BF\M (eV);-;"
		liststr+="Temperature;time (sec);time (min);"
		liststr+="Polar Angle (deg);Azimuth Angle (deg);Elevation Angle (deg);-;"
		liststr+="k\Bx\M (\S-1\M);k\By\M (\S-1\M);X (µm);Y (µm);-;"
	else
		SVAR liststr=root:PLOT:axis_lst
	endif
	return liststr	
end



function ImgCorrelate( img, opt )
//========================================
// correlate 1D X or Y slices from 2D image 
// Return linear offset array
// Options:  
//    Output:      img_cx (default), or /D=outw
//    Direction of slices: /X (default), /Y
//    Sub-range:  /X=x1,x2 (or /Y=y1,y2)
//    Reference line: /REF=val  or /PREF=pixel (0=default)
//    Extra:
//          /P  - plot output array
	wave img
	string opt
	
	string imgn=NameOfWave(img)
	// check validity/dimension of imA, imB
	if (WaveDims(img)!=2)
		return 0	//"ERROR (ImgCorrelate): input not 2D image"
	endif
	
	//determine correlation slice direction
	variable corrDir=KeySet("Y", opt)		// /X is default
	string Xrng
	if (corrDir==1)
		MatrixTranspose img		// transpose back afterwards
		xrng=KeyStr("Y",opt)
	else
		xrng=KeyStr("X",opt)
	endif
	variable nx=DimSize( img, 0), ny=DimSize( img, 1)
	
	// correlation sub-range
	//print xrng
	variable x1, x2
	if (strlen(xrng)==0)
		x1=DimOffset(img,0); x2=x1+DimDelta(img,0)*(DimSize(img,0)-1)
	else
		x1=NumFromList(0, xrng,","); x2=NumFromList(1, xrng,","); 
	endif

	
	//determine output wave
	string shiftn=KeyStr("D", opt)
	if (strlen(shiftn)==0) 
		shiftn=imgn+"_c"+"xy"[corrDir]
	endif
	Make/O/N=(ny) $shiftn
	WAVE shiftw=$shiftn
	
	NewDataFolder/O root:tmp
	// select reference slice (sub-range)
	variable iref=0, vref=0
	if (KeySet("PREF", opt))
		iref=KeyVal("PREF", opt)
		Duplicate/O/R=(x1,x2)[iref,iref] img, root:tmp:refline
	endif
	if (KeySet("REF", opt))
		vref=KeyVal("REF", opt)
		Duplicate/O/R=(x1,x2)(vref,vref) img, root:tmp:refline
	endif

	
	variable ii=0
	DO
		//imgline = 
		shiftw[ii] = CorrelateX( imgline, refline, "")
	
		ii+=1
	WHILE( ii< ny)
	
	if (corrDir==1)
		MatrixTranspose img		// transpose back 
	endif
	
	if (KeySet("P",opt))		//optional new plot
		Display shiftw
	endif
	
	
	return ny
end

function CorrelateX( wv, refw, opt )
//========================================
// correlate 1D wave to reference wave 
// return linear offset required to best match wave to ref
// Options:  
//    Wave subrange:  /X=x1,x2  (default is full range)
//    use full ref wave
	wave wv, refw
	string opt

	// sub-range
	string xrng=""
	variable x1, x2
	if (KeySet("X", opt))
		xrng=KeyStr("X", opt)
	endif
	if (strlen(xrng)==0)
		x1=DimOffset(wv,0); x2=x1+DimDelta(wv,0)*(DimSize(wv,0)-1)
	else
		x1=NumFromList(0, xrng,","); x2=NumFromList(1, xrng,","); 
	endif
	print x1, x2
	NewDataFolder/O root:tmp		
	Duplicate/O/R=(x1,x2) wv, root:tmp:corrw	
	WAVE corrw=root:tmp:corrw
	
	Correlate/C refw, corrw
	//Correlate/C wv, corrw
	WaveStats/Q corrw
	variable xshift
	xshift=V_maxloc - pnt2x( corrw, 0)
	//xshift=V_maxloc - xoffset(corrw)
	print V_maxloc, DimOffset(corrw, 0), pnt2x( corrw, 0)
	
	return xshift
end


Function/T ImgRGB2gray( img3, opt )
//====================
// sum 3 layers of 8-bit color image to single-precision grayscale image
// convert to single precision
// Options string:
// 		/O 			- overwrite RGB image
//		/D=img		- specify output name (*bw = default)
//		/Avg		- sum three layers (default = luminance sum)
//		/P			- plot output image
//		/IT			- pipeline to ImageTool
	wave img3		// 3-layer color image input
	string opt		// default is to overwrite

	string img3n=NameOfWave(img3)
	if (DimSize(img3,2)!=3)
		abort img3n+" not a 3-layer color image!"
	endif
	
	//output image	
	string newimgn=KeyStr("D", opt)
	opt = SelectString( strlen(opt)==0, opt, "/O") 
	variable overwrite=KeySet("O", opt)+stringmatch(img3n,newimgn)
	if ((strlen(newimgn)==0)+overwrite)
		newimgn=img3n+"bw"
	endif
	
	//summing method
	variable method=KeySet("Avg", opt)	 

	variable nx=DimSize(img3,0), ny=DimSize(img3,1)
	if (method==1)
		Duplicate/O img3, $newimgn
		WAVE newimgw=$newimgn
		Redimension/S/N=(nx,ny) newimgw		// 8-bit unsigned to single-precision
		// Average three color layers
		newimgw=(img3[p][q][0] + img3[p][q][1] + img3[p][q][2]) / 3
	else  // default
		ImageTransform rgb2gray img3		// creates M_RGB2Gray
			//RGB values are converted into the luminance Y of the YIQ standard using:
			//  Y=0.299R+0.587G+0.114B.
		Duplicate/O M_RGB2Gray, $newimgn
		WAVE newimgw=$newimgn
		Redimension/S newimgw		// 8-bit unsigned to single-precision
	endif
	
	if (overwrite)
		Duplicate/O newimgw, img
		Killwaves/Z newimgw
		newimgn=NameOfWave(img)
	else
		if (KeySet("P",opt))
			//Display; appendimage newimgw
			NewImage newimgw
			//Assume source image has 1:1 pixel aspect
			ModifyGraph width={Plan,1,top,left}
			
			//ColorTable
			string CTwnam=img3n+"_CT"
			if (exists(CTwnam)==1)
				Duplicate/O $CTwnam $(newimgn+"_CT")
				//Modifyimage newimg cindex=$(newimgn+"_CT")
				execute "Modifyimage "+newimgn+" cindex="+newimgn+"_CT"
				//execute "Modifyimage "+newimgn+" cindex="+CTwnam
			endif	
		endif
	endif
	if (KeySet("IT",opt))
		string ITlst=winlist("ImageTool*",";","WIN:1")
		if (strlen(ITlst)==0)
			//NewImageTool(outn)
			//ShowImageTool_( "", newimgn )		//requires ImageTool (bad?)
			execute "ShowImageTool_( \"\", "+newimgn+" )"
		else		//use top ImageTool
			DoWindow/F $StringFromList(0, ITlst)
			//NewImg( newimgn )		//requires ImageTool (bad?)
			//execute "NewImg( "+newimgn+" )"
			execute "NewImg( \""+newimgn+"\" )"
		endif
	endif
	
	return "SUM: "+newimgn
end

Macro LoadRGB2gray()
//----------------------------
	ImageLoad/T=any/N=RGBload/O 
	string imgn
	//imgn=CleanUpName( S_filename, 0)		// keeps "_JPG" extension
	variable pd=StrSearch(S_filename, ".", inf,1)	// search from end
	imgn=S_filename[0, pd-1]
	ImgRGB2Gray( RGBload, "/D="+imgn+"/P")
End


Function XYarr2img( xw, yw, opt )
//=======================
// options:m
//     /D=destw	-- output image array
//	  /X=x0,x1,xinc  /Y=y0,y1,yinc  -- output dimensions
//    Method:  /M=0/GW=gwidth  (default = 1 pixel)
//            or      /M=1      1/(x-x0) e.g. Lorentzian with tiny width
//     /P - plot array
//    /IT - pipeline to ImageTool
//    /S - Silent / supresses reports to history
	WAVE xw, yw
	string opt
	
	variable silent=KeySet("S", opt)

//output image name
	string newimgn=KeyStr("D", opt)
	if (strlen(newimgn)==0)
		newimgn="XYimg"
	endif

// XY array subrange
	string irng=KeyStr("I", opt)
	variable i1, i2, inc, nXY
	if (strlen(irng)==0)
		i1=0; i2=numpnts( xw ); inc=1		//assume yw same length
	else
		i1=NumFromList(0, irng,","); i2=NumFromList(1, irng,","); inc=NumFromList(2, irng,","); 
		inc = SelectNumber( numtype(inc)==2, round(inc), 1 )
	endif
	nXY = (i2-i1)/inc + 1
//	print "XY:", nXY, i1, i2, inc
	
// output size and range
	string xrng=KeyStr("X", opt), yrng=KeyStr("Y", opt)
	//print xrng, yrng
	variable x1, x2, xinc, nx
	if (strlen(xrng)==0)
		Wavestats/Q/R=[i1,i2]  xw 
		x1=V_min; x2=V_max
		nx=101
		xinc = (x2-x1)/nx
	else
		x1=NumFromList(0, xrng,","); x2=NumFromList(1, xrng,","); 
		xinc=NumFromList(2, xrng,",")
		nx = round((x2-x1)/xinc) + 1
	endif
//		print "x:", nx, x1, x2, xinc
	variable y1, y2, yinc, ny
	if (strlen(yrng)==0)
		Wavestats/Q/R=[i1,i2]  yw 
		y1=V_min; y2=V_max
		ny=101
		yinc = (y2-y1)/ny
	else
		y1=NumFromList(0, yrng,","); y2=NumFromList(1, yrng,","); 
		yinc=NumFromList(2, yrng,",")
		ny = round((y2-y1)/yinc) + 1
	endif
//		print "y:", ny, y1, y2, yinc
      if (!silent)
		print "x:", nx, x1, x2, xinc, "   y:", ny, y1, y2, yinc
	endif
// create output array	
	Make/O/N=(nx, ny) $newimgn
	WAVE im=$newimgn
	SetScale/P x x1, xinc, im
	SetScale/P y y1, yinc, im
	im=0		

// Gaussian coefficient wave
	variable wid=KeyValDef("GW", opt, (xinc+yinc)/2)		// default = average of XY increments	
	make/o Gcoef = {0, 1, 0, wid, 0, wid, 0}
	WAVE Gcoef=Gcoef
	
// Method: /INV
	variable method=KeySet("M", opt)		// 1/distance = Lorentzian with ~zero width
	if (!silent)
		print "Method=", method, "G-width=", wid
	endif
	
//Create Lorentzian or Gaussian image centered on (0,0) to interpolate from rather than calculate each time
	if (method == 1)
		Make/O/N=(501,501) Pt2Img
		SetScale/I x -50*wid,50*wid, Pt2Img
		SetScale/I y -50*wid,50*wid, Pt2Img
		WAVE Pt2Img=Pt2Img
		Pt2Img = 1 / ( (x-0)^2+(y-0)^2 +0.0001 )
	else
		Gcoef[2] = 0;   Gcoef[4] = 0
		Make/O/N=(501,501) Pt2Img
		SetScale/I x -5*wid,5*wid, Pt2Img
		SetScale/I y -5*wid,5*wid, Pt2Img
		WAVE Pt2Img=Pt2Img
		Pt2Img = gauss2D(  Gcoef, x, y )
	endif
	
	Variable timerRefNum
	Variable msec
	timerRefNum = startMSTimer	

	variable ii=i1, inotify=500
	DO
		if (numtype(xw[ii])==0)			//skip Nan or Inf
			if (method == 1)
	//			im += 1 / sqrt( (x-xw[ii])^2+(y-yw[ii])^2 +0.0001 )
//				im += 1 / ( (x-xw[ii])^2+(y-yw[ii])^2 +0.0001 )
				im += Pt2img( x-xw[ii])(y-yw[ii])		// only 1.1X faster
			else
//				Gcoef[2] = xw[ii];   Gcoef[4] = yw[ii]
//				im += gauss2D(  Gcoef, x, y )
				im += Pt2img( x-xw[ii])(y-yw[ii])		//6X faster
			endif
		endif
		
		if (( mod(ii, inotify) == 0)*!silent)
			print ii, " of ", nXY
		endif

		ii+=inc
	WHILE( ii<=i2)
	
	msec = stopMSTimer(timerRefNum) / 1000
	if (!silent)
		Print "Tot time=", msec/1E3, "sec, ", msec/nXY, "msec per iteration"	
	endif
	
	if (KeySet("P",opt))
		Display; appendimage im
//			string CTwnam=imgn+"_CT"
//			if (exists(CTwnam)==1)
//				Duplicate/O $CTwnam $(newimgn+"_CT")
//				execute "Modifyimage "+newimgn+" cindex="+newimgn+"_CT"
//			endif	
	endif

	if (KeySet("IT",opt))
		string ITlst=winlist("ImageTool*",";","WIN:1")
		if (strlen(ITlst)==0)
			execute "ShowImageTool_( \"\", "+newimgn+" )"
		else		//use top ImageTool
			DoWindow/F $StringFromList(0, ITlst)
			execute "NewImg( \""+newimgn+"\" )"
		endif
	endif
	return nXY
End


Function/T OutputName( nam0, opt, default_suffix )
//===================
	string nam0, opt, default_suffix
	string nam1=opt					// opt contains full new name
	if (strlen(opt)==0)				// no opt - assume default suffix
		nam1=nam0+default_suffix
	endif
	if (stringmatch(opt[0],"+"))		// opt specifies suffix
		nam1=nam0+opt[1,9]
	endif
	if (stringmatch(opt[0],"_"))		// opt specifies suffix with undescore spacer
		nam1=nam0+opt
	endif
	return nam1
End