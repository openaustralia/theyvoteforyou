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

import java.awt.Image;


/////////////////////////////////////////////
class radframe extends JFrame
{
	raddisplay raddisp;

	radframe() throws IOException
	{
		super("Ministerial roulette");
		setDefaultCloseOperation(EXIT_ON_CLOSE);
		setSize(800, 700);

		Image lblairimg = getToolkit().getImage("data/10047.jpg");
		raddisp = new raddisplay(lblairimg);
		raddisp.radpane.SetDate("1997-05-02", 50);
		getContentPane().add("Center", raddisp);
	}

	/////////////////////////////////////////////
	// startup the program
    // first parameter - mpcoords.txt file to load in
    // second parameter (optional) - filename of png to save to

	public static void main(String args[]) throws IOException
	{
		radframe radfram = new radframe();
		radfram.raddisp.LoadData(new BufferedReader(new FileReader(new File("data/ministers.xml"))));

		// used for making a snapshot of it
//			if (args.length > 1)
//				mpf.mpsc.pp.SavePNG(args[1], Integer.parseInt(args[2]), Integer.parseInt(args[3]));
//			else
		radfram.setVisible(true);
		radfram.raddisp.radpane.start();
	}
}

