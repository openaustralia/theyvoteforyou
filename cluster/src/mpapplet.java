// $Id: mpapplet.java,v 1.1 2003/08/14 19:35:48 frabcus Exp $

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

import java.io.FileReader;
import java.io.BufferedReader; 
import java.io.InputStreamReader; 


/////////////////////////////////////////////
public class mpapplet extends JApplet
{
	mpscatter mpsc; 

	public mpapplet()
	{
	}


    public void init() 
	{
		mpsc = new mpscatter(); 
		getContentPane().add("Center", mpsc); 

        //Get the applet parameters.
        String path = getParameter("posfile");
System.out.println("path " + path); 
		try
		{
			
			BufferedReader br = new BufferedReader(new InputStreamReader(this.getClass().getResourceAsStream(path))); 
			mpsc.LoadData(br); 
		}
		catch (IOException e)
		{
			getContentPane().removeAll(); 
			getContentPane().add("Center", new JLabel("Data error")); 
		}
	}

    //Called to start the applet's execution.
    public void start() 
	{
    }

    public void stop() 
	{
    }
}
