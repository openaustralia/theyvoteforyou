// $Id: mparr.java,v 1.1 2003/08/14 19:35:48 frabcus Exp $

// The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.

/////////////////////////////////////////////
import java.io.IOException; 
import java.io.File;
import java.io.FileReader;
import java.io.BufferedReader; 
import java.io.StreamTokenizer;

/////////////////////////////////////////////
class mparr
{
	double ranfac = 0.0005; 
	mppos[] mpa; // the data.  

	double xlo, xhi; 
	double ylo, yhi; 
	double zlo, zhi; 

	double xeig; 
	double yeig; 
	double zeig; 
	
	// construct the data from a given buffer (online or in a file).  
	mparr(BufferedReader br) throws IOException
	{
		StreamTokenizer stoken = new StreamTokenizer(br); 
  		stoken.quoteChar('"'); 
		
		// get the number of MPs (and check it's within bounds).  
		if ((stoken.nextToken() != StreamTokenizer.TT_NUMBER) || (stoken.nval > 1000) || (stoken.nval < 1)) 
			throw new IOException(); 
		int nmpa = (int)stoken.nval; 
		mpa = new mppos[nmpa]; 
		
		// get the eigenvalues 
		if (stoken.nextToken() != StreamTokenizer.TT_NUMBER) 
			throw new IOException(); 
		xeig = stoken.nval; 
		if (stoken.nextToken() != StreamTokenizer.TT_NUMBER) 
			throw new IOException(); 
		yeig = stoken.nval; 
		if (stoken.nextToken() != StreamTokenizer.TT_NUMBER) 
			throw new IOException(); 
		zeig = stoken.nval; 
		
		xeig = (xeig > 0.0 ? Math.sqrt(xeig) : 0.0); 
		yeig = (yeig > 0.0 ? Math.sqrt(yeig) : 0.0); 
		zeig = (zeig > 0.0 ? Math.sqrt(zeig) : 0.0); 

		
		for (int i = 0; i < nmpa; i++) 
		{
			mppos mpp = new mppos(stoken, ranfac); 
			
			// factor in the eigenvalues 
			mpp.x *= xeig; 
			mpp.y *= yeig; 
			mpp.z *= zeig; 

			// find the ranges			
			if ((i == 0) || (mpp.x < xlo)) 
				xlo = mpp.x; 
			if ((i == 0) || (mpp.x > xhi)) 
				xhi = mpp.x; 
			if ((i == 0) || (mpp.y < ylo)) 
				ylo = mpp.y; 
			if ((i == 0) || (mpp.y > yhi)) 
				yhi = mpp.y; 
			if ((i == 0) || (mpp.z < zlo)) 
				zlo = mpp.z; 
			if ((i == 0) || (mpp.z > zhi)) 
				zhi = mpp.z; 
		
			mpa[i] = mpp; 
		}
	}
}

