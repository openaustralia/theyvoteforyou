<?php require_once "common.inc";
    # $Id: mp.php,v 1.61 2005/03/09 19:38:51 goatchurch Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "cache-begin.inc";

    include "db.inc";
    $db = new DB();

	# standard decoding functions for the url attributes
	include "decodeids.inc";
	include "tablemake.inc";
	include "tableoth.inc";
    include "dream.inc";
	include "tablepeop.inc";

	# decode the parameters.
	# first is the two voting objects which get compared together.
	# First is an mp (arranged by person or by constituency)
	# Second is another mp (by person), a dream mp, or a/the party
	$voter1attr = get_mpid_attr_decode($db, "");
	if ($voter1attr == null)
		die("No mp found that fit parameters");
	$voter1type = "mp";

	# against a dreammp, another mp, or the party
	$voter2attr = get_dreammpid_attr_decode($db, "");
	if ($voter2attr != null)
	{
		$voter2type = "dreammp";
		$voter2 = $voter2attr['dreammpid'];
	}
	else
	{
		$voter2attr = get_mpid_attr_decode($db, "2");
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

	# shorthand to get at the designated MP for this class of MP holders
	# (multiple sets of properties, usually overlapping, hold for each MP if they've had more than one term)
	$mpprop = $voter1attr["mpprop"];

	# case now is we know the two voting actors,
	# (and whether the first is a constituency or a person)
	# select a mode for what is displayed
	# code for the 0th mp def, if it is there.
    $thispagemp = "mp.php?";
	$thispagemp .= "mpn=".urlencode(str_replace(" ", "_", $mpprop['name']))."&"."mpc=".urlencode($mpprop['constituency']);

	# extend to the comparison type
	$thispage = $thispagemp;
	if ($voter2type == "dreammp")
		$thispage .= "&dmp=".$voter2;
	else if ($voter2type == "person")
		$thispage .= "&mpn2=".urlencode(str_replace(" ", "_", $voter2["mpprop"]['name']))."&"."mpc2=".urlencode($voter2["mpprop"]['constituency']);

	# constants
	$dismodes = array();
	if ($voter2type == "party")
	{
		$dismodes["summary"] = array("dtype"	=> "summary",
								 "description" => "Summary",
								 "generalinfo" => "yes",
								 "votelist"	=> "short",
								 "possfriends"	=> "some",
								 "dreamcompare"	=> "short");
	}

	if ($voter2type == "person")
	{
		$dismodes["difference"] = array("dtype"	=> "difference",
								 "description" => "Differences",
								 "votelist"	=> "short");
	}

	$dismodes["allvotes"] = array("dtype"	=> "allvotes",
							 "generalinfo" => "eventsonly",
							 "description" => "All votes",
							 "votelist"	=> "all",
							 "defaultparl" => "recent");
	if ($voter2type == "party")
		$dismodes["allvotes"]["generalinfo"] = "eventsonly";

	if ($voter2type == "dreammp")
	{
		$dismodes["motions"] = array("dtype"	=> "motions",
								 "description" => "Display motions",
								 "votelist"	=> "all",
								 "votedisplay"	=> "fullmotion",
								 "defaultparl" => "recent");
	}

	if ($voter2type != "dreammp")
	{
		$dismodes["everyvote"] = array("dtype"	=> "everyvote",
								 "description" => "Every division",
								 "generalinfo" => "yes",
								 "votelist"	=> "every",
								 "defaultparl" => "recent");
		if ($voter2type == "party")
			$dismodes["everyvote"]["generalinfo"] = "eventsonly";
	}

	# friendships if not a comparison table
	if ($voter2type == "party")
	{
		$dismodes["allfriends"] = array("dtype"	=> "allfriends",
								 "description" => "All possible friends",
								 "possfriends"	=> "all",
								 "defaultparl" => "recent");

		$dismodes["alldreams"] = array("dtype"	=> "alldreams",
								 "description" => "All dream comparisons",
								 "dreamcompare"	=> "all",
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


	# generate title and header of this webpage
	if ($voter2type == "dreammp")
		$title = $mpprop['name']." MP, ".$mpprop['constituency']." - Whipped by '".$voter2attr['name']."'";
	else if ($voter2type == "person")
		$title = $mpprop['name']." MP, ".$mpprop['constituency']." - Compared to ".$voter2attr["mpprop"]['name']." MP";
	else if ($dismode["possfriends"] == "all")
		$title = "Friends of ".$mpprop['name']." MP, ".$mpprop['constituency'];
	else if ($voter1attr["bmultiperson"])
		$title = "Voting Record - Honourable Member for ".$mpprop['constituency'];
	else
		$title = "Voting Record - ".$mpprop['name']." MP, ".$mpprop['constituency'];
    include "header.inc";


	# make list of links to other display modes
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

	# secondary links to variations
	if ($voter2type != "party")
	{
		if ($display != "summary" and $voter2type != "dreammp")
			$dislink = "&display=$display";
		$dlink = "href=\"$thispagemp$dislink\"";
		print $leadch;
		$leadch = " | ";
		print "<a $dlink>Without comparison</a>";
	}
	if ($voter2type == "person")
	{
		$dlink = "mp.php?";
		$dlink .= "mpn=".urlencode(str_replace(" ", "_", $voter2["mpprop"]['name']))."&mpc=".urlencode($voter2["mpprop"]['constituency']);
		print $leadch;
		print "<a href=\"$dlink\">Compared MP</a>";
	}
	if ($voter2type == "dreammp")
	{
		$dlink = "href=\"dreammp.php?id=$voter2\"";
		print $leadch;
		print "<a $dlink>Dream MP</a>";
	}
	print "</p>\n";
?>

<?
	# extract the events in this mp's life
	$events = "";
	if ($dismode["generalinfo"])
	{
		$mpattr = $voter1attr;
		# the events that have happened in this MP's career
   		if (!$mpattr['bmultiperson'])
		{
			# generate ministerial events (maybe events for general elections?)
		 	$query = "SELECT dept, position, from_date, to_date
		        	  FROM pw_moffice
					  WHERE pw_moffice.person = '".$mpattr["mpprop"]["person"]."'
		        	  ORDER BY from_date DESC";
			if ($bdebug == 1)
				print "<h1>query for events: $query</h1>\n";
		    $db->query($query);

			$events = array();
			$currently_minister = "";
			# it goes in reverse order
		    while ($row = $db->fetch_row_assoc())
		    {
		        if ($row["to_date"] == "9999-12-31")
		            $currently_minister = $row["position"].  ", " .  $row["dept"];
				else
		            array_push($events, array($row["to_date"],   "Stopped being " .  $row["position"].  ", " . $row["dept"]));
		        array_push($events, 	array($row["from_date"], "Became " .  $row["position"]. ", 		   " . $row["dept"]));
		    }
		}
	}

	# general information
	if ($dismode["generalinfo"] == "yes")
	{
	    print "<h2><a name=\"general\">General Information</a></h2>";

	    if ($currently_minister)
	        print "<p><b>".$mpprop['name']."</b> is currently <b>$currently_minister</b>.<br>
	               MP for <b>".$mpprop['constituency']."</b>";
	    else if ($mpattr['bmultiperson'])
	        print "<p>MPs who have represented <b>".$mpprop['constituency']."</b>";
	    else
	        print "<p><b>".$mpprop['name']."</b> has been MP for <b>".$mpprop['constituency']."</b>";
		print " during the following periods of time during the last two parliaments:<br>";
		print "(Check out <a href=\"faq.php#clarify\">our explanation</a> of 'attendance'
	            and 'rebellions', as they may not have the meanings you expect.)</p>";

		seat_summary_table($mpattr['mpprops'], $mpattr['bmultiperson']);

	    print "<p><a href=\"http://www.theyworkforyou.com/mp/?m=".$mpprop["mpid"]."\">
	    		Performance data, recent speeches, and biographical links</a>
	    		at TheyWorkForYou.com.<br>
	    	   <a href=\"http://www.writetothem.com\">Contact your MP</a> for free at
	    		WriteToThem.com or look for their
				<a href=\"http://www.parliament.uk/directories/hciolists/alms.cfm\">
				email address</a>.";
	}
?>


<?php
	if ($dismode["votelist"])
    {
		# title for the vote table
	    if ($voter2type == "dreammp")
	        $vtitle = "Votes chosen by '".$voter2attr['name']."' Dream MP";
		else if ($voter2type == "person")
			$vtitle = "Votes compared to ".$voter2attr["mpprop"]['name']." MP";
		else if ($dismode["votelist"] == "short")
			$vtitle = "Interesting Votes";
		else if ($dismode["votelist"] == "every")
			$vtitle .= "Every Vote";
		else
			$vtitle = "Votes Attended";
		print "<h2><a name=\"divisions\">$vtitle</a></h2>\n";

		# subtext for the vote table
		if ($dismode["votelist"] == "short" and $voter2type == "party")
			print "<p>Votes in parliament for which this MP's vote differed from the
	        	majority vote of their party (Rebel), or in which this MP was
	        	a teller (Teller) or both (Rebel Teller).  \n";
		else if ($dismode["votelist"] == "every" and $voter2type == "party")
			print "<p>All votes this MP could have attended. \n";

		if ($events !== "")
		    print " Also shows when this MP became or stopped being a paid minister. </p>";

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
				"voter2type"	=> $voter2type,
				"voter2"		=> $voter2,
				"showwhich"		=> $showwhichvotes,
				"votedisplay"	=> $dismode["votedisplay"],
				"headings"		=> 'columns',
				"sortby"		=> 'date'	);

		# get rid of headings in the full motion case
		if ($dismode["votedisplay"] == "fullmotion")
		{
			$divtabattr["headings"] = 'none';
			$divtabattr["sortby"] = 'datereversed';
		}

		# put in the events list
		if ($events !== "")
		{
			if ($divtabattr['sortby'] == 'date')
				$events = array_reverse($events);
		}

		# make the table over this MP's votes
	    print "<table class=\"votes\">\n";
    	foreach ($voter1attr['mpprops'] as $mpprop)
		{
			$divtabattr["voter1"] = $mpprop;
			division_table($db, $divtabattr, $events);
		}
	    print "</table>\n";
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
	    print "<p>Shows which MPs voted most similarly to this one. The
    		distance is measured from 0 (always voted the same) to 1 (always
		    voted differently).  Only votes that both MPs attended are
		    counted.  This may reveal relationships between MPs that were
		    previously unsuspected.  Or it may be nonsense.";

		# loop and make a table for each
		if ($dismode["possfriends"] == "some")
		{
			foreach ($voter1attr['mpprops'] as $mpprop)
				print_possible_friends($db, $mpprop, $dismode["possfriends"]);
		}

		# if it's a show all, then just do it of one sitting mp
		else
			print_possible_friends($db, $voter1attr['mpprop'], $dismode["possfriends"]);
    }
?>

<?php
	if ($dismode["dreamcompare"])
	{
		print "<h2><a name=\"dreammotions\">Dream MP Comparisons</a></h2>";
	    print "<p>Votes on motions chosen by a Dream MP.  A selected list which can
	        be used to find what an MP stands for. Email us if you think your Dream
	        MP is appropriate to include here.";
	    print "<table class=\"mps\">\n";
	    print "<tr class=\"headings\">
	        <td>Votes</td>
	        <td>Made by</td>
	        <td>Dream MP</td>
	        <td>Description</td>
	        </tr>";
	
	    $prettyrow = 0;
        if ($dismode["dreamcompare"] == "all") 
            $db->query(get_top_dream_query(null));
        else
            $db->query(get_top_dream_query(8));
	    $dreams = array();
	    while ($row = $db->fetch_row_assoc()) {
	        $dreamid = $row['rollie_id'];
	        $prettyrow = pretty_row_start($prettyrow);
	        print_selected_dream($db, $mpprop, $dreamid);
	    }
	    print "</table>\n";
	}
?>


<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>

