// Copyright (C) 2004 Martin Dunschen and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.
////////////////////////////////////////////////////////////////////////////////
package radialtree;

import java.awt.Image;
import java.awt.Toolkit;


class personfloat
{
	Image timg;
	String pname;

	personoffice[] poffices = new personoffice[10];
	int npoffices = 0;

	// position we're at
	double rad = 10.0;
	double ang = 0.0;

	// position we want to get to
	double gorad = 10.0;
	double goang = 0.0; 

	personfloat()
	{
		// get the pnum from somewhere
		// timg = toolkit.getImage("data/10186.jpg");
	}

	void AddPoffice(String lstartdate, String lstopdate, String lposition, String ldept, String lpname)
	{
		poffices[npoffices] = new personoffice(lstartdate, lstopdate, lposition, ldept);
		npoffices++;
		pname = lpname;
	}

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

	String GetDept(int mind)
	{
		return poffices[mind].dept;
	}

	int GetRank(int mind)
	{
		return poffices[mind].rank;
	}
};




