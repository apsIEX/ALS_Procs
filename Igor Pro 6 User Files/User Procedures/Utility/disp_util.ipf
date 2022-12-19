// File: disp_util	12/1/96  J. Denlinger

#pragma rtGlobals=1		// Use modern global access method.
//#include <Strings As Lists>
//#include "List_util"
#include "Image_util"

menu "Plot"
	"-"
	"PlotList"
	"MergeList"
	"KillList"
end

//function rpx( wv, iwv )
//=========
//replace i-th trace in graph with y vs y_x
//	wave wv
//	variable iwv
//	PauseUpdate
//	string yw=NameOfWave(wv)
//	string xw=yw+"_x"
//	string ywold=WaveName("", iwv, 1)
	//	string xwold=XWaveName("", ywold)
//	ReplaceWave/X trace=$ywold   $xw
//	ReplaceWave     trace=$ywold   $yw
//end

Proc PlotList( wvlst, xwn, disp, xlbl, ylbl, winnam )
//---------------
//assumes ";" is the list separator
	string wvlst, xwn
	variable disp
	string xlbl=StrVarOrDefault("root:PLOT:xlabel","x"), ylbl=StrVarOrDefault("root:PLOT:ylabel","y")
	string winnam=StrVarOrDefault("root:PLOT:winnam0","")
	prompt wvlst, "Wave List, ;=separator", popup, StringList("*lst",";")
	prompt disp, "Method", popup, "Display;Append"
	prompt xwn, "X-wave(s): <>=scaled, <_x>=use extension"
	prompt xlbl, "X-axis label"
	prompt ylbl, "Y-axis label"
	
	PauseUpdate; Silent 1
	disp=abs(disp)
	NewDataFolder/O root:PLOT
	String/G root:PLOT:xlabel=xlbl, root:PLOT:ylabel=ylbl, root:PLOT:winnam0=winnam
	
	//if (ItemsInList(wvlst, ";")==1)
	//	wvlst=$wvlst
	//endif
	
	variable xscale=1+(strlen(xwn)==0)	//1=exists, 2=scaled
	if (cmpstr(xwn[0,0],"_")==0)
		xwn=StringFromList(0, $wvlst,";")+xwn
	endif
	variable idx=0
	string wn
	do
		wn=StringFromList(idx, wvlst,";")
		//print wn
		if (exists(wn)!=1)
			break
		endif
		if ((idx==0)*(disp==1))
			if (xscale==2)
				display $wn
			else
				display $wn vs $xwn
			endif
			//Legend/F=0
			ModifyGraph tick=2, minor=1, sep=8
			ModifyGraph fSize=12
			ModifyGraph mirror=1
			ModifyGraph/Z mirror(left)=2
			ModifyGraph nticks(left)=3
			ModifyGraph sep(left)=10
				//XPS_Style2(xlbl, ylbl)
			Label/Z left ylbl
			Label/Z bottom xlbl
			if ((strlen(winnam)>0)*(checkname(winnam,6)==0))
				DoWindow/C $winnam
			endif
		else
			if (xscale==2)
				append $wn
			else
				append $wn vs $xwn
			endif
		endif
		idx+=1
	while( idx<100)
End

Proc KillList( wvlstnam )
//---------------
//assumes ";" is the list separator
	string wvlstnam
	prompt wvlstnam, "Wave List, ;=separator", popup, "TopGraph;"+StringList("*lst",";")
	
	PauseUpdate; Silent 1
	string wvlst
	if (cmpstr(wvlstnam,"TopGraph")==0)
		wvlst=WaveList("*", ";", "WIN:")
		xwn=XWaveName("", WaveName("",0,1))
		DoWindow/K $WinName(0,1)
	else
		if (ItemsInList(wvlstnam, ";")==1)
			wvlst=$wvlstnam
		endif
	endif
	variable idx=0
	string wn
	do
		wn=StringFromList(idx, wvlst, ";")
		if (exists(wn)!=1)
			break
		endif
		killwaves $wn
		idx+=1
	while( idx<100)
End


Proc MergeList( wvlstnam, xwn, ywn, imn )
//---------------
//assumes ";" is the list separator
//use x-scaling from first in list
	string wvlstnam, xwn, ywn, imn
	prompt wvlstnam, "Wave List, ;=separator", popup, "TopGraph;"+StringList("*lst",";")
	prompt xwn, "X-wave for scaling: <>=scaled (first in list)"
	prompt ywn, "Y-wave for scaling: <>=point scaling"
	prompt imn, "Output 2D array name"

	PauseUpdate; Silent 1
	string wvlst
	if (cmpstr(wvlstnam,"TopGraph")==0)
		wvlst=WaveList("*", ";", "WIN:")
		xwn=XWaveName("", WaveName("",0,1))
	else
		if (ItemsInList(wvlstnam, ";")==1)
			wvlst=$wvlstnam
		endif
	endif
	string wn=StringFromList(0, wvlst, ";")
	variable nx=numpnts($wn), ny=ItemsInList( wvlst,";")
	make/o/n=(nx, ny) $imn
	if (strlen(xwn)==0)
		CopyScales/P $wn, $imn
	endif
	print imn, xwn, ywn
	 ScaleImg( $imn, xwn, ywn )
	//print nx, ny, wvlst
	variable idx=0
	do
		wn=StringFromList( idx, wvlst, ";")
		if (exists(wn)!=1)
			break
		endif
		if (numpnts($wn)==nx)
			$imn[][idx] = $wn[p]
		else
			print "Wave length mismatch "+wn		//interpolate
			xwn=XWaveName("", wn)
			if (strlen(xwn)==0)
				$imn()[idx] = $wn(x)	
			else
				$imn()[idx] = interp( x, $xwn, $wn)
			endif
		endif
		idx+=1
	while( idx<ny)
	if (idx<ny)
		print "fewer valid waves than in list:", idx,"<", ny
		redimension/n=(nx, idx) $imn
	endif
	print "Created: "+imn+" ("+num2str(nx)+"x"+num2str(idx)+")"
end

