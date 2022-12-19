#pragma rtGlobals=1		// Use modern global access method.

//Menu "GraphMarquee", dynamic
//	"Horiz Expand + Vert Auto", smartautoscale(2)
//	"Vert Auto", smartautoscale(4)
//	"Vert Expand + Horiz Auto", smartautoscale(1)
//	"Horiz  Auto", smartautoscale(3)
//End

Menu "GraphMarquee", dynamic 
		 ASInRmenu(),doASInRmenu()
end

function /s ASInRmenu()
	string wn = winname(0,1)
	if(strsearch(wn,"ImageTool",0)<0)
		return "Horiz Expand + Vert Auto;Vert Auto;Vert Expand + Horiz Auto;Horiz  Auto"
	else
		return ""
	endif
end

function DOASInRmenu()
	GetLastUserMenuInfo
	strswitch(S_value)
		case "Horiz Expand + Vert Auto":
			smartautoscale(2)
			break
		case "Vert Expand + Horiz Auto":
			smartautoscale(1)
			break
		case 	"Horiz  Auto":
			smartautoscale(3)
			break
		case 	"Vert Auto":
			smartautoscale(4)
			break
	endswitch
end
		
// autoscale graph in one axis using only the data in the range of the other axis
function AutoscaleInRange(axisY,axisX,axis)
	string axisX,axisY
	variable axis
//	print axisY,axisX,axis
	string ti, wn,ya,xa
	if(cmpstr("",axisY)==0)
		axisY="left"
	endif
	if(cmpstr("",axisX)==0)
		axisY="bottom"
	endif
	variable aymin=+inf, aymax=-inf, axmin, axmax
	if(axis==1)
		if (strsearch( stringbykey("SETAXISFLAGS",axisinfo("",axisX),":",";"),"/A",0)>=0)
			return 0
		endif
		GetAxis/Q $axisX; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	else
		if (strsearch( stringbykey("SETAXISFLAGS",axisinfo("",axisY),":",";"),"/A",0)>=0)
			return 0
		endif
		GetAxis/Q $axisY; axmin=min(V_max, V_min); axmax=max(V_min, V_max)
	endif

//	print axmin,axmax
	string wnlist= tracenamelist("",";",1)
	variable n=itemsinlist(wnlist)
	variable i=0,ii,n1	
	do
		wn= StringFromList(i,wnlist)
	 	ti = traceinfo("",wn,0)
	 	ya=stringbykey("YAXIS",ti)
		xa=stringbykey("XAXIS",ti)
		if(cmpstr(ya,axisY)==0&&cmpstr(xa,axisx)==0)
			wave wref = TraceNameToWaveRef("", wn )
			wave xwref = Xwavereffromtrace("", wn )
			if(axis==1)
				if(waveexists(xwref))
					n1=numpnts(wref)
					for(ii=0;ii<n1;ii+=1)
						if(xwref[ii]<=axmax&&xwref[ii]>=axmin&&numtype(wref[ii])==0)
							aymin=min(aymin,wref[ii])
							aymax=max(aymax,wref[ii])
						endif
					endfor
				else
					wavestats /Q /R=(axmin,axmax) wref
					if( V_npnts>0 && v_numNaNs==0)
						aymin=min(aymin,V_min)
						aymax=max(aymax,V_max)
					endif
				endif
			else
				if(waveexists(xwref))
					n1=numpnts(wref)
					for(ii=0;ii<n1;ii+=1)
						if(wref[ii]<=axmax&&wref[ii]>=axmin&&numtype(xwref[ii])==0)
							aymin=min(aymin,xwref[ii])
							aymax=max(aymax,xwref[ii])
						endif
					endfor
				else
					n1=numpnts(wref)
					for(ii=0;ii<n1;ii+=1)
						if(wref[ii]<=axmax&&wref[ii]>=axmin)
							aymin=min(aymin,DimOffset(wref, 0)+DimDelta(wref,0)*ii)
							aymax=max(aymax,DimOffset(wref, 0)+DimDelta(wref,0)*ii)
						endif
					endfor
				endif
			endif
//			print wn , aymin,aymax,V_min,V_max

		endif
		i+=1
	while (i<n)
// print aymin,aymax
	if(aymin!=-inf&&aymax!=+inf)
		if(axis==1)
			setaxis $axisY , aymin,aymax	
		else
			setaxis $axisX , aymin,aymax	
		endif
	endif
end

Function smartautoscale(mode)
	variable mode
	String format
	GetMarquee/K 
	format = "flag: %g; left: %g; top: %g; right: %g; bottom: %g\r"
//	printf format, V_flag, V_left, V_top, V_right, V_bottom
	variable mtop=V_top,mleft=V_left,mright=V_right, Mbottom=v_bottom
	string al = axislist(""),axis,ai,AXTYPE,haxislist="",vaxislist=""
//	print al
	variable i,j,amax,amin,atop,aleft,aright,abottom
	for(i=0;i<itemsinlist(al);i+=1)
		axis = stringfromlist(i,al)
		ai = axisinfo("",axis)
		AXTYPE = stringbykey("AXTYPE",ai)
		GetAxis /Q $axis; amin=min(V_max, V_min); amax=max(V_min, V_max)
//		print axis,AXTYPE
		if (cmpstr(AXTYPE,"left")==0||cmpstr(AXTYPE,"right")==0)
			atop = axisvalfrompixel("",axis,mtop)
			abottom = axisvalfrompixel("",axis,mbottom)
			if ((atop<=amax&&atop>=amin)||(abottom<=amax&&abottom>=amin))
				if(mode==1)
					setaxis $axis abottom,atop
				endif
				vaxislist=addlistitem(axis,vaxislist)
			endif		
		else
			aleft = axisvalfrompixel("",axis,mleft)
			aright = axisvalfrompixel("",axis,mright)
			if ((aleft<=amax&&aleft>=amin)||(aright<=amax&&aright>=amin))
				if(mode==2)
					setaxis $axis aleft,aright
				endif
				haxislist=addlistitem(axis,haxislist)
			endif
		endif	
	endfor
	variable nh = itemsinlist(haxislist)
	variable nv = itemsinlist(vaxislist)
	string axisX,axisY
	for(i=0;i<nh;i+=1)
		axisX=stringfromlist(i,haxislist)
		for(j=0;j<nv;j+=1)
			axisY=stringfromlist(j,vaxislist)
			if((mode==1)+(mode==3))
				 AutoscaleInRange(axisY,axisX,2)
			else
				AutoscaleInRange(axisY,axisX,1)
			endif
		endfor
	endfor
End


