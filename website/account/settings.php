<?  
# $Id: settings.php,v 1.4 2003/10/31 01:37:56 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('database.inc');
include('user.inc');

$just_logged_in = false;
if (!user_isloggedin())
{
    $user_name=mysql_escape_string($_POST["user_name"]);
    $password=mysql_escape_string($_POST["password"]);
    $submit=mysql_escape_string($_POST["submit"]);

    if ($submit) {
        if (user_login($user_name,$password))
        {
            $just_logged_in = true;
            $feedback = "";
        }
    }
}

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

    if ($feedback) {
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
	<INPUT TYPE="checkbox" NAME="newsletter" ' . $newsletter . '>Email newsletter (at most once a fortnight)
	<P>
	<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Change">
	</FORM>
	<P>';
}
else # User not logged in, show login screen
{
    $title = "Login to The Public Whip"; 
    include "../header.inc";

    if ($feedback) {
        print "<div class=\"error\"><h2>Login not correct,
        please try again</h2><p>$feedback</div>";
    }

    print '
        <P>
        Enter your user name and password and we\'ll set a cookie so we know you\'re logged in.
        <p>Not got a login?  <A HREF="register.php">Register a new
        account</A>.  You will receive a free email newsletter.
        <br>Lost your password? <a href="lostpass.php">Reset your password here</a>.
        <P>
        <FORM ACTION="'. $PHP_SELF .'" METHOD="POST">
        <B>User Name:</B><BR>
        <INPUT TYPE="TEXT" NAME="user_name" VALUE="" SIZE="15" MAXLENGTH="15">
        <P>
        <B>Password:</B><BR>
        <INPUT TYPE="password" NAME="password" VALUE="" SIZE="15" MAXLENGTH="15">
        <P>
        <INPUT TYPE="SUBMIT" NAME="submit" VALUE="Login To Public Whip">
        </FORM>
        <P>';
}
?>
<?php include "../footer.inc" ?>
