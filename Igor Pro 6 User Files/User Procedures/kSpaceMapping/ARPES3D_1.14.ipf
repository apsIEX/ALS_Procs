//////////
//  ARPES3D Package
// Written by Eli Rotenberg, Advanced Light Source, erotenberg@lbl.gov
/////////
//v.1.13  6/19/03  added polar2k
//v1.14  10/6/03 made apply disp correction a function

#pragma rtGlobals=1		// Use modern global access method.
//uses bandmap image in top graph to generate correction table 
#include <Strings as lists>
menu "kspace"
	submenu "Correct..."
		"Make Dispersion Correction"
		"Apply Dispersion Correction"
	end
	//"Polar2k..."	
	submenu "ky_kz"
		"pixel2theta..."
		"theta2k..."
	end
	"Symmetrize..."
end

proc Polar2k(wv,hv,axes)
	string wv; variable hv,axes
	prompt wv,"Wave to convert",popup   "-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")	
	prompt hv,"Photon Energy"
	prompt axes,"Axis BE/angle",popup "X/Y;Y/X"
	silent 1
	doPolar2k(wv,hv,axes)
	display; appendimage $(wv+"_kconv")
	print "new data stored in ",wv+"_kconv"
end

//assumes neg be=more bound
function doPolar2k(wv,hv,axes)
	string wv; variable hv,axes
	wave wvin=$wv
	variable nx,ny,nz,xi,yi,x0,xd,xn,x1
	if (axes==2)	//need to transpose
		xi=1; yi=0
	else
		xi=0;yi=1
	endif
	nx=round(dimsize(wvin,xi))
	ny=round(dimsize(wvin,yi))
	nz=dimsize(wvin,2)
	make/o/n=(nx,ny,nz) $(wv+"_kconv")
	wave wvout=$(wv+"_kconv")
	setscale/p y dimoffset(wvin,yi),dimdelta(wvin,yi),waveunits(wvin,yi),wvout
	setscale/p z dimoffset(wvin,2),dimdelta(wvin,2),waveunits(wvin,2),wvout
	x0=dimoffset(wvin,xi); xd=dimdelta(wvin,xi); xn=dimsize(wvin,xi); x1=x0+xd*(xn-1)
	variable kk0,kk1
	kk0=0.5124*sqrt(hv)*sin(x0*pi/180)
	kk1=0.5124*sqrt(hv)*sin(x1*pi/180)
	setscale/i x kk0,kk1,"k, 1/Å", wvout
	make/n=(nx,ny)/o polar2k_theta
	setscale/i x kk0,kk1,"k, 1/Å", polar2k_theta
	setscale/p y dimoffset(wvin,yi),dimdelta(wvin,yi),waveunits(wvin,yi),polar2k_theta
	polar2k_theta=asin(x/.5124/sqrt(hv+y))*180/pi
	variable i
	if(nz==0)
		if(axes==2) //transpose
			wvout[][][i]=interp2d(wvin,y,polar2k_theta[p][q])
		else
			wvout[][][i]=interp2d(wvin,polar2k_theta[p][q],y)
		endif
	else			
		for(i=0;i<nz;i+=1)
			duplicate/o/r=[][][i] wvin polar2k_temp
			redimension/n=(dimsize(wvin,0), dimsize(wvin,1)),polar2k_temp
			if(axes==2) //transpose
				wvout[][][i]=interp2d(polar2k_temp,y,polar2k_theta[p][q])
			else
				wvout[][][i]=interp2d(polar2k_temp,polar2k_theta[p][q],y)
			endif
		endfor
	endif
	killwaves polar2k_theta
end

	redimension/n=(dimsize(wvin,1),dimsize(wvin,0),dimsize(wvin,2))

proc Symmetrize(w,symmetry, rangeoption, xrange,yrange,zrange, trWave,trWavex)
	string w,symmetry, rangeoption, xrange,yrange,zrange,rangeOutOption,xrout,yrout,trWave,trWaveX
	prompt w,"Wave to symmetrize",popup  "-; -- 2D --;"+WaveList("!*_CT",";","DIMS:2")+"-; -- 3D --;"+WaveList("!*_CT",";","DIMS:3")	
	prompt symmetry, "Enter symmetry operation",popup "Mirror_LR;Mirror_UD;Mirror_LRUD;Translational;C2;C3;C4;C5;C6;C10"
	prompt rangeoption, "Data Range to Symmetrize", popup "Auto;Manual"
	prompt xrange,"xrange [\"start,end\"]"
	prompt yrange,"yrange [\"start,end\"]"
	prompt zrange,"zrange [\"start,end\"]"
	prompt trWave,"G-Vector y-wave",popup wavelist("*y",";","")
	prompt trWaveX,"G-Vector x-wave",popup wavelist("*x",";","")
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
		mirSymm(symmetry,$w,x0,x1,y0,y1,z0,z1)
	endif
	if(strsearch(symmetry,"Translational",0)>=0)
//		string wvx=getstrfromlist(trwave,0,"_")+"_x"
		string wvx=trWaveX
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

//adds an img (2d or 3d (z=3rd direction) ) reflected upon itself
//x0,x1,y0,y1,z0,z1 are ranges you want to modify
//	z0,z1 are ignored for 2Dim
//img should be NaN where you don't want to add
function mirSymm(mirSym,img,x0,x1,y0,y1,z0,z1)
	wave img
	variable x0,x1,y0,y1,z0,z1
	string mirSym //"Mirror
	string suffix=mirSym[7,999]
	variable isLR=(cmpstr(suffix,"LR")==0)
	variable isUD=(cmpstr(suffix,"UD")==0)
	variable isLRUD=(cmpstr(suffix,"LRUD")==0)
       variable numMir=1*(isLR || isUD) + 3*isLRUD
       
       //pad wave with data to make room for reflections
       make/o/n=(dimsize(img,0),dimsize(img,1)) img0
       setscale/p x,dimoffset(img,0),dimdelta(img,0),waveunits(img,0),img0
       print dimoffset(img,0),dimdelta(img,0),waveunits(img,0)
       setscale/p y,dimoffset(img,1),dimdelta(img,1),waveunits(img,1),img0
       print dimoffset(img,0),dimdelta(img,0),waveunits(img,0)

       if(isLR||isLRUD)
       	redimension/n=(dimsize(img0,0)*2,dimsize(img0,1),dimsize(img,2)) img
       	variable h0=dimoffset(img0,0), h1=h0+dimdelta(img0,0)*dimsize(img0,0)
       	x0=-1*max(abs(h0),abs(h1)); x1=max(abs(h0),abs(h1))
     		setscale/i x,x0,x1,waveunits(img0,0),img
       endif
       if(isUD||isLRUD)
       	redimension/n=(dimsize(img,0),dimsize(img0,1)*2,dimsize(img,2)) img
       	variable v0=dimoffset(img0,1), v1=v0+dimdelta(img0,1)*dimsize(img0,1)
       	y0=-1*max(abs(v0),abs(v1)); y1=max(abs(v0),abs(v1))
     		setscale/i y,y0,y1,waveunits(img0,1),img
       endif
       variable ii=dimsize(img,2)

       if(ii)
		for(ii=0;ii<dimsize(img,2);ii+=1)
			img0=img[p][q][ii]
			img[][][ii]=interp2d(img0,x,y)
		endfor
	else 
		img0=img[p][q]
		img=interp2d(img0,x,y)
	endif
	make/o/n=(dimsize(img,0),dimsize(img,1),numMir) newx,newy,img1,isvalid
	setscale/p x dimoffset(img,0),dimdelta(img,0),"",newx,newy,img1,isvalid
	setscale/p y dimoffset(img,1),dimdelta(img,1),"",newx,newy,img1,isvalid
	make/o/n=(dimsize(img,0),dimsize(img,1)) img2
	setscale/p x dimoffset(img,0),dimdelta(img,0),"",img2
	setscale/p y dimoffset(img,1),dimdelta(img,1),"",img2

	variable xmin,xmax,ymin,ymax
	if (isLR)
		newx[][]=-x; newy[][]= y
		xmax=max(abs(dimoffset(img,0)), abs(dimoffset(img,0)+dimdelta(img,0)*dimsize(img,0)))
		xmin=-1*xmax
		ymin=dimoffset(img,1)
		ymax=ymin+dimdelta(img,1)*dimsize(img,1)
	endif
	if (isUD)
		newx[][]=x; newy[][]=-y
		xmin=dimoffset(img,0)
		xmax=xmin+dimdelta(img,0)*dimsize(img,0)
		ymax=max(abs(dimoffset(img,1)), abs(dimoffset(img,1)+dimdelta(img,1)*dimsize(img,1)))
		ymin=-1*ymax

	endif
	if (isLRUD)
		newx[][][0]=-x; newy[][][0]= y
		newx[][][1]=-x; newy[][][1]= -y
		newx[][][2]=x; newy[][][2]= -y
		xmax=max(abs(dimoffset(img,0)), abs(dimoffset(img,0)+dimdelta(img,0)*dimsize(img,0)))
		xmin=-1*xmax
		ymax=max(abs(dimoffset(img,1)), abs(dimoffset(img,1)+dimdelta(img,1)*dimsize(img,1)))
		ymin=-1*ymax		
	endif
	
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
	if (x0>x1)
		switchvar(x0,x1)
	endif
	if(y0>y1) 
		switchvar(y0,y1)
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
				for(k=0; k<numMir; k+=1)
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
	
       ApplyDispersionCorrectionF($dat,$cwv,ovw,new)	
     
end
	
function ApplyDispersionCorrectionF(dat,cwv,ovw,newin)
	wave dat,cwv
	string newin
	variable ovw
	
	ovw-=1
	variable ndx=dimsize(dat,0),ndy=dimsize(dat,1)
	variable ncx=dimsize(cwv,0),ncy=dimsize(cwv,1)
	if((ndx==ncx)*(ndy==ncy))
		variable dim3d=dimsize(dat,2),k
		if(dim3d)
			make/o/n=(ndx,ndy) c_temp0, c_temp
			setscale/p x dimoffset(dat,0),dimdelta(dat,0),"",c_temp0
			setscale/p y dimoffset(dat,1),dimdelta(dat,1),"",c_temp0
			setscale/p x dimoffset(dat,0),dimdelta(dat,0),"",c_temp
			setscale/p y dimoffset(dat,1),dimdelta(dat,1),"",c_temp
			if(!ovw)
				duplicate/o dat $newin
			endif
			wave new=$newin
			do
				print k
				//ImageTransform /p=(k)  /D=c_temp0 getPlane dat
				c_temp0=dat[p][q][k]
				c_temp=interp2d(c_temp0,cwv[p][q][0], cwv[p][q][1])
				if(ovw)
					//dat[][][k]=c_temp[p][q]
					ImageTransform /p=(k)  /D=c_temp setPlane dat

				else
					//new[][][k]=c_temp[p][q]
					ImageTransform /p=(k)  /D=c_temp setPlane new

				endif
				k+=1
			while(k<dim3d)
			killwaves c_temp,c_temp0
		else
			duplicate/o dat c_temp
			c_temp=interp2d(dat,cwv[p][q][0], cwv[p][q][1])
			//c_temp=interpAng($dat,$cwv)
			if(ovw)
				dat=c_temp
			else
				if(strlen(newin)==0)
					duplicate/o c_temp $(nameofwave(dat)+"_corr")
				else
					duplicate/o c_temp $newin
				endif
			endif
			killwaves c_temp
		endif
	else
		doalert 0, "Sorry, the dimensions of the data and the correction array must match"	
	endif	
end


//------------------------------ THETA2K STUFF -----------------------------

//assumes x-index is currently arbitrary scaling, convert to deg per pixels
macro pixel2theta(wv,degperpixel,centerval,centerposn)
	string wv; variable degperpixel,centerval,centerposn
	prompt wv,"wave to convert pixels to theta"
	prompt degperpixel,"degrees per pixel"
	prompt centerval,"center value [degrees]"
	prompt centerposn,"center position [wave units]"
	silent 1;pauseupdate
	variable p0=(centerposn - DimOffset($wv, 0))/DimDelta($wv,0)
 	setscale/p x -p0*degperpixel+centerval,degperpixel,"deg",$wv
 end

	
//assumes input data has correctly scaled and offsetted theta in degeres
//photon energies are taken from wv_mono_eV 
macro theta2k(wv)
	string wv
	prompt wv, "wave to adjust" 
	silent 1; pauseupdate
	variable ndims=wavedims($wv)
	variable n0=dimsize($wv,0), n1=dimsize($wv,1), n2=dimsize($wv,2), n3=dimsize($wv,3)
	string wvout=wv+"_t2k"
	string wvhv=wv+"_mono_ev"
	string lwlvnm=stringbykey("LWLVNM",note($wv),"=")
	
	if(cmpstr(lwlvnm[0,5], "Photon")==0)
		//indices are [theta][BE][k]
		if (ndims!=3)
			abort "Error: expecting three dimensions [theta][BE][k]
		endif
		if (exists(wvhv)==0)
			abort "Expected wave "wvhv
		endif
		make/o/n=(dimsize($wvhv,0)), kk
		kk=0.5124*sqrt($wvhv)
		//don't worry about beta since beta does not enter into the mapping theta->kx
		//variable/g t2k_beta0=str2num(stringbykey("CMOTOR1",note($wv),"="))
		//gett2k_beta0(wv,)
		duplicate/o $wv $wvout
		//get k range
		wavestats/q kk
		variable kmin=v_min,kmax=v_max
		variable k0=kmax*sin(dimoffset($wv,0)*pi/180)
		variable k1=kmax*sin((dimoffset($wv,0)+(dimsize($wv,0)-1)*dimdelta($wv,0))*pi/180)
		make/o/n=(dimsize($wvout,0),dimsize($wvhv,0)) t2k_theta
		setscale/i x k0,k1,"kpar",$wvout, t2k_theta
		t2k_theta=asin(x/kk[q])*180/pi
		$wvout=interp3d($wv,t2k_theta[p][r],y,z)
		setscale/i z kk[0],kk[n2-1],"kout",$wvout
	endif
	
	if(cmpstr(lwlvnm[0,4], "ky-kz")==0)
		//must be ky-kz scan
		if(ndims==3) 
			//indices are [theta][BE][ky]
			variable monoev=numberbykey("MONOEV",note($wv),"=")
			//first convert ky direction angle to beta since ky is strictly only true at theta=0 degrees
			make/o/n=(dimsize($wv,2)) t2k_beta
			variable kk0=dimoffset($wv,2), kkd=dimdelta($wv,2),km=.5124*sqrt(monoev)
			t2k_beta=asin((kk0+p*kkd)/km)*180/pi
			duplicate/o $wv $wvout
			duplicate/o/r=[][][0,0] $wv t2k_2d,t2k_2din
			redimension/n=(dimsize($wv,0),dimsize($wv,1)) t2k_2d,t2k_2din
			variable k0=km*sin(dimoffset($wv,0)*pi/180)
			variable k1=km*sin((dimoffset($wv,0)+(dimsize($wv,0)-1)*dimdelta($wv,0))*pi/180)
			make/o/n=(dimsize($wvout,0),dimsize($wvout,1)) t2k_theta
			setscale/i x k0,k1,"kpar",$wvout,t2k_2d,t2k_theta	
			setscale/p y dimoffset($wv,1),dimdelta($wv,1), t2k_theta
			//x is kpar strictly at BE=0
			t2k_theta=asin(x/km)*180/pi
			t2k_theta=asin(x/(0.5124*sqrt(  (km/.5124)^2+y)))*180/pi
			iterate(dimsize($wv,2))
				t2k_2din=$wv[p][q][i]
				t2k_2d=interp2d(t2k_2din,t2k_theta[p][q],y)
				$wvout[][][i]=t2k_2d[p][q]
			loop
			
			
		else
			//indices are [theta][BE][ky][k]
			if (ndims!=4)
				abort "Error: expecting four dimensions [theta][BE][ky][k]
			endif
		endif
	endif
	
end

proc getT2k_beta0(wv,b0)
	string wv; variable b0=t2k_beta0
	prompt wv,"Wave name"
	prompt b0,"Beta value, degrees"
	variable/g t2k_beta0=b0
end

//-------------------------------------------------

//interpolation for when there is no energy (y) correction
//too slow
function interpAng(d,c)
	wave d,c
	variable j,nx=dimsize(d,0), ny=dimsize(d,1)
	make/n=(nx)/o iax
	setscale/p x dimoffset(d,0),dimdelta(d,0),"",iax
	iax=d(c[p][q][0])[q]
end


