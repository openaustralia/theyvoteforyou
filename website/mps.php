<?php require_once "common.inc";
    # $Id: mps.php,v 1.39 2009/05/26 11:10:43 marklon Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $db = new DB();

    require_once "tablemake.inc";
    require_once "tablepeop.inc";
    require_once "parliaments.inc";

    $rdefaultdisplay_house = "commons";
	$rdefaultdisplay_parliament = 'now';

	$rdisplay_parliament = db_scrub($_GET["parliament"]);
	if (!$rdisplay_parliament)
		$rdisplay_parliament = $rdefaultdisplay_parliament;

	$rdisplay_house = strtolower(trim($_GET["house"]));
    if ($rdisplay_house!=='' && false===in_array($rdisplay_house,array('lords','commons','scotland','both','all'))) {
        pw_header();
        print '<h1>Invalid house entered</h1>';
        possiblexss('house = '.$rdisplay_house);
        pw_footer();
        exit();
    }
	if (!$rdisplay_house)
		$rdisplay_house = $rdefaultdisplay_house;

    $sort = strtolower(trim($_GET["sort"]));
    if (''===$sort) {
        $sort = 'lastname';
    }
    if (false===in_array($sort,array('lastname','rebellions','party','constituency','attendance'))) {
        pw_header();
        print '<h1>Invalid sort entered</h1>';
        possiblexss('sort = '.$sort);
        pw_footer();
        exit();
    }
	# constants
	$rdismodes = array();
	$rdismodes_house = array();

    $rdismodes['now'] = array(
							 "description" => "Show only current members",
							 "lkdescription" => "Current members",
							 "parliament" => 'now',
							 "titdescription" => "Current members");
    if ($rdisplay_house == 'commons') {
        foreach ($parliaments as $lrdisplay => $val)
        {
            $rdismodes[$lrdisplay] = array(
                                     "description" => $val['name']."&nbsp;Parliament",
                                     "lkdescription" => $val['name'],#." Parliament",
                                     "parliament" => $ldisplay,
                                     "titdescription" => $val['name']."&nbsp;Parliament");
        }
    }
	$rdismodes["all"] = array(     # still the first selector
							 "description" => "All members on record",
							 "lkdescription" => "All Parliaments",
							 "titdescription" => "All on record",
							 "parliament" => "all");


	# the alternative modes
	$rdismodes_house["commons"] = array(
							 "description" => "Show only MPs in the Commons",
							 "lkdescription" => "Commons",
							 "titdescription" => "MPs");
	$rdismodes_house["lords"] = array(
							 "description" => "Show only Lords in the House",
							 "lkdescription" => "Lords",
							 "titdescription" => "Lords");
	$rdismodes_house["scotland"] = array(
							 "description" => "Show only MSPs",
							 "lkdescription" => "Scottish Parliament",
							 "titdescription" => "MSPs");
	$rdismodes_house["all"] = array(
							 "description" => "Show all people",
							 "lkdescription" => "All houses",
							 "titdescription" => "MPs, MSPs and Lords");

    $title = "";
	if ($sort == "rebellions") {
		$title .= "Rebel ";
    }
	$title .= $rdismodes_house[$rdisplay_house]["titdescription"];
	$title .= " - ".$rdismodes[$rdisplay_parliament]["titdescription"];

    $colour_scheme = $rdisplay_house;

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
            'text'=>$lrdismode["lkdescription"],
            'tooltip'=>$lrdismode["description"]));
	}

	$second_links2 = array();
    foreach ($rdismodes_house as $lrdisplay_house => $lrdismode)
	{
		$dlink = makempslink($rdisplay_parliament, $lrdisplay_house, $sort);
        array_push($second_links2, array('href'=>$dlink,
            'current'=> ($lrdisplay_house == $rdisplay_house ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"],
            'tooltip'=>$lrdismode["description"]));
	}

    $second_type = "tabs";
    pw_header();

    print '<p>';
    if ($rdisplay_house == 'commons')
        print 'Members of the House of Commons (part of the UK Parliament) are listed below.';
    elseif ($rdisplay_house == 'lords')
        print 'Members of the House of Lords (part of the UK Parliament) are listed below.';
    else
        print 'Members of both Houses of the UK Parliament are listed below.';
    print ' Refer to <a href="faq.php#clarify">this explanation</a> of the
         "rebellion" and "attendance" rates, as they may not mean what you
         think they do. </p>
			';

	function makesortmpslink($rdisplay_parliament, $rdisplay_house, $sort, $hcelltitle, $hcellsort, $hcellalt)
	{
        static $donebar = 0;
		$dlink = makempslink($rdisplay_parliament, $rdisplay_house, $hcellsort);
        if ($donebar)
            print " | ";
        $donebar = 1;
		if ($sort == $hcellsort)
			print "<b>$hcelltitle</b>";
		else
			print "<a href=\"$dlink\" alt=\"$hcellalt\">$hcelltitle</a>";
	}
    print "<p style=\"font-size: 89%\" align=\"center\">Sort by: ";
    makesortmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Name", "lastname", "Sort by surname");
    if ($rdisplay_house != 'lords')
        makesortmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Constituency", "constituency", "Sort by constituency");
    makesortmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Party", "party", "Sort by party");
    if ($rdisplay_parliament == "all")
        makesortmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Dates", "date", "Sort by Date"); 
    makesortmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Rebellions", "rebellions", "Sort by rebels");
    #makesortmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Attendance", "attendance", "Sort by attendance");

    print "<table class=\"mps\">\n";


	# a function which generates any table of mps for printing,
	$mptabattr = array("listtype" 	=> "parliament",
					   "parliament" => $rdisplay_parliament,
					   "showwhich" 	=> "all",
					   "sortby"		=> $sort,
                       "house"      => $rdisplay_house, 
					   "headings"	=> "yes");
	if ($rdisplay_parliament == "now")
		$mptabattr["ministerial"] = "yes";
    $mptabattr["hitcounter"] = ($rdisplay_house == "z"); 

	mp_table($mptabattr);
    print "</table>\n";
pw_footer();
