<?php require_once "common.inc";

$cache_params = rand(0, 10); include "cache-begin.inc";

# $Id: index.php,v 1.52 2005/11/01 00:56:21 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$title = "Counting votes on your behalf"; include "header.inc";
?>

<p>Every week, a dozen or so times, your MP votes in the UK parliament.  This
is their crucial, visible exercise of power.  The Public Whip
data-mines their voting record to help you hold them to account.
For more information about the project, <a href="faq.php">read the FAQ</a>.

<?php
    require_once "db.inc";
    $db = new DB();

	require_once "decodeids.inc";
	require_once "tablemake.inc";
	require_once "tablepeop.inc";

    require_once "dream.inc";

	update_dreammp_votemeasures($db, null, 0); # for all

    $random_mp = searchtip_random_mp($db);
    $random_topic = searchtip_random_topic($db);
    $random_topic2 = searchtip_random_topic($db);
    $random_topic3 = searchtip_random_topic($db);
?>

<table class="layout"><tr>

<tr>

<td width="20%" class="layout" bgcolor="#dddddd">
<h2>Forum</h2>
<p><a href="/forum">Chat in our forum</a> to other users.
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
</form>
</p>

<li>
<form class="search" action="search.php" name=second>
<p><span class="actionsheading">Search for votes in parliament on your subject</span>
<br>Enter the topic to search for:
<input maxLength=256 size=10 name=query value=""> <input type=submit value="Search" name=button>
<br><i>Examples: "<?=$random_topic?>", "<?=$random_topic2?>", "<?=$random_topic3?>"</i>
</form></p>
</p>

<li><p><span class="actionsheading">Make policies and check your MP against them</span>
<br>Either <a href="policies.php">browse</a> existing policies or <a
href="account/addpolicy.php">make</a> a new policy</span>
<br>Some examples:
<?php
    $db->query(get_top_dream_query(5));
    $dreams = array();
    while ($row = $db->fetch_row_assoc())
    {
        $dmp_name = $row['name'];
        $dreamid = $row['dream_id'];
        array_push($dreams, "<a href=\"policy.php?id=$dreamid\">" .  $dmp_name . "</a>");
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

<h2>Recent Controversial Divisions <a href="divisions.php"
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

<?php

	$mptabattr = array("listtype" 	=> "parliament",
					   "parliament" => $parliaments[$parliament], # current parl I assume
					   "limit"	=> 3,
					   "sortby"		=> "rebellions");
	print "<table class=\"mps\">\n";
	mp_table($db, $mptabattr);
	print "</table>\n";
?>

</td><td>

<h2>Best Attendance <a href="mps.php?sort=attendance" title="Show all MPs ordered by attendance">(more...)</a></h2>
<?
	$mptabattr = array("listtype" 	=> "parliament",
					   "parliament" => $parliaments[$parliament], # current parl I assume
					   "limit"	=> 3,
					   "sortby"		=> "attendance");
	print "<table class=\"mps\">\n";
	mp_table($db, $mptabattr);
	print "</table>\n";
?>

</td></tr></table>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
