<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.18 2003/10/13 15:15:15 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

if (!is_bool(strpos(dirname($_SERVER{'REQUEST_URI'}), "/account"))) $toppath = "../"; else $toppath = "";

include $toppath . "pretty.inc";
include $toppath . "account/quick.inc";
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
<tr><td class="identity"><a href="<?=$toppath?>index.php"><img src="<?=$toppath?>thepublicwhip.gif" alt="The Public Whip"></a></td></tr>

<!-- the main site navigation -->
<tr class="headers"><td bgcolor="#666666"><a href="<?=$toppath?>index.php">Home</a>
<a href="<?=$toppath?>news.php">Newsletter</a>
<a href="<?=$toppath?>faq.php">FAQ</a>
<a href="<?=$toppath?>divisions.php">Divisions</a>
<a href="<?=$toppath?>mps.php">MPs</a>
<a href="<?=$toppath?>mpsee.php">Vote Map</a>
<a href="<?=$toppath?>code.php">Code</a>
<?  if (user_isloggedin()) {?>
<a href="<?=$toppath?>account/settings.php">Account</a>
<? } else {?>
<a href="<?=$toppath?>account/login.php">Login</a>
<? } ?>
<a href="<?=$toppath?>search.php">Search</a>
</td>
</tr>

<!-- the title bar -->
<tr><td class="pagetitlebar"><h1><? print $title ?></h1></td></tr>

<!-- the rest of the content -->
<tr><td>


