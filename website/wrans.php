<?php 
    # $Id: wrans.php,v 1.8 2003/12/12 20:49:25 frabcus Exp $

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
		$result = WrapResult(FetchWrans($shellid));

		$title = "Written Answers";
		if ($result)
			$title = ApplyXSLT($result, "wrans-title.xslt");
		include "header.inc";

		if ($result)
			print ApplyXSLT($result, "wrans-full.xslt");	
		print "<hr>";
	}
	else
	{
		$title = "Written Answers";
		include "header.inc";
	}

?>

<p><b>You've stumbled upon... Some new stuff.  It isn't ready yet.</b>
	
<p class="search">Search in Written Answers:</p>
<form class="search" action="wrans.php" name=pw>
<input maxLength=256 size=25 name=search value=""> <input type="submit" value="Search" name="button">
</form>

<p class="search"><i>Example: "Coastguard", "Cameras" or "China"</i>

<?php include "footer.inc" ?>
