<?  $title = "Counting votes on your behalf"; include "header.inc";
# $Id: index.php,v 1.3 2003/09/17 15:11:53 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<!-- How does your MP vote? -->
<p>Mining data on the voting records of Members of the United Kingdom
Parliament.

<table class="layout"><tr>

<td class="layout"><table class="layout">

<tr><td class="layout">
<h2>Top Rebels <a href="mps.php?sort=rebellions" title="Show all MPs ordered by rebellions">(more...)</a></h2>
<table class="mps">
<?php
    include "db.inc";
    include "render.inc";
    $db = new DB(); 

    $db->query("$mps_query_start order by round(rebellions/votes_attended,10) desc, last_name,
        first_name, constituency, party limit 5");

    $c = 0;
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $c++;
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$c</td><td><a href=\"mp.php?firstname=" . urlencode($row[0]) .
            "&lastname=" . urlencode($row[1]) . "&constituency=" .
            urlencode($row[3]) . "\"mp.php?mpid=$row[5]\">$row[2]
            $row[0] $row[1]</a></td> <td>$row[3]</td>
            <td>" . pretty_party($row[4]) . "</td><td class=\"percent\">$row[6]% rebel</td>";
        print "</tr>\n";
    }
?>
</table>
</td></tr>

<tr><td class="layout">
<h2>Best Attendance <a href="mps.php?sort=attendance" title="Show all MPs ordered by attendance">(more...)</a></h2>
<table class="mps">
<?
    $db->query("$mps_query_start order by round(votes_attended/votes_possible,10) desc, last_name,
        first_name, constituency, party limit 5");

    $c = 0;
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $c++;
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$c</td><td><a href=\"mp.php?firstname=" . urlencode($row[0]) .
            "&lastname=" . urlencode($row[1]) . "&constituency=" .
            urlencode($row[3]) . "\"mp.php?mpid=$row[5]\">$row[2]
            $row[0] $row[1]</a></td> <td>$row[3]</td>
            <td>" . pretty_party($row[4]) . "</td><td class=\"percent\">$row[7]% attendance</td>";
        print "</tr>\n";
    }
    print "</table>\n";
?>
</td></tr><tr><td class="layout">

<h2>Interesting Divisions <a href="divisions.php?sort=rebellions"
title="Show all divisions ordered by number of rebellions">(more...)</a></h2>
<p>Selected at random from divisions with more than 10 rebellions.

<?php
    $db->query("$divisions_query_start and rebellions > 10 and
        pw_division.division_id = pw_cache_divinfo.division_id order by
        rand() limit 5"); 

    print "<table class=\"votes\">\n";
    print "<tr class=\"headings\">\n";
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$row[2]</td> 
               <td><a href=\"division.php?date=" . urlencode($row[2]) . "&number=" . urlencode($row[1]) . "\">$row[3]</a></td> 
               <td>$row[5] rebellions</td>";
        print "</tr>\n";
    }
    print "</table>\n";

?>

</td></tr></table>
</td>
<td class="layout">
<h2>MP Voting Map</h2>
<p><a href="cluster.php">
<img src="mpseethumb.png">
<br>Where is Blair on this map?
</a>
</td></tr>

</table>

<?php include "footer.inc" ?>
