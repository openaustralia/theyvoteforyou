<?php header("Content-Type: text/html; charset=latin-1");?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: s8-header.inc,v 1.1 2005/02/22 10:49:01 sams Exp $

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
include_once $toppath . "cache-tools.inc";

$pagetitle = "$title - The Public Whip";
if ($title == "Counting votes on your behalf")
    $pagetitle = "The Public Whip - $title";

?>

<head>
<link href="http://www.publicwhip.org.uk/publicwhip.css" type="text/css" rel="stylesheet">
<title><? print $pagetitle ?></title>
</head>

<body align="center" onLoad="<?=$onload?>">
<center>

<!-- hold the maximum width of the content -->
<table align="center" class="container" cellpadding="0" cellspacing="0">

<!-- the site logo -->
<tr><td class="identity" colspan="2">
<span align="right">The Public Whip Logo</span>
<!-- the title bar -->
<tr><td class="pagetitlebar" colspan="2"><h1><? print $title ?></h1></td></tr>

<!-- the rest of the content -->
<tr><td colspan="2">


