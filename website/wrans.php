<?php 
    # $Id: wrans.php,v 1.15 2004/02/20 11:33:23 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
    include "wrans.inc";
    $db = new DB(); 

    $prettysearch = html_scrub(trim($_GET["search"]));
    $shellid = html_scrub(trim($_GET["id"]));
    $expand = false;
    if ($_GET["expand"] == "yes")
        $expand = true;

	if ($prettysearch != "")
	{
		// Search query
		$title = "Written Answers matching '$prettysearch'";
		include "header.inc";
		$ids = wrans_search($prettysearch);	
		if (count($ids) > 1000)
		{
			print "<p>More than 1000 matches, showing only first 1000.";
			$ids = array_slice($ids, 0, 1000);
		}
		if (count($ids) > 0)
		{
			$result = "";
			foreach ($ids as $id)
				$result .= FetchWrans($id);
			$result = WrapResult($result);
			print "<p>Found these " . count($ids) . " Written Answers matching '$prettysearch':";

			if ($expand)
				print ApplyXSLT($result, "wrans-full.xslt");
			else
				print ApplyXSLT($result, "wrans-table.xslt");

			$url = "wrans.php?search=" . urlencode($_GET["search"]);
			if (!$expand)
				print "<p><a href=\"$url&expand=yes\">Show contents of all these Written Answers on one large page</a></p>";
			else
				print "<p><a href=\"$url&expand=no\">Collapse all these answers into a summary table</a></p>";

		}
		else
		{
			print "<p>Not found any Written Answers matching '$prettysearch'.";
		}
	}
	else if ($shellid != "")
	{
		// ID query
		$wrans = FetchWrans($shellid);
		if ($wrans)
		{
			$result = WrapResult($wrans);

			$title = "Written Answers";
			if ($result)
				$title = ApplyXSLT($result, "wrans-title.xslt");
			include "header.inc";

			if ($result)
				print ApplyXSLT($result, "wrans-full.xslt");	
		}
		else
		{
			$title = "Written Answer not found";
			include "header.inc";
			print "<p>Written answer " . $shellid . " not in database.";
		}
	}
	else
	{
		$title = "Written Answers";
        $onload = "givefocus('search')";
		include "header.inc";
		# print "Use the <a href=\"search.php\">general search page</a> to find Written Answers now.";
?>
<p>A <i>Written Answer</i> (sometimes <i>wrans</i>) is an exchange between an MP and a minister.  They contain mainly
factual data researched by a civil servant, and help members scrutinise the workings of government. 
<a href="search.php">Search for written answers</a> by topic, or <a href="mps.php">look up an MP</a> to
get a list of all the questions they asked.</p>
<?
    print "<h2>Popular Written Answers</h2>
        <p>Recent questions and answers which have been viewed by many people on this site.";
    $ids = wrans_recent_popular(20);
    $result = "";
    foreach ($ids as $id)
        $result .= FetchWrans($id);
    $result = WrapResult($result);
    print ApplyXSLT($result, "wrans-table.xslt");
}
/*
<form class="search" action="wrans.php" name=pw>
<input maxLength=256 size=25 name=search value=""> <input type="submit" value="Search" name="button">
</form>

<p class="search"><i>Example: "Coastguard", "Speed Cameras" or "China"</i>

<p class="search"><span class="ptitle">Search Tips:</span> 
<? search_wrans_tip() ?>
*/
?>

<?php include "footer.inc" ?>

