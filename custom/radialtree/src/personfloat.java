// Copyright (C) 2004 Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.
////////////////////////////////////////////////////////////////////////////////
package radialtree;

import java.awt.Image;
import java.awt.Toolkit;
import java.awt.FontMetrics;


class personfloat
{
	static double outerrad = 8.0;

	Image timg;
	String pname;

	personoffice[] poffices = new personoffice[10];
	int npoffices = 0;

	String[] officebio;
	int maxdstringwidth = 0;
	int dstringheight = 0;

	// angles are 0->1 for right hand sector
	// and 2->3 for left hand sector

	// position we're at
	double rad = outerrad;
	double sang = 0.0;
	int monthcount;
	int nontrivdeptfromend;

	// the position of the drawn name
	int sx;
	int sy;
	int sh;
	int sw;

	// position we want to get to
	double gorad = outerrad;
	double gosang = 0.0;

	int mind; 
	int rank;
	String dept;

	int displaycode = 0;

	personfloat()
	{
		// get the pnum from somewhere
		// timg = toolkit.getImage("data/10186.jpg");
	}

	static String[] prefixes = { "Rt Hon ", "Mr ", "Dr ", "Sir ", "Miss ", "Mrs ", "Ms ", };
	void AddPoffice(String lstartdate, String lstopdate, String lposition, String ldept, String lpname)
	{
		poffices[npoffices] = new personoffice(lstartdate, lstopdate, lposition, ldept);
		npoffices++;

		// strip off all the hon titles
		pname = lpname;
		int ofcase = lpname.indexOf(" of ");
		if ((ofcase != -1) && !pname.startsWith("Duke"))
			pname = pname.substring(0, ofcase);
		for (int i = 0; i < prefixes.length; i++)
		{
			if (pname.startsWith(prefixes[i]))
				pname = pname.substring(prefixes[i].length());
		}

		// shorten Baroness
		if (pname.startsWith("Baroness "))
			pname = "B. " + pname.substring(9);
	}


    /////////////////////////////////////////////
	void GenOfficeBio(FontMetrics fm)
	{
		officebio = new String[npoffices];
		maxdstringwidth = 0;
		for (int i = 0; i < npoffices; i++)
		{
			String lstopdate = (poffices[i].stopdate.startsWith("9999") ? "  -----               " : poffices[i].stopdate);
			officebio[i] = poffices[i].startdate + "  " + lstopdate + "  " + poffices[i].position + "  " + poffices[i].dept;
			maxdstringwidth = Math.max(maxdstringwidth, fm.stringWidth(officebio[i]));
		}
		dstringheight = fm.getHeight();
	}


    /////////////////////////////////////////////
	static int MonthCount(String tdate, String sdate)
	{
		int tyear = Integer.parseInt(tdate.substring(0, 4));
		int tmonth = Integer.parseInt(tdate.substring(5, 7));
		int syear = Integer.parseInt(sdate.substring(0, 4));
		int smonth = Integer.parseInt(sdate.substring(5, 7));

		return (syear - tyear) * 12 + (smonth - tmonth);
	}


	/////////////////////////////////////////////
	boolean SetDate(String sdate)
	{
		gorad = personfloat.outerrad;
		mind = GetMIndex(sdate);
		if (mind == -1)
			return false;

		// data on this hit
		dept = poffices[mind].dept;
		rank = poffices[mind].rank;
		monthcount = MonthCount(poffices[mind].startdate, sdate);
		return true;
	}

	/////////////////////////////////////////////
	int GetMIndex(String sdate)
	{
		int res = -1;
		for (int i = 0; i < npoffices; i++)
		{
			if ((poffices[i].startdate.compareTo(sdate) <= 0) && (poffices[i].stopdate.compareTo(sdate) >= 0))
				res = i;
		}
		return res;
	}


	/////////////////////////////////////////////
	void SetPosition(int cx, int cy, double cr, FontMetrics fm)
	{
		double ang = sang * Math.PI / 2 - Math.PI / 4;
		int x = (int)(cx + Math.cos(ang) * (rad * 1.1 - 0.5) * cx / 3.7);
		int y = (int)(cy + Math.sin(ang) * (rad + 1.0) * cy / 3.1);

		double lsang = sang;
		if (lsang < 0.0)
			lsang += 4.0;
		if (lsang >= 4.0)
			lsang -= 4.0;

		double spos = 0.0;
		if (lsang < 1.0)
			spos = 0.0;
		else if (lsang < 2.0)
			spos = sang - 1.0;
		else if (lsang < 3.0)
			spos = 1.0;
		else
			spos = 4.0 - lsang;

		sw = fm.stringWidth(pname);
		sh = fm.getHeight();
		sx = x - (int)(spos * sw);
		sy = y - fm.getAscent();
	}
};




