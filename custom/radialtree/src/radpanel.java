// Copyright (C) 2004 Martin Dunschen and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.
////////////////////////////////////////////////////////////////////////////////
package radialtree;

import java.io.File;
import java.io.IOException;

import javax.swing.JPanel;

import java.awt.Dimension;
import java.awt.Color;

import java.awt.Graphics;
import java.awt.Graphics2D;

import java.awt.Image;
import java.awt.image.BufferedImage;

import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.awt.event.MouseEvent;

import java.awt.Cursor;
import java.awt.FontMetrics;

import java.io.File;
import javax.imageio.ImageIO;

/////////////////////////////////////////////
class radpanel extends JPanel implements MouseListener, MouseMotionListener, Runnable
{
	Image offscreen;
    Dimension csize = new Dimension(1,1);
    Graphics offgraphics;

	Image louiseimg;
	ministertimes mintimes;

	Thread animthread;


	/////////////////////////////////////////////
	radpanel()
	{
		addMouseListener(this);
        addMouseMotionListener(this);
		//setCursor(new Cursor(Cursor.CROSSHAIR_CURSOR));

		louiseimg = getToolkit().getImage("data/10186.jpg");
	}

	/////////////////////////////////////////////
    public void paintComponent(Graphics g)
	{
		// remake the image if necessary
		Dimension d = getSize();
		if ((offscreen == null) || (d.width != csize.width) || (d.height != csize.height))
		{
		    offscreen = createImage(d.width, d.height);
		    csize = d;
		    if (offgraphics != null)
		        offgraphics.dispose();
		    offgraphics = offscreen.getGraphics();
		    offgraphics.setFont(getFont());
		}

		paintW(offgraphics);
		g.drawImage(offscreen, 0, 0, null);
	}

	/////////////////////////////////////////////
    public void paintW(Graphics g)
	{
		g.setColor(Color.lightGray);
		g.fillRect(0, 0, csize.width, csize.height);

		g.drawImage(louiseimg, csize.width / 2, csize.height / 2, Color.black, null);
		int cr = Math.min(csize.width / 2, csize.height / 2);
		mintimes.paintW(g, csize.width / 2, csize.height / 2, cr);
    }

	static int nyear = 1997;
	static int nmonth = 6;

	/////////////////////////////////////////////
	void NextTime()
	{
		nmonth++;
		if (nmonth > 12)
		{
			nmonth = 1;
			nyear++;
		}
		String sdate = nyear + "-" + (nmonth < 10 ? "0" : "") + nmonth;
		System.out.println(sdate);
		mintimes.AllocateSectors(sdate);
		repaint();
	}

	/////////////////////////////////////////////
    public void LoadData(String sministers) throws IOException
	{
		mintimes = new ministertimes(new File("data/ministers.xml"));
		NextTime();
	}

	/////////////////////////////////////////////
    public void start()
	{
		animthread = new Thread(this);
		animthread.start();
    }

    public void stop()
	{
		animthread = null;
    }

    public void run()
	{
        Thread me = Thread.currentThread();
		while (animthread == me)
		{
			// do something
			if (mintimes.GoCloser())
				repaint();
		    try
			{
				Thread.sleep(100);
		    }
			catch (InterruptedException e)
			{
				break;
		    }
		}
    }



    // Mouse events
    public void mouseClicked(MouseEvent e)
	{
		NextTime();
    }

    public void mousePressed(MouseEvent e)
	{
	}

    public void mouseReleased(MouseEvent e)
	{
    }

    public void mouseEntered(MouseEvent e)
	{
    }

    public void mouseExited(MouseEvent e)
	{
    }

    public void mouseDragged(MouseEvent e)
	{
		int x = e.getX();
		int y = e.getY();
    }

    public void mouseMoved(MouseEvent e)
	{
    }
};

