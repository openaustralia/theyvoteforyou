<?php require_once "common.inc";
# $Id: division.php,v 1.57 2005/03/20 22:31:53 goatchurch Exp $
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
	include "tablepeop.inc";


	# decode the attributes
	$divattr = get_division_attr_decode($db, "");
    if ($divattr == "none") {
        $title = "Division not found";
        include "header.inc";
?> <p>Public Whip does not have this division.  Perhaps it
    doesn't exist, or it hasn't been added to The Public Whip yet.
    New divisions are added one or two working days after they happen.</p>
    <p><a href="divisions.php">Browse for a division</a> </p>
<?
        include "footer.inc";
        exit;
    }

	# second division (which we can compare against)
	$divattr2 = get_division_attr_decode($db, "2");
	if ($divattr2 != "none")
		$div2invert = ($_GET["div2invert"] == "yes");

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

	# make the title
	$title = "$name - ".$divattr["prettydate"]." - Division No. $div_no";
	if ($divattr2 != "none")
	{
		$divattr2 = get_division_attr_decode($db, "2");
		if ($divattr2 != "none")
		{
			$title .= " compared to Division No. ".$divattr2["division_id"];
			if ($divattr2["prettydate"] == $divattr["prettydate"])
				$title .= " on the same day";
			else
				$title .= " on ".$divattr2["prettydate"];
			if ($div2invert)
				$title .= " (inverted)";
		}
	}
	include "header.inc";

	# constants
	$dismodes = array();
	$dismodes["summary"] = array("dtype"	=> "summary",
							 "description" 	=> "Summary",
							 "motiontext" 	=> "yes",
							 "summarytext"	=> "yes",
							 "partysummary"	=> "yes",
							 "showwhich" 	=> "rebels",
							 "dreamvoters"	=> "all");

	$dismodes["allvotes"] = array("dtype"	=> "allvotes",
							 "description" 	=> "All voters",
							 "motiontext" 	=> "yes",
							 "summarytext"	=> "yes",
							 "partysummary"	=> "yes",
							 "showwhich" 	=> "voters",
							 "dreamvoters"	=> "all");

	$dismodes["allpossible"] = array("dtype"	=> "allpossible",
							 "description" 	=> "All possible voters",
							 "summarytext"	=> "yes",
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

	# the sort field
    $sort = db_scrub($_GET["sort"]);
	if ($sort == "")
		$sort = "party";

	# make list of links to other display modes
	$thispage = $divattr["divhref"];
	$tpdisplay = ($display == "summary" ? "" : "&display=$display");
	$tpsort = ($sort == "sort" ? "" : "&sort=$sort");
	$leadch = "<p>"; # get those bars between the links working
    foreach ($dismodes as $ldisplay => $ldismode)
	{
		print $leadch;
		$leadch = " | ";
		$dlink = $thispage.($ldisplay == "summary" ? "" : $ldisplay).$tpsort;
        if ($ldisplay == $display)
			print $ldismode["description"];
        else
            print "<a href=\"$dlink\">".$ldismode["description"]."</a>";
	}


	# Dream MP voting feature
	if (user_isloggedin())
		write_dream_vote($db, $divattr);

	# Summary
	if ($dismode["summarytext"])
    {
    	print "<h2>Summary</h2>";

        $query = "SELECT sum(vote = 'aye') AS ayes,
						 sum(vote = 'no')  AS noes,
						 sum(vote = 'both') AS boths,
						 sum(vote = 'tellaye' or vote = 'tellno') AS tellers
				  FROM pw_vote WHERE division_id = $div_id";
		$row = $db->query_one_row_assoc($query);
        print "<br>On $prettydate, $turnout MPs voted in division no. $div_no in the House of Commons.
            <br>Subject was '$name'
            <br>Votes were ".$row["ayes"]." aye, ".$row["noes"]." no, ".$row["boths"]." both, ".$row["tellers"]." tellers.
            There were $rebellions rebellions against majority party vote.";

        $debate_gid = str_replace("uk.org.publicwhip/debate/", "", $debate_gid);
        $source_gid = str_replace("uk.org.publicwhip/debate/", "", $source_gid);
        if ($debate_gid != "")
		{
            print "<br><a href=\"http://www.theyworkforyou.com/debates/?id=$debate_gid\">Read the full debate</a> leading up to this division";
            print " (on TheyWorkForYou.com)";
        }
        if ($source != "")
    	{
    		print "<br><a href=\"$source\">Check original division listing</a>";
        	print " (on the Parliament website)";
		}
	}

	# motion text paragraph
	if ($dismode["motiontext"])
    {
		# current motion text from the database
		$motion_data = get_wiki_current_value($divattr["motion_key"]);

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


	# Division votes table
	if ($dismode["showwhich"])
    {
		# title for the division table (with explanation and links to the other cases)
		if ($display == "summary")
		{
			print "<h2><a name=\"votes\">Rebel Voters - sorted by $sort</a></h2>\n";
			print "<p>MPs for which their vote in this division differed from the majority vote of their party.
					You can see <a href=\"$thispage&display=allvotes$tpsort\">all votes</a> in this division,
					or <a href=\"$thispage&display=everyvote$tpsort\">every eligible MP</a> who could have
					voted in this division</p>\n";
		}
		elseif ($display == "allvotes")
		{
			print "<h2><a name=\"votes\">All Votes Cast - sorted by $sort</a></h2>\n";
			print "<p>MPs for which their vote in this division differed
					from the majority vote of their party are marked in red.
					Also shows which MPs were ministers at the time of this vote.
					You can also see <a href=\"$thispage&display=allpossible$tpsort\">every eligible MP</a>
					including those who did not vote in this division.</p>\n";
		}
		else
		{
			print "<h2><a name=\"votes\">All MPs Eligible to Vote - sorted by $sort</a></h2>\n";
			print "<p>Includes MPs who were absent (or abstained)
					from this vote.</p>\n";
		}


		# the sort by cases
		print "<table class=\"votes\"><tr class=\"headings\">";
		if ($sort == "name")
			print "<td>MP</td>";
		else
			print "<td><a href=\"$thispage$tpdisplay&sort=name\">MP</a></td>";
		if ($sort == "constituency")
			print "<td>Constituency</td>";
		else
			print "<td><a href=\"$thispage$tpdisplay&sort=constituency\">Constituency</a></td>";
		if ($sort == "party")
			print "<td>Party</td>";
		else
			print "<td><a href=\"$thispage$tpdisplay\">Party</a></td>";
		if ($sort == "vote")
			print "<td>Vote</td>";
		else
			print "<td><a href=\"$thispage$tpdisplay&sort=vote\">Vote</a></td>";
		print "</tr>\n";

		$mptabattr = array("listtype"	=> "division",
							"divdate"	=> $divattr["division_date"],
							"divno"		=> $divattr["division_number"],
							"divid"		=> $divattr["division_id"],  # redundant, but the above two are not used by all tables
							"sortby"	=> $sort,
							"showwhich" => $dismode["showwhich"]);
		mp_table($db, $mptabattr);
		print "</table>";
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
