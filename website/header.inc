<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.8 2003/10/02 14:01:42 frabcus Exp $

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

<!-- page centering format -->
<table width="100%" height="100%"><tr><td align="CENTER" valign="TOP">

<!-- hold the maximum width of the content -->
<table class="container" cellpadding="0" cellspacing="0">

<!-- the site logo -->
<tr><td class="identity"><img src="thepublicwhip.gif"></td></tr>


<!-- the main site navigation -->
<tr class="headers"><td bgcolor="#666666"><a href="index.php">Home</a>
<a href="news.php">News</a>
<a href="faq.php">FAQ</a>
<a href="divisions.php">Divisions</a>
<a href="mps.php">MPs</a>
<a href="mpsee.php">VoteMap</a>
<a href="code.php">Code</a>
<a href="search.php">Search</a></td></tr>

<!-- the title bar -->
<tr><td class="pagetitlebar"><h1><? print $title ?></h1></td></tr>

<!-- the rest of the content -->
<tr><td>


