// $Id: mppos.java,v 1.1 2003/08/14 19:35:48 frabcus Exp $

// The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.

/////////////////////////////////////////////
import java.io.IOException; 
import java.io.StreamTokenizer;


/////////////////////////////////////////////
class mppos
{
	int mpid; // links back into the database, also is the index in the array.  
	int partyid; // for drawing colour
	String name; // mp's name.  

	// multi-dimensional scaling position.  
	double x, y, z; 

	// maybe will list previous position, if we want to animate drift.  

	// could include other data, such as consitutency to, say, plot on a map.  

	// positions on the screen for picking purposes.  
	int ix, iy; 
	boolean bActive = false; 

	mppos(StreamTokenizer stoken, double ranfac) throws IOException  
	{
		// very strict routine.  
		if (stoken.nextToken() != StreamTokenizer.TT_NUMBER) 
			throw new IOException(); 
		mpid = (int)stoken.nval; 
		if (mpid != (int)stoken.nval) 
			throw new IOException(); 
		if (stoken.nextToken() != StreamTokenizer.TT_NUMBER) 
			throw new IOException(); 
		x = stoken.nval; 
		if (stoken.nextToken() != StreamTokenizer.TT_NUMBER) 
			throw new IOException(); 
		y = stoken.nval; 
		if (stoken.nextToken() != StreamTokenizer.TT_NUMBER) 
			throw new IOException(); 
		z = stoken.nval; 

		if (stoken.nextToken() != '"') 
			throw new IOException(); 
		name = stoken.sval.trim(); 
   		
		if (stoken.nextToken() != '"') 
			throw new IOException(); 
		String party = stoken.sval.trim(); 
		
		if (party.equals("Lab") || party.equals("Lab/Co-op"))
			partyid = 0; 
		else if (party.equals("Con"))
			partyid = 1; 
		else if (party.equals("LDem"))
			partyid = 2; 
		else 
			partyid = 3; 
								
		// add party tag 
		name = name + " (" + party + ")"; 
		
		// add random dither.  
		x += (Math.random() - 0.5) * ranfac; 
		y += (Math.random() - 0.5) * ranfac; 
	}

	public String toString() 
	{
		return name; 
	}
};


