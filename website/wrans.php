<?php 
    # $Id: wrans.php,v 1.10 2003/12/21 01:05:22 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
	include "xquery.inc";
	include "protodecode.inc";
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
		
		$ids = DecodeWord($prettysearch);
		if (count($ids) > 0)
		{

			$result = "";
			foreach ($ids as $id)
				$result .= FetchWrans($id);
			$result = WrapResult($result);
			print "<p>Found these Written Answers matching '$prettysearch':";

			$url = "wrans.php?search=" . urlencode($_GET["search"]);
			if (!$expand)
				print "<p><a href=\"$url&expand=yes\">Show contents of all these Written Answers on one large page</a></p>";
			else
				print "<p><a href=\"$url&expand=no\">Collapse all these answers into a summary table</a></p>";

			if ($expand)
				print ApplyXSLT($result, "wrans-full.xslt");
			else
				print ApplyXSLT($result, "wrans-table.xslt");
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
		print "<hr>";
	}
	else
	{
		$title = "Written Answers";
		include "header.inc";
	}

?>

<p class="search">Search in Written Answers:</p>
<form class="search" action="wrans.php" name=pw>
<input maxLength=256 size=25 name=search value=""> <input type="submit" value="Search" name="button">
</form>

<p class="search"><i>Example: "Coastguard", "Cameras" or "China"</i>

<?php include "footer.inc" ?>
