<?php include "cache-begin.inc"; ?>
<?php 
    # $Id: wrans.php,v 1.3 2003/12/05 20:23:28 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
	include "xquery.inc";
    $db = new DB(); 
    $title = html_scrub("Written Answers");
    include "header.inc";

    $prettyquery = html_scrub(trim($_GET["query"]));
?>

<p class="search">Search in Written Answers:</p>
<form class="search" action="wrans.php" name=pw>
<input maxLength=256 size=25 name=query value=""> <input type="submit" value="Search" name="button">
</form>

<?
# MP query
#	$query = 'stag("wrans") ..  etag("wrans") containing (stag("speech") ..  etag("speech") containing (attribute("id") containing attvalue("uk.org.publicwhip/member/1032")))';

	if ($prettyquery <> "")
	{
		$query = 'stag("wrans") ..  etag("wrans") containing 
				(stag("speech") ..  etag("speech") containing word("' 
				. $prettyquery . '"))';
		$result = sgrep_query("wrans", $query);
		print_transform("wrans.xslt", $result);	
	}
?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
