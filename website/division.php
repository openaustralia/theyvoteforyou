<?php require_once "common.inc";
# $Id: division.php,v 1.71 2005/10/04 18:24:32 goatchurch Exp $
# vim:sw=4:ts=4:et:nowrap

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    $db = new DB();
    $db2 = new DB();

   	include "decodeids.inc";
	include "tablepeop.inc";
	include "tablemake.inc";
	include "tableoth.inc";


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
	$singlemotionpage = ($divattr2 == "none");


	$div_id = $divattr["division_id"];
    # current motion text from the database
    $motion_data = get_wiki_current_value($divattr["motion_key"]);
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
	$voterattr = get_dreammpid_attr_decode($db, "");
	if ($voter2attr != null)
	{
		$votertype = "dreammp";
		$voter = $voter2attr['dreammpid'];
		$query = "SELECT vote FROM pw_dyn_dreamvote
					WHERE division_date = ".$divattr["division_date"]." AND division_number = ".$divattr["division_number"]."
						AND dream_id = $voter";
		$row = $db->query_one_row_assoc($query);
		$vote = $row["vote"];
	}
	else
	{
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
			$votertype = "";  # could have a designated party if we wanted.
			$voter = "";
		}
	}


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
	}

	# two motion page
	else
	{
		$dismodes["differences"] = array("dtype"	=> "differences",
								 "description" 	=> "Differences",
								 "motiontext" 	=> "yes",
								 "showwhich" 	=> "rebels");

		$dismodes["allvotes"] = array("dtype"	=> "allvotes",
								 "description" 	=> "All voters",
								 "motiontext" 	=> "yes",
								 "showwhich" 	=> "voters");

		$dismodes["allpossible"] = array("dtype"	=> "allpossible",
								 "description" 	=> "All possible voters",
								 "motiontext" 	=> "yes",
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
		else
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
		$thispage .= "&date2=".$divattr2["division_date"]."&number2=".$divattr2["division_number"];
		if ($div2invert)
            $thispage .= "&div2invert=yes";
	}
	$tpdisplay = ($display == "summary" ? "" : "&display=$display");
	$tpsort = ($sort == "party" ? "" : "&sort=$sort");
    $second_links = array();
    foreach ($dismodes as $ldisplay => $ldismode)
	{
        $dlink = $thispage.($ldisplay == "summary" ? "" : "&display=$ldisplay").$tpsort;
        array_push($second_links, "<a class=\"".($ldisplay == $display ? "on" : "off")."\" href=\"$dlink\">".$ldismode["description"]."</a>");
	}

    # Display title and second nav links
	include "header.inc";

	# Dream MP voting feature
	if ($divattr2 == "none" and user_isloggedin())
		write_dream_vote($db, $divattr);

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
		print " with ".$row["tellers"]." tellers";
		if ($row['both'] != 0)
			print " and ".$row["boths"]." voting both";
		print ".</p>\n";

		if ($votertype = "mp")
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
	}

	# motion text paragraph
	if ($dismode["motiontext"])
    {
		if ($singlemotionpage)
		{
	    	# Show motion text
	        if ($motion_data['user_id'] == 0) {
		        print "<h2><a name=\"motion\">Motion</a></h2>";
	            print "<p>Procedural text extracted from the debate,
	            so you can try to work out what 'aye' (for the motion) and 'no' (against the motion) meant.
	            This is for guidance only, irrelevant text may be shown, crucial text may be missing.
	            </p>";
	        } else {
	        	# trial run of printing nothing here before the motion text
	            print "<p></p>";
	        }
	        print "<div class=\"motion\">" . extract_motion_text_from_wiki_text($motion_data['text_body']); # TODO: validate this text_body
	        print "</div>\n";

			print "<p>"; 
	        $debate_gid = str_replace("uk.org.publicwhip/debate/", "", $debate_gid);
	        $source_gid = str_replace("uk.org.publicwhip/debate/", "", $source_gid);
	        if ($debate_gid != "")
			{
	            print "<a href=\"http://www.theyworkforyou.com/debates/?id=$debate_gid\">Full debate</a>";
	        }
	        if ($source != "")
	    	{
	            print " | ";
	    		print "<a href=\"$source\">Original Hansard</a>";
			}

	    	print " | <a href=\"account/wiki.php?key=".$divattr["motion_key"]."&r=" .
	         urlencode($_SERVER["REQUEST_URI"]) . "\">Edit text</a>";
	        if ($motion_data['user_id'] != 0) {
	            $db->query("select * from pw_dyn_user where user_id = " . $motion_data['user_id']);
	            $row = $db->fetch_row_assoc();
	            $last_editor = html_scrub($row['user_name']);
#	            print " (last edited by $last_editor on " .
#	                $motion_data['edit_date'] . ")";
	        } else {
#	            print " (be the first to edit this)";
	        }
	        print "</p>\n";
		}

		# print the two motion type
		else
		{
			$motion_data_a = get_wiki_current_value($divattr["motion_key"]);
			$titlea = "<a href=\"".$divattr["divhref"]."\">".$divattr["name"]." - ".$divattr["prettydate"]." - Division No. ".$divattr["division_number"]."</a>";
	        print "<h2><a name=\"motion\">Motion (a) ".($motion_data_a['user_id'] == 0 ? " (unedited)" : "")."</a>: $titlea</h2>";
	        print "<div class=\"motion\">".extract_motion_text_from_wiki_text($motion_data_a['text_body'])."</div>\n";

			$motion_data_b = get_wiki_current_value($divattr2["motion_key"]);
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
		}

		else
		{
			if ($display == "differences")
			{
				print "<h2><a name=\"votes\">Difference in Voter - sorted by $sort</a></h2>\n";
				print "<p>MPs for which their vote on Motion (a) differed from their";
				if ($div2invert)
					print " <b>inverted</b>";
				print " vote on Motion (b)</p>\n";
			}
			elseif ($display == "allvotes")
			{
				print "<h2><a name=\"votes\">All Votes Cast - sorted by $sort</a></h2>\n";
				print "<p>All MP who voted in one or other of the two divisions.
						Also shows which MPs were ministers at the time of the first vote.</p>\n";
			}
			else
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



	# Show Dream MPs who voted in this division and their votes
        $db->query("select name, pw_dyn_dreammp.dream_id, vote, user_name from pw_dyn_dreammp, pw_dyn_dreamvote, pw_dyn_user
            where pw_dyn_dreamvote.dream_id = pw_dyn_dreammp.dream_id and
            pw_dyn_user.user_id = pw_dyn_dreammp.user_id and
            pw_dyn_dreamvote.division_date = '$date' and pw_dyn_dreamvote.division_number = '$div_no' ");
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
                print "<td><a href=\"dreammp.php?id=" . $row["dream_id"] . "\">";
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
