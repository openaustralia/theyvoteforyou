// Copyright (C) 2004 Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.
////////////////////////////////////////////////////////////////////////////////
package radialtree;

import java.io.File;
import java.io.IOException;

import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JLabel;
import javax.swing.JButton;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import java.io.FileReader;
import java.io.BufferedReader;

import java.awt.BorderLayout;
import java.awt.FlowLayout;

import java.text.DateFormat;
import java.util.Date;

/////////////////////////////////////////////
public class raddisplay extends JPanel
{
	public radpanel radpane;

	JPanel lower = new JPanel(new FlowLayout());
	JButton bearliermonth = new JButton("Earlier Month");
	JButton bearlierday = new JButton("Earlier Day");
	JLabel labeldate = new JLabel("0000-00-00");
	JButton blaterday = new JButton("Later Day");
	JButton blatermonth = new JButton("Later Month");

	public raddisplay(String lblairimg) throws IOException
	{
		super(new BorderLayout());
		radpane = new radpanel(lblairimg);
		radpane.labeldate = labeldate;
		add("Center", radpane);

		bearliermonth.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.AdvanceTime(false, false); } } );
		lower.add(bearliermonth);
		bearlierday.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.AdvanceTime(false, true); } } );
		lower.add(bearlierday);

		lower.add(labeldate);

		blaterday.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.AdvanceTime(true, true); } } );
		lower.add(blaterday);
		blatermonth.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.AdvanceTime(true, false); } } );
		lower.add(blatermonth);

		add("South", lower);
	}

	/////////////////////////////////////////////
	public void LoadData(BufferedReader br) throws IOException
	{
		radpane.mintimes = new ministertimes(br);
		radpane.AdvanceTime(true, true);
	}
};


