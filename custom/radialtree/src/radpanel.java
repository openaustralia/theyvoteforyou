// Copyright (C) 2004 Julian Todd
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
import java.awt.Font;

import java.io.File;
import javax.imageio.ImageIO;
import javax.swing.JLabel;

import java.text.SimpleDateFormat;
import java.util.Date; 

/////////////////////////////////////////////
class radpanel extends JPanel implements MouseListener, MouseMotionListener, Runnable
{
	Image offscreen;
    Dimension csize = new Dimension(1,1);
    Graphics offgraphics;

	Image blairimg;

	boolean bpositionsinvalid = true;
	ministertimes mintimes;
	personfloat personfactive = null;
	boolean bselectdept = false;
	boolean bmousedown = false;

	SimpleDateFormat formatter = new SimpleDateFormat("EEE d MMM yyyy");
	Date today = new Date();

	JLabel labeldate; // copied from the display panel above

	Thread animthread;

	// the fonts we draw the text in
	Font fontnormal;
	Font fontbold;
	FontMetrics fmnormal;
	FontMetrics fmbold;

	Color[] deptcols = { new Color(170, 0, 50),
						new Color(0, 30, 110),
						new Color(60, 130, 0),
						new Color(0, 0, 12),
					 } ;

	Color colseldept = new Color(200, 0, 0);

	/////////////////////////////////////////////
	radpanel()
	{
System.out.println(formatter.format(today));

		addMouseListener(this);
        addMouseMotionListener(this);
		//setCursor(new Cursor(Cursor.CROSSHAIR_CURSOR));
		blairimg = getToolkit().getImage("data/10047.jpg");
	}

	/////////////////////////////////////////////
    public void paintComponent(Graphics g)
	{
		// remake the image if necessary
		Dimension d = getSize();
		if ((offscreen == null) || (d.width != csize.width) || (d.height != csize.height))
		{
		    offscreen = createImage(d.width, d.height);
		    csize.width = d.width;
		    csize.height = d.height;
		    if (offgraphics != null)
		        offgraphics.dispose();
		    offgraphics = offscreen.getGraphics();

			fontnormal = g.getFont();
			fontbold = fontnormal.deriveFont(Font.BOLD);
			fmnormal = g.getFontMetrics();
			fmbold = g.getFontMetrics();

			mintimes.updateofficebioW(fmnormal);

		    bpositionsinvalid = true;
		}

		SetActives();
		paintW(offgraphics);
		paintWoverlay(offgraphics);

		g.drawImage(offscreen, 0, 0, null);
	}

	/////////////////////////////////////////////
	void SetActives()
	{
		for (int i = 0; i < mintimes.personfloats.length; i++)
		{
			personfloat personf = mintimes.personfloats[i];
			if (personf.rad == personfloat.outerrad)
				personf.displaycode = 0;
			else if (bselectdept && (personfactive != null) && personf.dept.equals(personfactive.dept))
				personf.displaycode = 2;
			else if (personf == personfactive)
				personf.displaycode = 3;
			else
				personf.displaycode = 1;
		}
	}

	/////////////////////////////////////////////
    public void paintW(Graphics g)
	{
		g.setColor(Color.lightGray);
		g.fillRect(0, 0, csize.width, csize.height);

		int lw = blairimg.getWidth(null);
		int lh = blairimg.getHeight(null);
		if ((lw != -1) && (lh != -1))
			g.drawImage(blairimg, (csize.width - lw) / 2, (csize.height - lh) / 2, Color.black, null);

		if (bpositionsinvalid)
		{
			int cr = Math.min(csize.width / 2, csize.height / 2);
			mintimes.updatepositionsW(csize.width / 2, csize.height / 2, cr, fmnormal);
			bpositionsinvalid = false;
		}

		// go through and paint everything
		g.setFont(fontnormal);
		for (int i = 0; i < mintimes.personfloats.length; i++)
		{
			personfloat personf = mintimes.personfloats[i];
			if (personf.displaycode == 1)
			{
				g.setColor(deptcols[personf.nontrivdeptfromend % deptcols.length]);
				g.drawString(personf.pname, personf.sx, personf.sy);
			}
		}
    }

	/////////////////////////////////////////////
    public void paintWoverlay(Graphics g)
	{
		g.setFont(fontbold);
		// now the overlaid stuff
		for (int i = 0; i < mintimes.personfloats.length; i++)
		{
			personfloat personf = mintimes.personfloats[i];
			if (personf.displaycode >= 2)
			{
				g.setColor(personf.displaycode == 2 ? colseldept : Color.black);
				g.drawString(personf.pname, personf.sx, personf.sy);
			}
		}

		// write in the department name
		if (bselectdept && (personfactive != null))
		{
			g.setColor(colseldept);
			g.drawString(personfactive.dept, (csize.width - fmbold.stringWidth(personfactive.dept)) / 2, csize.height - fmbold.getHeight() - 10);
		}

		// write in the bio text
		else if (personfactive != null)
		{
			g.setFont(fontnormal);
			g.setColor(Color.white);
			int rx = personfactive.sx - personfactive.maxdstringwidth / 2;
			int ry = personfactive.sy + fmnormal.getHeight() + 3;
			int rw = personfactive.maxdstringwidth;
			int rh = fmnormal.getHeight() * personfactive.officebio.length;

			if (rx < 3) 
				rx = 3; 
			if (rx + rw > csize.width - 3)
				rx = csize.width - 3 - rw;
			g.fillRect(rx - 3, ry - fmnormal.getAscent() - 3, rw + 6, rh + 6);

			g.setColor(Color.black);
			for (int i = 0; i < personfactive.officebio.length; i++)
				g.drawString(personfactive.officebio[i], rx, ry + i * fmnormal.getHeight());
		}
	}



	static int nyear = 1997;
	static int nmonth = 6;
	static int nday = 1;

	/////////////////////////////////////////////
	void AdvanceTime(boolean bforward, boolean bbyday)
	{
		if (bforward)
		{
			if (bbyday)
				nday++;
			if (!bbyday || (nday >= 32))
			{
				nmonth++;
				if (nmonth > 12)
				{
					nmonth = 1;
					nyear++;
				}
			}
		}
		else
		{
			if (bbyday)
				nday--;
			if (!bbyday || (nday <= 0))
			{
				nmonth--;
				if (nmonth <= 0)
				{
					nmonth = 12;
					nyear--;
				}
			}
		}

		String sdate = nyear + "-" + (nmonth < 10 ? "0" : "") + nmonth + "-" + (nday < 10 ? "0" : "") + nday;
		labeldate.setText(sdate);
		mintimes.AllocateSectors(sdate);
		repaint();
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
			{
				bpositionsinvalid = true;
				repaint();
			}
		    try
			{
				Thread.sleep(50);
		    }
			catch (InterruptedException e)
			{
				break;
		    }
		}
    }



	// http://www.publicwhip.org.uk/mp.php?id=uk.org.publicwhip/member/875
    // Mouse events
    public void mouseClicked(MouseEvent e)
	{
    }

    public void mousePressed(MouseEvent e)
	{
		personfloat ppersonfactive = personfactive;
		personfactive = mintimes.FindHit(e.getX(), e.getY());
		bselectdept = ((personfactive != null) && (personfactive != ppersonfactive));
		bmousedown = true;
		repaint();
	}

    public void mouseReleased(MouseEvent e)
	{
		bmousedown = false;
		repaint();
    }

    public void mouseEntered(MouseEvent e)
	{
    }

    public void mouseExited(MouseEvent e)
	{
    }

    public void mouseDragged(MouseEvent e)
	{
    }

    public void mouseMoved(MouseEvent e)
	{
    }
};

