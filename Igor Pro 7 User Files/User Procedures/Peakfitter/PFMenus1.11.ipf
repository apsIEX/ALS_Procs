#pragma rtGlobals=1		// Use modern global access method.

// Quick access to select packages in WaveMetrics Procedures folder...


Menu "Analysis"
	Submenu "Packages"
		"PeakFitter",Execute/P "INSERTINCLUDE  \"Peak Fitter 1.11\"";Execute/P "COMPILEPROCEDURES ";Execute/Q/P "PFStartup()"; execute/P/Q "string/g :PF:version=\"1.11\""; execute/P/Q "doLogoWindow()"

	End
End