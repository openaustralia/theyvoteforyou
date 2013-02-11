<?php
    # $Id: tableoth.inc,v 1.57 2010/02/24 18:38:48 publicwhip Exp $

    # The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

	# the table which summarises a set of mps, the same one or different ones in the same constituency
	function seat_summary_table($mpprops, $bmultiperson, $conscolumn, $brebelrates, $thispagesettings)
	{
		global $bdebug;
		$prettyrow = 0;
	    print "<table>\n";
		print "<tr class=\"headings\">";
		if ($bmultiperson)
			print "<td>Name</td>";
        if ($conscolumn)
            print "<td>Constituency</td>";
	    print "<td>From</td><td>To</td>";
	    print "<td>Party</td>";
		if ($brebelrates)
		{
		    print "<td>Rebellions (<a href=\"faq.php#clarify\">explain...</a>)</td><td>Attendance (<a href=\"faq.php#clarify\">explain...</a>)</td>";
			if (!$bmultiperson)
			    print "<td>Teller</td>";
		}
		print "</tr>\n";

	    foreach ($mpprops as $mpprop)
	    {
            // suppress all the MPs that are too early
            if ($mpprop['enteredhouse'] < '1997')
                continue; 

            $prettyrow = pretty_row_start($prettyrow);
			if ($bmultiperson)
			{
				if ($thispagesettings)
					print "<td>
                    ".$mpprop['name']."
                    <a href=\"mp.php?mpn=".$mpprop['name']."&$thispagesettings\">(show only their votes)</a>
                    </td>\n";
				else
					print "<td>".$mpprop['name']."</td>\n";
   			}
			if ($conscolumn) {
                if ($mpprop["house"] == "lords") 
                    print "<td class=\"lords\">House of Lords</td>\n";
                else
                    print "<td class=\"commons\">".$mpprop['constituency']."</td>\n";
            }
            $enteredhouse = ($mpprop['enteredhouse'] == "0000-00-00" ? "before 1999" : pretty_date($mpprop['enteredhouse']));
			print "<td>".$enteredhouse."</td>\n";
	        $lefthouse = ($mpprop['lefthouse'] == "9999-12-31" ? "still in office" : pretty_date($mpprop['lefthouse']));
			print "<td>".$lefthouse."</td>\n";
	        print "<td>".pretty_party($mpprop['party'])."</td>\n";
			if ($brebelrates)
			{
                if (whipless_party($mpprop["party"]))
                    print "<td class=\"percent\">no whip</td>\n";
                else
                    print "<td class=\"percent\">".percentise_votes($mpprop['rebellions'], $mpprop['votesattended'])."</td>\n";
				print "<td class=\"percent\">".percentise_votes($mpprop['votesattended'], $mpprop['votespossible'])."</td>\n";
				if (!$bmultiperson)
				{
			        $tells = $mpprop['tells'];
					if( $mpprop['house'] == 'scotland' )
						print "<td> n/a </td>\n";
					else
						print "<td> $tells ".($tells != 1 ? "times" : "time")."</td>\n";
				}
			}
	        print "</tr>\n";
	    }
	    print "</table>";
	}



	# ideally we should be pulling out of the cached table!!!

	# This is used to show a list of policies people who are friends, where
	# listtype is:
	#   'comparelinks', then 'person' who we compare to
	#	'mainlist'
	#   'aggregatevotes', then 'dreamid' is the aggregate dreammp
	# listlength is 'short' or 'allpublic'
	function print_policy_table($db, $dreamtabattr)
	{
        global $pwpdo;
        $placeholders=array();
		$qselect = " SELECT name, description, votes_count, private,
						pw_dyn_dreammp.dream_id AS dream_id,
						round(100 * edited_motions_count / votes_count, 0) AS motions_percent,
						(votes_count - edited_motions_count) AS unedited_motions";
		$qfrom =   " FROM pw_dyn_dreammp";
		$qjoin =   " LEFT JOIN pw_cache_dreaminfo ON pw_cache_dreaminfo.dream_id = pw_dyn_dreammp.dream_id
					 LEFT JOIN pw_dyn_user ON pw_dyn_user.user_id = pw_dyn_dreammp.user_id";
		$qwhere =  " WHERE 1=1";
		$qorder =  "";
		$qlimit = "";

		// matching to an MP
		if ($dreamtabattr['listtype'] == "comparelinks")
		{
	        $qselect .= ", distance_a AS distance";
        	$qjoin   .= " LEFT JOIN pw_cache_dreamreal_distance
		                        ON pw_cache_dreamreal_distance.dream_id = pw_dyn_dreammp.dream_id
                                    	AND pw_cache_dreamreal_distance.person = :pwc_distance_person";
            $placeholders[':pwc_distance_person']=$dreamtabattr['person'];
	        $qorder = " ORDER BY name";
            $qwhere .= " AND distance_a <> -1";
		}

		if ($dreamtabattr['listlength'] != "every")
			$qwhere .= " AND votes_count > 0";
		if ($dreamtabattr['listlength'] == "allpublic")
			$qwhere .= " AND private <> 1";
        if ($dreamtabattr['listlength'] == "short")
			$qwhere .= " AND private = 0";

		// main given list case
		if ($dreamtabattr['listtype'] == "mainlist")
		    $qorder = " ORDER BY private, name";

        // This "aggregatevotes" was never properly finished, and is superceded by other stuff
		if ($dreamtabattr['listtype'] == "aggregatevotes")
        {
        	$qselect .= ", pw_dyn_aggregate_dreammp.vote_strength AS vote_strength";
			$qjoin .= " LEFT JOIN pw_dyn_aggregate_dreammp
        					ON pw_dyn_aggregate_dreammp.dream_id_sel = pw_dyn_dreammp.dream_id
        					AND pw_dyn_aggregate_dreammp.dream_id_agg = :pwd_dream_ud_agg";
            $placeholders[':pwd_dream_id_agg']=$dreamtabattr['dreamid'];
		}

        $qgroup = "";
        if ($dreamtabattr['hitcounter'])
        {
            $qselect .= ", SUM(pw_logincoming.page = 'policy') AS hits"; 
            $qselect .= ", SUM(pw_logincoming.page = 'mppolicy') AS mhits"; 
            $qgroup = " GROUP BY pw_dyn_dreammp.dream_id"; 
            $qjoin .= " LEFT JOIN pw_logincoming
                            ON (pw_logincoming.page = 'policy'
                                AND pw_logincoming.thing_id = pw_dyn_dreammp.dream_id)
                            OR (pw_logincoming.page = 'mppolicy'
                                AND pw_logincoming.subject = pw_dyn_dreammp.dream_id)";
        }


		$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup.$qorder.$qlimit;

		$allRows=$pwpdo->fetch_all_rows($query,$placeholders);
		$res = count($allRows);
		if ($res == 0)
		{
	        $prettyrow = pretty_row_start($prettyrow);
            print "<td colspan=\"4\">No policies match this person's votes.
                You can <a href=\"/policies.php\">edit or make a policy</a> that will appear here.</td></tr>";
        }

		$columnforms = array("policy" => "yes");
        #if ($dreamtabattr['listtype'] != "aggregatevotes")
        #    $columnforms["description"] = "yes";
        if ($dreamtabattr['hitcounter'])
	        $columnforms["hitcounter"] = "yes";	
        if ($dreamtabattr['listtype'] == "mainlist")
			$columnforms["votes"] = "yes";
		if ($dreamtabattr['listtype'] == "comparelinks")
			$columnforms["agreement"] = "yes";
		#if ($dreamtabattr['listtype'] == "mainlist")
		#	$columnforms["dists"] = "yes";
		if ($dreamtabattr['listtype'] == "aggregatevotes")
			$columnforms["selected"] = "yes";

		if ($dreamtabattr['headings'])
		{
			print "<tr class=\"headings\">";
            if ($columnforms["hitcounter"])
                print "<td>Hits</td><td>Compare-hits</td>";
			if ($columnforms["votes"])
				print "<td>Votes <i>(unedited)</i></td>";
			if ($columnforms["agreement"])
                print "<td>Agreement</td>"; 
			if ($columnforms["policy"])
		        print "<td>Policy</td>";
            if ($columnforms["description"])
		        print "<td>Description</td>";
			if ($columnforms["vote"])
				print "<td>Vote count</td>";
			if ($columnforms['dists'])
		        print "<td>Party agree<br>/ disagree</td>";
			if ($columnforms["selected"])
		        print "<td>Selected</td>";
	        print "</tr>\n";
		}

        foreach ($allRows as $row) {
	        $prettyrow = pretty_row_start($prettyrow);
	        $dreamid = $row['dream_id'];

            $link = "policy.php?id=$dreamid";
		    if ($columnforms["hitcounter"])
                print "<td>".$row["hits"]."</td><td>".$row["mhits"]."</td>"; 
            if ($columnforms["votes"])
	        {
                print "<td>".$row['votes_count'];
                if ($row['unedited_motions'] != 0)
                    print " <i>(".$row['unedited_motions'].")</i>";
                print "</td>\n";
			}

            if ($columnforms["agreement"])
            {
                $distance = $row['distance'];
                $agreement = (1.0 - (float)($distance)) * 100.0;
                $compare_link = "mp.php?".$dreamtabattr["mpanchor"]."&dmp=$dreamid"; 
                print "<td><b><a href=\"$compare_link\">".number_format($agreement, 0)."%</a></b></td>\n"; 
            }
			if ($columnforms["policy"])
	        {
	        	print "<td><a href=\"$link\">".soft_hyphen($row['name'], 25)."</a>";
	            if ($row['private'] == 2)
	                print " <i>(provisional)<i>";
	            if ($row['private'] == 1)
	                print " <i>(legacy Dream MP)<i>";
	            print "</td>\n";
			}
            
			if ($columnforms["description"])
		        print "<td>".trim_characters(str_replace("\n", "<br>", html_scrub($row['description'])), 0, 100)."</td>\n";
			if ($columnforms["vote"])
			    print "<td>".$row["votes_count"]."</td>\n";
			if ($columnforms['dists'])
	            print "<td>&nbsp;<img src=\"dreamplot.php?id=$dreamid&display=reverse\">&nbsp;</td>\n";
			if ($columnforms["selected"])
		    {
				print "<td>";
				if ($dreamtabattr["editable"])
				{
			        print '<FORM ACTION="policy.php" METHOD="POST"> ';
			        print ' <select name="seldreamid" size="1">
	            			<option value="'.$dreamid.',no" '.($row['vote_strength'] ? "" : "selected").'>No</option>
	            			<option value="'.$dreamid.',yes" '.($row['vote_strength'] ? "selected" : "").'>Yes</option>
			                </select>';
					print ' <input type="hidden" name="id" value="'.$dreamtabattr["dreamid"].'">';
			        print ' <INPUT TYPE="SUBMIT" NAME="submit" VALUE="Update"></FORM>';
					print "</FORM>";
				}
				else
					print ($row['vote_strength'] ? "Yes" : "No");
				print "</td>";
		    }

	        print "</tr>\n";
  		}

		return $res;
 	}



    function print_party_summary_division( $div_id, $baseurl, $house)
    {
        global $pwpdo;
        if ($house != "commons" && $house != "lords" && $house != "scotland") {
            die;
        }
        $pwpdo->query("SELECT party, total_votes FROM pw_cache_partyinfo where house = ?",array($house));
        $alldivs = array();
        while ($row = $pwpdo->fetch_row()) {
            $alldivs[$row[0]] = $row['total_votes'];
        }
        $alldivs_total = array_sum(array_values($alldivs));

        $pwpdo->query("SELECT aye_majority FROM pw_cache_divinfo WHERE division_id=?",array($div_id));
        $row = $pwpdo->fetch_row();
        $aye_majority = $row["aye_majority"];

        # Table of votes by party
        print "<h2><a name=\"summary\">Party Summary</a></h2>";
        print "<p>Votes by party, red entries are votes against the majority for that party.</p>";
        print "<div class=\"tableexplain\">";
        if ($house != "scotland") {
	  print "<p><span class=\"ptitle\">What is Tell?</span>
        '+1 tell' means that in addition one member of that party was a
        <a href=\"".$baseurl."faq.php#jargon\">teller</a> for that division lobby.</p>";
        }
        if ($house != "lords" and $house != "scotland")
            print "<p>
            <span class=\"ptitle\">What are Boths?</span> An MP can vote both
            aye and no in the same division. The <a href=\"".$baseurl."boths.php\">boths
            page</a> explains this.
            <p>";
        print "<span class=\"ptitle\">What is Turnout?</span> This is measured against 
        the total membership of the party at the time of the vote.
        </p>
        </div>";

		$query = "SELECT party, aye_votes, aye_tells, no_votes, no_tells, both_votes, abstention_votes, possible_votes, whip_guess
					FROM pw_cache_whip
					WHERE division_id = ?
					ORDER BY party";
		$pwpdo->query($query,array($div_id));

        $noesfirst = ($aye_majority < 0); 
        # Make table
        print "<table><tr class=\"headings\"><td>Party</td>";
        if ($aye_majority == 0)
            print ($house == "lords" ? "<td>Contents</td><td>Not-Contents</td>":"<td>Ayes</td><td>Noes</td>");
        else if ($noesfirst)
            print ($house == "lords" ? "<td>Majority (Not-Content)</td><td>Minority (Content)</td>":"<td>Majority (No)</td><td>Minority (Aye)</td>");
        else
            print ($house == "lords" ? "<td>Majority (Content)</td><td>Minority (Not-Content)</td>":"<td>Majority (Aye)</td><td>Minority (No)</td>");
        if ($house != "lords") {
	  if ($house == "scotland")
	    print "<td>Abstentions</td>";
	  else
            print "<td>Both</td>";
	}
        print "<td>Turnout</td></tr>\n";
        $prettyrow = 0;

		$totalayes = 0;
		$totalnoes = 0;
		$totalboths = 0;
		$totalturnout = 0;
		$totalpossible = 0;
		$totalabstentions = 0;
	    
        while ($row = $pwpdo->fetch_row())
		{
            $party = $row["party"];
			$aye = $row["aye_votes"];
			$tellaye = $row["aye_tells"];
			$no = $row["no_votes"];
			$tellno = $row["no_tells"];
			$both = $row["both_votes"];
			$abstentions = $row["abstention_votes"];

            $total = $aye + $no + $both + $abstentions + $tellaye + $tellno;
            if (($total == 0) && ($party != "Con" && $party != "Lab" && $party != "LDem"))
                continue; 

			$totalayes += $aye;
			$totaltellayes += $tellaye;
			$totalnoes += $no;
			$totaltellnoes += $tellno;
			$totalboths += $both;
			$totalabstentions += $abstentions;
			$totalturnout += $total;
			$totalpossible += $row["possible_votes"];

            $whip = $row["whip_guess"];
            $classaye = ($aye + $tellaye > 0 ? ($whip == "no" ? "rebel" : "whip") : "normal");
            $classno = ($no + $tellno > 0 ? ($whip == "aye" ? "rebel" : "whip") : "normal");
            $classboth = ($both > 0 ? "important" : "normal");
	    if( $house == "scotland" ) {
	      $classaye = (($aye > 0) ? (($whip == "no" || $whip == "abstention") ? "rebel" : "whip") : "normal");
	      $classno = (($no > 0) ? (($whip == "aye" || $whip == "abstention") ? "rebel" : "whip") : "normal");
	      $classabstentions = (($abstentions > 0) ? (($whip == "aye" || $whip == "no") ? "rebel" : "whip") : "normal");
	    }

            if ($tellaye > 0)
                $aye .= " (+" . $tellaye . " tell)";
            if ($tellno > 0)
                $no .= " (+" . $tellno . " tell)";

            $prettyrow = pretty_row_start($prettyrow);
            print "<td>" . pretty_party($party) . "</td>";
            
            if ($noesfirst)
                print "<td class=\"$classno\">$no</td> <td class=\"$classaye\">$aye</td>";
            else
                print "<td class=\"$classaye\">$aye</td> <td class=\"$classno\">$no</td>";
            
            if ($house == "lords" && $both > 0)
                print "ERROR - both for lords";
            if ($house != "lords") {
	      if ($house == "scotland")
		print "<td class=\"$classabstentions\">$abstentions</td>";
	      else
                print "<td class=\"$classboth\">$both</td>";
	    }
            print "<td class=\"percent\">".percentise_votes_short($total, $row['possible_votes'])."</td>"; 
            print "</tr>";
        }

		// the setting for the final line of totals
        $prettyrow = pretty_row_start($prettyrow);
        $classayes = ($totalayes >= $totalnoes ? "whip" : "normal"); 
        $classnoes = ($totalayes <= $totalnoes ? "whip" : "normal");
        print "<td class=\"whip\">" . "Total:" . "</td>";
        if ($noesfirst)
            print "<td class=\"$classnoes\">$totalnoes</td> <td class=\"$classayes\">$totalayes</td>";
        else
            print "<td class=\"$classayes\">$totalayes</td> <td class=\"$classnoes\">$totalnoes</td>";
        
        if ($house != "lords") {
	  if ($house == "scotland") {
            print "<td class=\"$classabstentions\">$totalabstentions</td>";
	  } else {
            print "<td class=\"$classboth\">$totalboths</td>";
	  }
	}
        else if ($totalboths > 0)
            print "ERROR - both for lords";
        print "<td class=\"percent\">".percentise_votes_short($totalturnout, $totalpossible)."</td>"; 
        print "</tr>";

		print "</table>";
	}
