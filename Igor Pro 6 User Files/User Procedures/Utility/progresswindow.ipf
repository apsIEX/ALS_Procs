#pragma rtGlobals=1		// Use modern global access method.

// 12/7/09 ab made window floating
//11/21/07 jdd use mode=3 to have progress bar vertical (no fractional part)
//  (future) program to allow two separate progress bars,e.g. inner & outer loop
//   or make custom 2-part panel 

 function  OpenProgressWindow(progressname, prog_max)
 //========================
		string progressname
		variable prog_max
		dowindow /k Export 
		variable top = 0,left=0
		NewPanel /K=1/FLT /N=Export /W=(left,top,left+260,top+106) as progressname
//		DoWindow /C Export
		variable /g root:progress 
		SetDrawLayer UserBack
		SetDrawEnv fsize= 24
		DrawText 154,49,"of "+num2str(prog_max-1)
		SetVariable progress,pos={20,20},size={125,28},title="Frame",fSize=20
		SetVariable progress,limits={-Inf,Inf,0},value=  root:progress,bodyWidth= 0
		ValDisplay valdisp0,pos={13,63},size={218,30},limits={0,prog_max-1,0},barmisc={0,0}
		ValDisplay valdisp0, mode=3, value= #"root:progress"
		 SetActiveSubwindow _endfloat_

		DoUpdate/W=Export/E=1		// mark this as our progress window
	
		SetWindow Export,hook(spinner)= ProgressWindowHook

end
//   end Open Progress Dialog

 function UpdateProgressWindow( val )	
//=========================	
		variable val
		// Close Progess dialog
		NVAR progress = root:progress
		progress= val
		DoUpdate
end
				
function CloseProgressWindow()	
//========================	
		// Close Progess dialog
		 DoWindow /k /W= Export Export 
		killvariables root:progress
end
Function ProgressWindowHook(s)
	STRUCT WMWinHookStruct &s
	
	if( s.eventCode == 23 )
		wave  prog = root:FITS:prog
		ValDisplay valdisp0,value= _NUM:prog[0],win=$s.winName
		DoUpdate/W=$s.winName
		if( V_Flag == 2 )	// we only have one button and that means abort
			KillWindow $s.winName
			return 1
		endif
	endif
	return 0
End