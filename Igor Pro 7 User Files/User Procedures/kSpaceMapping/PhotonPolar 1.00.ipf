#pragma rtGlobals=1		// Use modern global access method.

menu "kspace" 
	"Polar Photon"
end

proc PolarPhoton(w,krange,anglerange)
	string w, krange, anglerange
	prompt w, "Image Array (3d)",popup, wavelist("!*_CT", ";","DIMS:3")
	prompt krange, "k-range [start, end, N], 1/Å"
	prompt anglerange, "Polar Angle Range [start,end,N]"

	silent 1; pauseupdate
	variable stk=str2num(GetStrFromList(krange,0,",")),sta=str2num(GetStrFromList(AngleRange,0,","))
	variable enk=str2num(GetStrFromList(krange,1,",")),ena=str2num(GetStrFromList(AngleRange,1,","))
	variable nk=str2num(GetStrFromList(krange,2,",")), na=str2num(GetStrFromList(AngleRange,2,","))

	string df=newPPPlot(w,stk,enk,nk,sta,ena,na)
	newdatafolder/o PPPlot;   PPPlot()
	string dfn=stringfromlist(1,df,":")
	dowindow/c/t $dfn,dfn
	
	SetVariable degPerPixel,value= $(df+"degPerPixel")
	SetVariable eVPerPixel,value= $(df+"eVPerPixel")
	SetVariable eVOffset,value= $(df+"eVOffset")	
	SetVariable motorStart,value= $(df+"startA")	
	SetVariable motorEnd,value= $(df+"endA")	
	SetVariable photonStart,value= $(df+"startK")	
	SetVariable photonEnd,value= $(df+"endK")	
	SetVariable cval,value= $(df+"cval")	

	calcPhotonCorrection(df)
	appendimage/L=pcLeft/B=pcBottom $(df+"photCorrImg")
	append/L=pcLeft/B=pcBottom $(df+"pc_y") vs $(df+"pc_x")
	ModifyGraph mode(pc_y)=3,marker(pc_y)=8
	append/L=pcLeft/B=pcBottom $(df+"pcf_y") vs $(df+"pcf_x")
	//ModifyGraph axisEnab(pcLeft)={0,0.5},axisEnab(pcBottom)={0,0.5}

	killdatafolder ppplot
end

function/s newPPPlot(w,stk,enk,nk,sta,ena,na)
	string w; variable stk,enk,nk,sta,ena,na
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
	wave ww=$w
	variable/g $(df+"numE")=dimsize(ww,1)
	variable/g $(df+"numAD")=dimsize(ww,0) //# SES detector pixels
	variable/g $(df+"degPerPixel")=.064
	variable/g $(df+"evPerPixel")=5/233
	variable/g $(df+"evOffset")=-1.8
	variable/g $(df+"e0")
	variable/g $(df+"kx0")
	variable/g $(df+"ky0")
	variable/g $(df+"kz0")
	variable/g $(df+"cval")
	variable/g $(df+"constMode")=1 	//1=energy, 2=kx, etc
	string/g $(df+"wvName")=w
	nvar numAD=$(df+"numAD"), numA=$(df+"numA"), numK=$(df+"numK"), numE=$(df+"numE")
	nvar evPerPixel=$(df+"evPerPixel")
	nvar degPerPixel=$(df+"degPerPixel"), evPerPixel=$(df+"evPerPixel"), evOffset=$(df+"eVOffset")
	nvar startA=$(df+"startA"), endA=$(df+"endA"), startK=$(df+"startK"), endK=$(df+"endK")
	
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
		wt=ww[p][r][q+i*numA]
		wavestats/q wt
		normF[i]=v_avg
	endfor
	//smooth 20,normF
	//killwaves wt
	
	wv=ww[p][s+eCorr[r]/evPerPixel][q+r*numA] / normF[r]
	
	variable thR=numAD*degPerPixel
	setscale/i x -thR/2, thR/2,"theta, deg",wv
	setscale/i y startA, endA,"beta, deg",wv
	setscale/i z startK,endK,"nom_k, 1/Å", wv
	setscale/p t eVOffset,eVPerPixel,"BE, eV", wv
	
	return df
end

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
	nvar numA=$(df+"numA"),eVPerPixel=$(df+"evPerPixel")
	CurveFit poly 4, pc_x /X=pc_y
	pcf_x=k0+k1*pcf_y + k2*(pcf_y^2) + k3*(pcf_y^3)
	eCorr=pcf_x
	wv=w[p][s+eCorr[r]/evPerPixel][q+r*numA]/normF[r]
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
	if(cMode==1)	//energy
		//extract 3d subset of data
		make/o/n=(numAD, numA, numK) $(df+"sub3d")	//theta, beta, ktot
		wave sub3d=$(df+"sub3d")
		sub3d=wv[p][q][r](cVal)
		setscale/p x dimoffset(wv,0), dimdelta(wv,0), waveunits(wv,0),sub3d
		setscale/p y dimoffset(wv,1), dimdelta(wv,1), waveunits(wv,1),sub3d
		variable k0=dimoffset(wv,2), kd=dimdelta(wv,2), kn=dimsize(wv,2), k1=(kn-1)*kd+k0
		k0=.5124*sqrt((k0/.5124)^2+cVal)
		k1=.5124*sqrt((k1/.5124)^2+cVal)
		setscale/i z k0,k1,waveunits(wv,2),sub3d
		
		//make kxyz map at constant e
		make/o/n=(50,100,100) $(wvn+"_e")
		wave wvout=$(wvn+"_e")
		setscale/i x, -.6, .6, "kx", wvout
		setscale/i y, -1, 4, "ky", wvout
		setscale/i z, 4,8,"kz", wvout
		duplicate/o wvout $(df+"theta"), $(df+"beta"), $(df+"ktot")
		wave theta=$(df+"theta"), beta=$(df+"beta"), ktot=$(df+"ktot")
		ktot=sqrt(x^2+y^2+z^2)
		theta=asin(x/ktot)
		beta=asin(y/ktot/cos(theta))
		wvout=interp3d(sub3d, theta*180/pi, beta*180/pi, ktot)
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
		make/o/n=(100,100,50) $(wvn+"_th")
		wave wvout=$(wvn+"_th")
		setscale/i x, -1,4,"ky", wvout
		setscale/p y evOffset, evPerPixel, "BE", wvout
		setscale/i z, 4,8,"kz", wvout
		duplicate/o wvout, $(df+"beta"), $(df+"kk"), $(df+"ktot")
		wave beta=$(df+"beta")
		wave kk=$(df+"kk")	//this is k at the fermi level
		wave ktot=$(df+"ktot")
		kk=sqrt(x^2+z^2)	
		ktot=.5124*sqrt((kk/.5124)^2 - y)
		beta=asin(x/ktot/cos(cval*pi/180))*180/pi
		wvout=interp3d(sub3d,beta, z, ktot)
	endif
	
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
Window PPPlot() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(243,69,799,469) as "PPPlot"
	ModifyGraph cbRGB=(0,32896,32896)
	ShowTools
	ControlBar 100
	Button Correct,pos={57,59},size={75,20},proc=PhotCorrProc,title="Correct..."
	PopupMenu MotorType,pos={145,1},size={76,20},title="Motor    "
	PopupMenu MotorType,mode=0,value= #"\"Beta;Theta;Phi\""
	SetVariable motorStart,pos={145,23},size={75,15},title="start"
	SetVariable motorStart,value= root:PPPlot:startA
	SetVariable fixedMot1,pos={145,78},size={75,15},title="phi",value= K0
	SetVariable degPerPixel,pos={235,24},size={110,15},title="degPerPixel"
	SetVariable degPerPixel,value= root:PPPlot:degPerPixel
	SetVariable eVPerPixel,pos={235,40},size={110,15},title="eVPerPixel"
	SetVariable eVPerPixel,value= root:PPPlot:eVPerPixel
	SetVariable theta,pos={145,61},size={75,15},title="theta",value= K0
	SetVariable motorEnd,pos={145,39},size={75,15},title="end"
	SetVariable motorEnd,value= root:PPPlot:endA
	PopupMenu Constant,pos={388,2},size={122,20},proc=ConstProc,title="Constant..."
	PopupMenu Constant,mode=1,popvalue="Energy",value= #"\"Energy;theta;ky;kz;hv\""
	SetVariable cval,pos={400,25},size={75,15},title=" val",value= root:PPPlot:cval
	PopupMenu SendTo,pos={393,64},size={82,20},proc=SendToProc,title="Send to..."
	PopupMenu SendTo,mode=0,value= #"\"Memory;Image Tool;Slicer;Surface Plot;\""
	PopupMenu Photon,pos={67,1},size={66,20},title="Photon"
	PopupMenu Photon,mode=0,value= #"\"Enter Values Below\""
	SetVariable photonStart,pos={56,23},size={75,15},title="start"
	SetVariable photonStart,value= root:PPPlot:startK
	SetVariable photonEnd,pos={55,41},size={75,15},title="end"
	SetVariable photonEnd,value= root:PPPlot:endK
	PopupMenu Detector,pos={234,1},size={112,20},title="Detector         "
	PopupMenu Detector,mode=0,value= #"\"Enter Values Below\""
	SetVariable eVOffset,pos={235,56},size={110,15},title="eVOffset"
	SetVariable eVOffset,value= root:PPPlot:eVOffset
EndMacro
