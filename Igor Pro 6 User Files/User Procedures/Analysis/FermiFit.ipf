#pragma rtGlobals=1		// Use modern global access method.
#include "XPD"

|ww[0]=overall offset
|ww[1]=offset of linear DOS
|ww[2]=slope of linear DOS
|ww[3]=fermi position, ev
|ww[4]=temperature, ev

function fermi_fit_eli(ww,xx)
	variable xx
	wave ww
	return(ww[0] + (ww[1]+ww[2]*xx)*(1/(exp((xx-ww[3])/ww[4])+1)))
end

