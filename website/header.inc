<!DOCTYPE HTML>
<html>


<?php
# $Id: header.inc,v 1.105 2011/04/11 13:25:23 publicwhip Exp $

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

?>

<head>
<meta charset="UTF-8">

<link href="/style.css" type="text/css" rel="stylesheet" media="all">
<!--[if IE 7]>
<link href="/ie7.css" type="text/css" rel="stylesheet" media="all">

<![endif]-->
<!--
/*
 * @license
 * MyFonts Webfont Build ID 981839, 2011-08-21T11:30:45-0400
 * 
 * The fonts listed in this notice are subject to the End User License
 * Agreement(s) entered into by the website owner. All other parties are 
 * explicitly restricted from using the Licensed Webfonts(s).
 * 
 * You may obtain a valid license at the URLs below.
 * 
 * Webfont: Museo 700 by exljbris
 * URL: http://new.myfonts.com/fonts/exljbris/museo/700/
 * 
 * Webfont: Museo 300 by exljbris
 * URL: http://new.myfonts.com/fonts/exljbris/museo/300/
 * 
 * 
 * License: http://www.myfonts.com/viewlicense?1056
 * Licensed pageviews: unlimited
 * Webfonts copyright: Copyright (c) 2008 by Jos Buivenga/exljbris. All rights reserved.
 * 
 * © 2011 Bitstream Inc
*/

-->
<link rel="stylesheet" type="text/css" href="/publicwhip.css">
<link href="<?php echo $toppath?>publicwhip_print.css" type="text/css" rel="stylesheet" media="print">
<link rel="icon" href="/<?php echo $favicon?>" type="image/x-icon" />
<link rel="shortcut icon" href="/<?php echo $favicon?>" type="image/x-icon" />
<link rel="alternate" type="application/rss+xml" title="RSS" href="http://www.publicwhip.org.uk/feeds/interestingdivisions.xml" />
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js"></script>
<script type="text/javascript">
$(document).ready(function() {
    $('tr').mouseover(function() {
		$(this).addClass('over');})
		.mouseout(function() {
		$(this).removeClass('over');
	});
	$('tr:even').addClass('alt');
});
</script>
<script type="text/javascript" src="/publicwhip.js"></script>
<title><?php print $headtitle ?></title>
<?php if( extension_loaded('newrelic') ) { echo newrelic_get_browser_timing_header(); } ?>
<script type="text/javascript">
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
</script>
    <?php
    if (function_exists('remote_analytics')) {
        remote_analytics();
    }
?>
</head>

<body onLoad="<?php echo $onload?>">
<div id="whitebox">
<script type="text/javascript" src="walterzorn/wz_tooltip.js"></script>

<div id="header" class="widewidth">
<div class="logo"><a href="/"><img src="/images/logo.jpg" alt="the Public Whip" /></a></div>
<div class="search"><form class="searchtitlebarform" action="/search.php" name=pw>
Search: <input maxLength=256 size=12 id="query_head" name="query" onblur="fadeout(this)" onfocus="fadein(this)" value="" /> <input type="submit" value="Go" name="button" />
</form></div>


<!-- the main site navigation -->
<div id="nav_main">
<a title="Front page and site highlights" href="<?php echo $toppath?>index.php">Home</a>
<a title="List of all votes in Parliament" href="<?php echo $toppath?>divisions.php">Divisions</a>
<a title="List of all Members of House of Commons" href="<?php echo $toppath?>mps.php">MPs</a>
<a title="List of all Members of House of Lords" href="<?php echo $toppath?>mps.php?house=lords">Lords</a>
<a title="List of all Members of the Scottish Parliament" href="<?php echo $toppath?>mps.php?house=scotland">MSPs</a>
<a title="Help to analyze MP's votes" href="<?php echo $toppath?>policies.php">Policies</a>
<!-- <a title="Chat with other users" href="/forum">Forum</a> -->
<a title="Blog" href="http://blog.publicwhip.org.uk">Blog</a>
<a title="Twitter" href="http://twitter.com/publicwhip">Twitter</a>
<!-- <a title="Help run the Public Whip project" href="<?php echo $toppath?>project/index.php">Join Us</a> -->
<a title="Frequently asked questions" href="<?php echo $toppath?>faq.php">Help / FAQ</a>


</div>
</div><!-- end header-->
<div id="main" class="widewidth"><!-- main content -->
<?
print $h1title;  # the actual heading
?>

<?php if ($second_links && $second_type == "default") { ?>
<!-- the second tier navigation as dropdowns -->
<!-- add hashes to $second_links array, keys are
     'href' - URL of link
     'text' - displayed text
     'tooltip' - text to put in title
     'current' - 'on' or 'off' for whether this item is currently selected -->

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
<!-- the second tier navigation as dropdowns end-->
<?php } ?>

