<?php 
    # $Id: mps.php,v 1.2 2003/10/02 09:42:03 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    $sort = mysql_escape_string($_GET["sort"]);
    if ($sort != "rebellions")
        $title = "MPs"; 
    else
        $title = "Rebels";
    
    $parliament = mysql_escape_string($_GET["parliament"]);

    include "parliaments.inc";
    if ($parliament == "")
        $parliament = this_parliament();

    $title .= " - " . parliament_name($parliament) . " Parliament";

    include "header.inc";
    include "db.inc";
    include "render.inc";
    $db = new DB(); 

    if ($sort == "")
    {
        $sort = "lastname";
    }
    if ($sort == "lastname")
    {
        $order = "last_name, first_name, constituency, party";
    }
    elseif ($sort == "firstname")
    {
        $order = "first_name, last_name, constituency, party";
    }
    elseif ($sort == "title")
    {
        $order = "title, last_name, first_name, constituency, party";
    }
    elseif ($sort == "constituency")
    {
        $order = "constituency, last_name, first_name, party";
    }
    elseif ($sort == "party")
    {
        $order = "party, last_name, first_name, constituency";
    }
    elseif ($sort == "rebellions")
    {
        $order = "round(rebellions/votes_attended,10) desc, last_name, first_name";
    }
    elseif ($sort == "attendance")
    {
        $order = "round(votes_attended/votes_possible,10) desc, last_name, first_name";
    }
    $db->query("$mps_query_start and entered_house <= '" .
        parliament_date_to($parliament) . "' and entered_house >= '".
        parliament_date_from($parliament) . "' order by $order");

    if ($sort == "rebellions")
    {
?>
<p>A rebellion is a suspected vote against the MP's party whip.  
Unfortunately, Public Whip can only guess the party whip.  It assumes
that the most common vote (aye or noe) for that party in that division
was the party whip.  That is, the whip is the modal vote.  This heuristic will
break down with a severe rebellion.
<?php
    }
    else
    {
?>
<p>The Members of Parliament are listed with how often they turn up to
vote, and a guess at the number of times they have gone against their
party whip.  You can change the order of the table by selecting the
headings.
<?php
    }
    print "<table class=\"mps\"><tr class=\"headings\">\n";

    $url = "mps.php?";
    print "<tr class=\"headings\">";
    head_cell($url, $sort, "Name", "lastname", "Sort by surname");
    head_cell($url, $sort, "Constituency", "constituency", "Sort by constituency");
    head_cell($url, $sort, "Party", "party", "Sort by party");
    head_cell($url, $sort, "Rebellions", "rebellions", "Sort by rebels");
    head_cell($url, $sort, "Attendance", "attendance", "Sort by attendance");
    print "</tr>";

    render_mps_table($db);
    print "</table>\n";

?>

<?php include "footer.inc" ?>
