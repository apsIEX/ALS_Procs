#pragma rtGlobals=1		// Use modern global access method.
#include "ColorTables" 

menu "kSpace"
	"TwoPolar"
end

function/s new2Polar(wn)
	string wn
	string df=uniquename("TwoPolar",11,0)
	newdatafolder $df
	df=":"+df+":"
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
	variable/g $(df+"isNorm")=0
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
	variable/g $(df+"RescaleAfterRezero")=0
	variable /g $(df+"kmapSampling")=1
	
	return df
end

//gets wave information from topmost image
proc TwoPolar(w)
	string w
	prompt w,"wave to use",popup wavelist("*",";","win:")
	string df=new2Polar(w)
	silent 1;pauseupdate
	calcAngleData(df)
	
	if(datafolderexists("TwoPolar")==0)	
		newdatafolder TwoPolar
		variable/g :twopolar:gamma
		string/g :twopolar:dfname
		variable/g :twopolar:whichCT
	endif
	
	TwoPolarWin()
	string dfn=stringfromlist(1,df,":")
	doWindow/c/t  $dfn, dfn					//rename window to datafolder without the colons
	setwindow $dfn hook=twoPolarHookFcn, hookevents=3  //mouse movement +clickevents hooks
	
	//wire up panel items to the particular data folder's variables
	$(df+"whichct")=1
	loadct($(df+"whichct"))
	duplicate :colors:ct $(df+"ct")
	setColorScale(df)

	SetVariable setgamma value= $(df+"gamma")
	SetVariable hv value= $(df+"hv")
	CheckBox kmap value=$(df+"kmap")
	SetVariable theta0 value= $(df+"theta0")
	SetVariable beta0 value= $(df+"beta0")
	SetVariable phi0 value= $(df+"phi0")
	Checkbox PolarGrid value=$(dF+"PolarGrid")
	Checkbox kgrid value=$(df+"kgrid")
	Checkbox azgrid value=$(df+"azgrid")
	SetVariable k value= $(df+"vdk")
	SetVariable kx value= $(df+"vdkx")
	SetVariable ky value= $(df+"vdky")
	SetVariable theta value= $(df+"vdtheta")
	SetVariable phi value= $(df+"vdphi")
	SetVariable beta value= $(df+"vdbeta")
	SetVariable degperpixel value=$(df+"degperpixel")
	Checkbox norm value=$(df+"isNorm")

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

end

function setColorScale(df)
	string df
	string ad=df+"angData"
	wavestats/q $ad
	setscale/i x v_min, v_max, "", $(df+"ct")
end

function calcAngleData(df)
	string df
	print "Calculating angle"
	nvar degPerPixel=$(df+"degPerPixel")
	svar wn=$(df+"wavName")
	wave w=$wn
	svar wavName=$(df+"wavName")
	svar indvars=$(wavname+"_indvars")
	string w1n=(wavName+"_"+cleanupname(stringfromlist(0,indvars,","),0))	//first indep variable
	string w2n=(wavName+"_"+cleanupname(stringfromlist(1,indvars,","),0))	//second indep variable
	wave w1=$w1n 
	wave w2=$w2n 
	duplicate/o w1 $(df+"uniqueAngle")
	wave ua=$(df+"uniqueAngle")
	uniqueValues(w1,ua)
	variable dAngle=abs(ua[1]-ua[0])
	variable numangle=numpnts(ua)				//# of coarse angle steps
	variable numangle2=numpnts(w1)/numangle	//#of fine angle steps
	variable numpixelsUse=abs(dAngle/degPerPixel)  //# nonoverlapping pixels
	variable under
	if (numPixelsUse>dimsize(w,0))
		under=1						//angle scan coarser than amount of angle data taken
		numPixelsUse=dimsize(w,0)
	else
		under=0
	endif
	variable startpixel=(dimsize(w,0)-numPixelsUse)/2
	if (startpixel<0)
		startpixel=0
	endif
	if(under)
		make/o/n=(abs((numangle-1)*dAngle/degPerPixel+numPixelsUse), numangle2) $(df+"angData0")	//don't have extra black on lhs or rhs
	else 
		make/o/n=(numangle * numPixelsuse+2*startpixel, numangle2) $(df+"angData0")  //don't truncate data on lhs or rhs 
	endif
	wave ad0=$(df+"angData0")
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
	//print under, x0,x1
	SetScale/i x -1*(x0-ua[0])-t0,-1*(x1-ua[0])-t0,w1n, ad0
	wavestats/q w2
	Setscale/i y v_min-b0, v_max-b0, w2n, ad0
	//print df+wavname+"_xscaled"
	duplicate/o w $(df+"xscaled")
	wave xs=$(df+"xscaled")
	Setscale/p x -0.5*numPixelsUse*degPerPixel,degPerPixel,"" xs	//like raw data wave, with x scaled to angle units
	//print numAngle, numAngle2, dangle, numPixelsUse, StartPixel,degPerPixel
	
	
	//normalize data
	nvar norm=$(df+"isNorm")
	duplicate/o w $(df+"dnorm")
	wave dnorm=$(df+"dnorm")
	make/o/n=(dimsize(w,0)) $(df+"normFunc")
	wave nf=$(df+"normFunc")
	variable i,j
	if(norm)
		for (i=0; i<numangle;i+=1)
			nf=0
			for (j=0; j<numangle2; j+=1)
				nf+=w[p][i*numangle2+j]
			endfor
			nf/=numangle2
			dnorm[0,dimsize(w,0)-1][i*numangle2,(i+1)*numangle2-1]=w[p][q]/nf[p]
		endfor
	endif 
	
	//calculate image for phi0=0
	variable st,en
	for (i=0;i<numAngle;i+=1)
		if (i==0) //first strip, use extra on lhs
			st=0
			en=st+(numpixelsUse+startpixel-1)
		else
			st=startpixel+(i*abs(dAngle)/degPerPixel)
			if  (i==numangle-1) //last strip, use extra on rhs
				en=st+(numpixelsUse+startpixel-1)
			else
				en=st+(numpixelsUse-1)
			endif
		endif
		ad0[st,en][*]=dnorm[p-st+(i!=0)*startpixel][q+i*numangle2]
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


function angle2k(df)
	string df
	print "Transforming Angle to k..."
	wave ad0 =$(df+"angData0")
	nvar hv=$(df+"hv")
	variable a0=dimoffset(ad0,0), da=dimdelta(ad0,0),na=dimsize(ad0,0),a1=a0+da*na
	variable b0=dimoffset(ad0,1), db=dimdelta(ad0,1),nb=dimsize(ad0,1),b1=b0+db*nb
	variable k=0.5124*sqrt(hv)
	nvar f0=$(df+"phi0")
	variable kxmin=k*sin(a0*pi/180), kxmax=k*sin(a1*pi/180)	//min, max k before rotation
	variable kymin=k*sin(b0*pi/180), kymax=k*sin(b1*pi/180)
	variable kxminr,kxmaxr,kyminr,kymaxr
	findkRangeAfterRotation(f0*pi/180,kxmin,kxmax,kymin,kymax,kxminr,kxmaxr,kyminr,kymaxr)
	string kws=(df+"kdata"), bs=(df+"beta"),ts=(df+"theta")
	duplicate/o ad0 $kws
	wave kw=$kws
	nvar kms=$(df+"kmapsampling")
	redimension/n=(na*kms,nb*kms) kw
	setscale/i x kxminr, kxmaxr, "kx", kw
	setscale/i y kyminr, kymaxr, "ky", kw
	duplicate/o kw,$bs,$ts
	wave beta=$bs, theta=$ts
	theta=asin(x/k)*180/pi
	beta=asin(y/k/cos(asin(x/k)))*180/pi
	wavestats/q ad0
	kw=ad0(theta)(beta)*(1-(beta<b0))*(1-(beta>b1))	//main interpolation
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
	
function rotateXYwv(ang,x,y,xr,yr)
	variable ang
	wave x,y,xr,yr
	xr=cos(ang)*x+sin(ang)*y
	yr=-sin(ang)*x+cos(ang)*y
end
	
	
//rotates the k-image using phi0 variable
//overwrites kdata array
function rotatek(df)
	string df
	print "Rotating in kspace..."
	wave kd=$(df+"kdata")
	duplicate/o kd $(df+"kdtemp")
	duplicate/o kd  $(df+"kxr")
	duplicate/o kd $(df+"kyr")
	wave kdtemp=$(df+"kdtemp"), kxr=$(df+"kxr"), kyr=$(df+"kyr")
	nvar f0=$(df+"phi0")
	variable f00=f0*pi/180
	kxr=cos(f00)*x - sin(f00)*y
	kyr=sin(f00)*x+cos(f00)*y
	kdtemp=kd(kxr)(kyr)
	duplicate/o kdtemp kd
end

//backtransformation from k-image to angles.
//only used for phi-rotated images
function k2angle(df)
	string df
	print "Backtransforming k to angle space..."
	wave kd =$(df+"kData")
	nvar hv=$(df+"hv")
	variable a0=dimoffset(kd,0), da=dimdelta(kd,0),na=dimsize(kd,0),a1=a0+da*na
	variable b0=dimoffset(kd,1), db=dimdelta(kd,1),nb=dimsize(kd,1),b1=b0+db*nb
	variable k=0.5124*sqrt(hv)
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
	ad=kd(kx)(ky)							//main interpolation
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
	return abs(a-b)<0.1
	
end

//convert points [wx,wy] from k to angle
function AngLine2k(df,wx,wy)
	string df
	wave wx,wy
	string txs=df+"tempx"	
	string tys=df+"tempy"
	nvar hv=$df+"hv"
	duplicate/o wx $txs
	wave tx=$txs
	duplicate/o wy $tys
	wave ty=$tys
	variable k=0.5124*sqrt(hv)
	tx=k*sin(pi/180*wx)
	ty=k*sin(pi/180*wy)*cos(pi/180*wx)
	wx=tx
	wy=ty
end

//convert points [wx,wy] from k to angle
function kLine2Ang(df,wx,wy)
	string df
	wave wx,wy
	string txs=df+"tempx"	
	string tys=df+"tempy"
	nvar hv=$df+"hv"
	duplicate/o wx $txs
	wave tx=$txs
	duplicate/o wy $tys
	wave ty=$tys
	variable k=0.5124*sqrt(hv)
	tx=asin(wx/k)*180/pi  				 		
	ty=asin(wy/k/cos(asin(wx/k)))*180/pi	
	wx=tx
	wy=ty
end

function k2Ang(df,kx,ky,theta,beta,phi)
	string df
	variable kx,ky
	variable &theta, &beta,&phi
	nvar hv=$df+"hv"
	variable k=0.5124*sqrt(hv)
	theta=asin(kx/k)*180/pi
	beta=asin(ky/k/cos(asin(kx/k)))*180/pi
	phi=atan2(ky,kx)*180/pi
	return 0
end

function ang2k(df,theta,beta,kx,ky)
	string df
	variable &kx,&ky
	variable theta, beta
	nvar hv=$df+"hv"
	variable k=0.5124*sqrt(hv)
	kx=k*sin(pi/180*theta)
	ky=k*sin(pi/180*beta)*cos(pi/180*theta)
	return 0
end


function fixrange(dfname)
	string dfname
	wave d=$(dfname+"data")
	string dfn=stringfromlist(1,dfname,":")

	dowindow/f $dfn
	variable dx0=dimoffset(d,0), dx1=dimoffset(d,0)+dimdelta(d,0)*dimsize(d,0)
	variable dy0=dimoffset(d,1), dy1=dimoffset(d,1)+dimdelta(d,1)*dimsize(d,1)
	setaxis bottom, dx0,dx1
	setaxis left,dy0,dy1
end

//================= G R A P H    C O N T R O L    R O U T I N E S	

//must make sure to have "TwoPolar" and not e.g. "TwoPolar1" etc
Window TwoPolarWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(106,53,644,728) as "TwoPolar"
	ModifyGraph cbRGB=(65535,32768,32768)
	ShowInfo
	ShowTools
	ControlBar 90
	SetVariable setGamma,pos={163,72},size={50,14},proc=SetGamma,title="g"
	SetVariable setGamma,font="Symbol"
	SetVariable setGamma,limits={0.001,10,0.1},value= root:TwoPolar:gamma
	Button killTwoPolar,pos={378,69},size={100,20},proc=killWindow,title="killTwoPolar"
	Button loadCT,pos={73,69},size={50,20},proc=floadCT,title="loadCT"
	CheckBox kmap,pos={146,14},size={51,14},proc=Checkboxkmap,title="kmap?",value= 0
	SetVariable hv,pos={207,13},size={75,15},proc=Sethv,title="hv"
	SetVariable hv,value= root:TwoPolar:hv
	SetVariable theta0,pos={5,17},size={100,15},proc=SetZeroAngles,title="theta0"
	SetVariable theta0,limits={-Inf,Inf,0.1},value= root:TwoPolar:theta0,limits={-Inf,Inf,.1}
	SetVariable beta0,pos={5,34},size={100,15},proc=SetZeroAngles,title="beta0"
	SetVariable beta0,limits={-Inf,Inf,0.1},value= root:TwoPolar:beta0,limits={-Inf,Inf,.1}
	CheckBox PolarGrid,pos={146,28},size={78,14},proc=CheckBoxPAGrid,title="Polar Grid..."
	CheckBox PolarGrid,value= 0
	CheckBox kGrid,pos={146,42},size={61,14},proc=CheckBoxkGrid,title="k-Grid..."
	CheckBox kGrid,value= 0
	CheckBox AzGrid,pos={146,56},size={91,14},proc=CheckBozAzGrid,title="Azimuth Grid..."
	CheckBox AzGrid,value= 0
	Button fixRange,pos={303,69},size={75,20},proc=fFixRange,title="fixRange"
	SetVariable theta,pos={299,9},size={70,15},title="q",font="Symbol",fSize=12
	SetVariable theta,value= root:TwoPolar:vdtheta
	SetVariable phi,pos={299,43},size={70,15},title="f",font="Symbol",fSize=12
	SetVariable phi,value= root:TwoPolar:vdphi
	SetVariable beta,pos={298,26},size={70,15},title="b",font="Symbol",fSize=12
	SetVariable beta,value= root:TwoPolar:vdbeta
	SetVariable k,pos={378,9},size={70,15},title="k",value= root:TwoPolar:vdk
	SetVariable kx,pos={378,26},size={70,15},title="kx",value= root:TwoPolar:vdkx
	SetVariable ky,pos={378,43},size={70,15},title="ky",value= root:TwoPolar:vdky
	SetVariable DegPerPixel,pos={5,0},size={100,15},proc=DegPixProc,title="Deg/Pix"
	SetVariable DegPerPixel,limits={0.001,0.25,0.002},value= root:TwoPolar:degperpixel
	CheckBox norm,pos={146,0},size={51,14},proc=CheckBoxNorm,title="norm?",value= 0
	SetVariable phi0,pos={5,51},size={100,15},proc=SetZeroAngles,title="phi0"
	SetVariable phi0,limits={-Inf,Inf,0.2},value= root:TwoPolar:phi0,limits={-Inf,Inf,.1}
	Button invCT,pos={122,69},size={40,20},proc=InvCTProc,title="invCT"
	Button Export,pos={235,69},size={50,20},proc=ExportProc,title="Export"
	Button Prefs,pos={6,69},size={50,20},proc=PrefsProc,title="Prefs"
	SetWindow kwTopWin,hook=twoPolarHookFcn,hookevents=3
	//SetAxis/A/R bottom

EndMacro

function twoPolarHookFcn(s)
	string s
	string dfn=winlist("*","","win:")
	string dfname=":"+dfn+":"	//get data folder from window title
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
	//convert mx and my to axis units
	variable axmin, axmax, aymin, aymax,ax,ay
	GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	ay=axisvalfrompixel(dfn,"left",my)
	ax=axisvalfrompixel(dfn,"bottom",mx)	
	//print ax,ay,kmap,dfname
	
	variable upMod
	if (cmpstr(igorinfo(2),"Macintosh")==0)
		upMod=4	//option click-up on Mac
	else
		upMod=8	//ctrl-click-up on Windows
	endif
	variable keymod=numberbykey("modifiers",s)==upMod
	variable mup=cmpstr(stringbykey("event",s),"mouseup")==0, axk,ayk,dummy
	if (keymod&mup)
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
		vdphi=atan2(ky,kx)*180/pi
		
	endif
	return 0
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

Function killWindow(ctrlName) : ButtonControl
	String ctrlName
	string dfname=winlist("*","","win:")	//get data folder from window title
	dowindow/k $dfname
	setdatafolder root:
	killdatafolder $dfname
End

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
	string dfname=":"+winlist("*","","win:")+":"	//get data folder from window title
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
	nvar pg=$(dfname+"polarGrid")
	pg=checked
End

proc MakePolarGrid(df,dt,db)
	string df
	variable dt=$(getdf()+"gridtheta"),db=$(getdf()+"gridbeta")
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
	string wlist=tracenamelist("",";",1)
	if (strsearch(wlist,"tgridy",0)<0)
		append $tgy vs $tgx
		ModifyGraph lstyle(tgridy)=3
	endif
	if (strsearch(wlist,"bgridy",0)<0)
		append $bgy vs $bgx
		ModifyGraph lstyle(bgridy)=3
	endif
end

proc MakekGrid(df,dkx,dky)
	string df
	variable dkx=$(getdf()+"gridkx"),dky=$(getdf()+"gridky")
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
	string wlist=tracenamelist("",";",1)
	if (strsearch(wlist,"kxgridy",0)<0)
		append $kxgy vs $kxgx
		ModifyGraph lstyle(kxgridy)=3
		ModifyGraph rgb(kxgridy)=(65535,32768,32768)
	endif
	if (strsearch(wlist,"kygridy",0)<0)
		append $kygy vs $kygx
		ModifyGraph lstyle(kygridy)=3
		ModifyGraph rgb(kygridy)=(65535,32768,32768)
	endif
end

proc MakeAzGrid(df,az0,daz,dth)
	string df
	variable az0=$(getdf()+"gridphi0"),daz=$(getdf()+"gridphi"),dth=$(getdf()+"gridphitheta")
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

	variable k=0.5124*sqrt($(df+"hv"))

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
	string wlist=tracenamelist("",";",1)
	if (strsearch(wlist,"azgridy",0)<0)
		append $azgy vs $azgx
		ModifyGraph lstyle(azgridy)=3
		ModifyGraph rgb(azgridy)=(65535,65535,0)
	endif
	if (strsearch(wlist,"azthgridy",0)<0)
		append $azthgy vs $azthgx
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

Function CheckBoxNorm(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string df=getdf()
	nvar in=$(df+"isNorm")
	in=checked
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
	fixrange(df)
	setColorscale(df)
end


Function ExportProc(ctrlName) : ButtonControl
	String ctrlName
	execute "doExport()"
End

proc doExport(name,symmetrize)
	string name=uniquename(getwvnm()+"_",1,0)
	variable symmetrize
	prompt name, "Name of exported image"	
	prompt symmetrize, "Symmetrization option", popup "none;left/right;up/down;both"
	symmetrize-=1
	string df=getdf()
	duplicate/o $(df+"ct") $(name+"ct")
	if (symmetrize)
		dosymmetrize($df+"data", name,symmetrize)
	else
		duplicate/o $(df+"data") $name
	endif
	display; appendimage $name
	modifyimage $name,cindex=$(name+"ct")
	if($(df+"aspect"))
		ModifyGraph width={Plan,1,bottom,left}
	endif
end

//symoption: 1=LR,2=UD, 3=LRUD
function doSymmetrize(d,name,symoption)
	wave d
	string name
	variable symoption
	variable a0=dimoffset(d,0), da=dimdelta(d,0),na=dimsize(d,0),a1=a0+da*na
	variable b0=dimoffset(d,1), db=dimdelta(d,1),nb=dimsize(d,1),b1=b0+db*nb
	variable ap0=(0 - DimOffset(d, 0))/DimDelta(d,0)  //point number for x=0
	variable bp0=(0 - DimOffset(d, 1))/DimDelta(d,1)  //point number for y=0
	print ap0
	switch(symoption)	// numeric switch
		case 1:		// LR
			make/n=(2*(na-ap0)-1,nb)/o $name
			wave w=$name
			w[na-ap0,][0,]				=d[p-(na-ap0)+ap0][q]
			w[0,(na-ap0)-1][0,]		=d[na-p][q]
			setScale/p x -a1,da,"",w
			setScale/p y b0,db,"",w
			break						
		case 2:		//UD
			make/n=(na,2*(nb-bp0)-1)/o $name
			wave w=$name
			w[0,][(nb-bp0),]			=d[p][q-(nb-bp0)+bp0]
			w[0,][0,(nb-bp0)-1]		=d[p][nb-q]
			setscale/p x 0,da,"",w
			setscale/p y -b1,db,"",w
			break
		case 3:		//LRUD
			make/n=(2*(na-ap0)-1,2*(nb-bp0)-1)/o $name
			wave w=$name
			w[na-ap0,][nb-bp0,]					=d[p-(na-ap0)+ap0][q-(nb-bp0)+bp0]
			w[0,(na-ap0)-1][nb-bp0,]			=d[na-p][q-(nb-bp0)+bp0]
			w[na-ap0,][0,(nb-bp0)-1]			=d[p-(na-ap0)+ap0][nb-q]
			w[0,(na-ap0)-1][0,(nb-bp0)-1]		=d[na-p][nb-q]
			setScale/p x -a1,da,"",w
			setscale/p y -b1,db,"",w
			break
		default:							
			duplicate/o d $name
	endswitch
end

Function PrefsProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	execute "doTPPrefs(,,)"
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