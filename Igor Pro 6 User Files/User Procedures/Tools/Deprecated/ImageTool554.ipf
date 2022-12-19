#pragma rtGlobals=1		// Use modern global access method.
#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName= Imagetool5
#pragma version = 5.53
#include "AutoScaleInRange"

static constant MAJOR_VERSION = 5.53
static constant MINOR_VERSION = 0

//5.53 fixed slice from cursor selection added stack functionality
//5.54 gamma slider ER


menu "2D"
	"New Image Tool 5",NewImageTool5("")
end


function makeData()
	make/o/n=(30,35,40,45) data 	//[theta][energy][beta][k]
	wave data=data
	setscale/i x -.75,2.5,"kx",data
	setscale/i y -1.8,0.2,"E",data
	setscale/i z -.5,1,"ky",data
	setscale/i t -4.3,7.4,"kz",data
	data = 1/(.1+(1-(x^2-z^2-t^2)/y)^2)
//	data=1/((y-(20+10*z)*((x-.05)^2))^2+(t/20)^2)
end

function newImageTool5(w)
	string w
	silent 1; pauseupdate

	if (strlen(w)==0)
		string wn
		prompt wn, "New array", popup, "; -- 4D --;"+WaveList("!*_CT",";","DIMS:4")+"; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")+"; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
		DoPrompt "Select 2D Image (or 3D volume)" wn
		if (V_flag==1)
			abort		//cancelled
		endif
		w=wn
	endif
	if(strsearch(w,"root:",0)<0)
		wn=getdatafolder(1)+w
		WAVE wv=$wn
		if(waveexists(wv)==0)
			wn="root+"+w
			WAVE wv=$wn
			if(waveexists(wv)==0)
				return -1
			else
				w=wn
			endif
		else
			w=wn
		endif
	endif
	WAVE wv=$w
	if(waveexists(wv)==0)
		return -1
	endif
	string oldfol=getdatafolder(1)
	setdatafolder "root:"
	string dfn=uniquename("ImageToolV",11,0)
	newdatafolder/o $dfn
	makeVariables(dfn)
	setupV(dfn,w)
	setdatafolder oldfol

end

function makeVariables(dfn)
	string dfn
	string df="root:"+dfn+":"
	variable/g $(df+"version")=MAJOR_VERSION
	variable/g $(df+"x0"),	$(df+"xd"), $(df+"xn"), $(df+"x1")
	variable/g $(df+"y0"), $(df+"yd"), $(df+"yn"), $(df+"y1")	
	variable/g $(df+"z0"),	$(df+"zd"), $(df+"zn"), $(df+"z1")
	variable/g $(df+"t0"), 	$(df+"td"), $(df+"tn"), $(df+"t1")
	variable/g $(df+"AutoScaleHP")=1, $(df+"AutoScaleVP")=1	
	variable/g $(df+"hasHI")=1, $(df+"hasHP")=1					//default: image slices ON, profiles ON
	variable/g $(df+"hasVI")=1,$(df+"hasVP")=1
	variable/g $(df+"hasZP")=1
	variable/g $(df+"hasTP")=1
	variable/g $(df+"dim3index")=2
	variable/g $(df+"dim4index")=3
	variable/g $(df+"transXY")=0	//0=no transpose, 1=transpose
	variable/g $(df+"ZTPMode")=0	//0=separate z,t profiles, 1=z-t image
	variable/g $(df+"xp"), $(df+"yp"), $(df+"zp"),$(df+"tp")		//cursor coords, pixel units
	variable/g $(df+"xc"), 	$(df+"yc"),$(df+"zc"), $(df+"tc")			//cursor coords, real units
	variable/g $(df+"d0")	//value at cursor
	variable/g $(df+"isNew")=1	//used to indicate it's a new tool
	string/g  $(df+"dname")
	variable/g $(df+"gamma")=1
	make/o/n=256/o $(df+"pmap")
	variable/g $(df+"whichCT")=0, $(df+"whichCTh")=0,$(df+"whichCTv")=0,$(df+"whichCTzt")=0
	variable/g $(df+"invertCT")=0
	//Color ROI waves
	
	variable i
	for(i=1;i<7;i+=1)
		make/o/n=0 $(df+"img"+num2str(i)+"rx"), $(df+"img"+num2str(i)+"ry")
		variable /g $(df+"img"+num2str(i)+"mode")=1,$(df+"img"+num2str(i)+"ShowROI")=1
	endfor

	//Color ROI mode: 1=free, 2=ROI ,3=lock
	variable/g $(df+"imgmode")=1, $(df+"imgHmode")=1, $(df+"imgVmode")=1, $(df+"imgZTmode")=1
	string/g $(df+"ROIctrlEditing")
	variable/g $(df+"imgShowROI"), $(df+"imgHShowROI"), $(df+"imgVShowROI"), $(df+"imgZTShowROI")
	make/o/n=3/o $(df+"ROIcolor")={65535,0,65535}





	//ROI variables one pair for each ROI tab 
	variable/g $(df+"ProcessROIMode")=0
	make/o/n=0 $(df+"processROIx"), $(df+"processROIy")
	variable/g $(df+"Norm2DROIMode")=0
	make/o/n=0 $(df+"Norm2DROIx"), $(df+"Norm2DROIy")
	// Norm 
	variable/g $(df+"Norm1_Mode")=0
	variable/g $(df+"Norm1_Axis")=0
	variable/g $(df+"Norm1_Method")=0
	variable/g $(df+"Norm1_X0")=0
	variable/g $(df+"Norm1_X1")=0
	variable/g $(df+"Norm1_p0")=0
	variable/g $(df+"Norm1_p1")=0

	variable/g $(df+"Norm2_Mode")=0
	variable/g $(df+"Norm2_Axis")=0
	variable/g $(df+"Norm2_Method")=0
	variable/g $(df+"Norm2_X0")=0
	variable/g $(df+"Norm2_X1")=0
	variable/g $(df+"Norm2_p0")=0
	variable/g $(df+"Norm2_p1")=0
	//avg
	make /o/n=4 $(df+"bin")
	wave bin=	$(df+"bin")
	bin=1
	variable /g $(df+"bincuropt0")=1,$(df+"bincuropt1")=1,$(df+"bincuropt2")=1,$(df+"bincuropt3")=1
	
	variable/g $(df+"setXavg")=1
	variable/g $(df+"setYavg")=1
	variable/g $(df+"setZavg")=1
	variable/g $(df+"setTavg")=1
	variable/g $(df+"AvgMMode")=1

	//stack
	string sdf = df+"stack"
	if (!DataFolderExists(sdf))
			newdatafolder /o $sdf
	endif
	variable /g $(df+"STACK:dmax")=1
	variable /g $(df+"STACK:dmin")=0
	variable /g $(df+"STACK:xmin")=0
	variable /g $(df+"STACK:xinc")=0
	variable /g $(df+"STACK:ymin")=0
	variable /g $(df+"STACK:yinc")=0
	variable /g $(df+"STACK:shift")=0
	variable /g $(df+"STACK:shift")=0
	variable /g $(df+"STACK:offset")=0
	variable /g $(df+"STACK:pinc")=1
	string /g $(df+"STACK:basen")
	string /g $(df+"STACK:exporti_nam")
end

function/s appendDF(df,s)
	string df,s
	if ((cmpstr(s,"p")==0) +(cmpstr(s,"q")==0) + (cmpstr(s,"r")==0) + (cmpstr(s,"s")==0))
		return s
	else
		return df+s
	endif
end

//function/s wv4d(wv,df,wvout,a,b,c,d)
//	string wv,df,wvout,a,b,c,d
//	a=appendDF(df,a); b=appendDF(df,b); c=appendDF(df,c); d=appendDF(df,d)
//	return df+wvout + ":=" + "root:"+ wv + "[" + a + "][" + b + "][" + c +"][" + d +"]"
//end

//for setting up equations like wvout:=wv[a][b][c][d]
//where a,b,c,d are elements of string array sarr
//scrambled according to indices in iarr
//and if strings are not equal to "p","q", "r", "s" then they are names of variables so prefix df=datafolder to them
function/s wv4dix(wv,df,wvout,sarr,iarr)
	string wv,df,wvout
	wave/t sarr
	wave iarr
	string sout=df+wvout+":="+ "root:"+ wv
	make/t/o/n=4 $(df+"wv4ditemp")
	wave/t swv=$(df+"wv4ditemp")
	swv[iarr[0]]=appendDF(df,sarr[iarr[0]])
	swv[iarr[1]]=appendDF(df,sarr[iarr[1]])
	swv[iarr[2]]=appendDF(df,sarr[iarr[2]])
	swv[iarr[3]]=appendDF(df,sarr[iarr[3]])	
	sout+="["+swv[0]+"]"
	sout+="["+swv[1]+"]"
	sout+="["+swv[2]+"]"
	sout+="["+swv[3]+"]"
	return sout
	//sarr[iarr[0]]=appendDF(df,sarr[iarr[0]])
	//sarr[iarr[1]]=appendDF(df,sarr[iarr[1]])
	//sarr[iarr[2]]=appendDF(df,sarr[iarr[2]])
	//sarr[iarr[3]]=appendDF(df,sarr[iarr[3]])	
	//a=appendDF(df,a); b=appendDF(df,b); c=appendDF(df,c); d=appendDF(df,d)
	//return df+wvout + ":=" + "root:"+ wv + "[" + sarr[iarr[0]] + "][" + sarr[iarr[1]] + "][" + sarr[iarr[2]] +"][" + sarr[iarr[3]] +"]"
end

function setcursor(xc,delta,x0,nx,bin,opt,n)
	variable xc,bin,delta,x0,nx,opt,n
	if  ((bin<2)+(opt==0))
		return xc
	else
		if(bin/2==trunc(bin/2))
			variable xp=trunc((xc-x0)/delta)
		else
			xp=round((xc-x0)/delta)
		endif
		variable bm=trunc((bin)/2)
		variable bp=bin-bm
		if(bp==bm)
			xp+=1
		endif
		switch(n)	
			case 0:
			case 1:
				if (xp<bm)
				return x0-.5*delta
				elseif (xp+bp>=nx)
				return (nx-bin-.5)*delta+x0
				else
				return delta*(xp-bm-.5)+x0	
				endif
				break
			case 3:
			case 4:
				return xc
				break
			case 6: 
			case 7:
				if (xp<bm)
				return delta*(bin-.5)+x0
				elseif (xp+bp>=nx)
				return (nx-.5)*delta+x0
				else
				return delta*(xp+bp-.5)+x0
				endif
				break
		endswitch
	endif
	
end


function/s wv4di(wv,df,wvout,sarr,iarr)
	string wv,df,wvout
	wave/t sarr
	wave iarr
	string sout=df+wvout+":="+  wv
	make/t/o/n=4 $(df+"swv"),$(df+"swv2")
	wave/t swv=$(df+"swv")
	wave/t swv2=$(df+"swv2")
	make/o/n=4 $(df+wvout+"_axis")
	variable /g $(df+wvout+"_trig")
	wave axis=$(df+wvout+"_axis")
	make/o/n=4 $(df+"iwv0"),$(df+"iwv1"),$(df+"iwv2")
	wave iwv0=$(df+"iwv0"), iwv1=$(df+"iwv1"), iwv2=$(df+"iwv2")
	iwv0=iarr; iwv1=p
	sort iwv0,iwv0,iwv1
	swv=appendDF(df,sarr)
	sout+="["+swv[iwv1[0]]+"]"
	sout+="["+swv[iwv1[1]]+"]"
	sout+="["+swv[iwv1[2]]+"]"
	sout+="["+swv[iwv1[3]]+"]"
	variable i,j=2
	
	for(i=0;i<4;i+=1)
		if (cmpstr(swv[iwv1[i]],"p")==0)
			axis[0]=i
		
		elseif (cmpstr(swv[iwv1[i]],"q")==0)
			axis[1]=i
		else
			axis[j]=i
			swv2[j]=swv[iwv1[i]]
			j+=1
		endif
	endfor
	wave wout=$(df+wvout)
	if(dimsize(wout,0)!=0)
		string nn1="Norm1"//+num2str(Norm_num)
		NVAR Mode1= $(df+nn1+"_Mode")
		string nn2="Norm2"//+num2str(Norm_num)
		NVAR Mode2= $(df+nn2+"_Mode")

		if (j==4) 
			//	sout= df+wvout +"=0;"+df+wvout+"_trig:=Extractplane("+df+wvout+","+ wv+","+df+wvout+"_axis,"+swv2[2]+","+swv2[3]+")"
			if(mode1==2)
				if(mode2==2)
					sout= df+wvout +"=0;"+df+wvout+"_trig:=Extractplanebinnorm2("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[2]+","+swv2[3]+","+df+"norm1,"+df+"norm2)"
				else
					sout= df+wvout +"=0;"+df+wvout+"_trig:=Extractplanebinnorm("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[2]+","+swv2[3]+","+df+"norm1)"
				endif
			else
				sout= df+wvout +"=0;"+df+wvout+"_trig:=Extractplanebin("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[2]+","+swv2[3]+")"
			endif
		else
			j=1
			for(i=0;i<4;i+=1)
				if (cmpstr(swv[iwv1[i]],"p")==0)
					axis[0]=i
				else
					axis[j]=i
					swv2[j]=swv[iwv1[i]]
					j+=1
				endif
			endfor
			if(j==4)	
				if(mode1==2)
					sout= df+wvout +"=0;"+df+wvout+"_trig:=ExtractBeambinnorm("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[1]+","+swv2[2]+","+swv2[3]+","+df+"norm1)"
				else
					sout= df+wvout +"=0;"+df+wvout+"_trig:=ExtractBeambin("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[1]+","+swv2[2]+","+swv2[3]+")"
				endif
			endif
		endif
	endif
	
	return df+wvout+"_trig=0;"+sout
	
end


function appImg(options,img)	//appends if not already there
	string options; string img
	string il=imagenamelist("",",")
	if (whichlistitem(img,il,",")<0)
		execute "appendimage" + options + " " +img
	endif
end

//given dim3index, dim4index, transXY, gives the name of the data axis "x", "y", "z", "t" 
//(assuming dim3index does not equal dim4index)
//corresponding to index di as follows:
//0 = "x" axis of main image
//1= "y" axis of main image
//2="z" axis at u.r. graph
//3="t" axis at u.r. lower graph
//
//also first time called creates "dnum" wave whose values correspond to x=0,y=1,z=2,t=3
function/s dimname(df,di)
	string df; 	variable di
	nvar d3i=$(df+"dim3index"), d4i=$(df+"dim4index"),txy=$(df+"transXY")
	variable notnew=exists(df+"dnum")>0
		
	make/n=4/o $(df+"dnum"),  $(df+"dnumOld")
	wave dnum=$(df+"dnum"), dnumOld=$(df+"dnumOld")
	make/o/n=4 q34w
	q34w={0,1,2,3}
	dnum=q34w
	q34w[d3i]=100
	q34w[d4i]=101
	sort q34w,dnum
	killwaves q34w
	//now 1st 2 indices are H and V axes of main image
	variable temp
	if(txy)
		temp=dnum[0]
		dnum[0]=dnum[1]
		dnum[1]=temp		
	endif

	//switch around xp, yp, zp, tp values if necessary
	if(notnew)
		nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc") 
		make/o/n=4 q34w,qi,qii
		q34w={xc,yc,zc,tc}
		qii=p
		variable i
		for(i=0; i<4; i+=1)
			qi[i]=findval(dnum,dnumold[i])
		endfor
		sort qi,qii
		xc=	q34w[qii[0]]; yc= q34w[qii[1]]; zc= q34w[qii[2]]; tc= q34w[qii[3]]
		
		killwaves q34w,qi,qii
	endif
			
	dnumOld=dnum	
	if (dnum[di]==0)
		return "x"
	endif
	if (dnum[di]==1)
		return "y"
	endif
	if (dnum[di]==2)
		return "z"
	endif
	if(dnum[di]==3)
		return "t"
	endif
	return "error"
end

//finds value in wave; returns -1 if not found
function findval(wv,val)
	wave wv; variable val	
	variable i=-1
	do
		i+=1
	while((wv[i]!=val)*(i<=numpnts(wv)))
	if(i>numpnts(wv))
		return -1
	else
		return i
	endif
end


function hasAxis(ax)
	string ax
	variable ans=strlen(axisinfo("",ax))
	return ans>0
end

//removes traces e.g. w+"#1" provided the "which" axis (which="X" or "Y") is ax (case sensitive match)
function removetraceaxis(w,which,ax)
	string w,which,ax
	string tl=tracenamelist("",";",1)
	string s
	variable ii=0,c1,c2
	do
		s=stringfromlist(ii,tl)
		c1=cmpstr(s,w)==0		//e.g. "abc"="abc"
		c2=(cmpstr(s[0,strlen(w)-1],w)==0)*(cmpstr(s[strlen(w)],"#")==0)	//e.g. "abc#2"="abc"
		if (cmpstr(s,w)>=0)
			//eg "w#1"
			if(cmpstr(stringbykey(which+"AXIS",traceinfo("",s,0)),ax)==0)
				removefromgraph/z $s
			endif
		endif
		ii+=1
	while (strlen(s)>0)
end

//modifies rgb of trace e.g. w"#1" provided the "which" axis (which ="X" or "Y") is ax (case sensitive match)
function modifyRGBaxis(w,which,ax,r,g,b)
	string w,which,ax
	variable r,g,b
		string tl=tracenamelist("",";",1)
	string s,sk
	variable ii=0,c1,c2
	do
		s=stringfromlist(ii,tl)
		c1=cmpstr(s,w)==0		//e.g. "abc"="abc"
		c2=(cmpstr(s[0,strlen(w)-1],w)==0)*(cmpstr(s[strlen(w)],"#")==0)	//e.g. "abc#2"="abc"
		if (c1 + c2)
			//eg "w#1"
			sk=stringbykey(which+"AXIS",traceinfo("",s,0))
			if(cmpstr(sk,ax)==0)
				modifygraph rgb($s)=(r,g,b)
			endif
		endif
		ii+=1
	while (strlen(s)>0)
end

Function DrawPolyProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	wave ycontour=$(df+"ycontour")
	wave xcontour=$(df+"xcontour")
	button donepoly,disable=0
	if(exists(df+"ycontour"))
		graphwaveedit ycontour
	else
		graphwavedraw ycontour,xcontour
	endif
End

Function DonePolyProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	graphnormal
	button donepoly,disable=1
	if (exists("ycontour"))
		execute "movewave ycontour, "+df
		execute "movewave xcontour, "+df
	endif
	button extractProfile,disable=0
	button killPoly,disable=0
End

function extractLineProc(ctrlName):ButtonControl
	string ctrlname
	string df=getdf()
	nvar xc=$(df+"xc"), yc=$(df+"yc")
	variable xx=xc,yy=yc,np=200,exporttype=2
	string phirange="0",wvout="wvout",wvu="len"
	prompt wvout,"name of output wave"
	prompt wvu,"units along line"
	prompt exporttype,"What to export vs angle",popup "1-d; 2-d"
	prompt xx,"x-origin of line"
	prompt yy,"y-origin of line"
	prompt np,"number of points along line"
	prompt phirange,"[angle] or [start, end, #] angles"
	doprompt "enter lineout information",wvout,wvu,exporttype,xx,yy,np,phirange
	if(v_flag)
		abort
	endif
	wave iwv=$(df+"iwv1")	//holds which axis is which
	variable xi=iwv[0], yi=iwv[1], zi=iwv[2]
	svar dname=$(df+"dname")
	wave wv=$dname
	variable x0=dimoffset(wv,xi), xd=dimdelta(wv,xi), xn=dimsize(wv,xi), x1=x0+xd*xn
	variable y0=dimoffset(wv,yi), yd=dimdelta(wv,yi), yn=dimsize(wv,yi), y1=y0+yd*yn
	variable z0=dimoffset(wv,zi), zd=dimdelta(wv,zi), zn=dimsize(wv,zi), z1=z0+zd*zn
	string zl=waveunits(wv,zi)
	struct rectcoords rr
	rr.xmax=max(x0,x1); rr.xmin=min(x0,x1); rr.ymax=max(y0,y1); rr.ymin=min(y0,y1)
	//check point is inside the window
	if((xx>=rr.xmin)*(xx<=rr.xmax)*(yy>=rr.ymin)*(yy<=rr.ymax))
	else
		abort "must have origin inside the data range"
	endif
	//parse phirange variables
	variable phistart, phiend, phiN
	phistart=str2num(stringfromlist(0,phirange,","))*pi/180
	if (itemsinlist(phirange,",")==3)
		phiend=str2num(stringfromlist(1,phirange,","))*pi/180
		phiN=str2num(stringfromlist(2,phirange,","))
	else
		phiend=phistart
		phiN=1
	endif
	//calculate end coordinates of line
	variable phi, phiincr=selectnumber(phiN==1,(phiend-phistart)/(phiN-1),inf)
	variable xa,ya,xb,yb
	make/o/n=(200,200) ilt
	setscale x rr.xmin, rr.xmax, ilt
	setscale y rr.ymin,rr.ymax,ilt
	variable xpos,ypos,xneg,yneg,ii=0
	make/o/n=(phiN*3) $(df+"xlines"),$(dF+"ylines")
	wave xlines=$(df+"xlines"), ylines=$(df+"ylines")
	//first pass to clip all of the lines to rectangle
	for(ii=0;ii<(phiN*3);ii+=3)
		phi=selectnumber(phiN==1,phistart+(ii/3)*phiIncr,phiStart)
	//for(phi=phistart;phi<=phiend;phi+=phiIncr)
		xpos=xx+(rr.xmax-rr.xmin)
		ypos=yy+(rr.xmax-rr.xmin)*tan(phi)
		xneg=xx-(rr.xmax-rr.xmin)
		yneg=yy-(rr.xmax-rr.xmin)*tan(phi)
		clipLineRect(xneg,yneg,xpos,ypos,rr)
		xlines[ii]=xneg; xlines[ii+1]=xpos; xlines[ii+2]=nan
		ylines[ii]=yneg; ylines[ii+1]=ypos; ylines[ii+2]=nan
		//ii+=3
	endfor
	//second pass: figure out the maximum lengths on the neg and pos sides
	variable negmax=-inf,negindex=-1,posmax=-inf, posindex=-1, neglen, poslen
	for(ii=0;ii<(phiN*3);ii+=3)
		neglen=sqrt((xx-xlines[ii])^2 + (yy-ylines[ii])^2)
		poslen=sqrt((xx-xlines[ii+1])^2 + (yy-ylines[ii+1])^2)
		if(neglen>negmax)
			negmax=neglen; negindex=ii/3
		endif
		if(poslen>posmax)
			posmax=poslen; posindex=ii/3
		endif
	endfor
	variable totalLen=negmax+posmax
	if(strsearch(tracenamelist("",",",1),"ylines",0)<0)
		appendtograph ylines vs xlines
	endif

	//create output wave
	make/o/n=(np) temp_xx, temp_yy
	switch (exporttype)
		case 1:	//1-d, export lineouts from current displayed image
			make/o/n=2 w_imagelineprofile
			make/o/n=(np,phiN) $wvout
			wave wvo=$wvout
			wave wvl=w_imagelineprofile
			setscale x -negmax,posmax,wvu,wvo
			setscale/p y phiStart*180/pi,phiIncr*180/pi,"azimuth",wvo
			wave img=$(df+"img")
			break
		case 2: //2-d, export images from 3d wave
			make/n=(2,2)/o m_imagelineprofile
			make/o/n=(np,zn,phiN) $wvout
			wave wvo=$wvout
			setscale/p y z0,zd,zl,wvo
			setscale x -negmax,posmax,wvu,wvo
			setscale/p y z0,zd,zl,wvo
			setscale/p z phiStart*180/pi,phiIncr*180/pi,"azimuth",wvo
			//make dummy 3d wave
			make/o/n=(xn,yn,zn) temp_3dwv
			setscale/p x x0,xd,temp_3dwv
			setscale/p y y0,yd,temp_3dwv
			setscale/p z z0,zd,temp_3dwv
			make/o/n=4/t temp_sarr={"p","q","r","s"}
			string ss="temp_3dwv="+dname
			ss+="["+temp_sarr[xi]+"]"
			ss+="["+temp_sarr[yi]+"]"
			ss+="["+temp_sarr[zi]+"]"
			execute  ss
			break
	endswitch

	//pull out lineouts
	for(ii=0;ii<phiN;ii+=1)
		phi=selectnumber(phiN==1,phistart+ii*phiIncr,phiStart)
		temp_xx=xx + (p-(np-1)*negmax/totalLen) * totalLen/(np-1)  * cos(phi)
		temp_yy=yy + (p-(np-1)*negmax/totalLen) * totalLen/(np-1) * sin(phi)
		//print phi*180/pi
		switch(exporttype)
			case 1:
				imagelineprofile/V xwave=temp_xx, ywave=temp_yy, srcwave=img
				wvo[][ii]=wvl[p]
				break
			case 2:
				imagelineprofile/V/p=-2 xwave=temp_xx, ywave=temp_yy, srcwave=temp_3dwv
				wvo[][][ii]=m_imagelineprofile[p][q]
				break
		endswitch
		//ii+=1
	endfor
	
	//cleanup waves and display
	killwaves/z temp_xx temp_yy
	switch (exporttype)
		case 1:
			if(phiN==1)
				redimension/n=(np) wvo
				display wvo
			else
				display; appendimage wvo
			endif
			break
		case 2:
			if(phiN==1)
				redimension/n=(np,zn) wvo
			endif
			execute "newimagetool5(\""+wvout+"\")"
			killwaves/z temp_3dwv
			break
	endswitch
				
end

function killLineProc(ctrlName):ButtonControl
	string ctrlName
	removefromgraph/z ylines
end

//implementation of cohen-sutherland algorithm for line clipping
//see http://www-static.cc.gatech.edu/grads/h/Hao-wei.Hsieh/Haowei.Hsieh/code1.html
function ClipLineRect(x0,y0,x1,y1,rr)
	variable &x0,&y0,&x1,&y1
	struct rectcoords &rr
	struct pointLocStruct ptlocneg
	struct pointLocStruct ptlocpos
	struct pointLocStruct oco	//"outcodeout"
	variable accept=0,done=0, neg
	compoutcode(x0,y0,rr,ptlocneg)
	compoutcode(x1,y1,rr,ptlocpos)
	do
		if (ptinrect(ptlocneg) * ptinrect(ptlocpos))
			//both endpoints in rect, trivial acceptance
			accept=1; done=1
		endif
		if(logicalIntersection(ptlocneg,ptlocpos))
			//both endpoints not in rect, trivial rejection
			done=1
		endif
		//failed both tests, so line is partially in rectangle
		//at least one endpoint is outside the rectangle, pick it
		if(done==0)
			if (!ptinrect(ptlocneg))
				oco=ptlocneg; neg=1
			else 
				oco=ptlocpos; neg=0
			endif
			//now find intersection point using eqns y=y0+(x-x0)*slope, x=x0+(y-y0)/slope
			variable xx,yy
			if(oco.top)
				xx=x0+(x1-x0)*(rr.ymax-y0)/(y1-y0)
				yy=rr.ymax
			endif
			if(oco.bottom)
				xx=x0+(x1-x0)*(rr.ymin-y0)/(y1-y0)
				yy=rr.ymin
			endif
			if(oco.right)
				yy=y0+(y1-y0)*(rr.xmax-x0)/(x1-x0)
				xx=rr.xmax
			endif
			if(oco.left)
				yy=y0+(y1-y0)*(rr.xmin-x0)/(x1-x0)
				xx=rr.xmin
			endif
			//now we move outside point to intersection point to clip and get ready for next poass
			if(neg)
				x0=xx; y0=yy;compOutCode(x0,y0,rr,ptlocneg)
			else
				x1=xx;y1=yy;compoutcode(x1,y1,rr,ptlocpos)
			endif
		endif		
	while(done==0)	
	return accept
end


function compoutcode(x0,y0,rr,ss)
	variable x0,y0
	struct pointLocStruct &ss
	struct rectCoords &rr
	ss.top= y0 > rr.ymax	
	ss.bottom= y0 < rr.ymin
	ss.left= x0 < rr.xmin
	ss.right= x0 > rr.xmax
end

function ptinrect(ss)
	struct pointLocStruct &ss
	return (ss.top==0) * (ss.bottom==0) * (ss.left==0) * (ss.right==0)
end

function logicalIntersection(s0,s1)
	struct pointLocStruct &s0
	struct pointLocStruct &s1
	variable ans=s0.left*s1.left + s0.right*s1.right + s0.top*s1.top + s0.bottom*s1.bottom
	return ans>0
end


structure pointLocStruct
	variable left, top, right, bottom
endstructure

structure rectCoords
	variable xmin, xmax, ymin, ymax
endstructure

Function ExtractPolyProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	execute "doExtractPoly()"	
End

proc doExtractPoly(wvnam,np,dim,indvarnam)
	variable np=100,dim
	string indvarnam=ss(), wvnam="wvout"
	prompt wvnam,"name of new wave"
	prompt np, "number of points along contour"
	prompt dim,"dimension of outgoing data",popup "lineout;image;volume"
	prompt indvarnam,"name of new independent variable"
	string df=getdf()
	//print df
	if(numpnts($(df+"ycontour"))!=2)
		abort "sorry, only 2 points are supported at present"
	endif
	interpolate2/t=1/n=(np)/x=$(df+"xx")/y=$(df+"yy") $(df+"xcontour"), $(df+"ycontour")
	make/n=(np)/o slen	//distance along line
	slen=sqrt(($(df+"xx")-$(df+"xx")[0])^2 + ($(df+"yy")-$(df+"yy")[0])^2)
	//variable ss0=slen[0]
	//slen-=ss0
	if (dim==1)
		make/n=(np)/o $wvnam
		$wvnam=interp2d($(df+"img"),$(df+"xx"),$(df+"yy"))
		display $wvnam
	endif
	if(dim==2)
		make/n=(np)/o t1
		make/n=(np,dimsize($(df+"imgh"),1))/o $wvnam
		setscale/p y dimoffset($(df+"imgh"),1),dimdelta($(df+"imgh"),1),waveunits($(df+"imgh"),1),$wvnam
		iterate(dimsize($(df+"imgh"),1))
			$(df+"zc")=dimoffset($(df+"imgh"),1)+i*dimdelta($(df+"imgh"),1)
			t1=interp2d($(df+"img"),$(df+"xx"),$(df+"yy"))
			$wvnam[][i]=t1[p]
		loop
		setscale/i x slen[0],slen[np-1],indvarnam,$wvnam
		display; appendimage $wvnam
	endif
	if(dim==3)
		string dn=$(df+"dname")
		variable i3=$(df+"dim3index"), i4=$(df+"dim4index"),nq=dimsize($dn,i3),nr=dimsize($dn,i4)
		make/n=(np)/o t1
		make/n=(np,nq,nr)/o $wvnam
		setscale/p y dimoffset($(df+"imgh"),1),dimdelta($(df+"imgh"),1),waveunits($(df+"imgh"),1),$wvnam
		setscale/p z dimoffset($dn,i4),dimdelta($dn,i4),waveunits($dn,i4),$wvnam
		iterate(nr)
			$(df+"tc")=dimoffset($dn,i4)+i*dimdelta($dn,i4)
			iterate(dimsize($(df+"imgh"),1))
				$(df+"zc")=dimoffset($(df+"imgh"),1)+i*dimdelta($(df+"imgh"),1)
				t1=interp2d($(df+"img"),$(df+"xx"),$(df+"yy"))
				$wvnam[][i][j]=t1[p]
			loop
		loop
		setscale/i x slen[0],slen[np-1],indvarnam,$wvnam
		newimagetool5(wvnam)

	endif

end

function/s ss()

	wave wv=$(getdf()+"img"), dnum=$(getdf()+"dnum")
	
	return waveunits(wv,0)+"_"+waveunits(wv,1)

end

Function KillPolyProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	wave ycontour=$(df+"ycontour")
	wave xcontour=$(df+"xcontour")
	
	removefromgraph/z ycontour
	killwaves/z ycontour xcontour
	button extractProfile,disable=2
	button killPoly,disable=2
End

function tabproc(name,tab)	
	string name
	variable tab
	string df=getdf()
	nvar isNew=$(df+"isNew")
	graphnormal
	setvariable setx0,disable=(tab!=0)		//Info
	setvariable setXp,disable=(tab!=0)
	setvariable sety0,disable=(tab!=0)
	setvariable setyp,disable=(tab!=0)
	setvariable setZ0,disable=(tab!=0)
	setvariable setZp,disable=(tab!=0)
	setvariable setT0,disable=(tab!=0)
	setvariable setTp,disable=(tab!=0)
	valdisplay valD0,disable=(tab!=0)
	// clear all ROIs
	ProcessDrawROI(df,"Process",0)

 	popupmenu ProcessROIDraw, disable=(tab!=1)	//process
	Button ProcessROIDone, disable=1
	//Button ProcessAlignImages, disable=(tab!=1)
	Button ProcessROIkill, disable=(tab!=1)
	if((isNew==0)*(tab==1))
		ProcessDrawROI(df,"Process",tab==1)
	endif
	popupmenu ProcessROI,disable=(tab!=1)
	popupmenu Process,disable=(tab!=1)
	
	setvariable setgamma,disable=(tab!=2)	//colors
	slider slidegamma,disable=(tab!=2)	//colors
	
	groupBox Colors,disable=(tab!=2)
	popupmenu selectCT,disable=(tab!=2)
	//checkbox lockcolors,disable=(tab!=2)
	checkbox invertCT,disable=(tab!=2)
	GroupBox groupCOpts,disable=(tab!=2)	
	popupmenu imgopt,disable=(tab!=2)
	popupmenu imgHopt,disable=(tab!=2)
	popupmenu imgVopt,disable=(tab!=2)
	popupmenu imgZTopt,disable=(tab!=2)
	button doneROI,disable=1	//should always be hidden at this point
	popupMenu ROIColor,disable=(tab!=2)
	popupMenu ROIAll,disable=(tab!=2)
	if((isNew==0)*(tab!=1))
		ROIUpdatePolys(df,tab==2)	//hide ROI when not on color tab
	endif
	
	checkbox hasHI,disable=(tab!=3)		//axes
	checkbox hasVI,disable=(tab!=3)
	checkbox hasHP,disable=(tab!=3)
	checkbox hasVP,disable=(tab!=3)
	checkbox ZTPMode,disable=(tab!=3)
	checkbox hasZP,disable=(tab!=3)
	checkbox hasTP,disable=(tab!=3)
	checkbox transXY,disable=(tab!=3)
	popupmenu dim3index,disable=(tab!=3)
	popupmenu dim4index,disable=(tab!=3)
	checkbox AutoScaleHP,disable=(tab!=3)		//axes
	checkbox AutoScaleVP,disable=(tab!=3)
	
	
	popupmenu export,disable=(tab!=4)	//export
	button animate,disable=(tab!=4)

	button drawpoly, disable=(tab!=5)	//lineout
	variable disab
	if (tab==5)
		disab=2*(!exists(df+"ycontour"))
	else
		disab=1
	endif
	button extractProfile,disable=disab
	button extractLine,disable=tab!=5
	button killLine,disable=tab!=5
	button killPoly,disable=disab
	button donepoly,disable=1	//at this point button should always be invisible
	
	Button Bstack,disable=tab!=5
	SetVariable Csetstackoffset,disable=tab!=5

	

	//avg
	groupBox MAvg,disable=(tab!=6)

	
	SetVariable setbin0,disable=(tab!=6),title=binaxistitle(df,0)
	SetVariable setbin1,disable=(tab!=6),title=binaxistitle(df,1)
	SetVariable setbin2,disable=(tab!=6),title=binaxistitle(df,2)
	SetVariable setbin3,disable=(tab!=6),title=binaxistitle(df,3)
	
	checkbox setbincuropt0,disable=(tab!=6)
	checkbox setbincuropt1,disable=(tab!=6)
	checkbox setbincuropt2,disable=(tab!=6)
	checkbox setbincuropt3,disable=(tab!=6)
	
//	 groupBox VAvg,disable=(tab!=6)
//	groupBox HAvg,disable=(tab!=6)
//
//	SetVariable setXavg,disable=(tab!=6)
//	SetVariable setYavg,disable=(tab!=6)
//	
//
//	NVAR AvgZTMode=$(df+"AvgZTMode")
//	NVAR ndim=$(df+"ndim")
//	if (ndim==4)
//		popupmenu AvgZTMenu,value="None;Range;ROI;\M1-;Add ROI;ShowROI;HideROI;Clear ROI"
//	else
	
//		NVAR AvgZTMode=$(df+"AvgZTMode")
//		if(AvgZTMode>2)
//			AvgZTMode=2
//		endif
//		popupmenu AvgZTMenu,mode=AvgZTMode,value="None;Range"

//	endif
//	popupmenu AvgZTROIDraw,disable=(((tab!=6)+(AvgMMode==1))>0)
//	popupmenu AvgZTMenu,disable=(tab!=6)
//	Button AvgZTROIDone,disable=1
//	Button AvgZTROIkill,disable=(((tab!=6)+(AvgMMode==1))>0)
//	SetVariable setZavg,disable=(((tab!=6)+(AvgZTMode!=2))>0)
//	SetVariable setTavg,disable=(((tab!=6)+(AvgZTMode!=2)+(ndim!=4))>0)
	
		// norm
		
	if(isnew)
		svar dname=$(df+"dname")
		wave w=$dname
		string u0="x ["+waveunits(w,0)+"];"
		string u1="y ["+waveunits(w,1)+"];"
		string u2=SelectString(wavedims(w)>2,"", "z ["+waveunits(w,2)+"];")
		string u3=SelectString(wavedims(w)>3,"","t ["+waveunits(w,3)+"];")
		execute "popupmenu  cNorm1_AXIS, value=\"" + u0 +u1+u2+u3+"\""
		execute "popupmenu  cNorm2_AXIS, value=\"" + u0 +u1+u2+u3+"\""
		STRUCT WMPopupAction PU_Struct
		PU_Struct.eventCode=2
		PU_Struct.popnum=1
		PU_Struct.ctrlname="cNorm1_Axis"
		NormAxisMenu(PU_Struct)
		PU_Struct.ctrlname="cNorm2_Axis"
		NormAxisMenu(PU_Struct)
	
	endif
	groupBox MNorm1,disable=(tab!=7)
	
	popupmenu cNorm1_Menu,disable=(tab!=7)
	popupmenu cNorm1_AXIS,disable=(tab!=7)
	
	popupmenu cNorm1_Method,disable=(tab!=7)
	SetVariable cNorm1_x0,disable=(tab!=7)
	SetVariable cNorm1_x1,disable=(tab!=7)
	
	
	groupBox MNorm2,disable=(tab!=7)
	
	popupmenu cNorm2_Menu,disable=(tab!=7)
	popupmenu cNorm2_AXIS,disable=(tab!=7)
	
	popupmenu cNorm2_Method,disable=(tab!=7)
	SetVariable cNorm2_x0,disable=(tab!=7)
	SetVariable cNorm2_x1,disable=(tab!=7)
	
	
//	popupmenu Norm2DROIDraw,disable=(tab!=7)
//	Button Norm2DROIDone,disable=(tab!=7)
//	Button Norm2DROIkill,disable=(tab!=7)

//	if((isNew==0)*(tab==7))
//		ProcessDrawROI(df,"Norm2D",tab==7)
//	endif



end



function setupcontrols(df)
	string df
	button loadbuttonV, title="Load",pos={5,20},size={50,20},proc=LoadNewImgV
	tabcontrol tab0 proc=tabproc,size={600,80},pos={60,0}
	tabcontrol tab0 tablabel(0)="info",tablabel(1)="process",tablabel(2)="colors",tablabel(3)="axes",tablabel(4)="export",tablabel(5)="lineout",tablabel(6)="bin",tablabel(7)="norm"	
	
	//INFO TAB
	variable cstarth=67,vstarth=26 , cstep=74 ,vstep=15

	SetVariable setX0,pos={cstarth,vstarth},size={70,14},title="X"
	SetVariable setX0,help={"Cross hair X-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setX0,limits={-inf,inf,1},value=$(df+"xc")
	setvariable setXP,pos={cstarth,vstarth +vstep},size={70,14},title="XP"
	setvariable setXP,help={"Cross hair X-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	setvariable setXP,limits={0,inf,1},value=$(df+"xp"),disable=2 ,proc=SetPCursor
	SetVariable setY0,pos={cstarth+cstep ,vstarth},size={70,14},title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,limits={-inf,inf,1},value= $(df+"yc")
	SetVariable setYP,pos={cstarth+cstep,vstarth +vstep},size={70,14},title="YP"
	SetVariable setYP,help={"Cross hair Y-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setYP,limits={0,inf,1},value=$(df+"yp"),disable=2 , proc=SetPCursor
	SetVariable setZ0,pos={cstarth+2*cstep,vstarth},size={70,14},title="Z"
	SetVariable setZ0,help={"Cross hair Z-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setZ0,limits={-inf,inf,1},value= $(df+"zc")
	SetVariable setZP,pos={cstarth+2*cstep,vstarth +vstep},size={70,14},title="ZP"
	SetVariable setZP,help={"Cross hair Z-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setZP,limits={0,inf,1},value=$(df+"zp"),disable=2 ,proc=SetPCursor
	SetVariable setT0,pos={cstarth+3*cstep,vstarth},size={70,14},title="T"
	SetVariable setT0,help={"Cross hair T-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setT0,limits={-inf,inf,1},value= $(df+"tc")
	SetVariable setTP,pos={cstarth+3*cstep,vstarth +vstep},size={70,14},title="TP"
	SetVariable setTP,help={"Cross hair T-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setTP,limits={0,inf,1},value=$(df+"tp"),disable=2, proc=SetPCursor
	ValDisplay valD0,pos={cstarth+4*cstep,vstarth},size={61,14},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,limits={0,0,0},barmisc={0,1000}
	execute "ValDisplay valD0,value="+df+"d0"	
	
	//COLORS TAB
	SetVariable setgamma,pos={74,26},size={52,14},title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol"
	SetVariable setgamma,limits={0.01,Inf,0.05},value=$(df+"gamma")
	Slider slidegamma size={70,16},pos={66,50},ticks=0,vert=0,variable=$(df+"gamma");DelayUpdate
	Slider slidegamma limits={0.01,10,0.01}
	//CheckBox lockColors,pos={219,26},size={80,14},proc=ColorLockCheck,title="Lock colors?"
	//CheckBox lockColors,value= 0
	checkbox invertCT,pos={153,45},size={80,14},title="Invert?"
	execute "checkbox invertCT,variable="+df+"invertCT" 
	variable x0=300,y0=17
	wave ROIcolor=$(df+"ROIColor")
	GroupBox groupCOpts title="Individual scale options", pos={x0,y0}, size={325,60}, fcolor=(65535,0,0)
	string imgopstring="\"Free;ROI;Lock;\M1-;Add ROI;Replace ROI;ShowROI;HideROI;Clear ROI;Set Color Table\""
	PopupMenu imgHOpt,pos={x0+9,y0+15},size={80,14},title="horiz"
	PopupMenu imgHOpt,mode=1,proc=ROIColorOption,value="\"Free;ROI;Lock;\M1-;Add ROI;Replace ROI;ShowROI;HideROI;Clear ROI;Set Color Table\""
	PopupMenu imgOpt,pos={x0+9,y0+36},size={80,14},title="main "
	PopupMenu imgOpt,mode=1,proc=ROIColorOption,value="\"Free;ROI;Lock;\M1-;Add ROI;Replace ROI;ShowROI;HideROI;Clear ROI;Set Color Table\""
	PopupMenu imgZTOpt,pos={x0+100,y0+15},size={80,14},title="corner"
	PopupMenu imgZTOpt,mode=1,proc=ROIColorOption,value="\"Free;ROI;Lock;\M1-;Add ROI;Replace ROI;ShowROI;HideROI;Clear ROI;Set Color Table\""
	PopupMenu imgVOpt,pos={x0+100,y0+36},size={80,14},title="vert   "
	PopupMenu imgVOpt,mode=1,proc=ROIColorOption,value="\"Free;ROI;Lock;\M1-;Add ROI;Replace ROI;ShowROI;HideROI;Clear ROI;Set Color Table\""
	button doneROI, title="Done",pos={x0-60,y+34},size={50,32},proc=ROIDoneEditing,disable=1
	PopupMenu ROIColor title="ROI Color", pos={x0+190, y0+15}, size={100,32}
	PopupMenu ROIColor proc=ROIColorProc,value="*COLORPOP*"
	PopupMenu ROIColor popcolor=(ROIColor[0],ROIColor[1],ROIColor[2])
	PopupMenu ROIAll,title="All  ", pos={x0+235,y0+36}, size={120,32},proc=ROIAllColorOpts
	PopupMenu ROIAll,mode=0,value=#"\"Free;ROI;\M1-;Show ROI;Hide ROI;Clear ROI\""

 	x0=140; y0=17
  	groupBox Colors title="Color Options",pos={x0,y0}, size={90,60},fcolor=(65535,0,0),labelback=0
	PopupMenu SelectCT,pos={x0+13,y0+15},size={43,20},proc=SelectCTList,title="CT"
	PopupMenu SelectCT,mode=0,value= #"colornameslist()"
	checkbox invertCT,pos={x0+13,y0+40},size={80,14},title="Invert?"

	//AXES TAB
	cstarth=67; vstarth=20
	CheckBox hasHP pos={cstarth,vstarth},proc=CheckBoxProc,title="has horz prof?"
	execute "checkbox hasHP,value="+df+"hasHP"
	CheckBox hasVP pos={cstarth,vstarth+15},proc=CheckBoxProc,title="has vert prof?"
	execute "checkbox hasVP,value="+df+"hasVP"
	CheckBox hasHI pos={cstarth+93,vstarth},proc=CheckBoxProc,title="(3D) has horz img?"
	execute "checkbox hasHI,value="+df+"hasHI"
	CheckBox hasVI pos={cstarth+93,vstarth+15},proc=CheckBoxProc,title="(3D) has vert img?"
	execute "checkbox hasVI,value="+df+"hasVI"
	CheckBox ZTPmode pos={cstarth+218,vstarth},proc=CheckBoxProc,title="(4D) image mode"
	execute "checkbox ZTPmode,value="+df+"ZTPmode"
	CheckBox hasZP pos={cstarth+218,vstarth+15},proc=CheckBoxProc,title="(3D) has Z prof?"
	execute "checkbox hasZP,value="+df+"hasZP"
	CheckBox hasTP pos={cstarth+218,vstarth+30},proc=CheckBoxProc,title="(4D) has T prof?"
	execute "checkbox hasTP,value="+df+"hasTP"

	CheckBox transXY pos={cstarth+50,vstarth+30},proc=CheckBoxProc,title="transpose 1st and 2nd axes"
	execute "checkbox transXY,value="+df+"transXY"
	nvar dim3index=$(df+"dim3index")
	nvar dim4index=$(df+"dim4index")
	popupmenu dim3index,pos={cstarth+333,vstarth},proc=dim34setproc,title="3rd dimension is",mode=0
	setupdim34value(df,"dim3index",dim3index)
	popupmenu dim4index,pos={cstarth+333,vstarth+22},proc=dim34setproc,title="4th  dimension is",mode=0
	setupdim34value(df,"dim4index",dim4index)
	
	CheckBox AutoScaleHP pos={cstarth +470,vstarth},proc=CheckBoxProc,title="SmartScale HP?"
	execute "checkbox AutoScaleHP,value="+df+"AutoScaleHP"
	CheckBox AutoScaleVP pos={cstarth +470,vstarth+15},proc=CheckBoxProc,title="SmartScale VP?"
	execute "checkbox AutoScaleVP,value="+df+"AutoScaleVP"
	
	//EXPORT TAB
	popupmenu Export,mode=0,pos={100,23},size={43,20},proc=ExportList,title="Export",value="-;X-wave;Y-wave;Z-wave;T-wave;-;H-image;V-image;-;Main Image;Corner Image"
	button Animate,pos={200,23},size={73,20},proc=AnimateProc,title="Animate"
	
		
	//LINEOUT TAB
	Button drawPoly title="drawPoly",pos={70,22},size={100,20},proc=DrawPolyProc 
	Button donePoly,title="done",pos={70,45},size={100,20},proc=DonePolyProc
	Button extractProfile,title="Extract w/Poly",pos={180,22},size={100,20},proc=ExtractPolyProc
	Button killPoly, title="Kill",pos={180,45},size={100,20},proc=KillPolyProc
	Button extractLine,title="Extract Line",pos={290,22},size={100,20},proc=ExtractLineProc
	Button killLine,title="Hide Lines",pos={290,45},size={100,20},proc=KillLineProc
	  //stack
	Button Bstack,title="Stack",pos={450,22},size={100,20},proc=Stack_UpdateStackV
	SetVariable Csetstackoffset,pos={400,22},size={40,14},title=" "
	SetVariable Csetstackoffset,limits={1,Inf,1},value=$(df+"stack:pinc")

	
	//PROCESS TAB
	popupmenu ProcessROIDraw,mode=0,pos={70,22},size={100,20},proc=ProcessROIDraw,title="draw ROI",value="Rectangular;Polygon;Polygon Smooth"
	Button ProcessROIDone,title="done",pos={70,45},size={100,20},proc=ProcessROIDone
	popupmenu ProcessROI,mode=0,pos={180,22},size={100,20},proc=ProcessUsingROI,title="Process w/ROI",value="Align Images"
	//Button ProcessAlignImages,title="Align Images",pos={180,22},size={100,20},proc=ProcessAlign
	Button ProcessROIkill,title="Kill ROI",pos={180,45},size={100,22},proc=ProcessROIkill
	popupmenu Process,mode=0,pos={290,22},size={100,20},proc=IT5process,title="Process",value="Zap Nans;Clip Min/Max"
	


	//Bin Tab
	
	svar dname=$(df+"dname")
	wave w=$dname
	 x0=67; y0=17
	 cstarth=77;vstarth=32
	cstep=150
	vstep=22
	variable bstep=70

	 groupBox MAvg title="Binning",pos={x0,y0}, size={250,60},labelback=0
	
	SetVariable setbin0,pos={cstarth,vstarth},size={70,14},title=binaxistitle(df,0)
	execute "SetVariable setbin0,limits={1,"+num2str(dimsize(w,0))+",1},value="+df+"bin[0], bodywidth=40"
	CheckBox setbincuropt0 pos={cstarth+bstep,vstarth},title=""
	execute "checkbox setbincuropt0,variable="+df+"bincuropt0"
	
	SetVariable setbin1,pos={cstarth,vstarth+vstep},size={70,14},title=binaxistitle(df,1)
	execute "SetVariable setbin1,limits={1,"+num2str(dimsize(w,1))+",1},value="+df+"bin[1], bodywidth=40"
	CheckBox setbincuropt1 pos={cstarth+bstep,vstarth+vstep},title=""
	execute "checkbox setbincuropt1,variable="+df+"bincuropt1"
	
	SetVariable setbin2,pos={cstarth+cstep,vstarth},size={70,14},title=binaxistitle(df,2)
	execute "SetVariable setbin2,limits={1,"+num2str(dimsize(w,2))+",1},value="+df+"bin[2], bodywidth=40"
	CheckBox setbincuropt2 pos={cstarth+cstep +bstep,vstarth},title=""
	execute "checkbox setbincuropt2,variable="+df+"bincuropt2"
	
	SetVariable setbin3,pos={cstarth+cstep,vstarth+vstep},size={70,14},title=binaxistitle(df,3)
	execute "SetVariable setbin3,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"bin[3], bodywidth=40"
	CheckBox setbincuropt3 pos={cstarth+cstep+bstep,vstarth+vstep},title=""
	execute "checkbox setbincuropt3,variable="+df+"bincuropt3"
	
	//Norm Tab
	//Norm Tab
	
	x0=67; y0=17
	 cstarth=70;vstarth=32
	cstep=60
	vstep=22
	 bstep=70

	 groupBox MNorm1 title="Norm1",pos={x0,y0}, size={230,60},labelback=0
	
	popupmenu cNorm1_Menu,mode=1,pos={cstarth,vstarth},size={43,20},proc=NormMenu,title="",value="off;1D;2D;3D"
	popupmenu cNorm1_AXIS,mode=1,pos={cstarth,vstarth+vstep},size={43,20},proc=NormAxisMenu,title="",userdata=df,value=""
	popupmenu cNorm1_Method,mode=1,pos={cstarth+cstep,vstarth},size={43,20},proc=NormMethproc,title="",value="Area;-m/(M-m);-m;-m/area"
	SetVariable cNorm1_x0,pos={cstarth+2.5*cstep,vstarth+3},size={70,14},title="x0"
	execute "SetVariable cNorm1_x0,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"Norm1_X0, bodywidth=60"
	SetVariable cNorm1_x1,pos={cstarth+2.5*cstep,vstarth+vstep+3},size={70,14},title="x1"
	execute "SetVariable cNorm1_x1,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"Norm1_X1, bodywidth=60"

	x0=300; y0=17
	 cstarth=303;vstarth=32
	cstep=60
	vstep=22
	 bstep=70


	 groupBox MNorm2 title="Norm2",pos={x0,y0}, size={230,60},labelback=0
	
	popupmenu cNorm2_Menu,mode=1,pos={cstarth,vstarth},size={43,20},proc=NormMenu,title="",value="off;1D;2D;3D"
	popupmenu cNorm2_AXIS,mode=1,pos={cstarth,vstarth+vstep},size={43,20},proc=NormAxisMenu,title="",userdata=df,value=""
	popupmenu cNorm2_Method,mode=1,pos={cstarth+cstep,vstarth},size={43,20},proc=NormMethproc,title="",value="Area;-m/(M-m);-m;-m/area"
	SetVariable cNorm2_x0,pos={cstarth+2.5*cstep,vstarth+3},size={70,14},title="x0"
	execute "SetVariable cNorm2_x0,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"Norm2_X0, bodywidth=60"
	SetVariable cNorm2_x1,pos={cstarth+2.5*cstep,vstarth+vstep+3},size={70,14},title="x1"
	execute "SetVariable cNorm2_x1,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"Norm2_X1, bodywidth=60"


//	popupmenu Norm2DROIDraw,mode=0,pos={70,45},size={100,20},proc=ProcessROIDraw,title="draw ROI",value="Rectangular;Polygon;Polygon Smooth"
//	Button Norm2DROIDone,title="done",pos={150,45},size={80,20},proc=ProcessROIDone
//	Button Norm2DROIkill,title="Kill ROI",pos={200,23},size={100,20},proc=ProcessROIkill	
		

//	 NVAR ndim=$(df+"ndim")
	 
//	 popupmenu AvgZTMenu,mode=1,pos={cstarth,vstarth},size={43,20},proc=AvgZTMenu,title="",value="None;Range;ROI;\M1-;Add ROI;ShowROI;HideROI;Clear ROI"
	
	//popupmenu AvgZTROIDraw,mode=0,pos={cstarth+cstep,vstarth},size={100,20},proc=ProcessROIDraw,title="draw ROI",value="Rectangular;Polygon;Polygon Smooth"

	//Button AvgZTROIDone,title="done",pos={cstarth+cstep,vstarth+vstep},size={80,20},proc=ProcessROIDone
	//Button AvgZTROIkill,title="Kill ROI",pos={cstarth+cstep,vstarth+vstep},size={80,20},proc=ProcessROIkill
//	vstep=17;vstarth=35
//	SetVariable setZavg,pos={cstarth + cstep,vstarth},size={70,14},title="Avg Z"
//	SetVariable setZavg,limits={1,inf,1},value=$(df+"setZavg")
//	SetVariable setTavg,pos={cstarth + cstep,vstarth +vstep},size={70,14},title="Avg T"
//	SetVariable setTavg,limits={1,inf,1},value=$(df+"setTavg")
//
//	 x0=350;cstarth=360
//	 cstep=100
//	vstep=17
//	 groupBox VAvg title="V Img",pos={x0,y0}, size={90,60},labelback=0
//
//	SetVariable setXavg,pos={cstarth,vstarth},size={70,14},title="Avg X"
//	SetVariable setXavg,limits={1,inf,1},value=$(df+"setYavg")
//
//	groupBox HAvg title="H Img",pos={x0+cstep,y0}, size={90,60},fcolor=(65535,0,0),labelback=0
//
//	SetVariable setYavg,pos={cstarth+cstep,vstarth },size={70,14},title="Avg Y"
//	SetVariable setyavg,limits={1,inf,1},value=$(df+"setYavg")
end

function /S BINaxistitle(df,n)
	string df
	variable n
	svar dname=$(df+"dname")
	wave w=$(dname)
	string wu=waveunits(w,n)
	if (strlen(wu)==0)
		return "axis"+num2str(n)
	else
		return wu
	endif
end


Function NormMenu(PU_Struct)
	STRUCT WMPopupAction &PU_Struct
	string df=getdf()
	svar dname=$(df+"dname")
	wave w=$dname
	string ctrlName=PU_Struct.ctrlName
	variable Norm_num=str2num( ctrlname[5,5])
	Nvar axis=$(df+"Norm"+num2str(Norm_num)+"_Axis")
	string nn="Norm"+num2str(Norm_num)
	NVAR Mode= $(df+nn+"_Mode")
	Nvar method=$(df+"Norm"+num2str(Norm_num)+"_Method")
	switch(PU_Struct.popnum)	
		case 1:
			Mode=1
			string Norm_name=df+"Norm"+num2str(Norm_Num)
			 execute Norm_name+"_trig=0"
			setupV(getdfname(),dname)
			break
		case 2:		
			Mode=2
			NormSetup(df,dname,nn,Norm_Num,axis,method)
			setupV(getdfname(),dname)
			break
		case 3:		
			break
					
	endswitch
end

Function NormMethProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	string df=getdf()
	svar dname=$(df+"dname")
	wave w=$dname
	string ctrlName=PU_Struct.ctrlName
	variable Norm_num=str2num( ctrlname[5,5])
	Nvar method=$(df+"Norm"+num2str(Norm_num)+"_Method")
	method = PU_Struct.popnum-1
	Nvar axis=$(df+"Norm"+num2str(Norm_num)+"_Axis")
	string nn="Norm"+num2str(Norm_num)
	NVAR Mode= $(df+nn+"_Mode")
	
	NormSetup(df,dname,nn,Norm_Num,axis,method)
end

Function NormSetup(df,dname,nn,Norm_Num,axis,method)
	string df,dname,nn
	variable Norm_Num,axis,method
	make /o/N=4 dims
	variable i=0,j=0
	wave w=$dname
	for(i=0;i<4;i+=1)
		dims[i]=dimsize(w,i)
	endfor
	dims[axis]=1
	string ANorm_name=df+"Norm"+num2str(Norm_Num)
	if(method==0)
		make /o  /N=(dims[0],dims[1],dims[2],dims[3]) $ANorm_name
	else
		make /o  /C/N=(dims[0],dims[1],dims[2],dims[3]) $ANorm_name
	endif
	wave Anormw=$ANorm_name
	variable /g $(ANorm_name+"_trig")
	NVAR trig=$(ANorm_name+"_trig")
	trig=0
	if(norm_num==1)
		execute ANorm_name+"_trig:=calcnorm("+ANorm_name+","+dname+","+num2str(method)+","+num2str(axis)+","+df+nn+"_p0,"+df+nn+"_p1)"
	elseif(norm_num==2)
		string ANorm_name1=df+"Norm"+num2str(1)
		execute ANorm_name+"_trig:=calcnorm2("+ANorm_name+","+dname+","+ANorm_name1+","+num2str(method)+","+num2str(axis)+","+df+nn+"_p0,"+df+nn+"_p1)"
	endif

end



Function NormAxisMenu(PU_Struct)
	STRUCT WMPopupAction &PU_Struct
	if(PU_Struct.eventCode==2)
	
		string df=getdf()
		svar dname=$(df+"dname")
		wave w=$dname
		string ctrlName=PU_Struct.ctrlName
		variable Norm_num=str2num( ctrlname[5,5])
		Nvar axis=$(df+"Norm"+num2str(Norm_num)+"_Axis")
		axis=PU_Struct.popNum-1
		popupmenu $ctrlName,mode=axis+1

		string nn="Norm"+num2str(Norm_num)
		NVAR Mode= $(df+nn+"_Mode")
		
		
		
		if(Mode==2)
			NormSetup(df,dname,nn,Norm_Num,PU_Struct.popNum-1,0)
		endif
		variable x0=-inf
		variable x1=inf
		getmarquee 
		if(V_flag==1)
			variable dn
			string dfn=winname(0,1)
			variable avgx=(V_left+V_right)/2
			variable avgy=(V_top+V_bottom)/2
			string imgname=whichimage(dfn,avgx,avgy)

			if(strlen(imgname)>0)
				struct imageWaveNameStruct s
				getimageinfo(df,imgname,s)		
				if(s.hindex==axis)
					getmarquee /K $s.haxis
					x0=V_left
					x1=V_right
				endif
				if(s.vindex==axis)
					getmarquee /K $s.vaxis
					x0=V_top
					x1=V_bottom
				endif				
			endif
			string tracename=whichtrace(df,avgx,avgy)
		endif
		variable x0L=dimoffset(w,axis)
		variable x1L=dimoffset(w,axis)+dimdelta(w,axis)*dimsize(w,axis)
		x0=max(x0,x0L)
		x1=min(x1,x1L)
		NVAR Norm1_X0=$(df+nn+"_X0")
		NVAR Norm1_X1=$(df+nn+"_X1")
		Norm1_X0=x0
		Norm1_X1=x1
		string X0n = num2str(dimoffset(w,axis))
		string Xdn = num2str(dimdelta(w,axis))

	
		execute df+nn+"_p0:=("+df+nn+"_x0-"+x0n+")/"+Xdn
		execute df+nn+"_p1:=("+df+nn+"_x1-"+x0n+")/"+Xdn
		execute "SetVariable cNorm1_x0,limits={"+num2str(x0L)+","+num2str(x1L)+","+num2str(dimdelta(w,axis))+"},value="+df+"Norm1_X0"
		execute "SetVariable cNorm1_x1,limits={"+num2str(x0L)+","+num2str(x1L)+","+num2str(dimdelta(w,axis))+"},value="+df+"Norm1_X1"

	endif
	
				
end
  


Function ProcessROIDraw(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string ROIName=getROIname(ctrlName)
	string df=getdf()
	button $(ROIName+"ROIdone"),disable=0
	nvar processROImode=$(df+ROIName+"ROIMode")
	processROIMode=popnum
	make/o/n=0 proc_ROIy proc_ROIx//$(df+"processROIy"), $(df+"processROIx")
	wave processROIx=$(df+ROIName+"ROIx"), processROIy=$(dF+ROIName+"ROIy")
// 	removefromgraph/z processROIy
	switch(processROIMode)	
		case 1:		//rect
			//user makes marquee then presses done
			break		
		case 2:		//polygon
			graphwavedraw/o/L=left/B=bottom proc_ROIy proc_ROIx
			break
		case 3:		//polygon smooth
			graphwavedraw/f=3/o/L=left/B=bottom proc_ROIy proc_ROIx
			break
	endswitch

end

Function ProcessROIDone(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	string ROIName=getROIname(ctrlName)
	graphnormal
	button $(ROIName+"ROIdone"),disable=1
	nvar processROImode=$(df+ROIName+"ROIMode")
	//nvar v_flag=v_flag, v_left=v_left, v_right=v_right, v_top=v_top, v_bottom=v_bottom
	wave proc_ROIx, proc_ROIy
	removefromgraph/z proc_roiy
	wave prx=$(df+ROIName+"ROIx"), pry=$(dF+ROIName+"ROIy")
	switch(processROIMode)
		case 1:	//rect
			getmarquee/k left bottom
			redimension/n=5 proc_ROIx, proc_ROIy
			if(v_flag)
				proc_ROIx={v_left,v_right,v_right,v_left, v_left}
				proc_ROIy={v_bottom, v_bottom, v_top, v_top, v_bottom}
			else
				print "error: no marquee was drawn"
			endif
			break
	endswitch
	variable np=numpnts(prx)
	redimension/n=(numpnts(proc_ROIx)+1+np) prx, pry
	prx[np]=nan; pry[np]=nan
	prx[np+1,]=proc_roix[p-np-1]; 	pry[np+1,]=proc_roiy[p-np-1]
	removefromgraph/z processROIy
	imageGenerateROIMask/e=0/i=1 img
	duplicate/o m_roimask $(df+ROIName+"ROImask")
	redimension/s $(dF+ROIName+"ROImask")
	ProcessDrawROI(df,ROIName,1)
end

function ProcessDrawROI(df,ROIname,show)
	string df; string ROIName;variable show
	wave prx=$(df+ROIName+"ROIx"), pry=$(dF+ROIName+"ROIy")
	setdrawlayer/k progfront
	setdrawenv fillpat=0, xcoord=bottom, ycoord=left,linethick=show,linefgc=(65535,0,0)
	drawpoly/abs 0,0,1,1,prx,pry
	setdrawlayer userfront
end

Function ProcessROIKill(ctrlName) : ButtonControl
	String ctrlName
	string ROIName=getROIname(ctrlName)
	string df=getdf()
	wave prx=$(df+ROIName+"ROIx"), pry=$(dF+ROIName+"ROIy")
	redimension/n=0 prx, pry
	ProcessDrawROI(df,ROIName,0)
end

Function/S getROIname(ctrlName)
	string ctrlName
	variable pos=strsearch(ctrlName,"ROI",Inf,3)
	if(pos<0)
		pos = strlen(ctrlName)
	endif
	return ctrlname[0,pos-1] 
end

Function ProcessUsingROI(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	nvar ndim=$(dF+"ndim")
	svar dname=$(dF+"dname")
	wave wv=$dname
	strswitch(popStr)
		case "Align Images":
			make/o/n=1 m_regout, w_regparams
			//wave m_regout,w_regparams
			if(ndim<3)
				doalert 0,"Must be at least 3 dimensional wave"
				break
			endif
			wavestats/q wv
			if(numpnts(wv)!=v_npnts)
				doalert 0,"Must Zap Nans first"
				break
			endif
			svar dname=$(df+"dname")
			string name=dname+"_al"
			prompt name,"Name of new 3d output wave"
			doprompt "Align Images",name
			wave img=$(dF+"img"), imgh=$(dF+"imgh")
			nvar zc=$(df+"zc")
			variable i=0,nz=dimsize(imgh,1),z0=dimoffset(imgh,1),zd=dimdelta(imgh,1),xd=dimdelta(img,0),yd=dimdelta(img,1)
			variable nx=dimsize(img,0),ny=dimsize(img,1)
			zc=z0+(nz-1)*zd;// print zc
			doupdate
			make/o/n=(nx,ny,nz) $name
			make/o/n=(nx,ny) pa_imgref, pa_imgtest
			pa_imgref=img[p][q]
			wave mask=$(dF+"procROImask")
			duplicate/o mask pa_testmask, pa_refmask
			wave wvout=$name
			copyscales/p wv,wvout,pa_imgref,pa_imgtest
	
			for(i=0;i<dimsize(imgh,1);i+=1)
				zc=z0 + i*zd
				doupdate
				pa_imgtest=img[p][q]
				imageregistration/q/rot={0,0,0}/skew={0,0,0} testwave=pa_imgtest, refwave=pa_imgref, testmask=pa_testmask, refmask=pa_refmask
				wvout[][][i]=interp2d(img,x-xd*w_regparams[0],y-yd*w_regparams[1])
				//print i,w_regparams[0],w_regparams[1]
			endfor
			killwaves pa_imgref,pa_imgtest
			break
	endswitch
end

Function IT5Process(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	svar dname=$(dF+"dname")
	wave wv=$dname
	strswitch(popstr)
		case "Zap Nans":
			wv=selectnumber(numtype(wv)==0,0,wv)
			break
		case "Clip Min/Max":
			wavestats/q wv
			variable minn=v_min, maxx=v_max,outside=0
			prompt minn,"Enter minimum value to clip to"
			prompt maxx,"Enter maximum value to clip to"
			prompt outside,"Enter value to use outside range"
			doprompt "Set clip values",minn,maxx
			if(!v_flag)
				wv=selectnumber((wv>=minn) * (wv<=maxx), outside,wv)
			endif
	endswitch
end

structure imageWaveNameStruct
	string xwv
	string ywv
	string image
	string imageROI
	string imode
	string haxis
	string vaxis
	string showROI
	string whCT
	variable hindex
	variable vindex
endstructure

Function ROIColorOption(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	struct imageWaveNameStruct s
	ROIgetStrings(df,ctrlname,s)
	wave xw=$(df+s.xwv), yw=$(df+s.ywv),img=$(df+s.image), imgROI=$(df+s.imageROI)
	nvar im=$(df+s.imode), showROI=$(df+s.showROI), whichCT=$(df+s.whCT)
	make/o/n=0 $(df+"xwt"), $(df+"ywt")	//temp waves for generating new ROI
	variable makeROI=(popnum==4), sel
	if((im==1)*(popnum==2))
		//going from "free" to "roi"
		if(numpnts(xw)==0)
			//force add ROI
			makeROI=1
		endif
	endif
	variable np
	switch(popnum)
		case 1:
			//free
			showROI=0
			ROIupdatePolys(df,1)
			im=1
			break
		case 2:
			//ROI
			showROI=1
			ROIupdatePolys(df,1)
			im=2
			break
		case 3:	
			//"Lock
			im=3
			break
		case 4:	
			//"dash" so do nothing
			break
		case 6:
			redimension/n=0 xw,yw
		case 5:	
			//ADD ROI
			im=2
			showROI=1
			getmarquee  /k $s.vaxis, $s.haxis
			if(V_flag==1) 
				make/o/n=5 roi_ywt, roi_xwt
				
				roi_xwt[0]=V_left
				roi_xwt[1]=V_left
				roi_xwt[2]=V_right
				roi_xwt[3]=V_right
				roi_xwt[4]=V_left

				roi_ywt[0]=V_top
				roi_ywt[1]=V_bottom
				roi_ywt[2]=V_bottom
				roi_ywt[3]=V_top
				roi_ywt[4]=V_top
				appendtograph /L=$s.vaxis/B=$s.haxis roi_ywt vs roi_xwt
				ROIDoneEditing("doneROI")
				popupmenu $ctrlName,mode=im

				return 0
			endif
			button  doneROI,disable=0	//make visible
			graphwavedraw/f=3/o/L=$s.vaxis/B=$s.haxis roi_ywt,roi_xwt
			return 0
			break
		
		
		case 7:	
			//Show ROI
			showROI=1
			ROIupdatePolys(df,1)
			popupmenu $ctrlName,mode=im
			break
		case 8:	
			//Hide ROI
			showROI=0
			ROIupdatePolys(df,1)
			popupmenu $ctrlName,mode=im
			break
		case 9:
			//Clear ROI
			redimension/n=0 xw,yw
			ROIupdatePolys(df,1)
			im=1
			popupmenu $ctrlName,mode=im		
			break
		case 10:
			//Color
			prompt sel,"choose a color table",popup colornameslist()
			doprompt "Choose color table",sel
			whichCT=sel
			popupmenu $ctrlName,mode=im
			break
	endswitch
	popupmenu $ctrlName,mode=im

	adjustCTmain(df)
	adjustCTh(df)
	adjustCTv(df)	
	adjustCTzt(df)
End

Function ROIAllColorOpts(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	nvar imgmode=$(df+"imgmode"), imgHmode=$(df+"imgHmode"), imgVmode=$(df+"imgVmode"), imgZTmode=$(df+"imgZTmode")
	nvar imgshow=$(df+"imgShowROI"), imgHshow=$(df+"imgHshowROI"), imgVshow=$(df+"imgVshowROI"), imgZTshow=$(df+"imgZTshowROI")	

	switch(popnum)
		case 6:
			//Clear ROI
			variable i
			for(i=1;i<7;i+=1)
				redimension/n=0 $(df+"img"+num2str(i)+"rx"), $(df+"img"+num2str(i)+"ry")
			endfor
			popnum=1	//force "FREE"
		case 1:
			//Free
				for(i=1;i<7;i+=1)
					NVAR im= $(df+"img"+num2str(i)+"mode")
					im=1
					NVAR show= $(df+"img"+num2str(i)+"showROI")
					show=0
				endfor
			popupmenu imgopt,mode=1; popupmenu imgHopt,mode=1; popupmenu imgVopt,mode=1;popupmenu imgZTopt,mode=1
			ROIupdatePolys(df,1)
			popupmenu $ctrlname,mode=0
			break
		case 2:
			//ROI
			imgmode=2; imgHmode=2; imgVmode=2; imgZTmode=2
			imgshow=1; imgHshow=1; imgVshow=1; imgZTshow=1
			for(i=1;i<7;i+=1)
				NVAR im= $(df+"img"+num2str(i)+"mode")
				im=2
				NVAR show= $(df+"img"+num2str(i)+"showROI")
				show=1
			endfor
			popupmenu imgopt,mode=2
			popupmenu imgHopt,mode=2
			popupmenu imgVopt,mode=2
			popupmenu imgZTopt,mode=2
			ROIupdatePolys(df,1)			
			popupmenu $ctrlname,mode=0
			break
		case 3:
			//-
			break
		case 4:
			//Show ROI
			imgshow=1; imgHshow=1; imgVshow=1; imgZTshow=1
			ROIUpdatePolys(df,1)			
			popupmenu $ctrlname,mode=0
			break
		case 5:
			//Hide ROI
			imgshow=0; imgHshow=0; imgVshow=0; imgZTshow=0
			ROIUpdatePolys(df,1)			
			popupmenu $ctrlname,mode=0
			break
	endswitch
	adjustCTmain(df)
	adjustCTh(df)
	adjustCTv(df)	
	adjustCTzt(df)
End

Function ROIDoneEditing(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	graphnormal
	button doneROI,disable=1
	svar ctrln=$(df+"ROIctrlEditing")
	struct imageWaveNameStruct s
	ROIGetStrings(df,ctrln,s)
	wave xw=$(df+s.xwv), yw=$(df+s.ywv),img_=$(df+s.image)
	wave xwt=$"roi_xwt", ywt=$"roi_ywt"
	nvar im=$(df+s.imode)
	variable np
	np=dimsize(xw,0)
	if (numpnts(xw)!=0)
		redimension/n=(np+1+dimsize(xwt,0)) xw,yw
		xw[np]=nan; yw[np]=nan
		xw[np+1,]=xwt[p-(np+1)]
		yw[np+1,]=ywt[p-(np+1)]
	else 
		duplicate/o xwt xw
		duplicate/o ywt,yw
		ROIupdatePoly(df,xw,yw,s.haxis,s.vaxis,1)
	endif
	
	imageGenerateROIMask/E=1/I=0 $s.image
	duplicate/o m_ROIMask $(df+s.imageROI)
	ROIupdatePolys(df,1)
	popupmenu $ctrln,mode=im
	removefromgraph roi_ywt
	adjustCTmain(df)
	adjustCTh(df)
	adjustCTv(df)	
	adjustCTzt(df)
End

Function ROLoadSliceState(df,img) 
	string img
	string df
	struct imageWaveNameStruct s
	String ctrlName=img+"OPT"
	ROIGetStrings(df,ctrlName,s)
	wave xw=$(df+s.xwv), yw=$(df+s.ywv),img_=$(df+s.image)
	nvar im=$(df+s.imode)
	popupmenu $ctrlName,mode=im

	ROIupdatePoly(df,xw,yw,s.haxis,s.vaxis,0)
	imageGenerateROIMask/E=1/I=0 $s.image
	duplicate/o m_ROIMask $(df+s.imageROI)
End




	 

Function ROIColorProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	wave ROIcolor=$(df+"ROIColor")
	variable r,g,b
	RGBstrToRGB(popStr,r,g,b)
	ROIcolor={r,g,b}
	ROIupdatePolys(df,1)
End

// take (r,g,b) string and extract out numeric r,g,b values
static Function RGBstrToRGB(rgbStr,r,g,b)
	String rgbStr
	Variable &r, &g, &b

	r= str2num(rgbStr[1,inf])
	variable spos= strsearch(rgbStr,",",0)
	g= str2num(rgbStr[spos+1,inf])
	spos= strsearch(rgbStr,",",spos+1)
	b= str2num(rgbStr[spos+1,inf])
	return 1
End

static function ROIupdatePoly(df,xw,yw,haxis,vaxis,lthk)
	string df
	wave xw,yw
	string haxis,vaxis
	variable lthk
	wave ROIcolor=$(df+"ROIcolor"); variable r=ROIcolor[0], g=ROIcolor[1], b=ROIcolor[2]
	setdrawlayer/k progfront
	setdrawenv fillpat=0, xcoord=$haxis, ycoord=$vaxis,linethick=lthk,linefgc=(r,g,b)
	drawpoly/abs 0,0,1,1,xw,yw
	setdrawlayer userfront

end

function ROIupdatePolys(df,show)
	string df; variable show
	wave ROIcolor=$(df+"ROIcolor"); variable r=ROIcolor[0], g=ROIcolor[1], b=ROIcolor[2]
	nvar hasHI=$(df+"hasHI"),hasVI=$(df+"hasVI"), hasTP=$(df+"hasTP")
	nvar ZTPMode=$(df+"ZTPmode")
	struct imageWaveNameStruct s
	setdrawlayer/k progfront
	String ctrlName="imgOPT"
	ROIGetStrings(df,ctrlName,s)
	nvar ShowROI=$(df+s.showroi)
	wave xw=$(df+s.xwv), yw=$(df+s.ywv)
	setdrawenv fillpat=0,xcoord=bottom, ycoord=left,linethick=showROI*show, linefgc=(r,g,b)
	drawpoly/abs 0,0,1,1,xw,yw
	if(hasHI)
		 ctrlName="imgHOPT"
		ROIGetStrings(df,ctrlName,s)
		nvar hShowROI=$(df+s.showROI)
		wave xw=$(df+s.xwv), yw=$(df+s.ywv)
		setdrawenv fillpat=0,xcoord=bottom, ycoord=imgHL,linethick=hshowROI*show, linefgc=(r,g,b)
		drawpoly/abs 0,0,1,1,xw,yw
	endif
	if(hasVI)
		 ctrlName="imgVOPT"
		ROIGetStrings(df,ctrlName,s)
		nvar vShowROI=$(df+s.showROI)
		wave xw=$(df+s.xwv), yw=$(df+s.ywv)
		setdrawenv fillpat=0,xcoord=imgVB, ycoord=left,linethick=vshowROI*show, linefgc=(r,g,b)
		drawpoly/abs 0,0,1,1,xw,yw
	endif
	if(ZTPmode*hasTP)
		 ctrlName="imgZTOPT"
		ROIGetStrings(df,ctrlName,s)
		nvar ztShowROI=$(df+s.showROI)
		wave xw=$(df+s.xwv), yw=$(df+s.ywv)
		setdrawenv fillpat=0,xcoord=imgZTt, ycoord=imgZTr,linethick=ztShowROI*show, linefgc=(r,g,b)
		drawpoly/abs 0,0,1,1,xw,yw
	endif
	setdrawlayer userfront	
end

//figures out for ctrlname="imgHopt" etc,  the names of the waves needed
//stores name "ctrlname" which was called for easy access when done editing ROI
static function ROIgetstrings(df,ctrlname,s)//xwv,ywv,image,imageROI,imode, haxis,vaxis,showROI
	string ctrlname
	struct imageWaveNameStruct &s//&xwv,&ywv,&image,&imageROI,&imode,&showROI
	//	string &haxis,&vaxis
	string df
	
	svar ROIctrlEditing=$(df+"ROICtrlEditing")
	ROIctrlediting=ctrlname
	string imgname=ctrlname[0,strlen(ctrlname)-4]
	 getimageinfo(df,imgname,s)
	return 0
end

static function gettraceaxis(df,tracename)
	string df,tracename
	WAVE dnum=$(df+"dnum")
	strswitch(tracename)
		case "Hprof":
			return dnum[0]
			break
		case "Vprof":
			return dnum[1]
			break
		case "ZProf":
			return dnum[2]
			break
		case "TProf":
			return dnum[3]
			break
	endswitch
end

static function getimageinfo(df,imgname,s)
	string imgname
	struct imageWaveNameStruct &s
	string df
	WAVE dnum=$(df+"dnum")
	strswitch(imgname)
		case "img":		
			//	s.xwv="imgrx"; s.ywv="imgry"
			s.image="img"; s.imageROI="imgROI"
			s.vaxis="left"; s.haxis="bottom"
			s.whCT="whichCT"
			s.hindex=dnum[0]
			s.vindex=dnum[1]
			break
		case "imgH":
			s.image="imgH"; s.imageROI="imgHROI"
			s.vaxis="imgHL"; s.haxis="bottom"
			s.whCT="whichCTh"
			s.hindex=dnum[0]
			s.vindex=dnum[2]
			break
		case "imgV":
			//	s.xwv="imgVrx"; s.ywv="imgVry"
			s.image="imgV"; s.imageROI="imgVROI";
			s.vaxis="left"; s.haxis="imgVB"
			s.whCT="whichCTv"
			s.hindex=dnum[2]
			s.vindex=dnum[1]
			break
		case "imgZT":
			s.xwv="imgZTrx"; s.ywv="imgZTry"
			s.image="imgZT"; s.imageROI="imgZTROI";
			s.vaxis="imgZTr"; s.haxis="imgZTt"
			s.whCT="whichCTzt"
			s.hindex=dnum[2]
			s.vindex=dnum[3]			
			break
	endswitch
	variable i
	variable i1=s.hindex
	variable i2=s.vindex
	variable temp,swap=1
	if (i1>i2)
		temp=i1
		i1=i2
		i2=temp
		swap=-1
	endif
	variable index=i1*2+i2

	if (index==7)
		index=6
	endif
	i= index*swap
	if(i<0)
		i*=-1
		s.xwv="img"+num2str(i)+"ry"
		s.ywv = "img"+num2str(i)+"rx"
	else
		s.ywv="img"+num2str(i)+"ry"
		s.xwv="img"+num2str(i)+"rx"
	endif
	s.imode= "img"+num2str(i)+"Mode"
	s.showROI="img"+num2str(i)+"ShowROI"
	return 0
end


function setupdim34value(df,s,valchecked)
	string df,s
	variable valchecked
	svar dname=$(df+"dname")
	wave w=$dname
	string u0=selectstring(valchecked==0,"","> ")+"x ["+waveunits(w,0)+"];"
	string u1=selectstring(valchecked==1,"","> ")+"y ["+waveunits(w,1)+"];"
	string u2=selectstring(valchecked==2,"","> ")+"z ["+waveunits(w,2)+"];"
	string u3=selectstring(valchecked==3,"","> ")+"t ["+waveunits(w,3)+"];"
	execute "popupmenu " + s + " value=\"" + u0 +u1+u2+u3+"\""
end	
	

function setupV(dfn,w)
	string dfn,w
	silent 1; pauseupdate
//	setdatafolder root:
	string df="root:"+dfn+":"
	variable/g $(df+"ndim")=wavedims($w)
	nvar ndim=$(df+"ndim")
	ndim=wavedims($w)
	wave wv=$w
	nvar x0=$(df+"x0"), xd=$(df+"xd"), xn=$(df+"xn")
	nvar y0=$(df+"y0"), yd=$(df+"yd"), yn=$(df+"yn") 
	nvar z0=$(df+"z0"), zd=$(df+"zd"), zn=$(df+"zn") 
	nvar t0=$(df+"t0"), td=$(df+"td"), tn=$(df+"tn") 
	nvar  x1=$(df+"x1"), y1=$(df+"y1"),z1=$(df+"z1"),t1=$(df+"t1")
	nvar isnew=$(df+"isNew")
	svar dname=$(df+"dname")
	dname=w
	string dummy=dimname(df,0) 	//dummy call to setup dnum array
	wave dnum=$(df+"dnum")
	string xl=waveunits($w,dnum[0]),yl=waveunits($w,dnum[1]),zl=waveunits($w,dnum[2]),tl=waveunits($w,dnum[3])
	x0=dimoffset($w,dnum[0]); xd=dimdelta($w,dnum[0]); xn=dimsize($w,dnum[0])	
	y0=dimoffset($w,dnum[1]); yd=dimdelta($w,dnum[1]); yn=dimsize($w,dnum[1])	
	z0=dimoffset($w,dnum[2]); zd=dimdelta($w,dnum[2]); zn=dimsize($w,dnum[2])	
	t0=dimoffset($w,dnum[3]); td=dimdelta($w,dnum[3]); tn=dimsize($w,dnum[3])
	x1=x0+xn+xd; 	y1=y0+yn+yd; z1=z0+zn+zd; t1=t0+tn+td
	
	//setup colors
	nvar whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"),whichCTv=$(df+"whichCTv"),whichCTzt=$(df+"whichCTzt")
	execute "loadct("+num2str(whichCT)+")"	//load initial color table
	duplicate/o root:colors:ct $(df+"ct"), $(df+"ct_h"), $(df+"ct_v"), $(df+"ct_zt")
	wave ct=$(df+"ct"), ct_h=$(df+"ct_h"), ct_v=$(df+"ct_v"), ct_zt=$(df+"ct_zt")
	wave pmap=$(dF+"pmap")
	nvar gamma=$(dF+"gamma")
	setformula $(df+"pmap") , "255*(p/255)^"+df+"gamma)"
	setformula $(df+"ct"), "root:colors:all_ct[pmap[invertct*(255-p)+(invertct==0)*p]][q][whichCT]"
	setformula $(df+"ct_h"), "root:colors:all_ct[pmap[invertct*(255-p)+(invertct==0)*p]][q][whichCTh]"
	setformula $(df+"ct_v"), "root:colors:all_ct[pmap[invertct*(255-p)+(invertct==0)*p]][q][whichCTv]"
	setformula $(df+"ct_zt"), "root:colors:all_ct[pmap[invertct*(255-p)+(invertct==0)*p]][q][whichCTzt]"
	
	
	//make img waves
	make/o/n=(xn,yn) $(df+"img");
	wave img=$(df+"img");	setscale/p x,x0,xd,xl,img;		setscale/p y,y0,yd,yl,img
	make/o/n=(xn*(zn>0),zn) $(df+"imgh");
	wave imgh=$(df+"imgh");	setscale/p x,x0,xd,xl,imgh;		setscale/p y,z0,zd,zl,imgh
	make/o/n=(zn,yn) $(df+"imgv");
	wave imgv=$(df+"imgv");	setscale/p x,z0,zd,zl,imgv;		setscale/p y,y0,yd,yl,imgv
	make/o/n=(zn,tn) $(df+"imgZT")
	wave imgZT=$(df+"imgZT"); setscale/p y,t0,td,tl,imgzt;	setscale/p x,z0,zd,zl,imgzt	
	
	//make profile waves
	make/o/n=(zn) $(df+"pz"); 	wave pz=$(df+"pz");	setscale/p x,z0,zd,zl,pz
	make/o/n=(tn) $(df+"pt");	wave pt=$(df+"pt");	setscale/p x,t0,td,tl,pt
	make/o/n=(xn) $(df+"px");	wave px=$(df+"px");	setscale/p x x0,xd,xl,px
	make/o/n=(yn) $(df+"pyy");	wave pyy=$(df+"pyy")
	make/o/n=(yn)  $(df+"pyx"); 	wave pyx=$(df+"pyx")

	//DISPLAY AND SET IMAGE's AXIS LIMITS
	variable new=0
	dowindow/f $dfn
	if(v_flag==0)
		display/w=(20,20,600,500); appendimage img	
		DoWindow/C/T $dfn,dfn+" [ "+dname+" ]"
		setwindow $dfn,hook=img4dHookFcn,hookevents=3
		new=1
		modifyimage img,cindex=ct
		wavestats/q wv
	endif
	DoWindow/C/T $dfn,dfn+" [ "+dname+" ]"
	nvar hasHI=$(df+"hasHI"), hasHP=$(df+"hasHP"), hasVI=$(df+"hasVI"), hasVP=$(df+"hasVP"), hasZP=$(df+"hasZP"), hasTP=$(df+"hasTP")
	nvar ZTpmode=$(df+"ztpmode") 	//0=profiles, 1=image in upper right corner
	if(isnew)
		controlinfo hasHI
		if(V_Flag>0)
			hasHI=V_Value
		endif

		controlinfo hasvI
		if(V_Flag>0)
			hasvI=V_Value
		endif

		controlinfo hasZP
		if(V_Flag>0)
			hasZP=V_Value
		endif

		controlinfo ZTpmode
		if(V_Flag>0)
			ZTpmode=V_Value
		endif

		controlinfo hasHP
		if(V_Flag>0)
			hasHP=V_Value
		endif

		controlinfo hasVP
		if(V_Flag>0)
			hasVP=V_Value
		endif

		controlinfo hasTP
		if(V_Flag>0)
			hasTP=V_Value
		endif		
	endif
	hasHI=hasHI*(ndim>=3)
	hasVI=hasVI*(ndim>=3)
	hasZP=hasZP*(ndim>=3)
	hasTP=hasTP*(ndim==4)
	ZTpmode=ZTpmode*(ndim==4)
	variable leftstop=1-((1+hasHI*hasHP )*((hasTP+hasZP+ZTpmode)>0) + ((hasTP+hasZP+ZTpmode)==0)*(hasHP+hasHI))/4  
	variable bottomstop=1-((1+hasVI*hasVP )*((hasTP+hasZP+ZTpmode)>0) + ((hasTP+hasZP+ZTpmode)==0)*(hasVP+hasVI))/4  
	ModifyGraph axisEnab(left)={0,leftstop},axisEnab(bottom)={0,bottomstop}

//DEPENDENCY FORMULAS
	make/n=4/o/t $(df+"sarr")
	wave/t sarr=$(df+"sarr")
	sarr={"xp","yp","zp","tp"}; 	execute wv4di(w,df,"d0",sarr,dnum)
	sarr={"p","q","zp","tp"}; 		execute wv4di(w,df,"img",sarr,dnum)//; print wv4di(w,df,"img",sarr,dnum)
	sarr={"p","yp","q","tp"};		execute wv4di(w,df,"imgh",sarr,dnum)
	sarr={"xp","q","p","tp"};		execute wv4di(w,df,"imgv",sarr,dnum)
	sarr={"p","yp","zp","tp"};		execute wv4di(w,df,"px",sarr,dnum)
	sarr={"xp","p","zp","tp"};		execute wv4di(w,df,"pyx",sarr,dnum)
	sarr={"xp","yp","p","tp"};		execute wv4di(w,df,"pz",sarr,dnum)
	sarr={"xp","yp","zp","p"};		execute wv4di(w,df,"pt",sarr,dnum)
	sarr={"xp","yp","p","q"};		execute wv4di(w,df,"imgzt",sarr,dnum)
	pyy=y0+p*yd




	
	//CURSOR STUFF
	nvar xp=$(df+"xp"),  yp=$(df+"yp"), zp=$(df+"zp"), tp=$(df+"tp")
	if(isNew)
		//only set cursors to center when loading a new data or creating
		xp=xn/2; yp=yn/2; zp=zn/2; tp=tn/2
	endif
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc")
	xc=x0+xd*xp; yc=y0+yd*yp; zc=z0+zd*zp; tc=t0+td*tp;
	execute df+"xp:=("+df+"xc-"+df+"x0)/"+df+"xd"
	execute df+"yp:=("+df+"yc-"+df+"y0)/"+df+"yd"
	execute df+"zp:=("+df+"zc-"+df+"z0)/"+df+"zd"
	execute df+"tp:=("+df+"tc-"+df+"t0)/"+df+"td"
	make/o/n=(8) $(df+"hcurx"), $(df+"hcury"), $(df+"vcurx"), $(df+"vcury"),$(df+"zcurx"), $(df+"zcury"), $(df+"tcurx"), $(df+"tcury")
	wave hcurx=$(df+"hcurx"), hcury=$(df+"hcury"), vcurx=$(df+"vcurx"), vcury=$(df+"vcury")
	wave zcurx=$(df+"zcurx"), zcury=$(df+"zcury"), tcurx=$(df+"tcurx"), tcury=$(df+"tcury")
 	hcurx={-inf,inf,nan,-inf,inf,nan,-inf,inf};
 	execute df+"hcury:=setcursor("+df+"yc,"+df+"yd,"+df+"y0,"+df+"yn,"+df+"bin["+df+"img_axis[1]],"+df+"bincuropt"+num2str(dnum[1])+",p)"
	execute df+"vcurx:=setcursor("+df+"xc,"+df+"xd,"+df+"x0,"+df+"xn,"+df+"bin["+df+"img_axis[0]],"+df+"bincuropt"+num2str(dnum[0])+",p)";			vcury={-inf,inf,nan,-inf,inf,nan,-inf,inf}
	execute df+"zcurx:=setcursor("+df+"zc,"+df+"zd,"+df+"z0,"+df+"zn,"+df+"bin["+df+"imgh_axis[1]],"+df+"bincuropt"+num2str(dnum[2])+",p)";			zcury={-inf,inf,nan,-inf,inf,nan,-inf,inf}
	execute df+"tcurx:=setcursor("+df+"tc,"+df+"td,"+df+"t0,"+df+"tn,"+df+"bin["+df+"imgzt_axis[1]],"+df+"bincuropt"+num2str(dnum[3])+",p)";			tcury={-inf,inf,nan,-inf,inf,nan,-inf,inf}
	if(new)
		appendtograph hcury vs hcurx
		appendtograph vcury vs vcurx
		setupcontrols(df)
		tabproc("info",0)
	endif
	modifyRGBaxis("hcury","Y","left",16385,65535,0)
	modifyRGBaxis("vcury","Y","left",16385,65535,0)

	//adjustCTmain(df)
	
	variable/g $(df+"actmain_trig")=0
	variable/g $(df+"acth_trig")=0
	variable/g $(df+"actv_trig")=0
	variable/g $(df+"actzt_trig")=0



	ROLoadSliceState(df,"img") 

	execute df+"actmain_trig:=Imagetool5#adjustCTmain(\""+df+"\")+"+df+"img_trig"

	//			adjustCTh(df)
//			adjustCTv(df)	
//			adjustCTzt(df)
	if(isNew)
		//only set cursors to center when loading a new data or creating
		wave bin = $(df+"bin")
		bin=1	
	endif
	
	//APPEND TO GRAPH
	if(ndim>=3)
		if(hasHI)
			if(hasAxis("imghL")==0)
				appimg("/L=imghL/b=bottom", df+"imgh")
				appendtograph/l=imghl vcury vs vcurx
				appendtograph /l=imghl zcurx vs hcurx
			endif
			ModifyGraph axisEnab(imghL)={leftstop+0.05,1-0.20*(hasHP==1)},freePos(imghL)=0
			ModifyGraph lblPosmode(imghL)=1
			modifyRGBaxis("vcury","Y","imghL",16385,0,65535)
			modifyRGBaxis("zcurx","Y","imghL",16385,0,65535)
			modifyimage imgh,cindex=ct_h
			ModifyGraph btLen(imghL)=5
			ROLoadSliceState(df,"imgH") 
			execute df+"actH_trig:=Imagetool5#adjustCTh(\""+df+"\")+"+df+"imgh_trig"
		else
			//remove imgH if present
			removeimage/z imgh
			removetraceaxis("vcury","Y","imghL")
			removetraceaxis("zcurx","Y","imghL")
		endif
	
		if(hasVI)
			variable hvb=hasaxis("imgvb")
			if(hasaxis("imgvB")==0)
				appimg("/L=left/b=imgvB",df+"imgv")
				appendtograph/b=imgvB hcury vs hcurx
				appendtograph/b=imgvB Vcury vs zcurx
			endif
			modifygraph axisEnab(imgvB)={bottomstop+0.05,1-0.20*(hasVP==1)},freePos(imgvB)=0	
			ModifyGraph lblPosmode(imgVB)=1
			modifyRGBaxis("hcury","X","imgvB",16385,0,65535)
			modifyRGBaxis("vcury","X","imgvB",16385,0,65535)
			modifyimage imgv,cindex=ct_v
			ModifyGraph btLen(imgVB)=5
			ROLoadSliceState(df,"imgV") 
			execute df+"actv_trig:=Imagetool5#adjustCTv(\""+df+"\")+"+df+"imgv_trig"

			adjustCTv(df)
		else
			removeimage/z imgv
			removetraceaxis("hcury","X","imgvB")
			removetraceaxis("vcury","X","imgvB")
		endif
	else
			removeimage/z imgh
			removetraceaxis("vcury","Y","imghL")
			removetraceaxis("zcurx","Y","imghL")
			removeimage/z imgv
			removetraceaxis("hcury","X","imgvB")
			removetraceaxis("vcury","X","imgvB")
	endif
	
	if(hasHP)
		if(hasaxis("profHL")==0)
			appendtograph/l=profHL px
			appendtograph/l=profHL vcury vs vcurx
		endif
		ModifyGraph axisEnab(profHL)={leftstop+.30*(hasHI==1)+.05,1},freePos(profhL)=0
		modifyRGBaxis("vcury","Y","profHL",24000,16385,20000)
		ModifyGraph lblPosMode(profHL)=1
		ModifyGraph btLen(profHL)=5
	else
		removetraceaxis("px","Y","profHL")
		removetraceaxis("vcury","Y","profHL")
	endif
	
	if(hasVP)
		if(hasaxis("profVB")==0)
			appendtograph/b=profVB pyy vs pyx
			appendtograph/b=profvb hcury vs hcurx
		endif	
		modifygraph axisEnab(profvb)={bottomstop +.30*(hasVI==1)+.05,1},freePos(profvB)=0	
		modifyRGBaxis("hcury","X","profVB",24000,16385,20000)
		ModifyGraph lblPosMode(profvB)=1
		ModifyGraph btLen(profvB)=5
	else
		removetraceaxis("pyy","X","profVB")
		removetraceaxis("hcury","X","profVB")
	endif 
	
	if((ndim==4)*ZTPmode)	
		//get rid of image traces from UR corner if any
		removetraceaxis("pz","X","profZB")
		removetraceaxis("zcurY","X","profZB")		
		removetraceaxis("pt","X","profTB")
		removetraceaxis("tcurY","X","proTB")		
		if(hasaxis("imgZTt")==0)
			//2d image in corner
			appimg("/t=imgZTt/r=imgZTr", df +"imgzt")
			modifyimage imgzt,cindex=ct_zt
			appendtograph/t=imgZTt/r=imgZTr tcurx vs tcury
			appendtograph/t=imgZTt/r=imgZTr zcury vs zcurx		
			ModifyGraph margin(right)=36, margin(top)=36
			
		endif
		modifygraph axisEnab(imgZTt)={bottomstop+.05,1},axisenab(imgZtr)={leftstop+.05,1}
		ModifyGraph freePos(imgZTt)={inf,imgZTR}, btLen(imgZTt)=5
		ModifyGraph freePos(imgZTr)={inf,imgZTt} ,btLen(imgZTr)=5
		ModifyGraph lblPosMode(imgZTr)=1,lblPosMode(imgZTt)=1
		ROLoadSliceState(df,"imgZT") 
		execute df+"actzt_trig:=Imagetool5#adjustCTzt(\""+df+"\")+"+df+"imgzt_trig"

		adjustCTZT(df)
	else
		removetraceaxis("tcurx","Y","imgZTr")
		removetraceaxis("zcury","Y","imgZTr")
		removeimage/z imgzt
		ModifyGraph margin(right)=0, margin(top)=0

	endif
	
	if(!ZTPmode)
		if(hasZP)
			if(hasaxis("profZB")==0)
				appendtograph/t=profZB/R=profZR pz
				appendtograph/t=profZB/R=profZR zcury vs zcurx
			endif
			modifygraph axisEnab(profzb)={bottomstop+.05,1},axisenab(profZR)={leftstop+.05+0.5*(1-leftstop)*hasTP,1},freepos(profZR)={inf,profZB}
			ModifyGraph rgb(pz)=(2,39321,1)
			ModifyGraph freePos(profZB)={-inf,profZR}
			ModifyGraph rgb(zcury)=(2,39321,1)
			ModifyGraph btLen(profZR)=5,btlen(profzb)=5
		else
			//get rid of image traces from UR corner if any
			removetraceaxis("pz","X","profZB")
			removetraceaxis("zcurY","X","profZB")		
		endif
		
		if(hasTP)
			if(hasaxis("profTB")==0)
				appendtograph/t=profTB/R=profTR pt
				appendtograph/t=profTB/R=profTR tcury vs tcurx
			endif
			modifygraph axisEnab(profTb)={bottomstop+.05,1},axisenab(profTR)={leftstop+.05,1-0.5*(1-leftstop)*hasZP},freepos(profTR)=0
			ModifyGraph rgb(pt)=(52428,1,20971)
			ModifyGraph freePos(profTB)={-inf,profTR}
			ModifyGraph rgb(tcury)=(52428,1,20971)
			ModifyGraph btLen(profTR)=5,btlen(profTB)=5
		else
			removetraceaxis("pt","X","profTB")
			removetraceaxis("tcurY","X","proTB")		
		endif
	endif
	controlbar 83
	ModifyGraph fSize=10
	isNew=0
	ModifyGraph btLen=5
end

function removeall()
	string inl=imagenamelist("",","), tnl=tracenamelist("",",",1)
	execute "removeimage/z "+ inl[0,strlen(inl)-2]			//remove all images
	execute "removefromgraph/z "+  tnl[0,strlen(tnl)-2]		//remove all traces
end

Menu "GraphMarquee" , dynamic
	marqueemenus(),/Q, doImagetool5Graphmarquee()
End


function /s marqueemenus()
	string df=getdf()
	string menustr =""
	if(strsearch(df,"ImageToolV",0)>0)
		string dfn=winname(0,1)
		getmarquee 
		variable avgx=(V_left+V_right)/2
		variable avgy=(V_top+V_bottom)/2
		string imgname=whichimage(dfn,avgx,avgy)
		if(strlen(imgname)!=0)
			struct imageWaveNameStruct s
			getimageinfo(df,imgname,s)
			nvar im=$(df+s.imode)
			wave xw=$(df+s.xwv)
			
			 menustr +="Free"
			if(im==1)
				menustr+="!"+num2char(18)	
			endif
					
			if (dimsize(xw,0)>0)
				menustr +=";ROI"
				if(im==2)
					menustr += "!"+num2char(18)	
				endif
			endif
			menustr +=";Lock"
			if(im==3)
				menustr += "!"+ num2char(18)	
			endif

			menustr += ";-;Add Color ROI"
		

			if (dimsize(xw,0)>0)
				menustr += ";Replace Color ROI!;Clear Color ROI"
			endif
			
			menustr +=";-;Norm "+BINaxistitle(df,s.hindex)
			menustr +=";Norm "+BINaxistitle(df,s.vindex)	
		endif
		string Tracename=whichtrace(dfn,avgx,avgy)
		if (strlen(tracename)!=0)
			variable axis=gettraceaxis(df,tracename)
			menustr +=";Norm "+BINaxistitle(df,axis)
		endif
	endif
	return menustr
end

FUNCTION doImagetool5Graphmarquee()
	string dfn=winname(0,1)
	string df=getdf()
	getmarquee 
	variable avgx=(V_left+V_right)/2
	variable avgy=(V_top+V_bottom)/2
	string ImgName=whichimage(dfn,avgx,avgy)
	string ctrlName=imgName+"Opt"
	string tracename=whichtrace(dfn,avgx,avgy)

	variable popnum 
	string popstr=""
	GetLastUserMenuInfo
	string menustr=S_value
	strswitch(menustr)
		case "Free":
			if(strlen(ctrlName)==0)
				return 0
			endif
			 popnum = 1
			ROIColorOption(ctrlName,popNum,popStr)
			break
		case "ROI":
			if(strlen(ctrlName)==0)
				return 0
			endif
			 popnum = 2
			ROIColorOption(ctrlName,popNum,popStr)
			break
		case "Lock":
			if(strlen(ctrlName)==0)
				return 0
			endif
			 popnum = 3
			ROIColorOption(ctrlName,popNum,popStr)
			break
		case "Add Color ROI":
			if(strlen(ctrlName)==0)
				return 0
			endif
			 popnum = 5
			ROIColorOption(ctrlName,popNum,popStr)
			break
		case "Replace Color ROI":
			if(strlen(ctrlName)==0)
				return 0
			endif
			 popnum = 6
			ROIColorOption(ctrlName,popNum,popStr)
			break
		case "Clear Color ROI":
			if(strlen(ctrlName)==0)
				return 0
			endif
			 popnum = 9
			ROIColorOption(ctrlName,popNum,popStr)
		default:
			struct imageWaveNameStruct s
			getimageinfo(df,imgname,s)
			STRUCT WMPopupAction PU_Struct
			if(cmpstr(menustr,"Norm "+BINaxistitle(df,s.hindex))==0)
				PU_Struct.popnum=s.hindex+1
				PU_Struct.eventcode=2
				PU_Struct.ctrlName="cNorm1_AXIS"
				NormAxisMenu(PU_Struct)
				break
			endif
			if(cmpstr(menustr,"Norm "+BINaxistitle(df,s.vindex))==0)
				PU_Struct.popnum=s.vindex+1
				PU_Struct.ctrlName="cNorm1_AXIS"
				PU_Struct.eventcode=2
				NormAxisMenu(PU_Struct)
				break
			endif
			variable axis = gettraceaxis(df,tracename)
			if(cmpstr(menustr,"Norm "+BINaxistitle(df,axis))==0)
				PU_Struct.popnum=axis+1
				PU_Struct.ctrlName="cNorm1_AXIS"
				PU_Struct.eventcode=2
				NormAxisMenu(PU_Struct)
				break
			endif
		endswitch
			
	end
	
function img4DHookFcn(s)
	string s
	string dfn=winname(0,1); string df="root:"+dfn+":"
	string temp=getdatafolder(1)
	wave pmap=$(df+"pmap"),vimg_ct=$(df+"ct_v"), himg_ct=$(df+"ct_h"), img_ct=$(df+"ct"), ztimg_ct=$(df+"ct_zt")
	if(cmpstr(stringbykey("event",s),"kill")==0)
		vimg_ct=0; himg_ct=0; img_ct=0; ztimg_ct=0; pmap=0
		removeall()
		killallinfolder(df)
		killdatafolder $df
		return(-1)
	endif
	variable mousex,mousey,ax,ay,zx,zy,tx,ty,modif,returnval=0
	variable xc,yc,zc,tc
	nvar xcg=$(df+"xc"), ycg=$(df+"yc"), zcg=$(df+"zc"), tcg=$(df+"tc"), ndim=$(df+"ndim")

	nvar ztpmode=$(df+"ztpmode"),hasZP=$(df+"hasZP"), hasTP=$(df+"hasTP"),ndim=$(df+"ndim"),hasVI=$(df+"hasVI"),hasHI=$(df+"hasHI"),hasVP=$(df+"hasVP"),hasHP=$(df+"hasHP")
	nvar AutoScaleVP=$(df+"AutoScaleVP"),  AutoScaleHP  	=$(df+"AutoScaleHP")
	variable xcold,ycold,zcold,tcold,bool
	modif=numberByKey("modifiers",s) & 15
	//print modif
	

	if(strsearch(s,"EVENT:mouse",0)>0)
		if((modif==9)+(modif==5))
			variable axmin, axmax, aymin, aymax
			variable zxmin, zxmax, zymin, zymax
			variable txmin, txmax, tymin, tymax
			variable xcur, ycur,zcur
			variable/C coffset
			mousex=NumberByKey("mousex", s)
			mousey=NumberByKey("mousey", s)
			ay=axisvalfrompixel(dfn,"left",mousey)
			ax=axisvalfrompixel(dfn,"bottom",mousex)	
		endif
		if(modif==9)	//9 means "1001" = cmd/ctrl + mousedown
			xc=xcg;yc=ycg;zc=zcg;tc=tcg
			GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
			GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
			//print ax,  axmax, axmin, ay, aymin, aymax
			xcold=xc; ycold=yc
			xc= SelectNumber((ax>axmin)*(ax<axmax), xc, ax) 
			yc= SelectNumber((ay>aymin)*(ay<aymax), yc, ay) 
			variable updateImgColors=0
			if(((ax<axmin)+(ax>axmax))*(ndim>=3)*hasVI*((ay>aymin)*(ay<aymax)))
				// mouse is in VI
				zx=axisvalfrompixel(dfn,"imgvB",mousex)
				getaxis/q imgvB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
				if((zx>zxmin)*(zx<zxmax))
					zc=zx
				endif
			endif
			if(((ay<aymin)+(ay>aymax))*(ndim>=3)*hasHI*((ax>axmin)*(ax<axmax)))
			      //mouse in HI
				zx=axisvalfrompixel(dfn,"imgHL",mousey)
				getaxis/q imgHL; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
				if((zx>zxmin)*(zx<zxmax))
					zc=zx
				endif
			endif
			if(((ax<axmin)+(ax>axmax))*((ay<aymin)+(ay>aymax))*(ndim>=3))
				//mouse must be in z, t profile area
				updateImgColors=1
				if(ndim==3)
					//mouse must be in z profile
					zx=axisvalfrompixel(dfn,"profZB",mousex)
					getaxis/q profZB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
					zc=selectnumber((zx>zxmin)*(zx<zxmax),zc,zx)
				else
					//must must point to zc or tc axis or zt image
					if(ztpmode)
						//upper right corner is showing image
						getaxis/q imgztt; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
						GetAxis/Q imgztr; tymin=min(V_max, V_min);tymax=max(V_min, V_max)
						ay=axisvalfrompixel(dfn,"imgztr",mousey)
						ax=axisvalfrompixel(dfn,"imgZTt",mousex)
						//print ax,ay,zxmin,zxmax,tymin,tymax
						zc=selectnumber((ax>zxmin)*(ax<zxmax)*(ay>tymin)*(ay<tymax), zc, ax)
						tc=selectnumber((ax>zxmin)*(ax<zxmax)*(ay>tymin)*(ay<tymax), tc, ay)
					else
						//upper right corner is showing traces
						if(hasZP)
							//z or t axis
							zcold=zc
							zx=axisvalfrompixel(dfn,"profZB",mousex)
							zy=axisvalfrompixel(dfn,"profZR",mousey)
							getaxis/q profZB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
							getaxis/q profZR; zymin=min(V_max, V_min); zymax=max(V_min, V_max)
							//print zx,zxmin,zxmax,">>>",zy,zymin,zymax
							bool=(zx>zxmin)*(zx<zxmax)*(zy>zymin)*(zy<zymax) //1 means z axis, 0 mean t axis
							zc=selectnumber(bool,zc,zx)
						endif
						if((zcold==zc)*(hasTP))
							//t axis only
							tx=axisvalfrompixel(dfn,"profTB",mousex)
							ty=axisvalfrompixel(dfn,"profTR",mousey)
							getaxis/q profTB; txmin=min(V_max, V_min); txmax=max(V_min, V_max)
							getaxis/q profTR; tymin=min(V_max, V_min); tymax=max(V_min, V_max)
							//print tx,txmin,txmax,"|||",ty,tymin,tymax
							tc=selectnumber((tx>txmin)*(tx<txmax)*(ty>tymin)*(ty<tymax),tc,tx)	
						endif
					endif //ztpmode
				ENDIF //ndim>=3
			endif
			if (xcg!=xc)
				xcg=xc
			endif
			if (ycg!=yc)
				ycg=yc
			endif
			if (zcg!=zc)
				zcg=zc
			endif
			if (tcg!=tc)
				tcg=tc
			endif
			returnval=1
		endif
		if((modif==9)+(modif==5))
			doupdate
//			adjustCTmain(df)
//			adjustCTh(df)
//			adjustCTv(df)	
//			adjustCTzt(df)
			if(hasHP*AutoScaleHP)
				AutoscaleInRange("profHL","bottom",1)
			endif
			if(hasVP*AutoScaleVP)
				AutoscaleInRange("left","profVB",2)
			endif
		endif
	endif
	return returnval
end	

 function adjustCTmain(df)
	string df
	wave img=$(df+"img"), imgROI=$(df+"imgROI")
	 string ctrlName="imgOPT"
	 struct imageWaveNameStruct s
	ROIGetStrings(df,ctrlName,s)
	wave xw=$(df+s.xwv)
	wave ct=$(df+"ct")
	nvar ict=$(df+"invertct")
	nvar im=$(df+s.imode)
	if(im!=3)
	if((im==2)*(numpnts(xw)>0))
		imagestats/M=1 /r=imgROI img
	else
		imagestats /M=1 img
	endif
	setscale/i x v_min,v_max,ct
	endif
end

static function adjustCTh(df)
	string df
	wave imgh=$(df+"imgh"), imgHROI=$(df+"imgHROI"), ct_h=$(df+"ct_h")
	nvar ict=$(df+"invertct"),hasHI=$(df+"hasHI")
	if(hasHI)
		struct imageWaveNameStruct s
		string ctrlName="imgHOPT"
		ROIGetStrings(df,ctrlName,s)
		nvar im=$(df+s.imode)
		if(im!=3)
			wave xw=$(df+s.xwv)
			if((im==2)*(numpnts(xw)>0))
				imagestats /M=1 /r=imgHROI imgH
			else
				imagestats /M=1 imgH
			endif
			setscale/i x v_min, v_max,ct_h
		endif
	endif
end

static function adjustCTv(df)
	string df
	wave imgv=$(df+"imgv"), imgVROI=$(df+"imgVROI"),ct_v=$(df+"ct_v")
	nvar ict=$(df+"invertct"),hasVI=$(df+"hasVI")
	if(hasVI)
		struct imageWaveNameStruct s
		string ctrlName="imgVOPT"
		ROIGetStrings(df,ctrlName,s)
		nvar im=$(df+s.imode)
		if (im!=3)
			wave xw=$(df+s.xwv)
			if((im==2)*(numpnts(xw)>0))
				imagestats/M=1 /r=imgVROI imgV
			else
				imagestats /M=1 imgV
			endif
			setscale/i x v_min, v_max,ct_v	
		endif
	endif
end

static function adjustCTzt(df)
	string df
	wave imgzt=$(df+"imgzt"), imgZTROI=$(df+"imgZTROI"),ct_zt=$(df+"ct_zt")
	nvar ict=$(df+"invertct"),ztpmode=$(df+"ztpmode"),hasTP=$(df+"hasTP")
	if(Ztpmode)
		struct imageWaveNameStruct s
		string ctrlName="imgZTOPT"
		ROIGetStrings(df,ctrlName,s)
		nvar im=$(df+s.imode)
		if(im!=3)
			wave xw=$(df+s.xwv)
			if((im==2)*(numpnts(xw)>0))
				imagestats /M=1 /r=imgZTROI imgZT
			else
				imagestats /M=1 imgZT
			endif
			setscale/i x v_min, v_max,ct_zt	
		endif
	endif
end

Function selectCTList(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	nvar  whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"),whichCTv=$(df+"whichCTv"),whichCTzt=$(df+"whichCTzt")
	whichCT=popnum-1
	whichCTh=popnum-1
	whichCTv=popnum-1
	whichCTzt=popnum-1
End

Function AnimateProc(ctrlName) : ButtonControl
	String ctrlName
	string df=getdf()
	variable numAxes=1, axis0,mode0=1,range0=1,axis1,mode1=1,range1=1,axis2,mode2=1,range2=1,axis3,mode3=1,range3=1
	variable a0,a1,ad,b0,b1,bd,c0,c1,cd,d0,d1,dd
	string axisP="Which axis to animate? ", axisM="X;Y;Z;T"
	string rangeP="Animation Range? ", rangeM="all;limited"
	string modeP="Animation Mode? ", modeM="once;up and down"

	prompt numAxes,"Number of axes to animate",popup "1;2;3;4"

	prompt axis0,axisP,popup axisM
	prompt range0, rangeP, popup RangeM
	prompt mode0,modeP,popup modeM
	prompt a0,"a0"	
	prompt a1,"a1"
	
	prompt axis1,axisP+"#2",popup axisM
	prompt range1, rangeP+"#2", popup RangeM
	prompt mode1,modeP+"#2",popup modeM
	prompt b0,"b0"	
	prompt b1,"b1"

	prompt axis2,axisP+"#3",popup axisM
	prompt range2, rangeP+"#3", popup RangeM
	prompt mode2,modeP+"#3",popup modeM
	prompt c0,"c0"	
	prompt c1,"c1"

	prompt axis3,axisP+"#4",popup axisM
	prompt range3, rangeP+"#4", popup RangeM
	prompt mode3,modeP+"#4",popup modeM
	prompt d0,"d0"	
	prompt d1,"d1"

	doprompt "Animate",numaxes,axis0,mode0,range0
	if(v_flag)
		return 0	//cancelled
	endif
	switch(numaxes)	// numeric switch
		case 2:		// execute if case matches expression
			doprompt "Enter Additional Axes",axis1,mode1,range1
			break
		case 3:
			doprompt "Enter Additional Axes",axis1,mode1,range1,axis2,mode2,range2
			break
		case 4:
			doprompt "Enter Additional Axes",axis1,mode1,range1,axis2,mode2,range2,axis3,mode3,range3
			break
	endswitch
	variable doit=0
	if (range0==1)
		a0=getleft(df,axis0); a1=a0+getwid(df,axis0); ad=getdelta(df,axis0)
	else
		a0=getleft(df,axis0); a1=a0+getwid(df,axis0); ad=getdelta(df,axis0)
		doit+=1
	endif
	if (range1==1)
		b0=getleft(df,axis1); b1=b0+getwid(df,axis1); bd=getdelta(df,axis1)
	else
		b0=getleft(df,axis1); b1=b0+getwid(df,axis1); bd=getdelta(df,axis1)
		doit+=1
	endif
	if (range2==1)
		c0=getleft(df,axis2); c1=c0+getwid(df,axis2); cd=getdelta(df,axis2)
	else
		c0=getleft(df,axis2); c1=c0+getwid(df,axis2); cd=getdelta(df,axis2)
		doit+=1
	endif
	if (range3==1)
		d0=getleft(df,axis3); d1=d0+getwid(df,axis3); dd=getdelta(df,axis3)
	else 
		d0=getleft(df,axis3); d1=d0+getwid(df,axis3); dd=getdelta(df,axis3)
		doit+=1
	endif
	
	sort2(a0,a1,ad); sort2(b0,b1,bd); sort2(c0,c1,cd); sort2(d0,d1,dd)
	
	if(doit)
		switch(numaxes)	// numeric switch
			case 1:
				doprompt "Enter Axes Limits",a0,a1
				break
			case 2:		// execute if case matches expression
				doprompt "Enter Axes Limits",a0,a1,b0,b1
				break
			case 3:
				doprompt "Enter Axes Limits",a0,a1,b0,b1,c0,c1
				break
			case 4:
				doprompt "Enter Axes Limits",a0,a1,b0,b1,c0,c1,d0,d1
				break
		endswitch
	endif
	make/o/n=4 $(df+"axisArr")={axis0,axis1,axis2,axis3}; wave axisarr=$(df+"axisarr")
	make/o/n=4 $(df+"a0Arr")={a0,b0,c0,d0}; wave a0arr=$(df+"a0arr")
	make/o/n=4 $(df+"a1Arr")={a1,b1,c1,d1}; wave a1arr=$(df+"a1arr")
	make/o/n=4 $(df+"adArr")={ad,bd,cd,dd}; wave adarr=$(df+"adarr")
	make/o/n=4 $(df+"modeArr")={mode0,mode1,mode2,mode3}; wave modeArr=$(df+"modeArr")
	newmovie/f=10/L/I
	variable region,rr
	for(region=0; region<numAxes; region+=1)
		switch(axisArr[region])
			case 1:
				nvar r=$(df+"xc")
				break
			case 2:
				nvar r=$(df+"yc")
				break
			case 3:
				nvar r=$(df+"zc")
				break
			case 4:
				nvar r=$(df+"tc")
				break
		endswitch
		for(r=a0arr[region];  r<=a1arr[region];r+=adarr[region])
			adjustCTmain(df); adjustCTh(df); adjustCTv(df)	; adjustCTzt(df)
			execute "doupdate"
			//print r
			addmovieframe
		endfor
		if(modearr[region]==2)
			for(r=a1arr[region]-adarr[region];  r>=a0arr[region];r-=adarr[region])
				adjustCTmain(df); adjustCTh(df); adjustCTv(df)	; adjustCTzt(df)
				execute "doupdate"
				//print r
				addmovieframe
			endfor
		endif
	endfor
	closemovie
End

static function sort2(x,y,d)
	variable &x,&y,&d
	variable t
	if(y<x)
		d*=-1
		t=x
		x=y
		y=t
	endif
end

 function getleft(df,which)
	string df		//data folder
	variable which	//1=x, 2=y, 3=z, 4=t
	wave img=$(df+"img"), pz=$(df+"pz"), pt=$(df+"pt")
	switch(which)
		case 1:
			return dimoffset(img,0)
			break
		case 2:
			return dimoffset(img,1)
		case 3:
			return dimoffset(pz,0)
		case 4:
			return dimoffset(pt,0)
			break
	endswitch
end

 function getwid(df,which)
	string df		//data folder
	variable which	//1=x, 2=y, 3=z, 4=t
	wave img=$(df+"img"), pz=$(df+"pz"), pt=$(df+"pt")
	switch(which)
		case 1:
			return dimdelta(img,0)*(dimsize(img,0)-1)
			break
		case 2:
			return dimdelta(img,1)*(dimsize(img,1)-1)
		case 3:
			return dimdelta(pz,0)*(dimsize(pz,0)-1)
		case 4:
			return dimdelta(pt,0)*(dimsize(pt,0)-1)
			break
	endswitch
end

static function getdelta(df,which)
	string df		//data folder
	variable which	//1=x, 2=y, 3=z, 4=t
	wave img=$(df+"img"), pz=$(df+"pz"), pt=$(df+"pt")
	switch(which)
		case 1:
			return dimdelta(img,0)
			break
		case 2:
			return dimdelta(img,1)
		case 3:
			return dimdelta(pz,0)
		case 4:
			return dimdelta(pt,0)
			break
	endswitch
end

Function ExportList(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	execute "doExportList(\"" + df + "\",\"" + popstr+"\",,)"
End

proc doExportList(df,popstr,name,dep)
	string df,popstr,name
	variable dep=1//,app=1
	prompt name,"name to export"
	prompt dep,"Dependency option",popup "free;keep dependency"
	//prompt app,"Display option",popup "display;append;none"
	dep-=1
	if(cmpstr("X-wave",popstr)==0)
		duplicate/o $(df+"px") $("root:"+name)
		if(app==1)
			append $name
		endif
		if(!dep)
			setformula $name ""
		endif
		abort
	endif
	
	if(cmpstr("Y-wave",popstr)==0)
		duplicate/o $(df+"pyx") $name
		setscale/p x $(df+"pyy")[0], $(df+"pyy")[1]-$(df+"pyy")[0], waveunits($(df+"img"),1-$(df+"transxy")), $name
		display $name
		if(!dep)
			setformula $name ""
		endif
		abort
	endif
	
	if(cmpstr("Z-wave",popstr)==0)
		if($(df+"ndim")>=3)		
			duplicate/o $(df+"pz") $("root:"+name)
			display $name
			if(!dep)
				setformula $name ""
			endif
			abort
		else
			abort "Sorry, must be >= 3 dimensions"
		endif
	endif
	
	if(cmpstr("T-wave",popstr)==0)
		if($(df+"ndim")==4)
			duplicate/o $(df+"pt") $("root:"+name)
			display $name
			if(!dep)
				setformula $name ""
			endif
			abort
		else
			abort 
		endif
	endif
	
	if(cmpstr("H-image",popstr)==0)
		duplicate/o $(df+"imgh") $("root:"+name)
		duplicate/o $(df+"ct_h") $("root:"+name+"_ct")
		display; appendimage $name
		ModifyImage $name cindex= $(name+"_ct")
		if(!dep)
			setformula $name ""
		endif
	
		abort
	endif
	
	if(cmpstr("V-image",popstr)==0)
		duplicate/o $(df+"imgV") $("root:"+name)
		duplicate/o $(df+"ct_v") $("root:"+name+"_ct")
		display; appendimage $name
		ModifyImage $name cindex= $(name+"_ct")
		if(!dep)
			setformula $name ""
		endif

		abort
	endif
	
	if(cmpstr("Main Image",popstr)==0)
		duplicate/o $(df+"img") $("root:"+name)
		duplicate/o $(df+"ct") $("root:"+name+"_ct")
		display; appendimage $name
		ModifyImage $name cindex= $(name+"_ct")
		if(!dep)
			setformula $name ""
		endif
		abort
	endif
	
	if(cmpstr("Corner Image",popstr)==0)
		if($(df+"ndim")==4)
		else
			abort "Sorry, only for 4 dimensional data")
		endif
		duplicate/o $(df+"imgzt") $("root:"+name)
		duplicate/o $(df+"ct_zt") $("root:"+name+"_ct")
		display; appendimage $name
		ModifyImage $name cindex= $(name+"_ct")
		if(!dep)
			setformula $name ""
		endif
		abort
	endif		
	
end


static function/s getdf()
	return "root:"+getdfname()+":"
end

static function/s getdfname()
	return winname(0,1)
end


Function SetPCursor(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			string df ="root:"+sva.win+":"
		//	(root:ImageToolV0:xc-root:ImageToolV0:x0)/root:ImageToolV0:xd
			strswitch ( sva.ctrlName)
			case "SetXP":
				nvar xc=$(df+"xc")
				nvar x0=$(df+"x0")
				nvar xd=$(df+"xd")
				xc=x0+dval*xd
				break
			case "SetYP":
				nvar yc=$(df+"yc")
				nvar y0=$(df+"y0")
				nvar yd=$(df+"yd")
				yc=y0+dval*yd
				break	
			case "SetZP":
				nvar zc=$(df+"zc")
				nvar z0=$(df+"z0")
				nvar zd=$(df+"zd")
				zc=z0+dval*zd
				break
			case "SetTP":
				nvar tc=$(df+"tc")
				nvar t0=$(df+"t0")
				nvar td=$(df+"td")
				tc=t0+dval*td
				break			
			endswitch		
	endswitch
	return 0
End

Function CheckBoxProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	string df=getdf()
	nvar sv=$(df+ctrlname)
	svar dname=$(df+"dname")
	sv=checked
	setupV(getdfname(),dname)
End

Function dim34setproc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	svar dname=$(df+"dname")
	nvar sv=$(df+ctrlname)
	string other=selectstring(cmpstr(ctrlname,"dim3index")==0,"dim3index","dim4index")
	nvar svother=$(df+other)
	variable svstore=sv
	sv=popnum-1
	if (sv==svother)
		//dimension #3 is same as dimension#4 --assume you want to transpose
		svother=svstore
	endif
	setupV(getdfname(),dname)
	setupdim34value(df,ctrlname,sv)
	setupdim34value(df,other,svother)
End



function LoadNewImgV(ctrlName) : ButtonControl
	string ctrlName
	string df=getdf()
	String wn=StrVarOrDefault(df+"dname","")
	prompt wn, "New array", popup, "; -- 4D --;"+WaveList("!*_CT",";","DIMS:4")+"; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")+"; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	DoPrompt "Select 2D Image (or 3D volume)" wn
	if (V_flag==1)
		abort		//cancelled
	endif
	//makeVariables(getdfname())
	NVAR isnew=$(df+"isnew")
	variable version
	if(exists((df+"ver"))==2)
		NVAR ver=$(df+"ver")
		version=ver
	else
		version=0
	endif
//	if(ver!=MAJOR_VERSION)  //old version rebuild window completley
//			string dfn=getdfname()
//			dowindow /K $dfn
//			newimagetool5(wn)
//			return 0
//	endif
	string w=wn
	if(strsearch(w,"root:",0)<0)
		wn=getdatafolder(1)+w
		WAVE wv=$wn
		if(waveexists(wv)==0)
			wn="root+"+w
			WAVE wv=$wn
			if(waveexists(wv)==0)
				return -1
			else
				w=wn
			endif
		else
			w=wn
		endif
	endif
	WAVE wv=$w
	if(waveexists(wv)==0)
		return -1
	endif
	isnew=1
	tabcontrol tab0, value=0
	tabproc("",0)
	setupV(getdfname(),wn)
end

function/S whichimage(wn,px,py)
	string wn
	variable px,py 
	variable axmin, axmax, aymin, aymax
	variable	ay=axisvalfrompixel(wn,"left",py)
	variable	ax=axisvalfrompixel(wn,"bottom",px)	
	GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	if( (ax<axmax) && (ax>axmin) && (ay<aymax) && (ay>aymin))
		return "img"
	elseif(ax<axmax&&ax>axmin)
		GetAxis/Q imgHL; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
		ay=axisvalfrompixel(wn,"imgHL",py)
		if(ay<aymax&&ay>aymin)
		return "imgH"
		endif
	elseif(ay<aymax&&ay>aymin)
		GetAxis/Q imgVb; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
		ax=axisvalfrompixel(wn,"imgVB",px)
		if(ax<axmax&&ax>axmin)
		return "imgV"
		endif
	endif	
	getaxis/q imgztr; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	GetAxis/Q imgztt; axmin=min(V_max, V_min);axmax=max(V_min, V_max)
	ay=axisvalfrompixel(wn,"imgztr",py)
	ax=axisvalfrompixel(wn,"imgZTt",px)
	if(ax<axmax&&ax>axmin)
		if(ay<aymax&&ay>aymin)
		return "imgZT"
		endif
	endif
	return ""
end

function/S whichtrace(wn,px,py)
	string wn
	variable px,py 
	variable axmin, axmax, aymin, aymax
	variable	ax=axisvalfrompixel(wn,"bottom",px)	
	variable	ay=axisvalfrompixel(wn,"profHL",py)
	GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	GetAxis/Q profHL; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	if( (ax<axmax) &&  (ax>axmin) && (ay<aymax) &&  (ay>aymin))
		return "HProf"
	endif
	ax=axisvalfrompixel(wn,"profVB",px)	
	ay=axisvalfrompixel(wn,"left",py)
	GetAxis/Q profVB; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	if( (ax<axmax) && (ax>axmin) && (ay<aymax) && (ay>aymin))
		return "VProf"
	endif
	
	ax=axisvalfrompixel(wn,"profZB",px)
	ay=axisvalfrompixel(wn,"profZR",py)
	getaxis/q profZB; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	getaxis/q profZR; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	if( (ax<axmax) && (ax>axmin) && (ay<aymax) && (ay>aymin))
		return "ZProf"
	endif		
			
	ax=axisvalfrompixel(wn,"profTB",px)
	ay=axisvalfrompixel(wn,"profTR",py)
	getaxis/q profTB; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	getaxis/q profTR; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	if( (ax<axmax) && (ax>axmin) && (ay<aymax) && (ay>aymin))
		return "TProf"
	endif	
	return ""			
end














// *** Stack Procs and Functions *****


///=====
//get the stack window name for a given imagetool df folder, supports the lagacy imagetool->STACK_.
static function /S stack_getswn(df)
	string df
	string dfn=stringfromlist(1,df,":")
	variable snum
	sscanf dfn ,"ImageToolV %i", snum
	return  "STACKV"+num2istr(snum)
end


//=========
//get image tool data folder from topmost window name of a stack window, supports the lagacy STACK_->ImageTool
static function /S stack_getdf()
	string df = getdf()
	string dfn=stringfromlist(1,df,":")
	variable snum
	sscanf dfn ,"STACKV %i", snum
	return  "root:ImageToolV"+num2istr(snum)+":"
end

//================
Function Stack_UpdateStackV(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: 
			String ctrlName
	
			string df=getdf(), curr=GetDataFolder(1)
			string dfn=stringfromlist(1,df,":")
			string swn=stack_getswn(df)
			string sdf=df+"Stack"
			if (!DataFolderExists(sdf))
				newdatafolder /o $sdf
				
				variable /g $(df+"STACK:dmax")=1
				variable /g $(df+"STACK:dmin")=0
				variable /g $(df+"STACK:xmin")=0
				variable /g $(df+"STACK:xinc")=0
				variable /g $(df+"STACK:ymin")=0
				variable /g $(df+"STACK:yinc")=0
				variable /g $(df+"STACK:shift")=0
				variable /g $(df+"STACK:shift")=0
				variable /g $(df+"STACK:offset")=0
				variable /g $(df+"STACK:pinc")
				string /g $(df+"STACK:basen")
				string /g $(df+"STACK:exporti_nam")
			endif
			string wn
			//	SetDataFolder root:IMG
			WAVE img=$(df+"Img")

			//** use only subset from marquee or current graph axes	
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
			Duplicate/O/R=(x1,x2)(y1,y2) img, $(df+"Stack:Image")

			WAVE imgstack=$(df+"Stack:Image")
			NVAR pinc=$(df+"STACK:pinc")

			WaveStats/Q imgstack
			//	print V_min, V_max
			variable/G $(df+"STACK:dmin")=V_min, $(df+"STACK:dmax")=V_max 
	
			string basen=df+"STACK:line"
			variable nw, nx, dir=0
			//nw=ItemsInList( Img2Waves( imgstack, basen, dir ), ";")
			nw=Image2Waves( imgstack, basen, dir, pinc )
			nx=DimSize($(df+"STACK:Image"), 0)
			variable/G $(df+"STACK:ymin")=y1, $(df+"STACK:yinc")=(y2-y1)/(nw-1)
			variable/G $(df+"STACK:xmin")=x1 , $(df+"STACK:xinc")=(x2-x1)/(nx-1)

			string trace_lst=""
			variable nt=0
			DoWindow/F $swn // Stack_
			if (V_flag==0)
				StackV_(df)
				dowindow /c $SWN
				If (!stringmatch( IgorInfo(2), "Macintosh") )
					//Display /W=(219,250,540,600)
					// Windows: scale window width smaller by 72/96Å0.75
					MoveWindow 219,250,219+(540-219)*0.7,600
				endif
			endif
			trace_lst=TraceNameList(swn,";",1 )
			nt=ItemsInList(trace_lst,";")
			//	print nw, nt
	
			variable ii
			if (nw>nt)				//plot additional waves
				ii=nt
				DO
					AppendToGraph $(basen+num2istr(ii))
					ii+=1
				WHILE( ii<nw )
			endif
	
			if (nw<nt)				//remove extra waves
				ii=nw
				DO
					//			RemoveFromGraph $(basen+num2istr(ii))
					RemoveFromGraph $StrFromList(trace_lst,ii, ";")
					
					wn = StrFromList(trace_lst,ii, ";")
					killwaves $(df+"STACK:"+wn)
					ii+=1
				WHILE( ii<nt )
			endif
	
			SVAR imgnam=$(df+"dname")
			DoWindow/T $swn, swn+": "+imgnam
	
			NVAR dmax=$(df+"STACK:dmax"), dmin=$(df+"STACK:dmin")
			variable shiftinc=DimDelta(imgstack,0), offsetinc, exp
			offsetinc=0.1*(dmax-dmin)
			exp=10^floor( log(offsetinc) )
			offsetinc=round( offsetinc / exp) * exp
			//	print offsetinc, exp
			SetVariable setshift limits={-Inf,Inf, shiftinc}
			SetVariable setoffset limits={-Inf,Inf, offsetinc}
			NVAR shift=$(df+"STACK:shift"),  offset=$(df+"STACK:offset")
			shift=0
			offset=offsetinc*(1-2*(offset<0))		//preserve previous sign of offset
			OffsetStack( shift, offset)
	
			SetDataFolder curr
			
			break
	endswitch
End


Static Function SetOffset(ctrlName,varNum,varStr,varName) : SetVariableControl
//---------------
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string df=stack_getdf()
	NVAR shift =$(df+"STACK:shift")
	NVAR offset =$(df+"STACK:offset")
	if (cmpstr(ctrlName,"setShift")==0)
	
		shift = varNum
	else
		offset=varNum
	endif
	
	OffsetStack(shift,offset)
End

Static Function MoveCursor(ctrlName) : ButtonControl
//------------
	String ctrlName
	//root:IMG:STACK:offset=0.5*(root:IMG:STACK:dmax-root:IMG:STACK:dmin)
	//OffsetStack( root:IMG:STACK:shift, root:IMG:STACK:offset)
	string df=stack_getdf()
	string dfn=stringfromlist(1,df,":")
	variable xcur=xcsr(A), ycur
	if ( numtype(xcur)==0 ) 
		NVAR ymin=$(df+"STACK:ymin") 
		NVAR yinc= $(df+"STACK:yinc") 
		string wvn=CsrWave(A)
		ycur=ymin
		ycur +=yinc * str2num( wvn[4,strlen(wvn)-1] )
		DoWindow/F $dfn
		ModifyGraph offset(HairY0)={xcur, ycur}
		WAVE image = $(df+"Image")
		Cursor/P A, profileH, round((xcur - DimOffset(Image, 0))/DimDelta(Image,0))
		Cursor/P B, profileV_y, round((ycur - DimOffset(Image, 1))/DimDelta(Image,1))
	endif
End

Static Function OffsetStack( shift, offset )
//================
	Variable shift, offset
	
	//string trace_lst=TraceNameList("",";",1 )
	string df=stack_getdf(), curr=GetDataFolder(1)
	setdatafolder $(df+"stack:")
	string trace_lst=wavelist("line*",";","")
	setdatafolder curr

	variable nt=ItemsInList(trace_lst,";")
//	print nt
	
	variable ii=0
	string wn, cmd
	DO
		wn=StrFromList(trace_lst, ii, ";")
		//print wn
		WAVE w=wn
//		ModifyGraph offset(wn)={ii*shift, ii*offset}
		cmd="ModifyGraph offset("+wn+")={"+num2str(ii*shift)+", "+num2str(ii*offset)+"}"
		execute cmd
		ii+=1
	WHILE( ii<nt )

	return nt
End


// No longer necessary with DoPrompt feature inside a function
//Proc StackName( stacknam )
//------------
//	String stacknam=StrVarOrDefault( "root:IMG:STACK:basen", root:IMG:imgnam )
//	prompt stacknam, "Export Stack Base Name"
//	
//	string/G root:IMG:STACK:basen=stacknam
//End

static Function ExportStackFct(ctrlName) : ButtonControl
//======================
	String ctrlName
	
	String df=stack_getdf()
	String basen=StrVarOrDefault( df+"STACK:basen", "base")
	Prompt basen, "Stack base name"
	DoPrompt "Export Stack", basen
	if (V_flag==1)
		abort		// Cancel selected
	endif
	string/G $(df+"STACK:basen")=basen
	
	SetDataFolder root:

	SVAR imgn=$(df+"dname")
	NVAR shift=$(df+"STACK:shift"), offset=$(df+"STACK:offset")
	NVAR xmin=$(df+"STACK:xmin"), xinc=$(df+"STACK:xinc")
	
	string trace_lst=TraceNameList(stack_getswn(df),";",1 )
	variable nt=ItemsInList(trace_lst,";")

	Display			// open empty plot
	PauseUpdate; Silent 1
	string tn, wn, tval, wnote
	variable ii=0, yval
	DO
		tn=df+"STACK:"+StrFromList(trace_lst, ii, ";")
		//print tn
		yval=NumberByKey( "VAL", note($tn), "=", ",")		// get y-axis value
		wn=basen+num2istr(ii)
		duplicate/o $tn $wn
		WAVE wv=$wn
		wv+=offset*ii
		SetScale/P x xmin+shift*ii, xinc,"" wv
		//SetScale/P x DimOffset($tn,0),DimDelta($tn,0),"" wv
		Write_Mod(wv, shift*ii, offset*ii, 1, 0, 0.5, 0, yval, imgn)
		AppendToGraph wv
		ii+=1
	WHILE( ii<nt )
	
	string winnam=(basen+"_Stack")
	DoWindow/F $winnam
	if (V_Flag==1)
		DoWindow/K $winnam
	endif
	DoWindow/C $winnam
End

function StackV_(df) 
	string df
	String fldrSav= GetDataFolder(1)

	SetDataFolder $(df+"STACK:")
	Display /K=1 /W=(219,250,540,600) line0 as "Stack_: BI"
	SetDataFolder fldrSav
	ModifyGraph cbRGB=(32769,65535,32768)
	
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=2
	ModifyGraph mirror=1
	ModifyGraph minor=1
	ModifyGraph sep(left)=8,sep(bottom)=10
	ModifyGraph fSize=10
	ShowInfo
	ControlBar 21
	SetVariable setshift,pos={6,2},size={80,14},proc=imagetool5#SetOffset,title="shift"
	SetVariable setshift,help={"Incremental X shift of spectra."},fSize=10
	SetVariable setshift,limits={-Inf,Inf,0.002},value= $(df+"STACK:shift")
	SetVariable setoffset,pos={90,2},size={90,14},proc=imagetool5#SetOffset,title="offset"
	SetVariable setoffset,help={"Incremental Y offset of spectra."},fSize=10
	SetVariable setoffset,limits={-Inf,Inf,0.2},value= $(df+"STACK:offset")
	Button MoveImgCsr,pos={188,1},size={35,16},proc=imagetool5#MoveCursor,title="Csr"
	Button MoveImgCsr,help={"Reposition cross-hair in Image_Tool panel to the location of the A cursor placed in the Stack_ window."}
	Button ExportStack,pos={233,1},size={50,16},proc=imagetool5#ExportStackFct,title="Export"
	Button ExportStack,help={"Copy stack spectra to a new window with a specified basename.  Wave notes contain appropriate shift, offset, and Y-value information."}
End
