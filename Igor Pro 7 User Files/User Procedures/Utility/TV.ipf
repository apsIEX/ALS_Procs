// File: tv   	~9/96
// Jonathan Denlinger, JDDenlinger@lbl.gov
//  3/27/97 JDD  -- moved bytscl and ByteScale from 'ColorTables'
// 6/8/00 jdd added ballon help info

#pragma rtGlobals=1		// Use modern global access method.
//#include "ColorTables"		//includes bytscl

menu "2D"
	"-"
	"Byte Scale"
		help={"rescale image values to 0-255"}
	Submenu "Shortcut Funcs"
		"fct BYTSCL im, ow"
			help={"rescale image values to 0-255"}
		"fct TV im"
			help={"short cut for 'display; appendimage'"}
		"fct TVSCL im"
			help={"display byte-scaled version of image '_b'"}
		"fct TVXY im, imx, imy"
			help={"short cut for MxN image display with M+1 & N+1 axis arrays'"}
		"fct TV_XY im"
			help={"short cut for image display with 'im_x', 'im_y' axis names assumed'"}
		"fct TV2XY im"
			help={"short cut,  creates 'im_x', 'im_y' from scaling"}
		"fct AXISW w, 'ow'  -- create np+1 wave"
			help={" create N+1 wave from N wave for axis plotting"}
	End
end

proc ByteScale(wv, dest)
//--------------------
	string wv;variable dest
	prompt wv,"Wave to convert to 0-255", popup, ImageNamelist("",";")
	prompt dest,"Destination",popup "new (_b);overwrite"
	silent 1;pauseupdate
	string ow=wv
	if (dest==1)
		ow+="_b"
	endif
	ow=BYTSCL( $wv, ow )

	print "byte-scaled data stored in: "+ow
end

function/T bytscl(im, outw)
//===================
	wave im
	string outw
	
	string imn=NameOfWave(im)
	if (strlen(outw)==0)				//""=overwrite
		outw=imn
	endif
	if (cmpstr(outw[0], "_")==0)		//postfix given
		outw=imn
	endif
	if (cmpstr(imn, outw)!=0)			//new output image
		duplicate/o im $outw
	endif
	WAVE ow=$outw
	wavestats/q im
	ow-=v_min
	ow*=255/(v_max-v_min)
	return outw
end


function TV(  w2d )
//===============
// shortcut for basic image plot
	wave  w2d
	display; appendimage  w2d
	variable notscl=DimDelta( w2d, 0)*DimDelta( w2d, 1)
	if (notscl==1)
		print "Unscaled image"
	endif
	//ModifyGraph height={Plan,1,left,bottom}
	if (wintype(NameOfWave( w2d)+"_")==0)
		DoWindow/C $(NameOfWave( w2d)+"_")
	endif
end

function TVSCL(  w2d )		// byte scales first to 0-255
//===============
// shortcut for basic image plot
	wave  w2d
	string wn=NameOfWave( w2d), ow
	ow=wn+"_b"
	BYTSCL( w2d, ow )
	display; appendimage  $ow
	DoWindow/C $(wn+"_")
	variable notscl=DimDelta( w2d, 0)*DimDelta( w2d, 1)
	if (notscl==1)
		print "Unscaled image"
	endif
end


function TV_XY( w2d )
//======================
// image plot [n x m] with *_x wave [n] and *_y wave [m] assumed
	wave w2d
	string wn=NameOfWave(w2d)
	wave wx=$(wn+"_x"), wy=$(wn+"_y")
	tvxy( w2d, wx, wy )
end

function TVXY( w2d, wx, wy )
//======================
// image plot [n x m] with xwave [n] and y wave [m] specified
	wave w2d, wx, wy
	string wn=NameOfWave(w2d)
	variable nx=DimSize(w2d,0), ny=DimSize(w2d,1)
	
	string wx1=wn+"1", wy1=wn+"2"
	axisw( wx, wx1, 1 )
	axisw( wy, wy1, 1 )
	string cmd="display; appendimage "+wn+" vs { "+wx1+", "+wy1+" }"
	print cmd
	execute cmd
	//straight execution doesn't work - gives mismatch of npts
	//display; appendimage w2d vs { $wx1, $wy1 }
	DoWindow/C $(NameOfWave( w2d )+"_")	
end

function AXISW( wv, ow, opt )
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

function TV2XY( w2d )
//======================
//  create X & Y waves from image scaling & plot IM vs {X, Y}
	wave w2d
	variable nx=DimSize(w2d,0), ny=DimSize(w2d,1)
	string wn=NameOfWave(w2d)
	make/o/n=(nx+1) $(wn+"_x")
	make/o/n=(ny+1) $(wn+"_y")
	WAVE wx1=$(wn+"_x"), wy1=$(wn+"_y")
	wx1=DimOffset(w2d,0)+(p-0.5)*DimDelta(w2d,0)
	wy1=DimOffset(w2d,1)+(p-0.5)*DimDelta(w2d,1)
	//tvxy( w2d, wx, wy )
	string cmd="display; appendimage "+wn+" vs { "+wn+"_x, "+wn+"_y }"
	print cmd
	execute cmd
	//print numpnts(wx1), numpnts(wy1)
	//display; appendimage w2d vs { wx1, wy1 }
end