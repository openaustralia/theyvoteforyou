<?php 
    # $Id: wrans.php,v 1.7 2003/12/12 10:39:37 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
	include "xquery.inc";
	include "protodecode.inc";
    $db = new DB(); 
    $title = html_scrub("Written Answers");
    include "header.inc";

    $prettysearch = html_scrub(trim($_GET["search"]));
    $shellsearch = escapeshellcmd(strtolower($prettysearch));
    $shellid = escapeshellcmd(html_scrub(trim($_GET["id"])));
?>

<p><b>You've stumbled upon... Some new stuff.  It isn't ready yet.</b>

<p class="search">Search in Written Answers:</p>
<form class="search" action="wrans.php" name=pw>
<input maxLength=256 size=25 name=search value=""> <input type="submit" value="Search" name="button">
</form>

<?
	if ($prettysearch <> "")
	{
		$ids = DecodeWord($shellsearch);
		$result = "";
		foreach ($ids as $id)
		{
			$result .= FetchWrans($id);
		}
		$result = WrapResult($result);
		print_transform("wrans-table.xslt", $result);
	}
	
	if ($shellid <> "")
	{
		$result = WrapResult(FetchWrans($shellid));
#		print "<pre>" . html_scrub($result) . "</pre>";
		if ($result)
			print_transform("wrans.xslt", $result);	
	}
?>

<?php include "footer.inc" ?>
