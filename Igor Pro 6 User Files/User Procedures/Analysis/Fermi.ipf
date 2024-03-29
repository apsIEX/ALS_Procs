//File:  FEdge			created: 6/97 J. Denlinger
// goal: simple flexible FE fitter, nothing fancy
//  9/11/00  JDD  added  display Fit option
//  --- not Y vs X compliant

#pragma rtGlobals=1		// Use modern global access method.

Menu "Macros"
	"Fit Edge/�"
End

Macro FitEdge(ywn, rang, fcn, anno, output, dopt )  //, fopt)
//------------------------
	string ywn=WaveName("",0,1)
	variable rang=NumVarOrDefault("root:FE:range",2)
	variable fcn=NumVarOrDefault("root:FE:ifcn",2)
	variable anno=NumVarOrDefault("root:FE:annotate",2)
	variable output=NumVarOrDefault("root:FE:output",2)
	variable dopt=NumVarOrDefault("root:FE:dispopt",2)
	prompt ywn, "Data wave", popup, "All;"+CsrWave(A)+";-;"+WaveList("!*_x",";","WIN:")
	prompt rang, "Range", popup, "Entire Wave;Between Cursors"
	prompt fcn, "Function", popup, "FEfct;Gstep;EdgeStats"
	prompt anno, "Add FitInfo Textbox", popup,"None;Append to;Dynamic Update"
	prompt output,"Output:",popup,"History only;Graph Legend;History&Graph;Table"
	prompt dopt, "Display fit", popup,"Yes;No"
	
	//PauseUpdate; 
	Silent 1
	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:FE
		variable/G range=rang, ifcn=fcn, annotate=anno, dispopt=dopt
		make/o/T root:FE:FEparms={"pos","width","ampl", "slope","offset"}
		make/o/N=5 root:FE:FEcoef
		string/G fitw
	SetDataFolder $curr
	
	variable fitall=SelectNumber( stringmatch(ywn,"All"), 0, 1 )
	variable numwaves=SelectNumber( fitall, 1, ItemsInList( WaveList("*",";","WIN:")))
	
	string wnam=WinName(0,1)
	//print wnam
	DoWindow/F FE_table
	if (V_Flag==0)
		FE_table()
	endif
	
	if (output==4)
		make/o/T/n=(numwaves) FEnames
		make/o/n=(numwaves) FEposns, FEwidths, FE_Teff
	endif
	variable/G kB=0.086   //meV/K
	
	string xwn, fracstr, txtstr, cmd, fcnstr, fitw
	variable slope, offset
	variable posn, ampl, wid, Teff
	variable ii=0, st, en, x0, x1
	variable frac=0.15, idx
	DO
		if (fitall)
			ywn=WaveName("",ii,1)
		endif
		//print ywn, strsearch(ywn,"FEfit",0), strlen(ywn)
		IF (strsearch(ywn,"FEfit",0)==0)	//+strlen(ywn)==0)
			//print ywn	//skip over wave
		ELSE
		if (strlen(ywn)==0)
			break
		endif
		root:FE:fitw=ywn
		xwn=XWaveName("", ywn)

		if (rang==2)
			st=hcsr(A); en=hcsr(B)
		endif
		if (rang==1)
			if (exists(xwn)==0)
				st=leftx($ywn); en=rightx($ywn)
			else
				st=$xwn[0]; en=$xwn[numpnts($xwn)-1]
			endif
		endif
		//print st, en

		fracstr="("+num2str(frac*100)+"/"+num2str((1-frac)*100)+"%)"
		EdgeStats/Q/F=(frac)/R=(st,en) $ywn
		print ywn+": Center=", round(1E3*V_edgeLoc2)/1E3, " Width=", round(1E3*V_edgeDloc3_1)/1E3, fracstr
		slope=(V_edgeLvl1-V_edgeLvl0)/(V_edgeLoc1-st)
		offset=min(V_edgeLvl0, V_edgeLvl4)
		//root:FE:FEcoef={root:V_edgeLoc2, abs(root:V_edgeDloc3_1),root:V_EdgeAmp4_0, slope,offset}
		root:FE:FEcoef={V_edgeLoc2, abs(V_edgeDloc3_1),abs(V_EdgeAmp4_0), slope,offset}
		//root:FE:FEcoef={V_edgeLoc2, abs(V_edgeDloc3_1),abs(V_EdgeAmp4_0), 0,offset}

		//Cursor A, $ywn, V_edgeLoc1
		//Cursor B, $ywn, V_edgeLoc3
		x0=min(st,en); x1=max(st,en)
		duplicate/o $ywn FEfit
		//make/o/n=100 FEfit
		//Setscale/I x x0,x1,"" FEfit
		FEfit=nan
		DoWindow/F $wnam
		CheckDisplayed FEfit
		if (V_Flag==0)
			append FEfit
			ModifyGraph lsize(FEfit)=1.5,rgb(FEfit)=(65535,65535,0)
		endif
	
		if (fcn==3)			//show edgestats only (initial guess)
			//FEfit=FEfct(root:FE:FEcoef, x)
			FEfit=Gstep(root:FE:FEcoef, x)
		else
			fcnstr="FEfct;Gstep"[(fcn-1)*6,(fcn-1)*6+4]
			cmd="FuncFit/Q/N "+fcnstr+" root:FE:FEcoef "+ywn
			cmd+="("+num2str(x0)+","+num2str(x1)+")"
			if (exists(xwn)!=0)
				cmd+=" /X="+xwn
			endif
			cmd+=" /D=FEfit"
			//print cmd
			execute cmd
			//FEfit=FEfct(root:FE:FEcoef, x)
		endif
		root:FE:FEcoef=round(1E4*root:FE:FEcoef)/1E4
		posn=root:FE:FEcoef[0]
		wid=root:FE:FEcoef[1]*SelectNumber( fcn==1,  1, 4)	// Gwidth�4*kB*T
		ampl=root:FE:FEcoef[2]
		Teff=(wid*1000/kB)/4  	
		
		if (fcn==1)
			print "FE_Fit: Pos=", posn,  ", ampl=", ampl, ", 4kT=", wid, ", Teff=", Teff
		else
			print "FE_Fit: Pos=", posn,  ", ampl=", ampl, ", width=", wid, ", Teff=", Teff
		endif

		if (output==4)
			FEnames[ii]=ywn
			FEposns[ii]=posn
			FEwidths[ii]=wid*1000		// meV
			FE_Teff[ii]=Teff
		endif
		string/G root:FE:FitInfoStr
		if (anno>1)
			if (strsearch(AnnotationList(""),"fitinfo",0)==-1)			//live update
				//root:FE:fitinfostr="FE fit:    pos  width"
				Textbox/N=fitinfo/F=0/A=MC "FE fit:    posn  "+SelectString(fcn==1, "width", "4kT")+"(meV)"
				if (anno==3)
					//root:FE:fitinfostr+="\{root:FE:fitw}  FE=\{root:FE:FEcoef[0]}  WID=\{root:FE:FEcoef[1]}"
					//Textbox/C/N=fitinfo root:FE:fitinfostr
					AppendText/N=fitinfo "\{root:FE:fitw}  FE=\{root:FE:FEcoef[0]}  WID=\{root:FE:FEcoef[1]}"
				endif
			endif
			if (anno==2)			// append infobox
				//root:FE:fitinfostr+="\r"+ywn+" \t"+num2str(root:FE:FEcoef[0])+" \t"+num2str(root:FE:FEcoef[1])
				AppendText/N=fitinfo  ywn+"  "+num2str(posn)+"  "+num2str(wid)
			endif
			//Textbox/C/N=fitinfo root:FE:fitinfostr
		endif
		if (dopt==1)
			fitw=ywn+"fit"
			duplicate/O FEfit  $fitw
			append $fitw
		endif
		ENDIF
		//ResumeUpdate;PauseUpdate
		ii+=1
	WHILE (ii<numwaves)
	RemoveFromGraph FEfit
	if (output==4)
		//redimension/n=(ii) FEnames, FEposns, FEwidths, FE_Teff
		Edit FEnames, FEposns, FEwidths, FE_Teff
	endif
End

macro addinfo()
	string txtstr, cmd
	variable index
	if (strsearch(AnnotationList(""),"text0",0)==-1)
		txtstr="First Line"
		Textbox/N=text0/F=0/A=MC txtstr
	else
		txtstr=AnnotationInfo("","text0")
		index=strsearch(txtstr,"TEXT",0)
		txtstr=txtstr[index+5,strlen(txtstr)-1]
		txtstr+="\rnewline"
		print txtstr
		Textbox/K/N=text0
		Textbox/N=text0/F=0/A=MC txtstr
		//ReplaceText/N=text0 txtstr    
		//This fails on the multiple passes because each \r (except the last one) gets converted to \\r
	endif
end

macro addinfo2()
	string txtstr, cmd
	variable index
	if (strsearch(AnnotationList(""),"text0",0)==-1)
		txtstr="First Line"
		Textbox/N=text0/F=0/A=MC txtstr
	else
		//txtstr=AnnotationInfo("","text0")
		//index=strsearch(txtstr,"TEXT",0)
		//txtstr=txtstr[index+5,strlen(txtstr)-1]
		txtstr="newline"
		AppendText/N=text0 txtstr
		//print txtstr
		//cmd="ReplaceText/N=text0 \""+ txtstr+"\""
		//print cmd
		//execute cmd			
		//This gives an error for missing terminating quote because of the last \r
	endif
end

function Gstep0(GW,POS, xx)
	variable GW,POS, xx
	variable dx=xx-POS
	return( 0.5*erfc(dx/(GW/1.66511)) )	///2)) )
end

function Gstep(coef, xx)
	wave coef
	variable xx
	variable dx=xx-coef[0], GW=coef[1]
	return(coef[4]+coef[3]*min(dx,0)+coef[2]*0.5*erfc(dx/(GW/1.66511)) )
end

function FEdge(WID, dx)
	variable WID, dx
	return( 1/(exp(dx/WID)+1) )
end

function FEfct0(coef, xx)
	wave coef
	variable xx
	variable dx=xx-coef[2], WID=coef[1]
	return( coef[0]/(exp(dx/WID)+1) ) 
end

function FEfct(coef, xx)
	wave coef
	variable xx
	variable dx=xx-coef[0], WID=coef[1]
	variable lin=coef[2]+coef[3]*dx, offs=coef[4]
	return( offs+lin*FEdge(WID,dx) ) 
end

function Temp( Teff, dE )
	variable Teff, dE
	variable kB=0.086		//meV/K
	variable tmp=(kB*Teff)^2 - (dE/4)^2
	return sqrt(tmp)/kB
end



Window FE_Table() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(317,61,578,306) root:FE:FEparms,root:FE:FEcoef
	ModifyTable width(Point)=20,width(root:FE:FEparms)=68,alignment=1
EndMacro