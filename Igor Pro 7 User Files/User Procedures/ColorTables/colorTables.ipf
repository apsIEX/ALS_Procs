#pragma rtGlobals=1		// Use modern global access method.

menu "Plot"
	submenu "images"
		"loadCT"
		"loadCT-interactive"
		"-"
		"BytScl2"
		"ct_Gamma"
	end
end

//------------------- begin TOP LEVEL ----------------------
proc loadCT(ctn)
	variable ctn
	prompt ctn, "New ColorTable", popup ColorNamesList()
	silent 1;pauseupdate
	//ctn-=1
	string fname=num2str(ctn)+"."+root:colors:colorTableNames[ctn]
	if (ctn<=9)
		fname="0"+fname
	endif
	string df=getdatafolder(1)
	setdatafolder root:colors
	loadwave/t/o/q/p=colorTablePath fname
	setdatafolder $df
	//print fname," --> ct wave"
	root:colors:currCTname=num2str(ctn)+". "+root:colors:colorTableNames[ctn]
	root:colors:currCT=ctn
end

//like loadCT, except choosing from menu we need to offset by 1
proc loadCTmenu(ctn)
	variable ctn
	prompt ctn, "New ColorTable", popup ColorNamesList()
	silent 1;pauseupdate
	ctn-=1
	string fname=num2str(ctn)+"."+root:colors:colorTableNames[ctn]
	if (ctn<=9)
		fname="0"+fname
	endif
	string df=getdatafolder(1)
	setdatafolder root:colors
	loadwave/t/o/q/p=colorTablePath fname
	setdatafolder $df
	print fname," --> ct wave"
	root:colors:currCTname=num2str(ctn)+". "+root:colors:colorTableNames[ctn]
	root:colors:currCT=ctn
end


proc loadCTinteractive()
	silent 1;pauseupdate
	string wl=winlist("loadct_","","")
	if (strlen(wl))
		dowindow/f loadct_
	else
		loadct_()
	endif
end

proc bytscl2(wv, dest)
	string wv;variable dest
	prompt wv,"Wave to convert to 0-255", popup, wavelist("*",";","win:")
	prompt dest,"Destination",popup "new;overwrite"
	silent 1;pauseupdate
	wavestats/q $wv
	if (dest==1)
		duplicate/o $wv $wv+"_b"
		wv+="_b"
	endif
	$wv-=v_min
	$wv*=255/(v_max-v_min)
	print "byte-scaled data stored in "+wv
end

proc ct_gamma(gam)	
	variable gam
	silent 1;pauseupdate
	duplicate/o root:colors:ct root:colors:temp_ct
	make/n=256/o root:colors:sss	
	root:colors:sss =round(256*((p/256)^gam))
	root:colors:temp_ct[][0]=root:colors:ct[root:colors:sss[p]][0]
	root:colors:temp_ct[][1]=root:colors:ct[root:colors:sss[p]][1]
	root:colors:temp_ct[][2]=root:colors:ct[root:colors:sss[p]][2]
	root:colors:ct=temp_ct
	//killwaves root:colors:sss,root:colors:temp_ct
	end
end


//----------------------- begin LOW LEVEL --------------------------

//make sure to have the following line at the beginning (otherwise won't initialize the 1st time)
//string dummy=colorNamesList()
Window loadct_() : Graph
	PauseUpdate; Silent 1		// building window...
	string dummy=colorNamesList()
	Display /W=(362,48,629,132) as "LoadCT_"
	AppendImage root:colors:w_loadct
	ModifyImage w_loadct cindex= root:colors:ct
	ModifyGraph margin(bottom)=50,width=216,height=22,wbRGB=(32768,54615,65535)
	ModifyGraph nticks(left)=0
	ModifyGraph font(bottom)="Geneva"
	ModifyGraph fSize(bottom)=9
	ModifyGraph axOffset(left)=-2.14286
	Textbox/N=text0/F=0/Z=1/G=(1,12815,52428)/B=1/A=MC/X=-0.83/Y=81.82 "\\f01\\{root:colors:currCTname}"
	PopupMenu ChooseCT,pos={24,60},size={110,19},proc=loadCTpopupMenu,title="Choose Table"
	PopupMenu ChooseCT,mode=0,value= #"root:colors:s_colorNL"
	Button gamma,pos={144,60},size={75,20},proc=popupGammaButton,title="Gamma…"
EndMacro

//does the initialization stuff which can't be done in function colorNamesList()
proc ColorNameL()
	silent 1;pauseupdate
	pathinfo igor
	string df=getdatafolder(1)
	newdatafolder/o root:colors
	setdatafolder root:colors
	// First try user files folder
	NewPath/q/z/o ColorTablePath specialDirPath("Igor Pro User Files",0,0,0)+"User Procedures:ColorTables:Names & Tables"
	if(V_flag!=0)        // If no color tables in user folder
		pathinfo Igor	// try igor procedures folder
		NewPath/q/o ColorTablePath s_path+"User Procedures:ColorTables:Names & Tables"
	endif
	loadwave/q/o/t/p=ColorTablePath "colorTableNames.awav"		
	string/g s_colorNL
	string ans
	variable nc=numpnts(colorTableNames)
	iterate(nc)
		ans+=num2str(i)+". "+colorTableNames[i]+";"
	loop
	s_colorNL=ans
	make/o/n=(255,20) w_loadct
	w_loadct=p
	//load an initial color table
	loadwave/t/o/q/p=colorTablePath "03."+colorTableNames[3]
	string/g currCTname="3. "+colorTableNames[3]
	variable/g currCT=3
	
	make/o/n=(256,3,nc) all_ct
	setdatafolder root:colors
	string fname
	iterate(nc)
		fname=num2str(i)+"."+root:colors:colorTableNames[i]
		if (i<=9)
			fname="0"+fname
		endif
		loadwave/t/q/o/p=colorTablePath fname
		all_ct[][][i]=ct[p][q]	
	loop
	setdatafolder $df
	
end

//create path to colors if it doesn't exist
function/s ColorNamesList()
	pathinfo ColorTablePath
	if ((v_flag==0)+(strsearch(s_path,"names & tables",0)==(-1)))
		execute "colorNameL()"
	endif
	svar sc=root:colors:s_colorNL
	return sc
end

Function loadCTpopupMenu(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	execute "loadct(" +   num2str(popnum-1)    +    ")"
End
Function popupGammaButton(ctrlName) : ButtonControl
	String ctrlName
	execute "ct_gamma()"
End
