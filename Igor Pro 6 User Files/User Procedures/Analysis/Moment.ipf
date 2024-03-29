Macro Moment(wavstr, output, nbk )
		string wavstr; variable output, nbk=5
		prompt wavstr,"Y-Wave(s):", popup,"All;"+WaveList("*",";","WIN:"+winname(0,1))
		prompt output,"Output:",popup,"History only;Graph Legend;History&Graph;Table"
		prompt nbk,"% Bkg Avg inside Cursors (0=No Bkg):"
		variable xL,xR, xcsa, xcsb 
		string ywav,xwav,wndw, gstring=""
	Silent 1
	wndw = winname(0,1)
	xcsa = hcsr(A); xcsb = hcsr(B)
	xL = min(xcsa,xcsb); xR =max(xcsa,xcsb)
	make/o/n=101 Mtmp,Mbtmp
	SetScale/I x, xL, xR, "" Mtmp,Mbtmp
	Mbtmp=nan; append Mbtmp;  modify mode(Mbtmp)=3,marker(Mbtmp)=18
	if (output==4)
		make/o/T/n=100 Wnames
		make/o/n=100 Wareas, Wxmom	
	endif
	variable ii=0, momt, xmomt
	iterate(100)
		ywav=WaveName( wndw,i,1)
		if (cmpstr(ywav,"Mbtmp")==0)
			break
		endif
		if ( (cmpstr(ywav,wavstr)==0) + (cmpstr(wavstr,"All")==0) )
			xwav = XWaveName( Wndw, ywav )
			if (cmpstr(xwav,"")==0)		// ywav is scaled
				print ywav+" scaled"
				Mtmp = $ywav( x )
			else
	//			print ywav+" plotted vs "+xwav
				Mtmp = interp( x, $xwav, $ywav )
			endif
			Mbtmp[0,nbk]=Mtmp[p];  Mbtmp[100-nbk,100]=Mtmp[p]
			momt = moment1( Mtmp, nbk )		
			xmomt = xmoment1( Mtmp, nbk )		
			print ywav, " Moment:", momt
			gstring += "\s("+ywav+") "+ywav+"  A="+num2str(momt)+"\r"
			if (output==4)
				Wnames[ii]=ywav
				Wareas[ii]=momt
				Wxmom[ii]=xmomt
			endif
		endif
		ii+=1
	loop
	if ((output==2)+(output==3))		// check for existence?
		ReplaceText/n=text0  gstring
	endif
	remove Mbtmp
	if (output==4)
		redimension/n=(ii) Wnames, Wareas, Wxmom
		Edit Wnames, Wareas, Wxmom
	endif
End

Function Moment1( ywav, nbk )
		wave ywav; variable nbk
		variable np, psum, bsum, xL,xR, dx, k
	np = numpnts( ywav )		// =101
	xR = pnt2x(ywav,np-1)
	xL = pnt2x(ywav,0)
	dx = xR - xL	
	psum = area( ywav,  xL,  xR )
	bsum=0
	if (nbk>0)
		k=0
		do
			bsum += ywav[k] + ywav[np-k-1]
			k += 1
		while( k< nbk )
		bsum *= dx / (2*nbk)
	endif		
	return( (psum-bsum) )
End		

Function XMoment1( ywav, nbk )
		wave ywav; variable nbk
		variable np, psum, bsum, xL,xR, dx, k
	np = numpnts( ywav )		// =101
	xR = pnt2x(ywav,np-1)
	xL = pnt2x(ywav,0)
	dx = xR - xL
	duplicate/o ywav XMtmp
	XMtmp=ywav*x	
	psum = area( XMtmp,  xL,  xR )/area( ywav,  xL,  xR )
	bsum=0
	//if (nbk>0)
	//	k=0
	//	do
	//		bsum += ywav[k] + ywav[np-k-1]
	//		k += 1
	//	while( k< nbk )
	//	bsum *= dx / (2*nbk)
	//endif		
	//return( (psum-bsum) )
	return psum
End		

Macro Moment2( ywav, nbk )	// macro for debugging purposes
		string ywav; variable nbk
		variable np, psum, bsum, xL,xR, dx, k
	np = numpnts( $ywav )		// =101
	xR = pnt2x($ywav,np-1)
	xL = pnt2x($ywav,0)
	dx = xR - xL	
	psum = area( $ywav,  xL,  xR )
	bsum=0
	if (nbk>0)
		k=0
		do
			bsum += $ywav[k] + $ywav[np-k-1]
			k += 1
		while( k< nbk )
		bsum *= dx / (2*nbk)
	endif		
	print psum-bsum , psum, bsum, dx
End		
