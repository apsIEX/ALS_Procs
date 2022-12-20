#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName= Imagetool5
#pragma version = 5.90
#include "AutoScaleInRange"
#include "colorTables"
#include "JSON_Util"
#include "Image_Tool5_API"
#include "progresswindow"
	static constant MAJOR_VERSION = 5.90
	static constant MINOR_VERSION = 0

//5.80 ER Initiated Version 5.80 in new git repo	
//5.81 ER Added mask selection for processing  
//5.82 ER Added storage of data points
//5.83 ER Integration of Advanced Peak Fitter
//5/84 ER New ROI Integration method
//5.85 AB add data units to cursor waves to fix axes labels disappearing when experiements are loaded
//5.86 AB Optimize dependencies to reduce redraws.S
//			 Add ImagetoolV menu
//			 Add sendtolabview
//5.87 AB Add duplicate imagetool
//			show in databrowser
//			open imagetool from databrowser
//5.88 AB Add overlays
//5.89 AB Add avg and sdev display for cursor point value

menu "2D"
	"New Image Tool 5",/Q,NewImageTool5("")
end        

Menu "ImageToolV"
	"New Image Tool 5",/Q,NewImageTool5("")
	"-"
	 Submenu ScanSystemName()
	 		ScanSystemMenu(),/Q, setSystemMenu()
	 end
	 "-"
	listImagetoolVs(), /Q, IT5_BringtoFront()
End
 
Function IT5_BringtoFront()
	GetLastUserMenuInfo		// Sets S_value, V_value, etc.
	string name = S_value[0,strsearch(S_Value,"[",0)-2]
	Dowindow /F $name
End 
 
Static Function AfterFileOpenHook(refNum,file,pathName,type,creator,kind)
	Variable refNum,kind
	String file,pathName,type,creator
	// Check that the file is open (read only), and of correct type
	//print "AfterFileOpenHook"
	if(kind==1)
		IT5_GlobalSetup()
		print "rebuild image tools"
		UpdateAllImagetoolVs(0)
	endif
	if(exists("root:packages:imagetoolV:SocketTGID"))
		KillVariables /Z root:packages:imagetoolV:SocketTGID
	endif
	createbrowser
	modifybrowser appendUserButton={ImageToolV,"IT5_openfromDataBrowser()" }
	return 0							// don't prevent MIME-TSV from displaying
End

static function IgorStartOrNewHook(igorApplicationNameStr )
	String igorApplicationNameStr
	IT5_GlobalSetup()
	createbrowser
	modifybrowser appendUserButton={ImageToolV,"IT5_openfromDataBrowser()" }
	return 0
end

function IT5_openfromDataBrowser()
	//string s
	string wn = GetBrowserSelection(0)
	if (strlen(wn)>0)
	NewImageTool5(wn)	
	endif
end

function UpdateAllImagetoolVs(opt)
	variable opt // force update for opt=1
	string toollist = WinList("ImageToolV*",";",""),tname,df
	variable num = itemsinlist(toollist)
	variable ii
	for(ii=0;ii<num;ii+=1)
		tname = stringfromlist(ii,toollist)
		df = getDFfromName(tname)
		NVAR version= $(df+"version")
		if(!(version==MAJOR_VERSION)||opt==1)
			UpdateImagetoolV(tname)
		else
				svar dname=$(df+"dname")
				setupV(tname,dname)    // this is to fix igor appending traces before images on recreation which breaks the axis labeling
		endif
	endfor 
end

function IT5_GlobalSetup()
	newdatafolder /o root:Packages
	newdatafolder /o root:Packages:ImagetoolV
	if (exists("root:Packages:ImagetoolV:ScanSystem")==0)
		variable /g root:Packages:ImagetoolV:ScanSystem 
	endif
	NVAR ScanSystem = root:Packages:ImagetoolV:ScanSystem 
	//ScanSystem = GetScanSystem(GetHostName())
end

function UpdateImagetoolV(dfn)
	string dfn
	string df=getDFfromName(dfn)
	svar dname=$(df+"dname")
	string w=dname
	dowindow /F $dfn
	SetupVariables(dfn)
	nvar isnew=$(df+"isnew")
	isnew=0
	variable /g $(df+"rebuild")=1
	controlinfo tab0
	variable /g $(df+"tabnum")=V_Value
	removeallcontrols(dfn)
	setupV(dfn,w)
end

function makeData()
	make/o/n=(30,35,40,45) data2 	//[theta][energy][beta][k]
	wave data=data2
	setscale/i x -1,1,"kx",data
	setscale/i y -1.8,0.2,"E",data
	setscale/i z -1,1,"ky",data
	setscale/i t -1,1,"kz",data
	data = 1/(.1+(1-(x^2-z^2-t^2)/y)^2)
	//	data=1/((y-(20+10*z)*((x-.05)^2))^2+(t/20)^2)
	data = (y<=0)*(.1-y*.2)/((y-2+3*sqrt(x^2+z^2+t^2))^2+(.1+-y*.2)^2)
	//	duplicate /o data2, data2D
	make/o/n=(30,40,45) data2D 	//[theta][energy][beta][k]
	setscale/i x -1,1,"kx",data2d
	setscale/i y -1,1,"ky",data2d
	setscale/i z -1,1,"kz",data2d
	make /o/N=(30,40) main
	setscale/i x -1,1,"kx",main
	setscale/i y -1,1,"ky",main
	data2D = 2-3*sqrt(x^2+y^2+z^2)
	//make 	/N=main_kx,main_ky,
end


function NewImageTool5(w)
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
	SetupVariables(dfn)
	setupV(dfn,w)
	setdatafolder oldfol
	GetLastUserMenuInfo
	if (cmpstr(S_value,"New Image Tool 5")==0)
		print "NewImageTool5(\""+ w + "\")"
	endif
	BuildMenu "ImageToolV"
end


Function DuplicateButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string df=getdf()
			dupimageToolV(df)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function dupimageToolV(df)
	string df
	string dfn=getdfname()
	svar dname=$(df+"dname")
	getwindow $dfn wsizeRM
	variable left=  V_left,right= V_right,top= V_top, bottom= V_bottom
	string w=dname
	string oldfol=getdatafolder(1)
	setdatafolder "root:"
	string new_dfn=uniquename("ImageToolV",11,0)
	string new_df=getDFfromName(new_dfn)
	DuplicateDataFolder $FixUpDF(df),$FixUpDF(new_df)
	nvar isnew=$(new_df+"isnew")
	//isnew=1
	setupV(new_dfn,w)
	//make window size same but offset
	movewindow /W=$new_dfn left+50, top+50, right+50, bottom+50
	setdatafolder oldfol
	//copy axis settings
	string axes = AxisList(IT5winname(df))
	variable na=itemsinlist(axes)
	variable ii
	string axis
	for(ii=0;ii<na;ii+=1)
		axis = stringfromlist(ii,axes)
		string info = AxisInfo(IT5winname(df), axis )
		string SETAXISCMD = stringbykey("SETAXISCMD",info)
		SETAXISCMD = replacestring("SetAxis",SETAXISCMD,"SetAxis/W="+IT5winname(new_df))
		execute SETAXISCMD
	endfor
	BuildMenu "ImageToolV"
	print "dupimageToolV(\""+df+"\") // duplicate "+dfn+"["+w+"]"+" as "+new_dfn
//	print "New image tool "+dfn+"["+w+"]"+" as "+new_dfn

end

function SetupVariables(dfn)
	string dfn 
	string df=getDFfromName(dfn)
	variable/g $(df+"version")=MAJOR_VERSION
	variable/g $(df+"x0"),	$(df+"xd"), $(df+"xn"), $(df+"x1")
	variable/g $(df+"y0"), $(df+"yd"), $(df+"yn"), $(df+"y1")	
	variable/g $(df+"z0"),	$(df+"zd"), $(df+"zn"), $(df+"z1")
	variable/g $(df+"t0"), 	$(df+"td"), $(df+"tn"), $(df+"t1")
	string /g  $(df+"xlable"),  $(df+"ylable"), $(df+"zlable"), $(df+"tlable")
	string /g $(df+"dataStoreWave")=""
	
	variable/g $(df+"xlock"),	$(df+"ylock"), $(df+"zlock"), $(df+"tlock")
	makevariable(df,"tabnum",0)
	makevariable(df,"AutoScaleHP",1)
	makevariable(df,"AutoScaleVP",1)
	makevariable(df,"MatchZAxes",1)	
	makevariable(df,"hasImg",1)
	makevariable(df,"hasHI",1)
	makevariable(df,"hasHP",1)	//default: image slices ON, profiles ON
	makevariable(df,"hasVI",1)
	makevariable(df,"hasVP",1)
	makevariable(df,"hasZP",1)
	makevariable(df,"hasTP",1)
	makevariable(df,"dim3index",2)
	makevariable(df,"dim4index",3)
	makevariable(df,"transXY",0) //0=no transpose, 1=transpose
	makevariable(df,"ZTPMode",0)//0=separate z,t profiles, 1=z-t image
	makevariable(df,"bottomAxisScale",1)
	makevariable(df,"leftAxisScale",1)
	makevariable(df,"HideCursors",0)

	variable/g $(df+"xp"), $(df+"yp"), $(df+"zp"),$(df+"tp")		//cursor coords, pixel units
	variable/g $(df+"xc"), 	$(df+"yc"),$(df+"zc"), $(df+"tc")			//cursor coords, real units
	variable/g $(df+"d0")	//value at cursor
	variable/g $(df+"di") 	//integrated value (over bin range) at cursor
	variable/g $(df+"isNew")=1	//used to indicate it's a new tool
	string/g  $(df+"dname")
	string /g $(df+"LastMouseDownGraph")
	variable /g $(df+"CustomMarqueeMenu") =1

	//Color Tables
	makevariable(df,"gamma",1)
	makevariable(df,"gammaSlider",0)
	makevariable(df,"gamma_img",1)
	makevariable(df,"gamma_H",1)
	makevariable(df,"gamma_V",1)
	makevariable(df,"gamma_ZT",1)
	makevariable(df,"Lockgamma_img",0)
	makevariable(df,"Lockgamma_H",0)
	makevariable(df,"Lockgamma_V",0)
	makevariable(df,"Lockgamma_ZT",0)
	

	make/o/n=256/o $(df+"pmap"),$(df+"pmap_H"),$(df+"pmap_V"),$(df+"pmap_ZT")
	make/o/n=256 $(df+"img_hist"),$(df+"imgV_hist"),$(df+"imgH_hist"),$(df+"imgZT_hist")
	variable/g $(df+"whichCT"), $(df+"whichCTh"),$(df+"whichCTv"),$(df+"whichCTzt")
	variable/g $(df+"invertCT")
	variable/g $(df+"invertCT_H")
	variable/g $(df+"invertCT_V")
	variable/g $(df+"invertCT_ZT")

	makevariable(df,"HiResCT",0)
	makevariable(df,"HistNormCT",0)

	//Color ROI waves
	variable i
	for(i=1;i<7;i+=1)
		makewave1d(df,"img"+num2str(i)+"rx",0,0)
		makewave1d(df,"img"+num2str(i)+"ry",0,0)
		makevariable(df,"img"+num2str(i)+"mode",1)
		makevariable(df,"img"+num2str(i)+"ShowROI",1)
	endfor

	//Color ROI mode: 1=free, 2=ROI ,3=lock
	makevariable(df,"imgmode",1) 
	makevariable(df,"imgHmode",1) 
	makevariable(df,"imgVmode",1) 
	makevariable(df,"imgZTmode",1)
	string/g $(df+"ROIctrlEditing")
	variable/g $(df+"imgShowROI"), $(df+"imgHShowROI"), $(df+"imgVShowROI"), $(df+"imgZTShowROI")
	make/o/n=3/o $(df+"ROIcolor")={65535,0,65535}

	//ROI variables one pair for each ROI tab 
	variable/g $(df+"ProcessROIMode")=0
	makewave1d(df,"processROIx",0,0) 
	makewave1d(df,"processROIy",0,0)
	variable/g $(df+"ShowProcessROI")=0
	
	variable/g $(df+"Norm2DROIMode")=0
	makewave1d(df,"Norm2DROIx",0,0)
	makewave1d(df,"Norm2DROIy",0,0)

	// Norm 
	makevariable(df,"Norm1_ON",0)
	makevariable(df,"Norm1_Mode",1)
	makevariable(df,"Norm1_Axis",0)
	makevariable(df,"Norm1_Method",0)
	makevariable(df,"Norm1_X0",0)
	makevariable(df,"Norm1_X1",0)
	makevariable(df,"Norm1_p0",0)
	makevariable(df,"Norm1_p1",0)

	makevariable(df,"Norm1_2Daxis",0)

	makevariable(df,"Norm2_ON",0)
	makevariable(df,"Norm2_Mode",1)
	makevariable(df,"Norm2_Axis",0)
	makevariable(df,"Norm2_Method",0)
	makevariable(df,"Norm2_X0",0)
	makevariable(df,"Norm2_X1",0)
	makevariable(df,"Norm2_p0",0)
	makevariable(df,"Norm2_p1",0)

	makevariable(df,"Norm2_2Daxis",0)

	//avg
	makewave1d(df,"bin",4,1)
	makevariable(df,"bincuropt0",1)
	makevariable(df,"bincuropt1",1)
	makevariable(df,"bincuropt2",1)
	makevariable(df,"bincuropt3",1)

	//link
	makevariable(df,"Link",0)
	makevariable(df,"linkaxis0",1)
	makevariable(df,"linkaxis1",1)
	makevariable(df,"linkaxis2",1)
	makevariable(df,"linkaxis3",1)
	makevariable(df,"linkgamma",1)
	makewave1D(df,"linkoffset",4,0)
	makewave1D(df,"linkaxis",4,0)
	variable/g $(df+"CursorLinkTrig")
	variable/g $(df+"GammaLinkTrig")

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
	
	
	//Overlays
	makevariable(df,"Overlays_Show",1)
	if(!waveexists($(df+"Overlays_ListBox")))
		make /T/N=(0,2) $(df+"Overlays_ListBox")
	endif
	if(!waveexists($(df+"Overlays_ListBoxSelection")))
		make /N=(0,2,2) $(df+"Overlays_ListBoxSelection")
		SetDimLabel 2,1,BackColors,$(df+"Overlays_ListBoxSelection")	//  plane 1 as foreground Back

	endif

	makewave1D(df,"OverLays_Enabled",0,1)

	makewave1DText(df,"OverLays_List",0,"")
	makewave1DText(df,"OverLays_Folder",0,"")
	if(!waveexists($(df+"Overlays_Mapping")))
		make /N=(4,0) $(df+"Overlays_Mapping")
	endif
	if(!waveexists($(df+"Overlays_Color")))
		make /N=(1,3) $(df+"Overlays_Color")
	endif
	makevariable(df,"Overlay_LineWidth",1)
	makevariable(df,"Overlays_Row",0)

end

function/s appendDF(df,s)
	string df,s
	if ((cmpstr(s,"p")==0) +(cmpstr(s,"q")==0) + (cmpstr(s,"r")==0) + (cmpstr(s,"s")==0))
		return s
	elseif ((cmpstr(s,"x")==0) +(cmpstr(s,"y")==0) + (cmpstr(s,"z")==0) + (cmpstr(s,"t")==0))
		return s
	else
		return df+s
	endif
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

function Extractplanebin_Debug(dst,src,axis,bin,tpi,ypi)
	wave dst,src,axis,bin
	variable tpi,ypi
	return Extractplanebin(dst,src,axis,bin,tpi,ypi)
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
	if ((strlen(wvout)==2) * (cmpstr(wvout[0],"d")==0))
		//trap "d0" and "di"
		if (cmpstr(wvout,"di")==0)
			wave bin=$df+"bin"
			sout=df+wvout+":=it5_dinteg(" + df+"px," +df+"xp,"    +df+"bin[" + num2str(iarr[0]) + "])"
		endif

	else
		wave /Z wout=$(df+wvout)
		if(dimsize(wout,0)!=0)
			string nn1="Norm1"//+num2str(Norm_num)
			NVAR Norm1_ON=$(df+"Norm1_ON")//+num2str(Norm_num)
			//NVAR Mode1= $(df+nn1+"_Mode")

			string nn2="Norm2"//+num2str(Norm_num)
			NVAR Norm2_ON=$(df+"Norm2_ON")//+num2str(Norm_num)
			//NVAR Mode2= $(df+nn2+"_Mode")

			if (j==4) 
				//	sout= df+wvout +"=0;"+df+wvout+"_trig:=Extractplane("+df+wvout+","+ wv+","+df+wvout+"_axis,"+swv2[2]+","+swv2[3]+")"
				if(Norm1_ON==1)
					if(Norm2_ON==1)
						sout= df+wvout +"=0;"+df+wvout+"_trig:=ExtractplanebinNorm2("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[2]+","+swv2[3]+","+df+"Norm1,"+df+"Norm2)"
					else
						sout= df+wvout +"=0;"+df+wvout+"_trig:=Extractplanebinnorm("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[2]+","+swv2[3]+","+df+"Norm1)"
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
					if(Norm1_ON==1)
						sout= df+wvout +"=0;"+df+wvout+"_trig:=ExtractBeambinnorm("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[1]+","+swv2[2]+","+swv2[3]+","+df+"Norm1)"
					else
						sout= df+wvout +"=0;"+df+wvout+"_trig:=ExtractBeambin("+df+wvout+","+ wv+","+df+wvout+"_axis,"+df+"bin,"+swv2[1]+","+swv2[2]+","+swv2[3]+")"
					endif
				endif
			endif
		endif	
	endif
	return df+wvout+"_trig=0;"+sout	
end

function it5_dinteg(wv,pos,wid)
	wave wv
	variable pos,wid
	wavestats/q/r=[round(pos)-floor((wid-1)/2), round(pos)+ceil((wid-1)/2)] wv
	return v_avg*wid
end

function /t it5_SetupdSdev(wv,df,sarr,iarr)
	string wv,df
	wave /t sarr
	wave iarr
	variable /g $(df+"dsdev_trig")
	return df+"dsdev_trig:=it5_dSdev("+wv+",\""+df+"\","+df+sarr[iarr[0]]+","+df+sarr[iarr[1]]+","+df+sarr[iarr[2]]+","+df+sarr[iarr[3]]+","+df+"bin)"
end

function it5_dSdev(wv,df,xp,yp,zp,tp,bin)
	wave wv,bin
	string df
	variable xp,yp,zp,tp
	//svar dname=$(df+"dname")
	//wave wv = $dname
	wave pwave = getcursorPointWave(df)
	wave bin = $(df+"bin")
	make /FREE /N=4 bot,top
	bot = round(pwave[p])-floor((bin[p]-1)/2)
	top = round(pwave[p])+ceil((bin[p]-1)/2)
	wavestats/q/RMD=[bot[0],top[0]][bot[1],top[1]][bot[2],top[2]][bot[3],top[3]] wv
	nvar D_sdev=$(df+"D_sdev")
	nvar D_avg=$(df+"D_avg")
	
	D_sdev = V_sdev
	D_avg = v_avg
	return 0
end



function appImg(options,img)	//appends if not already there
	string options; string img
	string il=imagenamelist("",",")
	if (whichlistitem(img,il,",")<0)
		execute "appendimage" + options + " " +img
	endif
end

//given dim3index, dim4index, transXY, creates "dnum" wave which enocdes mapping of data->imagtool axis
//gives the name of the data axis "x", "y", "z", "t" 
//(assuming dim3index does not equal dim4index)
//corresponding to index di as follows:
//0 = "x" axis of main image
//1= "y" axis of main image
//2="z" axis at u.r. graph
//3="t" axis at u.r. lower graph
// on fisrt call "dnum" wave whose values correspond to x=0,y=1,z=2,t=3
//on squbsequent calls also swaps around xp,yp,xp,tp to that cursors remain on the same data point when axes setting are changed 

static function SetupDimMapping(df)
	string df; //	variable di
	nvar d3i=$(df+"dim3index"), d4i=$(df+"dim4index"),txy=$(df+"transXY")
	variable notnew=exists(df+"dnum")>0

	make/n=4/o $(df+"dnum"),  $(df+"dnumOld")
	wave dnum=$(df+"dnum"), dnumOld=$(df+"dnumOld")
	setdimlabel 0,0,axis0,dnum
	setdimlabel 0,1,axis1,dnum
	setdimlabel 0,2,axis2,dnum
	setdimlabel 0,3,axis3,dnum
	
	make/o/n=4/FREE q34w
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

	//switch around xp, yp, zp, tp values if necessary, needed to preserve cursor location when changes axis settings
	if(notnew)
		nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc") 
		make/o/n=4/FREE q34w,qi,qii
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
	
	make /o/N=4 $(df+"adnum")  //inverse dnum mapping
	wave adnum=$(df+"adnum")
	setdimlabel 0,0,x,adnum
	setdimlabel 0,1,y,adnum
	setdimlabel 0,2,z,adnum
	setdimlabel 0,3,t,adnum
	adnum = p
	sort dnum,adnum
	
	return 0
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
	string df=getdf()
	nvar hc=$(df+"hidecursors")
	do
		s=stringfromlist(ii,tl)
		c1=cmpstr(s,w)==0		//e.g. "abc"="abc"
		c2=(cmpstr(s[0,strlen(w)-1],w)==0)*(cmpstr(s[strlen(w)],"#")==0)	//e.g. "abc#2"="abc"
		if (c1 + c2)
			//eg "w#1"
			sk=stringbykey(which+"AXIS",traceinfo("",s,0))
			if(cmpstr(sk,ax)==0)
				modifygraph rgb($s)=(r,g,b),lsize($s)=1-hc
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

Function PolyDoneProc(ctrlName) : ButtonControl
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
	for(ii=0;ii<(phiN*1);ii+=1)
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
			execute "NewImageTool5(\""+wvout+"\")"
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
	string indvarnam=ss1_name(), wvnam="wvout"
	prompt wvnam,"name of new wave"
	prompt np, "number of points along contour"
	prompt dim,"dimension of outgoing data",popup "lineout;image;volume"
	prompt indvarnam,"name of new independent variable"
	string df=getdf()
	//print df
	if(numpnts($(df+"ycontour"))<2)
		abort "sorry, only 2 points are supported at present"
	endif
//	interpolate2/t=1/n=(np)/x=$(df+"xx")/y=$(df+"yy") $(df+"xcontour"), $(df+"ycontour")
	make /o /N=(np) $(df+"xx"), $(df+"yy")
	variable slen = interp_poly($(df+"xcontour"),$(df+"ycontour"),$(df+"xx"), $(df+"yy"))

	if (dim==1)
		make/n=(np)/o $wvnam
		$wvnam=interp2d($(df+"img"),$(df+"xx"),$(df+"yy"))
		setscale/i x 0,slen,indvarnam,$wvnam
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
		setscale/i x 0,slen,indvarnam,$wvnam
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
		setscale/i x 0,slen,indvarnam,$wvnam
		NewImageTool5(wvnam)

	endif
end

function/s ss1_name()
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
	string dfn=getdfname()
	nvar isNew=$(df+"isNew")
	nvar ndim=$df+"ndim"
	graphnormal
	
	//ER 5-2017
	//all the ", win=$IT5WinName(df)" are needed to get around igor bug.
	//window loses focus when clicking tab control when subpanel was frontmost
	//dowindow/f doesn't fix it
	string ws=IT5WinName(df)
	
	//Info=============================
	SetVariable setXUnit,disable=(tab!=0), win=$ws
	SetVariable setYUnit,disable=(tab!=0), win=$ws
	SetVariable setZUnit,disable=(tab!=0), win=$ws
	SetVariable setTUnit,disable=(tab!=0), win=$ws
	checkbox xlock,disable=(tab!=0), win=$ws
	checkbox ylock,disable=(tab!=0), win=$ws
	checkbox zlock,disable=(tab!=0), win=$ws
	checkbox tlock,disable=(tab!=0), win=$ws

	setvariable setx0,disable=(tab!=0)		, win=$ws
	setvariable setXp,disable=(tab!=0), win=$ws
	setvariable sety0,disable=(tab!=0), win=$ws
	setvariable setyp,disable=(tab!=0), win=$ws
	setvariable setZ0,disable=(tab!=0), win=$ws
	setvariable setZp,disable=(tab!=0), win=$ws
	setvariable setT0,disable=(tab!=0), win=$ws
	setvariable setTp,disable=(tab!=0), win=$ws
	valdisplay valD0,disable=(tab!=0), win=$ws
	valdisplay valDi,disable=(tab!=0), win=$ws
	valdisplay valDavg,disable=(tab!=0), win=$ws
	valdisplay valDsdev,disable=(tab!=0), win=$ws
	
	
	
	popupmenu StoreData,disable=!(tab==0 + tab==1), win=$ws
	button CapturePoint,disable=!(tab==0 + tab==1), win=$ws
	
	// Process=========================
	// clear all ROIs
	ProcessDrawROI(df,"Process",0)
	wave rmask=$(df+"ProcessROIMask")
	nvar checked=$(df+"ShowProcessROI")
	if(WaveExists(rmask)*Nvar_Exists(checked))
		doProcessROIMaskShowCheckProc(checked*(tab==1), rmask)
	endif	
	popupmenu ProcessROIDraw, disable=(tab!=1), win=$ws	//process
	controlinfo/W=$ws ProcessROIDone
	switch(abs(v_flag))
		case 1: //button
			killcontrol/w=$ws ProcessROIDone  //remove old-style button to replace with new popupmenu on old IT windows
			popupmenu ProcessROIDone,win=$ws, title="Done...", pos={65,39}, size={100,20}, proc=ProcessROIDone, mode=0, disable=1, value="Add;Subtract", win=$ws
		break
		case 3: //popupmenu
			popupmenu ProcessROIDone,win=$ws, disable=1, win=$ws
	endswitch
	checkbox ShowProcessROIMask, disable=(tab!=1), pos={70,59}, win=$ws
	Button ProcessROIkill, disable=(tab!=1), win=$ws
	if((isNew==0)*(tab==1))
		ProcessDrawROI(df,"Process",tab==1)
	endif
	popupmenu ProcessROI,disable=(tab!=1), win=$ws
	popupmenu Process,disable=(tab!=1), win=$ws
	button TileButton, disable=(tab!=1), win=$ws


	//Colors =========================
	setvariable setgamma,value=$(df+"gamma"), disable=(tab!=2), win=$ws	// We set the variable to support the old name
	slider slidegamma,disable=(tab!=2), win=$ws	//colors

	popupmenu selectCT,disable=(tab!=2), win=$ws
	checkbox invertCT,disable=(tab!=2), win=$ws
	checkbox HiResCT,disable=(tab!=2), win=$ws
	checkbox HistNormCT,disable=(tab!=2), win=$ws

	GroupBox groupCOpts,disable=(tab!=2)	, win=$ws
	popupmenu imgopt,disable=(tab!=2), win=$ws
	popupmenu imgHopt,disable=(tab!=2), win=$ws
	popupmenu imgVopt,disable=(tab!=2), win=$ws
	popupmenu imgZTopt,disable=(tab!=2), win=$ws
	button doneROI,disable=1	, win=$ws//should always be hidden at this point
	popupMenu ROIColor,disable=(tab!=2), win=$ws
	popupMenu ROIAll,disable=(tab!=2), win=$ws
	if((isNew==0)*(tab!=1))
		ROIUpdatePolys(df,tab==2)	//hide ROI when not on color tab
	endif

	// Axes ==========================
	checkbox hasHI,disable=(tab!=3)||(ndim<3)	, win=$ws	//axes
	checkbox hasVI,disable=(tab!=3)||(ndim<3), win=$ws
	checkbox hasHP,disable=(tab!=3), win=$ws
	checkbox hasVP,disable=(tab!=3), win=$ws
	checkbox ZTPMode,disable=(tab!=3)||(ndim<4), win=$ws
	checkbox hasZP,disable=(tab!=3)||(ndim<3), win=$ws
	checkbox hasTP,disable=(tab!=3)||(ndim<4), win=$ws
	checkbox transXY,disable=(tab!=3), win=$ws
	popupmenu dim3index,disable=(tab!=3)||(ndim<3), win=$ws
	popupmenu dim4index,disable=(tab!=3)||(ndim<3), win=$ws
	checkbox AutoScaleHP,disable=(tab!=3), win=$ws		//axes
	checkbox AutoScaleVP,disable=(tab!=3), win=$ws
	checkbox MatchZAxes,disable=(tab!=3), win=$ws
	checkbox HideCursors,disable=(tab!=3), win=$ws
	slider sliderLeft,disable=(tab!=3), win=$ws
	slider sliderBottom,disable=(tab!=3), win=$ws
	// Export ==============================
	popupmenu export,disable=(tab!=4)	, win=$ws//export
	button animate,disable=(tab!=4), win=$ws
	button exportCropped,disable=(tab!=4)||(ndim<3), win=$ws
	Button DupButtonV, disable=(tab!=4), win=$ws
	Button ShowInDataBrowserButton, disable=(tab!=4), win=$ws
	Button CreateStyleMacroButton, disable=(tab!=4), win=$ws
   // Lineout ==============================
	button drawpoly, disable=(tab!=5), win=$ws 	//lineout
	variable disab
	if (tab==5)
		disab=2*(!exists(df+"ycontour"))
	else
		disab=1
	endif
	button extractProfile,disable=disab, win=$ws
	button extractLine,disable=tab!=5, win=$ws
	button killLine,disable=tab!=5, win=$ws
	button killPoly,disable=disab, win=$ws
	button donepoly,disable=1, win=$ws	//at this point button should always be invisible

	Button Bstack,disable=tab!=5, win=$ws
	SetVariable Csetstackoffset,disable=tab!=5, win=$ws

	//avg==============================
	groupBox MAvg,disable=(tab!=6)

	SetVariable setbin0,disable=(tab!=6),title=axistitle(df,0), win=$ws
	SetVariable setbin1,disable=(tab!=6),title=axistitle(df,1), win=$ws
	SetVariable setbin2,disable=(tab!=6),title=axistitle(df,2), win=$ws
	SetVariable setbin3,disable=(tab!=6),title=axistitle(df,3), win=$ws
	PopupMenu setbins,disable=(tab!=6), win=$ws
	
	checkbox setbincuropt0,disable=(tab!=6), win=$ws
	checkbox setbincuropt1,disable=(tab!=6), win=$ws
	checkbox setbincuropt2,disable=(tab!=6), win=$ws
	checkbox setbincuropt3,disable=(tab!=6), win=$ws

	// norm  ============================		
	nvar rebuild=$(df+"rebuild")
	svar dname=$(df+"dname")
	wave w=$dname
	if((isnew==1)+(rebuild==1))

		string u0="x ["+waveunits(w,0)+"];"
		string u1="y ["+waveunits(w,1)+"];"
		string u2=SelectString(wavedims(w)>2,"", "z ["+waveunits(w,2)+"];")
		string u3=SelectString(wavedims(w)>3,"","t ["+waveunits(w,3)+"];")
		execute "popupmenu  cNorm1_AXIS, value=\"" + u0+u1+u2+u3+"\""+",win=$IT5WinName(\""+df+"\")"
		execute "popupmenu  cNorm2_AXIS, value=\"" + u0+u1+u2+u3+"\""+",win=$IT5WinName(\""+df+"\")"
		execute "popupmenu cNorm1_2DAXIS value=\""+Norm_2DAXIS_MenuList(df)+"\""+",win=$IT5WinName(\""+df+"\")"
		execute "popupmenu cNorm2_2DAXIS value=\""+Norm_2DAXIS_MenuList(df)+"\""+",win=$IT5WinName(\""+df+"\")"

		NVAR Norm1_Axis=$(df+"Norm1_Axis")
		STRUCT WMPopupAction PU_Struct
		PU_Struct.win=dfn
		PU_Struct.eventCode=2
		PU_Struct.popnum=Norm1_Axis+1
		PU_Struct.ctrlname="cNorm1_Axis"
		Norm1D_AxisMenu(PU_Struct)
		NVAR Norm2_Axis=$(df+"Norm2_Axis")
		PU_Struct.popnum=Norm2_Axis+1
		PU_Struct.ctrlname="cNorm2_Axis"
		Norm1D_AxisMenu(PU_Struct)

	endif

	groupBox MNorm1,disable=(tab!=7), win=$ws
	checkbox cNorm1_ON,disable=(tab!=7), win=$ws
	popupmenu cNorm1_Mode,disable=(tab!=7), win=$ws
	NVAR Mode= $(df+"Norm1_Mode")

	popupmenu cNorm1_AXIS,disable=(tab!=7 || mode!=1), win=$ws
	popupmenu cNorm1_Method,disable=(tab!=7 || mode!=1), win=$ws
	SetVariable cNorm1_x0,disable=(tab!=7 || mode!=1), win=$ws
	SetVariable cNorm1_x1,disable=(tab!=7 || mode!=1), win=$ws

	popupmenu cNorm1_2DAXIS,disable=(tab!=7 || mode!=2), win=$ws


	groupBox MNorm2,disable=(tab!=7), win=$ws
	checkbox cNorm2_ON,disable=(tab!=7), win=$ws
	popupmenu cNorm2_Mode,disable=(tab!=7), win=$ws
	NVAR Mode= $(df+"Norm2_Mode")

	popupmenu cNorm2_AXIS,disable=(tab!=7 || mode!=1), win=$ws
	popupmenu cNorm2_Method,disable=(tab!=7 || mode!=1), win=$ws
	SetVariable cNorm2_x0,disable=(tab!=7 || mode!=1), win=$ws
	SetVariable cNorm2_x1,disable=(tab!=7 || mode!=1), win=$ws

	popupmenu cNorm2_2DAXIS,disable=(tab!=7 || mode!=2), win=$ws

	// Link =====================

	CheckBox LinkCheckBox, disable=(tab!=8), win=$ws

	popupmenu LinkedImageTool5, disable=(tab!=8), win=$ws
	groupBox MLink , disable=(tab!=8), win=$ws
	CheckBox setLink0, disable=(tab!=8), win=$ws
	CheckBox setLink1, disable=(tab!=8), win=$ws
	CheckBox setLink2, disable=(tab!=8), win=$ws
	CheckBox setLink3, disable=(tab!=8), win=$ws

	SetVariable setLinkOffset0, disable=(tab!=8),title=axistitle(df,0),limits={-inf,inf,dimdelta(w,0)}, win=$ws
	SetVariable setLinkOffset1, disable=(tab!=8),title=axistitle(df,1),limits={-inf,inf,dimdelta(w,1)}, win=$ws
	SetVariable setLinkOffset2, disable=(tab!=8),title=axistitle(df,2),limits={-inf,inf,dimdelta(w,2)}, win=$ws
	SetVariable setLinkOffset3, disable=(tab!=8),title=axistitle(df,3),limits={-inf,inf,dimdelta(w,3)}, win=$ws

//	CheckBox setLinkBin, disable=(tab!=8)
	CheckBox setLinkgamma, disable=(tab!=8), win=$ws
	
	//Overlays ========================
	CheckBox OverLays_Show disable=(tab!=9) , win=$ws
	ListBox Overlay_List disable=(tab!=9), win=$ws
	Button AddOverlay disable=(tab!=9), win=$ws
	Button DeleteOverlay disable=(tab!=9), win=$ws
	Popupmenu Overlay_Color disable=(tab!=9), win=$ws
	PopupMenu Overlay_Linesyle disable=(tab!=9), win=$ws
	SetVariable Overlay_LineWidth disable=(tab!=9), win=$ws
end

function setupcontrols(df)
	string df
	string windowname = IT5WinName(df)
	//SplitString /E="root:([[:alnum:]]+):" df , windowname
	dowindow /F $windowname

	TitleBox version,pos={5,2},size={21,12},title="v"+num2str(MAJOR_VERSION) ,frame=0,fStyle=2

	button loadbuttonV, title="Load",pos={5,20},size={50,20},proc=LoadNewImgV
	tabcontrol tab0 proc=tabproc,size={600,80},pos={60,0}
	tabcontrol tab0 tablabel(0)="info",tablabel(1)="process",tablabel(2)="colors",tablabel(3)="axes",tablabel(4)="export",tablabel(5)="lineout",tablabel(6)="bin",tablabel(7)="norm", tablabel(8)="Link",tablabel(9)="Overlays"	
	NVAR tabnum= $(df+"tabnum")
	tabcontrol tab0 value=tabnum
	
	//INFO TAB
	variable cstarth=63,vstarth=22 , cstep=90 ,vstep=15
	SetVariable setXUnit,frame=0,noedit=1,pos={cstarth,vstarth},size={80,14},title=" ",value=$(df+"xlable")
	SetVariable setYUnit,frame=0,noedit=1,pos={cstarth + cstep,vstarth},size={80,14},title=" ",value=$(df+"ylable")
	SetVariable setZUnit,frame=0,noedit=1,pos={cstarth + 2*cstep,vstarth},size={80,14},title=" ",value=$(df+"zlable")
	SetVariable setTUnit,frame=0,noedit=1,pos={cstarth + 3*cstep,vstarth},size={80,14},title=" ",value=$(df+"tlable")
	cstarth=67+65
	CheckBox xlock pos={cstarth,vstarth},proc=CheckBoxProc,title=" "
	CheckBox xlock, help={"Lock X Cross hair"}
	CheckBox ylock pos={cstarth+cstep,vstarth},proc=CheckBoxProc,title=" "
	CheckBox ylock, help={"Lock Y Cross hair"}
	CheckBox zlock pos={cstarth+2*cstep,vstarth},proc=CheckBoxProc,title=" "
	CheckBox zlock, help={"Lock Z Cross hair"}
	CheckBox tlock pos={cstarth+3*cstep,vstarth},proc=CheckBoxProc,title=" "
	CheckBox tlock, help={"Lock T Cross hair"}
	cstarth=67;vstarth+=vstep 
	SetVariable setX0,pos={cstarth,vstarth},size={80,14},title="X"
	SetVariable setX0,help={"Cross hair X-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setX0,limits={-inf,inf,1},value=$(df+"xc")
	setvariable setXP,pos={cstarth,vstarth +vstep},size={80,14},title="XP"
	setvariable setXP,help={"Cross hair X-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	setvariable setXP,limits={0,inf,1},value=$(df+"xp"),disable=2 ,proc=SetPCursor
	SetVariable setY0,pos={cstarth+cstep ,vstarth},size={80,14},title="Y"
	SetVariable setY0,help={"Cross hair Y-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setY0,limits={-inf,inf,1},value= $(df+"yc")
	SetVariable setYP,pos={cstarth+cstep,vstarth +vstep},size={80,14},title="YP"
	SetVariable setYP,help={"Cross hair Y-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setYP,limits={0,inf,1},value=$(df+"yp"),disable=2 , proc=SetPCursor
	SetVariable setZ0,pos={cstarth+2*cstep,vstarth},size={80,14},title="Z"
	SetVariable setZ0,help={"Cross hair Z-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setZ0,limits={-inf,inf,1},value= $(df+"zc")
	SetVariable setZP,pos={cstarth+2*cstep,vstarth +vstep},size={80,14},title="ZP"
	SetVariable setZP,help={"Cross hair Z-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setZP,limits={0,inf,1},value=$(df+"zp"),disable=2 ,proc=SetPCursor
	SetVariable setT0,pos={cstarth+3*cstep,vstarth},size={80,14},title="T"
	SetVariable setT0,help={"Cross hair T-value.  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setT0,limits={-inf,inf,1},value= $(df+"tc")
	SetVariable setTP,pos={cstarth+3*cstep,vstarth +vstep},size={80,14},title="TP"
	SetVariable setTP,help={"Cross hair T-value (index).  Updates when cross hair is moved.  Cross hair moves if value is manually changed."}
	SetVariable setTP,limits={0,inf,1},value=$(df+"tp"),disable=2, proc=SetPCursor
	ValDisplay valD0,pos={cstarth+4*cstep,vstarth},size={61,14},title="D"
	ValDisplay valD0,help={"Image intensity value at current cross hair (X,Y) location.  "}
	ValDisplay valD0,limits={0,0,0},barmisc={0,1000}
	execute "ValDisplay valD0,value="+df+"d0"	
	ValDisplay valDi,pos={cstarth+4*cstep,vstarth+20},size={61,14},title="Di"
	ValDisplay valDi,help={"Integrated data over bin range"}
	ValDisplay valDi,limits={0,0,0},barmisc={0,1000}
	execute "ValDisplay valDi,value="+df+"Di"	
	
	ValDisplay valDavg,pos={cstarth+4.7*cstep,vstarth},size={61,14},title="Da"
	ValDisplay valDavg,help={"Avergae of data over bin range"}
	ValDisplay valDavg,limits={0,0,0},barmisc={0,1000}
	execute "ValDisplay valDavg,value="+df+"D_avg"
	
	ValDisplay valDsdev,pos={cstarth+4.7*cstep,vstarth+20},size={61,14},title="Ds"
	ValDisplay valDsdev,help={"Standard deviation of data over bin range"}
	ValDisplay valDsdev,limits={0,0,0},barmisc={0,1000}
	execute "ValDisplay valDsdev,value="+df+"d_sdev"
	
	PopupMenu StoreData,pos={cstarth+490,vstarth},size={43,20},proc=StoreDataProc,title="Store Data", mode=0,value="New;Edit;Sort;Clear"
	Button CapturePoint,title="Capture Point",pos={cstarth+490,vstarth+23},size={90,20},proc=CapturePointProc

	//COLORS TAB
	variable x0=140, y0=17
	SetVariable setgamma,pos={66,y0+10},size={62,14},title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol",format="%3.3g",fsize=11, bodyWidth=55
	SetVariable setgamma,limits={0.01,Inf,0.05},value=$(df+"gamma")
	SetVariable setgamma, proc=GammaNumericProc

	variable n=7,slidelimit=1.5
	make /o/N=(2*n+1) $(df+"gamsliderticks")  =  -(p<n) *log((p<n)*alog(slidelimit)*(n-p)/n+(p>=n)) +   (p>n) *  log( (p>n)*alog(slidelimit)*(p-n)/n+(p<=n) )

	make /o/N=(2*n+1) /T $(df+"gamsliderlables")

	Slider slidegamma size={170,16},pos={66,47},ticks=0,vert=0,proc=GammaSliderProc,variable=$(df+"gammaslider")
	Slider slidegamma userTicks={$(df+"gamsliderticks") ,$(df+"gamsliderlables")};
	Slider slidegamma limits={-1.5,1.5,0.01}, ticks=1
	Slider slidegamma tkLblRot=90,fSize=5

	PopupMenu SelectCT,pos={x0,y0+7},size={43,20},proc=SelectCTList,title="CT"
	PopupMenu SelectCT,mode=0,value= #"colornameslist()"
	checkbox invertCT,pos={x0+50,y0+10},size={80,14},title="Invert?"
	execute "checkbox invertCT,variable="+df+"invertCT" 
	checkbox invertCT,help={"Invert color table"}
	CheckBox invertCT proc=InvertCTCheckProc

	checkbox HiResCT,pos={x0+105,y0+10},size={80,14},proc=CheckBoxProc,title="HiResCT?"
	execute "checkbox HiResCT,variable="+df+"HiResCT" 
	checkbox HiResCT,help={"Enable high resolution color tables."}
	checkbox HistNormCT,pos={x0+105,y0+27},size={80,14},proc=CheckBoxProc,title="Hist Norm?"
	execute "checkbox HistNormCT,variable="+df+"HistNormCT" 
	checkbox HistNormCT,help={"Enable histogram normalization."}


	x0=360 ; y0=17
	wave ROIcolor=$(df+"ROIColor")
	GroupBox groupCOpts title="Individual scale options", pos={x0,y0}, size={295,60}, fcolor=(65535,0,0)
	string imgopstring="\"Free;ROI;Lock;\M1-;Add ROI;Replace ROI;ShowROI;HideROI;Clear ROI;Set Color Table\""
	PopupMenu imgHOpt,pos={x0+9,y0+15},size={80,14},title="horiz"
	PopupMenu imgHOpt,mode=1,proc=ROIColorOption,value=#imgopstring,bodyWidth=55
	PopupMenu imgOpt,pos={x0+9,y0+36},size={80,14},title="main "
	PopupMenu imgOpt,mode=1,proc=ROIColorOption,value=#imgopstring,bodyWidth=55
	PopupMenu imgZTOpt,pos={x0+100,y0+15},size={80,14},title="corner"
	PopupMenu imgZTOpt,mode=1,proc=ROIColorOption,value=#imgopstring,bodyWidth=55
	PopupMenu imgVOpt,pos={x0+100,y0+36},size={80,14},title="vert   "
	PopupMenu imgVOpt,mode=1,proc=ROIColorOption,value=#imgopstring,bodyWidth=55
	button doneROI, title="Done",pos={x0-60,y0+34},size={50,32},proc=ROIDoneEditing,disable=1
	PopupMenu ROIColor title="ROI Color", pos={x0+190, y0+15}, size={100,32}
	PopupMenu ROIColor proc=ROIColorProc,value="*COLORPOP*"
	PopupMenu ROIColor popcolor=(ROIColor[0],ROIColor[1],ROIColor[2]),bodyWidth=55
	PopupMenu ROIAll,title="All  ", pos={x0+240,y0+36},proc=ROIAllColorOpts,bodyWidth=55
	PopupMenu ROIAll,mode=0,value=#"\"Free;ROI;\M1-;Show ROI;Hide ROI;Clear ROI\""
	nvar ndim=$df+"ndim"

	//AXES TAB
	cstarth=87; vstarth=20
	CheckBox hasHP pos={cstarth,vstarth},proc=CheckBoxProc,title="show horz prof"
	execute "checkbox hasHP,variable="+df+"hasHP"
	CheckBox hasVP pos={cstarth,vstarth+15},proc=CheckBoxProc,title="show vert prof"
	execute "checkbox hasVP,variable="+df+"hasVP"
	CheckBox hasHI pos={cstarth+93,vstarth},proc=CheckBoxProc,title="(3D) show horz img",disable=(ndim<3)
	execute "checkbox hasHI,variable="+df+"hasHI"
	CheckBox hasVI pos={cstarth+93,vstarth+15},proc=CheckBoxProc,title="(3D) show vert img", disable=(ndim<3)
	execute "checkbox hasVI,variable="+df+"hasVI"
	CheckBox ZTPmode pos={cstarth+218,vstarth},proc=CheckBoxProc,title="(4D) show ZT img",disable=(ndim<4)
	execute "checkbox ZTPmode,variable="+df+"ZTPmode"
	CheckBox hasZP pos={cstarth+218,vstarth+15},proc=CheckBoxProc,title="(3D) show Z prof",disable=(ndim<3)
	execute "checkbox hasZP,variable="+df+"hasZP"
	CheckBox hasTP pos={cstarth+218,vstarth+30},proc=CheckBoxProc,title="(4D) show T prof",disable=(ndim<4)
	execute "checkbox hasTP,variable="+df+"hasTP"

	CheckBox transXY pos={cstarth+50,vstarth+30},proc=CheckBoxProc,title="transpose 1st and 2nd axes"
	execute "checkbox transXY,variable="+df+"transXY"
	nvar dim3index=$(df+"dim3index")
	nvar dim4index=$(df+"dim4index")
	popupmenu dim3index,pos={cstarth+333,vstarth},proc=dim34setproc,title="3rd dimension is",mode=0,disable=(ndim<3)
	setupdim34value(df,"dim3index",dim3index)
	popupmenu dim4index,pos={cstarth+333,vstarth+22},proc=dim34setproc,title="4th dimension is",mode=0,disable=(ndim<3)
	setupdim34value(df,"dim4index",dim4index)

	CheckBox AutoScaleHP pos={cstarth +470,vstarth},proc=CheckBoxProc,title="SmartScale HP?"
	execute "checkbox AutoScaleHP,value="+df+"AutoScaleHP"
	CheckBox AutoScaleVP pos={cstarth +470,vstarth+15},proc=CheckBoxProc,title="SmartScale VP?"
	execute "checkbox AutoScaleVP,value="+df+"AutoScaleVP"
	CheckBox MatchZAxes  pos={cstarth +470,vstarth+30}, proc=CheckBoxProc,title="Match Z Axes"
	execute "checkbox MatchZAxes,value="+df+"MatchZAxes"
	CheckBox HideCursors  pos={cstarth +470,vstarth+45}, proc=CheckBoxProc,title="Hide Cursors"
	execute "checkbox HideCursors,value="+df+"HideCursors"

	Slider sliderLeft,pos={cstarth-20,vstarth},size={13,53},proc=SliderAxisProc
	Slider sliderLeft,limits={0.2,1.25,0},variable= $df+"leftAxisScale",live= 1,side= 0
	Slider sliderLeft, help={"Adjusts main image vertical size."}
	Slider sliderBottom,pos={cstarth,vstarth+47},size={53,13},proc=SliderAxisProc
	Slider sliderBottom,limits={0.2,1.25,0},variable= $df+"bottomAxisScale",live= 1,side= 0,vert= 0
	Slider sliderBottom, help={"Adjusts main image horizontal size."}

	//EXPORT TAB
	popupmenu Export,mode=0,pos={100,23},size={43,20},proc=ExportMenuProc,title="Export",value="-;X-wave;Y-wave;Z-wave;T-wave;-;H-image;V-image;-;Main Image;Corner Image"
	button Animate,pos={200,23},size={73,20},proc=AnimateProc,title="Animate"
	button ExportCropped,pos={100,46}, size={65,20},proc=DoExportCropped,title="Volume",disable=(ndim<3)
	button ExportCropped, help={"Export data using display axes mapping and visible ranges."}
	Button DupButtonV title="Duplicate ImageToolV",pos={501,29},size={150,20},proc=DuplicateButtonProc
	Button ShowInDataBrowserButton title="Show wave in Data Browser",pos={475,54},size={180,20},proc=ShowInDataBrowserButtonProc
	Button CreateStyleMacroButton title="Create Style Macro",pos={475,54},size={180,20},proc=CreateStyleMacroButtonProc

	
	//LINEOUT TAB
	Button drawPoly title="drawPoly",pos={70,22},size={100,20},proc=DrawPolyProc 
	Button donePoly,title="done",pos={70,45},size={100,20},proc=PolyDoneProc
	Button extractProfile,title="Extract w/Poly",pos={180,22},size={100,20},proc=ExtractPolyProc
	Button killPoly, title="Kill",pos={180,45},size={100,20},proc=KillPolyProc
	Button extractLine,title="Extract Line",pos={290,22},size={100,20},proc=ExtractLineProc
	Button killLine,title="Hide Lines",pos={290,45},size={100,20},proc=KillLineProc
	//stack
	Button Bstack,title="Stack",pos={450,22},size={100,20},proc=Stack_UpdateStackV
	SetVariable Csetstackoffset,pos={400,22},size={40,14},title=" "
	SetVariable Csetstackoffset,limits={1,Inf,1},value=$(df+"stack:pinc")

	//PROCESS TAB
	popupmenu ProcessROIDraw,mode=0,pos={70,22},size={100,20},proc=ProcessROIDraw,title="draw ROI",value="Rectangular;Polygon;Polygon Smooth;Select Pixel Range by Marquee;Select Particle by Marquee"
	//Button ProcessROIDone,title="done",pos={70,22},size={100,20},proc=ProcessROIDone
	popupmenu ProcessROIDone, title="Done...", pos={65,39}, size={100,20}, proc=ProcessROIDone, mode=0, disable=1, value="Add;Subtract"
	popupmenu ProcessROI,mode=0,pos={180,22},size={100,20},proc=ProcessUsingROI,title="Process w/ROI",value="Align Images;Zap Data;Integrate;IntegrateV2"
	CheckBox ShowProcessROIMask title="Show Mask?", pos={70,59},proc=ProcessROIMaskShowCheckProc
	Button ProcessROIkill,title="Kill ROI",pos={180,45},size={100,22},proc=ProcessROIkill
	popupmenu Process,mode=0,pos={290,22},size={100,20},proc=IT5process,title="Process",value="Zap NaNs;Clip Min/Max;Convolve Gaussian"
	Button TileButton,title="Tile Multiple Sets",pos={300,45},size={125,22},proc=doTile

	//Bin Tab
	svar dname=$(df+"dname")
	wave w=$dname
	x0=67; y0=17
	cstarth=100;vstarth=32
	cstep=125
	vstep=22
	variable bstep=70

	groupBox MAvg title="Binning",pos={x0,y0}, size={cstep*2,60},labelback=0

	SetVariable setbin0,pos={cstarth,vstarth},size={70,14},title=axistitle(df,0)
	execute "SetVariable setbin0,limits={1,"+num2str(dimsize(w,0))+",1},value="+df+"bin[0], bodywidth=40"
	SetVariable setbin0,help={"Set 1st axis binning range."}
	CheckBox setbincuropt0 pos={cstarth+bstep,vstarth},title=""
	execute "checkbox setbincuropt0,variable="+df+"bincuropt0"
	CheckBox setbincuropt0 ,help={"Show 1st axis binning range with cursors."}


	SetVariable setbin1,pos={cstarth,vstarth+vstep},size={70,14},title=axistitle(df,1)
	execute "SetVariable setbin1,limits={1,"+num2str(dimsize(w,1))+",1},value="+df+"bin[1], bodywidth=40"
	SetVariable setbin1,help={"Set 2nd axis binning range."}
	CheckBox setbincuropt1 pos={cstarth+bstep,vstarth+vstep},title=""
	execute "checkbox setbincuropt1,variable="+df+"bincuropt1"
	CheckBox setbincuropt1 ,help={"Show 2nd axis binning range with cursors."}

	SetVariable setbin2,pos={cstarth+cstep,vstarth},size={70,14},title=axistitle(df,2)
	execute "SetVariable setbin2,limits={1,"+num2str(dimsize(w,2))+",1},value="+df+"bin[2], bodywidth=40"
	SetVariable setbin2,help={"Set 3rd axis binning range."}

	CheckBox setbincuropt2 pos={cstarth+cstep +bstep,vstarth},title=""
	execute "checkbox setbincuropt2,variable="+df+"bincuropt2"
	CheckBox setbincuropt2 ,help={"Show 3rd axis binning range with cursors."}


	SetVariable setbin3,pos={cstarth+cstep,vstarth+vstep},size={70,14},title=axistitle(df,3)
	execute "SetVariable setbin3,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"bin[3], bodywidth=40"
	SetVariable setbin3,help={"Set 4th axis binning range."}
	CheckBox setbincuropt3 pos={cstarth+cstep+bstep,vstarth+vstep},title=""
	execute "checkbox setbincuropt3,variable="+df+"bincuropt3"
	CheckBox setbincuropt3 ,help={"Show 4th axis binning range with cursors."}

	PopupMenu setbins,mode=0,pos={cstarth+2*cstep,vstarth},title="set all to...",value="1;3;5;7;9;11;21;31;51;101", proc=SetBinsPopMenuProc
	

	//Norm Tab
	x0=67; y0=17
	cstarth=x0+3;vstarth=y0+15
	cstep=60
	vstep=22
	bstep=70
	svar dname=$(df+"dname")
		wave w=$dname
		string u0="x ["+waveunits(w,0)+"];"
		string u1="y ["+waveunits(w,1)+"];"
		string u2=SelectString(wavedims(w)>2,"", "z ["+waveunits(w,2)+"];")
		string u3=SelectString(wavedims(w)>3,"","t ["+waveunits(w,3)+"];")
		execute "popupmenu  cNorm1_AXIS, value=\"" + u0+u1+u2+u3+"\""
		execute "popupmenu  cNorm2_AXIS, value=\"" + u0+u1+u2+u3+"\""
		execute "popupmenu cNorm1_2DAXIS value=\""+Norm_2DAXIS_MenuList(df)+"\""
		execute "popupmenu cNorm2_2DAXIS value=\""+Norm_2DAXIS_MenuList(df)+"\""

	groupBox MNorm1 title="Norm1",pos={x0,y0}, size={292,60},labelback=0

	CheckBox cNorm1_ON pos={cstarth,vstarth+3},title=""
	CheckBox cNorm1_ON proc=Norm_On_Proc
	execute "checkbox cNorm1_ON,variable="+df+"Norm1_ON"
	CheckBox cNorm1_ON,help={"Check to activate normaliztion.\r eg. NormX = D(x,y,z,t)/Integrate(D(x1,y,z,t) dx1)"}

	nvar Norm1_mode=$(df+"Norm1_Mode")
	popupmenu cNorm1_Mode,mode=1,pos={cstarth+15,vstarth},size={43,20},proc=Norm_ModeProc,title="",value="1D;2D;3D"
	popupmenu cNorm1_Mode,help={"Number of dimensions to integrate."}

	popupmenu cNorm1_AXIS,mode=1,pos={cstarth+1.25*cstep,vstarth},size={43,20},proc=Norm1D_AxisMenu,title="",userdata=df,value=""
	popupmenu cNorm1_AXIS,help={"Axis to integrate along."}

	popupmenu cNorm1_Method,mode=1,pos={cstarth+1.25*cstep,vstarth+vstep},size={43,20},proc=NormMethproc,title="",value="Data/Area;(Data-m)/(M-m);Data-min;(Data-m)/area"
	popupmenu cNorm1_Method,help={"Normalization method.\r m=Min\r M=Max"}

	SetVariable cNorm1_x0,pos={cstarth+3.5*cstep,vstarth+3},size={70,14},title="x0"
	SetVariable cNorm1_x0,help={"Start of normalization range"}
	execute "SetVariable cNorm1_x0,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"Norm1_X0, bodywidth=60"
	SetVariable cNorm1_x1,pos={cstarth+3.5*cstep,vstarth+vstep+3},size={70,14},title="x1"
	SetVariable cNorm1_x1,help={"End of normalization range"}
	execute "SetVariable cNorm1_x1,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"Norm1_X1, bodywidth=60"


	popupmenu cNorm1_2DAXIS,mode=Norm1_mode,pos={cstarth+1.25*cstep,vstarth},size={43,20},proc=Norm2D_AxisMenu,title="",userdata=df,value=""


	x0=363; y0=17
	cstarth=x0+3;vstarth=y0+15
	cstep=60
	vstep=22
	bstep=70


	groupBox MNorm2 title="Norm2",pos={x0,y0}, size={292,60},labelback=0

	CheckBox cNorm2_ON pos={cstarth,vstarth+3},title=""
	CheckBox cNorm2_ON proc=Norm_On_Proc
	execute "checkbox cNorm2_ON,variable="+df+"Norm2_ON"
	nvar Norm2_mode=$(df+"Norm2_Mode")

	popupmenu cNorm2_Mode,mode=Norm2_mode,pos={cstarth+15,vstarth},size={43,20},proc=Norm_ModeProc,title="",value="1D;2D;3D"

	popupmenu cNorm2_AXIS,mode=1,pos={cstarth+1.25*cstep,vstarth},size={43,20},proc=Norm1D_AxisMenu,title="",userdata=df,value=""
	popupmenu cNorm2_Method,mode=1,pos={cstarth+1.25*cstep,vstarth+vstep},size={43,20},proc=NormMethproc,title="",value="Area;-m/(M-m);-m;-m/area"
	SetVariable cNorm2_x0,pos={cstarth+3.5*cstep,vstarth+3},size={70,14},title="x0"
	execute "SetVariable cNorm2_x0,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"Norm2_X0, bodywidth=60"
	SetVariable cNorm2_x1,pos={cstarth+3.5*cstep,vstarth+vstep+3},size={70,14},title="x1"
	execute "SetVariable cNorm2_x1,limits={1,"+num2str(dimsize(w,3))+",1},value="+df+"Norm2_X1, bodywidth=60"


	popupmenu cNorm2_2DAXIS,mode=1,pos={cstarth+1.25*cstep,vstarth},size={43,20},proc=Norm2D_AxisMenu,title="",userdata=df,value=""


	// Linking tab

	x0=67; y0=17
	cstarth=270;vstarth=32
	cstep=150
	vstep=22
	bstep=70

	CheckBox LinkCheckBox pos={70,vstarth+2},title="", proc=LinkCheckBoxProc 
	execute "checkbox LinkCheckBox,variable="+df+"Link"


	popupmenu LinkedImageTool5 mode=1,pos={90,vstarth},size={100,20},noproc,title="",value=WinList("ImageToolV*",";",""),noproc,mode=1

	groupBox MLink title="Offset and Link",pos={cstarth-cstep/3-10,17}, size={cstep*2,60},labelback=0

	SetVariable setLinkOffset0,pos={cstarth,vstarth},size={70,14},title=axistitle(df,0),bodyWidth=60,format="%.4g"
	execute "SetVariable setLinkOffset0,limits={-inf,inf,1},value="+df+"LinkOffset[0]"
	CheckBox setLink0 pos={cstarth+bstep,vstarth},title=""
	execute "checkbox setLink0,variable="+df+"LinkAxis0"

	SetVariable setLinkOffset1,pos={cstarth,vstarth+vstep},size={70,14},title=axistitle(df,1),bodyWidth=60,format="%.4g"
	execute "SetVariable setLinkOffset1,limits={-inf,inf,1},value="+df+"LinkOffset[1]"
	CheckBox setLink1 pos={cstarth+bstep,vstarth+vstep},title=""
	execute "checkbox setLink1,variable="+df+"LinkAxis1"

	SetVariable setLinkOffset2,pos={cstarth+cstep,vstarth},size={70,14},title=axistitle(df,2),bodyWidth=60,format="%.4g"
	execute "SetVariable setLinkOffset2,limits={-inf,inf,"+num2str(dimdelta(w,2))+"},value="+df+"LinkOffset[2]"
	CheckBox setLink2 pos={cstarth+cstep +bstep,vstarth},title=""
	execute "checkbox setLink2,variable="+df+"LinkAxis2"

	SetVariable setLinkOffset3,pos={cstarth+cstep,vstarth+vstep},size={70,14},title=axistitle(df,3),bodyWidth=60,format="%.4g"
	execute "SetVariable setLinkOffset3,limits={-inf,inf,1},value="+df+"LinkOffset[3]"
	CheckBox setLink3 pos={cstarth+cstep+bstep,vstarth+vstep},title=""
	execute "checkbox setLink3,variable="+df+"LinkAxis3"

	CheckBox SetLinkgamma pos={cstarth+1.7*cstep,vstarth},title="Link Gamma"
	execute "checkbox SetLinkgamma,variable="+df+"Linkgamma"
	
	//Overlays tab
	CheckBox OverLays_Show title="Show Overlays",pos={68,24},proc=OverLays_ShowCheckProc,variable=$(df+"Overlays_Show")
	ListBox Overlay_List pos={160,23},size={197,58},listWave=$(df+"Overlays_ListBox"),mode=6,proc=OverlayListBoxProc,selWave=$(df+"Overlays_ListBoxSelection"), widths={15,100},colorWave=$(df+"Overlays_Color")
	Button AddOverlay pos={65,53},size={85,21}, title="Add Overlay"
	Button AddOverlay proc=AddOverlayButtonProc
	Button DeleteOverlay title="Delete Overlay",pos={360,25},size={100,21},proc=DeleteOverlayButtonProc
	PopupMenu Overlay_Color title="",value="*COLORPOP*",pos={361,55},proc=OverLayColorPopMenuProc,popColor=(65535,0,0)
	PopupMenu Overlay_Linesyle title="",proc=OverlayLinestylePopMenuProc,value="*LINESTYLEPOP*",pos={416,55}
	SetVariable Overlay_LineWidth limits={1,10,1}, pos={575,58},size={45,14}, title=" ", value=$(df+"Overlay_LineWidth"), proc=Overlay_LineWidthSetVarProc
end

function /S axistitle(df,n) 
	string df
	variable n
	svar dname=$(df+"dname")
	wave w=$(dname)
	string wu=waveunits(w,n)
	if (strlen(wu)==0)
		if(dimsize(w,n)==0)
			return " "
		else
			return "axis"+num2str(n)
		endif
	else
		return wu
	endif
end



Function Norm_On_Proc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	switch( cba.eventCode )
		case 2: // mouse up
			string df=getDFfromName(cba.win)
			string ctrlName=cba.ctrlName
			variable Norm_num=str2num( ctrlname[5,5])
			string Norm_Name="Norm"+num2str(Norm_num)
			svar dname=$(df+"dname")
			Variable checked = cba.checked
			if (checked==1)
				NormSetup(df,Norm_Num)
			else
				execute df+Norm_name+"_trig=0"
				execute df+Norm_name+"=0"
				setupV(getdfname(),dname)
			endif
			break
	endswitch
	return 0
End

Function NormSetup(df,Norm_Num)
	string df
	variable Norm_Num
	svar dname=$(df+"dname")
	wave w=$dname
	string Norm_Name="Norm"+num2str(Norm_num)
	NVAR Mode= $(df+Norm_Name+"_Mode")
	NVAR Norm_ON= $(df+Norm_Name+"_ON")
	if(Norm_ON==1)
	switch (mode)
		case 1:
			Nvar axis=$(df+Norm_Name+"_Axis")
			Nvar method=$(df+Norm_Name+"_Method")
			Norm1D_Setup(df,dname,Norm_Name,Norm_Num,axis,method)
			setupV(getdfname(),dname)
			break
		case 2:
			Nvar axis=$(df+Norm_Name+"_2DAxis")
			Norm2D_Setup(df,dname,Norm_Name,Norm_Num,axis,0)
			setupV(getdfname(),dname)
	endswitch
	endif
end

Function Norm_ModeProc(PU_Struct)
	STRUCT WMPopupAction &PU_Struct
	if(PU_Struct.eventCode==2)
		string df=getDFfromName(PU_Struct.win)
		svar dname=$(df+"dname")
		wave w=$dname
		string ctrlName=PU_Struct.ctrlName
		variable Norm_num=str2num( ctrlname[5,5])
		Nvar axis=$(df+"Norm"+num2str(Norm_num)+"_Axis")
		string nn="Norm"+num2str(Norm_num)
		NVAR Mode= $(df+nn+"_Mode")
		Nvar method=$(df+"Norm"+num2str(Norm_num)+"_Method")
		Mode=PU_Struct.popnum
		NormSetup(df,Norm_Num)
		tabproc("",7)
	endif
end


Function NormMethProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	if(PU_Struct.eventCode==2)
		string df=getDFfromName(PU_Struct.win)
		svar dname=$(df+"dname")
		wave w=$dname
		string ctrlName=PU_Struct.ctrlName
		variable Norm_num=str2num( ctrlname[5,5])
		Nvar method=$(df+"Norm"+num2str(Norm_num)+"_Method")
		method = PU_Struct.popnum-1
		Nvar axis=$(df+"Norm"+num2str(Norm_num)+"_Axis")
		string nn="Norm"+num2str(Norm_num)
		NVAR Mode= $(df+nn+"_Mode")

		Norm1D_Setup(df,dname,nn,Norm_Num,axis,method)
	endif
end

Function Norm1D_Setup(df,dname,nn,Norm_Num,axis,method)
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
		execute ANorm_name+"_trig:=calcNorm2("+ANorm_name+","+dname+","+ANorm_name1+","+num2str(method)+","+num2str(axis)+","+df+nn+"_p0,"+df+nn+"_p1)"
	endif
end

Function Norm1D_AxisMenu(PU_Struct)
	STRUCT WMPopupAction &PU_Struct
	if(PU_Struct.eventCode==2)
		string df=getDFfromName(PU_Struct.win)
		svar dname=$(df+"dname")
		wave w=$dname
		string ctrlName=PU_Struct.ctrlName
		variable Norm_num=str2num( ctrlname[5,5])
		Nvar axis=$(df+"Norm"+num2str(Norm_num)+"_Axis")
		axis=PU_Struct.popNum-1
		 popupmenu $ctrlName,mode=axis+1

		string nn="Norm"+num2str(Norm_num)
		NVAR Mode= $(df+nn+"_Mode")
		NVAR Norm_ON= $(df+nn+"_ON")
		if(Norm_ON==1)
			Norm1D_Setup(df,dname,nn,Norm_Num,axis,0)
		endif
		variable x0=-inf
		variable x1=inf
		getmarquee left, bottom
		if(V_flag==1)
			variable dn
			string dfn=getdfname()
			variable avgx=PixelFromAxisVal(dfn,"bottom",(V_left +V_right)/2)
			variable avgy=PixelFromAxisVal(dfn,"left",(V_top+V_bottom)/2)
			string imgname=whichimage(dfn,avgx,avgy)
			string tracename=whichtrace(dfn,avgx,avgy)

			struct imageWaveNameStruct s

			if(strlen(imgname)>0)
				getimageinfo(df,imgname,s)	
			elseif(strlen(tracename)>0)
				gettraceinfo(df,tracename,s)	
			endif
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
		variable x0L=dimoffset(w,axis)
		variable x1L=dimoffset(w,axis)+dimdelta(w,axis)*dimsize(w,axis)
		x0=max(x0,x0L)
		x1=min(x1,x1L)
		NVAR Norm_X0=$(df+nn+"_X0")
		NVAR Norm_X1=$(df+nn+"_X1")
		Norm_X0=x0
		Norm_X1=x1
		string X0n = num2str(dimoffset(w,axis))
		string Xdn = num2str(dimdelta(w,axis))

		execute df+nn+"_p0:=("+df+nn+"_x0-("+x0n+"))/"+Xdn
		execute df+nn+"_p1:=("+df+nn+"_x1-("+x0n+"))/"+Xdn
		execute "SetVariable c"+nn+"_x0,limits={"+num2str(min(x0L,x1L))+","+num2str(max(x0L,x1L))+","+num2str(dimdelta(w,axis))+"},value="+df+nn+"_X0, title=\""+axistitle(df,axis)+"0\""
		execute "SetVariable c"+nn+"_x1,limits={"+num2str(min(x0L,x1L))+","+num2str(max(x0L,x1L))+","+num2str(dimdelta(w,axis))+"},value="+df+nn+"_X1, title=\""+axistitle(df,axis)+"1\""
	endif
end

Function /S Norm_2DAXIS_MenuList(df)
	string df
	SVAR dname = $(df+"dname")
	WAVE dwave = $dname
	variable n=wavedims(dwave)
	variable ii=0,jj=1
	string menulist =""
	for(jj=1;jj<n;jj+=1)
		for(ii=0;ii<jj;ii+=1)
			menulist += 	axistitle(df,ii) +" vs " + 	axistitle(df,jj) +";"
		endfor
	endfor
	return menulist
end	


function Norm2Dindex2axis(index,axis)
	variable index,axis
	variable temp = trunc((sqrt(8*index+1)+1)/2)
	if(axis==0)
		return index-temp*(temp-1)/2
	else
		return temp
	endif
end

function Norm2Daxes2index(axis0,axis1)
	variable axis0,axis1
	return axis0+axis1*(axis1-1)/2
end

Function Norm2D_Setup(df,dname,nn,Norm_Num,Axes_index,method)
	string df,dname,nn
	variable Norm_Num,Axes_index,method
	make /o/N=4 dims
	variable i=0,j=0
	wave dwave=$dname
	for(i=0;i<4;i+=1)
		dims[i]=dimsize(dwave,i)
	endfor
	dims[Norm2Dindex2axis(Axes_index,0)]=1
	dims[Norm2Dindex2axis(Axes_index,1)]=1
	string ANorm_name=df+"Norm"+num2str(Norm_Num)
	if(method==0)
		make /o  /N=(dims[0],dims[1],dims[2],dims[3]) $ANorm_name
	else
		make /o  /C/N=(dims[0],dims[1],dims[2],dims[3]) $ANorm_name
	endif
	wave Anormw=$ANorm_name
	string axis_name = ANorm_name+"_2DaxisWave"
	make /O/N=4 $axis_name
	wave axis= $axis_name
	axis[0]=Norm2Dindex2axis(Axes_index,0)
	axis[1]=Norm2Dindex2axis(Axes_index,1)
	variable ii,jj=2
	for(ii=0;ii<4;ii+=1)
		if(ii!=axis[0]&&ii!=axis[1])
			axis[jj]=ii
			jj+=1
		endif
	endfor
	string temp_name=ANorm_name+"_temp"
	make /O/N=(dimsize(dwave,axis[0]),dimsize(dwave,axis[1])) $temp_name
	wave temp=$temp_name
	variable /g $(ANorm_name+"_trig")
	NVAR trig=$(ANorm_name+"_trig")
	trig=0
//	if(norm_num==1)
		execute ANorm_name+"=norm2d_func("+temp_name+","+dname+","+num2str(method)+","+axis_name+","+axisIGORvariable(axis[2])+","+axisIGORvariable(axis[3])+")"
//	elseif(norm_num==2)
//		string ANorm_name1=df+"Norm"+num2str(1)
//		execute ANorm_name+"_trig:=calcNorm2("+ANorm_name+","+dname+","+ANorm_name1+","+num2str(method)+","+num2str(axis)+","+df+nn+"_p0,"+df+nn+"_p1)"
//	endif
end

function /S axisIGORvariable(axis)
	variable axis
	switch (axis)
		case 0:
			return "p"
		case 1:
			return "q"
		case 2:
			return "r"
		case 3:
			return "s"
		endswitch
end

function /C norm2d_func(norm2dtemp,dwave,method,axis,p0,p1)
	wave norm2dtemp,dwave,axis
	variable method, p0,p1
	extractplane(norm2dtemp,dwave,axis,p0,p1)
	wavestats /Q norm2dtemp
	return 1/V_avg
end

Function Norm2D_AxisMenu(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	if(PU_Struct.eventCode==2)
		string df=getDFfromName(PU_Struct.win)
		svar dname=$(df+"dname")
		wave w=$dname
		string ctrlName=PU_Struct.ctrlName
		variable Norm_num=str2num( ctrlname[5,5])
		Nvar axis=$(df+"Norm"+num2str(Norm_num)+"_Axis")
		axis=PU_Struct.popNum-1
		popupmenu $ctrlName,mode=axis+1

		string nn="Norm"+num2str(Norm_num)
		NVAR Mode= $(df+nn+"_Mode")
		NVAR Norm_ON= $(df+nn+"_ON")
		variable /g $(df+nn+"_2Daxis") = axis
		if(Norm_ON==1)
			Norm2D_Setup(df,dname,nn,Norm_Num,axis,0)
		endif
	endif
end

//Function ProcessROIDraw(ctrlName,popNum,popStr) : PopupMenuControl
Function ProcessROIDraw(PU) : PopupMenuControl
	STRUCT WMpopupAction &PU
	String ctrlName=PU.ctrlname
	Variable popNum=PU.popnum
	String popStr=PU.popStr
	string ROIName=getROIname(ctrlName)
	string df=getdf()
	popupmenu $(ROIName+"ROIdone"),disable=0
	nvar processROImode=$(df+ROIName+"ROIMode")
	processROIMode=popnum
	make/o/n=0 proc_ROIy, proc_ROIx
	make/o/n=0 sel_ROIy, sel_ROIx
	
	wave processROIx=$(df+ROIName+"ROIx"), processROIy=$(dF+ROIName+"ROIy")
	// 	removefromgraph/z processROIy
	switch(abs(processROIMode))	
		case 1:		//rect
			//user makes marquee then presses done
			break		
		case 2:		//polygon
			graphwavedraw/o/L=left/B=bottom proc_ROIy, proc_ROIx
			break
		case 3:		//polygon smooth
			graphwavedraw/f=3/o/L=left/B=bottom proc_ROIy, proc_ROIx
			break
		case 4: //select pixel range by Marquee
			//user makes marquee then presses done
			break
		case 5: //select particle by Marquee
			//user makes marquee within a particle, then presses done
			break  
	endswitch
end

function setRectFromMarquee(wvx,wvy)
	wave wvx,wvy
	getmarquee/k left bottom
	redimension/n=5 wvx, wvy
	if(v_flag)
		wvx={v_left,v_right,v_right,v_left, v_left}
		wvy={v_bottom, v_bottom, v_top, v_top, v_bottom}
		return 0
	else
		print "error: no marquee was drawn"
		return -1
	endif
end

function reorderRectByPixels(wx,wy,img)
	wave wx,wy,img
	variable px0,px1,py0,py1
	px0=ScaleToIndex(img,wx[0],0)
	px1=ScaleToIndex(img,wx[1],0)
	py0=ScaleToIndex(img,wy[0],1)
	py1=ScaleToIndex(img,wy[2],1)
	if (px0>px1) 
		duplicate/o wx tempx_A45
		tempx_A45={wx[1],wx[0],wx[0],wx[1],wx[1]}
		wx=tempx_A45
		killwaves tempx_A45
	endif
	if (py0>py1) 
		duplicate/o wy tempy_A45
		tempy_A45={wy[2],wy[2],wy[0],wy[0],wy[2]}
		wy=tempy_A45
		killwaves tempy_A45
	endif
end

	
//Function ProcessROIDone(ctrlName) : ButtonControl
Function ProcessROIDone(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	String ctrlName=pa.ctrlname
	string df=getdf()
	string ROIName=getROIname(ctrlName)
	graphnormal
	popupmenu $(ROIName+"ROIdone"),disable=1
	nvar processROImode=$(df+ROIName+"ROIMode")
	wave proc_ROIx, proc_ROIy, sel_ROIx, sel_ROIy
	removefromgraph/z proc_roiy
	wave prx=$(df+ROIName+"ROIx"), pry=$(dF+ROIName+"ROIy")
	wave img=$(df+"img")
	wave masktemp=$(df+"mask_temp")
	wave masktempsign=$df+"mask_temp_sign"
	nvar showmask=$(df+"ShowProcessROI")
	variable isSubtract=(pa.popnum==2)

	variable ii
	if (exists(df+"mask_temp"))
		ii=dimsize(masktemp,2)+1
	else
		duplicate/o img $(df+"mask_temp")
		make/o/n=1 $df+"mask_temp_sign"
		wave masktemp=$(df+"mask_temp")
		wave masktempsign=$df+"mask_temp_sign"
		ii=1
	endif
	redimension/n=(-1,-1,ii) masktemp
	redimension/n=(ii) masktempsign
	maskTempSign[ii]=isSubtract

	switch(processROIMode)
		case 1:	//rect
			setRectFromMarquee(proc_ROIx,proc_ROIy)
		case 2: //polygon drawn
		case 3: //smooth poly drawn
			//add drawn polygon to storage wave (automatically updates draw object in ProgFront layer)
			variable np=numpnts(prx)
			redimension/n=(numpnts(proc_ROIx)+1+np) prx, pry
			prx[np]=nan; pry[np]=nan
			prx[np+1,]=proc_roix[p-np-1]; 	pry[np+1,]=proc_roiy[p-np-1]
	
			//temporary store waves
			duplicate/o prx $df+"prx0"; wave prx0= $dF+"prx0"
			duplicate/o pry $df+"pry0"; wave pry0=$df+"pry0"
			//individually draw polygons and generate mask layers
			variable j=1 //skip first nan
			variable j1
			do
				j1=findNan(j,prx0)
				redimension/n=(j1-j) prx,pry
				prx[0,j1-j-1]=prx0[p+j]
				pry[0,j1-j-1]=pry0[p+j]
				imageGenerateROIMask/e=0/i=1 img
				wave m_roimask
				masktemp[][][ii-1]=m_roimask[p][q]
				j=j1+1
			while(j<numpnts(prx0))
			duplicate/o prx0 prx
			duplicate/o pry0 pry
			break
		case 4: //select pixel range by Marquee
		case 5: //select particle by Marquee
			if (setRectFromMarquee(sel_ROIx,sel_ROIy)>=0)
			   reorderRectByPixels(sel_ROIx,sel_ROIy,img)
				imagestats/GS={sel_ROIx[0],sel_ROIx[2],sel_ROIy[0],sel_ROIy[2]} img
				variable lo=v_min, hi=v_max
				switch(processROIMode)
					case 4:
						masktemp[][][ii-1]=(img[p][q]>=lo)&&(img[p][q]<=hi) //select all pixels in image based on range
						break
					case 5:
						wavestats/q sel_ROIx; variable cx=v_avg
						wavestats/q sel_ROIy; variable cy=v_avg
						imageseedfill/b=0 min=lo, max=hi, seedx=cx, seedy=cy, target=1, srcwave=$(df+"img")
						wave m_SeedFill
						masktemp[][][ii-1]=m_seedfill[p][q]
						break
				endswitch
				showmask=1; 	checkbox ShowProcessROIMask, value=1
			endif
			break
	endswitch
	
	//removefromgraph/z processROIy
//	imageGenerateROIMask/e=0/i=1 img
	//wave m_roimask
	duplicate/o img $(df+ROIName+"ROImask")
	wave rmask=$(df+ROIName+"ROImask")
	rmask=0
	variable kk
	if (exists(df+"mask_temp"))
		for(kk=0;kk<dimsize(masktemp,2);kk+=1)
			if(masktempsign[kk])
				rmask-=masktemp[p][q][kk]
			else
				rmask+=masktemp[p][q][kk]
			endif
		endfor
		rmask=selectnumber(rmask<0,rmask[p][q],0) //threshold at zero
		rmask=rmask>0  //cap at 1
	endif
	redimension/s rmask
	ProcessDrawROI(df,ROIName,1)
	if (showMask)
		doProcessROIMaskShowCheckProc(showmask, rmask)
	endif
end
	
//returns next index that's non, or numpnts(w) if end of wave is reached	
function findnan(index, w)
	variable index
	wave w
	variable i
	if (index<numpnts(w)-1)
		i=index
		do
			if((numtype(w[i])==2))
				return i
			else
				i+=1
			endif
		while(i<numpnts(w))
		return i
	else
		return -1
	endif
end

Function ProcessROIMaskShowCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	switch( cba.eventCode )
		case 2: // mouse up
			string df=getdf()
			nvar checked=$(df+"ShowProcessROI")
			wave rmask=$(df+"ProcessROImask")
			checked = cba.checked
			doProcessROIMaskShowCheckProc(checked, rmask)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

function doProcessROIMaskShowCheckProc(checked, rmask)
	variable checked
	wave rmask
	if(WaveExists(rmask))
		removeimage/z $nameofwave(rmask)
		if(checked)
			appendimage/l/b rmask
			modifyimage $nameOfWave(rmask) explicit=1, eval={0,-1,-1,-1}, eval={1,60000,60000,0}
		endif
	endif	

end
	
function/T IT5WinName(df)
	string df
	return parsefilepath(0,df,":",1,0)
end
	
function ProcessDrawROI(df,ROIname,show)
	string df; string ROIName;variable show
	wave prx=$(df+ROIName+"ROIx"), pry=$(dF+ROIName+"ROIy")
	setdrawlayer/k progfront
	setdrawenv/w=$IT5WinName(df) fillpat=0, xcoord=bottom, ycoord=left,linethick=show,linefgc=(65535,0,0)
	drawpoly/abs 0,0,1,1,prx,pry
	setdrawlayer userfront
end

Function ProcessROIKill(ctrlName) : ButtonControl
	String ctrlName
	string ROIName=getROIname(ctrlName)
	string df=getdf()
	wave prx=$(df+ROIName+"ROIx"), pry=$(dF+ROIName+"ROIy")
	redimension/n=0 prx, pry
	if(exists(df+ROIName+"ROImask"))
		WAVE wv=$(df+ROIName+"ROIMask")
		wv=0	
	endif
	if(exists(df+"mask_temp")&&(cmpstr(ROIName,"Process")==0))
		killwaves $(df+"mask_temp")
	endif
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

static function index2cursorVal(df,i)
	string df;variable i
	switch(i)
		case 0: 
			nvar xp=$df+"xp"
			return xp
		case 1:
			nvar yp=$df+"yp"
			return yp
		case 2:
			nvar zp=$df+"zp"
			return zp
		case 3:
			nvar tp=$df+"tp"
			return tp
	endswitch
end

Function ProcessUsingROI(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	nvar ndim=$(dF+"ndim")
	svar dname=$(dF+"dname")
	wave wv=$dname
	wave mask=$(dF+"processROImask")
	wave dnum=$df+"dnum"
	strswitch(popStr)
		case "Zap Data":
			variable dvalue=0,option=1
			prompt dvalue,"Data value to zap to (or NaN)"
			prompt option,"Overwriting option",popup "this plane of source wave;all planes in source wave"
			doPrompt "Overwriting original wave !!",dvalue,option
			if(v_flag==0)
				//not cancelled
				make/o/n=4 $df+"dnum2"
				wave dnum2=$dF+"dnum2"
				dnum2=p
				sort dnum,dnum2
//				dnum2[dnum[0]]=
				string ss=dname
				if(option==2)
					ss+="[][][][]"
				else
					variable ii //cycles over [p][q][r][s]
					for(ii=0;ii<4;ii+=1)
						if(dnum2[ii]>1)
							ss+=selectstring(option==1,"[]","["+num2str(index2cursorVal(df,dnum2[ii]))+"]")
						else
							ss+="[]"							
						endif
					endfor
				endif
				string spi="pqrs"
				ss+="=selectnumber("+df+"processROImask"+"["+spi[dnum[0]]+"]" + "["+spi[dnum[1]]+"]==1,"+dname+"[p][q][r][s],"
				ss+=num2str(dvalue)+")"

				execute ss
				doupdate

			endif
			break	
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
			variable daisyChain
			prompt name,"Name of new 3d output wave"
			prompt daisyChain,"Alignment Method",popup "To reference image;To Previous Image"
			doprompt "Align Images",name,daisychain
			wave img=$(dF+"img"), imgh=$(dF+"imgh")
			nvar zc=$(df+"zc")
			variable i=0,nz=dimsize(imgh,1),z0=dimoffset(imgh,1),zd=dimdelta(imgh,1),xd=dimdelta(img,0),yd=dimdelta(img,1)
			variable nx=dimsize(img,0),ny=dimsize(img,1)
			//zc=z0+(nz-1)*zd;// print zc
			zc=round(zc)
			doupdate
			make/o/n=(nx,ny,nz) $name
			make/o/n=(nx,ny) pa_imgref, pa_imgtest
			pa_imgref=img[p][q]
			duplicate/o mask pa_testmask, pa_refmask
			wave wvout=$name
			copyscales/p wv,wvout,pa_imgref,pa_imgtest
			make/o/n=(dimsize(imgh,1)) $df+"pa_za", $df+"pa_ia"
			variable zn=dimsize(imgh,1)
			wave paza=$df+"pa_za", paia=$df+"pa_ia"
			if(zc==0) 
				paia=p
			else
				if(zc==zn-1)
					paia=zn-1-p
				else
					paia[0,zc]=zc-p
					paia[zc+1,]=p
				endif
			endif
			duplicate/o pa_imgref pa_imgref2
			paza=z0+paia*zd
			for(i=0;i<dimsize(imgh,1);i+=1)
				zc=paza[i]  //z0 + i*zd
				doupdate
				pa_imgtest=img[p][q]
				imageregistration/q/rot={0,0,0}/skew={0,0,0} testwave=pa_imgtest, refwave=pa_imgref, testmask=pa_testmask, refmask=pa_refmask
				wvout[][][i]=interp2d(img,x-xd*w_regparams[0],y-yd*w_regparams[1])
				//print i,w_regparams[0],w_regparams[1]
				if(daisyChain==2)
					if(paia[i]==0)
						pa_imgref=pa_imgref2	//about to go back to start, get back original reference
					else
						pa_imgref=pa_imgtest[p][q]
					endif

				endif
			endfor
			killwaves pa_imgref,pa_imgtest
			break
		case "Integrate" :
			dointegV1(df,ndim,wv,dnum)
		break //integrate
		case "IntegrateV2" :
			dointegV2(df,ndim,wv,dnum)
		break //integrate2
	endswitch
end

function doIntegV2(df,ndim,wv,dnum)
	string df
	variable ndim
	wave wv,dnum
	wave rmask=$(df+"ProcessROIMask")
	switch(ndim)
		case 2:
			//answer is a scalar
			duplicate/o rmask $(df+"u8mask")
			wave u8m=$(df+"u8mask")
			wave img=$(df+"img")
			redimension/u/b u8m
			u8m=1-u8m
			imagestats/r=u8m img
			string temp
			sprintf temp,"Total intensity=%f\n number of pixels=%d\n intensity/pixel=%f",V_avg*v_npnts, v_npnts, v_avg
			doalert 0, temp
		break
		case 3:
		case 4:
			string wvout=nameofwave(wv)+"_i"
			prompt wvout,"Enter wave name"
			variable nps=makeMaskPQlist(df,rmask)
			if(nps==0)
				abort "no mask points found"
			endif
			doprompt "Enter wave name",wvout
			if(v_flag)
				abort
			endif
			if (exists(wvout))
				doalert 1,"Wave " + wvout + " will be overwritten. Is that okay?"
			endif
			if(v_flag==2)
				abort
			endif
			variable dim2, dim3
			wave bin=$df+"bin"
			nvar zc=$(df+"zp")
			nvar tc=$(df+"tp")
			wave zcurx=$df+"zcurx"
			dim2=dimsize(wv,dnum[2])
			dim3=dimsize(wv,dnum[3])
			if(ndim==4)
				make/o/n=(dim2,dim3) $(df+"integ_result") //need to divide by #bins
			else
				make/o/n=(dim2) $(df+"integ_result") //need to divide by #bins
			endif
			wave integ=$(df+"integ_result")
			setscale/p x,dimoffset(wv,dnum[2]),dimdelta(wv,dnum[2]), waveunits(wv,dnum[2]), integ
			setscale/p y,dimoffset(wv,dnum[3]),dimdelta(wv,dnum[3]), waveunits(wv,dnum[2]), integ
			integ=0
			variable i
			wave pmP=$df+"processMaskP", pmQ=$df+"processMaskQ", pmV=$df+"processMaskV"
			string t0, t1, t2, t3,cmd, c0
			make/t/n=4/o $df+"twave"; wave/t twave=$df+"twave"
			openProgressWindow("Integrating...",nps,0)
			variable/g $df+"prog"; nvar prog=$df+"prog"
			nvar progress=root:progress
			execute "root:progress := "+df+"prog"
			t2="[p]"; twave[dnum[2]]=t2
			t3="[q]"; twave[dnum[3]]=t3
			c0=GetWavesDataFolder(integ,2) +"+=" + GetWavesDataFolder(wv,2)
			for(i=0;i<numpnts(pmP);i+=1)
				//prog=i
				updateprogresswindow(i)
				sprintf t0,"[%d]",pmP[i]; 	twave[dnum[0]]=t0
				sprintf t1,"[%d]",pmQ[i]; 	twave[dnum[1]]=t1
				//t0="["+num2str(pmP[i])+"]"; 	twave[dnum[0]]=t0	//slower
				//t1="["+num2str(pmQ[i])+"]"; 	twave[dnum[1]]=t1												
				cmd=c0+twave[0]+twave[1]+twave[2]
				if(ndim==4)
					cmd+=twave[3] 
				endif
				execute cmd
			endfor
			CloseProgressWindow()
			wave wvo=$wvout
			killwaves/Z wvo
			movewave $GetWavesDataFolder(integ,2), $wvout
			wave wvo=$wvout
			wvo/=numpnts(pmp)
			if(ndim==4)
				newimagetool5(wvout)
			else
				display wvo
			endif
			break
	endswitch
end

//creates PQ list of all nonzero values of the mask
//results stored in processMaskP, processMaskQ, processmaskV (= nonzero values)
//returns number of points
function makeMaskPQList(df,rmask)
	string df
	wave rmask
	variable xn=dimsize(rmask,0)
	variable yn=dimsize(rmask,1)
	make/n=(xn*yn)/o $df+"processMaskP", $df+"processMaskQ", $df+"processMaskVal"
	wave pmP=$df+"processMaskP", pmQ=$df+"processMaskQ", pmV=$df+"processMaskVal"
	pmP=mod(p,xn)
	pmQ=floor(p/xn)
	pmV=rmask[pmP[p]][pmQ[p]]
	sort/r pmV,pmV,pmP,pmQ
	findlevel pmV,0
	redimension/n=(v_levelx) pmV,pmP,pmQ
	return numpnts(pmV)
end


//integrates, with output binned according to setbin2 and setbin3 (axes 3 and 4)
function doIntegV1(df,ndim,wv,dnum)
	string df
	variable ndim
	wave wv,dnum
	wave rmask=$(df+"ProcessROIMask")
	duplicate/o rmask $(df+"u8mask")
	wave u8m=$(df+"u8mask")
	wave img=$(df+"img")
	redimension/u/b u8m
	u8m=1-u8m
	switch(ndim)	
		case 2:
			imagestats/r=u8m img
			string temp
			sprintf temp,"Total intensity=%f\n number of pixels=%d\n intensity/pixel=%f",V_avg*v_npnts, v_npnts, v_avg
			doalert 0, temp
			break		
		case 3:
		case 4:
			variable dim2, dim3, ri,si
			wave bin=$df+"bin"
			variable b2=bin[(dnum[2])] //z-profile binning in pixels
			variable b3=bin[(dnum[3])] //t-profile binning in pixels
			nvar zc=$(df+"zp")
			nvar tc=$(df+"tp")
			wave zcurx=$df+"zcurx"
			dim2=dimsize(wv,dnum[2]) / b2
			dim3=dimsize(wv,dnum[3]) / b3
			make/o/n=(dim2,dim3) $(df+"integ_result") //need to divide by #bins
			wave integ=$(df+"integ_result")
			//print dnum[2], dimoffset(wv,dnum[2])
			variable zstart=dimoffset(wv,dnum[2])+dimdelta(wv,dnum[2])*floor(b2/2)
			variable zdelta=dimdelta(wv,dnum[2])*b2	
			variable tstart=dimoffset(wv,dnum[3])+dimdelta(wv,dnum[3])*floor(b3/2)
			variable tdelta=dimdelta(wv,dnum[3])*b3
			setscale/p y tstart, tdelta, integ
			setscale/p x zstart, zdelta, integ 
			execute df+"zc="+num2str(zstart)
			//zc=dimoffset(wv,dnum[2])+dimdelta(wv,dnum[2])*floor(b2/2)
			si=0
			do
				execute df+"tc="+num2str(tstart)
				//tc=dimoffset(wv,dnum[3])+dimdelta(wv,dnum[3])*floor(b3/2)
				si=0
				do
					doupdate
					imagestats/r=u8m img
					//print ">",ri,si,zc,zcurx[3],v_avg, v_npnts
					integ[ri][si]=v_avg//*v_npnts
					execute df+"tc+="+num2str(tdelta)
					//tc+=dimdelta(wv,dnum[3])*b3
					si+=1
				while (si<dim3)
				ri+=1
				execute df+"zc+="+num2str(zdelta)
				//zc+=dimdelta(wv,dnum[2])*b2
			while (ri<dim2)
			duplicate/o integ root:wvout
			wave wv2=root:wvout
			string sss
			if (wavedims(integ)==2)
				sss="NewImageTool5(\"" + nameofwave(wv2) + "\")"
				execute sss
			else
				display wv2
			endif
			break
	endswitch //3, 4
end

proc doInteg34()
	string df=getdf()
	variable b2=$(df+"bin")[$(df+"dnum")[2])] //z-profile binning in pixels
	variable b3=$(df+"bin")[$(df+"dnum")[3]] //t-profile binning in pixels
end


Function IT5Process(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	svar dname=$(dF+"dname")
	wave wv=$dname
	strswitch(popstr)
		case "Zap NaNs":
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
		case "Convolve Gaussian":
			variable gx=.01, gy=.025
			prompt gx,"Enter horizontal gaussian width"
			prompt gy,"Enter vertical gaussian width"
			doprompt "Set gaussian parameters",gx,gy
			if(!v_flag)
				wave img=$df+"img"
				wave dnum=$df+"dnum"	//index wave
				variable nx=dimsize(img,dnum[0]), ny= dimsize(img,dnum[1])
				make/n=(selectnumber(nx/2==round(nx/2),nx+1,nx),selectnumber(ny/2==round(ny/2),ny+1,ny))/o $df+"convTemp"
				wave convTemp= $df+"convTemp"
				copyscales img,convTemp
				convTemp=img[p][q]
				duplicate/o convTemp $df+"g"
				wave g=$df+"g"
				variable x0=dimoffseT(g,0), xd=dimdelta(g,0), xn=dimsize(g,0), x1=x0+xn*xd,xa=(x1+x0)/2
				variable y0=dimoffseT(g,1), yd=dimdelta(g,1), yn=dimsize(g,1), y1=y0+yn*yd,ya=(y1+y0)/2
				g=exp(-((x-x0)/gx*1.6651)^2)*exp(-((y-y0)/gy*1.6651)^2)
				g+=exp(-((x-x0)/gx*1.6651)^2)*exp(-((y-y1)/gy*1.6651)^2)
				g+=exp(-((x-x1)/gx*1.6651)^2)*exp(-((y-y1)/gy*1.6651)^2)
				g+=exp(-((x-x1)/gx*1.6651)^2)*exp(-((y-y0)/gy*1.6651)^2)
				fft g
				fft convTemp
				execute df+"convtemp*= "+df+"g" 
				ifft convTemp
				copyscales img,convTemp
				duplicate/o convTemp convOut
				display; appendimage convOut

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
	string whInvertCT
	string whGamma
	string whGLock
	string ctwave
	string ctBwave
	variable hindex
	variable vindex
	string has
endstructure


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
	adjustCT(df,"img")
	adjustCT(df,"imgH")
	adjustCT(df,"imgV")	
	adjustCT(df,"imgZT")
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
	adjustCT(df,"img")
	adjustCT(df,"imgH")
	adjustCT(df,"imgV")	
	adjustCT(df,"imgZT")
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
	getimageinfo(df,"img",s)
	nvar ShowROI=$(df+s.showroi)
	wave xw=$(df+s.xwv), yw=$(df+s.ywv)
	setdrawenv/w=$IT5WinName(df) fillpat=0,xcoord=bottom, ycoord=left,linethick=showROI*show, linefgc=(r,g,b)
	drawpoly/abs 0,0,1,1,xw,yw
	if(hasHI)
		getimageinfo(df,"imgH",s)
		nvar hShowROI=$(df+s.showROI)
		wave xw=$(df+s.xwv), yw=$(df+s.ywv)
		setdrawenv/w=$IT5WinName(df) fillpat=0,xcoord=bottom, ycoord=imgHL,linethick=hshowROI*show, linefgc=(r,g,b)
		drawpoly/abs 0,0,1,1,xw,yw
	endif
	if(hasVI)
		getimageinfo(df,"imgV",s)
		nvar vShowROI=$(df+s.showROI)
		wave xw=$(df+s.xwv), yw=$(df+s.ywv)
		setdrawenv/w=$IT5WinName(df) fillpat=0,xcoord=imgVB, ycoord=left,linethick=vshowROI*show, linefgc=(r,g,b)
		drawpoly/abs 0,0,1,1,xw,yw
	endif
	if(ZTPmode*hasTP)
		getimageinfo(df,"imgZT",s)
		nvar ztShowROI=$(df+s.showROI)
		wave xw=$(df+s.xwv), yw=$(df+s.ywv)
		setdrawenv/w=$IT5WinName(df) fillpat=0,xcoord=imgZTt, ycoord=imgZTr,linethick=ztShowROI*show, linefgc=(r,g,b)
		drawpoly/abs 0,0,1,1,xw,yw
	endif
	setdrawlayer userfront	
end

//figures out for ctrlname="imgHopt" etc,  the names of the waves needed
//stores name "ctrlname" which was called for easy access when done editing ROI
static function ROIgetstrings(df,ctrlname,s)//xwv,ywv,image,imageROI,imode, haxis,vaxis,showROI
	string ctrlname
	struct imageWaveNameStruct &s
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
	return -1
end


function gettraceinfo(df,tracename,s)
	string tracename
	struct imageWaveNameStruct &s
	string df
	WAVE dnum=$(df+"dnum")
	variable returnval=0
	strswitch(tracename)
		case "Hprof":		
			//	s.xwv="imgrx"; s.ywv="imgry"
			s.image="px"
			s.vaxis="profHL"; s.haxis="bottom"
			s.hindex=dnum[0]
			s.vindex=-1
			s.has="hasHP"
			break
		case "Vprof":
			s.image="pyx"
			s.vaxis="left"; s.haxis="profVB"
			s.hindex=-1
			s.vindex=dnum[1]
			s.has="hasVP"
			break
		case "Zprof":
			s.image="pz"
			s.vaxis="profZR"; s.haxis="profZB"
			s.hindex=dnum[2]
			s.vindex=-1
			s.has="hasZP"
			break
		case "Tprof":
			s.image="pt"
			s.vaxis="profTR"; s.haxis="profTB"
			s.hindex=dnum[3]
			s.vindex=-1
			s.has="hasTP"
			break
		default:
		 returnval = 1
	endswitch
	return returnval
end

//static
function getimageinfo(df,imgname,s)
	string imgname
	struct imageWaveNameStruct &s
	string df
	WAVE dnum=$(df+"dnum")
	variable returnval=0
	strswitch(imgname)
		case "img":		
			//	s.xwv="imgrx"; s.ywv="imgry"
			s.image="img"; s.imageROI="imgROI"
			s.vaxis="left"; s.haxis="bottom"
			s.whCT="whichCT"
			s.whInvertCT="invertCT"
			s.whGamma="gamma_img"
			s.whGLock="Lockgamma_img"
			s.ctwave="ct"
			s.ctBwave="ctB"
			s.has="hasImg"
			s.hindex=dnum[0]
			s.vindex=dnum[1]
			break
		case "imgH":
			s.image="imgH"; s.imageROI="imgHROI"
			s.vaxis="imgHL"; s.haxis="bottom"
			s.whCT="whichCTh"	
			s.whInvertCT="invertCT_H"				
			s.whGamma="gamma_H"
			s.whGLock="Lockgamma_H"
			s.ctwave="ct_h"
			s.ctBwave="ctB_h"
			s.has="hasHI"
			s.hindex=dnum[0]
			s.vindex=dnum[2]
			break
		case "imgV":
			//	s.xwv="imgVrx"; s.ywv="imgVry"
			s.image="imgV"; s.imageROI="imgVROI";
			s.vaxis="left"; s.haxis="imgVB"
			s.whCT="whichCTv"
			s.whInvertCT="invertCT_V"
			s.whGamma="gamma_V"
			s.whGLock="Lockgamma_V"
			s.ctwave="ct_v"
			s.ctBwave="ctB_v"
			s.has="hasVI"
			s.hindex=dnum[2]
			s.vindex=dnum[1]
			break
		case "imgZT":
			s.xwv="imgZTrx"; s.ywv="imgZTry"
			s.image="imgZT"; s.imageROI="imgZTROI";
			s.vaxis="imgZTr"; s.haxis="imgZTt"
			s.whCT="whichCTzt"	
			s.whInvertCT="invertCT_ZT"
			s.whGamma="gamma_ZT"
			s.whGLock="Lockgamma_ZT"
			s.ctwave="ct_zt"
			s.ctBwave="ctB_zt"
			s.has="ZTPMode"
			s.hindex=dnum[2]
			s.vindex=dnum[3]			
			break
		default:
			returnval = 1
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
	return returnval
end


function setupdim34value(df,control,valchecked)
	string df,control
	variable valchecked
	svar dname=$(df+"dname")
	wave w=$dname
	string u0=selectstring(valchecked==0,"","> ")+"x ["+waveunits(w,0)+"];"
	string u1=selectstring(valchecked==1,"","> ")+"y ["+waveunits(w,1)+"];"
	string u2=selectstring(valchecked==2,"","> ")+"z ["+waveunits(w,2)+"];"
	string u3=selectstring(valchecked==3,"","> ")+"t ["+waveunits(w,3)+"];"
	execute "popupmenu " + control + " value=\"" + u0 +u1+u2+u3+"\""
end	


function setupV(dfn,w)
	string dfn,w
	silent 1; pauseupdate
	//	setdatafolder root:
	string df=getDFfromName(dfn)
	//store the state of all the visible axes relative to the datawave axes
	dowindow/f $dfn
	if(v_flag==1)
		wave /T DnumAxesState = getDnumAxesScales(df)
	endif
	
	//clear some dependecies to prevent updates during setup
	variable/g $(df+"actmain_trig")=0
	variable/g $(df+"acth_trig")=0
	variable/g $(df+"actv_trig")=0
	variable/g $(df+"actzt_trig")=0
	variable/g $(df+"point_trig")=0
	variable/g $(df+"img_trig")=0
	variable/g $(df+"imgh_trig")=0
	variable/g $(df+"imgv_trig")=0
	variable/g $(df+"imgzt_trig")=0

	setformula $(df+"point_trig"),""
	setformula $(df+"actmain_trig"),""
	setformula $(df+"acth_trig"),""
	setformula $(df+"actv_trig"),""
	setformula $(df+"actzt_trig"),""
	setformula $(df+"img_trig"),""
	setformula $(df+"imgh_trig"),""
	setformula $(df+"imgv_trig"),""	
	setformula $(df+"imgzt_trig"),""	
	
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
	
	//when loading a new wave, with fewer dims fixup axis mapping
	nvar d3i=$(df+"dim3index"), d4i=$(df+"dim4index"),txy=$(df+"transXY")
	if(wavedims(wv)==2)
		d3i=2
		d4i=3
	elseif(wavedims(wv)==3)
		d4i=3
		if(d3i==3)
			d3i=2
		endif
	endif
			
	SetupDimMapping(df) 	// call to setup dnum and adnum arrays

	wave dnum=$(df+"dnum")		//maps display axis to wave axis
	wave adnum=$(df+"adnum") //inverse dnum mapping
	



	SVAR  xlable=$(df+"xlable"), ylable=$(df+"ylable"),zlable=$(df+"zlable"),tlable=$(df+"tlable")
	string xl,yl,zl,tl
	xl=waveunits($w,dnum[0]); yl=waveunits($w,dnum[1]); zl=waveunits($w,dnum[2]); tl=waveunits($w,dnum[3])
	x0=dimoffset($w,dnum[0]); xd=dimdelta($w,dnum[0]); xn=dimsize($w,dnum[0])	
	y0=dimoffset($w,dnum[1]); yd=dimdelta($w,dnum[1]); yn=dimsize($w,dnum[1])	
	z0=dimoffset($w,dnum[2]); zd=dimdelta($w,dnum[2]); zn=dimsize($w,dnum[2])	
	t0=dimoffset($w,dnum[3]); td=dimdelta($w,dnum[3]); tn=dimsize($w,dnum[3])
	x1=x0+(xn-1)*xd; 	y1=y0+(yn-1)*yd; z1=z0+(zn-1)*zd; t1=t0+(tn-1)*td

	// setup info tab dim  lables
	xlable=xl
	ylable=yl
	zlable=zl
	tlable=tl

	//setup colors 
	nvar whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"),whichCTv=$(df+"whichCTv"),whichCTzt=$(df+"whichCTzt")
	execute "loadct("+num2str(whichCT)+")"	//load initial color table
	duplicate/o root:colors:ct $(df+"ct"), $(df+"ct_h"), $(df+"ct_v"), $(df+"ct_zt")

	wave ct=$(df+"ct"), ct_h=$(df+"ct_h"), ct_v=$(df+"ct_v"), ct_zt=$(df+"ct_zt")
	wave pmap=$(dF+"pmap")
	wave pmap_H=$(dF+"pmap_H")
	wave pmap_V=$(dF+"pmap_V")
	wave pmap_ZT=$(dF+"pmap_ZT")
	variable /g $(dF+"gamma")
	nvar gamma=$(dF+"gamma")
	variable /g $(dF+"gamma_trigger")

	setformula $(dF+"gamma_trigger"),  "UpdateGamma(\""+df+"\","+dF+"gamma)"
	//print "UpdateGamma("+df+","+dF+"gamma)"
	setformula $(df+"pmap") , "invertct*255 - ((invertct==1)*2-1)*(("+df+"gamma_img>=1)*255*(p/255)^(abs("+df+"gamma_img)) + ("+df+"gamma_img<1)*255*(1-((255-p)/255)^(1/"+df+"gamma_img)))"
	setformula $(dF+"pmap_H"), "invertct_H*255 - ((invertct_H==1)*2-1)*(("+df+"gamma_H>=1)*255*(p/255)^(abs("+df+"gamma_H)) + ("+df+"gamma_H<1)*255*(1-((255-p)/255)^(1/"+df+"gamma_H)))"
	setformula $(dF+"pmap_V"), "invertct_V*255 - ((invertct_V==1)*2-1)*(("+df+"gamma_V>=1)*255*(p/255)^(abs("+df+"gamma_V)) + ("+df+"gamma_V<1)*255*(1-((255-p)/255)^(1/"+df+"gamma_V)))"
	setformula $(dF+"pmap_ZT"), "invertct_ZT*255 - ((invertct_ZT==1)*2-1)*(("+df+"gamma_ZT>=1)*255*(p/255)^(abs("+df+"gamma_ZT)) + ("+df+"gamma_ZT<1)*255*(1-((255-p)/255)^(1/"+df+"gamma_ZT)))"

	NVAR HiResCT=$(df+"HiResCT") 
	if(HiResCT!=1)
		setformula $(df+"ct"), "root:colors:all_ct[pmap[p]][q][whichCT]"
		setformula $(df+"ct_h"), "root:colors:all_ct[pmap_H[p]][q][whichCTh]"
		setformula $(df+"ct_v"), "root:colors:all_ct[pmap_V[p]][q][whichCTv]"
		setformula $(df+"ct_zt"), "root:colors:all_ct[pmap_ZT[p]][q][whichCTzt]"
	else
		// Highres
		variable /g $(dF+"ct_size")=4096
		nvar ct_size=$(dF+"ct_size")
		make /o/N=(ct_size,3) $(df+"ct"), $(df+"ct_h"), $(df+"ct_v"), $(df+"ct_zt")
		duplicate/o root:colors:ct $(df+"ctB"), $(df+"ctB_h"), $(df+"ctB_v"), $(df+"ctB_zt")

		setformula $(df+"ctB"), "root:colors:all_ct[p][q][whichCT]"
		setformula $(df+"ct"), "interp2d(ctB,pmap(255*p/ct_size),q)"

		setformula $(df+"ctB_h"), "root:colors:all_ct[p][q][whichCTh]"
		setformula $(df+"ct_h"), "interp2d(ctB_h,pmap_H(255*p/ct_size),q)"

		setformula $(df+"ctB_v"), "root:colors:all_ct[p][q][whichCTv]"
		setformula $(df+"ct_v"), "interp2d(ctB_v,pmap_V(255*p/ct_size),q)"

		setformula $(df+"ctB_zt"), "root:colors:all_ct[p][q][whichCTzt]"
		setformula $(df+"ct_zt"), "interp2d(ctB_zt,pmap_ZT(255*p/ct_size),q)"
	endif

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
	make/o/n=(yn) $(df+"pyy");	wave pyy=$(df+"pyy");	
	make/o/n=(yn)  $(df+"pyx"); 	wave pyx=$(df+"pyx") ;setscale/p x y0,yd,yl,pyx

	//DISPLAY AND SET IMAGE's AXIS LIMITS
	variable new=0
	dowindow/f $dfn
	if(v_flag==0)
		display/w=(20,20,800,700); appendimage img	
		DoWindow/C/T $dfn,dfn+" [ "+dname+" ]"
		ModifyGraph margin(right)=36 , margin(left)=36
		new=1
		modifyimage img,cindex=ct
		wavestats/q wv
	endif
	
		// make controls match state
	checkbox transXY, value=txy
	setupdim34value(df,"dim3index",d3i)
	setupdim34value(df,"dim4index",d4i)
	
	RemoveOverlays(df)
	
	DoWindow/C/T $dfn,dfn+" [ "+dname+" ]"
	setwindow $dfn,hook(cursorhook)=img4DHookFcn2,hookevents=3,hook=$"" 

	string TB_wavename= "\\Z09" + nameofwave(wv)
	TextBox/C/N=TB_wavename /E=2/F=0 /A=RB/X=0.00/Y=0.00 TB_wavename
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

	//DEPENDENCY FORMULAS
	variable /g $(df+"xpi"),$(df+"ypi"),$(df+"zpi"),$(df+"tpi"),$(df+"point_trig")
	execute df+"point_trig:= updateCursorPoints(\""+df+"\","+df+"xp,"+df+"yp,"+df+"zp,"+df+"tp)"
	
	variable /g $(df+"d_sdev"),$(df+"d_avg")
	
	make/n=4/o/t $(df+"sarr")
	wave/t sarr=$(df+"sarr")
	
	
	sarr={"xpi","ypi","zpi","tpi"}; 	execute wv4di(w,df,"d0",sarr,dnum)   //;print wv4di(w,df,"d0",sarr,dnum)
												execute wv4di(w,df,"di",sarr,dnum)   //; print wv4di(w,df,"di",sarr,dnum)
												execute it5_SetupdSdev(w,df,sarr,dnum)
	
	sarr={"p","q","zpi","tpi"}; 		execute wv4di(w,df,"img",sarr,dnum) //; print wv4di(w,df,"img",sarr,dnum)
	sarr={"p","ypi","q","tpi"};		execute wv4di(w,df,"imgh",sarr,dnum)
	sarr={"xpi","q","p","tpi"};		execute wv4di(w,df,"imgv",sarr,dnum)
	sarr={"p","ypi","zpi","tpi"};		execute wv4di(w,df,"px",sarr,dnum)
	sarr={"xpi","p","zpi","tpi"};		execute wv4di(w,df,"pyx",sarr,dnum)
	sarr={"xpi","ypi","p","tpi"};		execute wv4di(w,df,"pz",sarr,dnum)
	sarr={"xpi","ypi","zpi","p"};		execute wv4di(w,df,"pt",sarr,dnum)
	sarr={"xpi","ypi","p","q"};		execute wv4di(w,df,"imgzt",sarr,dnum)
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
	setscale  d,0,1, xl hcurx 
	setscale  d,0,1, yl hcury 
	setscale  d,0,1, zl vcury 
	setscale  d,0,1, zl vcurx 

	
	wave zcurx=$(df+"zcurx"), zcury=$(df+"zcury"), tcurx=$(df+"tcurx"), tcury=$(df+"tcury")
	setscale  d,0,1, zl zcurx 
	setscale  d,0,1, tl tcurx 
	setscale  d,0,1, zl tcury 

	hcurx={-inf,inf,nan,-inf,inf,nan,-inf,inf};
	execute df+"hcury:=setcursor("+df+"yc,"+df+"yd,"+df+"y0,"+df+"yn,"+df+"bin["+df+"img_axis[1]],"+df+"bincuropt"+num2str(dnum[1])+",p)"
	execute df+"vcurx:=setcursor("+df+"xc,"+df+"xd,"+df+"x0,"+df+"xn,"+df+"bin["+df+"img_axis[0]],"+df+"bincuropt"+num2str(dnum[0])+",p)";			vcury={-inf,inf,nan,-inf,inf,nan,-inf,inf}
	execute df+"zcurx:=setcursor("+df+"zc,"+df+"zd,"+df+"z0,"+df+"zn,"+df+"bin["+df+"imgh_axis[1]],"+df+"bincuropt"+num2str(dnum[2])+",p)";			zcury={-inf,inf,nan,-inf,inf,nan,-inf,inf}
	execute df+"tcurx:=setcursor("+df+"tc,"+df+"td,"+df+"t0,"+df+"tn,"+df+"bin["+df+"imgzt_axis[1]],"+df+"bincuropt"+num2str(dnum[3])+",p)";			tcury={-inf,inf,nan,-inf,inf,nan,-inf,inf}
	nvar rebuild=$(df+"rebuild")
	if((new==1)+(rebuild==1))
		if(new)
			appendtograph hcury vs hcurx
			appendtograph vcury vs vcurx
		endif
	endif

	setscale  x,0,1, zl zcurx 

	modifyRGBaxis("hcury","Y","left",16385,65535,0)
	modifyRGBaxis("vcury","Y","left",16385,65535,0)

	ROLoadSliceState(df,"img") 

	execute df+"actmain_trig:=ImageTool5#adjustCT(\""+df+"\",\"img\")+"+df+"img_trig"

	if(isNew)
		//remove binning loading a new data or creating
		wave bin = $(df+"bin")
		bin=1	
	endif

	nvar leftAxisScale=$(df+"leftAxisScale"), bottomAxisScale=$(df+"bottomAxisScale")

	variable leftstop=1-((1+hasHI*hasHP )*((hasTP+hasZP+ZTpmode)>0) + ((hasTP+hasZP+ZTpmode)==0)*(hasHP+hasHI))/4  
	leftstop*=leftAxisScale
	variable bottomstop=1-((1+hasVI*hasVP )*((hasTP+hasZP+ZTpmode)>0) + ((hasTP+hasZP+ZTpmode)==0)*(hasVP+hasVI))/4  
	bottomstop*=bottomAxisScale
	ModifyGraph axisEnab(left)={0,leftstop},axisEnab(bottom)={0,bottomstop}


	variable leftStop2=leftStop, bottomStop2=bottomstop,axisGap=.02
	//APPEND TO GRAPH
	if(ndim>=3)
		//remove imgH if present
		removeimage/z imgh
		removetraceaxis("vcury","Y","imghL")
		removetraceaxis("zcurx","Y","imghL")
		if(hasHI)
			if(hasAxis("imghL")==0)
				appimg("/L=imghL/b=bottom", df+"imgh")
				appendtograph/l=imghl vcury vs vcurx
				appendtograph /l=imghl zcurx vs hcurx
			endif
			leftstop2 = 1-0.20*(hasHP==1)
			ModifyGraph axisEnab(imghL)={leftstop+axisGap,leftStop2},freePos(imghL)=0
			ModifyGraph lblPosmode(imghL)=1
			modifyRGBaxis("vcury","Y","imghL",16385,0,65535)
			modifyRGBaxis("zcurx","Y","imghL",16385,0,65535)

			modifyimage imgh,cindex=ct_h
			ModifyGraph btLen(imghL)=5
			ROLoadSliceState(df,"imgH") 
			execute df+"actH_trig:=ImageTool5#adjustCT(\""+df+"\",\"imgH\")+"+df+"imgh_trig"
		else

		endif
		removeimage/z imgv
		removetraceaxis("hcury","X","imgvB")
		removetraceaxis("vcury","X","imgvB")
		if(hasVI)
			variable hvb=hasaxis("imgvb")
			if(hasaxis("imgvB")==0)
				appimg("/L=left/b=imgvB",df+"imgv")
				appendtograph/b=imgvB Vcury vs zcurx
				appendtograph/b=imgvB hcury vs hcurx
			endif
			bottomStop2=1-0.20*(hasVP==1)
			modifygraph axisEnab(imgvB)={bottomstop+axisGap,bottomStop2},freePos(imgvB)=0	
			ModifyGraph lblPosmode(imgVB)=1
			modifyRGBaxis("hcury","X","imgvB",16385,0,65535)
			modifyRGBaxis("vcury","X","imgvB",16385,0,65535)
			modifyimage imgv,cindex=ct_v
			ModifyGraph btLen(imgVB)=5
			ROLoadSliceState(df,"imgV") 
			execute df+"actv_trig:=ImageTool5#adjustCT(\""+df+"\",\"imgV\")+"+df+"imgv_trig"
		else
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
		ModifyGraph axisEnab(profHL)={leftstop2+AxisGap,1},freePos(profhL)=0
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
		modifygraph axisEnab(profvb)={bottomStop2+AxisGap,1},freePos(profvB)=0	
		modifyRGBaxis("hcury","X","profVB",24000,16385,20000)
		ModifyGraph lblPosMode(profvB)=1
		ModifyGraph btLen(profvB)=5
	else
		removetraceaxis("pyy","X","profVB")
		removetraceaxis("hcury","X","profVB")
	endif 
	
	removetraceaxis("tcurx","Y","imgZTr")
	removetraceaxis("zcury","Y","imgZTr")
	removeimage/z imgzt
	ModifyGraph margin(right)=0, margin(top)=0
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
		modifygraph axisEnab(imgZTt)={bottomstop+AxisGap,1},axisenab(imgZtr)={leftstop+AxisGap,1}
		ModifyGraph freePos(imgZTt)={0,kwFraction}
		ModifyGraph freePos(imgZTr)={0,kwFraction}
		//ModifyGraph freePos(imgZTt)={inf,imgZTR}, btLen(imgZTt)=5
		//ModifyGraph freePos(imgZTr)={inf,imgZTt} ,btLen(imgZTr)=5
		ModifyGraph lblPosMode(imgZTr)=1,lblPosMode(imgZTt)=1
		ROLoadSliceState(df,"imgZT") 
		execute df+"actzt_trig:=ImageTool5#adjustCT(\""+df+"\",\"imgZT\")+"+df+"imgzt_trig"
	else
	endif
	nvar hc=$(df+"hideCursors")
	if(!ZTPmode)
		if(hasZP)
			if(hasaxis("profZB")==0)
				appendtograph/t=profZB/R=profZR pz
				appendtograph/t=profZB/R=profZR zcury vs zcurx
			endif
			modifygraph axisEnab(profzb)={bottomstop+AxisGap,1},axisenab(profZR)={leftstop+2*axisGap+0.5*(1-leftstop)*hasTP,1},freepos(profZR)={inf,profZB}
			ModifyGraph rgb(pz)=(2,39321,1)
			ModifyGraph freePos(profZB)={-inf,profZR}
			ModifyGraph rgb(zcury)=(2,39321,1),lsize(zcury)=1-hc
			ModifyGraph btLen(profZR)=5,btlen(profzb)=5
			ModifyGraph margin(right)=36

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
			modifygraph axisEnab(profTb)={bottomstop+axisGap,1},axisenab(profTR)={leftstop+2*axisGap,1-0.5*(1-leftstop)*hasZP},freepos(profTR)=0
			ModifyGraph rgb(pt)=(52428,1,20971)
			ModifyGraph freePos(profTB)={-inf,profTR}
			ModifyGraph rgb(tcury)=(52428,1,20971),lsize(tcury)=1-hc
			ModifyGraph btLen(profTR)=5,btlen(profTB)=5
			ModifyGraph margin(right)=36
		else
			removetraceaxis("pt","X","profTB")
			removetraceaxis("tcurY","X","proTB")		
		endif
	else
		modifygraph lsize(zcury)=1-hc, lsize(tcurx)=1-hc
	endif
	controlbar 83
	ModifyGraph fSize=10
	if(waveexists(DnumAxesState))
		ApplyDnumAxesState(df,DnumAxesState)
	endif
	if((new==1)+(rebuild==1))
		setupcontrols(df)
		controlinfo tab0
		tabproc("info",V_Value)
	endif
	string exmenu = exportmenustring(df)
	execute "popupmenu Export, value=\"" +exmenu+"\""
	isNew=0
	rebuild=0
	ModifyGraph btLen=5
	updateoverlays(df)
end

function removeall()
	string inl=imagenamelist("",","), tnl=tracenamelist("",",",1)
	execute "removeimage/z "+ inl[0,strlen(inl)-2]			//remove all images
	execute "removefromgraph/z "+  tnl[0,strlen(tnl)-2]		//remove all traces
end

Menu "GraphMarquee" , dynamic
	IT5_PopUpMenu(0),/Q, doImageTool5Graphmarquee()
End

//Menu "OverrideMarqueeMenu" , dynamic ,contextualmenu
//	IT5_MarqueeMenu(),/Q, doImageTool5Graphmarquee()
//End

Menu "IT5_PopUpMenu" , dynamic ,contextualmenu
	IT5_PopUpMenu(0),/Q, doImageTool5Graphmarquee()
End


// generates the marquee menu on the fly
function /s IT5_PopUpMenu(MenuType) //Type 0=marquee;1=custommarquee;2=shiftclick
	variable MenuType
	if(strsearch(winName(0,95),"ImageToolV",0)==-1)
		return""
	endif
	getmarquee left, bottom
	if(V_Flag==1)
		MenuType=1
	else
		MenuType=2
	endif
	string dfn=getdfname()
	string menustr =""
	if(strsearch(dfn,"ImageToolV",0)>=0)
		string df=getdf()
		if(MenuType==1)
			menustr += "Expand;Horiz Expand;Vert Expand;AutoScale;-;"
		endif
		variable avgx,avgy
		if(MenuType==1)
			getmarquee left, bottom
			avgx=PixelFromAxisVal(dfn,"bottom",(V_left +V_right)/2)
			avgy=PixelFromAxisVal(dfn,"left",(V_top+V_bottom)/2)
		endif
		if(MenuType==2) // must be passed by global since igor doesn't acount for the controlbar when useing getmouse
			NVAR ShiftClickMenu_X = $(df+"ShiftClickMenu_X")
			NVAR ShiftClickMenu_Y = $(df+"ShiftClickMenu_Y")
			avgx=ShiftClickMenu_X
			avgy=ShiftClickMenu_Y
		endif
		
		string imgname=whichimage(dfn,avgx,avgy)
		string Tracename=whichtrace(dfn,avgx,avgy)

		struct imageWaveNameStruct s
		if(strlen(imgname)!=0)
			getimageinfo(df,imgname,s)
		elseif(strlen(Tracename)!=0)
			gettraceinfo(df,tracename,s)
		endif
		if(strlen(imgname)!=0)
			nvar im=$(df+s.imode)
			wave xw=$(df+s.xwv)
			nvar gammalock=$(df+"lock"+s.whgamma)
			if(MenuType==2)
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
				menustr +=";Set Color Table"
			
				menustr +=";Lock Gamma"
				if(gammalock==1)
					menustr += "!"+ num2char(18)	
				endif
			
				menustr += ";-"
			endif
			if(MenuType==1)
				menustr += ";Add Color ROI"
			endif
			if (dimsize(xw,0)>0)
				if(MenuType==1)
					menustr += ";Replace Color ROI"
				endif
				menustr += ";Clear Color ROI"
			endif
			menustr +=";-;Norm "+axistitle(df,s.hindex)
			menustr +=";Norm "+axistitle(df,s.vindex)	
			
		endif
		if (strlen(tracename)!=0)
			variable axis=gettraceaxis(df,tracename)
			menustr +=";Norm "+axistitle(df,axis)
		endif
		if ((strlen(tracename)!=0)||(strlen(imgname)!=0))
			if(MenuType==1)
				menustr +=";-;Set Binning"
			endif
			menustr +=";-;Export"
			NVAR ZTPmode=$(df+"ZTPmode")
			if(MenuType==2)
				if(cmpstr(imgname,"img")==0 || cmpstr(imgname,"imgZT")==0)
					menustr +=";-;Transpose"
				endif	
				if(cmpstr(imgname,"img")==0 && (ZTPmode==1))
					menustr +=";Swap with ZT"
				endif
				if(cmpstr(imgname,"imgZT")==0)
					menustr +=";Swap with Main Image"
				endif			
			endif
			NVAR ScanSystem=root:Packages:ImagetoolV:ScanSystem
			if(ScanSystem>0)
				menustr +=";-;Send Coordinates"
				if(MenuType==1)
					menustr += ";Send Marquee"
				endif
			endif	
				if(MenuType==2)
					wave cursors = getcursorWave(df)
					svar dname=$(df+"dname")
					wave w=$dname
					if((s.hindex!=-1)&&(s.vindex!=-1))
						menustr += ";-;"+waveunits(w,s.hindex)+":"+ num2str(cursors[s.hindex])
						menustr += ";"+waveunits(w,s.vindex)+":"+num2str(cursors[s.vindex])
					else
						menustr += ";-;"+waveunits(w,max(s.hindex,s.vindex))+":"+num2str(cursors[max(s.hindex,s.vindex)])
					endif
				endif
			
		else
			string axisname = whichaxis(dfn,avgx,avgy)
			wave adnum=$(df+"adnum")
			if(strlen(axisname)!=0)
				menustr = "Reverse Axis;-"// + axisname
				
				if(adnum[getaxisdnum(df,axisname)]!=2)
					menustr += ";Make 3rd Axis"// + axisname
				endif
				NVAR ndim=$(df+"ndim")
				if(adnum[getaxisdnum(df,axisname)]!=3 && ndim==4)
					menustr += ";Make 4th Axis"// + axisname
				endif
			endif
		endif

	endif
	return menustr
end

// handle marquee menu selections
FUNCTION doImageTool5Graphmarquee()
	string dfn=getdfname()
	string df=getdf()
	variable avgx,avgy
	getmarquee left, bottom
	variable marquee=V_Flag
	if (V_Flag==1)
		avgx=PixelFromAxisVal(dfn,"bottom",(V_left +V_right)/2)
		avgy=PixelFromAxisVal(dfn,"left",(V_top+V_bottom)/2)
	else
		NVAR ShiftClickMenu_X = $(df+"ShiftClickMenu_X")
		NVAR ShiftClickMenu_Y = $(df+"ShiftClickMenu_Y")
		avgx=ShiftClickMenu_X
		avgy=ShiftClickMenu_Y
	endif
	string ImgName=whichimage(dfn,avgx,avgy)
	string ctrlName=imgName+"Opt"
	string tracename=whichtrace(dfn,avgx,avgy)
	struct imageWaveNameStruct s

	variable popnum 
	string popstr=""
	GetLastUserMenuInfo
	string menustr=S_value
	strswitch(menustr)
		case "Expand":
		case "Horiz Expand":
		case "Vert Expand":
		case "AutoScale":
			MarqueeExpand(df , dfn,menustr)
			break
		case "Set Binning":
			if(strlen(ImgName)>0)
				getimageinfo(df,imgname,s)
			elseif(strlen(TraceName)>0)				
				gettraceinfo(df,tracename,s)
			else
				break
			endif
				SVAR w=$(df+"dname")
				wave dnum=$(df+"dnum")
				wave adnum=$(df+"adnum")
				//wave w=$wname
				wave bin=$(df+"bin")
				getmarquee /K /W=$dfn  $(s.vaxis), $(s.haxis)
				if(s.hindex>=0)
					bin[s.hindex]=max(1,min(trunc(abs(v_left-V_right)/dimdelta($w,s.hindex)),dimsize($w,s.hindex)))
					NVAR ax = $(axisvariable(df,adnum[s.hindex]))
					ax=(v_left+V_right)/2
				endif
				if(s.vindex>=0)
					bin[s.vindex]=max(1,min(trunc(abs(V_top-V_bottom)/dimdelta($w,s.vindex)),dimsize($w,s.vindex)))
					NVAR ay = $(axisvariable(df,adnum[s.vindex]))
					ay=(V_top+V_bottom)/2
				endif
			break
		case "Transpose":
			if(cmpstr(imgname,"img")==0)
				NVAR transXY=$(df+"transXY")
				transXY=!transXY
				SVAR w=$(df+"dname")
			else
				NVAR dim3index=$(df+"dim3index")
				NVAR dim4index=$(df+"dim4index")
				variable tmp = dim3index
				dim3index=dim4index
				dim4index = tmp
			endif
			SVAR w=$(df+"dname")
			setupV(dfn,w)
			break	
		case "Swap with ZT":
		case "Swap with Main Image":
			wave dnum=$(df+"dnum")
			wave adnum=$(df+"adnum")
			SVAR w=$(df+"dname")
			variable xaxis = dnum[0]
			variable yaxis = dnum[1]
			variable zaxis = dnum[2]
			variable taxis = dnum[3]
			NVAR dim3index=$(df+"dim3index")
			NVAR dim4index=$(df+"dim4index")
			dim3index=xaxis
			dim4index=yaxis
			getimageinfo(df,"img",s)
			NVAR MainwhichCT=$(df+s.whCT)
			NVAR MainInvertCT=$(df+s.whInvertCT)
			NVAR MainGamma=$(df+s.whGamma)
			NVAR Lockgamma_img = $(df+"Lockgamma_img")

			getimageinfo(df,"imgZT",s)
			NVAR ZTwhichCT=$(df+s.whCT)
			NVAR ZTInvertCT=$(df+s.whInvertCT)
			NVAR ZTGamma=$(df+s.whGamma)
			NVAR Lockgamma_ZT = $(df+"Lockgamma_ZT")
			
			variable temp=MainwhichCT
			MainwhichCT=ZTwhichCT
			ZTwhichCT=temp
			temp=MainInvertCT
			MainInvertCT=ZTInvertCT
			ZTInvertCT=temp
			temp=Lockgamma_img
			Lockgamma_img=Lockgamma_ZT
			Lockgamma_ZT=temp
			temp=MainGamma
			MainGamma=ZTGamma
			ZTGamma=temp			
			
			setupV(dfn,w)		
			break
		case "Export":
			if(strlen(ImgName)>0)
				getimageinfo(df,imgname,s)

				Export_image(df,s)
			elseif(strlen(TraceName)>0)
				gettraceinfo(df,Tracename,s)
				Export_Trace(df,s)
			endif
			break
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
		case "Set Color Table":
			//Color
			getimageinfo(df,imgname,s)
			NVAR whichCT=$(df+s.whCT)
			NVAR InvertCT = $(df+s.whInvertCT)
			variable sel=whichCT+1			
			variable invert=InvertCT+1			
			prompt sel,"choose a color table",popup colornameslist()
			prompt invert,"Invert", popup "No;Yes;"
			doprompt "Choose color table",sel,invert
			whichCT=sel-1
			InvertCT = invert-1
			//popupmenu $ctrlName,mode=im
			break
		case "Lock Gamma":
			getimageinfo(df,imgname,s)
			nvar gamma=$(df+"gamma")
			nvar gammalock=$(df+"lock"+s.whgamma)
			if(gammalock==0)
				gammalock=1
			else
				gammalock=0
			endif
			UpdateGamma(df,gamma)
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
			break
		case "Send Coordinates":
			if(strlen(ImgName)>0)
				getimageinfo(df,imgname,s)
				SendToScan( IT5_getcoordJSON(df,s))
			elseif(strlen(TraceName)>0)
				gettraceinfo(df,Tracename,s)
				SendToScan(  IT5_getcoordJSON(df,s))
			endif
			break
		
			break
		case "Send Marquee":
			SendToScan(IT5_getMarqueeJSON())
			break
				
		case "Reverse Axis":
			string axisname = whichaxis(dfn,avgx,avgy)
			if(strlen(axisname)!=0)
					string info = AxisInfo(IT5winname(df), axisname )
					string SETAXISCMD = stringbykey("SETAXISCMD",info)
					SETAXISCMD = replacestring("SetAxis",SETAXISCMD,"SetAxis/W="+IT5winname(df))
					string flags
					variable AxisLeft,AxisRight
					sscanf SETAXISCMD,"SetAxis%s "+ axisname +" %f , %f",flags,AxisLeft,AxisRight
					if(V_Flag==1) //no axis values->axis autoscaled
						if(strsearch(flags,"/R",0)>=0)
							flags =replacestring("/A/R",flags,"/A")
						else
							flags =replacestring("/A",flags,"/A/R")
						endif
					else //axis not autoscaled
						sscanf SETAXISCMD,"SetAxis%s "+ axisname +" %f , %f",flags,AxisLeft,AxisRight
						flags =replacestring("/R",flags,"")
						if(AxisLeft<AxisRight)
							flags=flags+"/R "
						endif
					endif
					string axes=getaxislistforDim(df,getaxisDim(df,axisname))
					
					variable n=itemsinlist(axes)
					variable i,d
					string axis1
					for(i=0;i<n;i+=1)
						axis1 =stringfromlist(i,axes,";")
						SETAXISCMD="SetAxis"+flags+"/Z "+axis1+" "+selectstring((V_Flag!=3), num2str(AxisRight)+","+num2str(AxisLeft),"")
						execute SETAXISCMD
					endfor
			endif
			break
			case "Make 3rd Axis":
				axisname = whichaxis(dfn,avgx,avgy)
				dim34setproc("dim3index",getaxisdnum(df,axisname)+1,"")
			break
			case "Make 4th Axis":
				axisname = whichaxis(dfn,avgx,avgy)
				dim34setproc("dim4index",getaxisdnum(df,axisname)+1,"")		
			break
		default:
			getimageinfo(df,imgname,s)
			STRUCT WMPopupAction PU_Struct
			PU_Struct.win=dfn
			if(cmpstr(menustr,"Norm "+axistitle(df,s.hindex))==0)
				PU_Struct.popnum=s.hindex+1
				PU_Struct.eventcode=2
				PU_Struct.ctrlName="cNorm1_AXIS"
				Norm1D_AxisMenu(PU_Struct)
				break
			endif
			if(cmpstr(menustr,"Norm "+axistitle(df,s.vindex))==0)
				PU_Struct.popnum=s.vindex+1
				PU_Struct.ctrlName="cNorm1_AXIS"
				PU_Struct.eventcode=2
				Norm1D_AxisMenu(PU_Struct)
				break
			endif
			variable axis = gettraceaxis(df,tracename)
			if(cmpstr(menustr,"Norm "+axistitle(df,axis))==0)
				PU_Struct.popnum=axis+1
				PU_Struct.ctrlName="cNorm1_AXIS"
				PU_Struct.eventcode=2
				Norm1D_AxisMenu(PU_Struct)
				break
			endif
			getimageinfo(df,imgname,s)
			variable value
			string scanstring=axistitle(df,s.hindex)+":%f"
			sscanf menustr,scanstring, value
			if(V_Flag==1)
				putscrapText num2str(value)
			endif
			scanstring=axistitle(df,s.vindex)+":%f"
			sscanf menustr, scanstring, value
			if(V_Flag==1)
				putscrapText num2str(value)
			endif
			axis = gettraceaxis(df,tracename)
			scanstring=axistitle(df,axis)+":%f"
			sscanf menustr, scanstring, value
			if(V_Flag==1)
				putscrapText num2str(value)
			endif
	endswitch
end


function img4DHookFcn2(H_Struct)
	STRUCT WMWinHookStruct &H_Struct
	variable eventCode = H_Struct.eventCode
	if(eventcode==8) // window modified
		return 0
	endif
	string dfn=H_Struct.winName; string df=getDFfromName(dfn)
	string temp=getdatafolder(1)
	wave pmap=$(df+"pmap"),vimg_ct=$(df+"ct_v"), himg_ct=$(df+"ct_h"), img_ct=$(df+"ct"), ztimg_ct=$(df+"ct_zt")
	if(eventcode==2) //kill window
		dowindow /F $dfn
		vimg_ct=0; himg_ct=0; img_ct=0; ztimg_ct=0; pmap=0
		removeoverlays(df)
		removeall()
		killallinfolder(df)
		killdatafolder $df
		BuildMenu "ImageToolV"
		return(-1)
	endif

	variable mousex,mousey,ax,ay,zx,zy,tx,ty,modif,returnval=0
	variable xc,yc,zc,tc
	nvar xcg=$(df+"xc"), ycg=$(df+"yc"), zcg=$(df+"zc"), tcg=$(df+"tc"), ndim=$(df+"ndim")
	nvar xlock=$(df+"xlock"), ylock=$(df+"ylock"), zlock=$(df+"zlock"), tlock=$(df+"tlock")

	nvar ztpmode=$(df+"ztpmode"),hasZP=$(df+"hasZP"), hasTP=$(df+"hasTP"),ndim=$(df+"ndim"),hasVI=$(df+"hasVI"),hasHI=$(df+"hasHI"),hasVP=$(df+"hasVP"),hasHP=$(df+"hasHP")
	nvar AutoScaleVP=$(df+"AutoScaleVP"),  AutoScaleHP  	=$(df+"AutoScaleHP")
	variable xcold,ycold,zcold,tcold,bool
	nvar x0=$(df+"x0"),x1=$(df+"x1"), y0=$(df+"y0"),y1=$(df+"y1"),z0=$(df+"z0"),z1=$(df+"z1"),t0=$(df+"t0"),t1=$(df+"t1")
	modif=H_Struct.eventMod & 15
	variable shift = H_Struct.eventMod & 2
	//print shift, modif
	SVAR LastMouseDownGraph=$(df+"LastMouseDownGraph")
	string img
	mousex=H_Struct.mouseLoc.h
	mousey=H_Struct.mouseLoc.v
	if (eventcode==1) // window deacitveate
		LastMouseDownGraph=""
		return -1
	endif
	
	if ((eventcode==3)&&(shift==0)) //marquee menus
		getmarquee
		if(V_flag==1)
			variable /g  $(df+"CustomMarqueeMenu")
			NVAR CustomMarqueeMenu = $(df+"CustomMarqueeMenu")
			CustomMarqueeMenu = 1
			PopupContextualMenu /C=(mousex, mousey) /N "IT5_PopUpMenu" // marqueemenus()
			CustomMarqueeMenu = 0
			return 1
		endif
	endif
	
	if ((eventcode==3)&&(H_Struct.eventMod==17))//(shift==2)) // right click menu
			string TraceList = StringByKey("TRACE",TraceFromPixel(mousex, mousey, "" ),":")  
			if(strlen(TraceList)!=0)
				if(stringmatch(TraceList,"!*cur*")) // if right click is near a trace that isn't a IT cursor, then aloow igor to open the built in trace menu
					return 0
				endif
			endif
			variable /g  $(df+"ShiftClickMenu_X")
			variable /g  $(df+"ShiftClickMenu_Y")
			NVAR ShiftClickMenu_X = $(df+"ShiftClickMenu_X") // must be passed by global since igor doesn't acount for the controlbar when using getmouse
			NVAR ShiftClickMenu_Y = $(df+"ShiftClickMenu_Y")
			ShiftClickMenu_X=mousex
			ShiftClickMenu_Y=mousey
			PopupContextualMenu /C=(mousex, mousey) /N "IT5_PopUpMenu" // marqueemenus()
			return 1
	endif

	if ((eventcode==3)*(modif==9)+(eventcode==11)*(modif==9))
		img = whichimage(dfn,mousex,mousey)
		if (cmpstr(img,"")==0)
			img = whichtrace(dfn,mousex,mousey)
		endif
		if (cmpstr(img,"")==0)
			LastMouseDownGraph = img
			return (-1)
		endif
		LastMouseDownGraph = img
	endif
	if(((eventcode==4)+(eventcode==3))*(modif==9)) // mousedown or mousemoved 9 means "1001" = cmd/ctrl + mousedown
		variable axmin, axmax, aymin, aymax
		variable zxmin, zxmax, zymin, zymax
		variable txmin, txmax, tymin, tymax
		variable xcur, ycur,zcur
		variable/C coffset
		xc=xcg;yc=ycg;zc=zcg;tc=tcg
		xcold=xc; ycold=yc

		strswitch(LastMouseDownGraph)
			case "img":
				ax=axisvalfrompixel(dfn,"bottom",mousex)	

				GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
				xc=min(max(ax,axmin),axmax)

				ay=axisvalfrompixel(dfn,"left",mousey)
				GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
				yc= min(max(ay,aymin),aymax)
				break
			case "imgH":
				ax=axisvalfrompixel(dfn,"bottom",mousex)	
				GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
				xc=min(max(ax,axmin),axmax)

				ay=axisvalfrompixel(dfn,"imghL",mousey)
				getaxis/q imghL; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
				zc=min(max(ay,zxmin),zxmax)

				break
			case "imgV":
				ay=axisvalfrompixel(dfn,"left",mousey)
				GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
				yc= min(max(ay,aymin),aymax)

				ax=axisvalfrompixel(dfn,"imgVB",mousex)
				getaxis/q imgVB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
				zc=min(max(ax,zxmin),zxmax)
				break
			case "imgZT":
				if(ztpmode)
					ax=axisvalfrompixel(dfn,"imgZTt",mousex)
					getaxis/q imgZTt; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
					zc=min(max(ax,zxmin),zxmax)

					ay=axisvalfrompixel(dfn,"imgztr",mousey)
					getaxis/q imgztr; txmin=min(V_max, V_min); txmax=max(V_min, V_max)
					tc=min(max(ay,txmin),txmax)
				endif
				break
			case "HProf":
				ax=axisvalfrompixel(dfn,"bottom",mousex)	
				GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
				xc=min(max(ax,axmin),axmax)
				break
			case "VProf":
				ay=axisvalfrompixel(dfn,"left",mousey)
				GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
				yc= min(max(ay,aymin),aymax)
				break
			case "ZProf":
				if(hasZP)
					ax=axisvalfrompixel(dfn,"ProfZB",mousex)	
					GetAxis/Q ProfZB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
					zc=min(max(ax,zxmin),zxmax)
				endif
				break
			case "TProf":
				if(hasTP)
					ax=axisvalfrompixel(dfn,"ProfTB",mousex)	
					GetAxis/Q ProfTB; txmin=min(V_max, V_min); txmax=max(V_min, V_max)
					tc=min(max(ax,txmin),txmax)
				endif
				break
		endswitch

		xc=min(xc,max(x0,x1));xc=max(xc,min(x0,x1))
		yc=min(yc,max(y0,y1));yc=max(yc,min(y0,y1))
		zc=min(zc,max(z0,z1));zc=max(zc,min(z0,z1))
		tc=min(tc,max(t0,t1));tc=max(tc,min(t0,t1))
		
		// only update images that have changed
		if ((xcg!=xc)&&(xlock==0))
			xcg=xc
		endif
		if ((ycg!=yc)&&(ylock==0))
			ycg=yc
		endif
		if ((zcg!=zc)&&(zlock==0))
			zcg=zc
		endif
		if ((tcg!=tc)&&(tlock==0))
			tcg=tc
		endif
		returnval=1
	endif
	if(eventcode==22) //mouse wheel

		if(cmpstr(IgorInfo(2),"Macintosh")==0)
			h_struct.wheelDy *=-1
			h_struct.wheelDx *=-1
		endif
		//NVAR mx = $(df+"mousex")
		//NVAR my = $(df+"mousey")
		variable mx = mousex;variable my=mousey+83
		if(mousey<0)
			ControlInfo /W=$IT5winname(df) tab0
			if(V_Value==2) //Colors
					ControlInfo /W=$IT5winname(df) slidegamma
					if(my>V_top&&my<(V_top+V_Height)&&(mx>V_Left&&mx<V_Left+V_Width))
					NVAR gamma=$(df+"gamma")
					gamma = alog(V_Value+.1*(h_struct.wheelDy-h_struct.wheelDx))
					gamma=min(max(.01,gamma),24)
					//(h_struct.wheelDy+h_struct.wheelDx)
					slider slidegamma win=$IT5winname(df), value=log(gamma)
					endif
			endif
			returnval=-1
		endif	
		img = whichimage(dfn,mousex,mousey)
		if (cmpstr(img,"")==0)
			img = whichtrace(dfn,mousex,mousey)
		endif
		//print h_struct.wheelDy,h_struct.wheelDx
		xc=xcg;yc=ycg;zc=zcg;tc=tcg
		xcold=xc; ycold=yc
		
		strswitch(img)
			case "img":
				GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
				ax=xcg+sign(V_min-V_max)*abs(getdelta(df,1))*h_struct.wheelDx/4

				xc=min(max(ax,axmin),axmax)

				GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
				ay=ycg-sign(V_min-V_max)*abs(getdelta(df,2))*h_struct.wheelDy/4

				yc= min(max(ay,aymin),aymax)
				break
			case "imgH":
				GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
				ax=xcg+sign(V_min-V_max)*abs(getdelta(df,1))*h_struct.wheelDx/4
				xc=min(max(ax,axmin),axmax)

				getaxis/q imghL; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
				ay=zcg-sign(V_min-V_max)*abs(getdelta(df,3))*h_struct.wheelDy/4

				zc=min(max(ay,zxmin),zxmax)

				break
			case "imgV":
				GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
				ay=ycg-sign(V_min-V_max)*abs(getdelta(df,2))*h_struct.wheelDy/4
				yc= min(max(ay,aymin),aymax)

				getaxis/q imgVB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
				ax=zcg+sign(V_min-V_max)*abs(getdelta(df,3))*h_struct.wheelDx/4

				zc=min(max(ax,zxmin),zxmax)
				break
			case "imgZT":
				if(ztpmode)
					getaxis/q imgZTt; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
					ax=zcg+sign(V_min-V_max)*abs(getdelta(df,3))*h_struct.wheelDx/4

					zc=min(max(ax,zxmin),zxmax)

					ay=axisvalfrompixel(dfn,"imgztr",mousey)
					getaxis/q imgztr; txmin=min(V_max, V_min); txmax=max(V_min, V_max)
					ay=tcg-sign(V_min-V_max)*abs(getdelta(df,4))*h_struct.wheelDy/4

					tc=min(max(ay,txmin),txmax)
				endif
				break
			case "HProf":
				GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
				ax=xcg+sign(V_min-V_max)*abs(getdelta(df,1))*h_struct.wheelDx/4
				xc=min(max(ax,axmin),axmax)
				break
			case "VProf":

				GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
				ay=ycg-sign(V_min-V_max)*abs(getdelta(df,2))*h_struct.wheelDy/4

				yc= min(max(ay,aymin),aymax)
				break
			case "ZProf":
				if(hasZP)
					GetAxis/Q ProfZB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
					ax=zcg+sign(V_min-V_max)*abs(getdelta(df,3))*h_struct.wheelDx/4

					zc=min(max(ax,zxmin),zxmax)
				endif
				break
			case "TProf":
				if(hasTP)
					GetAxis/Q ProfTB; txmin=min(V_max, V_min); txmax=max(V_min, V_max)
					ax=tcg+sign(V_min-V_max)*abs(getdelta(df,4))*h_struct.wheelDx/4

					tc=min(max(ax,txmin),txmax)
				endif
				break
		endswitch
		xc=min(xc,max(x0,x1));xc=max(xc,min(x0,x1))
		yc=min(yc,max(y0,y1));yc=max(yc,min(y0,y1))
		zc=min(zc,max(z0,z1));zc=max(zc,min(z0,z1))
		tc=min(tc,max(t0,t1));tc=max(tc,min(t0,t1))
		// only update images that have changed
		if ((xcg!=xc)&&(xlock==0))
			xcg=xc
		endif
		if ((ycg!=yc)&&(ylock==0))
			ycg=yc
		endif
		if ((zcg!=zc)&&(zlock==0))
			zcg=zc
		endif
		if ((tcg!=tc)&&(tlock==0))
			tcg=tc
		endif
		returnval=1
	endif

	if((eventcode==11)*(modif==8)) // Keyboard event with Cmd Key 	
		variable key = H_Struct.keycode	
		//print key, mousex,mousey
		if((key>=28)&&(key<=31)) //Arrow keys
			xc=xcg;yc=ycg;zc=zcg;tc=tcg
			xcold=xc; ycold=yc
			string cAinfo = csrinfo(A)
			string cAgraph = stringbykey("TNAME",cAinfo)
			string cBinfo = csrinfo(B)
			string cBgraph = stringbykey("TNAME",cBinfo)
			if(cmpstr(cAgraph,"")==0)
				return (-1)
			endif
			if(cmpstr(cAgraph,cBgraph)!=0)
				return (-1)
			endif
			variable Harrow=0
			switch(key)
				case 28:
					ax=min(xcsr(A),xcsr(B))
					Harrow=1
					break
				case 29:
					ax=max(xcsr(A),xcsr(B))
					Harrow=1
					break
				case 31:
					ay=min(vcsr(A),vcsr(B))
					break
				case 30:
					ay=max(vcsr(A),vcsr(B))
					break	
			endswitch
			strswitch(cAgraph)
				case "img":		
					if(Harrow==1)
						GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
						xc=min(max(ax,axmin),axmax)
					else
						GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
						yc= min(max(ay,aymin),aymax)
					endif
					break
				case "imgH":
					if(Harrow==1)
						GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
						xc=min(max(ax,axmin),axmax)	
					else			
						getaxis/q imghL; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
						zc=min(max(ay,zxmin),zxmax)
					endif
					break
				case "imgV":
					if(Harrow==0)
						GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
						yc= min(max(ay,aymin),aymax)	
					else	
						getaxis/q imgVB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
						zc=min(max(ax,zxmin),zxmax)
					endif
					break
				case "imgZT":
					if(ztpmode)
						if(Harrow==1)
							getaxis/q imgZTt; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
							zc=min(max(ax,zxmin),zxmax)
						else
							getaxis/q imgztr; txmin=min(V_max, V_min); txmax=max(V_min, V_max)
							tc=min(max(ay,txmin),txmax)
						endif
					endif
					break
				case "px":
					if(Harrow==1)
						GetAxis/Q bottom; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
						xc=min(max(ax,axmin),axmax)
					endif
					break
				case "pyy":
					if(Harrow==0)
						GetAxis/Q left; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
						yc= min(max(ay,aymin),aymax)
					endif
					break
				case "pz":
					if(hasZP)
						if(Harrow==1)
							GetAxis/Q ProfZB; zxmin=min(V_max, V_min); zxmax=max(V_min, V_max)
							zc=min(max(ax,zxmin),zxmax)
						endif
					endif
					break
				case "pt":
					if(hasZP)
						if(Harrow==1)
							GetAxis/Q ProfTB; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
							tc=min(max(ax,txmin),txmax)
						endif
					endif
					break
			endswitch
		endif 
		// only update images that have changed
		if ((xcg!=xc)&&(xlock==0))
			xcg=xc
		endif
		if ((ycg!=yc)&&(ylock==0))
			ycg=yc
		endif
		if ((zcg!=zc)&&(zlock==0))
			zcg=zc
		endif
		if ((tcg!=tc)&&(tlock==0))
			tcg=tc
		endif
		returnval=1
	endif
	if(returnval==1) // only if we have handled the event
		//doupdate
		//	 CTs updated by dependency trigger
		if(hasHP*AutoScaleHP)
			AutoscaleInRange("profHL","bottom",1)
		endif
		if(hasVP*AutoScaleVP)
			AutoscaleInRange("left","profVB",2)
		endif
		NVAR ScanSystem=root:Packages:ImagetoolV:ScanSystem
		if(ScanSystem>0)
			SendToScan(IT5_getCursorsJSON(df))
		endif
	endif
	return returnval
end	


function updateCursorPoints(df,xp,yp,zp,tp)
	string df
	variable xp,yp,zp,tp
	nvar xpi=$(df+"xpi"), ypi=$(df+"ypi"), zpi=$(df+"zpi"), tpi=$(df+"tpi")
	if(xpi!=round(xp))
		xpi=round(xp)
	endif
	if(ypi!=round(yp))
		ypi=round(yp)
	endif
	if(zpi!=round(zp))
		zpi=round(zp)
	endif
	if(tpi!=round(tp))
		tpi=round(tp)
	endif
end


function img4DHookFcn(s)
	string s
	string dfn=getdfname(); string df=getDFfromName(dfn)
	// set the new window hook function on old graphs
	setwindow $dfn,hook(cursorhook)=img4DHookFcn2,hookevents=3,hook=$"" 
	return 1
end	

static function adjustCT(df,imgname)
	string df,imgname
	struct imageWaveNameStruct s
	getimageinfo(df,imgname,s) 
	NVAR has = $(df+s.has)
	if(has==1)
		wave img=$(df+s.image), imgROI=$(df+s.imageROI)
		wave xw=$(df+s.xwv)
		wave ct=$(df+s.ctwave)		
		nvar ict=$(df+s.whinvertct)
		nvar imode=$(df+s.imode)
		if(imode!=3)
			if((imode==2)*(numpnts(xw)>0))
				imagestats/M=1 /r=imgROI img
			else
				imagestats /M=1 img
			endif
			setscale/i x v_min,v_max,ct
		endif
		NVAR HistNormCT=$(df+"HistNormCT") 	
		if (HistNormCT)
			if((imode==2)*(numpnts(xw)>0))
				ImageHistogram /r=imgROI img
			else
				ImageHistogram  img
			endif
			wave W_imageHist
			wave hist=$(df+s.image+"_hist")
			hist = W_imageHist
			integrate hist
			wavestats /Q hist
			hist /= V_max/255
			setscale /p x 0,1,hist
			string whCT = df+s.whCT
			nvar HiResCT=$(df+"HiResCT")
			if(HiResCT!=1)
				nvar whichCT=$(df+s.whCT)
				setformula $(df+s.ctwave), "root:colors:all_ct["+df+"pmap["+df+s.image+"_hist[p]]][q]["+whCT+"]"			
			else			
				setformula $(df+s.ctBwave), "root:colors:all_ct[p][q]["+whCT+"]"
				setformula $(df+s.ctwave), "interp2d("+df+s.ctBwave+","+df+"pmap("+df+s.image+"_hist(255*p/ct_size)),q)"
			endif
		endif
	endif
end



Function selectCTList(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	SetAllColorTables(df,popnum-1)
//	nvar  whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"),whichCTv=$(df+"whichCTv"),whichCTzt=$(df+"whichCTzt")
//	whichCT=popnum-1
//	whichCTh=popnum-1
//	whichCTv=popnum-1
//	whichCTzt=popnum-1
End

Function SetAllColorTables(df,CT_Num)
	string df
	variable CT_num
	nvar  whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"),whichCTv=$(df+"whichCTv"),whichCTzt=$(df+"whichCTzt")
	whichCT=CT_Num
	whichCTh=CT_Num
	whichCTv=CT_Num
	whichCTzt=CT_Num
end

Function SetAllColorTablesInvert(df,invert)
	string df
	variable invert
	NVAR invertCT = $(df+"invertCT")
	NVAR invertCT_H = $(df+"invertCT_H")
	NVAR invertCT_V = $(df+"invertCT_V")
	NVAR invertCT_ZT = $(df+"invertCT_ZT")
	invertCT = invert
	invertCT_H = invert
	invertCT_V = invert
	invertCT_ZT = invert
end


Function DoExportCropped(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			string df=getdf()
			wave dnum=$df+"dnum"
			nvar ndim=$df+"ndim", ZTPMode=$df+"ZTPMode",hasZP=$df+"hasZP", hasTP=$df+"hasTP"
			svar dname=$(df+"dname")
			variable i,ii,p0,p1,axesShown, toobig=0
			string ss, axStrings,wvstrings,wvs,wvout,plow="",phigh="",pn=""


			// check if high enough dimensions
			if (ndim<3)
				abort "Use regular export menu when wave is dimension <=2"
			endif
			//check if correct axes are showing
			axesShown=selectnumber(ndim==4, hasZP, ZTPMode+(hasTP*hasZP))
			if(axesShown==0)
				abort selectstring(ndim==4,"For 3D waves, you must show ZP for this operation", "For 4D waves, Either the corner image, or else both Z and T Profiles, must be visible")
			endif
			wvout=dname+"_c"
			prompt wvout,"Enter name of output wave"
			doprompt "User Input", wvout
			if(v_flag)
				//cancelled
				abort
			endif
			
			//figure out ranges
			axStrings="bottom;left;"+selectstring(ndim==4,"profZB", selectstring(ZTPMode,"profZB;profTB","imgZTt;imgZTr"))
			wvStrings="img;img;"+selectstring(ndim==4,"pz", selectstring(ZTPMode,"pz;pt","imgZT;imgZT"))
			for(i=0;i<ndim;i+=1)
				//ss=axisinfo("",stringfromlist(i,axStrings,";")
				getaxis/q $stringfromlist(i,axStrings,";")
				wvs=stringfromlist(i,wvStrings,";")
				wave wv=$df+wvs
				ii=selectnumber(i>=2,i,selectnumber(ZTPMode,0,i-2))
				p0=min(scaleToIndex(wv,v_min,ii), scaleToIndex(wv,v_max,ii))
				p1=max(scaleToIndex(wv,v_min,ii), scaleToIndex(wv,v_max,ii))
				p0=selectnumber(p0<0, p0, 0)
				p1=selectnumber(p1>(dimsize(wv,ii)-1), p1, dimsize(wv,ii)-1)
				//print p0,p1
				plow+=num2istr(p0)+";"
				phigh+=num2istr(p1)+";"
				pn+=num2istr(p1-p0+1)+";"
			endfor
			//make wave
			printf "Making..."; doUpdate
			ss="make/o/n=("
			for(i=0;i<ndim;i+=1)
				ss+=selectstring(i==0,",","") + stringfromlist(i,pn)
			endfor
			ss+=") "+ wvout
			execute ss
			//copy data
			printf "Copying..."; doUpdate
			wave wvo = $wvout
			wave wvi=$dname
			string indName="p;q;r;s"
			ss= wvout + "=" + dname
			wave adnum=$df+"adnum"
			for(i=0;i<ndim;i+=1)
				ss+="[" + stringfromlist(adnum[i],indName) + "+" + stringfromlist(adnum[i],plow)+"]"
			endfor
			//print ss
			execute ss
			//scale wave
			print "Scaling..."; doUpdate
			for(i=0;i<ndim;i+=1)
				ss="setscale/p " + stringfromlist(i,"x;y;z;t") + "," + num2str(dimoffset(wvi,dnum[i]) + str2num(stringfromlist(i,plow))*dimdelta(wvi,dnum[i]))
				ss+="," + num2str(dimdelta(wvi,dnum[i])) +", \"" + waveunits(wvi,dnum[i]) +"\"," + wvout   
				//print ss
				execute ss
			endfor
	
			newImageTool5(wvout)			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
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
			execute "doupdate"
			//print r
			addmovieframe
		endfor
		if(modearr[region]==2)
			for(r=a1arr[region]-adarr[region];  r>=a0arr[region];r-=adarr[region])
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


Function ShowInDataBrowserButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string df=getdf()
			ShowWaveInDataBrowser(df)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

function ShowWaveInDataBrowser(df)
	string df
	SVAR dname=$(df+"dname")
	wave w = $dname
	string datafolder = GetWavesDataFolder(w,1)
	modifybrowser showWaves=1
	modifybrowser clearSelection
	modifybrowser selectList=dname
	createbrowser
end 

Function CreateStyleMacroButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string df=getdf()
			string IT5StyleMacro = IT5_GenerateSettingsMacro(df,AsString=1)
			DoWindow /F IT5StyleMacro
			if(V_Flag==0)
				newnotebook /N=IT5StyleMacro/F=0/K=1
			endif
			Notebook IT5StyleMacro selection={startOfFile, endOfFile}	
			notebook IT5StyleMacro text=IT5StyleMacro
			
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

function /S ExportMenuString(df)
	string df
	string result = "--Profiles--"
	svar dname=$(df+"dname")
	wave w=$dname
	WAVE dnum=$(df+"dnum")
	nvar ztpmode=$(df+"ztpmode"),hasZP=$(df+"hasZP"), hasTP=$(df+"hasTP"),hasVI=$(df+"hasVI"),hasHI=$(df+"hasHI"),hasVP=$(df+"hasVP"),hasHP=$(df+"hasHP")
	if (hasHP==1)
		result += ";"+"Hprof ["+waveunits(w,dnum[0])+"]"
	endif
	if (hasVP==1)
		result += ";"+"Vprof ["+waveunits(w,dnum[1])+"]"
	endif
	if (hasZP==1)
		result += ";"+"Zprof ["+waveunits(w,dnum[2])+"]"
	endif
	if (hasTP==1)
		result += ";"+"Tprof ["+waveunits(w,dnum[3])+"]"
	endif		


	struct imageWaveNameStruct s
	result +=";--Images--"
	getimageinfo(df,"img",s)
	result += ";"+"img ["+waveunits(w,s.hindex)+ " vs " + waveunits(w,s.vindex)+"]"
	if (hasHI==1)
		getimageinfo(df,"imgH",s)
		result += ";"+"imgH ["+waveunits(w,s.hindex)+ " vs " + waveunits(w,s.vindex)+"]"
	endif
	if (hasVI==1)
		getimageinfo(df,"imgV",s)
		result += ";"+"imgV ["+waveunits(w,s.hindex)+ " vs " + waveunits(w,s.vindex)+"]"
	endif
	if (ztpmode==1)
		getimageinfo(df,"imgZT",s)
		result += ";"+"imgZT ["+waveunits(w,s.hindex)+ " vs " + waveunits(w,s.vindex)+"]"
	endif
	return result
end


Function ExportMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string df=getdf()
	string item
	sscanf popStr, "%s", item
	struct imageWaveNameStruct s
	if (getimageinfo(df,item,s)==0)
		Export_image(df,s)
	elseif (gettraceinfo(df,item,s)==0)
		Export_Trace(df,s)
	endif
End

function Export_ALL(df)
	string df
	SVAR dname = $(df+"dname")

	string name = StrVarOrDefault(df+"ImgExportName",dname+"_")
	prompt name,"name to export"
	doprompt "Export Image Options",name

	if(V_Flag==0)
		string /G $(df+"ImgExportName")
		SVAR ImgExportName=$(df+"ImgExportName") 
		ImgExportName = name
		duplicate/o $(dname) $(name)
		wave Src=$(dname)
		wave dest = $(name)
		wave norm1 = $(df+"norm1")
		string nn1="Norm1"//+num2str(Norm_num)
		NVAR Norm1_ON=$(df+"Norm1_ON")//+num2str(Norm_num)
		if(Norm1_ON==1)
			dest=(src[p][q][r][s])*norm1[p][q][r][s]
		endif
	endif
end



function Export_image(df,s)
	string df
	struct imageWaveNameStruct &s
	variable mv0,mv1,mh0,mh1,marquee
	variable gv0,gv1,gh0,gh1
	string notestr=""
	getaxis/q $s.vaxis; gV0=min(v_min,v_max); gV1=max(v_min,v_max)
	getaxis/q $s.haxis; gH0=min(v_min,v_max); gH1=max(v_min,v_max)
	getmarquee 
	if(V_flag==1)
		getmarquee  $s.vaxis , $s.haxis
		mH0=min(V_left,V_right)
		mH1=max(V_right,V_left)
		mV0=Min(V_top,V_bottom)
		mV1=Max(V_top,V_bottom)
		marquee=1
	endif
	SVAR dname = $(df+"dname")
	wave Swv = $dname
	string s_note = note(swv)
	string fname = StringByKey("file", s_note,"=","\r")
	if(strlen(fname)>0)
		notestr = "file="+fname+"\r"
	endif
	notestr += "source:name="+dname+","+"tool="+df+"\r"
	notestr += "coord:"+getcoordstr(df)+"\r"
	notestr += "bin:"+getbinstr(df)+"\r"
	string name = StrVarOrDefault(df+"ImgExportName",dname+"_")
	variable range = NumVarOrDefault(df+"ImgExportRange",1)
	variable disp = NumVarOrDefault(df+"ImgExportDisp",1)

	prompt name,"name to export"
	if(V_flag==1)
		range = 3
		prompt range,"range to export",popup "all;from axis ranges;from Maquee"
	else
		prompt range,"range to export",popup "all;from axis ranges"
	endif
	prompt disp ,"Display Option",popup "Display;Display with colorbar;Imagetool4;ImageTool5;nothing"
	doprompt "Export Image Options",name,range,disp

	if(V_Flag==0)
		If(marquee==1)
			getmarquee /K
		endif
		variable /G $(df+"ImgExportRange")
		NVAR ImgExportRange=$(df+"ImgExportRange")
		variable /G $(df+"ImgExportDisp")
		NVAR ImgExportDisp=$(df+"ImgExportDisp")
		string /G $(df+"ImgExportName")
		SVAR ImgExportName=$(df+"ImgExportName")
		ImgExportRange = range
		ImgExportDisp = disp
		ImgExportName = name
		switch(range)
			case 1: //all
				duplicate/o $(df+s.image) $(name)
				break
			case 2:
				duplicate/o/r=(gH0,gH1)(gV0,gV1) $(df+s.image) $(name)
				break
			case 3:
				duplicate/o/r=(mH0,mH1)(mV0,mV1) $(df+s.image) $(name)
				break
			endswitch
		wave Owv = $(name)
		Note/K Owv			//kill previous note
	 	Note Owv,  notestr

		Switch(disp)
			case 1:
			case 2:				
			duplicate/o $(df+s.ctwave) $(name+"_ct")
			nvar  whichCT=$(df+s.whCT)
			nvar gamma=$(df+s.whgamma)
			nvar invertCT=$(df+s.whInvertCT)

			string colorlist = colornameslist()
			string ctnam = StringFromList(whichCT, colorlist)
			notestr ="CT:name="+CTnam+",gamma="+num2str(gamma)+",invert="+num2str(invertCT)+"\r"
			WAVE CTw=$(name+"_ct")
			Note/K CTw			//kill previous note
   		Note CTw,  notestr
			display; appendimage $name
			TextBox/C/N=TB_wavename/F=0/A=RB/X=0.00/Y=0.00/E=2 nameofwave($name)
			wave wct=$(name+"_ct")
			ModifyImage  $(nameofwave($name)) cindex= wct
			if(disp==2)
				make/o/n=(3,dimsize(wct,0)) $(name+"_cbox"); wave cbox=$(name+"_cbox")
				cbox=dimoffset(wct,0) + q*dimdelta(wct,0)
				setscale/p y dimoffset(wct,0), dimdelta(wct,0), cbox
				appendimage/b=cbb/r=cbr cbox
				string cimagename=nameofwave($(name+"_cbox"))
				ModifyImage  $cimagename cindex= wct
				ModifyGraph axisEnab(cbb)={0.9,1},freePos(cbb)=0
				ModifyGraph axisEnab(bottom)={0,0.85},freePos(cbr)=0
				ModifyGraph lblPos(cbr)=50, noLabel(cbb)=2, tick(cbb)=3
			endif
			break
			case 3:
			newImagetool(name)
			break
			case 4:
			NewImageTool5(name)
			break
		endswitch	
	endif
end	


function Export_Trace(df,s)
	string df
	struct imageWaveNameStruct &s
	variable m0,m1,marquee
	variable g0,g1
	string axis
	if (s.vindex>=0)
		axis = s.vaxis
	elseif(s.hindex>=0)
		axis=s.haxis
	else
		return 0
	endif
	getaxis/q $axis; g0=min(v_min,v_max); g1=max(v_min,v_max)
	getmarquee 
	if(V_flag==1)
		getmarquee  $s.vaxis , $s.haxis
		if (s.vindex>=0)
			m0=Min(V_top,V_bottom)
			m1=Max(V_top,V_bottom)
			marquee=1
		elseif(s.hindex>=0)
			m0=min(V_left,V_right)
			m1=max(V_right,V_left)
			marquee=1
		else
			marquee=0
		endif
	endif
	SVAR dname = $(df+"dname")
	string name = StrVarOrDefault(df+"TraceExportName",dname+"_")
	variable range = NumVarOrDefault(df+"TraceExportRange",1)
	variable disp = NumVarOrDefault(df+"TraceExportDisp",1)

	prompt name,"name to export"
	if(V_flag==1)
		prompt range,"range to export",popup "all;from axis ranges;from Maquee"
	else
		prompt range,"range to export",popup "all;from axis ranges"
	endif
	prompt disp ,"Display Option",popup "Display;append;nothing"
	doprompt "Export Trace Options",name,range,disp
	if(V_Flag==0)
		If(marquee==1)
			getmarquee /K
		endif
		variable /G $(df+"TraceExportRange")
		NVAR TraceExportRange=$(df+"TraceExportRange")
		variable /G $(df+"TraceExportDisp")
		NVAR TraceExportDisp=$(df+"TraceExportDisp")
		string /G $(df+"TraceExportName")
		SVAR TraceExportName=$(df+"TraceExportName")
		TraceExportRange = range
		TraceExportDisp = disp
		TraceExportName = name
		switch(range)
			case 1: //all
				duplicate/o $(df+s.image) $(name)
				break
			case 2: //  axis range
				duplicate/o/r=(g0,g1) $(df+s.image) $(name)
				break
			case 3: //  marquee
				duplicate/o/r=(m0,m1) $(df+s.image) $(name)
				break
		endswitch
		Switch(disp)
			case 1:				
				display $name
				break
			case 2:
				string win=winname(0,1)
				if(strsearch(win,"ImageToolV",0)==0)
					win=winname(1,1)		
					if(strsearch(win, "ImageTool", 0 )<0 && strlen(win)>0)	
						// dowindow /F $win
						Appendtograph /W=$win $name
					endif
				endif
				break
			case 3:
				break
		endswitch	
	endif
end	


static function/s getDF()
	return getDFfromName(getDFname())
end

static function /s getDFfromName(winnam)
	string winnam
	if (DataFolderExists("root:"+winnam+":"))
		return "root:"+winnam+":"
	elseif ( DataFolderExists("root:imagetoolV:"+winnam+":"))
		return  "root:imagetoolV:"+winnam+":"
	endif
	
	return "root:"+winnam+":"
end

//gets the name of the topmost imagetoolV 
static function/s getDFname()
	string wlist = winlist("imagetoolV*",";","WIN:1")
	return StringFromList(0, wlist  )
	//return winname(0,1)
end

function/s IT5_getDFfromNum(It5_Num)
	variable IT5_NUM
	string df = "root:imagetoolV"+num2str(It5_Num)+":"
	if (DataFolderExists(df))
		return df
	endif
	df = "root:imagetoolV:imagetoolV"+num2str(It5_Num)+":"
	if (DataFolderExists(df))
		return df
	endif
	return ""
end

Function StoreDataProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string df=getdf()
			svar dname=$(df+"dname")
			wave wv=$dname
			svar storewv=$(df+"DataStoreWave")
			strswitch (pa.popstr)
				case "New":
					string st=""
					prompt st,"Enter the wavename"
					doprompt "New Data Wave",st
					storewv=st
					switch (wavedims(wv))
						case 4:
							make/o/n=0 $(st+"_t")
						case 3:
							make/o/n=0 $(st+"_z")
						case 2:
							make/o/n=0 $(st+"_data"), $(st+"_x"), $(st+"_y")
					endswitch
						
				break
				case "Edit":
					if (strlen(storewv))
						switch (wavedims(wv))
							case 4:
								edit $(storewv+"_x"), $(storewv+"_y"), $(storewv+"_z"), $(storewv+"_t"), $(storewv+"_data")
								break
							case 3:
								edit $(storewv+"_x"), $(storewv+"_y"), $(storewv+"_z"), $(storewv+"_data")
								break
							case 2:
								edit $(storewv+"_x"), $(storewv+"_y"), $(storewv+"_data")
								break
						endswitch
					else
						print "no storage wave defined"
					endif
				break
				case "Clear":
					if (strlen(storewv))
						switch (wavedims(wv))
							case 4:
								redimension/n=0 $(storewv+"_x"), $(storewv+"_y"), $(storewv+"_z"), $(storewv+"_t"), $(storewv+"_data")
								break
							case 3:
								redimension/n=0 $(storewv+"_x"), $(storewv+"_y"), $(storewv+"_z"), $(storewv+"_data")
								break
							case 2:
								redimension/n=0 $(storewv+"_x"), $(storewv+"_y"), $(storewv+"_data")
								break
						endswitch

					else
						print "no storage wave defined"
					endif
				break
				case "Sort":
					if (strlen(storewv))
						string ss=""
						switch (wavedims(wv))
							case 4:
								ss+= storewv + "_t"
							case 3:
								ss=  storewv + "_z,"+ ss
							case 2:
								ss="sort "+storewv+"_x," + storewv + "_x,"+ storewv + "_y," + storewv + "_data," +ss
						endswitch
						execute ss
					else
						print "no storage wave defined"
					endif
				break


			endswitch
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function CapturePointProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			string df=getdf()
			svar storewv=$(df+"DataStoreWave")
			svar dname=$(df+"dname")
			wave wv=$dname
			svar storewv=$(df+"DataStoreWave")
			wave wvx=$(storewv+"_x"), wvy=$(storewv+"_y"), wvz=$(storewv+"_z"), wvt=$(storewv+"_t"), wvd=$(storewv+"_data")

			if (strlen(storewv))
				variable np=numpnts(wvx)
				switch (wavedims(wv))
					case 4: 
						redimension/n=(np+1) wvt
						nvar tc=$(df+"tc")
						wvt[np]=tc
					case 3:
						redimension/n=(np+1) wvz
						nvar zc=$(df+"zc")
						wvz[np]=zc
					case 2:
						redimension/n=(np+1) wvx, wvy, wvd
						nvar xc=$(df+"xc"), yc=$(df+"yc"), d0=$(df+"d0")
						wvx[np]=xc
						wvy[np]=yc
						wvz[np]=zc
						wvd[np]=d0
				endswitch
					
				break
			else
				print "no data store wave defined"
			endif
		case -1: // control being killed
			break
	endswitch
	return 0
End


Function SetPCursor(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			string df =getDFfromName(sva.win)
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

Function SliderAxisProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
	switch( sa.eventCode )
		case -1: // kill
			break
		default:
			if( sa.eventCode & 1 ) // value set
				string df=getdf()
				svar dname=$(df+"dname")
				Variable curval = sa.curval
				setupV(getdfname(),dname)
			endif
			break
	endswitch
	return 0
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
//	setupdim34value(df,ctrlname,sv)
//	setupdim34value(df,other,svother)
End

Function InvertCTCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			string df=getdf()
			SetAllColorTablesInvert(df,checked)
			break
	endswitch
	return 0
End



function LoadNewImgV(ctrlName) : ButtonControl
	string ctrlName
	string df=getdf()
	string wn = ""
	variable reset=1
	svar dname = $(df+"dname")
	WAVE /Z cwv = $dname
	if(waveexists(cwv))
		wn = nameofwave(cwv)
	endif
	prompt wn, "New array", popup, "; -- 4D --;"+WaveList("!*_CT",";","DIMS:4")+"; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")+"; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	prompt reset, "Reset Settings?",popup,"Yes;No"
	DoPrompt "Select 2D Image (or 3D volume)" wn,reset
	if (V_flag==1)
		abort		//cancelled
	endif
	//SetupVariables(getdfname())
	NVAR isnew=$(df+"isnew")
	variable /g $(df+"rebuild")=1
	
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
	if(reset==2)
		variable /g $(df+"rebuild")=1
	else
		isnew=1
	endif
	tabcontrol tab0, value=0
	controlinfo tab0 

	tabproc("",V_Value)
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


function/S whichaxis(wn,px,py)
	string wn
	variable px,py 
	variable axmin, axmax, aymin, aymax ,Vmin,Vmax,Hmin,Hmax
	variable	ay=axisvalfrompixel(wn,"left",py)
	variable	ax=axisvalfrompixel(wn,"bottom",px)	
	GetAxis/Q bottom; Hmin=V_min;Hmax=V_max;axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	
	GetAxis/Q left; Vmin=V_min;Vmax=V_max;aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	if( (( (ay<Vmin) && (Vmin<Vmax) ) ||(  (ay>Vmin) && (Vmin>Vmax) )))
		if((ax<axmax) && (ax>axmin) )
			return "bottom"
		endif
		GetAxis/Q imgVb; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
		ax=axisvalfrompixel(wn,"imgVB",px)
		if((ax<axmax) && (ax>axmin) )
			return "imgVB"
		endif
	elseif( (( (ax<Hmin) && (Hmin<Hmax) ) ||(  (ax>Hmin) && (Hmin>Hmax) )))
		if((ay<aymax) && (ay>aymin) )
			return "left"
		endif
		GetAxis/Q imgHL; aymin=min(V_max, V_min); aymax=max(V_min, V_max)
		ay=axisvalfrompixel(wn,"imgHL",py)
		if((ay<aymax) && (ay>aymin) )
			return "imgHL"
		endif
	endif	
	getaxis/q imgztr; Vmin=V_min;Vmax=V_max;aymin=min(V_max, V_min); aymax=max(V_min, V_max)
	GetAxis/Q imgztt; Hmin=V_min;Hmax=V_max;axmin=min(V_max, V_min);axmax=max(V_min, V_max)
	ay=axisvalfrompixel(wn,"imgztr",py)
	ax=axisvalfrompixel(wn,"imgZTt",px)
	if((ax<axmax&&ax>axmin)&&(( (ay>Vmax) && (Vmin<Vmax) ) ||(  (ay<Vmax) && (Vmin>Vmax) )))
		return "imgZTt"
	elseif((ay<aymax&&ay>aymin)&& (( (ax>Hmax) && (Hmin<Hmax) ) ||(  (ax<Hmax) && (Hmin>Hmax) )))
		return "imgztr"
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
	string wlist = winlist("STACKV*",";","WIN:1")
	string dfn =StringFromList(0, wlist  )
	//string dfn=stringfromlist(1,df,":")
	variable snum
	sscanf dfn ,"STACKV %i", snum
	return getDFfromName("ImageToolV"+num2istr(snum))
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
			DoWindow $swn // Stack_
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
					AppendToGraph /W=$swn $(basen+num2istr(ii))
					ii+=1
				WHILE( ii<nw )
			endif

			if (nw<nt)				//remove extra waves
				ii=nw
				DO
					//			RemoveFromGraph $(basen+num2istr(ii))
					RemoveFromGraph /W=$swn $StrFromList(trace_lst,ii, ";")

					wn = StrFromList(trace_lst,ii, ";")
					killwaves $(df+"STACK:"+wn)
					ii+=1
				WHILE( ii<nt )
			endif
			 curr=GetDataFolder(1)
			setdatafolder $(df+"stack:")
			trace_lst=wavelist("line*",";","")
			nt=ItemsInList(trace_lst,";")

			if (nw<nt)				//remove extra waves
				ii=nw
				DO
					//			RemoveFromGraph $(basen+num2istr(ii))

					wn = StrFromList(trace_lst,ii, ";")
					killwaves $(df+"STACK:"+wn)
					ii+=1
				WHILE( ii<nt )
			endif
			setdatafolder $curr

			SVAR imgnam=$(df+"dname")
			DoWindow/T $swn, swn+": "+imgnam

			NVAR dmax=$(df+"STACK:dmax"), dmin=$(df+"STACK:dmin")
			variable shiftinc=DimDelta(imgstack,0), offsetinc, exp
			offsetinc=0.1*(dmax-dmin)
			exp=10^floor( log(offsetinc) )
			offsetinc=round( offsetinc / exp) * exp
			//	print offsetinc, exp
			SetVariable setshift limits={-Inf,Inf, shiftinc}, win=$swn
			SetVariable setoffset limits={-Inf,Inf, offsetinc},win=$swn
			NVAR shift=$(df+"STACK:shift"),  offset=$(df+"STACK:offset")
			shift=0
			offset=offsetinc*(1-2*(offset<0))		//preserve previous sign of offset
			Stack_OffsetStack(df, shift, offset)
			SetDataFolder curr
			break
	endswitch
End


Static Function Stack_SetOffset(ctrlName,varNum,varStr,varName) : SetVariableControl
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

	Stack_OffsetStack(df, shift,offset)
End

Static Function Stack_MoveCursor(ctrlName) : ButtonControl
	//------------
	String ctrlName
	//root:IMG:STACK:offset=0.5*(root:IMG:STACK:dmax-root:IMG:STACK:dmin)
	//Stack_OffsetStack( root:IMG:STACK:shift, root:IMG:STACK:offset)
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

Static Function Stack_OffsetStack( df,shift, offset )
	//================
	string df
	Variable shift, offset

	//string trace_lst=TraceNameList("",";",1 )
//	string df=stack_getdf(), 
	string curr=GetDataFolder(1)
	setdatafolder $(df+"stack:")
	string trace_lst=wavelist("line*",";","")
	setdatafolder curr

	variable nt=ItemsInList(trace_lst,";")
	//	print nt

	variable ii=0
	string wn, cmd
	string swn=stack_getswn(df)

	DO
		wn=StrFromList(trace_lst, ii, ";")
		//print wn
		WAVE w=$wn
		//		ModifyGraph offset(wn)={ii*shift, ii*offset}
		cmd="ModifyGraph /W="+swn+" offset("+wn+")={"+num2str(ii*shift)+", "+num2str(ii*offset)+"}"
		execute cmd
		ii+=1
	WHILE( ii<nt )
	return nt
End

static Function Stack_Export(ctrlName) : ButtonControl
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
	SetVariable setshift,pos={6,2},size={80,14},proc=ImageTool5#Stack_SetOffset,title="shift"
	SetVariable setshift,help={"Incremental X shift of spectra."},fSize=10
	SetVariable setshift,limits={-Inf,Inf,0.002},value= $(df+"STACK:shift")
	SetVariable setoffset,pos={90,2},size={90,14},proc=ImageTool5#Stack_SetOffset,title="offset"
	SetVariable setoffset,help={"Incremental Y offset of spectra."},fSize=10
	SetVariable setoffset,limits={-Inf,Inf,0.2},value= $(df+"STACK:offset")
	Button MoveImgCsr,pos={188,1},size={35,16},proc=ImageTool5#Stack_MoveCursor,title="Csr"
	Button MoveImgCsr,help={"Reposition cross-hair in Image_Tool panel to the location of the A cursor placed in the Stack_ window."}
	Button ExportStack,pos={233,1},size={50,16},proc=ImageTool5#Stack_Export,title="Export"
	Button ExportStack,help={"Copy stack spectra to a new window with a specified basename.  Wave notes contain appropriate shift, offset, and Y-value information."}
End

//---------------------------------------
//TILE STUFF
Function doTile(ctrlName) : ButtonControl
	String ctrlName
	TileStartup()
End

//a single image (XY Image (index 1, 2), over 3rd dimension Z(index 0), usually eV) in a ImageTool5 must be on top, that will be converted to a tile of multiple
function tileStartup()
	variable i
	print getdf()
	svar dname=$getdf()+"dname"
	string indexWave=getdf()+"iwv1"
	wave wv0=$dname
	string un=uniquename("Tile",11,0)
	string df="root:"+un
	newdatafolder/o $df
	df+=":"
	make/t/n=1/o $df+"names"
	wave/t names=$df+"names"
	names[0]=nameofwave($dname)
	make/n=1/o $df+"cx",$df+"cy"
	wave cx=$df+"cx",cy=$df+"cy"
	cx=0; cy=0

	duplicate/o $indexWave $df+"iwv1"; 	wave iwv1=$df+"iwv1"
	duplicate iwv1 $df+"iwv" ;	wave iwv=$df+"iwv"
	duplicate iwv1 $df+"iwv2"
	iwv=p
	sort iwv1,iwv1,iwv	//iwv now holds the correct index i.e. iwv[0]=index of x-direction etc

	duplicate/o wv0 $df+"img"
	wave img=$df+"img"
	display;appendimage img
	DoWindow/C/T $un,un

	controlbar 100
	modifygraph cbRGB=(12000,23000,1000)
	Button editList title="edit list",size={75,20},proc=editList
	Button reTile title="reTile",proc=doReTile	
	Button ExportFull title="Export Full",size={100,20},proc=ExportFull

	retile()
end

function/t getTiledf()
	return "root:"+winname(0,1)+":"
end


//tile window should be on top
function reTile()
	setdatafolder root:
	//set data ranges
	string df=getTiledf()
	wave/t names=$df+"names"
	variable nwv=dimsize(names,0)
	make/o/n=(2,2,nwv) $df+"drange"
	wave drange=$df+"drange"
	make/o/n=(nwv) $df+"xmin",$df+"xmax",$df+"ymin",$df+"ymax"
	wave xmin= $df+"xmin",xmax=$df+"xmax",ymin=$df+"ymin",ymax=$df+"ymax"
	string wv
	variable x0,x1,y0,y1,xs,ys,i
	wave cx=$df+"cx"
	wave cy=$df+"cy"
	wave iwv=$df+"iwv",iwv2=$df+"iwv2"
	variable xi=iwv[0],yi=iwv[1],zi=iwv[2],ti=iwv[3]
	for(i=0;i<nwv;i+=1)
		wv=names[i]
		if(i==0)
			xs=abs(dimdelta($wv,xi))
			ys=abs(dimdelta($wv,yi))
		else
			xs=min(abs(dimdelta($wv,xi)),xs)
			ys=min(abs(dimdelta($wv,yi)),ys)
		endif
		x0=dimoffset($wv,xi)+cx[i]	//xmin
		x1=dimoffset($wv,xi)+dimdelta($wv,xi)*dimsize($wv,xi)+cx[i]//xmax
		y0=dimoffset($wv,yi)+cy[i]	//ymin
		y1=dimoffset($wv,yi)+dimdelta($wv,yi)*dimsize($wv,yi)+cy[i]	//ymax

		drange[0][0][i]=min(x0,x1)	;	xmin[i]=drange[0][0][i]
		drange[1][0][i]=max(x0,x1)	;	xmax[i]=drange[1][0][i]
		drange[0][1][i]=min(y0,y1)	;	ymin[i]=drange[0][1][i]
		drange[1][1][i]=max(y0,y1)	;	ymax[i]=drange[1][1][i]		

	endfor
	wavestats/q xmin; x0=v_min
	wavestats/q xmax; x1=v_max
	wavestats/q ymin; y0=v_min
	wavestats/q ymax; y1=v_max
	make/o/n=((x1-x0)/xs,(y1-y0)/ys) $df+"img"
	wave img=$df+"img"
	img=nan
	setscale/p x x0,xs,img
	setscale/p y,y0,ys,img

	calcimg(df,1,0,0)

end

//if isAverage, then calculate image over all j,k averaged.
//if not, then evaluate only at specific j,k
 function calcimg(df,isAverage,j,k)
	string df
	variable isAverage,j,k
	variable p0,p1,q0,q1,jj,kk,i
	wave/t names=$df+"names"
	variable nwv=dimsize(names,0)
	wave iwv=$df+"iwv",iwv2=$df+"iwv2",xmin=$df+"xmin",ymin=$df+"ymin",xmax=$df+"xmax",ymax=$df+"ymax"
	wave img=$df+"img",cx=$df+"cx",cy=$df+"cy"
	variable xi=iwv[0],yi=iwv[1],zi=iwv[2],ti=iwv[3]

	string si="pqjk",si1=df+"imgav+=",si2="",si3,ss,wv
	for(i=0;i<4;i+=1)
		si2+="["+si[iwv2[i]]+"]"
	endfor
	for(i=0;i<nwv;i+=1)
		wv=names[i]
		make/o/n=(dimsize($wv,xi),dimsize($wv,yi)) $df+"imgav"
		wave imgav=$df+"imgav"
		imgav=0
		if (isAverage)
			for(jj=0;jj<dimsize($wv,zi);jj+=1)
				for(kk=0;(kk==0)+(kk<dimsize($wv,ti));kk+=1)
					si3=strsub(si2,jj,kk)
					ss= si1+"root:"+names[i]+si3
					execute ss
				endfor
			endfor
		else
			si3=strsub(si2,j,k)
			ss=si1+"root:"+names[i]+si3
			execute ss
		endif
		setscale/p x dimoffset($wv,xi),dimdelta($wv,xi),imgav
		setscale/p y dimoffset($wv,yi),dimdelta($wv,yi),imgav

		p0=(xmin[i] - DimOffset(img, 0))/DimDelta(img,0)
		p1=(xmax[i] - DimOffset(img, 0))/DimDelta(img,0)
		q0=(ymin[i] - DimOffset(img, 1))/DimDelta(img,1)
		q1=(ymax[i] - DimOffset(img, 1))/DimDelta(img,1)
		img[p0,p1-1][q0,q1-1]=interp2d(imgav,x-cx[i],y-cy[i])
	endfor
end

//replace literal "j" with numeric j and "k" with k
//string must have both j and k, not at beginning or end, lowercase
static function/t strsub(ss,j,k)
	string ss; variable j,k
	variable v0=strsearch(ss,"j",0)
	string ans=ss[0,v0-1]+num2str(j)+ss[v0+1,999]
	v0=strsearch(ans,"k",0)
	return ans[0,v0-1]+num2str(k)+ans[v0+1,999]
end

Function editList(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			string df=getTileDF()
			string wn=winname(0,1)+"_table"
			dowindow/f $wn
			if(v_flag==0)
				edit $df+"names",$df+"cx",$df+"cy"
				dowindow/c/t $wn,wn
			endif
			break
	endswitch
	return 0
End

Function doReTile(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			retile()
			break
	endswitch
	return 0
End

//exports full data set to new array
Function ExportFull(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string nm
			prompt nm,"Name of Exported Tile"
			doprompt "Export Full",nm
			string df=getTiledf()
			wave img=$df+"img"
			duplicate/o img $nm
			wave wv=$nm
			wave/t names=$df+"names"
			wave iwv=$df+"iwv"
			variable nz=dimsize($names[0],iwv[2])
			variable nt=dimsize($names[0],iwv[3])
			redimension/n=(-1,-1,nz,nt) wv
			setscale/p z,dimoffset($names[0],iwv[2]),dimdelta($names[0],iwv[2]),wv
			setscale/p t,dimoffset($names[0],iwv[3]),dimdelta($names[0],iwv[3]),wv
			variable j,k
			for(j=0;j<nz;j+=1)
				for(k=0;(k==0)+(k<nt);k+=1)
					calcImg(df,0,j,k)
					doupdate
					wv[][][j][k]=img[p][q]
				endfor
			endfor
			NewImageTool5(nameofwave(wv))
			break
	endswitch
	return 0
End

Function GammaSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
	switch( sa.eventCode )
		case -1: // kill
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
				string df = getdf()
				NVAR gamma=$(df+"gamma")
				if(curval>0)
					gamma = alog(curval) //curval+1
				else
					gamma = alog(curval)
				endif					
			endif
			break
	endswitch
	return 0
End

Function GammaNumericProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			string df = getdf()
			slider slidegamma value=log(sva.dval)
			break
	endswitch
	return 0
End

function UpdateGamma(df,gamma)
	string df
	variable gamma
	NVAR Lockgamma_img = $(df+"Lockgamma_img")
	NVAR Lockgamma_H = $(df+"Lockgamma_H")
	NVAR Lockgamma_V = $(df+"Lockgamma_V")
	NVAR Lockgamma_ZT = $(df+"Lockgamma_ZT")
	NVAR gamma_img = $(df+"gamma_img")
	NVAR gamma_H = $(df+"gamma_H")
	NVAR gamma_V = $(df+"gamma_V")
	NVAR gamma_ZT = $(df+"gamma_ZT")
	if(Lockgamma_img==0)
		gamma_img = gamma
	endif	
	if(Lockgamma_H==0)
		gamma_H = gamma
	endif
	if(Lockgamma_V==0)
		gamma_V = gamma
	endif
	if(Lockgamma_ZT==0)
		gamma_ZT = gamma
	endif
end

	

Function LinkCheckBoxProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			string df0 =  ImageTool5#getdf()
			string dfn0  = ImageTool5#getdfname()
			if (checked==1)
				ControlInfo LinkedImageTool5
				string dfn1 = S_Value
				if(cmpstr(dfn0,dfn1)==0)
					checkbox LinkCheckBox, value=0
					return 0
				endif
				linkmake_cursors(df0,getDFfromName(dfn1))
				linkmake_gamma(df0,getDFfromName(dfn1))
			elseif(checked==0)
				string cmd = df0+"CursorLinkTrig=0"
				execute cmd
				cmd = df0+"GammaLinkTrig=0"
				execute cmd
			endif
			break
	endswitch
	return 0
End


function linkmake_gamma(df0,df1)
	string df0, df1
	NVAR Linkgamma=$(df0+"Linkgamma")
	string cmd
	variable /g $(df0+"GammaLinkTrig")
	variable /g $(df0+"Link_GammaOld")
	NVar Link_GammaOld =$(df0+"Link_GammaOld")
	NVAR gamma1=$(df1+"gamma")
	Link_GammaOld = gamma1
	cmd= df0+"GammaLinkTrig" + ":= linkfunc_gamma(\""+df0+"\",\""+df1+"\","
	cmd += df0+ "gamma,"
	cmd += df1+ "gamma)"
	execute cmd
end

function linkfunc_gamma(df0,df1,gamma0,gamma1)
	string df0,df1
	variable gamma0,gamma1
	NVAR Linkgamma=$(df0+"Linkgamma")
	if(Linkgamma==1)
		NVar Link_GammaOld =$(df0+"Link_GammaOld")
		NVAR g0=$(df0+"gamma")
		NVAR gs0=$(df0+"gammaSlider")

		NVAR g1=$(df1+"gamma")
		NVAR gs1=$(df1+"gammaSlider")

		if(gamma0==Link_GammaOld)
			g0=gamma1
			gs0=log(gamma1)
			Link_GammaOld=gamma1
		else
			g1=gamma0
			gs1=log(gamma0)
			Link_GammaOld=gamma0
		endif
	endif
end

// make cursor dependecey between linked image tools
function linkmake_cursors(df0,df1)
	string df0, df1
	variable /g $(df0+"CursorLinkTrig")
	wave dnum1 = $(df1+"dnum")
	make /D/o/n=4  $(df0+"Link_Oldval")
	wave OldVal = $(df0+"Link_Oldval")
	wave linkoffset = $(df0+"linkoffset")

	variable i
	for(i=0;i<4;i+=1)
		NVAR c1 = $(axisvariable(df1,dnum1[i]))
		oldval[i]=c1-linkoffset[i]
	endfor

	string cmd= df0+"CursorLinkTrig" + ":= linkfunc_cursor(\""+df0+"\",\""+df1+"\","
	cmd += df0+ "linkoffset,"
	cmd += df0 + "xc,"+df1+"xc,"
	cmd += df0 + "yc,"+df1+"yc,"
	cmd += df0 + "zc,"+df1+"zc,"
	cmd += df0 + "tc,"+df1+"tc)"
	 execute cmd
end

// returns the name of the axis cursor variable
function /s axisvariable(df,axis)
	string df
	variable axis
	switch(axis)
		case 0:
			return df+"xc"
			break
		case 1:
			return  df+"yc"
			break	
		case 2:
			return df+"zc"
			break
		case 3:
			return df+"tc"
			break
	endswitch
end

// function used for depenecey between linked imagetools to update cursors
function linkfunc_cursor(df0,df1,linkoffset,x0,x1,y0,y1,z0,z1,t0,t1)
	string df0,df1
	wave  linkoffset
	variable  x0,x1,y0,y1,z0,z1,t0,t1 
	wave adnum0 = $(df0+"adnum")
	wave adnum1 = $(df1+"adnum")
	wave OldVal = $(df0+"Link_Oldval")
	variable i
	for(i=0;i<4;i+=1)
		nvar linkaxis = $(df0+"linkaxis"+num2str(i))
		IF (linkaxis==1)
			NVAR c0 = $(axisvariable(df0,adnum0[i]))
			NVAR c1 = $(axisvariable(df1,adnum1[i]))
			if(Oldval[i]!=c0+linkoffset[i])
				OldVal[i]=c0+linkoffset[i]
				c1=c0+linkoffset[i]
			elseif(Oldval[i]!=c1)	
				Oldval[i]=c1
				c0=c1-linkoffset[i]
			endif
		endif
	endfor
end

// handle our personal expand marquee menus with optional matching of all Z axis ranges
function MarqueeExpand(df , wn,menuitem)
	string df,wn,menuitem
	getmarquee left, bottom
	variable avgx=PixelFromAxisVal(wn,"bottom",(V_left +V_right)/2)
	variable avgy=PixelFromAxisVal(wn,"left",(V_top+V_bottom)/2)

	string ImgName=whichimage(wn,avgx,avgy)
	string tracename=whichtrace(wn,avgx,avgy)
	struct imageWaveNameStruct s 
	if(strlen(imgname)!=0)
		getimageinfo(df,imgname,s)
	elseif (strlen(tracename)!=0)
		gettraceinfo(df,tracename,s)
	else
		return 1
	endif
	getmarquee /K /W=$wn  $(s.vaxis), $(s.haxis)

	strswitch(menuitem)
		case "Expand":
			SetAxis /W=$wn $(s.haxis) V_left ,V_right
			SetAxis /W=$wn $(s.vaxis) V_bottom ,V_top
			break
		case "Horiz Expand":
			SetAxis /W=$wn $(s.haxis) V_left ,V_right
			break
		case "Vert Expand":
			SetAxis /W=$wn $(s.vaxis) V_bottom ,V_top
			break
		case "AutoScale":
			SetAxis /W=$wn /A $(s.haxis) 
			SetAxis /W=$wn /A $(s.vaxis) 
		endswitch
	// make all Z axis have the same range if desired
	NVAR MatchZAxes=$(df+"MatchZAxes")
	if(MatchZAxes==1)
		string Zaxislist = "imgHL;imgVB;profZB;imgZTt"
		string axis
		variable i,n=itemsinlist(Zaxislist)
		if(FindListItem(s.haxis,Zaxislist)>=0 && (cmpstr(menuitem,"Horiz Expand")==0 || cmpstr(menuitem,"Expand")==0))
			for(i=0;i<n;i+=1)
				axis = StringFromList(i, Zaxislist  )
				SetAxis /Z /W=$wn $(axis) V_left ,V_right
			endfor
		elseif(FindListItem(s.vaxis,Zaxislist)>=0 && (cmpstr(menuitem,"Vert Expand")==0 || cmpstr(menuitem,"Expand")==0))
			for(i=0;i<n;i+=1)
				axis = StringFromList(i, Zaxislist  )
				SetAxis /Z /W=$wn $(axis) V_Bottom ,V_Top
			endfor
		elseif ((FindListItem(s.vaxis,Zaxislist)>=0 ||FindListItem(s.haxis,Zaxislist)>=0)&& cmpstr(menuitem,"AutoScale")==0)
			for(i=0;i<n;i+=1)
				axis = StringFromList(i, Zaxislist  )
			SetAxis /A /Z /W=$wn $(axis) 
			endfor
		endif
	endif 
	return 1
end	


// used when rebuilding imagetools to preserver previuos value if it exists or creat new variable whith correct default value
static function makevariable(df,name,defaultvalue)
	string df,name
	variable defaultvalue
	if (exists(df+name))
		return 0
	elseif (exists(name)==3)
		NVAR test = $(df+name)
		if(Nvar_exists(test))
			return 0
		endif
	endif
	variable /g $(df+name) = defaultvalue
end

static function makestring(df,name,defaultvalue)
	string df,name, defaultvalue
	if (exists(df+name))
		return 0
	endif
	string /g $(df+name) = defaultvalue
end

static function makewave1D(df,name,dim,defaultvalue)
	string df,name
	variable dim,defaultvalue
	if (exists(df+name))
		wave wv=$(df+name)
		if(wavedims(wv)==1)
			if(dimsize(wv,0)==dim)
				return 0
			endif
			if(dim==0)
				return 0
			endif
		endif
	endif
	make /o  /N=(dim) $(df+name) = defaultvalue
end

static function makewave1DText(df,name,dim,defaultvalue)
	string df,name
	variable dim
	string defaultvalue
	if (exists(df+name))
		wave wv=$(df+name)
		if(wavedims(wv)==1)
			if(dimsize(wv,0)==dim)
				return 0
			endif
			if(dim==0)
				return 0
			endif
		endif
	endif
	make /o /T /N=(dim) $(df+name) = defaultvalue
end

static function removeallcontrols(winNameStr)
	string winNameStr
	string controllist=ControlNameList(winNameStr)
	variable num=ItemsInList(controllist)
	variable ii=0
	string control
	for(ii=0;ii<num;ii+=1)
		control = StringFromList(ii, controllist )
		killcontrol /W=$winNameStr $control
	endfor
end

//remove trailing colon from datafolder path if it exists
//used to work around igor not allowing the trailing colon in some functions that call for a datafolder name
static function /T FixUpDF(df)
	string df
	if(cmpstr(df[strlen(df)-1],":")==0)
		return df[0,strlen(df)-2]
	else
		return df
	endif
end


function getaxisdnum(df,axisname)
	string df,axisname
	Wave dnum=$(df+"dnum")
	variable dim = getaxisDim(df,axisname)
	if(dim>=0)
		return dnum[dim]
	else
		return -1
	endif
end

function getaxisDim(df,axisname)
	string df,axisname
	strswitch(axisname)
	 case "bottom":
	 	return 0
	 	break
	 case "left":
	 	return 1
	 	break
	 case "imgHL":
	 case "imgVB":
	 case "profZB":
	 case "imgZTt":
	 	 return 2
		break
	 case "imgZTr":
	 case "profTB":
	 	return 3
	 	break
	 default:
	 	return -1
	 endswitch 
end

function /S getdnumaxislist(df,d)
	string df
	variable d
	wave adnum = $(df+"adnum")
	return getaxislistforDim(df,adnum[d])
end

function /S getaxislistforDim(df,d)
	string df
	variable d
	switch(d)
		case 0:
			return "bottom"
			break
		case 1:
			return "left"
			break
		case 2:
			return "imgHL;imgVB;profZB;imgZTt"
			break
		case 3:
			return "imgZTr;profTB"
			break
		default:
			return ""
	endswitch
end

function /S getAxesState(df)
	string df
	string AL = AxisList(IT5winname(df))
	variable ii, N = itemsinlist(AL)
	string axis,SETAXISCMD,info,axesState=""
	for (ii=0;ii<N;ii+=1)
		axis = stringfromList(ii,AL)
		info = AxisInfo(IT5winname(df), axis )
		SETAXISCMD = stringbykey("SETAXISCMD",info)
		axesState = addlistItem(axis+":"+SETAXISCMD,axesState)
	endfor
	return axesState
end


function /WAVE getDnumAxesScales(df)
	string df
	
	string AL = AxisList(IT5winname(df))
	make /T/Free/N=4 dnummaxiscmds = "SetAxis/A AXISNAME"
	variable ii, N = itemsinlist(AL),dnum
	string axis,SETAXISCMD,info,axesState=""
	for (ii=0;ii<N;ii+=1)
		axis = stringfromList(ii,AL)
		info = AxisInfo(IT5winname(df), axis )
		SETAXISCMD = replacestring(axis,stringbykey("SETAXISCMD",info),"AXISNAME")
		Dnum = getaxisdnum(df,axis)
		if(dnum>=0)
			dnummaxiscmds[Dnum]=SETAXISCMD
		endif
		//axesState = addlistItem(axis+":"+SETAXISCMD,axesState)
	endfor
	return dnummaxiscmds
end
	
function ApplyDnumAxesState	(df,DnumAxesState)
	string df
	wave /T DnumAxesState
	string AL = AxisList(IT5winname(df))
	variable ii, N = itemsinlist(AL),dnum
	string axis,SETAXISCMD,info
	for (ii=0;ii<N;ii+=1)
		axis = stringfromList(ii,AL)
		Dnum = getaxisdnum(df,axis)
		if(Dnum>=0)
			SETAXISCMD = replacestring("AXISNAME" ,DnumAxesState[dnum],axis)
			SETAXISCMD = replacestring("SetAxis",SETAXISCMD,"SetAxis/W="+IT5winname(df)+" ")
			execute SETAXISCMD
		endif
	endfor
end

function  ApplyAxisState(df,axesState,to,from)
	string df,axesState,to,from
	string SETAXISCMD = stringbykey(from,axesState)
	SETAXISCMD = replacestring("SetAxis",SETAXISCMD,"SetAxis/W="+IT5winname(df)+" ")
	execute replacestring(from,SETAXISCMD,to) 
end

function Link_matchaxis(df0,df1)
	string df0,df1

	string al0 =axislist(stringfromlist(1,df0,":"))
	string al1=axislist(stringfromlist(1,df1,":"))

	variable n=itemsinlist(al1)
	variable i,d
	string axis1,axislist0
	for(i=0;i<n;i+=1)
		axis1 =stringfromlist(i,al1,";")
		d = 	getaxisdnum(df1,axis1)
		if(d>=0)
			axislist0 = getdnumaxislist(df0,d)
		endif
	endfor
end

function Link_copyaxis(df,axis,Vmin,Vmax)
	string df,axis
	variable Vmin,Vmax
end	

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
			NVAR whichCT=$(df+s.whCT)
			NVAR InvertCT = $(df+s.whInvertCT)
			variable CT=whichCT+1			
			variable invert=InvertCT+1			
			prompt CT,"choose a color table",popup colornameslist()
			prompt invert,"Invert", popup "No;Yes;"
			doprompt "Choose color table",CT,invert
			whichCT=CT-1
			InvertCT = invert-1
			popupmenu $ctrlName,mode=im
			break
	endswitch
	popupmenu $ctrlName,mode=im

	adjustCT(df,"img")
	adjustCT(df,"imgH")
	adjustCT(df,"imgV")	
	adjustCT(df,"imgZT")
End


//interpolate N between xy points with contant linear density 
function interp_poly(xwave,ywave,destx,desty)
	wave xwave,ywave,destx,desty
	destx=0
	desty=0
	variable N=dimsize(destx,0)
	make /o /N=(dimsize(xwave,0)-1) lenwave
	lenwave = sqrt((xwave[p]-xwave[p+1])^2+(ywave[p]-ywave[p+1])^2)
	variable len = sum(lenwave),ii=0,jj=0,kk=-1
	do
		variable numpts = round(N*lenwave[ii]/len)
		make /FREE /o /N=(numpts+1) temp
		setscale /i x,0,1 ,"", temp
		temp = xwave[ii]+(xwave[ii+1]-xwave[ii])*x
		destx[jj,jj+numpts] = temp[p-jj]
		setscale /i x,0,1,"", temp
		temp = ywave[ii]+(ywave[ii+1]-ywave[ii])*x
		desty[jj,jj+numpts] = temp[p-jj]
		jj+=numpts
		ii+=1
	while(ii<dimsize(lenwave,0))
	return len
end

function /S getcoordstr(df)
	string df
	nvar xcg=$(df+"xc"), ycg=$(df+"yc"), zcg=$(df+"zc"), tcg=$(df+"tc")
	svar xlable = $(df+"xlable"),ylable = $(df+"ylable"),zlable = $(df+"zlable"),tlable = $(df+"tlable")
	return xlable+"="+num2str(xcg)+"," +ylable+ "="+num2str(ycg)+","+zlable+"="+num2str(zcg)+","+tlable+"="+num2str(xcg)
end

function /s getbinstr(df)
	string df
	wave bin = $(df+"bin")
	return "b0="+num2str(bin[0])+",b1="+num2str(bin[1])+",b2="+num2str(bin[2])+",b3="+num2str(bin[3])
end

function /WAVE getcursorWave(df)
		string df
		wave dnum=$(df+"dnum")
		nvar xcg=$(df+"xc"), ycg=$(df+"yc"), zcg=$(df+"zc"), tcg=$(df+"tc")
		make /FREE/N=4 cursorwave 
		cursorwave[dnum[0]]=xcg
		cursorwave[dnum[1]]=ycg
		cursorwave[dnum[2]]=zcg
		cursorwave[dnum[3]]=tcg
		return cursorwave
end

function /WAVE getcursorPointWave(df)
		string df
		wave dnum=$(df+"dnum")
		nvar xpg=$(df+"xp"), ypg=$(df+"yp"), zpg=$(df+"zp"), tpg=$(df+"tp")
		make /FREE/N=4 cursorPointwave 
		cursorPointwave[dnum[0]]=xpg
		cursorPointwave[dnum[1]]=ypg
		cursorPointwave[dnum[2]]=zpg
		cursorPointwave[dnum[3]]=tpg
		return cursorPointwave
end


Function SetBinsPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	switch( pa.eventCode )
		case 2: // mouse up
			string df=getdf()
			wave bin=$df+"bin"
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			bin[0,3]=str2num(popStr)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End


//Overlays

function AddOverlayPrompt()
	string df = imagetool5#getdf()
	DFREF saveDFR = GetDataFolderDFR()
	SVAR dname=$(df+"dname")
	wave dwave = $dname
	
	string wn
	//prompt wn, "New Overlay", popup, "; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")+"; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")
	prompt wn, "New Overlay", popup, WaveList("!*_CT",";","DIMS:"+num2str(wavedims(dwave)-1))

	DoPrompt "Select an Overlay wave" wn
	if (V_flag==1)
		abort		//cancelled
	endif
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
	if(waveexists(wv))
		make /free/T/n=4 dimnames
		dimnames = Waveunits(dwave,p)
		// try to guess mapping based on dimension units
		variable Dep_Axis,X_Axis,Y_Axis,Z_Axis
		Findvalue /TEXT=waveunits(wv,0) dimnames
		X_Axis=max(0,V_Value)
		Findvalue /TEXT=waveunits(wv,1) dimnames
		Y_Axis=max(0,V_Value)
		Findvalue /TEXT=waveunits(wv,2) dimnames
		Z_Axis=max(0,V_Value)
		variable dep_default =max(min(otheraxis(X_Axis,Y_Axis,Z_Axis),3),0)
	
		Findvalue /TEXT=waveunits(wv,-1) dimnames
		Dep_Axis=max(dep_default,V_Value)
		Dep_Axis+=1;X_Axis+=1;Y_Axis+=1;Z_Axis+=1
		variable error=0
		string errorPrompt="Each Axis can only be selected once"
		string dimlist = "X ("+Waveunits(dwave,0)+");Y ("+Waveunits(dwave,1)+");Z ("+Waveunits(dwave,2)+");T ("+Waveunits(dwave,3)+")"
		do
			prompt errorPrompt, "Error"
			prompt Dep_Axis, "Dependent Axis ("+waveunits(wv,-1)+")", popup, dimlist
			prompt X_Axis, "X Axis ("+waveunits(wv,0)+")", popup, dimlist
			prompt Y_Axis, "Y Axis ("+waveunits(wv,1)+")", popup, dimlist
			prompt Z_Axis, "Z Axis ("+waveunits(wv,2)+")", popup, dimlist
			if(error)
				DoPrompt "Select Axis Mapping (data->Overlay)" errorPrompt,Dep_Axis,X_Axis,Y_Axis,Z_Axis
			else
				DoPrompt "Select Axis Mapping (data->Overlay)" Dep_Axis,X_Axis,Y_Axis,Z_Axis
			endif
			if (V_flag==1)
				abort		//cancelled
			endif
			make /Free/O/N=4 axes={Dep_Axis,X_Axis,Y_Axis,Z_Axis}
			sort axes,axes
			axes=(axes[p]==p+1)
			error = (sum(axes)!=4)
		while(error)
		print "IT5_AddOverlay(\""+df+"\",\""+w+"\","+num2str(Dep_Axis)+","+num2str(X_Axis)+","+num2str(Y_Axis)+","+num2str(Z_Axis)+")"
		IT5_AddOverlay(df,w,Dep_Axis,X_Axis,Y_Axis,Z_Axis)
		
	else
		abort
	endif
	SetDataFolder saveDFR
end

function IT5_AddOverlay(df,w,Dep_Axis,X_Axis,Y_Axis,Z_Axis)	
	string df,w
	variable Dep_Axis,X_Axis,Y_Axis,Z_Axis
	make /Free/O/N=4 axes={Dep_Axis,X_Axis,Y_Axis,Z_Axis}
	sort axes,axes
	axes=(axes[p]==p+1)
	if((sum(axes)!=4))
		print "AddOverlay Error: Each Axis can only be selected once"
		abort
	endif
	
	DFREF saveDFR = GetDataFolderDFR()
	wave wv=$w
 
	setdatafolder $df
	make /Free/O/N=4 axes={Dep_Axis,X_Axis,Y_Axis,Z_Axis}
		
	axes -=1
	//print Dep_Axis,X_Axis,Y_Axis,Z_Axis
	wave /T Overlays_List = $(df+"Overlays_List")
	wave /T Overlays_Folder = $(df+"Overlays_Folder")
	wave Overlays_Mapping = $(df+"Overlays_Mapping")		
	wave /T Overlays_ListBox = $(df+"Overlays_ListBox")
	wave Overlays_ListBoxSelection = $(df+"Overlays_ListBoxSelection")		
	wave Overlays_Color = $(df+"Overlays_Color")		
	wave OverLays_Enabled = $(df+"OverLays_Enabled")		

	variable numOverlays = dimsize(Overlays_List,0)
	redimension 	/N=(numOverlays+1) Overlays_List,Overlays_Folder,OverLays_Enabled
	redimension 	/N=(-1,numOverlays+1) Overlays_Mapping
	redimension 	/N=(numOverlays+2,-1) Overlays_Color // stupid igor uses 0 as special value, so need 1 based indexing
	redimension 	/N=(numOverlays+1,-1,-1,-1) Overlays_ListBox,Overlays_ListBoxSelection
	if(numOverlays==0)
		Overlays_ListBoxSelection[numOverlays][1][0]=1 //need to set selection on first creation
	endif
	OverLays_Enabled[numOverlays]=1
	Overlays_ListBoxSelection[numOverlays][0][0]=48
	Overlays_ListBoxSelection[][0][1]=p+1 // color background of check box
		
	Overlays_ListBox[numOverlays][1]=w
	Overlays_List[numOverlays]=w
	string dfn=uniquename("Overlay",11,0)
	newdatafolder/o/s $dfn
	Overlays_Folder[numOverlays]=dfn
	Overlays_Mapping[][numOverlays] = axes[p]
		
	controlinfo /W=$(imagetool5#IT5WinName(df)) Overlay_Color
	make /N=3 Overlay_Color={V_Red, V_Green, V_Blue}
	Overlays_Color[numOverlays+1][] = Overlay_Color[q]
	controlinfo /W=$(imagetool5#IT5WinName(df)) Overlay_LineStyle
	variable /G Overlay_LineStyle=V_Value-1
	controlinfo /W=$(imagetool5#IT5WinName(df)) Overlay_LineWidth
	variable /G Overlay_LineWidth=V_Value
	UpdateOverlays(df)

	SetDataFolder saveDFR
end

function deleteoverlay()
	string df = imagetool5#getdf()
	DFREF saveDFR = GetDataFolderDFR()
	controlinfo /W=$(imagetool5#IT5WinName(df)) Overlay_List
	if(v_Flag==11)
		RemoveOverlays(df)
		variable selection = V_Value
		wave /T Overlays_List = $(df+"Overlays_List")
		wave /T Overlays_Folder = $(df+"Overlays_Folder")
		wave Overlays_Mapping = $(df+"Overlays_Mapping")		
		wave /T Overlays_ListBox = $(df+"Overlays_ListBox")
		wave Overlays_ListBoxSelection = $(df+"Overlays_ListBoxSelection")	
		wave OverLays_Enabled = $(df+"OverLays_Enabled")		

		String O_df = (df+Overlays_Folder[selection])
		deleteBeam(Overlays_List,selection,0)
		deleteBeam(Overlays_Folder,selection,0)
		deleteBeam(Overlays_Mapping,selection,1)
		deleteBeam(Overlays_ListBoxSelection,selection,0)
		deleteBeam(Overlays_ListBox,selection,0)
		deleteBeam(OverLays_Enabled,selection,0)

		UpdateOverlays(df) // this removes the deleted overlay from the graph
		killallinfolder(O_df)
		killdatafolder $(O_df)
	endif
	SetDataFolder saveDFR
end

function UpdateOverlays(df)
	string df
	RemoveOverlays(df)
	wave /T Overlays_List = $(df+"Overlays_List")
	wave /T Overlays_Folder = $(df+"Overlays_Folder")
	wave Overlays_Mapping = $(df+"Overlays_Mapping")
	wave OverLays_Enabled = $(df+"OverLays_Enabled")		

	NVAR ZTPMode = $(df+"ZTPMode")
	variable ii=0
	for(ii=0;ii<dimsize(Overlays_List,0);ii+=1)
			wave source = $(Overlays_List[ii])
			make /FREE /N=4 axisMapping=Overlays_Mapping[p][ii]
			string O_df = df+Overlays_Folder[ii]+":"
			makeImageOverlay3D(df,O_df,Source,"img",axisMapping,ii,OverLays_Enabled[ii])
			makeImageOverlay3D(df,O_df,Source,"imgh",axisMapping,ii,OverLays_Enabled[ii])
			makeImageOverlay3D(df,O_df,Source,"imgv",axisMapping,ii,OverLays_Enabled[ii])
			makeImageOverlay3D(df,O_df,Source,"imgzt",axisMapping,ii,OverLays_Enabled[ii])
			
			makeProfileOverlay3D(df,O_df,source,"Hprof",axisMapping,ii,OverLays_Enabled[ii])
			makeProfileOverlay3D(df,O_df,source,"Vprof",axisMapping,ii,OverLays_Enabled[ii])
			makeProfileOverlay3D(df,O_df,source,"Tprof",axisMapping,ii,OverLays_Enabled[ii]*(ZTPMode==0))
			makeProfileOverlay3D(df,O_df,source,"Zprof",axisMapping,ii,OverLays_Enabled[ii]*(ZTPMode==0))
	endfor
end

function RemoveOverlays(df)
	string df
	String traceList = tracenamelist(IT5WinName(df),";",1)
	traceList = ReduceList(traceList,"*Overlay*")
	traceList = replaceString(";",traceList,",")
	Variable numTraces = ItemsInList(traceList)
	execute "removefromgraph/z /W="+IT5WinName(df)+" "+traceList[0,strlen(traceList)-2]		//remove all traces
end

// data -> wave shown in image tool
// source -> 3d wave which defines a function f(x,y,z) which takes 3 axis of data to the remaning axis
// dep_Axis -> data axis that corresponds to the value of source (dependent axis)
// X_axis etc -> data axis that corresponds to 1st axis of source
function makeImageOverlay3D(df,O_df,source,img,AxisMaping,index,enabled)
	string df,O_df
	wave source
	string img
	wave AxisMaping
	variable index,enabled
	variable dep_Axis=AxisMaping[0]
	variable X_axis = AxisMaping[1]
	variable y_axis = AxisMaping[2]
	variable z_axis = AxisMaping[3]
	
	DFREF saveDFR = GetDataFolderDFR()
	wave dnum=$(df+"dnum")
	wave adnum=$(df+"adnum")
	
	string win = IT5WinName(df)
	string SourceName = nameofwave(source)
	newdatafolder /o/s $fixupdf(O_df)	
	string /g dname = GetWavesDataFolder(source,2)
	make /N=4/o S_Dnum, aS_Dnum
	S_Dnum[X_axis]=0
	S_Dnum[Y_axis]=1
	S_Dnum[Z_axis]=2
	S_Dnum[dep_Axis]=20

	aS_Dnum = p
	sort S_dnum,aS_dnum
	
	make /FREE/T/N=4 CursorAxisVariables = {"xc","yc","zc","tc"}
	make /FREE/T/N=4 AxisVariables
	variable /g $(img+"_trig")
	NVAR  trig= $(img+"_trig") 
	setformula trig,""
	Wave W_img = $img
	if(waveexists($img))
		setformula W_img,""
	endif
	Wave W_img_y = $(img+"_y")
	if(waveexists(W_img_y))
		setformula W_img_y,""
	endif
	Wave W_img_x = $(img+"_x")
	if(waveexists(W_img_x))
		setformula W_img_x,""
	endif
	struct imageWaveNameStruct s
	getimageinfo(df,img,s)
	NVAR OverLays_Show=$(df+"OverLays_Show")
	NVAR hasimg=$(df+s.has)
	if(!hasimg || !OverLays_Show || !enabled)
		SetDataFolder saveDFR
		return 0
	endif
	if(s.hindex!=dep_Axis && s.vindex!=dep_Axis)
		variable free_axis = otheraxis(s.hindex,s.vindex,dep_Axis)
		variable X_src_axis = s_Dnum[s.hindex] // 
		variable Y_src_axis = s_Dnum[s.vindex]
		variable Z_src_axis = s_Dnum[free_axis]
		make /o/N=(dimsize(source,X_src_axis),dimsize(source,Y_src_axis)) $img
		Wave W_img = $img
		setscale /P x,dimoffset(source,X_src_axis),dimdelta(source,X_src_axis),waveunits(source,X_src_axis),W_img
		setscale /P y,dimoffset(source,Y_src_axis),dimdelta(source,Y_src_axis),waveunits(source,Y_src_axis),W_img

		AxisVariables[X_src_axis] = "x"
		AxisVariables[Y_src_axis] = "y"
		AxisVariables[Z_src_axis] = CursorAxisVariables[adnum[free_axis]]

		string formula = GetWavesDataFolder(source,2)+"("+appendDF(df,AxisVariables[0])+")("+appendDF(df,AxisVariables[1])+")("+appendDF(df,AxisVariables[2])+")"
		setformula W_img, formula
		
		make /o/N=10 $(img+"_x"),$(img+"_y")
		Wave W_img_x = $(img+"_x")
		Wave W_img_y = $(img+"_y")
		AxisVariables = {"xc","yc","zc","tc"}
		formula =" contourupdate("+appendDF(df,AxisVariables[adnum[dep_axis]])+ ","+O_df+img+")" //,"+O_df+img+"_x"+","+O_df+img+"_y)"
		setformula trig,formula
	else
		if (s.vindex==dep_Axis)
			X_src_axis = s_Dnum[s.hindex]
		else
			X_src_axis = s_Dnum[s.vindex]
		endif
		make /o/N=(dimsize(source,X_src_axis)) $(img+"_x"),$(img+"_y")
		Wave W_img_x = $(img+"_x")
		Wave W_img_y = $(img+"_y")
		setscale /P x,dimoffset(source,X_src_axis),dimdelta(source,X_src_axis),waveunits(source,X_src_axis),W_img_x
		setscale /P x,dimoffset(source,X_src_axis),dimdelta(source,X_src_axis),waveunits(source,X_src_axis),W_img_y
		W_img_x = x
		W_img_Y = x

		AxisVariables = CursorAxisVariables[Adnum[aS_dnum[p]]]
		AxisVariables[X_src_axis] = "x"
		formula = GetWavesDataFolder(source,2)+"("+appendDF(df,AxisVariables[0])+")("+appendDF(df,AxisVariables[1])+")("+appendDF(df,AxisVariables[2])+")"
		if (s.vindex==dep_Axis)
			setformula W_img_y, formula
			setformula W_img_x,""
		else
			setformula W_img_x, formula
			setformula W_img_y,""
		endif
	endif
	string overlay_name = (SourceName+" "+img+" Overlay"+num2str(index))
	AppendToGraph/L=$(s.vaxis)/B=$(s.haxis) W_img_y/TN=$overlay_name vs W_img_x
	wave Overlay_Color = $(O_df+"Overlay_Color")
	ModifyGraph rgb($overlay_name)=(Overlay_Color[0],Overlay_Color[1],Overlay_Color[2])
	NVAR Overlay_LineStyle = $(O_df+"Overlay_LineStyle")
	ModifyGraph lstyle($overlay_name)=Overlay_LineStyle
	NVAR Overlay_LineWidth = $(O_df+"Overlay_LineWidth")
	ModifyGraph lsize($overlay_name)=Overlay_LineWidth
	SetDataFolder saveDFR
end

function makeProfileOverlay3D(df,O_df,source,profile,AxisMaping,index,enabled)
	string df,O_df
	wave source
	string profile
	wave AxisMaping
	variable index,enabled
	variable dep_Axis=AxisMaping[0]
	variable X_axis =AxisMaping[1]
	variable y_axis = AxisMaping[2]
	variable z_axis = AxisMaping[3]
	
	DFREF saveDFR = GetDataFolderDFR()
	wave dnum=$(df+"dnum")
	wave adnum=$(df+"adnum") 
	
	string win = IT5WinName(df)
	string SourceName = nameofwave(source)
	newdatafolder /o/s $fixupdf(O_df)	
	string /g dname = GetWavesDataFolder(source,2)
	make /N=4/o S_Dnum, aS_Dnum
	S_Dnum[X_axis]=0
	S_Dnum[Y_axis]=1
	S_Dnum[Z_axis]=2
	S_Dnum[dep_Axis]=20

	aS_Dnum = p
	sort S_dnum,aS_dnum
	
	make /FREE/T/N=4 CursorAxisVariables = {"xc","yc","zc","tc"}
	make /FREE/T/N=4 AxisVariables
	variable /g $(profile+"_trig")
	NVAR  trig= $(profile+"_trig") 
	setformula trig,""
	Wave W_profile = $profile
	if(waveexists($profile))
		setformula W_profile,""
	endif 
	struct imageWaveNameStruct s
	getTraceinfo(df,profile,s)
	NVAR OverLays_Show=$(df+"OverLays_Show")
	NVAR hasimg=$(df+s.has)
	if(!hasimg||!OverLays_Show|!enabled)
		SetDataFolder saveDFR
		return 0 
	endif
	if(s.hindex!=dep_Axis && s.vindex!=dep_Axis)
		if (s.vindex==-1)
			variable X_src_axis = s_Dnum[s.hindex]
		else
			X_src_axis = s_Dnum[s.vindex]
		endif
		make /o/N=(dimsize(source,X_src_axis)) $(profile),$(profile+"_x"),$(profile+"_y")
		wave W_Profile = $(profile)
		Wave W_img_x = $(profile+"_x")
		Wave W_img_y = $(profile+"_y")
		setscale /P x,dimoffset(source,X_src_axis),dimdelta(source,X_src_axis),waveunits(source,X_src_axis),W_Profile
		AxisVariables = CursorAxisVariables[Adnum[aS_dnum[p]]]
		AxisVariables[X_src_axis] = "x"	
		string cmd = GetWavesDataFolder(source,2)+"("+appendDF(df,AxisVariables[0])+")("+appendDF(df,AxisVariables[1])+")("+appendDF(df,AxisVariables[2])+")"
		setformula W_Profile, cmd
		cmd = "OverlayProfileUpdate("+appendDF(df,CursorAxisVariables[adnum[dep_axis]])+","+O_df+profile+","+df+s.image+")"
		setformula trig, cmd
	else	
		AxisVariables = CursorAxisVariables[Adnum[aS_dnum[p]]]
		make /o/N=1 $(profile+"_x"),$(profile+"_y")
		Wave W_img_x = $(profile+"_x")
		Wave W_img_y = $(profile+"_y")
		cmd = GetWavesDataFolder(source,2)+"("+appendDF(df,AxisVariables[0])+")("+appendDF(df,AxisVariables[1])+")("+appendDF(df,AxisVariables[2])+")"
		setformula W_img_x, cmd
		cmd = df+s.image+"("+ GetWavesDataFolder(W_img_x,2)+"[p])"
		setformula W_img_Y, cmd
	endif
	string overlay_name = (SourceName+" "+Profile+" Overlay"+num2str(index))

	if (s.vindex==-1)
		AppendToGraph/L=$(s.vaxis)/B=$(s.haxis) W_img_y/TN=$(overlay_name) vs W_img_x
	else
		AppendToGraph/L=$(s.vaxis)/B=$(s.haxis) W_img_x/TN=$(overlay_name) vs W_img_y
	endif
	ModifyGraph mode($overlay_name)=3
	ModifyGraph marker($(overlay_name))=19
	wave Overlay_Color = $(O_df+"Overlay_Color")
	ModifyGraph rgb($(overlay_name))=(Overlay_Color[0],Overlay_Color[1],Overlay_Color[2])
	SetDataFolder saveDFR

end
		
static function otheraxis(a,b,c)
	variable a,b,c
	make /Free /N=4 set
	set=p
	set[a]=0
	set[b]=0
	set[c]=0
	return sum(set)
end 

function contourupdate(E,img) 
	variable E
	wave img//,destXWave,dstYWave
	string O_df = GetWavesDataFolder(img,1)
	string img_name = nameofwave(img)
	wave dstXWave = $(O_df+img_name+"_x")
	wave dstYWave = $(O_df+img_name+"_y")
	FindContour /DSTX=dstXWave /DSTY=dstYWave img,E
	return 1
end 

function OverlayProfileUpdate(E,kx_trace,profile)
	variable E
	wave kx_trace,profile
	string O_df = GetWavesDataFolder(kx_trace,1)
	string img_name = nameofwave(kx_trace)
	wave dstXWave = $(O_df+img_name+"_x")
	wave dstYWave = $(O_df+img_name+"_y")
	FindLevels /q /DEST=dstXWave kx_trace,E
	duplicate /o dstXWave,dstYWave
	dstYWave=profile(dstXWave[p])
end
  
function  deleteBeam(wv,beam,axis)
	wave  wv
	variable beam,axis
	make /T/FREE/N=4 index={"p","q","r","s"} 
	make /T/FREE/N=4 range={"[]","[]","[]","[]"}
	make /T/FREE/N=4 dims
	dims="-1" 
	index[axis]=index[axis]+"+1"
	range[axis]="["+num2str(beam)+","+num2str(dimsize(wv,axis)-2)+"]"
	index = "["+index[p]+"]"
	dims[axis] = num2str(dimsize(wv,axis)-1)
	string cmd = getwavesdatafolder(wv,2)+range[0]+range[1]+range[2]+range[3]+"="+getwavesdatafolder(wv,2)+index[0]+index[1]+index[2]+index[3]
	execute cmd
	cmd = "redimension/ N=("+dims[0]+","+dims[1]+","+dims[2]+","+dims[3]+") "+getwavesdatafolder(wv,2)
	execute cmd
end

Function AddOverlayButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			addoverlayPrompt()
			break
	endswitch
	return 0
End

Function DeleteOverlayButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			deleteoverlay()
			break
	endswitch
	return 0
End

Function OverLays_ShowCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			string df = imagetool5#getdf()
			UpdateOverlays(df)
			break
	endswitch
	return 0
End

Function OverlayListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case 4: // cell selection
		case 5: // cell selection plus shift key
			string df = imagetool5#getdf()
			NVAR Overlays_Row = $(df+"Overlays_Row")
			Overlays_Row = lba.row
			 
			wave /T Overlays_Folder = $(df+"Overlays_Folder")
			string O_df = df+Overlays_Folder[lba.row]+":"
			wave Overlay_Color = $(O_df+"Overlay_Color")
			PopupMenu Overlay_Color popColor=(Overlay_Color[0],Overlay_Color[1],Overlay_Color[2])
			NVAR Overlay_LineStyle = $(O_df+"Overlay_LineStyle")
			PopupMenu Overlay_Linesyle mode = Overlay_LineStyle +1
			NVAR Overlay_LineWidth = $(O_df+"Overlay_LineWidth")
			SetVariable Overlay_LineWidth value=Overlay_LineWidth
			
			wave  Overlays_ListBoxSelection = $(df+"Overlays_ListBoxSelection")
			Overlays_ListBoxSelection[][1][0] = 0 // Overlays_ListBoxSelection[Overlays_Row][1][0] 
			Overlays_ListBoxSelection[Overlays_Row][1][0] = 1 // Overlays_ListBoxSelection[Overlays_Row][1][0] 
			Overlays_ListBoxSelection[Overlays_Row][0][0] = Overlays_ListBoxSelection[Overlays_Row][0][0] & (254) // Overlays_ListBoxSelection[Overlays_Row][1][0] 
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			df = imagetool5#getdf()
			NVAR Overlays_Row = $(df+"Overlays_Row")
			wave Overlays_ListBoxSelection = $(df+"Overlays_ListBoxSelection")
			wave OverLays_Enabled = $(df+"OverLays_Enabled")
			Overlays_Row = lba.row
			if (Overlays_ListBoxSelection[Overlays_Row][0][0]==48)
					OverLays_Enabled[Overlays_Row]=1
			else
					OverLays_Enabled[Overlays_Row]=0
			endif
			updateoverlays(df)
			break
	endswitch

	return 0
End


Function OverLayColorPopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string df = imagetool5#getdf()
			controlinfo /W=$(imagetool5#IT5WinName(df)) Overlay_List
			NVAR Overlays_Row = $(df+"Overlays_Row")
			wave /T Overlays_Folder = $(df+"Overlays_Folder")
			wave Overlays_Color = $(df+"Overlays_Color")		
			string O_df = df+Overlays_Folder[Overlays_Row]+":"
			//wave Overlay_Color = $(O_df+"Overlay_Color")
			controlinfo /W=$(imagetool5#IT5WinName(df)) Overlay_Color

			make /o/N=3 $(O_df+"Overlay_Color")={V_Red, V_Green, V_Blue}
			wave Overlay_Color=$(O_df+"Overlay_Color")
			Overlays_Color[Overlays_Row+1][]=Overlay_Color[q]

			updateoverlays(df)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function OverlayLinestylePopMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string df = imagetool5#getdf()
			NVAR Overlays_Row = $(df+"Overlays_Row")
			wave /T Overlays_Folder = $(df+"Overlays_Folder")
			string O_df = df+Overlays_Folder[Overlays_Row]+":"
			variable /G $(O_df+"Overlay_LineStyle")= pa.popNum //V_Value-1
			updateoverlays(df)
			break
		case -1: // control being killed
			break
	endswitch
	return 0
End

Function Overlay_LineWidthSetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			string df = imagetool5#getdf()
			NVAR Overlays_Row = $(df+"Overlays_Row")
			wave /T Overlays_Folder = $(df+"Overlays_Folder")
			string O_df = df+Overlays_Folder[Overlays_Row]+":"
			variable /G $(O_df+"Overlay_LineWidth")= sva.dval//V_Value
			updateoverlays(df)
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


function /T listImagetoolVs()	
	string windowList = WinList("ImageToolV*",";","")
	wave/T windowwave = ListToTextWave(windowList, ";")
	Duplicate/FREE/T windowwave,wavenames,windowtitles
	variable num = dimsize(windowwave,0)
	variable ii 
	string dfn,name
	for(ii=0;ii<num;ii+=1)
		dfn = getDFfromName(windowwave[ii])
		svar dname = $(dfn+"dname")
		wavenames[ii] = dname
		name = windowwave[ii]
		getwindow  $name title
		//svar S_Value=S_Value
		windowtitles[ii] = S_Value
	endfor
	sortcolumns keywaves=wavenames, sortWaves={wavenames,windowtitles,windowwave}
	String list = ""
	Variable i
	 num=dimsize(wavenames,0)
	for(i=0; i<num; i+=1)
		list += windowtitles[i] + ";"
	endfor
	return list
end


//SendtoScan=========

function /T GetHostName()
	String unixCmd
		String igorCmd
	#if defined(MACINTOSH)
		unixCmd = "hostname"
		sprintf igorCmd, "do shell script \"%s\"", unixCmd
		ExecuteScriptText/UNQ igorCmd
		string host = S_value
		return host
	#else
		return ""
	#endif
end

function  GetScanSystem(name)
	string name
	if(strsearch(UpperStr(name),"UARPES",0)>=0)
		return 1 // "uarpes.als.lbl.gov"
	endif
	if(strsearch(UpperStr(name),"NARPES",0)>=0)
		return 2 // "narpes.als.lbl.gov"
	endif
	if(strsearch(UpperStr(name),"PEEM",0)>=0)
		return 3 // "narpes.als.lbl.gov"
	endif
	if(strsearch(UpperStr(name),"LOCALHOST",0)>=0)
		return 4 // "narpes.als.lbl.gov"
	endif
	
	return 0
end

function /T ScanSystemName()
	if(!exists("root:Packages:ImagetoolV:ScanSystem"))
			IT5_GlobalSetup()
	endif
	NVAR system = root:Packages:ImagetoolV:ScanSystem
	string systems = "Connect to ...;uARPES;nARPES;PEEM;localhost"
	return stringfromlist(system,systems)
end

function /T GetScanSystemIP(system)
	variable system
	string systems = ";uarpes.als.lbl.gov;narpes.als.lbl.gov;PEEM.als.lbl.gov;127.0.0.1"
	return stringfromlist(system,systems)
end
	
function /T ScanSystemMenu()
	return "uARPES;nARPES;PEEM;localhost;disconnect"
end

function setSystemMenu()
	GetLastUserMenuInfo
	NVAR ScanSystem=root:Packages:ImagetoolV:ScanSystem
	ScanSystem = GetScanSystem(S_Value)
end



function /s IT5_getCursorsJSON(df)
	string df
	return IT5_buildmsgJSON(df,"Cursors","")
end

function /s IT5_getcoordJSON(df,s)
	string df
	struct imageWaveNameStruct &s
	svar dname=$(df+"dname")
	wave w=$dname
	wave cursors = getcursorWave(df)
	string Position
	if((s.hindex!=-1)&&(s.vindex!=-1))
		Position = "{"+ quote("axes") + " : ["+ quote(waveunits(w,s.hindex))+"," +quote(waveunits(w,s.vindex))+"]"
		Position += "," + quote("coordinates")+ " : [" + num2str(cursors[s.hindex]) + "," + num2str(cursors[s.vindex]) + "]}"
	else
		Position = "{"+ quote("axes") + " : ["+ quote(waveunits(w,max(s.hindex,s.vindex)))+"]"
		Position += "," + quote("coordinates")+ " : [" + num2str(cursors[max(s.hindex,s.vindex)])  + "]}"
	endif
	return IT5_buildmsgJSON(df,"Position",KeyObjectJSON("Position",position))
end

function /s IT5_getMarqueeJSON()
	string dfn=getdfname()
	string df=getDFfromName(dfn)
	getmarquee left, bottom
	variable avgx=PixelFromAxisVal(dfn,"bottom",(V_left +V_right)/2)
	variable avgy=PixelFromAxisVal(dfn,"left",(V_top+V_bottom)/2)
	string ImgName=whichimage(dfn,avgx,avgy)
	string tracename=whichtrace(dfn,avgx,avgy)
	struct imageWaveNameStruct s
	svar dname=$(df+"dname")
	wave w=$dname
	string marquee
	if(strlen(ImgName)>0)
		getimageinfo(df,imgname,s)
		getmarquee $s.haxis, $s.vaxis
		marquee = "{"+ quote("axes") + " : ["+ quote(waveunits(w,s.hindex))+"," +quote(waveunits(w,s.vindex))+"]"
		marquee += "," + quote("coordinates")+ " : [" + num2str(V_left) + "," + num2str(V_top) + "," + num2str(V_right) + "," + num2str(V_bottom) +"]}"
	elseif(strlen(TraceName)>0)
		gettraceinfo(df,Tracename,s)
		getmarquee $s.haxis, $s.vaxis
		if(s.hindex!=-1)
			marquee = "{" + KeyStringJSON("axes","["+ quote(waveunits(w,s.hindex))+"]")
			marquee +="," + KeyStringJSON("coordinates"," [["+ num2str(V_left)+"],[" + num2str(V_right) +"]]}")
		else 
			marquee = "{" + quote("axes") +" : ["+ quote(waveunits(w,s.vindex))+"]"
			marquee +=","+quote("coordinates") + " : [["+ quote(num2str(V_top))+"],[" + quote(num2str(V_bottom)) +"]]}"
		endif
	endif
	return IT5_buildmsgJSON(df,"Marquee",KeyObjectJSON("Position",Marquee))
end

function /T IT5_buildmsgJSON(df,type,custom)
	string df,type,custom
	svar dname=$(df+"dname")
	wave img=$(dname)	
	string imgtool = stringfromlist(1,df,":")
	string Cursor_Pos = IT5_getcursorJSON(df)
	string wavenote = note(img)
	string file = stringbykey("file",wavenote,"=",";\r")
	string LWLVNM = stringbykey("LWLVNM",wavenote,"=",";\r")
	LWLVNM = trimstring(LWLVNM[0,strsearch(LWLVNM,"/",0)-1])
	string json = "{"+ KeyStringJSON("source",imgtool) +","+ KeyStringJSON("type",type) + "," + KeyStringJSON("file",file) +","+ KeyStringJSON("ScanMode",LWLVNM)
	json += ","+ KeyObjectJSON("Cursors",Cursor_Pos)+","+KeyStringJSON("timestamp" , IT5_getTimeStampJSON()) 
	if(strlen(custom)==0)
		json +="}"
	else
		json += "," + custom +"}"
	endif
	return json
end

function /s IT5_getcursorJSON(df)
	string df
	svar dname=$(df+"dname")
	wave img=$(dname)	
	nvar xcg=$(df+"xc"), ycg=$(df+"yc"), zcg=$(df+"zc"), tcg=$(df+"tc")
	make /FREE/N=4 coordinates
	coordinates[0]=xcg;coordinates[1]=ycg;coordinates[2]=zcg;coordinates[3]=tcg;
	svar xlable = $(df+"xlable"),ylable = $(df+"ylable"),zlable = $(df+"zlable"),tlable = $(df+"tlable")
	make /T/FREE/N=4 axes
	axes[0] = xlable;axes[1]=ylable;axes[2]=zlable;axes[3]=tlable
	string Cursor_Pos = "{"+ KeyObjectJSON("axes",TextWave2JSONArray(axes))+","+KeyObjectJSON("coordinates",Wave2JSONArray(coordinates))+"}"
	return Cursor_Pos
end

function /s IT5_getcoordJSON_Top()
	String WL = WinList("ImageToolV*",";","");
	if (strlen(WL) == 0)
		return ""
	endif
	string IT_Name = stringfromlist(0,WL)
	String df = getDFfromName(IT_Name)
	//return IT5_getcoordJSON(df)
end

function /s IT5_getTimeStampJSON()
	return Secs2Date(DateTime,-2) +"T" + Secs2Time(DateTime,3)+".000Z"
end


function SendToScan(msg)
	string msg
	NVAR ScanSystem=root:Packages:ImagetoolV:ScanSystem
	string address = GetScanSystemIP(ScanSystem)
	SendMsgBkgSockitThread(msg,address,50000)
end


ThreadSafe Function Sockitworker()
	print "IT5 BkgSockitThread started"
	do
		do
			DFREF dfr = ThreadGroupGetDFR(0,1000)	// Get free data folder from input queue
			if (DataFolderRefStatus(dfr) == 0)
				if( GetRTError(2) )	// New in 6.2 to allow this distinction:
					Print "IT5 BkgSockitThread closing down due to group release"
				else
					//Print "worker thread still waiting for input queue"
				endif
			else
				break
			endif
		while(1)

		SVAR msg = dfr:msg
		NVAR port = dfr:port
		SVAR address = dfr:address
		//print msg
		string url = "http://"+address+":"+num2str(port)
		URLRequest /Z /DSTR=msg method=post, url=url
		KillDataFolder dfr		// We are done with the input data folder
	while(1)

	return 0
End



Function SendMsgBkgSockitThread(message,host,host_port)
	string message,host
	variable host_port
	Variable i,ntries= 5,nthreads= 2
	if(!exists("root:packages:imagetoolV:SocketTGID"))
		IT5_StartBkgSockitThread()
	endif
	NVAR threadGroupID = root:packages:imagetoolV:SocketTGID
	if (threadgroupwait(threadGroupID,0)==0)
		IT5_StartBkgSockitThread()
	endif
		
	NewDataFolder/S forThread
	String/G msg=message
	String/G address=host
	variable /g port = host_port
	ThreadGroupPutDF threadGroupID,:	// Send current data folder to input queue
End


function IT5_StartBkgSockitThread()
	Variable/G root:packages:imagetoolV:SocketTGID = ThreadGroupCreate(1)
	NVAR threadGroupID=root:packages:imagetoolV:SocketTGID
	ThreadStart threadGroupID,0,Sockitworker()
end

function IT5_StopBkgSockitThread()
	NVAR threadGroupID = root:packages:imagetoolV:SocketTGID
	Variable tstatus= ThreadGroupRelease(threadGroupID)
	killvariables /Z root:packages:imagetoolV:SocketTGID
	if( tstatus == -2 )
		Print "IT5 BkgSockitThread would not quit normally, had to force kill it. Restart Igor."
	endif
end


