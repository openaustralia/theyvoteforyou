<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.13 2003/10/11 07:45:17 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

if (strpos($_SERVER{'REQUEST_URI'}, "/account")) $toppath = "../"; else $toppath = "";

include "pretty.inc";
?>

<head>
<link href="<?=$toppath?>publicwhip.css" type="text/css" rel="stylesheet">
<title>Public Whip - <? print $title ?></title>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<script>
<!--
function givefocus() { if (document.pw) document.pw.query.focus(); }
// -->
</script>
</head>

<body align="center" onLoad="<?=$onload?>">
<center>

<!-- hold the maximum width of the content -->
<table align="center" class="container" cellpadding="0" cellspacing="0">

<!-- the site logo -->
<tr><td class="identity"><a href="index.php"><img src="<?=$toppath?>thepublicwhip.gif" alt="The Public Whip"></a></td></tr>

<!-- the main site navigation -->
<tr class="headers"><td bgcolor="#666666"><a href="<?=$toppath?>index.php">Home</a>
<a href="<?=$toppath?>news.php">News</a>
<a href="<?=$toppath?>faq.php">FAQ</a>
<a href="<?=$toppath?>divisions.php">Divisions</a>
<a href="<?=$toppath?>mps.php">MPs</a>
<a href="<?=$toppath?>mpsee.php">VoteMap</a>
<a href="<?=$toppath?>code.php">Code</a>
<a href="<?=$toppath?>search.php">Search</a></td></tr>

<!-- the title bar -->
<tr><td class="pagetitlebar"><h1><? print $title ?></h1></td></tr>

<!-- the rest of the content -->
<tr><td>


