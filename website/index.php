<?php require_once "common.inc";

$cache_params = rand(0, 10); include "cache-begin.inc";

# $Id: index.php,v 1.40 2005/03/05 11:57:48 goatchurch Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$title = "Counting votes on your behalf"; $onload = "givefocus()"; include "header.inc";
?>

<p>Every week, a dozen or so times, your MP votes in the UK parliament.  This
is their crucial, visible exercise of power.  The Public Whip
data-mines their voting record to help you hold them to account.
For more information about the project, <a href="faq.php">read the FAQ</a>.

<?php
    include "db.inc";
    $db = new DB();

	include "decodeids.inc";
	include "tablemake.inc";

    include "dream.inc";

    check_table_cache_counts_all_dream_mps($db);

    $random_mp = searchtip_random_mp($db);
    $random_topic = searchtip_random_topic($db);
    $random_topic2 = searchtip_random_topic($db);
    $random_topic3 = searchtip_random_topic($db);
?>

<table class="layout"><tr>

<tr>

<td width="20%" class="layout" bgcolor="#dddddd">
<h2>Forum</h2>
<p>Chat to other users <a href="/forum">in our new forum</a>.
<h2>Newsletter</h2>
<p>Keep up with the Public Whip project.
An at most monthly briefing.
<p><a href="account/register.php">Sign up now!</a>
</td>

<td class="layout" bgcolor="#eeeeee" colspan="2">
<h2>At the Public Whip you can:</i></h2>
<ol class="actions" type="1">

<li>
<form class="search" action="search.php" name=pw>
<p><span class="actionsheading">Find out how any MP votes</span>
<br>Enter your postcode or MP name:
<input maxLength=256 size=10 name=query value=""> <input type=submit value="Go" name=button>
<br><i>Example: "OX1 3DR", "<?=$random_mp?>"</i>
</form></p>
</p>

<li>
<form class="search" action="search.php" name=pw>
<p><span class="actionsheading">Search for votes in parliament on your subject</span>
<br>Enter the topic to search for:
<input maxLength=256 size=10 name=query value=""> <input type=submit value="Search" name=button>
<br><i>Examples: "<?=$random_topic?>", "<?=$random_topic2?>", "<?=$random_topic3?>"</i>
</form></p>
</p>

<li><p><span class="actionsheading">Discover your Dream MP</span>
<br>Either <a href="dreammps.php">browse</a> or <a
href="account/adddream.php">create</a> an MP who votes how you want</span>
<br>Some examples:
<?php
    $db->query(get_top_dream_query(5));
    $dreams = array();
    while ($row = $db->fetch_row_assoc())
    {
        $dmp_name = $row['name'];
        $dreamid = $row['rollie_id'];
        array_push($dreams, "<a href=\"dreammp.php?id=$dreamid\">" .  $dmp_name . "</a>");
    }
    print join(", ", $dreams);
?>
</p>
</ol>

<td width="20%" class="layout" bgcolor="#dddddd">
<h2>Ministerial Whirl </h2>
<p><a href="minwhirl.php">
<img src="minwhirl/minwhirl.png"></a>
<p><a href="minwhirl.php">Reshuffle diagram of government posts</p>
</a>
</td>

</td></tr></table>

<table class="layout">

<td colspan=2>

<h2>Recent Divisions <a href="divisions.php"
title="Show all divisions ordered by most recent">(more...)</a></h2>

<?php
	$divtabattr = array(
			"showwhich"		=> 'rebellions10',
			"headings"		=> 'none',
			"limitby"		=> 5	);

    print "<table class=\"votes\">\n";
	division_table($db, $divtabattr);
    print "</table>\n";

?>

</td>

</tr><tr><td>

<h2>Top Rebels <a href="mps.php?sort=rebellions" title="Show all MPs ordered by rebellions">(more...)</a></h2>
<table class="mps">
<?php
$mps_query_start = "select first_name, last_name, title, constituency,
        party, pw_mp.mp_id as mp_id, round(100*rebellions/votes_attended,0) as rebellions,
        round(100*votes_attended/votes_possible,0) as attendance, entered_reason,
        left_reason, entered_house, left_house from pw_mp,
        pw_cache_mpinfo where
        pw_mp.mp_id = pw_cache_mpinfo.mp_id";

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

</td></tr></table>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
