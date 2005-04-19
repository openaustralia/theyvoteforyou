<?php header("Content-Type: text/html; charset=latin-1");?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php
# $Id: header.inc,v 1.51 2005/04/19 09:13:05 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include_once $toppath . "pretty.inc";
include_once $toppath . "account/user.inc";
include_once $toppath . "cache-tools.inc";

$pagetitle = "$title - The Public Whip";
if ($title == "Counting votes on your behalf")
    $pagetitle = "The Public Whip - $title";

?>

<head>
<link href="<?=$toppath?>publicwhip.css" type="text/css" rel="stylesheet">
<link rel="icon" href="/favicon.ico" type="image/x-icon" />
<link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
<link rel="alternate" type="application/rss+xml" title="RSS" href="http://www.publicwhip.org.uk/feeds/interestingdivisions.xml" />
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

<!-- the site logo -->
<tr><td class="identity" colspan="2">
<a href="<?=$toppath?>index.php"><img src="<?=$toppath?>thepublicwhip.gif" alt="The Public Whip"></a>

</td></tr>

<!-- the main site navigation -->
<tr class="headers">
<td class="pagenavlinks" >
<a title="Front page and site highlights" href="<?=$toppath?>index.php">Home</a>
<!--NEWSLETTERBEGIN-->
<?php print newsletter_navbar(); ?>
<!--NEWSLETTEREND-->
<a title="Frequently Asked Questions" href="<?=$toppath?>faq.php">FAQ</a>
<a title="List of all votes in Parliament" href="<?=$toppath?>divisions.php">Divisions</a>
<a title="List of all Members of Parliament" href="<?=$toppath?>mps.php">MPs</a>
<a title="MPs who vote the way you want" href="<?=$toppath?>dreammps.php">Dream MPs</a>
<!-- <a title="Cluster diagram of voting record" href="<?=$toppath?>mpsee.php">Vote Map</a> -->
<a title="Help run the project" href="<?=$toppath?>project/index.php">Project</a>
<a title="Find an MP or division" href="<?=$toppath?>search.php">Search</a>
</td>
<td class="pagenavlinks" align="right">
<!--ACCOUNTBEGIN-->
<?php print account_navbar(); ?>
<!--ACCOUNTEND-->
</td>
</tr>

<!-- the title bar -->
<tr><td class="pagetitlebar" colspan="2"><h1><? print $title ?></h1></td></tr>

<!-- the rest of the content -->
<tr><td colspan="2">


