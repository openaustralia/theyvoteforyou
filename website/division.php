<?php require_once "common.inc";
# $Id: division.php,v 1.94 2005/11/28 22:45:16 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
   	require_once "decodeids.inc";
	require_once "tablepeop.inc";
	require_once "tablemake.inc";
	require_once "tableoth.inc";
    require_once "account/user.inc";
    require_once "database.inc";
    require_once "divisionvote.inc";
    require_once "dream.inc";

    $db = new DB();
    $db2 = new DB();

	# decode the attributes
	$divattr = get_division_attr_decode($db, "");
    if ($divattr == "none") {
        $title = "Division not found";
        pw_header();
?> <p>Public Whip does not have this division.  Perhaps it
    doesn't exist, or it hasn't been added to The Public Whip yet.
    New divisions are added one or two working days after they happen.</p>
    <p><a href="divisions.php">Browse for a division</a> </p>
<?
        pw_footer();
        exit;
    }

	# second division (which we can compare against)
	$divattr2 = get_division_attr_decode($db, "2");
	$singlemotionpage = ($divattr2 == "none");


	$div_id = $divattr["division_id"];
    # current motion text from the database
    $motion_data = get_wiki_current_value("motion", array($divattr["division_date"], $divattr["division_number"], $divattr['house']));
	$name = extract_title_from_wiki_text($motion_data['text_body']);
	$source = $divattr["source_url"];
	$rebellions = $divattr["rebellions"];
	$turnout = $divattr["turnout"];
	$original_motion = $divattr["original_motion"];
	$debate_url = $divattr["debate_url"];
	$source_gid = $divattr["source_gid"];
	$debate_gid = $divattr["debate_gid"];
	$div_no = html_scrub($divattr["division_number"]);
	$this_anchor = $divattr["divhref"];


	# designated voter on this division
	$votertype = "";
	$voter = "";

    $voterattr = get_mpid_attr_decode($db, $db2, "", null);
    if ($voterattr != null)
    {
        $votertype = "mp";
        $voter = $voterattr['mpprop'];

        # brutally find which of the set did the vote
        foreach ($voterattr['mpprops'] as $lkey => $mpprop)
        {
            $query = "SELECT vote FROM pw_vote
                        WHERE division_id = ".$divattr["division_id"]."
                            AND mp_id = ".$mpprop['mpid'];
            $row = $db->query_onez_row_assoc($query);
            if ($row)
            {
                $voter = $mpprop;
                $vote = $row["vote"];
                break;
            }
        }
	}
	else
	{
        $voterattr = get_dreammpid_attr_decode($db, "");
        if ($voterattr != null)
        {
            $votertype = "dreammp";
            $voter = $voterattr['dreammpid'];
            # $vote is calculated in write_single_policy_vote
        }
		else
		{
            $active_policy = user_getactivepolicy();
            if ($active_policy)
			{
                $votertype = "dreammp";
                $voter = $active_policy;
            }
        }
    }

	# calculate the same/different voting pattern so we can work out if it's better to invert the second set of votes
	if (!$singlemotionpage)
    {
    	$lqselect = "SELECT SUM((pw_vote_a.vote = 'tellaye' OR pw_vote_a.vote = 'aye') = (pw_vote_b.vote = 'tellaye' OR pw_vote_b.vote = 'aye')) AS same, ";
		$lqselect .= "      SUM((pw_vote_a.vote = 'tellaye' OR pw_vote_a.vote = 'aye') = (pw_vote_b.vote = 'tellno' OR pw_vote_b.vote = 'no')) AS opposite, ";
    	$lqselect .= "      COUNT(*) AS total";
    	$lqfrom = " FROM pw_mp";
        $lqjoin  = " LEFT JOIN pw_vote AS pw_vote_a ON pw_vote_a.mp_id = pw_mp.mp_id
                        AND pw_vote_a.division_id = ".$divattr["division_id"];
        $lqjoin .= " LEFT JOIN pw_vote AS pw_vote_b ON pw_vote_b.mp_id = pw_mp.mp_id
                        AND pw_vote_b.division_id = ".$divattr2["division_id"];
		$lqwhere = " WHERE pw_vote_a.vote IS NOT null AND pw_vote_b.vote IS NOT null
                       AND pw_vote_a.vote <> 'both' AND pw_vote_b.vote <> 'both'";
		$lqgroupby = " GROUP BY pw_vote_a.division_id"; # would prefer a group by all

	    $lquery = $lqselect.$lqfrom.$lqjoin.$lqwhere.$lqgroupby;
	    if ($bdebug == 1)
	        print "\n<h3>$lquery</h3>\n";
	    $row = $db->query_one_row_assoc($lquery);
		$div2invert = ($row["same"] < $row["opposite"]);
	    if ($bdebug == 1)
			print "<h1>same ".$row["same"]." Opposite ".$row["opposite"]." Total ".$row["total"]."  inv$div2invert </h1>"; # total should be sum of other two
    }

	# make the title
	$title = "$name - ".$divattr["prettydate"]." - Division No. $div_no";
	if (!$singlemotionpage)
	{
		$title .= " <br> &nbsp; compared to Division No. ".$divattr2["division_number"];
		if ($divattr2["prettydate"] == $divattr["prettydate"])
			$title .= " on the same day";
		else
			$title .= " on ".$divattr2["prettydate"];
		if ($div2invert)
			$title .= " (inverted)";
	}

	# constants
	$dismodes = array();
	if ($singlemotionpage)
	{
		$dismodes["summary"] = array("dtype"	=> "summary",
								 "description" 	=> "Summary",
								 "motiontext" 	=> "yes",
								 "summarytext"	=> "yes",
								 "partysummary"	=> "yes",
								 "showwhich" 	=> "rebels",
								 "ministerial" 	=> "yes",
								 "dreamvoters"	=> "all",
                                 "tooltip"      => "Overview of division");

		$dismodes["allvotes"] = array("dtype"	=> "allvotes",
								 "description" 	=> "All voters",
								 "motiontext" 	=> "yes",
								 "summarytext"	=> "yes",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "voters",
                                 "tooltip"      => "Every MP who cast a vote in the division");

		$dismodes["allpossible"] = array("dtype"	=> "allpossible",
								 "description" 	=> "All eligible voters",
								 "motiontext" 	=> "yes",
								 "summarytext"	=> "yes",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "allpossible",
                                 "tooltip"      => "Show even MPs who did not vote but could have" );
	}

	# two motion page
	else
	{
        # TODO: Add "tooltip" entries to these
		$dismodes["opposites"] = array("dtype"	=> "opposites",
								 "description" 	=> "Opposites",
								 "motiontext" 	=> "yes",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "rebels");

		$dismodes["differences"] = array("dtype"	=> "differences",
								 "description" 	=> "Differences",
								 "motiontext" 	=> "yes",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "changes");

		$dismodes["allvotes"] = array("dtype"	=> "allvotes",
								 "description" 	=> "All voters",
								 "motiontext" 	=> "yes",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "voters");

		$dismodes["allpossible"] = array("dtype"	=> "allpossible",
								 "description" 	=> "All eligible voters",
								 "motiontext" 	=> "yes",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "allpossible");
	}

	# work out which display mode we are in
	$display = $_GET["display"];
	if (!$dismodes[$display])
	{
		if ($_GET["showall"] == "yes")
			$display = "allvotes"; # legacy
		elseif ($singlemotionpage)
			$display = "summary"; # default
		else # two motion page
			$display = "differences"; # default
	}
	$dismode = $dismodes[$display];

	# the sort field
    $sort = db_scrub($_GET["sort"]);
	if ($sort == "")
		$sort = "party";

	# make list of links to other display modes
	$thispage = $divattr["divhref"];
	if (!$singlemotionpage)
	{
		if ($divattr2["division_date"] <> $divattr["division_date"])
			$thispage .= "&date2=".$divattr2["division_date"];
		$thispage .= "&number2=".$divattr2["division_number"];
	}
	$tpdisplay = ($display == "summary" ? "" : "&display=$display");
	$tpsort = ($sort == "party" ? "" : "&sort=$sort");
    $second_links = dismodes_to_second_links($thispage, $dismodes, $tpsort, $display);

    # Display title and second nav links
	pw_header();

	# Summary
	if ($dismode["summarytext"])
    {
        $query = "SELECT sum(vote = 'aye') AS ayes,
						 sum(vote = 'no')  AS noes,
						 sum(vote = 'both') AS boths,
						 sum(vote = 'tellaye' or vote = 'tellno') AS tellers
				  FROM pw_vote WHERE division_id = $div_id";
		$row = $db->query_one_row_assoc($query);

		print "<p>";
		if ($row['ayes'] > $row['noes'])
	        print "The Aye-voters won by ".$row["ayes"]." to ".$row["noes"];
		else
	        print "The No-voters won by ".$row["noes"]." to ".$row["ayes"];
        print " (majority " . (abs($row["noes"] - $row["ayes"])) . ") ";
		print " with ".$row["tellers"]." tellers";
		if ($row['both'] != 0)
			print " and ".$row["boths"]." voting both";
        print ", making a turnout of " . ($row["noes"] + $row["ayes"] + $row["tellers"] + $row["boths"]);
		print ". ";
        print "</p>\n";

		# cross-over case listing vote of single MP
		if ($votertype == "mp")
		{
			print "<p>And <a href=\"mp.php?".$voter['mpanchor']."\">".$voter['name']." MP</a> (".$voter['constituency'].")";
			if ($vote == 'aye')
				print " voted Aye.";
			else if ($vote == 'no')
				print " voted No.";
			else if ($vote == 'tellaye')
				print " was a Teller for the Ayes.";
			else if ($vote == 'tellno')
				print " was a Teller for the Noes.";
			else if ($vote == 'both')
				print " voted both ways.";
			else
				print " did not vote.";
			print "</p>\n";
			# state if it is rebellion??
		}

		# crossover page for updating and changing a policy vote
		elseif ($votertype == "dreammp")
	        $vote = write_single_policy_vote($db, $divattr, $voter);
	}

	# motion text paragraph
	if ($dismode["motiontext"])
    {
		if ($singlemotionpage)
		{
	    	# Show motion text
            $edit_link = "account/wiki.php?type=motion&date=".$divattr["division_date"].
                "&number=".$divattr["division_number"]."&house=".$divattr["house"].
                "&rr=".urlencode($_SERVER["REQUEST_URI"]);
            $history_link = "edits.php?type=motion&date=".$divattr["division_date"].
                "&number=".$divattr["division_number"]."&house=".$divattr["house"];
            $discuss_url = "division-forum.php?date=".$divattr["division_date"].
                "&number=".$divattr["division_number"]."&house=".$divattr["house"];

            $db->query("SELECT * FROM pw_dyn_user WHERE user_id = " . $motion_data['user_id']);
            $row = $db->fetch_row_assoc();
            $last_editor = html_scrub($row['user_name']);

	        print "<div class=\"motion\">";
	        if ($motion_data['user_id'] == 0) {
                print "<p><strong>Description automatically extracted from the debate, 
                    please <a href=\"$edit_link\">edit it</a> to make it better.</strong></p>";
	        }
            $description = extract_motion_text_from_wiki_text($motion_data['text_body']);
            print $description;
            
	        if ($motion_data['user_id'] != 0)  {
                print "<p align=\"right\">";
	            print " (last edited ".  relative_time($motion_data["edit_date"]) .  " by $last_editor) ";
                print "<a href=\"$edit_link\">Edit description</a>";
                if ($discuss_url)
                    print ' | <a href="'.htmlspecialchars($discuss_url).'">Discuss changes</a>';
                if ($history_link) {
                    # commented out, as confusing and deprecated
                    print '<!-- | <a href="'.htmlspecialchars($history_link).'">History</a>-->';
                }
            }

	        print "</div>\n";

			print "<p>"; 
	        $debate_gid = str_replace("uk.org.publicwhip/debate/", "", $debate_gid);
	        $source_gid = str_replace("uk.org.publicwhip/debate/", "", $source_gid);
	        if ($debate_gid != "") {
	            print "<a href=\"http://www.theyworkforyou.com/debates/?id=$debate_gid\">Full debate</a>";
	        }
	        if ($source != "") {
                if ($debate_gid)
                    print " | ";
	    		print "<a href=\"$source\">Original Hansard</a>";
			}

	        print "</p>\n";
		}

		# print the two motion type
		else
		{
            $motion_data_a = get_wiki_current_value("motion", array($divattr["division_date"], $divattr["division_number"], $divattr['house']));
			$titlea = "<a href=\"".$divattr["divhref"]."\">".$divattr["name"]." - ".$divattr["prettydate"]." - Division No. ".$divattr["division_number"]."</a>";
	        print "<h2><a name=\"motion\">Motion (a) ".($motion_data_a['user_id'] == 0 ? " (unedited)" : "")."</a>: $titlea</h2>";
	        print "<div class=\"motion\">".extract_motion_text_from_wiki_text($motion_data_a['text_body'])."</div>\n";

            $motion_data_b = get_wiki_current_value("motion", array($divattr2["division_date"], $divattr2["division_number"], $divattr2['house']));
			$titleb = "<a href=\"".$divattr2["divhref"]."\">".$divattr2["name"]." - ".$divattr2["prettydate"]." - Division No. ".$divattr2["division_number"]."</a>";
	        print "<h2>Motion (b) ".($motion_data_b['user_id'] == 0 ? " (unedited)" : "").": $titleb</h2>";
	        print "<div class=\"motion\">".extract_motion_text_from_wiki_text($motion_data_b['text_body'])."</div>\n";
		}
	}


	# Work out proportions for party voting (todo: cache)
	if ($dismode["partysummary"])
	    print_party_summary_division($db, $div_id, "");


	# Division votes table
	if ($dismode["showwhich"])
    {
		if ($singlemotionpage)
		{
			# title for the division table (with explanation and links to the other cases)
			if ($display == "summary")
			{
				print "<h2><a name=\"votes\">Rebel Voters - sorted by $sort</a></h2>\n";
				print "<p>MPs for which their vote in this division differed from the majority vote of their party.
						You can see <a href=\"$thispage&display=allvotes$tpsort\">all votes</a> in this division,
						or <a href=\"$thispage&display=allpossible$tpsort\">every eligible MP</a> who could have
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
		}

		else
		{
			if ($display == "opposites")
			{
				print "<h2><a name=\"votes\">Opposite in Votes - sorted by $sort</a></h2>\n";
				print "<p>MPs for which their vote on Motion (a) was opposite to their";
				if ($div2invert)
					print " <b>inverted</b>";
				print " vote on Motion (b).\n";
				print " You can also see <a href=\"$thispage&display=differences$tpsort\">all differing votes</a>
						between these two divisions,
						or simply <a href=\"$thispage&display=allvotes$tpsort\">all the votes</a>.</p>\n";
			}
			elseif ($display == "differences")
			{
				print "<h2><a name=\"votes\">Difference in Votes - sorted by $sort</a></h2>\n";
				print "<p>MPs for which their vote on Motion (a) differed from their";
				if ($div2invert)
					print " <b>inverted</b>";
				print " vote on Motion (b).\n";
				print " You can also see <a href=\"$thispage&display=opposites$tpsort\">just opposite votes</a>
						between these two divisions,
						or simply <a href=\"$thispage&display=allvotes$tpsort\">all the votes</a>.</p>\n";
			}
			elseif ($display == "allvotes")
			{
				print "<h2><a name=\"votes\">All Votes Cast - sorted by $sort</a></h2>\n";
				print "<p>All MP who voted in one or other of the two divisions.
						Also shows which MPs were ministers at the time of the first vote.</p>\n";
			}
			else  # all votes
			{
				print "<h2><a name=\"votes\">All MPs Eligible to Vote - sorted by $sort</a></h2>\n";
				print "<p>Includes MPs who were absent (or abstained)
						from the first vote vote.</p>\n";
			}
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

		if ($singlemotionpage)
		{
			if ($sort == "vote")
				print "<td>Vote</td>";
			else
				print "<td><a href=\"$thispage$tpdisplay&sort=vote\">Vote</a></td>";
		}
		else
		{
			if ($sort == "vote")
				print "<td>Vote (a)</td>";
			else
				print "<td><a href=\"$thispage$tpdisplay&sort=vote\">Vote (a)</a></td>";
			if ($sort == "vote2")
				print "<td>Vote (b)</td>";
			else
				print "<td><a href=\"$thispage$tpdisplay&sort=vote2\">Vote (b)</a></td>";
		}
		print "</tr>\n";

		$mptabattr = array("listtype"	=> "division",
							"divdate"	=> $divattr["division_date"],
							"divno"		=> $divattr["division_number"],
							"divid"		=> $divattr["division_id"],  # redundant, but the above two are not used by all tables
							"sortby"	=> $sort,
							"showwhich" => $dismode["showwhich"],
							"ministerial" => $dismode["ministerial"],
                            "house"     => $divattr["house"]);


		if (!$singlemotionpage)
		{
			$mptabattr["listtype"] = "division2";
			$mptabattr["divdate2"] = $divattr2["division_date"];
			$mptabattr["divno2"] = $divattr2["division_number"];
			$mptabattr["divid2"] = $divattr2["division_id"];
			$mptabattr["div2invert"] = $div2invert;
		}

		mp_table($db, $mptabattr);
		print "</table>";
	}


	if ($dismode["dreamvoters"])
	{
        # Show Dream MPs who voted in this division and their votes
        $db->query("SELECT name, pw_dyn_dreammp.dream_id, vote, user_name
					FROM pw_dyn_dreammp, pw_dyn_dreamvote, pw_dyn_user
            		WHERE pw_dyn_dreamvote.dream_id = pw_dyn_dreammp.dream_id
						AND pw_dyn_user.user_id = pw_dyn_dreammp.user_id
						AND pw_dyn_dreamvote.division_date = '".$divattr["division_date"]."'
						AND pw_dyn_dreamvote.division_number = '".$divattr["division_number"]."'
            			AND NOT private");
        if ($db->rows() > 0)
        {
            $prettyrow = 0;
            print "<h2><a name=\"dreammp\">Policies</a></h2>";
            print "<p>The following policies have selected this division.  You can use this
               to help you work out the meaning of the vote.";
            print "<table class=\"divisions\"><tr class=\"headings\">";
            print "<td>Policy</td><td>Vote (in this division)</td>";
            while ($row = $db->fetch_row_assoc()) {
                $prettyrow = pretty_row_start($prettyrow);
                $vote = $row["vote"];
                if ($vote == "both")
                    $vote = "abstain";
                print "<td><a href=\"policy.php?id=" . $row["dream_id"] . "\">";
                print $row["name"] . "</a></td>";
                print "<td>" . $vote . "</td>";
                print "</tr>";
            }
            print "</table>";
            print "<p><a href=\"account/addpolicy.php\">Make a new policy</a>";
        }
    }

?>

<?php pw_footer() ?>
