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
import java.awt.GridLayout;

import java.text.DateFormat;
import java.util.Date;

/////////////////////////////////////////////
public class raddisplay extends JPanel
{
	public radpanel radpane;


	JButton bgozero = new JButton("Day Zero");
	JButton bearliershuff = new JButton("Reshuffle <<");
	JButton bearliermonth = new JButton("Month <<");
	JButton bearlierday = new JButton("Day <<");
	JLabel labeldate = new JLabel("0000-00-00", JLabel.CENTER);
	JButton blaterday = new JButton(">> Day");
	JButton blatermonth = new JButton(">> Month");
	JButton blatershuff = new JButton(">> Reshuffle");
	JButton bgotoday = new JButton("Today");

	public raddisplay(String lblairimg, boolean bisurl) throws IOException
	{
		super(new BorderLayout());
		radpane = new radpanel(lblairimg, bisurl);
		radpane.labeldate = labeldate;
		add("Center", radpane);

		JPanel lower = new JPanel(new GridLayout(2, 7));

		// year zero
		bgozero.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.SetDate("1997-05-02", 0); radpane.AdvanceTime(0); } } );
		lower.add(bgozero);

		// earlier reshuffle
		bearliershuff.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.SetDate(radpane.mintimes.NextShuffFrom(radpane.sdate, false), 0); radpane.AdvanceTime(-1); } } );
		lower.add(bearliershuff);

		// middle spacing
		lower.add(new JLabel());
		lower.add(new JLabel());
		lower.add(new JLabel());

		// later reshuffle
		blatershuff.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.SetDate(radpane.mintimes.NextShuffFrom(radpane.sdate, true), 0); radpane.AdvanceTime(1); } } );
		lower.add(blatershuff);

		// go today
		bgotoday.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.SetDate(radpane.stoday, 0);  radpane.AdvanceTime(0); } } );
		lower.add(bgotoday);

		// second row

		lower.add(new JLabel());

		// earlier month
		bearliermonth.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.AdvanceTime(-30); } } );
		lower.add(bearliermonth);

		// earlier day
		bearlierday.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.AdvanceTime(-1); } } );
		lower.add(bearlierday);

		//lower.add(labeldate);
		lower.add(new JLabel(""));

		// later day
		blaterday.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.AdvanceTime(1); } } );
		lower.add(blaterday);

		// later month
		blatermonth.addActionListener(new ActionListener()
			{ public void actionPerformed(ActionEvent event) { radpane.AdvanceTime(30); } } );
		lower.add(blatermonth);

		lower.add(new JLabel());

		add("South", lower);
	}

	/////////////////////////////////////////////
	public void LoadData(BufferedReader br) throws IOException
	{
		radpane.mintimes = new ministertimes(br);
		radpane.AdvanceTime(0);
	}
};


