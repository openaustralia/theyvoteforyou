<?php require_once "common.inc";
# $Id: divisions.php,v 1.9 2005/02/25 07:51:51 goatchurch Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    include "cache-begin.inc";

    include "db.inc";
    $db = new DB();
	$bdebug = 0;

	include "decodeids.inc";
	include "tablemake.inc";

    $sort = db_scrub($_GET["sort"]);
	if ($sort == "")
		$sort = "date";

	# this indexes into the array $parliaments
	# should go into decodeids so can be a general purpose division rendering category
	$parliament = db_scrub($_GET["parliament"]);
	if ($parliament == "")
	    $parliament = "2001";  # prefer to be able to fetch first row from $parliaments

    $title = "Divisions - " . parliament_name($parliament) . " Parliament";
    include "header.inc";
?>


<p>A <i>division</i> is the House of Commons terminology for what would
normally be called a vote.  The word <i>vote</i> is reserved for the
individual choice of each MP within a division.  Divisions with a high
number of suspected rebellions are marked in red.  Sometimes these are
just divisions where the whips allowed free voting.  You can change
the order of the table by selecting the headings.

<?
    include "render.inc";

	# this stuff to be turned into a series of tabbing tyle links
    if ($parliament == "2001")
        print "<p><a href=\"divisions.php?parliament=1997&sort=" .  html_scrub($sort) . "\">View divisions for 1997-2001 parliament</a>";
    if ($parliament == "1997")
        print "<p><a href=\"divisions.php?parliament=2001&sort=" .  html_scrub($sort) . "\">View divisions for 2001-2005 parliament</a>";
    $url = "divisions.php?parliament=" . urlencode($parliament) . "&";

	# these head cells are tabbing type links
    print "<table class=\"votes\">\n";
    print "<tr class=\"headings\">";
    print "<td>No.</td>";
    head_cell($url, $sort, "Date", "date", "Sort by date");
    head_cell($url, $sort, "Subject", "subject", "Sort by subject");
    head_cell($url, $sort, "Rebellions", "rebellions", "Sort by rebellions");
    head_cell($url, $sort, "Turnout", "turnout", "Sort by turnout");
    print "</tr>";

	# would like to have the above heading put into the scheme
	division_table($db, "", "", "", "", "everyvote", "none", $sort, $parliaments[$parliament]);

    print "</table>\n";

?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc" ?>
