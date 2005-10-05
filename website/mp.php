<?php require_once "common.inc";
    # $Id: mp.php,v 1.87 2005/10/05 11:22:03 goatchurch Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "cache-begin.inc";

    include "db.inc";
    $db = new DB();
	$db2 = new DB();

	# standard decoding functions for the url attributes
	include "decodeids.inc";
	include "tablemake.inc";
	include "tableoth.inc";
    include "dream.inc";
	include "tablepeop.inc";

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
	if ($voter1attr == null)
	{
        $title = "MP/Peer not found";
        include "header.inc";
		print "<p>No MP or Peer found. If you entered a postcode, please make
        sure it is correct.  Or you can <a href=\"/mps.php\">browse
        all MPs</a>.";
        include "footer.inc";
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
	$thispage = "$voter1link&$thispagesettings";

	# constants
	$dismodes = array();
	if ($voter2type == "party")
	{
		$dismodes["summary"] = array("dtype"	=> "summary",
								 "description" => "Summary",
								 "generalinfo" => "yes",
								 "votelist"	=> "short",
								 "possfriends"	=> "some",
								 /*"dreamcompare"	=> "short"*/);
		if (!$voter1attr['bmultiperson'])
			$dismodes["summary"]["eventsinfo"] = "yes";
	}

	if ($voter2type == "person")
	{
		$dismodes["difference"] = array("dtype"	=> "difference",
								 "description" => "Differences",
								 "generalinfo" => "yes",
								 "votelist"	=> "short");
	}

	$dismodes["allvotes"] = array("dtype"	=> "allvotes",
							 "eventsinfo" => "yes",
							 "description" => ($voter2type == "dreammp" ? "Summary" : "All votes"),
							 "votelist"	=> "all",
							 "defaultparl" => "recent");
	if (!$voter1attr['bmultiperson'])
		$dismodes["allvotes"]["eventsinfo"] = "yes";
	if ($voter2type != "party" and $voter2type != "dreammp")
		$dismodes["allvotes"]["generalinfo"] = "yes";

	if ($voter2type == "dreammp")
	{
		$dismodes["motions"] = array("dtype"	=> "motions",
								 "description" => "Unabbreviated",
								 "votelist"	=> "all",
								 "votedisplay"	=> "fullmotion",
								 "defaultparl" => "recent");
		if ($voter1attr['bmultiperson'])
			$dismodes["motions"]["multimpterms"] = "yes";
	}

	if ($voter2type != "dreammp")
	{
		$dismodes["everyvote"] = array("dtype"	=> "everyvote",
								 "description" => "Every division",
								 "votelist"	=> "every",
								 "defaultparl" => "recent");
		if (!$voter1attr['bmultiperson'])
			$dismodes["everyvote"]["eventsinfo"] = "yes";
		if ($voter2type != "party")
			$dismodes["everyvote"]["generalinfo"] = "yes";
	}

	# friendships if not a comparison table
	if ($voter2type == "party")
	{
		$dismodes["allfriends"] = array("dtype"	=> "allfriends",
								 "description" => "All possible friends",
								 "possfriends"	=> "all",
								 "defaultparl" => "recent");

		$dismodes["alldreams"] = array("dtype"	=> "alldreams",
								 "description" => "Policy comparisons",
								 "dreamcompare"	=> "public",
								 "defaultparl" => "all");
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
	if ($voter2type == "dreammp")
	{
		$title = "Policy Report - ";
		if ($voter1attr["bmultiperson"])
			$title .= $mpprop['housenounplural']." ".$contitlefor;
		else
			$title .= $mpprop['fullname'];
		$title .= "<br> on ".html_scrub($voter2attr['name']);
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
    $second_links = array();
    foreach ($dismodes as $ldisplay => $ldismode)
    {
        $leadch = " | ";
        $dlink = "href=\"$thispage".($ldisplay != "summary" ? "&display=$ldisplay" : "")."\"";
        array_push($second_links, "<a $dlink class=\"".($ldisplay == $display ? "on" : "off")."\">".$ldismode["description"]."</a>");
    }

    include "header.inc";
?>

<?
	# extract the events in this mp's life
	# the events that have happened in this MP's career
	if ($dismode["eventsinfo"])
	{
		# generate ministerial events (maybe events for general elections?)
	 	$query = "SELECT dept, position, from_date, to_date
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
	            $currently_minister = $row["position"].", ".$row["dept"];
			else
				puteventintompprop($voter1attr["mpprops"], $row["to_date"], "Stopped being ".$row["position"].", ".$row["dept"]);
			puteventintompprop($voter1attr["mpprops"], $row["from_date"], "Became ".$row["position"].", ".$row["dept"]);
	    }

		# reverse the arrays that we create (could have done above loop already reversed)
		for ($i = 0; $i < count($voter1attr["mpprops"]); $i++)
			$voter1attr["mpprops"][$i]["mpevents"] = array_reverse($voter1attr["mpprops"][$i]["mpevents"]);
	}

	# general information
	if ($dismode["generalinfo"])
	{
	    print "<h2><a name=\"general\">General Information</a></h2>";

        // See if MP always in same constituency
        $con = $mpprop['constituency'];
        $all_same_cons = true;
        foreach ($voter1attr['mpprops'] as $p)
		{
            if ($p['constituency'] != $con)
                $all_same_cons = false;
        }

	    if ($currently_minister)
	        print "<p><b>".$mpprop['name']."</b> is currently <b>$currently_minister</b>.<br>
	               MP for <b>".$mpprop['constituency']."</b>";
	    else if ($voter1attr['bmultiperson'])
	        print "<p>MPs who have represented <b>".$mpprop['constituency']."</b>";
	    else {
	        print "<p><b>".$mpprop['name']."</b> has been " . $mpprop['housenoun']." ";
            if ($all_same_cons && $mpprop['house'] == 'commons')
                print " for <b>".$mpprop['constituency']."</b>";
        }
        if ($mpprop['house'] == 'commons')
            print " during the following periods of time in the last three parliaments";
        else
            print " during the following periods of time since our records began";
        print ":<br>(Check out <a href=\"faq.php#clarify\">our explanation</a> of 'attendance'
		            and 'rebellions', as they may not have the meanings you expect.)</p>";

		seat_summary_table($voter1attr['mpprops'], $voter1attr['bmultiperson'], ($all_same_cons ? false : true), true, $thispagesettings);

        if ($mpprop['house'] == 'commons' && $voter2type == "party")
		{
		    print "<h2><a name=\"exlinks\">External Links</a></h2>\n";
            print "<ul>\n";

			print "<li>Read Parliamentary speeches at: ";
			print "<a href=\"http://www.theyworkforyou.com/mp/?m=".$mpprop["mpid"]."\">TheyWorkForYou.com</a></li>\n";

			# can we link directly?
			print "<li>Contact your MP for free at: <a href=\"http://www.writetothem.com\">WriteToThem.com</a></li>\n";

			print "<li><b>New!</b> Sign up to your constituency mailing list at: <a href=\"http://www.mysociety.org/ycml/\">MySociety.org</a></li>\n";

            print "</ul>\n";
        }
	}

	if ($dismode["votelist"])
    {
		# title for the vote table
	    if ($voter2type == "dreammp")
	        $vtitle = ""; #Votes chosen by '".$voter2attr['name']."' Policy";
		else if ($voter2type == "person" && $dismode["votelist"] == "short")
			$vtitle = "Voting Differences";
		else if ($dismode["votelist"] == "short")
			$vtitle = "Interesting Votes";
		else if ($dismode["votelist"] == "every")
			$vtitle .= "Every Vote";
		else
			$vtitle = "Votes Attended";
        if ($vtitle)
            print "<h2><a name=\"divisions\">$vtitle</a></h2>\n";

		# subtext for the vote table
		if ($dismode["votelist"] == "short" and $voter2type == "party")
			print "<p>Votes in parliament for which this ".$mpprop['housenoun']."'s vote differed from the
	        	majority vote of their party (Rebel), or in which this ".$mpprop['housenoun']." was
	        	a teller (Teller), or both (Rebel Teller).  \n";
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

			print "<p><b>Definition of <a href=\"$voter2link\">".html_scrub($voter2attr['name'])."</a>:</b>\n";
			print html_scrub($voter2attr['description']);
			print "</p>\n";
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
				#"voter1"        => $mpprop,
				"voter1link"	=> $voter1link,
				"voter2type"	=> $voter2type,
				"voter2"		=> $voter2,
				"voter2link"	=> $voter2link,
				"showwhich"		=> $showwhichvotes,
				"votedisplay"	=> $dismode["votedisplay"],
				"headings"		=> 'columns',
				"sortby"		=> 'date'	);

		# get rid of headings in the full motion case
		if ($dismode["votedisplay"] == "fullmotion")
		{
			$divtabattr["headings"] = 'none';
			$divtabattr["sortby"] = 'datereversed';
			$voter1attr['mpprops'] = array_reverse($voter1attr['mpprops']);
		}

		# the full version is in chron order so it can be printed out.  But saying so is sheer clutter.
		# print "<p>Table is in".($divtabattr["sortby"] == 'datereversed' ? "" : " reverse")." chronological order.</p>\n";

		# make the table over this MP's votes
	    print "<table class=\"votes\">\n";
    	foreach ($voter1attr['mpprops'] as $lkey => $mpprop)
		{
			$divtabattr["voter1"] = $mpprop;
			$events = $mpprop["mpevents"];  # a bit confused, but a complete list of events per mpid makes the code simple

			# slip in a title in the multiperson case
			if ($voter1attr['bmultiperson'] && ($divtabattr["votedisplay"] != "fullmotion"))
				print "<tr><td colspan=7 align=left>
                    <b>Votes by <a href=\"mp.php?".$mpprop['mpanchor']."\">" .$mpprop["name"]." MP</a></b>
                    </td></tr>\n";

			# apply a designated voter
			$divtabattr["divhrefappend"] = "&".$mpprop['mpanchor'];

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
			print "<h3>Similarity equation</h3>\n";
            if ($voter1attr["bmultiperson"])
            	print "<p>Value is meaningless for a table of more than one MP.</p>";
			else
			{
				print "<p>This MP is scored against the policy,
					   coming up with a 'voting distance' between them.  The voting distance is
					   between 0.0 and 1.0. Here is how we calculate the score.</p>\n";
				# sum up the arrays
				foreach ($voter1attr['mpprops'] as $mpprop)
				{
					if ($dismetric)
					{
						foreach($mpprop["dismetric"] as $lkey => $lvalue)
							$dismetric[$lkey] += $lvalue;
					}
					else
						$dismetric = $mpprop["dismetric"];
				}

				# outputs an explanation of the votes
				print_dreammp_person_distance($dismetric["agree"], $dismetric["agree3"],
							  $dismetric["disagree"], $dismetric["disagree3"],
							  $dismetric["ab1"], $dismetric["ab1line3"],
								  $db, $mpprop["person"], $voter2);
			}
		}

		if ($voter2type == "person" and $showwhich == "everyvote")
		{
			print "<p>[Explanation of distance relationship between MPs and people should be shown here.]</p>\n";
		}
	}

?>


<?php
	# the friends tables
	if ($dismode["possfriends"])
	{
	    print "<h2><a name=\"friends\">";
		if ($dismode["possfriends"] == "all")
			print "All ";
		print "Possible Friends</a></h2>";
	    print "<p>Shows which ".$mpprop['housenounplural']." voted most similarly to this one. The
    		distance is measured from 0 (always voted the same) to 1 (always
		    voted differently).  Only votes that both ".$mpprop['housenounplural']." attended are
		    counted.  This may reveal relationships between ".$mpprop['housenounplural']." that were
		    previously unsuspected.  Or it may be nonsense.";


	# 	'dreamdistance', then 'dreammpid' is what we compare to
	#   'division', then 'divdate', 'divno' index into that
	#   'division2, then there's also 'divdate2', 'divno2'
	# limit is nothing or a number
	# sortby is 'turnout', 'rebellions', 'name', 'constituency', 'attendance'

		# loop and make a table for each
		foreach ($voter1attr['mpprops'] as $mpprop)
		{
			$mptabattr = array("listtype" => 'mpdistance',
							   'mpfriend' => $mpprop);
			if ($dismode["possfriends"] == "some")
				$mptabattr["limit"] = 5;

	        print "<h3>" . pretty_parliament_and_party($mpprop['enteredhouse'], $mpprop['party'], $mpprop['enteredreason'], $mpprop['leftreason']). "</h3>";
	        print "<table class=\"mps\">\n";
	        print "<tr class=\"headings\"><td>Name</td><td>Constituency</td><td>Party</td><td>Distance</td></tr>\n";
			$same_voters = mp_table($db, $mptabattr);
	        print "</table>\n";

			if ($same_voters)
                print "<p>($same_voters MPs voted exactly the same as this one)\n";

			# do only one table if it's a show all case
			if ($dismode["possfriends"] == "all")
				break;
		}
    }
?>

<?php
	if ($dismode["dreamcompare"])
	{
		print "<h2><a name=\"dreammotions\">Policy Comparisons</a></h2>";
	    print "<table class=\"mps\">\n";
	    print "<tr class=\"headings\">
	        <td>Votes</td>
	        <td>Made by</td>
	        <td>Policy</td>
	        <td>Description</td>
	        </tr>";

	    $prettyrow = 0;
        if ($dismode["dreamcompare"] == "all")
            $db->query(get_top_dream_query(null));
        else if ($dismode["dreamcompare"] == "public")
            $db->query(get_top_dream_query(-1));
        else
            $db->query(get_top_dream_query(8));
	    $dreams = array();
	    while ($row = $db->fetch_row_assoc()) {
	        $dreamid = $row['dream_id'];
	        $prettyrow = pretty_row_start($prettyrow);
	        print_selected_dream($db, $mpprop, $dreamid);
	    }
	    print "</table>\n";
	}
?>


<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>

