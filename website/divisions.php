<?php $title = "Divisions"; include "header.inc" 
# $Id: divisions.php,v 1.1 2003/08/14 19:35:48 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<p>A <i>division</i> is the House of Commons terminology for what would
normally be called a vote.  The word <i>vote</i> is reserved for the
individual choice of each MP within a division.  Divisions with a high
number of suspected rebellions are marked in red.  Sometimes these are
just divisions where the whips allowed free voting.  You can change
the order of the table by selecting the headings.

<?php
    $sort = mysql_escape_string($_GET["sort"]);

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


    $db->query("$divisions_query_start order by $order"); 

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
