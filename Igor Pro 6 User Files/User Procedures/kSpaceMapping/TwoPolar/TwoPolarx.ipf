#pragma rtGlobals=1		// Use modern global access method.
function/s new2Polar()
	string df=uniquename("TwoPolar",11,0)
	newdatafolder $df
	df=":"+df+":"
	variable/g $df+"theta0", $df+"beta0", $df+"gridkx",$df+"gridky",$df+"gridtheta",$df+"gridbeta",$df+"gridphi"
	return df
end

//gets wave information from topmost image
macro TwoPolar(w,degperpixel)
	string w
	variable degperpixel=.031
	prompt w,"wave to use",popup wavelist("*",";","win:")
	string df=new2Polar()
	print df
	string w1=w+"_"+cleanupname(stringfromlist(0,$w+"_indvars",","),0) //first indep variable
	string w2=w+"_"+cleanupname(stringfromlist(1,$w+"_indvars",","),0) //second indep variable
	string ua=df+"uniqueAngle"
	duplicate/o $w1 $ua
	uniqueValues($w1,$ua)
	variable dAngle=abs($ua[1]-$ua[0])
	variable numangle=numpnts($ua)				//# of coarse angle steps
	variable numangle2=numpnts($w1)/numangle	//#of fine angle steps
	variable numpixelsUse=abs(dAngle/degPerPixel)  //# nonoverlapping pixels
	if (numPixelsUse>dimsize($w,0))
		numPixelsUse=dimsize($w,0)
	endif
	variable startpixel=(dimsize($w,0)-numPixelsUse)/2
	if (startpixel<0)
		startpixel=0
	endif
	string cd=df+"combData"					//wave containing side by side slices
	make/n=(abs((numangle+1)*dAngle/degPerPixel), numangle2) $cd 	//+1 since  always no overlapping data on extreme slices
	SetScale/p x -1*startpixel*degPerPixel-dangle/2,degPerPixel,"", $cd
	duplicate/o $w $(df+w+"_xscaled")
	Setscale/p x -0.5*numPixelsUse*degPerPixel,degPerPixel,"" $(df+w+"_xscaled")	//like raw data wave, with x scaled to angle units
	print numAngle, numAngle2, dangle, numPixelsUse, StartPixel,degPerPixel
	combineStrips($w,$cd, numAngle, numAngle2, dangle, numPixelsUse, StartPixel,degPerPixel)
end

function combineStrips(w,cd,numAngle, numAngle2, dAngle, numPixelsUse, StartPixel,degPerPixel)
	wave w,cd
	variable numAngle, numAngle2, dAngle, numPixelsUse, StartPixel,degPerPixel
	variable i,st,en
	for (i=0;i<numAngle;i+=1)
		if (i==0) //first strip, use extra on lhs
			st=0
			en=st+(numpixelsUse+startpixel-1)
		else
			st=startpixel+(i*abs(dAngle)/degPerPixel)
			if  (i==numangle-1) //last strip, use extra on rhs
				en=st+(numpixelsUse+startpixel-1)
			else
				en=st+(numpixelsUse-1)
			endif
		endif
		//variable pst=(st - DimOffset(cd, 0))/DimDelta(cd,0)
		//variable pen=(en - DimOffset(cd, 0))/DimDelta(cd,0) 
		cd[st,en][*]=w[p-st+(i!=0)*startpixel][q+i*numangle2]
	endfor
end

function uniqueValues(win, wout)
	wave win, wout
	wout=0
	variable j=0, lastj=0,v,ni
	wout[0]=win[0]
	do
		v=uniqueValue(win,lastj,ni)
		print v
		lastj=ni
		j+=1
		if (wout[j-1]!=v)    //(!almostEqual(wout[j-1],v))
			wout[j]=v
		else
			redimension/n=(j) wout
			return(0)
		endif
	while ((j<numpnts(win))*(v!=wout[j-1]))
end	
	
//finds first unique value of wave w starting from point n
//returns w[n] if error or no unique next value
 function uniqueValue(w,n,ni)
	wave w; variable n, &ni
	variable i=n+1, val=w[n], found=0
	do
		if (!almostEqual(w[i],w[n]))
			found=1
			val=w[i]
		endif
		i+=1
	while((found==0)*(i<numpnts(w)))
	ni=i
	return(val)
end
			
function almostEqual(a,b)
	variable a,b
	return abs((a-b)/(a+b)) < 1e-2
end	