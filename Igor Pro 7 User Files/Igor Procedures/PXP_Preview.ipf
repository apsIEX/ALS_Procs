#pragma rtGlobals=1		// Use modern global access method.


static function BeforeExperimentSaveHook(refNum,fileName,path,type,creator,kind)
	Variable refNum,kind
	String fileName,path,type,creator
	#if exists("screencap")
		newdatafolder  /o root:Packages
		newdatafolder  /o root:Packages:PXP_Preview
	
		make /o root:Packages:PXP_Preview:PXP_Preview
		screencap root:Packages:PXP_Preview:PXP_Preview
	#endif
	
	#if defined(MACINTOSH)
		String unixCmd
		String igorCmd

		unixCmd = "hostname"
		sprintf igorCmd, "do shell script \"%s\"", unixCmd
		ExecuteScriptText/UNQ igorCmd
		string host = S_value
		
		unixCmd = "whoami"
		sprintf igorCmd, "do shell script \"%s\"", unixCmd
		ExecuteScriptText/UNQ igorCmd
		string user = S_value
	#else
		string host = ""
		string user= ""
	#endif
		PathInfo $path
		string FQFN = S_path+fileName
		
		string logline = Date() +"\t"+Time()+"\t"+ user+ "\t"+Host +"\t"+ FQFN
		
		if (exists("root:Packages:PXP_Preview:PXP_Preview_Log")!=1)
			newdatafolder  /o root:Packages
			newdatafolder  /o root:Packages:PXP_Preview
			make /o root:Packages:PXP_Preview:PXP_Preview_Log
		endif
		note  root:Packages:PXP_Preview:PXP_Preview_Log logline
		Printf "Saved \"%s\" on %s at %s\r",FQFN ,date(),time()

end

Static Function AfterFileOpenHook(refNum,file,pathName,type,creator,kind)
	Variable refNum,kind
	String file,pathName,type,creator
	// Check that the file is open (read only), and of correct type
	//print "AfterFileOpenHook"
	if(kind==1)
			PathInfo $pathName
			string FQFN = S_path+file

		print "Experiment \""+ FQFN +"\" opened " + date() + " " + time()
	endif
	return 0							// don't prevent MIME-TSV from displaying
End

static function IgorStartOrNewHook(igorApplicationNameStr )
	String igorApplicationNameStr
	print "New Experiment created " + date() + " " + time()
	return 0
end