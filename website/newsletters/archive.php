<? $title = "News Archive"; include "../header.inc";
# $Id: archive.php,v 1.3 2003/12/03 11:06:09 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

/*
<h2>2003 by Francis</h2>
<p></p>
*/

function render_newsletter($newsletter)
{
	$handle = fopen($newsletter, 'r');
	while ($line = fgets($handle))
	{
	    print $line . "<br>";
	}
	fclose($handle);
}
?>

<p>There's a free Public Whip newsletter.  At most every fortnight
we'll email you with news, articles and comment about the project.  <a
href="account/register.php">Sign up now!</a>

<hr><h2>Latest Newsletter - 3 December 2003</h2>
<p> <?php render_newsletter("issue2.txt"); ?>

<hr><h2>Previous Newsletter - 31 October 2003</h2>
<p> <?php render_newsletter("issue1.txt"); ?>

<hr><p><a href="old.php">Older site news</a>

<p>

<?php include "../footer.inc" ?>

