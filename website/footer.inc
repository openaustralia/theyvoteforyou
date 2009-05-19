<?php
# $Id: footer.inc,v 1.22 2009/05/19 14:47:21 marklon Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$colour_hex = '#003300';
if ($colour_scheme=='lords')
    $colour_hex = '#340900';
elseif ($colour_scheme=='scotland')
    $colour_hex = '#000433';

?>

<!-- the end of the major content -->
</td></tr>

<!-- the footer section -->
<tr class="headers"><td bgcolor="<?=$colour_hex?>" colspan="3"><p class="footer">
<span class="footerleft">
<a title="Frequently asked questions" href="<?=$toppath?>faq.php#whatis">About us</a>
<a title="Send comments, problems or suggestions" href="/email.php">Contact us</a>
<a title="Fodder for your spreadsheet" href="/project/data.php">Data feeds</a>
<a title="Public Whip is open source software" href="/project/code.php">Source code</a>
 <!-- Open Knowledge Link -->
<a href="http://okd.okfn.org/">
<img style="vertical-align: bottom" alt="This material is Open Knowledge" border="0"
src="/images/ok_80x23_red_green.png" /></a>
<!-- /Open Knowledge Link -->
</span>
<span class="footerright">
<img width="0" height="23" style="vertical-align: bottom"> <!-- nasty fake image to get vspacing same as footerleft -->
<a title="Divisions in your news reader" href="/faq.php#rss">RSS</a>
<a title="Details on the free license for this data" href="/faq.php#legal">Legal information</a>
</span>
<!-- this stuff appears centred
<a href="/newsletters/signup.php">Newsletter</a>
-->
</p></td></tr>

<!-- hold the maximum width of the content -->
</table>

</center>
<? 
    // Add in extra space at bottom so # internal links near bottom
    // of page scroll to top of screen (really, IMHO, this is a browser
    // bug, but all browsers have it)
    if ($paddingforanchors) { 
?>
<p class="paddingforanchors"></p>
<? } ?>
</body>
</html>
