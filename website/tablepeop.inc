<?php
    # $Id: tablepeop.inc,v 1.2 2005/03/14 18:58:16 goatchurch Exp $

    # The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.



	function print_mp_row($nrows, $row, $name, $href, $colstyle)
	{
    	print "<tr class=\"".(($nrows % 2 == 1) ? "odd" : "even")."\">";

		if ($colstyle == "rebellions" or $colstyle == "attendance")
			print "<td>$nrows</td>";

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
		print "<td>$party</td>";

		# do the two types of writing out
		if ($colstyle == "distance")
		{
			$distance = $row['distance'];
			if ($distance == 0)
				$distance = "0 - always vote the same";
			elseif ($distance == 1)
				$distance = "1 - always vote the differently";
			print "<td>$distance</td>";
		}

		# the remaining columns
		elseif ($colstyle == "list")
		{
			print "<td class=\"percent\">".percentise_votes_short($row['rebellions'], $row['votes_attended'])."</td>";
        	print "<td class=\"percent\">".percentise_votes_short($row['votes_attended'], $row['votes_possible'])."</td>";
  		}

		else # rebellions or attendance
		{
			print "<td class=\"percent\">";
			if ($colstyle == "attendance")
	            print percentise_votes_short($row['votes_attended'], $row['votes_possible']);
			else
				print percentise_votes_short($row['rebellions'], $row['votes_attended']);
			print ($colstyle == "rebellions" ? " rebel" : " attendance");
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
	# sortby is 'turnout', 'rebellions', 'name', 'constituency', 'attendance'
	# showwhich is 'rebels', 'voters', 'allpossible'
	function mp_table($db, $mptabattr)
	{
		global $bdebug;

		$aquery = array();
		$aquery["qselect"] = "SELECT first_name, last_name, title, constituency, party,
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

		if ($mptabattr["sortby"] == "constituency")
	        $aquery["qorder"] .= " constituency, last_name, first_name, party";
		elseif ($mptabattr["sortby"] == "party")
	        $aquery["qorder"] .= " party, last_name, first_name, constituency";

		# defaults to last name
		else
	        $aquery["qorder"] .= " last_name, first_name, constituency, party";


		# go through the different list selection cases

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
			$aquery["qorder"] = " ORDER BY distance";
			$friendlk = "mpn2=".urlencode(str_replace(" ", "_", $mpprop['name']))."&mpc2=".urlencode($mpprop['constituency']);
		}

		elseif ($mptabattr["listtype"] == 'dreamdistance')
		{
			$aquery["qjoin"] .= "  ON ".$mptabattr["dreammpid"];
			$friendlk = "dreammpid=".$mptabattr["dreammpid"];
		}
		elseif ($mptabattr["listtype"] == 'division')
		{
			$aquery["qjoin"] .= "  ON ".$mptabattr["dreammpid"];
		}
		elseif ($mptabattr["listtype"] == 'division')
		{
			$aquery["qjoin"] .= "  ON ".$mptabattr["dreammpid"];
		}


		# apply the showwhich cases
		# showwhich is 'all', 'limit'(limitno=>n), 'rebels', 'attended'
		if ($mptabattr["limit"])
			$aquery["qlimit"] = " LIMIT ".$mptabattr["limit"];


		$query = $aquery["qselect"].$aquery["qfrom"].$aquery["qjoin"].$aquery["qwhere"].$aquery["qorder"].$aquery["qlimit"];
		if ($bdebug == 1)
			print "\n<h3>$query</h3>\n";
		$db->query($query);

		# determin the column type
		if ($friendlk)
			$colstyle = "distance";
		elseif ($mptabattr["limit"])
			$colstyle = $mptabattr["sortby"]; # short table on the index page
		else
			$colstyle = "list";

		# now output all the parts of the table
		$nrows = 0;
        while ($row = $db->fetch_row_assoc())
        {
			$mpname = $row['first_name']." ".$row['last_name'];
			$href = "mp.php?mpn=".urlencode(str_replace(" ", "_", $mpname))."&mpc=".urlencode($row['constituency']);
			if ($friendlk)
				$href .= "&$friendlk";
			$nrows += 1; # number from 1
			print_mp_row($nrows, $row, $mpname, $href, $colstyle);
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


