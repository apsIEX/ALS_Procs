#pragma rtGlobals=1		// Use modern global access method.
//wv is 3d wave (ccd images as function of azimuth)
//   indices are (SES-angle, BE, phi)
//th is value of theta (constant for scan) in degrees
//phi is wave containing phi values in degrees
//will overwrite the scale values of incoming wave

//good examples of usage:
//MDC_AZ(X21116_011_hdf, f011_cryo_phi, 17, 90, .033, 1/233, "f011_3d")
//MDC_AZ(X21116_021_hdf, f011_cryo_phi, 17, 90, .033, 1/233, "f021_3d")

//menu "kSpace"
//	"MDC_AZ"
//end

function MDC_AZ(wv, phi,th, hv, degperpixel, evperpixel, wvout)
 	wave wv,phi
 	variable th,hv,degperpixel, evperpixel
 	string wvout
 	th=abs(th)
 	variable numSESang=dimsize(wv,0)
 	variable numEn=dimsize(wv,1)
 	variable numMotor=dimsize(wv,2)
 	variable numAz=numpnts(phi)
 	variable nps=100
 	variable k=0.5124*sqrt(hv)
	wavestats/q phi
	variable phimin=v_min, phimax=v_max
	variable thetamin=th-numSESang/2*degperpixel, thetamax=th+numSESang/2*degperpixel
	//scale incoming wave properly
	setscale/i x thetamin,thetamax, "theta", wv
	setscale/p y 0,evperpixel, "energy", wv
	setscale/p z, phi[0], phi[1]-phi[0], "phi", wv
	//figure out appropriate krange to calculate
 	make/o/n=(2*numAz) extremeTheta,ExtremePhi,extremekx,extremeky
 	extremetheta[0,numAz-1]=thetamin
 	extremetheta[numAz,]=thetamax
 	extremephi[0,numAz-1]=phi
 	extremephi[numAz,]=phi[p-numaz]
	extremekx=k*sin(extremetheta*pi/180)*cos(extremephi*pi/180)
	extremeky=k*sin(extremetheta*pi/180)*sin(extremephi*pi/180)
	wavestats/q extremekx
 	variable kxmax=v_max, kxmin=v_min
	wavestats/q extremeky
	variable kymax=v_max, kymin=v_min

 	make/n=(nps,nps,numEn)/o $wvout
 	wave wvo=$wvout
 	wvo=0
 	setscale/i x, kxmin,kxmax,"kx", wvo
 	setscale/i y, kymin,kymax,"ky", wvo
 	setscale/p z, 0, evperpixel, "energy", wvo
 	variable i
 	make/n=(nps,nps)/o thetawv, phiwv
 	setscale/i x, kxmin,kxmax,"kx", thetawv
 	setscale/i y, kymin,kymax,"ky", thetawv
 	setscale/i x, kxmin,kxmax,"kx", phiwv
 	setscale/i y, kymin,kymax,"ky", phiwv
 	thetawv=asin(sqrt(x^2+y^2)/k)*180/pi
	phiwv=atan2(y,x)*180/pi
 	for (i=0; i<numEn; i+=1)
 		wvo[][][i]=wv(thetawv[p][q])[i](phiwv[p][q])
 	endfor
	wvo[][][]*=(1-(phiwv[p][q]<(phimin)))*(1-(phiwv[p][q]>(phimax)))//*(1-(phiwv[p][q]<phimin))
end