//File:  Wav_util		created:  1/97 J. Denlinger
//
//  Modifications:
//  8/3/08 -- added ZapUnit( wv) 
//  12/08/07  - create fct DeleteXYrange(xw, yw, opt)
//  5/24/06 -- fix _x wave naming for DuplicateGraph()
// 12/11/05  --take care of GraphMarquee menu item: NoiseStats
//  8/28/05 jdd      --added FindPeaks()
//  6/20/04 jdd   	-- added IntegrateReg() updated from BkgSubtract.ipf
//  6/18/04  jdd    	-- update MkGrid range specification & keyword options
//  2/23/03 jdd      -- fancied up SaveWave()
//  1/1/02   jdd	-- replaced num2str with sprintf "%.9g" in WriteMod
//  5/25/01  jdd     -- created new scalewave2 with keystring options
//  5/22/01  jdd     -- more DupicateGraoh naming options + Y vs X support
//  11/19/00 jdd	-- added DeleteValues
//  12/27/99 jdd	-- added x2point
//  1/11/99  jdd	-- added ScaleWave
//   5/11/98	jdd	-- added NoiseStats marquee
//  ?/97 jdd 		-- added DeGlitch

#pragma rtGlobals=1		// Use modern global access method.
#include "List_util"
#include "Tags"      // FindPeaks option

//Fct 	ReadMod( w )
//Fct 	WriteMod(w, val1, val2, val3, styl1, styl2, styl3, mode)
//Fct/T 	ScaleWave( wv, xwn, dim, method )
//Fct 	RescaleWave( rng, Np, own )
//Fct		MkRange( min, max, inc, np, own )
//Fct		Reverse( w )
//Fct		MkGrid(xr,yr, xwn, ywn, opt)			
//Fct 	Expand2d( wv, ny )
//Fct 	AppendNAN( wv, idim )
//Fct 	Interlace( aw, bw, own, opt )
//Macro  SaveWave(wn, opt, xi, xf, xinc )
//Win	SaveTable() 					: Table
//Proc 	Deglitch( opt )					-- put cursor(A) on errant point  & run
//Fct 	NoiseTag()					: GraphMarquee
//Fct 	NoiseStats()					: GraphMarquee
//Fct 	RenameList( oldstr, newstr, mode)
//Proc 	SmoothGraph(winnam, ns)
//Macro  InsertNAN()        -- Top graph at A cursor
//Fct 	val2pnt( w, xval )
//Fct 	x2pntM( w, xval, dim )
//Fct 	x2pntNAN( w, xval )
//Fct 	x2point( w, xw, xval )
//Fct 	CondVAL( val1, cond, outval)
//Proc 	RenameWaves( oldstr, newstr, mode )
//Fct 	RenameList( oldstr, newstr, mode)
//Fct/T 	GetRange( w, dir )
//Fct/C 	DeleteValues( cond, wav1, wav2)
//Fct	FindPeaks( arr, opt)

Menu "Macros"
	"-"
	"ZapUnits"
	"InsertNAN"
	"SaveWave"
	"Deglitch"
	"NoiseTag" 
	"SmoothGraph"
	"DuplicateGraph"
	"RenameWaves"
	Submenu "Wave Functions"
		"Fct\T  ReadMod{ w }"
		"Fct\T WriteMod{ w, shft, off, gain, lin,  thk, clr, val, txt}"
		"Fct\T  ScaleWave{ wv, xwn, dim, method }"
		"Fct\T  ScaleWave2{ wv, opt }"
		"Fct RescaleWave{ rng, Np, own }"
		"MkRange{ min, max, INC, 0, own } - calc NP"
		"MkRange{ min, max, 0, NP, own } - calc INC"
		"Reverse{ wv }  - 1D"
		"MkGrid{ xr,yr, xwn, ywn, opt } - opt=1,2"	
		"Expand2d{ wv, ny } - 1D �> 2D"
		"AppendNAN{ wv, idim } - to row or col"
		"Interlace{ aw, bw, own, opt } - opt=1, NAN"
		"RenameList{ oldstr, newstr, mode}"
		"Fct\T 	GetRange{ w, dir }"
		"val2pnt{ w, xval }"
		"x2pntM{ w, xval, dim } - multi-dim"
		"x2pntNAN{ w, xval }"
		"CondVAL{ val1, cond, outval }"
		"Fct\C DeleteValues{ cond, wav1, wav2}"
		"Fct/T ExtractName{ filenam, opt}"
		"Fct FindPeaks{ arr, opt}"
	End
End

menu "GraphMarquee"
	"-"
	submenu "Misc"
		"1D: NoiseStats", NoiseStats()
	end
end

Function/T ReadMod( w )		//, destwn )
//============
	wave w
	string destwn
	string noteStr, modlst
	noteStr=note(w)
	modlst=StringByKey( "MOD", noteStr, ":", "\r" )
	if (strlen(modlst)==0)					// no wave mod keywords
		modlst=ReadMod_old(w)			// check for previous method of storing values
		if (strlen(modlst)==0)		
	   		Note/K w
	   		//modlst="SHIFT=0,OFFSET=0,GAIN=1,LIN=0,THK=0.5,CLR=0,VAL=0,TXT= ;"
	   		modlst="Shift=0,Offset=0,Gain=1,Lin=0,Thk=0.5,Clr=0,Val=0,Txt= "
	   		Note w, "MOD:"+modlst+"\r"+noteStr		// pre-pend default
   		endif
   	endif
	return modlst
	//print noteStr
	//string moddef="MOD:SHIFT=0,OFFSET=0,GAIN=1,LIN=0,THK=0.5,CLR=0,VAL=0,TXT= ;"
	//string moddef="MOD=0,0,1;STYLE=0,0.5,0;VAL=0,TXT= ;"
	//string styledef="STYLE:lin=0,thk=0.5,clr=0;"
	//string annodef="ANNO:val=0,txt= ;"
End

Function/T ReadMod_old( w )		//, destwn )
//============
	wave w
	string destwn
	string noteStr, modlst=""
	noteStr=note(w)
	if (strlen(noteStr)>0)
		variable shft, off, gain, lin, thk, clr, val
		shft=ValFromList( noteStr, 0, ",")
		if (numtype(shft)==0)					// no wave mod keywords
			off=ValFromList( noteStr, 1, ",")
			gain=ValFromList( noteStr, 2, ",")
			lin=ValFromList( noteStr,3, ",")
			thk=ValFromList( noteStr, 4, ",")
			clr=ValFromList( noteStr, 5, ",")
			val=ValFromList( noteStr, 6, ",")
	   		Note/K w								// remove old values (and everything else?)
			modlst=WriteMod(w, shft, off, gain, lin,  thk, clr, val,"")
	   	endif
   	endif
	return modlst
End

Function/T WriteMod(w, shft, off, gain, lin,  thk, clr, val, txt)
//=============
	wave w
	variable shft, off, gain, lin, thk, clr, val
	string txt
	string notestr, modlst
	//modlst="SHIFT="+num2str(shft)+",OFFSET="+num2str(off)+",GAIN="+num2str(gain)
	//modlst+=",LIN="+num2str(lin)+",THK="+num2str(thk)+",CLR="+num2str(clr)
	//modlst+=",VAL="+num2str(val)+",TXT="+txt
	// ** num2str limited to about 6 significant digits 
	// ** large number shifts will have decrease decimal 
	//modlst="Shift="+num2str(shft)+",Offset="+num2str(off)+",Gain="+num2str(gain)
	sprintf modlst, "Shift=%.9g,Offset=%.9g,Gain=%.9g", shft, off, gain
	modlst+=",Lin="+num2str(lin)+",Thk="+num2str(thk)+",Clr="+num2str(clr)
	modlst+=",Val="+num2str(val)+",Txt="+txt
	notestr=note(w)
	notestr=ReplaceStringByKey("MOD", notestr, modlst, ":", "\r")
   	Note/K w			//kill previous note
   	Note w, noteStr
   	return modlst
end

Function val2pnt( w, xval )
//=====================
//returns fractional index
	wave w
	variable xval
	variable np=DimSize(w, 0)
	WAVE indx=indx
	if (exists("indx")==0)
	 	if (np!=DimSize(indx,0))
			make/o/n=(np) indx=p
		endif
	endif
	return interp(xval, w, indx)
End

Function x2pntM( w, xval, dim )
//=====================
//Multi-dimensional x2pnt with Rounding to nearest integer
//inherently handles NaN, �INF correctly
// do not round to nearest integer if dim<0  (use -.1 for -0)
	wave w
	variable xval, dim
	variable d=abs(trunc(dim))
	variable pt=(xval - DimOffset(w, d))/DimDelta(w,d)
	if (dim>=0 )
		pt=round( pt )
	endif
	return pt
End

Function x2pntNAN( w, xval )
//=====================
//return NaN,�INF when x=NaN or �INF
//x2pnt() returns large E09 number when x=NaN
// use new SelectNumber built-in function
	wave w
	variable xval
	return SelectNumber( numtype(xval)==0, xval, x2pnt( w, xval) )
	
	//if (numtype(xval)==0) 		// normal number
	//	return x2pnt( w, xval)
	//else
	//	return xval
	//endif
End

Function x2point( w, xw, xval )
//=====================
// generalized x2pnt to include Y vs X wave plotting
// point value is a real number that can be trunc or rounded to an integer
// ** if not x-wave then returns x2pnt() which is an integer
	wave w
	string xw
	variable xval
	
	if (strlen(xw)==0)			//scaled y-wave; same as x2pnt
		if (numtype(xval)==0)
			return x2pnt(w, xval)		// integer value
		else
			return xval				//Nan or INF
		endif
	else
		if (stringmatch(xw[0],"_"))
			xw=NameOfWave(w)+xw
		endif
		//print xw, waveexists($xw)
		if (waveexists($xw))
			NewDataFolder/O root:tmp
			make/o/n=(numpnts($xw)) root:tmp:pxw=p
			return interp(xval, $xw, root:tmp:pxw)
		else
			return NAN
		endif
	endif
End

Function CondVAL( val1, cond, outval)
//--------------------
//designed to easly handle replacement of values by NAN
// - not easily done in a single command line
	string cond
	variable val1, outval
	
	variable/G res
	execute "res="+num2str(val1)+cond
	if (res) 
		return outval
	else
		return 0
	endif
End

Macro InsertNAN()
//------------
	PauseUpdate; Silent 1
	string wn=CsrWave(A), xwn=CsrXWave(A)
	variable pt=pcsr(A)
	InsertPoints pt,1, $wn, $xwn
	$wn[pt]=nan
	$xwn[pt]=nan
End

function/T ScaleWave( wv, xwn, dim, method )
//=========================
// scale n-dim wave to x-wave values for specified dimension 
// 2D wave to both x and y values
// methods: 0 - Point, 1-inclusive, 2 - reinterpolated
	wave wv
	string xwn
	variable dim, method
	variable ndim=WaveDims(wv)
	if (dim>=ndim)
		return "dimension out of range: "+num2str(ndim)
	endif
	//string wvn=NameOfWave(wv)
	string wvn=GetWavesDataFolder(wv, 2)			// returns full data folder path and name
	string cmd
	variable incr, np
	if (strlen(xwn)>0)
		if (cmpstr(xwn[0],"_")==0)
			xwn=wvn+xwn
		endif
		WAVE xw=$xwn
		//WaveStats/Q $xwn
		//SetScale/I x V_min,V_max, "" wv
		if (method==0)
			cmd="SetScale/P "+"xyzt"[dim]+" "
			cmd+=num2str(xw[0])+", "+num2str( xw[1]-xw[0])
		else
			np=numpnts(xw)
			cmd="SetScale/I "+"xyzt"[dim]+" "
			cmd+=num2str(xw[0])+", "+num2str( xw[np-1])
		endif
		cmd+=", \""+ WaveUnits(xw, 0) +"\" "+ wvn
		execute cmd 
		if (method==2)
			duplicate/o wv wtmp
			wv=interp( x, xw, wtmp )
			killwaves/Z wtmp
		endif
	endif
	return cmd
end

function/T ScaleWave2( wv,  opt )
//=========================
// scale n-dim wave to x-wave values for specified dimension 
// 2D wave to both x and y values
// methods: 0 - Point, 1-inclusive, 2 - reinterpolated
// options:
//  XWave:
//     (default)=*_x;  /Y - *_y, /Z - *_z, /T - *_t
//        /X=xwn, /Y=ywn, /Z=zwn, /T=twn
//  Limits:
//     (default)  Inclusive: use min & max from xwave  
//      /P - point: use min & inc from xwave
//  Interpolation:  (default)=yes;  /NOInterp - none 
//  Dimension:  (default)=0;   /D=dimension
//  Output: (default)=overwrite; /W=output wave
//        
	wave wv
	string  opt
	
	variable dim
	dim=KeyVal("D", opt)
	dim=SelectNumber(numtype(dim)==0, 0, dim)		//catch Nan
		
	variable V_inclusive=SelectNumber( KeySet("P",opt), 1, 0)
	variable V_interp=SelectNumber( KeySet("Noi",opt), 1, 0)

	//string wvn=NameOfWave(wv)
	string wvn=GetWavesDataFolder(wv, 2)			// returns full data folder path and name
	
	string xwn=wvn+"_x", xstr		//default
	variable ii=0
	DO
		if (KeySet("XYZT"[ii], opt) )
			dim=ii
			xstr=KeyStr("XYZT"[ii], opt) 
			xwn=SelectString( strlen(xstr)==0,  xstr, wvn+"_"+"xyzt"[ii])
			break
		endif
		ii+=1
	WHILE( ii<4)
	
	variable ndim=WaveDims(wv)
	if (dim>=ndim)
		return "dimension out of range: "+num2str(ndim)
	endif
	
	string outw
	outw=SelectString( KeySet("O",opt), wvn, KeyStr("O",opt))
	//print V_inclusive, V_interp, dim, xwn, outw
	string cmd
	variable incr, np
	if (strlen(xwn)>0)
		//if (cmpstr(xwn[0],"_")==0)
		//	xwn=wvn+xwn
		//endif
		WAVE xw=$xwn
		//WaveStats/Q $xwn
		//SetScale/I x V_min,V_max, "" wv
		if (V_inclusive)
			np=numpnts(xw)
			cmd="SetScale/I "+"xyzt"[dim]+" "
			cmd+=num2str(xw[0])+", "+num2str( xw[np-1])
		else
			cmd="SetScale/P "+"xyzt"[dim]+" "
			cmd+=num2str(xw[0])+", "+num2str( xw[1]-xw[0])
		endif
		cmd+=", \""+ WaveUnits(xw, 0) +"\" "+ outw
		execute cmd 
		if (V_interp)
			duplicate/o wv wtmp
			WAVE out=$outw
			out=interp( x, xw, wtmp )
			killwaves/Z wtmp
		endif
	endif
	return cmd
end


Function RescaleWave( rng, Np, own )
//=============
//redimension & rescale wave with values determined by given range
// create wave if non-existent
//if Np<1 then calc using inc; return value=Np
//if Np>=1 then calculate inc; return value=inc
	wave rng
	variable np
	string own
	
	variable min=rng[0], max=rng[1], inc=rng[2]
	
	if ((inc==0)*(np<=0))
		abort "improper increment or Npoint value"
	endif
	variable calc
	if (np<=0)		//use increment value
		calc=1
		np=round((max-min)/inc)+1
	else
		calc=2
		inc=(max-min)/(np-1)
	endif
	if (exists(own)==0)
		make/D/o/n=(np) $own
	else
		Redimension/N=(np) $own
	endif
	//WAVE ow=$own
	SetScale/P x min, inc, "" $own
	return Np*(calc==1)+inc*(calc==2)
End


Function MkRange( min, max, inc, np, own )
//=============
//create a wave with values determined by given range
//if N<1 then calc using inc; return value=N
//if N>=1 then calculate inc; retrun value=inc
	variable/D min, max, inc, np
	string own
	if ((inc==0)*(np<=0))
		abort "improper increment or Npoint value"
	endif
	variable calc
	if (np<=0)		//use increment value
		calc=1
		np=round((max-min)/inc)+1
	else
		calc=2
		inc=(max-min)/(np-1)
	endif
	if (exists(own)==0)
		make/D/o/n=(np) $own
	else
		Redimension/N=(np) $own
	endif
	WAVE ow=$own
	ow=min+inc*p
	return np*(calc==1)+inc*(calc==2)
End

// *** New function in Igor 5.0
Function Reverse_( w )
//============
	wave w
	NewDataFolder/O root:tmp
	duplicate/o w root:tmp
	WAVE tmp=root:tmp
	variable np=numpnts(w)
	w=tmp(np-1-p)
	return np
End


Function Reverse2d( w )
//============
	wave w
	variable nx=DimSize( w, 0 )
	variable ny=DimSize( w, 1)
	make/o/n=(nx) tmpw
	variable ii=1
	DO
		tmpw=w[p][ii]
		w[][ii]=tmpw[nx-1-p]
		ii+=2
	WHILE (ii<ny)
	return ii-2
End

Function MkGrid0(xr,yr, xwn, ywn, opt)				
//===============
//creates 2d grid of x,y values with specified names (xwn,ywn)
//  according to input 3-vector ranges [min,max, step] (xr, yr)
//return value = number of points = nx*ny
// opt=1 (flatten to 1D array), 2 (keep as 2D)
		wave xr, yr
		string xwn, ywn
		variable opt
	variable nx, ny, np
	nx=MkRange( xr[0], xr[1], xr[2], -1,  xwn )
	ny=MkRange( yr[0], yr[1], yr[2], -1,  ywn )
	np=nx*ny
	WAVE xw=$xwn, yw=$ywn
	Expand2d( $xwn, ny )
	Expand2d( $ywn, nx )
	MatrixTranspose $xwn
	AppendNAN( $xwn, 0 )
	AppendNAN( $ywn, 0 )
	if (opt==1)
		redimension/n=((nx)*(ny+1)) xw, yw
	endif
	//print "Npts: ", np, "=", nx, "x", ny
	return np
End

Function MkGrid(xr, yr, xwn, ywn, opt)				
//===============
//creates 2d grid of x, y values with specified names (xwn,ywn)
//  according to specified ranges:
//      (a) min,max, step    or 
//      (b) range wave name (allows non uniform steps)
// option:  /FLAT (flatten to 1D array), (default - keep as 2D)
//              /SWAP (switch X and Y)
//  return value = number of points = nx*ny
		string xr, yr
		string xwn, ywn
		string opt
	variable nx, ny, np
	
	variable xmin=NumFromList(0, xr,","), xmax=NumFromList(1, xr,","), xinc=NumFromList(2, xr,",")
	if (numtype(xmin)==2)		// Nan --> test if wave name
		if ((exists(xr)==1)*(wavetype($xr)>0))		//not text wave
			Duplicate/O $xr $xwn
			nx=DimSize($xwn,0)
		else
			abort "improper X range specification"
		endif
	else
		nx=MkRange( xmin, xmax, xinc, -1,  xwn )
	endif
	variable ymin=NumFromList(0, yr,","), ymax=NumFromList(1, yr,","), yinc=NumFromList(2, yr,",")
	if (numtype(ymin)==2)		// Nan --> test if wave name
		if ((exists(yr)==1)*(wavetype($xr)>0))		//not text wave
			Duplicate/O $yr $ywn
			ny=DimSize($ywn,0)
		else
			abort "improper Y range specification"
		endif
	else
		ny=MkRange( ymin, ymax, yinc, -1,  ywn )
	endif
	
	np=nx*ny
	WAVE xw=$xwn, yw=$ywn
	Expand2d( $xwn, ny )
	Expand2d( $ywn, nx )
	if (KeySet("SWAP",opt))
		MatrixTranspose $ywn
	else
		MatrixTranspose $xwn
	endif
	AppendNAN( $xwn, 0 )
	AppendNAN( $ywn, 0 )
	if (KeySet("FLAT", opt)	)			//			(opt==1)
		redimension/n=((nx)*(ny+1)) xw, yw
	endif
	//print "Npts: ", np, "=", nx, "x", ny
	return np
End

Function Expand2d( wv, ny )
//=============
//redimension 1D wave to 2D
	wave wv
	variable ny
	variable nx=numpnts(wv)
	redimension/n=(nx,ny) wv
	wv=wv[p][0]
End


Function AppendNAN( wv, idim )
//===============
//append NAN column or row
	wave wv
	variable idim
	variable ndim=WaveDims( wv )
	variable n0=DimSize( wv, 0 ), np
	if (ndim>1)
		variable n1=DimSize( wv, 1)
		if (ndim>2)
			abort "not implemented yet"
		else
			np=(n0+(idim==0))*(n1+(idim==1))
			redimension/n=(n0+(idim==0), n1+(idim==1)) wv
			if (idim==0)
				wv[n0][]=nan
			else
				wv[][n1]=nan
			endif
		endif
	else
		np=n0+1
		redimension/n=(np) wv
		wv[n0]=nan
	endif
	return np
End

Function Interlace( aw, bw, own, opt )
//=============
//Merge two waves as (a0,b0,c,a1,b1,c,...)
//if opt=1, c=nan; otherwise no c
	wave aw, bw
	string own
	variable opt

	variable np=numpnts(aw)
	make/o/n=((2+opt)*np) $own=nan
	Wave ow=$own
	variable ii=0
	do
		ow[(2+opt)*ii]=aw[ii]
		ow[(2+opt)*ii+1]=bw[ii]
		ii+=1
	while( ii<np )
	return (2+opt)*np
End

//** New function in Igor 5.0
Function Concatenate_( aw, bw, own, opt )
//=============
//Concatenate two arrays: ow={a0,a1,...,opt,b0,b1,...}
//Options:   /NAN - insert nan point (value) or "" (string)
//                /PT=(x0,x1) - subset of array b to append to a
//                /EXT=_x  - also do same waves with extension

	wave aw, bw
	string own
	string opt
	
	variable ii=1
	string opt1
	DO
		opt1=StringfromList(ii, opt,  "/")
		if (strlen(opt1)>0)
			print opt1
		else
			break
		endif
		ii+=1
	WHILE(ii<4)

	variable na=numpnts(aw), nb=numpnts(bw)
	make/o/n=(na+nb) tmp=nan
	Wave tmp=tmp
	tmp[0,na-1]=aw[p]
	tmp[na, na+nb-1]=bw[p-na]
	Duplicate/O tmp $own
	return na+nb
End

Macro SaveWave(wn, rngopt, xrng, opt )
//--------------
	string wn=StrVarOrDefault("root:save:g_wn","out")
	variable rngopt=NumVarOrDefault("root:save:g_rngopt",1)
	string xrng=StrVarOrDefault("root:save:g_xrng", GetRange(CsrWaveRef(A),0))
	//string xrng=GetRange(CsrWaveRef(A),0)
	//string xrng=SelectString(root:save:g_rngopt==1, root:save:g_xrng, GetRange(CsrWaveRef(A),0))
	variable opt=NumVarOrDefault("root:save:g_opt",2)
	prompt wn, "Wave to save in 2-column text format", popup, WaveList("*",";","WIN:")
	prompt rngopt, "Range option", popup, "Full wave;Between cursors;Custom Range Interpolation [Below]"
	prompt xrng, "Custom X range: xi, xf, xinc"
	prompt opt, "Formatting", popup, "Normal;Use SaveTable settings"
	
	string curr=GetDataFolder(1)
	NewDatafolder/O/S root:save
		string/G g_wn=wn, g_xrng=xrng
		variable/G g_rngopt=rngopt, g_opt=opt
	SetdataFolder curr
	
	// determine x-range, npts
	variable np, xi, xf,  xinc
	if (rngopt==1)				// full wave
		np=DimSize($wn, 0)
		xi=DimOffset($wn,0)
		xinc=DimDelta($wn,0)
		xf=xi+(np-1)*xinc
	else
	if (rngopt==2)			// between cursors
		xi=hcsr(A)
		xinc=DimDelta($wn,0)		//valid for scaled wave only
		np=abs(pcsr(B)-pcsr(A))+1
		xf=xi+(np-1)*xinc
	else
	if (rngopt==3)			// custom range, incr
		xi=ValFromList( xrng, 0, ",")
		xf=ValFromList( xrng, 1, ",")
		xinc=ValFromList( xrng, 2, ",")
		np=round((xf-xi)/xinc)+1
	endif
	endif
	endif
	xrng=num2str(xi)+","+num2str(xf)+","+num2str(xinc)
	root:save:g_xrng=xrng
	string rpt="Npts, xi, xf, xinc="+num2istr(np)+","+xrng
		
	// create X,Y waves
	//np=MkRange( xi, xf, xinc, 0, "xtmp")
	make/D/o/n=(np) root:save:w_x, root:save:w 

	string xwn=XWaveName("", wn)
	string fwn = "root:"+wn			// or use waveref ??
	if (strlen(xwn)==0)		// scaled wave
		root:save:w_x=xi+p*xinc
		root:save:w=$fwn( root:save:w_x[p] )
		rpt+="; scaled input wave"
	else							// already Y vs X
		xwn="root:"+xwn
		if (rngopt==3)			//custom x-range
			root:save:w_x=xi+p*xinc
			root:save:w=interp( root:save:w_x[p], $xwn, $fwn )
		else	 
		if (rngopt==2)		// between cursors
			root:save:w_x = $xwn[pcsr(A)+p]
			root:save:w = $fwn[pcsr(A)+p]
			//root:save:w_x=xmin+p*xinc
			//root:save:w=interp( root:save:w_x[p], $xwn, $wn )
		else						// full range
			root:save:w_x = $xwn[p]
			root:save:w = $fwn[p]
		endif
		endif
	endif
	print rpt
	// display root:save:w vs root:save:w_x
	
	//save to file
	if (opt==2)
		DoWindow/F SaveTable
		if (V_flag==0)
			SaveTable()
		endif
		Save/F/G/I/M="\r\n" root:save:w_x,root:save:w as wn+".dat"    //using formatting from SaveTable
	else
		Save/G/I/M="\r\n" root:save:w_x,root:save:w as wn+".dat"  
	endif
End

Window SaveTable() : Table
//----------------
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:save:
	Edit/W=(11,107,232,216) root:save:w_x,root:save:w
	ModifyTable width(Point)=26,format(w_x)=3,width(w_x)=66,format(w)=3,digits(w)=5
	ModifyTable width(w)=96
	SetDataFolder fldrSav
EndMacro

Proc Deglitch( opt )
//-------------
	variable opt
	prompt opt, "Method", popup, "=([-1]+[+1])/2;=[-1];=[+1]"
	string wvn=CsrWave(A)
	variable pt=pcsr(A), pt2
	if (opt==1)
		$wvn[pt]=0.5*($wvn[pt-1]+$wvn[pt+1])
		print wvn+"["+num2istr(pt)+"]=0.5*("+wvn+"["+num2istr(pt-1)+"]+"+wvn+"["+num2istr(pt+1)+"])"
	else
		pt2=pt-(opt==2)+(opt==3)
		$wvn[pt]=$wvn[pt2]
		print wvn+"["+num2istr(pt)+"]="+wvn+"["+num2istr(pt2)+"]"
	endif
End

Proc SmoothGraph(winnam, ns)
//--------------------
	string winnam
	variable ns=1
	prompt winnam, "GraphName",popup,WinList("*",";","")
	prompt ns, "# of binomial smooth passes"
	
	PauseUpdate;Silent 1
	string wvlst=WaveList("*",";","WIN:"+winnam), wvn
	variable nw=ItemsInList(wvlst, ";")
	variable ii=0
	DO
		wvn=StrFromList(wvlst, ii, ";")
//		print ii, wvn
		smooth ns, $wvn	
		ii+=1
	WHILE( ii<nw)	
End

Proc DuplicateGraph(winnam, opt, str)
//--------------------
	string winnam, str="_"
	variable opt=1
	prompt winnam, "GraphName",popup,WinList("*",";","")
	prompt opt, "Naming option", popup, "Add extension;Replace last character;Replace first character"
	prompt str, "character(s)"
	
	PauseUpdate;Silent 1
	string wvlst=WaveList("!*_x",";","WIN:"+winnam), wvn
	variable nw=ItemsInList(wvlst, ";")
	if (strlen(str)==0)
		str=SelectString(opt==3, "_", "a")
	endif
	string newnam, newxnam, xwvn
	variable ii=0, len
	display
	DO
		wvn=StrFromList(wvlst, ii, ";")
		xwvn=XWavename(winnam, wvn)
		len=strlen(wvn)
		newnam=wvn
		if (opt==3)
			newnam=str+wvn[1,len-1]
			if (WaveExists($xwvn))
				newxnam=str+xwvn[1,strlen(xwvn)-1]
				print xwvn, "exists"
			endif
		else
			newnam=SelectString(opt==1, wvn[0,len-2]+str,  wvn+str )
		endif
		duplicate/o $wvn $newnam
		print ii, wvn, newnam, xwvn, newxnam
		if (WaveExists($xwvn))
			duplicate/o $xwvn $newxnam
			append $newnam vs $newxnam
		else
			append $newnam 
		endif
		ii+=1
	WHILE( ii<nw)	
End


Proc NoiseTag(wav, opt, wav2, extent, disp)
//=============
	string wav=CsrWave(A), wav2
	variable extent, opt, disp
	prompt wav, "Wave for noise stats", popup, WaveList("*",";","WIN:")
	prompt wav2, "Smooth Wave for subtraction", popup, WaveList("*",";","WIN:")
	prompt extent, "Extent", popup, "Between Cursors;Entire Wave"
	prompt opt, "Noise options", popup, "Cursor Wave only;Wav-smooth"
	prompt disp, "Display", popup, "History+Tag;History only"
	Variable x1=hcsr(A), x2=hcsr(B)
	string  wn=CsrWave(A)		
	Wavestats/Q/R=(x1,x2) $wn 
	string tagstr="noise="+num2str(round(1E4*V_sdev/V_avg)/1E2)+"%"
	print wn, tagstr
	Tag/F=0  $wn, x1, tagstr

End

Function NoiseStats()	//: GraphMarquee
//=============
	GetMarquee bottom
	print V_left, V_right
	variable ii=0
	DO
		WAVE w=WaveRefIndexed("",ii,1)
		if (WaveExists(w)==0)
			break
		endif		
		Wavestats/Q/R=(V_left,V_right) w 
		Print NameOfWave(w), ": avg=", V_avg, ", sdev=", V_sdev, ", sdev/avg=", round(1E5*V_sdev/V_avg)/1E3, "%"
		ii+=1
	WHILE( ii<10)
	GetMarquee/K
	return V_sdev
End

Proc RenameWaves( oldstr, newstr, mode )
//-------------
	string oldstr, newstr
	variable mode
	prompt oldstr, "old substr, (str, *str, *str*, str*)"
	prompt newstr, "replacement string (Rename/Duplicate)"
	prompt mode, "Mode",popup, "Rename;Duplicate;Duplicate/O;Kill"
	//prompt opt, "Options", popup, "All Dim;1D;2D;3D;4D;"
	print RenameList( oldstr, newstr, mode )
End

Function RenameList( oldstr, newstr, mode)
//==================
//mode: 1=Rename, 2=Duplicate, 3=Duplicate/O, 4=Kill
	string oldstr, newstr
	variable mode
	string substr=oldstr
	variable nch=strlen(oldstr), i1, i2
	i1=(cmpstr(oldstr[0],"*")==0)					//=1 if prefix wildcard
	i2=nch -1-(cmpstr(oldstr[nch-1],"*")==0)		//postfix wildcard
	substr=oldstr[i1,i2]				//stripped of wildcards
	nch=strlen(substr)
	print substr, nch

	string wvlst=WaveList(oldstr,";",""), own, nwn, cmd	//not Case-Sensitive
	variable nw=ItemsInList(wvlst,";")		//=100
	if (nw==0)
		abort "No matching waves for substring:  "+oldstr
	endif
	variable ii=0,  nch2
	DO
		own=StringFromList(ii, wvlst)
		if (mode<4)			//string substitution
			i1=strsearch(LowerStr(own), LowerStr(substr),0)		//should not be -1; Case-Sensitive
			i2=i1+nch
			nch2=strlen(own)
			nwn=own[0,i1-1]+newstr+own[i2,nch2-1]
			//print "Renaming: "+own+" to "+nwn
			cmd=SelectString( mode-2, "Rename ", "Duplicate ", "Duplicate/O " )
			print cmd+own+", "+nwn
			execute cmd+own+", "+nwn
		endif
		if (mode==4)			//KillWaves - only works if not used in graph
			KillWaves $own		//  /Z gives no error if in use
		endif
		ii+=1
	WHILE( ii<nw )
	return ii
End

Function RenameList_( oldstr, newstr, mode)
//==================
//mode: 1=prefix, 2=postfix
	string oldstr, newstr
	variable mode
	string test=oldstr
	if ((mode==1)+(mode==3))
		test=test+"*"
	endif
	if ((mode==2)+(mode==3))
		test="*"+test
	endif
	string wvlst=WaveList(test,";",""), own, nwn
	variable nc1=strlen(wvlst)-1
	variable nw=100			//ItemsInList(wlst,";")
	variable ii=0, jj, nc=strlen(oldstr)
	DO
		jj=strsearch(wvlst,";", 0)
		if (jj==-1)
			break
		endif
		own=wvlst[0,jj-1]
		nwn=newstr+own[nc,30]
		print "Renaming: "+own+" to "+nwn
		Rename $own, $nwn
		wvlst=wvlst[jj+1,nc1]
		ii+=1
	WHILE( ii<nw )
	print ii
End

Function/T GetRange( w, dir )
//==============
	wave w
	variable dir								// select direction
	string img=ImageNameList("",";")
	img=StringFromList(0, img, ";")				// use first image for range
	variable inc=DimDelta(w,dir), x1, x2
	//inc=abs(inc)
	x1=DimOffset(w, dir)			// do not use image ranges
	x2=x1+(DimSize(w, dir)-1)*inc
	string str=num2str(x1)+","+num2str(x2)+","+num2str(inc)
	return str
End

Function/C DeleteValues( wav1, wav2, cond)
//================
// Sets Wav1 values to INF based on condition, e.g. "<=5.1"
// then deletes points that equal INF
	Wave wav1, wav2
	string cond	//, wav1, wav2
	variable ii=0, npt=numpnts(wav1), npt0
	npt0=npt
	//print npt
	//wav1=SelectNumber(wav1<=0.02, wav1, inf)
	string wav1n=NameOfWave(wav1)
	string cmd=wav1n+"+=SelectNumber("+wav1n+cond+", 0, inf)"
	//print cmd
	execute cmd
	DO
		if (wav1[ii]==inf)
			DeletePoints ii, 1, wav1, wav2
			npt-=1
		else
			ii+=1
		endif
	WHILE( ii<npt)
	return CMPLX( npt0, numpnts(wav1))
End


Function/C DeleteXYrange(xw, yw, opt)
//==================
// Keep (or Delete) points that within specified X & Y ranges
// options:
//     output:  yw+"c" (default),  or  /D=ywaven+"d", or  /O (overwrite)
//                   xwn = ywn+"_x" unless overwrite  
//     range:	/X=x1,x2    /Y=y1,y2  
//     crop:    /XD /YD  delete points within range 
//                   (default = keep points within range)
//

	Wave xw, yw				// XY pair
	string opt
	
	string ywn=NameofWave(yw)
	
	//output arrays
	string youtn=KeyStr("D", opt), xoutn
	variable overwrite=KeySet("O", opt)+stringmatch(ywn,youtn)
	if ((strlen(youtn)==0)+overwrite)
		youtn=ywn+"d"
	endif
	xoutn=youtn+"_x"
	
	// crop/selection range
	string xrng=KeyStr("X", opt), yrng=KeyStr("Y", opt)
	//print xrng, yrng
	variable x1, x2, y1, y2
	variable marquee=KeySet("M", opt)
	if (marquee)			// look for marquee box in top graph; supercede XY ranges
		GetMarquee/K left, bottom
		if (V_Flag==1)
			x1=V_left; x2=V_right
			y1=V_bottom; y2=V_top
		else
			marquee=0
		endif
	endif
	IF (!marquee)
		if (strlen(xrng)==0)
			WaveStats/Q xw
			x1=V_min; x2=V_max
		else
			x1=NumFromList(0, xrng,","); x2=NumFromList(1, xrng,","); 
		endif
		if (strlen(yrng)==0)
			WaveStats/Q yw
			y1=V_min; y2=V_max
		else
			y1=NumFromList(0, yrng,","); y2=NumFromList(1, yrng,","); 
		endif
	ENDIF
//	print x1, x2, y1, y2
	
	// keep or delete
	variable xkeep=1 - KeySet( "XD", opt), ykeep=1 - KeySet( "YD", opt)
//	print xkeep, ykeep
//	Wave selector				// Contains 1 if corresponding point is selected for deletion
	
	Variable numPoints = numpnts(xw)		// Assumed same as yw and selector
	Variable numDeleted = 0
	Variable ii, xselect, yselect
	
	Duplicate/O yw $youtn
	Duplicate/O xw $xoutn
	WAVE xout=$xoutn, yout=$youtn
	for(ii=0; ii<numPoints; ii+=1)
		xselect = (xw[ii]>=x1)*(xw[ii]<=x2)
		xselect = SelectNumber( xkeep, 1-xselect, xselect)
		yselect = (yw[ii]>=y1)*(yw[ii]<=y2)
		yselect = SelectNumber( ykeep, 1-yselect, yselect)
//		selector[ii] = xselect*yselect
		if (xselect*yselect == 0)			// skip if not selected
			numDeleted += 1
		else
			xout[ii-numDeleted] = xw[ii]
			yout[ii-numDeleted] = yw[ii]
//			selector[i-numDeleted] = 0
		endif
	endfor
	
	Redimension/N=(numPoints-numDeleted) xout, yout		//, selector
	
	if (overwrite)
		Duplicate/O xout xw
		Duplicate/O yout yw
		Killwaves/Z xout, yout
	endif
	
	if (KeySet("P",opt)*!overwrite)		// don't do if overwrite
		display yout vs xout
		ModifyGraph mode=2,lsize=2
	endif
	
//	return numDeleted
	return CMPLX( numPoints, numPoints-numDeleted)
End


Function/T ExtractName( filenam, opt)
//==================
// extract wavename from "base.ext"  filename
// options:  /B   - full base name
//                /B=n(>0)  - first n characters
//                /B=n(<0)  - last n characters
//                /E   - extension
//                /U  - convert . to _ (+ /B/E)
//                /P=str  - prefix string
//                /S=str  - suffix string
	string filenam, opt
	
	string outnam="", prefix="", suffix=""
	//variable nc=strlen(filenam)

	// separate basename and extension
	string base="", ext=""
	variable ipd=strsearch(filenam,".",0)
	if (ipd<0)					//no period found
		ipd=strlen(filenam)
		base=filenam
		ext=""
	else
		base=filenam[0, ipd-1]
		ext=filenam[ipd+1,strlen(filenam)-1]
	endif
	
	variable ibase=KeySet("B",opt), iext=KeySet("E",opt)
	variable underscore=KeySet("U",opt)
	if (underscore)
		ibase=1; iext=1
	endif
	
	if (KeySet("P",opt))				//Prefix
		outnam=KeyStr("P",opt)
	endif
	if (ibase)
		variable nbase=KeyVal("B",opt)
		if (numtype(nbase)==2)		//NaN no value given
			outnam+=base
		endif
		if (nbase>0)		//First N prefix characters;
			outnam+=base[0,nbase-1]
		endif
		if (nbase<0)		//Last N prefix characters;
			outnam+=base[ipd-abs(nbase), ipd-1]
		endif
	endif
	if (underscore)					//Period
		outnam+="_"
	endif
	if (iext)						//Extension
		outnam+=ext
	endif
	if (KeySet("S",opt))			//Suffix
		outnam+=KeyStr("S",opt)
	endif
	if (strlen(opt)==0)		// default, no extension given
		outnam=CleanUpName(filenam,0)
	endif
	return outnam
End

Function IntegrateReg(data, opt)
//===============
// integrate 1D scaled wave with options for subrange and reverse direction
	wave data			// scaled wave
	string opt
	
	//output array
	string datan=NameOfWave( data )
		//output image
	string dwn=KeyStr("D", opt)
	variable overwrite=KeySet("O", opt)+stringmatch(datan,dwn)
	if ((strlen(dwn)==0)+overwrite)
		dwn=datan+"_int"
	endif	
	
	variable rev=SelectNumber( KeySet("R", opt), 0, 1)
	//extract subregion
	string xrng=KeyStr("X",opt)
	if (strlen(xrng)==0)
		Duplicate/O data $dwn
	else
		execute "Duplicate/O/R=("+xrng+") "+datan+" "+dwn
	endif
	WAVE destw=$dwn
	
	if (rev)
		Reverse destw
		Integrate destw
		Reverse destw
		destw=-destw
	else
		Integrate destw
	endif
	
	if (overwrite)
		Duplicate/O destw data
		Killwaves/Z destw
		dwn=datan
	endif
	if (KeySet("P",opt))
		Display $dwn
	endif
End


function FindPeaks( arr,  opt )
//=============
//  Iteratively find multiple peaks in array
//   -- uses trailing halfwidth point as start for next peak search
//        return   Npk  (number peaks found)
//  Options:
//		/D=pknam   (peak value wave; Default= arrn_x)
//        					peak postions in pknam_x)
//          /Npk=number of peaks to find (default=100)
//   	/Min=minval 
//      	/Box=boxcar smooth npts
//		/Tag   (add arrows at peaks with postion labels)
//          /Tag=0   (remove Tags)
//          /Stick   (append Pk vs Pkx sticks to zero in top graph)
//
	wave arr
	string opt
	
	//output arrays
	string pkn=KeyStr("D", opt), pkan, pkxn, pkwn	//amplitude, x-position, width
	if (strlen(pkn)==0)
		pkn=NameOfWave(arr)
	endif
	pkan=pkn+"_a"
	pkxn=pkn+"_x"
	pkwn=pkn+"_w"
	
	//number peaks (default=100)
	variable npk=KeyValDef("Npk", opt, 200)
	
	//minlevel
	//variable minlevel=KeyValDef("Min", opt, 0.1)
	variable minlevel=KeyVal("Min", opt)
	if (numtype(minlevel)==2)		//Nan
		WaveStats/Q arr
		minlevel=0.1*V_max
	endif
	
	//minimum width  (default =10 points - convert to x-scaling )
	variable minwidth=KeyValDef("Width", opt, 10)
	
	//boxcar smoothing
	variable boxcar=KeyValDef("Box", opt, 10)
	//print pkn, pkxn, npk, minlevel, boxcar
	
	Make/O/N=(npk) $pkxn, $pkan, $pkwn
	Wave Pka=$pkan, Pkx=$pkxn, Pkw=$pkwn
	
	variable x0=0, x1=pnt2x(arr, numpnts(arr)-1)

	variable ii=0, jj=0
	DO
		FindPeak/Q/M=(minlevel)/R=(x0,x1)/B=(boxcar) arr
		if (V_PeakWidth>=minwidth)
			Pkx[ii]=V_PeakLoc
			Pka[ii]=V_PeakVal
			Pkw[ii]=V_PeakWidth
			jj+=1
		endif
		//print p0, p1
		x0= V_TrailingEdgeLoc
		if (numtype(x0)==2)
			npk=jj
			break
		endif
		ii+=1
	WHILE(ii<npk)
	Redimension/N=(npk) Pkx, Pka, Pkw
	
	string arrn=NameOfWave(arr)
	//Top graph options
	if (KeyVal("Tag", opt)==0 )				//remove tags
		execute "RemoveTags(\""+arrn+"\",\"\")"
	endif
	
	variable idspace=0
	string pktagn=pkxn
	if (KeySet("Tag", opt) )
		execute "RemoveTags(\""+arrn+"\",\"\")"
		if (stringmatch(KeyStr("Tag", opt),"A")==1 )
			pktagn=pkan
		endif
		if (stringmatch(KeyStr("Tag", opt),"W")==1 )
			pktagn=pkwn
		endif
		if (stringmatch(KeyStr("Tag", opt),"D")==1 )
			// Interpret Pkx as 2-theta; convert to d-spacing using CuKa
			idspace=1
			variable wvlCuKa1=1.5406, d2r=pi/180
			string pkdn=Pkn+"_d"
			duplicate/o Pkx, $pkdn
			Wave Pkd=$pkdn
			Pkd = wvlCuKa1/2/sin(d2r*Pkx[p]/2)
			pktagn=pkdn
		endif
		print pktagn
		execute "TagWaveAt(\""+pktagn+"\",\""+arrn+"\",\""+pkxn+"\",1)"
		//TagWaveAt(pkn,arrn,pkn,1)
	endif
	if (KeySet("Stick", opt) )
		CheckDisplayed Pka
		if (V_Flag==0)
			AppendToGraph Pka vs Pkx
			execute "ModifyGraph mode("+pkan+")=1,lsize("+pkan+")=0.5"
			execute "ModifyGraph rgb("+pkan+")=(0,0,0)"
		endif
	endif
	if (KeySet("Table", opt) )
		Edit Pkx, Pka, Pkw
		//CheckDisplayed Pka
		if (idspace==1)
			//Wave Pkd=$(pkn+"_d")
			Edit Pkx, Pkd, Pka, Pkw
		endif
		//execute "ModifyGraph mode("+pkan+")=1,lsize("+pkan+")=0.5"
		//execute "ModifyGraph rgb("+pkan+")=(0,0,0)"
	endif
	
	return npk
end


Function ZapUnit( wv )
//========
// blank out units field for each axis  scaling
	WAVE wv

	variable ndim=WaveDims(wv)
	if (ndim==0)
		return ndim
	endif
	
	string cmd, sdim="xyzt"
	Variable vOffset, vDelta
	Variable ii=0				
	do
		vOffset= DimOffset( wv, ii)
		vDelta = DimDelta( wv, ii)
		cmd="SetScale/P "+sdim[ii]+" "+num2str(vOffset)+","+num2str(vDelta)+",\"\", "+NameOfWave(wv)
//		print cmd
		execute cmd
		ii += 1
	while(ii < ndim)
	return ndim
end

Proc ZapUnits( wvn )
//------------
// blank out units field for each axis  scaling
// coud add flag for "ALL" or recognize wildcard selection in string "f*"
//	WAVE wv
	string wvn
	prompt wvn, "WaveName",popup,WaveList("*",";","")
	
	string wlist=wvn
	if (strsearch(wvn, "*", 0)>0)		//wildcard = >multiple wave selection
		wlist=WaveList(wvn,";","")
	endif
//	print wlist
	variable nw=ItemsInList( wlist), iw=0
	variable ii, ndim
	string cmd, sdim="xyzt", sOffset, sDelta
//	variable vOffset, vDelta
	DO
		wvn=StringFromList( iw, wlist )
		ndim=WaveDims($wvn)
		IF (ndim>0)		
			ii=0				
			do
				sOffset= num2str( DimOffset( $wvn, ii) )
				sDelta = num2str( DimDelta( $wvn, ii) )
				cmd="SetScale/P "+sdim[ii]+" "+sOffset+","+sDelta+",\"\", "+wvn
				print cmd +" :  old=\""+WaveUnits( $wvn, ii)+"\""
				execute cmd
				ii += 1
			while(ii < ndim)
		ENDIF
		iw+=1
	WHILE( iw<nw)
end



