<?  
# $Id: settings.php,v 1.8 2004/06/15 10:27:01 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('database.inc');
include_once('user.inc');
include "../db.inc";
$db = new DB(); 

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
	<P>
    <a href="logout.php">Logout</a>
        | <a href="changeemail.php">Change Email</a>
        | <a href="changepass.php">Change Password</a>

	<FORM ACTION="'. $PHP_SELF .'" METHOD="POST">
	<INPUT TYPE="checkbox" NAME="newsletter" ' . $newsletter . '>Email newsletter (at most once a month)
	<p><INPUT TYPE="SUBMIT" NAME="submit" VALUE="Change">
	</FORM>
	<P>';

    print "<h2>Your Dream MPs</h2>";
    $query = "select rollie_id, name, description from pw_dyn_rolliemp where user_id = '" . user_getid() . "'";
    $db->query($query);
    $rowarray = $db->fetch_rows_assoc();
    foreach ($rowarray as $row)
    {
        print '<br><a href="../dreammp.php?id=' . $row['rollie_id'] . '">' . html_scrub($row['name']) . "</a>\n";
    }
    print '<p><a href="adddream.php">[Add new dream MP]</a></p>';
}
else # User not logged in, show login screen
{
    login_screen();
}
?>
<?php include "../footer.inc" ?>
