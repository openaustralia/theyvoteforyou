<?php require_once "common.inc";
    # $Id: mp.php,v 1.54 2005/02/24 21:22:17 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "cache-begin.inc";

    include "db.inc";
    $db = new DB();
	$bdebug = 0;

	# standard decoding functions for the url attributes
	include "decodeids.inc";
	include "tablemake.inc";
	include "tableoth.inc";
    include "dream.inc";

	# decode the incoming line, getting all the alternatives;
	# mps take priority, then dreammps (the whips)
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
			$voter2 = ""; #could fill in party for clarity
		}
	}


	# try and construct some settings for what's visible on this page
	# [showall=yes]  [allfriends=yes]
	$showwhichfriends = "none";
	if ($voter2type == "party")
	{
	    if ($_GET["allfriends"] == "yes")
		{
			$showwhichvotes = "none";
			$showwhichfriends = "all";
		}
		else if ($_GET["showall"] == "yes")
			$showwhichvotes = "all1";
		else if ($_GET["showall"] == "every")
			$showwhichvotes = "everyvote";
		else
		{
			$showwhichvotes = "bothdiff";
			$showwhichfriends = "some";
		}
	}
	else
	{
		$showwhichvotes = "both";
		if ($_GET["showall"] == "yes")
			$showwhichvotes = "either";
		else if ($voter2type == "dreammp")
			$showwhichvotes = "all2";
		else if ($_GET["showall"] == "every")
			$showwhichvotes = "everyvote";
	}



	# code for the 0th mp def, if it is there.
	$mpid = $voter1attr["mpid"];
    $this_anchor = "mp.php?".$voter1attr["mpanchor"];

	if ($bdebug == 1)
		print "<h1>which votes: $showwhichvotes whichfriends: $showwhichfriends  mpid: $mpid</h1>\n";

	# generate the header of this webpage
	if ($showwhichvotes == "none")
		$title = html_scrub("Friends of ".$voter1attr['mpname']." MP, ".$voter1attr['constituency']);
    else if ($voter2type == "dreammp")
		$title = html_scrub($voter1attr['mpname']." MP, ".$voter1attr['constituency']." - Whipped by '".$voter2attr['name']."'");
    else if ($voter2type == "person")
		$title = html_scrub($voter1attr['mpname']." MP, ".$voter1attr['constituency']." - Compared to ".$voter2attr['mpname']." MP");
	else # party
		$title = html_scrub("Voting Record - ".$voter1attr['mpname']." MP, ".$voter1attr['constituency']);
    include "header.inc";


	# internal page links
	if ($showwhichvotes != "none" and $showwhichfriends != "none")
	{
		print '<p>';
		print '<a href="#divisions">Votes</a>';
		print ' | ';
		print '<a href="#friends">Possible Friends</a>';
		print ' | ';
		print '<a href="#dreammotions">Dream MP Comparisons</a>';
	}
?>

<?
	# extract the events in this mp's life
	if ($showwhichvotes != "none")
	{
		$mpattr = $voter1attr;
		# generate ministerial events (maybe events for general elections?)
	 	$query = "SELECT dept, position, from_date, to_date
	        	  FROM pw_moffice
				  WHERE pw_moffice.person = '".$mpattr["personid"]."'
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
		if ($mpattr['bmultiperson'])  # remove problem if not going to be the same guy all the way through
			$events = array();

	    print "<h2><a name=\"general\">General Information</a></h2>";

	    if ($currently_minister)
	        print "<p><b>".$mpattr['mpname']."</b> is currently <b>$currently_minister</b>.<br>
	               MP for <b>".$mpattr['constituency']."</b>";
	    else
	        print "<p><b>".$mpattr['mpname']."</b> has been MP for <b>".$mpattr['constituency']."</b>";
		print " during the following periods of time during the last two parliaments:<br>";
		print "(Check out <a href=\"faq.php#clarify\">our explanation</a> of 'attendance'
	            and 'rebellions', as they may not have the meanings you expect.)</p>";

		seat_summary_table($mpattr['mpprops'], $mpattr['bmultiperson']);

	    print "<p><a href=\"http://www.theyworkforyou.com/mp/?m=".$voter1attr["mpid"]."\">
	    		Performance data, recent speeches, and biographical links</a>
	    		at TheyWorkForYou.com.<br>
	    	   <a href=\"http://www.writetothem.com\">Contact your MP</a> for free at
	    		WriteToThem.com or look for their
				<a href=\"http://www.parliament.uk/directories/hciolists/alms.cfm\">
				email address</a>.";
	}
?>


<?php
    if ($showwhichvotes != "none")
    {
		if ($voter2type == "person")
		{
            print "<h2><a name=\"divisions\">Votes compared to ".$voter2attr['mpname']." MP</a></h2>";
	        print "<p>You can also see <a href=\"$this_anchor#divisions\">
				   only the votes".$voter1attr['mpname']." MP rebelled in</a>. ";
		}
	    else if ($voter2type == "dreammp")
	    {
	        print "<h2><a name=\"divisions\">Votes chosen by '".$voter2attr['name']."' Dream MP</a></h2>
	        	<p>The first column indicates this MP voted in comparison.
	        		You can also see <a href=\"$this_anchor&showall=yes#divisions\">all votes this MP attended</a>.";
	    }
    	else if ($showwhichvotes == "bothdiff")
	    {
	        print "<h2><a name=\"divisions\">Interesting Votes</a></h2>
	        	<p>Votes in parliament for which this MP's vote differed from the
	        	majority vote of their party (Rebel), or in which this MP was
	        	a teller (Teller) or both (Rebel Teller).  ";
	        print "You can also see <a href=\"$this_anchor&showall=yes#divisions\">all votes this MP attended</a> or
	        		<a href=\"$this_anchor&showall=every#divisions\">every vote</a> that this MP could have attended.</p>\n";
	    }
	    else
	    {
			if ($showwhichvotes == "everyvote")
		        print "<h2><a name=\"divisions\">All Votes</a></h2>
		        	<p>All Votes in which this MP could have voted.";
			else
		        print "<h2><a name=\"divisions\">Votes Attended</a></h2>
		        	<p>Votes in which this MP voted.";
			print "The first column
	        	indicates if they voted against the majority vote of
	        	their party (Rebel), were a teller for that side (Teller)
	        	or both (Rebel Teller).";
	    }
	    print " Also shows when the MP became or stopped being a paid minister. ";

		# make the table over this MP's votes
    	$events_ix = 0;
	    print "<table class=\"votes\">\n";
    	foreach ($voter1attr['mpprops'] as $mpprop)
			division_table($db, $voter1type, $mpprop, $voter2type, $voter2, $showwhichvotes, 'columns');
	    print "</table>\n";

		# link back to short case
	    if ($showwhichvotes != "bothdiff" and $voter2type == "party")
	        print "<p><a href=\"$this_anchor#divisions\">Show only the votes MP rebelled in.</a>";
	}


	# the friends tables
	if ($showwhichfriends != "none")
	{
	    print "<h2><a name=\"friends\">Possible Friends</a></h2>";
	    print "<p>Shows which MPs voted most similarly to this one. The
    		distance is measured from 0 (always voted the same) to 1 (always
		    voted differently).  Only votes that both MPs attended are
		    counted.  This may reveal relationships between MPs that were
		    previously unsuspected.  Or it may be nonsense.";

		# loop and make a table for each
		if ($showwhichfriends == "some")
		{
			foreach ($voter1attr['mpprops'] as $mpprop)
				print_possible_friends($db, $mpprop, $showwhichfriends);
		}

		# if it's a show all, then just do it of one sitting mp
		else
			print_possible_friends($db, $voter1attr['mpprop'], $showwhichfriends);
    }
?>

<?php
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
    $db->query(get_top_dream_query(8));
    $dreams = array();
    while ($row = $db->fetch_row_assoc()) { 
        $dreamid = $row['rollie_id'];
        $prettyrow = pretty_row_start($prettyrow);
        print_selected_dream($db, $voter1attr["mpprop"], $dreamid);
    }
    print "</table>\n";
?>


<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>

