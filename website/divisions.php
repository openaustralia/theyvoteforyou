<?php include "cache-begin.inc"; ?>
<?php 
# $Id: divisions.php,v 1.6 2003/10/14 22:39:06 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";

    $sort = db_scrub($_GET["sort"]);

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
    $db = new DB(); 

    if ($sort == "")
    {
        $sort = "date";
    }
    if ($sort == "date")
    {
        $order = "division_date desc, division_number desc";
    }
    elseif ($sort == "subject")
    {
        $order = "division_name, division_date desc, division_number desc";
    }
    elseif ($sort == "rebellions")
    {
        $order = "rebellions desc, division_date desc, division_number desc";
    }
    elseif ($sort == "turnout")
    {
        $order = "turnout desc, division_date desc, division_number desc";
    }

    if ($parliament == "2001")
        print "<p><a href=\"divisions.php?parliament=1997&sort=" .  html_scrub($sort) . "\">View divisions for 1997 parliament</a>";
    if ($parliament == "1997")
        print "<p><a href=\"divisions.php?parliament=2001&sort=" .  html_scrub($sort) . "\">View divisions for 2001 parliament</a>";
 
    $db->query("$divisions_query_start and division_date <= '" .
        parliament_date_to($parliament) . "' and division_date >= '" .
        parliament_date_from($parliament) . "' order by $order"); 

    $url = "divisions.php?parliament=" . urlencode($parliament) . "&";
    print "<table class=\"votes\">\n";
    print "<tr class=\"headings\">";
    print "<td>No.</td>";
    head_cell($url, $sort, "Date", "date", "Sort by date");
    head_cell($url, $sort, "Subject", "subject", "Sort by subject");
    head_cell($url, $sort, "Rebellions", "rebellions", "Sort by rebellions");
    head_cell($url, $sort, "Turnout", "turnout", "Sort by turnout");
    print "</tr>";
    render_divisions_table($db);
    print "</table>\n";

?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc" ?>
