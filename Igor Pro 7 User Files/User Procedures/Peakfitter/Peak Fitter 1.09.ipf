#pragma rtGlobals=1		// Use modern global access method.

#include <Strings as Lists>
#include <NumInList>
#include <Keyword-Value>
#include "colorTables"
#include "PFnewfunctions1.09"

//menu "PF"
//	"PFstartup"
//end

proc PFstartup()
	setdatafolder root:
	newdatafolder/o PF
	dowindow/f PFPanel
	if (v_flag==0)
		PFPanel()
	endif
end

proc AreYouSure(yn)
	variable yn
	prompt yn,"Are you sure?",popup "yes;no"
	if (yn==2)
		abort
	endif
end

Function startButtonFunc(ctrlName) : ButtonControl
	String ctrlName
	variable/g v_chisq
	execute "AreYouSure()"
	NewDataFolder/o PF
	SetDataFolder PF
	variable/g numPks=0,npnts=nan, hasFE=0
	make/o/n=(7,numPks+1) fitparms   // n=(parameters, numpeaks)
	make/o/n=(7,numPks+1,2) minmax
	make/o/n=(7,numPks+1,3) hold
	make/o/n=(numPks+1) fittype
	make/o/n=0 hold1store, convstore
	fittype[0]=2 //linear
	make/o/n=(3,21) DSGtable
	string/g winNam=GetStrFromList(winlist("*",";","WIN:1"),0,";") //extract name of window
	string/g xwv="", ywv=""
	make/o/t/n=7 parmnames
	parmnames={"POS", "AMP", "LW", "GW", "ASYM", "SPLIT", "RATIO"}
	variable/g channel, peak=1, oldpeak=-1,LWguess=0.1, GWGuess=.05, ASYMguess=0.1,SPLITguess=1.0,RATIOguess=0.5,nextPkAdd=0
	variable/g chanAutoHist=0	//if true auto recall history when recalling channel
	variable/g g_currPk,v_fititerstart=-1  // for lor-don-gauss function
	variable/g isSeries=0
	
	variable/g LW, GW, ASYM, POS, AMP
	variable/g SPLIT, RATIO
	
	variable/g posRelPeak, ampRelPeak
	variable/g LWrelPeak, GWrelPeak, ASYMrelPeak
	variable/g splitRelPeak, ratioRelPeak
	
	variable/g posRelVal, ampRelVal
	variable/g LWrelVal, GWrelVal, ASYMrelVal
	variable/g splitRelVal, ratioRelVal
	
	variable/g posLo, ampLo
	variable/g LWlo, GWlo, ASYMlo
	variable/g splitlo, ratiolo
	
	variable/g posHi, ampHi
	variable/g LWhi, GWhi, ASYMhi
	variable/g splithi, ratiohi
	
	variable/g bkgd0,bkgd1,bkgd2,bkgd3,bkgd4,bkgd5,bkgd6
	variable/g FEPos, FEWidth
	string/g lastExportName
	
	variable/g offsetStackPF, shiftStackPF
	
	hold[] [] [0]=0
	hold[] [] [1]=nan
	hold[] [] [2]=nan
	minmax=nan
	
	fitparms[][0]=0           //  set background to line, values zero

 	setDataFolder :: 
 	execute "getWaves()"
 	setDatafolder :PF
 	if(isSeries)
 		string dwv="Singlechannel"
 	else
 		dwv="::"+ywv
 	endif
 	duplicate/o $dwv bkgdRgn, bkgdWeight, bkgdFit, peakFit, peak1,peak2,peak3,peak4,peak5,peak6,peak7,peak8,peak9,peak10,peak11,peak12,peak13,peak14,peak15,peak16,peak17,peak18,peak19,peak20
	bkgdfit=nan ; bkgdrgn=nan; bkgdweight=0


	execute "updatePFPanel()"
	
	SetDataFolder ::
End

proc doLogoWindow()
	silent 1; pauseupdate
	dowindow/f PFLogo
	if (v_flag==0)
		if (exists(":PF:logo")==0)
			pathinfo igor
			NewPath/q/o PFPath s_path+"User Procedures:PeakFitter"
			ImageLoad/P=PFPath/T=tiff/N=logo/o "logo.tif"
			movewave logo :PF:
			movewave logocmap :PF:
		endif
		display
		DoWindow/C/T PFLogo,"PFLogo"
		appendimage :PF:logo
		ModifyImage logo cindex= :PF:logoCMap
		setaxis/a/r left
		ModifyGraph width=906/2,height=348/2,nticks=0, wbrgb=(65535,49157,16385)
		TextBox/C/N=text0 "\JCPeak Fitter Version "+:PF:VERSION+"\r(c) 2002 Eli Rotenberg, Lawrence Berkeley National Laboratory";DelayUpdate
		AppendText "\\K(65535,0,0)May be distributed freely assuming this panel is included as-is.";DelayUpdate
		AppendText "\\K(1,4,52428)Email bugs/suggestions to erotenberg@lbl.gov"
		AppendText "\\K(1,4,52428)Latest version at http://www-bl7.lbl.gov/BL7/software/software.html"

		TextBox/C/N=text0/X=0.55/Y=2.96/A=MB/E/F=0/B=1
	endif
end
	
		
//must be in folder above PF folder
proc getWaves(yw)
	string yw
	prompt yw,"y-wave",popup wavelist("*",";","WIN:"+:PF:winnam)
	silent 1; pauseupdate
	variable np=dimsize($yw,0)
	variable method
	if(wavedims($yw)==2)
		//wave is a matrix
		if(dimsize($yw,1)==1)
			:PF:isSeries=0	//just a trivial one-column matrix
		else
			:PF:isSeries=1	//series fit
		endif
	else
		:PF:isSeries=0
	endif
	string/g :PF:ywv=yw, :PF:xwv=xwavename(winnam,ywv)
	variable/g :PF:nchan
	if(:PF:isSeries)
	 	string/g :PF:axName="LChannel" //name for axis for spectral data
	 	string/g :PF:g_sd=yw
		:PF:xwv=xwavename(winnam, ywv)  //ywv+"_x"
		:PF:nchan=dimsize($yw,1)
		:PF:ywv=":PF:SingleChannel"
		make/o/n=(dimsize($:PF:g_sd,0)) :PF:SingleChannel
		string ss=waveinfo($:PF:g_sd,0)
		SetScale/P x dimoffset($:PF:g_sd,0),dimdelta($:PF:g_sd,0),"", :PF:singlechannel
		string/g :PF:g_indname, :PF:g_indunits
		variable/g :PF:npnts=np
		variable/g :PF:g_indstart=dimoffset($g_sd,1), :PF:g_indincr=dimdelta($g_sd,1)
		//initializeSeries(yw,,,,)
		//setdatafolder ::
		//dowindow/f $:PF:winnam
		//append/l=$:PF:axname :PF:singlechannel vs $(:PF:xwv)
		appwv(:PF:xwv,":PF:singlechannel",:PF:winnam)
		ModifyGraph/w=$:PF:winnam mode(SingleChannel)=3,marker(SingleChannel)=18,msize(SingleChannel)=2
		ModifyGraph/w=$:PF:winnam axisEnab(LChannel)={0.55,1},freePos(LChannel)=0
		SetVariable channel,pos={ 100,0},size={100,14},proc=SetVarChannel,title="channel",win=$:PF:winnam
		SetVariable channel,fSize=9,limits={0,:PF:nchan-1,1},value= :PF:channel,win=$:PF:winnam
		Button showFitter,pos={215,0},size={50,20},title="FitPanel",proc=fitterwindowproc,win=$:PF:winnam
		Button showHistory,pos={270,0},size={50,20},proc=HistoryWindowProc,title="History",win=$:PF:winnam
		variable/g :PF:whichHistBrowse=0
		variable startChan=round(:PF:nchan/2)
		
		string dwv="Singlechannel"
 		make/o/n=(:PF:nchan) :PF:hist_npks; :PF:hist_npks=nan
		make/o/n=(:PF:nchan) :PF:hist_chisq; :PF:hist_chisq=nan
		make/o/n=(:PF:nchan) :PF:hist_isStored; :PF:hist_isStored=0
 		make/o/n=(20,:PF:nchan) :PF:hist_fittype; :PF:hist_fittype=nan
	 	make/o/n=(7,20,:PF:nchan) :PF:hist_fitparms; :PF:hist_fitparms=nan
 		make/o/n=(7,20,3,:PF:nchan) :PF:hist_hold
		make/o/n=(:PF:nchan+1,20) :PF:hist_POS, :PF:hist_AMP, :PF:hist_LW
		make/o/n=(:PF:nchan+1,20) :PF:hist_GW, :PF:hist_ASYM, :PF:hist_SPLIT, :PF:hist_RATIO
		make/o/n=(:PF:nchan+1,20) :PF:hist_indvar
		:PF:hist_indvar[][]=p*g_indincr+g_indstart
		make/o/n=(:PF:nchan+1,20) :PF:browse_y, :PF:browse_x
		
		ModifyGraph/w=$:PF:winnam axisEnab(left)={0,0.45}
		//make cursor line and enable live update
		make/o/n=2 :PF:csrx :PF:csry
		:PF:csrx={-inf,inf}
		:PF:csry={hist_indvar[startchan][0],hist_indvar[startchan][0]}
		appwvleft(":PF:csrx", ":PF:csry", :PF:winnam)
		ModifyGraph/w=$:PF:winnam rgb(csry)=(0,65535,65535)
		SetWindow $:PF:winnam hook=imgFitHookFcn, hookevents=3
		copychannel(startChan)
		
		//append position history
		:PF:hist_pos=nan
		
		appwvleft(":PF:hist_POS", ":PF:hist_indvar", :PF:winnam)
		ModifyGraph mode(hist_indvar)=3,marker(hist_indvar)=8,msize(hist_indvar)=2;DelayUpdate
		ModifyGraph rgb(hist_indvar)=(65535,0,0)
	else
 		string/g :PF:axName="Left"
		:PF:nchan=1
		variable npnp=numpnts($:PF:ywv)
		:PF:npnts=npnp
	endif
	dowindow/f $:PF:winnam
	if (:PF:isSeries==0)
		modify rgb($:PF:ywv)=(0,0,0)
	else
		modify rgb(singlechannel)=(0,0,0)
	endif
	showinfo	
end

function imgFitHookfcn (infostr)
//===============
//  CMD/CTRL key + mouse motion = dynamical update of cross-hair
//  Modifier bits:  0001=mousedown, 0010=shift  , 0100=option/alt, 1000=cmd/ctrl
	string infostr
	variable mousex,mousey,ax,ay, modif
	modif=numbykey("modifiers", infostr)  & 15
	svar wn=:PF:winnam
	wave hi=:PF:hist_indvar, csry=:PF:csry
	nvar nc=:PF:nchan, ch=:PF:channel
	if (((modif==9)+(modif==11))*(strsearch(infostr,"EVENT:mouse",0)>0))   //mousedown * (cmd/ctrl or cmd/ctrl+shift)
		mousey=numbykey("mousey",infostr)
		ay=axisvalfrompixel(wn,"left",mousey)
		//convert indvar to channel#
		findlevel/q hi forcerange(ay,hi[0][0],hi[nc-1][0])
		ch=x2pnt(hi,v_levelx)
		csry=hi[ch][0]
		execute "copychannel("+num2str(ch)+")"
		if (modif==11)
			execute "doHistory2Fit()"
		endif
		execute "updatePFPanel()"
		return 1
	else
		return 0
	endif
end

function forcerange(xx,x0,x1)
	variable xx,x0,x1
	if (xx<min(x0,x1))
		xx=x0
	endif
	if(xx>max(x0,x1))
		xx=x1
	endif
	return xx
end

//entry: folder above PF
//exit : same
function copyChannel(which)
	variable which
	
	svar ss=:PF:g_sd//, sx=:PF:xwv
	wave sc=:PF:SingleChannel, gy=$ss//, scx=$sx
	sc=gy[p+which*dimsize(gy,0)]    //  gy[p+which*numpnts(scx)]
	nvar chan=:PF:channel
	chan=which
	wave csry=:PF:csry, hi=:PF:hist_indvar
	:csry={hi[which][0],hi[which][0]}

	//dowindow/f PeakFitGraph
	//if(wintype("PeakFitGraph"))
	//	textbox/c/n=chan "Channel #"+num2str(which)
	//endif
end

;---------------------------------------------
proc updatePFPanel()
//entry: must be in PF folder
//exit: in PF folder
	silent 1;pauseupdate
	variable needexit=0
	if(streq(getdatafolder(0),"PF")==0)
		setdatafolder PF
		needExit=1
	endif

	bkgd0=fitparms[0][0];		checkbox fix0 value=hold[0][0][0], win=PFPanel
	bkgd1=fitparms[1][0];		checkbox fix1 value=hold[1][0][0], win=PFPanel
	bkgd2=fitparms[2][0];		checkbox fix2 value=hold[2][0][0], win=PFPanel
	bkgd3=fitparms[3][0];		checkbox fix3 value=hold[3][0][0], win=PFPanel
	bkgd4=fitparms[4][0];		checkbox fix4 value=hold[4][0][0], win=PFPanel
	//bkgd5=fitparms[5][0];		checkbox fix5 value=hold[5][0][0], win=PFPanel
	//bkgd6=fitparms[6][0];		checkbox fix6 value=hold[6][0][0], win=PFPanel
	FEPos=fitparms[5][0];		checkbox fixFEPOS value=hold[5][0][0], win=PFPanel
	FEWidth=fitparms[6][0];		checkbox fixFEWid value=hold[6][0][0], win=PFPanel
	
	disableBkgdParms(0)
	checkbox  FECheckBox value=hasFE,win=PFPanel
	disableFEParms(hasFE)
	
	if (peak >numpks)
		peak=numpks
	endif
	if (peak<1)
		peak=1
	endif
	SetVariable peak,win=PFPanel, limits={1,numpks+(numpks==0)*1,1}
	if(numpks!=0)
		pos=fitparms[0][peak];		poslo=minmax[0][peak][0];	poshi=minmax[0][peak][1] 	
		amp=fitparms[1][peak]; 	amplo=minmax[1][peak][0];	amphi=minmax[1][peak][1]
		lw=fitparms[2][peak];		lwlo=minmax[2][peak][0];	lwhi=minmax[2][peak][1]
		gw=fitparms[3][peak];		gwlo=minmax[3][peak][0];	gwhi=minmax[3][peak][1]
		asym=fitparms[4][peak];	asymlo=minmax[4][peak][0];	asymhi=minmax[4][peak][1]
		split=fitparms[5][peak];	splitlo=minmax[5][peak][0];	splithi=minmax[5][peak][1]
		ratio=fitparms[6][peak];	ratiolo=minmax[6][peak][0];	ratiohi=minmax[6][peak][1]
		button csr2thispk,win=PFPanel,disable=0
		button killpk,win=PFPanel,disable=0
		setvariable peak,win=PFPanel,disable=0
		popupmenu thispktyp,win=PFPanel,disable=0,mode=abs(fittype[peak])
	else
		pos=nan	;poslo=minmax[0][peak][0];	poshi=minmax[0][peak][1] 	
		amp=nan	;amplo=minmax[1][peak][0];	amphi=minmax[1][peak][1]
		lw=nan		;lwlo=minmax[2][peak][0];	lwhi=minmax[2][peak][1]
		gw=nan		;gwlo=minmax[3][peak][0];	gwhi=minmax[3][peak][1]
		asym=nan	;asymlo=minmax[4][peak][0];	asymhi=minmax[4][peak][1]
		split=nan	;splitlo=minmax[5][peak][0];	splithi=minmax[5][peak][1]
		ratio=nan	;ratiolo=minmax[6][peak][0];	ratiohi=minmax[6][peak][1]
		button  csr2thispk,win=PFPanel,disable=2
		button killpk,win=PFPanel,disable=2
		setvariable peak,win=PFPanel,disable=1
		popupmenu thispktyp,win=PFPanel,disable=0
	endif

	if(isSeries==0)
		button fitspectra,win=PFPanel,disable=2
		button hist2fit,win=PFPanel,disable=2
		button fit2hist,win=PFPanel,disable=2
		button seriesreport,win=PFPanel,disable=2
	else
		button fitspectra,win=PFPanel,disable=0
		button hist2fit,win=PFPanel,disable=0
		button fit2hist,win=PFPanel,disable=0
		button seriesreport,win=PFPanel,disable=0
	endif
		
	SetVariable channel win=PFPanel, limits={0,nchan,1}
	PopupMenu  poshold win=PFPanel,mode=hold[0][peak][0]+1 ;		posrelpeak=hold[0][peak][2];		posrelval=hold[0][peak][1]
	PopupMenu amphold win=PFPanel,mode=hold[1][peak][0]+1 ;		amprelpeak=hold[1][peak][2];		amprelval=hold[1][peak][1]
	PopupMenu lwhold win=PFPanel,mode=hold[2][peak][0]+1 ;		lwrelpeak=hold[2][peak][2];		lwrelval=hold[2][peak][1]
	PopupMenu gwhold win=PFPanel,mode=hold[3][peak][0]+1 ;		gwrelpeak=hold[3][peak][2];		gwrelval=hold[3][peak][1]
	PopupMenu asymhold win=PFPanel,mode=hold[4][peak][0]+1 ;		asymrelpeak=hold[4][peak][2];		asymrelval=hold[4][peak][1]
	PopupMenu splithold win=PFPanel,mode=hold[5][peak][0]+1 ;		splitrelpeak=hold[5][peak][2];		splitrelval=hold[5][peak][1]
	PopupMenu ratiohold win=PFPanel,mode=hold[6][peak][0]+1 ;		ratiorelpeak=hold[6][peak][2];		ratiorelval=hold[6][peak][1]
	disableparms("POS",0);		showoptions("POS")
	disableparms("AMP",0);		showoptions("AMP")
	disableparms("LW",0);			showoptions("LW")
	disableparms("GW",0);			showoptions("GW")
	disableparms("ASYM",0);		showoptions("ASYM")
	disableparms("SPLIT",0);		showoptions("SPLIT")
	disableparms("RATIO",0);		showoptions("RATIO")
	

	PopupMenu background win=PFPanel,mode=abs(fittype[0])
	setdatafolder ::

	updateXPSFit(0)
	setdatafolder PF
	controlupdate/a/w=PFPanel
	setPeakColors()

	if(needExit)
		setdatafolder ::
	endif
end

//depending on fit hold setting, shows appropriate optional parameters
//should be in PF
proc showoptions(pr)
	string pr
	variable ishidden, dis
	controlinfo/w=PFPanel $("edit"+pr)
	ishidden=(v_disable==1)
	controlinfo/w=PFPanel $(pr+"hold")
	if(v_value <3) //free or fixed
		setvariable $(pr+"lo"),win=PFPanel,disable=1
		setvariable $(pr+"hi"),win=PFPanel,disable=1
		setvariable $(pr+"relval"),win=PFPanel,disable=1
		setvariable $(pr+"relpeak"),win=PFPanel,disable=1
		if (!isHidden)
			setvariable $("edit"+pr), win=PFPanel,disable=0
		endif
	endif
	if (v_value==3)	//between
		if (numtype($(pr+"lo"))==2)	//nan
			$(pr+"lo")=$pr
		endif
		if(numtype($(pr+"hi"))==2)  //nan
			$(pr+"hi")=$pr
		endif
		setvariable $(pr+"relval"),win=PFPanel,disable=1
		setvariable $(pr+"relpeak"),win=PFPanel,disable=1
		if (!isHidden)
			setvariable $("edit"+pr), win=PFPanel,disable=0
			dis=0
		else
			dis=1
		endif
		setvariable $(pr+"lo"),win=PFPanel,disable=dis
		setvariable $(pr+"hi"),win=PFPanel,disable=dis

	endif
	if(v_value==4) //relative to another peak
		setvariable $(pr+"lo"),win=PFPanel,disable=1
		setvariable $(pr+"hi"),win=PFPanel,disable=1
		if (!isHidden)
			setvariable $("edit"+pr), win=PFPanel,disable=2
			dis=0
		else
			dis=1
		endif
		setvariable $(pr+"relval"),win=PFPanel,disable=dis
		setvariable $(pr+"relpeak"),win=PFPanel,disable=dis

	endif
	setdatafolder ::
	//copyparms()
	setdatafolder PF
end

//hide those bkgd parameters which are not needed
//should be in :PF
//if mode=0 then normal; if mode=1 then force display
proc disableBkgdParms(mode)
	variable mode=0
	variable nterms
	nterms=abs(fittype[0])
	iterate(7)
		setvariable $("bkgd"+num2str(i)),win=PFPanel,disable=(1-mode)*(1-(i<nterms))
		checkbox $("fix"+num2str(i)),win=PFPanel,disable=(1-mode)*(1-(i<nterms))
	loop
end

//hide FE parameters if not needed
//should be in :PF
//if mode=0 then hide; if mode=1 then force display
proc disableFEParms(mode)
	variable mode=0
	variable nterms
	//if (hasFE==0)
		setvariable FEPos,win=PFPanel,disable=(1-mode)
		checkbox fixFEPos,win=PFPanel,disable=(1-mode)
		setvariable FEWidth,win=PFPanel,disable=(1-mode)
		checkbox fixFEWid,win=PFPanel,disable=(1-mode)
	//endif
end


//if a peak type doesn't include a parameter, hide the parameter
//enable=1 --> show instead of hide
//sbould be in PF
proc disableParms(pr,enable)
	string pr; variable enable=1
	variable dis
	dis=(numtype($pr)==2) ; setvariable $("edit"+pr),win=PFPanel,disable=dis*(1-enable)
	popupmenu $(pr+"hold"),win=PFPanel,disable=dis*(1-enable)
	dis=(numtype($(pr+"lo"))==2) ; setvariable $(pr+"lo"),win=PFPanel,disable=dis*(1-enable)
	dis=(numtype($(pr+"hi"))==2) ; setvariable $(pr+"hi"),win=PFPanel,disable=dis*(1-enable)
	dis=(numtype($(pr+"relval"))==2) ; setvariable $(pr+"relval"),win=PFPanel,disable=dis*(1-enable)
	dis=(numtype($(pr+"relpeak"))==2) ; setvariable $(pr+"relpeak"),win=PFPanel,disable=dis*(1-enable)
end

proc showParms(mode)
	variable mode
	prompt mode, "mode", popup "showall;hide minmax;hide relval&pk"
	silent 1; pauseupdate
	setdatafolder PF
	disableparms("POS",1)
	disableparms("AMP",1)
	disableparms("LW",1)
	disableparms("GW",1)
	disableparms("ASYM",1)
	disableparms("SPLIT",1)
	disableparms("RATIO",1)
	string pr, s1, s2
	if (mode>=2)
		if (mode==2)
			s1="lo";s2="hi"
		endif
		if (mode==3)
			s1="relval"; s2="relpeak"
		endif
		pr="POS" ; setvariable $(pr+s1),win=PFPanel,disable=1; setvariable $(pr+s2),win=PFPanel,disable=1
		pr="AMP" ; setvariable $(pr+s1),win=PFPanel,disable=1; setvariable $(pr+s2),win=PFPanel,disable=1
		pr="LW" ; setvariable $(pr+s1),win=PFPanel,disable=1; setvariable $(pr+s2),win=PFPanel,disable=1
		pr="GW" ; setvariable $(pr+s1),win=PFPanel,disable=1; setvariable $(pr+s2),win=PFPanel,disable=1
		pr="ASYM" ; setvariable $(pr+s1),win=PFPanel,disable=1; setvariable $(pr+s2),win=PFPanel,disable=1
		pr="SPLIT" ; setvariable $(pr+s1),win=PFPanel,disable=1; setvariable $(pr+s2),win=PFPanel,disable=1
		pr="RATIO" ; setvariable $(pr+s1),win=PFPanel,disable=1; setvariable $(pr+s2),win=PFPanel,disable=1
	endif
	setdatafolder ::
end	
	
//should not be in PF
//if pp=0, update all peaks else just pk# (pp)
proc updateXPSFit(pp)
	variable pp
	silent 1;pauseupdate
	variable FEPos=:PF:FEPos , FEWidth=:PF:FEWidth , hasFE=:PF:hasFE
	makeconstraints()
	//variable dummy=setupPkTyp()
	variable hasBkgd
	variable/g v_fititerstart
	wavestats/q :PF:bkgdfit
	hasBkgd=1//(v_numNans==0)
	:PF:peakfit=0
	string peakname
	//dowindow/f $:PF:winnam
	string wn=:PF:winnam
	if(hasBkgd)
		if (strlen(:PF:xwv)==0)
			:PF:bkgdfit=BkgdFunction(fitparms,fittype,x)
		else
			:PF:bkgdfit=BkgdFunction(fitparms,fittype,::$xwv)
		endif
	endif
	iterate(20-:PF:numpks)
		remwv("peak"+num2str(i+1),wn)
	loop
	if(:PF:numpks==0)
		remwv("peakfit",wn)
	else
		v_fitIterStart=1 //force new fft if needed in lor_don_gauss function
		iterate(:PF:numpks)
			peakname=":PF:peak"+num2str(i+1)
			if((pp==0)+((i+1)==pp)) then
				if (strlen(:PF:xwv)==0)
					$peakname=subFunction(fitparms,fittype,x,i+1)
					$peakname/=subFunction0(fitparms,fittype,i+1)
				else
					$peakname=subFunction(fitparms,fittype,::$xwv,i+1)
					$peakname/=subFunction0(fitparms,fittype,i+1)
				endif
			endif
			if (hasFE*((pp==0)+((i+1)==pp)))
				//$peakname *= ( 1/(exp((x-FEPos)/FEwidth)+1) )
			endif
			if (hasbkgd*((pp==0)+((i+1)==pp))) then
				$peakname+=bkgdfit
			endif
			:PF:peakfit+=$("peak"+num2str(i+1))
			if(hasBkgd) then
				:PF:peakfit-=bkgdfit
				appwv(:PF:xwv,":PF:bkgdfit",wn)
			endif
			appwv(:PF:xwv,peakname,wn)
		loop
				
		if (hasBkgd)then
			if(hasFE)
				:PF:peakfit+=bkgdfit
			else
				:PF:peakfit+=bkgdfit
			endif
		endif
		if (hasFE)
			:PF:peakfit*=( 1/(exp((x-FEPos)/FEwidth)+1) )
		endif
		appwv(:PF:xwv,":PF:peakfit",wn)
	endif
	string resname="res_"+ywvnm(0)
	if (exists(resname)==1)		
		$resname= $(ywvnm(1)) -  :PF:peakfit
	endif
end

//should be in :PF
proc SetPeakColors()
	iterate(numpks)
		if((i+1)==peak)
			ModifyGraph/w=$winnam rgb($("peak"+num2str(i+1)))=(0,0,0)
		else
			ModifyGraph/w=$winnam rgb($("peak"+num2str(i+1)))=(65535,16385,16385)
		endif
	loop
end

//returns ywavename, not including path
//if method==0, returns without path
//if method==1, returns full path with folder, good for when above PF
//must be above PF
function/s ywvnm(method)
	variable method
	svar ywv=:PF:ywv
	if (strsearch(ywv,"PF",0)==0)
		if(method)
			return ":"+ywv
		else
			return  getstrfromlist(ywv,1,":")
		endif
	else
		return ywv
	endif
end

function/s BkgdHoldString()
	string h=""
	nvar b0=:PF:bkgd0,b1=:PF:bkgd1,b2=:PF:bkgd2,b3=:PF:bkgd3,b4=:PF:bkgd4, b5=:PF:bkgd5,b6=:PF:bkgd6
	wave hold=:PF:hold
	NVAR hasFE = :PF:hasFE
	h+=num2str((numtype(b0)==2) + (hold[0][0][0]==1)>0)
	h+=num2str((numtype(b1)==2) + (hold[1][0][0]==1)>0)
	h+=num2str((numtype(b2)==2) + (hold[2][0][0]==1)>0)
	h+=num2str((numtype(b3)==2) + (hold[3][0][0]==1)>0)
	h+=num2str((numtype(b4)==2) + (hold[4][0][0]==1)>0)
//	h+=num2str((numtype(b5)==2) + (hold[5][0][0]==1)>0)
//	h+=num2str((numtype(b6)==2) + (hold[6][0][0]==1)>0)
       h+=num2str((HasFE==0) + (hold[5][0][0]==1)>0)
       h+=num2str((hasFE==0) + (hold[6][0][0]==1)>0)
	return h
end

//sets up hold string
function/s HoldString()
	string h=""
	variable i=0,j
	wave fp=:PF:fitparms, hold=:PF:hold
	nvar npks=:PF:numpks
	//background
	j=1
	do
		h+=num2str((numtype(fp[0][j])==2) + (hold[0][j][0]==1)>0)
		h+=num2str((numtype(fp[1][j])==2) + (hold[1][j][0]==1)>0)
		h+=num2str((numtype(fp[2][j])==2) + (hold[2][j][0]==1)>0)
		h+=num2str((numtype(fp[3][j])==2) + (hold[3][j][0]==1)>0)
		h+=num2str((numtype(fp[4][j])==2) + (hold[4][j][0]==1)>0)
		h+=num2str((numtype(fp[5][j])==2) + (hold[5][j][0]==1)>0)
		h+=num2str((numtype(fp[6][j])==2) + (hold[6][j][0]==1)>0)
		j+=1
	while (j<=npks)
	
	//first pass: go through 
	
	return h
end

//should not be in PF
function setupPkTyp()
	nvar numpks=:PF:numpks
	wave fitparms=:PF:fitparms, fittype=:PF:fittype
	make/o/n=7 :PF:nantemp
	wave nantemp=:PF:nantemp
	variable hasSO,i=1
	if (numpks>=1)
		do
			nantemp=numtype(fitparms[p][i])
			hasSO= (nantemp[5]==0) * (nantemp[6]==0)
			if ((nantemp[2]==0)*(nantemp[3]==2)*(nantemp[4]==2))	//lor
				fittype[i]=1
			endif
			if ((nantemp[2]==0)*(nantemp[3]==0)*(nantemp[4]==2))	//lor_gauss
			 	fittype[i]=2
			endif
			if ((nantemp[2]==0)*(nantemp[3]==2)*(nantemp[4]==0))	//lor_don
				fittype[i]=3
			endif
			if ((nantemp[2]==0)*(nantemp[3]==0)*(nantemp[4]==0))	//lor_don_gauss
				fittype[i]=4
			endif
			if ((nantemp[2]==2)*(nantemp[3]==0)*(nantemp[4]==2))	//gauss
				fittype[i]=5
			endif
			if (hasSO) 
				fittype[i]*=-1
			endif
			i+=1
		while (i<=numpks)
	endif
	return 0
end

//test fit function evaluation
//should be above PF
function XPSFit(fitparms,fittype,xx)
	wave fitparms,fittype
	variable xx
	variable res=0,i
	nvar hasbkgd=:PF:hasbkgd, np=:PF:numpks
	svar xwvnm=:PF:xwv
	wave xwv=$xwvnm
	if(hasBkgd)
		if (strlen(xwvnm)==0)
			res=BkgdFunction(fitparms,fittype,xx)
		else
			res=BkgdFunction(fitparms,fittype,xwv)
		endif
	endif
	i=0
	do
		res+=subFunction(fitparms,fittype,xx,i+1)/subFunction0(fitparms,fittype,i+1)
		i+=1
	while(i<np)
	return res
end

proc testTime()
	silent 1; pauseupdate
	variable/d ttime=ticks
	iterate(20)
		//print i
		PF=xpsfit(:PF:fitparms,:PF:fittype,t226_x)
	loop
	print (ticks-ttime)/60.15
end

function BkgdFunction(fp,ft,xx)
	wave fp,ft; variable xx
	variable nt=ft[0]
	variable res=0
	variable i=1
	do
		res+=fp[nt-i]
		if (i<nt)
			res*=xx
		endif
		i+=1
	while (i<=nt)
	return res
end

//can be in or above PF
//function BkgdFunction(ww,xx)
//	wave ww; variable xx
//	string ss
//	if (streq(getdatafolder(0),"PF")) then
//		ss = ""
//	else
//		ss=":PF:"
//	endif
//	wave ft=$(ss+"fittype")
//	variable nt=ft[0]
//	variable res=0
//	variable i=1
//	do
//		res+=ww[nt-i]
//		if (i<nt)
//			res*=xx
//		endif
//		i+=1
//	while (i<=nt)
//	return res
//end

//can be in or above PF
function fitFunction(ww,xx)
	wave ww; variable xx
	wave ft=:PF:fittype
	wave fp=:PF:fitparms
	svar xwvname=:PF:xwv
	wave xwv=$xwvname
	svar ywvname=:PF:ywv
	wave ywv=$ywvname
	nvar npks=:PF:numpks
	nvar FEPos=:PF:FEPos , FEWidth=:PF:FEWidth , hasFE=:PF:hasFE
	wave convStore=:PF:convStore
	variable i,nparms=(npks+1)*7	//number of fit parameters
	variable npts=numpnts(ywv)
	variable/g V_FitIterStart
	variable cp=V_FitIterStart-1
	variable evWithinX=mod(cp, nparms+1)   	//evaluation # with current value of x
	variable isSameX=evWithinX>0
	variable g_currPk=floor((evWithinX-1)/7)		//current peak being fit
	nvar cc=cc
	cc+=1
	if(cp==0)	//only executes once per iteration
		make/o/n=(npks+1) :PF:hold1store
		make/o/n=(nparms+1,npks+1) :PF:Amp0Store
		//print npts,npks+1,nparms+1
		make/o/n=(npts,npks+1,nparms+1) :PF:convStore
		if(strlen(xwvname)==0)
			SetScale/P x dimoffset(ywv,0),dimdelta(ywv,0),"", convstore
		endif
		//print npts,npks,nparms
	endif
	wave hold1Store=:PF:hold1store
	wave hold=:PF:hold
	wave amp0store=:PF:amp0store
	variable ans=0, res=0,holdIs1,parmisNaN,fittingotherpeak, hasConvolved
	holdis1=(hold[evWithinX-1]==1)
	parmIsNaN=(numtype(fp[evWithinX-1])==2)
	hasconvolved=0
	
	//ways to save time:
	//  (1) when fitting a "hold=1" parameter, don't recalculate any peaks: all can be taken from first calculation at this x-value
	//  (2) when varying peak#n, all other peaks can use stored values
	//  (3) normalize peakheight only once for each set of parameters
	//  (4) precalculate convolved functions at first x, once for each parameter variation
	wave ftft=:PF:fittype
	if((cp<=nparms))
		//precalculate amplitudes for timesaver (3)
		amp0store[cp][1,npks]=subfunction0(ww,:PF:fittype,q)
		i=1
		do
			if(abs(ft[i])==4)
				if (strlen(xwvname)==0)
					convstore[][i][cp]=subfunction(ww,:PF:fittype,x,i)
				else
					convstore[][i][cp]=subfunction(ww,:PF:fittype,xwv[p],i)
				endif
			endif
			i+=1
		while(i<=npks)
	endif

	//print cp,xx,xwv[floor(cp/(nparms+1))],evWithinX,g_currPk,">",ww[0],ww[1],ww[2],ww[3],ww[4],ww[5],ww[6],ww[7],ww[8],ww[9],ww[10],ww[11],ww[12],ww[13]
	i=0
	do
		fittingOtherPeak=(i!=g_currPk)
		if(isSameX*(holdIs1+parmIsNaN+fittingOtherPeak))	//timesavers (1) and (2)
			//no parameter is varying, recall from storage
			res=Hold1Store[i]
			//print isSAmeX,holdis1,parmisNaN,">", Hold1Store[i]	
		else
			//calculate for new parameter
			if(i==0) 
				res=bkgdfunction(ww,:PF:fittype,xx)
			else
				if(abs(ft[i])==4)
					res=convStore[floor(cp/(nparms+1))][i][evwithinX]				//timesaver (4)
				else
					res=subfunction(ww,:PF:fittype,xx,i)
				endif
				res/=amp0store[evWithinX][i]					//timesaver (3)
			endif
			//print res
		endif
		if(evWithinX==0)	//storage for methods (1) and (2)
			Hold1Store[i]=res
		endif
		ans+=res
		i+=1
	while(i<=npks)
	V_FitIterStart+=1
	//if(numtype(ans)!=0)
	//	print numtype(ans)
	//endif
	if (hasFE==1)
		ans *= ( 1/(exp((xx-ww[5][0])/ww[6][0])+1) )
	endif
	return ans
end 


//can be in or above PF
function subFunction(fp,fittype,xx,pk)
	wave fp,fittype
	variable xx, pk

	//string ss
	//if (streq(getdatafolder(0),"PF")) then
	//	ss = "fittype"
	//else
	//	ss=":PF:fittype"
	//endif
	//wave fittype=$ss
	//print "1:"
	
	//print "df:",getdatafolder(0)
	//print "here"
	variable ans,hasSO=fittype[pk]<0
	//print pk,fittype[pk],hasSO
	variable POS=fp[0][pk], AMP=abs(fp[1][pk]), LW=abs(fp[2][pk]), GW=abs(fp[3][pk]), ASYM=abs(fp[4][pk]), SPLIT=fp[5][pk], RATIO=fp[6][pk]
	if (abs(fittype[pk])==1)	//lor
		ans=AMP*flor(LW,xx-POS)
		if (hasSO) 
			ans+=RATIO*AMP*flor(LW,xx-POS+SPLIT)
		endif
		return ans
	endif
	if (abs(fittype[pk])==2)	//lor_gauss
		ans=AMP*fvoigtH(LW,GW,xx-POS)
		if (hasSO) 
			ans+=RATIO*AMP*fvoigtH(LW,GW,xx-POS+SPLIT)
		endif
		return ans
	endif
	if (abs(fittype[pk])==3)	//lor_don
		ans=AMP*florDS(LW,ASYM,xx-POS)
		if(hasSO) 
			ans+=RATIO*AMP*florDS(LW,ASYM,xx-POS+SPLIT)
		endif
		return ans
	endif
	if (abs(fittype[pk])==4)	//lor_don_gauss
		ans=AMP*fDSConvG(pk,LW,GW,ASYM,xx-POS)
		if(hasSO) 
			//print " LW,GW,ASYM=",LW,GW,ASYM
			ans+=RATIO*AMP*fDSConvG(pk,LW,GW,ASYM,xx-POS+SPLIT)
		endif
		return ans
	endif
	if (abs(fittype[pk])==5)	//gauss
		ans=AMP*fGauss(GW,xx-POS)
		if(hasSO) 
			ans+=RATIO*AMP*fGauss(GW,xx-POS+SPLIT)
		endif
		return ans
	endif
end

//can be in or above PF
function subFunction0(fp,fittype,pk)
	variable pk
	wave fp,fittype
	//string ss
	//if (streq(getdatafolder(0),"PF")) 
	//	ss = "fittype"
	//else
	//	ss=":PF:fittype"
	//endif
	//wave fittype=$ss
	variable hasSO= fittype[pk]<0
	variable ans
	variable POS=fp[0][pk], AMP=abs(fp[1][pk]), LW=abs(fp[2][pk]), GW=abs(fp[3][pk]), ASYM=abs(fp[4][pk]), SPLIT=fp[5][pk], RATIO=fp[6][pk]
	if (abs(fittype[pk])==1)	//lor
		ans=1
		if (hasSO) 
			ans+=RATIO*flor(LW,SPLIT)
		endif
		return ans
	endif
	if (abs(fittype[pk])==2)	//lor_gauss
		ans= fvoigtH(LW,GW,0)
		if(hasSO) 
			ans+= RATIO*fvoigtH(LW,GW,SPLIT)
		endif
		return ans
	endif
	if (abs(fittype[pk])==3)	//lor_don
		ans= florDS(LW,ASYM,0)
		if (hasSO) 
			ans+=RATIO*florDS(LW,ASYM,SPLIT)
		endif
		return ans
	endif
	if (abs(fittype[pk])==4)	//lor_don_gauss
		ans=fDSConvG(pk,LW,GW,ASYM,0)
		if(hasSO) 
			ans+=RATIO*fDSConvG(pk,LW,GW,ASYM,SPLIT)
		endif
		return ans
	endif
	if (abs(fittype[pk])==5)	//gauss
		ans=1
		if(hasSO) 
			ans+=RATIO*fGauss(GW,SPLIT)
		endif
		return ans
	endif
end
 
//returns true if strings are equal; ignores case
function streq(s1,s2)
	string s1,s2
	return  cmpstr(lowerstr(s1),lowerstr(s2))==0
end

//called from PFPanel
Function crsr2rgn(ctrlName) : ButtonControl
	String ctrlName
	if (checkCursors()) 
		addBkRg("CSR")
	else 
		print "no cursors"
	endif
End

//called from marquee
function fit_addBkgdRegion():graphmarquee
	return addBkRg("MRQ")
end

function addBkRg(type)
	string type//="MRQ" //"CSR" means from cursors, "MRQ"=from marquee
	svar wn=:PF:winnam,an=:PF:axName
	variable x0,x1,p0,p1
	if (cmpstr(type,"CSR")==0)
		x0=min(hcsr(a,wn),hcsr(b,wn))
		x1=max(hcsr(a,wn),hcsr(b,wn))
		print x0,x1
	else
		getmarquee/k $an,bottom
		print v_flag,v_left,v_right
		x0=min(v_left,v_right)
		x1=max(v_left,v_right)
		print x0,x1
	endif
	svar ywv=:PF:ywv,xwv=:PF:xwv
	wave bk=:PF:bkgdrgn, bw=:PF:bkgdweight
	wave yw=$ywv
	if(strlen(xwv))
		findlevel/q $xwv,x0
		p0=v_levelx
		findlevel/q $xwv,x1
		p1=v_levelx
	else
		p0=x2pnt(yw,x0)
		p1=x2pnt(yw,x1)
	endif
	print p0,p1
	bk[min(p0,p1),max(p0,p1)]=yw
	bw[min(p0,p1),max(p0,p1)]=1

	execute "appwv(:PF:xwv,\":PF:bkgdrgn\",:PF:winnam)"
	ModifyGraph mode(bkgdRgn)=4,marker(bkgdRgn)=5

end

function testit()
	svar ywv=:PF:ywv
	string ss=":"+ywv
	wave yw=$ss
	wavestats yw
end

//checks if wave is already there before appending
//checks if xw exists before using
proc appwv(xw,yw,wn)
	string xw,yw,wn
	variable nl=numinlist(yw,":")
	string ywt=lowerstr(getstrfromlist(yw,nl-1,":"))  //convert string to tracename
	if (strsearch(lowerstr(tracenamelist("",";",1)),ywt,0)<0) 
		if (strlen(xw)==0)
			appendtograph/w=$wn/l=$:PF:axname $yw
		else
			appendtograph/w=$wn/l=$:PF:axname $yw vs $xw
		endif
	endif	
end
//like appwv, but force to left axis
proc appwvleft(xw,yw,wn)
	string xw,yw,wn
	variable nl=numinlist(yw,":")
	string ywt=lowerstr(getstrfromlist(yw,nl-1,":"))  //convert string to tracename
	if (strsearch(lowerstr(tracenamelist("",";",1)),ywt,0)<0) 
		if (strlen(xw)==0)
			appendtograph/w=$wn/l=left $yw
		else
			appendtograph/w=$wn/l=left $yw vs $xw
		endif
	endif	
end
//checks if wave is there before removing
proc remwv(yw,wn)
	string yw,wn
	variable nl=numinlist(yw,":")
	string ywt=lowerstr(getstrfromlist(yw,nl-1,":"))  //convert string to tracename
	if (strsearch(lowerstr(tracenamelist("",";",1)),ywt,0)>=0) 
		removefromgraph/w=$wn $yw
	endif	
end

//checks if cursors are on wave like ywv, returns "1" if they are, "0" otherwise, and gives alert
Function checkCursors()
//	execute "doCheckCursors()"
	svar wn=:PF:winNam,ywv=:PF:ywv
	nvar np=:PF:npnts
	variable npA=numpnts(csrWaveRef(A,wn)),npB=numpnts(csrWaveRef(B,wn))
	//print wn, ywv, np, npa, npb
	variable ans=((npA==np) * (npB==np)
	if (ans)
		return 1
	else
		doAlert  0, "Sorry, you must have 2 cursors on '"+ywv+"' or a wave like it"
		return 0
	endif

end
	
proc doCheckCursors()
	variable npA=numpnts(csrWaveRef(A,:PF:winNam)),npB=numpnts(csrWaveRef(B,:PF:winNam))
	variable ans=((npA==:PF:npnts) * (npB==:PF:npnts)
	if (ans)
		return 1
	else
		doAlert  0, "Sorry, you must have 2 cursors on '"+:PF:ywv+"' or a wave like it"
		abort
		return 0
	endif
	
end

Function ClearRegionsProc(ctrlName) : ButtonControl
	String ctrlName
	execute "DoClearRegions()"
End
//must not be in PF
proc DoClearRegions()
	:PF:bkgdRgn=nan
	:PF:bkgdWeight=0
end

Function Guess(ctrlName) : ButtonControl
	String ctrlName
	execute "doBkgdGuess()"
End

//should not be in :PF
proc doBkgdGuess()
	variable nterms=:PF:fittype[0]
	appwv(:PF:xwv,":PF:bkgdfit",:PF:winnam)
	ModifyGraph lstyle(bkgdFit)=1,rgb(bkgdFit)=(0,0,65535)
	variable hasX=strlen(:PF:xwv) >0
	if (nterms>1)
		string cmd="CurveFit "
		if (nterms==2)
			cmd +="line,"
		else
			cmd +="poly " + num2str(nterms) +","
		endif
		cmd+=":PF:bkgdrgn /w=:PF:bkgdweight "
		if (hasX)
			cmd += "/x="+:PF:xwv
		endif
		execute cmd
		if(hasX) 
			duplicate/o $(:PF:xwv) :PF:tempX	   //get around igor limitation in next line(s)
			:PF:bkgdfit=polyflex(::w_coef,tempX)
		else
			:PF:bkgdfit=polyflex(::w_coef,x)
		endif
		:PF:fitparms[0,numpnts(w_coef)-1][0]=::w_coef
		if(numpnts(w_coef)<=6)
			:PF:fitparms[numpnts(w_coef),][0]=nan
		endif
	else		//offset only; just average the points
		wavestats/q :PF:bkgdrgn
		variable temp=v_avg
		:PF:bkgdfit=temp
		:PF:fitparms[0][0]=temp
		:PF:fitparms[1,][0]=nan
	endif
	setdatafolder PF
	updatePFPanel()
	setdatafolder ::
end

//handles polynomials with #terms less than 3
function polyFlex(ww,xx)
	wave ww; variable xx
	variable nt=numpnts(ww)
	variable res=0
	variable i=1
	do
		res+=ww[nt-i]
		if (i<nt)
			res*=xx
		endif
		i+=1
	while (i<=nt)
	return res
end

Function selectBkgd(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	wave wv=:PF:fittype
	wv[0]=popnum
	execute "updatePFPanel()"
End

Function FECheckBoxProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	nvar hasFE=:PF:hasFE
	print hasFE, checked
	hasFE=checked
	execute "updatePFPanel()"
End

Function killPk(ctrlName) : ButtonControl
	String ctrlName
	execute "dokillPk()"
End

//should not be in :PF
proc doKillPk()
	if (:PF:numpks >0)
		doalert  1, "Are you sure you want to kill peak #"+num2str(:PF:peak)+"?"
		if (v_flag==1)
			DeletePoints/M=1 :PF:peak,1, :PF:fitparms
			DeletePoints/M=1 :PF:peak,1, :PF:hold
			DeletePoints/M=1 :PF:peak,1, :PF:minmax
			DeletePoints :PF:peak,1, :PF:fittype
			remwv("peak"+num2str(:PF:numpks),:PF:winnam)
			:PF:numpks-=1
		
			updatePFPanel()
		endif
	endif
end


Function NewPeak(ctrlName) : ButtonControl
	String ctrlName
	execute "doNewPeak(\"CSR\")"
End

function fit_AddNewPeak():graphmarquee
	execute "doNewPeak(\"MRQ\")"
end

//should not be in :PF
proc doNewPeak(type)
	string type   //CSR or MRQ
	if (cmpstr(type,"CSR")==0) then
		doCheckCursors()
	endif
	:PF:numpks+=1
	redimension/n=(7,:PF:numpks+1) :PF:fitparms
	redimension/n=(7,:PF:numpks+1,3) :PF:hold
	redimension/n=(7,:PF:numpks+1,2) :PF:minmax
	redimension/n=(:PF:numpks+1) :PF:fittype
	//----make some default parameters for relative peak constraint
	print :PF:numpks
	if(:PF:numpks==1)
		:PF:hold[][:PF:numpks][2]=2  //default peak 1 is relative to peak 2
	else
		:PF:hold[][:PF:numpks][2]=numpks-1
	endif
	:PF:hold[0][:PF:numpks][1]=0
	:PF:hold[1,6][:PF:numpks][1]=1
	//----
	:PF:minmax[][:PF:numpks][]=nan
	:PF:peak=numpks
	if (cmpstr(type,"CSR")==0)    //csrs on center, center+halfwidth
		doThisPeak(hcsr(a),hcsr(b))
	else
		getmarquee/k $:PF:axname,bottom //marquee on entire peak (lower left to lower right)
		variable mn=min(v_left,v_right), mx=max(v_left,v_right)
		dothispeak((mx+mn)/2,(mx+mn)/2+(mx-mn)/4)
	endif
end

//should not be in :PF
//ha=center of peak
//hb=offset from ha by halfwidth
function doThisPeak(ha,hb)
	variable ha,hb
	silent 1;pauseupdate
	execute "askPeakType()"
	nvar pkty=:PF:nextPkAdd
	nvar numpks=:PF:numpks
	if (!numpks)
		abort "Cannot execute because no current peak exists"
	endif
	wave fp=:PF:fitparms, ft=:PF:fittype, bkgdfit=:PF:bkgdfit
	nvar peak=:PF:peak, lwg=:PF:LWGuess, ag=:PF:ASYMguess, sg=:PF:splitguess, rg=:PF:ratioGuess
	fp[0][peak]=ha
	svar ywv=:PF:ywv								//POS
	wave yw=$ywv
	variable pa=x2pnt($ywv,ha)
	print ha,pa
	if (numtype(bkgdfit[pa])==2)  //if NAN
		fp[1][peak]=yw[pa] //$("::"+ywv)[pa]//pcsr(a)]			//AMP
	else	
		fp[1][peak]=yw[pa]-bkgdfit[pa]  //$("::"+ywv)[pa]-bkgdfit[pa]		//AMP - BKGD
	endif
	ft[peak]=pkty
	variable hasSO=(pkty<0)
	if(abs(pkty)==1) //lor
		fp[2][peak]=2*abs(hb-ha)		//LW
		fp[3][peak]=nan								//GW
		fp[4][peak]=nan								//ASYM
		if(hasSO)
			fp[5][peak]=sg								//split
			fp[6][peak]=rg								//ratio
		else
			fp[5][peak]=nan								
			fp[6][peak]=nan								
		endif
	endif
	if(abs(pkty)==2) //lor-gauss
		fp[2][peak]=lwg						//LW
		fp[3][peak]=2*abs(hb-ha)					//GW
		fp[4][peak]=nan								//ASYM
		if(hasSO)
			fp[5][peak]=sg								//split
			fp[6][peak]=rg								//ratio
		else
			fp[5][peak]=nan								
			fp[6][peak]=nan								
		endif
	endif
	if(abs(pkty)==3) //lor-don
		fp[2][peak]=2*abs(hb-ha)					//LW
		fp[3][peak]=nan								//GW
		fp[4][peak]=ag						//ASYM
		if(hasSO)
			fp[5][peak]=sg								//split
			fp[6][peak]=rg								//ratio
		else
			fp[5][peak]=nan								
			fp[6][peak]=nan								
		endif
	endif
	if(abs(pkty)==4) //lor-don-gauss
		fp[2][peak]=lwg						//LW
		fp[3][peak]=2*abs(hb-ha)					//GW
		fp[4][peak]=ag						//ASYM
		if(hasSO)
			fp[5][peak]=sg								//split
			fp[6][peak]=rg								//ratio
		else
			fp[5][peak]=nan								
			fp[6][peak]=nan								
		endif
	endif
	if(abs(pkty)==5) //gauss
		fp[2][peak]=nan								//LW
		fp[3][peak]=2*abs(hb-ha)					//GW
		fp[4][peak]=nan								//ASYM
		if(hasSO)
			fp[5][peak]=sg								//split
			fp[6][peak]=rg								//ratio
		else
			fp[5][peak]=nan								
			fp[6][peak]=nan								
		endif
	endif
	if(abs(pkty)==6) //gstep
	endif
	if(abs(pkty)==7) //lshape
	endif
	execute	"updatePFPanel()"
end



//should not be in PF
proc askPeakType(pt,hasSO)
	variable pt, hasSO
	prompt pt,"Peak Type To Add",popup "Lor;Lor_Gauss;Lor_Doniach;Lor_Don_Gauss;Gaussian;Gauss Step;Lineshape"
	prompt hasSO,"Has Spin-orbit splitting?", popup "No;Yes"
	:PF:nextPkAdd=pt
	if (hasSO==2)
		:PF:nextPkAdd*=-1
	endif
end	

//when user requests new peak to edit
function peakVar(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	setdatafolder PF
	nvar oldpeak=oldpeak
	if (varnum!=oldpeak)
		execute "updatePFPanel()"
		oldpeak=varnum
	endif
	setdatafolder ::
End

//when user changes the current peak type
Function changetype(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	nvar peak=:PF:peak
	execute "doChangeType("+num2str(popnum)+")"
End

proc doChangeType(pkty)
	variable  pkty
	silent 1 ; pauseupdate
	variable peak=:PF:peak
	:PF:fittype[peak]=pkty
	if(pkty==1) //lor
		:PF:fitparms[3][peak]=nan								//GW
		:PF:fitparms[4][peak]=nan								//ASYM
	endif
	if(pkty==2) //lor-gauss
		if(numtype(:PF:fitparms[2][peak])==2)
			:PF:fitparms[2][peak]=LWguess						//LW
		endif
		if(numtype(:PF:fitparms[3][peak])==2)
			:PF:fitparms[3][peak]=GWGuess					//GW
		endif
		:PF:fitparms[4][peak]=nan								//ASYM
	endif
	if(pkty==3) //lor-don
		if(numtype(:PF:fitparms[2][peak])==2)
			:PF:fitparms[2][peak]=LWguess						//LW
		endif
		:PF:fitparms[3][peak]=nan								//GW
		if(numtype(:PF:fitparms[4][peak])==2)
			:PF:fitparms[4][peak]=ASYMguess						//LW
		endif
	endif
	if(pkty==4) //lor-don-gauss
		if(numtype(:PF:fitparms[2][peak])==2)
			:PF:fitparms[2][peak]=LWguess						//LW
		endif
		if(numtype(:PF:fitparms[3][peak])==2)
			:PF:fitparms[3][peak]=GWGuess					//GW
		endif
		if(numtype(:PF:fitparms[4][peak])==2)
			:PF:fitparms[4][peak]=ASYMguess						//LW
		endif
	endif
	if(pkty==5) //gauss
		:PF:fitparms[2][peak]=nan								//LW
		if(numtype(:PF:fitparms[3][peak])==2)
			:PF:fitparms[3][peak]=GWGuess					//GW
		endif
		:PF:fitparms[4][peak]=nan								//ASYM
	endif
	if(pkty==6) //gstep
	endif
	if(pkty==7) //lshape
	endif
	updatePFPanel()
end


	

Function csrs2thisPeak(ctrlName) : ButtonControl
	String ctrlName
	execute "doThisPeak(hcsr(a),hcsr(b))"
End

Function editPOS(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	setdatafolder PF
	wave fp=fitparms
	nvar pk=peak,np=numpks
	if(np>=1)
		fp[0][pk]=varNum
	endif
	setdatafolder ::
	execute "updateXPSfit("+num2str(pk)+")"
End

Function editAMP(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	setdatafolder PF
	wave fp=fitparms
	nvar pk=peak,np=numpks
	if(np>=1)
		fp[1][pk]=varNum
	endif
	setdatafolder ::
	execute "updateXPSfit("+num2str(pk)+")"
End

Function editLW(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	setdatafolder PF
	wave fp=fitparms
	nvar pk=peak,np=numpks
	if(np>=1)
		fp[2][pk]=varNum
	endif
	setdatafolder ::
	execute "updateXPSfit("+num2str(pk)+")"
End

Function editGW(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	setdatafolder PF
	wave fp=fitparms
	nvar pk=peak,np=numpks
	if(np>=1)
		fp[3][pk]=varNum
	endif
	setdatafolder ::
	execute "updateXPSfit("+num2str(pk)+")"
End

Function editASYM(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	setdatafolder PF
	wave fp=fitparms
	nvar pk=peak,np=numpks
	if(np>=1)
		fp[4][pk]=varNum
	endif
	setdatafolder ::
	execute "updateXPSfit("+num2str(pk)+")"
End

Function editSPLIT(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	setdatafolder PF
	wave fp=fitparms
	nvar pk=peak,np=numpks
	if(np>=1)
		fp[5][pk]=varNum
	endif
	setdatafolder ::
	execute "updateXPSfit("+num2str(pk)+")"
End

Function editRATIO(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	setdatafolder PF
	wave fp=fitparms
	nvar pk=peak,np=numpks
	//print np
	if(np>=1)
		fp[6][pk]=varNum
	endif
	setdatafolder ::
	execute "updateXPSfit("+num2str(pk)+")"
End

Function GuessPrefs(ctrlName) : ButtonControl
	String ctrlName
	execute "doGuessPrefs()"
End

//should not be in PF
proc DoGuessPrefs(lg,gg,ag,sg,rg)
	variable lg=:PF:LWGuess,gg=:PF:GWGuess, ag=:PF:ASYMguess,sg=:PF:SPLITguess,rg=:PF:RATIOguess
	prompt lg,"Default LW value"
	prompt gg, "Default GW value"
	prompt ag,"Default ASYM value"
	prompt sg,"Default SPLIT value"
	prompt rg,"Default RATIO value"
	:PF:LWGuess=lg
	:PF:GWGuess=gg
	:PF:ASYMguess=ag
	:PF:SPLITguess=sg
	:PF:RATIOguess=rg
end
	
Function fitChannel(ctrlName) : ButtonControl
	String ctrlName
	execute "doFitChannel(0)"
End

//should not be in PF
proc doFitChannel(quiet)
	variable quiet=0
	silent 1
	string cmd
	variable/g v_FitIterStart//, cc=0
	cmd="FuncFit/Q"
	
	makeConstraints()
	variable hasConstr=0
	if(numpnts(:PF:constraints)>0)
		hasConstr=1
	endif
	if (hasConstr)
		cmd+="/c"
	endif
	iterate(:PF:numPks)
		$(":PF:peak"+num2str(i+1))=nan
	loop
	if(quiet) 
		pauseupdate
	endif
	cmd+="/h=\""+bkgdholdstring()+holdstring()+"\""
	if (:PF:isSeries)
		cmd+=" FitFunction :PF:fitparms :PF:singlechannel"
	else
		cmd+=" FitFunction :PF:fitparms :"+:PF:ywv  
	endif	
	if(strlen(:PF:xwv))
		cmd+=" /x=" +:PF:xwv
	endif
	cmd+=" /D=:PF:peakfit/R"
	if(hasConstr)
		cmd+="/c=:PF:constraints"
	endif
	print cmd
	variable tstart=datetime
	execute cmd
	resumeupdate
//make LW, GW, ASYM positive
	:PF:fitparms[2,4][1,]=abs(fitparms[p][q])
	if(!quiet)
		updatePFPanel()
	endif
	print "Fittime=",datetime-tstart," sec"
end

Function fitChannels(ctrlName) : ButtonControl
	String ctrlName
	execute "doFitChannels()"
End

//be above :PF
proc doFitChannels(cstart, cend)
	variable cstart=:PF:channel, cend=:PF:nchan-1
	variable c=cstart, step=1, condn
	if(cend<cstart)
		step=-1
	endif
	do
		print "Channel=",c
		:PF:channel=c
		copychannel(c)
		doFitChannel(1)
		doFit2History()
		calcHistory()
		c+=step
		if(cend<cstart)
			condn=(c>=cend)
		else
			condn=(c<=cend)
		endif
	while(condn)
	updatepfpanel()
end

//should be above PF
proc makeConstraints()
	silent 1; pauseupdate
	make/t/o/n=(14*:PF:numpks) :PF:constraints
	variable pk=1, pk1, k0, k1, v,j,nc=0,isNan
	string s, op, cmd
	do
		j=0
		do
			isNan=numtype(:PF:fitparms[j][pk])==2
			if((:PF:hold[j][pk][0]==3)*(!isNan))	//relative to
				k0=j+(pk)*7
				pk1=:PF:hold[j][pk][2]
				k1=j + (pk1) * 7
				v=:PF:hold[j][pk][1]
 				if ((j==0)+(j==5)) //POS and SPLIT are additive, others multiplicative
					op="*"//"+"
				else
					op="*"
				endif
				s="k"+num2str(k0) + "<" + num2str(v) + op + "k"+num2str(k1)
				:PF:constraints[nc]=s
				s="k"+num2str(k0) + ">" + num2str(v) + op + "k"+num2str(k1)
				:PF:constraints[nc+1]=s
				if ((j==0)+(j==5))		//force constraint on parms
					:PF:fitparms[j][pk]=fitparms[j][pk1] *v//+ v
				else
					:PF:fitparms[j][pk]=fitparms[j][pk1] * v
				endif
				nc+=2
			endif
			if((:PF:hold[j][pk][0]==2)*(!isNan))	//between
				if (numtype(:PF:minmax[j][pk][0])==0) 	//low value
					k0=j+(pk)*7
					v=:PF:minmax[j][pk][0]
					s="k"+num2str(k0)+">" +num2str(v)
					:PF:constraints[nc]=s
					if(:PF:fitparms[j][pk]<v)	//force constraint on parms
						:PF:fitparms[j][pk]=v
					endif
					nc+=1
				endif
				if (numtype(:PF:minmax[j][pk][1])==0) 	high value
					k0=j+(pk)*7
					v=:PF:minmax[j][pk][1]
					s="k"+num2str(k0)+"<" +num2str(v)
					:PF:constraints[nc]=s
					if(:PF:fitparms[j][pk]>v)	//force constraint on parms
						:PF:fitparms[j][pk]=v
					endif
					nc+=1
				endif
			endif
			j+=1
		while(j<7)
		pk+=1
	while(pk<=:PF:numpks)
	redimension/n=(nc) :PF:constraints
end

Window pfpanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(651,456,1223,797) as "PFPanel"
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fname= "Times",fsize= 10
	SetDrawEnv save
	DrawText 134,175,"Low"
	DrawText 215,175,"High"
	DrawText 306,175,"Hold?"
	DrawText 372,175,"rel. to peak #"
	SetDrawEnv fillfgc= (32768,54615,65535)
	DrawRect 4,16,435,102
	SetDrawEnv fillfgc= (65535,54607,32768)
	DrawRect 4,110,435,325
	DrawRect 481,236,483,236
	SetDrawEnv fillfgc= (49163,65535,32768)
	DrawRect 441,97,556,298
	DrawRect 0,57,0,56
	SetDrawEnv fname= "Monaco"
	DrawText 115,175,"Constraint Mode"
	SetDrawEnv fillfgc= (65535,16385,16385)
	DrawRect 435,110,4,136
	SetDrawEnv fstyle= 2
	DrawText 248,93,"checkbox means fix this parameter"
	SetDrawEnv fillfgc= (32768,54615,65535)
	DrawRect 441,16,556,86
	Button init,pos={448,103},size={100,20},proc=startButtonFunc,title="initialize"
	PopupMenu background,pos={12,26},size={84,20},proc=selectBkgd,title="type"
	PopupMenu background,mode=1,popvalue="Offset",value= #"\"Offset;Line;Poly 2;Poly 3;Poly 4\""
	Button crsr2rgn,pos={126,23},size={110,20},proc=crsr2rgn,title="Crsrs -> Region"
	Button button2,pos={238,23},size={90,20},proc=ClearRegionsProc,title="ClearRegions"
	Button button3,pos={331,23},size={90,20},proc=Guess,title="Guess Bkgd"
	SetVariable channel,pos={276,115},size={100,15},proc=SetVarChannel,title="channel"
	SetVariable channel,fSize=9,limits={0,99,1},value= root:PF:channel
	SetVariable peak,pos={80,114},size={80,18},proc=peakVar,title="peak",fSize=12
	SetVariable peak,limits={1,2,1},value= root:PF:peak
	SetVariable editPOS,pos={10,177},size={100,15},proc=editPOS,title="POS",fSize=9
	SetVariable editPOS,limits={-inf,inf,0.1},value= root:PF:POS
	SetVariable editAMP,pos={9,197},size={100,15},proc=editAMP,title="AMP",fSize=9
	SetVariable editAMP,value= root:PF:AMP
	SetVariable editLW,pos={9,221},size={100,15},proc=editLW,title="LW",fSize=9
	SetVariable editLW,limits={-inf,inf,0.1},value= root:PF:LW
	SetVariable editGW,pos={10,240},size={100,15},proc=editGW,title="GW",fSize=9
	SetVariable editGW,limits={-inf,inf,0.1},value= root:PF:GW
	SetVariable editASYM,pos={9,260},size={100,15},disable=1,proc=editASYM,title="ASYM"
	SetVariable editASYM,fSize=9,limits={-inf,inf,0.02},value= root:PF:ASYM
	SetVariable editSPLIT,pos={9,285},size={100,15},disable=1,proc=editSPLIT,title="SPLIT"
	SetVariable editSPLIT,fSize=9,limits={-inf,inf,0.1},value= root:PF:SPLIT
	SetVariable editRATIO,pos={9,304},size={100,15},disable=1,proc=editRATIO,title="RATIO"
	SetVariable editRATIO,fSize=9,limits={-inf,inf,0.05},value= root:PF:RATIO
	PopupMenu POShold,pos={116,175},size={96,20},proc=SetParmMenu
	PopupMenu POShold,mode=1,popvalue="Free           ",value= #"\"Free           ;Fixed         ;Between;the value from peak #...\""
	PopupMenu AMPhold,pos={115,194},size={96,20},proc=SetParmMenu
	PopupMenu AMPhold,mode=1,popvalue="Free           ",value= #"\"Free           ;Fixed         ;Between;the value from peak #...\""
	PopupMenu LWHold,pos={115,219},size={96,20},proc=SetParmMenu
	PopupMenu LWHold,mode=1,popvalue="Free           ",value= #"\"Free           ;Fixed         ;Between;the value from peak #...\""
	PopupMenu GWhold,pos={115,238},size={94,20},proc=SetParmMenu
	PopupMenu GWhold,mode=2,popvalue="Fixed         ",value= #"\"Free           ;Fixed         ;Between;the value from peak #...\""
	PopupMenu ASYMhold,pos={115,257},size={96,20},disable=1,proc=SetParmMenu
	PopupMenu ASYMhold,mode=1,popvalue="Free           ",value= #"\"Free           ;Fixed         ;Between;the value from peak #...\""
	PopupMenu SPLIThold,pos={115,283},size={96,20},disable=1,proc=SetParmMenu
	PopupMenu SPLIThold,mode=1,popvalue="Free           ",value= #"\"Free           ;Fixed         ;Between;the value from peak #...\""
	PopupMenu RATIOhold,pos={115,302},size={96,20},disable=1,proc=SetParmMenu
	PopupMenu RATIOhold,mode=1,popvalue="Free           ",value= #"\"Free           ;Fixed         ;Between;the value from peak #...\""
	SetVariable ampRelPeak,pos={298,197},size={50,15},disable=1,proc=SetParms,title=" "
	SetVariable ampRelPeak,fSize=9,limits={1,inf,1},value= root:PF:ampRelPeak
	SetVariable LWRelPeak,pos={298,223},size={50,15},disable=1,proc=SetParms,title=" "
	SetVariable LWRelPeak,fSize=9,limits={1,inf,1},value= root:PF:LWRelPeak
	SetVariable GWRelPeak,pos={298,242},size={50,15},disable=1,proc=SetParms,title=" "
	SetVariable GWRelPeak,fSize=9,limits={1,inf,1},value= root:PF:GWRelPeak
	SetVariable ASYMRelPeak,pos={298,260},size={50,15},disable=1,proc=SetParms,title=" "
	SetVariable ASYMRelPeak,fSize=9,limits={1,inf,1},value= root:PF:ASYMRelPeak
	SetVariable SPLITRelPeak,pos={298,286},size={50,15},disable=1,proc=SetParms,title=" "
	SetVariable SPLITRelPeak,fSize=9,limits={1,inf,1},value= root:PF:SPLITRelPeak
	SetVariable RATIORelPeak,pos={298,303},size={50,15},disable=1,proc=SetParms,title=" "
	SetVariable RATIORelPeak,fSize=9,limits={1,inf,1},value= root:PF:RATIORelPeak
	SetVariable posRelVal,pos={351,177},size={75,15},disable=1,proc=SetConstraintParms,title="plus  "
	SetVariable posRelVal,fSize=9,value= root:PF:posRelVal
	SetVariable ampRelVal,pos={351,197},size={75,15},disable=1,proc=SetParms,title="times"
	SetVariable ampRelVal,fSize=9,value= root:PF:ampRelVal
	SetVariable LWRelVal,pos={351,223},size={75,15},disable=1,proc=SetParms,title="times"
	SetVariable LWRelVal,fSize=9,value= root:PF:LWRelVal
	SetVariable GWRelVal,pos={351,242},size={75,15},disable=1,proc=SetParms,title="times"
	SetVariable GWRelVal,fSize=9,value= root:PF:GWRelVal
	SetVariable ASYMRelVal,pos={351,259},size={75,15},disable=1,proc=SetParms,title="times"
	SetVariable ASYMRelVal,fSize=9,value= root:PF:ASYMRelVal
	SetVariable SPLITRelVal,pos={350,286},size={75,15},disable=1,proc=SetParms,title="plus  "
	SetVariable SPLITRelVal,fSize=9,value= root:PF:SPLITRelVal
	SetVariable RATIORelVal,pos={350,303},size={75,15},disable=1,proc=SetParms,title="times"
	SetVariable RATIORelVal,fSize=9,value= root:PF:RATIORelVal
	SetVariable POSlo,pos={208,177},size={75,15},disable=1,proc=SetParms,title="Lo"
	SetVariable POSlo,fSize=9,value= root:PF:POSlo
	SetVariable AMPlo,pos={208,197},size={75,15},disable=1,proc=SetParms,title="Lo"
	SetVariable AMPlo,fSize=9,value= root:PF:AMPlo
	SetVariable LWlo,pos={208,221},size={75,15},disable=1,proc=SetParms,title="Lo"
	SetVariable LWlo,fSize=9,value= root:PF:LWlo
	SetVariable GWlo,pos={208,240},size={75,15},disable=1,proc=SetParms,title="Lo"
	SetVariable GWlo,fSize=9,value= root:PF:GWlo
	SetVariable ASYMlo,pos={208,260},size={75,15},disable=1,proc=SetParms,title="Lo"
	SetVariable ASYMlo,fSize=9,value= root:PF:ASYMlo
	SetVariable SPLITlo,pos={208,285},size={75,15},disable=1,proc=SetParms,title="Lo"
	SetVariable SPLITlo,fSize=9,value= root:PF:SPLITlo
	SetVariable RATIOlo,pos={208,304},size={75,15},disable=1,proc=SetParms,title="Lo"
	SetVariable RATIOlo,fSize=9,value= root:PF:RATIOlo
	SetVariable POShi,pos={298,177},size={75,15},disable=1,proc=SetParms,title="Hi"
	SetVariable POShi,fSize=9,value= root:PF:POShi
	SetVariable AMPhi,pos={297,197},size={75,15},disable=1,proc=SetParms,title="Hi"
	SetVariable AMPhi,fSize=9,value= root:PF:AMPhi
	SetVariable LWhi,pos={297,221},size={75,15},disable=1,proc=SetParms,title="Hi"
	SetVariable LWhi,fSize=9,value= root:PF:LWhi
	SetVariable GWhi,pos={297,240},size={75,15},disable=1,proc=SetParms,title="Hi"
	SetVariable GWhi,fSize=9,value= root:PF:GWhi
	SetVariable ASYMhi,pos={296,260},size={75,15},disable=1,proc=SetParms,title="Hi"
	SetVariable ASYMhi,fSize=9,value= root:PF:ASYMhi
	SetVariable SPLIThi,pos={296,285},size={75,15},disable=1,proc=SetParms,title="Hi"
	SetVariable SPLIThi,fSize=9,value= root:PF:SPLIThi
	SetVariable RATIOhi,pos={296,304},size={75,15},disable=1,proc=SetParms,title="Hi"
	SetVariable RATIOhi,fSize=9,value= root:PF:RATIOhi
	Button FitSpectrum,pos={449,135},size={100,20},proc=fitChannel,title="Fit Spectrum"
	Button fitspectra,pos={449,178},size={100,20},proc=fitChannels,title="Fit Spectra..."
	Button csr2newpk,pos={9,138},size={105,20},proc=NewPeak,title="Csrs->New Peak"
	Button killpk,pos={207,138},size={90,20},proc=killPk,title="Kill Peak"
	SetVariable bkgd1,pos={12,66},size={90,15},disable=1,proc=editBkgdProc,title="1"
	SetVariable bkgd1,fSize=9,value= root:PF:bkgd1
	SetVariable bkgd2,pos={12,81},size={90,15},disable=1,proc=editBkgdProc,title="2"
	SetVariable bkgd2,fSize=9,value= root:PF:bkgd2
	SetVariable bkgd3,pos={129,51},size={90,15},disable=1,proc=editBkgdProc,title="3"
	SetVariable bkgd3,fSize=9,value= root:PF:bkgd3
	SetVariable bkgd4,pos={129,66},size={90,15},disable=1,proc=editBkgdProc,title="4"
	SetVariable bkgd4,fSize=9,value= root:PF:bkgd4
	SetVariable bkgd0,pos={12,51},size={90,15},proc=editBkgdProc,title="0",fSize=9
	SetVariable bkgd0,value= root:PF:bkgd0
	CheckBox fix0,pos={103,51},size={16,14},proc=SetFixedFcn,title="",value= 0
	CheckBox fix1,pos={103,66},size={16,14},disable=1,proc=SetFixedFcn,title=""
	CheckBox fix1,value= 0
	CheckBox fix2,pos={103,82},size={16,14},disable=1,proc=SetFixedFcn,title=""
	CheckBox fix2,value= 0
	CheckBox fix3,pos={220,52},size={16,14},disable=1,proc=SetFixedFcn,title=""
	CheckBox fix3,value= 0
	CheckBox fix4,pos={220,67},size={16,14},disable=1,proc=SetFixedFcn,title=""
	CheckBox fix4,value= 0
	CheckBox fix5,pos={220,82},size={16,14},disable=1,proc=SetFixedFcn,title=""
	CheckBox fix5,value= 0
	SetVariable bkgd5,pos={129,81},size={90,15},disable=1,proc=editBkgdProc,title="5"
	SetVariable bkgd5,fSize=9,value= root:PF:bkgd5
	SetVariable bkgd6,pos={246,51},size={90,15},disable=1,proc=editBkgdProc,title="6"
	SetVariable bkgd6,fSize=9,value= root:PF:bkgd6
	CheckBox fix6,pos={338,51},size={16,14},disable=1,proc=SetFixedFcn,title=""
	CheckBox fix6,value= 0
	ValDisplay valdisp0,pos={15,114},size={61,17},title="#peaks",fSize=12
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #":PF:numpks"
	Button csr2thispk,pos={115,138},size={90,20},proc=csrs2thisPeak,title="Csrs -> Peak"
	Button guessprefs,pos={299,138},size={90,20},proc=GuessPrefs,title="GuessPrefs"
	Button fit2hist,pos={449,197},size={100,20},proc=fit2history,title="Fit --> History"
	Button hist2fit,pos={449,235},size={100,20},proc=history2fit,title="Fit <-- History"
	Button fitReport,pos={449,154},size={100,20},proc=FitReport,title="Fit Report"
	Button SeriesReport,pos={449,254},size={100,20},proc=SeriesReport,title="Series Report"
	PopupMenu thispktyp,pos={161,113},size={111,20},proc=changetype,title="Type"
	PopupMenu thispktyp,mode=2,popvalue="Lor_Gauss",value= #"\"Lor;Lor_Gauss;Lor_Doniach;Lor_Don_Gauss;Gaussian;Gauss Step;Lineshape\""
	SetVariable posRelPeak,pos={298,177},size={50,15},disable=1,proc=SetParms,title=" "
	SetVariable posRelPeak,fSize=9,limits={1,inf,1},value= root:PF:posRelPeak
	CheckBox FECheckBox,pos={490,25},size={53,14},proc=FECheckBoxProc,title="Has FE?"
	CheckBox FECheckBox,value= 0
	SetVariable FEPos,pos={445,45},size={90,15},disable=1,proc=editBkgdProc,title="Pos"
	SetVariable FEPos,fSize=9,value= root:PF:FEPos
	CheckBox fixFEPOS,pos={538,46},size={16,14},disable=1,proc=SetFixedFcn,title=""
	CheckBox fixFEPOS,value= 0
	CheckBox fixFEWid,pos={538,63},size={16,14},disable=1,proc=SetFixedFcn,title=""
	CheckBox fixFEWid,value= 0
	SetVariable FEWidth,pos={445,63},size={90,15},disable=1,proc=editBkgdProc,title="Width"
	SetVariable FEWidth,fSize=9,value= root:PF:FEWidth
	Button showData,pos={451,303},size={40,20},proc=DataWindowProc,title="Data"
	Button showHistory,pos={494,303},size={50,20},proc=HistoryWindowProc,title="History"
	Button animate,pos={450,273},size={100,20},proc=AnimateFit,title="Animate"
	CheckBox check0,pos={380,116},size={51,14},title="history"
	CheckBox check0,variable= root:PF:chanAutoHist
	Button killHist,pos={449,216},size={100,20},proc=KillHistory,title="Kill History"
EndMacro


Function SetParms(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	execute "CopyParms()"
	execute "updatePFPanel()"
End

Function SetConstraintParms(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	execute "CopyParms()"
	execute "MakeConstraints()"
	execute "updatePFPanel()"
End

//should be above PF
//copies from PFPanel to hold arrays when new values are typed to PFPanel
proc CopyParms()
	//hold popup menus
	variable/g v_value
	controlinfo/w=PFPanel poshold ;	:PF:hold[0][:PF:peak][0]=::v_value-1
	controlinfo/w=PFPanel amphold ;	:PF:hold[1][:PF:peak][0]=::v_value-1
	controlinfo/w=PFPanel lwhold ;	:PF:hold[2][:PF:peak][0]=::v_value-1
	controlinfo/w=PFPanel gwhold ;	:PF:hold[3][:PF:peak][0]=::v_value-1
	controlinfo/w=PFPanel asymhold ;	:PF:hold[4][:PF:peak][0]=::v_value-1
	controlinfo/w=PFPanel splithold ;	:PF:hold[5][:PF:peak][0]=::v_value-1
	controlinfo/w=PFPanel ratiohold ;	:PF:hold[6][:PF:peak][0]=::v_value-1

	//numerical controls
	:PF:hold[0][:PF:peak][2]=posrelpeak		;:PF:hold[0][:PF:peak][1]=posrelval
	:PF:hold[1][:PF:peak][2]=amprelpeak		;:PF:hold[1][:PF:peak][1]=amprelval
	:PF:hold[2][:PF:peak][2]=lwrelpeak		;:PF:hold[2][:PF:peak][1]=lwrelval
	:PF:hold[3][:PF:peak][2]=gwrelpeak		;:PF:hold[3][:PF:peak][1]=gwrelval
	:PF:hold[4][:PF:peak][2]=asymrelpeak		;:PF:hold[4][:PF:peak][1]=asymrelval
	:PF:hold[5][:PF:peak][2]=splitrelpeak		;:PF:hold[5][:PF:peak][1]=splitrelval
	:PF:hold[6][:PF:peak][2]=ratiorelpeak		;:PF:hold[6][:PF:peak][1]=ratiorelval
	
	:PF:minmax[0][:PF:peak][0]=poslo			;:PF:minmax[0][:PF:peak][1]=poshi
	:PF:minmax[1][:PF:peak][0]=amplo		;:PF:minmax[1][:PF:peak][1]=amphi
	:PF:minmax[2][:PF:peak][0]=lwlo			;:PF:minmax[2][:PF:peak][1]=lwhi
	:PF:minmax[3][:PF:peak][0]=gwlo			;:PF:minmax[3][:PF:peak][1]=gwhi
	:PF:minmax[4][:PF:peak][0]=asymlo		;:PF:minmax[4][:PF:peak][1]=asymhi
	:PF:minmax[5][:PF:peak][0]=splitlo		;:PF:minmax[5][:PF:peak][1]=splithi
	:PF:minmax[6][:PF:peak][0]=ratiolo		;:PF:minmax[6][:PF:peak][1]=ratiohi
end	

Function SetParmMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	nvar np=:PF:numpks
	if ((np==1)*(popnum==4))
		doalert 0, "Sorry, you must have at least 2 peaks defined before you can use this option"
		PopupMenu POShold, win=PFPanel, mode=1
	else
		execute "doParmMenu()"
	endif
end

proc doParmMenu()
	CopyParms()
	MakeConstraints()
	UpdatePFPanel()
end

//if any "bkgdn fixed?" is checked, save all to hold array
proc SetFixed()
	variable/g v_value
	controlinfo/w=PFPanel fix0;	:PF:hold[0][0][0]=::v_value
	controlinfo/w=PFPanel fix1;	:PF:hold[1][0][0]=::v_value
	controlinfo/w=PFPanel fix2;	:PF:hold[2][0][0]=::v_value
	controlinfo/w=PFPanel fix3;	:PF:hold[3][0][0]=::v_value
	controlinfo/w=PFPanel fix4;	:PF:hold[4][0][0]=::v_value
	//controlinfo/w=PFPanel fix5;	:PF:hold[5][0][0]=::v_value
	//controlinfo/w=PFPanel fix6;	:PF:hold[6][0][0]=::v_value
	controlinfo/w=PFPanel fixFEPos;	:PF:hold[5][0][0]=::v_value
	controlinfo/w=PFPanel fixFEWid;	:PF:hold[6][0][0]=::v_value
end

Function SetFixedFcn(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	execute "SetFixed()"
End

Function editBkgdProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	execute "copyBkgdParms()"
	execute "updateXPSfit(0)"

End

proc copyBkgdParms()
	variable/g v_value
	controlinfo/w=PFPanel bkgd0; :PF:fitparms[0][0]=::v_value
	controlinfo/w=PFPanel bkgd1; :PF:fitparms[1][0]=::v_value
	controlinfo/w=PFPanel bkgd2; :PF:fitparms[2][0]=::v_value
	controlinfo/w=PFPanel bkgd3; :PF:fitparms[3][0]=::v_value
	controlinfo/w=PFPanel bkgd4; :PF:fitparms[4][0]=::v_value
//	controlinfo/w=PFPanel bkgd5; :PF:fitparms[5][0]=::v_value
//	controlinfo/w=PFPanel bkgd6; :PF:fitparms[6][0]=::v_value
	controlinfo/w=PFPanel FEPos; :PF:fitparms[5][0]=::v_value
	controlinfo/w=PFPanel FEWidth; :PF:fitparms[6][0]=::v_value
end
		
Function fit2history(ctrlName) : ButtonControl
	String ctrlName
	execute "doFit2History()"
End

//not in PF
proc doFit2History()
	:PF:hist_fitparms[][0,:PF:numpks][:PF:channel]=fitparms[p][q][channel]
	:PF:hist_fittype[0,:PF:numpks][:PF:channel]=fittype[p][channel]
	:PF:hist_npks[:PF:channel]=numpks
	:PF:hist_chisq[:PF:channel]=::v_chisq
	:PF:hist_isStored[:PF:channel]=1
	:PF:hist_hold[][][][:PF:channel]=hold[p][q][r]
	calchistory()
end

Function killhistory(ctrlName) : ButtonControl
	String ctrlName
	execute "doKillHistory()"
End

//not in PF
proc doKillHistory()
	:PF:hist_fitparms[][0,][:PF:channel]=nan
	:PF:hist_fittype[0,][:PF:channel]=nan
	:PF:hist_npks[:PF:channel]=nan
	:PF:hist_chisq[:PF:channel]=nan
	:PF:hist_isStored[:PF:channel]=nan
	:PF:hist_hold[][][][:PF:channel]=nan
	calchistory()
end

Function history2fit(ctrlName) : ButtonControl
	String ctrlName
	execute "doHistory2Fit()"
End

//not in PF
proc doHistory2Fit()
	if(:PF:hist_isStored[:PF:channel])
		:PF:numpks=hist_npks[channel]
		redimension/n=(7,:PF:numpks+1) :PF:fitparms
		:PF:fitparms[][]=hist_fitparms[p][q][channel]
		redimension/n=(:PF:numpks+1) :PF:fittype
		:PF:fittype[][]=hist_fittype[p][channel]
		redimension/n=(7,:PF:numpks+1,3) :PF:hold
		:PF:hold[][][]=hist_hold[p][q][r][channel]
		updatePFPanel()
	endif
end

Function FitReport(ctrlName) : ButtonControl
	String ctrlName
	execute "doFitReport()"
End

//must be above PF
proc doFitReport()
	silent 1; pauseupdate
	dowindow/k FitReportLayout
	dowindow/f PF_fitparms
	if (v_flag==0)
		PF_fitparms()
	endif
	string wn=:PF:winnam
	layout $wn, PF_fitparms
	DoWindow/C/T FitReportLayout,"Fit Report"
	Tile/W=(35,588,579,758) PF_fitparms
	Tile/W=(31,184,577,544) $wn
end

Function SeriesReport(ctrlName) : ButtonControl
	String ctrlName
	execute "DoSeriesReport()"
End

proc DoSeriesReport()
	calcHistory()
	dowindow/k SeriesReportLayout
	dowindow/f PF_history
	if(v_flag==0)
		PF_history()
	endif
	string wn=:PF:winnam
	layout/p=landscape $wn, PF_history
	dowindow/c/t SeriesReportLayout "Series Report"
	tile/a=(1,0)
end

Function AnimateFit(ctrlName) : ButtonControl
	String ctrlName
	execute "doAnimate()"
End


//animate and create stack plot
proc doAnimate(ch0,ch1)
	variable ch0,ch1
	
	string wn=:PF:winnam
	dowindow/F $wn
	newmovie/L/F=10 
	variable dir=sign(ch1-ch0)
	string wvn_,wvn
	variable np
	iterate((ch1-ch0)+1)
		copychannel(ch0+i*dir)
		dohistory2fit()		
		addmovieframe
		if(i==0)
			//initialize stack plot
			wavestats/q :pf:hist_npks
			variable pkmax=v_max
			iterate(pkmax)
				wvn_=":pf:hist_peak"+num2str(i+1)
				np=numpnts(:pf:singlechannel)+1
				make/o/n=(np,(ch1-ch0)+1) $wvn_
			loop
			duplicate/o $wvn_ :pf:hist_peakx :pf:hist_peakfit :pf:hist_bkgd :pf:hist_dataFit
			if(strlen(:pf:xwv)>0)
				hist_peakx=:pf:singlechannel_x[p]
			else
				:pf:hist_peakx=p*dimdelta(singlechannel,0)+dimoffset(singlechannel,0)
			endif

		endif
		:pf:hist_peakfit[0,np-2][i]= peakfit[p]; :pf:hist_peakfit[np-1][i]= nan
		:pf:hist_bkgd[0,np-2][i]= bkgdfit[p]; :pf:hist_bkgd[np-1][i]= nan
		:pf:hist_dataFit[0,np-2][i]= singlechannel[p]; :pf:hist_dataFit[np-1][i]= nan
		iterate(pkmax)
			wvn="peak"+num2str(i+1)
			wvn_=":pf:hist_peak"+num2str(i+1)
			if(i<:pf:hist_npks[j])
				$wvn_[0,np-2][j]=$wvn[p]
			else
				$wvn_[0,np-2][j]=nan
			endif
			$wvn_[np-1][j]=nan
		loop
	loop
	closemovie
	makeFitStack()
end

//makes fit stack assuming doanimate has already run
proc makeFitStack()
	duplicate/o :pf:hist_peakfit :pf:hist_peakFitStack
	duplicate/o :pf:hist_datafit :pf:hist_dataFitStack
	duplicate/o :pf:hist_peakx :pf:hist_peakxStack
	:pf:hist_peakFitStack:=hist_peakfit[p][q]+q*offsetStackPF
	:pf:hist_dataFitStack:=hist_datafit[p][q]+q*offsetStackPF	
	:pf:hist_peakxStack:=hist_peakX[p][q]+q*shiftStackPF
	dowindow/f FitStack
	if(v_flag==0)
		FitStack()
	endif
end

macro calcHistory()
	silent 1; pauseupdate
	string npk=":PF:numpks"
	wavestats/q :PF:hist_npks
	variable npkmax=v_max
	variable nch=:PF:nchan

	:PF:hist_POS=nan
	:PF:hist_AMP=nan
	:PF:hist_LW=nan
	:PF:hist_GW=nan
	:PF:hist_ASYM=nan
	:PF:hist_SPLIT=nan
	:PF:hist_RATIO=nan

	//copy parameters from history
	
	:PF:hist_POS[0,nch-1][1,npkmax] = hist_fitparms[0][q][p]
	:PF:hist_AMP[0,nch-1][1,npkmax] = hist_fitparms[1][q][p]
	:PF:hist_LW[0,nch-1][1,npkmax] = hist_fitparms[2][q][p]
	:PF:hist_GW[0,nch-1][1,npkmax] = hist_fitparms[3][q][p]
	:PF:hist_ASYM[0,nch-1][1,npkmax] = hist_fitparms[4][q][p]
	:PF:hist_SPLIT[0,nch-1][1,npkmax] = hist_fitparms[5][q][p]
	:PF:hist_RATIO[0,nch-1][1,npkmax] = hist_fitparms[6][q][p]

	//iterate (nch)
	//	npkmax=:PF:hist_npks[i]
	//	:PF:hist_POS[i][npkmax+1,] = nan
	//	:PF:hist_AMP[i][npkmax+1,] = nan
	//	:PF:hist_LW[i][npkmax+1,] = nan
	//	:PF:hist_GW[i][npkmax+1,] = nan
	//	:PF:hist_ASYM[i][npkmax+1,] = nan
	//	:PF:hist_SPLIT[i][npkmax+1,] = nan
	//	:PF:hist_RATIO[i][npkmax+1,] = nan		
	//loop

	
	//make last point nan for plotting
	//:PF:hist_POS[nch][0,npkmax]=nan
	//:PF:hist_AMP[nch][0,npkmax]=nan
	//:PF:hist_LW[nch][0,npkmax]=nan
	//:PF:hist_GW[nch][0,npkmax]=nan
	//:PF:hist_ASYM[nch][0,npkmax]=nan
	//:PF:hist_SPLIT[nch][0,npkmax]=nan
	//:PF:hist_RATIO[nch][0,npkmax]=nan
	
	//make data from "0th" peak (i.e. the background) nan
	//:PF:hist_POS[][0]=nan
	//:PF:hist_AMP[][0]=nan
	//:PF:hist_LW[][0]=nan
	//:PF:hist_GW[][0]=nan
	//:PF:hist_ASYM[][0]=nan
	//:PF:hist_SPLIT[][0]=nan
	//:PF:hist_RATIO[][0]=nan
	
	//make data from empty peaks nan
	//:PF:hist_POS[][1+npkmax,19]=nan
	//:PF:hist_AMP[][1+npkmax,19]=nan
	//:PF:hist_LW[][1+npkmax,19]=nan
	//:PF:hist_GW[][1+npkmax,19]=nan
	//:PF:hist_ASYM[][1+npkmax,19]=nan
	//:PF:hist_SPLIT[][1+npkmax,19]=nan
	//:PF:hist_RATIO[][1+npkmax,19]=nan
end

;========= HISTORY BROWSER ROUTINES
Function DataWindowProc(ctrlName) : ButtonControl
	String ctrlName
	execute "DoDataWindowProc()"
End



//above :PF
proc DoDataWindowProc()
	dowindow/f $:PF:winnam
end

Function doSelectPeakBrowseProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	execute "selectPeakBrowse()"
End

proc selectPeakBrowse()
	updateBrowser()
end

Window historybrowser() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:PF:
	Display /W=(651,47,1194,429) browse_y vs browse_x as "History Browser"
	SetDataFolder fldrSav
	ModifyGraph mode=3
	ModifyGraph gaps=0
	ModifyGraph axisEnab(left)={0,0.85}
	Label left "hist_INDVAR"
	Label bottom "hist_POS"
	Cursor/P A browse_y 0
	ShowInfo
	ShowTools
	PopupMenu LeftAxis,pos={62,2},size={98,20},proc=updateBrowserProc
	PopupMenu LeftAxis,mode=1,popvalue="hist_INDVAR",value= #"\"hist_INDVAR;hist_POS;hist_AMP;hist_LW;hist_GW;hist_ASYM;hist_SOSPLIT;hist_SORATIO\""
	PopupMenu BottomAxis,pos={194,2},size={75,20},proc=updateBrowserProc
	PopupMenu BottomAxis,mode=2,popvalue="hist_POS",value= #"\"hist_INDVAR;hist_POS;hist_AMP;hist_LW;hist_GW;hist_ASYM;hist_SOSPLIT;hist_SORATIO\""
	Button transpose,pos={302,2},size={90,20},proc=TransposeProc,title="Transpose"
	Button export,pos={400,2},size={90,20},proc=ExportHistoryProc,title="Export"
	Button showData,pos={401,28},size={40,20},proc=DataWindowProc,title="Data"
	Button showData01,pos={443,28},size={50,20},proc=FitterWindowProc,title="FitPanel"
	SetVariable which_PkBrowse,pos={51,23},size={120,15},proc=doSelectPeakBrowseProc,title="Peak (0=all)"
	SetVariable which_PkBrowse,limits={0,19,1},value= root:PF:whichHistBrowse
	Button update,pos={347,28},size={50,20},proc=UpdateButtonProc,title="Update"
	SetDrawLayer UserFront
	SetDrawEnv xcoord= abs,ycoord= abs,fillfgc= (65535,21845,0)
	DrawRect 494,0,14,54
	SetDrawEnv xcoord= abs,ycoord= abs
	DrawText 33.1481481481482,18.1390841320554,"Plot"
	SetDrawEnv xcoord= abs,ycoord= abs
	DrawText 179.074696545285,19.2790085314047,"vs"
EndMacro

Function HistoryWindowProc(ctrlName) : ButtonControl
	String ctrlName
	execute "DoHistoryWindowProc()"
End

//above :PF
proc DoHistoryWindowProc()
	dowindow/f HistoryBrowser
	if (v_flag==0)
		historybrowser()
	endif
	updateBrowser()
end

Function FitterWindowProc(ctrlName) : ButtonControl
	String ctrlName
	execute "DoFitterWindowProc()"
End

//above :PF
proc DoFitterWindowProc()
	dowindow/f PFPanel
	if (v_flag==0)
		startup()
	endif
end


Function updateBrowserProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	execute "updateBrowser()"
End

//above :PF
proc UpdateBrowser()
	pauseupdate
	string/g s_value
	controlinfo/w=HistoryBrowser leftAxis
	if(:PF:whichHistBrowse==0)
	print s_value
		duplicate/o $":PF:"+s_value :PF:browse_x 
		:PF:browse_y:=$::s_value
	else
		:PF:browse_y=$::s_value[p][whichHistBrowse]
	endif
	label left s_value
	controlinfo/w=HistoryBrowser bottomAxis
	if(:PF:whichHistBrowse==0)
		duplicate/o $":PF:"+s_value :PF:browse_x 
		:PF:browse_x:=$::s_value
	else
		:PF:browse_x=$::s_value[p][whichHistBrowse]
	endif
	label bottom s_value
	resumeupdate
end

Function TransposeProc(ctrlName) : ButtonControl
	String ctrlName
	execute "doTranspose()"	
End

proc doTranspose()
	controlinfo/w=HistoryBrowser leftAxis
	variable/g :PF:tempv=root:v_value
	controlinfo/w=HistoryBrowser bottomAxis
	popupmenu leftaxis win=HistoryBrowser,mode=v_value
	popupmenu bottomaxis win=HistoryBrowser,mode=:PF:tempv
	updateBrowser()
end

Function ExportHistoryProc(ctrlName) : ButtonControl
	String ctrlName
	execute "doExportHistory()"
End

Function UpdateButtonProc(ctrlName) : ButtonControl
	String ctrlName
	execute "updateBrowser()"
End


//above PF
proc doExportHistory(pref,peaknum, disp)
	string  pref=:PF:lastExportName
	variable peaknum=:PF:whichHistBrowse, disp
	prompt pref "Prefix of new waves"
	prompt peaknum, "Peaknum (0=all peaks)"
	prompt disp, "Output mode", popup "new graph;append to graph;new table;append to table"
	silent 1; pauseupdate
	:PF:lastExportName=pref

	if (peaknum<0) 
		peaknum=0
	endif
	variable/g v_max
	wavestats/q :PF:hist_npks
	if(peaknum>v_max)
		peaknum=v_max
	endif
	if (strlen(pref)==0)
		abort "Aborted because no prefix specified"
	endif
	if(peaknum==0)
		variable mx=v_max
		variable i=1
	else
		variable mx=peaknum
		variable i=peaknum
	endif
	variable istart=i
	string leftname, bottomname, winnam
	variable np
	print i,mx
	string vv=""
	if (disp==1)
		display
		vv="vs"
	endif
	if(disp==2)
		winnam=(getstrfromlist(winlist("*",";","win:1"),1,";"))
		dowindow/f $winnam
		vv="vs"
	endif
	if(disp==3)
		edit
	endif
	if(disp==4)
		winnam=(getstrfromlist(winlist("*",";","win:2"),0,";"))
		dowindow/f $winnam
	endif
	do
		controlinfo/w=HistoryBrowser leftAxis
		leftname=pref+"_"+num2str(i)+"_"+s_value[5,100]
		np=dimsize($":PF:"+s_value,0)
		make/o/n=(np) $leftname
		$leftname=$":PF:"+s_value[p][i]
		controlinfo/w=HistoryBrowser bottomAxis
		bottomname=pref+"_"+num2str(i)+"_"+s_value[5,100]
		make/o/n=(np) $bottomname
		$bottomname=$":PF:"+s_value[p][i]	
		execute "append $leftname "+vv+" $bottomname"
		i+=1
	while (i<=mx)
end	
;======================= WINDOW ROUTINES =======================

Window PF_hold() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:PF:
	Edit/W=(2,456,329,623) hold as "PF_hold"
	SetDataFolder fldrSav
EndMacro

Window PF_constraints() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:PF:
	Edit/W=(3,249,232,558) constraints as "PF_constraints"
	SetDataFolder fldrSav
EndMacro

Window PF_dsgtable() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:PF:
	Edit/W=(38,312,498,465) DSGtable as "PF_dsgtable"
	SetDataFolder fldrSav
EndMacro



Window PF_fitparms() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:PF:
	Edit/W=(461,52,899,249) fitparms,parmnames as "PF_fitparms"
	ModifyTable width(Point)=10,width(fitparms)=74,alignment(parmnames)=0
	SetDataFolder fldrSav
EndMacro

Window PF_history() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:PF:
	Display /W=(5,42,386,637)/L=POS hist_POS vs hist_indvar as "PF_history"
	AppendToGraph/L=AMP hist_AMP vs hist_indvar
	AppendToGraph/L=LW hist_LW vs hist_indvar
	AppendToGraph/L=GW hist_GW vs hist_indvar
	AppendToGraph/L=ASYM hist_ASYM vs hist_indvar
	AppendToGraph/L=SPLIT hist_SPLIT vs hist_indvar
	AppendToGraph/L=RATIO hist_RATIO vs hist_indvar
	SetDataFolder fldrSav
	ModifyGraph margin(left)=72
	ModifyGraph mode=4
	ModifyGraph marker=19
	ModifyGraph msize=2
	ModifyGraph tick=2
	ModifyGraph mirror=1
	ModifyGraph minor(bottom)=1
	ModifyGraph lblPos(POS)=72,lblPos(AMP)=72,lblPos(LW)=72,lblPos(GW)=72,lblPos(ASYM)=72
	ModifyGraph lblPos(SPLIT)=72,lblPos(RATIO)=72
	ModifyGraph freePos(POS)=0
	ModifyGraph freePos(AMP)=0
	ModifyGraph freePos(LW)=0
	ModifyGraph freePos(GW)=0
	ModifyGraph freePos(ASYM)=0
	ModifyGraph freePos(SPLIT)=0
	ModifyGraph freePos(RATIO)={0,bottom}
	ModifyGraph axisEnab(POS)={0.85,1}
	ModifyGraph axisEnab(AMP)={0.71,0.84}
	ModifyGraph axisEnab(LW)={0.57,0.7}
	ModifyGraph axisEnab(GW)={0.43,0.56}
	ModifyGraph axisEnab(ASYM)={0.29,0.42}
	ModifyGraph axisEnab(SPLIT)={0.15,0.28}
	ModifyGraph axisEnab(RATIO)={0,0.14}
	Label POS "POS"
	Label AMP "AMP"
	Label LW "LW"
	Label GW "GW"
	Label ASYM "ASYM"
	Label SPLIT "SPLIT"
	Label RATIO "RATIO"
EndMacro

Window FitStack() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:PF:
	Display /W=(-1910,26,-1353,705) hist_dataFitStack,hist_peakFitStack vs hist_peakxStack as "FitStack"
	SetDataFolder fldrSav0
	ModifyGraph marker(hist_dataFitStack)=19
	ModifyGraph rgb(hist_peakFitStack)=(0,0,0)
	ModifyGraph msize(hist_dataFitStack)=2
	ModifyGraph opaque(hist_dataFitStack)=1
	SetVariable offsetFitStack,pos={123,2},size={100,15},title="offset"
	SetVariable offsetFitStack,limits={-inf,inf,100},value= root:PF:offsetStackPF
	SetVariable shiftFitStack,pos={233,2},size={100,15},title="shift"
	SetVariable shiftFitStack,limits={-inf,inf,0.01},value= root:PF:shiftStackPF
EndMacro

Function SetVarChannel(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	copychannel(varNum)
	nvar auto=:pf:chanAutoHist
	if(auto)
		execute "doHistory2Fit()"
	endif
End
