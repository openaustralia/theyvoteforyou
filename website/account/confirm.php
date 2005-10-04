<?php require_once "../common.inc";

# $Id: confirm.php,v 1.8 2005/10/04 19:22:44 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('../database.inc');
include_once('user.inc');

$email=mysql_escape_string($_GET["email"]);
$hash=mysql_escape_string($_GET["hash"]);

if ($hash && $email) {
	$worked=user_confirm($hash,$email);
} else {
	$feedback = 'Missing params';
}

$title = "Registration Confirmation"; 
include "../header.inc";

if ($feedback) {
    if ($worked)
    {
        print "<p>$feedback</p>";
        print '<p><a href="addpolicy.php">Make your own policies</a>';
        print "<br><a href=\"settings.php\">Account settings</a>";
    }
    else
    {
        echo "<div class=\"error\"><h2>Confirmation of registration failed</h2><p>$feedback</div>";
    }
}

if (!$worked){
	echo '<h2>Having trouble confirming?</h2>
        <p>Try the <a href="changeemail.php">Change Your Email
        Address</a> page to receive a new confirmation email';
}

?>
<?php include "../footer.inc" ?>
