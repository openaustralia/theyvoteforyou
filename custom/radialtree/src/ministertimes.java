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

import java.util.Vector;



/////////////////////////////////////////////
class ministertimes
{
	personfloat[] personfloats;
	Color[] rankcol = { new Color(0, 0, 0), new Color(0, 0, 40), new Color(0, 0, 80), new Color(0, 0, 120), new Color(0, 0, 160) } ;


	deptsector[] depts;
	Color[] coltimeserved = new Color[80];


	// load the data from the structured xml file
	// using very primitive parsing technology
	ministertimes(BufferedReader br) throws IOException
	{
		// set the colours
		for (int i = 0; i < coltimeserved.length; i++)
			coltimeserved[i] = new Color(i * 2, 0, 0);

		// load the ministers.xml data
		personfloats = loaddat.LoadMinisters(br);

		// make list of departments
		depts = loaddat.ExtractDepts(personfloats);
	}


	/////////////////////////////////////////////
	// allocate sectors and positions (in polar coordinates)
	String NextShuffFrom(String sdate, boolean bFore)
	{
		String rdate = "";
		for (int i = 0; i < personfloats.length; i++)
		{
			personfloat personf = personfloats[i];
			for (int j = 0; j < personf.npoffices; j++)
			{
				// j = personf.GetMIndex(sdate)
				if (bFore)
				{
					String ndate = personf.poffices[j].stopdate;
					if ((ndate.compareTo(sdate) >= 0) && (rdate.equals("") || (ndate.compareTo(rdate) <= 0)))
						rdate = ndate;
					ndate = personf.poffices[j].startdate;
					if ((ndate.compareTo(sdate) >= 0) && (rdate.equals("") || (ndate.compareTo(rdate) <= 0)))
						rdate = ndate;
				}
				else
				{
					String ndate = personf.poffices[j].stopdate;
					if ((ndate.compareTo(sdate) <= 0) && (rdate.equals("") || (ndate.compareTo(rdate) >= 0)))
						rdate = ndate;
					ndate = personf.poffices[j].startdate;
					if ((ndate.compareTo(sdate) <= 0) && (rdate.equals("") || (ndate.compareTo(rdate) >= 0)))
						rdate = ndate;
				}
			}
		}

		return (rdate.startsWith("9999") || rdate.equals("") ? sdate : rdate);
	}

	/////////////////////////////////////////////
	// allocate sectors and positions (in polar coordinates)
	void AllocateSectors(String sdate)
	{
		// find the departments
		for (int i = 0; i < depts.length; i++)
			depts[i].clear();
		for (int i = 0; i < personfloats.length; i++)
		{
			personfloat personf = personfloats[i];
        	if (personf.SetDate(sdate))
			{
				// add it in
				int d = 0;
				for ( ; d < depts.length; d++)
				{
					if (personf.dept.equals(depts[d].dept))
						break;
				}
				if (personf.rank != -1)
					depts[d].vranks[personf.rank].addElement(personf);
			}
		}


		// find the halfway department
		double sumL = 0.0;
		double sumR = 0.0;
		int d0 = 0;
		int d1 = depts.length - 1;
		while (d0 <= d1)
		{
			if (sumL < sumR)
			{
				sumL += depts[d0].GetWidth();
				d0++;
			}
			else
			{
				sumR += depts[d1].GetWidth();
				d1--;
			}
		}

		// now allocate the sectors for each
		int nontrivcounter = 0;
		double lsumL = 0.0;
		for (int i = 0; i < d0; i++)
		{
			double wid = depts[i].GetWidth();
			depts[i].nontrivfromend = (wid != 0.0 ? nontrivcounter++ : -1);
			double nsumL = lsumL + wid;

			double ang0 = lsumL / sumL;
			double ang1 = nsumL / sumL;
//			depts[i].AllocateGo(ang0 + 2, ang1 + 2);
			depts[i].AllocateGo(ang0, ang1);

			lsumL = nsumL;
		}

		double lsumR = 0.0;
		for (int i = d0; i < depts.length; i++)
		{
			double wid = depts[i].GetWidth();
			depts[i].nontrivfromend = (wid != 0.0 ? nontrivcounter++ : -1);
			double nsumR = lsumR + wid;

			double ang0 = lsumR / sumR;
			double ang1 = nsumR / sumR;
//			depts[i].AllocateGo(ang1, ang0);
			depts[i].AllocateGo(ang1 + 2, ang0 + 2);

			lsumR = nsumR;
		}
	}


	static double radrate = 0.08;
	static double angrate = 0.04;

	/////////////////////////////////////////////
	boolean GoCloser()
	{
		boolean bres = false;
		for (int i = 0; i < personfloats.length; i++)
		{
			personfloat personf = personfloats[i];
			if (((personf.rad != personf.gorad) || (personf.sang != personf.gosang)))
			{
				double steps = Math.max(Math.abs(personf.gorad - personf.rad) / radrate, Math.abs(personf.gosang - personf.sang) / angrate);
				int nsteps = (int)(steps + 0.01);
				double al = (nsteps == 0 ? 0.0 : (nsteps) / (nsteps + 1.0));
				personf.rad = personf.rad * al + personf.gorad * (1.0 - al);
				personf.sang = personf.sang * al + personf.gosang * (1.0 - al);
				bres = true;
			}
		}
		return bres;
	}

	/////////////////////////////////////////////
	void updatepositionsW(int cx, int cy, double cr, FontMetrics fm)
	{
		for (int i = 0; i < personfloats.length; i++)
			personfloats[i].SetPosition(cx, cy, cr, fm);
	}

	/////////////////////////////////////////////
	void updateofficebioW(FontMetrics fm)
	{
		for (int i = 0; i < personfloats.length; i++)
			personfloats[i].GenOfficeBio(fm);
	}

	/////////////////////////////////////////////
	personfloat FindHit(int x, int y)
	{
		personfloat res = null;
		int cd = 0;
		for (int i = 0; i < personfloats.length; i++)
		{
			personfloat personf = personfloats[i];
			int lcd = Math.min(Math.min(x - personf.sx, personf.sx + personf.sw - x),
							   Math.min(y + personf.sh - personf.sy, personf.sy - y));
			if ((res == null) || (lcd > cd))
			{
				res = personf;
				cd = lcd;
			}
		}
		return (cd >= -1 ? res : null);
	}
};




