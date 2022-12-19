#pragma rtGlobals=1		// Use modern global access method.

macro newCompareTool(w0,w1)
	string w0="f1287_aligned_sm",w1="aout"
	silent 1; pauseupdate
	string dfn=uniquename("cfTool",11,0)
	newdatafolder/o $dfn
	makectoolVariables(dfn,w0,w1)
	SetupCtool(dfn,w0,w1)
end

 function makectoolVariables(dfn,w0,w1)
	string dfn,w0,w1
	string df="root:" + dfn + ":"
	string/g $(df+"wvnm0")="root:"+w0
	string/g $(df+"wvnm1")="root:"+w1
	wave  wv0=$w0, wv1=$w1
	make/o $(df+"img0")
	make/o/n=(dimsize(wv0,0),dimsize(wv0,1)) $(df+"img0")
	make/o/n=(dimsize(wv1,0),dimsize(wv1,1)) $(df+"img1")
	make/o/n=(dimsize(wv0,0),dimsize(wv0,1),3) $(df+"img0_3d")
	make/o/n=(dimsize(wv1,0),dimsize(wv1,1),3) $(df+"img1_3d")
	variable/g $(df+"xmin"), $(df+"xmax"), $(df+"ymin"), $(df+"ymax")
	variable/g $(df+"dx0")=0, $(df+"dy0")=0
	variable/g $(df+"dx1")=0, $(df+"dy1")=0
	variable/g $(df+"invertx0")=0, $(df+"inverty0")=0
	variable/g $(df+"invertx1")=0, $(df+"inverty1")=0
	variable/g $(dF+"yScale0")=1,$(df+"yScale1")=1
	nvar xmin=$(df+"xmin"), xmax=$(df+"xmax"), ymin=$(df+"ymin"), ymax=$(df+"ymax")
	variable xmin0=min(dimoffset(wv0,0),dimoffset(wv0,0)+dimsize(wv0,0)*dimdelta(wv0,0))
	variable xmax0=max(dimoffset(wv0,0),dimoffset(wv0,0)+dimsize(wv0,0)*dimdelta(wv0,0))
	variable xmin1=min(dimoffset(wv1,0),dimoffset(wv1,0)+dimsize(wv1,0)*dimdelta(wv1,0))
	variable xmax1=max(dimoffset(wv1,0),dimoffset(wv1,0)+dimsize(wv1,0)*dimdelta(wv1,0))
	variable ymin0=min(dimoffset(wv0,1),dimoffset(wv0,1)+dimsize(wv0,1)*dimdelta(wv0,1))
	variable ymax0=max(dimoffset(wv0,1),dimoffset(wv0,1)+dimsize(wv0,1)*dimdelta(wv0,1))
	variable ymin1=min(dimoffset(wv1,1),dimoffset(wv1,1)+dimsize(wv1,1)*dimdelta(wv1,1))
	variable ymax1=max(dimoffset(wv1,1),dimoffset(wv1,1)+dimsize(wv1,1)*dimdelta(wv1,1))
	xmin=min(xmin0,xmin1); xmax=max(xmax0,xmax1)
	ymin=min(ymin0,ymin1); ymax=max(ymax0,ymax1)	

	//profiles
	variable/g $(df+"xval")=(xmin+xmax)/2
	variable/g $(df+"yval") =(ymin+ymax)/2
	make/n=(dimsize(wv0,0)) $(df+"ph0")
	make/n=(dimsize(wv1,0)) $(df+"ph1")
	make/n=(dimsize(wv0,1)) $(df+"pv0x") $(df+"pv0y")
	make/n=(dimsize(wv1,1)) $(df+"pv1x"), $(df+"pv1y")
	make/n=3 $(df+"p0rgb")={65535,0,0}
	make/n=3 $(df+"p1rgb")={0,0,65535}
	
	//cursors
	make/n=2 $(df+"hcx"), $(df+"hcy"),$(df+"vcx"),$(df+"vcy")
	make/n=3 $(df+"csrrgb")={16385,65535,65535}
end

function SetupCTool(dfn,w0,w1)
	string dfn,w0,w1
	string df="root:"+dfn+":"


	wave  wv0=$w0, wv1=$w1
	wave img0=$(df+"img0"),img1=$(df+"img1")
	wave img0_3d=$(df+"img0_3d"),img1_3d=$(df+"img1_3d")

	svar wvnm0=$(df+"wvnm0")
	svar wvnm1=$(df+"wvnm1")
	nvar dx0=$(df+"dx0"),dx1=$(df+"dx1"),dy0=$(df+"dy0"),dy1=$(df+"dy1")
	

	copyscales wv0 img0,img0_3d
	copyscales wv1 img1,img1_3d
	setscale/p z -1,1,img0_3d,img1_3d
	setformula img0_3d,wvnm0+"[p][q]"
	setformula img1_3d,wvnm1+"[p][q]"
	setformula img0,"interp3d(img0_3d, x-" + df+"dx0" + ", y-" +df+ "dy0,0)"
	setformula img1, "interp3d(img1_3d, x-" + df+"dx1" + ",y-" + df+"dy1,0)"

	dowindow/f $dfn
	if(v_flag==0)
		display; appendimage img0
		dowindow/c/t $dfn,dfn+" [ "+w0 +", " + w1+"]"
		setwindow $dfn,hook=cftoolHookFcn,hookevents=3
		setdrawenv fillpat=0,xcoord=bottom,ycoord=left
	endif
	
	controlbar 75
	modifygraph cbrgb=(15555,33915,51000)
	
	appendimage/b=b2 img1
	ModifyGraph axisEnab(bottom)={0,0.35},axisEnab(b2)={0.37,0.74}, freePos(b2)=0
	ModifyGraph axisEnab(left)={0,.74}
	nvar xmin=$(df+"xmin"), xmax=$(df+"xmax"), ymin=$(df+"ymin"), ymax=$(df+"ymax")
	setaxis bottom xmin, xmax
	setaxis b2 xmin,xmax
	setaxis left ymin,ymax
	//setaxis right ymin,ymax
	if(exists(w0+"_ct")==1)
		duplicate/o $(w0+"_ct") $(df+"img0_ct")
		modifyimage img0 cindex=$(df+"img0_ct")
	endif
	
	if(exists(w1+"_ct")==1)
		duplicate/o $(w1+"_ct") $(df+"img1_ct")
		modifyimage img1 cindex=$(df+"img1_ct")
	endif
	
	//profiles
	wave ph0=$(df+"ph0")
	wave ph1=$(df+"ph1")
	wave pv0x=$(df+"pv0x")
	wave pv0y=$(df+"pv0y")	
	wave pv1x=$(df+"pv1x")
	wave pv1y=$(df+"pv1y")
	copyscales wv0,ph0
	copyscales wv1,ph1
	setscale/p x dimoffset(wv0,1),dimdelta(wv0,1),pv0x
	setscale/p x dimoffset(wv1,1),dimdelta(wv1,1),pv1x
	setformula ph0,"interp3d("+df+"img0_3d,x-" + df+"dx0," + df+"yval-" + df+"dy0,0)*"+df+"yscale0"
	setformula ph1,"interp3d("+df+"img1_3d,x-" + df+"dx1," + df+"yval-" + df+"dy1,0)*"+df+"yscale1"
	//setformula ph1,"interp2d(root:" + w1+",x," + df+"yval)"
	appendtograph/L=L2 ph0,ph1
	modifygraph axisenab(L2)={0.76,1},freepos(l2)=0
	setformula pv0y,"dimoffset("+df+"img0_3d,1) + dimdelta("+df+"img0,1)*p+"+df+"dy0"
	setformula pv1y,"dimoffset("+df+"img1_3d,1) + dimdelta("+df+"img1,1)*p+"+df+"dy1"
	setformula pv0x,"interp3d("+df+"img0_3d,"+df+"xval-"+df+"dx0,x,0)*"+df+"yscale0"
	setformula pv1x,"interp3d("+df+"img1_3d,"+df+"xval-"+df+"dx1,x,0)*"+df+"yscale1"
	appendtograph/b=b3 pv0y vs pv0x
	appendtograph/b=b3 pv1y vs pv1x
	modifygraph axisenab(B3)={0.76,1},freepos(B3)=0
	wave p0rgb=$(df+"p0rgb"), p1rgb=$(df+"p1rgb")
	modifygraph rgb(ph0)=(p0rgb[0],p0rgb[1],p0rgb[2])
	modifygraph rgb(ph1)=(p1rgb[0],p1rgb[1],p1rgb[2])
	modifygraph rgb(pv0y)=(p0rgb[0],p0rgb[1],p0rgb[2])
	modifygraph rgb(pv1y)=(p1rgb[0],p1rgb[1],p1rgb[2])
	ModifyGraph axRGB(bottom)=(p0rgb[0],p0rgb[1],p0rgb[2]),tlblRGB(bottom)=(p0rgb[0],p0rgb[1],p0rgb[2]), alblRGB(bottom)=(p0rgb[0],p0rgb[1],p0rgb[2])
	ModifyGraph axRGB(b2)=(p1rgb[0],p1rgb[1],p1rgb[2]),tlblRGB(b2)=(p1rgb[0],p1rgb[1],p1rgb[2]), alblRGB(b2)=(p1rgb[0],p1rgb[1],p1rgb[2])
	//cursors
	wave hcx=$(df+"hcx"),hcy=$(df+"hcy"),vcx=$(df+"vcx"),vcy=$(df+"vcy")
	hcx={-inf,inf}
	setformula hcy,df+"yval"
	vcy={-inf,inf}
	setformula vcx,df+"xval"
	appendtograph hcy vs hcx
	appendtograph vcy vs vcx
	appendtograph/b=b2 hcy vs hcx
	appendtograph/b=b2 vcy vs vcx
	appendtograph/l=l2 vcy vs vcx
	appendtograph/b=b3 hcy vs hcx
	wave csrRGB=$(dF+"csrrgb")
	ModifyGraph rgb(hcy)=(csrRGB[0],csrRGB[1],csrRGB[2]),rgb(vcy)=(csrRGB[0],csrRGB[1],csrRGB[2]);DelayUpdate
	ModifyGraph rgb(hcy#1)=(csrRGB[0],csrRGB[1],csrRGB[2]),rgb(vcy#1)=(csrRGB[0],csrRGB[1],csrRGB[2]);DelayUpdate
	ModifyGraph rgb(vcy#2)=(csrRGB[0],csrRGB[1],csrRGB[2]),rgb(hcy#2)=(csrRGB[0],csrRGB[1],csrRGB[2])
	
	//controls
	execute "ValDisplay xval value="+df+"xval"
	valdisplay xval,title="x",bodyWidth=60,pos={40,2}
	execute "ValDisplay yval value="+df+"yval"
	valdisplay yval, title="y",bodyWidth=60,pos={40,22}
	execute "SetVariable dx0 value="+df+"dx0"
	setvariable dx0,bodywidth=90,limits={-inf,inf,0.02},pos={170,2}
	execute "SetVariable dy0 value="+df+"dy0"
	setvariable dy0,bodywidth=90,limits={-inf,inf,0.02},pos={170,22}
	execute "SetVariable yscale0 value="+df+"yscale0"
	setvariable yscale0,bodywidth=90,pos={170,42}
		
	execute "SetVariable dx1 value="+df+"dx1"
	setvariable dx1,bodywidth=90,limits={-inf,inf,0.02},pos={290,2}
	execute "SetVariable dy1 value="+df+"dy1"
	setvariable dy1,bodywidth=90,limits={-inf,inf,0.02},pos={290,22}
	execute "SetVariable yscale1 value="+df+"yscale1"
	setvariable yscale1,bodywidth=90,pos={290,42}

	
	Button copylimR title="limits ->",size={80,20},proc=cf_limitProc,pos={350,0}
	Button copylimL title="<- limits",size={80,20},proc=cf_limitProc,pos={350,20}
	 
	
//	execute "Checkbox invertx0 value="+df+"invertx0"
//	checkbox invertx0,title="invert x?",bodywidth=90,limits={-inf,inf,0.02},pos={120,42}
//	execute "Checkbox inverty0 value="+df+"inverty0"
//	checkbox inverty0,title="invert y?",bodywidth=90,limits={-inf,inf,0.02},pos={120,55}
//
//	execute "Checkbox invertx1 value="+df+"invertx1"
//	checkbox invertx1,title="invert x?",bodywidth=90,limits={-inf,inf,0.02},pos={240,42}
//	execute "Checkbox inverty1 value="+df+"inverty1"
//	checkbox inverty1,title="invert y?",bodywidth=90,limits={-inf,inf,0.02},pos={240,55}
	
end

Function cf_limitProc(ctrlName) : ButtonControl
	String ctrlName

	strswitch(ctrlName)
		case "copylimR":
			getaxis/q bottom
			setaxis b2 v_min, v_max			
			break
		case "copylimL":
			getaxis/q b2
			setaxis bottom v_min, v_max			
			break
	endswitch
	
End
//function interp2dER(wv,x,y)
//	wave wv
//	variable x,y
//	return interp3d(wv,x,y,0)
//end


function cftoolHookFcn(s)
	string s
	string dfn=winname(0,1); string df="root:"+dfn+":"
	variable mousex,mousey,ax,ay,zx,zy,tx,ty,modif,returnval=0
	modif=numberByKey("modifiers",s) & 15
	nvar xval=$(df+"xval"), yval=$(df+"yval")
	if(cmpstr(stringbykey("event",s),"kill")==0)
		//delete formulae

		setformula $(df+"img0_3d"),""	; setformula $(df+"img1_3d"),""
		setformula $(df+"img0"),""	; setformula $(df+"img1"),""
		setformula $(df+"ph0"),""	; setformula $(df+"ph1"),""
		setformula $(df+"pv0x"),""	; setformula $(df+"pv1x"),""
		setformula $(df+"pv0y"),""	; setformula $(df+"pv1y"),""
		setformula $(df+"hcy"),""	; setformula $(df+"vcx"),""
		
		string inl=imagenamelist("",","), tnl=tracenamelist("",",",1)
		execute "removeimage/z "+ inl[0,strlen(inl)-2]			//remove all images
		execute "removefromgraph/z "+  tnl[0,strlen(tnl)-2]		//remove all traces
		killdatafolder $df
		return(-1)
	endif
	variable val=0
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
		if(modif==9)	////9 means "1001" = cmd/ctrl + mousedown
			GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
			GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
			xval=selectnumber((ax>axmin)*(ax<axmax), xval, ax)
			yval=SelectNumber((ay>aymin)*(ay<aymax), yval, ay) 
			val=1
		endif
	endif
	return val
end

static function/s getdf()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
 	return df 
 end