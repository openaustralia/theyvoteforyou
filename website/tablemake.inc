<?php
    # $Id: tablemake.inc,v 1.5 2005/03/04 02:27:54 frabcus Exp $

    # The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.



	# this assigns an mp here and returns the MP's party
	function divmpconds(&$aquery, &$db, $voter, $bonlyvotes, $bperson, $i)
	{
		global $bdebug;

		# build the selection
		$aquery["qselect"] .= ", pwvote$i.vote as vote$i";

		# searching against a person, not just an mpid
		if ($bperson)
		{
			$aquery["qjoin"]   .= "	LEFT JOIN pw_vote as pwvote$i ON
										pwvote$i.division_id = pw_division.division_id";
			$aquery["qjoin"]   .= " LEFT JOIN pw_mp as pwmp$i ON
										pwvote$i.mp_id = pwmp$i.mp_id";
			$aquery["qwhere"] .= " AND pwmp$i.person = ".$voter['personid'];

			# get the fields for this particular person time range
	        $datecond = "";
			foreach ($voter['mpprops'] as $mpprop)
			{
				if ($datecond != "")
					$datecond .= " OR ";
				$datecond .= " (pw_division.division_date >= \"".$mpprop['enteredhouse']."\"
						  			AND pw_division.division_date < \"".$mpprop['lefthouse']."\")";
			}
			if ($datecond != "")
				$aquery["qwhere"] .= " AND ($datecond)";
			$aquery["qwhere"] .= " AND pwmp$i.person = ".$voter['personid'];
			if ($bdebug == 1)
				print "<h1>datecond: $datecond</h1>\n";
		}

		# searching against an mp
		else
		{
			if ($bdebug == 1)
			{
				print "<h1>";
				print_r($voter);
				print "</h1>\n";
			}
			$aquery["qjoin"]   .= " LEFT JOIN pw_vote as pwvote$i ON
										pwvote$i.division_id = pw_division.division_id
										AND pwvote$i.mp_id = ".$voter['mpid'];

			# limit down the time range if not a full-join
			$datecond = " (pw_division.division_date >= \"".$voter['enteredhouse']."\"
					  			AND pw_division.division_date < \"".$voter['lefthouse']."\")";
			$aquery["qwhere"] .= " AND $datecond";

			$aquery["name$i"] = $voter["name"];
			$aquery["party$i"] = $voter["party"];
		}

		if ($bonlyvotes)
			$aquery["qwhere"] .= " AND pwvote$i.vote IS NOT NULL";

		$aquery["vote$i"] = "pwvote$i.vote";  # used because whipping has a special column
	}

	# this joins a dreammp here
	function divdreammpconds(&$aquery, &$db, $dreammpid, $bonlyvotes, $i)
	{
		# build the selection.  There is no division_id in the rollievote table
		$aquery["qselect"] .= ", pwvote$i.vote as vote$i";
		$aquery["qjoin"]   .= " LEFT JOIN pw_dyn_rollievote as pwvote$i ON
									pwvote$i.rolliemp_id = $dreammpid
									 AND pwvote$i.division_date = pw_division.division_date
									 AND pwvote$i.division_number = pw_division.division_number";

		# limit down the time range if not a full-join
		if ($bonlyvotes)
			$aquery["qwhere"] .= " AND pwvote$i.vote IS NOT NULL";

		$aquery["vote$i"] = "pwvote$i.vote";  # used because whipping has a special column
	}

	# this joins a party vote here
	function divpartyconds(&$aquery, &$db, $party, $i)
	{
		# parties always vote everywhere, so safe to join to one
		$aquery["qselect"] .= ", pwvote$i.whip_guess as vote$i";
		$aquery["qjoin"]   .= " LEFT JOIN pw_cache_whip as pwvote$i ON
									pwvote$i.division_id = pw_division.division_id
									AND pwvote$i.party = \"$party\"";

		$aquery["vote$i"] = "pwvote$i.whip_guess";  # used because whipping has a special column
	}




	# the votes
	function workrolevote($votertype, &$vote)
	{
		if ($votertype == "mp" or $votertype == "person")
		{
			if ($vote == "tellaye")
				return "aye";
			if ($vote == "tellno")
				return "no";
			if ($vote == "both")
				return "";
			if ($vote == "")
			{
				$vote = "absent";
				return "";
			}
		}
		else if ($votertype == "dreammp")
		{
			if ($vote == "both")
			{
				$vote = "abstain";
				return "";
			}
		}
		else if ($votertype == "party")
		{
			if ($vote == "unknown")
				return "";
		}
		return $vote;
	}

	# this makes a comment on the row used to highlight rebels
	function workrolecolumn($voter1type, &$vote1, $voter2type, &$vote2, $showwhich)
	{
		$class = "";
		$votedesc = "";

		$dtvote1 = workrolevote($voter1type, $vote1);
		if ($voter2type == "")
			return "<td></td>";

		$dtvote2 = workrolevote($voter2type, $vote2);

		# mp to party terminology
		if ($voter1type == "mp" and $voter2type == "party")
		{
			if ($vote1 == "absent")
				$votedesc = "absent";
			else if ($dtvote1 != $dtvote2 and $vote2 != "unknown")
			{
				$class = "rebel";
				$votedesc = "Rebel";
			}
			if ($vote1 == "tellaye" || $vote1 == "tellno")
			{
				$class .= "teller";
				$votedesc .= " Teller";
			}
			if ($votedesc == "")
				$votedesc = "Loyal";
		}

		# other cross comparisons
		else
		{
			if ($dtvote1 != $dtvote2)
			{
				if ($dtvote1 == "" or $dtvote1 == "abstain" or $dtvote2 == "" or $dtvote2 == "abstain")
				{
					$class = "rebelteller"; # yellow
					$votedesc = "miss";
				}
				else
				{
					$class = "rebel";
					$votedesc = "disagree";
				}
			}
			else
			{
				$class = "teller";  # green
				$votedesc = "agree";
			}
		}

		return "<td class=\"$class\">$votedesc</td>";
	}


    function print_event($event)
    {
        global $prettyrow;
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>&nbsp;</td><td>&nbsp;</td>";
        print "<td>" . $event[0] . "</td>";
        print "<td colspan=7>" . $event[1] .  "</td></tr>\n";
    }

	# table that shows a selected heap of divisions, and provides a comparison between
	# one or two independent voting actors.
	# votertype is 'dreammp', 'mp', 'party'
	# voter is a mpid, dreammpid, blank-for-self party,
	# showwhich is 'everyvote', 'all1', 'all2', 'either', 'both', 'bothdiff' (tellers appear automatically)
	# (then we need a signal for order and for expanded display, and for events)
	# headings is 'none', 'columns', 'fulldesc'(for changing mps)
	# sortby is 'date', 'subject', 'rebellions', 'turnout'
	# $parldatelimit is null or a line from $parliaments
	function division_table($db, $voter1type, $voter1, $voter2type, $voter2, $showwhich, $headings, $sortby = "date", $parldatelimit = null)
	{
		global $bdebug;
		if ($bdebug == 1)
			print "<h1>divisiontable: $voter1type, $voter1, $voter2type, $voter2, $showwhich, $headings</h1>";

		# the underlying division list
		$aquery = array();
        $aquery["qselect"] = " SELECT
								pw_division.division_number AS divisionnumber,
							  	pw_division.division_date 	AS divisiondate,
							  	division_name, source_url, debate_url, source_gid, debate_gid,
								object_key as motionedited";

		$aquery["qfrom"]   = " FROM pw_division";
		$aquery["qjoin"]   = " LEFT JOIN pw_cache_divinfo ON pw_cache_divinfo.division_id = pw_division.division_id";

		# where clause with limitation for one parliament, or dummy condition
		$aquery["qwhere"]  = " WHERE 1=1";
		if ($parldatelimit)
			$aquery["qwhere"]  = " WHERE (pw_division.division_date >= \"".$parldatelimit['from']."\"
								  		  AND pw_division.division_date < \"".$parldatelimit['to']."\")";

		# this handles joins with the wiki motion text
		$aquery["qgroup"]  = " GROUP BY pw_division.division_id";


		# accumulate the ordering command
		$aquery["qorder"]  = " ORDER BY";
		if ($sortby == "subject")
			$aquery["qorder"] .= " division_name, ";
		if ($sortby == "rebellions" or $sortby == "turnout")
			$aquery["qorder"] .= " $sortby DESC, ";
		$aquery["qorder"] .= " divisiondate DESC, divisionnumber DESC";


		# corrected column (yet another division_id coding!)
		$aquery["qjoin"]  .= " LEFT JOIN pw_dyn_wiki ON pw_dyn_wiki.object_key =
							 	concat('motion-', pw_division.division_date, '-', pw_division.division_number)";


		# construct the first column of votes
		$bonlyvotes1 = ($showwhich == "all1" or $showwhich == "both" or $showwhich == "bothdiff");
		if ($voter1type == "mp")
			divmpconds($aquery, $db, $voter1, $bonlyvotes1, false, 1);
		else if ($voter1type == "dreammp")
			divdreammpconds($aquery, $db, $voter1, $bonlyvotes1, 1);
		else if ($voter1type == "")  # this case means we are listing all divisions without a driver
			$aquery["qselect"] .= ", rebellions, turnout";

		# construct the second column of votes (if it exists)
		if ($voter2type != "")
		{
			$bonlyvotes2 = ($showwhich == "all2" or $showwhich == "both" or $showwhich == "bothdiff");
			if ($voter2type == "dreammp")
				divdreammpconds($aquery, $db, $voter2, $bonlyvotes2, 2);
			else if ($voter2type == "party")
			{
				if ($voter2 == "")
					$voter2 = $aquery["party1"];
				divpartyconds($aquery, $db, $voter2, 2);
			}
			else if ($voter2type == "person")
				divmpconds($aquery, $db, $voter2, $bonlyvotes2, true, 2);

			# put in the selection mechanism of diffs into this
			if ($showwhich == "bothdiff")
				$aquery["qwhere"]  .= " AND ".$aquery["vote1"]." <> ".$aquery["vote2"];
			else if ($showwhich == "either");
				$aquery["qwhere"]  .= " AND (".$aquery["vote1"]." IS NOT NULL OR ".$aquery["vote2"]." IS NOT NULL)";
		}



        # main set that grabs all the divisions and makes a coarse subsampling
        $query = $aquery["qselect"].$aquery["qfrom"].$aquery["qjoin"].$aquery["qwhere"].$aquery["qgroup"].$aquery["qorder"];
		if ($bdebug == 1)
		{
			$query .= " LIMIT 10";
			print "<h1>GGGG $voter1type ";
			print_r($voter1);
			print " $voter2type $voter2 $showwhich $headings</h1>";
			print "<h1>query: $query</h1>\n";
		}
        $db->query($query);


		# make the printing
		$prettyrow = 0;
		$nrows = 0;

		# write the headings if wanted
		if ($headings == "columns" or $headings == "fulldesc")
		{
	        print "<tr class=\"headings\">";
			if ($voter2type != "")
				print "<td>Role</td>";
	        print "<td>Date.</td><td>No.</td>";
			print "<td>Subject</td>";

			# comparison type
            if ($voter1type == "mp" and $voter2type == "person")
				print "<td>".$voter1["name"]."</td><td>".$voter2["mpprop"]["name"]."</td>";
			# mp to dream or party type
			else
			{
	            if ($voter1type == "party")
					print "<td>$voter1 Vote</td>";
				else if ($voter1type == "dreammp")
					print "<td>Dream Vote</td>";
				else
					print "<td>Vote</td>";

				if ($voter2type != "")
		        {
		        	if ($voter2type == "party")
						print "<td>$voter2 Vote</td>";
					else if ($voter2type == "dreammp")
						print "<td>Dream Vote</td>";
					else
						print "<td>Vote</td>";
				}
			}
	        print "<td>Debate</td></tr>\n";


			# blank case table; must say something
      		if ($db->rows() == 0)
	        {
	            $prettyrow = pretty_row_start($prettyrow, "");
	            $mess = "no votes listed";
				if ($showwhich == "bothdiff" and $voter1type == "mp" and $voter2type == "party")
					$mess = "no rebellions, never teller";
				$cspan = ($voter2type != "" ? 7 : 5);
	            print "<td colspan=$cspan>$mess</td></tr>\n";
    	    }
		}

		# now do the actual rows here
        while ($row = $db->fetch_row_assoc())
        {
			# mark the role column and fix the terminology of the vote
            $pretrowclass = "";
			if ($voter1type != "")
			{
				$vote1 = $row['vote1'];
				$vote2 = $row['vote2'];
				$rolecol = workrolecolumn($voter1type, $vote1, $voter2type, $vote2, $showwhich);
				if ($rolecol == "")
					continue;      # final filter bail out
			}

			# it's ugly if it's all red at the top when sorted
			else if ($row['rebellions'] >= 10 and $sortby != "rebellions")
	            $pretrowclass = "rebel";


            $prettyrow = pretty_row_start($prettyrow, $pretrowclass);
			if ($voter2type != "")
				print $rolecol;
			print "<td>".$row['divisiondate']."</td>";
			print "<td>".$row['divisionnumber']."</td>";
			$divhref = "division.php?date=".urlencode($row['divisiondate'])."&number=".urlencode($row['divisionnumber']);
			$divdesc = $row['division_name'];
			if ($row['motionedited'] == "")
				$divdesc .= " (<i>uncorrected</i>)";
			print "<td><a href=\"$divhref\">$divdesc</a></td>\n";

			if ($voter1type != "")
			{
				print "<td>$vote1</td>";
				if ($voter2type != "")
					print "<td>$vote2</td>\n";
   			}

			# alternative columns on division table
			else
				print "<td>".$row['rebellions']."</td> <td>".$row['turnout']."</td>\n";

			# no reason not to have a speeches column on the division table, but we don't
			if ($voter1type != "")
			{
				$debate_gid = str_replace("uk.org.publicwhip/debate/", "", $row['debate_gid']);
			    if ($debate_gid != "")
					$hrefsource = "http://www.theyworkforyou.com/debates/?id=$debate_gid";
				else
					$hrefsource = $row['source_url'];
	            print "<td><a href=\"$hrefsource\">speeches</a></td>";
			}

            print "</tr>\n";
            $nrows += 1;
        }
	}

?>


