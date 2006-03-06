<?php require_once "common.inc";
    # $Id: mps.php,v 1.33 2006/03/06 17:30:54 publicwhip Exp $

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

    $rdefaultdisplay_house = "commons";
	$rdefaultdisplay_parliament = 'now';

	$rdisplay_parliament = db_scrub($_GET["parliament"]);
	if (!$rdisplay_parliament)
		$rdisplay_parliament = $rdefaultdisplay_parliament;

	$rdisplay_house = db_scrub($_GET["house"]);
	if (!$rdisplay_house)
		$rdisplay_house = $rdefaultdisplay_house;

    $sort = db_scrub($_GET["sort"]);
    if (!$sort)
        $sort = "lastname";


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
                                     "description" => $val['name']." Parliament",
                                     "lkdescription" => $val['name']." Parliament",
                                     "parliament" => $ldisplay,
                                     "titdescription" => $val['name']." Parliament");
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
							 "lkdescription" => "Commons only",
							 "titdescription" => "MPs");
	$rdismodes_house["lords"] = array(
							 "description" => "Show only Lords in the House",
							 "lkdescription" => "Lords only",
							 "titdescription" => "Lords");
	$rdismodes_house["both"] = array(
							 "description" => "Show all people in Parliament",
							 "lkdescription" => "Both houses",
							 "titdescription" => "MPs and Lords");

    $title = "";
	if ($sort == "rebellions")
		$title .= "Rebel ";
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
    makesortmpslink($rdisplay_parliament, $rdisplay_house, $sort, "Attendance", "attendance", "Sort by attendance");

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

	mp_table($db, $mptabattr);
    print "</table>\n";
?>

<?php pw_footer() ?>
