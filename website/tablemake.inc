<?php
    # $Id: tablemake.inc,v 1.1 2005/02/19 10:27:26 goatchurch Exp $

    # The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

	# the table which summarises a set of mps, the same one or different ones in the same constituency
	function seat_summary_table($db, $mpids, $bmultiperson)
	{
		$prettyrow = 0;
	    print "<table>\n";
		print "<tr class=\"headings\">";
		if ($bmultiperson)
			print "<td>Name</td>";
	    print "<td>Party</td>";
	    print "<td>From</td><td>To</td>";
	    print "<td>Rebellions (estimate)</td><td>Attendance (divisions)</td>";
		if (!$bmultiperson)
		    print "<td>Teller</td>";
		print "</tr>\n";

	    foreach ($mpids as $mpid)
	    {
			$query = "SELECT CONCAT(first_name, ' ', last_name) as name,
							party, pw_mp.mp_id as mpid,
		        			rebellions, votes_attended, votes_possible,
		        			entered_house, left_house, tells
					  FROM pw_mp, pw_cache_mpinfo
					  WHERE pw_mp.mp_id = pw_cache_mpinfo.mp_id and pw_mp.mp_id = $mpid";
		    $row = $db->query_one_row_assoc($query);

	        $prettyrow = pretty_row_start($prettyrow);
			if ($bmultiperson)
				print "<td>".$row['name']."</td>\n";
	        print "<td>".pretty_party($row['party'])."</td>\n";
			print "<td>".$row['entered_house']."</td>\n";
	        $lefthouse = ($row['left_house'] == "9999-12-31" ? "still in office" : $row['left_house']);
			print "<td>".$lefthouse."</td>\n";
	        print "<td class=\"percent\">".percentise_votes($row['rebellions'], $row['votes_attended'])."</td>\n";
			print "<td class=\"percent\">".percentise_votes($row['votes_attended'], $row['votes_possible'])."</td>\n";
			if (!$bmultiperson)
			{
		        $tells = $row['tells'];
				print "<td> $tells ".($tells != 1 ? "times" : "time")."</td>\n";
			}
	        print "</tr>\n";
	    }
	    print "</table>";
	}

	# the table which summarises a set of mps, the same one or different ones in the same constituency
	# idtype is 'mp', 'dreammp'
	# whip is 'dreammp', 'mp', or 'party'
	# show is 'rebeltell', 'whippedandvoted', 'whipped', 'whippedorvoted', 'all'
	function division_table($db, $idtype, $id, $whiptype, $whipid, $show)
	{
		# construct the basic stuff first
        $qselect = "pw_division.division_number as divisionnumber, pw_division.division_date as divisiondate, division_name,
					 source_url, debate_url, source_gid, debate_gid";
		$qfrom = "pw_division, pw_cache_divinfo";
		$qwhere = "pw_cache_divinfo.division_id = pw_division.division_id";

		# grab info about this mpid, if it exists
		$qwdatelimit = "";
		if ($idtype == "mp")
		{
			$mpid = $id;
			$query = "SELECT mp_id, constituency, person, entered_house, left_house, party
					  FROM  pw_mp
					  WHERE mp_id = $mpid
					  ORDER BY entered_house DESC";
			$row = $db->query_one_row_assoc($query);
			if ($whiptype == "party" and $whipid == "")  # set self party
				$whipid = $row['party'];

			$qselect .= ", vote, mp_id";
			$qfrom .= ", pw_vote";
			$qwhere .= " AND pw_vote.division_id = pw_division.division_id";

			# restrictions on interesting AndCondition divisions
			if ($show == "rebeltell")
				$qwhere .= " AND ((vote <> whip_guess and whip_guess <> 'unknown' and vote <> 'both')
							   OR vote = 'tellaye' OR vote = 'tellno')";
			if ($show == "whippedandvoted" or $show == "rebeltell")
				$qwhere .= " AND mp_id = $mpid";
			else
				$qwhere .= " AND division_date >= \"".$row['entered_house']."\"
							  AND division_date < \"".$row['left_house']."\"";
		}

		# fill in info if it's a page on a dreammp
		if ($idtype == "dreammp")
		{
			$dreammpid = $id;

			$qselect .= ", vote";
			$qfrom .= ", pw_dyn_rollievote";
			$qwhere .= " AND pw_dyn_rollievote.rolliemp_id = '$dreammpid'
						 AND pw_division.division_date = pw_dyn_rollievote.division_date
        				 AND pw_division.division_number = pw_dyn_rollievote.division_number";
		}

		# parties always vote everywhere, so safe to join to one
		if ($whiptype == "party")
		{
			$qselect .= ", whip_guess, rebellions";
			$qfrom .= ", pw_cache_whip";
			$qwhere .= " AND pw_cache_whip.division_id = pw_division.division_id
						  AND pw_cache_whip.party = \"".$whipid."\"";
		}


        # main set that grabs all the divisions and makes a coarse subsampling
        $query = "SELECT $qselect FROM $qfrom WHERE $qwhere
				  ORDER BY divisiondate DESC, divisionnumber DESC";
		#print "<h1>$query</h1>\n";
        $db->query($query);

		$prettyrow = 0;


		# make the printing
		$nrows = 0;
        while ($row = $db->fetch_row_assoc())
        {
            $prettyrow = pretty_row_start($prettyrow);

            $class = "";
			if ($whiptype == "party")
	        {
	        	$votedesc = "Loyal";
	            if ($row["whip_guess"] != "unknown")
	            {
	                $vote = $row["vote"];
	                if ($vote == "tellaye" || $vote == "tellno")
	                {
		                $detellvote = ($vote == "tellaye" ? "aye" : "no");
	                    if ($detellvote != $row["whip_guess"])
	                    {
	                    	$votedesc = "Rebel Teller";
		                    $class .= "rebel";
		            	}
	                    else
	                        $votedesc = "Teller";
	                    $class .= "teller";
	                }
	                else
	                {
						if ($vote != $row["whip_guess"])
		                {
		                	$class .= "rebel";
		                    $votedesc = "Rebel";
		                }
						$detellvote = $vote;
	                }
	            }
	            if ($votedesc == "")
	                $votedesc = "Loyal";
	            print "<td class=\"$class\">$votedesc</td>";
        	}

            print "<td>".$row['divisionnumber']."</td>";
			print "<td>".$row['divisiondate']."</td>";
			$divhref = "division.php?date=".urlencode($row['divisiondate'])."&number=".urlencode($row['divisionnumber']);
			print "<td><a href=\"$divhref\">".$row['division_name']."</a></td>";
			print "<td>".$row['vote']."</td>";
			if ($whiptype == "party")
                print "<td>".$row['whip_guess']."</td>";
			$debate_gid = str_replace("uk.org.publicwhip/debate/", "", $row['debate_gid']);
		    if ($debate_gid != "")
				$hrefsource = "http://www.theyworkforyou.com/debates/?id=$debate_gid";
			else
				$hrefsource = $row['source_url'];
            print "<td><a href=\"$hrefsource\">source</a></td>";
            print "</tr>\n";
            $nrows += 1;
        }

		# blank case
        if ($nrows == 0)
        {
            $prettyrow = pretty_row_start($prettyrow, "");
            $mess = ($show == "rebeltell" ? "no rebellions, never teller" : "no rebellions, never teller");
            print "<td colspan=7>$mess</td></tr>\n";
        }
	}

?>


