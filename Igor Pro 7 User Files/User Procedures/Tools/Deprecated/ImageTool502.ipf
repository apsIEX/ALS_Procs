#pragma rtGlobals=1		// Use modern global access method.
#pragma rtGlobals=1		// Use modern global access method.

function makeData()
	make/o/n=(30,35,40,45) data 	//[theta][energy][beta][k]
	wave data=data
	setscale/i x -.75,2.5,"kx",data
	setscale/i y -1.8,0.2,"ky",data
	setscale/i z -.5,1,"kz",data
	setscale/i t -4.3,7.4,"kt",data
	
	data=1/((y-(20+10*z)*((x)^2-.05))^2+(t/20)^2)
end

macro newImageTool5(w)
	string w
	silent 1; pauseupdate
	string dfn=uniquename("ImageToolV",11,0)
	newdatafolder/o $dfn
	makeVariables(dfn)
	setupV(dfn,w)
end

function makeVariables(dfn)
	string dfn
	string df="root:"+dfn+":"
	variable/g $(df+"x0"),	$(df+"xd"), $(df+"xn"), $(df+"x1")
	variable/g $(df+"y0"), $(df+"yd"), $(df+"yn"), $(df+"y1")	
	variable/g $(df+"z0"),	$(df+"zd"), $(df+"zn"), $(df+"z1")
	variable/g $(df+"t0"), 	$(df+"td"), $(df+"tn"), $(df+"t1")
	variable/g $(df+"hasHI")=1, $(df+"hasHP")=1					//default: image slices ON, profiles ON
	variable/g $(df+"hasVI")=1,$(df+"hasVP")=1
	variable/g $(df+"hasZP")
	variable/g $(df+"hasTP")
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
	make/n=256/o $(df+"pmap")
	variable/g $(df+"whichCT")=0
	variable/g $(df+"invertCT")=0
end

function/s appendDF(df,s)
	string df,s
	if ((cmpstr(s,"p")==0) +(cmpstr(s,"q")==0) + (cmpstr(s,"r")==0) + (cmpstr(s,"s")==0))
		return s
	else
		return df+s
	endif
end

function/s wv4d(wv,df,wvout,a,b,c,d)
	string wv,df,wvout,a,b,c,d
	a=appendDF(df,a); b=appendDF(df,b); c=appendDF(df,c); d=appendDF(df,d)
	return df+wvout + ":=" + "root:"+ wv + "[" + a + "][" + b + "][" + c +"][" + d +"]"
end

//for setting up equations like wvout:=wv[a][b][c][d]
//where a,b,c,d are elements of string array sarr
//scrambled according to indices in iarr
//and if strings are not equal to "p","q", "r", "s" then they are names of variables so prefix df=datafolder to them
function/s wv4di(wv,df,wvout,sarr,iarr)
	string wv,df,wvout
	wave/t sarr
	wave iarr
	sarr[iarr[0]]=appendDF(df,sarr[iarr[0]])
	sarr[iarr[1]]=appendDF(df,sarr[iarr[1]])
	sarr[iarr[2]]=appendDF(df,sarr[iarr[2]])
	sarr[iarr[3]]=appendDF(df,sarr[iarr[3]])	
	//a=appendDF(df,a); b=appendDF(df,b); c=appendDF(df,c); d=appendDF(df,d)
	return df+wvout + ":=" + "root:"+ wv + "[" + sarr[iarr[0]] + "][" + sarr[iarr[1]] + "][" + sarr[iarr[2]] +"][" + sarr[iarr[3]] +"]"
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
	make/n=4/o q34w,$(df+"dnum")
	wave dnum=$(df+"dnum")
	q34w={0,1,2,3}
	dnum=q34w
	q34w[d3i]=100
	q34w[d4i]=101
	sort q34w,q34w,dnum
	killwaves q34w
	//now 1st 2 indices are H and V axes of main image
	variable temp
	if(txy)
		temp=dnum[0]
		dnum[0]=dnum[1]
		dnum[1]=temp		
	endif
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

function setupcontrols(df)
	string df
	tabcontrol tab0 proc=tabproc,size={600,70},pos={60,0}
	tabcontrol tab0 tablabel(0)="info",tablabel(1)="process",tablabel(2)="colors",tablabel(3)="axes",tablabel(4)="export"	
	
	SetVariable setX0,pos={67,26},size={70,14},title="X"
	SetVariable setX0,help={"Cross hair X-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setX0,limits={-inf,inf,1},value=$(df+"xc")
	setvariable setXP,pos={67,41},size={70,14},title="XP"
	setvariable setXP,help={"Cross hair X-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	setvariable setXP,limits={0,inf,1},value=$(df+"xp")
	
	SetVariable setY0,pos={141,26},size={70,14},title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,limits={-inf,inf,1},value= $(df+"yc")
	SetVariable setYP,pos={141,41},size={70,14},title="YP"
	SetVariable setYP,help={"Cross hair Y-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setYP,limits={0,inf,1},value=$(df+"yp")
	
	SetVariable setZ0,pos={215,26},size={70,14},title="Z"
	SetVariable setZ0,help={"Cross hair Z-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setZ0,limits={-inf,inf,1},value= $(df+"zc")
	SetVariable setZP,pos={215,41},size={70,14},title="ZP"
	SetVariable setZP,help={"Cross hair Z-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setZP,limits={0,inf,1},value=$(df+"zp")

	SetVariable setT0,pos={282,26},size={70,14},title="T"
	SetVariable setT0,help={"Cross hair T-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setT0,limits={-inf,inf,1},value= $(df+"tc")
	SetVariable setTP,pos={282,41},size={70,14},title="TP"
	SetVariable setTP,help={"Cross hair T-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setTP,limits={0,inf,1},value=$(df+"tp")

	
	ValDisplay valD0,pos={349,26},size={61,14},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,limits={0,0,0},barmisc={0,1000}
	execute "ValDisplay valD0,value="+df+"d0"	
	variable cstarth=67,vstarth=20
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
	CheckBox transXY pos={cstarth+50,vstarth+30},proc=CheckBoxProc,title="transpose 1st and 2nd axes"
	execute "checkbox transXY,value="+df+"transXY"
	nvar dim3index=$(df+"dim3index")
	nvar dim4index=$(df+"dim4index")
	popupmenu dim3index,pos={cstarth+333,vstarth},proc=dim34setproc,title="3rd dimension is",mode=0
	setupdim34value(df,"dim3index",dim3index)
	popupmenu dim4index,pos={cstarth+333,vstarth+20},proc=dim34setproc,title="4th  dimension is",mode=0
	setupdim34value(df,"dim4index",dim4index)
	SetVariable setgamma,pos={74,26},size={52,14},title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol"
	SetVariable setgamma,limits={0.1,Inf,0.1},value=$(df+"gamma")
	PopupMenu SelectCT,pos={153,23},size={43,20},proc=SelectCTList,title="CT"
	PopupMenu SelectCT,mode=0,value= #"colornameslist()"
	CheckBox lockColors,pos={219,26},size={80,14},proc=ColorLockCheck,title="Lock colors?"
	CheckBox lockColors,value= 0
	checkbox invertCT,pos={153,45},size={80,14},title="Invert?"
	execute "checkbox invertCT,variable="+df+"invertCT" 
	PopupMenu colorOptions,pos={309,26},size={113,20},proc=ColorOptionsProc,title="Set Colors By..."
	PopupMenu colorOptions,mode=0,value= #"\"2D images;All XYZ Data;Last Marquee\""
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
	//string u0="x ["+waveunits(w,0)+"]"+selectstring(valchecked==0,"","!"+num2char(18))+";"
	//string u1="y ["+waveunits(w,1)+"]"+selectstring(valchecked==1,"","!"+num2char(18))+";"
	//string u2="z ["+waveunits(w,2)+"]"+selectstring(valchecked==2,"","!"+num2char(18))+";"
	//string u3="t ["+waveunits(w,3)+"]"+selectstring(valchecked==3,"","!"+num2char(18))+";"

	execute "popupmenu " + s + " value=\"" + u0 +u1+u2+u3+"\""
end	
	
function tabproc(name,tab)	
	string name
	variable tab
	setvariable setx0,disable=(tab!=0)		//Info
	setvariable setXp,disable=(tab!=0)
	setvariable sety0,disable=(tab!=0)
	setvariable setyp,disable=(tab!=0)
	setvariable setZ0,disable=(tab!=0)
	setvariable setZp,disable=(tab!=0)
	setvariable setT0,disable=(tab!=0)
	setvariable setTp,disable=(tab!=0)
	valdisplay valD0,disable=(tab!=0)

	setvariable setgamma,disable=(tab!=2)	//colors
	popupmenu selectCT,disable=(tab!=2)
	checkbox lockcolors,disable=(tab!=2)
	checkbox invertCT,disable=(tab!=2)
	popupmenu coloroptions,disable=(tab!=2)
	

	checkbox hasHI,disable=(tab!=3)		//axes
	checkbox hasVI,disable=(tab!=3)
	checkbox hasHP,disable=(tab!=3)
	checkbox hasVP,disable=(tab!=3)
	checkbox ZTPMode,disable=(tab!=3)
	checkbox transXY,disable=(tab!=3)
	popupmenu dim3index,disable=(tab!=3)
	popupmenu dim4index,disable=(tab!=3)
end

function setupV(dfn,w)
	string dfn,w
	silent 1; pauseupdate
	setdatafolder root:
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
	nvar whichCT=$(df+"whichCT")
	execute "loadct("+num2str(whichCT)+")"	//load initial color table
	duplicate/o root:colors:ct $(df+"ct"), $(df+"ct_h"), $(df+"ct_v"), $(df+"ct_zt")
	wave ct=$(df+"ct"), ct_h=$(df+"ct_h"), ct_v=$(df+"ct_v"), ct_zt=$(df+"ct_zt")
	wave pmap=$(dF+"pmap")
	nvar gamma=$(dF+"gamma")
	setformula $(df+"pmap") , "255*(p/255)^"+df+"gamma)"
	setformula $(df+"ct"), "root:colors:all_ct[pmap[p]][q][whichCT]"
	setformula $(df+"ct_h"), "root:colors:all_ct[pmap[p]][q][whichCT]"
	setformula $(df+"ct_v"), "root:colors:all_ct[pmap[p]][q][whichCT]"
	setformula $(df+"ct_zt"), "root:colors:all_ct[pmap[p]][q][whichCT]"
	
	
	//make img waves
	make/o/n=(xn,yn) $(df+"img");
	wave img=$(df+"img");	setscale/p x,x0,xd,xl,img;		setscale/p y,y0,yd,yl,img
	make/o/n=(xn,zn) $(df+"imgh");
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
		display/w=(20,20,500,500); appendimage img	
		DoWindow/C/T $dfn,dfn+" [ "+dname+" ]"
		setwindow $dfn,hook=img4dHookFcn,hookevents=3
		new=1
		modifyimage img,cindex=ct
		wavestats/q wv
	endif
	nvar hasHI=$(df+"hasHI"), hasHP=$(df+"hasHP"), hasVI=$(df+"hasVI"), hasVP=$(df+"hasVP"), hasZP=$(df+"hasZP"), hasTP=$(df+"hasTP")
	nvar ZTpmode=$(df+"ztpmode") 	//0=profiles, 1=image in upper right corner
	hasZP=1*(ndim>=3)
	hasTP=1*(ndim==4)
	variable leftstop=0.75-(hasHI * hasHP)/4  
	variable bottomstop=0.75-(hasVI*hasVP)/4
	ModifyGraph axisEnab(left)={0,leftstop},axisEnab(bottom)={0,bottomstop}

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
	make/o/n=(2) $(df+"hcurx"), $(df+"hcury"), $(df+"vcurx"), $(df+"vcury"),$(df+"zcurx"), $(df+"zcury"), $(df+"tcurx"), $(df+"tcury")
	wave hcurx=$(df+"hcurx"), hcury=$(df+"hcury"), vcurx=$(df+"vcurx"), vcury=$(df+"vcury")
	wave zcurx=$(df+"zcurx"), zcury=$(df+"zcury"), tcurx=$(df+"tcurx"), tcury=$(df+"tcury")
 	hcurx={-inf,inf};
 	execute df+"hcury:="+df+"yc"
	execute df+"vcurx:="+df+"xc";			vcury={-inf,inf}
	execute df+"zcurx:="+df+"zc";			zcury={-inf,inf}
	execute df+"tcurx:="+df+"tc";			tcury={-inf,inf}
	if(new)
		appendtograph hcury vs hcurx
		appendtograph vcury vs vcurx
		setupcontrols(df)
		tabproc("info",0)
	endif
	modifyRGBaxis("hcury","Y","left",16385,65535,0)
	modifyRGBaxis("vcury","Y","left",16385,65535,0)

	//DEPENDENCY FORMULAS
	//execute wv4d(w,df,"d0",dimname(df,0)+"p", dimname(df,1)+"p", dimname(df,2)+"p", dimname(df,3)+"t")
	make/n=4/o/t $(df+"sarr")
	wave/t sarr=$(df+"sarr")
	sarr={"xp","yp","zp","tp"}; 	execute wv4di(w,df,"d0",sarr,dnum)
	sarr={"p","q","zp","tp"}; 		execute wv4di(w,df,"img",sarr,dnum)
	sarr={"p","yp","q","tp"};		execute wv4di(w,df,"imgh",sarr,dnum)
	sarr={"xp","q","p","tp"};		execute wv4di(w,df,"imgv",sarr,dnum)
	sarr={"p","yp","zp","tp"};		execute wv4di(w,df,"px",sarr,dnum)
	sarr={"xp","p","zp","tp"};		execute wv4di(w,df,"pyx",sarr,dnum)
	sarr={"xp","yp","p","tp"};		execute wv4di(w,df,"pz",sarr,dnum)
	sarr={"xp","yp","zp","p"};		execute wv4di(w,df,"pt",sarr,dnum)
	sarr={"xp","yp","p","q"};		execute wv4di(w,df,"imgzt",sarr,dnum)
	pyy=y0+p*yd

	adjustCTmain(df)
	
	//APPEND TO GRAPH
	if(ndim>=3)
		if(hasHI)
			if(hasAxis("imghL")==0)
				appimg("/L=imghL/b=bottom", df+"imgh")
				appendtograph/l=imghl vcury vs vcurx
			endif
			ModifyGraph axisEnab(imghL)={leftstop+0.05,1-0.20*(hasHP==1)},freePos(imghL)=0
			label imghl zl
			ModifyGraph lblPos(imghL)=60
			modifyRGBaxis("vcury","Y","imghL",16385,0,65535)
			modifyimage imgh,cindex=ct_h
			adjustCTh(df)
		else
			//remove imgH if present
			removeimage/z imgh
			removetraceaxis("vcury","Y","imghL")
		endif
	
		if(hasVI)
			variable hvb=hasaxis("imgvb")
			if(hasaxis("imgvB")==0)
				appimg("/L=left/b=imgvB",df+"imgv")
				appendtograph/b=imgvB hcury vs hcurx
			endif
			modifygraph axisEnab(imgvB)={bottomstop+0.05,1-0.20*(hasVP==1)},freePos(imgvB)=0	
			label imgvb zl
			ModifyGraph lblPos(imgVB)=40
			modifyRGBaxis("hcury","X","imgvB",16385,0,65535)
			modifyimage imgv,cindex=ct_v
			adjustCTv(df)
		else
			removeimage/z imgv
			removetraceaxis("hcury","X","imgvB")
		endif
	endif
	
	if(hasHP)
		if(hasaxis("profHL")==0)
			appendtograph/l=profHL px
			appendtograph/l=profHL vcury vs vcurx
		endif
		ModifyGraph axisEnab(profHL)={leftstop+.30*(hasHI==1)+.05,1},freePos(profhL)=0
		modifyRGBaxis("vcury","Y","profHL",24000,16385,20000)
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
		endif
		modifygraph axisEnab(imgZTt)={bottomstop+.05,1},axisenab(imgZtr)={leftstop+.05,1}
		ModifyGraph freePos(imgZTt)={inf,imgZTR}
		ModifyGraph freePos(imgZTr)={inf,imgZTt}
	else
		removetraceaxis("tcurx","Y","imgZTr")
		removetraceaxis("zcury","Y","imgZTr")
		removeimage/z imgzt
	endif
	
	if(!ZTPmode)
		if(hasZP)
			if(hasaxis("profZB")==0)
				appendtograph/t=profZB/R=profZR pz
				appendtograph/t=profZB/R=profZR zcury vs zcurx
			endif
			modifygraph axisEnab(profzb)={bottomstop+.05,1},axisenab(profZR)={leftstop+.05+0.5*(1-leftstop)*hasTP,1},freepos(profZR)=0
			ModifyGraph rgb(pz)=(2,39321,1)
			ModifyGraph freePos(profZB)={-inf,profZR}
			ModifyGraph rgb(zcury)=(2,39321,1)
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
		else
			removetraceaxis("pt","X","profTB")
			removetraceaxis("tcurY","X","proTB")		
		endif
	endif
	controlbar 75
	isNew=0
end

function removeall()
	string inl=imagenamelist("",","), tnl=tracenamelist("",",",1)
	execute "removeimage/z "+ inl[0,strlen(inl)-2]			//remove all images
	execute "removefromgraph/z "+  tnl[0,strlen(tnl)-2]		//remove all traces
end

function img4DHookFcn(s)
	string s
	string dfn=winname(0,1); string df="root:"+dfn+":"
	string temp=getdatafolder(1)
	wave pmap=$(df+"pmap"),vimg_ct=$(df+"ct_v"), himg_ct=$(df+"ct_h"), img_ct=$(df+"ct"), ztimg_ct=$(df+"ct_zt")
	if(cmpstr(stringbykey("event",s),"kill")==0)
		vimg_ct=0; himg_ct=0; img_ct=0; ztimg_ct=0; pmap=0
		removeall()
		killdatafolder $df
		return(-1)
	endif
	variable mousex,mousey,ax,ay,zx,zy,tx,ty,modif,returnval=0
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc"), ndim=$(df+"ndim")
	nvar ztpmode=$(df+"ztpmode"),hasZP=$(df+"hasZP"), hasTP=$(df+"hasTP")
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
			GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
			GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
			//print ax,  axmax, axmin, ay, aymin, aymax
			xcold=xc; ycold=yc
			xc= SelectNumber((ax>axmin)*(ax<axmax), xc, ax) 
			yc= SelectNumber((ay>aymin)*(ay<aymax), yc, ay) 
			variable updateImgColors=0
			if((xc==xcold)*(yc==ycold))
				updateImgColors=1
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

			endif
			returnval=1
		endif
		adjustCTmain(df)
		adjustCTh(df)
		adjustCTv(df)	
		adjustCTzt(df)
	endif

	return returnval
end	

static function COLORSTUFF_________()
end

static function adjustCTmain(df)
	string df
	wave img=$(df+"img")
	wave ct=$(df+"ct")
	nvar ict=$(df+"invertct")
	wavestats/q img 
	if (ict)
		setscale/i x v_max,v_min,ct
	else
		setscale/i x v_min,v_max,ct
	endif
end

static function adjustCTh(df)
	string df
	wave imgh=$(df+"imgh")
	wave ct_h=$(df+"ct_h")
	nvar ict=$(df+"invertct")
	wavestats/q imgh
	if(ict)
		setscale/i x v_max, v_min,ct_h
	else
		setscale/i x v_min, v_max,ct_h
	endif
end

static function adjustCTv(df)
	string df
	wave imgv=$(df+"imgv")
	wave ct_v=$(df+"ct_v")
	nvar ict=$(df+"invertct")
	wavestats/q imgv
	if(ict)
		setscale/i x v_max, v_min,ct_v
	else
		setscale/i x v_min, v_max,ct_v
	endif
end

static function adjustCTzt(df)
	string df
	wave imgzt=$(df+"imgzt")
	wave ct_zt=$(df+"ct_zt")
	nvar ict=$(df+"invertct")
	wavestats/q imgzt
	if(ict)
		setscale/i x v_max, v_min,ct_zt
	else
		setscale/i x v_min, v_max,ct_zt
	endif
end


Function selectCTList(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	nvar whichCT=$(df+"whichCT")
	whichCT=popnum-1
End


static function/s getdf()
	return "root:"+getdfname()+":"
end

static function/s getdfname()
	return winname(0,1)
end

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

