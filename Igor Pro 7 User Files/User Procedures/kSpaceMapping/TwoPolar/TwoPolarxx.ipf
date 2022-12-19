#pragma rtGlobals=1		// Use modern global access method.
#include "ColorTables"

function/s new2Polar(wn)
	string wn
	string df=uniquename("TwoPolar",11,0)
	newdatafolder $df
	df=":"+df+":"
	variable/g $(df+"theta0")=0
	variable/g $(df+"beta0")=0
	variable/g $df+"gridkx"=.25
	variable/g $df+"gridky"=.25
	variable/g $df+"gridtheta"=5		//theta spacing for "checkerboard" theta-beta grid
	variable/g $df+"gridbeta"=5
	variable/g $df+"gridphi"=45
	variable/g $df+"gridphitheta"=5	//theta spacing for "bullseye" azimuth grid
	variable/g $(df+"gamma")=1
	string/g $(df+"dfname")=df
	string/g $(df+"wavName")=wn
	variable/g $(df+"whichct")
	variable/g $(df+"kmap")=0
	variable/g $(df+"hv")=100
	variable/g $(df+"recalcAngle") =1	//need to recalculate the angle image
	variable/g $(df+"recalcK") =1		//need to recalc the k image
	variable/g $(df+"degPerPixel")=.031
	variable/g $(df+"PolarGrid")=0	//no grid initially
	variable/g $(df+"AzGrid")=0		//no grid initially
	variable/g $(df+"kGrid")=0		//no grid initially
	return df
end

//gets wave information from topmost image
macro TwoPolar(w)
	string w
	prompt w,"wave to use",popup wavelist("*",";","win:")
	string df=new2Polar(w)
	
	calcAngleData(df)
	
	if(datafolderexists("TwoPolar")==0)	
		newdatafolder TwoPolar
		variable/g :twopolar:gamma
		string/g :twopolar:dfname
		variable/g :twopolar:whichCT
	endif
	
	TwoPolarWin()
	string dfn=stringfromlist(1,df,":")
	doWindow/c/t $dfn, dfn					//rename window to datafolder without the colons

	//wire up panel items to the particular data folder's variables
	loadct(4)
	duplicate :colors:ct $(df+"ct")
	string ad=df+"angData"
	wavestats/q $ad
	setscale/i x v_min, v_max, "", $(df+"ct")
	$(df+"whichct")=4
	SetVariable setgamma value= $(df+"gamma")
	SetVariable hv value= $(df+"hv")
	CheckBox kmap value=$(df+"kmap")
	SetVariable theta0 value= $(df+"theta0")
	SetVariable beta0 value= $(df+"beta0")
	Checkbox PolarGrid value=$(dF+"PolarGrid")
	Checkbox kgrid value=$(df+"kgrid")
	Checkbox azgrid value=$(df+"azgrid")
	
	//post data to window
	string d=df+"data"
	duplicate/o $ad $d			
	appendimage $d
	modifyimage data cindex=$(df+"ct")
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
	if (numPixelsUse>dimsize(w,0))
		numPixelsUse=dimsize(w,0)
	endif
	variable startpixel=(dimsize(w,0)-numPixelsUse)/2
	if (startpixel<0)
		startpixel=0
	endif
	make/o/n=(abs((numangle+1)*dAngle/degPerPixel), numangle2) $(df+"angData") 	//+1 since  always no overlapping data on extreme slices
	wave ad=$(df+"angData")
	nvar t0=$(df+"theta0")
	nvar b0=$(df+"beta0")
	wavestats/q w1
	SetScale/p x -1*startpixel*degPerPixel-dangle/2+v_max-t0,degPerPixel,w1n, ad
	wavestats/q w2
	Setscale/i y v_min-b0, v_max-b0, w2n, ad
	print df+wavname+"_xscaled"
	duplicate/o w $(df+"xscaled")
	wave xs=$(df+"xscaled")
	Setscale/p x -0.5*numPixelsUse*degPerPixel,degPerPixel,"" xs	//like raw data wave, with x scaled to angle units
	//print numAngle, numAngle2, dangle, numPixelsUse, StartPixel,degPerPixel
	
	variable i,st,en
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
		ad[st,en][*]=w[p-st+(i!=0)*startpixel][q+i*numangle2]
	endfor
	nvar ra=$(df+"recalcAngle")
	ra=0
	nvar rk=$(df+"recalcK")
	rk=1
end

function angle2k(df)
	string df
	print "Calculating k..."
	wave w =$(df+"angData")
	nvar hv=$(df+"hv")
	variable a0=dimoffset(w,0), da=dimdelta(w,0),na=dimsize(w,0),a1=a0+da*na
	variable b0=dimoffset(w,1), db=dimdelta(w,1),nb=dimsize(w,1),b1=b0+db*nb
	print a0,b0
	variable k=0.5124*sqrt(hv)
	variable kxmin=k*sin(a0*pi/180), kxmax=k*sin(a1*pi/180)
	variable kymin=k*sin(b0*pi/180), kymax=k*sin(b1*pi/180)
	string kws=(df+"kdata"), bs=(df+"beta"),ts=(df+"theta")
	duplicate/o w $kws
	wave kw=$kws
	setscale/i x kxmin, kxmax, "kx", kw
	setscale/i y kymin, kymax, "ky", kw
	duplicate/o kw,$bs,$ts
	wave ad=$(df+"angdata"), beta=$bs, theta=$ts
	theta=asin(x/k)*180/pi
	beta=asin(y/k/cos(asin(x/k)))*180/pi
	wavestats/q ad
	kw=ad(theta)(beta)*(1-(beta<b0))*(1-(beta>b1))	//main interpolation
	nvar rk=$(df+"recalcK")
	rk=0
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

//================= W I N D O W    R O U T I N E S	

//must make sure to have "TwoPolar" and not e.g. "TwoPolar1" etc
Window TwoPolarWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(68,92,731,864) as "TwoPolar"
	ModifyGraph cbRGB=(65535,32768,32768)
	ShowInfo
	ShowTools
	ControlBar 75
	SetVariable setGamma,pos={10,52},size={100,15},proc=setGamma,title="gamma"
	SetVariable setGamma,limits={0.001,10,0.1},value= root:TwoPolar:gamma
	Button killTwoPolar,pos={481,52},size={100,20},proc=killWindow,title="killTwoPolar"
	Button loadCT,pos={117,50},size={50,20},proc=floadCT,title="loadCT"
	CheckBox kmap,pos={149,6},size={51,14},proc=Checkboxkmap,title="kmap?",value= 0
	SetVariable hv,pos={210,6},size={75,15},proc=Sethv,title="hv"
	SetVariable hv,value= root:TwoPolar:hv
	SetVariable theta0,pos={19,4},size={100,15},proc=SetZeroAngles,title="theta0"
	SetVariable theta0,value= root:TwoPolar:theta0
	SetVariable beta0,pos={19,21},size={100,15},proc=SetZeroAngles,title="beta0"
	SetVariable beta0,value= root:TwoPolar:beta0
	CheckBox PolarGrid,pos={317,8},size={78,14},proc=CheckBoxPAGrid,title="Polar Grid..."
	CheckBox PolarGrid,value= 0
	CheckBox kGrid,pos={317,27},size={61,14},proc=CheckBoxkGrid,title="k-Grid..."
	CheckBox kGrid,value= 0
	CheckBox AzGrid,pos={317,46},size={91,14},proc=CheckBozAzGrid,title="Azimuth Grid..."
	CheckBox AzGrid,value= 0
EndMacro


Function SetGamma(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	wave ct=root:colors:ct

	string dfname=":"+winlist("*","","win:")+":"	//get data folder from window title
	wave lct=$(dfname+"ct")
	nvar wct=$(dfname+"whichct")
	execute "loadct(" + num2str(wct) + ")"
	execute "ct_gamma(" + num2str(varNum)+")"	//get original color table
	lct=ct
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
end

//when theta0 and beta0 are altered
Function SetZeroAngles(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string dfname=":"+winlist("*","","win:")+":"	//get data folder from window title
	nvar kmap=$(dfname+"kmap")
	wave ad=$(dfname+"angData")
	wave d=$(dfname+"data")
	wave kd=$(dfname+"kdata")
	calcAngleData(dfname)
	print kmap
	if (kmap)
		angle2k(dfname)
		duplicate/o kd d	
	else
		duplicate/o ad d
	endif
End

//when hv is selected
Function Sethv(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string dfname=":"+winlist("*","","win:")+":"	//get data folder from window title
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
	fixgrid(dfname)
End

Function CheckBoxPAGrid(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string dfname=":"+winlist("*","","win:")+":"	//get data folder from window title
	if(checked)
		execute "MakePolarGrid(\""+dfname+"\",,)"
	else
		string wlist=tracenamelist("",";",1)
		print wlist
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

macro MakePolarGrid(df,dt,db)
	string df
	variable dt=5,db=5
	prompt dt,"Theta grid spacing [deg]"
	prompt db,"Beta grid spacing [deg]"
	pauseupdate
	$(df+"gridtheta")=dt
	$(df+"gridbeta")=db
	variable t0=dimoffset($df+"angdata",0), td=dimdelta($df+"angdata",0), ts=dimsize($df+"angdata",0), ts1=ts+1
	variable thetarange=td*ts
	variable b0=dimoffset($df+"angdata",1), bd=dimdelta($df+"angdata",1), bs=dimsize($df+"angdata",1), bs1=bs+1
	variable betarange=bd*bs

	variable ntheta=round(thetarange/dt)+1
	string tgx=(df+"tgridx")
	string tgy=(df+"tgridy")
	make/o/n=(ntheta*bs1) $tgx,$tgy
	iterate(ntheta)
		$tgx[i*bs1,(i+1)*bs1-1]=(i-1)*dt
		$tgy[i*bs1,(i+1)*bs1-1]=b0+(p-bs1*i)*bd
		$tgy[(i+1)*bs1-1]=nan
	loop

	variable nbeta=round(betarange/db)+1
	string bgx=(df+"bgridx")
	string bgy=(df+"bgridy")
	make/o/n=(ntheta*ts1) $bgx,$bgy
	iterate(nbeta)
		$bgy[i*ts1,(i+1)*ts1-1]=(i-1)*db
		$bgx[i*ts1,(i+1)*ts1-1]=t0+(p-ts1*i)*td
		$bgx[(i+1)*ts1-1]=nan
	loop
	
	variable kmap=$(df+"kmap")
	if (kmap)
		AngGrid2k(df)
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

macro MakekGrid(df,dkx,dky)
	string df
	variable dkx=.25,dky=.25
	prompt dkx,"kx grid spacing [1/]"
	prompt dky,"ky grid spacing [1/]"
	pauseupdate
	$(df+"gridkx")=dkx
	$(df+"gridky")=dky
	variable kx0=dimoffset($df+"kdata",0), kxd=dimdelta($df+"kdata",0), kxs=dimsize($df+"kdata",0), kxs1=kxs+1
	variable kxrange=kxd*kxs
	variable ky0=dimoffset($df+"kdata",1), kyd=dimdelta($df+"kdata",1), kys=dimsize($df+"kdata",1), kys1=kys+1
	variable kyrange=kyd*kys

	variable nkx=round(kxrange/dkx)+1
	string kxgx=(df+"kxgridx")
	string kxgy=(df+"kxgridy")
	make/o/n=(nkx*kys1) $kxgx,$kxgy
	iterate(nkx)
		$kxgx[i*kys1,(i+1)*kys1-1]=(i-1)*dkx
		$kxgy[i*kys1,(i+1)*kys1-1]=ky0+(p-kys1*i)*kyd
		$kxgy[(i+1)*kys1-1]=nan
	loop

	variable nky=round(kyrange/dky)+1
	string kygx=(df+"kygridx")
	string kygy=(df+"kygridy")
	make/o/n=(nkx*kxs1) $kygx,$kygy
	iterate(nky)
		$kygy[i*kxs1,(i+1)*kxs1-1]=(i-2)*dky
		$kygx[i*kxs1,(i+1)*kxs1-1]=kx0+(p-kxs1*i)*kxd
		$kygx[(i+1)*kxs1-1]=nan
	loop
	
	variable kmap=$(df+"kmap")
	if (!kmap)
		kGrid2Ang(df)
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

macro MakeAzGrid(df,daz,dth)
	string df
	variable daz=45,dth=5
	prompt daz,"az grid spacing [deg]"
	prompt dth,"th grid spacing [deg]"
	pauseupdate
	$(df+"gridphi")=daz
	$(df+"gridphitheta")=dth
	variable kx0=dimoffset($df+"kdata",0), kxd=dimdelta($df+"kdata",0), kxs=dimsize($df+"kdata",0), kxs1=kxs+1
	variable kxrange=kxd*kxs
	variable ky0=dimoffset($df+"kdata",1), kyd=dimdelta($df+"kdata",1), kys=dimsize($df+"kdata",1), kys1=kys+1
	variable kyrange=kyd*kys

	variable nkth=round(asin(max(max(abs(kx0),abs(ky0)),   max(abs(kx0+kxrange),abs(ky0+kyrange)))/k)/dth)+1
	variable k=0.5124*sqrt($(df+"hv"))
	string azthgx=(df+"azthgridx")
	string azthgy=(df+"azthgridy")
	
	//stopped programming here
	make/o/n=(nkx*101) $kygx,$kygy
	iterate(nky)
		$kygy[i*kxs1,(i+1)*kxs1-1]=(i-2)*dky
		$kygx[i*kxs1,(i+1)*kxs1-1]=kx0+(p-kxs1*i)*kxd
		$kygx[(i+1)*kxs1-1]=nan
	loop

	variable nkphi=round(360/daz)
	string azgx=(df+"azgridx")
	string azgy=(df+"azgridy")
	make/o/n=(nkx*101) $azgx,$azgy
	iterate(nkphi)
		$azgx[i*101,(i+1)*101-1]=cos(2*pi*p/101)
		$azgy[i*101,(i+1)*101-1]=sin(2*pi*p/101)
		$azgy[(i+1)*101-1]=nan
	loop
	

	
	
	variable kmap=$(df+"kmap")
	if (!kmap)
		kGrid2Ang(df)
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


function AngGrid2k(df)
	string df
	wave tgx=$(df+"tgridx")
	wave tgy=$(df+"tgridy")
	wave bgx=$(df+"bgridx")
	wave bgy=$(df+"bgridy")
	string txs=df+"tempx"	
	string tys=df+"tempy"
	nvar hv=$df+"hv"
	duplicate/o tgx $txs
	wave tx=$txs
	duplicate/o tgy $tys
	wave ty=$tys
	variable k=0.5124*sqrt(hv)
	tx=k*sin(pi/180*tgx)
	ty=k*sin(pi/180*tgy)*cos(pi/180*tgx)
	tgx=tx
	tgy=ty
	duplicate/o bgx $txs
	duplicate/o bgy $tys
	tx=k*sin(pi/180*bgx)
	ty=k*sin(pi/180*bgy)*cos(pi/180*bgx)
	bgx=tx
	bgy=ty

end


function kGrid2Ang(df)
	string df
	wave kxgx=$(df+"kxgridx")
	wave kxgy=$(df+"kxgridy")
	wave kygx=$(df+"kygridx")
	wave kygy=$(df+"kygridy")
	string txs=df+"tempx"	
	string tys=df+"tempy"
	nvar hv=$df+"hv"
	duplicate/o kxgx $txs
	wave tx=$txs
	duplicate/o kxgy $tys
	wave ty=$tys
	variable k=0.5124*sqrt(hv)
	tx=asin(kxgx/k)*180/pi  				 		//k*sin(pi/180*tgx)
	ty=asin(kxgy/k/cos(asin(kxgx/k)))*180/pi	//k*sin(pi/180*tgy)*cos(pi/180*tgx)
	kxgx=tx
	kxgy=ty
	duplicate/o kygx $txs
	duplicate/o kygy $tys
	tx=asin(kygx/k)*180/pi 						//k*sin(pi/180*bgx)
	ty=asin(kygy/k/cos(asin(kygx/k)))*180/pi	//k*sin(pi/180*bgy)*cos(pi/180*bgx)
	kygx=tx
	kygy=ty
end


Function CheckBoxkGrid(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string dfname=":"+winlist("*","","win:")+":"	//get data folder from window title
	if(checked)
		execute "MakekGrid(\""+dfname+"\",,)"
	else
		string wlist=tracenamelist("",";",1)
		print wlist
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
	string dfname=":"+winlist("*","","win:")+":"	//get data folder from window title
	if(checked)
		execute "MakeAzGrid(\""+dfname+"\",,)"
	else
		string wlist=tracenamelist("",";",1)
		print wlist
		if (strsearch(wlist,"azgridy",0)>=0)
			removefromgraph azgridy
		endif
		if(strsearch(wlist,"azgridy",0)>=0)
			removefromgraph azgridy
		endif
	endif
	nvar ag=$(dfname+"AzGrid")
	ag=checked

End