<?php require_once "../common.inc";

# $Id: changepass.php,v 1.9 2006/03/06 19:09:56 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../database.inc";
require_once "user.inc";

if (user_isloggedin())
{
    $new_password1=mysql_real_escape_string($_POST["new_password1"]);
    $new_password2=mysql_real_escape_string($_POST["new_password2"]);
    $change_user_name=$user_name;
    $old_password=mysql_real_escape_string($_POST["old_password"]);
    $submit=mysql_real_escape_string($_POST["submit"]);

    $ok = false;
    if ($submit) {
            $ok = user_change_password ($new_password1,$new_password2,$change_user_name,$old_password);
    }
}

$title = "Change password";
pw_header();

if (!user_isloggedin())
{
    print "<p><a href=\"settings.php\">Log in first</a> before changing password.";
}
else
{

if ($feedback) {
    if ($ok)
    {
	echo "<p>$feedback</p>";
    }
    else
    {
	echo "<div class=\"error\"><h2>Password not changed</h2><p>$feedback</div>";
    }
}

if (!$ok)
{

echo '
	<P>
	Want a more memorable password? Quickly fill in this info and your password will be changed.
	<P>
	<FORM ACTION="'. $PHP_SELF .'" METHOD="POST">
	<B>User name:</B><BR>
	<INPUT TYPE="TEXT" NAME="change_user_name" VALUE="'.$user_name.'" SIZE="40" MAXLENGTH="15">
	<P>
	<B>OLD Password:</B><BR>
	<INPUT TYPE="password" NAME="old_password" VALUE="" SIZE="40" MAXLENGTH="15">
	<P>
	<B>NEW Password:</B><BR>
	<INPUT TYPE="password" NAME="new_password1" VALUE="" SIZE="40" MAXLENGTH="15">
	<P>
	<B>NEW Password (again):</B><BR>
	<INPUT TYPE="password" NAME="new_password2" VALUE="" SIZE="40" MAXLENGTH="15">
	<P>
	<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Change My Password">
	</FORM>';
}
}

?>
<?php pw_footer() ?>
