<? $title = "News Archive"; include "../header.inc";
# $Id: archive.php,v 1.2 2003/11/27 00:41:18 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

/*
<h2>2003 by Francis</h2>
<p></p>
*/
?>

<p>There's a free Public Whip newsletter.  At most every fortnight
we'll email you with news, articles and comment about the project.  <a
href="account/register.php">Sign up now!</a>

<h2>Latest Newsletter - 31 October 2003</h2>
<p>
<?php
$newsletter = "issue1.txt";
$handle = fopen($newsletter, 'r');
while ($line = fgets($handle))
{
    print $line . "<br>";
}
fclose($handle);

?>

<p><a href="old.php">Older site news</a>

<p>

<?php include "../footer.inc" ?>

