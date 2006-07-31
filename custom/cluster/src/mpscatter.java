// $Id: mpscatter.java,v 1.4 2006/07/31 23:27:51 frabcus Exp $

// The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.

////////////////////////////////////////////////////////////////////////////////
import java.io.File; 
import java.io.IOException;
import java.util.Vector;

import javax.swing.ButtonGroup;
import javax.swing.JFrame;
import javax.swing.JPanel; 
import javax.swing.JLabel; 
import javax.swing.JTextField; 

import javax.swing.JSplitPane; 


import java.awt.BorderLayout; 
import java.awt.FlowLayout; 

import javax.swing.JCheckBox; 
import javax.swing.JButton; 
import javax.swing.JSlider; 
import javax.swing.event.ChangeListener; 
import javax.swing.event.ChangeEvent; 

import java.awt.event.ActionEvent; 
import java.awt.event.ActionListener; 

import java.awt.geom.Rectangle2D;  

import java.awt.event.ActionEvent; 
import java.awt.event.ActionListener; 

import java.awt.Image; 
import java.awt.image.BufferedImage;

import java.io.FileReader;
import java.io.BufferedReader; 
import java.io.StreamTokenizer;

import java.awt.Dimension;  

//
//
//
//

/////////////////////////////////////////////
class mpscatter extends JPanel
{
	double ranfac = 0.0005; 
	
	// the array of mps
	mparr ma; 
	mparr[] maseq; // sequence of arrays.  
	boolean[] mpactive; 
	JSlider seqslide = null; 
		
	plotpanel pp; 
	listmps lm; 

	/////////////////////////////////////////////
	//	SpiralPanel spiralpanel; 

	
	/////////////////////////////////////////////
	/////////////////////////////////////////////
	mpscatter()
	{
	}		
		
	
	/////////////////////////////////////////////
	void Construct() 
	{
		// put top panes into frame.  
		pp = new plotpanel(); 
		lm = new listmps(); 
		pp.lm = lm; 
		ma.mpactive = new boolean[ma.mpa.length]; 
        //System.out.println("maseq l " + maseq.length); 
		for (int i = 0; i < maseq.length; i++) 
			maseq[i].mpactive = ma.mpactive; 
	
		setSize(700, 400); 
		pp.setPreferredSize(new Dimension(500, 400)); 
		//	lm.setPreferredSize(new Dimension(200, 400)); // seems to cause it to squash up badly.  

 		// buttons 
		JPanel brow = new JPanel(); 

		ButtonGroup bg = new ButtonGroup(); 
		bg.add(pp.cbdrag); 
		bg.add(pp.cbzoom); 
		bg.add(pp.cbsel); 

		brow.setLayout(new FlowLayout(FlowLayout.CENTER));
		brow.add(pp.cbdrag); 
		brow.add(pp.cbzoom); 
		brow.add(pp.cbsel); 

		JButton buttReset = new JButton("Reset"); 
		buttReset.addActionListener(new ActionListener() 
			{ public void actionPerformed(ActionEvent event) { pp.InitScale(); } } ); 
		brow.add(buttReset); 

/*JButton buttNEXT = new JButton("Next"); 
buttNEXT.addActionListener(new ActionListener() 
	{ public void actionPerformed(ActionEvent event) { s++; 
	pp.ma = maseq[s]; pp.InitScale(); } 
} ); 
brow.add(buttNEXT); 
*/		
		JPanel vp = new JPanel(new BorderLayout()); 
		vp.add("Center", pp); 
		if (maseq.length > 1) 
		{
			seqslide = new JSlider(0, maseq.length - 1, 0); 
        	vp.add("South", seqslide); 
			seqslide.addChangeListener(new ChangeListener() 
				{ public void stateChanged(ChangeEvent e) 
					{ pp.ma = maseq[seqslide.getValue()]; 
					  pp.repaint(); //pp.InitScale(); 
					}
				} ); 
   		}
				
		JSplitPane spane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT); 
		spane.setLeftComponent(vp); 
		
		spane.setRightComponent(lm); 
        spane.setDividerLocation(500); 
		
		setLayout(new BorderLayout()); 
		add("Center", spane); 
		add("South", brow); 
	}


	/////////////////////////////////////////////
	void LoadData(BufferedReader br) throws IOException  
	{
		maseq = new mparr[1]; 
		maseq[0] = new mparr(br, ranfac);  
		ma = maseq[0]; 
		Construct(); 
		
		pp.ma = ma; 
		lm.Init(ma, pp); 
		pp.InitScale(); 
	}
		
	/////////////////////////////////////////////
	void LoadData(File[] coordfiles) throws IOException  
	{
		maseq = new mparr[coordfiles.length]; 
		for (int i = 0; i < coordfiles.length; i++) 
		{
			BufferedReader br = new BufferedReader(new FileReader(coordfiles[i])); 
			maseq[i] = new mparr(br, 0.0);  
        	br.close(); 
		}
				
		ma = maseq[0]; 
		Construct(); 
		
		pp.ma = ma; 
		lm.Init(ma, pp); 
		pp.InitScale(); 
	}
}; 


