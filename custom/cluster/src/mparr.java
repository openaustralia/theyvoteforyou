// $Id: mparr.java,v 1.4 2006/07/31 23:27:51 frabcus Exp $

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
	mppos[] mpa; // the data.  
    boolean[] mpactive; // the active flags 
	
	double xlo, xhi; 
	double ylo, yhi; 
	double zlo, zhi; 

	double xeig; 
	double yeig; 
	double zeig; 
	
	// construct the data from a given buffer (online or in a file).  
	mparr(BufferedReader br, double ranfac) throws IOException
	{
		StreamTokenizer stoken = new StreamTokenizer(br); 
  		stoken.quoteChar('"'); 
		
		// get the number of MPs (and check it's within bounds).  
		if ((stoken.nextToken() != StreamTokenizer.TT_NUMBER) || (stoken.nval < 1)) 
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
		
		xeig = (xeig != 0.0 ? Math.sqrt(Math.abs(xeig)) : 0.0); 
		yeig = (yeig != 0.0 ? Math.sqrt(Math.abs(yeig)) : 0.0); 
		zeig = (zeig != 0.0 ? Math.sqrt(Math.abs(zeig)) : 0.0); 

		// measure the c of g of the parties.  
		double[] ptyx = new double[5]; 
		double[] ptyy = new double[5]; 
		int[] ptyn = new int[5]; 
		
		for (int i = 0; i < nmpa; i++) 
		{
			mppos mpp = new mppos(stoken, ranfac); 
			
			// factor in the eigenvalues 
			mpp.x *= xeig; 
			mpp.y *= yeig; 
			mpp.z *= zeig; 

			ptyx[mpp.partyid] += mpp.x; 
			ptyy[mpp.partyid] += mpp.y; 
			ptyn[mpp.partyid]++; 
			
			mpa[i] = mpp; 
		}

		// invert to put labour on the left 
		boolean bInvertx = (ptyx[0] * ptyn[1] > ptyx[1] * ptyn[0]); 
		boolean bInverty = ((ptyy[0] + ptyy[1]) * ptyn[2] < ptyy[2] * (ptyn[0] + ptyn[1])); 
		
		// invert and find the ranges
		for (int i = 0; i < nmpa; i++) 
		{
			mppos mpp = mpa[i]; 
			if (bInvertx) 
				mpp.x = -mpp.x; 
			if (bInverty) 
				mpp.y = -mpp.y; 
		}
		
		// it's still too jumpy.  normalize.  (keep the coding simple) 
		double xg = 0; 
		double yg = 0; 
		for (int i = 0; i < nmpa; i++) 
		{
			mppos mpp = mpa[i]; 
			xg += mpp.x; 
			yg += mpp.y; 
		}
		xg /= nmpa; 
		yg /= nmpa; 

        // variance  
		double vg = 0.0; 
		for (int i = 0; i < nmpa; i++) 
		{
			mppos mpp = mpa[i]; 
			double xd = mpp.x - xg; 
			double yd = mpp.y - yg; 
			vg += xd * xd + yd * yd; 
		}
		vg /= nmpa; 
        // System.out.println("Variance " + vg); 
		
		// normalize the points 
		for (int i = 0; i < nmpa; i++) 
		{
			mppos mpp = mpa[i]; 
			mpp.x = (mpp.x - xg) / vg; 
			mpp.y = (mpp.y - yg) / vg; 
		}
				
												
		// find the ranges  
		for (int i = 0; i < nmpa; i++) 
		{
			mppos mpp = mpa[i]; 
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
		}
	}
}

