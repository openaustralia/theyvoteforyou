<?php 
    # $Id: mps.php,v 1.5 2003/10/13 17:45:59 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "header.inc";
    include "db.inc";
    include "render.inc";
    $db = new DB(); 

    $sort = db_scrub($_GET["sort"]);
    if ($sort != "rebellions")
        $title = "MPs"; 
    else
        $title = "Rebels";
    
    include "parliaments.inc";
    $title .= " - " . parliament_name($parliament) . " Parliament";

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
<p>The Members of Parliament are listed with how often they turn up to
vote, and a guess at the number of times they have gone against their
party whip.  They are sorted so that the most rebellious appear first.
You can change the order of the table by selecting the headings.
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
    if ($parliament == "2001")
        print "<p><a href=\"mps.php?parliament=1997&sort=" . html_scrub($sort) . "\">View MPs for 1997 parliament</a>";
    if ($parliament == "1997")
        print "<p><a href=\"mps.php?parliament=2001&sort=" .  html_scrub($sort) . "\">View MPs for 2001 parliament</a>";
    
    print "<table class=\"mps\"><tr class=\"headings\">\n";

    $url = "mps.php?parliament=" . urlencode($parliament) . "&";
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
