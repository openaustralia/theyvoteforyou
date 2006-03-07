<?php require_once "common.inc";

cache_begin(rand(0, 10));

# $Id: index.php,v 1.69 2006/03/07 09:55:05 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$title = "Counting votes on your behalf";
pw_header();
?>

<p>Every week, a dozen or so times, your MP votes in the UK Parliament.  This
is their definitive exercise of power.  The Public Whip
extracts their voting record from the pages of the Parliamentary transcript
so that you can see it and hold them to account.
For more information about the project <a href="faq.php">see the FAQ</a>.

<?php
    require_once "db.inc";
    $db = new DB();

	require_once "decodeids.inc";
	require_once "tablemake.inc";
	require_once "tablepeop.inc";
	require_once "tableoth.inc"; 
	
    require_once "dream.inc";

	update_dreammp_votemeasures($db, null, 0); # for all

    $random_mp = searchtip_random_mp($db, "commons");
    $random_lord = searchtip_random_mp($db, "lords");
    $random_topic = searchtip_random_topic($db);
    $random_topic2 = searchtip_random_topic($db);
    $random_topic3 = searchtip_random_topic($db);
?>

<table class="layout"><tr>

<tr>

<td width="20%" class="layout" bgcolor="#dddddd">
<h2>Newsletter</h2>
<p>Keep up with the Public Whip project.
An at most monthly briefing.
<p>
    <FORM ACTION="/newsletters/signup.php" METHOD="POST">
    <B>Your email: </B><INPUT TYPE="TEXT" NAME="email" id="email" VALUE="<?=$email?>" SIZE="15" MAXLENGTH="50">
     <INPUT TYPE="SUBMIT" NAME="submit" VALUE="Subscribe">
    </FORM>

<p><a href="newsletters/signup.php">More details</a>
<!--<h2>Forum</h2>
<p><a href="/forum">Chat in our forum</a> to other users.-->
</td>

<td class="layout" bgcolor="#eeeeee" colspan="2">
<h2>At the Public Whip you can:</i></h2>
<ol class="actions" type="1">

<li>
<form class="search" action="search.php" name=pw>
<p><span class="actionsheading">Find out how any MP or Lord votes</span>
<br>Enter your postcode or their name:
<input maxLength=256 size=8 name=query value=""> <input type=submit value="Go" name=button>
<br><i>Example: "OX1 3DR", "<?=$random_mp?>", "<?=$random_lord?>"</i>
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

<li><p><span class="actionsheading">Test your MP or Lord against policies you care about</span>
<br>Either <a href="policies.php">browse</a> existing policies or <a
href="account/addpolicy.php">make</a> a new policy</span>
<br>Some examples:
<?php
	// do this inline to free up the fact that it ain't going to be used anywhere else
	// could even be selected at random
    $query = "SELECT name, pw_dyn_dreammp.dream_id
        		FROM pw_dyn_dreammp
				LEFT JOIN pw_cache_dreaminfo
					ON pw_cache_dreaminfo.dream_id = pw_dyn_dreammp.dream_id
				WHERE votes_count > 0 AND private = 0
				ORDER BY RAND()
				LIMIT 5";

    $db->query($query); 
    $delcomma = "";
    while ($row = $db->fetch_row_assoc())
    {
        print $delcomma."<a href=\"policy.php?id=".$row['dream_id']."\">".$row['name']."</a>";
		$delcomma = ", ";
	}
    print "\n";
?>
</p>
</ol>

<td width="20%" class="layout" bgcolor="#dddddd">
<p><a href="minwhirl.php">
<img src="minwhirl/minwhirl.png"></a>
<p><a href="minwhirl.php">Reshuffle diagram of government posts</p>
</a>
<p><a href="mpsee.php">
<img src="votemap/mpseethumb.png"></a>
<p><a href="mpsee.php">Where is Blair?</p>
</a>
</td>

</td></tr></table>

<table class="layout">

<td colspan=2>

<h2>Recent controversial divisions (<a href="divisions.php"
title="Show all divisions ordered by most recent">more...</a>)</h2>

<?php
	$divtabattr = array(
			"showwhich"		=> 'rebellions10',
			"headings"		=> 'frontpageshort',
			"limitby"		=> 5	);

    print "<table class=\"votes\">\n";
	division_table($db, $divtabattr);
    print "</table>\n";

?>

</td>

</tr><tr><td>

<h2>Top rebel MPs (<a href="mps.php?sort=rebellions" title="Show all MPs ordered by rebellions">more...</a>)</h2>

<?php

	$mptabattr = array("listtype" 	=> "parliament",
					   "parliament" => "now", 
					   "limit"	=> 3,
					   "house" => "commons", 
                       "sortby"		=> "rebellions");
	print "<table class=\"mps\">\n";
	mp_table($db, $mptabattr);
	print "</table>\n";
?>

</td><td>

<h2>Best attending MPs and Lords (<a href="mps.php?sort=attendance&house=both" title="Show all MPs ordered by attendance">more...</a>)</h2>
<?
	$mptabattr = array("listtype" 	=> "parliament",
					   "parliament" => "now", 
					   "limit"	=> 3,
                       "house"  => "both", 
					   "sortby"		=> "attendance");
	print "<table class=\"mps\">\n";
	mp_table($db, $mptabattr);
	print "</table>\n";
?>

</td></tr></table>

<?php pw_footer(); ?>
<?php cache_end(); ?>

