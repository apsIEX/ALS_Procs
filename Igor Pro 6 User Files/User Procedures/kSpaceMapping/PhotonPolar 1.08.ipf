#pragma rtGlobals=1		// Use modern global access method.

menu "kspace" 
	"Polar Photon"
end

proc PolarPhoton(w,krange,anglerange,theta0,evoff,evincr)
	string w, krange, anglerange; variable theta0,evoff,evincr
	prompt w, "Image Array (3d)",popup, wavelist("!*_CT", ";","DIMS:3")
	prompt krange, "k-range [start, end, N], 1/Å"
	prompt anglerange, "Polar Angle [beta] Range [start,end,N]"
	prompt theta0,"Fixed Polar [theta] value"

	silent 1; pauseupdate
	variable stk=str2num(GetStrFromList(krange,0,",")),sta=str2num(GetStrFromList(AngleRange,0,","))
	variable enk=str2num(GetStrFromList(krange,1,",")),ena=str2num(GetStrFromList(AngleRange,1,","))
	variable nk=str2num(GetStrFromList(krange,2,",")), na=str2num(GetStrFromList(AngleRange,2,","))

	string df=newPPPlot(w,stk,enk,nk,sta,ena,na,theta0,evoff,evincr)
	newdatafolder/o PPPlot;   PPPlot()
	string dfn=stringfromlist(1,df,":")
	dowindow/c/t $dfn,dfn
	
	SetVariable degPerPixel,value= $(df+"degPerPixel")
	SetVariable eVPerPixel,value= $(df+"eVPerPixel")
	SetVariable eVOffset,value= $(df+"eVOffset")	
	setvariable gamma,value=$(df+"gamma")
	SetVariable motorStart,value= $(df+"startA")	
	SetVariable motorEnd,value= $(df+"endA")	
	SetVariable photonStart,value= $(df+"startK")	
	SetVariable photonEnd,value= $(df+"endK")	
	SetVariable cval,value= $(df+"cval")	
	setvariable nx,value=$(df+"nx")
	setvariable ny,value=$(df+"ny")
	setvariable nz,value=$(df+"nz")
	setvariable kx0,value=$(df+"kx0")
	setvariable kx1,value=$(df+"kx1")
	setvariable ky0,value=$(df+"ky0")
	setvariable ky1,value=$(df+"ky1")
	setvariable kz0,value=$(df+"kz0")
	setvariable kz1,value=$(df+"kz1")
	setvariable nl,value=$(df+"nl")
	setvariable klx0,value=$(df+"klx0")
	setvariable klx1,value=$(df+"klx1")
	setvariable kly0,value=$(df+"kly0")
	setvariable kly1,value=$(df+"kly1")
	setvariable klz0,value=$(df+"klz0")
	setvariable klz1,value=$(df+"klz1")
	setvariable theta0,value=$(df+"th0")

	calcPhotonCorrection(df)
	appendimage/R=pcRight/B=pcBottom $(df+"photCorrImg")
	append/R=pcRight/B=pcBottom $(df+"pc_y") vs $(df+"pc_x")
	ModifyGraph mode(pc_y)=3,marker(pc_y)=8
	append/R=pcRight/B=pcBottom $(df+"pcf_y") vs $(df+"pcf_x")
	ModifyGraph axisEnab(pcBottom)={0.6,1.0}
	ModifyGraph freePos(pcRight)=0,freePos(pcBottom)=0
	modifyimage photCorrImg, cindex=$(df+"photCorr_ct")
	setPhotCorrColors(df)
	
	make/n=(100,$(df+"numE")) $(df+"bmap")
	setscale/p y $(df+"evOffset"), $(df+"evPerPixel"), "BE", $(df+"bmap")
	setscale/i x, -1,4,"k",$(df+"bmap")
	$(df+"bmap")=sin(p/6)*cos(q/$("numE")*6)
	appendimage $(df+"bmap")
	modifyimage bmap,cindex=$(df+"bmap_ct")
	setbmapcolors(df)
			
	ModifyGraph axisEnab(Bottom)={0.0,0.5}

	imgtabfunc("",0)
	killdatafolder ppplot
end

 
	
function/s newPPPlot(w,stk,enk,nk,sta,ena,na,theta0,evoff,evincr)
	string w; variable stk,enk,nk,sta,ena,na,theta0,evoff,evincr
	string df=uniquename("PPPlot",11,0)
	newdatafolder $df
	df=":"+df+":"
	//here allocate working variables in the data folder
	variable/g $(df+"startk")=stk
	variable/g $(df+"endk")=enk
	variable/g $(df+"numK")=nk
	variable/g $(df+"startA")=sta
	variable/g $(df+"endA")=ena
	variable/g $(df+"numA")=na
	variable/g $(df+"th0")=theta0
	wave ww=$w
	variable/g $(df+"numE")=dimsize(ww,1)
	variable/g $(df+"numAD")=dimsize(ww,0) //# SES detector pixels
	variable/g $(df+"degPerPixel")=.064
	variable/g $(df+"evPerPixel")=evincr   //5/233
	variable/g $(df+"evOffset")=evoff
	variable/g $(df+"gamma")=0.3
	variable/g $(df+"e0")
	variable/g $(df+"cval")
	variable/g $(df+"constMode")=1 	//1=energy, 2=kx, etc
	//3d plot region default values
	variable/g $(df+"kx0")=-0.5
	variable/g $(df+"kx1")=0.5
	variable/g $(df+"nx")=100
	variable/g $(df+"ky0")=-1
	variable/g $(df+"ky1")=4
	variable/g $(df+"ny")=100
	variable/g $(df+"kz0")=3.5
	variable/g $(df+"kz1")=7.5
	variable/g $(df+"nz")=100
	//bandmap line default values
	variable/g $(df+"klx0")=0.0
	variable/g $(df+"klx1")=0.0
	variable/g $(df+"kly0")=-1.0
	variable/g $(df+"kly1")=4.0
	variable/g $(df+"klz0")=5.124
	variable/g $(df+"klz1")=5.124
	variable/g $(df+"nl")=100	
	string/g $(df+"wvName")=w
	nvar numAD=$(df+"numAD"), numA=$(df+"numA"), numK=$(df+"numK"), numE=$(df+"numE")
	nvar evPerPixel=$(df+"evPerPixel")
	nvar degPerPixel=$(df+"degPerPixel"), evPerPixel=$(df+"evPerPixel"), evOffset=$(df+"eVOffset")
	nvar startA=$(df+"startA"), endA=$(df+"endA"), startK=$(df+"startK"), endK=$(df+"endK")
	nvar th0=$(df+"th0")
	
	make/n=(nk) $(df+"kvals"); wave kvals=$(df+"kvals")
	kvals=stk+p*(enk-stk)/(nk-1)  //start with nominal k values here; users can correct later

	make/o/n=(numAD, numA, numK, numE) $(df+"wv")
	wave wv=$(df+"wv")

	make/o/n=(numK) $(df+"eCorr")	//energy correction for photons
	wave eCorr=$(df+"eCorr")

	eCorr=0
	
	make/o/n=(numK) $(df+"normF")	//intensity normalization function
	wave normF=$(df+"normF")
	variable i
	make/o/n=(numAD, numA, numE) $(df+"temp")
	wave wt=$(df+"temp")
	for (i=0; i<numK; i+=1	)
		wt=ww[p][r][q+i*numA]  //ww: AD, E, A
		wavestats/q wt
		normF[i]=v_avg
	endfor

	//smooth 20,normF
	//killwaves wt
	
	wv=ww[p][s+eCorr[r]/evPerPixel][q+r*numA]// / normF[r]
	
	variable thR=numAD*degPerPixel
	setscale/i x -thR/2+th0, thR/2+th0,"theta, deg",wv
	setscale/i y startA, endA,"beta, deg",wv
	setscale/i z startK,endK,"nom_k, 1/Å", wv
	setscale/p t eVOffset,eVPerPixel,"BE, eV", wv


	make/o/n=(256,3) $(df+"gray_ct"), $(df+"bmap_ct"), $(df+"photCorr_ct") 
	wave gray_ct=$(df+"gray_ct")
	gray_ct=p*256
	
	make/o/n=256 $(df+"pmap")
	wave pmap=$(df+"pmap")
	
	nvar gamma=$(df+"gamma")
	pmap=255*(p/255)^gamma
		
	wave bmap_ct=$(df+"bmap_ct")
	bmap_ct=gray_ct[pmap[p]][q]
	//setbmapcolors(df)
	
	wave photCorr_ct=$(df+"photCorr_ct")
	photCorr_ct=gray_ct[pmap[p]][q]
	//setPhotCorrColors(df)
	
	return df
end


//window with bmap should be topmost
function setBmapColors(df)
	string df
	wave bmap=$(df+"bmap"), bmap_ct=$(df+"bmap_ct")
	wavestats/q bmap
	setscale/i x v_min,v_max,"",bmap_ct
end
//window with photcorrimg should be topmost
function setPhotcorrColors(df)
	string df
	wave photCorrImg=$(df+"photCorrimg"), photCorr_ct=$(df+"PhotCorr_ct")
	wavestats/q photCorrimg
	setscale/i x v_min,v_max,"",photCorr_ct
end

Function SetGammaProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string df=getdf()
	nvar gamma=$(dF+"gamma")
	wave bmap_ct=$(df+"bmap_ct"), gray_ct=$(df+"gray_ct"), pmap=$(df+"pmap")
	wave photCorr_ct=$(df+"photCorr_ct")
	pmap=255*(p/255)^gamma
 	bmap_ct=gray_ct[pmap[p]][q]
 	photCorr_ct=gray_ct[pmap[p]][q]
 	setBmapColors(df)
 	setphotCorrColors(df)
End


Function SetThetaScale(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string df=getdf()
	wave wv=$(df+"wv")
	nvar numAD=$(df+"numAD")
	nvar th0=$(df+"th0")
	nvar degPerPixel=$(df+"degPerPixel")
	variable thR=numAD*degPerPixel
	setscale/i x -thR/2+th0, thR/2+th0,"theta, deg",wv	
End


function calcPhotonCorrection(df)
	string df
	nvar numE=$(df+"numE"), numK=$(df+"numK"), evOffset=$(df+"eVOffset")
	nvar evPerPixel=$(df+"evPerPixel"), startk=$(df+"startk"), endk=$(df+"endK")
	make/o/n=(numE,numK) $(df+"photCorrImg")
	wave pci=$(df+"photCorrImg")
	wave wv=$(df+"wv")
	setscale/p x evOffset, evPerPixel, "BE, eV", pci
	setscale/i y startK, endK, "k, 1/Å", pci
	pci=wv[dimsize(wv,0)/2][dimsize(wv,1)/2][q][p]	//typical EDC vs k
	variable i
	for(i=0; i<numK; i+=1)
		wavestats/q/r=[i*numE,i*numE +numE-1] pci
		pci[][i]/=v_avg
	endfor
	make/o/n=2 $(df+"pc_x"), $(df+ "pc_y")			//wave for generating spline points
	wave pc_x= $(df+"pc_x"), pc_Y=$(df+"pc_y")	
	pc_x=0
	pc_y[0]=dimoffset(wv,2); pc_y[1]=pc_y[0]+dimdelta(wv,2)*(dimsize(wv,2)-1)
	make/o/n=(numK) $(df+"pcf_x"), $(df+"pcf_y") //wave for fitting to splines
	wave pcf_x= $(df+"pcf_x"), pcf_Y=$(df+"pcf_y")	
	pcf_x=0
	pcf_y=dimoffset(wv,2) + p*dimdelta(wv,2)
end


//precalculates waves for photon correction
proc PhotCorrProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	//wave pc_x=$(df+"pc_x"), pc_y=$(df+"pc_y")
	graphwaveedit pc_y
	Button done proc=photCorrDone,title="done",pos={64,80}

End

function photCorrDone(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	graphnormal
	wave pc_x=$(df+"pc_x"), pc_y=$(df+"pc_y")
	wave pcf_x=$(df+"pcf_x"), pcf_y=$(df+"pcf_y")
	wave eCorr=$(df+"eCorr")
	wave wv=$(df+"wv")
	svar wvnm=$(df+"wvname")
	wave w=$wvnm
	wave normF=$(df+"normF")
	nvar numA=$(df+"numA"),eVPerPixel=$(df+"evPerPixel"),evOffset=$(df+"evOffset")
	CurveFit poly 4, pc_x /X=pc_y
	pcf_x=k0+k1*pcf_y + k2*(pcf_y^2) + k3*(pcf_y^3)
	eCorr=pcf_x
	wavestats/q eCorr
	wv=w[p][s+(eCorr[r]-v_min)/evPerPixel][q+r*numA]//   /normF[r]
	//wavestats/q pc_x
	setscale/p t,evOffset-v_min,eVPerPixel,waveunits(wv,3),wv
	killcontrol done
End


Function SendToProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	nvar cMode=$(df+"constMode"), cVal=$(df+"cVal"), eVoffset=$(df+"evOffset"), evPerPixel=$(df+"eVPerPixel")
	nvar numA=$(df+"numA"), numAD=$(df+"numAD"), numK=$(df+"numK"), numE=$(df+"numE")
	svar wvn=$(df+"wvName")
	wave wv=$(df+"wv")	//4d wave
	nvar kx0=$(df+"kx0"),kx1=$(df+"kx1")
	nvar ky0=$(df+"ky0"),ky1=$(df+"ky1")
	nvar kz0=$(df+"kz0"),kz1=$(df+"kz1")
	nvar nx=$(df+"nx"),ny=$(df+"ny"), nz=$(df+"nz")
	variable ii
	variable deltaE, offE, i
	variable k0, kd, kn, k1

	if(cMode==1)	//energy
		//extract 3d subset of data
		make/o/n=(numAD, numA, numK) $(df+"sub3d")	//theta, beta1, ktot
		wave sub3d=$(df+"sub3d")
		sub3d=wv[p][q][r](cVal)
		//make normalization from 2d subsets of data
		make/o/n=(numAD, numA) $(df+"sub2d"); wave sub2d=$(df+"sub2d")
		make/o/n=(numK) $(df+"normFE"); wave normFE=$(df+"normFE")
		for (ii=0;ii<numK;ii+=1)
			sub2d=wv[p][q][ii](cval)
			wavestats/q sub2d
			normFE[ii]=v_avg
		endfor
		sub3d/=normFE[r]
			
		setscale/p x dimoffset(wv,0), dimdelta(wv,0), waveunits(wv,0),sub3d
		setscale/p y dimoffset(wv,1), dimdelta(wv,1), waveunits(wv,1),sub3d
		k0=dimoffset(wv,2)
		kd=dimdelta(wv,2)
		kn=dimsize(wv,2)
		k1=(kn-1)*kd+k0
		k0=.5124*sqrt((k0/.5124)^2+cVal)
		k1=.5124*sqrt((k1/.5124)^2+cVal)
		setscale/i z k0,k1,waveunits(wv,2),sub3d
		
		//make kxyz map at constant e
		make/o/n=(nx,ny,nz) $(wvn+"_e")
		wave wvout=$(wvn+"_e")
		setscale/i x, kx0, kx1, "kx", wvout
		setscale/i y, ky0, ky1, "ky", wvout
		setscale/i z, kz0,kz1,"kz", wvout
		duplicate/o wvout $(df+"theta"), $(df+"beta1"), $(df+"ktot")
		wave theta=$(df+"theta"), beta1=$(df+"beta1"), ktot=$(df+"ktot")
		ktot=sqrt(x^2+y^2+z^2)
		ktot=0.5124*sqrt((ktot/.5124)^2+cval)
		theta=asin(x/ktot)
		beta1=asin(y/ktot/cos(theta))
		wvout=interp3d(sub3d, theta*180/pi, beta1*180/pi, ktot)
	endif
	if(cMode==2) //theta
		//extract 3d subset of data
		make/o/n=(numA, numK, numE) $(df+"sub3d")
		wave sub3d=$(df+"sub3d")
		sub3d=wv(cval)[p][q][r]
		setscale/p x dimoffset(wv,1), dimdelta(wv,1), waveunits(wv,1),sub3d
		setscale/p y dimoffset(wv,2), dimdelta(wv,2), waveunits(wv,2),sub3d
		setscale/p z dimoffset(wv,3), dimdelta(wv,3), waveunits(wv,3),sub3d
		//make ky, E, kz map at constant theta
		make/o/n=(nx,nz,numE) $(wvn+"_th")
		wave wvout=$(wvn+"_th")
		setscale/i x, ky0,ky1,"ky", wvout
		setscale/p y evOffset, evPerPixel, "BE", wvout
		setscale/i z, kz0,kz1,"kz", wvout
		duplicate/o wvout, $(df+"beta1"), $(df+"kk"), $(df+"ktot")
		wave beta1=$(df+"beta1")
		wave kk=$(df+"kk")	//this is k at the fermi level
		wave ktot=$(df+"ktot")
		kk=sqrt(x^2+z^2)	
		ktot=.5124*sqrt((kk/.5124)^2 - y)
		beta1=asin(x/ktot/cos(cval*pi/180))*180/pi
		wvout=interp3d(sub3d,beta1, z, ktot)
	endif
	if(cMode==3)	//energy
		doalert 1,"This will take a while. Are you sure?"
		if (v_flag==2)	//NO
			return (-1)
		endif
		//loop for extracting each E_binding
		numE=Dimsize (wv,3) 
		deltaE=DimDelta (wv,3) 
		offE=DimOffset (wv,3) 
		make/o/n=(nx,ny,nz, numE) $(wvn+"_4d")
		wave wvout4=$(wvn+"_4d")			
		setscale/i x, kx0, kx1, "kx", wvout4
		setscale/i y, ky0, ky1, "ky", wvout4
		setscale/i z, kz0,kz1,"kz", wvout4
		setscale/p t, offE,deltaE,"BE", wvout4

		for (i=0;i<numE;i+=1)
			cVal=offE+deltaE*i		

			//extract 3d subset of data
			make/o/n=(numAD, numA, numK) $(df+"sub3d")	//theta, beta1, ktot
			wave sub3d=$(df+"sub3d")
			sub3d=wv[p][q][r](cVal)
			//make normalization from 2d subsets of data
			make/o/n=(numAD, numA) $(df+"sub2d"); wave sub2d=$(df+"sub2d")
			make/o/n=(numK) $(df+"normFE"); wave normFE=$(df+"normFE")
			for (ii=0;ii<numK;ii+=1)
				sub2d=wv[p][q][ii](cval)
				wavestats/q sub2d
				normFE[ii]=v_avg
			endfor
			sub3d/=normFE[r]
			
			setscale/p x dimoffset(wv,0), dimdelta(wv,0), waveunits(wv,0),sub3d
			setscale/p y dimoffset(wv,1), dimdelta(wv,1), waveunits(wv,1),sub3d
			k0=dimoffset(wv,2)
			kd=dimdelta(wv,2)
			kn=dimsize(wv,2)
			k1=(kn-1)*kd+k0
			k0=.5124*sqrt((k0/.5124)^2+cVal)
			k1=.5124*sqrt((k1/.5124)^2+cVal)
			setscale/i z k0,k1,waveunits(wv,2),sub3d
		
			//make kxyz map at constant e
			make/o/n=(nx,ny,nz) $(wvn+"_e")
			wave wvout=$(wvn+"_e")
			setscale/i x, kx0, kx1, "kx", wvout
			setscale/i y, ky0, ky1, "ky", wvout
			setscale/i z, kz0,kz1,"kz", wvout
			duplicate/o wvout $(df+"theta"), $(df+"beta1"), $(df+"ktot")
			wave theta=$(df+"theta"), beta1=$(df+"beta1"), ktot=$(df+"ktot")
			ktot=sqrt(x^2+y^2+z^2)  //no BE correction
			ktot=0.5124*sqrt((ktot/.5124)^2+cval)
			theta=asin(x/ktot)
			beta1=asin(y/ktot/cos(theta))
			wvout=interp3d(sub3d, theta*180/pi, beta1*180/pi, ktot)

			wvout4[][][][i]=wvout[p][q][r]
		endfor
	endif
End

Function MapItProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	wave bmap=$(df+"bmap"), wv=$(df+"wv") //AD,A,K,E
	nvar numE=$(df+"numE"), numAD=$(df+"numAD"), numA=$(df+"numA"), numK=$(df+"numK"), nl=$(df+"nl")
	nvar klx0=$(df+"klx0"),kly0=$(df+"kly0"),klz0=$(df+"klz0") 
	nvar klx1=$(df+"klx1"),kly1=$(df+"kly1"),klz1=$(df+"klz1") 
	nvar nx=$(df+"nx"), ny=$(df+"ny"), nz=$(df+"nz")
	nvar kx0=$(df+"kx0"),ky0=$(df+"ky0"),kz0=$(df+"kz0") 
	nvar kx1=$(df+"kx1"),ky1=$(df+"ky1"),kz1=$(df+"kz1") 
	nvar whichx=:imagetool:x0, whichy=:imagetool:y0, whichz=:imagetool:z0
	nvar islicedir=:imagetool:islicedir //1=XY, 2=XZ, 3=YZ
	variable kmin,kmax,nk
	if(popnum==1)	//map from manual numbers
		nk=nl
		kmin=0
		kmax=sqrt((klx1-klx0)^2 + (kly1-kly0)^2 + (klz1-klz0)^2)
	endif
	if(popnum==2)	//kx-line from imagetool
		nk=nx
		kmin=kx0
		kmax=kx1
	endif
	if(popnum==3) //ky-line from imagetool
		nk=ny
		kmin=ky0
		kmax=ky1
	endif
	if(popnum==4)
		nk=nz
		kmin=kz0
		kmax=kz1
	endif
	redimension/n=(nk,numE) bmap 
	setscale/i x,kmin,kmax,"k-line",bmap
	setscale/p y,dimoffset(wv,3),dimdelta(wv,3),waveunits(wv,3),bmap
	duplicate/o bmap $(df+"kx"), $(df+"ky"), $(df+"kz"), $(df+"kk"),$(df+"theta"),$(df+"beta1")
	wave kx=$(df+"kx"), ky=$(df+"ky"), kz=$(df+"kz"), kk=$(df+"kk"),theta=$(df+"theta"),beta1=$(df+"beta1")
	if(popnum==1)
		kx=klx0+p*(klx1-klx0)/(nl-1)
		ky=kly0+p*(kly1-kly0)/(nl-1)
		kz=klz0+p*(klz1-klz0)/(nl-1)
	endif
	if(popnum==2)	//x-slice
		kx=x
		ky=(islicedir==1)*whichy +(islicedir==2)*whichz  + (islicedir==3)*whichx
		kz=(islicedir==1)*whichz + (islicedir==2)*whichy + (islicedir==3)*whichy
	endif
	if(popnum==3)//y-slice
		kx=(islicedir==1)*whichx + (islicedir==2)*whichx + (islicedir==3)*whichz
		ky=x
		kz=(islicedir==1)*whichz + (islicedir==2)*whichy + (islicedir==3)*whichy
	endif
	if(popnum==4) //z-slice
		kx=(islicedir==1)*whichx + (islicedir==2)*whichx + (islicedir==3)*whichz
		ky=(islicedir==1)*whichy +(islicedir==2)*whichz  + (islicedir==3)*whichx
		kz=x
	endif
	kk=sqrt(kx^2+ky^2+kz^2)
	theta=asin(kx/kk)
	beta1=asin(ky/kk/cos(theta))
	//bmap=wv(theta*180/pi)(beta1*180/pi)(kk)(y) //fast method, inferior quality
	make/o/n=(numAD, numA, numK) $(df+"sub3d")	//theta, beta1, ktot
	wave sub3d=$(df+"sub3d")
	setscale/p x dimoffset(wv,0), dimdelta(wv,0), waveunits(wv,0),sub3d
	setscale/p y dimoffset(wv,1), dimdelta(wv,1), waveunits(wv,1),sub3d
	variable k0=dimoffset(wv,2), kd=dimdelta(wv,2), kn=dimsize(wv,2), k1=(kn-1)*kd+k0
	variable kk0, kk1
	make/o/n=(numE) $(df+"en")
	wave en=$(df+"en")
	en=dimoffset(wv,3)+dimdelta(wv,3)*p
	variable i
	for (i=0;i<numE;i+=1)
		sub3d=wv[p][q][r][i]
		kk0=.5124*sqrt((k0/.5124)^2+en[i])
		kk1=.5124*sqrt((k1/.5124)^2+en[i])
		//print k0,k1, kk0,kk1,en[i]
		setscale/i z k0,k1,waveunits(wv,2),sub3d
		//bmap=sub3d[p][q][0]
		//doupdate
		bmap[][i]=interp3d(sub3d,theta*180/pi,beta1*180/pi,kk)
	endfor
	setbmapcolors(df)
End


Function ConstProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	nvar constmode=$(df+"constMode")	//1=energy, 2=kx, etc.
	constMode=popnum
End



//get data folder from topmost window name
static function/s getdf()
	return ":"+winlist("*","","win:")+":"
end

//should not contain references to e.g. pplot0
//should not have any data on it
Window ppplot() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(118,284,850,682) as "PPPlot"
	ModifyGraph cbRGB=(32769,65535,32768)
	ShowTools
	ControlBar 104
	Button Correct,pos={5,59},size={75,20},proc=PhotCorrProc,title="Correct..."
	PopupMenu MotorType,pos={93,1},size={76,20},title="Motor    "
	PopupMenu MotorType,mode=0,value= #"\"Beta;Theta;Phi\""
	SetVariable motorStart,pos={93,23},size={75,15},title="start"
	SetVariable motorStart,value= root:ppplot:startA
	SetVariable degPerPixel,pos={183,24},size={110,15},proc=SetThetaScale,title="degPerPixel"
	SetVariable degPerPixel,value= root:ppplot:degPerPixel
	SetVariable eVPerPixel,pos={183,40},size={110,15},title="eVPerPixel"
	SetVariable eVPerPixel,value= root:ppplot:eVPerPixel
	SetVariable theta0,pos={93,61},size={75,15},title="theta",value= root:ppplot:theta0,proc=SetThetaScale
	SetVariable motorEnd,pos={93,39},size={75,15},title="end"
	SetVariable motorEnd,value= root:ppplot:endA
	PopupMenu Constant,pos={320,2},size={122,20},proc=ConstProc,title="Constant..."
	PopupMenu Constant,mode=1,popvalue="Energy",value= #"\"Energy;theta;All energies (4d);ky;kz;hv\""
	SetVariable cval,pos={442,3},size={75,15},title=" val",value= root:ppplot:cval
	PopupMenu SendTo,pos={540,1},size={82,20},proc=SendToProc,title="Send to..."
	PopupMenu SendTo,mode=0,value= #"\"Memory;Image Tool;Slicer;Surface Plot;\""
	PopupMenu Photon,pos={15,1},size={66,20},title="Photon"
	PopupMenu Photon,mode=0,value= #"\"Enter Values Below\""
	SetVariable photonStart,pos={4,23},size={75,15},title="start"
	SetVariable photonStart,value= root:ppplot:startK
	SetVariable photonEnd,pos={3,41},size={75,15},title="end"
	SetVariable photonEnd,value= root:ppplot:endK
	PopupMenu Detector,pos={182,1},size={112,20},title="Detector         "
	PopupMenu Detector,mode=0,value= #"\"Enter Values Below\""
	SetVariable eVOffset,pos={183,56},size={110,15},title="eVOffset"
	SetVariable eVOffset,value= root:ppplot:eVOffset
	SetVariable gamma size={60,20},title="g",font="Symbol",limits={0.01,100,0.1}
	setvariable gamma pos={175,80},value=root:ppplot:gamma, proc=setgammaproc
	TabControl imgTab,pos={320,22},size={350,75},proc=imgTabFunc
	TabControl imgTab,tabLabel(0)="3d range",tabLabel(1)="band map",value= 0
	SetVariable kx0,pos={340,46},size={75,15},disable=1,title="kx0"
	SetVariable kx0,value= root:ppplot:kx0
	SetVariable kx1,pos={425,46},size={75,15},disable=1,title="kx1"
	SetVariable kx1,value= root:ppplot:kx1
	SetVariable ky0,pos={340,59},size={75,15},disable=1,title="ky0"
	SetVariable ky0,value= root:ppplot:ky0
	SetVariable ky1,pos={425,59},size={75,15},disable=1,title="ky1"
	SetVariable ky1,value= root:ppplot:ky1
	SetVariable kz0,pos={340,73},size={75,15},disable=1,title="kz0"
	SetVariable kz0,value= root:ppplot:kz0
	SetVariable kz1,pos={425,73},size={75,15},disable=1,title="kz1"
	SetVariable kz1,value= root:ppplot:kz1
	SetVariable nx,pos={510,46},size={75,15},disable=1,title="nx"
	SetVariable nx,value= root:ppplot:nx
	SetVariable ny,pos={510,59},size={75,15},disable=1,title="ny"
	SetVariable ny,value= root:ppplot:ny
	SetVariable nz,pos={510,73},size={75,15},disable=1,title="nz"
	SetVariable nz,value= root:ppplot:nz
	SetVariable klx0,pos={340,46},size={75,15},title="klx0",value= root:ppplot:klx0
	SetVariable klx1,pos={425,46},size={75,15},title="klx1",value= root:ppplot:klx1
	SetVariable kly0,pos={340,59},size={75,15},title="kly0",value= root:ppplot:kly0
	SetVariable kly1,pos={425,59},size={75,15},title="kly1",value= root:ppplot:kly1
	SetVariable klz0,pos={340,73},size={75,15},title="klz0",value= root:ppplot:klz0
	SetVariable klz1,pos={425,73},size={75,15},title="klz1",value= root:ppplot:klz1
	SetVariable nl,pos={510,46},size={75,15},title="num",value= root:ppplot:nl
	PopupMenu MapIt,pos={512,66},size={75,20},proc=MapItProc,title="Map It..."
	PopupMenu MapIt,mode=0,value= #"\"Manual;ImageTool kx-line;ImageTool ky-line;ImageTool kz-line\""
EndMacro

function imgTabFunc(name,tab)
	string name; variable tab
	setvariable kx0,disable=(tab!=0); setvariable ky0,disable=(tab!=0); setvariable kz0,disable=(tab!=0)
	setvariable kx1,disable=(tab!=0);setvariable ky1,disable=(tab!=0);setvariable kz1,disable=(tab!=0)
	setvariable nx,disable=(tab!=0);setvariable ny,disable=(tab!=0);setvariable nz,disable=(tab!=0)

	setvariable klx0,disable=(tab!=1); setvariable kly0,disable=(tab!=1); setvariable klz0,disable=(tab!=1)
	setvariable klx1,disable=(tab!=1);setvariable kly1,disable=(tab!=1);setvariable klz1,disable=(tab!=1)
	setvariable nl,disable=(tab!=1)
	popupmenu mapit,disable=(tab!=1)
end