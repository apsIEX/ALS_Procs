//File: CT_Control	 
// Jonathan Denlinger, JDDenlinger@lbl.gov
// 1/27/10 moved & updated from image_util
// 2/2/10 include AB modified Gamma mapping

#pragma rtGlobals=1		// Use modern global access method.
#include "ColorTables"

Function/S CTselect(img, CTnum, gama, invert)
// =============
// better scriptable  CT selection function; Usage:
// CT_select(im, 41, -1, -1)	-- select CT, leave gamma & invert the same as in note
// CT_select(im, -1, 2.1, -1)	-- adjust gamma, leave CT and inver the same
// CT_select(im, -1,-1, 0)	-- set no CT inversion
// CT_select(im, -1,-1, 1)	-- set inverted CT
// CT_select(im, -1,-1, 2)	-- toggle CT invert from current value
// CT_select(im, 3,0.5, 0)	-- set all three settings at once
//"img" is only use to determine  *_CT array, so optionally allow 
//  direct specification of img_CT (without knowledge of img)
// CT_select(im_CT, 3,0.5, 0)	-- set all three settings at once
	WAVE img
	variable  CTnum, gama, invert
	
	variable debug=1, method=2
	if (debug)
		WAVE pmap=$("root:WinGlobals:"+WinName(0,1)+":pmap")
		WAVE CT=$("root:WinGlobals:"+WinName(0,1)+":CT")
	endif
	
	
//check if colors folder exists yet; if not load CTs	
	IF (DataFolderExists("root:colors")==0)
		execute "colorNameL()"			//can't call procedure from function, so execute
//		ColorNamesList()		// will give error if variable root:colors:s_colorNL does not already exist
//								// only checks if ColorPath exists
	ENDIF
	
// determine CT array name
	string imgCTwnam = NameOfWave( img)+"_CT"	
	if (stringmatch( NameOfWave(img), "*_CT") )
		imgCTwnam = NameOfWave( img)		// is already a CT name
	endif
//	print NameOfWave( img), imgCTwnam
// read current CT settings from CT wave note	
	string curr_CTnam
	variable curr_CTnum, curr_gama, curr_invert
	if (exists(imgCTwnam))
		//abort "ColorTable ("+imCTwn+") already exists!"
		WAVE imgCTw=$imgCTwnam
		string imgCTlst = CTreadNote( imgCTw )
		curr_CTnam=StringByKey("name", imgCTlst, "=", "," )
   		curr_gama=NumberByKey("gamma", imgCTlst, "=", "," )
   		curr_invert=NumberByKey("invert", imgCTlst, "=", "," )	
   		curr_CTnum=WhichListItem( curr_CTnam, ColorNamesList(),";",0 )
   		if (curr_CTnum==-1)
   			curr_CTnum=WhichListItem( curr_CTnam, CTnamelist(2),";",0 )
   		endif
		curr_CTnum=Selectnumber( curr_CTnum==-1, curr_CTnum, 0)	
	else
		abort 		//	//ask if want to create CT -> CTmake( img, opt )
	endif
	
// determine new CT settings
	string CTnam
	CTnum = SelectNumber( CTnum==-1, CTnum, curr_CTnum)
	CTnam=StringFromList( CTnum, ColorNamesList())
//	CTnam=StringFromList( CTnum, CTnameList(2))
	gama = SelectNumber( gama==-1, gama, curr_gama)
	invert = SelectNumber( invert==-1, invert, curr_invert)
	invert = SelectNumber( invert==2, invert, 1-curr_invert)		//toggle current setting	
// Evaluate CT array; do without intermediate pmap array or dependencies
	WAVE all_ct=root:colors:all_ct
//	pmap=255*(p/255)^gama
//	 imgCTw=all_ct[pmap[CTinvert*(255-p)+(CTinvert==0)*p]][q][CTnum]

	IF (method==1)
	// invert direction of point index mapping	
	 if (invert)
	 	imgCTw=all_ct[ 255*((255-p)/255)^gama ][q][CTnum]
	 else
	 	imgCTw=all_ct[ 255*(p/255)^gama ][q][CTnum]
	 endif
	 
	 if (debug)
		 if (invert)
		 	pmap= 255*((255-p)/255)^gama
		 	CT= all_ct[pmap[255-p]][q][CTnum]
		 else
		 	pmap= 255*(p/255)^gama 
		 	CT= all_ct[pmap[p]][q][CTnum]
		 endif
	 endif

	ELSE	 
	 // use 1/gamma for inverted colortable; use AB ImageTool5 forumula
//	  setformula $(df+"pmap") , "("+df+"gamma>=1)*255*(p/255)^(abs("+df+"gamma)) + ("+df+"gamma<1)*255*(1-((255-p)/255)^(1/"+df+"gamma))"
//  	  setformula $(df+"ct"), "root:colors:all_ct[invertct*(255-pmap[p])+(invertct==0)*pmap[p]][q][whichCT]"	
 	 if (invert)
 	 	if (gama>=1)
	 		imgCTw=all_ct[ 255 - 255*(p/255)^gama ][q][CTnum]
	 	else		//gamma<1
	 		imgCTw=all_ct[ 255 - 255*(1-((255-p)/255)^(1/gama)) ][q][CTnum]
//	 		imgCTw=all_ct[ ((255-p)/255)^(1/gama) ][q][CTnum]
	 	endif
	 else
	 	if (gama>=1)
	 		imgCTw=all_ct[ 255*(p/255)^gama ][q][CTnum]
	 	else		//gamma<1
	 		imgCTw=all_ct[ 255*(1-((255-p)/255)^(1/gama)) ][q][CTnum]
	 	endif
	 endif
	 
	 if (debug)
		 if (invert)
	 	 	if (gama>=1)
		 		pmap = 255 - 255*(p/255)^gama 
		 	else		//gamma<1
//		 		pmap =  255 - 255*(1-((255-p)/255)^(1/gama)) 
		 		pmap =  ((255-p)/255)^(1/gama)   
		 	endif
		 	CT= all_ct[pmap[255-p]][q][CTnum]
		 else
		 	if (gama>=1)
		 		pmap = 255*(p/255)^gama 
		 	else		//gamma<1
		 		pmap =  255*(1-((255-p)/255)^(1/gama)) 
		 	endif
		 	CT= all_ct[pmap[p]][q][CTnum]
		 endif
	 endif
	 ENDIF

//Update CT wavenote	
	 CTwriteNote(imgCTw, CTnam, gama, invert)		

	return "CTselect("+NameOfWave(img)+","+num2str(CTnum)+","+num2str(gama)+","+num2str(invert)+")"
End 

Function CTselectPop(ctrlName,popNum,popStr) : PopupMenuControl
//==================
	String ctrlName
	Variable popNum
	String popStr
		
	string winnam=WinName(0,1)
	SVAR imCTwnam=$("root:WinGlobals:"+winnam+":imCTwnam")
	SVAR CTname=$("root:WinGlobals:"+winnam+":CTname")
	NVAR CTnum=$("root:WinGlobals:"+winnam+":CTnum")
	CTnum=popNum-1		
//	CTname=StringFromList( CTnum, CTnameList(2))
	CTname=StringFromList( CTnum, ColorNamesList())
	CTselect($imCTwnam, CTnum, -1, -1)

	return CTnum	
End


Function CTadjGamma(ctrlName,sliderValue,event) : SliderControl
//==============
// 1/25/10 change slider input value from Gamma to log(Gamma)
	String ctrlName
	Variable sliderValue
	Variable event	// bit field: bit 0: value set, 1: mouse down, 2: mouse up, 3: mouse moved

//	string winnam=WinName(0,1)
//	SVAR imCTwnam=$("root:WinGlobals:"+winnam+":imCTwnam")
	string imgn=StringFromList(0,ImageNameList("",";"))		//first image in graph window
	string imCTwn=StringByKey( "cindex", colorTableStr("",imgn), "=", "," )
	imCTwn=imCTwn[1,99]		//strip initial space
//	NVAR gama=$("root:WinGlobals:"+winnam+":CTgama")		//global not needed; wavenote used
	variable gama
	gama=round( 20*10^sliderValue)/20		//slider is log value of gamma	
	execute "ValDisplay GammaVal value="+num2str(gama)
	CTselect($imCTwn, -1, gama, -1)

	return gama
End

Function CTinvertCheck(ctrlName,checked) : CheckBoxControl
//=================
	String ctrlName
	Variable checked
	
//	string winnam=WinName(0,1)
//	SVAR imCTwn=$("root:WinGlobals:"+winnam+":imCTwnam")
	string imgn=StringFromList(0,ImageNameList("",";"))
	string imCTwn=StringByKey( "cindex", colorTableStr("",imgn), "=", "," )
	imCTwn=imCTwn[1,99]		//strip initial space
	
//	NVAR invert=$("root:WinGlobals:"+winnam+":CTinvert")		//global not needed; wavenote used
	variable invert
	invert=checked		//necessary? since stored in wave note
//	print imgn, imCTwn, invert
	CTselect($imCTwn, -1, -1, invert)
//	CTselect($imgn, -1, -1, invert)

	return invert
End

Function CTrescale(ctrlName,checked) : CheckBoxControl
//=================
// invert taken care of by p-mapping; not by min/max scaling of CT array
	String ctrlName
	Variable checked

//Determine img and CT waves
	WAVE imgw=$StringFromList(0,ImageNameList("",";")	)   //top graph, top image
	SVAR imCTwnam=$("root:WinGlobals:"+WinName(0,1)+":imCTwnam")
	WAVE imCTw=$imCTwnam

// determine marquee (ROI) min/max
	GetMarquee/K left, bottom
	If (V_Flag==1)
		//pixel ordering of p(V_left)<p(V_right) required for ImageStats so must convert to pixels
		//   since marquee left/right dependent on sign of axis delta AND axis reverse checkbox
			//ImageStats/M=1/GS={V_left,V_right,V_bottom,V_top} imgw
			//print V_left,V_right,V_bottom,V_top, V_min, V_max
		variable p1, p2, q1, q2
		p1=(V_left-DimOffset( imgw,0))/ DimDelta(imgw,0)
		p2=(V_right-DimOffset(imgw,0))/ DimDelta(imgw,0)
		q1=(V_bottom-DimOffset(imgw,1))/ DimDelta(imgw,1)
		q2=(V_top-DimOffset(imgw,1))/ DimDelta(imgw,1)
		ImageStats/M=1/G={min(p1,p2),max(p1,p2),min(q1,q2),max(q1,q2)} imgw
		//print p1,p2,q1,q2, V_min, V_max
//		CTsetscale( imCTw, V_min, V_max, invert)
	else		//no marquee, rescale full image
		ImageStats/M=1 imgw
		//print p1,p2,q1,q2, V_min, V_max
//		CTsetscale( imCTw, V_min, V_max, invert)
	endif
	SetScale/I x V_min,V_max,""  imCTw
	
	Checkbox CTrescale value=0		//use only as an action button
End


Function/S CTreadNote(CTw)
//=============
	WAVE CTw
	//string &CTnam			//Pass-By-Reference
	//variable &gamma, &invert			//Pass-By-Reference
	
	string noteStr, CTlst
	noteStr=note(CTw)
	//print "notestr:", noteStr, NameOfWave(CTw)
	CTlst=StringByKey( "CT", noteStr, ":", "\r" )
	if (strlen(CTlst)==0)					// no CT keywords present in wave note
		CTlst=CTwritenote( CTw, "3. Red Temperature", 1, 0)
		//CTnam="0. B-W Linear"
		//CTnam="3. Red Temperature"
		//gamma=1
		//invert=0
		//CTwritenote( CTw, CTnam, gamma, invert)

	   	//Note/K w
	   	//CTlst="name=0. B-W Linear,gamma=1"		//,CTmin=0,CTmax=1,reverse=0"
	   	//Note CTw, "CT:"+CTlst+"\r"+noteStr		// pre-pend default
   	else		// or do this outside of function
   		//CTnam=StringByKey("name", CTlst, "=", "," )
   		//gamma=NumberByKey("gamma", CTlst, "=", "," )
   		//invert=NumberByKey("invert", CTlst, "=", "," )
   		//print "CTread:", noteStr, CTlst, CTnam, gamma
   	endif
	return CTlst

End

Function/S CTwriteNote(CTw, CTnam, gama, invert)
//=============
	WAVE CTw
	string CTnam			
	variable gama, invert
	
	string notestr, CTlst
	CTlst="name="+CTnam+",gamma="+num2str(gama)+",invert="+num2str(invert)
	notestr=note(CTw)
	notestr=ReplaceStringByKey("CT", notestr, CTlst, ":", "\r")
   	Note/K CTw			//kill previous note
   	Note CTw, noteStr
   	return CTlst
End

Proc CT_ControlBar()
//============
// work on top image in top graph
	string winnam=WinName(0,1)		// top graph
	string imlst=ImageNameList("",";")		//WaveList("*",";","Win:,DIMS:3")
	string imgn=StringFromList(0,imlst)
	if (!exists(imgn))
			abort "no 2D array in top graph"
	endif
	
// get image 'colorindex' CT wave name 	-  (how to treat Igor built-in CTs?)
	string imCTwn
	imCTwn=StringByKey( "cindex", colorTableStr("",imgn), "=", "," )
	imCTwn=imCTwn[1,99]		//strip initial space
	if (strlen(imCTwn)>0)
		if (stringmatch(imCTwn[0]," "))
			imCTwn= imCTwn[1,strlen(imCTwn)-1]		//strip off initial space (after =)
		endif
	else
		//abort "Using Igor built-in Color Table: "+colorTableStr("",imgn)
		DoAlert 1,"Using Igor built-in Color Table: "+colorTableStr("",imgn)+". Create index CT?"
		if (V_flag==1)
			imCTwn=CTmake( $imgn,"/P")			// use default B&W, Gamma=1, no invert
		else
			abort
		endif
	endif

// check if colors subfolder created yet	
	if (DataFolderExists("root:colors")==0)
		execute "colorNameL()"			//can't call procedure from function, so execute
	//		ColorNamesList()		// will give error if variable root:colors:s_colorNL does not already exist
	endif
	
// read base CT name, gamma & invert from wave note	(create if not present)
	//          (store otherinfo in wavenote? CTmin, CTmax store in CT wave scaling)
	string imCTlst, CTnam=""
	variable gama, invert
	//string/G test
	//Pass-by-reference only good from a Function, not proc
	//imCTlst = CTreadNote( $imCTwn, CTnam, gama, invert )
	imCTlst = CTreadNote( $imCTwn )
		CTnam=StringByKey("name", imCTlst, "=", "," )
   		gama=NumberByKey("gamma", imCTlst, "=", "," )
   		invert=NumberByKey("invert", imCTlst, "=", "," )
	
// create/initialize temporary globals folder 
	//colornameslist()	//checks if ColorTablePath exists, if not creates colors subfolder
	string curr=GetDataFolder(1)
	NewDataFolder/O/S root:WinGlobals
	NewDataFolder/O/S $"root:WinGlobals:"+winnam
	
		make/o/n=(256,3) CT
		make/o/n=256 pmap
		string/G CTname=CTnam, imCTwnam=imCTwn		//,CTnamelst
		variable/G CTnum, CTgama=gama, CTinvert=invert

		
//	CTnum=WhichListItem( CTname, CTnamelist(2),";",0 )		// -1 if not found
	CTnum=WhichListItem( CTname, ColorNameslist(),";",0 )	
	if (CTnum==-1)
		CTnum=WhichListItem( CTname, CTnamelist(2),";",0 )
	endif
	CTnum=Selectnumber( CTnum==-1, CTnum, 0)		// not CT in lists
	print CTnum
//	CTselectPop("",CTnum+1,"")		// load linear CT from file
//	CTselect($imCTwn,CTnum,-1, -1)		// load linear CT from file
	pmap=255*(p/255)^gama

//	SetDataFolder $curr
//	abort

	// Add Adjust_CT controls if not already present
	ControlInfo kwControlBar		// sets V_height
	//print V_height
	variable addctrl=SelectNumber(V_height==0, 0,1)
	if (addctrl)
		ControlBar 45
		//PopupMenu CTpop value=root:colors:s_colorNL
		//PopupMenu CTpop value=CTablist()  //builtin Igor CTs
		//PopupMenu CTpop value=root:colors:s_colorNL
		PopupMenu CTpop bodyWidth=140, fsize=8, proc=CTselectPop, mode=CTnum+1  //global or local CTnum?
//		PopupMenu CTpop value=CTnamelist(2), pos={135,1}, size={130,20}
		PopupMenu CTpop value=ColorNamesList(), pos={140,1}, size={130,20}
//		PopupMenu CTpop value="Invert;"+CTnamelist(2), pos={135,1}, size={130,20}
//		PopupMenu CTpop value=ColorNamesList(), pos={130,2}		//1/24/10

		Slider GammaSlide  fsize=8, pos={113,25},size={60,16}
		Slider GammaSlide  proc=CTadjGamma , value=log(gama)  //global or local CTnum?
		Slider GammaSlide  limits={-1,1,0.05},vert= 0,ticks= 0
			//execute "Slider GammaSlide value="+num2str(gama)
//		Slider GammaSlide limits={0.05,SelectNumber(CTinvert==1, 2,20),0.05}
		ValDisplay GammaVal, bodyWidth=30,  fsize=9, title="g", font="Symbol" , pos={186,26}, size={38,11}
		execute "ValDisplay GammaVal value="+num2str(gama)
//		ValDisplay GammaVal, value=gama		//can't use local variable for dependency
		
		//Checkbox Invert,  title="Invert", mode=0, pos={5,25}
		CheckBox CTinvert,pos={232,24},size={31,14},proc=CTinvertCheck,title="Inv"
		CheckBox CTinvert,value= invert
		Checkbox Kill,  title="Kill", proc=CTkillControls, mode=1, pos={6,3}, size={31,14},value= 0,mode=1
		Checkbox CTrescale,  title="rescale (marquee)", mode=1, pos={7,24},size={98,14}, proc=CTrescale, value=0
		//NVAR KeepCTscale=root:colors:KeepCTscale
		Checkbox CTscale,  title="Keep CT scale", mode=0, pos={45,3},size={80,14}
	else
		print "Control Bar already exists"
	endif
	SetDataFolder $curr
	
	// Add color scale legend (check if present?)
	variable addcscale=1			//SelectNumber(V_height==0, 0,1)
	if (addcscale)
		ColorScale/C/N=CTlegend/F=0/S=3/H=14/A=RC/E image=$imgn,fsize=8
		//ColorScale/C/N=CTlegend/F=0/S=3/H=14/A=RC/E cindex=$CTwn,fsize=8
	else
		print "Color Scale already exists"
	endif

End

Function CTkillControls(ctrlName,checked) : CheckBoxControl
//=================
	String ctrlName
	Variable checked
	
	ControlInfo CTscale
	if (!V_value )
		ColorScale/K/N=CTlegend
	endif
	
	KillControl Kill
	KillControl CTscale
	KillControl CTrescale
	KillControl GammaVal
	KillControl GammaSlide
	KillControl CTinvert
	KillControl CTpop
	ControlBar 0

	// remove temporary globals folder
	KillDataFolder "root:WinGlobals:"+WinName(0,1)
End


Function/T CTmake( img, opt )
//=============
// make IDL index Color Table from scratch
	wave img
	string opt
	
	//output CT wave
	string imgn=NameOfWave(img)
	string imCTwn=SelectString(KeySet("D",opt), imgn+"_CT", KeyStr("D",opt))
	
	string CTnam
	variable CTnum, gama=1, invert=0
	if (exists(imCTwn))
		//abort "ColorTable ("+imCTwn+") already exists!"
		string imCTlst = CTreadNote( $imCTwn )
		CTnam=StringByKey("name", imCTlst, "=", "," )
   		gama=NumberByKey("gamma", imCTlst, "=", "," )
   		invert=NumberByKey("invert", imCTlst, "=", "," )
//   		CTnum=WhichListItem( CTnam, CTnamelist(2),";",0 )
   		 CTnum=WhichListItem( CTnam, ColorNamesList(),";",0 )
		CTnum=Selectnumber( CTnum==-1, CTnum, 1)		
	endif

	//CT selection
	CTnum=SelectNumber( KeySet("CT",opt), 0, KeyVal("CT", opt) )
//	CTnam=StringFromList( CTnum, CTnamelist(2))
	CTnam=StringFromList( CTnum, ColorNamesList())
	string fname=StringFromList(CTnum, CTnamelist(1)) 
	PathInfo ColorTablePath
	if (V_flag==0)
		PathInfo Igor
		NewPath/Q ColorTablePath s_path+"User Procedures:ColorTables:Names & Tables"
	endif
//	LoadWave/T/O/Q/P=ColorTablePath fname
	WAVE CT=CT
	
	//Gamma, invert, scale
	gama=SelectNumber( KeySet("Gamma",opt), gama, KeyVal("Gamma", opt) )
	invert=SelectNumber( KeySet("Invert",opt), invert, 1 )
	
	variable dmin, dmax
	ImageStats/M=1 img			//WaveStats/Q im
	dmin=SelectNumber( KeySet("Min",opt), V_min, KeyVal("Min", opt) )
	dmax=SelectNumber( KeySet("Max",opt), V_max, KeyVal("Max", opt) )
//	gama=SelectNumber(invert==1, gama, 1/gama )
	//print imgn, imCTwn, CTnam, gama, invert, dmin, dmax
	
	//Create CT
	Make/O/N=(256,3) $imCTwn
	WAVE imCTw=$imCTwn
	SetScale/I x dmin, dmax, imCTw
	CTselect( imCTw, CTnum, gama, invert)
	
	//optional plot CT
	if (KeySet("P",opt))
		//check if img is on top graph?
		execute "ModifyImage "+imgn+" cindex="+imCTwn
	endif

	KillWaves CT
	return imCTwn
End

Function/S CTnameList(mode)
//=======
// try to make work independent
	variable mode		//0=popup menu , 1 = filename
	string lst
	if (mode==0)   // std numbering with space  
	//also get from ColorNamesList() or root:color:s_colorNL
		lst="0. B-W Linear;1. Blue-White;2. Grn-Red-Blu-Wht;3. Red Temperature;4. Blue-Green-Red-Yellow;5. Std Gamma-II;"
		lst+="6. Prism;7. Red-Purple;8. Green-White Linear;9. Grn-Wht Exponential;10. Green-Pink;"
		lst+="11. Blue-Red;12. 16 Level;13. Rainbow;14. Steps;15. Stern Special;"
		lst+="16. Haze;17. Blue-Pastel-Red;18. Pastels;19. Hue Sat Lightness 1;20. Hue Sat Lightness 2;"
		lst+="21. Hue Sat Value 1;22. Hue Sat Value 2;23. Purple-Red + Stripes;24. Beach;25. Mac Style;"
		lst+="26. Eos A;27. Eos B;28. Hardcandy;29. Nature;30. Ocean;"
		lst+="31. Peppermint;32. Plasma;33. Blue-Red;34. Rainbow;35. Blue Waves;"
		lst+="36. Volcano;37. Waves;38. Rainbow18;39. Rainbow + white;40. Rainbow + black;"
		lst+="41. Rainbow light;42. Purple - Yellow;"
	elseif (mode==1)   //2-digit numbering with no spaces
		lst="00.B-W Linear;01.Blue-White;02.Grn-Red-Blu-Wht;03.Red Temperature;04.Blue-Green-Red-Yellow;05.Std Gamma-II;"
		lst+="06.Prism;07.Red-Purple;08.Green-White Linear;09.Grn-Wht Exponential;10.Green-Pink;"
		lst+="11.Blue-Red;12.16 Level;13.Rainbow;14.Steps;15.Stern Special;"
		lst+="16.Haze;17.Blue-Pastel-Red;18.Pastels;19.Hue Sat Lightness 1;20.Hue Sat Lightness 2;"
		lst+="21.Hue Sat Value 1;22.Hue Sat Value 2;23.Purple-Red + Stripes;24.Beach;25.Mac Style;"
		lst+="26.Eos A;27. Eos B;28.Hardcandy;29.Nature;30.Ocean;"
		lst+="31.Peppermint;32.Plasma;33.Blue-Red;34.Rainbow;35.Blue Waves;"
		lst+="36.Volcano;37.Waves;38.Rainbow18;39.Rainbow + white;40.Rainbow + black;"
		lst+="41.Rainbow light;42.Purple - Yellow;"
	else    // no  numbering
		lst="B-W Linear;Blue-White;Grn-Red-Blu-Wht;Red Temperature;Blue-Green-Red-Yellow;Std Gamma-II;"
		lst+="Prism;Red-Purple;Green-White Linear;Grn-Wht Exponential;Green-Pink;"
		lst+="Blue-Red;16 Level;Rainbow;Steps;Stern Special;"
		lst+="Haze;Blue-Pastel-Red;Pastels;Hue Sat Lightness 1;Hue Sat Lightness 2;"
		lst+="Hue Sat Value 1;Hue Sat Value 2;Purple-Red + Stripes;Beach;Mac Style;"
		lst+="Eos A;Eos B;Hardcandy;Nature;Ocean;"
		lst+="Peppermint;Plasma;Blue-Red;Rainbow;Blue Waves;"
		lst+="Volcano;Waves;Rainbow18;Rainbow + white;Rainbow + black;"
		lst+="Rainbow light;Purple - Yellow;"
	endif
	return lst
End


Function/S ColorTableStr(win, imgn)
//=================
	string win, imgn
	if (strlen(imgn)==0)
		imgn=ImageNameList(win, ";")
		//imgn=imgn[0, strlen(imgn)-2]				//assumes only one image
		imgn=imgn[0, strsearch(imgn, ";", 0)-1]	// assumes first image in window
	endif
	
	string infostr=ImageInfo( win, imgn, 0 )
	variable i1, i2
	i1=strsearch(infostr, "RECREATION:", 0)+11;   i2=strsearch(infostr, ";", i1)-1
	//print i1, i2
	return infostr[i1, i2]
End