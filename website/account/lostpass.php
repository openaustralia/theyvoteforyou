<?php require_once "../common.inc";

# $Id: lostpass.php,v 1.4 2005/01/15 20:38:11 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('../database.inc');
include_once('user.inc');

$email=mysql_escape_string($_POST["email"]);
$user_name=mysql_escape_string($_POST["user_name"]);
$submit=mysql_escape_string($_POST["submit"]);

if (user_isloggedin()) {
	user_logout();
	$user_name='';
}

$ok = false;
if ($submit) {
	$ok = user_lost_password($email,$user_name);
}

$title = "Reset Password";
include "../header.inc";

if ($feedback) {
    if ($ok)
    {
	echo "<p>$feedback</p><p><a href=\"settings.php\">Login here</a>";
    }
    else
    {
	echo "<div class=\"error\"><h2>Password not reset</h2><p>$feedback</div>";
    }
}

if (!$ok)
{

echo ' <P>
	Lost your password?  Quickly fill in this info and a new
        password will be emailed to you.
	<P>
	<FORM ACTION="'. $PHP_SELF .'" METHOD="POST">
	<B>Login Name:</B><BR>
	<INPUT TYPE="TEXT" NAME="user_name" VALUE="'.$user_name.'" SIZE="40" MAXLENGTH="15">
	<P>
	<B>Email Address:</B><BR>
	<INPUT TYPE="TEXT" NAME="email" VALUE="" SIZE="40" MAXLENGTH="50">
	<P>
	<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Reset My Password">
	</FORM>';
}

?>
<?php include "../footer.inc" ?>
