// $Id: mpframe.java,v 1.3 2003/10/07 23:23:46 frabcus Exp $

// The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.

////////////////////////////////////////////////////////////////////////////////
import java.io.File; 
import java.io.IOException;

import javax.swing.JFrame;
import javax.swing.JPanel; 
import javax.swing.JTextField; 

import java.io.FileReader;
import java.io.BufferedReader; 

import java.util.Arrays; 

/////////////////////////////////////////////
class mpframe extends JFrame
{
	mpscatter mpsc; 

	mpframe()
	{
		super("MP scatter graph"); 
		setDefaultCloseOperation(EXIT_ON_CLOSE); 
		setSize(700, 400); 

		mpsc = new mpscatter(); 
		getContentPane().add("Center", mpsc); 
	}

	/////////////////////////////////////////////
	// startup the program
    // first parameter - mpcoords.txt file to load in
    // second parameter (optional) - filename of png to save to
	public static void main(String args[]) 
	{
		File[] coordfiles = null; 
		File f = new File(args.length >= 1 ? args[0] : "mpcoords.txt"); 
		if (f.isDirectory())
		{
			coordfiles = f.listFiles();
			Arrays.sort(coordfiles); 
		}
		else if (f.isFile())
		{
			coordfiles = new File[1]; 
			coordfiles[0] = f; 
		}
		else
		{
			System.out.println("Not a file or directory: " + f.toString()); 
			System.exit(0); 
		}
				
		try
		{
			mpframe mpf = new mpframe(); 
			mpf.mpsc.LoadData(coordfiles); 
			
			if (args.length > 1)
				mpf.mpsc.pp.SavePNG(args[1]);
			else
				mpf.show(); 
		}
		catch (IOException e)
		{
			System.exit(0); 
		}
	}
}
