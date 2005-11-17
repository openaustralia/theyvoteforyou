<?php
    # $Id: tableoth.inc,v 1.19 2005/11/17 10:34:16 publicwhip Exp $

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
		    print "<td>Rebellions (estimate)</td><td>Attendance (votes)</td>";
			if (!$bmultiperson)
			    print "<td>Teller</td>";
		}
		print "</tr>\n";

	    foreach ($mpprops as $mpprop)
	    {
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
			if ($conscolumn)
                print "<td>".$mpprop['constituency']."</td>\n";
			print "<td>".$mpprop['enteredhouse']."</td>\n";
	        $lefthouse = ($mpprop['lefthouse'] == "9999-12-31" ? "still in office" : $mpprop['lefthouse']);
			print "<td>".$lefthouse."</td>\n";
	        print "<td>".pretty_party($mpprop['party'])."</td>\n";
			if ($brebelrates)
			{
		        print "<td class=\"percent\">".percentise_votes($mpprop['rebellions'], $mpprop['votesattended'])."</td>\n";
				print "<td class=\"percent\">".percentise_votes($mpprop['votesattended'], $mpprop['votespossible'])."</td>\n";
				if (!$bmultiperson)
				{
			        $tells = $mpprop['tells'];
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
	# listlength is 'short' or 'allpublic'
	function print_policy_table($db, $dreamtabattr)
	{
		$qselect = " SELECT name, description, votes_count, private,
					   pw_dyn_dreammp.dream_id AS dream_id,
				       round(100 * edited_motions_count / votes_count, 0) AS motions_percent,
					   (votes_count - edited_motions_count) AS unedited_motions";
		$qfrom =   " FROM pw_dyn_dreammp";
		$qjoin =   " LEFT JOIN pw_cache_dreaminfo ON pw_cache_dreaminfo.dream_id = pw_dyn_dreammp.dream_id
					 LEFT JOIN pw_dyn_user ON pw_dyn_user.user_id = pw_dyn_dreammp.user_id";
		$qwhere =  " WHERE 1=1";
		$qgroup =  " GROUP BY dream_id"; // not understood where the duplicates were getting in
		$qorder =  "";
		$qlimit = "";

		// matching to an MP
		if ($dreamtabattr['listtype'] == "comparelinks")
		{
	        $qselect .= ", distance_a AS distance";
        	$qjoin   .= " LEFT JOIN pw_cache_dreamreal_distance
                                    	ON pw_cache_dreamreal_distance.person = ".$dreamtabattr['person'];
	        $qorder = " ORDER BY distance";
            $qwhere .= " AND distance_a <> -1";

		}

		if ($dreamtabattr['listlength'] != "every")
			$qwhere .= " AND votes_count > 0";
		if ($dreamtabattr['listlength'] == "allpublic" || $dreamtabattr['listlength'] == "short")
			$qwhere .= " AND NOT private";
		if ($dreamtabattr['listlength'] == "short")
			$qlimit = " LIMIT 20";

		// main given list case
		if ($dreamtabattr['listtype'] == "mainlist")
		    $qorder = " ORDER BY motions_percent DESC, edited_motions_count DESC, votes_count DESC";


		$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup.$qorder.$qlimit;
//		if ($bdebug == 1)
			print "<h2>$query</h2>\n";
		$db->query($query);
		$res = $db->rows();

	    while ($row = $db->fetch_row_assoc())
		{
	        $prettyrow = pretty_row_start($prettyrow);
	        $dreamid = $row['dream_id'];

			if ($dreamtabattr['listtype'] == "mainlist")
	        {
	        	print "<td>".$row['votes_count']." (".$row['unedited_motions'].")</td>\n";
				$link = "policy.php?id=$dreamid";
				$suffix = "";
			}
			if ($dreamtabattr['listtype'] == "comparelinks")
			{
		        print "<td>".$row["votes_count"]."</td>\n";
			    $link = "mp.php?".$dreamtabattr["mpanchor"]."&dmp=$dreamid";
				$suffix = " (Compare)";
			}

	        print "<td><a href=\"$link\">".soft_hyphen($row['name'], 25)."$suffix</a></td>\n";
	        print "<td>".trim_characters(str_replace("\n", "<br>", html_scrub($row['description'])), 0, 150)."</td>\n";

			if ($dreamtabattr['listtype'] == "mainlist")
		        print "<td>0&nbsp;<img src=\"dreamplot.php?id=$dreamid\">&nbsp;1</td>\n";
			if ($dreamtabattr['listtype'] == "comparelinks")
		    {
		        $distance = $row['distance'];
        		$agreement = (1.0 - (float)($distance)) * 100.0;
        		print "<td>".number_format($agreement, 1)."%</td>\n";
			}

	        print "</tr>\n";
  		}

		return $count;
 	}



    function print_party_summary_division($db, $div_id, $baseurl)
    {
        $db->query("SELECT party, total_votes FROM pw_cache_partyinfo");
        $alldivs = array();
        while ($row = $db->fetch_row())
            $alldivs[$row[0]] = $row[1];

        $alldivs_total = array_sum(array_values($alldivs));

        # Table of votes by party
        print "<h2><a name=\"summary\">Party Summary</a></h2>";
        print "<p>Votes by party, red entries are votes against the majority for that party.  ";
        print "
        <div class=\"tableexplain\">
        <span class=\"ptitle\">What is Tell?</span>
        '+1 tell' means that in addition one member of that party was a
        <a href=\"".$baseurl."faq.php#jargon\">teller</a> for that division lobby.</p>
        <p>
        <span class=\"ptitle\">What are Boths?</span> An MP can vote both
        aye and no in the same division. The <a href=\"".$baseurl."boths.php\">boths
        page</a> explains this.
        <p>
        <span class=\"ptitle\">What is Abstain?</span> Abstentions are
        <a href=\"".$baseurl."faq.php#abstentions\">estimated by statistics</a>.
        They are relative to other parties, so can be negative.</p>
        </div>";

        $partysummary = GetPartyVoteSummaryH($db, $div_id);

        # Make table
        print "<table><tr class=\"headings\"><td>Party</td><td>Ayes</td><td>Noes</td>";
        print "<td>Both</td>";
        print "<td>Turnout</td>";
        print "<td>Expected</td><td>Abstain</td></tr>";
        $prettyrow = 0;
        $allparties = array_keys($alldivs);
        usort($allparties, strcasecmp);
        #if ($partysummary['votes'] != $turnout)
        #    print "<p>Error $votes != $turnout\n";

        foreach ($allparties as $party)
        {
            $aye = $partysummary['ayes'][$party];
            $no = $partysummary['noes'][$party];
            $both = $partysummary['boths'][$party];
            $tellaye = $partysummary['tellayes'][$party];
            $tellno = $partysummary['tellnoes'][$party];
            if ($aye == "") { $aye = 0; }
            if ($no == "") { $no = 0; }
            if ($both == "") { $both = 0; }
            $whip = $partysummary['whips'][$party];
            $total = $aye + $no + $both + $tellaye + $tellno;
            $classaye = "normal";
            $classno = "normal";
            if ($whip == "aye") { if ($no + $tellno > 0) { $classno = "rebel";} ;} else { $classno = "whip"; }
            if ($whip == "no") { if ($aye + $tellaye> 0) { $classaye = "rebel";} ;} else { $classaye = "whip"; }

            $classboth = "normal";
            if ($both > 0) { $classboth = "important"; }

            $alldiv = $alldivs[$party];
            $expected = round($partysummary['votes'] * ($alldiv / $alldivs_total), 0);
            $abstentions = round($expected - $total, 0);
            $classabs = "normal";
            if (abs($abstentions) >= 2) { $classabs = "important"; }

            if ($tellaye > 0 or $tellno > 0 or $aye > 0 or $no > 0 or $both > 0 or $abstentions >= 2)
            {
                if ($tellaye > 0)
                    $aye .= " (+" . $tellaye . " tell)";
                if ($tellno > 0)
                    $no .= " (+" . $tellno . " tell)";

                $prettyrow = pretty_row_start($prettyrow);
                print "<td>" . pretty_party($party) . "</td>";
                print "<td class=\"$classaye\">$aye</td>";
                print "<td class=\"$classno\">$no</td>";
                print "<td class=\"$classboth\">$both</td>";
                print "<td>$total</td>";
                print "<td>$expected</td>";
                print "<td class=\"$classabs\">$abstentions</td>";
                print "</tr>";
            }
        }
        print "</table>";
	}
?>
