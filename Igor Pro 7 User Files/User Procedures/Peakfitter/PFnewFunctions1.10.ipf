#pragma rtGlobals=1		// Use modern global access method.

function fLor(LW, dx)			//=fLorDS(LW, ASY=0, xx)
	variable LW, dx
	variable lhw2=(LW/2)^2
	variable ans=lhw2/(dx^2+ lhw2)
	//if (!numtype(ans))
		return ans
	//else
	//	return 1
	//endif
end

function fLorDS(LW, ASY, dx)
	variable LW, ASY, dx
	variable num, den,lhw=lw/2
	num=LHW*cos(pi*ASY/2 + (1-ASY)*atan(dx/LHW) )
	den=(dx^2+LHW^2)^((1-ASY)/2)
	return(num/den)				//normalized to 1 for ASY=0
end

//modified Igor Tech Note TN026 which is reorganized version of
//vectorized code of J. Humlicek, JQSRT 27 ('82) 437; JQSRT 21 ('79) 309
Function fvoigtH(LW,GW,delx)
	variable LW, GW, delx
	variable LHW=LW/2, GHW=GW/2
	variable X,Y, sln2=0.832555	//sqrt(ln2)
	Y=sln2*LHW/GHW
	X=sln2*delx/GHW

	variable/C W,U,T= cmplx(Y,-X)
	variable S =abs(X)+Y

	if( S >= 15 )								//        Region I
		W= T*0.5641896/(0.5+T*T)
	else
		if( S >= 5.5 ) 							//        Region II
			U= T*T
			W= T*(1.410474+U*0.5641896)/(0.75+U*(3+U))
		else
			if( Y >= (0.195*ABS(X)-0.176) ) 	//        Region III
				W= (16.4955+T*(20.20933+T*(11.96482+T*(3.778987+T*0.5642236))))
				W /= (16.4955+T*(38.82363+T*(39.27121+T*(21.69274+T*(6.699398+T)))))
			else									//        Region IV
				U= T*T
				W= T*(36183.31-U*(3321.9905-U*(1540.787-U*(219.0313-U*(35.76683-U*(1.320522-U*0.56419))))))
				W /= (32066.6-U*(24322.84-U*(9022.228-U*(2186.181-U*(364.2191-U*(61.57037-U*(1.841439-U)))))))
				W= cmplx(exp(real(U))*cos(imag(U)),0)-W
			endif
		endif
	endif
	return real(W)//     /(exp(y^2)*erfc(y))
end

function fGauss(GW, dx)
	variable GW, dx
	variable GHW=GW/2
	return(exp(-(0.832555*dx/GHW)^2))	//sqrt(ln2)=0.832555
end

function fDSconvG(pk,LHW, GHW, ASY, delx)		//Doniach-Sunjic convolved with Gaussian
	variable pk,LHW, GHW, ASY, delx
	string ss
	if (streq(getdatafolder(0),"PF")) 
		ss = ""
	else
		ss=":PF:"
	endif
	wave DSGTable=$(ss+"DSGTable")
	variable tailFactor=10 //bigger it is, longer the tail
	variable totwid=(LHW+GHW)*40*tailFactor, twPos=totwid*0.5

	if (neq(LHW,DSGTable[0][pk])+neq(GHW,DSGTable[1][pk])+neq(ASY,DSGTable[2][pk]))
//print LHW,DSGTable[0][pk],neq(LHW,DSGTable[0][pk])
//print GHW,DSGTable[1][pk],neq(GHW,DSGTable[1][pk])
//print ASY,DSGTable[2][pk],neq(ASY,DSGTable[2][pk])
//print "~",pk
		variable gw, norm
		make/o/r/n=(256*tailFactor) $(ss+"wvDS"+num2str(pk))
		wave wv=$(ss+"wvDS"+num2str(pk))
		SetScale/I x 0,totwid,"",wv
		wv=fLorDS(LHW, ASY, x-twPos)
		fft wv
		wave/c wvc=wv			//wvc(omplex) is another name for wv
		gw=GHW/0.832555	//sqrt(ln2)
		wvc*=cmplx( exp(-(gw*pi*x)^2),0)
		ifft wvc			//=wv (real)
		norm=wv(twPos)
		wv/=norm
		DSGTable[0][pk]=LHW
		DSGTable[1][pk]=GHW
		DSGTable[2][pk]=ASY
	else
		wave wv=$(ss+"wvDS"+num2str(pk))
	endif
	return(wv(delx+twPos))	
end

function neq(x1,x2)
	variable x1,x2
	if(abs((x1-x2)/(x1+x2)) <= 1e-7 )
		return 0
	else
		return 1
	endif
end