// Copyright (C) 2004 Martin Dunschen and Julian Todd
// This is free software, and you are welcome to redistribute it under
// certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
// For details see the file LICENSE.html in the top level of the source.
////////////////////////////////////////////////////////////////////////////////
package radialtree;

import java.awt.Image;
import java.awt.Toolkit;


class personoffice
{
	String startdate;
	String stopdate;
	String position;
	String dept;
	int rank = 1;

	static String[][] ranks = { { "Prime Minister" },
								{ "Secretary of State", "Minister without Portfolio", "Deputy Prime Minister", "Lord Chancellor", "Chancellor of the Duchy of Lancaster" },
								{ "Minister of State", "Parliamentary Secretary", "Chief Secretary", "Attorney General", "Lords Commissioner" },
								{ "Parliamentary Under-Secretary", "Financial Secretary", "Economic Secretary", "Solicitor General", "Assistant Whip", "Baronesses in Waiting", "Lords in Waiting" }
							  };

	personoffice(String lstartdate, String lstopdate, String lposition, String ldept)
	{
		startdate = lstartdate;
		stopdate = lstopdate;
		position = lposition;
		dept = ldept;

		rank = -1;
		for (int j = 0; j < ranks.length; j++)
		{
			for (int i = 0; i < ranks[j].length; i++)
			{
				if (position.equals(ranks[j][i]))
				{
					rank = j;
					break;
				}
			}
			if (rank != -1)
				break;
		}

		if (rank == -1)
			System.out.println(position);
	}
};

