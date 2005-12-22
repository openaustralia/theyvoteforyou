<?php require_once "common.inc";
# $Id: divisions.php,v 1.25 2005/12/22 19:55:14 goatchurch Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $db = new DB();
	$bdebug = 0;

	require_once "decodeids.inc";
	require_once "tablemake.inc";
    require_once "render.inc";

	# constants
	$rdismodes = array();
    $rdismodes2 = array();
	$rdismodes_house = array();

	$rdefaultdisplay = ""; # we grab the front entry from array
	foreach ($parliaments as $lrdisplay => $val)
	{
		$rdismodes[$lrdisplay] = array(
								 "description" => $val['name']." Parliament",
								 "lkdescription" => $val['name']." Parliament",
								 "parliament" => $ldisplay);
		if (!$rdefaultdisplay)
			$rdefaultdisplay = $lrdisplay;
	}
	$rdismodes["all"] = array(
							 "description" => "All divisions on record",
							 "lkdescription" => "All Parliaments",
							 "parliament" => "all");

	$rdismodes2["every"] = array(
							 "description" => "Divisions",
							 "lkdescription" => "All Divisions",
							 "showwhich" => "everyvote");
	$rdismodes2["rebels"] = array(
							 "description" => "Rebellions",
							 "lkdescription" => "Rebellions",
							 "showwhich" => "rebellions10");
    $rdefaultdisplay2 = "every";


	$rdismodes_house = array();
	$rdismodes_house["both"] = array(
							 "description" => "Show divisions of both Houses",
							 "lkdescription" => "Both Houses");
	$rdismodes_house["commons"] = array(
							 "description" => "Show only Commons divisions",
							 "lkdescription" => "Commons only");
	$rdismodes_house["lords"] = array(
							 "description" => "Show only Lords divisions",
							 "lkdescription" => "Lords only");
    $rdefaultdisplay_house = "both";

	# find the display mode
	$rdisplay = $_GET["rdisplay"];
	if (!$rdismodes[$rdisplay])
	{
		$rdisplay = $_GET["parliament"]; # legacy
		if (!$rdismodes[$rdisplay])
			$rdisplay = $rdefaultdisplay;
	}
	$rdisplay2 = $_GET["rdisplay2"];
    if (!$rdismodes2[$rdisplay2])
        $rdisplay2 = $rdefaultdisplay2;

	$rdismode = array_merge($rdismodes[$rdisplay], $rdismodes2[$rdisplay2]);
    $rdismode['description'] = $rdismodes2[$rdisplay2]['description'] . " - " . $rdismodes[$rdisplay]['description'];
    $rdismode['lkdescription'] = null;
	$rdismode['display_house'] = $rdisplay_house;

	$rdisplay_house = $_GET["house"];
	if (!$rdisplay_house)
		$rdisplay_house = $rdefaultdisplay_house;

	# the sort field
    $sort = db_scrub($_GET["sort"]);
	if ($sort == "")
		$sort = "date";

	# do the title
    $title = $rdismodes2[$rdisplay2]['description'] . " - " . $rdismodes[$rdisplay]['description'];
	if ($rdisplay_house != "both")
		$title .= " Just the ".($rdisplay_house == "lords" ? "Lords" : "Commons");
	if ($sort != 'date')
		$title .= " (sorted by $sort)";

	# do the tabbing list using a function that leaves out default parameters
	function makedivlink($rdisplay, $rdisplay2, $rdisplay_house, $sort)
	{
        global $rdefaultdisplay, $rdefaultdisplay2, $rdefaultdisplay_house;
		$base = "divisions.php";
        $rest = "";
		if ($rdisplay != $rdefaultdisplay)
			$rest .= "&rdisplay=$rdisplay";
        if ($sort != "date")
			$rest .= "&sort=$sort";
		if ($rdisplay2 != $rdefaultdisplay2)
			$rest .= "&rdisplay2=$rdisplay2";
		if ($rdisplay_house != $rdefaultdisplay_house)
			$rest .= "&house=$rdisplay_house";

        if ($rest && $rest[0] == '&')
            $rest[0] = '?';
        return $base . $rest;
	}

    $second_links2 = array();
    foreach ($rdismodes as $lrdisplay => $lrdismode)
	{
		$dlink = makedivlink($lrdisplay, $rdisplay2, $rdisplay_house, $sort);
        array_push($second_links2, array('href'=>$dlink,
            'current'=> ($lrdisplay == $rdisplay ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}
    $second_links = array();
    foreach ($rdismodes2 as $lrdisplay => $lrdismode)
	{
		$dlink = makedivlink($rdisplay, $lrdisplay, $rdisplay_house, $sort);
        array_push($second_links, array('href'=>$dlink,
            'current'=> ($lrdisplay == $rdisplay2 ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}
	$third_links = array();
    foreach ($rdismodes_house as $lrdisplay_house => $lrdismode)
	{
		$dlink = makedivlink($rdisplay, $lrdisplay, $lrdisplay_house, $sort);
        array_push($third_links, array('href'=>$dlink,
            'current'=> ($lrdisplay_house == $rdisplay_house ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}


    pw_header();

	print "<p>A <i>division</i> is the Parliamentary terminology for what would
		   normally be called a vote.  The word <i>vote</i> is reserved for the
		   individual choice of each MP within a division.  </p>";
	if ($sort != "rebellions" and $rdisplay2 != "rebels")
		print "<p>Divisions with a high number of suspected rebellions
			   (votes different from the majority of the party)
			   are marked in red.  Often these are
			   not real rebellions against the party whip because it's a
			   free vote and the party was divided.  
			   Unfortunately, there is no published information
			   to say when there was a free vote, so you will have to guess
			   them yourself.
			   By convention, bipartisan matters concerning the running of
			   Parliament (such as pay rises and the working conditions), and matters
			   of moral conscience (such as the death penalty) are free votes.  </p>

			   <p>For more information, please <a href=\"faq.php#freevotes\">
			   see the FAQ</a>.</p>";

	if ($sort == "date")
		print "<p>You can change the order of the table by selecting
				the headings.</p>";

	function makeheadcelldivlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, $hcelltitle, $hcellsort, $hcellalt)
	{
		$dlink = makedivlink($rdisplay, $rdisplay2, $rdisplay_house, $hcellsort);
		if ($sort == $hcellsort)
			print "<td>$hcelltitle</td>";
		else
			print "<td><a href=\"$dlink\" alt=\"$hcellalt\">$hcelltitle</a></td>";
	}

	# these head cells are tabbing type links
    print "<table class=\"votes\">\n";
    print "<tr class=\"headings\">";
    makeheadcelldivlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "Date", "date", "Sort by date");
	if ($rdisplay_house == "both")
	    makeheadcelldivlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "House", "house", "Sort by house");
    print "<td>No.</td>";
    makeheadcelldivlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "Subject", "subject", "Sort by subject");
    makeheadcelldivlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "Rebellions", "rebellions", "Sort by rebellions");
    makeheadcelldivlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "Turnout", "turnout", "Sort by turnout");
    print "</tr>";


	# would like to have the above heading put into the scheme
	$divtabattr = array(
			"showwhich"		=> $rdismode["showwhich"],
			"headings"		=> 'none',
			"sortby"		=> $sort
			"display_house" => $rdisplay_house);

	if ($rdismode["parliament"] != "all")
		$divtabattr["parldatelimit"] = $parliaments[$rdisplay];
	else
		$divtabattr["motionwikistate"] = "listunedited";

	division_table($db, $divtabattr);
    print "</table>\n";
?>

<?php pw_footer() ?>
