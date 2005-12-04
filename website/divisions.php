<?php require_once "common.inc";
# $Id: divisions.php,v 1.21 2005/12/04 20:41:35 frabcus Exp $

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

	$rdefaultdisplay = ""; # I don't know how to grab the front
	foreach ($parliaments as $lrdisplay => $val)
	{
		$rdismodes[$lrdisplay] = array("dtype"	=> $lrdisplay,
								 "description" => "Divisions - ".$val['name']." Parliament",
								 "lkdescription" => $val['name']." Parliament",
								 "parliament" => $ldisplay,
								 "showwhich" => 'everyvote');
		if (!$rdefaultdisplay)
			$rdefaultdisplay = $lrdisplay;
	}

	$rdismodes["rebelall"] = array("dtype"	=> "rebelall",
							 "description" => "All Rebellions for all Parliaments since 1997",
							 "lkdescription" => "All Rebellions",
							 "parliament" => "all",
							 "showwhich" => "rebellions10");

	$rdismodes["every"] = array("dtype"	=> "every",
							 "description" => "All Divisions for all Parliaments since 1997",
							 "lkdescription" => "All Divisions",
							 "parliament" => "all",
							 "showwhich" => "everyvote");


	# find the display mode
	$rdisplay = $_GET["rdisplay"];
	if (!$rdismodes[$rdisplay])
	{
		$rdisplay = $_GET["parliament"]; # legacy
		if (!$rdismodes[$rdisplay])
			$rdisplay = $rdefaultdisplay;
	}
	$rdismode = $rdismodes[$rdisplay];

	# the sort field
    $sort = db_scrub($_GET["sort"]);
	if ($sort == "")
		$sort = "date";

	# do the title 
    $title = $rdismode['description'];
	if ($sort != 'date')
		$title .= " (sorted by $sort)";

	# do the tabbing list using a function that leaves out default parameters
	function makedivlink($rdisplay, $sort)
	{
		$base = "divisions.php";
		if ($rdisplay == $rdefaultdisplay)
		{
			if ($sort == "date")
				return $base;
			return "$base?sort=$sort";
		}
		if ($sort == "date")
			return "$base?rdisplay=$rdisplay";
		return "$base?rdisplay=$rdisplay&sort=$sort";
	}

    $second_links = array();
    foreach ($rdismodes as $lrdisplay => $lrdismode)
	{
		$dlink = makedivlink($lrdisplay, $sort);
        array_push($second_links, array('href'=>$dlink, 
            'current'=> ($lrdisplay == $rdisplay ? "on" : "off"),
            'text'=>$lrdismode["lkdescription"]));
	}
    pw_header();

	print "<p>A <i>division</i> is the House of Commons terminology for what would
		   normally be called a vote.  The word <i>vote</i> is reserved for the
		   individual choice of each MP within a division.  </p>";
	if ($sort != "rebellions" and $rdisplay != "rebelall")
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

	function makeheadcelldivlink($rdisplay, $sort, $hcelltitle, $hcellsort, $hcellalt)
	{
		$dlink = makedivlink($rdisplay, $hcellsort);
		if ($sort == $hcellsort)
			print "<td>$hcelltitle</td>";
		else
			print "<td><a href=\"$dlink\" alt=\"$hcellalt\">$hcelltitle</a></td>";
	}

	# these head cells are tabbing type links
    print "<table class=\"votes\">\n";
    print "<tr class=\"headings\">";
    makeheadcelldivlink($rdisplay, $sort, "Date", "date", "Sort by date");
    print "<td>No.</td>";
    makeheadcelldivlink($rdisplay, $sort, "Subject", "subject", "Sort by subject");
    makeheadcelldivlink($rdisplay, $sort, "Rebellions", "rebellions", "Sort by rebellions");
    makeheadcelldivlink($rdisplay, $sort, "Turnout", "turnout", "Sort by turnout");
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
