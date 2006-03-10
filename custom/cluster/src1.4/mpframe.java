// $Id: mpframe.java,v 1.1 2006/03/10 16:49:06 frabcus Exp $

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

import java.awt.*;
import java.awt.image.*;
import javax.imageio.ImageIO; // Java 1.4 only.


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
	
	/** Uses 'pp' to construct an image and save it as a PNG file.
	 * Uses javax.imageio, so only works on Java 1.4. */
       public static void SavePNG(plotpanel pp, String filename, int w, int h)
        {
            // Draw image
            pp.csize = new Dimension(w,h);
            BufferedImage img = new BufferedImage(pp.csize.width, pp.csize.height, BufferedImage.TYPE_INT_RGB);
            Graphics gfx = img.getGraphics();
            pp.InitScale(); 
            pp.paintGraph(gfx); 

            // Save to disk
            try
            {
                ImageIO.write(img, "png", new File(filename));
            } catch(IOException ioe) {
                System.err.println("Error saving PNG");
                System.exit(1);
            }
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
				SavePNG(mpf.mpsc.pp, args[1], Integer.parseInt(args[2]), Integer.parseInt(args[3]));
			else
				mpf.setVisible(true); 
		}
		catch (IOException e)
		{
			System.exit(0); 
		}
	}
}
