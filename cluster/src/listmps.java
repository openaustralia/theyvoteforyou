// $Id: listmps.java,v 1.1 2003/08/14 19:35:48 frabcus Exp $

// The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.

////////////////////////////////////////////////////////////////////////////////
import java.io.File; 
import java.io.IOException;

import javax.swing.JPanel; 
import javax.swing.JScrollPane; 
import javax.swing.JList; 

import java.awt.Dimension;  
import java.awt.Color; 

import java.awt.Graphics; 
import java.awt.Graphics2D; 

import java.awt.Image; 

import java.awt.event.MouseListener; 
import javax.swing.event.ListSelectionListener; 
import javax.swing.event.ListSelectionEvent; 


//
//
//
//

/////////////////////////////////////////////
class listmps extends JScrollPane implements ListSelectionListener
{
	JList listall; 
	mparr ma; 
	plotpanel pp; 
	boolean bEnableSelectionEvents = true; 

	listmps() 
	{
	}

	void Init(mparr lma, plotpanel lpp) 
	{
		ma = lma; 
		pp = lpp; 

		listall = new JList(ma.mpa); 
		listall.addListSelectionListener(this); 

		getViewport().setView(listall); 
	}

	public void valueChanged(ListSelectionEvent e) 
	{
		if (bEnableSelectionEvents)  
		{
			for (int i = e.getFirstIndex(); i <= e.getLastIndex(); i++) 
				ma.mpa[i].bActive = listall.isSelectedIndex(i); 
			pp.repaint(); 
		}
	}
}
