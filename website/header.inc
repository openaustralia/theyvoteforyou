<?php header("Content-Type: text/html; charset=latin-1");?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.30 2004/02/20 11:33:23 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$loc = dirname($_SERVER['REQUEST_URI']);
if (!is_bool(strpos($loc, "/account")) || !is_bool(strpos($loc, "/project")) || !is_bool(strpos($loc, "/newsletters")) )
    $toppath = "../"; 
else 
    $toppath = "";

include $toppath . "pretty.inc";

$pagetitle = "$title - Public Whip";
if ($title == "Counting votes on your behalf")
    $pagetitle = "Public Whip - $title";

?>

<head>
<link href="<?=$toppath?>publicwhip.css" type="text/css" rel="stylesheet">
<link rel="icon" href="<?=$toppath?>favicon.ico" type="image/x-icon" />
<link rel="shortcut icon" href="<?=$toppath?>favicon.ico" type="image/x-icon" />
<title><? print $pagetitle ?></title>
<script>
<!--
function givefocus(field) { if (document.pw) eval("document.pw." + field + ".focus()"); }
// -->
</script>
</head>

<body align="center" onLoad="<?=$onload?>">
<center>

<!-- hold the maximum width of the content -->
<table align="center" class="container" cellpadding="0" cellspacing="0">

<!-- the site logo -->
<tr><td class="identity"><a href="<?=$toppath?>index.php"><img src="<?=$toppath?>thepublicwhip.gif" alt="The Public Whip"></a></td></tr>

<!-- the main site navigation -->
<tr class="headers"><td bgcolor="#666666">
<a title="Front page and site highlights" href="<?=$toppath?>index.php">Home</a>
<a title="Subscribe to our email newsletter" href="<?=$toppath?>account/register.php">Newsletter</a>
<a title="Frequently Asked Questions" href="<?=$toppath?>faq.php">FAQ</a>
<a title="List of all votes in Parliament" href="<?=$toppath?>divisions.php">Divisions</a>
<a title="List of all Members of Parliament" href="<?=$toppath?>mps.php">MPs</a>
<a title="Parliamentary Questions for Written Answer" href="<?=$toppath?>wrans.php">Wrans</a>
<a title="Cluster diagram of voting record" href="<?=$toppath?>mpsee.php">Vote Map</a>
<a title="Help run the project" href="<?=$toppath?>project/index.php">Project</a>
<a title="Login or change settings" href="<?=$toppath?>account/settings.php">Account</a>
<a title="Find an MP or division" href="<?=$toppath?>search.php">Search</a>
</td>
</tr>

<!-- the title bar -->
<tr><td class="pagetitlebar"><h1><? print $title ?></h1></td></tr>

<!-- the rest of the content -->
<tr><td>


