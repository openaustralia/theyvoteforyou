// Copyright (C) 2004 Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.
////////////////////////////////////////////////////////////////////////////////
package radialtree;

import java.io.File;
import java.io.IOException;

import javax.swing.JFrame;
import javax.swing.JPanel;

import java.io.FileReader;
import java.io.BufferedReader;


/////////////////////////////////////////////
class radframe extends JFrame
{
	raddisplay raddisp;

	radframe()
	{
		super("Ministerial roulette");
		setDefaultCloseOperation(EXIT_ON_CLOSE);
		setSize(800, 700);

		raddisp = new raddisplay();
		getContentPane().add("Center", raddisp);
	}

	/////////////////////////////////////////////
	// startup the program
    // first parameter - mpcoords.txt file to load in
    // second parameter (optional) - filename of png to save to

//http://www.theyworkforyou.com/images/mps/10186.jpg

	public static void main(String args[])
	{
		try
		{
			radframe radfram = new radframe();
			radfram.raddisp.LoadData("ministers.xml");

//			if (args.length > 1)
//				mpf.mpsc.pp.SavePNG(args[1], Integer.parseInt(args[2]), Integer.parseInt(args[3]));
			radfram.setVisible(true);
			radfram.raddisp.radpane.start();
		}
		catch (IOException e)
		{
			System.exit(0);
		}
	}
}

