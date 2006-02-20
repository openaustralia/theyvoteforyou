<?php require_once "common.inc";
    # $Id: mp.php,v 1.120 2006/02/20 10:29:31 publicwhip Exp $

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
    if ($voter1attr["bmultiperson"])
        $voter1link .= "mpc=".urlencode($mpprop['constituency']);
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
							 "eventsinfo" => "yes",
							 "description" => ($voter2type == "dreammp" ? "Summary" : "Votes attended"),
                             "votelist"	=> "all",
							 "defaultparl" => "recent",
                             "tooltip" => "Show every vote cast by this MP");
	if (!$voter1attr['bmultiperson'])
		$dismodes["allvotes"]["eventsinfo"] = "yes";
	if (/*$voter2type != "party" and */$voter2type != "dreammp")
		$dismodes["allvotes"]["generalinfo"] = "yes";

	if ($voter2type == "dreammp")
	{
		$dismodes["motions"] = array("dtype"	=> "motions",
								 "description" => "Full",
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
		$title = "Policy Report - '".html_scrub($voter2attr['name'])."' compared to ";
		if ($voter1attr["bmultiperson"])
			$title .= $mpprop['housenounplural']." ".$contitlefor;
		else
			$title .= $mpprop['fullname'];
	}
	else if ($voter2type == "person")
		$title = "Voting Comparison - ".$mpprop['fullname']."<br> to ".$voter2attr["mpprop"]['fullname'];
	else if ($dismode["possfriends"] == "all")
		$title = "Friends of ".$mpprop['name']." ".$mpprop['housenamesuffix'].$contitlecomma;
	else if ($voter1attr["bmultiperson"])
		$title = "Voting Record - ".$mpprop['housenounplural']." ".$contitlefor;
	else
		$title = "Voting Record - ".$mpprop['fullname'];

    # make list of links to other display modes
    $second_links = dismodes_to_second_links($thispage, $dismodes, "", $display);

    pw_header();
?>


<?
	# extract the events in this mp's life
	# the events that have happened in this MP's career
	if ($dismode["eventsinfo"])
	{
		# generate ministerial events (maybe events for general elections?)
	 	$query = "SELECT dept, position, responsibility, from_date, to_date
	        	  FROM pw_moffice
				  WHERE pw_moffice.person = '".$voter1attr["mpprop"]["person"]."'
	        	  ORDER BY from_date DESC";
		if ($bdebug == 1)
			print "<h1>query for events: $query</h1>\n";
	    $db->query($query);

		# we insert an events array into each mpprop, which we will allocate timewise
		for ($i = 0; $i < count($voter1attr["mpprops"]); $i++)
			$voter1attr["mpprops"][$i]["mpevents"] = array();

		function puteventintompprop(&$mpprops, $eventdate, $eventdesc)
		{
			for ($i = 0; $i < count($mpprops) - 1; $i++)
				if ($eventdate >= $mpprops[$i + 1]["lefthouse"])
					break;
            array_push($mpprops[$i]["mpevents"], array($eventdate, $eventdesc));
		}

		$currently_minister = "";
		# it goes in reverse order
	    while ($row = $db->fetch_row_assoc())
	    {
	        if ($row["to_date"] == "9999-12-31")
	            $currently_minister = pretty_minister($row);
			else
				puteventintompprop($voter1attr["mpprops"], $row["to_date"], "Stopped being ".pretty_minister($row));
			puteventintompprop($voter1attr["mpprops"], $row["from_date"], "Became ".pretty_minister($row));
	    }

		# reverse the arrays that we create (could have done above loop already reversed)
		for ($i = 0; $i < count($voter1attr["mpprops"]); $i++)
			$voter1attr["mpprops"][$i]["mpevents"] = array_reverse($voter1attr["mpprops"][$i]["mpevents"]);
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
		print "<p><b>".$mpprop['name']."</b> is currently <b>$currently_minister</b>.<br>";
	else
		print "<p>";
        if ($mpprop['house'] == 'commons')
            print "Please note, our records only go back to 1997.";
        else
            print "Please note, our records only go back to May 2005.";
	seat_summary_table($voter1attr['mpprops'], $voter1attr['bmultiperson'], ($all_same_cons ? false : true), true, $thispagesettings);

        if ($mpprop['house'] == 'commons' && $voter2type == "party")
		{
		    print "<h2><a name=\"exlinks\">External Links</a></h2>\n";
            print "<ul>\n";

			print "<li>See <strong>".$mpprop["name"]."</strong>'s Parliamentary speeches at: ";
			print "<a href=\"http://www.theyworkforyou.com/mp/?m=".$mpprop["mpid"]."\">TheyWorkForYou.com</a></li>\n";

			# can we link directly?
			print "<li>Contact your MP for free at: <a href=\"http://www.writetothem.com\">WriteToThem.com</a></li>\n";

			print "<li><b>New!</b> Form a long term relationship with your MP: <a href=\"http://www.hearfromyourmp.com\">HearFromYourMP.com</a></li>\n";

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
	        	a teller (Teller), or both (Rebel Teller).  \n";
            print "<a href=\"$thispage&display=allvotes\">Click here to see all votes this person attended.</a>";
        }
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

            print "<p>";
            $previous_person = -1;
            foreach ($voter1attr['mpprops'] as $pp) {
                if ($pevious_person == $pp["person"])
                    continue;
                $query   = "SELECT nvotessame, nvotessamestrong,
                                nvotesdiffer, nvotesdifferstrong,
                                nvotesabsent, nvotesabsentstrong,
                                distance_a, distance_b
                            FROM pw_cache_dreamreal_distance
                            WHERE dream_id = $voter2 AND person = ".$pp["person"];
                $row = $db->query_onez_row_assoc($query);
                print "<a href=\"".$voter1link."\">".html_scrub($pp['fullname'])."</a>";
                print " agrees ";
                print " <b>";
                print pretty_distance_to_agreement($row['distance_a']);
                print "</b>";
                print " (<a href=\"#ratioexpl\">explain...</a>)";
                print " with ";
                print "<a href=\"$voter2link\">".html_scrub($voter2attr['name'])."</a> ";
                print "<br>";
                $pevious_person = $pp["person"];
            }
                
			print "<p class=\"policydefinition\"><b>Definition of <a href=\"$voter2link\">".html_scrub($voter2attr['name'])."</a> policy:</b>\n";
			print html_scrub($voter2attr['description']);
			print "</p>\n";

            print "<h2>Vote Details</h2>";
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
			$voter1attr['mpprops'] = array_reverse($voter1attr['mpprops']);
		    print "<table>\n";  // so we get underlines
		}
		else
		    print "<table class=\"votes\">\n";

		# the full version is in chron order so it can be printed out.  But saying so is sheer clutter.
		# print "<p>Table is in".($divtabattr["sortby"] == 'datereversed' ? "" : " reverse")." chronological order.</p>\n";

    	foreach ($voter1attr['mpprops'] as $lkey => $mppropt)
		{
			$divtabattr["voter1"] = $mppropt;
			$events = $mppropt["mpevents"];  # a bit confused, but a complete list of events per mpid makes the code simple

			# slip in a title in the multiperson case
			if ($voter1attr['bmultiperson'] && ($divtabattr["votedisplay"] != "fullmotion"))
				print "<tr><td colspan=7 align=left>
                    <b>Votes by <a href=\"mp.php?".$mppropt['mpanchor']."\">" .$mppropt["name"]." MP</a></b>
                    </td></tr>\n";

			# apply a designated voter
			$divtabattr["divhrefappend"] = "&".$mppropt['mpanchor'];

			# long asignment for return value because we're lacking foreach as &
			$voter1attr['mpprops'][$lkey]["dismetric"] = division_table($db, $divtabattr, $events);

			# remove repeated listing of headings
			#if ($divtabattr["headings"] == 'columns')
			#	$divtabattr["headings"] = 'none';
		}
	    print "</table>\n";

		# generate a friendliness table from the data
		if ($voter2type == "dreammp")
		{
            print "<h2><a name=\"ratioexpl\">Agreement Score Explanation</a></h2>\n";
            if (count($voter1attr['mpprops']) == 0)
                print "<p><b>There is no overlap between this MPs term and the votes in this policy.</b></p>\n";
            elseif ($voter1attr['bmultiperson'])
                print "<p><b>Calculation only available for single MPs.</b></p>\n";
            else
            {
                print "<p>The measure of agreement between this MP and the policy is a calculation
                        based on a comparison of their votes.</p>\n";
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

?>


<?php
	if ($dismode["dreamcompare"])
	{
		print "<h2><a name=\"dreammotions\">Policy Comparisons</a>\n";
        print "</h2>\n";

		print "<p>This chart shows the percentage agreement between this " . 
        ($voter1attr['bmultihouse'] ? "person" : $mpprop['housenoun'])
         . " and each of the policies in the database, according to their
        voting record.  </p>\n";

	    print "<table class=\"mps\">\n";
	    print "<tr class=\"headings\">
	        <td>Agreement</td>
	        <td>Policy</td>
	        <td>Description</td>
	        <td>Vote</td>
	        </tr>\n";

		$dreamtabattr = array("listtype" => 'comparelinks',
						      'person' => $mpprop["person"],
						      'mpanchor' => $mpprop["mpanchor"],
						      'listlength' => $dismode["dreamcompare"]);
		print_policy_table($db, $dreamtabattr);
	    print "</table>\n";
	}
?>

<?php
	# the friends tables
	if ($dismode["possfriends"])
	{
		# loop and make a table for each
        $mpprop = $voter1attr['mpprop'];
        $mptabattr = array("listtype" => 'mpdistance',
                           'mpfriend' => $mpprop,
                           'house' => $mpprop['house']);
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
        print "<tr class=\"headings\"><td>Agreement</td><td>Name</td>";
        if ($mpprop['house'] != "lords")
            print "<td>Constituency</td>";
        print "<td>Party</td></tr>\n";
        $same_voters = mp_table($db, $mptabattr);
        print "</table>\n";

        if ($same_voters)
            print "($same_voters MPs voted exactly the same as this one)\n";

        # do only one table if it's a show all case
        # if ($dismode["possfriends"] == "all")
        #    break;
    }
?>


<?php pw_footer() ?>

