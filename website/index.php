<?php $cache_postfix = rand(0, 10); include "cache-begin.inc"; ?>

<?  $title = "Counting votes on your behalf"; $onload = "givefocus()"; include "header.inc";
# $Id: index.php,v 1.24 2004/02/11 00:07:47 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<p>Every week, a dozen or so times, your MP votes in the UK parliament.  This
is their crucial, visible exercise of power.  The Public Whip 
data-mines their voting record to help you hold them to account.
For more information about the project, <a href="faq.php">read the FAQ</a>.

<?php
    include "db.inc";
    include "render.inc";
    include "parliaments.inc";
    $db = new DB(); 
?>

<table class="layout"><tr>

<td width="20%" class="layout" bgcolor="#eeeeee">
<h2>Newsletter</h2>
<p>Keep up with the Public Whip project.
An at most monthly briefing.  
<p><a href="account/register.php">Sign up now!</a>
</td>

<td class="layout" bgcolor="#dddddd">
<h2>Search <a href="search.php">(help...)</a></h2>
<p class="search">
Enter your postcode, MP name or a topic:
</p>
<form class="search" action="search.php" name=pw>
<input maxLength=256 size=25 name=query value=""> <input type=submit value="Search" name=button>
</form></p>
<?php search_example($db, false); ?>
</td>

<td class="layout" bgcolor="#eeeeee">
<h2>Vote Map <a href="mpsee.php">(find Blair...)</a></h2>
<p><a href="mpsee.php">
<img src="votemap/mpseethumb.png"></a>
</td>


</td></tr></table>

<table class="layout"><tr><td>

<h2>Top Rebels <a href="mps.php?sort=rebellions" title="Show all MPs ordered by rebellions">(more...)</a></h2>
<table class="mps">
<?php
    $db->query("$mps_query_start and " . parliament_query_range($parliament) . "
        order by round(rebellions/votes_attended,10) desc, last_name,
        first_name, constituency, party limit 3");

    $c = 0;
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $c++;
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$c</td><td><a href=\"mp.php?firstname=" . urlencode($row[0]) .
            "&lastname=" . urlencode($row[1]) . "&constituency=" .
            urlencode($row[3]) . "\">$row[2]
            $row[0] $row[1]</a></td> <td>$row[3]</td>
            <td>" . pretty_party($row[4], $row[8], $row[9]) . "</td>";
        print "<td class=\"percent\">$row[6]% rebel (" .  year_range($row[10], $row[11]) . ")</td>";
        print "</tr>\n";
    }
?>
</table>

</td><td>

<h2>Best Attendance <a href="mps.php?sort=attendance" title="Show all MPs ordered by attendance">(more...)</a></h2>
<table class="mps">
<?
    $db->query("$mps_query_start and " . parliament_query_range($parliament) . "
        order by round(votes_attended/votes_possible,10) desc, last_name,
        first_name, constituency, party limit 3");

    $c = 0;
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $c++;
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$c</td><td><a href=\"mp.php?firstname=" . urlencode($row[0]) .
            "&lastname=" . urlencode($row[1]) . "&constituency=" .
            urlencode($row[3]) . "\">$row[2]
            $row[0] $row[1]</a></td> <td>$row[3]</td>
            <td>" . pretty_party($row[4], $row[8], $row[9]) . "</td>";
        print "<td class=\"percent\">$row[7]% attendance (" .  year_range($row[10], $row[11]) . ")</td>";
        print "</tr>\n";
    }
    print "</table>\n";
?>

</td></tr><td colspan=2>

<h2>Interesting Divisions <a href="divisions.php?sort=rebellions"
title="Show all divisions ordered by number of rebellions">(more...)</a></h2>
<p>Selected at random from divisions with more than 10 rebellions.

<?php
    $db->query("$divisions_query_start and " . parliament_query_range_div($parliament) . "
        and rebellions > 10 and
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
               <td>$row[5] rebels</td>";
        print "</tr>\n";
    }
    print "</table>\n";

?>

</td></tr></table>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
