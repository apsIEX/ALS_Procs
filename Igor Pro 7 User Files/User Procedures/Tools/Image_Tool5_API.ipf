#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function Test_IT5Style(w,df)
	wave w
	string df
	print "Test_IT5Style",nameofWave(w),df
end

function Test2_IT5Style(w,df)
	wave w
	string df
	print "Test_IT5Style2",nameofWave(w),df
end

function test()
	string Func_List =  functionList("*_IT5Style",";","KIND:2;NINDVARS:2")
	variable ii,N=ItemsInList(Func_List)
	for(ii=0;ii<N;ii+=1)
		string Func = StringFromList(ii, Func_List)  
		make/FREE/N=4 testwave
		string df = "test"
		FUNCREF Test_IT5Style f = $Func
		f(testwave,df)
	endfor
end

function test2(df)
	string df
	DFREF dfr=$df
	DFREF dfroot=root:

	print dataFolderRefStatus(dfr)
	print dataFolderRefStatus(dfroot)
	print dataFolderRefsEqual(dfr,dfroot)
end

function /S IT5_FixUpDF(df)
	string df
	df = trimString(df)
	if(strlen(df)==0)	// return topmost IT5 if df=""
		df = imagetool5#getdf()
		DFREF dfr=$df	
		if(dataFolderRefStatus(dfr)==1)
			return df
		else
			abort "No ImagetoolV exists"
		endif
	endif
	DFREF dfr=$df	
	if(dataFolderRefStatus(dfr)==1) // if df is a full path just return it
		return df
	endif
	if(stringmatch(df,"imagetoolV*")==1)
		df=imagetool5#getDFfromName(df)
		DFREF dfr=$df	
		if(dataFolderRefStatus(dfr)==1)
			return df
		else
			abort "Named ImagetoolV doesn't exist"
		endif
	endif
	variable it5_num=str2num(df)
	if(numtype(it5_num)==0) // if df is just a number and a IT5 of that number exists return its df
		df=IT5_getDFfromNum(It5_Num)
		DFREF dfr=$df	
		if(dataFolderRefStatus(dfr)==1)
			return df
		else
			abort "That number ImagetoolV doesn't exist"
		endif
	endif
	abort "Unknown ImagetoolV"
end

function IT5_setbinning(df,a,b,c,d)
	string df
	variable a,b,c,d
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	make /FREE/N=4 newbin = {a,b,c,d}
	wave bin=$df+"bin"
	bin = (newbin[p]<1)*bin[p] + (newbin[p]>=1)*newbin[p]
	return 0
end


function /T IT5_GenerateBinCmds(df)
	string df
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return ""
	endif
	wave bin=$df+"bin"
	return "IT5_setbinning(df,"+num2str(bin[0])+","+num2str(bin[1])+","+num2str(bin[2])+","+num2str(bin[3])+")"
end


function IT5_setDimMap(df,a,b,c,d)
	string df
	variable a,b,c,d
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	make /N=4/FREE map={a,b,c,d}
	sort map,map
	variable ii,good=1
	for(ii=0;ii<4;ii += 1)
		good *= (map[ii]==ii)
	endfor
	if(good==0)
		print "IT5_setDimMap() error: map is invalid"
		return 0
	endif
	nvar d3i=$(df+"dim3index"), d4i=$(df+"dim4index"),txy=$(df+"transXY")
	d3i=c
	d4i=d
	if(a>b)
		txy=1
	else
		txy=0
	endif
	SVAR w=$(df+"dname")
	setupV(IT5winname(df),w)
end


function /T IT5_GenerateDimMap(df)
	string df
	if(!DataFolderExists(df))
		return ""
	endif
	wave dnum=$df+"dnum"	
	return "IT5_setDimMap(df,"+num2str(dnum[0])+","+num2str(dnum[1])+","+num2str(dnum[2])+","+num2str(dnum[3])+")"
end


function IT5_dataAxisScale(df,dnum,setaxiscmd)
	string df
	variable dnum
	string setaxiscmd
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	SETAXISCMD = replacestring("SetAxis",SETAXISCMD,"SetAxis/Z/W="+imagetool5#IT5winname(df)+" ")
	string AL = getdnumaxislist(df,dnum)
	variable ii,N = itemsinlist(AL)
	string axis
	for (ii=0;ii<N;ii+=1)
		axis = stringfromList(ii,AL)
		execute  replacestring("_AXIS_",SETAXISCMD,axis)
	endfor
end

function /t IT5_GenerateAxisCmds(df)
	string df
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return ""
	endif
	string output=""
	wave /t DnumAxesScales = getDnumAxesScales(df)
	variable ii
	for (ii=0;ii<4;ii+=1)
		STRING SETAXISCMD = replacestring("AXISNAME",DnumAxesScales[II],"_AXIS_")
		if(ii!=0)
			output += "\r" 
		endif
		output += "IT5_dataAxisScale(df,"+num2str(ii)+",\""+SETAXISCMD+"\")"
		//print SETAXISCMD
	endfor
	return output
end

function IT5_ShowPlot(df,plot)
	string df
	string plot
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	struct imageWaveNameStruct s
	if(getimageinfo(df,plot,s)==0)
		NVAR has = $(df+s.has)
		has = 1
		SVAR w=$(df+"dname")
		setupV(IT5winname(df),w)
	endif
	if(gettraceinfo(df,plot,s)==0)
		NVAR has = $(df+s.has)
		has = 1
		SVAR w=$(df+"dname")
		setupV(IT5winname(df),w)
	endif
end

function IT5_HidePlot(df,plot)
	string df
	string plot
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	struct imageWaveNameStruct s
	if(getimageinfo(df,plot,s)==0)
	elseif(gettraceinfo(df,plot,s)==0)
	else
		return -1
	endif
	NVAR has = $(df+s.has)
	has = 0
	SVAR w=$(df+"dname")
	setupV(IT5winname(df),w)
end


function /t IT5_GeneratePlotCmds(df)
	string df
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return ""
	endif
	string output=""
	string Plotlist	 = "img;imgH;imgV;imgZT;Hprof;Vprof;Tprof;Zprof"
	STRING SETPlotCMD
	variable ii,N = itemsinlist(Plotlist)
	for (ii=0;ii<N;ii+=1)
		string plot = stringfromlist(ii,plotlist)
		struct imageWaveNameStruct s
		if(getimageinfo(df,plot,s)==0)
		elseif(gettraceinfo(df,plot,s)==0)
		else
			break
		endif
		NVAR has = $(df+s.has)
		if(has==0)
			SETPlotCMD = "IT5_HidePlot("
		else
			SETPlotCMD = "IT5_ShowPlot("
		endif
		SETPlotCMD += "df,\""+plot+"\")"
		if(ii!=0) 
			output+="\r"
		endif
		output += SETPlotCMD  
	endfor
	return output
end


function	IT5_SetAllColorTables(df,CT_num,invert)
	string df
	variable CT_num,invert
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	imagetool5#SetAllColorTables(df,CT_Num)
	imagetool5#SetAllColorTablesInvert(df,invert)
end


function IT5_SetColorTable(df,plot,CT_Num,invert)
	string df,plot
	variable CT_num,invert
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	struct imageWaveNameStruct s
	if(getimageinfo(df,plot,s)==0)
			NVAR whichCT=$(df+s.whCT)
			NVAR InvertCT=$(df+s.whInvertCT)
			whichCT = CT_Num
			InvertCT = invert
	endif	
end

function /t IT5_GenerateSetColorTables(df)
	string df
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return ""
	endif
	string output =""
	nvar ict=$(df+"invertct")
	nvar  whichCT=$(df+"whichCT"), whichCTh=$(df+"whichCTh"),whichCTv=$(df+"whichCTv"),whichCTzt=$(df+"whichCTzt")
	nvar  InvertCT=$(df+"invertCT"), InvertCT_H=$(df+"invertCT_H"),InvertCT_V=$(df+"invertCT_V"),InvertCT_ZT=$(df+"InvertCT_ZT")

	if((whichCT==whichCTh)&&(whichCT==whichCTv)&&(whichCT==whichCTzt)&&(InvertCT==InvertCT_H)&&(InvertCT_H==InvertCT_V)&&(InvertCT_V==InvertCT_ZT))
		return "IT5_SetAllColorTables(df,"+num2str(whichCT)+","+num2str(ict)+")"
	endif
	string Plotlist	 = "img;imgH;imgV;imgZT"
	variable ii,N = itemsinlist(Plotlist)
	for (ii=0;ii<N;ii+=1)
		string plot = stringfromlist(ii,plotlist)
		struct imageWaveNameStruct s
		if(getimageinfo(df,plot,s)==0)
			if(ii!=0)
				output += "\r" 
			endif
			NVAR whichCT=$(df+s.whCT)
			NVAR InvertCT=$(df+s.whInvertCT)
			output+="IT5_SetColorTable(df,\""+plot+"\","+num2str(whichCT)+","+num2str(InvertCT)+")"
		endif
	endfor
	return output
end

function	IT5_SetAllGamma(df,gamma)
	string df
	variable gamma
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	NVAR Lockgamma_img = $(df+"Lockgamma_img")
	NVAR Lockgamma_H = $(df+"Lockgamma_H")
	NVAR Lockgamma_V = $(df+"Lockgamma_V")
	NVAR Lockgamma_ZT = $(df+"Lockgamma_ZT")
	Lockgamma_img=0
	Lockgamma_H=0
	Lockgamma_V=0
	Lockgamma_ZT=0
	imagetool5#UpdateGamma(df,gamma)

end


function IT5_SetGamma(df,plot,gamma,lock)
	string df,plot
	variable gamma, lock
	variable CT_num,invert
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return -1
	endif
	struct imageWaveNameStruct s
	if(getimageinfo(df,plot,s)==0)
			NVAR gGamma=$(df+s.whGamma)
			NVAR gGammaLock=$(df+s.whGLock)
			gGamma = gamma
			gGammaLock = lock
	endif	
end


function /t IT5_GenerateSetGamma(df)
	string df
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return ""
	endif
	string output =""
	NVAR Lockgamma_img = $(df+"Lockgamma_img")
	NVAR Lockgamma_H = $(df+"Lockgamma_H")
	NVAR Lockgamma_V = $(df+"Lockgamma_V")
	NVAR Lockgamma_ZT = $(df+"Lockgamma_ZT")
	
	NVAR gamma_img = $(df+"gamma_img")
	NVAR gamma_H = $(df+"gamma_H")
	NVAR gamma_V = $(df+"gamma_V")
	NVAR gamma_ZT = $(df+"gamma_ZT")
	
	if((Lockgamma_img+Lockgamma_H+Lockgamma_V+Lockgamma_ZT)==0)
		return "IT5_SetAllGamma(df,"+num2str(gamma_img)+")"
	endif

	string Plotlist	 = "img;imgH;imgV;imgZT"
	variable ii,N = itemsinlist(Plotlist)
	for (ii=0;ii<N;ii+=1)
		string plot = stringfromlist(ii,plotlist)
		struct imageWaveNameStruct s
		if(getimageinfo(df,plot,s)==0)
			if(ii!=0)
				output += "\r" 
			endif
			NVAR Gamma=$(df+s.whGamma)
			NVAR GammaLock=$(df+s.whGLock)
			output+="IT5_SetGamma(df,\""+plot+"\","+num2str(gamma)+","+num2str(GammaLock)+")"
		endif
	endfor
	return output
end


function /t IT5_GenerateSettingsMacro(df,[AsString])
	string df
	variable AsString
	df = IT5_FixUpDF(df)
	if(!DataFolderExists(df))
		return ""
	endif
	string output = "function "+IT5WinName(df) +"_Style() \r"
	output += "\t//string df=\""+df+"\"\r"
	output += "\tstring df = imagetool5#getdf()\r"

	output += "\t"+replacestring("\r",IT5_GenerateDimMap(df),"\r\t")+"\r"
	output += "\t"+replacestring("\r",IT5_GenerateBinCmds(df),"\r\t")+"\r"
	output += "\t"+replacestring("\r",IT5_GeneratePlotCmds(df),"\r\t")+"\r"
	output += "\t"+replacestring("\r",IT5_GenerateAxisCmds(df),"\r\t")+"\r"
	output += "\t"+replacestring("\r",IT5_GenerateSetColorTables(df),"\r\t")+"\r"
	output += "\t"+replacestring("\r",IT5_GenerateSetGamma(df),"\r\t")+"\r"

	output += "end\r"
	if( ParamIsDefault(AsString))
		putscrapText output
		print IT5WinName(df)+"_Style() IT5 style macro copied to cliboard"
	else
		output = "Copy this function to the macro window to use.\rBy default it will apply the style to the topmost image tool\r\r" + output

		return output
	endif
	return ""
end


function imagetoolv0_Style() 
	//string df="root:imagetoolv0:"
	string df = imagetool5#getdf()
	IT5_setDimMap(df,3,0,2,1)
	IT5_setbinning(df,1,1,1,1)
	IT5_ShowPlot(df,"img")
	IT5_ShowPlot(df,"imgH")
	IT5_ShowPlot(df,"imgV")
	IT5_ShowPlot(df,"imgZT")
	IT5_ShowPlot(df,"Hprof")
	IT5_ShowPlot(df,"Vprof")
	IT5_ShowPlot(df,"Tprof")
	IT5_ShowPlot(df,"Zprof")
	IT5_dataAxisScale(df,0,"SetAxis/A _AXIS_")
	IT5_dataAxisScale(df,1,"SetAxis _AXIS_ -0.641315973029528,0.123622413392234")
	IT5_dataAxisScale(df,2,"SetAxis _AXIS_ -0.850678733031674,-0.156862745098039")
	IT5_dataAxisScale(df,3,"SetAxis/A _AXIS_")
	IT5_SetColorTable(df,"img",0,1)
	IT5_SetColorTable(df,"imgH",0,0)
	IT5_SetColorTable(df,"imgV",0,0)
	IT5_SetColorTable(df,"imgZT",0,0)
	
end


