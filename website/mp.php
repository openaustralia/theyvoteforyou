<?php require_once "common.inc";
    # $Id: mp.php,v 1.146 2010/03/12 12:26:46 publicwhip Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $db = new DB();
	$db2 = new DB();

	# standard decoding functions for the url attributes
	require_once "decodeids.inc";
	require_once "tablemake.inc";
	require_once "tableoth.inc";
    require_once "dream.inc";
	require_once "tablepeop.inc";

	# pull in the voter2 type first so if it's a dreammp we can filter
	# the main mp list

	# against a dreammp, another mp, or the party
	$voter2attr = get_dreammpid_attr_decode($db, "");
	if ($voter2attr != null)
	{
		$voter2type = "dreammp";
		$voter2 = $voter2attr['dreammpid'];
	}
	else
	{
		$voter2attr = get_mpid_attr_decode($db, $db2, "2");
		if ($voter2attr != null)
		{
			$voter2type = "person";
			$voter2 = $voter2attr;
		}
		else
		{
			$voter2type = "party";
			$voter2 = ""; # this varies for each incarnation, but could remain fixed
		}
	}


	# decode the parameters.
	# first is the two voting objects which get compared together.
	# First is an mp (arranged by person or by constituency)
	# Second is another mp (by person), a dream mp, or a/the party
	$voter1attr = get_mpid_attr_decode($db, $db2, "", ($voter2type == "dreammp" ? $voter2attr : null));
	if ($voter1attr == null) {
        $title = "MP/Lord not found";
        pw_header();
		print "<p>No MP or Lord found. If you entered a postcode, please make
        sure it is correct.  Or you can <a href=\"/mps.php\">browse
        all MPs</a> or <a href=\"/mps.php?house=lords\">browse all Lords</a>.";
        pw_footer();
        exit;
    }
	$voter1type = "mp";


	# if we have a dreammp comparison, we should discard any


	# shorthand to get at the designated MP for this class of MP holders
	# (multiple sets of properties, usually overlapping, hold for each MP if they've had more than one term)
	$mpprop = $voter1attr["mpprop"];

	# case now is we know the two voting actors,
	# (and whether the first is a constituency or a person)
	# select a mode for what is displayed
	# code for the 0th mp def, if it is there.
    $voter1link = "mp.php?";
    if ($voter1attr["bmultiperson"]) {
        $voter1link .= "mpc=".urlencode($mpprop['constituency']);
        $voter1link .= "house=".urlencode($mpprop['house']);
    }
    else
		$voter1link .= $mpprop['mpanchor'];

	# extend to the comparison type
	$thispagesettings = "";
	if ($voter2type == "dreammp")
	{
		$thispagesettings = "dmp=$voter2";
	    $voter2link = "policy.php?id=$voter2";
	}
	else if ($voter2type == "person")
	{
		$thispagesettings = $voter2["mpprop"]["mpanchor2"];
	    $voter2link = "mp.php?". $voter2["mpprop"]["mpanchor"];
	}
	$thispage = $voter1link; 
	if ($thispagesettings != "")
		$thispage .= "&$thispagesettings";

    $mpid = $mpprop["mpid"];
    $page_logged = ($voter2type == "dreammp" ? "mppolicy" : "mp");
    $subject_logged = ($voter2type == "dreammp" ? $voter2 : "");

    
    # constants
	$dismodes = array();
	if ($voter2type == "party")
	{
		$dismodes["summary"] = array("dtype"	=> "summary",
								 "description" => "Summary",
								 "generalinfo" => "yes",
								 "votelist"	=> "short",
								 "possfriends"	=> "some",
								 "dreamcompare"	=> "short",
                                 "tooltip" => "Overview of MP");
		if (!$voter1attr['bmultiperson'])
			$dismodes["summary"]["eventsinfo"] = "yes";
	}

	if ($voter2type == "person")
	{
		$dismodes["difference"] = array("dtype"	=> "difference",
								 "description" => "Differences",
								 "generalinfo" => "yes",
								 "votelist"	=> "short",
                                 "tooltip" => "Votes where the two MPs votes differed");
	}

	$dismodes["allvotes"] = array("dtype"	=> "allvotes",
							 "description" => ($voter2type == "dreammp" ? "Summary" : "Votes attended"),
                             "votelist"	=> "all",
							 "defaultparl" => "recent",
                             "tooltip" => "Show every vote cast by this MP");
	if (!$voter1attr['bmultiperson'] && ($voter2type != "dreammp"))
		$dismodes["allvotes"]["eventsinfo"] = "yes";
	if (/*$voter2type != "party" and */$voter2type != "dreammp")
		$dismodes["allvotes"]["generalinfo"] = "yes";

	if ($voter2type == "dreammp")
	{
		$dismodes["motions"] = array("dtype"	=> "motions",
								 "description" => "Full description",
								 "votelist"	=> "all",
								 "votedisplay"	=> "fullmotion",
								 "defaultparl" => "recent",
                                 "tooltip" => "Also show descriptions of every vote");
		if ($voter1attr['bmultiperson'])
			$dismodes["motions"]["multimpterms"] = "yes";

	}

	if ($voter2type != "dreammp")
	{
		$dismodes["everyvote"] = array("dtype"	=> "everyvote",
								 "description" => "All votes",
								 "votelist"	=> "every",
								 "defaultparl" => "recent",
                                 "tooltip" => "Show even divisions where the MP was absent, but could have voted");
		if (!$voter1attr['bmultiperson'])
			$dismodes["everyvote"]["eventsinfo"] = "yes";
		//if ($voter2type != "party")
			$dismodes["everyvote"]["generalinfo"] = "yes";
	}

	# friendships if not a comparison table
	if ($voter2type == "party")
	{
		$dismodes["allfriends"] = array("dtype"	=> "allfriends",
								 "description" => "All friends",
								 "possfriends"	=> "all",
								 "defaultparl" => "recent",
                                 "tooltip" => "Show all MPs in order of how similarly to this MP they voted");
	}
    if (($voter2type == "party") || ($voter2type == "dreammp"))
    {
		$dismodes["alldreams"] = array("dtype"	=> "alldreams",
								 "description" => "Policy comparisons",
								 "dreamcompare"	=> "allpublic",
								 "defaultparl" => "all",
                                 "tooltip" => "Show all Policies and how this MP voted on them");
	}


	# work out which display mode we are in
	$display = $_GET["display"];
	if (!$dismodes[$display])
	{
		if ($_GET["showall"] == "yes")
			$display = "allvotes"; # legacy
		else if ($_GET["allfriends"] == "yes")
			$display = "allfriends"; # legacy
		else if ($voter2type == "dreammp")
			$display = "allvotes";
		else if ($voter2type == "person")
			$display = "difference";
		else
			$display = "summary"; # default
	}
	$dismode = $dismodes[$display];
	$thispagesettings .= ($thispagesettings ? "&" : "")."display=$display";

	if ($voter2type != "dreammp")
	{
		$rdismodes_parl = Array();
		foreach ($parliaments as $lrdisplay => $val)
		{
			// limit by date ranges
			$rdismodes_parl[$lrdisplay] = array(
									 "description" => $val['name']."&nbsp;Parliament",
									 "lkdescription" => $val['name']."&nbsp;Parliament",
									 "parliament" => $ldisplay,
									 "titdescription" => $val['name']."&nbsp;Parliament");
		}
		$rdismodes_parl["all"] = array(
								 "description" => "All votes on record",
								 "lkdescription" => "All Parliaments",
								 "titdescription" => "All on record",
								 "parliament" => "all");
		$rdisplay_parliament = db_scrub($_GET["parliament"]);
	}
	if (!$rdisplay_parliament)
		$rdisplay_parliament = "all";


	# generate title and header of this webpage
	if ($mpprop['house'] == 'commons') {
		$contitlefor = "for ".$mpprop['constituency'];
		$contitlecomma = ", ".$mpprop['constituency'];
	} else {
		$contitlefor = "";
		$contitlecomma = "";
	}
    $colour_scheme = $mpprop['house'];

    if ($voter2type == "dreammp")
	{
        update_dreammp_person_distance($db, $voter2);
        $query   = "SELECT nvotessame+nvotessamestrong+nvotesdiffer+nvotesdifferstrong AS nvotes, distance_a
                            FROM pw_cache_dreamreal_distance
                            WHERE dream_id = $voter2 AND person = ?";
	$pwpdo->get_single_row($query,array($mpprop['person']));
	$h1title = "<div class=\"h1mppolicy\">";
        $h1title .= "<p class=\"mp\"><a href=\"".$voter1link."\">".html_scrub($mpprop['fullname'])."</a></p>";
        $agreement_a = 1.0 - ($row["distance_a"]);
        $h1title .= "<p class=\"voteexpl\">";
        if ($row["nvotes"] == 0)
            $h1title .= "has <em>never voted</em> on";
        else if ($agreement_a >= 0.80)
            $h1title .= "voted <em>strongly for</em>";
        else if ($agreement_a >= 0.60)
            $h1title .= "voted <em>moderately for</em>";
        else if ($agreement_a <= 0.20)
            $h1title .= "voted <em>strongly against</em>";
        else if ($agreement_a <= 0.40)
            $h1title .= "voted <em>moderately against</em>";
        else 
            $h1title .= "voted <em>ambiguously</em> on";
        $h1title .= " the policy</p>";
        $h1title .= "<p class=\"policy\"><a href=\"$voter2link\"><i><b>".html_scrub($voter2attr['name'])."</b></i></a></p> ";
        $h1title .= "<p>by <a href=\"#ratioexpl\">scoring</a> ";
        $h1title .= "<em class=\"percent\">".pretty_distance_to_agreement($row['distance_a'])."</em> ";
        $h1title .= "compared to the votes below</p>";
        $h1title .= "</div>";

        $headtitle = $mpprop["name"]." compared to '".$voter2attr['name']."'";
	}
	
    else if ($voter2type == "person")
		$title = "Voting Comparison - ".$mpprop['fullname']."<br> to ".$voter2attr["mpprop"]['fullname'];
	else if ($dismode["possfriends"] == "all")
		$title = "Friends of ".$mpprop['name']." ".$mpprop['housenamesuffix'].$contitlecomma;
	else if ($voter1attr["bmultiperson"])
		$title = "Voting Record - ".$mpprop['housenounplural']." ".$contitlefor;
	else
		$title = "Voting Record - ".$mpprop['fullname']." (".$mpprop["person"].")";

	// now build up the links
    # make list of links to other display modes
    $second_links = dismodes_to_second_links($thispage, $dismodes, "", $display);
	if ($rdismodes_parl)
	{
		$second_links2 = $second_links;
		$second_links = array();
	    foreach ($rdismodes_parl as $lrdisplay => $val)
		{
			$dlink = $thispage."&parliament=$lrdisplay&display=$display";
	        array_push($second_links, array('href'=>$dlink,
	            'current'=> ($rdisplay_parliament == $lrdisplay ? "on" : "off"),
	            'text'=>$val["lkdescription"]));
		}
	}

	// we apply a date range to the
    $second_type = "tabs";
    pw_header();


	# extract the events in this mp's life
	# the events that have happened in this MP's career
	if ($dismode["eventsinfo"])
	{
		# generate ministerial events (maybe events for general elections?)
	 	$query = "SELECT dept, position, responsibility, from_date, to_date
	        	  FROM pw_moffice
				  WHERE pw_moffice.person = ? ORDER BY from_date DESC";
		$pwpdo->query($query,array($voter1attr["mpprop"]["person"]));
		# we insert an events array into each mpprop, which we will allocate timewise
		for ($i = 0; $i < count($voter1attr["mpprops"]); $i++)
			$voter1attr["mpprops"][$i]["mpevents"] = array();

		function puteventintompprop(&$mpprops, $eventdate, $eventBE, $row)
		{
			for ($i = 0; $i < count($mpprops) - 1; $i++)
				if ($eventdate > $mpprops[$i + 1]["lefthouse"])
					break;
            $eventdesc = ($eventBE == "B" ? "Became " : "Stopped being ").pretty_minister($row);
            array_push($mpprops[$i]["mpevents"], array($eventdate, $row['dept'], $eventBE, $row['position'], $eventdesc));
		}

		$currently_minister = array();
		# it goes in reverse order
	    while ($row = $pwpdo->fetch_row())
	    {
	        if ($row["to_date"] == "9999-12-31")
	            $currently_minister[] = pretty_minister($row);
			else
				puteventintompprop($voter1attr["mpprops"], $row["to_date"], "A", $row); 
			puteventintompprop($voter1attr["mpprops"], $row["from_date"], "B", $row);
	    }

		# reverse the arrays that we create (could have done above loop already reversed)
		for ($i = 0; $i < count($voter1attr["mpprops"]); $i++)
        {
            $mpevents = &$voter1attr["mpprops"][$i]["mpevents"];
            sort($mpevents); 
			for ($j = 0; $j < count($mpevents); $j++)
            {
                # Chairmen of committees are automatically part of this committee
                #if ($mpevents[$j][1] == "Liaison Committee")
                #    $mpevents[$j][2] = "Ignoreevent";
                # Promotion of member of committee to chairman of same committee
                if (($j > 0) && ($mpevents[$j][1] == $mpevents[$j - 1][1]) && ($mpevents[$j][2] == "B") && ($mpevents[$j - 1][2] == "A") && ($mpevents[$j][3] == "Chairman") && ($mpevents[$j - 1][3] == ""))
                    $mpevents[$j - 1][2] = "Ignoreevent"; 
            }
            #$voter1attr["mpprops"][$i]["mpevents"] = array_reverse($voter1attr["mpprops"][$i]["mpevents"]);
        }
	}


	# general information
	if ($dismode["generalinfo"])
	{

        // See if MP always in same constituency
        $con = $mpprop['constituency'];
        $all_same_cons = true;
        foreach ($voter1attr['mpprops'] as $p)
	    {
		    if ($p['constituency'] != $con)
			    $all_same_cons = false;
        }

	    if ($currently_minister)
        {
		    print "<p><b>".$mpprop['name']."</b> is currently ";
            for ($i = 0; $i < count($currently_minister); $i++)
            {
                if ($i != 0)
                    print ($i != count($currently_minister) - 1 ? ", " : " and "); 
                print "<b>".$currently_minister[$i]."</b>"; 
            }
            print "</p>"; 
        }

        print "<p><em>Note:</em> our records only go back to 1997 for the Commons and 2001 for the Lords (<a href=\"/faq.php#timeperiod\">more details</a>).";

	    seat_summary_table($voter1attr['mpprops'], $voter1attr['bmultiperson'], ($all_same_cons ? false : true), true, $thispagesettings);

        if ($voter2type == "party")
	    {
		    print "<h2><a name=\"exlinks\">External Links</a></h2>\n";
            print "<ul>\n";

			print "<li>See <strong>".$mpprop["name"]."</strong>'s Parliamentary speeches at: ";
			print "<a href=\"http://www.theyworkforyou.com/mp/?m=".$mpprop["mpid"]."\">TheyWorkForYou.com</a></li>\n";

            if ($mpprop['house'] == 'commons') 
            {
                # can we link directly? no - you need postcode
                print "<li>Contact your MP for free at: <a href=\"http://www.writetothem.com\">WriteToThem.com</a></li>\n";

                print "<li>Form a long term relationship with your MP: <a href=\"http://www.hearfromyourmp.com\">HearFromYourMP.com</a></li>\n";

                include $toppath . "ecdonations.inc";
            }

            print "</ul>\n";
        }
	}
	
	
	if ($dismode["votelist"])
    {
		# title for the vote table
        $vextra = "";
	    if ($voter2type == "dreammp")
	        $vtitle = ""; #Votes chosen by '".$voter2attr['name']."' Policy";
		else if ($voter2type == "person" && $dismode["votelist"] == "short")
			$vtitle = "Voting Differences";
		else if ($dismode["votelist"] == "short") {
			$vtitle = "Interesting Votes";
            # TODO: should have a "more..." or "all..." link here but not sure how
            #$vextra = " (<a href=\"$thispage&display=allvotes\">more...</a>)";
        } else if ($dismode["votelist"] == "every")
			$vtitle .= "All Votes";
		else
			$vtitle = "Votes Attended";
        if ($vtitle)
            print "<h2><a name=\"divisions\">$vtitle</a>$vextra</h2>\n";

		# subtext for the vote table
		if ($dismode["votelist"] == "short" and $voter2type == "party")
		{
            print "<p>Votes in parliament for which this ".$mpprop['housenoun']."'s vote differed from the
	        	majority vote of their party (Rebel), or in which this ".$mpprop['housenoun']." was
	        	a teller (Teller), or both (Rebel Teller).</p>  \n";
            print "<p style=\"font-size: 89%\" align=\"center\">See also all votes... <a href=\"$thispage&display=allvotes#divisions\">attended</a> | <a href=\"$thispage&display=everyvote#divisions\">possible</a></p>\n";
        }
        else if ($dismode["votelist"] == "all" and $voter2type == "party")
            print "<p style=\"font-size: 89%\">See also <a href=\"$thispage&display=everyvote#divisions\">all votes possible</a></p>\n";
		else if ($dismode["votelist"] == "every" and $voter2type == "party")
			print "<p>All votes this MP could have attended. \n";
		else if ($voter2type == "dreammp")
		{
            # list of all MPs being displayed
            if ($dismode["multimpterms"])
			{
                print "<p>These MPs for ".$mpprop['constituency'];
				print " are compared to the policy, according to which held the seat at the time of each vote.";
                seat_summary_table($voter1attr['mpprops'], $voter1attr['bmultiperson'], ($all_same_cons ? false : true), false, $thispagesettings);
				print "</p>\n";
            }


            if ($dismode["votedisplay"] == "fullmotion") 
            {
                print "<p>Someone who believes that ";
                print "<span class=\"policytext\">".str_replace("\n", "<br>", html_scrub($voter2attr["description"])) . "</span> ";
                if ($dismode["votedisplay"] != "fullmotion")
                    print "would cast votes as in the 'Policy vote' column.";
                else
                    print "would cast votes described by the policy."; 
                print "</p>\n"; 
            }
        }

		#if ($dismode["eventsinfo"])
		#    print " Also shows when this MP became or stopped being a paid minister. </p>";

		# convert the view for the table selection depending on who are the voting actors
		if ($dismode["votelist"] == "every")
			$showwhichvotes = "everyvote";
		else if ($voter2type == "party")
			$showwhichvotes = ($dismode["votelist"] == "all" ? "all1" : "bothdiff");
		else if ($voter2type == "dreammp")
			$showwhichvotes = "all2";
		else if ($dismode["votelist"] == "all")
			$showwhichvotes = "either";
		else if ($dismode["votelist"] == "short")
			$showwhichvotes = "bothdiff";
		else
			$showwhichvotes = "both";

if (true===function_exists('advertisement')) {
    advertisement('mp');
}?>
<?php
		# division table attributes used
		$divtabattr = array(
				"voter1type" 	=> $voter1type,
				#"voter1"        => $mpprop, # filled in loop below
				"voter1link"	=> $voter1link,
				"voter2type"	=> $voter2type,
				"voter2"		=> $voter2,
				"voter2attr"    => $voter2attr,
				"voter2link"	=> $voter2link,
				"showwhich"		=> $showwhichvotes,
				"votedisplay"	=> $dismode["votedisplay"],
				"headings"		=> 'columns',
				"sortby"		=> 'date'	);

		# make the table over this MP's votes

		# get rid of headings in the full motion case
		if ($dismode["votedisplay"] == "fullmotion")
		{
			$divtabattr["headings"] = 'none';
			$divtabattr["sortby"] = 'datereversed';
		    print "<table>\n";  // so we get underlines
		}
		else
        {
            if ($voter2type == "dreammp")
                $divtabattr["sortby"] = 'datereversed';
		    print "<table class=\"votes\">\n";
            if ($voter2type == "dreammp")
                print '<caption><a href="http://www.publicwhip.org.uk/faq.php#ayemajority">Why Majority/minority instead of Aye/No?</a></caption>';
        }

        if ($divtabattr["sortby"] == 'datereversed')
            $voter1attr['mpprops'] = array_reverse($voter1attr['mpprops']); 


		# the full version is in chron order so it can be printed out.  But saying so is sheer clutter.
		# print "<p>Table is in".($divtabattr["sortby"] == 'datereversed' ? "" : " reverse")." chronological order.</p>\n";

    	foreach ($voter1attr['mpprops'] as $lkey => $mppropt)
		{
			if (($rdisplay_parliament != "all") && ($rdisplay_parliament != $mppropt["parliament"]))
                continue; 

            $divtabattr["voter1"] = $mppropt;
			$events = $mppropt["mpevents"];  # a bit confused, but a complete list of events per mpid makes the code simple
            if ($events && $divtabattr["sortby"] == 'datereversed')
                $events = array_reverse($events); 

            # slip in a title in the multiperson case
			if ($voter1attr['bmultiperson'] && ($divtabattr["votedisplay"] != "fullmotion"))
				print "<tr><td colspan=7 align=left>
                    <b>Votes by <a href=\"mp.php?".$mppropt['mpanchor']."\">" .$mppropt["name"]." MP</a></b>
                    </td></tr>\n";

			# apply a designated voter
			$divtabattr["divhrefappend"] = "&".$mppropt['mpanchor'];

			# apply a date range to the current MP in this list, and roll up the year range.  

			# long asignment for return value because we're lacking foreach as &
			$voter1attr['mpprops'][$lkey]["dismetric"] = division_table($db, $divtabattr, $db2, $events);

			# remove repeated listing of headings
			#if ($divtabattr["headings"] == 'columns')
			#	$divtabattr["headings"] = 'none';
		}
	    print "</table>\n";

		# generate a friendliness table from the data
		if ($voter2type == "dreammp")
		{
            print "<h2><a name=\"ratioexpl\">How the number is calculated</a></h2>\n";
            if (count($voter1attr['mpprops']) == 0)
                print "<p><b>There is no overlap between this MPs term and the votes in this policy.</b></p>\n";
            elseif ($voter1attr['bmultiperson'])
                print "<p><b>Calculation only available for single MPs.</b></p>\n";
            else
            {
                print "<p>The MP's votes count towards a weighted average where the most important votes
                          get 50 points, less important votes get 10 points, and less important votes for which the 
                          MP was absent get 2 points.  
                          In important votes the MP gets awarded the full 50 points for voting the same as the policy, 
                          no points for voting against the policy, and 25 points for not voting.
                          In less important votes, the MP gets 10 points for voting with the policy, 
                          no points for voting against, and 1 (out of 2) if absent.</p>\n";
                print "<p>Questions about this formula can be discussed on <a href=\"http://www.publicwhip.org.uk/forum/viewtopic.php?t=150\">the forum</a>.</p>\n"; 

                # sum up the arrays
                foreach ($voter1attr['mpprops'] as $mppropt)
                {
                    if ($dismetric)
                    {
                        foreach($mppropt["dismetric"] as $lkey => $lvalue)
                            $dismetric[$lkey] += $lvalue;
                    }
                    else
                        $dismetric = $mppropt["dismetric"];
                }

                # outputs an explanation of the votes
                print_dreammp_person_distance($dismetric["agree"], $dismetric["agree3"],
                              $dismetric["disagree"], $dismetric["disagree3"],
                              $dismetric["ab1"], $dismetric["ab1line3"],
                                  $db, $mppropt["person"], $voter2);
            }
		}

		# unfinished business, kind of.
		if ($voter2type == "person" and $showwhich == "everyvote")
		{
			print "<p>[Explanation of distance relationship between MPs and people should be shown here.]</p>\n";
		}
	}

	if ($dismode["dreamcompare"])
	{
		print "<h2><a name=\"dreammotions\">Policy Comparisons</a>\n";
        print "</h2>\n";

		print "<p>This chart shows the percentage agreement between this " .
        ($voter1attr['bmultihouse'] ? "person" : $mpprop['housenoun'])
         . " and each of the policies in the database, according to their
        voting record.  </p>\n";

	    print "<table class=\"mps\">\n";
		$dreamtabattr = array("listtype" => 'comparelinks',
						      'person' => $mpprop["person"],
						      'mpanchor' => $mpprop["mpanchor"],
						      'listlength' => $dismode["dreamcompare"],
						      'headings' => 'yes');
		print_policy_table($db, $dreamtabattr);
	    print "</table>\n";
	}

	# the friends tables
	if ($dismode["possfriends"])
	{
		# loop and make a table for each
        $mpprop = $voter1attr['mpprop'];
        if (($rdisplay_parliament != "all") && ($mpprop["parliament"] != $rdisplay_parliament))
        {
            foreach ($voter1attr['mpprops'] as $lkey => $lmpprop)
            {
                if ($lmpprop["parliament"] == $rdisplay_parliament)
                    $mpprop = $lmpprop;
            }
        }
        
        $mptabattr = array("listtype" => 'mpdistance',
                           'mpfriend' => $mpprop,
                           'house' => $mpprop['house'], 
                           'headings' => 'yes');
        if ($dismode["possfriends"] == "some")
            $mptabattr["limit"] = 5;

	    print "<h2><a name=\"friends\">";
		if ($dismode["possfriends"] == "all")
			print "All ";
		print "Possible Friends";
		if ($dismode["possfriends"] != "all")
            print " (<a href=\"$thispage&display=allfriends\">more...</a>)";

        print "</a></h2>";
	    print "<p>Shows which ".$mpprop['housenounplural']." voted most similarly to this one in the ";
        print pretty_parliament_and_party($mpprop['enteredhouse'], $mpprop['party'], $mpprop['enteredreason'], $mpprop['leftreason']);
        print ". This is measured from 0% agreement (never voted the same) to 100% (always
		    voted the same).  Only votes that both ".$mpprop['housenounplural']." attended are
		    counted.  This may reveal relationships between ".$mpprop['housenounplural']." that were
		    previously unsuspected.  Or it may be nonsense.";

        print "<table class=\"mps\">\n";
        $same_voters = mp_table( $mptabattr);
        print "</table>\n";

        if ($same_voters)
            print "($same_voters MPs voted exactly the same as this one)\n";

        # do only one table if it's a show all case
        # if ($dismode["possfriends"] == "all")
        #    break;
    }
pw_footer();

