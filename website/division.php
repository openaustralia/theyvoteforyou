<?php require_once "common.inc";
# $Id: division.php,v 1.54 2005/03/14 18:58:14 goatchurch Exp $
# vim:sw=4:ts=4:et:nowrap

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    $db = new DB();
    $db2 = new DB();

    include "gather.inc";
   	include "decodeids.inc";

	# decode the attributes
	$divattr = get_division_attr_decode($db, "");

	$div_id = $divattr["division_id"];
	$name = $divattr["name"];
	$source = $divattr["source_url"];
	$rebellions = $divattr["rebellions"];
	$turnout = $divattr["turnout"];
	$original_motion = $divattr["original_motion"];
	$debate_url = $divattr["debate_url"];
	$source_gid = $divattr["source_gid"];
	$debate_gid = $divattr["debate_gid"];
	$div_no = html_scrub($divattr["division_number"]);
	$this_anchor = $divattr["divhref"];

    include_once "account/user.inc";
    if (!user_isloggedin()) 
	{
        $cache_params = "#date=$date#div_no=$div_no#show_all=$show_all#";
        include "cache-begin.inc";
    }

    include "database.inc";
    include_once "cache-tools.inc";

    include "divisionvote.inc";

	$title = "$name - ".$divattr["prettydate"]." - Division No. $div_no";
	include "header.inc";

	# constants
	$dismodes = array();
	$dismodes["summary"] = array("dtype"	=> "summary",
							 "description" 	=> "Summary",
							 "motiontext" 	=> "yes",
							 "partysummary"	=> "yes",
							 "showwhich" 	=> "rebels",
							 "dreamvoters"	=> "all");

	$dismodes["allvotes"] = array("dtype"	=> "allvotes",
							 "description" 	=> "All voters",
							 "motiontext" 	=> "yes",
							 "partysummary"	=> "yes",
							 "showwhich" 	=> "voters",
							 "dreamvoters"	=> "all");

	$dismodes["allpossible"] = array("dtype"	=> "allpossible",
							 "description" 	=> "All possible voters",
							 "motiontext" 	=> "yes",
							 "showwhich" 	=> "allpossible");

	# work out which display mode we are in
	$display = $_GET["display"];
	if (!$dismodes[$display])
	{
		if ($_GET["showall"] == "yes")
			$display = "allvotes"; # legacy
		else
			$display = "summary"; # default
	}
	$dismode = $dismodes[$display];

	# make list of links to other display modes
	$thispage = $divattr["divhref"];
	$leadch = "<p>"; # get those bars between the links working
    foreach ($dismodes as $ldisplay => $ldismode)
	{
		print $leadch;
		$leadch = " | ";
		$dlink = "href=\"$thispage".($ldisplay != "summary" ? "&display=$ldisplay" : "")."\"";
        if ($ldisplay == $display)
            print $ldismode["description"];
        else
            print "<a $dlink>".$ldismode["description"]."</a>";
	}

	$motion_data = get_wiki_current_value($divattr["motion_key"]);


	# Dream MP feature
	if (user_isloggedin())
		write_dream_vote($divattr);

        # Summary
        print "<h2>Summary</h2>";

        $ayes = $db->query_one_value("select count(*) from pw_vote
            where division_id = $div_id and vote = 'aye'");
        $noes = $db->query_one_value("select count(*) from pw_vote
            where division_id = $div_id and vote = 'no'");
        $boths = $db->query_one_value("select count(*) from pw_vote
            where division_id = $div_id and vote = 'both'");
        $tellers = $db->query_one_value("select count(*) from pw_vote
            where division_id = $div_id and (vote = 'tellaye' or vote = 'tellno')");
        print "<br>On $prettydate, $turnout MPs voted in division no. $div_no in the House of Commons.
            <br>Subject was '$name'
            <br>Votes were $ayes aye, $noes no, $boths both, $tellers tellers.
            There were $rebellions rebellions against majority party vote.";

        $debate_gid = str_replace("uk.org.publicwhip/debate/", "", $debate_gid);
        $source_gid = str_replace("uk.org.publicwhip/debate/", "", $source_gid);
        if ($debate_gid != "") 
		{
            print "<br><a href=\"http://www.theyworkforyou.com/debates/?id=$debate_gid\">Read the full debate</a> leading up to this division";
            print " (on TheyWorkForYou.com)";
        }
        if ($source != "")
            print "<br><a href=\"$source\">Check original division listing</a>";
        print " (on the Parliament website)";

        # Unused -- $debate_url contains start of debate link on parliament website.
        # Unused -- $source_gid contains division listing link on TheyWorkForYou.com website.

	if ($dismode["motiontext"])
    {
    	# Show motion text
        print "<h2><a name=\"motion\">Motion</a></h2>";
        if ($motion_data['user_id'] == 0) {
            print "<p>Procedural text extracted from the debate,
            so you can try to work out what 'aye' (for the motion) and 'no' (against the motion) meant.
            This is for guidance only, irrelevant text may be shown, crucial text may be missing.
            </p>";
        } else {
            print "<p>Result of the motion in a human readable form, as judged by
            our team of self-appointed experts.</p>";
        }
        print "<div class=\"motion\">" . sanitise_wiki_text_for_display($motion_data['text_body']); # TODO: validate this text_body
        print "</div>\n";
        print "<p><a href=\"account/wiki.php?key=$motion_key&r=" .
         urlencode($_SERVER["REQUEST_URI"]) . "\">Edit and correct this motion</a>";
        if ($motion_data['user_id'] != 0) {
            $db->query("select * from pw_dyn_user where user_id = " . $motion_data['user_id']);
            $row = $db->fetch_row_assoc();
            $last_editor = html_scrub($row['user_name']);
            print " (last edited by $last_editor on " .
                $motion_data['edit_date'] . ")";
        } else {
            print " (be the first to edit this)";
        }
        print "</p>\n";
	}


	# Work out proportions for party voting (todo: cache)
	if ($dismode["partysummary"])
    {
        $db->query("select party, total_votes from pw_cache_partyinfo");
        $alldivs = array();
        while ($row = $db->fetch_row())
        {
            $alldivs[$row[0]] = $row[1];
        }
        $alldivs_total = array_sum(array_values($alldivs));

        # Table of votes by party
        print "<h2><a name=\"summary\">Party Summary</a></h2>";
        print "<p>Votes by party, red entries are votes against the majority for that party.  ";
        print "
        <div class=\"tableexplain\">
        <span class=\"ptitle\">What is Tell?</span>
        '+1 tell' means that in addition one member of that party was a
        <a href=\"faq.php#jargon\">teller</a> for that division lobby.</p>
        <p>
        <span class=\"ptitle\">What are Boths?</span> An MP can vote both
        aye and no in the same division. The <a href=\"boths.php\">boths
        page</a> explains this.
        <p>
        <span class=\"ptitle\">What is Abstain?</span> Abstentions are
        <a href=\"faq.php#abstentions\">estimated by statistics</a>.
        They are relative to other parties, so can be negative.</p>
        </div>";



        $partysummary = GetPartyVoteSummary($db, $div_id);

        # Make table
        print "<table><tr class=\"headings\"><td>Party</td><td>Ayes</td><td>Noes</td>";
        print "<td>Both</td>";
        print "<td>Turnout</td>";
        print "<td>Expected</td><td>Abstain</td></tr>";
        $prettyrow = 0;
        $allparties = array_keys($alldivs);
        usort($allparties, strcasecmp);
        if ($partysummary['votes'] <> $turnout)
        {
            print "<p>Error $votes <> $turnout\n";
        }
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

        $mps = array();

        function vote_table($div_id, $db, $date, $show_all, $query)
        {
            # Table of MP votes
            $db->query($query);

            global $mps, $db2;

            print "<table class=\"votes\"><tr class=\"headings\"><td>MP::</td><td>Constituency</td><td>Party</td><td>Vote</td></tr>";
            $prettyrow = 0;
            while ($row = $db->fetch_row())
            {
                // Find out if minister
                $query2 = "select dept, position, from_date, to_date
                    from pw_moffice where pw_moffice.person = '" . $row[8] . "'
                    and from_date <= '$date' and '$date' < to_date";
                // (<= from day as they're being appointed, < for to date
                // as they may have resigned to vote the other way, give
                // benefit of doubt)
                $result = $db2->query($query2);
                $is_minister = false;
                while ($minrow = $db2->fetch_row_assoc()) {
                    $is_minister = true;
                    // can look at post titles etc. here
                }
                $minpost = $is_minister ? "(Minister)" : "";

                // Print stuff
                array_push($mps, $row[5]);
                $class = "";
                if ($row[4] == "")
                    $row[4] = "nonvoter";
                $nt4 = str_replace("tell", "", $row[4]);
                $nt6 = str_replace("tell", "", $row[6]);
                if ($show_all && $nt6 != $nt4 && $nt6 <> "unknown" && $nt4 <> "both" && $nt4 <> "nonvoter")
                    $class = "rebel";
                if ($nt4 == "both")
                    $class = "both";
                $prettyrow = pretty_row_start($prettyrow, $class);
                print "<td><a href=\"mp.php?firstname=" . urlencode($row[0]) .
                    "&lastname=" . urlencode($row[1]) . "&constituency=" .
                    urlencode($row[7]) . "\">$row[2] $row[0] $row[1]</a></td>
                    <td>$row[7]</td><td>" . pretty_party($row[3]) . " " .  $minpost . " </td><td>$row[4]</td>";
                print "</tr>";
            }
            if ($db->rows() == 0)
            {
                $prettyrow = pretty_row_start($prettyrow, "");
                print "<td colspan=4>no rebellions</td></tr>\n";
            }
            print "</table>";
        }

        $query = "select first_name, last_name, title, pw_mp.party,
            vote, pw_mp.mp_id, whip_guess, constituency, person from pw_mp, pw_vote, pw_cache_whip
            where pw_vote.mp_id = pw_mp.mp_id
                and pw_cache_whip.party = pw_mp.party
                and pw_vote.division_id = $div_id
                and pw_cache_whip.division_id = $div_id
                and entered_house <= '$date' and left_house >= '$date' and vote is not null ";
        if (!$show_all)
        {
            $query .= "and vote is not null and whip_guess <> 'unknown' and vote <>
                'both' and whip_guess <> replace(vote, 'tell', '')";
            print "<h2><a name=\"rebels\">Rebel Voters</a></h2>
            <p>MPs for which their vote in this division differed from
            the majority vote of their party.";
        }
        else
        {
            print "<h2><a name=\"voters\">Voter List</a></h2>
                <p>Vote of each MP. Those where they voted differently from
                the majority in their party are marked in red.";
        }
        $query .= "order by party, last_name, first_name desc";
        vote_table($div_id, $db, $date, $show_all, $query);
        if (!$show_all)
        {
            print "<p><a href=\"$this_anchor&showall=yes#voters\">Show detailed voting records -
            all MPs who voted in this division, and all MPs who did not</a>";
        }
        else
        {
            print "<p><a href=\"$this_anchor#rebels\">Show only MPs who rebelled in this division</a>";
        }

        if ($show_all)
        {
            $mp_not_already = "mp_id<>" . join(" and mp_id<>", $mps);
            $query = "select first_name, last_name, title, pw_mp.party,
                \"\", pw_mp.mp_id, \"\", constituency, person from pw_mp where
                    entered_house <= '$date' and left_house >= '$date' and
                    ($mp_not_already)";
            $query .= "order by party, last_name, first_name desc";
            print "<h2><a name=\"nonvoters\">Non-Voter List</a></h2>
                <p>MPs who did not vote in the division.  There are many
                reasons an MP may not vote - read this
                <a href=\"faq.php#clarify\">clear explanation</a> of
                attendance to find some reasons.  Note that MPs who voted both for
                and against are listed in the table above, not this table.  Search
                for \"both\" to find them.";
            vote_table($div_id, $db, $date, $show_all, $query);
            print "<p><a href=\"$this_anchor#rebels\">Show only MPs who rebelled in this division</a>";
        }

        # Show Dream MPs who voted in this division and their votes
        $db->query("select name, rollie_id, vote, user_name from pw_dyn_rolliemp, pw_dyn_rollievote, pw_dyn_user
            where pw_dyn_rollievote.rolliemp_id = pw_dyn_rolliemp.rollie_id and
            pw_dyn_user.user_id = pw_dyn_rolliemp.user_id and
            pw_dyn_rollievote.division_date = '$date' and pw_dyn_rollievote.division_number = '$div_no' ");
        if ($db->rows() > 0)
        {
            $prettyrow = 0;
            print "<h2><a name=\"dreammp\">Dream MP Voters</a></h2>";
            print "<p>The following Dream MPs have voted in this division.  You can use this
               to help you work out the meaning of the vote.";
            print "<table class=\"divisions\"><tr class=\"headings\">";
            print "<td>Dream MP</td><td>Vote (in this division)</td><td>Made by</td>";
            while ($row = $db->fetch_row_assoc()) {
                $prettyrow = pretty_row_start($prettyrow);
                $vote = $row["vote"];
                if ($vote == "both")
                    $vote = "abstain";
                print "<td><a href=\"dreammp.php?id=" . $row["rollie_id"] . "\">";
                print $row["name"] . "</a></td>";
                print "<td>" . $vote . "</td>";
                print "<td>" . html_scrub($row['user_name']) . "</td>";
                print "</tr>";
            }
            print "</table>";
            print "<p><a href=\"account/adddream.php\">Make your own dream MP</a>";

    }

?>

<?php include "footer.inc" ?>
<?php
if (!user_isloggedin())
    include "cache-end.inc";
?>
