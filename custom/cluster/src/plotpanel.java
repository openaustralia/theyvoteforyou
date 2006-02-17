// $Id: plotpanel.java,v 1.2 2006/02/17 19:32:06 frabcus Exp $

// The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.

////////////////////////////////////////////////////////////////////////////////
import java.io.File; 
import java.io.IOException;

import javax.swing.JPanel; 
import javax.swing.JRadioButton; 
import javax.swing.ButtonGroup; 

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

//
//
//
//

/////////////////////////////////////////////
class plotpanel extends JPanel implements MouseListener, MouseMotionListener 
{
	Image offscreen;
    Dimension csize = new Dimension(1,1);
    Graphics offgraphics;

	mparr ma = null; 
	listmps lm = null; 
	
	// font sizes
	int fmascent = -1; 
	int fmdescent = -1; 

	
	double cenx, ceny; 
	double sca; 

	JRadioButton cbdrag = new JRadioButton("Drag", true); 
	JRadioButton cbzoom = new JRadioButton("Zoom", false); 
	JRadioButton cbsel = new JRadioButton("Select", false); 

	Color[] partycols = { Color.red, Color.blue, Color.yellow, Color.green, Color.white }; 
	Color backgnd = new Color(99, 99, 99); 


	// mouse interface.  
	double oldcenx; 
	double oldceny; 
	double oldsca; 
	int downx; 
	int downy; 

	int rdiam = 6; // size of the rectangle 
	int rsdiam = 8; // size of the selected rectangle 
	int cdiam = 16; // size of the select circle.  

	int motiontype = 0; // 1 drag, 2 zoom, 3 select.  


	/////////////////////////////////////////////
	plotpanel() 
	{
		addMouseListener(this); 
        addMouseMotionListener(this);
		setCursor(new Cursor(Cursor.CROSSHAIR_CURSOR)); 
	}

	/////////////////////////////////////////////
	void InitScale()
	{
		cenx = (ma.xlo + ma.xhi) / 2; 
		ceny = (ma.ylo + ma.yhi) / 2; 
		sca = Math.min(csize.width / (ma.xhi - ma.xlo), csize.height / (ma.yhi - ma.ylo)); 
		sca *= 0.9;
		repaint(); 
	}


	/////////////////////////////////////////////
	void SetFM(Graphics g)
	{
		FontMetrics fm = g.getFontMetrics(); 
		fmascent = fm.getAscent() - 5; 
		fmdescent = fm.getDescent(); 
		for (int i = 0 ; i < ma.mpa.length ; i++) 
			ma.mpa[i].charwid = fm.stringWidth(ma.mpa[i].name); 
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

			if (ma != null) 
				InitScale(); 
		}

		if (motiontype != 3)
			paintGraph(offgraphics); 
		g.drawImage(offscreen, 0, 0, null); 

		// draw the select circle onto the screen 
		if (motiontype == 3)
		{
			g.setColor(Color.white); 
			g.drawArc(downx - cdiam / 2, downy - cdiam / 2, cdiam, cdiam, 0, 360); 
		}


		// paint the selection 
		g.setColor(Color.white); 
		if (fmascent == -1) 
			SetFM(g); 
		for (int i = 0 ; i < ma.mpa.length ; i++) 
		{
			if (ma.mpactive[i]) 
			{
				g.setColor(Color.black); 
				g.drawRect(ma.mpa[i].ix - rsdiam / 2 - 1, ma.mpa[i].iy - rsdiam / 2 - 1, rsdiam + 2, rsdiam + 2); 
				g.fillRect(ma.mpa[i].ix + rsdiam / 2 + 3, ma.mpa[i].iy - fmascent - 1, ma.mpa[i].charwid, fmascent + fmdescent + 2); 
				
				g.setColor(Color.white); 
				g.fillRect(ma.mpa[i].ix - rsdiam / 2, ma.mpa[i].iy - rsdiam / 2, rsdiam, rsdiam); 
				g.drawString(ma.mpa[i].name, ma.mpa[i].ix + rsdiam / 2 + 3, ma.mpa[i].iy); 
			}
	    }
	}

        public void SavePNG(String filename, int w, int h)
        {
            // Draw image
            csize = new Dimension(w,h);
            BufferedImage img = new BufferedImage(csize.width, csize.height, BufferedImage.TYPE_INT_RGB);
            Graphics gfx = img.getGraphics();
            InitScale(); 
            paintGraph(gfx); 

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
    public void paintGraph(Graphics g) 
	{
		g.setColor(backgnd);
		g.fillRect(0, 0, csize.width, csize.height);

		if (ma == null) 
			return; 

		for (int i = 0 ; i < ma.mpa.length ; i++) 
		{
			g.setColor(partycols[Math.min(ma.mpa[i].partyid, partycols.length - 1)]); 

			ma.mpa[i].ix = (int)((ma.mpa[i].x - cenx) * sca + csize.width / 2); 
			ma.mpa[i].iy = (int)((ma.mpa[i].y - ceny) * sca + csize.height / 2); 
			g.fillRect(ma.mpa[i].ix - rdiam / 2, ma.mpa[i].iy - rdiam / 2, rdiam, rdiam); 
	    }
    }

	void MakeSelection()
	{
//		lm.bEnableSelectionEvents = false; 
		int nsel = 0; // annoying interface which means we can select only as batch.  
		for (int i = 0 ; i < ma.mpa.length ; i++) 
		{
			int dx = ma.mpa[i].ix - downx; 
			int dy = ma.mpa[i].iy - downy; 
			int dsq = dx * dx + dy * dy; 

			ma.mpactive[i] = (dsq < rsdiam * rsdiam); 
			if (ma.mpactive[i]) 
				nsel++; 
	    }
		if (nsel == 0) 
			lm.listall.clearSelection(); 
		else 
		{
			int[] indices = new int[nsel]; 
			int j = 0; 
			for (int i = 0 ; i < ma.mpa.length ; i++) 
			{
				if (ma.mpactive[i]) 
				{
					indices[j] = i; 
					j++; 
				}
			}
			lm.listall.setSelectedIndices(indices); 
			lm.listall.ensureIndexIsVisible(indices[0]); 
		}

//		lm.bEnableSelectionEvents = true; 
	}



    // Mouse events  
    public void mouseClicked(MouseEvent e) 
	{
    }

    public void mousePressed(MouseEvent e) 
	{
		downx = e.getX(); 
		downy = e.getY(); 

		oldcenx = cenx; 
		oldceny = ceny; 
		oldsca = sca; 

		if (cbdrag.isSelected()) 
			motiontype = 1; 
		else if (cbzoom.isSelected()) 
			motiontype = 2; 
		else if (cbsel.isSelected()) 
		{
			motiontype = 3; 
			MakeSelection(); 
			repaint(); 
		}
	}

    public void mouseReleased(MouseEvent e) 
	{
		motiontype = 0; 
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
		int x = e.getX(); 
		int y = e.getY(); 

		if (motiontype == 1) 
		{
			cenx = oldcenx - (x - downx) / sca; 
			ceny = oldceny - (y - downy) / sca; 
			
			repaint(); 
		}

		else if (motiontype == 2) 
		{
			double relsca = (Math.abs(x - downx) * 3.0 / csize.width) + 1; 
			if (x < downx) 
				relsca = 1 / relsca; 
			
			sca = oldsca * relsca; 
			cenx = oldcenx + (downx - csize.width / 2) / sca * (relsca - 1); 
			ceny = oldceny + (downy - csize.height / 2) / sca * (relsca - 1); 
			
			repaint(); 
		}

		else if (motiontype == 3) 
		{
			downx = x; 
			downy = y; 
			MakeSelection(); 
			repaint(); 
		}
    }

    public void mouseMoved(MouseEvent e) 
	{
    }
}




