<?php require_once "common.inc";
# $Id: division.php,v 1.146 2010/05/10 06:47:28 publicwhip Exp $
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
    require_once "distances.inc";
	require_once "parliaments.inc";

function no_division_found($plural)
{
	$title = "Division$plural not found";
    pw_header();
	print "<p>Public Whip does not have this/these divisions.  Perhaps it
    		  doesn't exist, or it hasn't been added to The Public Whip yet.
		      New divisions are added one or two working days after they happen.</p>
		     <p><a href=\"divisions.php\">Browse for a division</a> </p>";
	pw_footer();
	exit;
}

# decode the attributes
	$divattr = get_division_attr_decode( "");
    if ($divattr == "none")
		no_division_found("");

	# second division (which we can compare against)
	$divattr2 = get_division_attr_decode( "2");
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
	$house = $divattr["house"];
    $clock_time = $divattr["clock_time"];
    $clock_time = preg_replace("/:00$/","",$clock_time);
    $clock_time = preg_replace("/^0/","",$clock_time);

    $colour_scheme = $house;

    $showhits = preg_match("/.*?house=z/", $referrer);


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

            $query = "SELECT vote FROM pw_vote WHERE division_id = ? AND mp_id = ? LIMIT 1" /* the tellaye+no vote is twice */;
            $row=$pwpdo->get_single_row($query,array($divattr["division_id"],$mpprop['mpid']));
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
	    $query = 'SELECT nvotessame, nvotesdiff FROM pw_cache_divdiv_distance WHERE pw_cache_divdiv_distance.division_id = ? AND pw_cache_divdiv_distance.division_id2 = ?';
        $row=$pwpdo->get_single_row($query,array($divattr["division_id"],$divattr2["division_id"]));
        $div2invert = (($row != null) && ($row["nvotessame"] < $row["nvotesdiff"]));
    }

    # make the title
    $title = "$name - ".$divattr["prettydate"]." ";
    if ($clock_time)
        $title .= " at $clock_time";
    if (!$singlemotionpage)
    {
        $title = "Comparison of Divisions: " . $title;
        $title .= " <i>with</i> Division No. ".$divattr2["division_number"];
        if ($divattr2["prettydate"] == $divattr["prettydate"])
            $title .= " <i>on the same day</i>";
        else
            $title .= " on ".$divattr2["prettydate"];
        $clock_time2 = $divattr2["clock_time"];
        $clock_time2 = preg_replace("/:00$/","",$clock_time2);
        $clock_time2 = preg_replace("/^0/","",$clock_time2);
        $title .= " at $clock_time2"; 
    } 
    else 
        ;#$title .= " - ".ucfirst($house). " Division No. $div_no";

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
								 "listsimilardivisions" => "", #short
                                 "tooltip"      => "Overview of division");

		$dismodes["allvotes"] = array("dtype"	=> "allvotes",
								 "description" 	=> "All voters",
								 "motiontext" 	=> "yes",
								 "summarytext"	=> "",
								 "partysummary"	=> "",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "voters",
                                 "tooltip"      => "Every MP who cast a vote in the division");

        $dismodes["slab"] = array("dtype"       => "slab",
                                 "summarytext"  => "yes",
                                 "description"  => "One view",
                                 "motiontext"   => "",
                                 "showwhich"    => "slab",
                                 "ministerial"  => "yes",
                                 "tooltip"      => "Show all votes as one compressed table" );
		$dismodes["allpossible"] = array("dtype"	=> "allpossible",
								 "description" 	=> "All eligible voters",
								 "motiontext" 	=> "yes",
								 "summarytext"	=> "yes",
								 "partysummary"	=> "yes",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "allpossible",
                                "tooltip"      => "Show even MPs who did not vote but could have" );

		$dismodes["similardivisionsparl"] = array("dtype"	=> "similardivisionsparl",
								 "description" 	=> "Similar Divisions",
								 "motiontext" 	=> "",
								 "summarytext"	=> "",
								 "listsimilardivisions" => "thisparliament",
                                 "tooltip"      => "Show all divisions in order of similarity of vote in this Parliament" );

		#$dismodes["similardivisionsall"] = array("dtype"	=> "similardivisionsall",
		#						 "description" 	=> "All Similar Divisions",
		#						 "motiontext" 	=> "yes",
		#						 "summarytext"	=> "yes",
		#						 "listsimilardivisions" => "all",
        #                        "tooltip"      => "Show all divisions in order of similarity of vote in all time" );

        $dismodes["policies"] = array("dtype"       => "policies",
                                 "description"  => "Policies",
                                 "policydata"   => "yes",
                                 "summarytext"  => "yes",
                                 "motiontext"   => "yes",
								 "dreamvoters"	=> "all",
                                 "tooltip"      => "Show or change the polices which vote on this division" );

    }

	# two motion page
	else
	{
        # TODO: Add "tooltip" entries to these
		$dismodes["opposites"] = array("dtype"	=> "opposites",
								 "description" 	=> "Opposing votes",
								 "motiontext" 	=> "yes",
								 "ministerial" 	=> "yes",
								 "showwhich" 	=> "rebels");

		$dismodes["differences"] = array("dtype"	=> "differences",
								 "description" 	=> "Changed votes",
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
		$thispageswap = $divattr2["divhref"];
		if ($divattr2["division_date"] <> $divattr["division_date"])
		{
			$thispage .= "&date2=".$divattr2["division_date"];
			$thispageswap .= "&date2=".$divattr["division_date"];
		}
		$thispage .= "&number2=".$divattr2["division_number"];
		$thispageswap .= "&number2=".$divattr["division_number"];
	}
	$tpdisplay = ($display == "summary" ? "" : "&display=$display");
	$tpsort = ($sort == "party" ? "" : "&sort=$sort");
    if ($votertype == "dreammp")
        $tpsort .= "&dmp=$voter";
    $second_links = dismodes_to_second_links($thispage, $dismodes, $tpsort, $display);

    # Display title and second nav links
    $second_type = "tabs";
    pw_header();

	# Summary
	if ($dismode["summarytext"])
    {
		// alternatively this could sum from pw_whip_cache
        $query = "SELECT sum(vote = 'aye') AS ayes,
						 sum(vote = 'no')  AS noes,
						 sum(vote = 'both') AS boths,
						 sum(vote = 'tellaye' or vote = 'tellno') AS tellers
				  FROM pw_vote WHERE division_id = ?";
        $row=$pwpdo->get_single_row($query,array($div_id));

		print "<p>";
		$ayenodiff = $row["ayes"] - $row["noes"];
        /*if ($ayenodiff > 0)
	        print "The <b>".($house=="lords"?"Contents":"Ayes")."</b> had a Majority of ".($ayenodiff)." (".$row["ayes"]." to ".$row["noes"].")";
		elseif ($row['ayes'] < $row['noes'])
	        print "The <b>".($house=="lords"?"Not-Contents":"Noes")."</b> had a Majority of ".(-$ayenodiff)." (".$row["noes"]." to ".$row["ayes"].")";
        else
            print "The vote was a <b>tie</b> (".$row["ayes"]." to ".$row["noes"].")";
		print " with ".$row["tellers"]." tellers";
		if ($row['both'] != 0)
			print " and ".$row["boths"]." voting both";
        print ", making a turnout of " . ($row["noes"] + $row["ayes"] + $row["tellers"] + $row["boths"]);
		print ". ";
        if ($ayenodiff == 0)
            print " <b>This means the Speaker will cast his vote in favour of the Government.</b>";
        #print "  Aye majority=".$divattr["aye_majority"].".";
        print "</p>\n";
        */

		# cross-over case listing vote of single MP
		if ($votertype == "mp")
		{
            $actiontext = extract_action_text_from_wiki_text($motion_data['text_body']);
            //print "<pre>";
            //print_r($actiontext);
            //print "</pre>";
			
            print "<p class=\"mpondivision\"><a href=\"mp.php?".$voter['mpanchor']."\">".$voter['name'].($house == "lords" ? "</a>" : " MP, ".$voter['constituency']."</a>");
			if ($actiontext[$vote])
            {
                print " voted <em>".$actiontext[$vote]."</em>";
            }
            else if (($vote == 'aye' || $vote == 'tellaye' || $vote == 'no' || $vote == 'tellno') && ($ayenodiff != 0))
            {
                if (($vote == 'aye' || $vote == 'tellaye') == ($ayenodiff >= 0))
                    print " voted <em>with the majority</em>";
                else
                    print " voted <em>in the minority</em>";
                if ($vote == 'aye')
				    print ($house=="lords")?" (Content).":" (Aye).";
    			else if ($vote == 'no')
	    			print ($house=="lords")?" (Not-Content).":" (No).";
		    	else if ($vote == 'tellaye')
			    	print ($house=="lords")?" (Teller for the Contents).":" (Teller for the Ayes).";
    			else if ($vote == 'tellno')
	    			print ($house=="lords")?" (Teller for the Not-Contents).":" (Teller for the Noes).";
            }
            else
            {
                if ($vote == 'aye')
				    print ($house=="lords")?" was Content.":" voted Aye.";
    			else if ($vote == 'no')
	    			print ($house=="lords")?" was Not-Content.":" voted No.";
		    	else if ($vote == 'tellaye')
			    	print ($house=="lords")?"was a Teller for the Contents":" was a Teller for the Ayes.";
    			else if ($vote == 'tellno')
	    			print ($house=="lords")?"was a Teller for the Not-Contents":" was a Teller for the Noes.";
		    	else if ($vote == 'both')
			    	print " voted <em>both ways</em>.";
    			else if (($vote == 'abstention') and ($house == 'scotland'))
	    			print " abstained";
    			else
	    			print ($house=="lords") ? " was absent" : " did not vote.";
			}
            print "</p>\n";
			# state if it is rebellion??
		}
    }

		# crossover page for updating and changing a policy vote
	if ($dismode["policydata"])
    {
        if ($votertype == "dreammp")
	        $vote = write_single_policy_vote($db, $divattr, $voter);
	}

    # policies table which hold votes on this division
	if ($dismode["dreamvoters"])
	{
        # Show Dream MPs who voted in this division and their votes
        $query=("SELECT name, pw_dyn_dreammp.dream_id, vote, user_name, private
					FROM pw_dyn_dreammp, pw_dyn_dreamvote, pw_dyn_user
            		WHERE pw_dyn_dreamvote.dream_id = pw_dyn_dreammp.dream_id
						AND pw_dyn_user.user_id = pw_dyn_dreammp.user_id
						AND pw_dyn_dreamvote.division_date = ?
						AND pw_dyn_dreamvote.division_number = ?
            			AND private <> 1");
        $allRows=$pwpdo->fetch_all_rows($query,array($divattr["division_date"],$divattr["division_number"]));
            $prettyrow = 0;
            print "<h2><a name=\"dreammp\">Policies</a></h2>";
            print "<p>The following policies have selected this division.  You can use this
               to help you work out the meaning of the vote.  Or <a href=\"/policies.php\">list all policies</a>.";
            print "<table class=\"divisions\"><tr class=\"headings\">";
            print "<td>Policy</td><td>Vote (in this division)</td>";

            if (count($allRows) == 0)
            {
                pretty_row_start($prettyrow);
                print "<td colspan=\"2\">No policies voted in this division</td></tr>\n";
            }
            foreach ($allRows as $row)
            {
                $prettyrow = pretty_row_start($prettyrow);
                $vote = $row["vote"];
                if ($vote == "both")
                    $vote = "abstain";
                print "<td><a href=\"policy.php?id=" . $row["dream_id"] . "\">";
                print $row["name"] . "</a>";
                if ($row["private"] == 2)
                    print " <i>(provisional)</i>";
                print "</td>";
                print "<td>" . vote_display_in_table($vote, 0) . "</td>";
                print "</tr>\n";
            }
            print "</table>";
            print "<p><a href=\"account/addpolicy.php\">Make a new policy</a>";
    }


	# motion text paragraph
	if ($dismode["motiontext"])
    {
		if ($singlemotionpage)
		{
	    	# Show motion text
            /**$edit_link = "account/wiki.php?type=motion&date=".$divattr["division_date"].
                "&number=".$divattr["division_number"]."&house=".$divattr["house"].
                "&rr=".urlencode($_SERVER["REQUEST_URI"]);
            $history_link = "edits.php?type=motion&date=".$divattr["division_date"].
                "&number=".$divattr["division_number"]."&house=".$divattr["house"];
            $discuss_url = "division-forum.php?date=".$divattr["division_date"].
                "&number=".$divattr["division_number"]."&house=".$divattr["house"];

            $db->query("SELECT * FROM pw_dyn_user WHERE user_id = " . $motion_data['user_id']);
            $row = $db->fetch_row_assoc();
            $last_editor = html_scrub($row['user_name']);
            **/
	        if (($divattr["house"] == "lords") and ($divattr["division_date"] >= "2009-01-21"))
            {
                $ldasess = "2008_09";
                $ldadate = str_replace("-", "", $divattr["division_date"]);
                $ldanum = "/number/".$divattr["division_number"];
                $ldalink = "http://services.parliament.uk/LordsDivisionsAnalysis/session/$ldasess/division/$ldadate$ldanum";
                
                # annoying waste of space, these links
                #print "<p style=\"background-color:#ffcdff; border:thin red solid; text-align:center\">
                #       <b>New:</b> This division listed under <a href=\"$ldalink\">Lords Division Analysis</a></p>\n";
            }

            print "<div class=\"motion\">";
	        //if ($motion_data['user_id'] == 0) {
            //    print "<p><strong>Description automatically extracted from the debate,
            //        please <a href=\"$edit_link\">edit it</a> to make it better.</strong></p>";
	        //}
            $description = extract_motion_text_from_wiki_text($motion_data['text_body']);
            print $description;

            print "<p>";
	        if ($debate_gid != "")
			{
				if ($divattr["house"] == "lords")
		        	$debate_gid = "lords/?id=".str_replace("uk.org.publicwhip/lords/", "", $debate_gid);
                else if ($divattr["house"] == "scotland")
					$debate_gid = "sp/?id=".str_replace("uk.org.publicwhip/spor/", "", $debate_gid);
		        else
					$debate_gid = "debates/?id=".str_replace("uk.org.publicwhip/debate/", "", $debate_gid);
                print "<b><a href=\"http://www.theyworkforyou.com/$debate_gid\" title=\"Links to debate shown at www.theyworkforyou.com\">Debate in Parliament</a></b> | ";
	        }

            if ($divattr["division_date"] <= '2005-03-17')
            {
                $millbankurl = $divattr["house"]."/".substr($divattr["division_date"], 0, 4)."/".substr($divattr["division_date"], 5, 2)."/".substr($divattr["division_date"], 8, 2)."/division_".$divattr["division_number"];
                print "<b><a href=\"http://hansard.millbanksystems.com/$millbankurl\" title=\"Debate hosted by millbank systems\">Historical Hansard</a></b> | "; 
            }

	        $source_gid = str_replace("uk.org.publicwhip/debate/", "", $source_gid);
	        if ($source != "") 
	    		print "<b><a href=\"$source\" title=\"The original record of vote as reported by Hansard\">".($debate_gid ? "Source" : "Online Hansard")."</a></b> | ";
		
           // print "<b><a href=\"$edit_link\" title=\"Edit and improve this description\">Edit</a></b>";
            //print " (<a href=\"faq.php#motionedit\">learn more</a>)";
           // if ($discuss_url)
           //     print ' | <b><a href="'.htmlspecialchars($discuss_url).'" title="Forum page for this vote, including record of changes">Discussion</a></b>';
            #if ($history_link)  # commented out, as confusing and deprecated
            #    print '<a href="'.htmlspecialchars($history_link).'">History</a>';
            //if ($motion_data['user_id'] != 0)
            //    print " (last edited ".  relative_time($motion_data["edit_date"]) .  " by " . pretty_user_name($db2, $last_editor).") ";
            print "</div>\n";
		}

		# print the two motion type
		else
		{
			print "<p>(<a href=\"$thispageswap\">Swap the two divisions around</a>).</p>";

            $motion_data_a = get_wiki_current_value("motion", array($divattr["division_date"], $divattr["division_number"], $divattr['house']));
			$titlea = "<a href=\"".$divattr["divhref"]."\">".extract_title_from_wiki_text($motion_data_a["text_body"])." - ".$divattr["prettydate"]." at $clock_time - Division No. ".$divattr["division_number"]."</a>";
	        print "<h2><a name=\"motion\">Vote (a) ".($motion_data_a['user_id'] == 0 ? " (unedited)" : "")."</a>: $titlea</h2>";
	        print "<div class=\"motion\">".extract_motion_text_from_wiki_text($motion_data_a['text_body'])."</div>\n";

            $motion_data_b = get_wiki_current_value("motion", array($divattr2["division_date"], $divattr2["division_number"], $divattr2['house']));
			$titleb = "<a href=\"".$divattr2["divhref"]."\">".extract_title_from_wiki_text($motion_data_b["text_body"])." - ".$divattr2["prettydate"]." at $clock_time2 - Division No. ".$divattr2["division_number"]."</a>";
	        print "<h2>Vote (b) ".($motion_data_b['user_id'] == 0 ? " (unedited)" : "").": $titleb</h2>";
	        print "<div class=\"motion\">".extract_motion_text_from_wiki_text($motion_data_b['text_body'])."</div>\n";
		}
	}

if (true===function_exists('advertisement')) {
    advertisement('division');
}

	# Work out proportions for party voting (todo: cache)
	if ($dismode["partysummary"]) {
	    print_party_summary_division( $div_id, "", $divattr['house']);
    }

	# Division votes table
	if ($dismode["showwhich"])
    {
		if ($singlemotionpage)
		{
			# title for the division table (with explanation and links to the other cases)
			if ($display == "summary")
			{
				print "<h2><a name=\"votes\">Rebel Voters - sorted by $sort</a></h2>\n";
				print "<p>".($house == "lords" ? "Lords" : "MPs")."
						for which their vote in this division differed from the majority vote of their party.
						You can see <a href=\"$thispage&display=allvotes$tpsort\">all votes</a> in this division,
						or <a href=\"$thispage&display=allpossible$tpsort\">every eligible ".($house == "lords" ? "lord" : "MP")."</a> who could have
						voted in this division</p>\n";
			}
			elseif ($display == "allvotes")
			{
				print "<h2><a name=\"votes\">All Votes Cast - sorted by $sort</a></h2>\n";
				print "<p>".($house == "lords" ? "Lords" : "MPs")."
						for which their vote in this division differed
						from the majority vote of their party are marked in red.
						Also shows which ".($house == "lords" ? "lords" : "MPs")."
						were ministers at the time of this vote.
						You can also see <a href=\"$thispage&display=allpossible$tpsort\">every eligible ".($house == "lords" ? "lord" : "MP")."</a>
						including those who did not vote in this division.</p>\n";
			}
			elseif ($display == "slab")
            {
				#print "<h2><a name=\"votes\">All ".($house == "lords" ? "lords" : "MPs")." eligible to vote in this division</a></h2>\n";
                print '<p class="votekey">Key: <span class="favour">Vote in majority</span> | <span class="against">Vote against majority</span> | ';
                if ($house == "scotland")
                    print '<span class="spabstention">Absentention</span> | <span class="spmissing">Not in Attendance</span> ';
                else {
                    print '<span class="absent">Absent from vote</span> ';
                    print '| <span class="minister both">Minister</span> | <span class="pps both"><a title="Parliamentary Private Secretary (an assistant to a Minister)">PPS</a></span>.';
                }
                print '<a href="#votetable">top</a> </p>'."\n";
                print '<p>This is an experimental slab view.  Tell us what you think. ';
                print 'Email: <a href="mailto:team@publicwhip.org.uk">team@publicwhip.org.uk</a> ';
                print ' or <a href="http://www.publicwhip.org.uk/forum/viewtopic.php?t=1239">leave a comment on the forum</a>.'."\n";
            }
            else # all possible
			{
				print "<h2><a name=\"votes\">All ".($house == "lords" ? "lords" : "MPs")." Eligible to Vote - sorted by $sort</a></h2>\n";
				print "<p>Includes ".($house == "lords" ? "lords" : "MPs")." who were absent (or abstained)
						from this vote.</p>\n";
			}
		}

		# two motion text
		else
		{
			if ($display == "opposites")
			{
				print "<h2><a name=\"votes\">Opposite in Votes - sorted by $sort</a></h2>\n";
				print "<p>".($house == "lords" ? "Lords" : "MPs")." for which their vote on Motion (a) was opposite to their";
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
				print "<p>".($house == "lords" ? "Lords" : "MPs")." for which their vote on Motion (a) differed from their";
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
				print "<p>All ".($house == "lords" ? "lords" : "MPs")." who voted in one or other of the two divisions.
						Also shows which ".($house == "lords" ? "lords" : "MPs")." were ministers at the time of the first vote.</p>\n";
			}
			else  # all votes
			{
				print "<h2><a name=\"votes\">All ".($house == "lords" ? "Lords" : "MPs")." Eligible to Vote - sorted by $sort</a></h2>\n";
				print "<p>Includes ".($house == "lords" ? "lords" : "MPs")." who were absent (or abstained)
						from the first vote vote.</p>\n";
			}
		}

		# the sort by cases
	    if ($display != "slab")
        {
            print "<p style=\"font-size: 89%\" align=\"center\">Sort by: ";
	    	print ($sort == "name" ? "<b>Name</b>" : "<a href=\"$thispage$tpdisplay&sort=name\">Name</a>");
		    if ($house != "lords")
    		{
	    		print " | ";
		    	print ($sort == "constituency" ? "<b>Constituency</b>" : "<a href=\"$thispage$tpdisplay&sort=constituency\">Constituency</a>");
    		}
	    	print " | ";
		    print ($sort == "party" ? "<b>Party</b>" : "<a href=\"$thispage$tpdisplay&sort=party\">Party</a>");
    		print " | ";
	    	if ($singlemotionpage)
		    	print ($sort == "vote" ? "<b>Vote</b>" : "<a href=\"$thispage$tpdisplay&sort=vote\">Vote</a>");
    		else
	    	{
		    	print ($sort == "vote" ? "<b>Vote (a)</b>" : "<a href=\"$thispage$tpdisplay&sort=vote\">Vote (a)</a>");
    			print " | ";
	    		print ($sort == "vote2" ? "<b>Vote (b)</b>" : "<a href=\"$thispage$tpdisplay&sort=vote2\">Vote (b)</a>");
		    }
    		print "</p>\n";
        }

		$mptabattr = array("listtype"	=> "division",
							"divdate"	=> $divattr["division_date"],
							"divno"		=> $divattr["division_number"],
							"divhouse"	=> $divattr["house"],
							"divid"		=> $divattr["division_id"],  # redundant, but the above two are not used by all tables
							"sortby"	=> $sort,
							"showwhich" => $dismode["showwhich"],
							"ministerial" => $dismode["ministerial"],
                            "house"     => $divattr["house"],
							"headings"  => "yes");


		if (!$singlemotionpage)
		{
			$mptabattr["listtype"] = "division2";
			$mptabattr["divdate2"] = $divattr2["division_date"];
			$mptabattr["divno2"] = $divattr2["division_number"];
			$mptabattr["divid2"] = $divattr2["division_id"];
			$mptabattr["div2invert"] = $div2invert;
		}

        if ($display == "slab")
		{
			$mptabattr["slabtable"] = "yes";
			$mptabattr["showwhich"] = "allpossible";
			$mptabattr["sortby"] = "party_slab";
			$mptabattr["favourvote"] = ($divattr["aye_majority"] >= 0 ? "aye" : "no"); // or no
			$mptabattr["numcolumns"] = 11;
			$mptabattr["tooltips"] = "walterzorn";
            $mptabattr["headings"] = "";
		    $tableclass = "rvotes";
        }
        else
    		$tableclass = "votes";
        
        print "<table class=\"$tableclass\" id=\"votetable\">\n";
        mp_table( $mptabattr);
		print "</table>\n";
	}

	if ($dismode["listsimilardivisions"])
	{
		# comment out lazy evaluation that is done to completion in a separate job.
        #fill_division_distances($db, $db2, $divattr["house"], $divattr);

        $divtabattr = array(
				"showwhich"		=> 'everyvote',
				"headings"		=> 'columns',
				"sortby"		=> 'closeness',
                "limitby"       => ($dismode["listsimilardivisions"] == 'short' ? "10" : ""),
				"divclose"		=> $divattr,
				"display_house" => $divattr["house"]);

		if ($dismode["listsimilardivisions"] == "thisparliament")
			$divtabattr["parldatelimit"] = $parliaments[$divattr["parliament"]];

        #print "<h2><a name=\"simdiv\">Similar Divisions</a></h2>";
        print "<p>Divisions where the ".
            ($divattr["house"] == "lords" ? "Lords" : "MPs") . "
                voted in a similar way to the
                division on this page.  Click 'details...' to see which
                votes differ between the two divisions.</p>";

        print "<table class=\"votes\">\n";
	    print "</tr>";
		division_table($db, $divtabattr);
    	print "</table>\n";
	}

# explanation of metric
	if (!$singlemotionpage and ($display != "opposites"))
	{
		print "<h3><a name=\"simexpl\">Division Similarity Ratio</a></h3>\n";
		print "<p>The measure of similarity between these two divisions is a calculation
				based on a comparison of their votes.</p>\n";
		print_divdiv_distance($divattr, $divattr2, "MP");
	}

 pw_footer();