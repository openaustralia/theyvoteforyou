<?php require_once "common.inc";
    # $Id: mps.php,v 1.24 2006/01/05 16:29:55 goatchurch Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $db = new DB();

    require_once "tablemake.inc";
    require_once "tablepeop.inc";
    require_once "render.inc";
    require_once "parliaments.inc";

	# constants
	$rdismodes = array();
	$rdismodes_house = array();

	$rdefault_parliament = 'now';
	$rdismodes['now'] = array(
							 "description" => "Show only current members",
							 "lkdescription" => "Currently sitting",
							 "parliament" => 'now');
	foreach ($parliaments as $lrdisplay => $val)
	{
		$rdismodes[$lrdisplay] = array(
								 "description" => $val['name']." Parliament",
								 "lkdescription" => $val['name']." Parliament",
								 "parliament" => $ldisplay);
	}
	$rdismodes["all"] = array(     # still the first selector
							 "description" => "All members on record",
							 "lkdescription" => "All Parliaments",
							 "parliament" => "all");


	# the alternative modes
	$rdismodes_house["commons"] = array(
							 "description" => "Show only MPs in the Commons",
							 "lkdescription" => "Commons only");
	$rdismodes_house["lords"] = array(
							 "description" => "Show only Lords in the House",
							 "lkdescription" => "Lords only");
	$rdismodes_house["both"] = array(
							 "description" => "Show all people in Parliament",
							 "lkdescription" => "Both Houses");
    $rdefaultdisplay_house = "commons";


	$rdisplay_parliament = db_scrub($_GET["parliament"]);
	if (!$rdisplay_parliament)
		$rdisplay_parliament = $rdefaultdisplay_parliament;

	$rdisplay_house = db_scrub($_GET["house"]);
	if (!$rdisplay_house)
		$rdisplay_house = $rdefaultdisplay_house;

    $sort = db_scrub($_GET["sort"]);
    if (!$sort)
        $sort = "lastname"; 

    $title = ($sort == "rebellions" ? "Rebel " : "").($rdisplay_house == "lords" ? "Lords" : "MPs").
				" - ".parliament_name($parliament)." Parliament";

	# do the tabbing list using a function that leaves out default parameters
	function makempslink($rdisplay_parliament, $rdisplay_house, $sort)
	{
        global $rdefaultdisplay_parliament, $rdefaultdisplay_house;
		$base = "mps.php";
        $rest = "";
		if ($rdisplay_parliament != $rdefaultdisplay_parliament)
			$rest .= "&parliament=$rdisplay_parliament";
		if ($rdisplay_house != $rdefaultdisplay_house)
			$rest .= "&house=$rdisplay_house";
        if ($sort)
			$rest .= "&sort=$sort";

        if ($rest && $rest[0] == '&')
            $rest[0] = '?';
        return $base . $rest;
	}


    $second_links = array();
    foreach ($rdismodes as $lrdisplay => $lrdismode)
	{
		$dlink = makempslink($lrdisplay, $rdisplay_house, $sort);
        array_push($second_links, array('href'=>$dlink,
            'current'=> ($lrdisplay == $rdisplay_parliament ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}

	$second_links2 = array();
    foreach ($rdismodes_house as $lrdisplay_house => $lrdismode)
	{
		$dlink = makempslink($rdisplay_parliament, $lrdisplay_house, $sort);
        array_push($second_links2, array('href'=>$dlink,
            'current'=> ($lrdisplay_house == $rdisplay_house ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}

    pw_header();

	print '<p>The Members of Parliament are listed with the number of times they
			voted against the majority vote for their party and how often they turn up
			to vote.  Read a <a href="faq.php#clarify">clear
			explanation</a> of these terms, as they may not have the meanings
			you expect. You can change the order of the table by selecting the headings.
		  ';

	function makeheadcellmpslink($rdisplay_parliament, $rdisplay_house, $sort, $hcelltitle, $hcellsort, $hcellalt)
	{
		$dlink = makempslink($rdisplay_parliament, $rdisplay_house, $hcellsort);
		if ($sort == $hcellsort)
			print "<td>$hcelltitle</td>";
		else
			print "<td><a href=\"$dlink\" alt=\"$hcellalt\">$hcelltitle</a></td>";
	}


    print "<table class=\"mps\">\n";

    $url = "mps.php?parliament=" . urlencode($parliament) . "&";
    print "<tr class=\"headings\">";
    makeheadcellmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Name", "lastname", "Sort by surname");
    if ($rdisplay_house != 'lords')
        makeheadcellmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Constituency", "constituency", "Sort by constituency");
    makeheadcellmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Party", "party", "Sort by party");
    makeheadcellmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Rebellions<br>(estimate)", "rebellions", "Sort by rebels");
    makeheadcellmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Attendance<br>(divisions)", "attendance", "Sort by attendance");
    print "</tr>";


	# a function which generates any table of mps for printing,
	$mptabattr = array("listtype" 	=> "parliament",
					   "parliament" => $parliament,
					   "showwhich" 	=> "all",
					   "sortby"		=> $sort,
                       "house"      => $rdisplay_house);
	mp_table($db, $mptabattr);
    print "</table>\n";
?>

<?php pw_footer() ?>
