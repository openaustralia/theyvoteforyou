<?  $title = "Counting votes on your behalf"; include "header.inc";
# $Id: index.php,v 1.9 2003/10/03 10:56:20 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<p>Every week, a dozen or so times, your MP votes in the UK parliament.  This
is the crucial, visible exercise of power.  The Public Whip presents and
data mines their voting record, to help you hold them to account.
For more information about the project, <a href="faq.php">read the FAQ</a>.

<?php
    include "db.inc";
    include "render.inc";
    $db = new DB(); 
?>

<table class="layout"><tr>

<td class="layout" bgcolor="#eeeeee">
<h2>Site News <a href="news.php">(more...)</a></h2>
<ul class="newsheadlines"><a href="news.php"><?php include "headlines.inc" ?></a></ul>
<?php include "newsdate.inc" ?>
</td>

<td class="layout" bgcolor="#dddddd">
<h2>Search <a href="search.php">(help...)</a></h2>
<p class="search">Enter your MP, constituency or debate topic:</p>
<form class="search" action="search.php" name=pw>
<input maxLength=256 size=25 name=query value=""> <input type=submit value="Search" name=button>
</form></p>
<?php search_example($db); ?>
</td>

<td class="layout" bgcolor="#eeeeee">
<h2>Vote Map <a href="mpsee.php">(find Blair...)</a></h2>
<p><a href="mpsee.php">
<img src="mpseethumb.png"></a>
<!--<br><a href="mpsee.php">Where is Blair on this map?  </a>-->
</td>


</td></tr></table>

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
               <td>$row[5] rebels</td>";
        print "</tr>\n";
    }
    print "</table>\n";

?>


<h2>Top Rebels <a href="mps.php?sort=rebellions" title="Show all MPs ordered by rebellions">(more...)</a></h2>
<table class="mps">
<?php
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
            urlencode($row[3]) . "\">$row[2]
            $row[0] $row[1]</a></td> <td>$row[3]</td>
            <td>" . pretty_party($row[4], $row[8], $row[9]) . "</td><td class=\"percent\">$row[6]% rebel</td>";
        print "</tr>\n";
    }
?>
</table>

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
            urlencode($row[3]) . "\">$row[2]
            $row[0] $row[1]</a></td> <td>$row[3]</td>
            <td>" . pretty_party($row[4], $row[8], $row[9]) . "</td><td class=\"percent\">$row[7]% attendance</td>";
        print "</tr>\n";
    }
    print "</table>\n";
?>

<?php include "footer.inc" ?>
