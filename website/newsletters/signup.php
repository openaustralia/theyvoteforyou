<?php require_once "../common.inc";

# $Id: signup.php,v 1.7 2006/10/25 00:40:57 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../auth.inc";
require_once "../account/user.inc";
require_once "../db.inc";
$db = new DB();

$email=mysql_real_escape_string($_POST["email"]);
$submit=mysql_real_escape_string($_POST["submit"]);
$token=mysql_real_escape_string($_GET["token"]);
$unsub=mysql_real_escape_string($_GET["unsub"]);

if ($email == "your email")
    $email = "";

if ($token) {
    $query = "SELECT COUNT(*) from pw_dyn_newsletter where token = '$token'";
    $count = $db->query_one_value($query);
    if ($count != 1) {
        $title = "Please check the link";
        pw_header();
        print "<p>Sorry! We couldn't recognise that link. Please try clicking on
        it in your email again. If that doesn't work, try using 'copy' to get
        the link from your email, and 'paste' it into your browser.</p>";
    } else {
        if ($unsub) {
            $title = "Unsubscribed from newsletter";
            pw_header();
            $db->query("update pw_dyn_newsletter set confirm = 0 where token = '$token'");
            print "<p>You will no longer receive the Public Whip newsletter.</p>";
            print "<p>To sign up again, with the same or a different address, <a href=\"/newsletters/signup.php\">click here</a>.</p>";
        } else {
            $title = "Newsletter confirmed";
            pw_header();
            $db->query("update pw_dyn_newsletter set confirm = 1 where token = '$token'");
            print "<p>Thanks! You will now receive the Public Whip newsletter.</p>";
?>
<form class="search" action="/search.php" name=pw>
<p>Enter your postcode to find out how your MP voted:
<input maxLength=256 size=8 name=query value=""> <input type=submit value="Go" name=button>
<i>Example: "OX1 3DR"
</form>
<?
        }
    }
    pw_footer();
    exit;
}

if (user_isloggedin()) {
    header("Location: /account/settings.php\n");
    exit;
}

$title = "Subscribe to Newsletter"; 

$ok = false;
if ($submit) {
    $token = auth_random_token();
    if (!pw_validate_email($email)) {
        $feedback = 'Please enter a valid email address'; 
    } else {
        $db->query("DELETE FROM pw_dyn_newsletter WHERE email='$email'");
		$query = "INSERT INTO pw_dyn_newsletter
                    (email, token, confirm, subscribed) VALUES ('$email', '$token', 0, now())";
		$db->query($query);
        $message = "Follow this link to confirm your subscription: ".
               "\n\nhttp://www.publicwhip.org.uk/N/". urlencode($token).
               "\n\nYou will then receive the Public Whip newsletter,".
                 "\nwhich is at most monthly.";
        mail ($email,'Confirm your subscripton to the Public Whip newsletter',$message,'From: Public Whip <auto@publicwhip.org.uk>');
        $ok = true;
        $title = "Now check your email!";
        $feedback = 'Please click on the link in the email
        we have just sent you to complete your subscription.';
    }
}


$onload = "givefocus('email')";
pw_header();

if ($feedback) {
    if ($ok)
    {
	echo "<p>$feedback</p>";
    }
    else
    {
	echo "<div class=\"error\"><h2>Signing up not complete,
        please try again</h2><p>$feedback</div>";
    }
}

if (!$ok) {
?>
    <P>
    <FORM ACTION="<?php echo $PHP_SELF?>" METHOD="POST">
    <B>Email: </B><INPUT TYPE="TEXT" NAME="email" id="email" VALUE="<?php echo $email?>" SIZE="20" MAXLENGTH="50">
     <INPUT TYPE="SUBMIT" NAME="submit" VALUE="Subscribe">
    </FORM>

    <p><span class="ptitle">Privacy Policy:</span>
    Your email address and info will never be given to or sold to third
    parties.  We will only send you the Public Whip newsletter, or 
    other occasional messages about the Public Whip.  
    <p>The Public Whip newsletter is at most once a month.  Occasionally
    we send an extra small topical newsletter.
    <p><a href="archive.php">Read archive of previous newsletters</a>
<?php } ?>

<?php pw_footer() ?>
