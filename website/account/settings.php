<?  
# $Id: settings.php,v 1.6 2004/02/08 04:01:44 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('database.inc');
include('user.inc');

$just_logged_in = do_login_screen();

if (user_isloggedin()) # User logged in, show settings screen
{
    if ($_POST["newsletter"])
        $newsletter = true;
    else
        $newsletter = false;
    $submit=mysql_escape_string($_POST["submit"]);

    $ok = false;
    if ($submit && (!$just_logged_in)) {
    	$ok = user_changenewsletter($newsletter);
    }

    $title = "Account Settings"; 
    include "../header.inc";

    if ($feedback && (!$just_logged_in)) {
        if ($ok)
        {
            print "<p>$feedback</p>";
        }
        else
        {
            print "<div class=\"error\"><h2>Failed to change settings</h2><p>$feedback</div>";
        }
    }

    $newsletter = user_getnewsletter();
    if ($newsletter)
        $newsletter = "checked";
    else
        $newsletter = "";

    print '<p>These are the settings for your Public Whip account.  If
    you would like to stop receiving the newsletter, uncheck the box and
    choose "Change".  You can also alter your email address, or logout
    from here.
	<P><span class="ptitle">User name:</span> ' . $user_name . '
	<br><span class="ptitle">Real name:</span> ' .  user_getrealname() . '
	<br><span class="ptitle">Email:</span> ' . user_getemail() . '
        <p><a href="logout.php">Logout</a>
        <br><a href="changeemail.php">Change email</a>
        <br><a href="changepass.php">Change password</a>
	<P>
	<FORM ACTION="'. $PHP_SELF .'" METHOD="POST">
	<INPUT TYPE="checkbox" NAME="newsletter" ' . $newsletter . '>Email newsletter (at most once a month)
	<P>
	<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Change">
	</FORM>
	<P>';
}
else # User not logged in, show login screen
{
    login_screen();
}
?>
<?php include "../footer.inc" ?>
