<?php require_once "common.inc";

    # $id: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    require_once "database.inc";

# standard decoding functions for the url attributes
require_once "decodeids.inc";
require_once "tablemake.inc";
require_once "tableoth.inc";

require_once "dream.inc";
require_once "tablepeop.inc";
require_once "DifferenceEngine.inc";

    $db = new DB();
    $db2 = new DB();

	# this replaces a lot of the work just below
	$voter = get_dreammpid_attr_decode($db, "id");  # for pulling a dreammpid from id= rather than the more standard dmp=
    $policyname = html_scrub($voter["name"]);
    if (isset($_GET['party'])) {
    $party_comp = db_scrub($_GET["party"]);
    } else {
        $party_comp='';
    }
    $dreamid = intval($voter["dreammpid"]);


	// all private dreams will be aggregate
    $bAggregate = ($voter["private"] == 1);
    $bAggregate = false; // disabled for now

	// should be available only to the owner
	$bAggregateEditable = false; //(($_GET["editable"] == "yes") || ($_POST["submit"] != ""));


    $title = "Policy #$dreamid: \"$policyname\"";
    if ($party_comp)
        $title .= " - Compared to $party_comp Party";

	# constants
	$dismodes = array();
	$dismodes["summary"] = array("dtype"	=> "summary",
								 "description" => "Selected votes",
                                 "definition" => "yes", 
								 "divisionlist" => "selected", # those which are seen out of the total
                                 "tooltip" => "Overview of the policy");
	
    $dismodes["comparison"] = array("description" => "Compare with MPs",
								 "comparisons" => "slab",
								 "divisionlist" => "selected", # those which are seen out of the total
                                 "tooltip" => "Comparison to MPs");
    
    if (!$bAggregate) {
        $dismodes["motions"] = array("dtype"     => "motions", 
                                     "description" => "Details of votes", 
                                     "divisionlist" => "selected", 
                                     "tooltip" => "Also shows description of every vote"); 
    }
	$dismodes["editdefinition"] = array("description" => "Edit",
								 "editdefinition" => "yes",
                                 "tooltip" => "Change title and definition of policy");

	$dismodes["discussion"] = array("description" => "Discussion",
								 "discussion" => "yes",
                                 "tooltip" => "Change title and definition of policy");



	// aggregate types get more options
	if ($bAggregate)
	{
		// just show differences to
		$dismodes["summary"]["aggregate"] = "shown";
		$dismoves["summary"]["divisionlist"] = "bothdiff"; # those which are seen out of the total
		$dismodes["summary"]["description"] = "Changes";

		$dismodes["allvotes"] = array("dtype"	=> "allvotes",
									 "description" => "All votes",
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

	$dismodes["linktopolicy"] = array("description" => "Link to this",
								 "policybox" => "yes",
                                 "tooltip" => "Link to a policy");


	# work out which display mode we are in (in case we arrive from a post)
	$display = $_GET["display"];
    if ($_POST["seldreamid"]) {
        $display = "extended";
    }
    if (!$dismodes[$display]) {
		$display = "summary"; # default
    }
	$dismode = $dismodes[$display];


# edit definition needs to check login
if ($dismode["editdefinition"]) {
    pw_header();
    print '<h1>Sorry, edit definitions are currently disabled</h1>';
    pw_footer();
    disabled('policy.php editdefinition');
    die();
        $just_logged_in = do_login_screen();
        if (!user_isloggedin()) {
            login_screen();
            exit;
        }
        $name=db_scrub($_POST["name"]);
        $description=$_POST["description"];
        $submiteditpolicy=db_scrub($_POST["submiteditpolicy"]);
        $form_provisional = $_POST["provisional"];

        $query = "select name, description, user_id, private from pw_dyn_dreammp where dream_id = '$dreamid'";
        $row = $db->query_one_row($query);
        if (!$name)
            $name = $row[0];
        if (!$description)
            $description = $row[1];
        $user_id = $row[2];
        $private = $row[3];
        $provisional = ($private == 2) ? 1 : 0;
        $legacy_dream = ($private == 1);

        $ok = false;
        if (($private == 1) && user_getid() != $user_id)
        {
            $feedback = "<p>This is not your legacy Dream MP, so you can't edit their name or defintion.";
        }
        elseif (policy_totally_frozen($dreamid))
        {
            $feedback = "<p>This policy is being used on TheyWorkForYou during the Election campaign. Please contact us if you think it needs editing."; 
        }
        elseif ($submiteditpolicy && (!$just_logged_in) && $submiteditpolicy == 'Save') 
        {
            if ($name == "" or $description == "")
                $feedback = "Please name the policy, and give a definition.";
            else
            {
                if ($legacy_dream)
                    $new_private = 1;
                else
                    $new_private = ($form_provisional ? 2 : 0);
                $db = new DB(); 
                list($prev_name, $prev_description) = $db->query_one_row("select name, description from pw_dyn_dreammp where dream_id = '$dreamid'");

                $name_diff = format_linediff($prev_name, stripslashes($name), false); # always have link
                $description_diff = format_linediff($prev_description, $description, true);

                dream_post_forum_action($db, $dreamid, "Changed name and/or definition of policy.\n\n[b]Name:[/b] ".$name_diff."\n[b]Definition:[/b] ".$description_diff);
                if ($new_private != $private) {
                    if ($new_private == 0)
                        $new_private_name = "public";
                    elseif ($new_private == 1)
                        $new_private_name = "legacy Dream MP";
                    elseif ($new_private == 2)
                        $new_private_name = "provisional";
                    dream_post_forum_action($db, $dreamid, "Policy is now [b]".$new_private_name."[/b]");
                }
                $ret = $db->query_errcheck("update pw_dyn_dreammp set name='$name', description='".mysql_real_escape_string($description)."', private='".$new_private."' where dream_id='$dreamid'");
                notify_dream_mp_updated($db, intval($dreamid));

                if ($ret)
                {
                    $ok = true;
                    $feedback = "Successfully edited policy '" . html_scrub($name) . "'.  
                     To see the changes, go to <a href=\"../policy.php?id=$dreamid\">the
                     policy's page</a>.";
                    audit_log("Edited definition policy '" . $name . "'");
                }
                else
                {
                    $feedback = "Failed to edit policy. " . mysql_error();
                }
            }
        } elseif ($submiteditpolicy) {
            $feedback = "Cancelled";
            $ok = true; # redirect on cancel
        }
        if ($ok)
        {
            header("Location: /policy.php?id=$dreamid\n");
            exit;
        }
    }

    # make list of links to other display modes
    $thispage = "policy.php?id=$dreamid"; 
    $second_links = dismodes_to_second_links($thispage, $dismodes, $tpsort, $display);
    $second_type = "tabs";

    pw_header();


	// this is where we save the votes
    // XXX this is not really used
	$clashesonsave = -1; // signifies no saving done
	if ($_GET["savevotes"] && $bAggregateEditable && $bAggregate)
	{
        pw_header();
        print '<h1>Sorry, saving votes are currently disabled</h1>';
        pw_footer();
        disabled('policy.php savevotes');
        exit();
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

	if ($dismode["definition"]) 
    {
        print "<p class=\"whatisflash\">This is the votes by vote definition of Public Whip ";
        print "policy #$dreamid: \"$policyname\".";
        
        print " You may want to <a href=\"/faq.php#policies\">read an introduction to policies</a>, ";
        print "or <a href=\"/faq.php\">read more about Public Whip</a>.";
        print "</p>";

        print "<p>Someone who believes that ";
        print "<span class=\"policytext\">".str_replace("\n", "<br>", html_scrub($voter["description"])) . "</span>";
        if ($dismode["divisionlist"] == "selected")
            print " would have voted like this...";

        print "<br>";
        print "<div align=\"right\">";

        //if ($voter["private"] == 1) {
        //    print "<b>Made by:</b> " . pretty_user_name($db, html_scrub($voter["user_name"])) . " (this is a legacy Dream MP)";
        //}
        //if ($voter["private"] == 2) {
        //    print "<strong>This policy is provisional, please help improve it</strong>";
        //}
        print "</div>";
        print "</p>";
    }

	if ($dismode["discussion"]) {
        pw_header();
        print '<h1>Sorry, discussions currently disabled</h1>';
        pw_footer();
        disabled('policy.php discussion');
        exit();
        $discuss_url = dream_post_forum_link($db, $dreamid);
        if (!$discuss_url) {
            // First time someone logged in comes along, add policy to the forum
            global $domain_name;
            if (user_getid()) {
                dream_post_forum_action($db, $dreamid, "Policy introduced to forum.\n\n[b]Name:[/b] [url=http://$domain_name/policy.php?id=".$dreamid."]".$policyname."[/url]\n[b]Definition:[/b] ".$voter['description']);
                $discuss_url = dream_post_forum_link($db, $dreamid);
            } else {
                $discuss_url = 'http://'.$domain_name.'/forum/viewforum.php?f=1';
            }
        }
        if ($discuss_url) {
            print '<iframe src="'.htmlspecialchars($discuss_url).'" width="100%" height="10000" scrolling="no">';
            print '<a href="'.htmlspecialchars($discuss_url).'">Click here for discussion</a>';
            print '</iframe>';
        }
    }

	if ($dismode["editdefinition"]) {
        pw_header();
        print '<h1>Sorry, edit definition currently disabled</h1>';
        pw_footer();
        disabled('policy.php editdefinition');
        exit();
        if (!user_getid()) {
            print "Error, expected to be logged in.";
            exit;
        }
        $db->query("update pw_dyn_user set active_policy_id = $dreamid where user_id = " . user_getid());

        print "<h2>How the policy votes</h2>";
        print "<p>This is currently your active policy; <b>to change its votes,
            go to the <a href=\"/divisions.php\">division page</a> for the vote you want to change</b>.
            You can use the <a href=\"search.php\">search facility</a> to find divisions.";

        print " If you haven't edited a policy before please 
        <a href=\"faq.php#policies\">read about how policies work</a>.";
        print "</p>";

        print "<h2>Policy title and text</h2>";

        if ($feedback && (!$just_logged_in)) {
            print "<div class=\"error\"><h2>Modifying the policy not complete, please try again
                </h2><p>$feedback</div>";
        }

        if (!$ok)
        {
        ?>
            <P>
            <FORM ACTION="policy.php?id=<?php echo $dreamid?>&display=editdefinition" METHOD="POST">
            <p><span class="ptitle">Title:</span> <INPUT TYPE="TEXT" NAME="name" VALUE="<?php echo html_scrub($name)?>" SIZE="40" MAXLENGTH="50">
            <P>
            <span class="ptitle">Text:</span> Someone who believes that<BR>
            <textarea class="policytext" name="description" rows="2" cols="80"><?php echo htmlspecialchars($description)?></textarea>
            <br>
            would vote according to this policy. (<em>From the text, everyone should 
            be able to agree which way the policy votes in each division</em>.)

            <?php if (!$legacy_dream) { ?>
            <p>
            <INPUT TYPE="checkbox" NAME="provisional" value="provisional" id="provisional" <?php echo $provisional?'checked':''?>>
            <label for="provisional" class="ptitle">Provisional policy</label>
            ('provisional' means the policy is not yet complete or consistent
            enough to display on MP pages)
            </p>
            <?php } ?>

            <p>
            <input type="hidden" name="submiteditpolicy" value="Save">
            <INPUT TYPE="SUBMIT" NAME="submitbutton" VALUE="Save title and text" accesskey="S">
            </FORM>
        <?
        }
        pw_footer();
    }
    // XXX this is not really used
    if ($dismode["aggregate"] == "fulltable")
	{
        pw_header();
        print '<h1>Sorry, full table aggregate stats currently disabled</h1>';
        pw_footer();
        disabled('policy.php full table aggregate stats');
        exit();
		// changed vote
		if (mysql_real_escape_string($_POST["submiteditpolicy"]))
        {
        	$newseldreamid = mysql_real_escape_string($_POST["seldreamid"]);
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
	else if ($dismode["divisionlist"] == "bothdiff" && $dismode["dtype"])
		print "<h2><a name=\"divisions\">Changed votes and new divisions</a></h2>\n";

    if ($dismode["dtype"]) {
        $divtabattr = array(
                "voter1type" 	=> "dreammp",
                "voter1"        => $dreamid,
                "voter1name"    => $policyname,
                "showwhich"		=> ($dismode["divisionlist"] == "selected" ? "all1" : "everyvote"),
                "headings"		=> ($dismode["dtype"] == "motions" ? 'none' : 'columns'),
                "divhrefappend"	=> "&dmp=$dreamid", # gives link to crossover page
                "motionwikistate" => "listunedited");
        if ($bAggregate)
        {
            $divtabattr["voter2type"] = "aggregate";
            $divtabattr["voter2"] = $dreamid;
            $divtabattr["showwhich"] = ($dismode["divisionlist"] == "bothdiff" ? "bothdiff" : "either");
        }
        
        if ($party_comp)
            print "<p>The <b>$party_comp</b> votes are listed along side.</p>\n";
        
        if ($party_comp)
        {
            $divtabattr["showwhich"] = "party";
            $divtabattr["party"] = $party_comp;
        }

        $divtabattr["sortby"] = "datereversed"; 
        if ($dismode["dtype"] == "motions")
        {
            $divtabattr["votedisplay"] = "fullmotion"; 
            print "<table>";
        }
        else
            print "<table class=\"votes\">";
        
        $dismetric = division_table($db, $divtabattr, $db2);
        print "</table>\n";

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
    }

	if ($dismode["comparisons"])
	{
        print "<h2><a name=\"comparison\">Comparison to all MPs, Lords and MSPs</a></h2>\n";

        print "<p>Colours represent political parties. If MPs, Lords or MSPs of a
        party vote the same way as the policy, then that party's colour appears
        by 'agree'. If they vote the opposite way, then it appears by 'disagree'.</p>";
        print "<p><img class=\"histoimg\" src=\"dreamplot.php?id=$dreamid&display=reverse&size=large&house=commons\" title=\"Histogram of MP agreement to policy by party\">";
        print "&nbsp;&nbsp;&nbsp;<img class=\"histoimg\" src=\"dreamplot.php?id=$dreamid&display=reverse&size=large&house=lords\" title=\"Histogram of Lord agreement to policy by party\">";
        print "&nbsp;&nbsp;&nbsp;<img class=\"histoimg\" src=\"dreamplot.php?id=$dreamid&display=reverse&size=large&house=scotland\" title=\"Histogram of MSP agreement to policy by party\"></p>";

        print "<p>MPs, Lords and MSPs are graded according to their agreement with the policy in terms of their votes.
	            If they always vote the same as the policy then their agreement is 100%; if they
				always vote opposite to the policy votes, their agreement is 0%.
                If they could never have voted at the same time as the policy, they are not listed.";
        print "<br clear=\"all\">"; 

		if ($dismode["comparisons"] == "slab")
        {
            $mptabattr = array("listtype" => "dreamdistance",
                               "dreammpid" => $dreamid,
                               "dreamname" => $policyname,
                               "headings" => "",
                               "slabtable" => "yes",
                               "sortby" => "party_slab",
                               "numcolumns" => 11,
                               "house" => "all",
                               "tooltips" => "walterzorn" );
            $tableclass = "rvotes";
        }
        else
        {
            $mptabattr = array("listtype" => 'dreamdistance',
						   'dreammpid' => $dreamid,
						   'dreamname' => $policyname,
                           'headings' => 'yes');
		    $tableclass = "mps";
        }
        
        print "<table class=\"$tableclass\">\n";
		mp_table($mptabattr);
		print "</table>\n";
    }

	if ($dismode["policybox"])
	{
	    print '<h2><a name="dreambox">Add policy to your website</a></h2>';
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

pw_footer() ?>

