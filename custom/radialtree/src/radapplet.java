// $Id: radapplet.java,v 1.3 2004/11/30 10:35:52 goatchurch Exp $

// The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.

////////////////////////////////////////////////////////////////////////////////
import java.io.File;
import java.io.IOException;

import javax.swing.JApplet;
import javax.swing.JPanel;
import javax.swing.JLabel;

import java.io.InputStreamReader;
import java.io.BufferedReader;

import radialtree.raddisplay;
import java.awt.Image;

import java.net.URL;


/////////////////////////////////////////////
public class radapplet extends JApplet
{
	// http://www.mythic-beasts.com/~julian/ministers.xml
	raddisplay raddisp;

	public radapplet()
	{
	}

    public void init()
	{
        //Get the applet parameters.
        String ministers = getParameter("ministers");
		System.out.println("ministersssssss " + ministers);
		String blairimg = getParameter("blairimg");

		try
		{
			Image lblairimg = getImage(getCodeBase(), blairimg);
			raddisp = new raddisplay(lblairimg);
			raddisp.radpane.SetDate(getParameter("startdate"), Integer.parseInt(getParameter("framemseconds")));

			getContentPane().add("Center", new JLabel("Loading: " + getCodeBase().toString() + ministers));
			getContentPane().repaint();
			BufferedReader br = new BufferedReader(new InputStreamReader(this.getClass().getResourceAsStream(ministers)));
			raddisp.LoadData(br);
			getContentPane().removeAll();
			getContentPane().add(raddisp);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			getContentPane().removeAll();
			getContentPane().add("Center", new JLabel("Data error", JLabel.CENTER));
		}
	}

    //Called to start the applet's execution.
    public void start()
	{
		raddisp.radpane.start();
    }

    public void stop()
	{
		raddisp.radpane.stop();
    }
}

