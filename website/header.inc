<?php header("Content-Type: text/html; charset=utf-8");?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.102 2010/03/12 12:26:46 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# title bar if not set
if (!$headtitle)
{
    $headtitle = preg_replace("/<[^>]*>/", "", $title);
    $headtitle = preg_replace("/ - /", " &#8212; ", $headtitle." - The Public Whip");
    if (!$title || ($title == "Counting votes on your behalf"))
        $headtitle = "The Public Whip &#8212; ".$title;
}
if (!$h1title)
    $h1title = "<h1> ".str_replace(" - ", " &#8212; ", $title)." </h1>";

$colour_hex = '#003300';
$favicon = 'favicon.ico';
$gificon = 'thepublicwhip.gif';
if ($colour_scheme=='lords') {
    $colour_hex = '#340900';
    $favicon = 'faviconred.ico';
    $css = 'red.css';
    $gificon = 'thepublicwhipred.gif';
} elseif ($colour_scheme=='scotland') {
    $colour_hex = '#000433';
    $favicon = 'faviconblue.ico';
    $css = 'blue.css';
    $gificon = 'thepublicwhipblue.gif';
}

?>

<head>
<link href="<?=$toppath?>publicwhip.css" type="text/css" rel="stylesheet" media="all">
<? if ($colour_scheme == "lords" || $colour_scheme == "scotland") { ?>
<link href="<?=$toppath.$css?>" type="text/css" rel="stylesheet" media="all">
<? } ?>
<link href="<?=$toppath?>publicwhip_print.css" type="text/css" rel="stylesheet" media="print">
<link rel="icon" href="/<?=$favicon?>" type="image/x-icon" />
<link rel="shortcut icon" href="/<?=$favicon?>" type="image/x-icon" />
<link rel="alternate" type="application/rss+xml" title="RSS" href="http://www.publicwhip.org.uk/feeds/interestingdivisions.xml" />
<script type="text/javascript" src="/publicwhip.js"></script>
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
function secondnav_goto3() {
    if (!document) return
    if (!document.getElementById) return
    var el = document.getElementById('r3')
    window.location=el.options[el.selectedIndex].value
}
function ClickSup(nsup) {
    var el = document.getElementById('footnote-' + nsup);
    el.style.backgroundColor = (el.style.backgroundColor ? "" : "#ffff77");
    var sups = document.getElementsByTagName("sup");
    for (var i = 0; i < sups.length; i++)
        if (sups[i].className == "sup-" + nsup)
            sups[i].style.backgroundColor = el.style.backgroundColor;
}
// -->
</script>
</head>

<body align="center" onLoad="<?=$onload?>">
<script type="text/javascript" src="walterzorn/wz_tooltip.js"></script>
<center>

<? if ($_SERVER["HTTP_HOST"] != 'www.publicwhip.org.uk'
	and $_SERVER["HTTP_HOST"] != 'publicwhip.org.uk') { ?>
<strong>This is a test site - the real site is <a href="http://www.publicwhip.org.uk">over here</a>.</strong> Developers are busy making Public Whip better using this page.<p>
<? } ?>

<!-- hold the maximum width of the content -->
<table align="center" class="container" cellpadding="0" cellspacing="0" border="0">

<? /*
<!-- banner advert for election site -->
<tr class="electionadvert">
<td >
    <a href="/election.php"><img src="/quiz/electionbanner.gif" alt="How they voted 2005"/></a>
</td>
<td class="electionadvertright">
    <a id="aElectionQuiz" class="electionadvert" href="/election.php">Click here to take the <Strong>Quick Election Quiz</strong>
Just&nbsp;7&nbsp;Questions, 1&nbsp;minute</a>
</td>
</tr>
*/?>

<!-- banner advert for save parliament -->
<!--<tr class="">
<td colspan="4" style="padding: 0; border-bottom: medium solid #F83812;">
<? $saveparliament_banner = 3; ?>
    <a href="http://www.saveparliament.org.uk/?pw=<?=$saveparliament_banner?>">
    <img style="margin-top: 0; float: left;" src="/saveparliament/left.png" alt="Save Parliament"/><img style="margin-top: 0; float: right;" src="/saveparliament/right.png" alt="Save Parliament"/>
    </a>
</td>
</tr>
-->



<!-- banner advert for thestraightchoice -->
<tr class="electionadvert">
<td style="font-size:140%; padding-left:2em; font-style:italic;color:#980808">
    Have you received any election leaflets?  <b>Go to:</b>
</td>
<td class="electionadvert">
    <a href="http://www.thestraightchoice.org/"><img src="/images/straightchoicelogosmall.png" alt="Election leaflet project"/></a>
</td>
</tr>

<!-- the site logo -->
<tr><td class="identity" colspan="1">
<a href="<?=$toppath?>index.php"><img src="<?=$toppath?><?=$gificon?>" alt="The Public Whip"></a>
</td>
<!-- software patents banner -->
<!--
<td>
<a href="http://noepatents.eu.org/index.php/NO_Software_Patents"><img src="/patents/swpatbanner.en.png" alt="STOP Software Patents!"/></a>
</td>
-->
<td class="searchtitlebar" align="right" valign="middle" colspan="2">
<form class="searchtitlebarform" action="/search.php" name=pw>
Search: <input maxLength=256 size=12 id=query name=query onblur="fadeout(this)" onfocus="fadein(this)" value=""> <input type=submit value="Go" name=button>
</form>
<FORM ACTION="/newsletters/signup.php" METHOD="POST">
Newsletter (<a href="/newsletters/signup.php">info</a>): <INPUT TYPE="TEXT" NAME="email" id="email" onblur="fadeout(this)" onfocus="fadein(this)" VALUE="" SIZE="12" MAXLENGTH="50">
<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Go">
</FORM>

</td>
</tr>

<!-- the main site navigation -->
<tr class="headers">
<td class="pagenavlinks" colspan="3">
<div class="pagenavlinks" style="float:right">
<!--ACCOUNTBEGIN-->
<?php print account_navbar(); ?>
<!--ACCOUNTEND-->
</div>
<a title="Front page and site highlights" href="<?=$toppath?>index.php">Home</a>
<!--NEWSLETTERBEGIN-->
<?php print newsletter_navbar(); ?>
<!--NEWSLETTEREND-->
<a title="List of all votes in Parliament" href="<?=$toppath?>divisions.php">Divisions</a>
<a title="List of all Members of House of Commons" href="<?=$toppath?>mps.php">MPs</a>
<a title="List of all Members of House of Lords" href="<?=$toppath?>mps.php?house=lords">Lords</a>
<a title="List of all Members of the Scottish Parliament" href="<?=$toppath?>mps.php?house=scotland">MSPs</a>
<a title="Help to analyze MP's votes" href="<?=$toppath?>policies.php">Policies</a>
<a title="Chat with other users" href="/forum"><strong>Forum</strong></a>
<a title="Help run the Public Whip project" href="<?=$toppath?>project/index.php">Join Us</a>
<a title="Frequently asked questions" href="<?=$toppath?>faq.php">Help / FAQ</a>
</td></tr>

<!--<tr><td colspan="3" style="background-color: #90ff60; font-size: 30px; text-align:center; border:5px white solid;"><a href="/fortytwodays.php">Click here for the Forty-two days question</a></td></tr>-->

<? if ($second_links && $second_type == "default") { ?>
<!-- the second tier navigation as dropdowns -->
<!-- add hashes to $second_links array, keys are
     'href' - URL of link
     'text' - displayed text
     'tooltip' - text to put in title
     'current' - 'on' or 'off' for whether this item is currently selected -->
<tr class="secondheaders">
<td class="pagesecondnavlinks" colspan="3">

<?
    function print_links_default($links, $offset) {
        print '<form name="secondnav" action="/redir.php" method="post" style="display: inline">';
        print '<select id="r'.$offset.'" name="r'.$offset.'" onchange="secondnav_goto'.$offset.'()">';
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

    print_links_default($second_links, "");
    if ($second_links2)
    {
    	print_links_default($second_links2, "2");
        if ($second_links3)
	    	print_links_default($second_links3, "3");
    }
?>
</td>
</tr>
<!-- the second tier navigation as dropdowns end-->
<? } ?>

<!-- the rest of the content -->
<tr><td colspan="3" class="content">

<?
//<div style="margin-left:80px; margin-right:80px; margin-top:30px; margin-bottom:30px; background-color:#eeeedd; font-size:200%; text-align:center; color: #886611; padding:20px; border:thick blue dashed;\"><a style="color:#886611" href="/byelection">Try the Glenrothes Byelection Quiz</a></div>
?>

<? 
print $h1title;  # the actual heading
?>

<? if ($second_links && $second_type == "tabs") { ?>
<!-- the second tier navigation as tabs -->
<!-- add hashes to $second_links array, keys are
     'href' - URL of link
     'text' - displayed text
     'tooltip' - text to put in title
     'current' - 'on' or 'off' for whether this item is currently selected -->
<div class="secondnavtabs">

<?
    function print_links_tabs($links, $offset) {
        foreach ($links as $this_link) {
            print "<li class=\"".$this_link['current']."\">";
            if ($this_link['current'] != 'on')
                print "<a title=\"".$this_link['tooltip']."\" href=\"".$this_link['href']."\" class=\"".$this_link['current']."\">";
            print $this_link['text'];
            if ($this_link['current'] != 'on')
                print "</a>";
            print " ";
            print "</li>";
        }
    }

    print '<ul>';  # we could ad in secondary colours for the second row of table (in the same row)
    print_links_tabs($second_links, "");
    print '</ul>';
    if ($second_links2)
    {
        print '<ul>';
        print_links_tabs($second_links2, "");
        print '</ul>';
    }
?>
</div>
<!-- the second tier navigation as dropdowns end-->
<? } ?>


