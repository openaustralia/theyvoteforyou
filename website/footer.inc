<?php
# $Id: footer.inc,v 1.4 2003/10/11 00:22:18 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$toppath =  str_repeat("../", substr_count(dirname($_SERVER{'REQUEST_URI'}), "/") - 1);
?>

<!-- the end of the major content -->
</td></tr>

<!-- the footer section -->
<tr class="headers"><td bgcolor="#003300"><p class="footer"><span class="footerleft">

Email: <a href="mailto:support@publicwhip.org.uk">support@publicwhip.org.uk</a>
</span>
<span class="footerright">
<a href="<?=$toppath?>faq.php#legal">Legal information</a>
</span></p></td></tr>

<!-- hold the maximum width of the content -->
</table>

</center>
</body>
</html>
