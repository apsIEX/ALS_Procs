#pragma rtGlobals=1		// Use modern global access method.
//uses bandmap image in top graph to generate correction table 

menu "kspace"
	submenu "Correct..."
		"Make Dispersion Correction"
		"Apply Dispersion Correction"
	end
end


//adds an img to itself translated by gx,gy
//x0,x1,y0,y1 are ranges you want to modify
//gx,gy are waves holding x and y coordinates
//g0,g1 are range of g waves to use
//img should be NaN where you don't want to add
function trSymm(img,x0,x1,y0,y1,gx,gy,g0,g1)
	wave img
	variable g0,g1,x0,x1,y0,y1
	wave gx,gy
	duplicate/o img img1,img2,isvalid
	variable i0,i1,j0,j1
	i0=round((x0 - DimOffset(img, 0))/DimDelta(img,0))
	i1=round((x1 - DimOffset(img, 0))/DimDelta(img,0))
	if (i0>i1)
		switchvar(i0,i1)
	endif
	if(j0>j1) 
		switchvar(j0,j1)
	endif
	j0=round((y0 - DimOffset(img, 1))/DimDelta(img,1))
	j1=round((y1 - DimOffset(img, 1))/DimDelta(img,1))
	//print i0,i1,j0,j1
	variable i,j,k,iav=round((i0+i1)/2),jav=round((j0+j1)/2)
	img2=0		//number of valid datapoints contributing to each pixel so far
	for (k=g0; k<=g1; k+=1)
		print k,gx[k],gy[k]
		img1[i0,i1][j0,j1]=interp2d(img,x-gx[k],y-gy[k])
		isvalid[i0,i1][j0,j1]=1-(numtype(img1)>0)
		img2[i0,i1][j0,j1]+=isvalid	//1 if valid number, zero if otherwise
		for (i=i0; i<=i1; i+=1)
			for (j=j0; j<=j1; j+=1)
				if (isvalid[i][j])
					img[i][j]= (img[i][j]*img2[i][j] + img1[i][j])/(img2[i][j]+1)
					if((i==iav)*(j==jav))
						print img[i][j],img2[i][j],img1[i][j],img2[i][j]+1
					endif
				endif
			endfor
		endfor
		doupdate
	endfor
end
	
static function switchvar(xx,yy)
	variable &xx,&yy
	variable temp=yy
	yy=xx
	xx=temp
end

proc MakeDispersionCorrection(wv, cOut)
	string cOut // wavename of correction wave
	string wv
	prompt wv, "Correction wave name", popup wavelist("!*_CT",";","DIMS:2,WIN:")
	string cout2="corr_"+cout
	make/o/n=4 tx,ty
	variable nx=dimsize($wv,0),  ny=dimsize($wv,1)
	tx={10,10,nx-10,nx-10}
	ty={10,ny-10,ny-10,10}
	make/o/n=2 ey ex
	ex={5,nx-5}
	ey={ny-20,ny-20}
	append ty vs tx
	append ey vs ex; modifygraph rgb(ey)=(0,0,65535)
	controlbar 50
	Button done proc=doneAnglrCorr,title="done",size={75,20}
	Button editE proc=doEditE,title="editEnergy",size={75,20}
	Button editA proc=doEditA,title="editAngle",size={75,20}
	Button noEdit proc=doNoEdit,title="stop editing",size={75,20}
	Button cancel proc=doCancel,title="cancel",size={75,20}
	doupdate
	string/g acw=wv, coutw=cout2

	graphwaveedit ty
end

Function doneAnglrCorr(ctrlName) : ButtonControl
	String ctrlName
	graphnormal
	killcontrols()
	finishADCorr()
End

Function doCancel(ctrlName) : ButtonControl
	String ctrlName
	killcontrols()
	removefromgraph ey,ty
End

function killControls()
	killcontrol done
	killcontrol editE
	killcontrol editA
	killcontrol noEdit
	killcontrol cancel
	controlbar 0
end

Function doNoEdit(ctrlName) : ButtonControl
	String ctrlName
	graphnormal
End

Function doEditE(ctrlName) : ButtonControl
	String ctrlName
	wave ey=ey
	graphwaveedit ey
End

Function doEditA(ctrlName) : ButtonControl
	String ctrlName
	wave ty=ty
	graphwaveedit ty
End

function finishADCorr()
	wave ty=ty,tx=tx
	removefromgraph ty, ey
	variable sL=(ty[1]-ty[0])/(tx[1]-tx[0])
	variable sR=(ty[2]-ty[3])/(tx[2]-tx[3])
	if(numpnts(ty)==4)
		svar wv=acw
		svar cw=coutw
		print cw
		wave acw=$wv
		duplicate/o acw $cw
		wave cout=$cw
		redimension/n=(dimsize(cout,0),dimsize(cout,1),2) cout
		
		//calculate x corrections
		variable j,ny=dimsize(acw,1),dxj
		variable xL0=tx[1]-1/sL*ty[1]			//left line intersects y=0
		variable xR0=tx[2]-1/sR*ty[2]			//right line intersects y=0
		variable xL1=tx[1]+1/sL*(ny-ty[1]-1)	//left line intersects y=ny-1
		variable xR1=tx[2]+1/sR*(ny-ty[2]-1)	//right line intersects y=ny-1
		make/o/n=(ny) stretch
		variable s0=(xR1-xL1)/(xR0-xL0)		//stretch factor to make bottom same scale as top 
		stretch=(1-s0)/ny * p + s0
		for (j=0;j<dimsize(acw,1);j+=1)
			cout[][j][0]=x/stretch[j]+(ny-1-j)/ny*(xL0-xL1)	//xcorrection
		endfor
	
		//calculate y corrections
		variable/g k2=0
		if (numpnts(ey)>2)
			CurveFit poly 3 , ey /X=ex /D 
		else
			CurveFit line, ey /X=ex /D
		endif
		cout[][][1]=y+(k1*x+k2*x^2)					//ycorrection
	
		//duplicate/o acw dout
		//dout=interp2d(acw,cout[p][q][0],cout[p][q][1])
	else
		doalert 0, "sorry, you cannot add or remove points from the angular correction polygon (linear corrections only, for now)"
	endif

end

proc ApplyDispersionCorrection(dat,cwv,ovw,new)
	string dat,cwv,new; variable ovw
	prompt dat,	"image, 2D array", popup, "-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")	
	prompt cwv,"correction wave",popup WaveList("corr_*",";","DIMS:3")
	prompt ovw,"overwrite existing?", popup "no;yes"
	prompt new, "new wave name"
	ovw-=1
	variable ndx=dimsize($dat,0),ndy=dimsize($dat,1)
	variable ncx=dimsize($cwv,0),ncy=dimsize($cwv,1)
	if((ndx==ncx)*(ndy==ncy))
		variable dim3d=dimsize($dat,2),k
		if(dim3d)
			make/o/n=(ndx,ndy) c_temp0, c_temp
			setscale/p x dimoffset($dat,0),dimdelta($dat,0),"",c_temp0
			setscale/p y dimoffset($dat,1),dimdelta($dat,1),"",c_temp0
			setscale/p x dimoffset($dat,0),dimdelta($dat,0),"",c_temp
			setscale/p y dimoffset($dat,1),dimdelta($dat,1),"",c_temp
			if(!ovw)
				duplicate/o $dat $new
			endif
			do
				print k
				c_temp0=$dat[p][q][k]
				c_temp=interp2d(c_temp0,$cwv[p][q][0], $cwv[p][q][1])
				if(ovw)
					$dat[][][k]=c_temp[p][q]
				else
					$new[][][k]=c_temp[p][q]
				endif
				k+=1
			while(k<dim3d)
			killwaves c_temp,c_temp0
		else
			duplicate/o $dat c_temp
			c_temp=interp2d($dat,$cwv[p][q][0], $cwv[p][q][1])
			//c_temp=interpAng($dat,$cwv)
			if(ovw)
				$dat=c_temp
			else
				if(strlen(new)==0)
					duplicate/o c_temp $(dat+"_corr")
				else
					duplicate/o c_temp $new
				endif
			endif
			killwaves c_temp
		endif
	else
		doalert 0, "Sorry, the dimensions of the data and the correction array must match"	
	endif	
end

//interpolation for when there is no energy (y) correction
//too slow
function interpAng(d,c)
	wave d,c
	variable j,nx=dimsize(d,0), ny=dimsize(d,1)
	make/n=(nx)/o iax
	setscale/p x dimoffset(d,0),dimdelta(d,0),"",iax
	iax=d(c[p][q][0])[q]
end
