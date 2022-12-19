#pragma rtGlobals=1		// Use modern global access method.
//uses bandmap image in top graph to generate correction table 
#include <Strings as lists>
menu "kspace"
	submenu "Correct..."
		"Make Dispersion Correction"
		"Apply Dispersion Correction"
	end
	
	"Symmetrize..."
end

proc Symmetrize(w,symmetry, rangeoption, xrange,yrange,zrange,trWave)
	string w,symmetry, rangeoption, xrange,yrange,zrange,trWave
	prompt w,"Wave to symmetrize",popup  "-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")	
	prompt symmetry, "Enter symmetry operation",popup "Mirror_LR;Mirror_UD;MirrorLRUD;Translational;C2;C3;C4;C5;C6;C10"
	prompt rangeoption, "Data Range to Symmetrize", popup "Auto;Manual"
	prompt xrange,"xrange [\"start,end\"]"
	prompt yrange,"yrange [\"start,end\"]"
	prompt zrange,"zrange [\"start,end\"]"
	prompt trWave,"G-Vector y-wave",popup wavelist("*y",";","")
	silent 1;
	variable x0,x1,y0,y1,z0,z1
	if (cmpstr(rangeoption,"Auto")==0)
		x0=dimoffset($w,0); x1=x0+dimdelta($w,0)*(dimsize($w,0)-1)
		y0=dimoffset($w,1); y1=y0+dimdelta($w,1)*(dimsize($w,1)-1)
		if (wavedims($w)==2)
			z0=0; z1=0
		else
			z0=dimoffset($w,2); z1=z0+dimdelta($w,2)*(dimsize($w,2)-1)
		endif
	else
		x0=str2num(getstrfromlist(xrange,0,",")); x1=str2num(getstrfromlist(xrange,1,","))
		y0=str2num(getstrfromlist(yrange,0,",")); y1=str2num(getstrfromlist(yrange,1,","))
		if (wavedims($w)==2)
			z0=0; z1=0
		else
			z0=str2num(getstrfromlist(zrange,0,",")); z1=str2num(getstrfromlist(zrange,1,","))
		endif
	endif
	
	if(strsearch(symmetry,"Mirror",0)>=0)
		string mirrorOption=getstrfromlist(symmetry,1,"_")
		abort "not implemented yet"
	endif
	if(strsearch(symmetry,"Translational",0)>=0)
		string wvx=getstrfromlist(trwave,0,"_")+"_x"
		print x0,x1,y0,y1,z0,z1
		print wvx,trwave,numpnts($trwave)-1
		trSymm($w,x0,x1,y0,y1,z0,z1,$wvx,$trwave,0,numpnts($trwave)-1)
	endif
	if(strsearch(symmetry,"C",0)>=0)
		variable ns=str2num(symmetry[1,99])
		print ns,x0,x1,y0,y1,z0,z1
		rotSymm(NS,$w,x0,x1,y0,y1,z0,z1)
	endif

end

//adds an img to itself translated by gx,gy
//x0,x1,y0,y1,z0,z1 are ranges you want to modify
//	z0,z1 are ignored for 2Dim  
//gx,gy are waves holding x and y coordinates
//g0,g1 are range of g waves to use
//img should be NaN where you don't want to add
function trSymm(img,x0,x1,y0,y1,z0,z1,gx,gy,g0,g1)
	wave img
	variable x0,x1,y0,y1,z0,z1,g0,g1
	wave gx,gy
	variable ns=g1-g0+1	//# symmetry operations
	print "allocating memory..."
	make/o/n=(dimsize(img,0),dimsize(img,1)) img1,isvalid
	setscale/p x dimoffset(img,0),dimdelta(img,0),"",img1,isvalid
	setscale/p y dimoffset(img,1),dimdelta(img,1),"",img1,isvalid
	make/o/n=(dimsize(img,0),dimsize(img,1)) img2
	setscale/p x dimoffset(img,0),dimdelta(img,0),"",img2
	setscale/p y dimoffset(img,1),dimdelta(img,1),"",img2
	print "calculating symmetry operation"
	//newx[][][]=x-gx[r+g0]
	//newy[][][]=y-gy[r+g0]
	variable is3d=dimsize(img,2)>1
	if(is3d)
		make/o/n=(dimsize(img,0),dimsize(img,1)) img2d
		setscale/p x dimoffset(img,0),dimdelta(img,0),"",img2d
		setscale/p y dimoffset(img,1),dimdelta(img,1),"",img2d
	endif
	variable i0,i1,j0,j1,zp0,zp1
	i0=round((x0 - DimOffset(img, 0))/DimDelta(img,0))
	i1=round((x1 - DimOffset(img, 0))/DimDelta(img,0))
	j0=round((y0 - DimOffset(img, 1))/DimDelta(img,1))
	j1=round((y1 - DimOffset(img, 1))/DimDelta(img,1))
	zp0=is3d*round((z0 - DimOffset(img, 2))/DimDelta(img,2))
	zp1=is3d*round((z1 - DimOffset(img, 2))/DimDelta(img,2))
	if (i0>i1)
		switchvar(i0,i1)
	endif
	if(j0>j1) 
		switchvar(j0,j1)
	endif
	if(zp0>zp1) 
		switchvar(zp0,zp1)
	endif
	variable i,j,k,iav=round((i0+i1)/2),jav=round((j0+j1)/2),zp
	for(zp=zp0; zp<=zp1; zp+=1)
		img2=0		//number of valid datapoints contributing to each pixel so far
		print "averaging..."
		print i0,i1,j0,j1,ns
		for(k=0; k<ns; k+=1)
			print "k=",k
			if(is3d)
				img2d=img[p][q][zp]
				img1[i0,i1][j0,j1]=interp2d(img2d,x+gx[k],y+gy[k])
			else
				img1[i0,i1][j0,j1]=interp2d(img,x+gx[k],y+gy[k])
			endif
			isvalid[i0,i1][j0,j1]=(numtype(img1)==0)
			img2[i0,i1][j0,j1]+=isvalid[p][q]	//add 1 if valid number, zero if otherwise
	
			for (i=i0; i<=i1; i+=1)
				for (j=j0; j<=j1; j+=1)
					//for(k=0; k<ns; k+=1)
					if (isvalid[i][j])
						//rotated data is valid, so average it in
						if(numtype(img[i][j])==0)
							//unrotated data is valid, average it with rotated data
							img[i][j][zp]= (img[i][j][zp]*img2[i][j] + img1[i][j])/(img2[i][j]+1)
						else
							//unrotated data is invalid, replace it with rotated data
							img[i][j][zp]=img1[i][j]
						endif
						endif
					endfor //j			
				endfor	//i
				doupdate
		endfor	//k
	endfor //zp
	
end

function XtrSymm(img,x0,x1,y0,y1,z0,z1,gx,gy,g0,g1)
	wave img
	variable g0,g1,x0,x1,y0,y1,z0,z1
	wave gx,gy
	duplicate/o img img1,img2,isvalid	//has same dimensionality (2 or 3) as input
	variable is3d=dimsize(img,2)>1
	if(is3d)
		make/o/n=(dimsize(img,0),dimsize(img,1)) img2d
		setscale/p x dimoffset(img,0),dimdelta(img,0),"",img2d
		setscale/p y dimoffset(img,1),dimdelta(img,1),"",img2d
	endif
	variable i0,i1,j0,j1,zp0,zp1
	i0=round((x0 - DimOffset(img, 0))/DimDelta(img,0))
	i1=round((x1 - DimOffset(img, 0))/DimDelta(img,0))
	j0=round((y0 - DimOffset(img, 1))/DimDelta(img,1))
	j1=round((y1 - DimOffset(img, 1))/DimDelta(img,1))
	zp0=is3d*round((z0 - DimOffset(img, 2))/DimDelta(img,2))
	zp1=is3d*round((z1 - DimOffset(img, 2))/DimDelta(img,2))
	if (i0>i1)
		switchvar(i0,i1)
	endif
	if(j0>j1) 
		switchvar(j0,j1)
	endif
	if(zp0>zp1) 
		switchvar(zp0,zp1)
	endif
	print i0,i1,j0,j1,zp0,zp1
	variable i,j,k,iav=round((i0+i1)/2),jav=round((j0+j1)/2),zp
	img2=0		//number of valid datapoints contributing to each pixel so far
	for (k=g0; k<=g1; k+=1)
		print k,gx[k],gy[k]
		if (is3d)
			for(zp=zp0; zp<=zp1; zp+=1)
//				print zp,"/",dimsize(img,2)
				img2d=img[p][q][zp]
				img1[i0,i1][j0,j1][zp]=interp2d(img2d,x-gx[k],y-gy[k])
			endfor
		else
			img1[i0,i1][j0,j1]=interp2d(img,x-gx[k],y-gy[k])
		endif
		isvalid[i0,i1][j0,j1][]=1-(numtype(img1)>0)
		img2[i0,i1][j0,j1][]+=isvalid	//add 1 if valid number, zero if otherwise
		for (i=i0; i<=i1; i+=1)
			for (j=j0; j<=j1; j+=1)
				for(zp=zp0; zp<=zp1; zp+=1)
					if (isvalid[i][j][zp])
						img[i][j][zp]= (img[i][j][zp]*img2[i][j][zp] + img1[i][j][zp])/(img2[i][j][zp]+1)
						if((i==iav)*(j==jav))
							print img[i][j][zp],img2[i][j][zp],img1[i][j][zp],img2[i][j][zp]+1
						endif
					endif
				endfor //zp
			endfor	//j
		endfor	//i
		doupdate
	endfor	//k
end

//adds an img (2d or 3d (z=3rd direction) ) to itself rotated NS times
//x0,x1,y0,y1,z0,z1 are ranges you want to modify
//	z0,z1 are ignored for 2Dim
//img should be NaN where you don't want to add
function rotSymm(NS,img,x0,x1,y0,y1,z0,z1)
	wave img
	variable ns, x0,x1,y0,y1,z0,z1
	wave gx,gy
	//duplicate/o img,img2,isvalid	//has same dimensionality (2 or 3) as input
	make/o/n=(dimsize(img,0),dimsize(img,1),ns) newx,newy,img1,isvalid
	setscale/p x dimoffset(img,0),dimdelta(img,0),"",newx,newy,img1,isvalid
	setscale/p y dimoffset(img,1),dimdelta(img,1),"",newx,newy,img1,isvalid
	make/o/n=(dimsize(img,0),dimsize(img,1)) img2
	setscale/p x dimoffset(img,0),dimdelta(img,0),"",img2
	setscale/p y dimoffset(img,1),dimdelta(img,1),"",img2

	newx[][][]=x*cos(r*2*pi/ns) -y*sin(r*2*pi/ns)
	newy[][][]=x*sin(r*2*pi/ns) +y*cos(r*2*pi/ns)
	variable is3d=dimsize(img,2)>1
	if(is3d)
		make/o/n=(dimsize(img,0),dimsize(img,1)) img2d
		setscale/p x dimoffset(img,0),dimdelta(img,0),"",img2d
		setscale/p y dimoffset(img,1),dimdelta(img,1),"",img2d
	endif
	variable i0,i1,j0,j1,zp0,zp1
	i0=round((x0 - DimOffset(img, 0))/DimDelta(img,0))
	i1=round((x1 - DimOffset(img, 0))/DimDelta(img,0))
	j0=round((y0 - DimOffset(img, 1))/DimDelta(img,1))
	j1=round((y1 - DimOffset(img, 1))/DimDelta(img,1))
	zp0=is3d*round((z0 - DimOffset(img, 2))/DimDelta(img,2))
	zp1=is3d*round((z1 - DimOffset(img, 2))/DimDelta(img,2))
	if (i0>i1)
		switchvar(i0,i1)
	endif
	if(j0>j1) 
		switchvar(j0,j1)
	endif
	if(zp0>zp1) 
		switchvar(zp0,zp1)
	endif
	variable i,j,k,iav=round((i0+i1)/2),jav=round((j0+j1)/2),zp
	print i0,i1,j0,j1,zp0,zp1
	
	for(zp=zp0; zp<=zp1; zp+=1)
		print zp,"/",zp1
		img2=0		//number of valid datapoints contributing to each pixel so far
		if(is3d)
			img2d=img[p][q][zp]
			img1[i0,i1][j0,j1][]=interp2d(img2d,newx,newy)
		else
			img1[i0,i1][j0,j1][]=interp2d(img,newx[p][q][r],newy[p][q][r])
		endif
		isvalid[i0,i1][j0,j1][]=(numtype(img1)==0)
		for (i=i0; i<=i1; i+=1)
			for (j=j0; j<=j1; j+=1)
				for(k=1; k<ns; k+=1)
					//print i,j,k
					img2[i][j]+=isvalid[p][q][k]	//add 1 if valid number, zero if otherwise
					if (isvalid[i][j][k])
						//rotated data is valid, so average it in
						if(numtype(img[i][j][zp])==0)
							//unrotated data is valid, average it with rotated data
							img[i][j][zp]= (img[i][j][zp]*img2[i][j] + img1[i][j][k])/(img2[i][j]+1)
						else
							//unrotated data is invalid, replace it with rotated data
							img[i][j][zp]=img1[i][j][k]
						endif
					else
					endif
				endfor //k			
			endfor	//j
		endfor	//i
	endfor //zp
	doupdate
end

//if r is NAN returns 0 else returns r
static function notNan(r)
	variable r
	if(numtype(r)>0)
		return r
	else
		return 0
	endif
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
