#pragma rtGlobals=1		// Use modern global access method.

Function FileSize_MB( filepath, filnam ) //written by Eli Rotenberg in Fits loader
	string filepath, filnam
	GetFileFolderInfo/Q/Z filepath+ filnam
	return round( 10*V_logEOF/1E6 )/10			//MB
End


////// Procs for dealing with data folders and files in a loader//////
Function DataFolderPopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	PauseUpdate
	string dfn=winname(0,64)
	string df="root:"+dfn+":"	
	svar filepath=$(df+"filepath"), folderlist=$(df+"folderlist"), filelist=$(df+"filelist"), filter=$(df+"filter")
	nvar filenum=$(df+"filenum")
	wave/t filelistw=$(df+"filelistw")
	wave fileselectw=$(df+"fileselectw")
	if(popnum==1)
		newpath/o/q/m="Select Data Folder" LoadPath
		pathinfo LoadPath
		filepath=s_path
		folderlist=folderlist+filepath+";"
	else
		filepath=StringFromList(popnum-1, folderList)
		newpath/q/o LoadPath filepath
	endif
	string fullfileList=IndexedFile(LoadPath,-1,"????")	
	fileList=ReduceList( fullfileList, filter )
	filenum=ItemsInList( fileList)
	filenum= List2Textw(fileList, ";",(df+"fileListw"))
	Redimension/N=(filenum,2) fileListw
	Redimension/N=(filenum,2,2) fileSelectw
	fileListw[][0]=stringfromlist(p,fileList)
	fileListw[][1]=num2str( FileSize_MB( filepath, fileListw[p][0]) )+" MB"
	fileSelectw[][][%forecolors]=floor( log(  FileSize_MB( filepath, fileListw[p][0])) )+1
	PopupMenu popFile  value=#dfn+"fileList", mode=1
end
Function UpdateFilesLB(ctrlName) : ButtonControl
	String ctrlName
	string dfn=winname(0,64)
	string df="root:"+dfn+":"	
	svar filepath=$(df+"filepath"), folderlist=$(df+"folderlist"), filelist=$(df+"filelist"), filter=$(df+"filter")
	nvar filenum=$(df+"filenum")
	wave/t filelistw=$(df+"filelistw")
	wave fileselectw=$(df+"fileselectw")
	string fullfileList=IndexedFile(LoadPath,-1,"????")	
	fileList=ReduceList( fullfileList, filter) 
	filenum=ItemsInList( fileList)
	filenum= List2Textw(fileList, ";",(df+"fileListw"))
	Redimension/N=(filenum,2) fileListw
	Redimension/N=(filenum,2,2) fileSelectw
	fileListw[][0]=stringfromlist(p,fileList)
	fileListw[][1]=num2str( FileSize_MB( filepath, fileListw[p][0]) )+" MB"
	fileSelectw[][][%forecolors]=floor( log(  FileSize_MB( filepath, fileListw[p][0])) )+1
	PopupMenu popFile  value=#dfn+"fileList", mode=1
end
Function DataFilePopupMenuAction (ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string
	string dfn=winname(0,64)
	string df="root:"+dfn+":"
	nvar filenum=$(df+"filenum"); filenum=popnum
	svar filename=$(df+"filename"); filename=popstr
	ListBox listboxfiles selRow=popNum-1, row=max(0,popNum-3)
end
Function FileListBoxAction (ctrlName,row,col,event) : ListBoxControl
	String ctrlName
	Variable row
	Variable col
	Variable event	//1=mouse down, 2=up, 3=dbl click, 4=cell select with mouse or keys
	//5=cell select with shift key, 6=begin edit, 7=end
	//print "event=", event, "row=", row		
	PauseUpdate; Silent 1
	string dfn=winname(0,64)
	string df="root:"+dfn+":"
	if ((event==4)) //+(event==10))    // mouse click or arrow up/down or 10=cmd ListBox
		nvar filenum=$(df+"filenum")
		svar filename=$(df+"filename"), fileList=$(df+"fileList")
		wave  fileListw=$(df+"fileListw")
		filenum=row
		filename= stringfromlist(filenum,fileList)
		PopupMenu popFile  mode=row+1
	endif
	return row
end




