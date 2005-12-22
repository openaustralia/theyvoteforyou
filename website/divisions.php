<?php require_once "common.inc";
# $Id: divisions.php,v 1.23 2005/12/22 18:22:28 publicwhip Exp $

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

	$rdefaultdisplay = ""; # I don't know how to grab the front
	foreach ($parliaments as $lrdisplay => $val)
	{
		$rdismodes[$lrdisplay] = array(
								 "description" => $val['name']." Parliament",
								 "lkdescription" => $val['name']." Parliament",
								 "parliament" => $ldisplay);
		if (!$rdefaultdisplay)
			$rdefaultdisplay = $lrdisplay;
	}

	$rdismodes2["every"] = array(
							 "description" => "Divisions",
							 "lkdescription" => "All Divisions",
							 "showwhich" => "everyvote");
	$rdismodes2["rebels"] = array(
							 "description" => "Rebellions",
							 "lkdescription" => "Rebellions",
							 "showwhich" => "rebellions10");
    $rdefaultdisplay2 = "every";


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

	# the sort field
    $sort = db_scrub($_GET["sort"]);
	if ($sort == "")
		$sort = "date";

	# do the title 
    $title = $rdismode['description'];
	if ($sort != 'date')
		$title .= " (sorted by $sort)";

	# do the tabbing list using a function that leaves out default parameters
	function makedivlink($rdisplay, $sort, $rdisplay2)
	{
        global $rdefaultdisplay, $rdefaultdisplay2;
		$base = "divisions.php";
        $rest = "";
		if ($rdisplay != $rdefaultdisplay)
			$rest .= "&rdisplay=$rdisplay";
        if ($sort != "date")
			$rest .= "&sort=$sort";
		if ($rdisplay2 != $rdefaultdisplay2)
			$rest .= "&rdisplay2=$rdisplay2";

        if ($rest && $rest[0] == '&')
            $rest[0] = '?';
        return $base . $rest;
	}

    $second_links2 = array();
    foreach ($rdismodes as $lrdisplay => $lrdismode)
	{
		$dlink = makedivlink($lrdisplay, $sort, $rdisplay2);
        array_push($second_links2, array('href'=>$dlink, 
            'current'=> ($lrdisplay == $rdisplay ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}
    $second_links = array();
    foreach ($rdismodes2 as $lrdisplay => $lrdismode)
	{
		$dlink = makedivlink($rdisplay, $sor, $lrdisplay);
        array_push($second_links, array('href'=>$dlink, 
            'current'=> ($lrdisplay == $rdisplay2 ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}
    pw_header();

	print "<p>A <i>division</i> is the House of Commons terminology for what would
		   normally be called a vote.  The word <i>vote</i> is reserved for the
		   individual choice of each MP within a division.  </p>";
	if ($sort != "rebellions" and $rdisplay2 != "rebels")
		print "<p>Divisions with a high number of suspected rebellions
			   (votes different from the majority of the party)
			   are marked in red.  Often these are
			   not real rebellions against the party whip, because it's a
			   free vote.  However, there is no published information
			   which says when it is a free vote, we can't tell you which
			   they are, so have to use your judgement.
			   By convention, bipartisan matters concerning the running of
			   Parliament (such as setting the working hours), and matters
			   of moral conscience (eg the death penalty) are free votes.  </p>";

	if ($sort == "date")
		print "<p>You can change the order of the table by selecting
				the headings.</p>";

	function makeheadcelldivlink($rdisplay, $rdisplay2, $sort, $hcelltitle, $hcellsort, $hcellalt)
	{
		$dlink = makedivlink($rdisplay, $rdisplay2, $hcellsort);
		if ($sort == $hcellsort)
			print "<td>$hcelltitle</td>";
		else
			print "<td><a href=\"$dlink\" alt=\"$hcellalt\">$hcelltitle</a></td>";
	}

	# these head cells are tabbing type links
    print "<table class=\"votes\">\n";
    print "<tr class=\"headings\">";
    makeheadcelldivlink($rdisplay, $sort, $rdisplay2, "Date", "date", "Sort by date");
    makeheadcelldivlink($rdisplay, $sort, $rdisplay2, "House", "house", "Sort by house");
    print "<td>No.</td>";
    makeheadcelldivlink($rdisplay, $sort, $rdisplay2, "Subject", "subject", "Sort by subject");
    makeheadcelldivlink($rdisplay, $sort, $rdisplay2, "Rebellions", "rebellions", "Sort by rebellions");
    makeheadcelldivlink($rdisplay, $sort, $rdisplay2, "Turnout", "turnout", "Sort by turnout");
    print "</tr>";


	# would like to have the above heading put into the scheme
	$divtabattr = array(
			"showwhich"		=> $rdismode["showwhich"],
			"headings"		=> 'none',
			"sortby"		=> $sort);

	if ($rdismode["parliament"] != "all")
		$divtabattr["parldatelimit"] = $parliaments[$rdisplay];
	else
		$divtabattr["motionwikistate"] = "listunedited"; 

	division_table($db, $divtabattr);
    print "</table>\n";
?>

<?php pw_footer() ?>
