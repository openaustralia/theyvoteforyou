<?php
    # $Id: tablepeop.inc,v 1.8 2005/03/28 17:35:59 frabcus Exp $

    # The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

	function print_mp_row($nrows, $row, $name, $href, $colstyle, $showwhich)
	{
		# row colour
		if ($colstyle == "division")
		{
			if ($row["vote"] == "both")
				$sclass = "both";
			elseif ($showwhich != "rebels"
					and $row["whip_guess"] != "unknown" and $row["vote"] != ""
					and str_replace("tell", "", $row["vote"]) != $row["whip_guess"])
        		$sclass = "rebel";
		}
		elseif ($colstyle == "division2" or $colstyle == "division2invert")
		{
			$dtvote_a = str_replace("tell", "", $row["vote_a"]);
			if ($dtvote_a != "aye" and $dtvote_a != "no")
				$dtvote_a = "neither";
			$dtvote_b = str_replace("tell", "", $row["vote_b"]);
			$sclassd = "rebelteller";
			if ($dtvote_b != "aye" and $dtvote_b != "no")
				$dtvote_b = "neither";
			elseif ($dtvote_a != "neither")
				$sclassd = ((($colstyle == "division2invert") == ($dtvote_a == $dtvote_b)) ? "rebel" : "teller");
		}

    	print "<tr class=\"".(($nrows % 2 == 1) ? "odd" : "even").$sclass."\">";

		# row numbering
		if ($colstyle == "shortrebellions" or $colstyle == "shortattendance")
			print "<td>$nrows</td>";

		# name and constituency
		print "<td><a href=\"$href\">".$row['title']." $name</a></td>";

		# we could mark if there are other MPs in this constituency and make a link to them
		#print "<td>".$row['constituency']."</td>";
		print "<td><a href=\"mp.php?mpc=".urlencode($row['constituency'])."\">".$row['constituency']."</a></td>";


		# convert and write out the party
		$party = $row['party'];
	    if ($party == "SPK")
	        $party = "Speaker";
	    elseif ($party == "CWM") # Chairman of Ways and Means (Deputy Speaker)
	        $party = "Deputy Speaker";
	    elseif ($party == "DCWM") # Deputy Chariman of Ways and Means
	        $party = "Deputy Speaker";

	    if ($row["entered_reason"] == "changed_party" or $row["left_reason"] == "changed_party")
			$party = "whilst ".$party;

		if ($colstyle == "division" and $row["ministerial"])
    		$party = $party." (minister)";


		print "<td>$party</td>";

		# distance voting table
		if ($colstyle == "mpdistance")
		{
			$distance = $row['distance'];
			if ($distance == 0)
				$distance = "0 - always vote the same";
			elseif ($distance == 1)
				$distance = "1 - always vote the differently";
			print "<td>".number_format($distance, 3)."</td>";
		}
		elseif ($colstyle == "dreamdistance")
		{
			$distance = $row['distance'];
			if ($distance < 0.1)
				$distance .= " (best)";
			elseif ($distance > 0.9)
				$distance .= " (worst)";
			print "<td>".number_format($distance, 3)."</td>";
		}

		# division vote
		elseif ($colstyle == "division")
			print "<td>".($row["vote"] ? $row["vote"] : "absent")."</td>";
		# double division list
		elseif ($colstyle == "division2" or $colstyle == "division2invert")
		{
			print "<td>".($row["vote_a"] ? $row["vote_a"] : "absent")."</td>\n";
			print "<td class=\"$sclassd\">".($row["vote_b"] ? $row["vote_b"] : "absent")."</td>\n";
		}

		# the remaining columns
		elseif ($colstyle == "list")
		{
			print "<td class=\"percent\">".percentise_votes_short($row['rebellions'], $row['votes_attended'])."</td>";
        	print "<td class=\"percent\">".percentise_votes_short($row['votes_attended'], $row['votes_possible'])."</td>";
  		}

		# rebellions or attendance
		else
		{
			print "<td class=\"percent\">";
			if ($colstyle == "shortattendance")
	            print percentise_votes_short($row['votes_attended'], $row['votes_possible']);
			else
				print percentise_votes_short($row['rebellions'], $row['votes_attended']);
			print ($colstyle == "shortrebellions" ? " rebel" : " attendance");
			$y1 = substr($row["entered_house"], 0, 4);
			$y2 = substr($row["left_house"], 0, 4);
			if ($y2 == "9999")
				$y2 = date("Y");
			print " ($y1-$y2)";
			print "</td>\n";
		}

        print "</tr>\n";
	}


	# a function which generates any table of mps for printing,
	# and marks their votes or distance rankings, or second votes
	# in another division.
	# This is used to show the people who are friends, where
	# listtype is:
	#   'parliament', then 'parliament' is a value from $parliaments,
	#   'mpdistance', then 'mpfriend' is an mpprop for distance from
	# 	'dreamdistance', then 'dreammpid' is what we compare to
	#   'division', then 'divdate', 'divno' index into that
	#   'division2, then there's also 'divdate2', 'divno2'
	# limit is nothing or a number
	# sortby is 'turnout', 'rebellions', 'name', 'constituency', 'attendance', 'party', 'vote'
	# showwhich is 'rebels', 'voters', 'allpossible'
	function mp_table($db, $mptabattr)
	{
		global $bdebug;

		if ($bdebug == 1)
			print_r($mptabattr);

		$aquery = array();
		$aquery["qselect"] = "SELECT first_name, last_name, title, constituency, pw_mp.party AS party,
									 entered_house, left_house,
									 entered_reason, left_reason,
									 pw_mp.mp_id AS mpid,
									 rebellions, votes_attended, votes_possible";
		$aquery["qfrom"] =  " FROM pw_mp";
		$aquery["qjoin"] =  " LEFT JOIN pw_cache_mpinfo ON pw_cache_mpinfo.mp_id = pw_mp.mp_id";
		$aquery["qwhere"] = " WHERE 1=1";

		$aquery["qorder"]  = " ORDER BY";

		# concatenates to the default case
	    if ($mptabattr["sortby"] == "rebellions")
	        $aquery["qorder"] .= " round(rebellions/votes_attended,10) desc,";
		elseif ($mptabattr["sortby"] == "attendance")
	        $aquery["qorder"] .= " round(votes_attended/votes_possible,10) desc,";

		if ($mptabattr["listtype"] == 'division')
		{
			if ($mptabattr["sortby"] == "party")
		        $aquery["qorder"] .= " party, pw_vote_sortorder.position DESC, last_name, first_name, constituency";
			elseif ($mptabattr["sortby"] == "vote")
		        $aquery["qorder"] .= " pw_vote_sortorder.position DESC, last_name, first_name, constituency";
			elseif ($mptabattr["sortby"] == "constituency")
		        $aquery["qorder"] .= " constituency, last_name, first_name";
			else  # by name
		        $aquery["qorder"] .= " last_name, first_name, constituency, party";
		}

		elseif ($mptabattr["listtype"] == 'division2')
		{
			if ($mptabattr["sortby"] == "party")
		        $aquery["qorder"] .= " party, pw_vote_sortorder_a.position DESC, pw_vote_sortorder_b.position DESC, last_name, first_name, constituency";
			elseif ($mptabattr["sortby"] == "vote")
		        $aquery["qorder"] .= " pw_vote_sortorder_a.position DESC, pw_vote_sortorder_b.position DESC, last_name, first_name, constituency";
			elseif ($mptabattr["sortby"] == "vote2")
		        $aquery["qorder"] .= " pw_vote_sortorder_b.position DESC, pw_vote_sortorder_a.position DESC, last_name, first_name, constituency";
			elseif ($mptabattr["sortby"] == "constituency")
		        $aquery["qorder"] .= " constituency, last_name, first_name";
			else  # by name
		        $aquery["qorder"] .= " last_name, first_name, constituency, party";
		}

		# without a vote column
		else
		{
			if ($mptabattr["sortby"] == "constituency")
		        $aquery["qorder"] .= " constituency, last_name, first_name, party";
			elseif ($mptabattr["sortby"] == "party")
		        $aquery["qorder"] .= " party, last_name, first_name, constituency";
			elseif ($mptabattr["sortby"] == "vote")
		        $aquery["qorder"] .= " vote, party, last_name, first_name, constituency";

			# defaults to last name
			else
		        $aquery["qorder"] .= " last_name, first_name, constituency, party";
		}

		# go through the different list selection cases
        $showwhich = $mptabattr["showwhich"];

		# range of mps in one parliament
		if ($mptabattr["listtype"] == 'parliament')
		{
			$parliament = $mptabattr["parliament"];
			$aquery["qwhere"] .= " AND left_house > '".$parliament['from']."'
								   AND entered_house <= '".$parliament['to']."'";
		}

		# list of possible friends of an mp
		elseif ($mptabattr["listtype"] == 'mpdistance')
		{
			$mpprop = $mptabattr["mpfriend"];
			$aquery["qselect"] .= ", distance";
			$aquery["qjoin"] .= " LEFT JOIN pw_cache_mpdist
									ON pw_cache_mpdist.mp_id_1 = pw_mp.mp_id
									 AND pw_cache_mpdist.mp_id_1 <> ".$mpprop["mpid"]."
						 			 AND pw_cache_mpdist.mp_id_2 = ".$mpprop["mpid"];
			$aquery["qwhere"] .= " AND distance IS NOT null";
			$aquery["qorder"] = " ORDER BY distance";
			$friendlk = "mpn2=".urlencode(str_replace(" ", "_", $mpprop['name']))."&mpc2=".urlencode($mpprop['constituency']);
		}

		elseif ($mptabattr["listtype"] == 'dreamdistance')
		{
			$dreamid = $mptabattr["dreammpid"];

			# we need to make the proper equation here, to people
			$aquery["qselect"]  .= ", distance_a AS distance";
			$aquery["qjoin"] 	.= " LEFT JOIN pw_cache_dreamreal_distance
										ON pw_cache_dreamreal_distance.person = pw_mp.person
										AND pw_cache_dreamreal_distance.rollie_id = $dreamid";
			$aquery["qorder"] = " ORDER BY distance";

			# this should use the left-reason case
			$aquery["qwhere"] 	.= " AND left_house = '9999-12-31'
									 AND distance_a <> -1";

			#$aquery["qgroupby"] = " GROUP BY pw_mp.person";

			$friendlk = "dmp=".$mptabattr["dreammpid"];
		}

		# list MPs voting in one division
		elseif ($mptabattr["listtype"] == 'division')
		{
			# the division vote (joined)
			$aquery["qselect"] 	.= ", pw_vote.vote AS vote";
			$aquery["qjoin"] 	.= " LEFT JOIN pw_vote ON pw_vote.mp_id = pw_mp.mp_id
										AND pw_vote.division_id = ".$mptabattr["divid"];

			if ($showwhich == 'allpossible')
	        	$aquery["qwhere"] 	.= " AND entered_house <= '".$mptabattr["divdate"]."'
	        							 AND left_house > '".$mptabattr["divdate"]."'";
			else
				$aquery["qwhere"] 	.= " AND pw_vote.vote IS NOT null";

			# the whip guess
			$aquery["qselect"]	.= ", whip_guess";
			$aquery["qjoin"]	.= " LEFT JOIN pw_cache_whip
										ON pw_cache_whip.division_id = ".$mptabattr["divid"]."
										AND pw_cache_whip.party = pw_mp.party";


			# comparison to the whip
			if ($showwhich == 'rebels')
				$aquery["qwhere"]	.= " AND whip_guess <> 'unknown'
										 AND whip_guess <> replace(pw_vote.vote, 'tell', '')";
										 #AND pw_vote.vote <> 'both'

			# vote table sorting
			$aquery["qselect"] 	.= ", pw_vote_sortorder.position AS votesort";
			$aquery["qjoin"] 	.= " LEFT JOIN pw_vote_sortorder
										ON pw_vote_sortorder.vote = pw_vote.vote";

			# is minister
			$aquery["qselect"] 	.= ", max(pw_moffice.from_date <= '".$mptabattr["divdate"]."'
										AND pw_moffice.to_date > '".$mptabattr["divdate"]."')
										AS ministerial";
			$aquery["qjoin"] 	.= " LEFT JOIN pw_moffice ON pw_moffice.person = pw_mp.person";

			$aquery["qgroupby"] = " GROUP BY pw_mp.mp_id";  # remove double ministers
		}

		# double division case
		elseif ($mptabattr["listtype"] == 'division2')
		{
			$aquery["qselect"] 	.= ", pw_vote_a.vote AS vote_a, pw_vote_b.vote AS vote_b";
			$aquery["qjoin"] 	.= " LEFT JOIN pw_vote AS pw_vote_a ON pw_vote_a.mp_id = pw_mp.mp_id
										AND pw_vote_a.division_id = ".$mptabattr["divid"];
			$aquery["qjoin"] 	.= " LEFT JOIN pw_vote AS pw_vote_b ON pw_vote_b.mp_id = pw_mp.mp_id
										AND pw_vote_b.division_id = ".$mptabattr["divid2"];

			if ($showwhich == "rebels")
			{
				$aquery["qwhere"] 	.= " AND pw_vote_a.vote IS NOT null AND pw_vote_b.vote IS NOT null
										 AND pw_vote_a.vote <> 'both' AND pw_vote_b.vote <> 'both'";
				$aquery["qwhere"] 	.= " AND ((pw_vote_a.vote = 'tellaye' OR pw_vote_a.vote = 'aye')";
				$aquery["qwhere"] 	.= ($mptabattr["div2invert"] ? " = " : " <> ");
				$aquery["qwhere"] 	.= "(pw_vote_b.vote = 'tellaye' OR pw_vote_b.vote = 'aye'))";
			}
			if ($showwhich == 'allpossible')
	        {
	        	$aquery["qwhere"] 	.= " AND entered_house <= '".$mptabattr["divdate"]."'
	        							 AND left_house > '".$mptabattr["divdate"]."'";
	        	$aquery["qwhere"] 	.= " AND entered_house <= '".$mptabattr["divdate2"]."'
	        							 AND left_house > '".$mptabattr["divdate2"]."'";
	        }
			else
				$aquery["qwhere"] 	.= " AND (pw_vote_a.vote IS NOT null OR pw_vote_b.vote IS NOT null)";


			# vote table sorting (on both)
			$aquery["qselect"] 	.= ", pw_vote_sortorder_a.position AS votesort_a, pw_vote_sortorder_b.position AS votesort_b";
			$aquery["qjoin"] 	.= " LEFT JOIN pw_vote_sortorder AS pw_vote_sortorder_a
										ON pw_vote_sortorder_a.vote = pw_vote_a.vote
									 LEFT JOIN pw_vote_sortorder AS pw_vote_sortorder_b
										ON pw_vote_sortorder_b.vote = pw_vote_b.vote";
		}


		# apply the limit
		if ($mptabattr["limit"])
			$aquery["qlimit"] = " LIMIT ".$mptabattr["limit"];


		$query = $aquery["qselect"].$aquery["qfrom"].$aquery["qjoin"].$aquery["qwhere"].$aquery["qgroupby"].$aquery["qorder"].$aquery["qlimit"];
		if ($bdebug == 1)
			print "\n<h3>$query</h3>\n";
		$db->query($query);

		# determin the column type
		if ($friendlk)
			$colstyle = $mptabattr["listtype"];
		elseif ($mptabattr["limit"])
			$colstyle = "short".$mptabattr["sortby"]; # a short table on the index page
		elseif ($mptabattr["listtype"] == "division")
			$colstyle = "division";
		elseif ($mptabattr["listtype"] == "division2")
			$colstyle = "division2".($mptabattr["div2invert"] ? "invert" : "");
		else
			$colstyle = "list";


		# now output all the parts of the table
		if ($showwhich == 'rebels' and $colstyle == "division" and $db->rows() == 0)
			print "<tr class=\"even\"><td colspan=4>no rebellions</td></tr>\n";

		$nrows = 0;
        while ($row = $db->fetch_row_assoc())
        {
			$mpname = $row['first_name']." ".$row['last_name'];
			$href = "mp.php?mpn=".urlencode(str_replace(" ", "_", $mpname))."&mpc=".urlencode($row['constituency']);
			if ($friendlk)
				$href .= "&$friendlk";
			$nrows += 1; # number from 1
			print_mp_row($nrows, $row, $mpname, $href, $colstyle, $showwhich);
		}


		# return value
		# find the number of voters which are the same
		if ($mptabattr["listtype"] == 'mpdistance' and $mptabattr["limit"])
		{
			$query = "SELECT pw_mp.mp_id as mpid".$aquery["qfrom"].$aquery["qjoin"].$aquery["qwhere"]." AND distance = 0";
			if ($bdebug == 1)
				print "\n<h3>$query</h3>\n";
			$db->query($query);
			$same_voters = $db->rows();
			if ($same_voters >= $mptabattr["limit"])
                return $same_voters;
		}
	}
?>
