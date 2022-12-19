//////////
//  Twopolar Package
// Written by Eli Rotenberg, Advanced Light Source, erotenberg@lbl.gov
/////////
//version 1.11 added support for different normalizations
//version 1.12 trapped creation--do not call hook function during creation
//verstion 1.13 made it so #coarse angles=1 is possible
//				added wave label to graph
//				added support for polar-azimuth
//				rename as "TwoAngle" not "TwoPolar"
//version 1.14	added correction tables to shift each strip by # pixels
//version 1.15 ER added support for single beta scan
//				made "auto" equivalent to "wavenote"
//verstion 1.17ER made symmetrize have option for keeping + or - sides
/////////
#pragma rtGlobals=1		// Use modern global access method.
#include "ColorTables" 
#include <Strings As Lists>
#include <Median>
menu "kSpace"
	"kplot"
	//"TwoPolar"
end

//dataname is "D"
//
//REDIM
//		auto:	either  exist waves DAPhi, DATheta, DABeta as needed where A is arbitrary string
//		manual: use AngleRangeC, AngleRangeF	
//		already done:	data should already be redimensioned to kx,ky or angle1,angle2
//						axis units should either be "kx,ky","theta,beta", "theta,phi", "beta,phi"
//AngleRangeC is outer loop 
//AngleRangeF is inner loop
proc kplot(w,map,reDim,AngleRangeC,AngleRangeF)
	string w,map,reDim,AngleRangeC,AngleRangeF
	prompt w,	"image array", popup, "-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")	
	prompt map,"Mapping method",popup,"TwoPolar;PolarAzimuth"
	prompt redim,"Redimension",popup,"Auto;Manual;Already Done;Wavenote"
	//prompt inputType, "Input Type", popup, "Auto;Angle;k"
	prompt angleRangeC,"Angle Range Coarse [start,end,N]"
	prompt angleRangeF,"Angle Range Fine [start,end,N]"
	
	string motorwave1="",motorwave2=""
	variable doredim=0
	
	string wavenote=note($w)
	if (cmpstr(reDim,"Auto")==0)
		if(numberbykey("Nextension",wavenote,"=")==1)
			redim="Wavenote"
		else
			string thetawaves=wavelist(w+"*theta",";","")
			string betawaves=wavelist(w+"*beta",";","")
			string phiwaves=wavelist(w+"*phi",";","")
			variable slt=strlen(thetawaves), slb=strlen(betawaves), slp=strlen(phiwaves)
			if(cmpstr(map,"TwoPolar")==0)
				motorwave1=getStrFromList(thetawaves,0,";")
				motorwave2=getStrFromList(betawaves,0,";")				
			else
				motorwave1=getStrFromList(phiwaves,0,";")
				motorwave2=getStrFromList(betawaves,0,";")
			endif
			doredim=1
		endif
	endif
	
	if (cmpstr(redim,"Manual")==0)
		variable stc=str2num(GetStrFromList(AngleRangeC,0,",")),stf=str2num(GetStrFromList(AngleRangeF,0,","))
		variable enc=str2num(GetStrFromList(AngleRangeC,1,",")),enf=str2num(GetStrFromList(AngleRangeF,1,","))
		variable nc=str2num(GetStrFromList(AngleRangeC,2,",")), nf=str2num(GetStrFromList(AngleRangeF,2,","))
		if(cmpstr(map,"TwoPolar")==0)
			motorwave1=w+"_manTheta"
			motorwave2=w+"_manBeta"
		else
			motorwave1=w+"_manPolar"
			motorwave2=w+"_manPhi"
		endif
		make/o/n=(nf,nc) $motorwave1,$motorwave2
		if(nc==1)
			$motorwave1=stc
		else
			$motorwave1=stc+q*(enc-stc)/(nc-1)
		endif
		if(nf==1)
			$motorwave2=stf
		else
			$motorwave2=stf+p*(enf-stf)/(nf-1)
		endif
		redimension/n=(nc*nf) $motorwave1,$motorwave2
		doredim=1
	endif

	if (cmpstr(redim,"Wavenote")==0)
	
		if(numtype(numberbykey("N_0_1",wavenote,"="))	== 2)//NaN
			//single fine scan
			variable stc=0,stf=numberbykey("ST_0_0",wavenote,"=")
			variable enc=0,enf=numberbykey("EN_0_0",wavenote,"=")
			variable nc=1, nf=numberbykey("N_0_0",wavenote,"=")
		else
			if(numberbykey("N_0_0",wavenote,"=")<numberbykey("N_0_1",wavenote,"=")		)
				variable stc=numberbykey("ST_0_0",wavenote,"="),stf=numberbykey("ST_0_1",wavenote,"=")
				variable enc=numberbykey("EN_0_0",wavenote,"="),enf=numberbykey("EN_0_1",wavenote,"=")
				variable nc=numberbykey("N_0_0",wavenote,"="), nf=numberbykey("N_0_1",wavenote,"=")
			else				
				variable stc=numberbykey("ST_0_1",wavenote,"="),stf=numberbykey("ST_0_0",wavenote,"=")
				variable enc=numberbykey("EN_0_1",wavenote,"="),enf=numberbykey("EN_0_0",wavenote,"=")
				variable nc=numberbykey("N_0_1",wavenote,"="), nf=numberbykey("N_0_0",wavenote,"=")
			endif
		endif
		if(cmpstr(map,"TwoPolar")==0)
			motorwave1=w+"_manTheta"
			motorwave2=w+"_manBeta"
		else
			motorwave1=w+"_manPolar"
			motorwave2=w+"_manPhi"
		endif
		make/o/n=(nf,nc) $motorwave1,$motorwave2
		if(nc==1)
			$motorwave1=stc
		else
			$motorwave1=stc+q*(enc-stc)/(nc-1)
		endif
		if(nf==1)
			$motorwave2=stf
		else
			$motorwave2=stf+p*(enf-stf)/(nf-1)
		endif
		redimension/n=(nc*nf) $motorwave1,$motorwave2
		doredim=1
	endif


	string df=newKplot(w,map,doRedim,motorwave1,motorwave2)
	silent 1;pauseupdate
	calcAngleData(df)
	
	newdatafolder/o KPlot		//so window creation has no errors
	KPlotWin()
	string dfn=stringfromlist(1,df,":")
	doWindow/c/t  $dfn, dfn					//rename window to datafolder without the colons
	setwindow $dfn hook=KPlotHookFcn, hookevents=3,hookcursor=20  //mouse movement +clickevents hooks
	//1=ptr, 2=watch, 3=cross, 4=left-up, 5=left-right arrow, 6=updown arrow, 7=right-down arrow
	//8=circle-dot-cross, 9=like cmd key, 10=left-down arrow, 11=right-up arrow, 12=little cross
	//13=hand, 14=like csr b, 15=like csr a, 16=rectangle+dot, 17=?-mark, 18=square+bigcross+smallcross
	//19=lightening, 20=mediumcross+dot, 21=circle+4arrows, 22=left-right arrow+vertical bars,
	//23=up-down arrow+horiz bars, 24="Click", 25=big angle (upper left), 26= "?" in cartoon balloon
	//27=pointy hand
	
	//wire up panel items to the particular data folder's variables
	$(df+"whichct")=1
	loadct($(df+"whichct"))
	duplicate :colors:ct $(df+"ct")
	setColorScale(df)

	SetVariable setgamma value= $(df+"gamma")
	SetVariable hv value= $(df+"hv")
	CheckBox kmap value=$(df+"kmap")
	SetVariable ang0 value= $(df+"theta0")
	SetVariable ang1 value= $(df+"beta0")
	SetVariable ang2 value= $(df+"phi0")
	if(cmpstr(map,"TwoPolar")==0)
		setvariable ang0 title="theta0"
		setvariable ang1 title="beta0"
		setvariable ang2 title="phi0"
	else
		setvariable ang0 title="polar0"
		setvariable ang1 title="phi0"
		setvariable ang2 title="N/A"
	endif	
	Checkbox PolarGrid value=$(dF+"PolarGrid")
	Checkbox kgrid value=$(df+"kgrid")
	Checkbox azgrid value=$(df+"azgrid")
	SetVariable k value= $(df+"vdk")
	SetVariable kx value= $(df+"vdkx")
	SetVariable ky value= $(df+"vdky")
	SetVariable theta value= $(df+"vdtheta")
	SetVariable phi value= $(df+"vdphi")
	SetVariable beta value= $(df+"vdbeta")
	SetVariable degperpixel value=$(df+"degperpixel"),disable=(1-doRedim)
	SetVariable wave,value= $(df+"wavname")
	SetVariable xshift value=$(df+"xshiftstr")
	setvariable yshift value=$(df+"yshiftstr")
	execute "popupmenu normpopup value=" + "\""+($(df+"normMenu"))+"\""
	killdatafolder KPlot			//don't need any more


	
	//post data to window
	string d=df+"data"
	string ad=df+"angData"

	duplicate/o $ad $d			
	appendimage $d
	modifyimage data cindex=$(df+"ct")
	if($(df+"aspect"))
		ModifyGraph width={Plan,1,bottom,left}
	endif
	fixrange(df)

	if($df+"is3d")
		cstyle(0)
		variable x0=dimoffset($d,0)+dimdelta($d,0)*dimsize($d,0)/2
		variable y0=dimoffset($d,1)+dimdelta($d,1)*dimsize($d,1)/2
		append $(df+"hairy0") vs $(df+"hairx0")
		modifygraph offset($("hairy0"))={dimoffset($d,0) + dimdelta($d,0)*dimsize($d,0)/2,dimoffset($d,1) + dimdelta($d,1)*dimsize($d,1)/2}
		ModifyGraph rgb(HairY0)=(0,65535,65535)
		make/n=(dimsize($w,1)) $(df+"zprof")
		setscale/p x dimoffset($w,1),dimdelta($w,1),waveunits($w,1),$(df+"zprof")
		$(df+"zprof")=interp3d($("root:"+w),x0,x,y0) //*
		makezwin(dfn,df)
	endif
	$(df+"creating")=0
	$(df+"zprof")=$("root:"+w)[rawP(x0)(y0)](x)[rawQ(x0)(y0)]
end



function/s newkPlot(wn,mapp,doredm,motorwave1,motorwave2)
	string wn,mapp,motorwave1,motorwave2
	variable doredm
	string df=uniquename("KPlot",11,0)
	newdatafolder $df
	df=":"+df+":"
	string/g $(df+"mapp")=mapp
	string/g $(df+"motor1")=motorwave1
	string/g $(df+"motor2")=motorwave2
	variable/g $(df+"creating")=1
	variable/g $(df+"theta0")=0
	variable/g $(df+"beta0")=0
	variable/g $(df+"phi0")=0
	variable/g $df+"gridkx"=.25
	variable/g $df+"gridky"=.25
	variable/g $df+"gridtheta"=5		//theta spacing for "checkerboard" theta-beta grid
	variable/g $df+"gridbeta"=5	
	variable/g $df+"gridphi0"=0
	variable/g $df+"gridphi"=45
	variable/g $df+"gridphitheta"=5	//theta spacing for "bullseye" azimuth grid
	variable/g $(df+"gamma")=1
	string/g $(df+"dfname")=df
	string/g $(df+"wavName")=wn
	variable/g $(df+"whichct")=1
	string/g $(df+"normMenu")="   normX;   normY;   use median;--;   scale overlap regions to match;   # pixels to match=5"
	variable/g $(df+"isNorm")=0
	variable/g $(df+"isNormX")=0
	variable/g $(df+"isNormY")=0
	variable/g $(df+"useMedian")=0
	variable/g $(df+"MatchOverlap")=0
	variable/g $(df+"NumPixelsMatch")=5
	
	make/n=50 $(df+"xShift"), $(df+"yShift")	//strip-by-strip pixel shift
	wave xshift=$(df+"xshift"), yshift=$(df+"yshift")
	xshift=0; yshift=0
	string/g $(df+"xshiftstr"), $(df+"yshiftstr")
	
	variable/g $(df+"kmap")=0
	variable/g $(df+"hv")=100
	variable/g $(df+"recalcAngle") =1	//need to recalculate the angle image
	variable/g $(df+"recalcK") =1		//need to recalc the k image
	variable/g $(df+"degPerPixel")=.031
	variable/g $(df+"PolarGrid")=0	//no grid initially
	variable/g $(df+"AzGrid")=0		//no grid initially
	variable/g $(df+"kGrid")=0		//no grid initially
	
	variable/g $(df+"vdk")=0			//value display variables
	variable/g $(df+"vdkx")=0
	variable/g $(df+"vdky")=0
	variable/g $(df+"vdtheta")=0
	variable/g $(df+"vdbeta")=0
	variable/g $(df+"vdphi")=0
	
	variable/g $(df+"Aspect")=1	//preferences  1=no, 2=yes
	variable/g $(df+"RescaleAfterRezero")=1
	variable /g $(df+"kmapSampling")=1
	variable/g $(df+"doRedm")=doRedm	//1 means redimension needed (data are linear not matrix)

	make/n=7 $(df+"HairY0"),$(df+"HairX0")
	wave hx0=$(df+"HairX0"), hy0=$(df+"HairY0")
	hx0={-Inf,0,Inf,NaN,0,0,0}
	hy0={0,0,0,NaN,Inf,0,-Inf}

	variable/g $(df+"is3D")=(dimsize($wn,2)>1)
	variable/g $(df+"z0p")=round(dimsize($wn,1)/2)				//center of z-window in pixels
	variable/g $(df+"zwp")=1 										//width of z-window in pixels (zero or one means 1 pixel)
	nvar z0p=$(df+"z0p"), zwp=$(df+"zwp")
	variable/g $(df+"z0")=dimoffset($wn,1)+dimdelta($wn,1)*z0p	//center of z-window
	variable/g $(df+"zw")=dimdelta($wn,1)*zwp						//width of z-window in ev
	nvar z0=$(df+"z0"), zw=$(df+"zw")
	variable/g $(df+"useBE")=0										//connected to checkbox on z-panel
	
	make/n=11 $(df+"HairYZ"),$(df+"HairXZ"),$(df+"HairXZP")
	wave hxz=$(df+"HairXZ"),hxzp=$(df+"HairXZP"),hyz=$(df+"HairYZ")
	hyz={Inf,0,-Inf,NAN,Inf,0,-Inf,NaN,Inf,0,-Inf}
	//zwp should be odd (this instance only, even taken care of later)
	hxzp={-(zwp-1)/2,-(zwp-1)/2,-(zwp-1)/2,NaN,0,0,0,NaN,(zwp-1)/2,(zwp-1)/2,(zwp-1)/2}
	hxzp+=z0p
	hxz=dimoffset($wn,1) + hxzp*dimdelta($wn,1)
	return df
end


function calcAngleData(df)
	string df
	//print "Calculating angle"
	nvar degPerPixel=$(df+"degPerPixel")
	svar wn=$(df+"wavName")
	wave w=$wn
	nvar doRedim=$(df+"doRedm")
	nvar is3D=$(df+"is3D")
	wave hxzp=$(df+"hairxzp")
	nvar z0=$(df+"z0"), zw=$(df+"zw")
	variable a1dim,a2dim
	if(is3d)
		a1dim=0
		a2dim=2
	else
		a1dim=0
		a2dim=1
	endif
	if (doRedim)
		svar w1n=$(df+"motor1")
		svar w2n=$(df+"motor2")
		wave w1=$w1n 
		wave w2=$w2n 
		duplicate/o w1 $(df+"uniqueAngle")
		wave ua=$(df+"uniqueAngle")
		uniqueValues(w1,ua)
		variable dAngle=abs(ua[1]-ua[0])
		variable numangle=numpnts(ua)				//# of coarse angle steps
		variable numangle2=numpnts(w1)/numangle	//#of fine angle steps
		variable numpixelsUse=abs(dAngle/degPerPixel)  //# nonoverlapping pixels
		wave xshift=$(df+"xshift"), yshift=$(df+"yshift")
		redimension/n=(numangle) $(df+"xshift"),  $(df+"yshift")
		variable ii
		svar xss=$(df+"xshiftstr"), yss=$(df+"yshiftstr")
		nvar creating=$(df+"creating")
		if(creating)
			xss=""; yss=""
			for(ii=0;ii<numangle;ii+=1)
				xss+="0, "
				yss+="0, "
			endfor
		endif
		//xshift=0; yshift=0
		variable under
		if (numPixelsUse>dimsize(w,a1dim))
			under=1							//angle scan coarser than amount of angle data taken
			numPixelsUse=dimsize(w,a1dim)	//i.e. there is no overlap of the strips
		else
			under=0
		endif
		variable startpixel=(dimsize(w,a1dim)-numPixelsUse)/2
		if (startpixel<0)
			startpixel=0
		endif
		if(under)
			make/o/n=(abs((numangle-1)*dAngle/degPerPixel+numPixelsUse), numangle2) $(df+"angData0"),$(df+"rawP"), $(df+"rawQ") 	//don't have extra black on lhs or rhs
		else 
			make/o/n=(numangle * numPixelsuse+2*startpixel, numangle2) $(df+"angData0"),$(df+"rawP"), $(df+"rawQ")  //don't truncate data on lhs or rhs 
		endif
		wave ad0=$(df+"angData0"), rawP=$(df+"rawP"), rawQ=$(df+"rawQ")
		ad0=0
		nvar t0=$(df+"theta0")
		nvar b0=$(df+"beta0")
		wavestats/q w1
		variable x0, x1
		//print numpixelsuse,startpixel,degperpixel
		if(under)
			x0=-1*numPixelsUse/2*degPerPixel		//xscale left value, degr
			x1=abs(v_min-v_max)+numPixelsUse/2*degPerPixel	//xscale right value, degr
		else
			x0=-1*(startpixel+numpixelsuse/2)*degperpixel
			x1=abs(v_min-v_max)+(abs(x0))
		endif
		SetScale/i x -1*(x0-ua[0])-t0,-1*(x1-ua[0])-t0,w1n, ad0,rawP,rawQ
		wavestats/q w2
		Setscale/i y v_min-b0, v_max-b0, w2n, ad0,rawP,rawQ
		make/o/n=(dimsize(w,a1dim),dimsize(w,a2dim)) $(df+"xscaled")
		wave xs=$(df+"xscaled")
		Setscale/p x -0.5*numPixelsUse*degPerPixel,degPerPixel,"" xs	//like raw data wave, with x scaled to angle units
	else
		//no analysis needed; just copy data to ad0 wave
		make/o/n=(dimsize(w,a1dim),dimsize(w,a2dim)) $(df+"angdata0"),$(df+"rawP"), $(df+"rawQ")
		wave ad0=$(df+"angData0"), rawP=$(df+"rawP"), rawQ=$(df+"rawQ")
		setscale/p x dimoffset(w,a1dim),dimdelta(w,a1dim),waveunits(w,a1dim),ad0,rawP,rawQ
		setscale/p y dimoffset(w,a2dim),dimdelta(w,a2dim),waveunits(w,a2dim),ad0,rawP,rawQ
		wave hxzp=$(df+"hairxzp")
		ad0=0
		variable rr
		//print "Integrating slices...",hxzp[0],hxzp[10]
		for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
			ad0+=w[p][rr][q]
		endfor
	endif
	 
	//normalize data
	nvar norm=$(df+"isNorm")
	make/o/n=(dimsize(w,a1dim),dimsize(w,a2dim)) $(df+"dnorm")
	wave dnorm=$(df+"dnorm")
	setscale/p x dimoffset(w,a1dim),dimdelta(w,a1dim),waveunits(w,a1dim),dnorm
	setscale/p y dimoffset(w,a2dim),dimdelta(w,a2dim),waveunits(w,a2dim),dnorm
	make/o/n=(dimsize(w,a1dim)) $(df+"normFuncX")  		//x-direction normalization function
	wave nfx=$(df+"normFuncX")	
	make/o/n=(numangle2) $(df+"normFuncY")  				//y-direction normalization function
	wave nfy=$(df+"normFuncY")	
	make/o/n=(dimsize(w,a1dim)) $(df+"normFuncXi")		//x-direction intermediate normalization function
	wave nfxi=$(df+"normFuncXi")
	make/o/n=(numangle2) $(df+"normFuncYi")  				//y-direction intermediate normalization function
	wave nfyi=$(df+"normFuncYi")	
	nvar isnormX=$(df+"isNormX")
	nvar isnormY=$(df+"isNormY")
	nvar useMedian=$(df+"useMedian")
	nvar matchOverlap=$(df+"matchOverlap")
	variable i,j
	if(isnormX||isNormY||matchOverlap)
		nfx=1
		nfy=1
		for (i=0; i<numangle;i+=1)		
		
			if(isNormX)
				if(useMedian)
					for(j=0; j<dimsize(w,a1dim);j+=1)
						if(is3d)
							nfyi=0
							for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
								nfyi+=w[j][rr][p+i*numangle2]
							endfor
						else
							nfyi=w[j][p+i*numangle2]
						endif
						nfx[j]=median(nfyi,-inf,inf)
					endfor //j
				else
					nfx=0
					for (j=0; j<numangle2; j+=1)
						if(is3d)
							for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
								nfx+=w[p][rr][i*numangle2+j]
							endfor
						else
							nfx+=w[p][i*numangle2+j]
						endif
					endfor
					nfx/=numangle2
				endif //useMedian
			endif //isNormX
			
			if(isNormY)
				if(useMedian)
					for(j=0;j<numangle2;j+=1)
						if(is3d)
							nfxi=0
							for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
								nfxi+=w[p][rr][j+i*numangle2]
							endfor
						else
							nfxi=w[p][j+i*numangle2]
						endif
						nfy[j]=median(nfxi,-inf,inf)
					endfor
				else
					nfy=0
					for(j=0; j<dimsize(w,a1dim); j+=1)
						nfy+=w[j][p+i*numangle2]
					endfor
					nfy/=dimsize(w,a1dim)
				endif //useMedian
			endif

			if(isNormX||isNormY)
				if(is3d)
					dnorm[0,dimsize(w,0)-1][i*numangle2,(i+1)*numangle2-1]=0
					for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
						dnorm[0,dimsize(w,0)-1][i*numangle2,(i+1)*numangle2-1]+=w[p][rr][q]/nfx[p]/nfy[q-i*numangle2]
					endfor
				else
					dnorm[0,dimsize(w,0)-1][i*numangle2,(i+1)*numangle2-1]=w[p][q]/nfx[p]/nfy[q-i*numangle2]
				endif
				nfy=1
			endif
			
			if(matchOverlap)
				make/o/n=(numangle2) $(df+"rght") $(df+"lft") //average data in overlap regions of left and right sides
				wave rght=$(df+"rght"), lft=$(df+"lft")
				nvar npm=$(df+"numPixelsMatch") //number of pixels to use in overlap region
				if(i==0)
					rght=0
					for (j=0; j<npm; j+=1)
						if(is3d)
							for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
								rght+=w[j+startpixel+numpixelsUse-1+xshift[j]][rr][p+yshift[j]]
							endfor
						else
							rght+=w[j+startpixel+numpixelsUse-1+xshift[j]][p+yshift[j]]
						endif
					endfor
					nfy=1	//don't norm first strip
				else
					lft=0
					for (j=0; j<npm; j+=1)
						if(is3d)
							for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
								lft+=w[startpixel-j+xshift[j]][rr][i*numangle2+p+yshift[j]]
							endfor
						else
							lft+=w[startpixel-j+xshift[j]][i*numangle2+p+yshift[j]]
						endif
					endfor
					nfyi=lft/rght
					smooth 200, nfyi
					nfy*=nfyi
					rght=0
					for (j=0; j<npm; j+=1)
						if(is3d)
							for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
								rght+=w[j+startpixel+numpixelsUse-1+xshift[j]][rr][i*numangle2+p+yshift[j]]
							endfor
						else
							rght+=w[j+startpixel+numpixelsUse-1+xshift[j]][i*numangle2+p+yshift[j]]
						endif
					endfor
				endif
				if(is3d)
					dnorm[0,dimsize(w,0)-1][i*numangle2,(i+1)*numangle2-1]=0
					for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
						dnorm[0,dimsize(w,0)-1][i*numangle2,(i+1)*numangle2-1]+=w[p][rr][q]/nfy[q-i*numangle2]
					endfor
				else
					dnorm[0,dimsize(w,0)-1][i*numangle2,(i+1)*numangle2-1]=w[p][q]/nfy[q-i*numangle2]
				endif
			endif
		endfor		
	else
		if(is3d)
			//print "integrating slices ",hxzp[0],hxzp[10]
			dnorm=0
			for(rr=hxzp[0];rr<=hxzp[10]; rr+=1)
				dnorm+=w[p][rr][q]
			endfor
		else
			dnorm=w[p][q]
		endif
	endif 
	
	//calculate image for phi0=0
	variable st,en
	for (i=0;i<numAngle;i+=1)
		if (i==0) //first strip, use extra on lhs
			st=0
			if (numangle>1)
				en=st+(numpixelsUse+startpixel-1)
			else
				en=st+dimsize(w,a1dim)	
			endif
		else
			st=startpixel+(i*abs(dAngle)/degPerPixel)
			if  (i==numangle-1) //last strip, use extra on rhs
				en=st+(numpixelsUse+startpixel-1)
			else
				en=st+(numpixelsUse-1)
			endif
		endif
		rawP[st,en][*]=p-st+(i!=0)*startpixel +xshift[i]
		rawQ[st,en][*]=i*numangle2 + coercerange(q + yshift[i],0,numangle2-1)
		ad0[st,en][*]=dnorm[rawP][rawQ]
	endfor
	
	nvar phi0=$(df+"phi0")
	if(phi0!=0)
		angle2k(df)	//converts to k and also does phi rotation
		k2angle(df)
	else
		duplicate/o ad0 $(df+"angdata")
	endif
	
	nvar ra=$(df+"recalcAngle")
	ra=0
	nvar rk=$(df+"recalcK")
	rk=(phi0==0)	//no need to recalc k if phi0 is nonzero--we have just calculated it
end

static function coercerange(x,x0,x1)
	variable x,x0,x1
	if(x<x0) 
		return x0
	else
		if(x>x1)
			return x1
		else
			return x
		endif
	endif
end

Function NormMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	nvar isNormX=$(df+"isNormX")
	nvar isNormY=$(df+"isNormY")
	nvar useMedian=$(df+"useMedian")
	nvar MatchOverlap=$(df+"MatchOverlap")
	nvar NumPixelsMatch=$(df+"NumPixelsMatch")
	svar normMenu=$(df+"normMenu")
	string newmenu=normMenu
	switch(popnum)	//numeric switch
		case 1:			//normx
			if(cmpstr(popstr[0],">")==0)
				isNormX=0
				newmenu=ReplaceItemInList( 0,"   normX", normMenu, ";" )
			else
				isNormX=1
				newmenu=ReplaceItemInList( 0,">normX", normMenu, ";" )
				MatchOverlap=0
				newmenu=ReplaceItemInList( 4,"   scale overlap regions to match", newMenu, ";" )
			endif
			break	
		case 2:			//normy
			if(cmpstr(popstr[0],">")==0)
				isNormY=0
				newmenu=ReplaceItemInList( 1,"   normY", normMenu, ";" )
			else
				isNormY=1
				newmenu=ReplaceItemInList( 1,">normY", normMenu, ";" )
				MatchOverlap=0
				newmenu=ReplaceItemInList( 4,"   scale overlap regions to match", newMenu, ";" )
			endif
		
			break
		case 3:			//use median
			if(cmpstr(popstr[0],">")==0)
				UseMedian=0
				newmenu=ReplaceItemInList( 2,"   use median", normMenu, ";" )
			else
				UseMedian=1
				newmenu=ReplaceItemInList( 2,">use median", normMenu, ";" )
			endif
			break
		case 4:			//(blank)
		case 5:			//match overlap regions
			if(cmpstr(popstr[0],">")==0)
				MatchOverlap=0
				newmenu=ReplaceItemInList( 4,"   scale overlap regions to match", normMenu, ";" )
			else
				MatchOverlap=1
				newmenu=ReplaceItemInList( 4,">scale overlap regions to match", normMenu, ";" )
				isNormX=0
				newmenu=ReplaceItemInList( 0,"   normX", newMenu, ";" )
				isNormY=0
				newmenu=ReplaceItemInList( 1,"   normY", newMenu, ";" )
			endif
			execute "PopupMenu normpopup value=\""+newMenu+"\""
			break
		case 6:			//set # pixels to match
			variable npm=numPixelsMatch
			prompt npm, "Enter new number of pixels to match (>0)"
			doprompt "(Option for Matching overlap region)", npm
			if (npm<1)
				npm=1
			endif
			numpixelsmatch=npm
			newmenu=ReplaceItemInList(5, "# pixels to match="+num2str(npm),normMenu,";")
			break
	endswitch
	execute "PopupMenu normpopup value=\""+newMenu+"\""
	normMenu=newMenu
	recalcall(df)
End

function is3d(df)
	string df
	svar wn=$(df+"wavname")
	wave w=$wn
	return dimsize(w,2)>1
end

//checks if 3d data set, then adjust hv if it is desired for deeper binding energy
//assumes negative=more bound BE
function gethv(df)
	string df
	nvar hv=$(df+"hv")
	nvar useBE=$(df+"useBE")
	if(useBE*is3d(df))
		nvar z0=$(df+"z0")
		return hv+z0
	else
		return hv
	endif
end

//returns maximum k-value of the set, considering useBE is set
function getmaxk(df)
	string df
	nvar hv=$(df+"hv")
	nvar useBE=$(df+"useBE")
	svar wn=$(df+"wavname")
	wave w=$wn
	if(useBE*is3d(df))
		return  0.5124*sqrt(hv +  dimoffset(w,1) + dimsize(w,1)*dimdelta(w,1))
	else
		return 0.5124*sqrt(hv)
	endif
end

function angle2k(df)
	string df
	//print "Transforming Angle to k..."
	svar mapp=$(df+"mapp")
	wave ad0 =$(df+"angData0")
	variable hv=gethv(df)
	variable a0=dimoffset(ad0,0), da=dimdelta(ad0,0),na=dimsize(ad0,0),a1=a0+da*na
	variable b0=dimoffset(ad0,1), db=dimdelta(ad0,1),nb=dimsize(ad0,1),b1=b0+db*nb
	variable k=0.5124*sqrt(hv), gmk=getmaxk(df)
	nvar f0=$(df+"phi0")
	variable kxmin, kxmax, kymin, kymax, kxminr,kxmaxr,kyminr,kymaxr
	if(cmpstr(mapp,"PolarAzimuth")==0)
		variable thmx=max(abs(dimoffset(ad0,0)), abs(dimoffset(ad0,0)+dimsize(ad0,0)*dimdelta(ad0,0)))
		variable kmx=gmk*sin(thmx*pi/180)
		kxminr=-kmx; kxmaxr=kmx
		kyminr=-kmx; kymaxr=kmx
	else
		kxmin=gmk*sin(a0*pi/180); kxmax=gmk*sin(a1*pi/180)	//min, max k before rotation
		kymin=gmk*sin(b0*pi/180); kymax=gmk*sin(b1*pi/180)
		findkRangeAfterRotation(f0*pi/180,kxmin,kxmax,kymin,kymax,kxminr,kxmaxr,kyminr,kymaxr)
	endif
	string kws=(df+"kdata")
	duplicate/o ad0 $kws
	wave kw=$kws
	nvar kms=$(df+"kmapsampling")
	redimension/n=(na*kms,nb*kms) kw
	setscale/i x kxminr, kxmaxr, "kx", kw
	setscale/i y kyminr, kymaxr, "ky", kw
	if(cmpstr(mapp,"PolarAzimuth")==0)
		string phiS=df+"phi", polarS=df+"polar"
		duplicate/o kw,$phiS, $polarS
		wave phi=$phiS, polar=$polarS
		phi=atan2(y,x)*180/pi
		polar=-1*asin(sqrt(x^2+y^2)/k)*180/pi
		kw=interp2d(ad0,polar,phi)
	else
		string bs=(df+"beta"),ts=(df+"theta")
		duplicate/o kw,$bs,$ts
		wave beta=$bs, theta=$ts
		theta=asin(x/k)*180/pi
		beta=asin(y/k/cos(asin(x/k)))*180/pi
		wavestats/q ad0
		kw=interp2d(ad0,theta,beta)
	endif
	nvar rk=$(df+"recalcK")
	rk=0
	if (f0!=0)
		rotatek(df)
	endif
end

function findkRangeAfterRotation(ang,kxmin,kxmax,kymin,kymax,kxminr,kxmaxr,kyminr,kymaxr)
	variable ang,kxmin,kxmax,kymin,kymax,&kxminr,&kxmaxr,&kyminr,&kymaxr
	//0=LL, 1=LR, 2=UR, 3=UL
	variable kx0=kxmin,kx1=kxmax,kx2=kxmax,kx3=kxmin
	variable ky0=kymin,ky1=kymin,ky2=kymax,ky3=kymax
	variable kx0r,kx1r,kx2r,kx3r
	variable ky0r,ky1r,ky2r,ky3r
	rotateXY(ang,kx0,ky0,kx0r,ky0r)
	rotateXY(ang,kx1,ky1,kx1r,ky1r)
	rotateXY(ang,kx2,ky2,kx2r,ky2r)
	rotateXY(ang,kx3,ky3,kx3r,ky3r)
	kxminr=min(min(kx0r,kx1r),min(kx2r,kx3r))
	kyminr=min(min(ky0r,ky1r),min(ky2r,ky3r))
	kxmaxr=max(max(kx0r,kx1r),max(kx2r,kx3r))
	kymaxr=max(max(ky0r,ky1r),max(ky2r,ky3r))
	if(kxmin>kxmax)
		switch0(kxminr,kxmaxr)
	endif
	if(kymin>kymax)
		switch0(kyminr,kymaxr)
	endif
end

function switch0(x,y)
	variable &x,&y
	variable temp
	temp=x
	x=y
	y=temp
end

function rotateXY(ang,x,y,xr,yr)
	variable ang,x,y,&xr,&yr
	xr=cos(ang)*x+sin(ang)*y
	yr=-sin(ang)*x+cos(ang)*y
end
	
//rotates the k-image using phi0 variable
//overwrites kdata array
function rotatek(df)
	string df
	//print "Rotating in kspace..."
	wave kd=$(df+"kdata")
	duplicate/o kd $(df+"kdtemp")
	duplicate/o kd  $(df+"kxr")
	duplicate/o kd $(df+"kyr")
	wave kdtemp=$(df+"kdtemp"), kxr=$(df+"kxr"), kyr=$(df+"kyr")
	nvar f0=$(df+"phi0")
	variable f00=f0*pi/180
	kxr=cos(f00)*x - sin(f00)*y
	kyr=sin(f00)*x+cos(f00)*y
	//kdtemp=kd(kxr)(kyr)
	kdtemp=interp2d(kd,kxr,kyr)	//** CHANGED BUT NOT TESTED **//
	duplicate/o kdtemp kd
end

//backtransformation from k-image to angles.
//only used for phi-rotated images
function k2angle(df)
	string df
	//print "Backtransforming k to angle space..."
	wave kd =$(df+"kData")
	variable a0=dimoffset(kd,0), da=dimdelta(kd,0),na=dimsize(kd,0),a1=a0+da*na
	variable b0=dimoffset(kd,1), db=dimdelta(kd,1),nb=dimsize(kd,1),b1=b0+db*nb
	variable k=0.5124*sqrt(gethv(df))
	variable thetamin, thetamax,betamin,betamax,dummy
	k2ang(df,a0,b0,thetamin,betamin,dummy)
	k2ang(df,a1,b1,thetamax,betamax,dummy)
	string kws=(df+"kdata"), bs=(df+"beta"),ts=(df+"theta")
	duplicate/o kd $(df+"angdata")
	wave ad=$(df+"angdata")
	setscale/i x thetamin,thetamax, "theta", ad
	setscale/i y betamin, betamax, "beta", ad
	duplicate/o ad,$(df+"kx"),$(df+"ky")
	wave kx=$(df+"kx"),ky=$(df+"ky")
	kx=k*sin(x*pi/180)
	ky=k*sin(y*pi/180)*cos(x*pi/180)
	//ad=kd(kx)(ky)							//main interpolation
	ad=interp2d(kd,kx,ky)
	nvar ra=$(df+"recalcAng")
	ra=0
end


function uniqueValues(win, wout)
	wave win, wout
	wout=0
	variable j=0, lastj=0,v,ni
	wout[0]=win[0]
	do
		v=uniqueValue(win,lastj,ni)
		//print j,lastj,v,ni
		lastj=ni
		j+=1
		if (!almostEqual(wout[j-1],v))
			//print j,wout[j],v
			wout[j]=v
		else
			redimension/n=(j) wout
			return(0)
		endif
	while ((j<numpnts(win))*(!almostEqual(wout[j-1],v)))
end	
	
//finds first unique value of wave w starting from point n
//returns w[n] if error or no unique next value
function uniqueValue(w,n,ni)
	wave w; variable n, &ni
	variable i=n+1, val=w[n], found=0
	do
		if (!almostequal(w[i],w[n]))
			found=1
			val=w[i]
		endif
		i+=1
	while((found==0)*(i<numpnts(w)))
	ni=i-1
	return(val)
end
			
function almostEqual(a,b)
	variable a,b
	//return abs((a-b)/(a+b)) < 1e-2
	return abs(a-b)<0.09
	
end

//convert points [wx,wy] from angle to k
function AngLine2k(df,wx,wy)
	string df
	wave wx,wy
	svar mapp=$(df+"mapp")
	string txs=df+"tempx"	
	string tys=df+"tempy"
	duplicate/o wx $txs
	wave tx=$txs
	duplicate/o wy $tys
	wave ty=$tys
	variable k=0.5124*sqrt(gethv(df))
	if (cmpstr(mapp,"TwoPolar")==0)
		tx=k*sin(pi/180*wx)							//kx
		ty=k*sin(pi/180*wy)*cos(pi/180*wx)		//ky
	else
		tx=k*sin(pi/180*sqrt(wx^2+wy^2))*sin(pi/180*wy)
		ty=k*sin(pi/180*sqrt(wx^2+wy^2))*cos(pi/180*wy)
	endif
	wx=tx
	wy=ty
end

//convert points [wx,wy] from k to angle
function kLine2Ang(df,wx,wy)
	string df
	wave wx,wy
	svar mapp=$(df+"mapp")
	string txs=df+"tempx"	
	string tys=df+"tempy"
	duplicate/o wx $txs
	wave tx=$txs
	duplicate/o wy $tys
	wave ty=$tys
	variable k=0.5124*sqrt(gethv(df))
	if (cmpstr(mapp,"TwoPolar")==0)
		tx=asin(wx/k)*180/pi  				 		//theta
		ty=asin(wy/k/cos(asin(wx/k)))*180/pi		//beta
	else
		tx=-asin(sqrt(wx^2+wy^2)/k)*180/pi		//polar
		ty=atan2(wy,wx)*180/pi						//azimuth
	endif
	wx=tx
	wy=ty
end

function k2Ang(df,kx,ky,theta,beta,phi)
	string df
	variable kx,ky
	variable &theta, &beta,&phi
	variable k=0.5124*sqrt(gethv(df))
	svar mapp=$(df+"mapp")
	if (cmpstr(mapp,"TwoPolar")==0)
		theta=asin(kx/k)*180/pi
		beta=asin(ky/k/cos(asin(kx/k)))*180/pi
		phi=atan2(ky,-kx)*180/pi
	else
		theta=-asin(sqrt(kx^2+ky^2)/k)*180/pi
		beta=nan
		phi=atan2(ky,kx)*180/pi
	endif
	return 0
end

function ang2k(df,theta,beta,kx,ky)
	string df
	variable &kx,&ky
	variable theta, beta
	variable k=0.5124*sqrt(gethv(df))
	kx=k*sin(pi/180*theta)
	ky=k*sin(pi/180*beta)*cos(pi/180*theta)
	return 0
end


function fixrange(dfname)
	string dfname
	wave d=$(dfname+"data")
	string dfn=stringfromlist(1,dfname,":")

	//dowindow/f $dfn
	variable dx0=dimoffset(d,0), dx1=dimoffset(d,0)+dimdelta(d,0)*dimsize(d,0)
	variable dy0=dimoffset(d,1), dy1=dimoffset(d,1)+dimdelta(d,1)*dimsize(d,1)
	setaxis/w=$dfn bottom, dx0,dx1
	setaxis/w=$dfn left,dy0,dy1
end

//================= G R A P H    C O N T R O L    R O U T I N E S	

//must make sure to have "KPlot" and not e.g. "KPlot1" etc
//should not have any image data or crosshair when creating macro
Window KPlotWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(584,102,1350,682) as "KPlot"
	ModifyGraph cbRGB=(16385,49025,65535)
	ShowTools
	ControlBar 100
	SetVariable setGamma,pos={240,83},size={50,14},proc=SetGamma,title="g"
	SetVariable setGamma,font="Symbol"
	SetVariable setGamma,limits={0.001,10,0.1},value= root:KPlot:gamma
	Button loadCT,pos={73,80},size={50,20},proc=floadCT,title="loadCT"
	CheckBox kmap,pos={124,21},size={51,14},proc=Checkboxkmap,title="kmap?",value= 0
	SetVariable hv,pos={207,20},size={75,15},proc=Sethv,title="hv"
	SetVariable hv,value= root:KPlot:hv
	SetVariable ang0,pos={5,24},size={100,15},proc=SetZeroAngles,title="theta0"
	SetVariable ang0,limits={-Inf,Inf,0.1},value= root:KPlot:theta0
	SetVariable ang1,pos={5,41},size={100,15},proc=SetZeroAngles,title="beta0"
	SetVariable ang1,limits={-Inf,Inf,0.1},value= root:KPlot:beta0
	CheckBox PolarGrid,pos={124,35},size={78,14},proc=CheckBoxPAGrid,title="Polar Grid..."
	CheckBox PolarGrid,value= 0
	CheckBox kGrid,pos={124,49},size={61,14},proc=CheckBoxkGrid,title="k-Grid..."
	CheckBox kGrid,value= 0
	CheckBox AzGrid,pos={124,63},size={91,14},proc=CheckBozAzGrid,title="Azimuth Grid..."
	CheckBox AzGrid,value= 0
	Button fixRange,pos={380,80},size={75,20},proc=fFixRange,title="fixRange"
	SetVariable theta,pos={299,16},size={70,15},title="q",font="Symbol",fSize=12
	SetVariable theta,value= root:KPlot:vdtheta
	SetVariable phi,pos={299,50},size={70,15},title="f",font="Symbol",fSize=12
	SetVariable phi,value= root:KPlot:vdphi
	SetVariable beta,pos={298,33},size={70,15},title="b",font="Symbol",fSize=12
	SetVariable beta,value= root:KPlot:vdbeta
	SetVariable k,pos={378,16},size={70,15},title="k",value= root:KPlot:vdk
	SetVariable kx,pos={378,33},size={70,15},title="kx",value= root:KPlot:vdkx
	SetVariable ky,pos={378,50},size={70,15},title="ky",value= root:KPlot:vdky
	SetVariable DegPerPixel,pos={5,7},size={100,15},proc=DegPixProc,title="Deg/Pix"
	SetVariable DegPerPixel,limits={0.001,0.5,0.002},value= root:KPlot:degperpixel
	SetVariable ang2,pos={5,58},size={100,15},proc=SetZeroAngles,title="phi0"
	SetVariable ang2,limits={-Inf,Inf,0.1},value= root:KPlot:phi0
	Button adjCT,pos={122,80},size={40,20},proc=adjCTProc,title="adjCT"
	Button Export,pos={312,80},size={50,20},proc=ExportProc,title="Export"
	Button Prefs,pos={23,80},size={50,20},proc=PrefsProc,title="Prefs"
	Button Z,pos={3,80},size={20,20},proc=doZ,title="Z"
	Button invCT01,pos={162,80},size={40,20},proc=InvCTProc,title="invCT"
	PopupMenu normpopup,pos={124,0},size={69,20},proc=NormMenuProc,title="norm..."
	PopupMenu normpopup,mode=0,value= #"\"   normX;   normY;   use median;--;   scale overlap regions to match;   # pixels to match=5\""
	SetVariable wave,pos={276,0},size={175,15},title="wave"
	SetVariable wave,value= root:KPlot:wavname
	SetVariable xshift,pos={459,6},size={200,15},title="XShift",value= acw,proc=setshift
	SetVariable yshift,pos={459,26},size={200,15},title="YShift",value= acw,proc=setshift
	SetWindow kwTopWin,hook=KPlotHookFcn,hookevents=3,hookcursor=20
EndMacro

Function cstyle(csrNum) : CursorStyle
	Variable csrNum
	Cursor/M/S=0/H=1/L=0 $num2char(0x41+csrNum) // /C=(24576,0,0)
	Return 0
End

//folders referenced should be kplot, not e.g. kplot0
//there shouldn't be any data plotted
Window kzplotWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(23,400,446,608) as "KPlot_z"
	ModifyGraph cbRGB=(0,43690,65535)
	ShowInfo
	ShowTools
	ControlBar 50
	Button XY,pos={0,1},size={30,20},proc=doXY,title="XY"
	SetVariable z0,pos={40,1},size={100,15},proc=SelectZSlice,title="Z0"
	SetVariable z0,limits={-1.7,0.0467811,0.00429185},value= root:KPlot:z0
	SetVariable zwidpix,pos={150,18},size={110,15},proc=SelectZSlice,title="Z-Wid(pix)"
	SetVariable zwidpix,limits={1,Inf,1},value= root:KPlot:zwp
	SetVariable z0pix,pos={39,16},size={100,15},proc=SelectZSlice,title="Z0(pix)"
	SetVariable z0pix,limits={0,407,1},value= root:KPlot:z0p
	SetVariable zwid,pos={149,2},size={110,15},proc=SelectZSlice,title="Z-Wid"
	SetVariable zwid,limits={-Inf,Inf,0.00429185},value= root:KPlot:zw
	CheckBox useBE,pos={37,34},size={75,14},proc=CheckBoxUseBE,title="BE --> hv?"
	CheckBox useBE,value= 0
	PopupMenu Batch,pos={266,6},size={118,20},proc=BatchProcMenu,title="Batch Process..."
	PopupMenu Batch,mode=0,value= #"\"To QT Movie;To Array\""
	SetWindow kwTopWin,hook=KZPlotHookFcn,hookevents=3,hookcursor=5
EndMacro


function kplotHookFcn(s)
	string s
	variable retval=0
	variable isMouse=strsearch(stringbykey("event",s),"mouse",0)>=0
	variable isKill=strsearch(stringbykey("event",s),"kill",0)>=0
	variable modif=numberbykey("modifiers",s) & 15
	string dfn=stringbykey("window",s)
	string dfname=":"+dfn+":"	//get data folder from window title
	nvar creating=$(dfname+"creating")
	//print s
	if((isMouse+isKill)*(creating==0))
		//string dfn=winlist("*","","win:")
		variable mx=numberbykey("mousex",s)
		variable my=numberbykey("mousey",s)
		nvar kmap=$(dfname+"kmap")
		nvar vdk=$(dfname+"vdk")
		nvar vdkx=$(dfname+"vdkx")
		nvar vdky=$(dfname+"vdky")
		nvar vdtheta=$(dfname+"vdtheta")
		nvar vdbeta=$(dfname+"vdbeta")
		nvar vdphi=$(dfname+"vdphi")
		nvar t0=$(dfname+"theta0")
		nvar b0=$(dfname+"beta0")
		nvar ra=$(dfname+	"recalcAngle")
		nvar rk=$(dfname+"recalcK")
		nvar is3D=$(dfname+"is3D")
		wave hy0=$(dfname+"hairy0")
		wave zp=$(dfname+"zprof")
		svar wn=$(dfname+"wavName")
		wave w=$wn
		svar mapp=$(dfname+"mapp")
		
		//convert mx and my to axis units 
		variable axmin, axmax, aymin, aymax,ax,ay
	 	GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
		GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
		ay=axisvalfrompixel(dfn,"left",my)
		ax=axisvalfrompixel(dfn,"bottom",mx)	
		//print ax,ay,kmap,dfname
		
		//MODIFIERS:flags	Bits set based on state of certain keys:
		//(1) bit 0:	mouse button is down.
		//(2) bit 1:	shift key is down.
		//(4) bit 2:	option (Mac) or ALT (Win) is down.
		//(8) bit 3:	command (Mac) or CTRL (Win) is down.
	
		variable upMod
		//if (cmpstr(igorinfo(2),"Macintosh")==0)
		//	upMod=4	//option click-up on Mac
		//else
		//	upMod=8	//ctrl-click-up on Windows
		//endif
		//variable downmod=9	//mousedown + cmd-ctrl keys
		//variable keymod=numberbykey("modifiers",s)==upMod
		variable mup=cmpstr(stringbykey("event",s),"mouseup")==0, axk,ayk,dummy
		variable mdn=cmpstr(stringbykey("event",s),"mousedown")==0
		variable mmv=cmpstr(stringbykey("event",s),"mousemoved")==0
//		if (keymod&mup)
//		if(numberbykey("modifiers",s)==upMod+1)
		if(modif==5)
			//Mac: option +mousedown
			//Windows: alt +mousedown
			//special mouse press--> change angle origin
			if(kmap)
				k2ang(dfname,ax,ay,axk,ayk,dummy)
			else
				axk=ax
				ayk=ay
			endif
			t0=t0+axk
			b0=b0+ayk
			DoSetZeroAngles(dfname)
		endif
		if((modif==9)*is3D*(StrSearch(s,"EVENT:mouse",0) > 0))
			//Mac: cmd +mousedown
			//Windows: ctrl +mousedown
			//special mouse press-->Move 3d cursor
			if(kmap)
				if(cmpstr(mapp,"TwoPolar")==0)
					k2ang(dfname,ax,ay,axk,ayk,dummy)
				else
					k2ang(dfname,ax,ay,axk,dummy,ayk)
				endif
			else
				axk=ax
				ayk=ay
			endif
			ModifyGraph offset(HairY0)={ax,ay}
			//print axk,ayk
			wave rawP=$(dfname+"rawP"), rawQ=$(dfname+"rawQ")
//			zp=interp3d(w,axk,x,ayk)
			zp=w[rawP(axk)(ayk)](x)[rawQ(axk)(ayk)]
			retval=1
		endif

		if (kmap)
			vdkx=ax
			vdky=ay
			vdk=sqrt(ax^2 + ay^2)
			variable theta, beta, phi
			k2ang(dfname,ax,ay,theta,beta,phi)
			vdtheta=theta
			vdbeta=beta
			vdphi=phi
		else
			vdtheta=ax
			vdbeta=ay
			variable kx,ky
			ang2k(dfname,ax,ay,kx,ky)
			vdkx=kx
			vdky=ky
			vdk=sqrt(kx^2+ky^2)
			vdphi=180-atan2(ky,kx)*180/pi
		endif
				
		if (cmpstr(stringbykey("event",s),"kill")==0)
			//window killed, so kill data
			dowindow/f $dfn
			setdatafolder root:
			removeimage data
			if(is3d)
				removefromgraph hairy0
				string zwin=dfn+"_z"
				dowindow/k $zwin
			endif
			killdatafolder $dfname
		endif
	endif

	return retval
end

function kzplothookfcn(s)
	string s
	variable retval=0
	variable isMouse=strsearch(stringbykey("event",s),"mouse",0)>=0
	variable modif=numberbykey("modifiers",s) & 15
	string dfn=stringbykey("window",s)
	string df=":"+getstrfromlist(dfn,0,"_")+":"
	if (ismouse*(modif==9))
		variable mx=numberbykey("mousex",s)
		variable my=numberbykey("mousey",s)

		variable axmin, axmax, aymin, aymax,ax,ay
	 	 GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
		GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
		ay=axisvalfrompixel(dfn,"left",my)
		ax=axisvalfrompixel(dfn,"bottom",mx)	
		nvar z0=$(df+"z0")
		z0=ax
		SelectZSlice("z0",ax,num2str(ax),"z0")
		retval=1
	endif
	return retval
end

Function SetGamma(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string dfname=getdf()	//get data folder from window title
	wave ct=root:colors:ct
	wave lct=$(dfname+"ct")
	nvar wct=$(dfname+"whichct")
	execute "loadct(" + num2str(wct) + ")"
	execute "ct_gamma(" + num2str(varNum)+")"	//get original color table
	lct=ct
End


function setColorScale(df)
	string df
	string ad=df+"angData"
	wavestats/q $ad
	setscale/i x v_min, v_max, "", $(df+"ct")
end


Function adjCTProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	wave d=$(df+"data")
	string winnam=stringfromlist(1,df,":")
	getmarquee
	variable mx0=min(v_left,v_right), mx1=max(v_left,v_right),my0=min( v_bottom, v_top),my1=max(v_bottom,v_top)
	
	//convert marquee to axis units	
	variable axmin, axmax, aymin, aymax,ax0,ay0,ax1,ay1
 	GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	ay0=axisvalfrompixel(winnam,"left",my0)
	ay1=axisvalfrompixel(winnam,"left",my1)
	ax0=axisvalfrompixel(winnam,"bottom",mx0)	
	ax1=axisvalfrompixel(winnam,"bottom",mx1)	
	
	//convert axis units to data units
	variable p0,p1,q0,q1
	p0=(ax0 - DimOffset(d, 0))/DimDelta(d,0)	
	p1=(ax1 - DimOffset(d, 0))/DimDelta(d,0)	
	q0=(ay0 - DimOffset(d,1))/DimDelta(d,1)	
	q1=(ay1 - DimOffset(d,1))/DimDelta(d,1)	
	imagestats/g={min(p0,p1),max(p0,p1),min(q0,q1),max(q0,q1)} d 
	//print p0,p1,q0,q1
	//print v_min, v_max, v_flag
	if (v_flag==0)
		setscale/i x v_min, v_max, "", $(df+"ct")
	endif
End

Function InvCTProc(ctrlName) : ButtonControl
	String ctrlName
	wave ct=root:colors:ct
	string dfname=getdf()	//get data folder from window title
	wave lct=$(dfname+"ct")
	lct=65535-lct
End

function doColors(dfname)
	string dfname
end

Function fFixRange(ctrlName) : ButtonControl
	String ctrlName
	string dfname=getdf()	//get data folder from window title
	fixrange(dfname)
End

//Function killWindow(ctrlName) : ButtonControl
//	String ctrlName
//	string dfname=winlist("*","","win:")	//get data folder from window title
//	dowindow/k $dfname
	//setdatafolder root:
	//killdatafolder $dfname	//delete is now taken care of by image hook function
//End

Function floadCT(ctrlName) : ButtonControl
	String ctrlName

	//window's current color properties
	string dfname=":"+winlist("*","","win:")+":"	//get data folder from window title
	wave lct=$(dfname+"ct")	//window's color table
	nvar wct=$(dfname+"whichct")	
	nvar gam=$(dfname+"gamma")

	//set working color table
	execute "loadctmenu()"
	nvar ctn=root:colors:currCT
	execute "ct_gamma(" + num2str(gam)+")"	//apply old gamma to new color table
	wave ct=root:colors:ct						//point to working color table

	lct=ct
	wct=ctn
End

Function Checkboxkmap(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string dfname=getdf()
	nvar rk=$(dfname+"recalcK")
	nvar ra=$(dfname+"recalcAngle")
	wave ad=$(dfname+"angData")
	wave d=$(dfname+"data")
	nvar kmap=$(dfname+"kmap")
	if(checked)
		if(rk)
			angle2k(dfname)
		endif
		wave kd=$(dfname+"kdata")
		duplicate/o kd d
	else
		if(ra)
			calcAngleData(dfname)
		endif
		duplicate/o ad d
	endif
	kmap=checked
	fixGrid(dfname)
	fixrange(dfname)
End

function fixGrid(dfname)
	string dfname
	nvar pg=$(dfname+"polarGrid")
	nvar gt=$(dfname+"gridtheta")
	nvar gb=$(dfname+"gridbeta")
	if(pg)
		execute "MakePolarGrid(\""+dfname+"\","+num2str(gt)+","+num2str(gb)+")"
	endif
	nvar kg=$(dfname+"kGrid")
	nvar gkx=$(dfname+"gridkx")
	nvar gky=$(dfname+"gridky")
	if(kg)
		execute "MakekGrid(\""+dfname+"\","+num2str(gkx)+","+num2str(gky)+")"
	endif
	nvar azg=$(dfname+"azGrid")
	nvar gphi0=$(dfname+"gridphi0")
	nvar gphi=$(dfname+"gridphi")
	nvar gpt=$(dfname+"gridphitheta")
	if(azg)
		execute "MakeAzGrid(\""+dfname+"\","+num2str(gphi0)+","+num2str(gphi)+","+num2str(gpt)+")"
	endif

end

//when theta0 and beta0 are altered
Function SetZeroAngles(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string dfname=getdf()	//get data folder from window title
	doSetZeroAngles(dfname)
End

Function DoSetZeroAngles(dfname)
	string dfname
	nvar kmap=$(dfname+"kmap")
	wave ad=$(dfname+"angData")
	wave d=$(dfname+"data")
	wave kd=$(dfname+"kdata")
	nvar f0=$(dfname+"phi0")
	calcAngleData(dfname)
	//print kmap
	if (kmap)
		if (f0==0)
			//if phi0 is nonzero, we have already done the angle transformation
			//in order to rotate the real space map
			angle2k(dfname)
		endif
		duplicate/o kd d	
	else
		duplicate/o ad d
	endif
	nvar raz=$(dfname+"rescaleafterrezero")
	if(raz)
		fixrange(dfname)
	endif
end

//when hv is selected
Function Sethv(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string dfname=getdf()  				//get data folder from window title
	nvar kmap=$(dfname+"kmap")
	wave d=$(dfname+"data")
	wave kd=$(dfname+"kdata")
	if(kmap)
		angle2k(dfname)
		duplicate/o kd d	
	else
		nvar rk=$(dfname+"recalcK")
		rk=1	//mark for recalc the next time kdata are plotted
	endif
	fixrange(dfname)
	fixgrid(dfname)
End

Function CheckBoxPAGrid(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string dfname=getdf()	//get data folder from window title
	svar mapp=$(dfname+"mapp")
	nvar pg=$(dfname+"polarGrid")
	if(cmpstr(mapp,"TwoPolar")==0)
		if(checked)
			execute "MakePolarGrid(\""+dfname+"\",,)"
		else
			string wlist=tracenamelist("",";",1)
			//print wlist
			if (strsearch(wlist,"tgridy",0)>=0)
				removefromgraph tgridy
			endif
			if(strsearch(wlist,"bgridy",0)>=0)
				removefromgraph bgridy
			endif
		endif
		pg=checked
	else
		doalert 0,"sorry, but polar grid does not apply to azimuth scans"
		pg=0
		checkbox polargrid,value=0
	endif
End

function gridthetaval()
	nvar gt=$(getdf()+"gridtheta")
	return gt
end
function gridbetaval()
	nvar gb=$(getdf()+"gridbeta")
	return gb
end
proc MakePolarGrid(df,dt,db)
	string df
	variable dt=gridthetaval()
	variable db=gridbetaval()
	prompt dt,"Theta grid spacing [deg]"
	prompt db,"Beta grid spacing [deg]"
	pauseupdate
	$(df+"gridtheta")=dt
	$(df+"gridbeta")=db
	variable t0=dimoffset($df+"angdata",0), td=dimdelta($df+"angdata",0), ts=dimsize($df+"angdata",0), t1=t0+td*ts, ts1=ts+1
	variable thetarange=td*ts
	variable b0=dimoffset($df+"angdata",1), bd=dimdelta($df+"angdata",1), bs=dimsize($df+"angdata",1), b1=b0+bd*bs,bs1=bs+1
	variable betarange=bd*bs

	variable ntheta=round(abs(thetarange/dt))+1
	string tgx=(df+"tgridx")
	string tgy=(df+"tgridy")
	make/o/n=(ntheta*bs1) $tgx,$tgy
	variable startT=min(t0,t1)-mod(min(t0,t1),dt)
	
	variable nbeta=round(abs(betarange/db))+1
	string bgx=(df+"bgridx")
	string bgy=(df+"bgridy")
	make/o/n=(ntheta*ts1) $bgx,$bgy

	variable startB=min(b0,b1)-mod(min(b0,b1),dt)

	iterate(ntheta)
		$tgx[i*bs1,(i+1)*bs1-2]=i*dt+startT
		$tgy[i*bs1,(i+1)*bs1-2]=b0+(p-bs1*i)*bd
		$tgy[(i+1)*bs1-1]=nan
	loop

	iterate(nbeta)
		$bgy[i*ts1,(i+1)*ts1-2]=i*db+min(b0,b1)-mod(min(b0,b1),db)
		$bgx[i*ts1,(i+1)*ts1-2]=t0+(p-ts1*i)*td
		$bgx[(i+1)*ts1-1]=nan
	loop
	
	variable kmap=$(df+"kmap")
	if (kmap)
		AngLine2k(df,$tgx,$tgy)
		Angline2k(df,$bgx,$bgy)
	endif
	string graphname=stringfromlist(1,df,":")
	string wlist=tracenamelist(graphname,";",1)
	if (strsearch(wlist,"tgridy",0)<0)
		append/w=$graphname $tgy vs $tgx
		ModifyGraph lstyle(tgridy)=3
	endif
	if (strsearch(wlist,"bgridy",0)<0)
		append/w=$graphname $bgy vs $bgx
		ModifyGraph lstyle(bgridy)=3
	endif
end

function gridkxval()
	nvar gkx=$(getdf()+"gridkx")
	return gkx
end
function gridkyval()
	nvar gky=$(getdf()+"gridky")
	return gky
end

proc MakekGrid(df,dkx,dky)
	string df
	variable dkx=gridkxval()// need to put in separate function because it fails otherwise under "execute"
	variable dky=gridkyval()
	prompt dkx,"kx grid spacing [1/]"
	prompt dky,"ky grid spacing [1/]"
	pauseupdate
	$(df+"gridkx")=dkx
	$(df+"gridky")=dky
	if (exists(df+"kdata")==0)
		angle2k(df)				//first time run, no kmap data calculated yet
	endif
	variable kx0=dimoffset($df+"kdata",0), kxd=dimdelta($df+"kdata",0), kxs=dimsize($df+"kdata",0), kx1=kx0+kxd*kxs,kxs1=kxs+1
	variable kxrange=kxd*kxs
	variable ky0=dimoffset($df+"kdata",1), kyd=dimdelta($df+"kdata",1), kys=dimsize($df+"kdata",1),  ky1=ky0+kyd*kys,kys1=kys+1
	variable kyrange=kyd*kys

	variable nkx=round(abs(kxrange/dkx))+1
	string kxgx=(df+"kxgridx")
	string kxgy=(df+"kxgridy")
	make/o/n=(nkx*kys1) $kxgx,$kxgy
	variable startKx=min(kx0,kx1)-mod(min(kx0,kx1),dkx)
	iterate(nkx)
		$kxgx[i*kys1,(i+1)*kys1-2]=(i)*dkx+startkx
		$kxgy[i*kys1,(i+1)*kys1-2]=ky0+(p-kys1*i)*kyd
		$kxgy[(i+1)*kys1-1]=nan
	loop

	variable nky=round(abs(kyrange/dky))+1
	string kygx=(df+"kygridx")
	string kygy=(df+"kygridy")
	make/o/n=(nkx*kxs1) $kygx,$kygy
	variable startKy=min(ky0,ky1)-mod(min(ky0,ky1),dky)
	iterate(nky)
		$kygy[i*kxs1,(i+1)*kxs1-2]=(i)*dky+startky
		$kygx[i*kxs1,(i+1)*kxs1-2]=kx0+(p-kxs1*i)*kxd
		$kygx[(i+1)*kxs1-1]=nan
	loop
	
	variable kmap=$(df+"kmap")
	if (!kmap)
		kLine2Ang(df,$kxgx,$kxgy)
		kLine2Ang(df,$kygx,$kygy)
	endif
	string graphname=stringfromlist(1,df,":")  //kplotN
	string wlist=tracenamelist(graphname,";",1)
	if (strsearch(wlist,"kxgridy",0)<0)
		append/w=$graphname $kxgy vs $kxgx
		ModifyGraph lstyle(kxgridy)=3
		ModifyGraph rgb(kxgridy)=(65535,32768,32768)
	endif
	if (strsearch(wlist,"kygridy",0)<0)
		append/w=$graphname $kygy vs $kygx
		ModifyGraph lstyle(kygridy)=3
		ModifyGraph rgb(kygridy)=(65535,32768,32768)
	endif
end

function gridaz0val()
	nvar gaz=$(getdf()+"gridphi0")
	return gaz
end
function gridazval()
	nvar gdaz=$(getdf()+"gridphi")
	return gdaz
end
function gridphithetaval()
	nvar gpt=$(getdf()+"gridphitheta")
	return gpt
end

proc MakeAzGrid(df,az0,daz,dth)
	string df
	variable az0=gridAz0Val()
	variable daz=gridazval()
	variable dth=gridPhiThetaVal()
	prompt az0,"azimuth shift [deg]"
	prompt daz,"az grid spacing [deg]"
	prompt dth,"th grid spacing [deg]"
	pauseupdate
	$(df+"gridphi")=daz
	$(df+"gridphitheta")=dth
	$(df+"gridphi0")=az0
	if (exists(df+"kdata")==0)
		angle2k(df)				//first time run, no kmap data calculated yet
	endif
	variable kx0=dimoffset($df+"kdata",0), kxd=dimdelta($df+"kdata",0), kxs=dimsize($df+"kdata",0), kxs1=kxs+1
	variable kxrange=kxd*kxs
	variable ky0=dimoffset($df+"kdata",1), kyd=dimdelta($df+"kdata",1), kys=dimsize($df+"kdata",1), kys1=kys+1
	variable kyrange=kyd*kys

	variable k=0.5124*sqrt(gethv(df))

	//rings
	variable kmax=max(max(abs(kx0),abs(ky0)),   max(abs(kx0+kxrange),abs(ky0+kyrange)))
	variable nth=round(180/pi*asin(kmax/k)/dth)+1
	string azthgx=(df+"azthgridx")
	string azthgy=(df+"azthgridy")
	make/o/n=(nth*101) $azthgx,$azthgy
	iterate(nth)
		$azthgy[i*101,(i+1)*101-2]=k*sin((i+1)*dth*pi/180)*cos(2*pi*p/99)
		$azthgx[i*101,(i+1)*101-2]=k*sin((i+1)*dth*pi/180)*sin(2*pi*p/99)
		$azthgx[(i+1)*101-1]=nan
	loop

	//rays
	string azgx=(df+"azgridx")
	string azgy=(df+"azgridy")
	variable nphi=round(360/daz)
	make/o/n=(nphi*101) $azgx,$azgy
	iterate(nphi)
		$azgx[i*101,(i+1)*101-2]=(p-i*101)*kmax*sqrt(2)/101*cos(pi/180*(daz*i-az0))
		$azgy[i*101,(i+1)*101-2]=(p-i*101)*kmax*sqrt(2)/101*sin(pi/180*(daz*i-az0))
		$azgy[(i+1)*101-1]=nan
	loop
	
	variable kmap=$(df+"kmap")
	if (!kmap)
		kLine2Ang(df,$azgx,$azgy)
		kLine2Ang(df,$azthgx,$azthgy)
	endif
	string graphname=stringfromlist(1,df,":")
	string wlist=tracenamelist(graphname,";",1)
	if (strsearch(wlist,"azgridy",0)<0)
		append/w=$graphname $azgy vs $azgx
		ModifyGraph lstyle(azgridy)=3
		ModifyGraph rgb(azgridy)=(65535,65535,0)
	endif
	if (strsearch(wlist,"azthgridy",0)<0)
		append/w=$graphname $azthgy vs $azthgx
		ModifyGraph lstyle(azthgridy)=3
		ModifyGraph rgb(azthgridy)=(65535,65535,0)
	endif
end

Function CheckBoxkGrid(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string dfname=getdf()	//get data folder from window title
	if(checked)
		execute "MakekGrid(\""+dfname+"\",,)"
	else
		string wlist=tracenamelist("",";",1)
		//print wlist
		if (strsearch(wlist,"kxgridy",0)>=0)
			removefromgraph kxgridy
		endif
		if(strsearch(wlist,"kygridy",0)>=0)
			removefromgraph kygridy
		endif
	endif
	nvar kg=$(dfname+"kGrid")
	kg=checked
End

Function CheckBozAzGrid(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string dfname=getdf()	//get data folder from window title
	if(checked)
		execute "MakeAzGrid(\""+dfname+"\",,,)"
	else
		string wlist=tracenamelist("",";",1)
		if (strsearch(wlist,"azgridy",0)>=0)
			removefromgraph azgridy
		endif
		if(strsearch(wlist,"azthgridy",0)>=0)
			removefromgraph azthgridy
		endif
	endif
	nvar ag=$(dfname+"AzGrid")
	ag=checked
End

//get data folder from topmost window name
function/s getdf()
	return ":"+winlist("*","","win:")+":"
end

//get data folder from topmost "Z" window name
function/s getdfZ()
	return ":"+getstrfromlist(winlist("*","","win:"),0,"_")+":"
end

function/s getwvnm()
	string df=getdf()
	svar wvnm=$(df+"wavName")
	return wvnm
end

Function DegPixProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string df=getdf()
	recalcall(df)
End


function recalcAll(df)
	string df
	nvar kmap=$(df+"kmap")
	wave d=$(df+"data")
	wave kd=$(df+"kdata")
	wave ad=$(df+"angdata")
	calcAngledata(df)
	if(kmap)
		angle2k(df)
		duplicate/o kd d
	else
		duplicate/o ad d
	endif
	fixgrid(df)
	nvar raz=$(df+"rescaleafterrezero")
	if(raz)
		fixrange(df)
	endif

	setColorscale(df)
end


Function ExportProc(ctrlName) : ButtonControl
	String ctrlName
	execute "doExport()"
End

proc doExport(name,symmetrize,whichSide)
	string name=uniquename(getwvnm()+"_",1,0)
	variable symmetrize,whichside
	prompt name, "Name of exported image"	
	prompt symmetrize, "Symmetrization option", popup "none;left/right;up/down;both"
	prompt whichside,"Keep which side",popup "pos;neg"
	symmetrize-=1
	string df=getdf()
	duplicate/o $(df+"ct") $(name+"ct")
	if (symmetrize)
		dosymmetrize($df+"data", name,symmetrize,whichside)
	else
		duplicate/o $(df+"data") $name
	endif
	display; appendimage $name
	modifyimage $name,cindex=$(name+"ct")
	if($(df+"aspect"))
		ModifyGraph width={Plan,1,bottom,left}
	endif
end

Function SetShift(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string df=getdf()
	//print df
	wave xs=$(df+"xshift"), ys=$(df+"yshift")
	svar xss=$(df+"xshiftstr"), yss=$(df+"yshiftstr")
	variable ii
	for(ii=0; ii<numpnts(xs); ii+=1)
		xs[ii]=str2num(stringfromlist(ii,xss,","))
		ys[ii]=str2num(stringfromlist(ii,yss,","))
	endfor
	recalcall(df)
End

function doSymmetrize(d,name,symoption,whichside)
	wave d
	string name
	variable symoption
	variable whichside
	variable a0=dimoffset(d,0), da=dimdelta(d,0),na=dimsize(d,0),a1=a0+da*na
	variable b0=dimoffset(d,1), db=dimdelta(d,1),nb=dimsize(d,1),b1=b0+db*nb
	variable sga=sign(da), sgb=sign(db)
	string name2
	whichside-=1	//0=pos,1=neg
	if (cmpstr(upperstr(nameofwave(d)),upperstr(name))==0)
		name2="temp_ds"
	else
		name2=name
	endif
	variable a0_=selectnumber(whichside,a0,a1)
	variable b0_=selectnumber(whichside,b0,b1)
	variable sgn=selectnumber(whichside,-1,1)
	switch(symoption)	// numeric switch
		case 1:		// LR
			make/n=(2*na+1,nb)/o $name2
			wave w=$name2
			setScale/i x -a0_,a0_,"",w
			setScale/p y b0,db,"",w
			w=interp2d(d,sgn*sga*abs(x),y)
			break						
		case 2:		//UD
			make/n=(na,2*nb+1)/o $name2
			wave w=$name2
			setscale/p x 0,da,"",w
			setscale/i y -b0_,b0_,"",w
			w=interp2d(d,x,-sgn*sgb*abs(y))
			break
		case 3:		//LRUD
			make/n=(2*na+1,2*nb+1)/o $name2
			wave w=$name2
			setScale/i x -a0_,a0_,"",w
			setscale/i y -b0_,b0_,"",w
			w=interp2d(d,sgn*sga*abs(x),-sgn*sgb*abs(y))
			break
		default:							
			duplicate/o d $name
	endswitch
	if (cmpstr(name2,"temp_ds")==0)
		duplicate/o w d
	endif
end

function doZ(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	string dfn=getstrfromlist(df,1,":") 	//folder name without the colons
	dowindow/f $(dfn+"_z")
	if (v_flag==0)
		makeZwin(dfn,df)
	endif
End

function makeZWin(dfn,df)
	string dfn,df
	newdatafolder/o root:kplot	//dummy folder so window creation doesn't bomb
	execute "kzplotwin()"
	dowindow/c/t $(dfn+"_z"), dfn+"_z"
	wave zp= $(df+"zprof"), hyz=$(df+"hairyz"), hxz=$(df+"hairxz")
	svar wn=$(df+"wavName")
	wave w=$wn
	setwindow $(dfn+"_z") hook=KZPlotHookFcn, hookcursor=5
	variable w0=dimoffset(w,2), wd=dimdelta(w,2), ws=dimsize(w,2), w1=w0+(ws-1)*wd

	SetVariable z0 value= $(df+"z0"),limits={min(w0,w1),max(w0,w1),wd}
	SetVariable zwid value= $(df+"zw"),limits={-Inf,Inf,wd}
	SetVariable z0pix value= $(df+"z0p"),limits={0,ws-1,1}
	SetVariable zwidpix value= $(df+"zwp"),limits={1,Inf,1}

	appendtograph zp
	appendtograph hyz vs hxz 
	ModifyGraph rgb(HairYZ)=(0,65535,65535)
	killdatafolder root:kplot
	return 0
end

proc doXY(ctrlName) : ButtonControl
	String ctrlName
	//print "hereXY"
	string df=getstrfromlist(getdf(),1,":")	//strip ":"
	df=getstrfromlist(df,0,"_")				//strip _xxx
	dowindow/f $df
End


Function PrefsProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	execute "doTPPrefs(,,)"
	recalcall(getdf())
End

proc doTPPrefs(Aspect,Rescale,kmapSampling)
	variable aspect=1+$(getdf()+"aspect")
	variable rescale=1+$(getdf()+"rescaleAfterReZero")
	variable kmapSampling=$(getdf()+"kmapSampling")
	prompt aspect, "Aspect ratio", popup "free;1:1"
	prompt rescale, "Rescale after Rezeroing", popup "no;yes"
	prompt kmapSampling, "K-map sampling (1=ok, >1 means better/slower)"
	string df=getdf()
	$(df+"aspect")=aspect-1
	$(df+"rescaleafterrezero")=rescale-1
	$(df+"kmapSampling")=kmapSampling
	if($(df+"aspect"))
		ModifyGraph width={Plan,1,bottom,left}
	else
		ModifyGraph width=0
	endif
end



Function CheckBoxUseBE(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string df=getdfz()
	nvar usebe=$(df+"useBE")
	usebe=checked
	nvar kmap=$(df+"kmap")
	if(kmap)
		recalcall(df)
	endif
End


Function SelectZSlice(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string df=getstrfromlist(getdf(),0,"_")
	//there is a bug--sometimes df comes back with ":" already
	if (cmpstr(df[strlen(df)-1],":")!=0)
		df+=":"
	endif
	wave hxz=$(df+"hairxz"), hxzp=$(df+"hairxzp")
	nvar z0=$(dF+"z0"), z0p=$(dF+"z0p"), zw=$(df+"zw"), zwp=$(df+"zwp")
	svar wn=$(df+"wavName")
	wave w=$wn
	variable w0=dimoffset(w,1), wd=dimdelta(w,1), ws=dimsize(w,1), w1=wd*(ws-1)
	strswitch(varname)	// string switch
		case "z0":
			z0p=round((z0 - w0)/wd)
			z0=w0+wd*z0p
			break
		case "zw":	
			zwp=max(1,round(abs(zw/wd)))
			zw=abs(zwp*wd)	
			break
		case "z0p":
			z0=w0+wd*z0p
			break
		case "zwp":
			zwp=max(1,zwp)
			zw=wd*zwp
			break
	endswitch
	variable iseven=(round(zwp/2.)==zwp/2), r0,r1,r2
	if (iseven)
		r0=-round(zwp/2)+1
		r2=round(zwp/2)
	else
		r2=(zwp-1)/2
		r0=-r2
	endif
	if((z0p+r0)<0)
		r0=-z0p
	endif
	if((z0p+r2)>=ws-1)
		r2=ws-z0p-1
	endif
	hxzp={r0,r0,r0,nan,0,0,0,nan,r2,r2,r2}
	hxzp+=z0p
	hxz=w0+wd*hxzp
	doupdate
	recalcall(df)
End

function BatchProcMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	//print popnum
	string df=getdfZ()
	variable isArray=(popnum==2)
	svar wn=$(df+"wavName")
	wave w=$wn
	wave zprof=$(df+"zprof")
	string newwv=wn+"_b"
	nvar z0p=$(df+"z0p"), zwp=$(df+"zwp")
	variable iseven=((zwp/2.)==round(zwp/2.))
	variable start
	if (iseven)
		start=zwp/2-1
	else
		start=(zwp-1)/2
	endif
	variable nz=round(dimsize(zprof,0)/zwp)
	print wn,dimsize(zprof,0),zwp,nz
	wave d=$(df+"data")
	if(isArray)
		variable nx=dimsize(d,0), ny=dimsize(d,1)
		make/o/n=(nx,ny,nz) $newwv
		wave nw=$newwv
		setscale/p x dimoffset(d,0),dimdelta(d,0),waveunits(d,0),nw
		setscale/p y dimoffset(d,1),dimdelta(d,1),waveunits(d,1),nw
		setscale/p z dimoffset(w,1),dimdelta(w,1)*zwp,waveunits(w,1),nw
		variable i
		for (i=0;i<nz;i+=1)
			z0p=start+(i*zwp)
			SelectZSlice("z0pix",z0p,num2str(z0p),"z0p")
			nw[][][i]=d[p][q]
		endfor
	endif
End
