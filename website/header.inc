<?php header("Content-Type: text/html; charset=latin-1");?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.72 2005/12/22 20:06:14 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$headtitle = "$title - The Public Whip";
if ($title == "Counting votes on your behalf")
    $headtitle = "The Public Whip - $title";
$h1title = str_replace(" - ", " &#8212; ", $title);
$headtitle = str_replace(" - ", " &#8212; ", $headtitle);

?>

<head>
<link href="<?=$toppath?>publicwhip.css" type="text/css" rel="stylesheet" media="all">
<link href="<?=$toppath?>publicwhip_print.css" type="text/css" rel="stylesheet" media="print">
<link rel="icon" href="/favicon.ico" type="image/x-icon" />
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<link rel="alternate" type="application/rss+xml" title="RSS" href="http://www.publicwhip.org.uk/feeds/interestingdivisions.xml" />
<title><? print $headtitle ?></title>
<script>
<!--
function givefocus(field) {
    if (!document || !document.getElementById)
        return
    f = document.getElementById(field)
    if (f)
        f.focus()
}
function secondnav_goto() {
    if (!document) return
    if (!document.getElementById) return
    var el = document.getElementById('r')
    window.location=el.options[el.selectedIndex].value
}
function secondnav_goto2() {
    if (!document) return
    if (!document.getElementById) return
    var el = document.getElementById('r2')
    window.location=el.options[el.selectedIndex].value
}
// -->
</script>
</head>

<body align="center" onLoad="<?=$onload?>">
<center>

<? if ($_SERVER["HTTP_HOST"] != 'www.publicwhip.org.uk'
	and $_SERVER["HTTP_HOST"] != 'publicwhip.org.uk') { ?>
<strong>This is a test site - the real site is <a href="http://www.publicwhip.org.uk">over here</a>.</strong> Developers are busy making Public Whip better using this page.<p>
<? } ?>

<!-- hold the maximum width of the content -->
<table align="center" class="container" cellpadding="0" cellspacing="0">

<!-- banner advert for election site -->
<!--<tr class="electionadvert">
<td >
    <a href="/election.php"><img src="/quiz/electionbanner.gif" alt="How they voted 2005"/></a>
</td>
<td class="electionadvertright">
    <a id="aElectionQuiz" class="electionadvert" href="/election.php">Click here to take the <Strong>Quick Election Quiz</strong>
Just&nbsp;7&nbsp;Questions, 1&nbsp;minute</a>
</td>
</tr>-->

<!-- the site logo -->
<tr><td class="identity" colspan="1">
<a href="<?=$toppath?>index.php"><img src="<?=$toppath?>thepublicwhip.gif" alt="The Public Whip"></a>
</td>
<!-- software patents banner -->
<!--
<td>
<a href="http://noepatents.eu.org/index.php/NO_Software_Patents"><img src="/patents/swpatbanner.en.png" alt="STOP Software Patents!"/></a>
</td>
-->
<td class="searchtitlebar" align="right" valign="middle">
<form class="searchtitlebarform" action="search.php" name=pw>
Search or Postcode:
<br><input maxLength=256 size=12 name=query value=""> <input type=submit value="Go" name=button>
</form>
</td>
</tr>

<!-- the main site navigation -->
<tr class="headers">
<td class="pagenavlinks" >
<a title="Front page and site highlights" href="<?=$toppath?>index.php">Home</a>
<!--NEWSLETTERBEGIN-->
<?php print newsletter_navbar(); ?>
<!--NEWSLETTEREND-->
<a title="List of all votes in Parliament" href="<?=$toppath?>divisions.php">Divisions</a>
<a title="List of all Members of Parliament" href="<?=$toppath?>mps.php">MPs</a>
<a title="Help to analyze MP's votes" href="<?=$toppath?>policies.php">Policies</a>
<a title="Chat with other users" href="/forum">Forum</a>
<a title="Help run the Public Whip project" href="<?=$toppath?>project/index.php">Join Us</a>
<a title="Frequently asked questions" href="<?=$toppath?>faq.php">Help</a>
</td>
<td class="pagenavlinks" align="right">
<!--ACCOUNTBEGIN-->
<?php print account_navbar(); ?>
<!--ACCOUNTEND-->
</td>
</tr>

<!-- the second tier navigation -->
<!-- add hashes to $second_links array, keys are
     'href' - URL of link
     'text' - displayed text
     'tooltip' - text to put in title
     'current' - 'on' or 'off' for whether this item is currently selected -->
<? if ($second_links) { ?>
<tr class="secondheaders">
<td class="pagesecondnavlinks" colspan="2">

<?
    function print_links($links, $offset) {
        print '<form name="secondnav" action="/redir.php" method="post" style="display: inline">';
        print '<select id="r'.$offset.'" name="r'.$offset.'">';
        foreach ($links as $this_link) {
    #       print "<a title=\"".$this_link['tooltip']."\" href=\"".$this_link['href']."\" class=\"".$this_link['current']."\">".$this_link['text']."</a> ";
            print "<option title=\"".$this_link['tooltip']."\" value=\"".$this_link['href']."\" ";
            if ($this_link['current'] == 'on')
                print "selected ";
            print 'onclick="secondnav_goto'.$offset.'()" ';
            print "class=\"".$this_link['current']."\">";
            print $this_link['text'];
            print "</option> ";
        }
        print '</select> ';
        print ' <input type="submit" name="submit" value="Go">';
        print '</form> ';
    }

    print_links($second_links, "");
    if ($second_links2)
    {
    	print_links($second_links2, "2");
        if ($second_links3)
	    	print_links($second_links3, "3");
    }
?>
</td>
</tr>
<? } ?>

<!-- the rest of the content -->
<tr><td colspan="2">

<?=$pretitle ? $pretitle : ""?>

<h1><? print $h1title ?></h1>

