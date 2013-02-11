<?php require_once "../common.inc";
# $Id: settings.php,v 1.23 2006/02/27 06:25:19 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../database.inc";
require_once "user.inc";
require_once "../db.inc";
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
    $submit=mysql_real_escape_string($_POST["submit"]);

    $ok = false;
    if ($submit && (!$just_logged_in)) {
    	$ok = user_changenewsletter($newsletter);
    }

    $title = "Account settings"; 
    $onload = "givefocus('user_name')";
    pw_header();

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

    print '<P><span class="ptitle">User name:</span> ' . $user_name . '
	<br><span class="ptitle">Real name:</span> ' .  user_getrealname() . '
	<br><span class="ptitle">Email:</span> ' . user_getemail() . ' (<a href="changeemail.php">change email</a>)
    <br><span class="ptitle">Password:</span> (<a href="changepass.php">change password</a>)

	<FORM ACTION="'. $PHP_SELF .'" METHOD="POST">
    <h2>Newsletter subscription</h2>
	<INPUT TYPE="checkbox" NAME="newsletter" ' . $newsletter . '>Email newsletter (at most once a month)
	<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Update">
	</FORM>
	<P>';

    print '<h2>Forum profile</h2>';
    print '<p>';
    print pretty_user_name($db, $user_name, 'View your forum profile, including posts you\'ve made');

    print "<h2>Policies which you made</h2>";
    $query = "select dream_id, name, description, private from pw_dyn_dreammp where user_id = '" . user_getid() . "' order by private, name";
    $db->query($query);
    $rowarray = $db->fetch_rows_assoc();
    foreach ($rowarray as $row)
    {
        print '<br><a href="../policy.php?id=' . $row['dream_id'] . '">' . html_scrub($row['name']) . "</a>\n";
        if ($row['private'] == 0)
            print " (public)";
        if ($row['private'] == 1)
            print " (legacy Dream MP)";
        if ($row['private'] == 2)
            print " (provisional)";
    }
    print '<p>(<a href="addpolicy.php">make a new policy</a>)</p>';
    pw_footer();
}
else # User not logged in, show login screen
{
    login_screen();
}
?>
