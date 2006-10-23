<?php require_once "common.inc";

    # $id: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    require_once "database.inc";


    $db = new DB();
    $db2 = new DB();

// create the table (once) so we can use it.
/*$db->query("create table pw_dyn_aggregate_dreammp (
	dream_id_agg int not null,
	dream_id_sel int not null,
    vote_strength enum(\"strong\", \"weak\") not null,
	index(dream_id_agg),
	index(dream_id_sel),
    unique(dream_id_agg, dream_id_sel)
);");
*/

	# standard decoding functions for the url attributes
	require_once "decodeids.inc";
	require_once "tablemake.inc";
    require_once "tableoth.inc";

    require_once "dream.inc";
	require_once "tablepeop.inc";

	# this replaces a lot of the work just below
	$voter = get_dreammpid_attr_decode($db, "id");  # for pulling a dreammpid from id= rather than the more standard dmp=
    $policyname = html_scrub($voter["name"]);
	$dreamid = $voter["dreammpid"];

	// all private dreams will be aggregate
    $bAggregate = ($voter["private"] == 1);
    $bAggregate = false; // disabled for now

	// should be available only to the owner
	$bAggregateEditable = true; //(($_GET["editable"] == "yes") || ($_POST["submit"] != ""));


    $title = "Someone who believes that..."; // $policyname

	# constants
	$dismodes = array();
	$dismodes["summary"] = array("dtype"	=> "summary",
								 "description" => "Votes",
								 "comparisons" => "yes",
								 "divisionlist" => "selected", # those which are seen out of the total
								 "policybox" => "yes",
                                 "tooltip" => "Overview of the policy");

	// aggregate types get more options
	if ($bAggregate)
	{
		// just show differences to
		$dismodes["summary"]["aggregate"] = "shown";
		$dismoves["summary"]["divisionlist"] = "bothdiff"; # those which are seen out of the total
		$dismodes["summary"]["description"] = "Changes";

		$dismodes["allvotes"] = array("dtype"	=> "allvotes",
									 "description" => "All Votes",
									 "divisionlist" => "selected",
									 "aggregate" => "shown",
	                                 "tooltip" => "Source of the policy");

		if ($bAggregateEditable)
			$dismodes["extended"] = array("dtype"	=> "extended",
										 "description" => "Extended",
										 "divisionlist" => "selected",
										 "aggregate" => "fulltable",
		                                 "tooltip" => "Editable list of policies");
	}


	# work out which display mode we are in (in case we arrive from a post)
	$display = $_GET["display"];
    if ($_POST["seldreamid"])
        $display = "extended";
    if (!$bAggregateEditable || !$bAggregate || !$dismodes[$display])
		$display = "summary"; # default
	$dismode = $dismodes[$display];

    # make list of links to other display modes
    $thispage = "policy.php?id=$dreamid"; 
    $second_links = dismodes_to_second_links($thispage, $dismodes, $tpsort, $display);

    pw_header();

	// this is where we save the votes
	$clashesonsave = -1; // signifies no saving done
	if ($_GET["savevotes"] && $bAggregateEditable && $bAggregate)
	{
		print "<h2>THIS IS WHERE WE SAVE THE VOTES INTO THE POLICY</h2>.\n";

		// remove superfluous entries
		$qdelete = "DELETE pw_dyn_dreamvote FROM pw_dyn_dreamvote";
		$qjoind  = " LEFT JOIN pw_dyn_aggregate_dreammp, pw_dyn_dreamvote AS pw_dyn_dreamvote_agg
								ON pw_dyn_aggregate_dreammp.dream_id_sel = pw_dyn_dreamvote_agg.dream_id
								AND pw_dyn_aggregate_dreammp.dream_id_agg = $dreamid";
	    $qjoind .=  "  			AND pw_dyn_dreamvote_agg.division_date = pw_dyn_dreamvote.division_date
                                AND pw_dyn_dreamvote_agg.division_number = pw_dyn_dreamvote.division_number"; # AND HOUSE!!!
								#AND pw_dyn_dreamvote_agg.division_id = pw_dyn_dreamvote.division_id";
		$qwhered = " WHERE pw_dyn_dreamvote.dream_id = $dreamid AND pw_dyn_dreamvote_agg.vote IS NULL";

		$queryd = $qdelete.$qjoind.$qwhered;
        #print "<h3>$queryd</h3><hr>\n";
		$db->query($queryd);

		// too difficult to design direct queries to add them in
		// because of a lack of an aggregation function that sticks together aye3,no into both
		// so we apply as a loop
		$qselect = " SELECT pw_dyn_dreamvote.division_date, pw_dyn_dreamvote.division_number";
		$qselect .= ", MAX(CASE pw_dyn_dreamvote.vote WHEN 'aye' THEN 1 WHEN 'aye3' THEN 3 ELSE 0 END) AS maye";
		$qselect .= ", MAX(CASE pw_dyn_dreamvote.vote WHEN 'no' THEN 1 WHEN 'no3' THEN 3 ELSE 0 END) AS mno";
	    $qselect .= ", MAX(CASE pw_dyn_dreamvote.vote WHEN 'both' THEN 1 ELSE 0 END) AS mabstain";

		$qfrom = " FROM pw_dyn_dreamvote";  # this is from transpose side of the one above
		$qjoinr  = " LEFT JOIN pw_dyn_aggregate_dreammp
								ON pw_dyn_aggregate_dreammp.dream_id_sel = pw_dyn_dreamvote.dream_id
								AND pw_dyn_aggregate_dreammp.dream_id_agg = $dreamid";
		$qwherer = " WHERE pw_dyn_aggregate_dreammp.dream_id_agg IS NOT NULL";
		$qgroup = " GROUP BY pw_dyn_dreamvote.division_date, pw_dyn_dreamvote.division_number";
        $queryr = $qselect.$qfrom.$qjoinr.$qwherer.$qgroup;
        #print "<h4>$queryr</h4>\n"; 
        $db->query($queryr); 

		$clashesonsave = 0;
	    while ($row = $db->fetch_row_assoc())
		{
			if (($row["maye"] != 0) && ($row["mno"] != 0))
			{
				$vote = "both";
				$clashesonsave += 1;
			}
			else if ($row["maye"])
				$vote = ($row["maye"] == 3 ? "aye3" : "aye");
			else if ($row["mno"])
				$vote = ($row["mno"] == 3 ? "no3" : "no");
			else if ($row["mabstain"])
				$vote = "both";
			else
				$vote = "cant happen"; // illegal value
			# vote enum("aye", "no", "both", "aye3", "no3") not null,
			$query = "REPLACE INTO pw_dyn_dreamvote
						(vote, dream_id, division_date, division_number)
					  VALUES
					    ('$vote', $dreamid, '".$row["division_date"]."', ".$row["division_number"].")";
            #print "<h5>$query</h5>\n"; 
            $db2->query($query);
		}

		# reset where there are disagreed value (not sure how this works)
		update_dreammp_votemeasures($db, $dreamid, 0);
	}

    print "<div class=\"policydefinition\">";
    print "<p>" . str_replace("\n", "<br>", html_scrub($voter["description"]));
    if ($voter["private"] == 1)
        print "<p><b>Made by:</b> " . pretty_user_name($db, html_scrub($voter["user_name"])) . " (this is a legacy Dream MP)";
    if ($voter["private"] == 2)
        print "<strong>This policy is provisional, please help improve it</strong>";

    print " <b><a href=\"account/editpolicy.php?id=$dreamid\">Edit definition</a></b>";
    print " (<a href=\"faq.php#policies\">learn more</a>)";
    $discuss_url = dream_post_forum_link($db, $dreamid);
    if (!$discuss_url) {
        // First time someone logged in comes along, add policy to the forum
        global $domain_name;
        if (user_getid()) {
            dream_post_forum_action($db, $dreamid, "Policy introduced to forum.\n\n[b]Name:[/b] [url=http://$domain_name/policy.php?id=".$dreamid."]".$policyname."[/url]\n[b]Definition:[/b] ".$voter['description']);
            $discuss_url = dream_post_forum_link($db, $dreamid);
        } else {
            print ' | <b><a href="http://'.$domain_name.'/forum/viewforum.php?f=1">Discuss</a></b>';
        }
    }
    if ($discuss_url)
        print ' | <b><a href="'.htmlspecialchars($discuss_url).'">Discussion</a></b>';

    print "</p>";

	print "</div>\n";

    if ($dismode["aggregate"] == "fulltable")
	{
		// changed vote
		if (mysql_escape_string($_POST["submit"]))
        {
        	$newseldreamid = mysql_escape_string($_POST["seldreamid"]);
			$icomma = strpos($newseldreamid, ',');
			$seldreamid = substr($newseldreamid, 0, $icomma);
			$seldreamidvote = substr($newseldreamid, $icomma + 1);
			print "<h1>DDDchch  $seldreamid = $seldreamidvote</h1>\n";

			// find current vote
		    $query = "SELECT vote_strength
					  FROM pw_dyn_aggregate_dreammp
					  WHERE pw_dyn_aggregate_dreammp.dream_id_agg = $dreamid
					  	AND pw_dyn_aggregate_dreammp.dream_id_sel = $seldreamid";
			$row = $db->query_onez_row_assoc($query);
			$bpolselectedcurrent = ($row != null);
			$bpolselectednew = ($seldreamidvote == "yes");

			if ($bpolselectedcurrent != $bpolselectednew)
			{
				if (!$bpolselectednew)
	                $query = "DELETE FROM pw_dyn_aggregate_dreammp
							  WHERE pw_dyn_aggregate_dreammp.dream_id_agg = $dreamid
							  	AND pw_dyn_aggregate_dreammp.dream_id_sel = $seldreamid";
				else
	                $query = "INSERT INTO pw_dyn_aggregate_dreammp
							  	(dream_id_agg, dream_id_sel, vote_strength)
							  VALUES
							    ($dreamid, $seldreamid, 'strong')";
	            $db->query($query);
			}
			else
				print "<h2>DDDD  No Vote Changed</h2>\n";
        }

	    print "<table class=\"mps\">\n";
		$dreamtabattr = array("listtype" => 'aggregatevotes',
						      'dreamid' => $dreamid,
						      'listlength' => "allpublic",
							  'headings' => "yes",
							  'editable' => "yes");
		$c = print_policy_table($db, $dreamtabattr);
	    print "</table>\n";
	}

	// short list
    if ($dismode["aggregate"] == "shown")
	{
		$query = "SELECT name, pw_dyn_dreammp.dream_id AS dream_id
				  FROM pw_dyn_aggregate_dreammp
				  LEFT JOIN pw_dyn_dreammp
				  		ON pw_dyn_dreammp.dream_id = pw_dyn_aggregate_dreammp.dream_id_sel
        					AND pw_dyn_aggregate_dreammp.dream_id_agg = $dreamid
				  ORDER BY name";
		$db->query($query);
		$npols = $db->rows();
		if ($npols == 0)
			print "<p>This Dream MP supports no policies";
		else if ($npols == 1)
			print "<p>This Dream MP supports the following policy: ";
		else
			print "<p>This Dream MP supports the following policies: ";
		$count = 0;
	    while ($row = $db->fetch_row_assoc())
		{
			$count++;
			if ($count == 1)
				;
			else if ($count == $npols)
				print ", and ";
			else
				print ", ";
	        print '<a href="policy.php?id='.$row['dream_id'].'">'.$row["name"].'</a>';
		}
		print ".</p>\n";
    }


/*    if ($dismode["policybox"])
    {
	    print "<h2><a name=\"comparison\">Compare Against one MP</a></h2>";
        print "<div class=\"tabledreambox\">";
        print dream_box($dreamid, $policyname);
        print '<p>Why not <a href="#dreambox">add this to your own website?</a></p>';
        print "</div>";
    } */

	if ($dismode["divisionlist"] == "selected")
	{
		print "<h2><a name=\"divisions\">... would have voted like this</a></h2>";
        /*if ($voter["votes_count"]) {
             print "<p>This policy has voted in <b>".$voter["votes_count"]."</b> divisions.";
             if ($voter["votes_count"] != $voter["edited_count"])
                print " A total of <b>".(($voter["votes_count"]) - ($voter["edited_count"]))."</b> of these have not had their descriptions edited.";
		 }
         */
	}

	else if ($dismode["divisionlist"] == "bothdiff")
		print "<h2><a name=\"divisions\">Changed votes and new divisions</a></h2>\n";
	else
		print "<h2><a name=\"divisions\">Every Division</a></h2>\n";

    print "<table class=\"divisions\">\n";
	$divtabattr = array(
			"voter1type" 	=> "dreammp",
			"voter1"        => $dreamid,
			"showwhich"		=> ($dismode["divisionlist"] == "selected" ? "all1" : "everyvote"),
			"headings"		=> 'columns',
			"divhrefappend"	=> "&dmp=$dreamid", # gives link to crossover page
			"motionwikistate" => "listunedited");
	if ($bAggregate)
	{
		$divtabattr["voter2type"] = "aggregate";
		$divtabattr["voter2"] = $dreamid;
		$divtabattr["showwhich"] = ($dismode["divisionlist"] == "bothdiff" ? "bothdiff" : "either");
	}
        $divtabattr["sortby"] = "datereversed"; 
	$dismetric = division_table($db, $divtabattr);
    print "</table>\n";

    print "<p>Please <strong>edit and fix</strong> (<a href=\"faq.php#policies\">learn more</a>) the votes and the definition above, if they are not consistent with each other, or something is missing. ";
    if (user_getid()) {
        $db->query("update pw_dyn_user set active_policy_id = $dreamid where user_id = " . user_getid());
        print " This is currently your active policy; <b>to change its votes, go to any division page</b>.";
    } else {
        print ' <a href="/account/settings.php">Log in</a> to do this.';
    }
    if ($discuss_url)
        print ' <b><a href="'.htmlspecialchars($discuss_url).'">Discussion</a></b>.';


	// should this be a button
	if ($bAggregateEditable && (($dismetric["updates"] != 0) || ($dismetric["clashes"] != 0)))
	{
		if ($dismetric["clashes"] != 0)
			print "<p>There are <strong>".$dismetric["clashes"]."</strong> divisions where your policy choices clash.</p>\n";
		if ($dismetric["updates"] != 0)
			print '<p>There are <strong>'.$dismetric["updates"].'</strong>
					changed votes which need saving into your Dream MP.
					<a href="policy.php?id='.$dreamid.'&display='.$display.'&savevotes=yes">CLICK HERE TO SAVE THEM</a></p>';
		if ($clashesonsave != -1)
			print "<h2>Error: After saving, none to update and $clashesonsave clashes found</h2>\n";
	}

	if ($dismode["comparisons"])
	{
	    print "<h2><a name=\"comparison\">Comparison to all MPs and Lords</a></h2>";

	    print "<p>Grades MPs and Lords acording to how often they voted with the policy.
	            If they always vote the same as the policy then their agreement is 100%, if they
				always vote the opposite when the policy votes, their agreement is 0%.
                If they never voted at the same time as the policy they don't appear.";

		$mptabattr = array("listtype" => 'dreamdistance',
						   'dreammpid' => $dreamid,
						   'dreamname' => $policyname,
                           'headings' => 'yes');
		print "<table class=\"mps\">\n";
		mp_table($db, $mptabattr);
		print "</table>\n";
	}

	if ($dismode["policybox"])
	{
	    print '<h2><a name="dreambox">Add Policies to Your Website</a></h2>';
	    print '<p>Get people thinking about your issue, by adding a policy search
				box to your website.  This lets people compare their own MP to your policy,
				like this.</p>';
	    print dream_box($dreamid, $policyname);
	    print '<p>To do this copy and paste the following HTML into your website.
				Feel free to fiddle with it to fit the look of your site better.  We only
				ask that you leave the link to Public Whip in.';
	    print '<pre class="htmlsource">';
	    print htmlspecialchars(dream_box($dreamid, $policyname));
	    print '</pre>';
	}
?>

<?php pw_footer() ?>

