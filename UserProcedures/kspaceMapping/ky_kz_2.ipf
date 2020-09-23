#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName=ky_kzFunctions


//May 8 2008 version 1.13 --JLM 
//working version, need to fix offset cursor axis, include v0calulator
//May 11 2008 -- fixed interp 
//May 16 2008 -- added betadrift correction
//March 17, 2011 version 2 -- JLM cleaned up ky-kzplotter


Menu "kspace"
	Submenu "ky_kz"
		"ky-kz Loader" ,Loadkykz4d
		"ky-kz Plotter", Newkykz()	
		"Convert Theta to kx, single hv", ConvertTheta2k()
		"Convert pixels to theta, single hv", ConvertPix2Theta()
		"v0 calculator",SetUpCalcv0()
		"k-space calculator",SetUpkspaceCalc()
	end
end

function ConvertTheta2k()
	setdatafolder root:
	string w
	prompt w, "Image Array", popup, "---2D---;"+WaveList("!*_CT",";", "DIMS:2")+"---3D---;"+WaveList("!*_CT",";", "DIMS:3")
//	prompt hv, "Photon energy"
//	prompt wk, "sample work function"
	doprompt "Select ky-kz wave", w//, hv, wk
	if (v_flag==1)
		abort
	endif
	wave ww_t=$w
	string wvnote=note(ww_t)
	variable hv=numberbykey("MONOEV", wvnote, "=",";"), wk=0
	duplicate/o ww_t $(w+"_k")
	wave ww_k=$(w+"_k")
	print "ky_kzFunctions#convertingtheta2k("+num2str(hv)+",+"+num2str( wk)+","+w+","+nameofwave( ww_k)+")"
	ky_kzFunctions#convertingtheta2k(hv, wk, ww_t, ww_k)
	display 
	appendimage ww_k
end

static function buttconverttheta2k(ctrlName): ButtonControl
	string ctrlName
	string w=imagenamelist("",";")
	w=stringfromlist(0,w)
	wave ww_t=$w
	string wvnote=note(ww_t)
	variable hv=numberbykey("MONOEV", wvnote, "=",";"), wk=0
	duplicate/o ww_t $(w+"_k")
	wave ww_k=$(w+"_k")
	print "ky_kzFunctions#convertingtheta2k("+num2str(hv)+",+"+num2str( wk)+","+w+","+nameofwave( ww_k)+")"
	ky_kzFunctions#convertingtheta2k(hv, wk, ww_t, $(w+"_k"))	
	newimagetool(nameofwave(ww_k))
	button t2kdonbut, title="accept k scale", pos={15,55}, proc=ky_kzFunctions#t2kdon, size={100,25}, fColor=(0,65535,65535)
end

static function t2kdon(ctrlName): buttoncontrol
	string ctrlName
 	string dfn= winname(0,1)
	svar  name=$("root:"+dfn+":imgnam")
	string tname=name[0,strlen(name)-3]
	killwaves/z $tname
	wave wv=$name
	rename wv, $(name[0,strlen(name)-4]+"b")
end


static function convertingtheta2k(hv, wk, ww_t, ww_k)
	variable hv, wk
	wave ww_t, ww_k
variable ki=0.5124*sqrt(hv-wk)*sin(dimoffset(ww_t,0)*pi/180)
	variable kf=0.5124*sqrt(hv-wk)*sin((dimoffset(ww_t,0)+dimdelta(ww_t,0)*dimsize(ww_t,0))*pi/180)
	setscale/i x, ki,kf, "kx", ww_k
	if(wavedims(ww_t)==2)
		ww_k=interp2d(ww_t, asin(x/0.5124/sqrt(hv-wk-y))*180/pi,y)
	elseif(wavedims(ww_T)==3)
		ww_k=interp3d(ww_t, asin(x/0.5124/sqrt(hv-wk-y))*180/pi,y,z)
	endif
end

function ConvertPix2Theta()
	string w, angmode 
	variable ang, thetaoffset
	prompt w, "Image Array", popup, "---2D---;"+WaveList("!*_CT",";", "DIMS:2")+"---3D---;"+WaveList("!*_CT",";", "DIMS:3")
//	prompt angmode, "lens mode", popup, "30;14;7"
//	prompt thetaoffset, "theta offset"
	doprompt "", w//,angmode, thetaoffset
	wave ww=$(w)
	string wvnote=note(ww)
	string mode=stringbykey("SSLNM0", wvnote, "=",";")
	if(cmpstr(mode[7,8],"30")*cmpstr(mode[7,8],"14")==0)	
		ang=str2num(mode[7,8])
	elseif(cmpstr(mode[7],"3")*cmpstr(mode[7],"7")==0)
		ang=str2num(mode[7])
	endif
	variable deg_pix=ang/7*0.0102

	duplicate/o ww $(w+"_t")
	wave ww_t=$(w+"_t")
	ky_kzFunctions# convertingpix2theta(thetaoffset, deg_pix, ww, ww_t)
	print  "ky_kzFunctions#convertingpix2theta("+num2str(thetaoffset)+", "+num2str(deg_pix)+","+ nameofwave(ww)+", "+nameofwave(ww_t)+")"
	display/W=(35,44,436,400)
	appendimage ww_t
	modifygraph margin(left)=100, margin(top)=72
	button but_t2k title="Convert to k", pos={10,10}, proc=ky_kzFunctions#buttconverttheta2k, size={100,20}, fColor=(0,65535,65535)
	slider sliderplane side=2,  proc=ky_kzFunctions#PlaneSliderProc, limits={dimoffset(ww,2), dimsize(ww,2)*dimdelta(ww,2),dimdelta(ww,2)}, size={45,150}, pos={20,60}
	DrawText -.3,-.06,waveunits(ww,2)
end

static function convertingpix2theta(thetaoffset, deg_pix, ww, ww_t)
	variable thetaoffset, deg_pix
	wave ww, ww_t
	variable thetadimoffset=abs(dimdelta(ww,0)*(dimsize(ww,0)-1)*deg_pix/2)
	setscale/p x, thetaoffset-thetadimoffset, dimdelta(ww,0)*deg_pix, "theta", ww_t
end

static Function PlaneSliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa
//	nvar=whichplane=$root:whichplane
	switch( sa.eventCode )
		case -1: // kill
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval
//				whichplane=curval
				string w=imagenamelist("",";")
				w=stringfromlist(0,w)
				wave wv=$w
				modifyimage $w, plane=curval
			endif
			break
	endswitch

	return 0
End


Function Loadkykz4d()
	setdatafolder root:
	string w
	prompt w, "Image Array", popup, "---3D---;"+WaveList("!*_CT",";", "DIMS:3")
	doprompt "Select ky-kz wave", w
	if (v_flag==1)
		abort
	endif
	wave ww=$w
	
	variable nky=41, nkz=5, iky=-.1, ikz, fky=.1,fkz
	string new
	prompt new, "add suffix to wave name (_4d)?" , popup, "yes;no"
	prompt iky, "initial ky"
	prompt fky, "final ky"
	prompt nky, "number of ky steps"
	prompt ikz, "initial kz"
	prompt fkz, "final kz"
	prompt nkz, "number of kz steps"
	doprompt "input paraments", new, iky,fky,nky,ikz,fkz,nkz
	if (v_flag==1)
		abort
	endif

	if(dimsize(ww,2)!=nky*nkz)
		print dimsize(ww,2), nky* nkz
		print "number of ky and kz steps is not correct"
		abort
	endif
		
	duplicate/o ww temp
	wave temp
	 redimension/n=(dimsize(ww,0)*dimsize(ww,1)*dimsize(ww,2)) temp
	 redimension/n=(dimsize(ww,0),dimsize(ww,1),nky,nkz) temp
	 setscale/p  x dimoffset(ww,0), dimdelta(ww,0), waveunits(ww,0) temp
	 setscale/p  y dimoffset(ww,1), dimdelta(ww,1), waveunits(ww,1) temp
	 setscale/i z iky, fky, "ky A-1" temp
	 setscale/i t ikz, fkz, "kzA-1"temp
	 	 
	 if(cmpstr(new,"yes")==0)
	 	killwaves/z $(w+"_4d")
	 	rename temp $(w+"_4d")
	 	NewImageTool5(w+"_4d")
	 endif
	 
	 if(cmpstr(new,"no")==0)
	 	duplicate/o temp $w
	 	killwaves temp
	 	NewImageTool5(w)
	 endif
end
	
Function Newkykz()
	string w
	prompt w, "Image Array", popup, "---4D---;"+WaveList("!*_CT",";", "DIMS:4")+"---3D---;"+WaveList("!*_CT",";", "DIMS:3")
	doprompt "", w
	if(v_flag==1)
		abort
	endif
	string dfn=uniquename("Kz_plotter", 11, 0)
	newdatafolder/o $dfn
	
	MakeKzVar(dfn,w)
	GetScanInfo(dfn)
	MakeDataWave(dfn,w)
	setupKzplot(dfn)
	setupTabkykz(dfn)

end
	
static Function  MakeKzVar(dfn,w)	
	string dfn, w
	string df="root:"+dfn+":"
	string/g $(df+"dname")		
	svar dname=$(df+"dname")
	wave wv=$w
	dname=getwavesdatafolder(wv,2)
	
	//kykz parameter
	variable/g $(df+"kxc"), $(df+"kyc"),$(df+"v0scan"), $(df+"wkscan")
	variable/g $(df+"x0"),$(df+"xd"),$(df+"xn") //pixel, theta, kx
	variable/g $(df+"y0"),$(df+"yd"),$(df+"yn") //kyscan ky
	variable/g $(df+"z0"),$(df+"zd"),$(df+"zn")//kzhv, kz
	variable/g $(df+"t0"),$(df+"td"),$(df+"tn")// BE
	string/g $(df+"plottype")
	//ky_kz  plotter var	
	variable/g $(df+"BEi"), $(df+"BEf")
	nvar BEi=$(df+"BEi"), BEf=$(df+"BEf")
	BEi=0;BEf=dimsize(wv,1)
	string/g $(df+"plottype")
	variable/g  $(df+"xp"),$(df+"yp"),$(df+"zp"),$(df+"tp") //curser coord, pnt units
	variable/g $(df+"xc"),$(df+"yc"),$(df+"zc"),$(df+"tc") //curser coord, real units
	make/o/n=0 $(df+"img_kxky"), $(df+"img_kzky"), $(df+"img_kxkz"), $(df+"prof_BE")
	//correction waves 
	variable/g $(df+"BEdrift_check")=0, $(df+"Thetadrift_check")=0, $(df+"Betadrift_check")=0
	variable/g $(df+"theta_offset")=0, $(df+"beta_offset")=0, $(df+"BE_offset")=0
	variable/g $(df+"v0new"), $(df+"wknew")
	make/o/n=0 $(df+"hv_scale")=0
	make/o/n=0 $(df+"ThetaDrift"), $(df+"BetaDrift"), $(df+"BEdrift")
	// color table
	variable/g $(df+"gamma")=1
	make/n=256/o $(df+"pmap")
	variable/g $(df+"whichCT")=0, $(df+"whichCTh")=0,$(df+"whichCTv")=0
	variable/g $(df+"invertCT")=0
end	

static Function GetScanInfo(dfn)
	string dfn
	string df="root:"+dfn+":"
	nvar kxc=$(df+"kxc"), kyc=$(df+"kyc"), v0scan=$(df+"v0scan"), wkscan=$(df+"wkscan")
	variable kx,ky,v0,wk
	prompt kx, "kx (A-1)"
	prompt ky, "ky center (A-1)"
	prompt v0, "inner potential (eV)"
	prompt wk, "sample work function (eV)"
	doprompt "ky-kz scan input parameters", kx, ky, v0, wk
	kxc=kx; kyc=ky; v0scan=v0; wkscan=wk
End

static Function Makedatawave(dfn,w)
	string dfn, w
	string df="root:"+dfn+":"
	nvar kxc=$(df+"kxc"), kyc=$(df+"kyc"), v0scan=$(df+"v0scan"), wkscan=$(df+"wkscan")
	nvar deg_pix=$(df+"deg_pix")
	wave wv=$("root:"+w)
	nvar kxc=$(df+"kxc"), kyc=$(df+"kyc"), v0scan=$(df+"v0scan"), wkscan=$(df+"wkscan")
	
	//get angle scaling
	if(cmpstr(waveunits(wv,0), "pixel")==0)
		string wvnote=note(wv)
		variable pos=strsearch(wvnote,"Angular",0)
		if(pos>0)
			variable ang=str2num(wvnote[pos+7,pos+9])
		else
			 ang=7
		endif
		variable/g $(df+"deg_pix")=ang/7*0.0102	
	else
		variable/g $(df+"deg_pix")=1
	endif

			
	//Make hv_scale
	wave hv_scale=$(df+"hv_scale")
	redimension/n=(selectnumber(wavedims(wv)==3, dimsize(wv,3), dimsize(wv,2))) hv_scale	
	duplicate/o hv_scale kz_temp
	if(wavedims(wv)==3)
		kz_temp=dimoffset(wv,2)+dimdelta(wv,2)*p
	elseif(wavedims(wv)==4)
		kz_temp=dimoffset(wv,3)+dimdelta(wv,3)*p
	endif
	hv_scale=1/0.5124^2*(kxc^2+kyc^2+kz_temp^2)-v0scan+wkscan
	killwaves kz_temp

	//ky_kz
	nvar t0=$(df+"t0"), td=$(df+"td"), tn=$(df+"tn")
	
	//Redim corretion waves
	wave BEdrift=$(df+"BEdrift"), BetaDrift=$(df+"BetaDrift"), ThetaDrift=$(df+"ThetaDrift")
	redimension/n=(selectnumber(wavedims(wv)==3, dimsize(wv,3), dimsize(wv,2))) BEdrift
	redimension/n=(selectnumber(wavedims(wv)==3, dimsize(wv,3), dimsize(wv,2))) BetaDrift
	redimension/n=(selectnumber(wavedims(wv)==3, dimsize(wv,3), dimsize(wv,2))) ThetaDrift
	BEdrift=0;BetaDrift=0;ThetaDrift=0
	
	variable BEp=(t0+td*tn)/2
	if(wavedims(wv)==3)
		duplicate/o wv $(nameofwave(wv)+"_kykz4d")
		wave wv_4d=$(nameofwave(wv)+"_kykz4d")
		redimension/n=(dimsize(wv,0),dimsize(wv,1),1,dimsize(wv,2)) wv_4d
		setscale/p x, dimoffset(wv,0),dimdelta(wv,0),waveunits(wv,0), wv_4d
		setscale/p y, dimoffset(wv,1),dimdelta(wv,1),waveunits(wv,1), wv_4d	
		setscale/p z, kyc,0,"ky", wv_4d
		setscale/p t, dimoffset(wv,2),dimdelta(wv,2),waveunits(wv,0), wv_4d
		wv=wv_4d
	endif
		setdatafolder $df
		string wvname="root:"+w
		interping(df, wvname, v0scan, wkscan, kxc, kyc, v0scan, wkscan, BEdrift, Betadrift, Thetadrift, BEp)
		setdatafolder root:
end	

static function Interping(df, w,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, i)
	string df,w
	wave  BEdrift, Betadrift, Thetadrift
	variable v0scan, wkscan, kxc, kyc, v0new, wknew,i
	wave org=$w
	
	variable BE=dimoffset(org,1)+dimdelta(org,1)*i
	variable c=0.5124
	nvar deg_pix=$(df+"deg_pix")
	variable khvmin=selectnumber(0>dimdelta(org,3),dimoffset(org,3),dimdelta(org,3)*(dimsize(org,3)-1)+dimoffset(org,3))
	variable khvmax=selectnumber(0<dimdelta(org,3),dimoffset(org,3),dimdelta(org,3)*(dimsize(org,3)-1)+dimoffset(org,3))
	variable thetaC=asin(kxc/sqrt(khvmin^2+c^2*(V0scan-wkscan)))*180/pi
	variable thetafwhm=abs(dimdelta(org,0)*(dimsize(org,0)-1)*deg_pix)/2 		//2*thetafwhm=full theta range
	variable theta1=asin(kxc/sqrt(khvmin^2+c^2*(V0scan-wkscan)))*180/pi
	variable theta2=asin(kxc/sqrt(khvmax^2+c^2*(V0scan-wkscan)))*180/pi
	variable theta_i=selectnumber(theta1<theta2,theta2,theta1)-thetafwhm
	variable theta_f=selectnumber(theta1>theta2,theta2,theta1)+thetafwhm	
	variable kx_i=sqrt(khvmin^2+c^2*(V0new-wknew-BE))*sin(theta_i*pi/180)*1.1
	variable kx_f=sqrt(khvmax^2+c^2*(V0new-wknew-BE))*sin(theta_f*pi/180)*1		
	wavestats/q betadrift
	variable Beta_shift=selectnumber(abs(V_max)>abs(v_min), V_max, V_min)
	variable ky_i=sqrt(khvmin^2+c^2*(v0new+wknew-BE))*cos(theta_i/180*pi)*sin(asin(dimoffset(org,2)/sqrt(khvmin^2+c^2*(v0scan+wkscan)))-Beta_shift/180*pi)
	variable ky_f=sqrt(khvmin^2+c^2*(v0new+wknew-BE))*cos(theta_i/180*pi)*sin(asin((dimoffset(org,2)+dimsize(org,2)*dimdelta(org,2))/sqrt(khvmin^2+c^2*(v0scan+wkscan)))+Beta_shift/180*pi)
	variable kz_i=0.9*khvmin
	variable kz_f=1.1*khvmax
	

	make/o/n=(dimsize(org,0), dimsize(org,2), dimsize(org,3)) $(df+"temp1")
	wave temp1=$(df+"temp1")
	setscale/p x, dimoffset(org,0), dimdelta(org,0), waveunits(org,0), temp1
	setscale/p y, dimoffset(org,2), dimdelta(org,2), waveunits(org,2), temp1
	setscale/p z, dimoffset(org,3), dimdelta(org,3), waveunits(org,3), temp1
	temp1=org[p][i][q][r]
			
	duplicate/o temp1 $(df+"temp2")
	wave temp2=$(df+"temp2")
	setscale/i x, theta_i, theta_f, "theta", temp2
	temp2=interp3d(temp1,(x-(asin(kxc/sqrt(z^2+c^2*(V0scan-wkscan)))*180/pi)+thetafwhm)/deg_pix,y,z)
	
	make/o/n=(dimsize(temp2,0), dimsize(temp2,1)*1.1, dimsize(temp2,2)*1.1) $(df+"temp6")
	wave temp6=$(df+"temp6")
	setscale/i x, kx_i, kx_f, "kx", temp6
	setscale/i y, ky_i, ky_f, "ky", temp6
	setscale/p z, dimoffset(temp2,2), dimdelta(temp2,2), waveunits(temp2,2), temp6
	temp6=interp3d(temp2,asin((x-thetadrift[p])/sqrt(z^2+c^2*(V0new-wknew-BE)))*180/pi,sqrt(z^2+c^2*(V0scan-wkscan))*cos(asin(kxc/sqrt(z^2+c^2*(v0scan-wkscan))))*sin(asin(y/sqrt(z^2+c^2*(V0new-wknew-BE))/cos(x/180*pi))-betadrift[q]),z)
	
	duplicate/o temp6 temp1
	setscale/i z, khvmin*.8, khvmax*1.01, "kz", temp6
	temp6=interp3d(temp1,x,y,sqrt(x^2+y^2+z^2+c^2*(V0new-wknew-BE)))
	
end


static function BEloop(df,wname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, BEpstart, BEpend)
	string df, wname
	wave  BEdrift, Betadrift, Thetadrift
	variable v0scan, wkscan, kxc, kyc, v0new, wknew, BEpstart, BEpend
	
	string newname=wname+"_k"

	variable i=BEpstart
	wave wv=$wname
	wave temp6=$(df+"temp6")
	make/o/n=(dimsize(temp6,0),abs(BEpend-BEpstart),dimsize(temp6,1),dimsize(temp6,2)) $(df+"kwave")
	wave kwave=$(df+"kwave")
	setscale/p x, dimoffset(temp6,0), dimdelta(temp6,0), waveunits(temp6,0), kwave
	setscale/p y, dimoffset(wv,1), dimdelta(wv,1), waveunits(wv,1), kwave
	setscale/p z, dimoffset(temp6,1), dimdelta(temp6,1), waveunits(temp6,1), kwave
	setscale/p t, dimoffset(temp6,2), dimdelta(temp6,2), waveunits(temp6,2), kwave
	
	Interping(df,wname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, i)
	i=BEpstart
	Do
		Interping(df,wname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, i)
		execute "kwave()["+num2str(i)+"]()()=temp6(x)(z)(t)"
	i+=1
	print i
	while(i<=BEpend)

//	rename kwave $("root:"+newname)
end



static Function setupKzplot(dfn)
	string dfn
	string df="root:"+dfn+":"
	silent 1; pauseupdate
	setdatafolder root:
	
	nvar v0scan=$(df+"v0scan"), wkscan=$(df+"wkscan"), kxc=$(df+"kxc"), kyc=$(df+"kyc")
	nvar deg_pix=$(df+"deg_pix")
	
	wave ww=$(df+"temp6")	
	svar plottype=$(df+"plottype")
	plottype="temp6"

	//setup colors
	nvar whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"),whichCTv=$(df+"whichCTv")
	execute "loadct("+num2str(whichCT)+")"	//load initial color table
	duplicate/o root:colors:ct $(df+"ct"), $(df+"ct_h"), $(df+"ct_v")
	wave ct=$(df+"ct"), ct_h=$(df+"ct_h"), ct_v=$(df+"ct_v")
	wave pmap=$(dF+"pmap")
	nvar gamma=$(dF+"gamma")
	setformula $(df+"pmap") , "255*(p/255)^"+df+"gamma)"
	setformula $(df+"ct"), "root:colors:all_ct[pmap[invertct*(255-p)+(invertct==0)*p]][q][whichCT]"
	setformula $(df+"ct_h"), "root:colors:all_ct[pmap[invertct*(255-p)+(invertct==0)*p]][q][whichCTh]"
	setformula $(df+"ct_v"), "root:colors:all_ct[pmap[invertct*(255-p)+(invertct==0)*p]][q][whichCTv]"
	
	//make img waves
	make/o/n=(dimsize(ww,0),dimsize(ww,1)) $(df+"img_kxky")
	wave img_kxky=$(df+"img_kxky")
	setscale/p x, dimoffset(ww,0),dimdelta(ww,0),waveunits(ww,0) img_kxky
	setscale/p y, dimoffset(ww,1),dimdelta(ww,1),waveunits(ww,1) img_kxky
	img_kxky[][]=ww[p][q][dimsize(ww,2)/2]

	make/o/n=(dimsize(ww,0),dimsize(ww,2)) $(df+"img_kxkz")
	wave img_kxkz=$(df+"img_kxkz")
	setscale/p x, dimoffset(ww,0),dimdelta(ww,0),waveunits(ww,0) img_kxkz
	setscale/p y, dimoffset(ww,2),dimdelta(ww,2),waveunits(ww,2) img_kxkz
	img_kxkz[][]=ww[p][dimsize(ww,1)/2][q]
	
	make/o/n=(dimsize(ww,2),dimsize(ww,1)) $(df+"img_kzky")
	wave img_kzky=$(df+"img_kzky")
	setscale/p x, dimoffset(ww,2),dimdelta(ww,2),waveunits(ww,2) img_kzky
	setscale/p y, dimoffset(ww,1),dimdelta(ww,1),waveunits(ww,1) img_kzky
	img_kzky[][]=ww[dimsize(ww,0)/2][q][p]
		
	svar dname=$(df+"dname")
	wave org=$dname
	make/o/n=(dimsize(org,1)) $(df+"prof_BE")
	wave prof_BE=$(df+"prof_BE")
	setscale/p x, dimoffset(org,1),dimdelta(org,1),waveunits(org,1) prof_BE
	prof_BE[]=org[dimsize(org,0)/2][p][dimsize(org,2)/2][dimsize(org,3)/2]
	//Display kxky
	dowindow/f $dfn
		if(v_flag==0)
			Display /W=(248,103,938,674); appendimage img_kxky
			DoWindow/c/t $dfn, dfn+"["+dname+"]"
			setwindow $dfn, hook=imgkykzHookFcn, hookevents=3
			modifyimage img_kxky, cindex=ct
		endif
			
	//cursors
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc")
	nvar xp=$(df+"xp"), yp=$(df+"yp"), zp=$(df+"zp"), tp=$(df+"tp")
	nvar x0=$(df+"x0"),y0=$(df+"y0"),z0=$(df+"z0"), t0=$(df+"t0")
	nvar xd=$(df+"xd"),yd=$(df+"yd"),zd=$(df+"zd") ,td=$(df+"td")
	x0=dimoffset(ww,0); y0=dimoffset(ww,1); z0=dimoffset(ww,2)
	xd=dimdelta(ww,0); yd=dimdelta(ww,1); zd=dimdelta(ww,2)
	xp=dimsize(ww,0)/2;yp=dimsize(ww,1)/2; zp=dimsize(ww,2)/2
	t0=dimoffset(prof_BE,0); td=dimdelta(prof_BE,0); tp=dimsize(prof_BE,0)/2
	xc=x0+xd*xp
	yc=y0+yd*yp
	zc=z0+zd*zp
	tc=t0+td*tp
	execute df+"xp:=("+df+"xc-"+df+"x0)/"+df+"xd"
	execute df+"yp:=("+df+"yc-"+df+"y0)/"+df+"yd"
	execute df+"zp:=("+df+"zc-"+df+"z0)/"+df+"zd"
	execute df+"tp:=("+df+"tc-"+df+"t0)/"+df+"td"
	make/o/n=(2) $(df+"hcurx"), $(df+"hcury"), $(df+"vcurx"), $(df+"vcury"),$(df+"zcurx"), $(df+"zcury"), $(df+"tcurx"), $(df+"tcury")
	wave hcurx=$(df+"hcurx"), hcury=$(df+"hcury"), vcurx=$(df+"vcurx"), vcury=$(df+"vcury")
	wave zcurx=$(df+"zcurx"), zcury=$(df+"zcury"), tcurx=$(df+"tcurx"), tcury=$(df+"tcury")
 	execute df+"hcury:="+df+"yc";	hcurx={-inf,inf};
	execute df+"vcurx:="+df+"xc";	vcury={-inf,inf}
	execute df+"zcurx:="+df+"zc";	zcury={-inf,inf}
	execute df+"tcurx:="+df+"tc";	tcury={-inf,inf}

	appendtograph hcury vs hcurx
	appendtograph vcury vs vcurx

	modifyRGBaxis("hcury","Y","left",16385,65535,0)
	modifyRGBaxis("vcury","Y","left",16385,65535,0)

	//DEPENDENCY FORMULAS
	string whichtemp=df+"temp6"
	execute df+"img_kxky:="+whichtemp+"[p][q]["+df+"zp]["+df+"tp]"
	execute df+"img_kxkz:="+whichtemp+"[p]["+df+"yp][q]["+df+"tp]"
	execute df+"img_kzky:="+whichtemp+"["+df+"xp][q][p]"

	//Append all graphs
	string ImgList=ImageNameList("", ";" )
	if(strsearch(ImgList,"img_kzky",0,2)==-1)
		appendimage/l=imghL/t=imghT img_kxkz
		appendtograph/l=imghL/t=imghT vcury vs vcurx
		appendtograph/l=imghL/t=imghT zcurx vs zcury
		appendimage/r=imgvR/b=imgvB img_kzky
		appendtograph/r=imgvR/b=imgvB hcury vs hcurx
		appendtograph/r=imgvR/b=imgvB zcury vs zcurx
		appendtograph/r=profR/b=profB prof_BE
		appendtograph/r=profR/b=profB tcury vs tcurx
	endif	
	
	//kxky
	ModifyGraph axisEnab(left)={0,0.4}, axisEnab(bottom)={0,0.47}
	ModifyGraph freePos(left)=0,freePos(bottom)=0
	Label bottom waveunits(img_kxky,0)
	Label left waveunits(img_kxky,1)

	//kxkz (hL,hT)
	modifyRGBaxis("vcury","X","imghT",16385,65535,0)
	modifyRGBaxis("zcurx","Y","imghL",16385,65535,0)	
	ModifyGraph axisEnab(imghT)={0,0.4}, axisEnab(imghL)={.53,1}
	ModifyGraph freePos(imghT)={0,kwFraction}, freePos(imghL)={0,kwFraction}	
	label imghL waveunits(img_kxkz,1)
	modifyimage img_kxkz, cindex=ct_h
	
	//kzky (vR,vB)
	modifyRGBaxis("hcury","Y","imgvR",16385,65535,0)
	modifyRGBaxis("zcurx","X","imgvB",16385,65535,0)
	modifygraph axisEnab(imgvB)={0.6,1}, axisEnab(imgvR)={0, 0.40}
	ModifyGraph freePos(imgvR)=0, freePos(imgvB)=0
	modifyimage img_kzky, cindex=ct_v
	Label imgvB waveunits(img_kzky,0)
	Label imgvR waveunits(img_kzky,1)
	
	//prof_BE
	Label profB waveunits(prof_BE,0)
	modifygraph axisEnab(profB)={0.6,1}, axisEnab(profR)={.6, 1}
	ModifyGraph freePos(profR)={0,kwFraction},freePos(profB)={0.6,kwFraction}
	modifyRGBaxis("tcury","X","profB",16385,65535,0)

	adjustCT_kykz(df, "img_kxky", "ct")
	adjustCT_kykz(df, "img_kxkz", "ct_h")
	adjustCT_kykz(df, "img_kzky", "ct_v")
	
ModifyGraph margin=72, margin(top)=144
end	

static function adjustCT_kykz(df, which, whichCT)
	string df, which, whichCT
	wave img=$(df+which)
	wave ct=$(df+whichCT)
	imagestats /M=1 img
	setscale/i x v_min,v_max,ct
end

function update_ps(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc")
	nvar xp=$(df+"xp"), yp=$(df+"yp"), zp=$(df+"zp"), tp=$(df+"tp")
	nvar x0=$(df+"x0"), y0=$(df+"y0"),z0=$(df+"z0"), t0=$(df+"t0")
	nvar xd=$(df+"xd"), yd=$(df+"yd"),zd=$(df+"zd"), td=$(df+"td")
	nvar xn=$(df+"xn"), yn=$(df+"yn"),zn=$(df+"zn"), tn=$(df+"tn")
	svar plottype=$(df+"plottype")
	wave ww=$(df+plottype)

	strswitch(varName)
		case "xp":
			x0=dimoffset(ww,0); xd=dimdelta(ww,0); xn=dimsize(ww,0)
			xc= xp*xd+x0
			break
		case "yp":
			y0=dimoffset(ww,1); yd=dimdelta(ww,1); yn=dimsize(ww,1)
			yc=yp*yd+y0
			break
		case "zp":
			z0=dimoffset(ww,2); zd=dimdelta(ww,2); zn=dimsize(ww,2)
			zc=zp*zd+z0
			break
		case "tp":
			tc=tp*td+t0
			break
	endswitch
end

Function selectCTList_kykz(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	nvar  whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"),whichCTv=$(df+"whichCTv")
	whichCT=popnum-1
	whichCTh=popnum-1
	whichCTv=popnum-1
End

function Tabkykz(name, tab)
	string name
	variable tab
	string dfn=winname(0,1)
	string df="root:"+dfn+":"

// info	tab=0
	SetVariable setvarxc, disable=(tab!=0)
	SetVariable setvarxp, disable=(tab!=0)
	SetVariable setvaryc, disable=(tab!=0)
	SetVariable setvaryp, disable=(tab!=0)
	SetVariable setvarzc, disable=(tab!=0)
	SetVariable setvarzp, disable=(tab!=0)
	SetVariable setvartc, disable=(tab!=0)
	SetVariable setvartp, disable=(tab!=0)	
	SetVariable setvarv0scan, disable=(tab!=0)
	SetVariable setvarwkscan, disable=(tab!=0)	

// plotting tab=1	
	popupmenu whichplot, disable=(tab!=1)
	button ToITbutton, disable=(tab!=1)
	button Org2ITbutton, disable=(tab!=1)
	button kykz_hvbutton, disable=(tab!=1)

// colors tab=2
	setvariable setgamma,disable=(tab!=2)
	slider slidegamma,disable=(tab!=2)	
	groupBox Colors,disable=(tab!=2)
	popupmenu selectCT,disable=(tab!=2)
	checkbox invertCT,disable=(tab!=2)

// process tab=3	
	SetVariable setvarv0new, disable=(tab!=3)
	SetVariable setvarwknew, disable=(tab!=3)
	button ReloadButton, disable=(tab!=3)
	button UpdateButton, disable=(tab!=3)

// drift correction tab=4
	GroupBox Driftoffset disable=(tab!=4)
	groupBox Driftkz disable=(tab!=4)
	SetVariable SetthetaOffset disable=(tab!=4)
	SetVariable SetbetaOffset disable=(tab!=4)
	button BEcorrButton, disable=(tab!=4)	
	button ThetaCorrbutton,  disable=(tab!=4)		
	button BetaCorrbutton, disable=(tab!=4)		
	button DonecorrButton, disable=3
// export tab=5
	button exportbut, disable=(tab!=5)
	SetVariable BEpfirst, disable=(tab!=5)
	SetVariable BEplast, disable=(tab!=5)
end

function setupTabkykz(dfn)
	string dfn
	string df="root:"+dfn+":"
	
	tabcontrol tab0 proc=tabkykz, size={600,80}, pos={20,0}, labelback=(16385,65535,65535)
	tabcontrol tab0 tablabel(0)="info",tablabel(1)="plotting", tablabel(2)="colors",tablabel(3)="process",tablabel(4)="Drift Correction"
	tabcontrol tab0 tablabel(5)="export"
	
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc")
	nvar xp=$(df+"xp"), yp=$(df+"yp"), zp=$(df+"zp"), tp=$(df+"tp")		
	nvar kx_check=$(df+"kx_check"),  BE_check=$(df+"BE_check"),  thetaDrift_check=$(df+"ThetaDrift_check"),betaDrift_check=$(df+"BetaDrift_check")
	nvar BEi=$(df+"BEi"), BEf=$(df+"BEf")
		
	nvar v0scan=$(df+"v0scan"), wkscan=$(df+"wkscan"), kxc=$(df+"kxc"), kyc=$(df+"kyc"), theta_offset=$(df+"theta_offset"), Beta_offset=$(df+"beta_offset")
	nvar v0new=$(df+"v0new"), wknew=$(df+"wknew")
	v0new=v0scan; wknew=wkscan
	wave hv_scale=$(df+"hv_scale")
	
	//info tab
	SetVariable setvarxc value=xc, title="x", pos={60,32},size={100,15},labelBack=(16385,65535,65535)
	SetVariable setvarxp value=xp,  title="x [p]", pos={60,52},size={100,15},labelBack=(16385,65535,65535),  proc=update_ps,limits={-inf,inf,1}
	SetVariable setvaryc value=yc, title="y", pos={170,32},size={100,15},labelBack=(16385,65535,65535)
	SetVariable setvaryp value=yp, title="y [p]", pos={170,52},size={100,15},labelBack=(16385,65535,65535), proc=update_ps,limits={-inf,inf,1}
	SetVariable setvarzc value=zc, title="kz", pos={280,32},size={100,15},labelBack=(16385,65535,65535)
	SetVariable setvarzp value=zp, title="kz [p]", pos={280,52},size={100,15},labelBack=(16385,65535,65535),  proc=update_ps,limits={-inf,inf,1}
	SetVariable setvartc value=tc, title="BE", pos={390,32},size={100,15},labelBack=(16385,65535,65535), proc=kykz_VarCnt
	SetVariable setvartp value=tp, title="BE [p]", pos={390,52},size={100,15},labelBack=(16385,65535,65535), proc=update_ps,limits={-inf,inf,1}
	SetVariable setvarV0scan, value=v0scan, title="V0scan", pos={500,32},size={100,15},labelBack=(16385,65535,65535)
	SetVariable setvarwkscan, value=wkscan, title="wkscan", pos={500,52},size={100,15},labelBack=(16385,65535,65535)
	
	//Plotting
	popupmenu whichplot, title="plot",pos={60,40},size={100,15},labelBack=(16385,65535,65535),  proc=ky_kzFunctions#kykzPlotpop
	PopupMenu whichplot value="kx, ky, kz;kx, ky, hv;theta, ky, hv;pixel, kyscan, k_hv "
	Button ToITbutton, title="to ImageTool5", pos={250,40},size={110,20},labelBack=(16385,65535,65535),  proc=kykz_buttonCnt
	Button Org2ITbutton, title="orginal 2 IT", pos={375,40},size={110,20},labelBack=(16385,65535,65535),  proc=kykz_buttonCnt
	Button kykz_hvbutton, title="dispay hv scale", pos={500,40},size={110,20},labelBack=(16385,65535,65535),  proc=kykz_buttonCnt

	// process
	SetVariable setvarv0new value=v0new, title="v0 new", pos={30,25}, size={75,15}, labelBack=(16385,65535,65535),limits={-inf,inf,0.1}
	SetVariable setvarwknew value=wknew, title="W new", pos={140,25}, size={75,15},labelBack=(16385,65535,65535),limits={-inf,inf,0.1}
	Button ReloadButton, title="Reload",  pos={35,50}, size={75,20},fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button UpdateButton, title="Update", pos={135,50}, size={75,20}, fcolor=(16385,28398,65535), proc=kykz_ButtonCnt

	//drift correction
	groupBox Driftkz title="kz-dependent drift",pos={25,22},size={280,53},fcolor=(65535,0,0),labelback=0
	Button BEcorrButton, title="BE vs kz", pos={35,45}, size={75,20},fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button ThetaCorrbutton, title="Theta drift", pos={130,45},  size={75,20},fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button BetaCorrbutton, title="Beta drift", pos={220,45},  size={75,20},fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button Donecorrbutton, title="Done", pos={315,45}, size={75,20}, disable=3, proc=kykz_ButtonCnt
	GroupBox Driftoffset title="Constant Offset",pos={460,18},size={145,60},fcolor=(65535,0,0),labelback=0
	SetVariable SetthetaOffset, value=theta_offset,title="theta _offset", pos={465,35}, size={135,15}, proc=kykz_VarCnt
	SetVariable SetbetaOffset, value=beta_offset,title="beta _offset", pos={465,55}, size={135,15}, proc=kykz_VarCnt	
	
	//export
	popupmenu whichplot, title="plot",pos={60,40},size={100,15},labelBack=(16385,65535,65535),  proc=ky_kzFunctions#kykzPlotpop
	PopupMenu whichplot value="4d(kx, BE, ky, kz); 4d(kx, BE, ky, hv); 4d(theta, BE, ky, hv);4d(kx, BE, ky, kz)"
	button exportbut,title="export", pos={30,35}, size={75,20},proc=kykz_ButtonCnt, fcolor=(16385,28398,65535)  
	setVariable BEpfirst, title="BE [p] first", pos={125,30}, size={120,20}, fcolor=(16385,28398,65535), value=BEi 
	setVariable BEplast, title="BE [p] last ", pos={125,55}, size={125,20}, fcolor=(16385,28398,65535) , value=BEf	
	
	//colors
	SetVariable setgamma,pos={74,26},size={52,14},title="g"
	SetVariable setgamma,help={"Gamma value for image color table mapping.  Gamma < 1 enhances lower intensity features."}
	SetVariable setgamma,font="Symbol"
	SetVariable setgamma,limits={0.01,Inf,0.05},value=$(df+"gamma")
	Slider slidegamma size={70,16},pos={66,50},ticks=0,vert=0,variable=$(df+"gamma");DelayUpdate
	Slider slidegamma limits={0.01,10,0.01}
	checkbox invertCT,pos={153,45},size={80,14},title="Invert?"
	execute "checkbox invertCT,variable="+df+"invertCT" 
	variable x0=140, y0=17
  	groupBox Colors title="Color Options",pos={x0,y0}, size={90,60},fcolor=(65535,0,0),labelback=0
	PopupMenu SelectCT,pos={x0+13,y0+15},size={43,20},proc=SelectCTList_kykz,title="CT"
	PopupMenu SelectCT,mode=0,value= #"colornameslist()"
	checkbox invertCT,pos={x0+13,y0+40},size={80,14},title="Invert?"


Tabkykz("tab0", 0) 
end

function imgkykzHookFcn(s)
	string s
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	string temp=getdatafolder(1)
	
	wave pmap=$(df+"pmap"),vimg_ct=$(df+"ct_v"), himg_ct=$(df+"ct_h"), img_ct=$(df+"ct")
	wave img_kxky=$(df+"img_kxky"), img_kxkz=$(df+"img_kxkz"), img_kzky=$(df+"img_kzBE")
	variable i	
	
	if (cmpstr(stringbykey("event",s),"kill")==0)
		vimg_ct=0; himg_ct=0; img_ct=0; pmap=0
		killvariables/z xc,yc,zc,tc
		string inl=imagenamelist("",","), tnl=tracenamelist("",",",1)
		execute "removeimage/z "+ inl[0,strlen(inl)-2]			//remove all images
		execute "removefromgraph/z "+  tnl[0,strlen(tnl)-2]		//remove all traces	
		killwaves/z img_kxky, img_kxBE, img_kzBE, prof_kz
		killdatafolder $df
		return(-1)
	endif
	
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc")
	variable mousex,mousey,ax,ay,az,modif
	variable xcold=xc,ycold=yc,zcold=zc, tcold=tc
	modif=numberByKey("modifiers",s) & 15
	variable statuscode=0
	
	if(strsearch(s,"EVENT:mouse",0)>0)
		if(modif==9) //cmd+mouse
			variable axmin, axmax,aymin, aymax
			variable azmin,azmax,zymin,zymax
			variable xcur,ycur,zcur
			variable/c offset
			mousex=numberbykey("mousex",s)
			mousey=numberbykey("mousey",s)
	//		print mousex,mousey
			ay=axisvalfrompixel(dfn,"left",mousey)
			ax=axisvalfrompixel(dfn,"bottom", mousex)
			az=axisvalfrompixel(dfn,"imghL",mousey)
	
			statuscode=1
			getaxis/q bottom;axmin=min(v_max,v_min);axmax=max(v_max,v_min)
			getaxis/q left; aymin=min(v_max,v_min);aymax=max(v_max,v_min)
			getaxis/q imghL;azmin=min(v_max,v_min);azmax=max(v_max,v_min)
			
			if((ax>axmin)*(ax<axmax)*(ay>aymin)*(ay<aymax)) //in ky vs kx
				xc=selectnumber((ax>axmin)*(ax<axmax),xc,ax)
				yc=selectnumber((ay>aymin)*(ay<aymax),yc,ay)
			endif
			if((ax>axmin)*(ax<axmax)*(az>azmin)*(az<azmax)) //in kx vs kz
				xc=selectnumber((ax>axmin)*(ax<axmax),xc,ax)
				zc=selectnumber((az>azmin)*(az<azmax),zc,az)
			endif
			
			az=axisvalfrompixel(dfn,"imgvB",mousex)
			if((az>azmin)*(az<azmax)*(ay>aymin)*(ay<aymax))//in kz vs ky
				yc=selectnumber((ay>aymin)*(ay<aymax),yc,ay)
				zc=selectnumber((az>azmin)*(az<azmax),zc,az)
			endif	
			if((mousex>375)*(mousey<300)) //in profile
				ax=axisvalfrompixel(dfn,"profB",mousex)
				getaxis/q profB; axmin=min(v_max,v_min);axmax=max(v_max,v_min)
				tc=selectnumber((ax>axmin)*(ax<axmax),tc,ax)
				svar dname=$(df+"dname")
				nvar v0scan=$(df+"v0scan"), wkscan=$(df+"wkscan"), kxc=$(df+"kxc"), kyc=$(df+"kyc")
				nvar v0new=$(df+"v0new"), wknew=$(df+"wknew"), tp=$(df+"tp")
				wave BEdrift=$(df+"BEdrift"), Betadrift=$(df+"Betadrift"), Thetadrift=$(df+"Thetadrift")
				interping(df, dname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, tp)
				 
			endif
			
			adjustCT_kykz(df, "img_kxky", "ct")
			adjustCT_kykz(df, "img_kxkz", "ct_h")
			adjustCT_kykz(df, "img_kzky", "ct_v")
		endif
	return statuscode	
	endif
	
end

Function kykz_VarCnt (ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar dname=$(df+"dname")
	nvar kxc=$(df+"kxc"), kyc=$(df+"kyc"), v0scan=$(df+"v0scan"), wkscan=$(df+"wkscan")
	nvar v0new=$(df+"v0new"), wknew=$(df+"wknew")
	nvar tp=$(df+"tp") 
	nvar theta_offset=$(df+"theta_offset"), beta_offset=$(df+"beta_offset")
	wave BEdrift=$(df+"BEdrift"), Betadrift=$(df+"Betadrift"), Thetadrift=$(df+"Thetadrift")
	
	strswitch(ctrlName)
		case "setvartc":
			ky_kzFunctions#interping(df, dname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, tp)
			break
		case "SetThetaOffset":
			thetadrift=theta_offset
			ky_kzFunctions#interping(df, dname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, tp)
			break
		case "SetBetaOffset":
			betadrift=beta_offset
			ky_kzFunctions#interping(df, dname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, tp)
			break
	endswitch
End


Function kykz_ButtonCnt(ctrlName) :ButtonControl
	string ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar dname=$(df+"dname"), plottype=$(df+"plottype")
	nvar tp=$(df+"tp")
	nvar kxc=$(df+"kxc"), kyc=$(df+"kyc"), v0scan=$(df+"v0scan"), wkscan=$(df+"wkscan")
	nvar v0new=$(df+"v0new"), wknew=$(df+"wknew")
	nvar theta_offset=$(df+"theta_offset"), beta_offset=$(df+"beta_offset")	
	wave BEdrift=$(df+"BEdrift"), Betadrift=$(df+"Betadrift"), Thetadrift=$(df+"Thetadrift")
	nvar BEi=$(df+"BEi"), BEf=$(df+"BEf")
	strswitch(ctrlName)
		//plotting
		case "ToITbutton":
			execute "NewImageTool5(\""+df+plottype+"\")"
			break
		case "Org2ITbutton":
			execute "NewImageTool5(\""+dname+"\")" 
			break
		case "kykz_hvButton":
			execute "ky_kzFunctions#kykz_hv()"
			break		
		//process
		case "ReLoadButton":
			v0new=v0scan; wknew=wkscan
			BEdrift=0; Betadrift=0; Thetadrift=0
			ky_kzFunctions#interping(df, dname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, tp)
			break
		case "UpdateButton":
			ky_kzFunctions#interping(df, dname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, tp)
			break
		//drift correction
		case  "BEcorrButton":
			execute "ky_kzFunctions#BEkz_Corr()"
			break
		case "ThetaCorrbutton":
			setdatafolder df
			execute "Edit/K=0 "+df+"ThetaDrift"
			break
		case "BetaCorrbutton":
			setdatafolder df
			execute "Edit/K=0 "+df+"BetaDrift"	
			break		
		// export
		case "exportbut":
		ky_kzFunctions#BEloop(df,dname,v0scan, wkscan, kxc, kyc, v0new, wknew, BEdrift, Betadrift, Thetadrift, BEi, BEf)
			break
	endswitch
end
static function kykzExportpop(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr	
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	string whichtemp
	switch(popNum)
		case 1:
			whichtemp="temp6"	
		break
		case 2:
			whichtemp="temp5"
		break
		case 3:
			whichtemp="temp4"
		break
	endswitch
end
static function kykzPlotpop(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr	
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	string whichtemp	
	switch(popNum)
		case 1:
			whichtemp="temp6"	
		break
		case 2:
			whichtemp="temp5"
		break
		case 3:
			whichtemp="temp4"
		break
		case 4:
			whichtemp="temp1"
		break	
	endswitch
	wave wv=$(df+whichtemp)
	svar plottype=$(df+"plottype")
	plottype=whichtemp
	nvar xp, xc, x0, xd
	nvar yp, yc, y0, yd
	nvar zp, zc, z0, zd
	x0=dimoffset(wv,0); xd=dimdelta(wv,0); xc=x0+xp*xd
	y0=dimoffset(wv,1); yd=dimdelta(wv,1); yc=y0+yp*yd
	z0=dimoffset(wv,2); zd=dimdelta(wv,2); zc=z0+zp*zd
	execute df+"xp:=("+df+"xc-"+df+"x0)/"+df+"xd"
	execute df+"yp:=("+df+"yc-"+df+"y0)/"+df+"yd"
	execute df+"zp:=("+df+"zc-"+df+"z0)/"+df+"zd"

	wave img_kxky=$(df+"img_kxky"), img_kxkz=$(df+"img_kxkz"),img_kzky=$(df+"img_kzky")
	make/o/n=(dimsize(wv,0),dimsize(wv,1)) img_kxky
	setscale/p x, dimoffset(wv,0),dimdelta(wv,0),waveunits(wv,0) img_kxky
	setscale/p y, dimoffset(wv,1),dimdelta(wv,1), waveunits(wv,1) img_kxky
	make/o/n=(dimsize(wv,0),dimsize(wv,2)) img_kxkz
	setscale/p x, dimoffset(wv,0), dimdelta(wv,0), waveunits(wv,0) img_kxkz
	setscale/p y, dimoffset(wv,2), dimdelta(wv,2), waveunits(wv,2) img_kxkz
	make/o/n=(dimsize(wv,2),dimsize(wv,1)) img_kzky
	setscale/p x, dimoffset(wv,2), dimdelta(wv,2), waveunits(wv,2) img_kzky
	setscale/p y, dimoffset(wv,1),dimdelta(wv,1), waveunits(wv,1) img_kzky	
	execute df+"img_kxky:="+whichtemp+"[p][q]["+df+"zp]["+df+"tp]"
	execute df+"img_kxkz:="+whichtemp+"[p]["+df+"yp][q]["+df+"tp]"
	execute df+"img_kzky:="+whichtemp+"["+df+"xp][q][p]"
	
	Label bottom waveunits(img_kxky,0)
	Label left waveunits(img_kxky,1)
	label imghL waveunits(img_kxkz,1)
	Label imgvB waveunits(img_kzky,0)
	Label imgvR waveunits(img_kzky,1)
end

function Export_kykz(ctrlName) :ButtonControl
	string ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar dname=$(df+"dname")
	wave org=$("root:"+dname)
//	wave datawave=$(df+"datawave")
	string newname
	nvar kx_check=$(df+"kx_check")
	variable run=1
//export 4D 
	 if(cmpstr(ctrlname, "exportkspacebut")==0) 
	 	prompt newname, "Name of new datawave"
	 	doprompt "Export 4D", newname
	 	if(v_flag==1)
	 		abort
	 	endif 
//	 	duplicate/o datawave $(df+"datawave_")
//	 	wave datawave_=$(df+"datawave_")
	 	if(kx_check==1)
	 		//Calc_datawave(df,"kx", 4,run)
		else 
			//Calc_datawave(df,"theta",4,run)
	 	endif
		killwaves/z $(df+"tmp"), $(df+"tmporg")
//		movewave $(df+"datawave") $("root:"+newname)
//		duplicate/o datawave $("root:"+newname)
//		duplicate/o datawave_ $(df+"datawave")
//	 	killwaves/z $(df+"datawave_")
		newimagetool5(newname)
	 endif
	
//export 3D	
	if(cmpstr(ctrlname, "export3dvol")==0) 
		prompt newname, "Name of new datawave"
	 	doprompt "Export 3D", newname
	 	if(v_flag==1)
	 		abort
	 	endif  	
		//Calc_datawave(df,selectstring(kx_check,"theta", "kx"), 3,run)
	//	duplicate $(df+selectstring(kx_check, "tmporg", "tmp")) $newname
	//	duplicate/o $(df+"datawave_") $(df+"datawave")
	//	killwaves/z $(df+"tmp"), $(df+"tmporg"), $(df+"datawave_")	
	endif
//export img	
	if(cmpstr(ctrlname, "exportimg")==0) 
		string which_img
		Prompt  which_img, "which image:", popup, "kx_BE; kx_ky;kz_BE"
		Prompt newname, "exported wave name"
		DoPrompt "", which_img, newname
		If(v_flag==1)
			abort
		endif
		strswitch(which_img)
			case "kx_BE":
				wave img=$(df+"img_kxBE")
				break
			case "kx_ky":
				wave img=$(df+"img_kxky")
				break
			case "kz_BE":
				wave img=$(df+"img_kzBE")
				break
			endswitch		                                                                                                                                                              
			duplicate/o img $("root:"+newname)
	endif
end



static Function BEkz_corr()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar dname=$(df+"dname")
	wave org=$dname
	make/o/n=(dimsize(org,selectnumber(wavedims(org)==4,2,3)),dimsize(org,1)) $(df+"img_kzBE")
	wave img=$(df+"img_kzBE")
	setscale/p y, dimoffset(org,1), dimdelta(org,1), waveunits(org,1) img
	if(wavedims(org)==3)
		setscale/p x, dimoffset(org,2), dimdelta(org,2), waveunits(org,2) img
		img[][]=org[dimsize(org,0)/2][q][p]
	else
		setscale/p x, dimoffset(org,3), dimdelta(org,3), waveunits(org,3) img
		img[][]=org[dimsize(org,0)/2][q][dimsize(org,1)/2][p]
	endif
	make/o/n=(dimsize(img,0)) $(df+"BEdrift")
	wave BEdrift=$(df+"BEdrift")
	BEdrift=0
	setscale/p x,dimoffset(img,0), dimdelta(img,0), waveunits(img,0), BEdrift
	display; appendimage img; appendtograph BEdrift
	appendtograph/r=imghR/b=imghB corr_BEkz
	graphwaveedit BEdrift
end

static Function DoneCorr()
	button donecorrbutton, disable=3
	graphnormal
end

static function kykz_hv() 
	string ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar dname=$(df+"dname")
	wave hv=$(df+"hv_scale")
	edit/k=0 $(df+"hv_scale")
end

static function SetOffsetCurs(ctrlname)
	string ctrlname
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc") 
	nvar theta_offset=$(df+"theta_offset"), beta_offset=$(df+"beta_offset")
	wave datawave=$(df+"datawave"), img_kxky=$(df+"img_kxky"), img_kxBE=$(df+"img_kxBE")
	strswitch(ctrlname)
		case "SetThetaCenter":
			if (cmpstr(waveunits(datawave,0),"theta")==0)
				theta_offset=-xc
	//			setscale/p x, dimoffset(datawave,0)-xc, dimdelta(datawave,0), waveunits(datawave,0), datawave
			elseif(cmpstr(waveunits(datawave,0),"kx")==0)
		  		theta_offset=-asin(xc/0.5124/sqrt(xc^2+zc^2+tc^2))*180/pi
//		  		setscale/p x, dimoffset(datawave,0)-xc, dimdelta(datawave,0), waveunits(datawave,0), datawave
		  	endif
		  	print "Theta Offset = ", theta_offset
		 	break
		case "SetBetaCenter":
			beta_offset=-asin(zc/0.5124/sqrt(xc^2+zc^2+tc^2))*180/pi
//			setscale/p z, dimoffset(datawave,2)-zc, dimdelta(datawave,2), waveunits(datawave,2), datawave
			print "Beta Offset = ", beta_offset
		 	break
	endswitch
	updatescales()
end

static function UpdateScales()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
//	wave datawave=$(df+"datawave"), img_kxky=$(df+"img_kxky"), img_kxBE=$(df+"img_kxBE"), img_kzBE=$(df+"img_kzBE"), prof_kz=$(df+"prof_kz")
//	setscale/p x, dimoffset(datawave,0), dimdelta(datawave,0), waveunits(datawave,0) img_kxBE
//	setscale/p x, dimoffset(datawave,0), dimdelta(datawave,0), waveunits(datawave,0) img_kxky
//	setscale/p y, dimoffset(datawave,1), dimdelta(datawave,1), waveunits(datawave,1) img_kxBE
//	setscale/p y, dimoffset(datawave,1), dimdelta(datawave,1), waveunits(datawave,1) img_kzBE	
//	setscale/p y, dimoffset(datawave,2), dimdelta(datawave,2), waveunits(datawave,2) img_kxky
//	setscale/p x, dimoffset(datawave,3), dimdelta(datawave,3), waveunits(datawave,3) img_kzBE	
//	setscale/p x, dimoffset(datawave,3), dimdelta(datawave,3), waveunits(datawave,3) prof_kz
end

static function ThetaDriftButton()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	string w
	nvar yp=$(df+"yp"), zp=$(df+"zp"), deg_pix
	nvar kx_off=$(df+"kx_off"), ky_off=$(df+"ky_off"), v0=$(df+"v0"), wk=$(df+"wk")
	nvar deg_pix=$(df+"deg_pix") 
	Prompt w, "Theta drift values",popup, "Theta drift wave;"+"none"+WaveList("!*_CT",";", "DIMS:1")+"create"
	DoPrompt "ky-kz plotter needs to have theta scaling", w
	if(v_flag==1)
	 	abort
	endif 
	nvar yp=$(df+"yp"), zp=$(df+"zp")
//	wave datawave=$(df+"datawave")
	wave hv_scale=$(df+"hv_scale")
	string/g $(df+"thetadriftwavename")
	svar driftw=$(df+"thetadriftwavename")
	driftw=w
//	make/o/n=(dimsize(datawave,0), dimsize(datawave,3)) $(df+"img_thetakz")
	wave img_thetakz=$(df+"img_thetakz")
//	setscale/p x, dimoffset(datawave,0), dimdelta(datawave,0), waveunits(datawave,0) img_thetakz
//	setscale/p y, dimoffset(datawave,3), dimdelta(datawave,3), waveunits(datawave,3) img_thetakz
//	img_thetakz=datawave[p][yp][zp][q]
//	make/o/n=(dimsize(datawave,3)) $(df+"ThetaDrift")	
	wave thetadrift=$(df+"ThetaDrift")
//	make/o/n=(dimsize(datawave,3)) $(df+"ThetaDrift_kz")
	wave thetadrift_kz=$(df+"thetadrift_kz")

	duplicate/o $(df+"CT") $(df+"img_thetakz_CT")
	wave img_thetakz_CT= $(df+"img_thetakz_CT")
	
	Display /W=(35,44,515,314)
	appendimage img_thetakz
	ModifyImage img_thetakz cindex= img_thetakz_CT
	controlbar 50
	modifygraph cbRGB=(16385,65535,65535)
	appendtograph thetadrift_kz vs thetadrift
	
	variable/g $(df+"kxDrift_kx"), $(df+"kxDrift_ky"),$(df+"kxDrift_kz"),$(df+"kxDrift_BE")
	nvar kx=$(df+"kxDrift_kx"), ky=$(df+"kxDrift_ky"),kz=$(df+"kxDrift_kz"),BE=$(df+"kxDrift_BE")
	nvar yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc"),wk=$(df+"wk"), v0=$(df+"v0")
	ky=zc;BE=yc;kz=tc
	
	setvariable kxD_kx title="kx", size={100,25}, value=kx, pos={5,2}
	setvariable kxD_ky title="ky", value=ky, size={100,25},limits={-inf,inf,0}, pos={115,2}
	setvariable kxD_BE title="BE", value=BE, size={100,25},limits={-inf,inf,0}, pos={225,2}
	setvariable kxD_wk title="wk", value=wk, size={100,25}, pos={5,25}
	setvariable kxD_v0 title="v0", value=v0, size={100,25}, pos={115,25}
	button  CalcThetaButton, title="calc theta",size={100,25},proc=kykz_ButtonCnt, pos={350,1}
	button UpdateImgButton, title="Update Img", size={100,25},proc=kykz_ButtonCnt, pos={470,1}	

	popupmenu popupTdrift, pos={350,30}, mode=45, popvalue=driftw, proc=kykz_GetDriftWave, value="none;"+WaveList("!*_CT",";", "DIMS:1")+"create new"
	
	Dowindow/C$(dfn+"ThetaDrift")
	execute  "ky_kzFunctions#CalcTheta()"
end

function kykz_GetDriftWave(ctrlName,popNum,popStr)
	string ctrlName
	variable popnum
	string popstr
	wave img_thetakz
	string dfn=selectstring(cmpstr(ctrlname,"popupTdrift"),winname(0,1)[0,strlen(winname(0,1))-11],winname(0,1)[0,strlen(winname(0,1))-10])
	string df="root:"+dfn+":"
	svar driftw=$(df+selectstring(cmpstr(ctrlname,"popupTdrift"),"thetadriftwavename","Betadriftwavename"))
 	driftw=popstr
	wave thetadrift=$(df+"thetadrift")
	wave betadrift=$(df+"betadrift")
	
	if (cmpstr(driftw, "none")==0)
		thetadrift=thetadrift
		betadrift=betadrift
		if(cmpstr(ctrlname,"popupTdrift")==0)
		 	execute  "ky_kzFunctions#CalcTheta()"
		elseif(cmpstr(ctrlname,"popupBdrift")==0)	
			execute  "ky_kzFunctions#CalcBeta()"
		endif
	elseif(cmpstr(driftw,"create new")==0)
		string newname
		prompt newname, "Name of drift wave"
		doprompt "", newname
		if(cmpstr(ctrlname,"popupTdrift")==0)	
			duplicate/o thetadrift, $("root:"+newname)
			wave driftwave=$("root:"+newname)
			execute  "ky_kzFunctions#CalcTheta()"
			execute  getwavesdatafolder(thetadrift,2)+"="+getwavesdatafolder(thetadrift,2)+"-"+getwavesdatafolder(driftwave,2)
	 		edit/k=0 
	 	elseif(cmpstr(ctrlname,"popupBdrift")==0)	
	 		duplicate/o betadrift, $("root:"+newname)
			wave driftwave=$("root:"+newname)
			execute  "ky_kzFunctions#Calcbeta()"
			execute  getwavesdatafolder(betadrift,2)+"="+getwavesdatafolder(betadrift,2)+"-"+getwavesdatafolder(driftwave,2)
	 		edit/k=0 
	 	else 
			wave driftwave=$("root:"+driftw)	
			if(cmpstr(ctrlname,"popupTdrift")==0)	
				execute  "ky_kzFunctions#CalcTheta()"
				execute getwavesdatafolder(thetadrift,2)+"="+getwavesdatafolder(thetadrift,2)+"-"+getwavesdatafolder(driftwave,2)
			elseif(cmpstr(ctrlname,"popupBdrift")==0)	
				execute  "ky_kzFunctions#Calcbeta()"
				execute  getwavesdatafolder(betadrift,2)+"="+getwavesdatafolder(betadrift,2)+"-"+getwavesdatafolder(driftwave,2)
			endif
		endif
	endif
	
end 

static Function CalcTheta()
	string win=winname(0,1)
	string dfn=win[0,strlen(win)-11]
	string df="root:"+dfn+":"
	nvar wk=$(df+"wk"), v0=$(df+"v0"), kz=$(df+"kxDrift_kz"), ky=$(df+"kxDrift_ky"),BE=$(df+"kxDrift_BE")
	nvar kx=$(df+"kxDrift_kx")
	wave thetadrift= $(df+"ThetaDrift")
	wave ThetaDrift_kz=$(df+"ThetaDrift_kz")
	Wave hv=$(df+"hv_scale")
	ThetaDrift=asin(kx/0.5124/sqrt(hv-BE-wk))*180/pi
	ThetaDrift_kz=sqrt(0.5214^2*(v0+hv-BE-wk)-(kx^2+ky^2))
	svar driftw=$(df+"Thetadriftwavename")
	wave driftwave=$("driftw")
	if (cmpstr(driftw,"none")==0)
		execute getwavesdatafolder(thetadrift,2)+"="+getwavesdatafolder(thetadrift,2)
	else
		wave driftwave=$("root:"+driftw)
		execute getwavesdatafolder(thetadrift,2)+"="+getwavesdatafolder(thetadrift,2)+"-"+getwavesdatafolder(driftwave,2)
	endif
End

static function UpDateimg_thetkz()
	string win=winname(0,1)
	string dfn=win[0,strlen(win)-11]
	string df="root:"+dfn+":"
//	wave img_thetakz=$(df+"img_thetakz")
	wave datawave=$(df+"datawave")
	nvar yp=$(df+"yp"), zp=$(df+"zp"), yc=$(df+"yc"), zc=$(df+"zc")
//	img_thetakz[][]=datawave[p][yp][zp][q] 
	nvar kx=$(df+"kxDrift_kx"), ky=$(df+"kxDrift_ky"),kz=$(df+"kxDrift_kz"),BE=$(df+"kxDrift_BE")
	BE=yc; ky=zc
	setvariable kxD_BE value=BE
	setvariable kxD_ky value=ky
end

static function kyDriftButton()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
//	wave datawave=$(df+"datawave")
	
	string w
	Prompt w, "Beta drift values",popup, "ky Drift wave;"+"none;"+WaveList("!*_CT",";", "DIMS:1")+"create"
	DoPrompt "ky-kz plotter needs to have theta scaling", w
	if(v_flag==1)
	 	abort
	endif 
	if(cmpstr(w,"create")==0)
		string name
		prompt name, "Name of beta drift wave"
		doprompt "", name
//		make/o/n=(dimsize(datawave,3)) $(name)
	endif
	string/g $(df+"Betadriftwavename")
	svar driftw=$(df+"Betadriftwavename")
	driftw=w
//	make/o/n=(dimsize(datawave,2),dimsize(datawave,3)) $(df+"img_Betakz")
	wave img_Betakz=$(df+"img_Betakz")
//	setscale/p x, dimoffset(datawave,2), dimdelta(datawave,2), waveunits(datawave,2) img_betakz
//	setscale/p y, dimoffset(datawave,3), dimdelta(datawave,3), waveunits(datawave,3) img_betakz
//	make/o/n=(dimsize(datawave,3)) $(df+"Betadrift")
	wave Betadrift=$(df+"Betadrift")
//	make/o/n=(dimsize(datawave,3)) $(df+"Betadrift_kz")
	wave betadrift_kz=$(df+"betadrift_kz")
//	betadrift_kz=dimoffset(datawave,3)+dimdelta(datawave,3)*p
	nvar xp=$(df+"xp"), yp=$(df+"yp"), xc=$(df+"xc"), yc=$(df+"yc")
//	img_betakz=datawave[xp][yp][p][q]
	
	duplicate/o $(df+"CT") $(df+"img_betakz_CT")
	wave img_betakz_CT= $(df+"img_betakz_CT")
	
	Display /W=(35,44,515,314)
	 appendimage img_betakz
	ModifyImage img_betakz cindex= img_thetakz_CT
	controlbar 50
	modifygraph cbRGB=(16385,65535,65535)
	appendtograph betadrift_kz vs betadrift

	variable/g $(df+"kyDrift_kx"), $(df+"kyDrift_ky"),$(df+"kyDrift_kz"),$(df+"kyDrift_BE")
	nvar kx=$(df+"kyDrift_kx"), ky=$(df+"kyDrift_ky"),kz=$(df+"kyDrift_kz"),BE=$(df+"kyDrift_BE")
	nvar yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc"),wk=$(df+"wk"), v0=$(df+"v0"), tp=$(df+"tp")
//	If(cmpstr(waveunits(datawave,0),"theta")==0)
//		wave hv_scale=$(df+"hv_scale") 
//		kx=sin(xc*pi/180)*0.5124*sqrt(hv_scale[round(tp)]-yc-wk)
//	else
//		kx=xc
//	endif
	BE=yc;kz=tc	

	setvariable kyD_kx title="kx", size={100,25}, value=kx,limits={-inf,inf,0}, pos={5,2}
	setvariable kyD_ky title="ky", value=ky, size={100,25}, pos={115,2}
	setvariable kyD_BE title="BE", value=BE, size={100,25},limits={-inf,inf,0}, pos={225,2}
	setvariable kyD_wk title="wk", value=wk, size={100,25}, pos={5,25}
	setvariable kyD_v0 title="v0", value=v0, size={100,25}, pos={115,25}
	button  CalcBetaButton, title="calc Beta",size={100,25},proc=kykz_ButtonCnt, pos={350,1}
	button UpdateImgButtonky, title="Update Img", size={100,25},proc=kykz_ButtonCnt, pos={470,1}	
	popupmenu popupBdrift, pos={350,30}, mode=45, popvalue=driftw, proc=kykz_GetDriftWave, value="none;"+WaveList("!*_CT",";", "DIMS:1")+"create"
	
	Dowindow/C$(dfn+"BetaDrift")
	execute  "ky_kzFunctions#CalcBeta()"
	
end

static Function CalcBeta()
	string win=winname(0,1)
	string dfn=win[0,strlen(win)-10]
	string df="root:"+dfn+":"
	nvar wk=$(df+"wk"), v0=$(df+"v0"), kz=$(df+"kyDrift_kz"), ky=$(df+"kyDrift_ky"),BE=$(df+"kyDrift_BE"), kx=$(df+"kyDrift_kx")
	wave betadrift= $(df+"BetaDrift")
	wave betaDrift_kz=$(df+"BetaDrift_kz")
	svar driftw=$(df+"Betadriftwavename")
	wave driftwave=$(driftw)
//	print getwavesdatafolder(driftwave,2)
	Wave hv=$(df+"hv_scale")
	betaDrift=sin(asin(ky/0.5124/sqrt(hv-BE-wk)/cos(asin(kx/0.5124/sqrt(hv-BE-wk))))+driftwave*pi/180)*0.5124*sqrt(hv-BE-wk)*cos(asin(kx/0.5124/sqrt(hv-BE-wk)))
	betaDrift_kz=sqrt(0.5214^2*(v0+hv-BE-wk)-(kx^2+ky^2))
	if (cmpstr(driftw,"none")==0)
		execute getwavesdatafolder(betadrift,2)+"="+getwavesdatafolder(betadrift,2)
	else
		execute getwavesdatafolder(betadrift,2)+"-="+getwavesdatafolder(driftwave,2)
	endif
End

static function UpDateimg_betakz()
	string win=winname(0,1)
	string dfn=win[0,strlen(win)-10]
	string df="root:"+dfn+":"
	wave img_betakz=$(df+"img_betakz")
//	wave datawave=$(df+"datawave")
	nvar xp=$(df+"xp"), yp=$(df+"yp"), xc=$(df+"xc"), yc=$(df+"yc"), tc=$(df+"tc"), tp=$(df+"tp"), wk=$(df+"wk")
//	img_betakz[][]=datawave[xp][yp][p][q] 
	nvar kx=$(df+"kxDrift_kx"), ky=$(df+"kxDrift_ky"),kz=$(df+"kxDrift_kz"),BE=$(df+"kxDrift_BE")
	BE=yc; kz=tc	
//	If(cmpstr(waveunits(datawave,0),"theta")==0)
//		wave hv_scale=$(df+"hv_scale") 
//		kx=sin(xc*pi/180)*0.5124*sqrt(hv_scale[round(tp)]-yc-wk)
//	else
//		kx=xc
//	endif
	BE=yc;
	setvariable kyD_BE value=BE
	setvariable kyD_kx value=kx
end

 function updateCalcv0(ctrlname)
 	string ctrlname
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	nvar wk=v0_wk, v0=v0_v0, BE=v0_BE
	nvar hv1p=v0_hv1p,hv1=v0_hv1,hv2p=v0_hv2,hv2=v0_hv2
	nvar kz1=v0_kz1,kz2=v0_kz2,kzdiff=v0_kzdiff, kx=v0_kx, ky=v0_ky
	wave kz_scale
	wave hv_scale
	kz_scale=sqrt(0.5124^2*(v0+hv_scale-BE-wk)-(kx^2+ky^2))
	hv1=hv_scale[hv1p]
	hv2=hv_scale[hv2p]
	kz1=kz_scale[hv1p]
	kz2=kz_scale[hv2p]
	kzdiff=abs(kz1-kz2)
end


//////////////Inner Potential Calculator///////////
Function SetUpCalcv0()
	string w
	variable work,V,Benergy,kyv, kxv
	Prompt w, "Name of hv wave", popup, "---1D---;"+WaveList("!*_CT",";", "DIMS:1")
	prompt v, "Inner Potential"
	prompt work, "Sample Work Function"
	prompt Benergy, "Binding Energy"
	prompt kxv, "kx"
	prompt kyv, "ky"
	Doprompt "Inner Potential Calculator", w//,v,work,Benergy,kxv,kyv
	wave hv_scale=$(w)
	duplicate/o hv_scale, kz_scale 
	variable/g v0_wk, v0_v0, v0_BE, v0_kx, v0_ky
	variable/g v0_hv1p,v0_hv1,v0_hv2p,v0_hv2,v0_kz1,v0_kz2,v0_kzdiff
	setformula kz_scale, "sqrt(0.5124^2*(v0_v0+"+w+"-v0_BE-v0_wk)-(v0_kx^2+v0_ky^2))"
	setformula v0_hv1, "hv_scale[v0_hv1p]"
	setformula v0_hv2, "hv_scale[v0_hv2p]"
	setformula v0_kz1, "kz_scale[v0_hv1p]"
	setformula v0_kz2, "kz_scale[v0_hv2p]"
	setformula v0_kzdiff, "abs(v0_kz1-v0_kz2)"
	Display /W=(46,135,442,234) 
	DoWindow/c/t v0Calculator, "v0Calculator["+w+"]"
	controlbar 100
	modifygraph cbRGB=(16385,65535,65535)
	setvariable varhv1p, value=v0_hv1p, title="hv1 pnt",size={100,15}, pos={5,2}
	setvariable varhv2p, value=v0_hv2p, title="hv2 pnt",size={100,15}, pos={5,25}
	setvariable varkx, value=v0_kx, title="kx",size={100,15}, pos={5,50}
	setvariable varky, value=v0_ky, title="ky",size={100,15}, pos={5,75}
	setvariable varBE, value=v0_BE, title="BE",size={100,15}, pos={125,50}
	setvariable varv0, value=v0_v0, title="v0",size={100,15}, pos={125,2}
	setvariable varwk, value=v0_wk, title="wk",size={100,15}, pos={125,25}
	setvariable varkz1, value=v0_kz1, title="kz1",size={100,15}, pos={250,2}
	setvariable varkz2, value=v0_kz2, title="kz2",size={100,15}, pos={250,25}
	setvariable varkzdiff, value=v0_kzdiff, title="kz2",size={100,15}, pos={250,50}
end


Function SetUpkspaceCalc()
	If(datafolderexists("KspaceCalc")==0)
		newdatafolder root:KspaceCalc
	endif
	string df="root:KspaceCalc:" 
	variable/g $(df+"v0"), $(df+"wk"), $(df+"kx"), $(df+"ky"), $(df+"kz"), $(df+"Theta"), $(df+"Beta1"), $(df+"hvA"), $(df+"hveV"),$(df+"BE")
	variable/g $(df+"Eout"), $(df+"kin")
	nvar v0=$(df+"v0"), wk=$(df+"wk"), kx=$(df+"kx"), ky=$(df+"ky"), kz=$(df+"kz"), theta=$(df+"Theta"), beta1=$(df+"Beta1")
	nvar hvA=$(df+"hvA"), hveV=$(df+"hveV"), BE=$(df+"BE")
	NewPanel/N=KspaceCalc
	ModifyPanel cbRGB=(32768,65535,65535)
	SetVariable varhvA, value=hvA, title="Photon Energy (-1)", size={170, 15}, pos={10,10}, proc=ky_kzFunctions#kspaceCalc,limits={-inf,inf,0.05}
	SetVariable varhveV, value=hveV, title="Photon Energy (eV)", size={170, 15}, pos={10,30},proc=ky_kzFunctions#kspaceCalc
	SetVariable varwk, value=wk, title="Work Function", size={170, 15}, pos={10,50}, proc=ky_kzFunctions#kspaceCalc

	SetVariable varBE, value=BE, title="Binding Energy (above EF is negative)", size={250, 15}, pos={10,80}, proc=ky_kzFunctions#kspaceCalc,limits={-inf,inf,0.10}
	
	SetVariable varTheta, value=Theta, title="Theta", size={100, 15}, pos={10,110}, proc=ky_kzFunctions#kspaceCalc
	SetVariable varkx, value=kx, title="kx (-1)", size={100, 15}, pos={170,110}, proc=ky_kzFunctions#kspaceCalc,limits={-inf,inf,0.05}
	SetVariable varBeta, value=Beta1, title="Beta", size={100, 15}, pos={10,130}	, proc=ky_kzFunctions#kspaceCalc
	SetVariable varky, value=ky, title="ky (-1)", size={100, 15}, pos={170,130}, proc=ky_kzFunctions#kspaceCalc,limits={-inf,inf,0.05}
	SetVariable varv0, value=v0, title="Inner Potential", size={150, 15}, pos={10,160}, proc=ky_kzFunctions#kspaceCalc,limits={-0,inf,1}
	SetVariable varkz, value=kz, title="kz (-1)", size={100, 15}, pos={170,160}, proc=ky_kzFunctions#kspaceCalc

	execute df+"Eout="+df+"hveV-"+df+"BE-"+df+"wk"
	execute df+"kin=sqrt("+df+"kx^2+"+df+"ky^2+"+df+"kz^2)"
	
End

static function kspaceCalc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	string df="root:KspaceCalc:" 
	nvar v0=$(df+"v0"), wk=$(df+"wk"), kx=$(df+"kx"), ky=$(df+"ky"), kz=$(df+"kz"), theta=$(df+"Theta"), beta1=$(df+"Beta1")
	nvar hvA=$(df+"hvA"), hveV=$(df+"hveV"), BE=$(df+"BE"), Eout=$(df+"Eout"), kin=$(df+"kin")
	variable c=0.5124
	variable kout=c*sqrt(Eout)
	variable Ein=kin^2/c/c
	if(cmpstr(ctrlName, "varkz")==0)
		hveV=(kx^2+ky^2+kz^2)/c^2-v0+BE+wk
		hvA=c*sqrt(hveV)
		kout=c*sqrt((kx^2+ky^2+kz^2)/c^2-v0)
		Theta=180/pi*asin(kx/kout)
		Beta1=asin(ky/kout/cos(Theta/180*pi))*180/pi
	else
		strswitch(ctrlName)
		case "varhvA":
			hveV=hvA^2/c
			Eout=hvEV-BE-Wk
			break
		case "varhveV":
			hvA=c*sqrt(hveV)
			Eout=hvEV-BE-Wk
			break
		case "varTheta":
			kx=sin(Theta*pi/180)/kout
			break
		case "varkx":
			Theta=180/pi*asin(kx/kout)
			break
		case "varBeta":
			ky=kout*cos(Theta/180*pi)*sin(Beta1/180*pi)
			break
		case "varky":
			Beta1=asin(ky/kout/cos(Theta/180*pi))*180/pi
			break
		endswitch
			Eout=hvEV-BE-wk
		kz=sqrt(c^2*(Eout+v0)-kx^2-ky^2)
	endif
end