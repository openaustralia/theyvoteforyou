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
import javax.swing.JLabel;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Calendar;
import java.util.GregorianCalendar;

import java.net.URL;


/////////////////////////////////////////////
public class radpanel extends JPanel implements MouseListener, MouseMotionListener, Runnable
{
	Image offscreen;
    Dimension csize = new Dimension(1,1);
    Graphics offgraphics;

	String[] PMnames = { "Tony Blair", "Gordon Brown", };
	Image[] PMimgs = new Image[2];

	boolean bpositionsinvalid = true;
	ministertimes mintimes;
	personfloat personfactive = null;
	boolean bselectdept = false;
	boolean bmousedown = false;
	boolean bdisplaybio = false;

	SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd");
	SimpleDateFormat longformatter = new SimpleDateFormat("d MMMM yyyy (EEEE)");

	String sstartdate = "1997-05-02";
	String stoday;

	JLabel labeldate; // copied from the display panel above
	String sdate;   	// displayed date
	String sdatelong;

	Thread animthread;

	// the fonts we draw the text in
	Font fontnormal;
	Font fontbold;
	Font fontlarge;
	FontMetrics fmnormal;
	FontMetrics fmbold;
	FontMetrics fmlarge;

	Color[] deptcols = { new Color(230, 0, 0),
						new Color(0, 30, 210),
						new Color(20, 200, 0),
						new Color(0, 0, 12),
						new Color(150, 150, 12),
						new Color(1, 150, 160),
						new Color(140, 1, 160),
					 } ;


	/////////////////////////////////////////////
	radpanel(String lstoday, Image lblairimg, Image lbrownimg) throws IOException
	{
		stoday = lstoday;

		addMouseListener(this);
        addMouseMotionListener(this);
		//System.out.println(stoday);

		PMimgs[0] = lblairimg;
		PMimgs[1] = lbrownimg;
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
			fontlarge = fontnormal.deriveFont(fontnormal.getSize() * 1.5F);

			fmnormal = g.getFontMetrics();
			g.setFont(fontbold);
			fmbold = g.getFontMetrics();
			g.setFont(fontlarge);
			fmlarge = g.getFontMetrics();

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
	int bljit = 0;
	boolean bPMjit = true;
	int blw = -1;
	int blh = -1;
    public void paintW(Graphics g)
	{
		g.setColor(Color.white);
		g.fillRect(0, 0, csize.width, csize.height);
		g.setColor(Color.black);
		g.drawRect(0, 0, csize.width - 1, csize.height - 1);


		// draw any pictures
		for (int i = 0; i < mintimes.personfloats.length; i++)
		{
			personfloat personf = mintimes.personfloats[i];
			if (personf.rad != 0.0)
				continue;
			Image img = null;
			for (int j = 0; j < PMnames.length; j++)
				if (personf.pname.equals(PMnames[j]))
					img = PMimgs[j];
			if (img == null)
				continue;
			blw = img.getWidth(null);
			blh = img.getHeight(null);
			if ((blw == -1) || (blh == -1))
				continue;
			int blx = (csize.width - blw) / 2;
			int bly = (csize.height - blh) / 2;
			if (bPMjit)
			{
				blx += ((bljit & 1) == 0 ? 1 : -1);
				bly += (((bljit + 3) & 2) == 0 ? 1 : -1);
				bljit++;
			}
			g.drawImage(img, blx, bly, Color.black, null);
			personf.displaycode = 0;
		}

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

	Color biobcol = new Color(0.8F, 0.8F, 1.0F);
	Color deptbcol = new Color(1.0F, 0.9F, 0.9F);
	Color colseldept = new Color(0.4F, 0.1F, 0.0F);
	int biobpoff = 3;
	int biobpwhoz = 3;
	/////////////////////////////////////////////
    public void paintWoverlay(Graphics g)
	{
		// now the overlaid stuff
		if (bselectdept)
		{
			// draw the backgrounds
			g.setColor(deptbcol);
			for (int i = 0; i < mintimes.personfloats.length; i++)
			{
				personfloat personf = mintimes.personfloats[i];
				if (personf.displaycode == 2)
					g.fillRect(personf.sx - biobpoff, personf.sy - fmbold.getAscent() - biobpoff, fmbold.stringWidth(personf.pname) + biobpoff * 2, fmbold.getHeight() + biobpoff * 2);
			}

			// draw the names
			g.setColor(colseldept);
			g.setFont(fontbold);
			for (int i = 0; i < mintimes.personfloats.length; i++)
			{
				personfloat personf = mintimes.personfloats[i];
				if (personf.displaycode == 2)
					g.drawString(personf.pname, personf.sx, personf.sy);
			}
		}

		// write the date
		int sdwid = fmlarge.stringWidth(sdatelong);
		int sdheg = fmlarge.getHeight();
		int sdx = (csize.width - sdwid) / 2;
		int sdy = csize.height - sdheg - 10;
		g.setColor(biobcol);
		g.fillRect(sdx - biobpoff, sdy - fmlarge.getAscent() - biobpoff, sdwid + biobpoff * 2, sdheg + biobpoff * 2);
		g.setColor(Color.blue);
		g.drawRect(sdx - biobpoff, sdy - fmlarge.getAscent() - biobpoff, sdwid + biobpoff * 2, sdheg + biobpoff * 2);
		g.setFont(fontlarge);
		g.setColor(Color.black);
		g.drawString(sdatelong, sdx, sdy);


		// write in the department name
		if (bselectdept && (personfactive != null))
		{
			g.setColor(deptbcol);
			int depwid = fmlarge.stringWidth(personfactive.dept);
			int depx = (csize.width - depwid) / 2;
			int depy = fmlarge.getHeight() + 10;
			g.fillRect(depx - biobpoff, depy - fmlarge.getAscent() - biobpoff, depwid + biobpoff * 2, fmlarge.getHeight() + biobpoff * 2);

			g.setFont(fontlarge);
			g.setColor(colseldept);
			g.drawString(personfactive.dept, depx, fmlarge.getHeight() + 10);
		}

		// write in the bio text
		else if ((personfactive != null) && bdisplaybio)
		{
			g.setColor(biobcol);
			g.fillRect(personfactive.sx - biobpoff, personfactive.sy - fmbold.getAscent() - biobpoff, fmbold.stringWidth(personfactive.pname) + biobpoff * 2, fmbold.getHeight() + biobpoff * 2);
			g.setColor(Color.black);
			g.setFont(fontbold);
			g.drawString(personfactive.pname, personfactive.sx, personfactive.sy);

			g.setFont(fontnormal);
			g.setColor(biobcol);
			int rx = personfactive.sx - personfactive.maxdstringwidth / 2;
			int ry = personfactive.sy + fmnormal.getHeight() + 3;
			int rw = personfactive.maxdstringwidth;
			int rh = fmnormal.getHeight() * personfactive.officebio.length;

			if (rx < biobpoff + biobpwhoz)
				rx = biobpoff + biobpwhoz;
			if (rx + rw > csize.width - (biobpoff + biobpwhoz))
				rx = csize.width - (biobpoff + biobpwhoz) - rw;
			g.fillRect(rx - biobpoff, ry - fmnormal.getAscent() - biobpoff, rw + biobpoff * 2, rh + biobpoff * 2);
			g.setColor(Color.blue);
			g.drawRect(rx - biobpoff, ry - fmnormal.getAscent() - biobpoff, rw + biobpoff * 2, rh + biobpoff * 2);

			g.setColor(Color.black);
			for (int i = 0; i < personfactive.officebio.length; i++)
				g.drawString(personfactive.officebio[i], rx, ry + i * fmnormal.getHeight());
		}
	}


	public int framemseconds = 50;

	int nyear = 1999;
	int nmonth = 9;
	int nday = 3;
	Calendar ncaldate = new GregorianCalendar();

	/////////////////////////////////////////////
	public void SetDate(String lsdate)
	{
		sdate = lsdate; 
		try
		{
			nyear = Integer.parseInt(sdate.substring(0, 4));
			nmonth = Integer.parseInt(sdate.substring(5, 7));
			nday = Integer.parseInt(sdate.substring(8, 10));
			ncaldate.set(nyear, nmonth - 1, nday);
		}
		catch (Exception e)
		{
			System.out.println("date not in yyy-mm-dd form.");
		}
	}


	/////////////////////////////////////////////
	// a month means 30 days
	// a year means 300 days
	void AdvanceTime(int ndays)
	{
		if (Math.abs(ndays) == 1)
			ncaldate.add(Calendar.DATE, ndays);
		if (Math.abs(ndays) == 30)
			ncaldate.add(Calendar.MONTH, ndays / 30);
		if (Math.abs(ndays) == 300)
			ncaldate.add(Calendar.YEAR, ndays / 300);

		sdate = formatter.format(ncaldate.getTime());
		if (sdate.compareTo(stoday) > 0)
			SetDate(stoday);
		if (sdate.compareTo(sstartdate) < 0)
			SetDate(sstartdate);

		sdatelong = longformatter.format(ncaldate.getTime());
		labeldate.setText(sdate);
		mintimes.AllocateSectors(sdate);

		if (bdisplaybio)
		{
			 bdisplaybio = false;
			 bselectdept = true;
		}
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
				Thread.sleep(framemseconds);
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
		bdisplaybio = ((personfactive != null) && !bselectdept);
		repaint();

		if ((Math.abs(csize.width / 2 - e.getX()) < 10) && (Math.abs(csize.height / 2 - e.getY()) < 10))
			bPMjit = !bPMjit;
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

