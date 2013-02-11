<?php require_once "common.inc";
# $Id: divisions.php,v 1.43 2009/05/19 14:47:21 marklon Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";

	$bdebug = 0;

	require_once "decodeids.inc";
	require_once "tablemake.inc";

	# constants
	$rdismodes = array();  # this refers to the parliament (time range)
	$rdismodes_house = array();  # this controls the house (second type)
    $rdismodes2 = array(); # this has everyvote or rebel, or parties if we are within one house

	$rdefaultdisplay = ""; # we grab the front entry from array
	foreach ($parliaments as $lrdisplay => $val)
	{
		$rdismodes[$lrdisplay] = array(
								 "description" => $val['name'],
								 "lkdescription" => $val['name'],
								 "parliament" => $lrdisplay);
		if (!$rdefaultdisplay)
			$rdefaultdisplay = $lrdisplay;
	}
	$rdismodes["all"] = array(     # still the first selector
							 "description" => "All divisions on record",
							 "lkdescription" => "All Parliaments",
							 "parliament" => "all");


    
    # move onto the secont selector
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
	$rdismodes_house["all"] = array(
							 "description" => "Show divisions from the Commons, Lords and Scottish Parliament",
							 "lkdescription" => "All houses");
	$rdismodes_house["commons"] = array(
							 "description" => "Show only Commons divisions",
							 "lkdescription" => "Commons only");
	$rdismodes_house["lords"] = array(
							 "description" => "Show only Lords divisions",
							 "lkdescription" => "Lords only");
	$rdismodes_house["scotland"] = array(
							 "description" => "Show only Scottish Parliament divisions",
							 "lkdescription" => "Scottish Parliament only");
    $rdefaultdisplay_house = "all";


	# find the display mode
	$rdisplay = db_scrub($_GET["rdisplay"]);
	if (!$rdismodes[$rdisplay])
	{
		$rdisplay = db_scrub($_GET["parliament"]); # legacy
		if (!$rdismodes[$rdisplay])
			$rdisplay = $rdefaultdisplay;
	}
	$rdisplay_house = db_scrub($_GET["house"]);
	if (!$rdisplay_house)
		$rdisplay_house = $rdefaultdisplay_house;

	# now try to construct all the parties present in a house that we could see the whip of
	if ($rdisplay_house != "all")
	{
        $qselect = "SELECT party";
		$qfrom .= " FROM pw_cache_whip";
		$qjoin .= " LEFT JOIN pw_division
						ON pw_division.division_id = pw_cache_whip.division_id";
		$qwhere .= " WHERE house = :house";
		if ($rdisplay != "all")
			$qwhere .= " AND division_date >= :fromdate AND division_date < :todate";
		$qgroup = " GROUP BY party";
		$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup;
        $placeholders=array(
            ':house'=>  $rdisplay_house,
            ':fromdate'=>$parliaments[$rdisplay]["from"],
            ':todate'=>$parliaments[$rdisplay]["to"]
        );
		$pwpdo->query($query,$placeholders);
		while ($row = $pwpdo->fetch_row())
		{
			$party = $row["party"];
            if ($party != "CWM" && $party != "DCWM" && substr($party, 0, 3) != "Ind" && $party != "Other" && $party != "None" && $party != "SPK")
			    $rdismodes2["${party}_party"] = array(
									 "description" => pretty_party_long($party, $rdisplay_house),
									 "lkdescription" => pretty_party_long($party, ""),
									 "showwhich" => "party",
									 "party" => $party);
		}
        #print_r($rdismodes2);
	}

	# now get this display of this subtype
	$rdisplay2 = db_scrub($_GET["rdisplay2"]);
    if (!$rdismodes2[$rdisplay2])
        $rdisplay2 = $rdefaultdisplay2;

	$rdismode = array_merge($rdismodes[$rdisplay], $rdismodes2[$rdisplay2]);
    $rdismode['description'] = $rdismodes2[$rdisplay2]['description'] . " - " . $rdismodes[$rdisplay]['description'];
    $rdismode['lkdescription'] = null;
	$rdismode['display_house'] = $rdisplay_house;


	# the sort field
    $sort = db_scrub($_GET["sort"]);
	if ($sort == "")
		$sort = "date";

	# do the title
    $title = $rdismodes2[$rdisplay2]['description'] . " - " . $rdismodes[$rdisplay]['description'];
	if ($rdisplay_house != "all")
    {
		if (($rdisplay2 == "every") || ($rdisplay2 == "rebels")) {
            if ($rdisplay_house == "scotland")
                $house_name = "Scottish Parliament";
            else if ($rdisplay_house == "lords")
                $house_name = "Lords";
            else
                $house_name = "Commons";
            $title .= " - " . $house_name . " only";
        }
        $colour_scheme = $rdisplay_house;
    }
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
		if ($rdisplay2 != $rdefaultdisplay2)
			$rest .= "&rdisplay2=$rdisplay2";
		if ($rdisplay_house != $rdefaultdisplay_house)
			$rest .= "&house=$rdisplay_house";
        if ($sort != "date")
			$rest .= "&sort=$sort";

        if ($rest && $rest[0] == '&')
            $rest[0] = '?';
        return $base . $rest;
	}

    $second_links3 = array();
    foreach ($rdismodes2 as $lrdisplay => $lrdismode)
	{
		$dlink = makedivlink($rdisplay, $lrdisplay, $rdisplay_house, $sort);
        array_push($second_links3, array('href'=>$dlink,
            'current'=> ($lrdisplay == $rdisplay2 ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}
    $second_links = array();
    foreach ($rdismodes as $lrdisplay => $lrdismode)
	{
		$dlink = makedivlink($lrdisplay, $rdisplay2, $rdisplay_house, $sort);
        array_push($second_links, array('href'=>$dlink,
            'current'=> ($lrdisplay == $rdisplay ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}
	$second_links2 = array();
    foreach ($rdismodes_house as $lrdisplay_house => $lrdismode)
	{
		$dlink = makedivlink($rdisplay, $rdisplay2, $lrdisplay_house, $sort);
        array_push($second_links2, array('href'=>$dlink,
            'current'=> ($lrdisplay_house == $rdisplay_house ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}


    pw_header();

	print "<p>A 'division' is parliamentary terminology for a 'vote' (<a href=\"/faq.php#jargon\">read more...</a>).
         This page shows divisions in the UK parliament. Make sure you <a href=\"/faq.php#clarify\">read the
         explanation</a> about rebellions, as they may not be what you expect.
		 </p>";

    if ($rdisplay2 == "rebels")
        print "<p>This is a table showing only the divisions where there were at least ten <a href=\"faq.php#clarify\">rebels</a>.</p>";

	function makesortlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, $hcelltitle, $hcellsort, $hcellalt)
	{
        static $donebar = 0;
		$dlink = makedivlink($rdisplay, $rdisplay2, $rdisplay_house, $hcellsort);
        if ($donebar)
            print " | ";
        $donebar = 1;
		if ($sort == $hcellsort)
			print "<b>$hcelltitle</b>";
		else
			print "<a href=\"$dlink\" alt=\"$hcellalt\">$hcelltitle</a>";
	}
    print "<p style=\"font-size: 89%\" align=\"center\">Sort by: ";
    makesortlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "Date", "date", "Sort by date");
    makesortlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "Subject", "subject", "Sort by subject");
    makesortlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "Rebellions", "rebellions", "Sort by rebellions");
    makesortlink($rdisplay, $rdisplay2, $rdisplay_house, $sort, "Turnout", "turnout", "Sort by turnout");

	# these head cells are tabbing type links (not any more)
    print "<table class=\"votes\">\n";

	# would like to have the above heading put into the scheme
	$divtabattr = array(
			"showwhich"		=> $rdismode["showwhich"],
			"headings"		=> 'columns',
			"sortby"		=> $sort,
			"display_house" => $rdisplay_house);

	if ($rdismode["showwhich"] == "party")
        $divtabattr["party"] = $rdismode["party"]; 
    
    if ($rdismode["parliament"] != "all")
		$divtabattr["parldatelimit"] = $parliaments[$rdismode["parliament"]];
	else
		$divtabattr["motionwikistate"] = "listunedited";  # this extra bit of information only shows up for advanced users who are looking at all parliaments
    $divtabattr["hitcounter"] = ($rdisplay_house == "z");  

	division_table($db, $divtabattr);
    print "</table>\n";

 pw_footer();
