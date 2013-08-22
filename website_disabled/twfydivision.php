<?php 
# $Id: twfydivision.php,v 1.1 2010/06/10 09:29:56 publicwhip Exp $
# vim:sw=4:ts=4:et:nowrap

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "common.inc";
require_once "db.inc";
require_once "decodeids.inc";

$db = new DB();

header("Content-type: text/html");

$divattr = get_division_attr_decode( "");

//print "<h1>Hi there</h1>";
$div_id = $divattr["division_id"];
$house = $divattr["house"];
$aye_majority = $divattr["aye_majority"];

$query = "SELECT party, aye_votes, aye_tells, no_votes, no_tells, both_votes, possible_votes, whip_guess
          FROM pw_cache_whip
          WHERE division_id = $div_id
          ORDER BY party";
$db->query($query);

$noesfirst = ($aye_majority < 0);

print "<table border=\"1\">\n";
print "<tr class=\"headings\"><td>Party</td>";
if ($aye_majority == 0)
    print ($house == "lords" ? "<td>Contents</td><td>Not-Contents</td>":"<td>Ayes</td><td>Noes</td>");
else if ($noesfirst)
    print ($house == "lords" ? "<td>Majority (Not-Content)</td><td>Minority (Content)</td>":"<td>Majority (No)</td><td>Minority (Aye)</td>");
else
    print ($house == "lords" ? "<td>Majority (Content)</td><td>Minority (Not-Content)</td>":"<td>Majority (Aye)</td><td>Minority (No)</td>");
if ($house != "lords")
    print "<td>Both</td>";
print "<td>Turnout</td>";

$totalayes = 0;
$totalnoes = 0;
$totalboths = 0;
$totalturnout = 0;
$totalpossible = 0;
while ($row = $db->fetch_row_assoc())
{
    $party = $row["party"];
    $aye = $row["aye_votes"];
    $tellaye = $row["aye_tells"];
    $no = $row["no_votes"];
    $tellno = $row["no_tells"];
    $both = $row["both_votes"];
    $possible = $row["possible_votes"];

    $total = $aye + $no + $both + $tellaye + $tellno;
    if (($total == 0) && ($party != "Con" && $party != "Lab" && $party != "LDem"))
        continue;

    $totalayes += $aye;
    $totaltellayes += $tellaye;
    $totalnoes += $no;
    $totaltellnoes += $tellno;
    $totalboths += $both;
    $totalturnout += $total;
    $totalpossible += $possible;

    $whip = $row["whip_guess"];
    $classaye = ($aye + $tellaye > 0 ? ($whip == "no" ? "rebel" : "whip") : "normal");
    $classno = ($no + $tellno > 0 ? ($whip == "aye" ? "rebel" : "whip") : "normal");
    $classboth = ($both > 0 ? "important" : "normal");

    if ($tellaye > 0)
        $aye .= " (+" . $tellaye . " tell)";
    if ($tellno > 0)
        $no .= " (+" . $tellno . " tell)";

    print "<tr>";
    print "<td>$party</td>";
    if ($noesfirst)
        print "<td class=\"$classno\">$no</td> <td class=\"$classaye\">$aye</td>";
    else
        print "<td class=\"$classaye\">$aye</td> <td class=\"$classno\">$no</td>";

    if ($house != "lords")
        print "<td class=\"$classboth\">$both</td>";

    print "<td class=\"percent\">".(int)($total * 100.0 / ($possible != 0 ? $possible : 1)+ 0.5)."%</td>";
    print "</tr>\n";
}

print "<td>" . "Total:" . "</td>";
if ($noesfirst)
    print "<td class=\"$classnoes\">$totalnoes</td> <td class=\"$classayes\">$totalayes</td>";
else
    print "<td class=\"$classayes\">$totalayes</td> <td class=\"$classnoes\">$totalnoes</td>";

if ($house != "lords")
    print "<td class=\"$classboth\">$both</td>";
print "<td class=\"percent\">".(int)($totalturnout * 100.0 / ($totalpossible != 0 ? $totalpossible : 1)+ 0.5)."</td>";
print "</tr>\n";


print "</table>\n";



//print_r($divattr);

?>
