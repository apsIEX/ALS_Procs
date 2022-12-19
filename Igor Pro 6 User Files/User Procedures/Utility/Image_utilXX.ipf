//File: image_util   
// Jonathan Denlinger, JDDenlinger@lbl.gov

//// 9/28/03  jdd modified ImgResize(); returns "outnam: nx x ny" string
// 3/1/03  jdd added ImgResize()
// 11/10/02 jdd revised ImgCrop, ImgNorm
// 7/8/02  jdd added ImgCrop
// 5/25/01 jdd added ShiftImg
// 6/7/00 jdd added balloon help
// 2/20/00 jdd  Image2Waves export Keyword MOD list


#pragma rtGlobals=1		// Use modern global access method.
#include <Keyword-Value>		// for gridding to contour
#include "TV"  //for Waves2Img (AXISW)
#include "list_util"   // for KeyStr()
//#include "JEG Color Legend"

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

menu "2D"
	"-"
	"Add CrossHair"
		help={"Append Cross Hair to top graph; click & drag dynamically displays X, Y values"}
	"Remove CrossHair"
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
	End
	Submenu "Image Functions"
		"fct\T Img2Waves Img, basen, dir"
			help={"Extract wave set from 2D array; use image scaling for x-axis and y-value in wave note"}
		"fct Image2Waves Img, basen, dir, inc"
			help={"Extract wave set from 2D array; use image scaling for x-axis and y-value in wave note; specify x-axis increment"}
		"fct\T ColorTableStr win, imgn"
			help={"return ColorTable info string"}
		"fct ImgCrop  img, opt"
			help={"Crop 2D image wave using specified x & y ranges; opt= /O=newimg /X=x1,x2 /Y=y1,y2"}
		"fct ImgResize img, xyval, opt "
			help={"Resize 2D image using nx,ny scale factors; opt= /O=newimg /Interp/Rebin/Thin/NP"}
		"fct ImgNorm img, opt"
			help={"divide by average lineprofile along specified direction"}
		"fct ImgAvg img, opt"
			help={"1D average  lineprofile along specified direction"}
		"fct ScaleImg  img, xwn, ywn"
			help={"Scale 2D image wave using specified x & y wave names; scaling assumes monotonic increasing x,y arrays"}
		"fct MaxImg img, indx, outw"
			help={"1D maximum of lineprofile along specified direction"}
		"fct\C ReinterpImg img, xscal, yscal, outimgn"
			help={" reinterpolation of 2D array for specified scale factors"}
		"fct ExtractImg newimgnam"
			help={"extract subset of image in top graph using current plot axes or marquee box"}
		"fct\T ImgRange dir "
			help={"return string containing 'min,max,inc' for specified scaled image axis"}
		"fct\T ReadImgNote  w "
			help={"read IMG note containing xSHIFT,ySHIFT, zOFFSET,zGAIN, VAL, TXT"}
		"fct\T WriteImgNote  w,xshft, yshft, zoff, zgain, val, txt"
			help={"assemble & write IMG note"}
		"fct CUTMX m, indx, xy"
		"fct EXTRACTMX  m, indx, xy, nw "
		"fct CHECKDIM w, dim"
	End	
end

//Menu "Graph"
//	Submenu "Remove"
//		"Color legend Controls", JEG_ZapColorLegendControls()
//		help = {"Remove color legend controls only"}
//	End
//End

Function/T Img_Info( image, opt )
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

Function/T ReadImgNote( w )		//, destwn )
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


Function/T WriteImgNote(w,xshft, yshft, zoff, zgain, val, txt)
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


Function/T ImgRange( dir )
//==============
	variable dir								// select direction
	string img=ImageNameList("",";")
	img=StringFromList(0, img, ";")				// use first image for range
	variable inc=DimDelta($img,dir), x1, x2
	inc=abs(inc)
	if (WinType(WinName(0, 87))!=1)		// top window not  a graph
		return "Nan,Nan,Nan"
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
	else										// use Axes ranges (allows manual zoom)
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
		//x1=DimOffset($img, dir)			// do not use image ranges
		//x2=x1+(DimSize($img, dir)-1)*inc
	endif
	string str=num2str(x1)+","+num2str(x2)+","+num2str(inc)
	return str
End


Function/T ImgAxisNam(win, imgn, which)
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


Function/T ColorTableStr(win, imgn)
//=================
	string win, imgn
	if (strlen(imgn)==0)
		imgn=ImageNameList(win, ";")
		//imgn=imgn[0, strlen(imgn)-2]				//assumes only one image
		imgn=imgn[0, strsearch(imgn, ";", 0)-1]	// assumes first image in window
	endif
	
	string infostr=ImageInfo( win, imgn, 0 )
	variable i1, i2
	i1=strsearch(infostr, "RECREATION:", 0)+11;   i2=strsearch(infostr, ";", i1)-1
	//print i1, i2
	return infostr[i1, i2]
End

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

Function/T ImgCrop( img, opt )
//================
// Crop subregion of image
// options: 
//     output:  img+"c" (default),  /O (overwrite),   or  /O=outputwavename
//     range:    /X=x1,x2     /Y=y1, y2    (optional for each axis; default=start, end)
//     plot:    /P  (display new image)
//    fct returns "CROP: newimgn; nx, ny" information string
	wave img
	string opt
	
	//output image
	variable overwrite
	string newimgn=KeyStr("O", opt)
	if (strlen(newimgn)==0)
		newimgn=NameOfWave(img)+"c"
		overwrite=KeySet("O", opt)
	endif
	
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
	Duplicate/O/R=(x1,x2)(y1,y2) img, $newimgn
	WAVE newimg=$newimgn
	string str=num2str(DimSize(newimgl,0))+","+num2str(DimSize(newimg,1))
	
	if (overwrite)
		Duplicate/O newimg, img
		Killwaves/Z newimg
		newimgn=NameOfWave(img)
	else
		if (KeySet("P",opt))
			Display; appendimage newimg
		endif
	endif
	
	return "CROP: "+newimgn+";"+str
End

Function/T ImgResize( img, xyval, opt )		//xyopt, xyval )
//==============
//	xyval = (Nx, Ny) or N [=Nx=Ny]
// options:  
//     output:  img+"r" (default),  /O (overwrite),   or  /O=outputwavename
//     xyopt:    /I (Interp), /R (Rebin) , /T (thin)
//     nopt:   /NP  (interpret xyval as Npts instead of scale factor) - interp only
// investigate ImageInterpolate (Igor 4) as option for making smaller 
	WAVE img
	//variable xyopt
	string xyval, opt	//=StrVarOrDefault(getdf()+"N_resize", "1,1" )
	//prompt xyopt, "Nx, Ny Resize option:", popup, "Interp by N;Interp to Npts;Rebin by N;Thin by N"
	//prompt xyval, "(Nx, Ny) or N [=Nx=Ny]"
	
	//output image
	variable overwrite
	string newimgn=KeyStr("O", opt)
	if (strlen(newimgn)==0)
		newimgn=NameOfWave(img)+"r"
		overwrite=KeySet("O", opt)
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
			SetScale/P y ymin, yinc,"" newimg
			SetScale/P x xmin, xinc,"" newimg
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


Function/T ImgNorm( img, opt )
//================
// Normalize image along selected direction by average value defined range
// Future:  other methods:  divide by edge profile;  plot norm wave
// options: 
//     output:  img+"_nrm" (default),  /O (overwrite),   or  /O=outputwavename
//     direction:    /X (default) or  /Y 
//     range:        /R=y1,y2  or x1,x2   (default = full range)
//     plot:    /P  (display new image)
	wave img
	string opt
	
	//output imgume
	variable overwrite
	string newimgn=KeyStr("O", opt)
	if (strlen(newimgn)==0)
		newimgn=NameOfWave(img)+"_nrm"
		overwrite=KeySet("O", opt)
	endif
	
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

Function/T ImgAvg( img, opt )
//================
// Average image along selected direction by average value defined range
// Future:  other methods:  divide by edge profile;  plot norm wave
// options: 
//     output:  img+"_av" (default),  /O (overwrite),   or  /O=outputwavename
//     direction:    /X (default) or  /Y 
//     range:        /R=y1,y2  or x1,x2   (default = full range)
//     plot:    /P  (display new image)
	wave img
	string opt
	
	//output array name
	//variable overwrite		-- no overwrite option
	string avgn=KeyStr("O", opt)
	if (strlen(avgn)==0)
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



Function/T ScaleImg( img, xwn, ywn)
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


Proc Waves2Img( wvlst, imgn, refwv, yrng, dopt, trans, offset, yinterp, gridopt)
//------------------------------
// Merge list of waves to a 2D array;
// use specified y-axis scaling parameters OR
// create _x, _y n+1 axis using wave note values for y-axis
	string wvlst, refwv 
	string yrng=	StrVarOrDefault("root:img:yrange","0,1")
	string imgn=	StrVarOrDefault("root:img:imgnm","out")
	variable dopt=	NumVarOrDefault("root:img:dispopt",1)
	variable trans=	NumVarOrDefault("root:img:transp",2)
	variable offset=	NumVarOrDefault("root:img:offsetopt",2)
	variable yinterp=	NumVarOrDefault("root:img:yreinterp",2)
	variable gridopt=	NumVarOrDefault("root:img:grid_opt",2)
	prompt wvlst, "WaveList", popup, "TopGraph;"+StringList("*_lst",";")	//+WinList("*",";","WIN:1")
	prompt refwv, "Reference Wave for X-axis", popup, TraceNameList("",";",1)
	prompt yrng, "Y Scaling: start,incr (VAL or TXT =use wavenote)"
	prompt imgn, "Output image name"
	prompt dopt, "Display Image", popup, "Yes;No"
	prompt trans, "Transpose Image", popup, "Yes;No"
	prompt offset, "Remove Offset by Cursor(A)", popup, "Yes;No"
	prompt yinterp, "Y reinterpolation factor", popup, "1X;2X;4X;8X;16X"
	prompt gridopt, "Grid option", popup, "Plot vs X,Y;Reinterp to uniform grid"

	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:img
		string/G yrange=yrng, imgnm=imgn
		variable/G dispopt=dopt, transp=trans, offsetopt=offset, yreinterp=yinterp, grid_opt=gridopt
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
		if (offset==1)
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

Function/T Img2Waves( img, basen, dir )
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

Function/T Write_Mod(w, shft, off, gain, lin,  thk, clr, val, txt)
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


Proc ReGridXY( imgn, outn, xwn, ywn, xrng, yrng,  dopt ) : GraphMarquee
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
	print "Created: ", outn, "(", nx, "x", ny, ") �xy=", xinc, yinc

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
		Label bottom "Kx (1/�)"
		Label left "Ky (1/�)"
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



Proc JEG_ZapColorLegendControls(legendName)
//====================
	//Variable	killControls
	String		legendName
	Prompt legendName, "Color legend to remove: ", popup JEG_ColorLegendList("",";")
	
//	String legendPath = "root:Packages:'JEG Color Legend':" + legendName
	
//	String dfSav = GetDataFolder(1)
//	SetDataFolder $legendPath
	
		// Kill controls

		ControlBar 0
		KillControl $("upper_" + legendName)
		KillControl $("lower_" + legendName)
		KillControl $("full_" + legendName)
		KillControl $("color_" + legendName)
		KillControl $("reverse_" + legendName)
		KillControl $("scale_" + legendName)
		KillControl $("zeroUpper_" + legendName)
		KillControl $("zeroLower_" + legendName)
		KillControl $("delete_" + legendName)
		
	
//	SetDataFolder dfSav
End


Function/T ShiftImg( img, shiftw, opt)
	wave img, shiftw
	string opt
	return ImgShift( img, shiftw, opt)
end

Function/T ImgShift( img, shiftw, opt)
//=================
// Subtraction shifts image according to specified wave (subtraction)
// Options:
//    Shift wave: /XW=x_shiftwn or /XW - shift_x  (default=scaled shift wave)
//    Direction:  /Y - yaxis shift (default=xaxis)
//    Output:      /O=outw (default=img_shftx or img_shfty)
//    Output dimension:  /E=expand  (-1=shrink, 0=avg, 1=expand)
//
	wave img, shiftw
	string opt
	
	string imgn=NameOfWave(img), shiftn=NameOfWave(shiftw)
// axis to shift:
	variable dim=SelectNumber(KeySet("Y",opt), 0, 1)		//0=X , 1=Y
// shift wave scaling
	variable V_scaled=SelectNumber(KeySet("XW",opt), 1, 0)	//0=xwave, 1=scaled
	string shiftxn=KeyStr("XW",opt)
	shiftxn=SelectString(strlen(shiftxn)==0, shiftxn, shiftn+"_x")
// axis range expansion  (-1, 0, 1)
	variable V_expand=SelectNumber(KeySet("E",opt), 1, KeyVal("E",opt) )		//1=default
	V_expand=SelectNumber(numtype(V_expand)==0, 1, V_expand) 
	
// original image parameters:
	variable nx, xmin, xmax, xinc
	variable ny, ymin, ymax, yinc
	nx=DimSize(img, 0); 	ny=DimSize(img, 1)
	xmin=DimOffset(img,0);  ymin=DimOffset(img,1);
	xinc=round(DimDelta(img,0) * 1E6) / 1E6	
	yinc=round(DimDelta(img,1)* 1E6) / 1E6
	xmax=xmin+xinc*(nx-1);	ymax=ymin+yinc*(ny-1);

// shift wave stats
	WaveStats/Q shiftw
	if (V_expand==1)	
		if (dim==0)
			xmin=xmin-V_max
			xmax=xmax-V_min
			nx=round((xmax-xmin)/xinc)+1
			xmax=xmin+xinc*(nx-1)
			print "x expand: ", xmin, xmax, nx
		else
			ymin=ymin-V_max
			ymax=ymax-V_min
			ny=round((ymax-ymin)/yinc)+1
			ymax=ymin+yinc*(ny-1)
			print "y expand: ", ymin, ymax, ny
		endif
	else
	if (V_expand==-1)		//shrink
		if (dim==0)
			xmin=xmin-V_min 		//+(V_max-V_min)
			xmax=xmax-V_max 	//-(V_max-V_min)
			nx=round((xmax-xmin)/xinc)+1
			xmax=xmin+xinc*(nx-1)
			print "x shrink: ", xmin, xmax, nx
		else
			ymin=ymin-V_min
			ymax=ymax-V_max
			ny=round((ymax-ymin)/yinc)+1
			ymax=ymin+yinc*(ny-1)
			print "y shrink: ", ymin, ymax, ny
		endif	
	else	
		if (dim==0)
			xmin=xmin-V_avg
			xmax=xmax-V_avg
			print "x avg: ", xmin, xmax, nx
		else
			ymin=ymin-V_avg
			ymax=ymax-V_avg
			print "y avg: ", ymin, ymax, ny
		endif
	endif
	endif
	
	string outw
	outw=SelectString( KeySet("O",opt), imgn+"_shft"+"xy"[dim], KeyStr("O",opt))
	
	Make/O/N=(nx,ny) $outw
	WAVE newimg=$outw
	SetScale/P x xmin,xinc,WaveUnits(img,0) newimg
	SetScale/P y ymin,yinc,WaveUnits(img,1) newimg

//requires MDinterpolator Igor Extension
	string cmd=outw+"=interp2D("+imgn+", x"
	if (dim==0)
		cmd+=SelectString(V_scaled, "+interp(y,"+shiftxn+","+shiftn+")" , "+"+shiftn+"(y)")
		cmd+=",y )"
	else
		cmd+=", y"
		cmd+=SelectString(V_scaled, "+interp(x,"+shiftxn+","+shiftn+"))" , "+"+shiftn+"(x))")
	endif

	if (V_scaled)
		if (dim==0)
			newimg=interp2D(img, x+shiftw(y), y)		
		else
			newimg=interp2D(img, x, y+shiftw(x))	
		endif
	else
		WAVE shiftx=$shiftxn
		if (dim==0)
			newimg=interp2D(img, x+interp(y, shiftx, shiftw), y)		
		else
			newimg=interp2D(img, x, y+interp(x, shiftx, shiftw))	
		endif
	endif	
	
	return cmd
End


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
