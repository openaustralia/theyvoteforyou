// Copyright (C) 2004 Martin Dunschen and Julian Todd
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

	double ang0;
	double ang1;

	/////////////////////////////////////////////
	deptsector(String ldept)
	{
		dept = ldept;
		for (int i = 0; i < vranks.length; i++)
			vranks[i] = new Vector();
	}

	/////////////////////////////////////////////
	void AllocateGo(double lang0, double lang1)
	{
		ang0 = lang0;
		ang1 = lang1;

		for (int rank = 1; rank < vranks.length; rank++)
		{
			double rad = rank;
			for (int p = 0; p < vranks[rank].size(); p++)
			{
				personfloat personf = (personfloat)(vranks[rank].elementAt(p));

				double al;
				if (vranks[rank].size() != 1)
					al = p * 1.0 / (vranks[rank].size() - 1);
				else
					al = 0.5;

				personf.goang = ang0 * (1.0 - al) + ang1 * al;
				personf.gorad = rad;
			}
		}
	}
};



/////////////////////////////////////////////
class ministertimes
{
	Vector personfloats = new Vector();
	personfloat pfloat = null;
	Color[] rankcol = { new Color(0, 0, 0), new Color(0, 0, 40), new Color(0, 0, 80), new Color(0, 0, 120), new Color(0, 0, 160) } ;

	String[] capwords = { "id", "name", "dept", "position", "fromdate", "todate" };
	int cwfromdate = 4;
	int cwtodate = 5;
	int cwdept = 2;
	int cwposition = 3;
	int cwname = 1;
	String[] capvalues = new String[capwords.length];
	int icapword = -1;

	Vector depts = new Vector();

	// load the data from the structured xml file
	// using very primitive parsing technology
	ministertimes(File data) throws IOException
	{
		BufferedReader br = new BufferedReader(new FileReader(data));

		StreamTokenizer stoken = new StreamTokenizer(br);
  		stoken.quoteChar('"');
  		stoken.wordChars('/', '/');

		// go through the known tokens
		while (stoken.nextToken() != StreamTokenizer.TT_EOF)
		{
			if (stoken.ttype == StreamTokenizer.TT_WORD)
			{
				for (icapword = capwords.length - 1; icapword >= 0; icapword--)
					if (stoken.sval.equals(capwords[icapword]))
						break;
				if (icapword == -1)
				{
					// group which defines a person
					if (stoken.sval.equals("ministerofficegroup"))
						pfloat = new personfloat();
					else if (stoken.sval.equals("/ministerofficegroup"))
					{
						personfloats.addElement(pfloat);
						pfloat = null;
					}

					// group which defines an office of a person
					else if (stoken.sval.equals("moffice"))
					{
						for (int i = 0; i < capvalues.length; i++)
							capvalues[i] = null;
					}
					else if (stoken.sval.equals("/moffice"))
						pfloat.AddPoffice(capvalues[cwfromdate], capvalues[cwtodate], capvalues[cwposition], capvalues[cwdept], capvalues[cwname]);

					// <moffice id="uk.org.publicwhip/moffice/290" name="Graham Allen" matchid="uk.org.publicwhip/member/8" dept="HM Treasury" position="Lords Commissioner" fromdate="1997-05-06" todate="1998-07-28" source="newlabministers2003-10-15"></moffice>
				}
			}

			// fill the attributes of the entity
			else if ((stoken.ttype == '"') && (icapword != -1))
			{
				capvalues[icapword] = stoken.sval;
				icapword = -1;
			}
		}

       	br.close();
	}


	/////////////////////////////////////////////
	// allocate sectors and positions (in polar coordinates)
	void AllocateSectors(String sdate)
	{
		// find the departments
		depts.clear();
		for (int i = 0; i < personfloats.size(); i++)
		{
			personfloat personf = (personfloat)personfloats.elementAt(i);
			personf.gorad = 10.0;

			int mind = personf.GetMIndex(sdate);
			if (mind == -1)
				continue;

			String dept = personf.GetDept(mind);
			int rank = personf.GetRank(mind);

			deptsector ds = null;
			for (int d = 0; d < depts.size(); d++)
			{
				ds = (deptsector)depts.elementAt(d);
				if (dept.equals(ds.dept))
					break;
				ds = null;
			}
			if (ds == null)
			{
				ds = new deptsector(dept);
				depts.addElement(ds);
			}

			if (rank != -1)
				ds.vranks[rank].addElement(personf);
		}

		// find the angles on each department.
		// (should work out a sector thing for this)
		for (int d = 0; d < depts.size(); d++)
		{
			deptsector ds = (deptsector)depts.elementAt(d);

			double ang0 = (double)d / depts.size();
			double ang1 = (double)(d + 0.8) / depts.size();
			ds.AllocateGo(Math.PI * 2 * ang0, Math.PI * 2 * ang1);
		}
	}

	static double radrate = 0.04;
	static double angrate = 0.1;

	/////////////////////////////////////////////
	boolean GoCloser()
	{
		boolean bres = false;
		for (int i = 0; i < personfloats.size(); i++)
		{
			personfloat personf = (personfloat)personfloats.elementAt(i);
			if (((personf.rad != personf.gorad) || (personf.ang != personf.goang)))
			{
				double steps = Math.max(Math.abs(personf.gorad - personf.rad) / radrate, Math.abs(personf.goang - personf.ang) / angrate);
				int nsteps = (int)(steps + 0.01);
				double al = (nsteps == 0 ? 1.0 : (nsteps) / (nsteps + 1.0));
				personf.rad = personf.rad * al + personf.gorad * (1.0 - al);
				personf.ang = personf.ang * al + personf.goang * (1.0 - al);
				bres = true;
			}
		}
		return bres;
	}

	/////////////////////////////////////////////
	void paintW(Graphics g, int cx, int cy, double cr)
	{
		for (int i = 0; i < personfloats.size(); i++)
		{
			personfloat personf = (personfloat)personfloats.elementAt(i);

			if (personf.rad != 10.0)
			{
				int rkc = (int)(personf.gorad + 0.5);
				g.setColor(rankcol[Math.min(rankcol.length - 1, rkc)]);
				int x = (int)(cx + Math.cos(personf.ang) * personf.rad * cr / 4);
				int y = (int)(cy + Math.sin(personf.ang) * personf.rad * cr / 4);
				g.drawString(personf.pname, x, y);
			}
		}
	}
};




