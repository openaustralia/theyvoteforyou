<?php require_once "common.inc";

//cache_begin(rand(0, 10));

# $Id: index.php,v 1.77 2011/04/11 13:20:43 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$title = "Counting votes on your behalf";
pw_header_notitle();

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

<div class="homeintro">
<h1>Find out how <span class="emph">your</span> MP votes on the issues <span class="emph">you</span> care about.</h1></div>
<div class="homevideo">
<p>Your MP votes on changes to British law on your behalf. When parliament is in session, they may do this a dozen times a week.</p>

<p>In order to know whether your MP is representing your views on the issues, you need to know how they’ve voted.</p>

<p>The Public Whip lets you see all their votes so you can hold them to account.</p>
</div>

<div class="homesearch">
<h2>Search the Whip</h2>
<p>Enter your <strong>postcode</strong>, an <strong>MP</strong> or <strong>Lord’s name</strong>, or a particular <strong>topic</strong> of interest</p>
<form class="searchtitlebarform" action="/search.php" name="pw" method="get">
<input maxLength=256 size=12 name="query" id="query" onblur="fadeout(this)" onfocus="fadein(this)"> <button type="submit" value="Submit" name="button">Submit</button>
</form>
</div>
    <?php
if (true===function_exists('advertisement')) {
advertisement('homepage');
}?>

<div class="homerecents">
<div class="narrowwidth">
<h2>Recent controversial divisions</h2>
<p><a href="divisions.php" title="Show all divisions ordered by most recent">Show all divisions ordered by most recent</a></p>

<?php
	$divtabattr = array(
			"showwhich"		=> 'rebellions10',
			"headings"		=> 'frontpageshort',
			"limitby"		=> 5	);

    print "<table class=\"votes\">\n";
	division_table($db, $divtabattr);
    print "</table>\n";

?>
</div>

<div class="col1"><h2>Top rebel MPs</h2>
<p><a href="mps.php?sort=rebellions" title="Show all MPs ordered by rebellions">Show all MPs ordered by rebellions</a></p>
</div>

<div class="col2"><h2>MPs and Lords who attend parliament most often</h2>
<p><a href="mps.php?sort=attendance&amp;house=both" title="Show all MPs ordered by attendance">Show all MPs ordered by attendance</a></p>
</div>
<div class="col3"><h2>Test an MP or Lord against policies you care about</h2>
<p><a href="policies.php">Browse</a> existing policies </p>

</div>
<div class="clear"></div>
</div>
<?php pw_footer(); ?>
<?php //cache_end(); ?>
