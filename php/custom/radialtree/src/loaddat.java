// Copyright (C) 2004 Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.
////////////////////////////////////////////////////////////////////////////////
package radialtree;


import java.io.File;
import java.io.IOException;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.StreamTokenizer;
import java.util.Vector;

// http://www.publicwhip.org.uk/data/ministers.xml

/////////////////////////////////////////////
class loaddat
{
	static String[] capwords = { "id", "name", "dept", "position", "fromdate", "todate" };
	static int cwfromdate = 4;
	static int cwtodate = 5;
	static int cwdept = 2;
	static int cwposition = 3;
	static int cwname = 1;
	static String[] capvalues = new String[capwords.length];
	static int icapword = -1;

	/////////////////////////////////////////////
	static personfloat[] LoadMinisters(BufferedReader br) throws IOException
	{
		Vector vpersonfloats = new Vector();
		personfloat pfloat = null;

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
						vpersonfloats.addElement(pfloat);
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

		// copy the array over
		personfloat[] personfloats = new personfloat[vpersonfloats.size()];
		for (int i = 0; i < vpersonfloats.size(); i++)
			personfloats[i] = (personfloat)vpersonfloats.elementAt(i);
		return personfloats;
	}


	/////////////////////////////////////////////
	static deptsector[] ExtractDepts(personfloat[] personfloats)
	{
		Vector vdepts = new Vector();
		for (int i = 0; i < personfloats.length; i++)
		{
			personfloat personf = personfloats[i];
			for (int j = 0; j < personf.npoffices; j++)
			{
				String sdept = personf.poffices[j].dept;
				int k = 0;
				for ( ; k < vdepts.size(); k++)
					if (sdept.equals((String)vdepts.elementAt(k)))
						break;
				if (k == vdepts.size())
					vdepts.addElement(sdept);
			}
		}

		deptsector[] depts = new deptsector[vdepts.size()];
		for (int i = 0; i < vdepts.size(); i++)
			depts[i] = new deptsector((String)vdepts.elementAt(i));
		return depts;
	}
}


