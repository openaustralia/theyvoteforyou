// $Id: mpscatter.java,v 1.1 2003/08/14 19:35:48 frabcus Exp $

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
	// the array of mps
	mparr ma; 
	plotpanel pp; 
	listmps lm; 

	/////////////////////////////////////////////
	//	SpiralPanel spiralpanel; 

	
	/////////////////////////////////////////////
	/////////////////////////////////////////////
	mpscatter()
	{
		// put top panes into frame.  
		pp = new plotpanel(); 
		lm = new listmps(); 
		pp.lm = lm; 

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

		JSplitPane spane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT); 
		spane.setLeftComponent(pp); 
		spane.setRightComponent(lm); 
        spane.setDividerLocation(500); 
		
		setLayout(new BorderLayout()); 
		add("Center", spane); 
		add("South", brow); 
	}



	/////////////////////////////////////////////
	void LoadData(BufferedReader br) throws IOException  
	{
		ma = new mparr(br); 
		pp.ma = ma; 
		lm.Init(ma, pp); 
		pp.InitScale(); 
	}
}; 


