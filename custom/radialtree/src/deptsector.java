// Copyright (C) 2004 Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.
////////////////////////////////////////////////////////////////////////////////
package radialtree;

import java.io.File;
import java.io.IOException;

import javax.swing.JPanel;

import java.io.FileReader;
import java.io.BufferedReader;
import java.io.StreamTokenizer;

import java.awt.Dimension;
import java.awt.Color;
import java.awt.FontMetrics;

import java.awt.Graphics;
import java.awt.Graphics2D;

import java.io.File;
import javax.imageio.ImageIO;

import java.util.Vector;


/////////////////////////////////////////////
class deptsector
{
	String dept;
	Vector[] vranks = new Vector[4];

	double sang0;
	double sang1;
	int nontrivfromend; // incremented for each one from top that's non-zero width


	/////////////////////////////////////////////
	void clear()
	{
		for (int i = 0; i < vranks.length; i++)
			vranks[i].clear();
	}

	/////////////////////////////////////////////
	deptsector(String ldept)
	{
		dept = ldept;
		for (int i = 0; i < vranks.length; i++)
			vranks[i] = new Vector();
	}

	/////////////////////////////////////////////
	double GetWidth()
	{
		int aw = 0;
		for (int rank = 1; rank < vranks.length; rank++)
			aw = Math.max(aw, vranks[rank].size());
		return aw;
	}

	/////////////////////////////////////////////
	void AllocateGo(double lang0, double lang1)
	{
		sang0 = lang0;
		sang1 = lang1;

		for (int rank = 1; rank < vranks.length; rank++)
		{
			double rad = rank;
			for (int p = 0; p < vranks[rank].size(); p++)
			{
				personfloat personf = (personfloat)(vranks[rank].elementAt(p));
				double al = (p + 0.5) / vranks[rank].size();
				personf.gosang = sang0 * (1.0 - al) + sang1 * al;
				personf.gorad = rad;
				personf.nontrivdeptfromend = nontrivfromend; 
			}
		}
	}
};


