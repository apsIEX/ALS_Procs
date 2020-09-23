#pragma rtGlobals=1		// Use modern global access method.

////////////////////////////////////////////////////////////////////////
// Written by Ruben Reininger
////////////////////////////////////////////////////////////////////////
Function MakeMatrixFromVectors()
	String xcoor, ycoor, data						// As for the WaveList function.
	Prompt xcoor,"Select x coordinate wave",popup,WaveList("*",";","")	
	Prompt ycoor,"Select y coordinate wave",popup,WaveList("*",";","")	
	Prompt data,"Select data wave",popup,WaveList("*",";","")	
	DoPrompt "Enter waves",xcoor,ycoor,data
	if (V_flag==1)
		return 0
	endif
	wave wxcoor=$xcoor
	wave wycoor=$ycoor
	wave wdata=$data
	String mat="m"+data

	Variable np, npx, npy
	wavestats/Q wxcoor

	variable xmin=v_min
	variable xmax=v_max
	wavestats/Q wycoor
	variable ymin=v_min
	variable ymax=v_max

	np=v_npnts
	Variable i=0
	Variable j=0
	Variable ntot
	Variable flag
//Getting the number of points in each direction
	do
		if(wxcoor[i+1] != wxcoor[i])
			Break
		endif
		i+=1								
	while (i<np)				
	if(i==0)		//y's for a given x
		do
			if(wycoor[i+1] != wycoor[i])
				Break
			endif
			i+=1								// execute the loop body
		while (i<np)				// as long as expression is TRUE
		npx=i+1
		npy=np/npx	
		flag=1
	else			//xs for a given y
		npy=i+1
		npx=np/npy	
		flag=0
	endif
	print "np=",np," ÊÊnpx=",npx," ÊÊnpy=",npy
	Make/N=(npx,npy)/D $mat
	wave mdata=$mat
	i=0
	j=0
	ntot=0
	if(flag==0)
		do
			j=0
			do
				mdata[i][j]=wdata[ntot]
				j+=1
				ntot+=1
			while(j<npy)
			i+=1
		while (ntot<np)				// as long as expression is TRUE
	else
		do
			i=0
			do
				mdata[i][j]=wdata[ntot]
				i+=1
				ntot+=1								// execute the loop body
			while(i<npx)
			j+=1
		while (ntot<np)				// as long as expression is TRUE
		print ntot
	endif
	SetScale/I x xmin,xmax,"", mdata
	SetScale/I y ymin,ymax,"", mdata
end



//_______________________________________________________________________
Macro GizmoRuben(wa,xAxis,yAxis,zAxis,size) : GizmoPlot
	string wa
	String xAxis="Horizontal (mm)"
	String yAxis="Vertical (mm)"
	String zAxis="Flux (A.U.)"
	Variable Size=0
	Prompt wa,"the wave",popup,WaveList("*",";","DIMS:2")//+";_none_"
//	Prompt text,"Title"
	Prompt xAxis,"Title for x axis"
	Prompt yAxis,"Title for y axis"
	Prompt zAxis,"Title for z axis"
	Prompt Size, " Small=0, Big=1"
	String text="G_"+wa


	PauseUpdate; Silent 1	// Building Gizmo 6 window...

	// Do nothing if the Gizmo XOP is not available.
	if(exists("NewGizmo")!=4)
		DoAlert 0, "Gizmo XOP must be installed"
		return
	endif
	if( size==0) 
		NewGizmo/N=$text/T=text /W=(50,50,500,500)
	endif
	if( size==1) 
		NewGizmo/N=$text/T=text /W=(50,50,800,800)
	endif
	ModifyGizmo startRecMacro
	AppendToGizmo surface=$wa,name=surface0
	ModifyGizmo ModifyObject=surface0 property={ srcMode,0}
	ModifyGizmo ModifyObject=surface0 property={ surfaceCTab,Rainbow}
	ModifyGizmo ModifyObject=surface0 property={ textureType,1}
	ModifyGizmo modifyObject=surface0 property={calcNormals,1}
	AppendToGizmo Axes=boxAxes,name=axes0
	ModifyGizmo ModifyObject=axes0,property={0,axisRange,-1,-1,-1,1,-1,-1}
	ModifyGizmo ModifyObject=axes0,property={1,axisRange,-1,-1,-1,-1,1,-1}
	ModifyGizmo ModifyObject=axes0,property={2,axisRange,-1,-1,-1,-1,-1,1}
	ModifyGizmo ModifyObject=axes0,property={3,axisRange,-1,1,-1,-1,1,1}
	ModifyGizmo ModifyObject=axes0,property={4,axisRange,1,1,-1,1,1,1}
	ModifyGizmo ModifyObject=axes0,property={5,axisRange,1,-1,-1,1,-1,1}
	ModifyGizmo ModifyObject=axes0,property={6,axisRange,-1,-1,1,-1,1,1}
	ModifyGizmo ModifyObject=axes0,property={7,axisRange,1,-1,1,1,1,1}
	ModifyGizmo ModifyObject=axes0,property={8,axisRange,1,-1,-1,1,1,-1}
	ModifyGizmo ModifyObject=axes0,property={9,axisRange,-1,1,-1,1,1,-1}
	ModifyGizmo ModifyObject=axes0,property={10,axisRange,-1,1,1,1,1,1}
	ModifyGizmo ModifyObject=axes0,property={11,axisRange,-1,-1,1,1,-1,1}
	ModifyGizmo ModifyObject=axes0,property={-1,axisScalingMode,1}
	ModifyGizmo ModifyObject=axes0,property={-1,axisColor,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,property={0,ticks,3}
	ModifyGizmo ModifyObject=axes0,property={1,ticks,3}
	ModifyGizmo ModifyObject=axes0,property={5,ticks,3}
	ModifyGizmo ModifyObject=axes0,property={1,labelOffset,-0.1,0,0}
	ModifyGizmo ModifyObject=axes0,property={0,canonicalIncrement,0.005}
	ModifyGizmo ModifyObject=axes0,property={1,canonicalIncrement,0.005}
	ModifyGizmo ModifyObject=axes0,property={5,canonicalIncrement,0.005}
	ModifyGizmo ModifyObject=axes0,property={0,canonicalDigits,3}
	ModifyGizmo ModifyObject=axes0,property={1,canonicalDigits,3}
	ModifyGizmo ModifyObject=axes0,property={5,canonicalDigits,3}
	ModifyGizmo ModifyObject=axes0,property={1,numTicks,3}
	ModifyGizmo ModifyObject=axes0,property={0,axisLabel,1}
	ModifyGizmo ModifyObject=axes0,property={1,axisLabel,1}
	ModifyGizmo ModifyObject=axes0,property={5,axisLabel,1}
	ModifyGizmo ModifyObject=axes0,property={0,axisLabelText,xAxis}
	ModifyGizmo ModifyObject=axes0,property={1,axisLabelText,yAxis}
	ModifyGizmo ModifyObject=axes0,property={5,axisLabelText,zAxis}
	ModifyGizmo ModifyObject=axes0,property={0,axisLabelCenter,-0.4}
	ModifyGizmo ModifyObject=axes0,property={1,axisLabelCenter,-0.8}
	ModifyGizmo ModifyObject=axes0,property={5,axisLabelCenter,-0.6}
	ModifyGizmo ModifyObject=axes0,property={0,axisLabelDistance,0.1}
	ModifyGizmo ModifyObject=axes0,property={1,axisLabelDistance,0.1}
	ModifyGizmo ModifyObject=axes0,property={5,axisLabelDistance,0.4}
	ModifyGizmo ModifyObject=axes0,property={0,axisLabelScale,0.6}
	ModifyGizmo ModifyObject=axes0,property={1,axisLabelScale,0.6}
	ModifyGizmo ModifyObject=axes0,property={5,axisLabelScale,0.6}
	ModifyGizmo ModifyObject=axes0,property={0,axisLabelRGBA,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,property={1,axisLabelRGBA,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,property={5,axisLabelRGBA,0,0,0,1}
	ModifyGizmo ModifyObject=axes0,property={0,axisLabelFont,"Arial"}
	ModifyGizmo ModifyObject=axes0,property={1,axisLabelFont,"Arial"}
	ModifyGizmo ModifyObject=axes0,property={5,axisLabelFont,"Arial"}
	ModifyGizmo ModifyObject=axes0,property={5,axisLabelFlip,1}
//	AppendToGizmo string=wa,strFont="Arial",name=string0
	AppendToGizmo light=Directional,name=light0
	ModifyGizmo light=light0 property={ position,0.739149,0.147759,-0.657135,0.000000}
	ModifyGizmo light=light0 property={ direction,0.739149,0.147759,-0.657135}
	ModifyGizmo light=light0 property={ specular,1.000000,1.000000,1.000000,1.000000}
	AppendToGizmo attribute color={0,0,0,1},name=color0
//	ModifyGizmo setDisplayList=0, opName=scale1, operation=scale, data={0.15,0.15,0.15}
//	ModifyGizmo setDisplayList=1, opName=rotate1, operation=rotate, data={180,1,0,0}
//	ModifyGizmo setDisplayList=2, opName=translate2, operation=translate, data={-10,-8,0}
//	ModifyGizmo setDisplayList=3, object=string0
	ModifyGizmo setDisplayList=0, object=light0
	ModifyGizmo setDisplayList=1, opName=clearColor0, operation=clearColor, data={1,1,0.8,1}
	ModifyGizmo setDisplayList=2, opName=MainTransform, operation=mainTransform
	ModifyGizmo setDisplayList=3, object=surface0
	ModifyGizmo setDisplayList=4, object=axes0
	ModifyGizmo SETQUATERNION={0.585491,-0.282473,-0.330210,0.684377}

	ModifyGizmo SETQUATERNION={0.542820,-0.269704,-0.353765,0.712359}
	ModifyGizmo autoscaling=1
	ModifyGizmo currentGroupObject=""
	ModifyGizmo compile

	ModifyGizmo showInfo
	ModifyGizmo infoWindow={752,279,1404,572}
	ModifyGizmo bringToFront
	ModifyGizmo endRecMacro
End
