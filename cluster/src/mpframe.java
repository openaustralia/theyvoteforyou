// $Id: mpframe.java,v 1.1 2003/08/14 19:35:48 frabcus Exp $

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
		try
		{
			BufferedReader br = new BufferedReader(new FileReader(args[0])); 
			mpframe mpf = new mpframe(); 
			mpf.mpsc.LoadData(br); 
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
