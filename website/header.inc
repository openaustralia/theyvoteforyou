<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.6 2003/09/18 09:28:22 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include "pretty.inc";
?>

<head>
<link href="publicwhip.css" type="text/css" rel="stylesheet">
<title>Public Whip - <? print $title ?></title>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
</head>
<body>

<div class="searchbox">
<form class="search" action="search.php" name=pw>
<input maxLength=256 size=10 name=query value=""> <input type=submit value="Search" name=button>
</form>
</div>

<div class="navline">
<a href="index.php">Home</a> |
<a href="news.php">News</a> |
<a href="faq.php">FAQ</a> 
<b>|</b>
<a href="divisions.php">Divisions</a> | 
<a href="mps.php">MPs</a> |
<a href="mpsee.php">Vote Map</a>
<b>|</b>
<a href="code.php">Code</a>
</div>

<h1><?
    print("the Public Whip - $title");
?></h1>

<hr class="topline">
