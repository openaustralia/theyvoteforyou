<?php 
# $Id: divisions.php,v 1.2 2003/10/02 09:42:03 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    $sort = mysql_escape_string($_GET["sort"]);
    $parliament = mysql_escape_string($_GET["parliament"]);

    include "parliaments.inc";
    if ($parliament == "")
        $parliament = this_parliament();

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
    include "db.inc";
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


    $db->query("$divisions_query_start and division_date <= '" .
    parliament_date_to($parliament) . "' and division_date >= '" .
    parliament_date_from($parliament) . "' order by $order"); 

    $url = "divisions.php?";
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
