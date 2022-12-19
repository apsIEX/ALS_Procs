//File: volume				created 6/7/00 
//Jonathan Denlinger, JDDenlinger@lbl.gov 

#pragma version = 5.13
// 3/27/09 jdd -- modify volshift for interp3d() to fix boundary problems
//                        -- Wavemetrics will include inter3D() fix in next version >6.05
//  2/19/08  jdd -- add /XZ  "zero" option to VolRescale()
// 11/16/07 jdd added CTinvert check to VOLcontrol
// 3/9/06 jdd copy vol wnote to VolAvg image
// 3/3/06 fw/jd  add VolAvg() use 10X-50X faster ImageTransform method
// 2/24/06 jd  fix VolResize bug > Rebin Z
// 10/14/05 jdd fix VolRescale using GetWavesDataFolder() instead of WaveName()
// 7/24/05 jdd supercede VolReorder with 10X faster VolTranspose (using ImageTransform Igor cmd)
// 5/17/04 jdd change /O dual purpose option into /O (overwrite) or /D=destw (consistent with Igor routines)
// 5/09/04 jdd  add VaryPlane ControlBar
// 11/29/03 jdd  added VolReorder(), VolRotate(); add VolAppend() directional capabilities
// 9/28/03 jdd fix some bugs in VolResize
// 3/1/03  jdd  rework ExtractAvgSlice to VolSlice; add VolResize(), VolRescale()
// 11/10/02 jdd revised VolCrop, VolNorm
// 11/10/02 jdd added 3D-to-3D functionality to AppendImg() & rename as VolAppend()
// 8/18/02 jdd added ExtractAvgSlice() modified from ExtractSlice()
// 7/8/02 jdd added Shift Vol and VolCrop, VolModify() for Image_Tool

#pragma rtGlobals=1		// Use modern global access method.
#pragma Igorversion = 5.02    //ImageTransform transposeVol axis scaling
// "ImageTransform now copies wave scaling when using the keyword transposeVol. "
#include "Image_util"		//uses WriteImgNote()

Menu "3D"
	"VOL Control Bar", Vol_ControlBar()
	"AppendVol"
		help={"Append 3D/2D volume/image to 3D/2D array z-axis"}
	Submenu "Volume Funcs"
		"fct\T VolSlice vol, index, opt"
			help={"Extract 2D slice from 3D; preserve slice scaling; slice averaging option"}
		"fct VolAppend vol, img, opt"
			help={"Append 2D or 3D array to a 3D volume; extend in Z only"}
		"fct\T Vol2Images vol, basen, opt "
			help={"Extract image slices from volume, /X/Y/Z, /INC=inc, /PLOT, /TILE"}
		"fct\T VolShift vol, shiftw, opt"
			help={"Shift 3D array along one direction according to input wave"}
		"fct\T VolCrop vol, opt"
			help={"Crop 3D volume along one axis; optional marquee XY range"}
		"fct VolResize vol, xyzval, opt "
			help={"Resize 3D volume using nx,ny,nz scale factors; opt= /D=newvol /Interp/Rebin/Thin/NP"}
		"fct\T VolNorm vol, opt"
			help={"Normalize volume along selected direction by average value of orthogonal slices"}
	End
End


Function/T VolSlice( vol, indx, opt)
//================
// Extract and sum ONE 2D slice from a 3D volume set; preserve scaling and units
// idir = direction index perpendicular to the 2D slice:  0=YZ, 1=XZ, 2=XY
// return avg intensity value  of slice
	wave vol
	variable indx
	string opt
	
	//output image
	string imgn=KeyStr("D", opt)
	if (strlen(imgn)==0)
		imgn=NameOfWave(vol)+"_"+num2str(indx)
	endif
	
	//direction  (/X=default)
	variable idir=2
	idir=SelectNumber( KeySet("X", opt), idir, 0)
	idir=SelectNumber( KeySet("Y", opt), idir, 1)
	idir=SelectNumber( KeySet("Z", opt), idir, 2)
	//variable  idir=0*KeySet("X", opt)+1*KeySet("Y", opt)+2*KeySet("Z", opt)
	
	//slice averaging
	variable navg=1, off=0
	string avg=KeyStr("AVG", opt)
	variable x1, x2, y1, y2, z1, z2
	if (strlen(avg)>0)
		navg=NumFromList(0, avg,",")
		off=NumFromList(1, avg,",")
		off=SelectNumber( numtype(off)==2, off, -floor(navg/2))
	endif
	variable i1=indx+off
	//print indx, navg, off, i1
	
	string voln=NameOfWave( vol )
	variable ix, iy, val
	iy=SelectNumber( idir==2, 2, 1)
	ix=SelectNumber( idir==0, 0, 1)
	variable nx, ny, nz
	nx=DimSize(vol, ix)
	ny=DimSize(vol, iy)
	//nz=DimSize(vol, dir)
	
	Make/o/n=(nx,ny) $imgn
	WAVE img=$imgn	
	SetScale/P x  DimOffset(vol,ix), DimDelta(vol,ix), WaveUnits(vol,ix) img
	SetScale/P y  DimOffset(vol,iy), DimDelta(vol,iy), WaveUnits(vol,iy) img

	//variable nslices=abs(i2-i1)+1, inc=sign(i2-i1)
	variable ii=0, islice
	img=0
	DO
		islice=i1+ii
		//islice=Min(Max(i1+ii,0), nz-1)	//limit range to vol 
		if (idir==2)
			img+=vol[p][q][islice]
		else
		if (idir==1)
			img+=vol[p][islice][q]
		else
			img+=vol[islice][p][q]
		endif
		endif
		ii+=1
	WHILE(ii<navg)
	img/=navg
	val=DimOffset(vol,idir)+indx*DimDelta(vol,idir)
	WriteImgNote(img, 0, 0, 0, 1, val, voln+"; "+"XYZ"[idir]+"=")
	
	if (KeySet("P",opt))
		Display; appendimage img
	endif
	
	//Wavestats/Q img
	//return V_avg
	return imgn
End


Function/T Vol2Images( vol, basen, opt )
//================
// Extract a SET of image slices from 3D array
// use image scaling for x-axis and y-value in wave note
// Options:
//     /X, /Y, /Z (def)   - direction of slicing
//     /INC=inc     - point increment of slicing (default=1)
	Wave vol
	String basen, opt
	
	//direction
	Variable dir=2, inc=1
	dir=SelectNumber( KeySet("X", opt), dir, 1)
	dir=SelectNumber( KeySet("Y", opt), dir, 2)
	
	//increment
	inc=trunc(KeyVal("INC", opt))
	inc=SelectNumber(inc>0 ,1, inc)
	//inc=round( max(inc,1) )
	
	//slice averaging
	variable navg=1, off=0
	string avgopt=""
	if (KeySet("AVG", opt))
		avgopt="/AVG="+KeyStr("AVG", opt)
	endif
	
	print opt, dir, inc
	
	variable ix, iy
	iy=SelectNumber( dir==2, 2, 1)
	ix=SelectNumber( dir==0, 0, 1)
	variable nx, ny, nz
	nx=DimSize(vol, ix)
	ny=DimSize(vol, iy)
	nz=DimSize(vol, dir)
	nz=round(nz/inc)
	
	//print ix, iy, iz, nx, ny, nz
	string imgn, voln=NameOfWave( vol )
	string imglst=""
	variable ii=0, val
	DO
		imgn=basen+num2str(ii)
		imglst+=imgn+";"
		//ExtractSlice( ii*inc, vol, imgn, dir )
		VolSlice( vol, ii*inc, "/"+"XYZ"[dir]+"/D="+imgn+"/AVG="+num2str(navg))
   		//print imgn, ii, ii*inc, val
		ii+=1
	WHILE( ii<nz)
	
	if (keyset("PLOT", opt)+keyset("TILE", opt))
		DisplayList( imglst,"" )
		if (keyset(opt, "tile"))
		
		
		endif
	endif
	return imglst
End

Function/T VolReorder( vol, opt)	// Obsolete: Replaced by faster VolTransposr
//=================
// Reorder dimensions of volume
// Options:
//    Output:      vol_r (default), or /D=outw, or /O (overwrite)
//    order:		/XZY, /YXZ, /YZX, /ZXY, /ZYX
//             /N={XYZ, YXZ, ZXY, XZY, YZX, ZYX} - new orientation
//             /C={"}  - current orientation => compute relative operation
//
	wave vol
	string opt
	
	string voln=GetWavesDataFolder(vol,0)+":"+NameOfWave(vol)
	//check validity of ord	
	string ord=""	
	ord=SelectString(KeySet("XYZ",opt), ord, "xyz012pqr")
	ord=SelectString(KeySet("YXZ",opt), ord, "yxz102qpr")	
	ord=SelectString(KeySet("XZY",opt), ord, "xzy021prq")
	ord=SelectString(KeySet("ZXY",opt), ord, "zxy201qrp")
	ord=SelectString(KeySet("YZX",opt), ord, "yzx120rpq")
	ord=SelectString(KeySet("ZYX",opt), ord, "zyx210rqp")
	if (strlen(ord)==0)
		return "no change"
	endif
	//Duplicate if "XYZ"
	
	//output image
	string newvoln=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(voln,newvoln)
	if ((strlen(newvoln)==0)+overwrite)
		newvoln=voln+ord[0,2]
	endif	
	
	//print overwrite, voln, newvoln
	if (KeySet("T", opt))
		variable timer=StartMSTimer
	endif

// determine output image range; keep increments constant
	variable ix=str2num(ord[3]), iy=str2num(ord[4]), iz=str2num(ord[5])
	string nx=num2str(DimSize(vol,ix)), ny=num2str(DimSize(vol,iy)), nz=num2str(DimSize(vol,iz))
	string xmin=num2str(DimOffset(vol,ix)), ymin=num2str(DimOffset(vol,iy)), zmin=num2str(DimOffset(vol,iz))
	string xinc=num2str(DimDelta(vol,ix)), yinc=num2str(DimDelta(vol,iy)), zinc=num2str(DimDelta(vol,iz))
	string xunit=WaveUnits(vol,ix), yunit=WaveUnits(vol,iy), zunit=WaveUnits(vol,iz)
	
	string cmd
	// Create output and scale
	cmd="Make/O/N=("+nx+","+ny+","+nz+") "+newvoln
	//print cmd
	execute cmd
	cmd="SetScale/P x "+xmin+", "+xinc+", \""+xunit+"\" "+newvoln
	//print cmd
	execute cmd
	cmd="SetScale/P y "+ymin+", "+yinc+", \""+yunit+"\" "+newvoln
	//print cmd
	execute cmd
	cmd="SetScale/P z "+zmin+", "+zinc+", \""+zunit+"\" "+newvoln
	//print cmd
	execute cmd
	
	// new indexing
	cmd=newvoln+"= "+voln+"["+ord[6]+"]["+ord[7]+"]["+ord[8]+"]"
	print cmd
	execute cmd
		
	if (overwrite)
		Duplicate/O $newvoln, vol
		Killwaves/Z $newvoln
		newvoln=voln
	endif	
	
	if (KeySet("T", opt))
		print StopMStimer( timer)/1E6, "sec: ", nx, ny, nz
	endif

	if (KeySet("P",opt))
		Display; appendimage $newvoln
	endif
	//print cmd
	return cmd
End

Function/T VolTranspose( vol, opt)
//=================
// Reorder dimensions of volume; using built-in Igor ImageTransform fct
// Options:
//    Output:      vol_r (default), or /D=outw, or /O (overwrite)
//    order:		/XZY, /YXZ, /YZX, /ZXY, /ZYX 
//                       /XYZ does nothing
//
	wave vol
	string opt
	
	string voln=GetWavesDataFolder(vol,0)+":"+NameOfWave(vol)
	//check validity of ord	
	string ord=""	
	ord=SelectString(KeySet("XYZ",opt), ord, "xyz012pqr0")
	ord=SelectString(KeySet("YXZ",opt), ord, "yxz102qpr5")	
	ord=SelectString(KeySet("XZY",opt), ord, "xzy021prq1")
	ord=SelectString(KeySet("ZXY",opt), ord, "zxy201rpq2")
	ord=SelectString(KeySet("YZX",opt), ord, "yzx120qrp4")
	ord=SelectString(KeySet("ZYX",opt), ord, "zyx210rqp3")
	if (strlen(ord)==0)
		return "no change"
	endif
	//Duplicate if "XYZ"
	
	//output image
	string newvoln=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(voln,newvoln)
	if ((strlen(newvoln)==0)+overwrite)
		newvoln=voln+ord[0,2]
	endif	
	
	//print overwrite, voln, newvoln
	if (KeySet("T", opt))
		variable timer=StartMSTimer
	endif

// determine output image range; keep increments constant
	variable ix=str2num(ord[3]), iy=str2num(ord[4]), iz=str2num(ord[5])
	string nx=num2str(DimSize(vol,ix)), ny=num2str(DimSize(vol,iy)), nz=num2str(DimSize(vol,iz))
	//string xmin=num2str(DimOffset(vol,ix)), ymin=num2str(DimOffset(vol,iy)), zmin=num2str(DimOffset(vol,iz))
	//string xinc=num2str(DimDelta(vol,ix)), yinc=num2str(DimDelta(vol,iy)), zinc=num2str(DimDelta(vol,iz))
	//string xunit=WaveUnits(vol,ix), yunit=WaveUnits(vol,iy), zunit=WaveUnits(vol,iz)
	
	//variable mode=str2num(ord[9])
	//ImageTransform/G=(mode) transposeVol vol
	
	string cmd=""
	//ImageTransform/G=(mode) transposeVol
	// Creates output in M_VolumeTranspose  (in current folder?)
	// Create output and scale
	if (str2num(ord[9])!=0)		// 0=no action
		cmd="ImageTransform/G="+ord[9]+" transposeVol "+voln
		print cmd
		execute cmd
	
		
		//Scales get transposed too?
		//cmd="SetScale/P x "+xmin+", "+xinc+", \""+xunit+"\" "+newvoln
		//print cmd
		//execute cmd
		//cmd="SetScale/P y "+ymin+", "+yinc+", \""+yunit+"\" "+newvoln
		//print cmd
		//execute cmd
		//cmd="SetScale/P z "+zmin+", "+zinc+", \""+zunit+"\" "+newvoln
		//print cmd
		//execute cmd
		
		// new indexing
		cmd=newvoln+"= "+voln+"["+ord[6]+"]["+ord[7]+"]["+ord[8]+"]"
		print cmd
		//execute cmd
		
		WAVE M_VolumeTranspose=M_VolumeTranspose	
		if (overwrite)
			Duplicate/O M_VolumeTranspose, vol
			Killwaves/Z M_VolumeTranspose
			newvoln=voln
		else
			Duplicate/O M_VolumeTranspose, $newvoln
			Killwaves/Z M_VolumeTranspose
			//or
			//MoveWave M_VolumeTranspose, $newvoln
			//Rename M_VolumeTranspose, $newvoln
		endif
	else
		if (!overwrite)
			Duplicate/O vol, $newvoln
		endif
	endif	
	
	if (KeySet("T", opt))
		print StopMStimer( timer)/1E6, "sec: ", nx, ny, nz
	endif

	if (KeySet("P",opt))
		Display; appendimage $newvoln
	endif
	//print cmd
	return cmd
End



Proc AppendVol0( voln, imgn )
//-------------
// Append 2D (image) array to a 3D (volume) array
// or create 3D array from 2D arrays; or append 3D array to 3D array
	string voln=StringFromList(0, ImageNameList("",";"))
	string imgn
	prompt voln, "base 3D or 2D array", popup, " --3D --;"+WaveList("!*_CT",";","DIMS:3")+"-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	prompt imgn, "2D or 3D array to append", popup, " --3D --;"+WaveList("!*_CT",";","DIMS:3")+"-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	
	variable ndim0=WaveDims( $voln), ndim1=WaveDims( $imgn)
	variable nx0=DimSize( $voln, 0), ny0=DimSize($voln, 1), nz0=DimSize($voln,2)
	variable nx1=DimSize( $imgn, 0), ny1=DimSize($imgn, 1), nz1=DimSize($imgn,2)
	nz0=SelectNumber( nz0==0, nz0, 1)
	nz1=SelectNumber( nz1==0, nz1, 1)
	
	if ((nx0==nx1)*(ny0==ny1))
		Redimension/N=(nx0, ny0, nz0+nz1) $voln
		IF (nz1==1)
			$voln[][][nz0]=$imgn[p][q]
		ELSE
			$voln[][][nz0,nz0+nz1-1]=$imgn[p][q][r-nz0]
		ENDIF
		print "nx,ny,nz=", nx0, ny0, nz0+nz1
	else
		string errorStr="Mismatch in Image sizes:"
		errorStr+="nx="+num2str(nx0)+"/"+num2str(nx1)
		errorStr+=",  ny="+num2str(ny0)+"/"+num2str(ny1)
		Abort errorStr
	endif
End


Proc AppendVol( voln, imgn )
//-------------
// Append 2D (image) array to a 3D (volume) array
// or create 3D array from 2D arrays; or append 3D array to 3D array
	string voln=StringFromList(0, ImageNameList("",";"))
	string imgn
	prompt voln, "base 3D or 2D array", popup, " --3D --;"+WaveList("!*_CT",";","DIMS:3")+"-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	prompt imgn, "2D or 3D array to append (to Z)", popup, " --3D --;"+WaveList("!*_CT",";","DIMS:3")+"-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	
	variable ndim0=WaveDims( $voln), ndim1=WaveDims( $imgn)
	
	VolAppend( $voln, $imgn, "")
End

Function/T VolAppend( vol, img, opt )
//========
// Append two 3D arrays along specified direction (X, Y, Z)
//    OR  append 2D image to a specified face of volume (XY-> YZ, ZX or XY)
//    OR create 3D array from two 2D arrays (nz=2)
// options:  /X, /Y, /Z(default);  output name
	WAVE vol, img
	string opt
	//string voln=StringFromList(0, ImageNameList("",";"))
	//string imgn
	//prompt voln, "base 3D or 2D array", popup, " --3D --;"+WaveList("!*_CT",";","DIMS:3")+"-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	//prompt imgn, "2D or 3D array to append", popup, " --3D --;"+WaveList("!*_CT",";","DIMS:3")+"-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	
	variable appdir=2		// default = Z, append XY slice(s)
	appdir=SelectNumber(KeySet("X",opt), appdir, 0)
	appdir=SelectNumber(KeySet("Y",opt), appdir, 1)	
	appdir=SelectNumber(KeySet("Z",opt), appdir, 2)		
	
	variable ndim0=WaveDims( vol), ndim1=WaveDims( img)
	variable nx0=DimSize( vol, 0), ny0=DimSize(vol, 1), nz0=DimSize(vol,2)
	variable nx1=DimSize( img, 0), ny1=DimSize(img, 1), nz1=DimSize(img,2)
	nz0=SelectNumber( nz0==0, nz0, 1)
	nz1=SelectNumber( nz1==0, nz1, 1)
	variable nx, ny, nz
	string errorStr="Mismatch in Image sizes:"
	
	IF (nz1==1)		//append XY image
		switch( appdir )
		case 2:			//Z-axis;  XY image --> XY slice
			if ((nx0==nx1)*(ny0==ny1))
				nx=nx0; ny=ny0; nz=nz0+1
				Redimension/N=(nx, ny, nz) vol
				vol[][][nz-1]=img[p][q]
			else
				errorStr+="nx="+num2str(nx0)+"/"+num2str(nx1)
				errorStr+=",  ny="+num2str(ny0)+"/"+num2str(ny1)
				Abort errorStr
			endif
			break
		case 1:			//Y-axis; XY image --> ZX slice
			if ((nz0==nx1)*(nx0==ny1))
				nx=nx0; ny=ny0+1; nz=nz0					
				Redimension/N=(nx, ny, nz) vol
				vol[][ny-1][]=img[r][p]
			else
				errorStr+="nx="+num2str(nz0)+"/"+num2str(nx1)
				errorStr+=",  ny="+num2str(nx0)+"/"+num2str(ny1)
				Abort errorStr
			endif
			break
		case 0:			//X-axis;  XY image --> YZ slice
			if ((ny0==nx1)*(nz0==ny1))
				nx=nx0+1; ny=ny0; nz=nz0		
				Redimension/N=(nx, ny, nz) vol
				vol[nx-1][][]=img[q][r]
			else
				errorStr+="nx="+num2str(ny0)+"/"+num2str(nx1)
				errorStr+=",  ny="+num2str(nz0)+"/"+num2str(ny1)
				Abort errorStr
			endif
		endswitch
	ELSE
		switch( appdir )
		case 2:			//Z-axis; append XY slices
			if ((nx0==nx1)*(ny0==ny1))
				nx=nx0; ny=ny0; nz=nz0+nz1
				Redimension/N=(nx, ny, nz) vol
				vol[][][nz0,nz-1]=img[p][q][r-nz0]
			else
				errorStr+="nx="+num2str(nx0)+"/"+num2str(nx1)
				errorStr+=",  ny="+num2str(ny0)+"/"+num2str(ny1)
				Abort errorStr
			endif
			break
		case 1:			//Y-axis; append ZX slices
			if ((nz0==nz1)*(nx0==nx1))
				nx=nx0; ny=ny0+ny1; nz=nz0
				Redimension/N=(nx, ny, nz) vol
				vol[][ny0, ny-1][]=img[p][q-ny0][r]
			else
				errorStr+="nz="+num2str(nz0)+"/"+num2str(nz1)
				errorStr+=",  nx="+num2str(nx0)+"/"+num2str(nx1)
				Abort errorStr
			endif
			break
		case 0:			//X-axis; append YZ-slices
			if ((ny0==ny1)*(nz0==nz1))
				nx=nx0+nx1; ny=ny0; nz=nz0
				Redimension/N=(nx, ny, nz) vol
				vol[nx0, nx-1][][]=img[p-nx0][q][r]
			else
				errorStr+="ny="+num2str(ny0)+"/"+num2str(ny1)
				errorStr+=",  nz="+num2str(nz0)+"/"+num2str(nz1)
				Abort errorStr
			endif
		endswitch
	ENDIF
	return num2str(nx)+" x "+num2str(ny)+" x "+num2str(nz)
End

Function VolAvg(vol, opt)
//================  Feng Wang 3/03/06
// Sum volume to an image along specified direction
// options: 
//     output:  vol+"av" (default),  or  /D=outputwavename
//     sum direction:      /X, /Y, /Z (=def)  
//    (not implemented)  direction+range:    /X=x1,x2     /Y=y1, y2    /Z=z1,z2  
//     plot image:  /P
//     method:    /M=1,2   (1=default, built-in ImageTransform; 2=standard loop)
//     execution time:  /T     (built-in is 10X-50X faster)
//          --could also do region of interest summing
	wave vol
	string opt
	string voln=GetWavesDataFolder(vol,0)+":"+NameOfWave(vol)

	//output image
	string newimgn=KeyStr("D", opt)
	newimgn=SelectString(strlen(newimgn)==0, newimgn, voln+"av")
	
	//direction
	// variable 	idir = 0*KeySet("X", opt)+1*KeySet("Y", opt)+2*KeySet("Z", opt)
	variable  idir=2  // default = Z sum
	idir = SelectNumber( KeySet("X", opt), idir, 0)
	idir = SelectNumber( KeySet("Y", opt), idir, 1)
	idir = SelectNumber( KeySet("Z", opt), idir, 2)

	string sdir="XYZ"[idir]
	
	//method
	variable method=SelectNumber( KeySet("M",opt), 1, KeyVal("M", opt))		
	//1=Igor built-in ImageTransform (fast); 2= std looping (slow)
	
	if (KeySet("T",opt))
		variable ref=StartMStimer
	endif

	if  (method==1)
		switch( idir )
		case 0:		// sum YZ images along X
			NewDataFolder/O root:tmp
			VolTranspose( vol, "/YZX/D=root:tmp:tmpvol")
			WAVE tmpvol = root:tmp:tmpvol
			ImageTransform  averageImage  tmpvol
			Duplicate/O M_AveImage $newimgn
			CopyScales/P tmpvol $newimgn
			//VolReorder( vol, "/ZXY")
			Killwaves root:tmp:tmpvol
			break
		case 1:			// sum XZ images along Z
			NewDataFolder/O root:tmp
			VolTranspose( vol, "/XZY/D=root:tmp:tmpvol")
			WAVE tmpvol = root:tmp:tmpvol
			ImageTransform  averageImage  tmpvol
			Duplicate/O M_AveImage $newimgn
			CopyScales/P tmpvol $newimgn
			Killwaves root:tmp:tmpvol
			break
		case 2:			// sum XY images along Z  (50X faster)
			ImageTransform  averageImage  vol
			Duplicate/O M_AveImage $newimgn
			CopyScales/P vol $newimgn		
		endswitch
		Killwaves M_AveImage, M_StdvImage
	else
		NewDataFolder/O root:tmp
		make/o/n=3 root:tmp:nvol
		wave nvol=root:tmp:nvol
		
		variable nx=dimsize(vol,0),ny=dimsize(vol,1),nz=dimsize(vol,2)
		nvol[0]=nx
		nvol[1]=ny
		nvol[2]=nz
	
		variable ii
		VolSlice( vol, 0, "/"+sdir+"/D="+newimgn)
		wave newwave = $newimgn
		wave slicewave = root:tmp:slicewave
		For(ii=1;ii<nvol[idir];ii+=1)
			VolSlice( vol, ii, "/"+sdir+"/D=root:tmp:slicewave")
			newwave+=slicewave
		endfor
	endif
	
	//copy volume wavenote to avg_img
	string notestr=note(vol)
	notestr+=note( $newimgn ) 
   	Note/K $newimgn
   	Note $newimgn, noteStr
	
	if (KeySet("T",opt))
		print StopMStimer( ref )*1E-6, "sec"
	endif
	
	if (KeySet("P",opt))
		WAVE newimg=$newimgn
		Display; appendimage newimg
	endif
	
	return Dimsize(vol, idir)
end 



Function/T VolCrop( vol, opt )
//================
// Crop subregion of volume 
// options: 
//     output:  vol+"_c" (default),  or  /D=outputwavename, /O (overwrite)
//     range:    /X=x1,x2     /Y=y1, y2    /Z=z1,z2    (optional for each axis; default=start, end)
	wave vol
	string opt	
	string voln=GetWavesDataFolder(vol,0)+":"+NameOfWave(vol)
	
	//output volume
	string newvoln=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(voln,newvoln)
	newvoln=SelectString(strlen(newvoln)==0, newvoln, voln+"c")
	newvoln=SelectString(overwrite, newvoln, voln+"_tmp")
	//if ((strlen(newvoln)==0)+overwrite)
	//	newvoln=voln+"c"
	//endif	
	//print overwrite, newvoln, voln	
	
	// crop range
	string xrng=KeyStr("X", opt), yrng=KeyStr("Y", opt), zrng=KeyStr("Z", opt)
	variable x1, x2, y1, y2, z1, z2
	if (strlen(xrng)==0)
		x1=DimOffset(vol,0); x2=x1+DimDelta(vol,0)*(DimSize(vol,0)-1)
	else
		x1=NumFromList(0, xrng,","); x2=NumFromList(1, xrng,","); 
	endif
	if (strlen(yrng)==0)
		y1=DimOffset(vol,1); y2=y1+DimDelta(vol,1)*(DimSize(vol,1)-1)
	else
		y1=NumFromList(0, yrng,","); y2=NumFromList(1, yrng,","); 
	endif
	if (strlen(zrng)==0)
		z1=DimOffset(vol,2); z2=z1+DimDelta(vol,2)*(DimSize(vol,2)-1)
	else
		z1=NumFromList(0, zrng,","); z2=NumFromList(1, zrng,","); 
	endif
	
	Duplicate/O/R=(x1,x2)(y1,y2)(z1,z2) vol, $newvoln
	WAVE newvol=$newvoln
	string str=num2str(DimSize(newvol,0))+","+num2str(DimSize(newvol,1))+","+num2str(DimSize(newvol,2))
	
	if (overwrite)
		Duplicate/O newvol, vol
		Killwaves/Z newvol
		newvoln=voln
	endif
	
	return "CROP "+newvoln+":"+str
End

Function/T VolRescale( arr, rng, opt )
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
	
	string arrn=GetWavesDataFolder( arr, 4) 		//NameOfWave(arr)
	//print GetWavesDataFolder( arr, 0) 
	//print GetWavesDataFolder( arr, 1) 
	//print GetWavesDataFolder( arr, 2)   //full path + nam
	//print GetWavesDataFolder( arr, 3) 
	//print GetWavesDataFolder( arr, 4)   // partial path + wavename
	
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
				df=getdf1()
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



Function/T VolResize( vol, xyzval, opt )		//xyopt, xyval )
//==============
//	xyzval = (Nx, Ny,Nz) or N [=Nx=Ny=Nz]
// options:  
//     output:  img+"r" (default),  or  /D=outputwavename, or /O (overwrite)
//     xyopt:    /I (Interp), /R (Rebin) , /T (thin)
//     nopt:   /NP  (interpret xyzval as Npts instead of scale factor) - interp only
// investigate ImageInterpolate (Igor 4) as option for making smaller 
	WAVE vol
	//variable xyopt
	string xyzval, opt	//=StrVarOrDefault(getdf()+"N_resize", "1,1" )
	//prompt xyopt, "Nx, Ny Resize option:", popup, "Interp by N;Interp to Npts;Rebin by N;Thin by N"
	//prompt xyval, "(Nx, Ny) or N [=Nx=Ny]"
	string voln=GetWavesDataFolder(vol,0)+":"+NameOfWave(vol)
	
	//output volume
	string newvoln=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(voln,newvoln)
	if ((strlen(newvoln)==0)+overwrite)
		newvoln=voln+"r"
	endif	
	
	// interpret xyval string
	if (stringmatch(xyzval,"1,1,1"))
		if (overwrite)
			newvoln=NameOfWave(vol)
		else
			duplicate/o vol $newvoln
		endif
		return newvoln+": "+"no change"	//NameOfWave(vol)
	endif
	variable xval=1, yval=1, zval=1
	xval=str2num(StringFromList(0, xyzval, ","))
	xval=SelectNumber(numtype(yval)==2, xval, 1)    //NaN for single value list
	yval=str2num(StringFromList(1, xyzval, ","))
	yval=SelectNumber(numtype(yval)==2, yval, xval)    //NaN for single value list
	zval=str2num(StringFromList(2, xyzval, ","))
	zval=SelectNumber(numtype(zval)==2, zval, xval)    //NaN for single value list
	//print xval, yval, zval
	
	variable  xyzopt=0*KeySet("I", opt)+1*KeySet("R", opt)+2*KeySet("T", opt)
	//string df=getdf(), curr=GetDataFolder(1)
	//SetDataFolder $df
	//string/G N_resize=xyval
	//variable/C coffset=GetWaveOffset($(df+"HairY0"))
	
	// globals will get updated later by ImgInfo()
	//input image info
	variable nx=DimSize( vol, 0), ny=DimSize( vol, 1), nz=DimSize( vol, 2)
	variable xmin=DimOffset( vol, 0), ymin=DimOffset( vol, 1),  zmin=DimOffset( vol, 2)
	variable xinc=DimDelta( vol, 0), yinc=DimDelta( vol, 1),  zinc=DimDelta( vol, 2)
	variable nx2=nx, ny2=ny, nz2=nz
	string sizestr
	//print nx, ny, nz
	
	switch( xyzopt )
	case 0:		//3D interpolate    
		//nx2=SelectNumber(xyopt==1, xval, nx*xval)
		//ny2=SelectNumber(xyopt==1, yval, ny*yval)
		variable nopt=KeySet("NP", opt)		// 0 = scale factors
		if (nopt==1)
			xval=round(xval); yval=round(yval)
			nx2=SelectNumber(xval==1, xval, nx)		// don't allow Nx2=1
			ny2=SelectNumber(yval==1, yval, ny)
			nz2=SelectNumber(zval==1, zval, nz)
			//print nx2, ny2
			Make/O/N=(nx2, ny2, nz2) $newvoln
			WAVE newvol=$newvoln
			SetScale/I x xmin, xmin+(nx-1)*xinc,"" newvol
			SetScale/I y ymin, ymin+(ny-1)*yinc,"" newvol
			SetScale/I z zmin, zmin+(nz-1)*zinc,"" newvol
			sizestr=num2str(nx2)+" x "+num2str(ny2)+" x "+num2str(nz2)
		else		// scale factors
			nx2=round(nx*xval) - 1*(mod(nx,2))
			ny2=round(ny*yval)- 1*(mod(ny,2))
			nz2=round(nz*zval)- 1*(mod(nz,2))
			xinc/=xval; yinc/=yval; zinc/=zval
			//print nx2, ny2, xinc, yinc
			Make/O/N=(nx2, ny2, nz2) $newvoln
			WAVE newvol=$newvoln
			SetScale/P x xmin, xinc,"" newvol
			SetScale/P y ymin, yinc,"" newvol
			SetScale/P z zmin, zinc,"" newvol
			sizestr=num2str(nx2)+"("+num2str(xval)+")"
			sizestr+=" x "+num2str(ny2)+"("+num2str(yval)+")"
			sizestr+=" x "+num2str(nz2)+"("+num2str(zval)+")"
		endif
		newvol=interp3D(vol, x, y, z)
		break
	case 1:		// Rebin  X, then Y
	case 2:		// Thin X, then Y
	//if (xyopt>=3)		
		variable ii, jj
		nx2=round(nx/xval)
		//ny2=trunc(ny/yval)
		ny2=round(ny/yval)
		nz2=round(nz/zval)
		// print nx2, ny2, nz2
		if (xval>1) 
			Make/O/N=(nx2, ny, nz) $(newvoln+"x")
			WAVE newvolx=$(newvoln+"x")
			xinc*=xval
			SetScale/P z zmin, zinc,"" newvolx
			SetScale/P y ymin, yinc,"" newvolx
			SetScale/P x xmin, xinc,"" newvolx
			ii=0
			DO
				newvolx[ii][][]=0
				if (xyzopt==1)				// Rebin X
					jj=0
					newvolx[ii][][]=0
					DO
						newvolx[ii][][]+= vol[xval*ii+jj][q][r]
						jj+=1
					WHILE( jj<xval )
					newvolx[ii][][]/=xval
				endif
				if (xyzopt==2)				// Thin X
					newvolx[ii][][]+=vol[xval*ii][q][r]
				endif
				ii+=1
			WHILE( ii<nx2)
			sizestr=num2str(nx2)+"("+num2str(xval)+")"
		else
			Duplicate/O vol $(newvoln+"x")
			WAVE newvolx=$(newvoln+"x")
			sizestr=num2str(nx2)
		endif
		if (yval>1) 
			yinc*=yval
			Make/O/N=(nx2, ny2, nz) $(newvoln+"y")
			WAVE newvoly=$(newvoln+"y")
			SetScale/P z zmin, zinc,"" newvoly
			SetScale/P y ymin, yinc,"" newvoly
			SetScale/P x xmin, xinc,"" newvoly
			ii=0
			DO
				newvoly[][ii][]=0
				if (xyzopt==1)				// Rebin Y
					jj=0
					newvoly[][ii][]=0
					DO
						newvoly[][ii][]+= newvolx[p][yval*ii+jj][r]
						jj+=1
					WHILE( jj<yval )
					newvoly[][ii][]/=yval
				endif
				if (xyzopt==2)				// Thin Y
					newvoly[][ii][]+= newvolx[p][yval*ii][r]
				endif
				ii+=1
			WHILE( ii<ny2)
			Killwaves/Z newvolx
			sizestr+=" x "+num2str(ny2)+"("+num2str(yval)+")"
		else
			Duplicate/O newvolx $(newvoln+"y")
			WAVE newvoly=$(newvoln+"y")
			Killwaves/Z newvolx
			sizestr+=" x "+num2str(ny2)
		endif
		if (zval>1) 
			zinc*=zval
			Make/O/N=(nx2, ny2, nz2) $newvoln
			WAVE newvol=$newvoln
			SetScale/P z zmin, zinc,"" newvol
			SetScale/P y ymin, yinc,"" newvol
			SetScale/P x xmin, xinc,"" newvol
			ii=0
			DO
				newvol[][][ii]=0
				if (xyzopt==1)				// Rebin Y
					jj=0
					newvol[][][ii]=0
					DO
						newvol[][][ii]+= newvoly[p][q][zval*ii+jj]
						jj+=1
					WHILE( jj<yval )
					newvol[][ii]/=yval
				endif
				if (xyzopt==2)				// Thin Y
					newvol[][][ii]+= newvoly[p][q][zval*ii]
				endif
				ii+=1
			WHILE( ii<nz2)
			Killwaves/Z newvoly
			sizestr+=" x "+num2str(nz2)+"("+num2str(zval)+")"
		else
			Duplicate/O newvoly $newvoln
			WAVE newvol=$newvoln
			Killwaves/Z newvoly
			sizestr+=" x "+num2str(nz2)
		endif
		break
	endswitch
	
	if (overwrite)
		Duplicate/O newvol vol
		Killwaves/Z newvol
		newvoln=voln
	endif
	print xval, yval, zval, "x", nx, ny, nz, "-->", nx2, ny2, nz2
	//SetDataFolder curr
	return newvoln+": "+sizestr
End


Function/T VolNorm( vol, opt )
//================
// Normalize volume along selected direction by average value of orthogonal slices 
// Future:  other methods:  divide by edge profile
// options: 
//     output:  vol+"_n" (default),  or  /O=outputwavename, or /O (overwrite) 
//     direction:    /X (default),   /Y  or   /Z 
	wave vol
	string opt
	string voln=GetWavesDataFolder(vol,0)+":"+NameOfWave(vol)
	
	//output volume
	string newvoln=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(voln,newvoln)
	if ((strlen(newvoln)==0)+overwrite)
		newvoln=voln+"n"
	endif	
	
	//direction
	variable  idir=0*KeySet("X", opt)+1*KeySet("Y", opt)+2*KeySet("Z", opt)
	string sdir="XYZ"[idir]
	variable NP=DimSize(vol, idir)
	
	NewDataFolder/O root:tmp
	Make/O/N=(NP) root:tmp:avgw
	WAVE avgw=root:tmp:avgw
	variable ii=0
	DO
		//if (idir==0)					// Requires MDInterpolater Igor extension
		//	Slice3d( vol, idir+8, ii/2)	 //bug in X-slice?		
		//else
		//	Slice3d( vol, idir+8, ii)
		//endif
		//WaveStats/Q Slice_Wave		// or subrange /R
		//avgw[ii]=V_avg					// or V_max
		
		//slower by accurate for idir=0
		//avgw[ii]=ExtractSlice( ii, vol, "root:tmp:slice_wave", idir )
		Wavestats/Q $VolSlice( vol, ii, "/"+sdir+"/D=root:tmp:slice_wave" )
		avgw[ii]=V_avg
	
		ii+=1
	WHILE( ii<NP)
	
	Duplicate/O vol, $newvoln
	WAVE newvol=$newvoln
	if (idir==0)
		newvol=vol/avgw[p]
	endif
	if (idir==1)
		newvol=vol/avgw[q]
	endif
	if (idir==2)
		newvol=vol/avgw[r]
	endif
	
	if (overwrite)
		Duplicate/O newvol, vol
		Killwaves/Z newvol
		newvoln=voln
	endif
	
	return "NORM "+"XYZ"[idir]+" "+newvoln+": "+num2str(NP)
End

Function/T VolShift( vol, shiftw, opt)
//=================
// Shifts (subtraction)volume according to specified wave (subtraction)
// adapt from ShiftImg()
// Options:
//    Shift wave: /XW=x_shiftwn or /XW - shift_x  (default=scaled shift wave)
//    Direction & Shift:  /XY, /XZ, /YX, /YZ, /ZX, /ZY  (default=/XY)
//    Output:      img_shftx or img_shfty (default), or /D=outw,  or /O (=overwrite)
//    Output dimension:  /E=expand  (-1=shrink, 0=avg, 1=expand)
//
	wave vol, shiftw
	string opt
	
	string voln=GetWavesDataFolder(vol,0)+":"+NameOfWave(vol)
	string shiftn=GetWavesDataFolder(shiftw,0)+":"+NameOfWave(shiftw) 
// axis to shift:
	variable dir=0, dir1=1					// XY = default
	dir=SelectNumber(KeySet("X",opt), dir, 0)		//0=X , 1=Y, 2=Z
	dir=SelectNumber(KeySet("Y",opt), dir, 1)	
	dir=SelectNumber(KeySet("Z",opt), dir, 2)	
	dir1=SelectNumber(KeySet("*X",opt)*(dir!=0), dir1, 0)		//0=X , 1=Y, 2=Z
	dir1=SelectNumber(KeySet("*Y",opt)*(dir!=1), dir1, 1)
	dir1=SelectNumber(KeySet("*Z",opt)*(dir!=2), dir1, 2)	
// shift wave scaling
	variable V_scaled=SelectNumber(KeySet("XW",opt), 1, 0)	//0=xwave, 1=scaled
	string shiftxn=KeyStr("XW",opt)
	shiftxn=SelectString(strlen(shiftxn)==0, shiftxn, shiftn+"_x")
// axis range expansion  (-1, 0, 1)
	variable V_expand=SelectNumber(KeySet("E",opt), 1, KeyVal("E",opt) )		//1=default
	V_expand=SelectNumber(numtype(V_expand)==0, 1, V_expand) 
	
// original volume parameters:
	variable nx, xmin, xmax, xinc
	variable ny, ymin, ymax, yinc
	variable nz, zmin, zmax, zinc
	nx=DimSize(vol, 0); 	ny=DimSize(vol, 1); nz=DimSize(vol, 2)
	xmin=DimOffset(vol,0);  ymin=DimOffset(vol,1); zmin=DimOffset(vol,2);
	xinc=round(DimDelta(vol,0) * 1E6) / 1E6	
	yinc=round(DimDelta(vol,1)* 1E6) / 1E6
	zinc=round(DimDelta(vol,2)* 1E6) / 1E6
	xmax=xmin+xinc*(nx-1);	ymax=ymin+yinc*(ny-1); zmax=zmin+zinc*(nz-1);

// shift wave stats
	WaveStats/Q shiftw		// determine range of shifts
	if (V_expand==1)		//expand
		if (dir==0)
			xmin=xmin-V_max
			xmax=xmax-V_min
			nx=round((xmax-xmin)/xinc)+1
			xmax=xmin+xinc*(nx-1)
			print "x expand: ", xmin, xmax, nx
		else
		if (dir==1)
			ymin=ymin-V_max
			ymax=ymax-V_min
			ny=round((ymax-ymin)/yinc)+1
			ymax=ymin+yinc*(ny-1)
			print "y expand: ", ymin, ymax, ny
		else
			zmin=zmin-V_max
			zmax=zmax-V_min
			nz=round((zmax-zmin)/zinc)+1
			zmax=zmin+zinc*(nz-1)
			print "z expand: ", zmin, zmax, nz
		endif
		endif
	else
	if (V_expand==-1)		//shrink
		if (dir==0)
			xmin=xmin-V_min 		//+(V_max-V_min)
			xmax=xmax-V_max 	//-(V_max-V_min)
			nx=round((xmax-xmin)/xinc)+1
			xmax=xmin+xinc*(nx-1)
			print "x shrink: ", xmin, xmax, nx
		else
		if (dir==1)
			ymin=ymin-V_min
			ymax=ymax-V_max
			ny=round((ymax-ymin)/yinc)+1
			ymax=ymin+yinc*(ny-1)
			print "y shrink: ", ymin, ymax, ny
		else
			zmin=zmin-V_min
			zmax=zmax-V_max
			nz=round((zmax-zmin)/zinc)+1
			zmax=zmin+zinc*(nz-1)
			print "z shrink: ", zmin, zmax, nz
		endif
		endif	
	else					// average
		if (dir==0)
			xmin=xmin-V_avg
			xmax=xmax-V_avg
			print "x avg: ", xmin, xmax, nx
		else
		if (dir==1)
			ymin=ymin-V_avg
			ymax=ymax-V_avg
			print "y avg: ", ymin, ymax, ny
		else
			zmin=zmin-V_avg
			zmax=zmax-V_avg
			print "z avg: ", zmin, zmax, nz		
		endif
		endif
	endif
	endif
	
//output volume
	string newvoln=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(voln,newvoln)
	if ((strlen(newvoln)==0)+overwrite)
		newvoln=voln+"_shft"+"xyz"[dir]
	endif	

	variable del=1E-12		//delta to remove end NaN interpolation	
	Make/O/N=(nx,ny,nz) $newvoln
	WAVE newvol=$newvoln
	SetScale/P x xmin-sign(xinc)*del, xinc,WaveUnits(vol,0) newvol
	SetScale/P y ymin-sign(yinc)*del, yinc,WaveUnits(vol,1) newvol
	SetScale/P z zmin-sign(zinc)*del, zinc,WaveUnits(vol,2) newvol

//requires MDinterpolator Igor Extension (Igor 4.x)
	string cmd=newvoln+"=interp3D("+voln+","
	if (V_scaled)
		if (dir==0)
			if (dir1==1)		// XY
				cmd+="x+"+shiftn+"(y), y, z )"
				newvol=interp3D(vol, x+shiftw(y), y, z)		//+del)
			else 				// XZ
				cmd+="x+"+shiftn+"(z), y, z )"
				newvol=interp3D(vol, x+shiftw(z), y, z)		//+del)
			endif
		endif
		if (dir==1)
			if (dir1==0)		// YX
				cmd+="x, y+"+shiftn+"(x), z )"
				newvol=interp3D(vol, x, y+shiftw(x), z)		//+del)
			else 				// YZ
				cmd+="x, y+"+shiftn+"(z), z )"
				newvol=interp3D(vol, x, y+shiftw(z), z)		//+del)
			endif
		endif
		if (dir==2)
			if (dir1==0)		// ZX
				cmd+="x, y, z+"+shiftn+"(x) )"
				newvol=interp3D(vol, x, y, z+shiftw(x))
			else    				// ZY
				cmd+="x, y, z+"+shiftn+"(y) )"
				newvol=interp3D(vol, x, y, z+shiftw(y))
			endif
		endif		
	else
		WAVE shiftx=$shiftxn
		if (dir==0)
			if (dir1==1)		// XY
				cmd+="x+interp(y,"+shiftxn+","+shiftn+"), y, z )" 
				newvol=interp3D(vol, x+interp(y, shiftx, shiftw), y, z)	//+del)
			else 				// XZ
				cmd+="x+interp(z,"+shiftxn+","+shiftn+"), y, z )" 
				newvol=interp_3D(vol, x+interp(z, shiftx, shiftw), y, z)	//+del)
			endif
		endif
		if (dir==1)
			if (dir1==0)		// YX
				cmd+="x, y+interp(x,"+shiftxn+","+shiftn+"), z )"
				newvol=interp3D(vol, x, y+interp(x, shiftx, shiftw), z)		//+del)
			else 				// YZ
				cmd+="x, y+interp(z,"+shiftxn+","+shiftn+"), z )"
				newvol=interp3D(vol, x, y+interp(z, shiftx, shiftw), z)		//+del)
			endif
		endif
		if (dir==2)
			if (dir1==0)		// ZX
				cmd+="x, y, z+interp(x,"+shiftxn+","+shiftn+") )"
				newvol=interp3D(vol, x, y, z+interp(x, shiftx, shiftw))
			else    				// ZY
				cmd+="x, y, z+interp(y,"+shiftxn+","+shiftn+") )"
				newvol=interp3D(vol, x, y, z+interp(y, shiftx, shiftw))	
			endif
		endif
	endif	
	
	if (overwrite)
		Duplicate/o newvol vol
		Killwaves/Z newvol
		newvoln=voln
	endif
	
	return cmd
End


Function/T VolRotate( vol, ang, opt)
//=================
// Rotates volume by specified angle (degrees)
// Options:
//    Output:      vol+"_r" (default), or /D=outw, or /O (overwrite)
//    Axis of Rotation:  /X, /Y, /Z [default, about (X,Y)=(0,0)]
//    Outside domain value:  Nan (default of interp3D)
//    Output dimension:  /F (fixed axes, no resize) (default=recalculate expanded) 
//    Method:  /M=num  (1=Igor ImageRotate+duplicate; 2=interp3D)
//
	wave vol
	variable ang
	string opt
	string voln=GetWavesDataFolder(vol,0)+":"+NameOfWave(vol)
	
//output volume
	string newvoln=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(voln,newvoln)
	if ((strlen(newvoln)==0)+overwrite)
		newvoln=voln+"_rot"
	endif		
	
//rotatation axis
	variable rotaxis=2		// default = Z, rotate in XY plane
	rotaxis=SelectNumber(KeySet("X",opt), rotaxis, 0)
	rotaxis=SelectNumber(KeySet("Y",opt), rotaxis, 1)	
	rotaxis=SelectNumber(KeySet("Z",opt), rotaxis, 2)		
		// axis range expansion  (-1, 0, 1)
	variable newaxes=SelectNumber(KeySet("F",opt), 1, 0 )		//1=default
		//V_expand=SelectNumber(numtype(V_expand)==0, 1, V_expand) 
	
// original image parameters:
	variable nx0, xmin0, xmax0, xinc0
	variable ny0, ymin0, ymax0, yinc0
	variable nz0, zmin0, zmax0, zinc0
	nx0=DimSize(vol, 0); 	ny0=DimSize(vol, 1); nz0=DimSize(vol, 2)
	xmin0=DimOffset(vol,0);  ymin0=DimOffset(vol,1); zmin0=DimOffset(vol,2);
	xinc0=round(DimDelta(vol,0) * 1E6) / 1E6	
	yinc0=round(DimDelta(vol,1)* 1E6) / 1E6
	zinc0=round(DimDelta(vol,2)* 1E6) / 1E6
	xmax0=xmin0+xinc0*(nx0-1);    ymax0=ymin0+yinc0*(ny0-1);  zmax0=zmin0+zinc0*(nz0-1)

// determine output image range; keep increments constant
	variable nx, xmin, xmax
	variable ny, ymin, ymax
	variable nz, zmin, zmax
	
	string cmd
	variable method=2		// 1=Igor ImageRotate+duplicate; 2= ImageRotate / Overwrite; 3=interp2D
	//method=SelectNumber( rotaxis==2, 2, 1)
	method=SelectNumber(KeySet("M",opt), 2, KeyVal("M",opt))	
	variable tnum=StartMSTimer
	switch( method )
		//intensity ofset introduced by ImageRotate??
	case 1:		//ImageRotate only works on XY plane; Z-axis rotation
		cmd="ImageRotate/S/A="+num2str(-ang)
		if (overwrite)
			ImageRotate/S/O/A=(-ang) vol			  //overwrite original
			newvoln=voln
			cmd+="/O"
		else
			Duplicate/O vol $newvoln
			WAVE newvol=$newvoln
			ImageRotate/O/A=(-ang)/E=(Nan) newvol			 // overwrite duplicate
		endif
		cmd+=" "+voln
		break
	case 2:
		// Reorder Volume axes & rotate about Z-axis OR 
		// newaxes=0 calculates for zero angle rotation
		variable angrad
		switch( rotaxis )
		case 2:				//Z-axis rotation
			RangeAfterRotation(ang*newaxes, xmin0, xmax0, ymin0, ymax0, xmin, xmax, ymin, ymax)
			nx=round((xmax-xmin)/xinc0)+1
			xmax=xmin+xinc0*(nx-1)
				//print "x expand: ", xmin, xmax, nx
			ny=round((ymax-ymin)/yinc0)+1
			ymax=ymin+yinc0*(ny-1)
				//print "y expand: ", ymin, ymax, ny
			nz=nz0; zmin=zmin0
			
			// create output image
			Make/O/N=(nx,ny,nz) $newvoln
			WAVE newvol=$newvoln
			SetScale/P x xmin, xinc0,WaveUnits(vol,0) newvol
			SetScale/P y ymin, yinc0,WaveUnits(vol,1) newvol
			SetScale/P z zmin, zinc0,WaveUnits(vol,2) newvol
		
			//generate low-level command (degrees)
			cmd=newvoln+"=interp3D("+voln
				cmd+=", rot_x( x, y, "+num2str(-ang)+")"
				cmd+=", rot_y( x, y, "+num2str(-ang)+"), z )"
			
			//execute rotated interpolation
			angrad=ang*pi/180
			newvol=interp3D(vol, rot_x( x, y, -angrad), rot_y( x, y, -angrad), z)	
			break
		case 1:				//Y-axis rotation
			RangeAfterRotation(ang*newaxes, zmin0, zmax0, xmin0, xmax0, zmin, zmax, xmin, xmax)
			nz=round((zmax-zmin)/zinc0)+1
			zmax=zmin+zinc0*(nz-1)
				//print "z expand: ", zmin, zmax, nz
			nx=round((xmax-xmin)/xinc0)+1
			xmax=xmin+xinc0*(nx-1)
				//print "x expand: ", xmin, xmax, nx
			ny=ny0; ymin=ymin0
			
			// create output image
			Make/O/N=(nx,ny,nz) $newvoln
			WAVE newvol=$newvoln
			SetScale/P x xmin, xinc0,WaveUnits(vol,0) newvol
			SetScale/P y ymin, yinc0,WaveUnits(vol,1) newvol
			SetScale/P z zmin, zinc0,WaveUnits(vol,2) newvol
		
			//generate low-level command (degrees)
			cmd=newvoln+"=interp3D("+voln
				cmd+=", rot_x( z, x, "+num2str(-ang)+"), y"
				cmd+=", rot_y( z, x, "+num2str(-ang)+") )"
			
			//execute rotated interpolation
			angrad=ang*pi/180
			newvol=interp3D(vol, rot_x( z, x, -angrad), y, rot_y( z, x, -angrad))	
			break
		case 0:				//X-axis rotation
			RangeAfterRotation(ang*newaxes, ymin0, ymax0, zmin0, zmax0, ymin, ymax, zmin, zmax)
			ny=round((ymax-ymin)/yinc0)+1
			ymax=ymin+yinc0*(ny-1)
				//print "y expand: ", ymin, ymax, ny
			nz=round((zmax-zmin)/zinc0)+1
			zmax=zmin+zinc0*(nz-1)
				//print "z expand: ", zmin, zmax, nz
			nx=nx0; xmin=xmin0
			
			// create output image
			Make/O/N=(nx,ny,nz) $newvoln
			WAVE newvol=$newvoln
			SetScale/P x xmin, xinc0,WaveUnits(vol,0) newvol
			SetScale/P y ymin, yinc0,WaveUnits(vol,1) newvol
			SetScale/P z zmin, zinc0,WaveUnits(vol,2) newvol
		
			//generate low-level command (degrees)
			cmd=newvoln+"=interp3D("+voln
				cmd+=", x, rot_x( y, z, "+num2str(-ang)+")"
				cmd+=", rot_y( y, z, "+num2str(-ang)+") )"
			
			//execute rotated interpolation
			angrad=ang*pi/180
			newvol=interp3D(vol, x, rot_x(y, z, -angrad), rot_y( y, z, -angrad))	
		endswitch
		
		if (overwrite)
			Duplicate/O newvol, vol
			Killwaves/Z newvol
			newvoln=voln
		endif	
	endswitch
	print "Method=",method , ", ", StopMSTimer( tnum )*1E-3, " ms"
	

	if (KeySet("P",opt))
		Display; appendimage newvol
		//ColorTable
	endif
	print cmd
	return cmd
End


//----- old versions --------

Function ExtractSlice( islice, vol, imgn, dir )
//================
// Extract 2D slice from a 3D volume set; preserve scaling and units
// idir = direction index perpendicular to the 2D slice:  0=YZ, 1=XZ, 2=XY
// return avg intensity value  of slice
	wave vol
	variable islice, dir
	string imgn
	
	string voln=NameOfWave( vol )
	variable ix, iy, val
	iy=SelectNumber( dir==2, 2, 1)
	ix=SelectNumber( dir==0, 0, 1)
	variable nx, ny, nz
	nx=DimSize(vol, ix)
	ny=DimSize(vol, iy)
	
	Make/o/n=(nx,ny) $imgn
	WAVE img=$imgn	
	SetScale/P x  DimOffset(vol,ix), DimDelta(vol,ix), WaveUnits(vol,ix) img
	SetScale/P y  DimOffset(vol,iy), DimDelta(vol,iy), WaveUnits(vol,iy) img
	if (dir==2)
		img=vol[p][q][islice]
	else
	if (dir==1)
		img=vol[p][islice][q]
	else
		img=vol[islice][p][q]
	endif
	endif
	val=DimOffset(vol,dir)+islice*DimDelta(vol,dir)
	WriteImgNote(img, 0, 0, 0, 1, val, voln+"; "+"XYZ"[dir]+"=")
	
	Wavestats/Q img
	return V_avg
End


Function Imgs2Vol(imglst, opt)
//==============
// wvlist is either a string list or the name of a wave
	string imglst, opt
	
	variable nlst=ItemsInList(imglst,";"), Nz
	string imlst
	if ((nlst==1)*exists(imglst))	// string wave
		WAVE wvlst=$imglst
		Nz=numpnts(wvlst)
		imlst=Textw2List( wvlst, ";",0, Nz-1)
	else
		Nz=nlst
		imlst=imglst
	endif
	
	WAVE imw=$StringFromList(0, imlst)
	variable nx, ny
		nx=DimSize(imw, 0)
		ny=DimSize(imw, 1) 
		print nx, ny, nz
		
	//output volume
	string newvoln=KeyStr("D", opt)
	if ((strlen(newvoln)==0))
		newvoln="newvol"
	endif	
	make/O/N=(nx, ny, nz) $newvoln
	WAVE newvol=$newvoln
	CopyScales/P imw, newvol
	
	// Z-scale
	variable zmin=0, zinc=1
	string zscale =KeyStr("ZS",opt)
	if (strlen(zscale)>0)
		zmin=NumFromList(0, zscale,",")
		zinc=NumFromList(1, zscale,",")
	endif		
	SetScale/P z zmin,zinc, newvol
	print zmin, zinc
	
	variable ii=0
	FOR (ii=0; ii<Nz; ii+=1)
		WAVE imw=$StringFromList(ii, imlst)
		//newvol[][][ii]=imw[p][q]
		newvol[][][ii]=imw(x)[q]
		ENDFOR
	return 	1
end

Function ExtractSlice0( volw, islice, idir, imgn )
//================
// Extract 2D slice from a 3D volume set; preserve scaling and units
// idir = direction index perpendicular to the 2D slice:  0=YZ, 1=XZ, 2=XY
// return avg intensity value  of slice
	wave volw
	variable islice, idir
	string imgn
	
	variable nx, ny, nz
	nx=DimSize(volw,0)
	ny=DimSize(volw,1)
	nz=DimSize(volw,2)
	string xunit, yunit
	
	variable test=0
	IF (test)
		// Requires Graphical Slicer Igor extension to use 'Slice3d'
		//Slice3d( volw, idir+8, islice)
		//Duplicate/O Slice_Wave $imgn
		// Does not copy scalings; must do manually
	
	ELSE
	IF (nz==0)			// 2D instead of 3D volume
		idir=2
		duplicate/o volw $imgn
	ELSE
	variable xmin, xinc, ymin, yinc
	if (idir==2)						// X-Y
		make/o/n=(nx, ny) $imgn
		WAVE img=$imgn
		img=volw[p][q][islice]
		xmin=DimOffset( volw, 0); xinc=DimDelta( volw, 0); xunit=WaveUnits( volw, 0)
		ymin=DimOffset( volw, 1); yinc=DimDelta( volw, 1); yunit=WaveUnits( volw, 1)
	endif
	if (idir==1)						// X-Z
		make/o/n=(nx, nz) $imgn
		WAVE img=$imgn
		img=volw[p][islice][q]
		xmin=DimOffset( volw, 0); xinc=DimDelta( volw, 0); xunit=WaveUnits( volw, 0)
		ymin=DimOffset( volw, 2); yinc=DimDelta( volw, 2); yunit=WaveUnits( volw, 2)
	endif
	if (idir==0)						// Y-Z
		make/o/n=(ny, nz) $imgn
		WAVE img=$imgn
		img=volw[islice][p][q]
		xmin=DimOffset( volw, 1); xinc=DimDelta( volw, 1); xunit=WaveUnits( volw, 1)
		ymin=DimOffset( volw, 2); yinc=DimDelta( volw, 2); yunit=WaveUnits( volw, 2)
	endif
	SetScale/P x xmin, xinc, xunit img
	SetScale/P y ymin, yinc, yunit img
	ENDIF
	
	ENDIF
	
	Wavestats/Q img
	return V_avg
End


Function/T Vol2Images0( vol, basen, dir, inc )
//================
// Extract wave set from 3D array
// use image scaling for x-axis and y-value in wave note
// For dir=1, transpose image first
// specify output x-axis increment of wave set
//  "/dir=z/inc=2/Tile=2,3"
	Wave vol
	String basen
	Variable dir, inc
	
	
	inc=round( max(inc,1) )
	variable nx=DimSize(vol, 0), ny=DimSize(vol,1), nz=DimSize(vol,2)
//	print nx, ny, nz
	string imgn, voln=NameOfWave( vol )
	string imglst
	variable ii=0, val
	if (dir==0)
		nz=round(nz/inc)
		//print nx, ny, inc
		DO
			imgn=basen+num2str(ii)
			imglst+=imgn+";"
			Make/o/n=(nx,ny) $imgn
			WAVE img=$imgn	
			SetScale/P x  DimOffset(vol,0), DimDelta(vol,0), WaveUnits(vol,0) img
			SetScale/P y  DimOffset(vol,1), DimDelta(vol,1), WaveUnits(vol,1) img
			img=vol[p][q][ii*inc]
			val=DimOffset(vol,2)+ii*inc*DimDelta(vol,2)
			WriteImgNote(img, 0, 0, 0, 1, val, voln+"; Z=")
	   		//print ii, ii*inc, val
			ii+=1
		WHILE( ii<nz)
		//return nz
	endif
	if (dir==1)
		ny=round(ny/inc)
		//print nx, ny, inc
		DO
			imgn=basen+num2str(ii)
			Make/o/n=(nx,nz) $imgn
			WAVE img=$imgn	
			SetScale/P x  DimOffset(vol,0), DimDelta(vol,0), WaveUnits(vol,0) img
			SetScale/P y  DimOffset(vol,2), DimDelta(vol,2), WaveUnits(vol,2) img
			img=vol[p][ii*inc][q]
			val=DimOffset(vol,1)+ii*inc*DimDelta(vol,1)
			WriteImgNote(img, 0, 0, 0, 1, val, voln+"; Y=")
	   		//print ii, ii*inc, val, note(img)
			ii+=1
		WHILE( ii<ny)
		//return ny
	endif
	if (dir==0)
		nx=round(nx/inc)
		//print nx, ny, inc
		DO
			imgn=basen+num2str(ii)
			Make/o/n=(ny,nz) $imgn
			WAVE img=$imgn	
			//CopyScales vol, img
			SetScale/P x  DimOffset(vol,1), DimDelta(vol,1), WaveUnits(vol,1) img
			SetScale/P y  DimOffset(vol,2), DimDelta(vol,2), WaveUnits(vol,2) img
			img=vol[ii*inc][p][q]
			val=DimOffset(vol,0)+ii*inc*DimDelta(vol,0)
			WriteImgNote(img, 0, 0, 0, 1, val, voln+"; X=")
	   		//print ii, ii*inc, val, note(img)
			ii+=1
		WHILE( ii<nx)
		//return nx
	endif
	return imglst
End

Function/T Vol2Images1( vol, basen, dir, inc )
//================
// Extract set of image slices from 3D array
// use image scaling for x-axis and y-value in wave note
// For dir=1, transpose image first
// specify output x-axis increment of wave set
//  "/dir=z/inc=2/Tile=2,3"
	Wave vol
	String basen
	Variable dir, inc
	
	inc=round( max(inc,1) )
	
	variable ix, iy, iz
	iz=dir
	iy=SelectNumber( dir==2, 2, 1)
	ix=SelectNumber( dir==0, 0, 1)
	variable nx, ny, nz
	nx=DimSize(vol, ix)
	ny=DimSize(vol, iy)
	nz=DimSize(vol, dir)
	nz=round(nz/inc)
	
	//print ix, iy, iz, nx, ny, nz
	string imgn, voln=NameOfWave( vol )
	string imglst=""
	variable ii=0, val
	DO
		imgn=basen+num2str(ii)
		imglst+=imgn+";"
		Make/o/n=(nx,ny) $imgn
		WAVE img=$imgn	
		SetScale/P x  DimOffset(vol,ix), DimDelta(vol,ix), WaveUnits(vol,ix) img
		SetScale/P y  DimOffset(vol,iy), DimDelta(vol,iy), WaveUnits(vol,iy) img
		if (dir==2)
			img=vol[p][q][ii*inc]
		else
		if (dir==1)
			img=vol[p][ii*inc][q]
		else
			img=vol[ii*inc][p][q]
		endif
		endif
		val=DimOffset(vol,dir)+ii*inc*DimDelta(vol,dir)
		WriteImgNote(img, 0, 0, 0, 1, val, voln+"; "+"XYZ"[dir]+"=")
   		//print imgn, ii, ii*inc, val
		ii+=1
	WHILE( ii<nz)
	return imglst
End


Proc Vol_ControlBar()
//-----------
	string vlst=WaveList("*",";","Win:,DIMS:3")
	string voln=StringFromList(0,vlst)
	
	if (exists(voln))
		variable nlayer1=DimSize($voln,2) - 1
		//print voln, nlayer1
			//string/G volnam=voln	//put in special graph-specific folder ?
			//variable/G iplane
	else
		abort "no 3D array in top graph"
	endif
	ControlInfo kwControlBar		// sets V_height
	//print V_height
	variable addctrl=SelectNumber(V_height==0, 0,1)
	if (addctrl)
		GetWindow kwTopwin gsize		//-> V_right gives width
		ControlBar 45
		ValDisplay PlaneVal, bodyWidth=30,  fsize=9, value=0    
		//Slider PlaneSlide size={200,35}, vert=0, fsize=8
		Slider PlaneSlide size={0.4*V_right,35}, vert=0, fsize=8
		Slider PlaneSlide limits={0,nlayer1,1},  proc=SelectPlane //, variable=iplane
		//SetVariable PlaneVar, variable=iplane,  title=" ", bodyWidth=50, fsize=9
		variable zval=DimOffset($voln,2) //+sliderValue*DimDelta($voln,2)
		ValDisplay PlaneZVal, bodyWidth=40,  fsize=9, title="Z" //, value=zval
		execute "ValDisplay PlaneZVal value="+num2str(zval)
		Checkbox Kill,  title="Kill", proc=Vol_KillControl, mode=1
		Checkbox autoCT, title="CT rescale", mode=0, pos={0.4*V_right+80,20}
		//PopupMenu VolOrderPop value="XY/Z;YX/Z;XZ/Y;ZX/Y;YZ/X;ZY/X", proc=VolReorderPop
		PopupMenu VolOrderPop value="X<>Y;X<>Z;Y<>Z;X<>YZ;XY<>Z", proc=Vol_TransposePop
		PopupMenu VolOrderPop mode=0, title="Axes", pos={2,18}
		PopupMenu VolOrderPop help={"Transpose Axes"}
	else
		print "Control Bar already exists"
	endif

End

Function SelectPlane(ctrlName,sliderValue,event) : SliderControl
//==============
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

	//SVAR volnam=volnam
	string voln=StringFromList(0, WaveList("*",";","Win:,DIMS:3") )
	ControlInfo autoCT
	variable CTrescale=V_value
	
	variable CTmode=1, CTrev=0
	string CTstr=colorTableStr("",voln), CTnam=""
	string volCTwn=StringByKey( "cindex", CTstr, "=", "," )
	if (strlen(volCTwn)>0)
		if (stringmatch(volCTwn[0]," "))
			volCTwn= volCTwn[1,strlen(volCTwn)-1]		//strip off initial space (after =)
		endif
		CTmode=1
	else
		CTmode=0
		CTnam=StringFromlist(2, CTstr,",")
		CTrev=str2num(StringFromlist(3, CTstr,","))
		//CTrescale=0    //abort "Using Igor built-in Color Table: "+colorTableStr("",imgn)
	endif
	
	
	//string volCTwn=voln+"_CT"		// get from colortablestr()

	variable zval=DimOffset($voln,2) +sliderValue*DimDelta($voln,2)
	if(event %& 0x1)	// bit 0, value set
		//ModifyImage $volnam plane=sliderValue
		ModifyImage $voln plane=sliderValue
		if (CTrescale)
			ImageStats/M=1/P=(sliderValue) $voln
			//print V_min, V_max, volCTwn, CTmode, CTnam, CTrev
			if (CTmode==1)
				WAVE volCTw=$volCTwn
//				CTstr=CTreadnote( volCTw )
//				CTrev=str2num(StringByKey( "invert", CTstr, "=", "," ) )
				//SetScale/I x V_min, V_max,"" $volCTwn
//				CTsetscale( volCTw, V_min, V_max, CTrev)		// check for invert CT 
				CTsetscale( volCTw, V_min, V_max, -1)		// 0 = auto-detect invert
				//print V_min, V_max, CTrev
			else
				ModifyImage $voln ctab= {V_min,V_max,$CTnam,CTrev}  //ctab method
			endif
		endif
		//SetVariable PlaneVar value=sliderValue
		execute "ValDisplay PlaneVal value="+num2str(sliderValue)
		execute "ValDisplay PlaneZVal value="+num2str(zval)
	endif

	return 0
End


Function Vol_KillControl(ctrlName,checked) : CheckBoxControl
//=================
	String ctrlName
	Variable checked
	
	KillControl Kill
	KillControl autoCT
	KillControl VolOrderPop
	KillControl PlaneVal
	KillControl PlaneZVal
	KillControl PlaneSlide
	ControlBar 0
End

Function Vol_ReorderPop(ctrlName,popNum,popStr) : PopupMenuControl
//================
	String ctrlName
	Variable popNum
	String popStr

	string voln=StringFromList(0, WaveList("*",";","Win:,DIMS:3") )
	//WAVE vol=$voln
	//string ordr=popStr[0,1]+popStr[3]
	string ordr=SelectString(popNum==2, "YXZ", "ZYX")		// 1=X<>Y, 2=X<>Z
	ordr=SelectString(popNum==3, ordr, "XZY")				// 3=Y<>Z
	
	VolReorder($voln,"/O/"+ordr)			//overwrite
	
	// Update controls for new Z range
	variable newZ=1
	if (newZ)
		variable nlayer1=DimSize($voln,2) - 1
		Slider PlaneSlide limits={0,nlayer1,1}
		variable zval=DimOffset($voln,2) //+sliderValue*DimDelta($voln,2)
		ValDisplay PlaneZVal, bodyWidth=40,  fsize=9, title="Z" //, value=zval
		execute "ValDisplay PlaneZVal value="+num2str(zval)
	endif
End

Function Vol_TransposePop(ctrlName,popNum,popStr) : PopupMenuControl
//================
	String ctrlName
	Variable popNum
	String popStr

	string voln=StringFromList(0, WaveList("*",";","Win:,DIMS:3") )
	//WAVE vol=$voln
	//string ordr=popStr[0,1]+popStr[3]
	string ordr="YXZ"									// 1=X<>Y,
		ordr=SelectString(popNum==2, ordr, "XZY")		// 2=X<>Z
		ordr=SelectString(popNum==3, ordr, "XZY")		// 3=Y<>Z
		ordr=SelectString(popNum==4, ordr, "YZX")		// 4=X<>YZ
		ordr=SelectString(popNum==5, ordr, "ZXY")		// 5=XY<>Z
	
	//VolReorder($voln,"/O/"+ordr)			//overwrite  - slower method
	VolTranspose($voln,"/O/"+ordr)			//overwrite
	
	// Update controls for new Z range
	variable newZ=1
	if (newZ)
		variable nlayer1=DimSize($voln,2) - 1
		Slider PlaneSlide limits={0,nlayer1,1}
		variable zval=DimOffset($voln,2) //+sliderValue*DimDelta($voln,2)
		ValDisplay PlaneZVal, bodyWidth=40,  fsize=9, title="Z" //, value=zval
		execute "ValDisplay PlaneZVal value="+num2str(zval)
	endif
End


function interp_3d( vol, xx, yy, zz )
//=============
// wrapper for builtin interp3d function to take care of boundary effects that
// erroneously return NaN.  The fix is to add or subtract a small number 
// (depending on the sign of the axis scaling) to get the interpolation to be just
// within the scaling boundary of source volume.
// 3/30/09 fixed in beta version 6.10b06 of Igor, should be included in Igor release >6.05.
// ** wrapper loses efficiency of implicit do-loop in builtin interp3d() function -> runs 10X slower
// => not a good solution;  need to apply boundary delta-shift in desired functions.
	Wave vol
	variable xx, yy, zz
	If (NumberByKey("IGORVERS", IgorInfo(0))==6.1)
		return interp3d( vol, xx, yy, zz )
	else
		variable del=1E-9
		variable xinc=DimDelta(vol,0), yinc=DimDelta(vol,1), zinc=DimDelta(vol,2)
		return interp3d( vol, xx-sign(xinc)*del, yy-sign(yinc)*del, zz-sign(zinc)*del )
	endif
end









