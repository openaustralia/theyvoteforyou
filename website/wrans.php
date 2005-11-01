<?php require_once "common.inc";
    # $Id: wrans.php,v 1.20 2005/11/01 01:23:17 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    require_once "parliaments.inc";
    $db = new DB(); 

    $prettysearch = html_scrub(trim($_GET["search"]));
    $shellid = html_scrub(trim($_GET["id"]));
    $expand = false;
    if ($_GET["expand"] == "yes")
        $expand = true;

	if ($prettysearch != "")
	{
		// Search query
        header("Location: http://www.theyworkforyou.com/search?s=".urlencode($prettysearch)."&maj=wrans");
        exit;
	}
	else if ($shellid != "")
	{
        $shellid = str_replace("uk.org.publicwhip/wrans/", "", $shellid);
        $handle = fopen("legacy/wransmap.txt", "r");
        $urls = array();
        while (!feof($handle)) {
            $line = trim(fgets($handle));
            list($from, $to) = split(" ", $line);
            if ($from == $shellid) {
                $tourl = "http://www.theyworkforyou.com/wrans?id=".urlencode($to);
                header("Location: $tourl");
                exit;
            }
        }
        fclose($handle);
	}
    $title = "Written Answers";
    pw_header();
?>
<p>Written Answers are now available from <a href="http://www.theyworkforyou.com/wrans">TheyWorkForYou.com</a> instead of The Public Whip.
<?
    if ($shellid != "") {
        print "The Written Answer $shellid is probably misspelt, and could not
        be found on TheyWorkForYou.com.  You will have to go there and search
        in order to find it.";
    }
?>
<?

?>

<?php pw_footer() ?>
