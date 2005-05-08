<?php
    # $Id: tableoth.inc,v 1.5 2005/05/08 22:47:13 frabcus Exp $

    # The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

	# the table which summarises a set of mps, the same one or different ones in the same constituency
	function seat_summary_table($mpprops, $bmultiperson)
	{
		global $bdebug;
		$prettyrow = 0;
	    print "<table>\n";
		print "<tr class=\"headings\">";
		if ($bmultiperson)
			print "<td>Name</td>";
	    print "<td>Constituency</td>";
	    print "<td>From</td><td>To</td>";
	    print "<td>Party</td>";
	    print "<td>Rebellions (estimate)</td><td>Attendance (votes)</td>";
		if (!$bmultiperson)
		    print "<td>Teller</td>";
		print "</tr>\n";

	    foreach ($mpprops as $mpprop)
	    {
	        $prettyrow = pretty_row_start($prettyrow);
			if ($bmultiperson)
				print "<td>".$mpprop['name']."</td>\n";
	        print "<td>".$mpprop['constituency']."</td>\n";
			print "<td>".$mpprop['enteredhouse']."</td>\n";
	        $lefthouse = ($mpprop['lefthouse'] == "9999-12-31" ? "still in office" : $mpprop['lefthouse']);
			print "<td>".$lefthouse."</td>\n";
	        print "<td>".pretty_party($mpprop['party'])."</td>\n";
	        print "<td class=\"percent\">".percentise_votes($mpprop['rebellions'], $mpprop['votesattended'])."</td>\n";
			print "<td class=\"percent\">".percentise_votes($mpprop['votesattended'], $mpprop['votespossible'])."</td>\n";
			if (!$bmultiperson)
			{
		        $tells = $mpprop['tells'];
				print "<td> $tells ".($tells != 1 ? "times" : "time")."</td>\n";
			}
	        print "</tr>\n";
	    }
	    print "</table>";
	}
?>


<?php
    function print_selected_dream($db, $mpprop, $dreammpid)
    {
		global $bdebug;
		if ($bdebug == 1)
		{
			print "<h1>Gprop:";
			print_r($mpprop);
			print "</h1>\n";
		}

		// should count overlapping votes between dream and mp
	    $query = "SELECT name, description, rollie_id, user_name, count(pw_dyn_rollievote.vote) as count
		           FROM pw_dyn_rolliemp
				   LEFT JOIN pw_dyn_user ON pw_dyn_user.user_id = pw_dyn_rolliemp.user_id
				   LEFT JOIN pw_dyn_rollievote ON pw_dyn_rollievote.rolliemp_id = pw_dyn_rolliemp.rollie_id
				  WHERE pw_dyn_rollievote.rolliemp_id = $dreammpid
				  GROUP BY rollie_id";
		if ($bdebug == 1)
			print "<h1>selected dream: $query</h1>\n";
	    $row = $db->query_one_row_assoc($query);
	    $link = "mp.php?".$mpprop["mpanchor"]."&dmp=".urlencode($dreammpid);
        print "<td>".$row["count"]."</td>\n";
        print "<td>".html_scrub($row["user_name"])."</td>\n";
        print "<td><a href=\"$link\">Compare ".html_scrub($mpprop['name'])." to '".html_scrub($row["name"])."'</a></td>\n";
        print "<td>" . trim_characters(str_replace("\n", "<br>", html_scrub($row["description"])), 0, 50);
        print "</tr>\n";
    }
?>

<?php
    function print_possible_friends($db, $mpprop, $showwhichfriends)
    {
		global $bdebug;

		$mpid = $mpprop['mpid'];
        if ($bdebug == 1)
			print "<h1>".$mpprop['enteredhouse']."  ".$mpprop['party']."  ".$mpprop['enteredreason']."  ".$mpprop['leftreason']."</h1>\n";
        print "<h3>" . pretty_parliament_and_party($mpprop['enteredhouse'], $mpprop['party'], $mpprop['enteredreason'], $mpprop['leftreason']). "</h3>";
        print "<table class=\"mps\">\n";

		$qselect = "SELECT first_name, last_name, title, constituency,
						party, pw_mp.mp_id as mpid,
						rebellions, votes_attended, votes_possible,
						distance, entered_reason, left_reason";
		$qfrom =  " FROM pw_mp, pw_cache_mpinfo, pw_cache_mpdist";
		$qwhere = " WHERE pw_mp.mp_id = pw_cache_mpinfo.mp_id
					 AND pw_mp.mp_id = pw_cache_mpdist.mp_id_1
					 AND pw_cache_mpdist.mp_id_2 = $mpid
					 AND pw_cache_mpdist.mp_id_1 <> $mpid";

		# find the number of voters which are the same
        if ($showwhichfriends == "some")
		{
			$query = "SELECT pw_mp.mp_id as mpid".$qfrom.$qwhere." AND distance = 0";
			if ($bdebug == 1)
				print "<h1>mpid: $mpid, query for same vote rows: $query</h1>\n";
			$db->query($query);
			$same_voters = $db->rows();
		}

		# comparison anchor
		$friendcomp = "mpn2=".urlencode(str_replace(" ", "_", $mpprop['name']))."&mpc2=".urlencode($mpprop['constituency']);

		# create the table
		$qorder = " ORDER BY distance";
		if ($showwhichfriends == "some")
			$qorder .= " LIMIT 0,5";
		$query = $qselect.$qfrom.$qwhere.$qorder;
		if ($bdebug == 1)
			print "<h1>query for friends: $query</h1>\n";
		$db->query($query);

        print "<tr class=\"headings\">
			   <td>Name</td><td>Constituency</td><td>Party</td><td>Distance</td> </tr>";
        $prettyrow = 0;
        while ($row = $db->fetch_row_assoc())
        {
            $prettyrow = pretty_row_start($prettyrow);
			$friendmpname = $row['first_name']." ".$row['last_name'];
			$friendanchor = "mpn=".urlencode(str_replace(" ", "_", $friendmpname))."&"."mpc$i=".urlencode($row['constituency']);

			$distance = $row['distance'];
            if ($distance == "0")
                $distance = "0 - always voted the same";
            if ($distance == "1")
                $distance = "1 - always voted differently";

            print "<td><a href=\"mp.php?$friendanchor&$friendcomp\">".
				$row['title']." $friendmpname</a> (compare)</td>";
			print "<td>".$row['constituency']."</td>";
			print "<td>".pretty_party($row['party'], $row['entered_reason'], $row['left_reason']) . "</td>";
			print "<td>$distance</td>";
#	        print "<td class=\"percent\">".percentise_votes($row['rebellions'], $row['votes_attended'])."</td>\n";
#			print "<td class=\"percent\">".percentise_votes($row['votes_attended'], $row['votes_possible'])."</td>\n";
            print "</tr>\n";
        }
        print "</table>\n";

		# anchor to show all friends
        if ($showwhichfriends == "some")
        {
            if ($same_voters > 4)
                print " ($same_voters MPs voted exactly the same as this one)";
        }
    }
?>

