<?  
# $Id: login.php,v 1.1 2003/10/11 10:29:13 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('database.inc');
include('user.inc');

if (user_isloggedin()) {
        user_logout();
        $user_name='';
}

$user_name=mysql_escape_string($_POST["user_name"]);
$password=mysql_escape_string($_POST["password"]);
$submit=mysql_escape_string($_POST["submit"]);

$ok = false;
if ($submit) {
	$ok = user_login($user_name,$password);
}

$title = "Login to The Public Whip"; 
include "../header.inc";

if ($feedback) {
    if ($ok)
    {
	print "<p>$feedback</p><p><a href=\"settings.php\">Account
        settings</a>";
    }
    else
    {
	print "<div class=\"error\"><h2>Login not correct,
        please try again</h2><p>$feedback</div>";
    }
}

if (!$ok)
{
    print '
	<P>
	Enter your user name and password and we\'ll set a cookie so we know you\'re logged in.
	<p>Not got a login?  <A HREF="register.php">Register a new
        account</A>.  You will receive a free email newsletter.
	<P>
	<FORM ACTION="'. $PHP_SELF .'" METHOD="POST">
	<B>User Name:</B><BR>
	<INPUT TYPE="TEXT" NAME="user_name" VALUE="" SIZE="10" MAXLENGTH="15">
	<P>
	<B>Password:</B><BR>
	<INPUT TYPE="password" NAME="password" VALUE="" SIZE="10" MAXLENGTH="15">
	<P>
	<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Login To Public Whip">
	</FORM>
	<P>';
}
?>
<?php include "../footer.inc" ?>
