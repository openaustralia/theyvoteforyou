<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.3 2003/08/19 12:19:03 frabcus Exp $

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

<div class="navline">
<a href="index.php">Home</a> |
<a href="divisions.php">Divisions</a> | 
<a href="mps.php">MPs</a> |
<a href="mpsee.php">Cluster</a> |
<a href="code.php">Code</a> |
<a href="faq.php">FAQ</a> |
<a href="search.php">Search</a>
</div>

<h1><?
    print("the Public Whip - $title");
?></h1>

<hr class="topline">
