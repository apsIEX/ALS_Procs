#pragma rtGlobals=1		// Use modern global access method.
#if str2num(StringByKey("IGORVERS",IgorInfo(0)))>=6.1
#include "IMAGETOOL575"
#elif str2num(StringByKey("IGORVERS",IgorInfo(0)))>5.99
#include "IMAGETOOL562er"
#endif