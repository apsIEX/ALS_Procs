#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

menu "TracePopup"
	"New Peakfitter", AdvancedPeakFitter()
end
//
//menu "GraphMarquee", dynamic
//	submenu selectstring(APF_HasFitPane(),"(","") + "Advanced Peak Fit"
//			APF_Menu("Add Bkgd Region"), APF_AddBkgdRgn(1)
//			APF_Menu("Clear Bkgd Region"), APF_AddBkgdRgn(-1)
//			submenu "Add Peak"
//				APF_Menu(APF_pkTypeNm(0)),APF_AddPeak(0)
//				APF_Menu(APF_pkTypeNm(1)),APF_AddPeak(1)
//				APF_Menu(APF_pkTypeNm(2)),APF_AddPeak(2)
//				APF_Menu(APF_pkTypeNm(3)),APF_AddPeak(3)
//				APF_Menu(APF_pkTypeNm(4)),APF_AddPeak(4)
//			end
//		end 
//	
//end

Menu "IT5_PopUpMenu" , dynamic ,contextualmenu
	submenu selectstring(APF_HasFitPane(),"(","") + "Advanced Peak Fit"
		APF_Menu("Add Bkgd Region"), APF_AddBkgdRgn(1)
		APF_Menu("Clear Bkgd Region"), APF_AddBkgdRgn(-1)
		submenu "Add Peak"
			APF_Menu(APF_pkTypeNm(0)),APF_AddPeak(0)
			APF_Menu(APF_pkTypeNm(1)),APF_AddPeak(1)
			APF_Menu(APF_pkTypeNm(2)),APF_AddPeak(2)
			APF_Menu(APF_pkTypeNm(3)),APF_AddPeak(3)
			APF_Menu(APF_pkTypeNm(4)),APF_AddPeak(4)
		end
	end
 End

function AdvancedPeakfitter()
	APF_InitConstants()
	wave/t bkgdDescr=root:APF:bkgdDescr
	wave/t peakShapeDescr=root:APF:peakShapeDescr
	GetLastUserMenuInfo
	//print s_graphname,s_tracename
	string s=traceinfo(s_graphname, s_tracename,0)
	//print s
	wave yw=tracenametowaveref(s_graphname,s_tracename)
	string wi=waveinfo(yw,0)
	//print ">>>",wi
	string df=getwavesdatafolder(yw,1)
	string ywn=tracename2wavename(s_tracename)
	string xwave=stringbykey("XWAVE",s)
	string xaxis=stringbykey("XAXIS",s), yaxis=stringbykey("YAXIS",s)
	
	if(strlen(xwave)>0)
		doalert 0, "Illegal axis or x-wave scaling not allowed."
		return -1
	endif
	string APF_df=("APF_"+s_graphname)
	//MAKE SUBFOLDER
 	newdatafolder/o $("APF_"+s_graphname)
 	string dfn=getdatafolder(1)+APF_df+":"
 	
 	
 	//MAKE DATA: BKGD PARAMS
	duplicate/o yw $(dfn+"bkgdrgn"); wave bkgdrgn=$(dfn+"bkgdrgn"); bkgdrgn=nan
	duplicate/o yw $(dfn+"bkgdfit"); wave bkgdfit=$(dfn+"bkgdfit"); bkgdfit=nan
	//duplicate/o yw $(dfn+"peakfit"); wave peakfit=$(dfn+"peakfit"); peakfit=nan
	make/o/n=(1,3)/t $(dfn+"bkDisp"); wave/t bkDisp=$(dfn+"bkDisp")
	bkDisp[][0]=bkgdDescr[p+1][0] 	//names of bkgd params
	bkDisp[][1]="0.00" 						//initial guess
	bkdisp[][2]="hold?"
	make/o/n=(1,3) $(dfn+"bkDispSel"); wave bkDispSel=$(dfn+"bkDispSel")
	bkDispSel[][0]=0		//not editable
	bkDispSel[][1]=2		//editable
	bkDispSel[][2]=32		//checkbox
	make/o/n=1/s $(dfn+"bkVals"); wave bkVals=$(dfn+"bkVals")	
		//*D* Note Double Precision Needed for higher Polynomials to work!
	variable/g $dfn+"bkType"; nvar bkType=$dfn+"bkType"; bktype=0
	variable/g $dfn+"bk_fitcoef_i"	//index into fitcoefs of bk parms
	
	APF_copyBkDisp2Vals(dfn)
	
	//OVERALL PARAMS
	variable/g $dfn+"has_FE"=0
	variable/g $dfn+"FE_energy"=0; variable/g $dfn+"FEe_hold"
	variable/g $dfn+"FE_temp"=300; variable/g $dfn+"FEt_hold"
	variable/g $dfn+"has_GW"=0	//overall GW broadening taken after all peaks+FE but not background
	variable/g $dfn+"GW"=0.1; variable/g $dfn+"GW_hold"

	//PEAK PARAMS
	make/o/n=0 $dfn+"pkTypes"
	make/o/n=0/t $dfn+"pkDisp"
	make/o/n=0 $dfn+"pkDispSel"
	make/o/n=0/s $dfn+"pkParms"
		//*D* Double Precision 
	make/o/n=0 $dfn+"pkFit"; wave pf=$dfn+"pkFit"			//individual peak fits (2D)
	make/o/n=0/s $dfn+"pkFitX"; wave pfX=$dfn+"pkFitX"		//  "         "     " xwave
		//*D* Double Precision 
	
	//PEAK FIT HOLD PARAMS--for fast evaluation of constraints during fits
	make/o/n=0 $dfn+"pkFitHold_type" //0=plus, 1=times
	make/o/n=0 $dfn+"pkFitHold_pk"		//peak that is constrained
	make/o/n=0 $dfn+"pkFitHold_ref"	//reference peak num
	make/o/n=0 $dfn+"pkFitHold_val" 	//scale or offset factor
	make/o/n=0/T $dfn+"pkFitConstraints" //range min/max are handled with built-in Igor constraints
	
	make/o/s/n=(dimsize(yw,0)) $dfn+"pkFitHiLite"; wave pfh=$dfn+"pkFitHilite"; pfh=nan
		//*D* Double Precision 
	make/o/n=(dimsize(yw,0)) $dfn+"pkFitTot"; wave pft=$dfn+"pkFitTot"
	make/o/n=(dimsize(yw,0)) $dfn+"pkFitDataCopy"; wave pfdc=$dfn+"pkFitDataCopy"
	pfdc=nan
	pft=nan
	make/o/s/n=(dimsize(yw,0)) $dfn+"pfx1"; wave pfx1=$dfn+"pfx1"		//dummy x wave used for calc; never for plotting
		//*D* Double Precision 
	pfx1=dimoffset(yw,0)+dimdelta(yw,0)*p
	duplicate/o pfh $dfn+"pfy1"; wave pfy1=$dfn+"pfy1"					//dummy y wave used for calc; never for plotting
	duplicate/o pfh $dfn+"pfy2"; wave pfy2=$dfn+"pfy2"					//dummy y wave used for calc; never for plotting
	duplicate/o pfh $dfn+"pfy3"; wave pfy3=$dfn+"pfy3"					//dummy y wave used for calc; never for plotting
	string/g $dfn+"holdstr"

	copyscales yw pf, pfy1, pfy2, pfy3, pfh, pft, pfdc
	make/o/s/n=0 $dfn+"pf_coefs1"
		//*D* Double Precision 
	variable/g $(dfn+"numpks")=0
	string/g $(dfn+"ywn")=df+ywn
	string/g $(dfn+"xaxis")=xaxis
	string/g $(dfn+"yaxis")=yaxis
	string/g $(dfn+"rootpath")=df
	string/g $(dfn+"graphname")=s_graphname
	string/g $(dfn+"panelname")=s_graphname+"#APF"
	svar panelName=$(dfn+"panelname")
	
	make/o/s/n=0 $dfn+"fitcoefs"
		//*D* Double Precision 
	make/o/n=0 $dfn+"fithold"
	//ADD WAVES
	APF_appwv(dfn+"bkgdrgn","")
	ModifyGraph mode(bkgdrgn)=3,marker(bkgdrgn)=19,rgb(bkgdrgn)=(52428,52425,1)
	APF_appwv(dfn+"bkgdfit","")
	APF_appwv(dfn+"pkFit",dfn+"pkFitX")
	ModifyGraph lstyle(pkFit)=3,rgb(pkFit)=(0,0,0)
	APF_appwv(dfn+"pkFitTot","")
	ModifyGraph rgb(pkFit)=(0,0,0)
	APF_appwv(dfn+"pkFitHilite","")
	ModifyGraph rgb(pkFitHiLite)=(0,0,0), lsize(pkFitHiLite)=2
	APF_appwv(dfn+"pkFitDataCopy","")

	//Is ImageToolV?
 	variable/g $dfn+"is_imageToolV"=(cmpstr(s_graphname[0,9],"ImageToolV")==0)
 	nvar is_imageToolV=$dfn+"is_imageToolV"
 	variable/g $dfn+"overwrite"=0
 	variable/g $dfn+"animate"=1
 	make/o/n=3 $dfn+"FitCoordStore"
 	string/g $dfn+"pkParmsPlotList"=""


	//PANEL DRAW
	APF_initPanel(dfn)
	//FIRST BKGD FIR
	APF_bkgdGuess(dfn,1)
	
 	if(is_imageToolV)
 		//energy direction index is the bottom index
 		string/g $dfn+"df_it"=df
 		svar df_it=$dfn+"df_it"
 		APF_Initpanel_HistControls(dfn,panelname)
 		wave dnum=$df+"dnum"
 		variable/g $dfn+"xIndex"; nvar xIndex=$dfn+"xIndex"//which dimension of source wave is x-axis
 		variable/g $dfn+"itAxis"; nvar itAxis=$dfn+"itAxis"//which axis of IT is the fit located on
 		strswitch(xaxis)
 			case "bottom":
 				xIndex=dnum[%axis0]
 				itAxis=0
 				break
 			case "profZB":
 				xIndex=dnum[%axis2]
 				itAxis=2
 				break
 			case "profTB":
 				xIndex=dnum[%axis3]
 				itAxis=3
 				break
 		endswitch
 		
 		//make storage waves for history
 		//it has same axis ordering as source wave
 		//the x-axis for fitting is replaced with the fit data wave flattened
		APF_Hist_MakeWave(dfn, "bkgd",dimsize(bkgdDescr,1))  //use max # bkgd params for size
		APF_Hist_MakeWave(dfn, "bk_hold",dimsize(bkgdDescr,1))
		APF_Hist_MakeWave(dfn, "peaks",1)	//initial matrix is empty except one dummy point
		variable/g $dfn+"hist_PeaksInitted" = 0
		
		wave hc=$APF_Hist_MakeWave(dfn, "constants",11)
		setdimlabel xindex,0,fitted,hc
		setdimlabel xindex,1,bktype,hc
		setdimlabel xindex,2,has_FE,hc
		setdimlabel xindex,3,FE_energy,hc
		setdimlabel xindex,4,FE_temp,hc
		setdimlabel xindex,5,FEe_hold,hc
		setdimlabel xindex,6,FEt_hold,hc
		setdimlabel xindex,7,has_GW,hc
		setdimlabel xindex,8,GW,hc
		setdimlabel xindex,9,GW_hold,hc
		setdimlabel xindex,10,numpks,hc
 	endif

end


function APF_copyBkDisp2Vals(df)
	string df
	wave/t bkDisp=$(df+"bkDisp")
	wave bkVals=$(df+"bkVals")
	redimension/n=(dimsize(bkdisp,0)) bkvals
	bkvals=str2num(bkDisp[p][1])
end

function APF_copyBkVals2Disp(df,bkfunc_i)
	string df
	variable bkfunc_i ////index of bkgd type from popupmenu (zero-based)
	wave/t bkDisp=$(df+"bkDisp")
	wave bkVals=$(df+"bkVals")
	APF_FixBkgdListBox(df, bkfunc_i, 0)
	bkDisp[][1]=num2str(bkvals[p])
end

function APF_FixBkgdListBox(df, bkfunc_i,clearHold)
	string df
	variable bkfunc_i //index of bkgd type from popupmenu (zero-based)
	variable clearHold //1 means clear hold checkboxes
	svar panelName=$df+"panelName"
	PopupMenu BkgdFunction, win=$panelName, mode=bkfunc_i+1
	wave/t bkDisp=$(df+"bkDisp")
	wave bkDispSel=$df+"bkDispSel"
	wave/t bkgdDescr=root:APF:bkgdDescr
	redimension/n=(APF_NumParmsBkgdFit(bkfunc_i),-1) bkDisp, bkDispSel
	bkDispSel[][0]=0; bkDispSel[][1]=2
	if(clearHold)
		bkDispSel[][2]=32
	endif
	bkDisp[][0]=bkgdDescr[p+1][bkfunc_i]
	bkDisp[][1]="--"
	bkDisp[][2]=""
end

//returns number of parameters for bkfunc_i indexed rel to BkgdDescr 
function APF_NumParmsBkgdFit(bkfunc_i)
	variable bkfunc_i //index of bkgd type from popupmenu (zero-based)
	wave/t bkgdDescr=root:APF:bkgdDescr
	variable j=1, tot=0, len,jmax=dimsize(bkgdDescr,0)
	do
		len=strlen(bkgdDescr[j][bkfunc_i])
		tot+=len > 0
		j+=1
	while ((len>0)&&(j<jmax))
	return tot
end

//returns number of parameters in fit indexed relative to peakShapeDescr table
function APF_NumParmsPkFit(pkfunc_i)
	variable pkfunc_i //index of bkgd type from popupmenu (zero-based)
	wave/t peakShapeDescr=root:APF:peakShapeDescr
	variable j=1, tot=0, len,jmax=dimsize(peakShapeDescr,0)
	do
		len=strlen(peakShapeDescr[j][pkfunc_i])
		tot+=len > 0
		j+=1
	while ((len>0)&&(j<jmax))
	return tot
end


function APF_bkgdGuess(df, dofit)
	string df
	variable dofit
	wave/t bkgdDescr=root:APF:bkgdDescr
	wave bkVals=$df+"bkvals"
	svar ywn=$df+"ywn"
	wave yw=$ywn
	wave bkgdrgn=$df+"bkgdrgn"
	wave bkgdfit=$df+"bkgdfit"
	svar panelname=$df+"panelname"
	controlinfo/w=$panelname BkgdFunction
	string bkfunc=bkgdDescr[0][v_value-1]
	variable bkfunc_i=v_value-1
	wavestats/q bkgdrgn
	if (v_npnts==0)
		//bkgd rgn not set, use whole wave
		APF_bkPolyGuess(df,dofit,bkfunc_i,yw,bkvals,bkgdFit)
	else
		//use bkgd region
		APF_bkPolyGuess(df,dofit,bkfunc_i,bkgdRgn,bkvals,bkgdFit)
	endif
	APF_copyBkVals2Disp(df,v_value-1)
	APF_UpdatePF(df)
end

function/S APF_GetBkgdHoldStr(df, bkfunc_i)
	string df
	variable bkfunc_i
	wave bkDispSel=$df+"bkDispSel"
	string hold=""
	variable i
	for(i=0;i<dimsize(bkDispSel,0);i+=1)
		hold+=selectstring(bkDispSel[i][2] & 0x10, "0", "1")
	endfor
	return hold
	
end
	
function APF_bkPolyGuess(df,dofit,bkfunc_i,yw, bkVals,bkgdFit)
	string df//,bkfunc
	variable bkfunc_i, dofit
	wave yw, bkVals, bkgdFit
	wave bkVals=$df+"bkvals"
	APF_copyBkDisp2Vals(df)
	wave/t bkgdDescr=root:APF:bkgdDescr
	string bkfunc=bkgdDescr[0][bkfunc_i], hold
	if(dofit) //A
		hold=APF_GetBkgdHoldStr(df, bkfunc_i)
		if (cmpstr(bkfunc,"offset")==0)
				wavestats/q yw
				redimension/n=1 bkvals
				if(cmpstr(hold,"0")==0)
					bkvals[0]=v_avg
					bkgdFit=v_avg
				endif
		else
			strswitch(bkfunc)
				case "Line":
					curvefit/h=hold line, kwCWave=bkvals, yw
				break
				case "Poly 3":
					curvefit/h=hold poly 3, kwCWave=bkvals, yw
				break
				case "Poly 4":
					curvefit/h=hold poly 4, kwCWave=bkvals, yw
				break
				case "Poly 5":
					curvefit/h=hold poly 5, kwCWave=bkvals, yw
				break
				case "Poly 6":
					curvefit/h=hold poly 6, kwCWave=bkvals, yw
				break
				case "Poly 7":
					curvefit/h=hold poly 7, kwCWave=bkvals, yw
				break
				case "Poly 8":
					curvefit/h=hold poly 8, kwCWave=bkvals, yw
				break
	
			endswitch
			//wave w_coef
			//redimension/n=(dimsize(w_coef,0)) bkvals
			//bkvals=w_coef
		endif //A
	endif 
	bkgdfit=poly(bkvals,x)
	printf ""
end

Function APFPanelHook(s)
	STRUCT WMWinHookStruct &s

	Variable hookResult = 0

	switch(s.eventCode)
		case 0:				// Activate
			// Handle activate
			break

		case 1:				// Deactivate
			// Handle deactivate
			break
		case 17: //killvote
			doalert 1, "Are you sure you want to kill the fitting panel?"
			if(v_flag==2)
				//NO clicked
				return v_flag
			else
				RemoveFromGraph bkgdrgn,bkgdfit,pkFit,pkFitTot,pkFitHiLite,pkFitDataCopy
				return 0
			endif
	endswitch

	return hookResult		// 0 if nothing done, else 1
End

function APF_initPanel(df)
	string df
	svar df_it=$df+"df_it"
	GetLastUserMenuInfo
	string ws=s_graphname+"#APF"
	GetWindow/Z $ws active
	
	nvar is_ImageToolV=$df+"is_ImageToolV"

	if (v_flag!=0)
		//MAKE PANEL
		newpanel/EXT=0/HOST=$s_graphname/W=(0,0,550,selectNumber(is_ImageToolV,475,600))/N=APF as "Advanced Peak Fitter"
		setwindow APF, hook(APFHook)=APFPanelHook
	else
		//print "peak fitter already exists"
	endif
	
	PopupMenu BkgdFunction,win=$ws,pos={1,5},size={142,23},title="Background Type"
	PopupMenu BkgdFunction,win=$ws,mode=1,popvalue="Const",value= APF_BkgdTypes()   //"\"Const;Line;Poly 2; Poly 3; Poly 4; Poly 5; Poly 6; Poly 7\""
	PopupMenu BkgdFunction, win=$ws, proc=APF_SetBkgdFcnProc, mode=1
	Button ClearBkgd,win=$ws,pos={150,5},size={100.00,25.00},proc=APF_ClearBkgdRegionButtProc,title=" Clear Bk Region "
	Button GuessBkgd,win=$ws,pos={260,5},size={100.00,25.00},proc=APF_GuessBkgdButtProc,title=" Guess Bkgd "

	wave/t bkDisp=$df+"bkDisp"
	wave bkDispSel=$df+"bkDispSel" 
	ListBox bkgdParms,win=$ws,pos={0,35.00},size={420,150}
	ListBox bkgdParms,win=$ws,listWave=bkDisp
	ListBox bkgdParms,win=$ws,selWave=bkDispSel,mode= 6
	ListBox bkgdParms, win=$ws, titleWave=::APF:bkgdParmsTitles, userColumnResize=1, widths={65,110,420-65-110-5}
	ListBox bkgdParms, win=$ws, proc=APF_BkgdListBoxProc
	
	DrawRect/W=$ws 425,35,546,92
	CheckBox hasGW, win=$ws, pos={430,43},size={39,16},title="GW?",variable=$df+"has_GW", proc=APF_CheckProc
	SetVariable setGW, win=$ws, pos={430,69},size={65,14},title=" ",value=$df+"GW", proc=APF_SetVarProc
	CheckBox GWHold, win=$ws, pos={500,69},size={39,16},title="hold?",variable=$df+"GW_hold", proc=APF_CheckProc


	variable y0=75
	DrawRect/W=$ws 425,35+y0,546,108+y0
	nvar FEe=$(df+"FE_Energy"), FEt=$(df+"FE_Temp")
	CheckBox hasFE,win=$ws, pos={430,43+y0},size={39,16},title="Fermi?",variable=$df+"has_FE", proc=APF_CheckProc
	SetVariable setFEe,win=$ws, pos={430,69+y0},size={65,14},title="E",value=FEe, proc=APF_SetVarProc
	SetVariable setFEt,win=$ws, pos={430,69+y0+20},size={65,14},title="T(K)",value=FEt, proc=APF_SetVarProc
	CheckBox FEeHold,win=$ws, pos={500,69+y0},size={39,16},title="hold?",variable=$df+"FEe_hold", proc=APF_CheckProc
	CheckBox FEtHold,win=$ws, pos={500,69+y0+20},size={39,16},title="hold?",variable=$df+"FEt_hold", proc=APF_CheckProc

	
	ValDisplay numPks,win=$ws,pos={0,200},size={100.00,13.00},title="# Peaks"
	ValDisplay numPks,win=$ws,limits={0,0,0},barmisc={0,1000}
	ValDisplay numPks,win=$ws,value=#(df+"numpks") 
	
	wave/t pkDisp=$df+"pkDisp"
	wave pkTypes=$df+"pkTypes", pkDispSel=$df+"pkDispSel"
	ListBox peakParms,win=$ws,pos={0,220},size={500,250}
	ListBox peakParms,win=$ws,listWave=pkDisp
	ListBox peakParms,win=$ws,selWave=pkDispSel,mode= 6
	ListBox peakParms,win=$ws, colorWave=root:APF:peakDispColors
	ListBox peakParms,win=$ws, proc=APF_PeakParmsProc, userColumnResize=1,widths={72,75,170,93,73}
	TitleBox instr1,win=$ws, title="Click (ctrl-click) Peak Type to edit (delete)",frame=0,pos={115,205}

	Button doFit,win=$ws, size={55,20},pos={425,200}, title="Fit",proc=APF_FitButtonProc
	Button doUndo,win=$ws, size={55,20},pos={490,200}, title="Undo",proc=APF_FitUndoButtonProc,disable=2
	
end

//only called if fit panel is tied to imagetoolV
function APF_Initpanel_HistControls(df,ws)
	string df
	string ws //name of panel
	svar df_it=$df+"df_it"
	
	//variables
	variable/g $df+"autoRecall"=0, $df+"auto_trig"=0
	string/g $df+"optString" = "Rectilinear Bounds;"
	
	//history controls
	button storeFit,win=$ws,size={100,20},pos={0,475},title="Fit --> History",proc=APF_HistoryButtProc
	button retrieveFit,win=$ws,size={100,20},pos={110,475},title="History --> Fit",proc=APF_HistoryButtProc
	Checkbox AutoRecall,win=$ws, pos={110,495},title="Auto Recall",variable=$(df+"autoRecall"), proc=APF_Hist_AutoRecall_CheckProc
	button killFit,win=$ws,size={75,20},pos={220,475},title="Kill Fit",proc=APF_HistoryButtProc
	button killHistory,win=$ws,size={100,20},pos={330,475},title="Kill History",proc=APF_HistoryButtProc
	
	//multifit controls
	variable xb=5, yb=520
	SetDrawLayer/W=$ws UserBack
	setdrawenv/W=$ws fillfgc=(191*256,191*256,191*256)
	drawrect/W=$ws xb-5,yb-5,xb+250,yb+75
	popupmenu FitMenu,win=$ws,size={100,20},pos={xb,yb},title="MultiFit...",mode=0,proc=APF_MultifitMenuProc
	svar optstring=$df+"optString"
	nvar itAxis=$df+"itAxis"
	nvar ndim=$df_it+"nDim"
	if(itAxis>=2)
		optstring+="ROI Mask (this chunk);"
		if(ndim==4)
			optstring+="ROI Mask (multiple chunks)"
		endif
	endif
	variable/g $df+"useAxes"=0
	popupmenu FitMenu,win=$ws,value=#(df+"optstring")
	checkbox UseAxes, win=$ws,pos={xb,yb+20}, title="Use Axis Ranges",variable=$df+"useAxes"
	PopupMenu GuessMode,win=$ws, pos={xb,yb+45},value="Use First Guess for All;Use Previous Fit"
	CheckBox Overwrite, win=$ws, pos={xb+110,yb},title="Overwrite History?",variable=$df+"overwrite"
	CheckBox Animate, win=$ws, pos={xb+110,yb+15},title="Show Full Animation?",variable=$df+"animate"

	//history view controls
	xb=275; yb=520;
	setdrawenv/W=$ws fillfgc=(191*256,191*256,191*256)
	drawrect/W=$ws xb-5,yb-5,xb+250,yb+75
	button ShowPkHist,win=$ws,size={100,20},pos={xb,yb},title="Peak History",proc=APF_HistShow_ButtonProc,disable=2
	svar pppl=$df+"pkParmsPlotList"
	popupmenu pkShow,win=$ws,pos={xb,yb+20},title="Parameter...",mode=1,value=#(df+"pkParmsPlotList")
end

Function APF_HistShow_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			string df=APF_df()
			nvar pin=$df+"hist_PeaksInitted"
			svar df_it=$dF+"df_it"
			wave dnum=$df_it+"dnum"
			string ctrln=ba.ctrlname
			string dname="root"+df
			string firstShow
			strswitch(ctrln)
				case "ShowPkHist":
					dname+="hist_peaks"
					firstShow="pk0_AMP"
					string/g $df+"pkHistPanelName"=""
					svar panName=$df+"pkHistPanelName"
				break
				case "ShowBkHist":
					dname+="hist_bkgd"
					firstShow=""
				break
				case "ShowConstHist":
					dname+="hist_constants"
					
			endswitch
			if(pin)
				NewImagetool5(dname)
				string dfh=getdf()
				panName=winname(0,1)
				//copy axis setup from imagetool to new one
				dim34setproc("dim3index",dnum[2]+1,"")
				dim34setproc("dim4index",dnum[3]+1,"") 
				//turn off profile for parameters
				nvar itAxis=$df+"itAxis"
				string cbn=stringfromlist(itAxis,"hasXP;hasYP;hasZP;hasTP")
				nvar cbv=$dfh+cbn; cbv=0
				checkbox $cbn,win=$winname(0,1),value=0
				setupV(winname(0,1),dname)
				//setup menu list for parameters to show
				svar pppl=$df+"pkParmsPlotList"
				nvar xindex=$df+"xindex"
				pppl=""
				variable i; string ss
				for(i=0;i<dimsize($dname,xindex);i+=1)
					ss=getdimlabel($dname,xindex,i)
					splitstring/E="(pk\d*_h\d*_)" ss  //exclude hold parameters
					if(v_flag==0)
						pppl+=ss+";"
					endif
				endfor
				//set initial value for parameter to display
				string cn=stringfromlist(itaxis,"xc;yc;zc;tc")
				nvar c=$dfh+cn
				variable ci=finddimlabel($dname,xindex,"pk0_AMP")
				c=selectnumber(ci>0,0,ci)
				svar pn=$df+"panelname"
				variable wli=whichlistitem("pk0_AMP",pppl)
				popupmenu pkShow,win=$pn,mode=wli+1
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function APF_Hist_AutoRecall_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			string df=APF_df()
			nvar auto_trig=$df+"auto_trig"
			svar df_it=$df+"df_it"
			nvar ndim=$df_it+"ndim"
			nvar itaxis=$df+"itaxis"
			if(!checked)
				setformula auto_trig,"0"
			else
				variable i
				string ss=""
				for(i=0;i<ndim;i+=1)
					if (i!=itaxis)
						ss+=df_it+stringfromlist(i,"xp+;yp+;zp+;tp+")
					endif
				endfor	
				ss+="APF_Hist_RetrieveFit(\"" + df_it + "\",\""+ df+"\",1)"
				setformula auto_trig, ss
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function APF_HistoryButtProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			//wave hbk=$df+"hist_bkdg"
			//wave hc=$df+"hist_constants"
			//nvar bktype=$df+"bktype"
			//string his=APF_historyIndexString(df, df_it)	
			//string cmd, wvn, ss
			string df=APF_df()
			strswitch (ba.ctrlName)
				case "storeFit":
					APF_Hist_StoreFit(df, 1)	//usecursors=1
					break
				case "retrieveFit":
					svar df_it=$dF+"df_it"
					APF_Hist_RetrieveFit(df, df_it,0)
					break
				case "killFit":
					APF_Hist_KillFit()
				break
				case "killHistory":
					APF_Hist_Reset(df, 1)
				break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//if UseCursors=1 then use live cursors of IT to address the history
//otherwise uses array "fitCoordStore"
function APF_Hist_StoreFit(df, UseCursors)
	variable useCursors
	string df//=APF_df()
	svar df_it=$df+"df_it"
	nvar has_FE=$df+"has_FE"
	nvar has_GW=$df+"has_GW"
	APF_Hist_StorePeaks(df, df_it, 0, useCursors)
	APF_Hist_StoreVal(df,df_it,"constants", "fitted",1,0, useCursors)
	APF_Hist_StoreVar(df, df_it, "bktype",0, useCursors)
	APF_Hist_StoreVar(df, df_it, "FEe_hold",1-has_FE, useCursors)
	APF_Hist_StoreVar(df, df_it, "FEt_hold",1-has_FE, useCursors)
	APF_Hist_StoreVar(df, df_it, "FE_energy",1-has_FE, useCursors)
	APF_Hist_StoreVar(df, df_it, "FE_temp",1-has_FE, useCursors)
	APF_Hist_StoreVar(df, df_it, "has_FE",0, useCursors)
	APF_Hist_StoreVar(df, df_it, "GW_hold",1-has_GW, useCursors)
	APF_Hist_StoreVar(df, df_it, "GW",1-has_GW, useCursors)
	APF_Hist_StoreVar(df, df_it, "has_GW",0, useCursors)
	APF_Hist_StoreVar(df, df_it, "numpks",0, useCursors)
	APF_Hist_StoreBkgd(df, df_it,0, useCursors)
	APF_Hist_StoreBkHold(df, df_it,0, useCursors)
end

//returns -1 if no fit available
//returns 0 otherwise
function APF_Hist_RetrieveFit(df_it, df, silentmode)
	string df_it, df
	variable silentmode // 1 means no error if fit is non-existent
	//string df=APF_df() 
	//svar df_it=$df+"df_it"
	nvar has_FE=$df+"has_FE"
	nvar has_GW=$df+"has_GW"
	nvar bktype=$dF+"bkType" 
	variable usecursors=1
	variable fitted=APF_Hist_RetrieveVal(df, df_it, "constants", "fitted", usecursors) 
	if(fitted!=1)
		if(silentmode==0)
			doalert 0, "Sorry, there is no fit at these coordinates"
		endif
		return -1
	endif
	APF_Hist_RetrievePeaks(df, df_it)
	APF_Hist_RetrieveBkgd(df, df_it)
	APF_Hist_RetrieveVar(df, df_it, "bktype")
	APF_Hist_RetrieveVar(df, df_it, "has_FE")
	APF_Hist_RetrieveVar(df, df_it, "has_GW")
	if(has_FE)
		APF_Hist_RetrieveVar(df,df_it,"FEe_hold")
		APF_Hist_RetrieveVar(df,df_it,"FEt_hold")
		APF_Hist_RetrieveVar(df,df_it,"FE_energy")
		APF_Hist_RetrieveVar(df,df_it,"FE_temp")
	endif
	if(has_GW)
		APF_Hist_RetrieveVar(df,df_it,"GW_hold")
		APF_Hist_RetrieveVar(df,df_it,"GW")
	endif
	APF_FixBkgdListBox(df, bktype,1)
	APF_copyBkVals2Disp(df,bkType)
	APF_UpdatePF(dF)
	APF_SetHiLitePk(df,-1)
	return 0
end

function APF_Hist_KillFit()
	string df=APF_df()
	svar df_it=$df+"df_it"
	variable useCursors=1
	APF_Hist_StoreVal(df, df_it, "constants", "", NaN,0,1)
	APF_Hist_StoreVal(df, df_it, "constants", "fitted", 0, 0, 1)
	APF_Hist_StoreBkgd(df, df_it, 1, 1)
	APF_Hist_StoreBkHold(df, df_it, 1, 1)
	APF_Hist_StorePeaks(df, df_it,1, 1)
end

function/t APF_Hist_MakeWave(dfn,name,size)
	string dfn,name
	variable size
 	svar df_it=$dfn+"df_it"
	nvar xIndex=$dfn+"xIndex"
	nvar ndim=$(df_it+"ndim")
	svar dname=$(df_it+"dname")
	wave data=$dname
	
	variable ii
	string wvname=dfn + "hist_" + name
	//*D* Double Precision
	string cmd="make/o/s/n=("
	for(ii=0;ii<ndim;ii+=1)
		cmd += num2str(selectnumber(ii==xindex,dimsize(data,ii),size)) + selectstring(ii==(ndim-1),",","") 
	endfor
	cmd+=") " + wvname
	execute cmd
	wave histwave=$wvname
	histwave=nan
	copyscales data,histwave
	cmd="setscale/p "+ stringfromlist(xindex,"x ;y ;z ;t ") + "0,1," + "\"ParmIndex\", " + wvname
	execute cmd
	histwave=0
	return wvname
end


function APF_Hist_Reset(df, doAlrt)
	string df; variable doAlrt
	if(doAlrt)
		doAlert 1,"Are you sure you want to delete the entire fit history?"
	endif
	if((v_flag!=1)*(doAlrt))
		return -1
	endif
	nvar hpi=$df+"hist_PeaksInitted"
	svar df_it=$df+"df_it"

	hpi=0
	svar ws=$df+"panelname"
	button ShowPkHist,win=$ws,disable=2
	string hwvn=df+"hist_bkgd"; 	wave hwv=$hwvn
	hwv=nan
	hwvn=df+"hist_bk_hold"; 	wave hwv=$hwvn
	hwv=nan
	hwvn=df+"hist_constants"; 	wave hwv=$hwvn
	hwv=nan
	variable usecursors=1
	APF_Hist_StoreVal(df, df_it, "constants", "fitted", 0, 1, useCursors)	//set all "fitted" to 0 not nan
	hwvn=df+"hist_peaks"; 	wave hwv=$hwvn
	string his=APF_historyDimensString(df, df_it)
	string ss, cmd
	sprintf ss, his, "1"
	cmd="redimension/n=" + ss + hwvn
	execute cmd
	hwv=nan
end

Function APF_Hist_StoreBkgd(df, df_it, storeNaN, useCursors)
	string df, df_it
	variable storeNaN	//if 1 puts NaN instead of value
	variable useCursors
	string hwvn=df+"hist_bkgd"; 	wave hwv=$hwvn
	string wvn="bkVals";			wave wv=$df+wvn
	string his=APF_historyIndexString(df, df_it, 0, useCursors)
	nvar xindex=$df+"xIndex"
	string ss, cmd
	sprintf ss,his,"0,"+num2str(dimsize(wv,0)-1)
	cmd=hwvn+ss + "=" + selectString(storeNaN, wvn + "[" + stringfromlist(xIndex,"p;q;r;s") + "]","NaN")
	execute cmd
	//set nonused parms to nan
	if (dimsize(hwv,xindex)>dimsize(wv,0))
		sprintf ss,his,num2str(dimsize(wv,0))+","
		cmd=hwvn+ss + "=nan"
		execute cmd
	endif
end

function APF_Hist_StorePeaks(df, df_it, storeNaN, useCursors)
	string df, df_it
	variable storeNaN //if 1 puts NaN instead of values
	variable useCursors
	string hwvn=df+"hist_peaks"; 	wave hwv=$hwvn
	string ppwvn="pkParms";			wave ppwv=$df+ppwvn
	string ptwvn="pkTypes";			wave ptwv=$df+ptwvn
	nvar numpks=$df+"numpks"
	nvar xindex=$df+"xIndex"
	svar panelname=$df+"panelname"
	
	nvar hist_PeaksInitted=$df+"hist_PeaksInitted"
	wave/t psd=root:APF:PeakShapeDescr
	string cmd, ss, his=APF_historyDimensString(df, df_it)
	if (!hist_PeaksInitted)
		//redimension peaks history wave, only works for more peaks, not fewer peaks?
		variable i,n=0
		for(i=0;i<numpks;i+=1)
			n+=1												 //store enable value
			n+=1												//store peak type
			n+= 1 + 4*2*ptwv[i][%has_so]  				//has_so, so_split, so_ratio (not stored if not used)
			n+= 1 + 3*ptwv[i][%has_shirley]			//store -1 for no shirley bkgd, or pos value if yes
			n+= 4*APF_NumParmsPkFit(ptwv[i][%type]) //*4 since storing peakvalues (1) and hold values (+3)
		endfor
		sprintf ss,his,num2str(n)	
		cmd="redimension/n="+ss+" " + hwvn
		execute cmd
		hist_PeaksInitted=1
		button ShowPkHist,win=$panelname,disable=0
	endif
	variable pp=0,ppi, j, k
	string si, slab=";h0_;h1_;h2_"
	his=APF_historyIndexString(df, df_it,0,useCursors)
	//loop over peaks
	
	for(i=0;i<numpks;i+=1)
		n=APF_NumParmsPkFit(ptwv[i][%type])
		//store enable
		setdimlabel xIndex,pp,$("pk"+num2str(i)+"_enable"),hwv; pp+=1
		APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_enable"), ptwv[i][%enable], 0, useCursors)
		//store type
		setdimlabel xIndex,pp,$("pk"+num2str(i)+"_type"),hwv; 	pp+=1
		APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_type"), ptwv[i][%type], 0, useCursors)
		//store SO information
		setdimlabel xIndex,pp,$("pk"+num2str(i)+"_has_so"),hwv; pp+=1
		APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_has_so"), ptwv[i][%has_so], 0, useCursors)
		if(ptwv[i][%has_so])
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_soSplit"),hwv; 		pp+=1
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h0_soSplit"),hwv; 	pp+=1
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h1_soSplit"),hwv; 	pp+=1
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h2_soSplit"),hwv; 	pp+=1
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_soSplit"), ppwv[i][%soSplit][0], 0, useCursors)
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h0_soSplit"), ppwv[i][%soSplit][1], 0, useCursors)
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h1_soSplit"), ppwv[i][%soSplit][2], 0, useCursors)
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h2_soSplit"), ppwv[i][%soSplit][3], 0, useCursors)
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_soRatio"),hwv; 		pp+=1
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h0_soRatio"),hwv; 	pp+=1
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h1_soRatio"),hwv; 	pp+=1
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h2_soRatio"),hwv; 	pp+=1
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_soRatio"), ppwv[i][%soRatio][0], 0, useCursors)
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h0_soRatio"), ppwv[i][%soRatio][1], 0, useCursors)
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h1_soRatio"), ppwv[i][%soRatio][2], 0, useCursors)
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h2_soRatio"), ppwv[i][%soRatio][3], 0, useCursors)
		endif
		//store Shirley information
		setdimlabel xIndex,pp,$("pk"+num2str(i)+"_shirley"),hwv; pp+=1
		APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_shirley"), Selectnumber(ptwv[i][%has_shirley],-1, ppwv[i][%shirley_amp][0]), 0, useCursors)
		if(ptwv[i][%has_shirley])
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h0_shirley"),hwv; pp+=1
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h1_shirley"),hwv; pp+=1
			setdimlabel xIndex,pp,$("pk"+num2str(i)+"_h2_shirley"),hwv; pp+=1
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h0_shirley"), Selectnumber(ptwv[i][%has_shirley],-1, ppwv[i][%shirley_amp][1]), 0, useCursors)
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h1_shirley"), Selectnumber(ptwv[i][%has_shirley],-1, ppwv[i][%shirley_amp][2]), 0, useCursors)
			APF_Hist_StoreVal(df, df_it, "peaks", ("pk"+num2str(i)+"_h2_shirley"), Selectnumber(ptwv[i][%has_shirley],-1, ppwv[i][%shirley_amp][3]), 0, useCursors)
		endif
		//store peakParms
		ppi=finddimlabel(ppwv,1,"parms")
		//loop over fit parms[0], hold[1], hold[2], hold[3]
		for(j=0;j<4;j+=1)
			sprintf ss,his,num2str(pp) + "," + num2str(pp+n-1)
			if(StoreNan)
				cmd=hwvn + ss + "= NaN"
			else 
				si=hwvn + ss + "=" + ppwvn + "[%d][%d+(%s-%d)][%d]"
				sprintf cmd,si,i,ppi,stringfromlist(xIndex,"p;q;r;s"), pp, j  
			endif
			execute cmd
			//loop over parms (POS, WID, etc)
			n=APF_NumParmsPkFit(ptwv[i][%type])
			for(k=0;k<n;k+=1)
				setdimlabel xIndex,pp+k,$("pk"+num2str(i)+"_" + stringfromlist(j,slab) + psd[k+1][ptwv[i][%type]]),hwv
			endfor
			pp+=n
		endfor
		printf ""
	endfor
end

function APF_Hist_RetrievePeaks(df, df_it)
	string df, df_it
	string hwvn=df+"hist_peaks"; 	wave hwv=$hwvn
	string ppwvn="pkParms";			wave ppwv=$df+ppwvn
	string ptwvn="pkTypes";			wave ptwv=$df+ptwvn
	variable usecursors=1
	nvar numpks=$df+"numpks"
	nvar xindex=$df+"xIndex"
	string cmd, ss, his=APF_historyIndexString(df, df_it,0,1)
	printf ""
	variable i, j, pk_i, temp, nparms
	wave/T psd=root:APF:PeakShapeDescr
	APF_Hist_RetrieveVar(df, df_it, "numpks")	//history # peaks
	//loop over peaks
	for(i=0;i<numpks;i+=1)
		//retrieve enabled?
		ptwv[i][%enable]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_enable", usecursors )
		//retrieve peak type
		ptwv[i][%type]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_type", usecursors)
		//retrieve SO
		ptwv[i][%has_so]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_has_so", usecursors)
		if(ptwv[i][%has_so])
			ppwv[i][%soSplit][0]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_soSplit", usecursors)
			ppwv[i][%soSplit][1]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h0_soSplit", usecursors)
			ppwv[i][%soSplit][2]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h1_soSplit", usecursors)
			ppwv[i][%soSplit][3]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h2_soSplit", usecursors)
			ppwv[i][%soRatio][0]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_soRatio", usecursors)
			ppwv[i][%soRatio][1]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h0_soRatio", usecursors)
			ppwv[i][%soRatio][2]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h1_soRatio", usecursors)
			ppwv[i][%soRatio][3]=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h2_soRatio", usecursors)
		endif
		//retrieve shirley
		temp=APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_shirley", usecursors)
		ptwv[i][%has_shirley]=(temp != -1)
		if(ptwv[i][%has_shirley])
			ppwv[i][%shirley_amp][0] = APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_shirley", usecursors)
			ppwv[i][%shirley_amp][1] = APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h0_shirley", usecursors)
			ppwv[i][%shirley_amp][2] = APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h1_shirley", usecursors)
			ppwv[i][%shirley_amp][3] = APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h2_shirley", usecursors)
		endif
		//retrieve peak parms
		variable type
		string pname
		type=ptwv[i][%type]
		nparms=APF_NumParmsPkFit(type)
		pk_i=finddimlabel(ppwv,1,"parms")
		for (j=0;j<nparms;j+=1)
			pname=psd[j+1][type]
			ppwv[i][pk_i +j][0] = APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_"+pname, usecursors)
			ppwv[i][pk_i +j][1] = APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h0_"+pname, usecursors)
			ppwv[i][pk_i +j][2] = APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h1_"+pname, usecursors)
			ppwv[i][pk_i +j][3] = APF_Hist_RetrieveVal(df, df_it, "peaks", "pk"+num2str(i)+"_h2_"+pname, usecursors)
			
		endfor
		
	endfor
	
end

Function APF_Hist_StoreBkHold(df, df_it,storeNaN, useCursors)
	string df, df_it
	variable storeNaN	//if 1 puts NaN instead of value
	variable useCursors
	string hwvn=df+"hist_bk_hold"; 	wave hwv=$hwvn
	string wvn="bkDispSel";				wave wv=$df+wvn
	string his=APF_historyIndexString(df, df_it, 0, useCursors)
	nvar xindex=$df+"xIndex"
	string ss, cmd
	sprintf ss,his,"0,"+num2str(dimsize(wv,0)-1)
	cmd=hwvn+ss + "=" + selectstring(storeNaN,"(" + wvn + "[" + stringfromlist(xIndex,"p;q;r;s") + "][2] & 0x010)>0","NaN")
	execute cmd
	//set nonused parms to nan
	if (dimsize(hwv,xindex)>dimsize(wv,0))
		sprintf ss,his,num2str(dimsize(wv,0))+","
		cmd=hwvn+ss + "=nan"
		execute cmd
	endif

end

Function APF_Hist_RetrieveBkgd(df, df_it)
	string df, df_it
	string hwvn="root"+df+"hist_bkgd"; 	wave hwv=$hwvn
	string cwvn="root"+df+"hist_constants"; 	wave cwv=$cwvn

	string wvn="root"+df+"bkVals";				wave wv=$wvn
	string his=APF_historyIndexString(df, df_it, 0,1)
	nvar xindex=$df+"xIndex"
	string ss, cmd
	variable usecursors=1
	//retrieve number of parameters
	variable bktype=APF_Hist_RetrieveVal(df, df_it, "constants", "bktype", usecursors)
	redimension/n=(APF_NumParmsBkgdFit(bktype)) wv

	sprintf ss,his,"p"
	cmd=wvn+"="+hwvn+ss
	execute cmd
end

//stores a numeric value into history wave
//if name="", writes all parameters for this history entry
//if setAll=1, writes parameters to all history entries
Function APF_Hist_StoreVal(df, df_it, histname, valuename,val, setAll, useCursors)
	string df, df_it, histname, valuename
	variable val, setAll, useCursors
	string cwvn="root"+df+"hist_"+histname; 	wave cwv=$cwvn
	string his=APF_historyIndexString(df, df_it, setAll, useCursors)
	nvar xindex=$df+"xIndex"
	string ss, cmd
	sprintf ss, his, selectstring(strlen(valuename),"","%"+valuename)
	cmd=cwvn+ss+"=" + num2str(val)
	execute cmd
end

Function APF_Hist_RetrieveVal(df, df_it, histname, valuename,usecursors)
	string df, df_it, valuename, histname
	variable usecursors
	string cwvn="root"+df+"hist_"+histname; 	wave cwv=$cwvn
	string his=APF_historyIndexString(df, df_it, 0, usecursors)
	nvar xindex=$df+"xIndex"
	string ss, cmd
	sprintf ss, his, "%"+valuename
	variable/g $df+"tempv"; nvar tempv=$df+"tempv"
	cmd="root"+df+"tempv="+cwvn+ss
	execute cmd
	return tempv
end

//stores a global variable into history wave
//if name="", writes all values (only NaN works)
Function APF_Hist_StoreVar(df, df_it, varname, storeNaN, useCursors)
	string df, df_it, varname
	variable storeNaN	//if 1 puts NaN instead of value
	variable useCursors
	string hwvn=df+"hist_constants"
	string his=APF_historyIndexString(df, df_it, 0, useCursors)
	nvar value=$df+varname
	string ss
	sprintf ss,his,selectstring(strlen(varname),"","%"+varname)
	string cmd= hwvn+ss+ "=" + selectstring(storeNaN,num2str(value),"NaN")
	execute cmd
end

Function APF_Hist_RetrieveVar(df, df_it, varname)
	string df, df_it, varname
	string hwvn=df+"hist_constants"
	string his=APF_historyIndexString(df, df_it, 0, 1)
	string ss,cmd
	sprintf ss,his,"%"+varname
	cmd="root"+df+varname + "=" + "root"+ hwvn + ss
	execute cmd
end


//returns string "[#][#][%s][#]
//where #s come from appropriate cursors of image tool (indexed to original wave axes)
//and %s is a placeholder for later sprintf command
//if isAll=1, then return []'s instead of [#]'s
//if useCursors==1, #s returned come from the live cursors
//otherwise they come from the array fitCoordStore
function/t APF_historyIndexString(df,df_it,isAll,useCursors)
	string df, df_it
	variable isAll, useCursors
	nvar xIndex=$df+"xIndex"
	nvar ndim=$df_it+"ndim"
	wave adnum=$df_it+"adnum"
	variable ii, j=0
	string ss=""
	for(ii=0;ii<ndim;ii+=1)
		if(ii==xIndex)
			ss+="[%s]"
		else
			if(!isAll)
				if(useCursors)
					nvar pp=$df_it+stringfromlist(adnum[ii],"xp;yp;zp;tp")
					ss+="["+ num2str(round(pp))+ "]"
				else
					wave fcs=$df+"fitCoordStore"
					ss+="[" + num2str(fcs[j]) + "]"
					j+=1
				endif
			else
				ss+="[]"
			endif
		endif
	endfor
	//print ss
	return ss
end

//returns string (#, #, %s, #) 
//where #s come from dimensions of source data
//and %s is a placeholder for later sprintf command
function/t APF_historyDimensString(df, df_it)
	string df, df_it
	nvar xIndex=$df+"xIndex"
	wave adnum=$df_it+"adnum"
	wave dnum=$df_it+"dnum"
	svar dname=$df_it+"dname"
	wave data=$dname
	nvar ndim=$df_it+"ndim"
	variable ii
	string ss="("
	for(ii=0;ii<ndim;ii+=1)
		ss+=selectstring(ii>0,"",", ") 
		if(ii==xIndex)
			ss+="%s"
		else
			ss+=num2str(dimsize(data,ii))
		endif
	endfor
	return ss+")"
end


//val> 0 means add region
//val< 0 means clear region
function APF_AddBkgdRgn(val)
	variable val
	string df="x"
	print apf_df()
	df=APF_df()
	svar xaxis=$df+"xaxis"
	getmarquee/K $xaxis
	print v_left, v_right
	wave bkgdrgn=$df+"bkgdrgn"
	svar ywn=$df+"ywn"
	wave yw=$ywn
	variable p0=APF_forcePrange(x2pnt(yw,v_left),yw)
	variable p1=APF_forcePrange(x2pnt(yw,v_right),yw)
	bkgdrgn[min(p0,p1),max(p0,p1)]=selectnumber(val>0, nan, yw[p])
end
 
function APF_AddPeak(pktype_i)
	variable pktype_i
	string df=APF_df()
	nvar numpks=$df+"numpks"
	numpks+=1
	wave/t peakShapeDescr=root:APF:peakShapeDescr
	wave pktypes=$df+"pkTypes"
	wave pkparms=$df+"pkParms"
	svar ywn=$df+"ywn"
	wave pf=$df+"pkFit", pfx=$df+"pkfitX",pfx1=$df+"pfx1", pfy1=$df+"pfy1"

	//main peak parameters
	redimension/n=(numpks,8) pktypes
	setdimlabel 1,0,type,pktypes				//Peak Type Index
	setdimlabel 1,1,expand,pktypes				//expand in table = ON
	setdimlabel 1,2,has_so,pktypes				//has so splitting?
	setdimlabel 1,3,so_fitcoef_i,pktypes		//index for so parms in fit coefs wave
	setdimlabel 1,4,has_shirley,pktypes		//has shirley bkgd?
	setdimlabel 1,5,shirley_fc_i,pktypes		//index for shirley parms in fit coefs wave
	setdimlabel 1,6,enable,pktypes				//enable in fit
	setdimlabel 1,7,fitcoef_i,pktypes			//stores index to parameters in fitcoefs wave
	pktypes[numpks-1][%type]=pktype_i 	
	pktypes[numpks-1][%expand]=1 				
	pktypes[numpks-1][%has_so]=0
	pktypes[numpks-1][%enable]=1
	pktypes[numpks-1][%so_fitcoef_i]=NaN
	pktypes[numpks-1][%shirley_fc_i]=NaN
	pktypes[numpks-1][%fitcoef_i]=NaN
	
	//first plane: fit parameters
	//second plane: free=0  hold=1, constrain (plus)=2, constrain (times)=3, constrain (range) =4
	//third plane:  when 2, 3: the value for adding or multiplying ; when 4: range lo
	//fourth plane: when2, 3: index of the other peak; when 4: range hi
	redimension/n=(numpks, 3+dimsize(peakShapeDescr,0)-1,4) pkparms	//3+ for soSplit, soRatio, shirley
	pkparms[numpks-1][][]=nan
	pkparms[numpks-1][][1]=0
	setdimlabel 1,0,soSplit,pkParms
	setdimlabel 1,1,soRatio,pkParms
	setdimlabel 1,2,shirley_amp,pkParms
	setdimlabel 1,3,parms,pkParms
	pkParms[numpks-1][%soSplit][0]=1.0
	pkParms[numpks-1][%soRatio][0]=0.5
	pkParms[numpks-1][%shirley_amp][0]=0

	APF_InitPeak(df, pkparms, numpks-1, pktype_i)
	redimension/n=(dimsize(pfx1,0),numpks) pf, pfx
	pfx[][]=pfx1[p]
	if(numpks==1)
		copyscales pfy1 pf
	endif
	APF_updatePF(df)
	APF_copyPkTypes2Disp(df, pkTypes)
	APF_SetHiLitePk(df,numpks-1)
end

//use i<0 to hide the hilite peak
function APF_SetHiLitePk(df,i)
	string df;	variable i
	wave pkfit=$df+"pkFit"
	wave pkhl=$df+"pkFitHiLite"
	if(i<0)
		pkhl=nan
	else
		pkhl=pkFit[p][i]
	endif
end


function APF_InitPeak(df, pkparms, pk_i, pktype_i)
	string df
	wave pkparms
	variable pk_i,pktype_i
	wave/T pkDescr=root:APF:PeakShapeDescr
	svar xaxis=$df+"xaxis"
	svar yaxis=$df+"yaxis"
	GetMarquee/K $xaxis,$yaxis
	variable p0=findDimLabel(pkParms,1,"parms")
	pkparms[pk_i][p0][0]=0.5*(v_left+v_right) //POS
	pkparms[pk_i][p0+1][0]=abs(v_top-v_bottom) //AMP
	pkparms[pk_i][p0+2][0]=0.5*abs(v_left-v_right) //Width
	variable k, kmax=APF_NumParmsPkFit(pktype_i), newWid
	string pname
	for(k=3;k<kmax;k+=1)
		pname=pkDescr[k+1][pktype_i]
		if(cmpstr(pname,"GW")==0)
			newWid=pkparms[pk_i][p0+2][0]/sqrt(2)
			pkparms[pk_i][p0+2][0]=newWid
			pkparms[pk_i][p0+k][0]=newWid
		else
			pkparms[pk_i][p0+k][0]=0
		endif
	endfor
	
end

static function wait(s)
	variable s
	variable t=datetime
	do
	while ((datetime-t)<s)
end

function APF_copyPkTypes2Disp(df,pkTypes)
	string df
	wave pkTypes
	variable numCols=5
	wave/t pkDisp=$df+"pkDisp"
	wave pkDispSel=$df+"pkDispSel"
	wave/t peakShapeDescr=root:APF:peakShapeDescr
	wave pkParms=$df+"pkParms"
	variable i=0, imax=dimsize(pktypes,0)-1, j=0, n1, n2, n3, p0,k, pkd_dim
	redimension/n=0 pkDisp, pkDispSel
	for(i=0;i<=imax;i+=1)
		// add line for peak
		pkd_dim=dimsize(pkdisp,0)
		redimension/n=(pkd_dim+1, numCols) pkdisp
		redimension/n=(pkd_dim+1, numCols,3) pkDispSel
		setdimlabel 2,1,foreColors,pkDispSel
		setdimLabel 2,2,backColors,pkDispSel
		//label and set colors of line
		setdimlabel 0,j,$("Peak"+num2str(i)),pkdisp
		pkdispsel[j][][%foreColors]=0
		pkdispsel[j][][%backColors]=selectnumber(pktypes[i][%enable],3,2) //Colors

		//1st column, expansion triangle state
		pkdisp[j][0]="Peak "+num2str(i)
		pkDispSel[j][0]=selectnumber(pktypes[i][%expand],64,80)
		//2nd column, lineshape type
		pkdisp[j][1]=APF_pkTypeNm(pktypes[i][%type])
		//3rd column, "has SO?"
		pkdisp[j][2]="S-O split?"
		pkdispsel[j][2][0]=selectnumber(pktypes[i][%has_so],32,48)
		//4th column, "has Shirley?"
		pkdisp[j][3]="Shirley bkgd?"
		pkdispsel[j][3][0]=selectnumber(pktypes[i][%has_shirley],32,48)
		//5th column, "enable?"
		pkdispsel[j][4][0]=selectnumber(pktypes[i][%enable],32,48)
		pkdisp[j][4]="Enable?"

		j+=1
		//add additional lines if peak is expanded in display
		if(pkTypes[i][%expand])
			n1=dimsize(pkDisp,0)
			n2=APF_numParmsPkFit(pktypes[i][%type])
			n3=2*pktypes[i][%has_so] + pktypes[i][%has_shirley]
			redimension/n=(n1+n2+n3, numCols) pkdisp				   // add lines for peak
			redimension/n=(n1+n2+n3, numCols,3) pkdisp, pkDispsel // add lines for peak
			//regular parameters
			for(k=0;k<n2;k+=1)
				pkdisp[j+k][0]=peakShapeDescr[k+1][pktypes[i][%type]] //copy name of parm to disp "AMP", etc
				p0=finddimlabel(pkParms,1,"parms")
				pkdisp[j+k][1]=num2str(pkParms[i][p0+k][0])
				pkdisp[j+k][2]=APF_holdDescr(pkParms,i,p0+k)
				setdimlabel 0,j+k,$num2str(i), pkdisp
				pkdispsel[j+k][][%foreColors]=selectnumber(pktypes[i][%enable],4,0) //dkgrey (disabled) vs black (enabled)
				pkdispsel[j+k][1][0]=selectnumber((pkparms[i][p0+k][1]==2) + (pkparms[i][p0+k][1]==3), 2, 0) //make parms editable if not der. from other pk
			endfor
			j+=n2
			//SO Splitting
			if(pktypes[i][%has_so])
				pkdisp[j][0]="soSPLIT";   pkdisp[j][1]=num2str(pkparms[i][%sosplit][0])
				pkdisp[j][2]=APF_holdDescr(pkParms,i,finddimlabel(pkparms,1,"sosplit"))
				pkdisp[j+1][0]="soRATIO"; pkdisp[j+1][1]=num2str(pkparms[i][%soratio][0])
				pkdisp[j+1][2]=APF_holdDescr(pkParms,i,finddimlabel(pkparms,1,"soratio"))
				setdimlabel 0,j,$num2str(i), pkdisp
				setdimlabel 0,j+1,$num2str(i), pkdisp
				pkdispsel[j,j+1][][%foreColors]=selectnumber(pktypes[i][%enable],5,1) //pink (disabled) vs red (enabled)
				pkdispSel[j,j+1][1][0]=selectnumber((pkparms[i][finddimlabel(pkparms,1,"sosplit")+(p-j)][1]==2) + (pkparms[i][finddimlabel(pkparms,1,"sosplit")+(p-j)][1]==3), 2, 0) //make parms editable if not der. from other pk
				j+=2
			endif
			//shirley
			if(pktypes[i][%has_shirley])
				pkdisp[j][0]="SHIRLEY_AMP"
				pkdisp[j][1]=num2str(pkParms[i][%shirley_amp][0])
				pkdisp[j][2]=APF_holdDescr(pkParms,i,finddimlabel(pkparms,1,"shirley_amp"))
				setdimlabel 0,j,$num2str(i), pkdisp
				pkdispsel[j][][%foreColors]=selectnumber(pktypes[i][%enable],5,1) //pink (disabled) vs red (enabled)
				pkdispsel[j][1][0]=2 //make parms editable
				
				j+=1
			endif
		endif
	endfor
end

function/S APF_holdDescr(pkParms,pk_i,parm_i)
	wave pkParms
	variable pk_i,parm_i
	variable holdType=pkParms[pk_i][parm_i][1]
	string ss
	switch (holdtype)
		case 0:
			return "free"
		case 1: //held constant
			return "fixed"
		case 2: //offset to another peak
			variable offsetVal=pkParms[pk_i][parm_i][2]
			variable relPk=pkParms[pk_i][parm_i][3]
			sprintf ss,"offset by %f from peak # %d", offsetVal, relPk
			return ss
		case 3:	//scaled to another peak
			variable scaleVal=pkParms[pk_i][parm_i][2]
			variable relPk2=pkParms[pk_i][parm_i][3]
			sprintf ss,"scaled by %f rel. to peak # %d", scaleVal, relPk2
			return ss
		case 4:	//constrained to range
			variable lo=pkParms[pk_i][parm_i][2]
			variable hi=pkParms[pk_i][parm_i][3]
			sprintf ss,"between  %f to %f", lo, hi
			return ss
	endswitch
end 
 
function/s APF_pkTypeNm(pktype_i)
	variable pktype_i
	if(!waveexists(root:APF:peakShapeDescr))
		APF_InitConstants() 
	endif
	wave/t psd=root:APF:peakShapeDescr
	return psd[0][pktype_i] 
end
    
function APF_forcePrange(pval,yw)
	variable pval; wave yw
	if (pval<0)  
		pval=0
	endif
	if (pval>=dimsize(yw,0))
		pval=dimsize(yw,0)-1
	endif
	return pval
end

function APF_forceXrange(xval, yw)
	variable xval; wave yw
	variable x0=dimoffset(yw,0)
	variable x1=dimoffset(yw,0)+dimdelta(yw,0)*dimsize(yw,0)
	variable minx=min(x0,x1), maxx=max(x0,x1)	
	if (xval<minx)
		xval=minx
	endif
	if(xval>maxx)
		xval=maxx
	endif
	return xval
end

function/s APF_BkgdTypes()
	wave/t bk=root:APF:bkgdDescr
	variable i
	string ss=""
	for(i=0;i<dimsize(bk,1);i+=1)
		ss+=bk[0][i]+";"
	endfor
	return ss
end

function/s APF_PeakTypes()
	wave/t pk=root:APF:peakShapeDescr
	variable i
	string ss=""
	for(i=0;i<dimsize(pk,1);i+=1)
		ss+=pk[0][i]+";"
	endfor
	return ss
end


//yw is scaled wave in APF subfolder
//checks if trace is already on the correct graph; does not append if already there
//ignores xw if blank
function APF_appwv(yw,xw)
	string yw,xw
	string wn=winname(0,1) //top graph
	string dfn=APF_df()  //":APF_"+wn+":"
  // variable nl=numinlist(yw,":") 
	string ywt=lowerstr(nameofwave($yw))  //strip path from name
	string tl=lowerstr(tracenamelist("",";",1))
	svar yaxis=$(dfn+"yaxis")
	svar xaxis=$(dfn+"xaxis")
	variable ii=0, hastrace
	string xwave=stringbykey("XWAVE",xaxis)
	string ti
	do
		ti=traceinfo(wn,ywt,ii)
		if (cmpstr(stringbykey("XAXIS",ti),xaxis)==0 && cmpstr(stringbykey("YAXIS",ti),yaxis)==0)
			hastrace+=1
		endif
		ii+=1
	while (strlen(ti)>0)
	if (!hastrace)
		if(!strlen(xw))
			appendtograph/w=$wn/l=$(yaxis)/b=$(xaxis) $yw
		else
			appendtograph/w=$wn/l=$(yaxis)/b=$(xaxis) $yw vs $xw
		endif
	endif	
end
	
function/s APF_df()
	string wn=winname(0,1)
	svar curr_df=root:APF:curr_df
	curr_df=":APF_" + wn + ":"
	return curr_df
end

static function/s tracename2wavename(tn)
	string tn
	variable ss=strsearch(tn,"#",0)
	if(ss>=0)
		return tn[0,ss-1]
	else
		return tn
	endif
end

//menu item is blank if there is no fitter added
function/s APF_Menu(ss)
	string ss
	if(APF_hasFitPane())
		return ss
	else
		return ""
	endif
end
	
function APF_hasFitPane()
	string name=WinName(0,1)+"#APF"
	getwindow/Z $name active
	return v_flag==0
end
	
function APF_InitConstants()
	newdatafolder/O root:APF
	string/g root:APF:curr_df
	make/o/t/n=(9,8) root:APF:bkgdDescr
	wave/t bk=root:APF:bkgdDescr
	bk=""
	bk[][0]={"Offset","c0"	}
	bk[][1]={"Line","c0", "c1"}
	bk[][2]={"Poly 3", "c0", "c1", "c2"}
	bk[][3]={"Poly 4", "c0", "c1", "c2", "c3"}
	bk[][4]={"Poly 5", "c0", "c1", "c2", "c3", "c4"}
	bk[][5]={"Poly 6", "c0", "c1", "c2", "c3", "c4", "c5"}
	bk[][6]={"Poly 7", "c0", "c1", "c2", "c3", "c4", "c5", "c6"}
	bk[][7]={"Poly 8", "c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7"}	
	
	make/o/t/n=3 root:APF:bkgdParmsTitles
	wave/t bkt=root:APF:bkgdParmsTitles
	bkt={"Param", "Value", "hold?"}
	
	make/o/t/n=(5,5) root:APF:peakShapeDescr
	wave/t pk=root:APF:peakShapeDescr
	pk=""
	//All peaks must start with "POS", "AMP" and width parameter (arb name)
	//Reserved names: "soSPLIT", "soRATIO", "SHIRLEY"
	//GW is initialized as peak width, or if width parameter present, splitted in quadrature
	//all other parameters initialized to 0
	pk[][0]={"Lorentzian", "POS", "AMP", "LW"}
	pk[][1]={"Gaussian", "POS", "AMP", "GW"}
	pk[][2]={"Voigt", "POS", "AMP", "LW", "GW"}
	pk[][3]={"DoniacSunjic", "POS", "AMP", "LW", "ASYM"}
	pk[][4]={"DSGauss","POS", "AMP", "LW", "GW", "ASYM"}

	make/o/n=(6,3) root:APF:peakDispColors
	wave peakDispColors=root:APF:peakDispColors
	peakDispColors={{0,65535,0,55000,40000,65535},{0,0,65535,55000,40000,45000},{0,0,65535,55000,40000,45000}} //black, red, teal, grey, dkgrey, pink
end



Function APF_ClearBkgdRegionButtProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string df=APF_df()
			wave bkgdRgn=$df+"bkgdRgn"
			bkgdRgn=nan
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
	

Function APF_GuessBkgdButtProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			APF_BkgdGuess(APF_df(),1)

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function APF_ChangeLineshape(df, pk_i)
	string df; variable pk_i
	wave pktypes=$df+"pktypes"
	variable ls_curr=pktypes[pk_i][%type]+1  //add 1 for popmenu base
	variable ls_new=ls_curr
	prompt ls_new, "Choose new lineshape",popup, APF_peaktypes()
	doprompt "New lineshape", ls_new
	if((v_flag==0)*(ls_new!=ls_curr)) //not cancelled
		pktypes[pk_i][%type]=ls_new - 1
		return 0
	else
		return 1 //cancelled
	endif
end

Function APF_ChangePeakHold(df, pk_i, parm_i, parmname)
	string df
	variable pk_i, parm_i
	string parmname
	wave pkParms=$df+"pkParms"
	wave pkTypes=$df+"pkTypes"
	variable oldholdtype=pkParms[pk_i][parm_i][1]+1, holdtype=oldholdtype //1-based
	variable p2=pkParms[pk_i][parm_i][2]
	variable p3=pkParms[pk_i][parm_i][3]
	wave/T psd=root:APF:peakShapeDescr
	prompt holdtype "Choose hold mode", popup, "Free;Fixed;Offset to Peak;Scaled to Peak;Range"
	doprompt "new holdmode", holdtype
	if (v_flag==1)
		return 1 // cancelled
	endif
	if(holdtype==5) //range
		prompt p2,APF_holdTypeToDescr(holdtype-1,0)
		prompt p3,APF_holdTypeToDescr(holdtype-1,1)
		doprompt "hold parameters",p2,p3
	elseif((holdtype==3)+(holdtype==4))	// offset/scale to other peak
		string peaknumlist=APF_activePeaksList(df,pk_i,parmname)
		if(cmpstr(peaknumlist,"NA")==0)
			doalert 0,"Sorry, there are no other enabled peaks available with parameter "+"\""+parmname+"\""
			return 1 //cancelled
		else
			p3+=1	//to ref menu item
			prompt p2,APF_holdTypeToDescr(holdtype-1,0)
			prompt p3,"relative to peak #",popup,peaknumlist
			doprompt "hold parameters",p2, p3
		endif
	endif
	if(v_flag==1)
		return 1 //cancelled
	endif
	variable parm_index=APF_ParmDispNametoParmIndex(parmName,APF_Peakname(df,pk_i),pkParms)
	pkparms[pk_i][parm_index][1]=holdtype-1
	if(holdtype==5)
		pkparms[pk_i][parm_index][2]=min(p2,p3)
		pkparms[pk_i][parm_index][3]=max(p2,p3)
	endif
	if((holdtype==3)+(holdtype==4))
		pkparms[pk_i][parm_index][2]=p2
		pkparms[pk_i][parm_index][3]=str2num(stringfromlist(p3-1,peaknumlist,";"))
	endif
	APF_FixConstraints(df)
	return 0
end

//returns list of enabled peaks by index e.g. "1;3;4;" or "NA" if no enabled peaks exist
//excludes pk_i (use pk_i=-1 to get all peaks)
//includes only peaks that have the named parameter e.g. "GW"
function/S APF_ActivePeaksList(df,pk_i,parmname)
	string df; variable pk_i
	string parmname
	wave pktypes=$df+"pkTypes"
	nvar numpks=$df+"numpks"
	string ss=""
	variable isStdParm = !(cmpstr(parmName,"soSPLIT")==0 + cmpstr(parmName,"soRATIO")==0 + cmpstr(parmName, "SHIRLEY_AMP")==0)
	wave/T psd=root:APF:peakShapeDescr
	variable i=0,imax=numpks,atot=0
	for(i=0;i<imax;i+=1)
		variable isEnabledandUniq = (pkTypes[i][%enable])*(i!=pk_i)
		variable isSameStdParm=isStdParm*(APF_PeakParmName2Index(APF_Peakname(df,i),parmName)>=0) 
		variable bothShirley = pkTypes[i][%has_shirley]*(cmpstr(parmname,"SHIRLEY_AMP")==0)
		variable bothSO = pkTypes[i][%has_so]*((cmpstr(parmname,"soSPLIT")==0) + (cmpstr(parmname,"soRATIO")==0))
		if (isEnabledandUniq*(isSameStdParm + bothShirley + bothSO))
			ss+=num2str(i)+";"
			atot+=1
		endif
	endfor
	return selectstring(atot>0,"NA",ss) //no active peaks available
end

//which can be 0 or 1
//holdtype is zero-based
function/S APF_holdTypeToDescr(holdtype,which)
	variable holdtype,which
	switch (holdtype)
		case 0: //free
			return ""
		case 1: //fixed
			return ""
		case 2: //offset to peak
			return selectstring(which,"offset","rel pk #")
		case 3: //scaled to peak
			return selectstring(which,"scale factor","rel pk #")
		case 4: //range
			return selectstring(which,"range lo","range hi")
	endswitch
end

//generic setvar control--only needs to update fit
Function APF_SetVarProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			APF_updatePF(APF_df())
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//generic checkbox control--only needs to update fit
Function APF_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			APF_updatePF(APF_df())
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function APF_BkgdListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			print "finished editing", row, col
			//value is changed by hand, reflect it by evaluating guess (no fit)
			APF_BkgdGuess(APF_df(),0)
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

//returns ;-separated list of bkgd parm names
function/S APF_bkParmsList(df)
	string df
	nvar bkType=$df+"bkType"
	wave/T bkgdDescr=root:APF:bkgdDescr
	string ss="",tt
	variable i=1, imax=dimsize(bkgdDescr,1)
	do
		ss+=bkgdDescr[i][bktype]+";"
		i+=1
	while((strlen(bkgdDescr[i][bktype])>0)*(i<imax))
	return ss
end

//returns ;-separated list of pk parm names
//for pk_i indexed to pktypes table
function/S APF_pkParmsList(df, pk_i)
	string df; variable pk_i
	wave pkTypes=$df+"pkTypes"
	wave/T psd=root:APF:peakShapeDescr
	string ss="",tt
	variable i=1,jj=pktypes[pk_i], imax=dimsize(psd,1)
	do
		ss+=psd[i][jj]+";"
		i+=1
	while((strlen(psd[i][jj])>0)*(i<imax))
	return ss
end


Function APF_PeakParmsProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave
	string df=apf_df()
	wave/T pkDisp=$df+"pkDisp"
	wave/T psd=root:APF:peakShapeDescr
	wave pkDispSel=$df+"pkDispSel"
	wave pktypes=$df+"pktypes", pkParms=$df+"pkParms"
	wave pkFit=$df+"pkFit", pkFitX=$df+"pkFitX"
	nvar numpks=$df+"numpks"
	variable cancelled=0, isEnabled, hasDepPeaks
	string pkname,parmname 
	variable parm_i
	variable nextHiLitePk=-1
	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: //mouse down
			break
		case 2: // mouse up
			//print lba.eventMod
			variable ctrl_click=(lba.eventmod & 0x10) > 0
			nvar is_imageToolV=$df+"is_imageToolV"
			nvar hist_peaksInitted=$df+"hist_peaksInitted"
			variable hasPeakHist=is_imageToolV * hist_PeaksInitted 
			if(row>=dimsize(pkdispsel,0))
				 //clicked on blank lines
				 APF_SetHilitePk(df,-1)
			else
				variable clicked_peakrow=(strsearch(pkDisp[row][0],"Peak",0)==0)
				if(clicked_peakrow)
					string pk=pkDisp[row][0]
					variable pk_i=str2num(pk[4,strlen(pk)-1])	//get number from "Peak n" label
					switch(col)
						case 0:
							//clicked on expansion triangle
							pktypes[pk_i][%expand]=1-pktypes[pk_i][%expand]
							break
						case 1:
							if (ctrl_click)
								hasDepPeaks=APF_hasDependentPeaks(df,pk_i,"")
								if(hasDepPeaks)
									doalert 0, "You cannot delete this peak because other peaks depend on it"
								else
									string warn="Are you sure you want to delete this peak?"
									warn+=selectstring(hasPeakHist, "", "\r\rIf you do so the fitting history will be erased! (Disable peak instead of deleting it to avoid this problem.)")
									doalert 1, warn
									if(v_flag==1) //YES clicked?
										deletepoints/m=0 pk_i,1,pkTypes //
										deletepoints/m=0 pk_i,1,pkParms
										numpks-=1
										redimension/n=(-1,numpks) pkFit, pkFitX
										APF_Hist_Reset(df,0)
										APF_UpdatePF(df)
									else
										cancelled=1
									endif
								endif
							else
								cancelled=APF_ChangeLineshape(df, pk_i)
								APF_SetHiLitePk(df,pk_i)
							endif						
							break
						case 2: //TOGGLE SO
							isEnabled=pktypes[pk_i][%has_so]==1
							hasDepPeaks=APF_hasDependentPeaks(df,pk_i,"SO")
							if(!isEnabled + !hasDepPeaks)
								pktypes[pk_i][%has_so]=1-pktypes[pk_i][%has_so]					
							else
								doalert 0,"You cannot disable SO splitting for this peak because other peaks depend on it."
							endif
							nextHiLitePk=pk_i
							break
						case 3: //TOGGLE SHIRLEY
							isEnabled=pktypes[pk_i][%has_shirley]==1
							hasDepPeaks=APF_hasDependentPeaks(df,pk_i,"SHIRLEY")
							if(!isEnabled + !hasDepPeaks)
								pktypes[pk_i][%has_shirley]=1-pktypes[pk_i][%has_shirley]			
							else
								doalert 0,"You cannot disable shirley for this peak because other peaks depend on it."
							endif
							nextHiLitePk=pk_i
							break
						case 4: //TOGGLE ENABLE PEAK
							isEnabled=pktypes[pk_i][%enable]==1
							hasDepPeaks=APF_hasDependentPeaks(df,pk_i,"")
							if(!isEnabled + !hasDepPeaks)
								nextHiLitePk=selectnumber(isenabled,pk_i,-1)
								pktypes[pk_i][%enable]=1-pktypes[pk_i][%enable]
							else
								doalert 0, "You cannot disable this peak, because other peaks depend on it."
							endif
							break
					endswitch
					if(!cancelled)
						APF_copyPkTypes2Disp(df,pktypes)
						APF_updatePF(df)
						APF_SetHiLitePk(df,nextHiLitePk)
					endif

				else //clicked on parameter row
					pk_i=str2num(getdimlabel(pkDisp,0,row))
					//print "parm",pk_i
					nextHiLitePk=pk_i
					switch(col)
						case 2:	//hold parameters
							pkname=APF_Peakname(df,pk_i)  //eg "Lorentzian"
							parmname=pkDisp[row][0]					//eg "POS"
							parm_i=APF_ParmDispNametoParmIndex(parmname,pkname,pkParms)
							cancelled=APF_ChangePeakHold(df,pk_i,parm_i,parmname)
							break
					endswitch
					if(!cancelled)
						APF_copyPkTypes2Disp(df,pktypes)
						APF_updatePF(df)
						APF_SetHiLitePk(df,nextHiLitePk)
						
					endif
					
				endif //clicked peakrow
			endif //row
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			//print "start edit"
			break
		case 7: // finish edit
			//print "finish edit"
			pk_i=str2num(getdimlabel(pkDisp,0,row))
			switch(col)
				case 1://editing parameters
					pkname=APF_Peakname(df,pk_i)  //eg "Lorentzian"
					parmname=pkDisp[row][0]					//eg "POS"
					parm_i=APF_ParmDispNametoParmIndex(parmname,pkname,pkParms)
					pkParms[pk_i][parm_i]=str2num(pkDisp[row][col])
					APF_updatePF(df)
					APF_copyPkTypes2Disp(df,pkTypes)	//needed in case constraints adjusted any values
					APF_SetHiLitePk(df,pk_i)
					break
			endswitch //col
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

//returns 1 if there are other peaks that depend on this peak
//mode="": all dependent parameters are checked
//mode="SO": only spin-orbit parameters are considered
//mode="SHIRLEY": only shirley parameter is considered
function APF_hasDependentPeaks(df,pk_i,mode)
	string df
	variable pk_i
	string mode
	variable i,j,found=0,t1,t2
	wave pkParms=$df+"pkParms"
	wave pkTypes=$df+"pkTypes"
	strswitch(mode)
		case "":
			for(i=0;i<dimsize(pkParms,0);i+=1)
				for(j=0;j<dimsize(pkParms,1);j+=1)
					found += pktypes[i][%enable]*((pkParms[i][j][1]==2)+(pkParms[i][j][1]==3))*(pkParms[i][j][3]==pk_i) 
				endfor
			endfor
			return found>0
		case "SO":
			for(i=0;i<dimsize(pkParms,0);i+=1)
				found += pktypes[i][%enable]*((pkParms[i][%soSplit][1]==2)+(pkParms[i][%soSplit][1]==3))*(pkParms[i][%soSplit][3]==pk_i)
				found += pktypes[i][%enable]*((pkParms[i][%soRatio][1]==2)+(pkParms[i][%soRatio][1]==3))*(pkParms[i][%soRatio][3]==pk_i)
			endfor
			return found>0
		case "SHIRLEY":
			for(i=0;i<dimsize(pkParms,0);i+=1)
				found += pktypes[i][%enable]*((pkParms[i][%shirley_amp][1]==2)+(pkParms[i][%shirley_amp][1]==3))*(pkParms[i][%shirley_amp][3]==pk_i)
			endfor
			return found>0
	endswitch
end

//converts "Lorentzian", "LW" to index (rel to 0) of "LW" in peakShapeDescr table
//returns -1 if pkname is invalid
//returns -2 if parmName is invalid
function APF_PeakParmName2Index(pkname,parmName)
	string pkname,parmName
	wave/T psd=root:APF:peakShapeDescr
	variable j=-1, jmax=dimsize(psd,1)-1, found=0
	do
		j+=1
		found = cmpstr(psd[0][j],pkname)==0
	while((!found)*(j<jmax))
	if(!found)
		return -1 //not found
	endif
	variable i=0,imax=dimsize(psd,1)
	do
		i+=1
		found = cmpstr(psd[i][j],parmName)==0
	while((!found)*(i<imax))
	if(!found)
		return -2 //not found
	endif
	return i-1
end

function APF_ParmDispNametoParmIndex(parmName,pkName,pkParms)
	string parmName,pkName;wave pkParms
	strswitch (parmName) 
		case "soSPLIT":
			return finddimlabel(pkParms,1,"soSplit")
		case "soRATIO":
			return finddimlabel(pkParms,1,"soRatio")
		case "SHIRLEY_AMP":
			return finddimlabel(pkParms,1,"shirley_amp")
	endswitch
	variable ans1=finddimlabel(pkParms,1,"parms")
	variable ans2=APF_PeakParmName2Index(pkname,parmName)
	return ans1+ans2
end 

function peak(df,pk_i,x)
	string df; 	variable pk_i,x
	wave pktypes=$dF+"pkTypes"
	wave pkParms=$df+"pkParms"
	wave/t psd=root:APF:peakShapeDescr
	string peakName=APF_Peakname(df,pk_i)
	
end

//takes only a short wave of the bk parameters
function APF_BkFitFunc(pw,yw,xw)
	wave pw,yw,xw
	yw=poly(pw,xw)
	variable i=0
end

//p0 is offset into coefficients wave 
function/d protoPeak(pw,p0,yw,xw)
	wave pw,yw,xw
	variable p0
end

function/d APF_Lorentzian(pw,p0,yw,xw)
	wave pw,yw,xw
	variable p0
	yw=abs(pw[p0+1])*(1/(1+(2*(pw[p0]-xw[p])/abs(pw[p0+2]))^2))
end

function/d APF_Gaussian(pw,p0,yw,xw)
	wave pw,yw,xw
	variable p0
	variable sigma=abs(pw[p0+2]/2.35482) 	//2*sqrt(2 *ln(2) )
	yw=abs(pw[p0+1])*exp(-((xw-pw[p0])/sigma)^2/2)
	printf""
end

function/d APF_Voigt(pw, p0, yw, xw)
	wave pw,yw,xw
	variable p0
	if(abs(pw[p0+3]/pw[p0+2]) < 1e-9)					//  (GW/LW) --> if too small, just use lorentzian
		APF_Lorentzian(pw,p0,yw,xw)
	else
		variable width=2*sqrt(ln(2))/pw[p0+3]   // √(ln 2)/(GW/2)
		variable shape=(abs(pw[p0+2])/2)*width 		//  (LW/2)*width
		yw=voigtFunc(width*(xw-pw[p0]),shape)
		variable amp=abs(voigtFunc(0,shape))
		yw*=pw[p0+1]/amp
	endif
end

function/d APF_DoniacSunjic(pw, p0, yw,xw)
	wave pw,yw,xw
	variable p0
	variable LW=abs(pw[p0+2]), ASY=pw[p0+3]
	variable lhw=lw/2
	variable aa=abs(ASY)
	yw=abs(pw[p0+1])*LHW*cos(pi*aa/2 + (1-aa)*atan(sign(ASY)*(xw-pw[p0])/LHW) )/(((xw-pw[p0]))^2+LHW^2)^((1-aa)/2)
end

function/d APF_DSGauss(pw, p0, yw,xw)
	wave pw,yw,xw
	variable p0
	variable LW=abs(pw[p0+2]), GW=abs(pw[p0+3]), ASY=pw[p0+4]
	variable lhw=lw/2
	variable aa=abs(ASY)
	yw=abs(pw[p0+1])*LHW*cos(pi*aa/2 + (1-aa)*atan(sign(ASY)*(xw-pw[p0])/LHW) )/(((xw-pw[p0]))^2+LHW^2)^((1-aa)/2)
	setscale/p x xw[0],xw[1]-xw[0],yw
	APF_DoConvolve(APF_df(),yw,gw)
end

//converts pk_i = index of peak in pkTypes wave to name of peak eg "Lorentzian"
function/S APF_Peakname(df,pk_i)
	string df; variable pk_i
	wave pktypes=$df+"pkTypes"
	wave/T psd=root:APF:PeakShapeDescr
	return psd[0][pktypes[pk_i][%type]]
end

Function APF_FixConstraints(df)
	string df
	wave pkparms=$df+"pkParms", pktypes=$df+"pktypes"
	nvar numpks=$df+"numPks"
	variable i,j,holdtype,p2,p3
	variable p0=findDimLabel(pkparms,1,"parms")
	for(i=0;i<numpks;i+=1)
		string ppl=APF_pkParmsList(df, i) //list of peak's params "LW" etc
		for(j=0;j<dimsize(pkparms,1);j+=1)
			holdtype=pkparms[i][j][1]
			p2=pkparms[i][j][2]
			p3=pkparms[i][j][3]
			if(holdtype>1)
				if(i<p0)
					//SO or Shirley: same index in src and dest pks
					variable jj=j	
				else
					//normal Peak Param: jj is index of equivalent parmeter eg "GW" in reference peak
					jj=p0+APF_PeakParmName2Index(APF_Peakname(df,p3),stringFromList(j-p0,ppl,";"))
				endif
				switch(holdtype)	//zero-based
					case 2://offset to pk
						pkparms[i][j][0]=pkparms[p3][jj][0]+p2
						break
					case 3://mult to pk
						pkparms[i][j][0]=pkparms[p3][jj][0]*p2
						break
					case 4://range
						pkparms[i][j][0]=selectnumber(pkparms[i][j][0]<p2,pkparms[i][j][0],p2)
						pkparms[i][j][0]=selectnumber(pkparms[i][j][0]>p3,pkparms[i][j][0],p3)
						break
				endswitch
			endif
		endfor
	endfor
end


Function APF_UpdatePF(df)
	string df
	wave pft=$df+"PkFitTot", pfx1=$df+"pfx1", pf=$df+"pkFit", bf=$df+"bkgdFit"
	wave pkTypes=$df+"pkTypes"
	wave fc=$df+"fitcoefs"
	APF_FixConstraints(df)
	APF_setupFit(df)
	APF_FitFunc(fc,pft,pfx1)
	APF_TweakPeaks(df)
	APF_copyPkTypes2Disp(df,pkTypes)

end

Function APF_TweakPeaks(df)
	string df
	variable i
	wave pfx1=$df+"pfx1", pfy1=$df+"pfy1", pf=$df+"pkFit", bf=$df+"bkgdFit"
	wave pktypes=$df+"pktypes"
	nvar numpks=$df+"numpks", has_GW=$df+"has_GW", gw=$df+"GW"
	for(i=0;i<numpks;i+=1)
		if(pktypes[i][%enable])
			if(has_GW)	
				pfy1=pf[p][i]
				copyscales pf,pfy1
				APF_doConvolve(df,pfy1,gw)
				pf[][i]=pfy1[p]
			endif
			pf[][i]+=bf[p]
		endif
	endfor
	pf[dimsize(pf,0)-1][]=nan  //for display to avoid showing scanback line

end

//if quiet==1 just do minimum processing i.e. no display updates
Function APF_UpdatePF_PostFit(df,quiet)
	string df; variable quiet
	nvar bkType=$df+"bkType"
	wave pkTypes=$df+"pkTypes"
	wave fc=$df+"fitcoefs"
	
	APF_FixConstraintsDuringFit(df, fc)
	APF_TweakPeaks(df)
	APF_CopyFitCoefsBack(df)
	if(!quiet)
		APF_copyBkVals2Disp(df,bkType)
		APF_copyPkTypes2Disp(df,pkTypes)
		APF_SetHiLitePk(df,-1)
	endif
end

//copies parameters from fit coefs to working waves
Function APF_CopyFitCoefsBack(df)
	string df
	wave pktypes=$df+"pkTypes", pkparms=$df+"pkParms"
	wave bkvals=$df+"bkvals"
	wave fc=$df+"fitcoefs"
	nvar has_GW=$df+"has_GW", GW=$df+"GW", has_FE=$df+"has_FE", FEe=$df+"FE_energy", FEt=$df+"FE_temp"
	nvar numpks=$df+"numpks",bfi=$df+"bk_fitcoef_i"
	//background
	bkvals=fc[p+bfi]
	//general
	if(has_GW)
		GW=selectnumber(has_GW,GW,fc[%GW0])
	endif
	if(has_FE)
		FEe=selectnumber(has_FE,FEe,fc[%FEe])
		FEt=selectnumber(has_FE,FEt,fc[%FEt])
	endif
	
	//peaks
	variable i,p0,pp0,np
	for(i=0;i<numpks;i+=1)
		if(pktypes[i][%enable])
			p0=findDimLabel(fc,0,"peak"+num2str(i)+"_POS")
			pp0=findDimLabel(pkparms,1,"parms")
			np=APF_NumParmsPkFit(pktypes[i][%type])
			pkparms[i][pp0,pp0+np-1][0]=fc[q-pp0+p0]
			if(pktypes[i][%has_so])
				pkparms[i][%soSplit][0]=fc[pktypes[i][%so_fitcoef_i]]
				pkparms[i][%soRatio][0]=fc[pktypes[i][%so_fitcoef_i]+1]
			endif
			if(pktypes[i][%has_shirley])
				pkparms[i][%shirley_amp][0]=fc[pktypes[i][%shirley_fc_i]]
			endif
		endif
	endfor
	
end

function APF_FixConstraintsDuringFit(df, fc)
	string df
	wave fc
	wave ph_type=$df+"pkFitHold_type" //0=plus, 1=times
	wave ph_pk=$df+"pkFitHold_pk"		//coefficient index that is constrained
	wave ph_ref=$df+"pkFitHold_ref"	//reference coefficient index
	wave ph_val=$df+"pkFitHold_val" 	//scale or offset factor
	variable i
	for(i=0;i<dimsize(ph_type,0);i+=1)
		switch (ph_type[i])
			case 0: //offset to other peak
				fc[ph_pk[i]]=ph_val[i]+fc[ph_ref[i]]
				break
			case 1: //scale to other peak
				fc[ph_pk[i]]=ph_val[i]*fc[ph_ref[i]]
				break
			case 2: //range NOT WORKING--interferes with igor fit routine
				//fc[ph_pk[i]]=selectnumber(fc[ph_pk[i]]<ph_val[i],fc[ph_pk[i]],ph_val[i]) //lo is stored in ph_val
				//fc[ph_pk[i]]=selectnumber(fc[ph_pk[i]]>ph_ref[i],fc[ph_pk[i]],ph_ref[i]) //hi is stored in ph_ref
				break
		endswitch
	endfor
end

Function APF_FitFunc(pw,yw,xw):FitFunc
	wave pw,yw,xw
	string df=getdimlabel(pw,0,0)
	nvar numpks=$df+"numpks"
	wave pktypes=$df+"pkTypes", pkFit=$df+"pkFit" //pkparms=$df+"pkParms", 
	wave pf=$df+"pkFit"
	wave pfc=$df+"pf_coefs1"
	wave pfx1=$df+"pfx1", pfy1=$df+"pfy1", pfy2=$df+"pfy2", pfy3=$df+"pfy3"
	wave bkgdfit=$df+"bkgdFit"
	wave pfh=$df+"pkFitHiLite", pft=$df+"pkFitTot"
	nvar has_GW=$df+"has_GW", has_FE=$df+"has_FE"
	nvar bkType=$dF+"bkType", bk_fitcoef_i=$df+"bk_fitcoef_i"
	variable i, numparms, p0
	pft=0	
	APF_FixConstraintsDuringFit(df, pw)
	if(has_FE)
		variable kb=8.61733248E-5	// (eV/K)
		pfy3=1/(exp((x-pw[%FEe])/(kb*pw[%FEt]))+1)
	endif
	for(i=0;i<numpks;i+=1)
		if(pkTypes[i][%enable])
			numparms=APF_NumParmsPkFit(pkTypes[i][%type])
			FUNCREF protoPeak f=$"APF_"+APF_peakName(df,i)
			f(pw,pktypes[i][%fitcoef_i],pfy1,pfx1)
			pf[][i]=pfy1[p]
			if(pkTypes[i][%has_so])
				redimension/n=(numparms) pfc
				p0=pktypes[i][%fitcoef_i]
				pfc[0,numparms-1]=pw[p0+p]
				p0=pktypes[i][%so_fitcoef_i]
				pfc[0]-=pw[p0]   
				pfc[1]*=pw[p0+1]
				f(pfc,0,pfy1,pfx1)
				pf[][i]+=pfy1[p]
			endif
			if(pktypes[i][%has_shirley])
				pfy2=pf[p][i]
				integrate pfy2
				pfy2*=-1
				wavestats/q pfy2
				pfy2-=v_min
				pfy2*=pw[pktypes[i][%shirley_fc_i]]/abs((v_max-v_min))
				pf[][i]+=abs(pfy2[p])
			endif
			if(has_FE)
				pf[][i]*=pfy3[p]
			endif
			pft+=pf[p][i]
			//bkgd
			//pf[][i]+=bf[p]
		else
			pf[i][]=nan //peak not enabled
		endif
		//pf[dimsize(pf,0)-1][]=nan  //for display to avoid showing scanback line
	endfor
	if(has_GW)	//general fit GW, not indiv. peaks
		APF_DoConvolve(df,pft,pw[%GW0])
	endif
	redimension/n=(APF_NumParmsBkgdFit(bktype)) pfc
	pfc=pw[p+bk_fitcoef_i]
	APF_BkFitFunc(pfc,BkgdFit,pfx1)
	pft+=BkgdFit
	yw=pft
	//wavestats/q yw
	//if(v_numNans>0)
	//	print v_numNans
	//endif
	p0=0
end

function/S APF_holdstr(df)
	string df
	wave fh=$df+"fitHold"
	variable i
	string ss=""
	for(i=0;i<dimsize(fh,0);i+=1)
		if((fh[i]==0)+(fh[i]==4))
			ss+="0" //free or range
		else
			ss+="1"
		endif//		ss+=selectstring(fh[i],"0","1")
	endfor
	return ss
end

//overwrites yw with gaussian-convolved wave.
function APF_doConvolve(df,yw,gw)
	string df
	wave yw
	variable gw
//requirements for convolution to work:
// 1) GW must be ~5 times larger than the step size of the fitwaves
//		if not, must reinterpolate fitwave to have more points
	variable d0=dimoffset(yw,0), dd0=dimdelta(yw,0), n0=dimsize(yw,0)
	variable needsInterp=(gw<5*dd0)
	if(needsInterp)
		variable n1=n0*dd0*5/gw
		make/o/n=(n1) $df+"gw_y1"; wave y1=$df+"gw_y1"
		setscale/i x d0,d0+dd0*(n0-1),y1 
		y1[]=yw(x)
	else
		duplicate/o yw $df+"gw_y1"; wave y1=$df+"gw_y1"
		n1=dimsize(y1,0)
	endif
	variable d1=dimoffset(y1,0), dd1=dimdelta(y1,0)
	variable n2=round(gw*10/dd1)	//# points for GW wave--should be wide enough to be zero at ends and ODD
	n2+=is_Even(n2)
	make/o/n=(n2) $df+"gw_y2"; wave y2=$df+"gw_y2"
	setscale/p x -dd1*(n2-1)/2,dd1,y2
	y2=sqrt(4*ln(2)/pi)/gw*exp(-((x-0)/(gw/2.35482))^2/2) 	//normalized to area = 1
	convolve/a y2 y1
	variable range=abs(dd1*n1)
	y1/=(n1-1)/range
	yw=y1(x) 	//interpolate back to orig. wave size

end

static function is_even(x)
	variable x
	return (x/2.0)==round(x/2.0)
end

function APF_SetupFit(df)
	string df
	wave bkvals=$df+"bkvals", bkDispSel=$df+"bkDispSel"
	wave pktypes=$df+"pktypes",pkparms=$df+"pkparms"
	wave fc=$df+"fitcoefs", fh=$df+"fithold"
	nvar has_fe=$df+"has_fe", FEe=$df+"FE_Energy", FEt=$df+"FE_temp",has_GW=$df+"has_GW", GW=$df+"GW"
	nvar GW_hold=$dF+"GW_hold", FEe_hold=$df+"FEe_hold", FEt_hold=$df+"FEt_hold"
	nvar numpks=$df+"numpks", bk_fitcoef_i=$df+"bk_fitcoef_i"
	svar holdstr=$df+"holdstr"
	wave ph_type=$df+"pkFitHold_type" //0=plus, 1=times
	wave ph_pk=$df+"pkFitHold_pk"		//coefficient index that is constrained
	wave ph_ref=$df+"pkFitHold_ref"	//reference coefficient index
	wave ph_val=$df+"pkFitHold_val" 	//scale or offset factor
	wave/t ph_const=$dF+"pkFitConstraints"	//range limits use built-in Igor constraints
	wave/T psd=root:APF:peakShapeDescr
	
	variable p0
	redimension/n=0 fc, fh
	//dummy field with df as dimlabel
	p0=expand(fc,1,df); fc=nan
	p0=expand(fh,1,df); fh=1
	//optional global parameters
	if(has_GW)
		p0=expand(fc,1,"GW0"); 	fc[p0]=GW
		p0=expand(fh,1,"GW0");		fh[p0]=GW_hold
	endif
	if(has_FE)
		p0=expand(fc,2,"FEe;FEt");	fc[p0]={FEe,FEt}
		p0=expand(fh,2,"FEe;FEt"); fh[p0]={FEe_hold,FEt_hold}
	endif
	//background
	p0=expand(fc,dimsize(bkvals,0),"bkgd_"+APF_BkParmsList(df)); fc[p0,]=bkvals[p-p0]
	p0=expand(fh,dimsize(bkvals,0),"bkgd_"+APF_BkParmsList(df))
	fh[p0,]=selectnumber(bkDispSel[p-p0][2] & 0x10, 0, 1)
	bk_fitcoef_i=p0
	//peaks
	variable i,numparms,pp,k, ht
	pp=finddimlabel(pkparms,1,"parms")
	for(i=0;i<numpks;i+=1)
		if(pktypes[i][%enable])
			numparms=APF_NumParmsPkFit(pktypes[i][%type])
			p0=expand(fc,numparms,"peak"+num2str(i)+"_"+APF_pkParmsList(df, i)); fc[p0,]=pkparms[i][p-p0+pp]
			p0=expand(fh,numparms,"peak"+num2str(i)+"_"+APF_pkParmsList(df, i)); fh[p0,]=(pkparms[i][p-p0+pp][1]) //ishold
			pktypes[i][%fitcoef_i]=p0
			if(pktypes[i][%has_SO])
				p0=expand(fc,2,"soSplit;soRatio;"); fc[p0]=pkparms[i][%soSplit][0]; fc[p0+1]=pkparms[i][%soRatio][0]	
				p0=expand(fh,2,	"soSplit;soRatio;"); fh[p0]=(pkparms[i][%soSplit][1]); fh[p0+1]=(pkparms[i][%soRatio][1]) //isholdx2
				pktypes[i][%so_fitcoef_i]=p0
			endif
			if(pktypes[i][%has_shirley])
				p0=expand(fc,1,"shirley_amp;"); fc[p0]=pkparms[i][%shirley_amp][0]
				p0=expand(fh,1,	"shirley_amp;"); fh[p0]=(pkparms[i][%shirley_amp][1]) //ishold
				pktypes[i][%shirley_fc_i]=p0
			endif
		endif
	endfor
	holdstr=""
	for(i=0;i<dimsize(fh,0);i+=1)
		holdstr+= num2str(fh[i]>0)
	endfor
	
	//make live-fit constraints waves
	redimension/n=0 ph_type,ph_pk,ph_ref,ph_val,ph_const
	pp=finddimlabel(pkparms,1,"parms")
	variable j, jmax=dimsize(pkParms,1), p0ref,npref
	for (i=0;i<numpks; i+=1)
		if(pktypes[i][%enable])
			for(j=0;j<jmax;j+=1)
				ht=pkparms[i][j][1]
				if((ht==2)+(ht==3)+(ht==4))
					p0=expand(ph_type,1,""); 	ph_type[p0]=ht-2//selectnumber(ht==3,0,1)
					p0=expand(ph_pk,1,"")
					p0=expand(ph_ref,1,"")
					p0=expand(ph_val,1,""); 		ph_val[p0]=pkparms[i][j][2]
					p0ref=findDimLabel(fc,0,"peak"+num2str(pkparms[i][j][3])) //index into fitcoefs of ref peak
					npref=APF_NumParmsPkFit(pktypes[i][%type])	//# parms in reference peak
					if(j<pp)
						//special parms SO or Shirley
						strswitch (GetDimLabel(pkparms,1,j))
							case "soSplit":
								ph_pk[p0]=pktypes[i][%so_fitcoef_i]
								ph_ref[p0]=pktypes[pkparms[i][%sosplit][3]][%so_fitcoef_i]
								break
							case "soRatio":
								ph_pk[p0]=pktypes[i][%so_fitcoef_i]+1
								ph_ref[p0]=pktypes[pkparms[i][%soratio][3]][%so_fitcoef_i]+1
								break
							case "shirley_amp":
								ph_pk[p0]=pktypes[i][%shirley_amp]
								ph_ref[p0]=pktypes[pkparms[i][%shirley_amp][3]][%shirley_fc_i]
								break
						endswitch
					else
						//regular fitparms GW, ASYM, etc
						ph_pk[p0]=findDimLabel(fc,0,"peak"+num2str(i)+"_POS")+j-pp
						switch(ht)
							case 2:
							case 3:
								variable ref_pk_i=pkparms[i][j][3]
								string refpkNm=APF_Peakname(df,ref_pk_i) 
								string parmname=psd[j-pp+1][pktypes[i][%type]]
								p0ref=findDimLabel(fc,0,"peak"+num2str(ref_pk_i)+"_POS")
								ph_ref[p0]=	APF_PeakParmName2Index(refpkNm,parmName)+p0ref
								//APF_PeakParmName2Index(refpkNm,parmName)+p0ref
								//findDimLabel(fc,0,"peak"+num2str(ref_pk_i)+"_POS")+j-pp
								break
							case 4:
								ph_ref[p0]=pkparms[i][j][3]	//hi value stored in ph_ref
								ph_val[p0]=pkparms[i][j][2]//lo value stored in ph_val
								variable pc0=expand(ph_const,2,"")
								string ks="K"+num2str(ph_pk[p0]), s0, s1
								sprintf s0,"%s > %f",ks,ph_val[p0]
								sprintf s1,"%s < %f",ks,ph_ref[p0]
								ph_const[pc0]={s0,s1}
								printf ""
						endswitch //ht
					endif //j<<pp
				endif	//ht==2 + ht==3
			endfor //j (parameters)
		endif  //pktype enabled
	endfor //i (peaks)
end //function APF_SetupFit() 

//hold=1, 2, 3 --> "1" in pkfit
static function ishold(i)
	variable i
	return selectnumber((i>=1) * (i<=3),0,1)
end

//expands 1D wave by n an uses ";" separated string list to dimlabel the rows
//returns start index of new rows
static function expand(w,n,dimlab)
	wave w; variable n; string dimlab
	variable n0=dimsize(w,0)
	redimension/n=(n+n0) w 
	variable i
	for(i=0;i<n;i+=1)
		setdimlabel 0,i+n0,$StringFromList(i, dimlab,";"),w
	endfor
	return n0
end
	

 Function APF_SetBkgdFcnProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			string df=APF_df()
			nvar bkType=$df+"bkType"
			bkType=popnum-1
			APF_FixBkgdListBox(df,bktype,1)
			APF_BkgdGuess(df,1)
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End




Function APF_FitButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
				string cn=ba.ctrlname
				string df=APF_df()
				wave pp=$df+"pkparms", bp=$df+"bkvals"
				svar pn=$df+"panelName"
				strswitch (cn)
					case "doFit":
						duplicate/o pp $df+"pkparms_bak"
						duplicate/o bp $df+"bkvals_bak"
						APF_doFit(df, 0)
						button doUndo, win=$pn, disable=0
					break
					case "doUndo":
						wave ppb=$df+"pkparms_bak", bpb=$df+"bkvals_bak"
						nvar bktype=$df+"bktype"
						duplicate/o ppb pp
						duplicate/o bpb bp
						APF_FixBkgdListBox(df, bktype,1)
						APF_copyBkVals2Disp(df,bkType)
						APF_UpdatePF(dF)
						APF_SetHiLitePk(df,-1)
					break
				endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//if useCopy=0, use original data wave
//if useCopy=1, use copy wave
function APF_DoFit(df, useCopy)
	variable useCopy
	string df//=APF_df()
	wave fc=$df+"fitCoefs"
	wave/T fh_const=$df+"pkFitConstraints"
	if(useCopy==0)
		svar ywn=$dF+"ywn"
		wave ywv=$ywn
	else
		wave ywv=$df+"PkFitDataCopy"
	endif
	//*D*  THIS WAS EXTRA AND MAY HAVE BEEN CAUSING CRASH WHEN OTHER PLACES WERE SET TO DP
	redimension/s ywv
	
	APF_FixConstraints(df)
	APF_SetupFit(df)
	string hs=APF_holdstr(df)
	
	Funcfit/Q/h=APF_holdstr(df) APF_FitFunc,fc,ywv/C=fh_const

	APF_UpdatePF_PostFit(df,useCopy)
end

Function APF_MultifitMenuProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			string df=APF_df()
			svar df_it=$df+"df_it"
			nvar xIndex=$df+"xIndex"
			nvar ndim=$df_it+"ndim"
			wave dnum=$df_it+"dnum", adnum=$df_it+"adnum"
			svar dname=$dF_it+"dname"
			wave data=$dname
			svar graphname=$df+"graphname"
			wave bkVals=$df+"bkVals", pkParms=$df+"pkParms"
			variable i, isAll,j=0
			string whichA="", whichAc="",  whichAnm="", temp
			variable pl, ph, p0, p1, pn,ptot
			make/o/n=(ndim-1) $df+"plow", $df+"phigh", $df+"pnum", $df+"pi0", $df+"whichAi",$df+"whichAdi"
			wave plow=$df+"plow", phigh=$df+"phigh", pnum=$df+"pnum", pi0=$df+"pi0", whichAi=$df+"whichAi", whichAdi=$df+"whichAdi"
	
			//get initial guess mode
			controlinfo GuessMode
			variable useFirstGuess=(v_value==1)	// otherwise use previous
			if(useFirstGuess)
				duplicate/o bkVals $df+"bkVals0"; wave bkVals0=$df+"bkVals0"
				duplicate/o pkParms $df+"pkParms0"; wave pkParms0=$df+"pkParms0"
			endif
			
			//get initial coordinates from cursors; define which axis index for each scan variable
			j=0
			for(i=0;i<ndim;i+=1)
				if(dnum[i]!=xIndex)
					nvar pval=$df_it+stringfromlist(i,"xp;yp;zp;tp")
					pi0[j]=round(pval)
					whichAi[j]=dnum[i]			//for each axis of IT, says which coord in raw data file
					whichAc+=stringfromlist(i,"xc;yc;zc;tc")+";"
					j+=1
				endif
			endfor
			j=0
			for(i=0;i<ndim;i+=1)
				if(i!=xindex)
					whichAdi[j]=adnum[i]  //for each dimension of data, says which column of FitPts to get coord from
					j+=1
				endif
			endfor
			APF_makeZeroToTwo(whichAdi)
			

	
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			
			nvar useAxes=$(df+"useAxes")
			isAll=1-useAxes
//			strswitch(popStr)
//				case "All Coordinates":
//				case "ROIMask (all chunks)":
//					isAll=1
//			endswitch	

			//Analyze Axes Ranges
			j=0
			for(i=0;i<ndim;i+=1)
				if(dnum[i]!=xIndex)
					whichA+=stringfromlist(i,"px;py;pz;pt")+";"	//which axes of IT are to be varied
					temp=stringfromlist(i,"bottom;left;profZB;profTB")
					whichAnm+=temp+";"	
					getaxis/Q/W=$graphname $temp
					p0=scaletoindex(data,v_min,dnum[i])
					p1=scaletoindex(data,v_max,dnum[i])
					pl=min(p0,p1); ph=max(p0,p1)
					pl=selectnumber(isall+(pl<0),pl,0)
					ph=selectnumber(isall+(ph>=dimsize(data,dnum[i])),ph,dimsize(data,dnum[i])-1)
					plow[j]=pl
					phigh[j]=ph
					pn=ph-pl+1
					pnum[j]=pn
					ptot=selectnumber(i>0,pn,ptot*pn)
					j+=1
				endif
			endfor
			
			//Setup Fit Points for Different Modes
			strswitch(popStr)
				case "Rectilinear Bounds":
				//case "Within Axis Ranges":
				//make a list of points that should be fitted
				string cmd="make/o/n=(", wvlist=""
				j=0
				for(i=0; i<ndim; i+=1)
					if(dnum[i]!=xIndex)
						cmd+=num2str(pnum[j])+selectstring(j<(ndim-2), "","*")
						//wvlist+=" fitPts_"+num2str(j)+","   //selectstring(j<(ndim-2),"",",")
						j+=1
					endif
				endfor
				string cmd2=cmd + ","+num2str(ndim-1)+") "+ df+"fitPts" //(n,d) where d=dimensionality of DOF space= ndim-1
				execute cmd2
				//cmd2=cmd+")" + df+"fitPts_r"	//add wave for sorting distance to start point
				//execute cmd2
				wave fitPts=$df+"fitPts"
				variable pfact=1
				for(j=0;j<ndim-1;j+=1)
					print pfact, pnum[j]
					fitpts[][j]=plow[j] + mod(floor(p/pfact),pnum[j])
					pfact*=pnum[j]
				endfor

				break
				case "ROI Mask (this chunk)":
				case "ROI Mask (multiple chunks)":
					string rwvn=df_it+"ProcessROIMask"
					wave rwv=$rwvn
					if(ndim<3)
						abort "wave does not have enough dimensions for this mode"
					endif
					if(adnum[xIndex]<=1)
						abort "the x-axis chosen for fitting must be along Z or T directions for this mode"
					endif
					if(exists(rwvn)!=1)
						abort "no mask defined. create mask using process>drawROI"
					endif
					wavestats/q rwv
					if(v_avg==0)
						abort "mask is empty. create mask using process>drawROI"
					endif
					variable nps=makeMaskPQlist(df_it,rwv)
					wave pmP=$df_it+"processMaskP", pmQ=$df_it+"processMaskQ"
					make/o/n=(dimsize(pmp,0),2) $df+"fitpts"
					wave fitpts=$df+"fitpts"
					fitpts[][0]=pmp[p]
					fitpts[][1]=pmq[p]
					if(ndim==4)
						redimension/n=(-1,3) fitpts
						fitpts[][2]=pi0[2]					//hardwired to fit in one chunk only
					endif
					
					if(strsearch(popstr,"chunks",0)>=0)
						//ROI Mask fitting, more than one chunk
						variable npc=dimsize(fitpts,0) 	//number of points in mask (single chunk)
						redimension/n=(npc*pnum[2],-1) fitpts
						fitpts[][0]=pmp[mod(p,npc)]
						fitpts[][1]=pmq[mod(p,npc)]
						fitpts[][2]=plow[2]+mod(floor(p/npc),pnum[2])
					endif

					if(1)
						//delete all chunks outside of XY image range
						duplicate/o fitpts $df+"fitpts2"
						wave fitpts2=$df+"fitpts2"
						fitpts2=nan
						variable xinrange,yinrange
						j=0
						for(i=0;i<dimsize(fitpts,0);i+=1)
							xinrange=(fitpts[i][0]>=plow[0])*(fitpts[i][0]<=phigh[0])
							yinrange=(fitpts[i][1]>=plow[1])*(fitpts[i][1]<=phigh[1])
							if(xinrange&&yinrange)
								fitpts2[j][]=fitpts[i][q]
								j+=1
							endif
						endfor
						redimension/n=(j,-1) fitpts2
						duplicate/o fitpts2 fitpts
					endif
			endswitch

			//sort data points to correct fit order	
			make/o/n=(dimsize(fitpts,0)) $df+"fitpts_r"
			wave fitPts_r=$df+"fitPts_r"
			nvar overwrite=$df+"overwrite"
			fitpts_r=0
			for(j=0;j<ndim-1;j+=1)
				fitpts_r+=(fitpts[p][j]-pi0[j])^2
			endfor
			if(ndim>=3)
				make/o/n=(dimsize(fitpts,0)) $df+"fitpts_phi"
				wave fitPts_phi=$df+"fitPts_phi"
				fitpts_phi=atan2(fitpts[p][1]-pi0[1], fitpts[p][0]-pi0[0])
				sortcolumns keywaves={fitpts_r,fitpts_phi} sortwaves={fitpts, fitpts_r, fitpts_phi}
			else
				sortcolumns keywaves=fitpts_r, sortwaves={fitpts, fitpts_r}
			endif
			
			
			//do fits
			openProgressWindow("Fitting...",numpnts(fitpts_r),0)
			variable ni=numpnts(fitpts_r), nj=dimsize(fitpts,1)
			wave pfdc=$df+"PkFitDataCopy"
			string his, ss
			svar ywn=$df+"ywn"
			nvar animate=$df+"animate"
			wave axis=$ywn+"_axis"
			wave bin=$df_it+"bin"			
			variable t0=datetime
			wave fcs=$df+"FitCoordStore"
			redimension/n=(ndim-1) fcs
			for(i=0;i<ni;i+=1)
				updateprogresswindow(i)
				if(useFirstGuess)
					bkVals=bkVals0
					pkparms=pkParms0
				endif
				if(animate)
					for(j=0;j<nj;j+=1)
						nvar cc=$df_it+stringfromlist(j,whichAc)
						cc=dimoffset(data,whichAi[j])+fitpts[i][j]*dimdelta(data,whichAi[j])
					endfor
					doupdate
				else
					fcs=fitpts[i][whichAdi[p]]
					switch(ndim-1)
						case 1:
							extractbeambin(pfdc,data,axis,bin,fitpts[i][whichAdi[0]],0,0)
							break
						case 2:
							extractbeambin(pfdc,data,axis,bin,fitpts[i][whichAdi[0]],fitpts[i][whichAdi[1]],0)
							break
						case 3:	
							extractbeambin(pfdc,data,axis,bin,fitpts[i][whichAdi[0]],fitpts[i][whichAdi[1]],fitpts[i][whichAdi[2]])
							break
					endswitch														
				endif	
				if(overwrite)								
					APF_dofit(df, !animate)
					APF_Hist_StoreFit(df, animate)
				elseif(APF_Hist_RetrieveVal(df, df_it,"constants","fitted", animate)==0)
					APF_dofit(df, !animate)
					APF_Hist_StoreFit(df, animate)
				endif
				doupdate
		//doalert 0,"test"

			endfor
			closeProgressWindow()
			print datetime-t0 , " seconds"
			pfdc=nan
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//takes wave with 3 uniaue values (@<=3) e.g. 3, 1, 0 and makes it 2, 1, 0
//3, 2, 1 --> 2,1,0
function APF_makeZeroToTwo(w)
	wave w
	variable b, ndim=numpnts(w)
	b=APF_DoesWaveHaveVal(w,0)
	if(b<0)
		w[APF_DoesWaveHaveVal(w,1)]=0
	endif
	b=APF_DoesWaveHaveVal(w,1)
	if((b<0)*(ndim>=2))
		w[APF_DoesWaveHaveVal(w,2)]=1
	endif
	b=APF_DoesWaveHaveVal(w,2)
	if((b<0)*(ndim==3))
		w[APF_DoesWaveHaveVal(w,3)]=2
	endif
	
	
end

//does linear search for val.
//returns index if found otherwise -1
function APF_DoesWaveHaveVal(w,val)
	wave w
	variable val
	variable i=0
	do
		if(w[i]==val)
			return i
		endif
		i+=1
	while(i<numpnts(w))
	return -1
end