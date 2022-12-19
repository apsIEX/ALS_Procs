#pragma rtGlobals=1		// Use modern global access method.
#pragma ModuleName=ky_kzFunctions

//May 8 2008 version 1.13 --JLM 
//working version, need to fix offset cursor axis, include v0calulator
//May 11 2008 -- fixed interp 
//May 16 2008 -- added betadrift correction

Menu "kspace"
	Submenu "ky_kz"
		"ky-kz Loader" ,Loadkykz4d
		"ky-kz Plotter", Newkykz4d()	
		"ky_kz at single ky", Newkykz3d()
		"Convert Theta to kx, single hv", ConvertTheta2k()
		"Convert pixels to theta, single hv", ConverPix2Theta()
		"v0 calculator",SetUpCalcv0()
	end
end

function ConvertTheta2k()
	setdatafolder root:
	string w
	variable hv, wk
	prompt w, "Image Array", popup, "---2D---;"+WaveList("!*_CT",";", "DIMS:2")+"---3D---;"+WaveList("!*_CT",";", "DIMS:3")
	prompt hv, "Photon energy"
	prompt wk, "sample work function"
	doprompt "Select ky-kz wave", w, hv, wk
	if (v_flag==1)
		abort
	endif
	wave ww=$w
	duplicate/o ww $(w+"_k")
	wave kwv=$(w+"_k")
	variable ki=0.5124*sqrt(hv-wk)*sin(dimoffset(ww,0)*pi/180)
	variable kf=0.5124*sqrt(hv-wk)*sin((dimoffset(ww,0)+dimdelta(ww,0)*dimsize(ww,0))*pi/180)
	setscale/i x, ki,kf, "kx", kwv
	if(wavedims(ww)==2)
		kwv=interp2d(ww, asin(x/0.5124/sqrt(hv-wk-y))*180/pi,y)
	elseif(wavedims(ww)==3)
		kwv=interp3d(ww, asin(x/0.5124/sqrt(hv-wk-y))*180/pi,y,z)
	endif
end

function ConverPix2Theta()
	setdatafolder root:
	string w, angmode 
	variable ang, thetaoffset
	prompt w, "Image Array", popup, "---2D---;"+WaveList("!*_CT",";", "DIMS:2")+"---3D---;"+WaveList("!*_CT",";", "DIMS:3")
	prompt angmode, "lens mode", popup, "30;14;7"
	prompt thetaoffset, "theta offset"
	doprompt "", w,angmode, thetaoffset
	variable deg_pix=str2num(angmode)/7*0.0102
	wave ww=$(w)
//	duplicate/o ww $(w+"backup")
	variable thetadimoffset=abs(dimdelta(ww,0)*(dimsize(ww,0)-1)*deg_pix/2)
	setscale/p x, thetaoffset-thetadimoffset, dimdelta(ww,0)*deg_pix, "theta", ww
end

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
	
Function Newkykz3d()
	string w
	prompt w, "Image Array", popup, "---3D---;"+WaveList("!*_CT",";", "DIMS:3")
	doprompt "", w
	if(v_flag==1)
		abort
	endif
	string dfn=uniquename("Kz_plotter", 11, 0)
	newdatafolder/o $dfn
	
	MakeKzVar(dfn,w)
	GetScanInfo(dfn)
	
end	
	
	
Function Newkykz4d()
	string w
	prompt w, "Image Array", popup, "---4D---;"+WaveList("!*_CT",";", "DIMS:4")
	doprompt "", w
	if(v_flag==1)
		abort
	endif
	string dfn=uniquename("Kz_plotter", 11, 0)
	newdatafolder/o $dfn
	MakeKzVar(dfn,w)
	GetScanInfo(dfn)
	MakeDataWave4d(dfn,w)
	setupKzplot(dfn)
	setupTabkykz(dfn)

end
	
static Function  MakeKzVar(dfn,w)	
	string dfn, w
	string df="root:"+dfn+":"
	variable/g $(df+"kx_check")
	string/g $(df+"dname")		
	svar dname=$(df+"dname")
	dname=w
	//kykz parameter
	variable/g $(df+"kx_off"),$(df+"v0"), $(df+"wk"), $(df+"ky_off")
	variable/g  $(df+"theta_offset")
	variable/g $(df+"x0"),$(df+"xd"),$(df+"xn")
	variable/g $(df+"y0"),$(df+"yd"),$(df+"yn")
	variable/g $(df+"z0"),$(df+"zd"),$(df+"zn")
	variable/g $(df+"t0"),$(df+"td"),$(df+"tn")
	string/g $(df+"xu"),$(df+"yu"),$(df+"zu"),$(df+"tu")
	//ky_kz  plotter var	
	variable/g  $(df+"xp"),$(df+"yp"),$(df+"zp"),$(df+"tp") //curser coord, pnt units
	variable/g $(df+"xc"),$(df+"yc"),$(df+"zc"),$(df+"tc") //curser coord, real units
	make/n=0 $(df+"img_kxBE"), $(df+"img_kzBE"), $(df+"img_kxky"), $(df+"prof_kz")
	//correction waves 
	variable/g $(df+"BE_check")=0, $(df+"kx_check")=1
	variable/g $(df+"ThetaDrift_check")=0, $(df+"BetaDrift_check")=0
	variable/g $(df+"theta_offset")=0, $(df+"beta_offset")=0, $(df+"BE_offset")=0
	make/n=0 $(df+"hv_scale")=0, $(df+"theta_drift"), $(df+"beta_drift"), $(df+"BE_drift")
	// color table
	variable/g $(df+"gamma")=1
	make/n=256/o $(df+"pmap")
	variable/g $(df+"whichCT")=0, $(df+"whichCTh")=0,$(df+"whichCTv")=0
	variable/g $(df+"invertCT")=0
	//input folder
	newdatafolder $(df+"Inputs")
	variable/g $(df+"Inputs:kx_off"), $(df+"Inputs:ky_off"), $(df+"Inputs:v0"), $(df+"Inputs:wk")	
end	

static Function GetScanInfo(dfn)
	string dfn
	string df="root:"+dfn+":"
	nvar kx_off=$(df+"kx_off"), ky_off=$(df+"ky_off"), v0=$(df+"v0"), wk=$(df+"wk")
	variable kx,ky,v,w
	string load
	string/g $(df+"scaleType")
	prompt kx, "kx (A-1)"
	prompt ky, "ky center (A-1)"
	prompt v, "inner potential (eV)"
	prompt w, "sample work function (eV)"
	prompt load, "x-scaling", popup, "kx scaling;theta scaling"
	doprompt "ky-kz scan input parameters", kx, ky, v, w, load
	kx_off=kx; ky_off=ky; v0=v; wk=w
	nvar kx_in=$(df+"Inputs:kx_off"), ky_in=$(df+"Inputs:ky_off"),v0_in=$(df+"Inputs:v0"), wk_in=$(df+"Inputs:wk")
	kx_in=kx; ky_in=ky; v0_in=v; wk_in=w
	svar type=$(df+"scaleType")
	Type=selectstring(cmpstr(load,"kx scaling"),"kx", "theta")
End

static Function Makedatawave4d(dfn,w)
	string dfn, w
	string df="root:"+dfn+":"
	nvar kx_off=$(df+"kx_off"), ky_off=$(df+"ky_off"), v0=$(df+"v0"), wk=$(df+"wk")
	nvar deg_pix=$(df+"deg_pix")
	duplicate/o $w $(df+"datawave")
	wave wv=$w
	
	//get angle scaling
	if(cmpstr(waveunits(wv,0), "pixel")==0)
		string wvnote=note(wv)
		variable pos=strsearch(wvnote,"Angular",0)
		if(pos>0)
			variable ang=str2num(wvnote[pos+7,pos+9])
		else
			 ang=7
		endif
		variable/g $(df+"deg_pix")=-ang/7*0.0102	
	else
		variable/g $(df+"deg_pix")=1
	endif

	//Make hv_scale
	wave hv_scale=$(df+"hv_scale")
	redimension/n=(selectnumber(wavedims(wv)==3, dimsize(wv,3), dimsize(wv,2))) hv_scale	
	duplicate/o hv_scale kz_temp
	kz_temp=dimoffset(wv,3)+dimdelta(wv,3)*p
	hv_scale=1/0.5124^2*(kx_off^2+ky_off^2+kz_temp^2)-v0+wk
	killwaves kz_temp

	//Redim corretion waves
	wave theta_drift=$(df+"theta_drift"), 	beta_drift=$(df+"beta_drift"), BE_drift=$(df+"BE_drift")
	redimension/n=(selectnumber(wavedims(wv)==3, dimsize(wv,3), dimsize(wv,2))) theta_drift
	redimension/n=(selectnumber(wavedims(wv)==3, dimsize(wv,3), dimsize(wv,2))) beta_drift
	redimension/n=(selectnumber(wavedims(wv)==3, dimsize(wv,3), dimsize(wv,2))) BE_drift

	svar scaleType=$(df+"scaleType")
	
	Calc_datawave(df,scaleType, 4,0)
	killwaves/z tmp, tmporg	
end	

static function Calc_datawave(df,kxORtheta, vol3OR4,run)
	string df, kxORtheta
	variable vol3OR4, run		//run=0 overwrites; run=1 duplicates datawave to datawave_back runs export and
	
	svar dname=$(df+"dname")
	wave datawave=$(df+"datawave")
	wave org=$("root:"+dname)
	nvar kx_off=$(df+"kx_off"), ky_off=$(df+"ky_off"), v0=$(df+"v0"), wk=$(df+"wk")
	nvar tp=$(df+"tp")
	nvar deg_pix=$(df+"deg_pix")
	wave theta_drift=$(df+"theta_drift"), 	beta_drift=$(df+"beta_drift"), BE_drift=$(df+"BE_drift")
	nvar theta_offset=$(df+"theta_offset"), beta_offset=$(df+"beta_offset"), BE_offset=$(df+"BE_offset")
	nvar BE_check=$(df+"BE_check"), ThetaDrift_check=$(df+"ThetaDrift_check"), BetaDrift_check=$(df+"BetaDrift_check")
	wave BE_drift=$(df+"BE_drift")

	variable drift=thetaDrift_check+betaDrift_check	
	string driftwave_theta, driftwave_beta
	Prompt driftwave_theta, "path of theta drift wave"
	Prompt driftwave_beta, "path of beta drift wave"
	switch(drift)
		case 2:
			Doprompt "", driftwave_theta, driftwave_beta
			wave theta_drift=$driftwave_theta
			wave beta_drift=$driftwave_beta
			break
		case 1:
			if(ThetaDrift_check==1)
				Doprompt "", driftwave_theta
				wave theta_drift=$driftwave_theta
				beta_drift=beta_offset		
			elseif(BetaDrift_check==1)
				Doprompt "", driftwave_beta
				wave beta_drift=$driftwave_beta
				theta_drift=theta_offset
			endif
			break
		case 0:
			beta_drift=beta_offset
			theta_drift=theta_offset
			break
	endswitch
	
	
	wave hv_scale=$(df+"hv_scale")
	variable i=selectnumber(vol3or4==4,tp,selectnumber(dimoffset(org,3)>(dimoffset(org,3)+dimdelta(org,3)*dimsize(org,3)),0,dimsize(org,3)))
 
 	variable theta_center, kout, theta_dimoffset, BE=0, theta_i, theta_f, beta_center
	theta_dimoffset=abs(dimdelta(org,0)*(dimsize(org,0)-1)*deg_pix/2)
	variable theta1=asin(kx_off/0.5124/sqrt(hv_scale[i]-wk-BE))*180/pi
	variable theta2=asin(kx_off/0.5124/sqrt(hv_scale[dimsize(org,3)-1]-wk-BE))*180/pi
	theta_i=selectnumber(theta1<theta2,theta2,theta1)+theta_drift[i]-theta_dimoffset
	theta_f=selectnumber(theta1>theta2,theta2,theta1)+theta_drift[i]+theta_dimoffset

	if(run==1)
		duplicate/o datawave $(df+"datawave_")
	endif
	
	duplicate/o org $(df+"datawave")
	wave datawave=$(df+"datawave")
	
	nvar kx_off=$(df+"kx_off"), ky_offset=$(df+"ky_off")
	variable kx=kx_off, ky=ky_off
		
	//for ky scanning
	make/n=(dimsize(org,0),dimsize(org,1),dimsize(org,2))/o $(df+"tmporg")
	wave tmporg=$(df+"tmporg")
	copyscales org tmporg
	duplicate/o tmporg $(df+"tmp")
	wave tmp=$(df+"tmp")
	duplicate/o beta_drift $(df+"ky_drift")
	wave ky_drift=$(df+"ky_drift")
	ky_drift=0.5124*sqrt(hv_scale[p]-wk-BE)*sin(beta_drift[p]*pi/180)

	//theta scaling
	if(cmpstr(kxORtheta, "theta")==0)
		i=selectnumber(vol3OR4==3,0,tp)
		duplicate/o org, $(df+"datawave")
		wave datawave=$(df+"datawave")
		redimension/n=(abs((theta_f-theta_i)/deg_pix/dimdelta(org,0)),-1,-1,-1) datawave
		setscale/i x, theta_i, theta_f, "theta", datawave
		datawave=nan
variable kz
		do
			tmporg=org[p][q][r][i]	
			wavestats/q tmporg
			tmporg/=v_avg			
			setscale/p x dimoffset(org,0), dimdelta(org,0), waveunits(org,0) tmporg	
			if(vol3or4==4)
			//		pixels=(theta-theta_center+theta_dimoffset)/deg_pix + dimoffset(org,0)
				if(BE_check==1)
					datawave[][][][i]=interp3d(tmporg,(x-asin(kx_off/0.5124/sqrt(hv_scale[i]-y-wk))*180/pi-theta_drift[i]+theta_dimoffset)/deg_pix+dimoffset(org,0), y+BE_drift[i],0.5124*sqrt(hv_scale[i]-y-wk)*cos(theta_center*pi/180)*sin(asin(z/0.5124/sqrt(hv_scale[i]-y-wk)+beta_drift[i]*pi/180)))
				else
					datawave[][][][i]=interp3d(tmporg,(x-asin(kx_off/0.5124/sqrt(hv_scale[i]-y-wk))*180/pi-theta_drift[i]+theta_dimoffset)/deg_pix+dimoffset(org,0), y,0.5124*sqrt(hv_scale[i]-y-wk)*cos(theta_center*pi/180)*sin(asin(z/0.5124/sqrt(hv_scale[i]-y-wk)+beta_drift[i]*pi/180)))
				endif
			endif
	 	i+=1
	 	while(i<selectnumber(vol3OR4==3,dimsize(org,3),0))
 	
	// kx scaling
	elseif(cmpstr(kxORtheta, "kx")==0)
		i=selectnumber(dimoffset(org,3)>dimdelta(org,3)*dimsize(org,3),0, dimsize(org,3))
		kout=0.5124*sqrt(hv_scale[i]-wk-BE)
		theta_center=asin(kx_off/0.5124/sqrt(hv_scale[i]-wk-BE))*180/pi-theta_drift[i]
		variable kx_i=0.5124*sqrt(hv_scale[i]-wk-BE)*sin(theta_i*pi/180)
		variable kx_f=0.5124*sqrt(hv_scale[dimsize(org,3)-1]-wk-BE)*sin(theta_f*pi/180)
		make/o/n=(dimsize(org,0), dimsize(org,1), dimsize(org,2), dimsize(org,3)) $(df+"datawave")
		wave datawave=$(df+"datawave")
		setscale/i  x, kx_i,kx_f, "kx", datawave
		setscale/p y, dimoffset(org,1), dimdelta(org,1), waveunits(org,1) datawave
		setscale/p z, dimoffset(org,2), dimdelta(org,2), waveunits(org,2) datawave
		setscale/p t, dimoffset(org,3), dimdelta(org,3), waveunits(org,3) datawave
		make/o/n=(dimsize(org,0),dimsize(org,2), dimsize(org,3)) $(df+"tmporg")
		wave tmporg=$(df+"tmporg")
		setscale/p x, dimoffset(org,0),  dimdelta(org,0)*deg_pix, "theta", tmporg
		setscale/p y, dimoffset(org,2), dimdelta(org,2), waveunits(org,2), tmporg
		setscale/p z, dimoffset(org,3), dimdelta(org,3), waveunits(org,3) tmporg
		make/o/n=(dimsize(org,0),dimsize(org,2), dimsize(org,3)) $(df+"tmp")
		wave tmp=$(df+"tmp")
		setscale/i x, kx_i, kx_f, "kx", tmp
		setscale/p y, dimoffset(org,2), dimdelta(org,2), waveunits(org,2), tmp
		setscale/p z, dimoffset(org,3), dimdelta(org,3), waveunits(org,3) tmp		
		i=selectnumber(vol3OR4==3,0,tp)
		make/o/n=(dimsize(tmp,2)) $(df+"hv_scaleInterp"), $(df+"BE_scaleInterp"), $(df+"Theta_driftInterp"), $(df+"Beta_driftInterp")
		wave hv_Interp=$(df+"hv_scaleInterp")
		setscale/p x, dimoffset(tmp,2), dimdelta(tmp,2), waveunits(tmp,2) hv_Interp
		wave BE_Interp=$(df+"BE_scaleInterp")
		setscale/p x, dimoffset(tmp,2), dimdelta(tmp,2), waveunits(tmp,2) BE_Interp
		wave Theta_Interp=$(df+"Theta_driftInterp")
		setscale/p x, dimoffset(tmp,2), dimdelta(tmp,2), waveunits(tmp,2) Theta_Interp
		wave Beta_Interp=$(df+"Beta_driftInterp")
		setscale/p x, dimoffset(tmp,2), dimdelta(tmp,2), waveunits(tmp,2) Beta_Interp
				
		Do
			tmporg=org[p][i][q][r]
			BE=dimoffset(org,1)+dimdelta(org,1)*i
			//going from tmporg(pixels,ky,kz) to drift corrected tmp1(theta,ky,kz) 
			duplicate/o tmporg $(df+"tmp1")
			wave tmp1=$(df+"tmp1")
			redimension/n=(abs((theta_f-theta_i)/deg_pix/dimdelta(org,0)),-1,-1) tmp1
			setscale/i x, theta_i, theta_f, "theta", tmp1
			tmp1=interp3d(tmporg,(x-asin(kx_off/0.5124/sqrt(hv_scale[r]-BE-wk))*180/pi-theta_drift[r]+theta_dimoffset)/deg_pix+dimoffset(org,0),y,z) 
			duplicate/o tmp1 tmporg
			tmporg=interp3d(tmp1,x,0.5124*sqrt(hv_scale[r]-BE-wk)*cos(asin(kx_off/0.5124/sqrt(hv_scale[z]-wk-BE))*180/pi+theta_drift[z])*sin(asin(y/0.5124/sqrt(hv_scale[r]-BE-wk)/cos(x*pi/180))-beta_drift[r]*pi/180),z)
			//going from tmp1(theta,ky,kz) to tmp(kx,ky,kz)
			tmp=interp3d(tmp1,asin(x/sqrt(x^2+y^2+z^2-0.5124^2*(v0+BE)))*180/pi,y,sqrt(x^2+y^2+z^2-(kx^2+ky^2)))
			
			//ky=ky_off*cos(theta)/cos(theta_center)
			//0.5124*sqrt(hv_scale[i]-BE-wk)*cos(asin(kx_off/0.5124/sqrt(hv_scale[r]-wk-BE))*180/pi+theta_drift[r]*pi/180)*sin(asin(z/0.5124/sqrt(hv_scale[r]-BE-wk)+beta_drift[r]*pi/180))
			//kout=sqrt(v0*0.5124^2+kx^2+ky^2+kz^2)
			//sin(Theta)=kx/kout
			//sin(Beta)=ky/kout/cos(Theta)
			//kz=sqrt(kx^2+ky^2+kz^2-(kx_off^2+ky_off^2-0.1524^2*BE))
//		theta=asin(x/sqrt(x^2+y^2+z^2-0.5124^2*(v0+BE)))*180/pi	
//		theta_center=asin(kx_off/0.5124/sqrt(hv_scale[z]-wk-BE))*180/pi+theta_drift[z]
//		pixels=(theta-theta_center+theta_dimoffset)/deg_pix + dimoffset(org,0)
			
	 		datawave[][i][][]=tmp(x)(z)(t)
	 	i+=1
	 	while(i<selectnumber(vol3OR4==3,dimsize(org,1),0))
			
	endif
end

static Function setupKzplot(dfn)
	string dfn
	string df="root:"+dfn+":"
	silent 1; pauseupdate
	setdatafolder root:
	
	
	nvar x0=$(df+"x0"), xd=$(df+"xd"), xn=$(df+"xn")
	nvar y0=$(df+"y0"), yd=$(df+"yd"), yn=$(df+"yn") 
	nvar z0=$(df+"z0"), zd=$(df+"zd"), zn=$(df+"zn") 
	nvar t0=$(df+"t0"), td=$(df+"td"), tn=$(df+"tn")
	svar xu=$(df+"xu"),yu=$(df+"yu"),zu=$(df+"zu"),tu=$(df+"tu")
	nvar v0=$(df+"v0"), wk=$(df+"wk"), kx_off=$(df+"kx_off"), ky_off=$(df+"ky_off")
	nvar deg_pix=$(df+"deg_pix")
	nvar kx_check=$(df+"kx_check")
	
	svar dname=$(df+"dname")
	wave ww=$(df+"datawave")
	
	//input vals
	x0=dimoffset(ww,0); xd=dimdelta(ww,0); xn=dimsize(ww,0)
	y0=dimoffset(ww,1); yd=dimdelta(ww,1); yn=dimsize(ww,1)
	z0=dimoffset(ww,2); zd=dimdelta(ww,2); zn=dimsize(ww,2)
	t0=dimoffset(ww,3); td=dimdelta(ww,3); tn=dimsize(ww,3)
	
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
	make/o/n=(xn,yn) $(df+"img_kxBE")
	wave img_kxBE=$(df+"img_kxBE");	setscale/p x, x0,xd,xu,img_kxBE; 	setscale/p y,y0,yd,yu,img_kxBE
	img_kxBE[][]=ww[p][q][zn/2][tn/2]
	
	make/o/n=(tn,yn) $(df+"img_kzBE")
	wave img_kzBE=$(df+"img_kzBE");	setscale/p x, t0,td,tu,img_kzBE; 	setscale/p y,y0,yd,yu,img_kzBE
	img_kzBE[][]=ww[xn/2][q][zn/2][p]
	
	make/o/n=(xn,zn) $(df+"img_kxky")
	wave img_kxky=$(df+"img_kxky");	setscale/p x x0,xd,xu,img_kxky; 	setscale/p y,z0,zd,zu,img_kxky
	img_kxky=ww[p][xn/2][q][tn/2]
		
	//make prof wave
	make/o/n=(tn) $(df+"prof_kz")
	wave prof_kz=$(df+"prof_kz");	setscale/p x, t0,td,tu, prof_kz
	prof_kz[]=ww[xn/2][yn/2][zn/2][p]
	
	
	//Display kx_BE
	dowindow/f $dfn
		if(v_flag==0)
			Display /W=(248,103,938,674); appendimage img_kxBE
			DoWindow/c/t $dfn, dfn+"["+dname+"]"
			setwindow $dfn, hook=imgkykzHookFcn, hookevents=3
			modifyimage img_kxBE, cindex=ct
		endif
			
	//cursors
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc")
	nvar xp=$(df+"xp"), yp=$(df+"yp"), zp=$(df+"zp"), tp=$(df+"tp")
	xp=xn/2;yp=yn/2; zp=zn/2; tp=tn/2
	xc=x0+xd*xp; yc=y0+yd*yp; zc=z0+zd*zp; tc=t0+td*tp;
	execute df+"xp:=("+df+"xc-"+df+"x0)/"+df+"xd"
	execute df+"yp:=("+df+"yc-"+df+"y0)/"+df+"yd"
	execute df+"zp:=("+df+"zc-"+df+"z0)/"+df+"zd"
	execute df+"tp:=("+df+"tc-"+df+"t0)/"+df+"td"
	make/o/n=(2) $(df+"hcurx"), $(df+"hcury"), $(df+"vcurx"), $(df+"vcury"),$(df+"zcurx"), $(df+"zcury"), $(df+"tcurx"), $(df+"tcury")
	wave hcurx=$(df+"hcurx"), hcury=$(df+"hcury"), vcurx=$(df+"vcurx"), vcury=$(df+"vcury")
	wave zcurx=$(df+"zcurx"), zcury=$(df+"zcury"), tcurx=$(df+"tcurx"), tcury=$(df+"tcury")
 	execute df+"hcury:="+df+"yc";	 	hcurx={-inf,inf};
	execute df+"vcurx:="+df+"xc";			vcury={-inf,inf}
	execute df+"zcurx:="+df+"zc";			zcury={-inf,inf}
	execute df+"tcurx:="+df+"tc";			tcury={-inf,inf}

	appendtograph hcury vs hcurx
	appendtograph vcury vs vcurx

	modifyRGBaxis("hcury","Y","left",16385,65535,0)
	modifyRGBaxis("vcury","Y","left",16385,65535,0)

	//DEPENDENCY FORMULAS
	execute df+"img_kxBE:="+df+"datawave[p][q]["+df+"zp]["+df+"tp]"
	execute df+"img_kxky:="+df+"datawave[p]["+df+"yp][q]["+df+"tp]"
	execute df+"img_kzBE:="+df+"datawave["+df+"xp][q]["+df+"zp][p]"
	execute df+"prof_kz:="+df+"datawave["+df+"xp]["+df+"yp]["+df+"zp][p]"
	

	//Append all graphs
	//kxBE
	ModifyGraph axisEnab(left)={0,0.4}, axisEnab(bottom)={0,0.47}
	ModifyGraph freePos(left)=0,freePos(bottom)=0
	Label bottom waveunits(img_kxBE,0)
	Label left waveunits(img_kxBE,1)
	//kzBE
	appendimage/r=imghR/b=imghB img_kzBE
	appendtograph/r=imghR/b=imghB hcury vs hcurx
	appendtograph/r=imghR/b=imghB tcury vs tcurx
	modifyRGBaxis("hcury","Y","imghR",16385,65535,0)
	modifyRGBaxis("tcury","X","imghB",16385,65535,0)
	modifygraph axisEnab(imghR)={0, 0.40}, axisEnab(imghB)={0.53,1}
	ModifyGraph freePos(imghR)=0,freePos(imghB)=0
	modifyimage img_kzBE, cindex=ct_v
	Label imghB waveunits(img_kzBE,0)
	Label imghR waveunits(img_kzBE,1)
	//kxky
	appendimage/l=imgvR/t=imgvT img_kxky
	appendtograph/l=imgvR/t=imgvT vcury vs vcurx
	appendtograph/l=imgvR/t=imgvT zcurx vs zcury
	modifyRGBaxis("vcury","X","imgvT",16385,65535,0)
	modifyRGBaxis("zcurx","x","imgvT",16385,65535,0)	
	ModifyGraph axisEnab(imgvR)={0.5,0.9}, axisEnab(imgvT)={0,0.47}
	ModifyGraph freePos(imgvR)=0,freePos(imgvT)={0.1,kwFraction}	
	label imgvR waveunits(img_kxky,1)
	modifyimage img_kxky, cindex=ct_h
	//kz prof
	appendtograph/r=profL/t=profT prof_kz
	appendtograph/r=profL/t=profT tcury vs tcurx
	modifygraph axisEnab(profL)={0.5,0.9},  axisEnab(profT)={0.53,1}
	modifyRGBaxis("tcury","X","proft",16385,65535,0)
	ModifyGraph freePos(profL)=0, freePos(profT)={0.1,kwFraction}
	ModifyGraph margin=72
	
	adjustCT_kykz(df, "img_kxBE", "ct")
	adjustCT_kykz(df, "img_kxky", "ct_h")
	adjustCT_kykz(df, "img_kzBE", "ct_v")
	
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
	nvar x0=$(df+"x0"), y0=$(df+"y0"),z0=$(df+"z0"),t0=$(df+"t0")
	nvar xd=$(df+"xd"), yd=$(df+"yd"),zd=$(df+"zd"),td=$(df+"td")
	nvar xn=$(df+"xn"), yn=$(df+"yn"),zn=$(df+"zn"),tn=$(df+"tn")
	wave ww=$(df+"datawave")

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
			t0=dimoffset(ww,3); td=dimdelta(ww,3); tn=dimsize(ww,3)
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
	button kykz_hvbutton, disable=(tab!=0)
// colors tab=1
	setvariable setgamma,disable=(tab!=1)
	slider slidegamma,disable=(tab!=1)	
	groupBox Colors,disable=(tab!=1)
	popupmenu selectCT,disable=(tab!=1)
	checkbox invertCT,disable=(tab!=1)
// process tab=2
	SetVariable setvarkxoff, disable=(tab!=2)
	SetVariable setvarkyoff, disable=(tab!=2)	
	SetVariable setvarv0, disable=(tab!=2)
	SetVariable setvarwk, disable=(tab!=2)
	CheckBox kxckbx2, disable=(tab!=2)
	button ReloadButton, disable=(tab!=2)
	button UpdateButton, disable=(tab!=2)
	groupBox SetCurskxky, disable=(tab!=2)
	button SetThetaCenter, disable=(tab!=2)
	button SetBetaCenter, disable=(tab!=2)
// drift correction tab=3
	GroupBox Driftoffset disable=(tab!=3)
	groupBox Driftkz disable=(tab!=3)
	SetVariable SetthetaOffset disable=(tab!=3)
	SetVariable SetbetaOffset disable=(tab!=3)
	button BEcorrButton, disable=(tab!=3)	
	button kxCorrButton,  disable=(tab!=3)		
	button kyCorrbutton, disable=(tab!=3)		
	button DonecorrButton, disable=3
// export tab=4
	button exportkspacebut, disable=(tab!=4)
	button export3dVol, disable=(tab!=4)
	button exportimg, disable=(tab!=4)
	checkbox BEckbx , disable=(tab!=4)&&(tab!=3)
	checkbox kxckbx, disable=(tab!=4)
	checkbox ThetaDriftckbx, disable=(tab!=4)&&(tab!=3)	
	CheckBox BetaDriftckbx, disable=(tab!=4)&&(tab!=3)	

end

function setupTabkykz(dfn)
	string dfn
	string df="root:"+dfn+":"
	
	tabcontrol tab0 proc=tabkykz, size={600,80}, pos={20,0}, labelback=(16385,65535,65535)
	tabcontrol tab0 tablabel(0)="info",tablabel(1)="colors",tablabel(2)="process",tablabel(3)="Drift Correction"
	tabcontrol tab0 tablabel(4)="export"
	
	nvar xc=$(df+"xc"), yc=$(df+"yc"), zc=$(df+"zc"), tc=$(df+"tc")
	nvar xp=$(df+"xp"), yp=$(df+"yp"), zp=$(df+"zp"), tp=$(df+"tp")		
	nvar kx_check=$(df+"kx_check"),  BE_check=$(df+"BE_check"),  thetaDrift_check=$(df+"ThetaDrift_check"),betaDrift_check=$(df+"BetaDrift_check")
	nvar v0=$(df+"v0"), wk=$(df+"wk"), kx_off=$(df+"kx_off"), ky_off=$(df+"ky_off"), theta_offset=$(df+"theta_offset"), Beta_offset=$(df+"beta_offset")
	
	wave hv_scale=$(df+"hv_scale")
	
	//info tab
	SetVariable setvarxc value=xc, title="x", pos={60,32},size={100,15},labelBack=(16385,65535,65535)
	SetVariable setvarxp value=xp,  title="x [p]", pos={60,52},size={100,15},labelBack=(16385,65535,65535),  proc=update_ps,limits={-inf,inf,1}
	SetVariable setvaryc value=yc, title="BE", pos={170,32},size={100,15},labelBack=(16385,65535,65535)
	SetVariable setvaryp value=yp, title="BE [p]", pos={170,52},size={100,15},labelBack=(16385,65535,65535), proc=update_ps,limits={-inf,inf,1}
	SetVariable setvarzc value=zc, title="ky", pos={280,32},size={100,15},labelBack=(16385,65535,65535)
	SetVariable setvarzp value=zp, title="ky [p]", pos={280,52},size={100,15},labelBack=(16385,65535,65535),  proc=update_ps,limits={-inf,inf,1}
	SetVariable setvartc value=tc, title="kz", pos={390,32},size={100,15},labelBack=(16385,65535,65535)
	SetVariable setvartp value=tp, title="kz [p]", pos={390,52},size={100,15},labelBack=(16385,65535,65535),  proc=update_ps,limits={-inf,inf,1}
	Button kykz_hvbutton, title="dispay hv scale", pos={500,40},size={110,20},labelBack=(16385,65535,65535),  proc=kykz_buttonCnt

	// process
	SetVariable setvarkxoff value=kx_off, title="kx offset", pos={30,25}, size={100,15},labelBack=(16385,65535,65535),limits={-inf,inf,0.1}
	SetVariable setvarkyoff value=ky_off, title ="ky offset", pos={140,25}, size={100,15}, labelBack=(16385,65535,65535),limits={-inf,inf,0.1}
	SetVariable setvarv0 value=v0, title="V0", pos={250,25}, size={75,15}, labelBack=(16385,65535,65535),limits={-inf,inf,0.1}
	SetVariable setvarwk value=wk, title="W", pos={330,25}, size={75,15},labelBack=(16385,65535,65535),limits={-inf,inf,0.1}
	Button ReloadButton, title="Reload",  pos={35,50}, size={75,20},fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button UpdateButton, title="Update", pos={135,50}, size={75,20}, fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
  	groupBox SetCurskxky title="Set Cursor as",pos={435, 27}, size={180,50},fcolor=(65535,0,0),labelback=0
	Button SetThetaCenter, title="Theta offset", pos={445,47}, size={75,20}, fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button SetBetaCenter, title="Beta offset", pos={535,47}, size={75,20}, fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	CheckBox kxckbx2, title="kx (unchecked for Theta)", pos={230,55},size={130,15}, variable=kx_check 

	//drift correction
	groupBox Driftkz title="kz-dependent drift",pos={25,22},size={280,53},fcolor=(65535,0,0),labelback=0
	Button BEcorrButton, title="BE vs kz", pos={35,45}, size={75,20},fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button kxCorrbutton, title="Theta drift", pos={130,45},  size={75,20},fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button kyCorrbutton, title="ky drift", pos={220,45},  size={75,20},fcolor=(16385,28398,65535), proc=kykz_ButtonCnt
	Button Donecorrbutton, title="Done", pos={315,45}, size={75,20}, disable=3, proc=kykz_ButtonCnt
	GroupBox Driftoffset title="Constant Offset",pos={460,18},size={145,60},fcolor=(65535,0,0),labelback=0
	SetVariable SetthetaOffset, value=theta_offset,title="theta _offset", pos={465,35}, size={135,15}
	SetVariable SetbetaOffset, value=beta_offset,title="beta _offset", pos={465,55}, size={135,15}	
	
	//export
	button exportkspacebut,title="export  4D", pos={30,35}, size={75,20},proc=Export_kykz , fcolor=(16385,28398,65535)  
	button export3dVol, title="Export 3D", pos={130,35}, size={75,20}, proc=Export_kykz,  fcolor=(16385,28398,65535)
	button exportimg, title="Exort Image", pos={230,35}, size={90,20}, proc=Export_kykz, fcolor=(16385,28398,65535)
	CheckBox kxckbx, title="kx (unchecked for Theta)", pos={110,60},size={130,15}, variable=kx_check 
	CheckBox BEckbx, title="correct BE Drift", pos={330,25},size={70,15}, variable=BE_check
	CheckBox ThetaDriftckbx, title="correct Theta Drift", pos={330,40},size={70,15}, variable=ThetaDrift_check
	CheckBox BetaDriftckbx, title="correct Beta Drift", pos={330,55},size={70,15}, variable=BetaDrift_check
	
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
	wave img_kxky=$(df+"img_kxky"), img_kxBE=$(df+"img_kxBE"), img_kzBE=$(df+"img_kzBE"), prof_kz=$(df+"prof_kz")
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
	variable mousex,mousey,ax,ay,az,at,modif
	variable xcold=xc,ycold=yc,zcold=zc,tcold=tc
	modif=numberByKey("modifiers",s) & 15
	variable statuscode=0
	
	if(strsearch(s,"EVENT:mouse",0)>0)
		if(modif==9) //cmd+mouse
			variable axmin, axmax,aymin, aymax
			variable azmin,azmax,zymin,zymax
			variable atmin, atmax,tymin,tymax
			variable xcur,ycur,zcur, tcur
			variable/c offset
			mousex=numberbykey("mousex",s)
			mousey=numberbykey("mousey",s)
			ay=axisvalfrompixel(dfn,"left",mousey)
			ax=axisvalfrompixel(dfn,"bottom", mousex)
			az=axisvalfrompixel(dfn,"imgvr",mousey)
			at=axisvalfrompixel(dfn,"profT",mousex)
	
			statuscode=1
			getaxis/q bottom;axmin=min(v_max,v_min);axmax=max(v_max,v_min)
			getaxis/q left; aymin=min(v_max,v_min);aymax=max(v_max,v_min)
			getaxis/q imgvr;azmin=min(v_max,v_min);azmax=max(v_max,v_min)
			getaxis/q proft; atmin=min(v_max,v_min);atmax=max(v_max,v_min)
			if((ax>axmin)*(ax<axmax)*(ay>aymin)*(ay<aymax))
				xc=selectnumber((ax>axmin)*(ax<axmax),xc,ax)
				yc=selectnumber((ay>aymin)*(ay<aymax),yc,ay)
			endif
			if((ax>axmin)*(ax<axmax)*(az>azmin)*(az<azmax))
				xc=selectnumber((ax>axmin)*(ax<axmax),xc,ax)
				zc=selectnumber((az>azmin)*(az<azmax),zc,az)
			endif
			if((at>atmin)*(at<atmax))
				tc=selectnumber((at>atmin)*(at<atmax),tc,at)
			endif
			if((at>atmin)*(at<atmax)*(ay>aymin)*(ay<aymax))
				yc=selectnumber((ay>aymin)*(ay<aymax),yc,ay)
				tc=selectnumber((at>atmin)*(at<atmax),tc,at)
			endif			

			adjustCT_kykz(df, "img_kxBE", "ct")
			adjustCT_kykz(df, "img_kxky", "ct_h")
			adjustCT_kykz(df, "img_kzBE", "ct_v")
		endif
	return statuscode	
	endif
	
end

Function kykz_ButtonCnt(ctrlName) :ButtonControl
	string ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	strswitch(ctrlName)
		case "ReLoadButton":
			execute "ky_kzFunctions#ReLoad_kykz()"
			break
		case "UpdateButton":
			execute "ky_kzFunctions#Update_kykz()"
			break
		case  "BEcorrButton":
			execute "ky_kzFunctions#BEkz_Corr()"
			break
		case "DoneCorrButton":
			execute "ky_kzFunctions#DoneCorr()"
			break
		case "kykz_hvButton":
			execute "ky_kzFunctions#kykz_hv()"
			break
		case "SetThetaCenter"	:
			execute "ky_kzFunctions#SetOffsetCurs(\""+ctrlname+"\")"
			break
		case "SetBetaCenter":
			execute "ky_kzFunctions#SetOffsetCurs(\""+ctrlname+"\")"
			break
		case "kxCorrbutton":
			execute  "ky_kzFunctions#ThetaDriftButton()"
			break
		case "kyCorrbutton":
			execute  "ky_kzFunctions#kyDriftButton()"		
			break
		case "CalcThetaButton":
			execute  "ky_kzFunctions#CalcTheta()"
			break
		case "CalcBetaButton":
			execute  "ky_kzFunctions#CalcBeta()"
			break		
		case "UpdateImgButton":
			execute "ky_kzFunctions#UpDateimg_thetkz()"
			break
		case "UpdateImgButtonky":
			execute "ky_kzFunctions#UpDateimg_betakz()"
		endswitch
end

static function Update_kykz()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	variable run=0
	nvar kx_check=$(df+"kx_check")
	print selectstring(kx_check,"theta", "kx")
	Calc_datawave(df,selectstring(kx_check,"theta", "kx"), 4,run)
	nvar theta_offset=$(df+"theta_offset"), beta_offset=$(df+"beta_offset")
	execute "ky_kzFunctions#UpdateScales()"
end 

static Function ReLoad_kykz()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	variable run=0
	nvar kx_off=$(df+"kx_off"), ky_off=$(df+"ky_off"), v0=$(df+"v0"), wk=$(df+"wk")
	nvar kx_check=$(df+"kx_check"), theta_offset=$(df+"theta_offset"), beta_offset=$(df+"beta_offset")
	nvar be_check=$(df+"be_check"), thetadrift_check=$(df+"thetaDrift_check"), betadrift_check=$(df+"betadrift_check")
	theta_offset=0;beta_offset=0;be_check=0;thetadrift_check=0;betadrift_check=0
	Calc_datawave(df,selectstring(kx_check,"theta", "kx"), 4,run)
	execute "ky_kzFunctions#UpdateScales()"
end

function Export_kykz(ctrlName) :ButtonControl
	string ctrlName
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	svar dname=$(df+"dname")
	wave org=$("root:"+dname)
	wave datawave=$(df+"datawave")
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
	 	duplicate/o datawave $(df+"datawave_")
	 	wave datawave_=$(df+"datawave_")
	 	if(kx_check==1)
	 		Calc_datawave(df,"kx", 4,run)
		else 
			Calc_datawave(df,"theta",4,run)
	 	endif
		killwaves/z $(df+"tmp"), $(df+"tmporg")
//		movewave $(df+"datawave") $("root:"+newname)
		duplicate/o datawave $("root:"+newname)
		duplicate/o datawave_ $(df+"datawave")
	 	killwaves/z $(df+"datawave_")
		newimagetool5(newname)
	 endif
	
//export 3D	
	if(cmpstr(ctrlname, "export3dvol")==0) 
		prompt newname, "Name of new datawave"
	 	doprompt "Export 3D", newname
	 	if(v_flag==1)
	 		abort
	 	endif  	
		Calc_datawave(df,selectstring(kx_check,"theta", "kx"), 3,run)
		duplicate $(df+selectstring(kx_check, "tmporg", "tmp")) $newname
		duplicate/o $(df+"datawave_") $(df+"datawave")
		killwaves/z $(df+"tmp"), $(df+"tmporg"), $(df+"datawave_")	
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
	string dfn=getdf()
	string df="root"+dfn
	wave img=$(df+"img_kzBE")
	variable size=dimsize(img,0)
	make/o/n=(size) $(df+"corr_BEkz")
	wave corr_BEkz=$(df+"corr_BEkz")
	setscale/p x,dimoffset(img,0), dimdelta(img,0), waveunits(img,0) corr_BEkz
	appendtograph/r=imghR/b=imghB corr_BEkz
	graphwaveedit corr_BEkz
	Button DonecorrButton, title="Done",disable=0, proc=kykz_ButtonCnt, pos={35,45}, size={75,20}
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
	wave datawave=$(df+"datawave"), img_kxky=$(df+"img_kxky"), img_kxBE=$(df+"img_kxBE"), img_kzBE=$(df+"img_kzBE"), prof_kz=$(df+"prof_kz")
	setscale/p x, dimoffset(datawave,0), dimdelta(datawave,0), waveunits(datawave,0) img_kxBE
	setscale/p x, dimoffset(datawave,0), dimdelta(datawave,0), waveunits(datawave,0) img_kxky
	setscale/p y, dimoffset(datawave,1), dimdelta(datawave,1), waveunits(datawave,1) img_kxBE
	setscale/p y, dimoffset(datawave,1), dimdelta(datawave,1), waveunits(datawave,1) img_kzBE	
	setscale/p y, dimoffset(datawave,2), dimdelta(datawave,2), waveunits(datawave,2) img_kxky
	setscale/p x, dimoffset(datawave,3), dimdelta(datawave,3), waveunits(datawave,3) img_kzBE	
	setscale/p x, dimoffset(datawave,3), dimdelta(datawave,3), waveunits(datawave,3) prof_kz
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
	wave datawave=$(df+"datawave")
	wave hv_scale=$(df+"hv_scale")
	string/g $(df+"thetadriftwavename")
	svar driftw=$(df+"thetadriftwavename")
	driftw=w
	make/o/n=(dimsize(datawave,0), dimsize(datawave,3)) $(df+"img_thetakz")
	wave img_thetakz=$(df+"img_thetakz")
	setscale/p x, dimoffset(datawave,0), dimdelta(datawave,0), waveunits(datawave,0) img_thetakz
	setscale/p y, dimoffset(datawave,3), dimdelta(datawave,3), waveunits(datawave,3) img_thetakz
	img_thetakz=datawave[p][yp][zp][q]
	make/o/n=(dimsize(datawave,3)) $(df+"ThetaDrift")	
	wave thetadrift=$(df+"ThetaDrift")
	make/o/n=(dimsize(datawave,3)) $(df+"ThetaDrift_kz")
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
	wave img_thetakz=$(df+"img_thetakz")
	wave datawave=$(df+"datawave")
	nvar yp=$(df+"yp"), zp=$(df+"zp"), yc=$(df+"yc"), zc=$(df+"zc")
	img_thetakz[][]=datawave[p][yp][zp][q] 
	nvar kx=$(df+"kxDrift_kx"), ky=$(df+"kxDrift_ky"),kz=$(df+"kxDrift_kz"),BE=$(df+"kxDrift_BE")
	BE=yc; ky=zc
	setvariable kxD_BE value=BE
	setvariable kxD_ky value=ky
end

static function kyDriftButton()
	string dfn=winname(0,1)
	string df="root:"+dfn+":"
	wave datawave=$(df+"datawave")
	
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
		make/o/n=(dimsize(datawave,3)) $(name)
	endif
	string/g $(df+"Betadriftwavename")
	svar driftw=$(df+"Betadriftwavename")
	driftw=w
	make/o/n=(dimsize(datawave,2),dimsize(datawave,3)) $(df+"img_Betakz")
	wave img_Betakz=$(df+"img_Betakz")
	setscale/p x, dimoffset(datawave,2), dimdelta(datawave,2), waveunits(datawave,2) img_betakz
	setscale/p y, dimoffset(datawave,3), dimdelta(datawave,3), waveunits(datawave,3) img_betakz
	make/o/n=(dimsize(datawave,3)) $(df+"Betadrift")
	wave Betadrift=$(df+"Betadrift")
	make/o/n=(dimsize(datawave,3)) $(df+"Betadrift_kz")
	wave betadrift_kz=$(df+"betadrift_kz")
	betadrift_kz=dimoffset(datawave,3)+dimdelta(datawave,3)*p
	nvar xp=$(df+"xp"), yp=$(df+"yp"), xc=$(df+"xc"), yc=$(df+"yc")
	img_betakz=datawave[xp][yp][p][q]
	
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
	If(cmpstr(waveunits(datawave,0),"theta")==0)
		wave hv_scale=$(df+"hv_scale") 
		kx=sin(xc*pi/180)*0.5124*sqrt(hv_scale[round(tp)]-yc-wk)
	else
		kx=xc
	endif
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
	wave datawave=$(df+"datawave")
	nvar xp=$(df+"xp"), yp=$(df+"yp"), xc=$(df+"xc"), yc=$(df+"yc"), tc=$(df+"tc"), tp=$(df+"tp"), wk=$(df+"wk")
	img_betakz[][]=datawave[xp][yp][p][q] 
	nvar kx=$(df+"kxDrift_kx"), ky=$(df+"kxDrift_ky"),kz=$(df+"kxDrift_kz"),BE=$(df+"kxDrift_BE")
	BE=yc; kz=tc	
	If(cmpstr(waveunits(datawave,0),"theta")==0)
		wave hv_scale=$(df+"hv_scale") 
		kx=sin(xc*pi/180)*0.5124*sqrt(hv_scale[round(tp)]-yc-wk)
	else
		kx=xc
	endif
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
