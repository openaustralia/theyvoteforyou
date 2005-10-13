<?php require_once "../common.inc";
# $Id: settings.php,v 1.18 2005/10/13 01:41:13 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('../database.inc');
include_once('user.inc');
include "../db.inc";
$db = new DB(); 

$just_logged_in = do_login_screen();

if (user_isloggedin()) # User logged in, show settings screen
{
    if ($_POST["r"]) {
        $r = $_POST["r"];
        # Remove phpBB session id for redirect back
        $r = preg_replace("/&sid=[0-9a-f]+/", "", $r);
        header("Location: " . $r);
        exit;
    }

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
    $onload = "givefocus('user_name')";
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

    print "<h2>Policies You Made</h2>";
    $query = "select dream_id, name, description, private from pw_dyn_dreammp where user_id = '" . user_getid() . "' order by private, name";
    $db->query($query);
    $rowarray = $db->fetch_rows_assoc();
    foreach ($rowarray as $row)
    {
        print '<br><a href="../policy.php?id=' . $row['dream_id'] . '">' . html_scrub($row['name']) . "</a>\n";
        if ($row['private'])
            print " (legacy Dream MP)";
    }
    print '<p><a href="addpolicy.php">[Make a new policy]</a></p>';
}
else # User not logged in, show login screen
{
    login_screen();
}
?>
<?php include "../footer.inc" ?>
