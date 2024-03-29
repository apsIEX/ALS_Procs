//File: volume				created 6/7/00 
//Jonathan Denlinger, JDDenlinger@lbl.gov 
// 7/8/02 jdd added Shift Vol and VolCrop, VolModify() for Image_Tool
// 8/18/02 jdd added ExtractAvgSlice() modified from ExtractSlice()

#pragma rtGlobals=1		// Use modern global access method.
#include "image_util"		//uses WriteImgNote()

Menu "3D"
	"AppendImg"
		help={"Append 2D image to 3D volume array"}
	Submenu "Volume Funcs"
		"fct Extract Slice vol, index, dir, imgnam"
			help={"Extract 2D image from 3D volume array; preserve scaling & units"}
		"fct/T Vol2Images vol, basen, opt "
			help={"Extract image slices from volume, /X/Y/Z, /INC=inc, /PLOT, /TILE"}
		"fct NormVol volw, idir, outvolnam"
			help={"Normalize volume along selected direction by average value of orthogonal slices"}

	End
End


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

Function ExtractAvgSlice( i1, i2, vol, imgn, dir )
//================
// Extract and sum 2D slices from a 3D volume set; preserve scaling and units
// idir = direction index perpendicular to the 2D slice:  0=YZ, 1=XZ, 2=XY
// return avg intensity value  of slice
	wave vol
	variable i1,i2, dir
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
	
	variable nslices=abs(i2-i1)+1, inc=sign(i2-i1)
	variable ii=0, islice
	img=0
	DO
		islice=i1+ii*inc
		if (dir==2)
			img+=vol[p][q][islice]
		else
		if (dir==1)
			img+=vol[p][islice][q]
		else
			img+=vol[islice][p][q]
		endif
		endif
		ii+=1
	WHILE(ii<nslices)
	img/=nslices
	val=DimOffset(vol,dir)+0.5*(i1+i2)*DimDelta(vol,dir)
	WriteImgNote(img, 0, 0, 0, 1, val, voln+"; "+"XYZ"[dir]+"=")
	
	Wavestats/Q img
	return V_avg
End



Proc AppendImg( voln, imgn )
//-------------
// Append 2D (image) array to a 3D (volume) array
// or create 3D array from 2D arrays
	string voln=StringFromList(0, ImageNameList("",";"))
	string imgn
	prompt voln, "base 3D or 2D array", popup, " --3D --;"+WaveList("!*_CT",";","DIMS:3")+"-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	prompt imgn, "2D array to append", popup, WaveList("!*_CT",";","DIMS:2")
	
	variable ndim0=WaveDims( $voln), ndim1=WaveDims( $imgn)
	variable nx0=DimSize( $voln, 0), ny0=DimSize($voln, 1), nz0=DimSize($voln,2)
	variable nx1=DimSize( $imgn, 0), ny1=DimSize($imgn, 1)
	nz0=SelectNumber( nz0==0, nz0, 1)
	
	if ((nx0==nx1)*(ny0==ny1))
		Redimension/N=(nx0, ny0, nz0+1) $voln
	
		$voln[][][nz0]=$imgn[p][q]
		print "nx,ny,nz=", nx0, ny0, nz0+1
	else
		string errorStr="Mismatch in Image sizes:"
		errorStr+="nx="+num2str(nx0)+"/"+num2str(nx1)
		errorStr+=",  ny="+num2str(ny0)+"/"+num2str(ny1)
		Abort errorStr
	endif
End

Function/T Vol2Images( vol, basen, opt )
//================
// Extract set of image slices from 3D array
// use image scaling for x-axis and y-value in wave note
// Options:
//     /X, /Y, /Z (def)   - direction of slicing
//     /INC=inc     - point increment of slicing (default=1)
	Wave vol
	String basen, opt
	
	Variable dir=2, inc=1
	dir=SelectNumber( KeySet("X", opt), dir, 1)
	dir=SelectNumber( KeySet("Y", opt), dir, 2)
	
	inc=trunc(KeyVal("INC", opt))
	inc=SelectNumber(inc>0 ,1, inc)
	//inc=round( max(inc,1) )
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
		ExtractSlice( ii*inc, vol, imgn, dir )
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

Function NormVol( volw, idir,outvoln )
//================
// Normalize volume along selected direction by average value of orthogonal slices 
	wave volw
	variable  idir
	string outvoln
	
	variable NP
	NP=DimSize(volw, idir)
	
	NewDataFolder/O root:tmp
	Make/O/N=(NP) root:tmp:avgw
	WAVE avgw=root:tmp:avgw
	variable ii=0
	DO
		Slice3d( volw, idir+8, ii)
		WaveStats/Q Slice_Wave
		avgw[ii]=V_avg
	
		ii+=1
	WHILE( ii<NP)
	
	Duplicate/O volw, $outvoln
	WAVE outvol=$outvoln
	if (idir==0)
		outvol=volw/avgw[p]
	endif
	if (idir==1)
		outvol=volw/avgw[q]
	endif
	if (idir==2)
		outvol=volw/avgw[r]
	endif
	
	return NP
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

Function/T ShiftVol( vol, shiftw, opt)
//=================
// Shifts (subtraction)volume according to specified wave (subtraction)
// adapt from ShiftImg()
// Options:
//    Shift wave: /XW=x_shiftwn or /XW - shift_x  (default=scaled shift wave)
//    Direction & Shift:  /XY, /XZ, /YX, /YZ, /ZX, /ZY  (default=/XY)
//    Output:      /O=outw (default=img_shftx or img_shfty), /O (=overwrite)
//    Output dimension:  /E=expand  (-1=shrink, 0=avg, 1=expand)
//
	wave vol, shiftw
	string opt
	
	string voln=NameOfWave(vol), shiftn=NameOfWave(shiftw) 
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
	
// output volume
	string outw
	outw=SelectString( KeySet("O",opt), voln+"_shft"+"xyz"[dir], KeyStr("O",opt))
	variable V_overwrite=Keyset("O",opt)*(strlen( KeyStr("O",opt) )==0)
	outw=SelectString( V_overwrite, outw, "root:tmp:vtmp")
	//print outw, V_overwrite, dir, dir1
	
	Make/O/N=(nx,ny,nz) $outw
	WAVE newvol=$outw
	SetScale/P x xmin,xinc,WaveUnits(vol,0) newvol
	SetScale/P y ymin,yinc,WaveUnits(vol,1) newvol
	SetScale/P z zmin, zinc,WaveUnits(vol,2) newvol

//requires MDinterpolator Igor Extension
	string cmd=outw+"=interp3D("+voln+","
	if (V_scaled)
		if (dir==0)
			if (dir1==1)		// XY
				cmd+="x+"+shiftn+"(y), y, z )"
				newvol=interp3D(vol, x+shiftw(y), y, z)
			else 				// XZ
				cmd+="x+"+shiftn+"(z), y, z )"
				newvol=interp3D(vol, x+shiftw(z), y, z)
			endif
		endif
		if (dir==1)
			if (dir1==0)		// YX
				cmd+="x, y+"+shiftn+"(x), z )"
				newvol=interp3D(vol, x, y+shiftw(x), z)
			else 				// YZ
				cmd+="x, y+"+shiftn+"(z), z )"
				newvol=interp3D(vol, x, y+shiftw(z), z)
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
				newvol=interp3D(vol, x+interp(y, shiftx, shiftw), y, z)
			else 				// XZ
				cmd+="x+interp(z,"+shiftxn+","+shiftn+"), y, z )" 
				newvol=interp3D(vol, x+interp(z, shiftx, shiftw), y, z)
			endif
		endif
		if (dir==1)
			if (dir1==0)		// YX
				cmd+="x, y+interp(x,"+shiftxn+","+shiftn+"), z )"
				newvol=interp3D(vol, x, y+interp(x, shiftx, shiftw), z)
			else 				// YZ
				cmd+="x, y+interp(z,"+shiftxn+","+shiftn+"), z )"
				newvol=interp3D(vol, x, y+interp(z, shiftx, shiftw), z)
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
	
	if (V_overwrite)
		Duplicate/o newvol vol
		//Killwaves/Z newvol
	endif
	
	return cmd
End

Function/T VolCrop( vol, opt )
//================
	wave vol
	string opt
	
	//output volume
	string newvoln=KeyStr("O", opt)
	variable overwrite=KeySet("O", opt)*(strlen(newvoln)==0)
	newvoln=SelectString(overwrite, newvoln, "root:tmp:vol_tmp")
	
	// crop range
	string xrng=KeyStr("X", opt), yrng=KeyStr("Y", opt), zrng=KeyStr("Z", opt)
	variable x1, x2, y1, y2, z1, z2
	x1=NumFromList(0, xrng,","); x2=NumFromList(1, xrng,","); 
	y1=NumFromList(0, yrng,","); y2=NumFromList(1, yrng,","); 
	z1=NumFromList(0, zrng,","); z2=NumFromList(1, zrng,","); 
	
	Duplicate/O/R=(x1,x2)(y1,y2)(z1,z2) vol, $newvoln
	
	if (overwrite)
		Wave volnew=$newvoln
		Duplicate/O volnew, vol
		//Killwaves/Z volnew
	endif
	
	return "no error"
End

Proc VolModify(ctrlName, popNum,popStr) : PopupMenuControl
//------------------------  for Image_Tool
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
	
	//variable/C coffset=GetWaveOffset(root:IMG:HairY0)
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
		AdjustCT()
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

		 AdjustCT()
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

		 AdjustCT()
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
		AdjustCT()
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
		AdjustCT()
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
		AdjustCT()
	endif
	if (cmpstr(popStr,"Invert Z")==0)
		Image=-Image_Undo
		AdjustCT()
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
	
	if (cmpstr(popStr,"ExtractAvgSlice")==0)

		ExtractAvgSlice( pcsr(A), pcsr(B), $datnam, "root:IMG:Image", 3-islicedir )
	
	endif

	
	ImgInfo( Image )
 	SetProfiles()	
	SetHairXY( "Check", 0, "", "" )
	imgproc+="+ "+popStr			// update this after operation incase of intermediate macro Cancel
	ReplaceText/N=title "\Z09"+imgnam+": "+imgproc
	
	SetDataFolder curr
End



