// $Id: radapplet.java,v 1.1 2004/10/19 22:57:30 goatchurch Exp $

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
			raddisp = new raddisplay(blairimg);
			getContentPane().add("Center", raddisp);

			BufferedReader br = new BufferedReader(new InputStreamReader(this.getClass().getResourceAsStream(ministers)));
			raddisp.LoadData(br);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			getContentPane().removeAll();
			getContentPane().add("Center", new JLabel("Data error"));
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

