// Copyright (C) 2004 Julian Todd
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

								{ "Secretary of State",
								  "Minister without Portfolio",
								  "Deputy Prime Minister",
								  "Lord Chancellor",
								  "Chief Whip (House of Lords)",
								  "Chancellor of the Exchequer",
								  "Chancellor of the Duchy of Lancaster",
								  "Parliamentary Secretary to the Treasury",
								  "Chief Secretary to the Treasury",
								  "Lord Privy Seal",
								  "President of the Council"
								},

								{ "Minister of State",
								  "Parliamentary Secretary",
								  "Solicitor General",
								  "Chief Secretary",
								  "Attorney General",
								  "Lords Commissioner",
								  "Deputy Chief Whip (House of Lords)",
								  "Lord Chamberlain",
								  "Lord Advocate",
								  "Advocate General for Scotland",
							  	},

								{ "Parliamentary Under-Secretary",
								  "Financial Secretary",
								  "Economic Secretary",
								  "Assistant Whip",
								  "Baronesses in Waiting",
								  "Paymaster General",
								  "Lords in Waiting",
								  "Comptroller",
								  "Vice Chamberlain",
								  "Master of the Horse",
								  "Lord Steward",
								  "Second Church Estates Commissioner",
								},
							  };

	// http://www.parliament.uk/documents/upload/M06.pdf
	// Transcribed 2004-10-16
	// HoC should include 57485 as MP salary
	static String[][] hcsalaries = {  { "Speaker", "72862" },
									{ "Chairman of Ways and Means", "37796" },
									{ "First Deputy Chairman of Ways and Means", "33218" },
									{ "Second Deputy Chairman of Ways and Means", "33218" },
									{ "Prime Minister", "121437" },
									{ "Cabinet Minister", "72862" },
									{ "Minister of State", "37796" },
									{ "Parliamentary Under-Secretary", "28688" },
									{ "Solicitor General", "63486" },
									{ "Advocate General for Scotland", "63486" },
									{ "Government Chief Whip", "72862" },
									{ "Government Deputy Chief Whip", "37796" },
									{ "Assistant Whip", "24324" },
									{ "Leader of Opposition", "66792" },
									{ "Opposition Chief Whip", "37796" },
									{ "Deputy Chief Opposition Whip", "24324" },
								};

	static String[][] ldsalaries = {  { "Lord Chancellor", "98899" },
									{ "Chairman of Committees", "77220" },
									{ "Principal Deputy Chairman", "77220" },
									{ "Cabinet Minister", "98899" },
									{ "Minister of State", "77220" },
									{ "Parliamentary Under-Secretary", "67255" },
									{ "Attorney General", "103461" },
									{ "Government Chief Whip", "77220" },
									{ "Government Deputy Chief Whip", "67255" },
									{ "Government Whip", "62191" },
									{ "Leader of Opposition", "67255" },
									{ "Opposition Chief Whip", "62191" },
								};

	personoffice(String lstartdate, String lstopdate, String lposition, String ldept)
	{
		startdate = lstartdate;
		stopdate = lstopdate;
		position = lposition;

		// substitute using old technology without regexps
		int iamp = ldept.indexOf("&amp;"); 
		if (iamp != -1)
			dept = ldept.substring(0, iamp) + "&" + ldept.substring(iamp + 5);
		else
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

		if ((rank == -1) && position.startsWith("Minister for"))
			rank = 3;
		if ((rank == -1) && position.startsWith("Parliamentary Secretary"))
			rank = 3;
		if ((rank == -1) && position.startsWith("Treasurer of"))
			rank = 3;

		if (rank == -1)
			System.out.println(position);
	}
};

