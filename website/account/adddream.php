<?php require_once "../common.inc";

# $Id: adddream.php,v 1.12 2005/02/18 12:13:18 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('../database.inc');
include_once('user.inc');
include "../db.inc";
include "../cache-tools.inc";

$just_logged_in = do_login_screen();

if (user_isloggedin()) # User logged in, show settings screen
{

    $name=db_scrub($_POST["name"]);
    $description=db_scrub($_POST["description"]);
    $submit=db_scrub($_POST["submit"]);

    $ok = false;
    if ($submit && (!$just_logged_in)) 
    {
        if (!$_POST["confirmprivacy"])
            $feedback = "Please check the box to confirm you have read the privacy notes.";
        else
        {
            if ($name == "" or $description == "")
                $feedback = "Please name your dream MP, and give a description.";
            else
            {
                cache_delete("dreammps.php", "");
                $db = new DB(); 
                $ret = $db->query_errcheck("insert into pw_dyn_rolliemp (name, user_id, description) values
                    ('$name', '" . user_getid() . "', '$description')"); 
                if ($ret)
                {
                    $ok = true;
                    $feedback = "Successfully added dream MP '" . html_scrub($name) . "'.  To 
                        select votes for your new MP, <a href=\"../search.php\">search</a> or
                        <a href=\"../divisions.php\">browse</a> for divisions.  On the page for
                        each division you can choose how your dream MP would have voted.";
                    audit_log("Added new dream MP '" . $name . "'");
                }
                else
                {
                    $feedback = "Failed to add new MP. " . mysql_error();
                }
            }
        }
    }

    $title = "Create a New Dream MP"; 
    include "../header.inc";

    if ($feedback && (!$just_logged_in)) {
        if ($ok)
        {
            echo "<p>$feedback</p>";
        }
        else
        {
            echo "<div class=\"error\"><h2>Creating a new dream MP not complete, please try again
                </h2><p>$feedback</div>";
        }
    }
    else
    {
        print "<p>Make up your own MP.  Here you have to name and describe
        your MP.  Afterwards, you will be able to specify how, if at all, your MP voted in
        every division.  Your MP can represent anything you like.  For example:
        <ul>
        <li>Organisation.  e.g. Greenpeace, Confederation of British Industry.
        <li>Single issue campaign.  e.g. Pro-Hunting, Anti-Europe, Anti-Iraq war.
        <li>Political party.  e.g. Labour party whip.
        <li>Prospective parliamentary candidate.  e.g. Tory candidate for Sedgefield.
        <li>Your self.  Issues that you personally care about.
        </ul>

        <p>All dream MPs are public.  It is important that you do not
        misrepresent an organisation.  Do not make it appear that your MP is an
        official representation of, say, Amnesty International's views, unless you have
        the authority from Amnesty International to do so.  Instead put
        \"Unofficial Amnesty International\".  Dream MPs which appear to
        represent an organisation but do not really will be removed.  Please
        contact <a
        href=\"mailto:team@publicwhip.org.uk\">team@publicwhip.org.uk</a> if
        you spot any such abuse.
        ";

    }

    if (!$ok)
    {
        if (!$feedback) {
            print "<p>What are you waiting for?  It's free!";
        }
    ?>
        <P>
        <FORM ACTION="<?=$PHP_SELF?>" METHOD="POST">
        <B>Name (enter the name of your organisation or the issue your dream MP votes on behalf of):</B><BR>
        <INPUT TYPE="TEXT" NAME="name" VALUE="<?=html_scrub($name)?>" SIZE="40" MAXLENGTH="50">
        <P>
        <B>Description (the criteria you will use to choose how your dream MP votes, give as much detail as possible):</B><BR>
        <textarea name="description" rows="6" cols="80"><?=html_scrub($description)?></textarea></p>

        <p><span class="ptitle">Copyright Notes:</span>  While you retain copyright of any text you enter
        into the Public Whip website, by submitting it you grant us a wide
        license of use.  In particular, we will display the text on the
        website, alongside your dream MP's voting record and your name and
        email.  You additionally grant us the right to publish the text
        in any other form, such as on a poster, on a CD-ROM or in a newspaper.

        <p><span class="ptitle">Privacy Notes:</span>
        By creating a dream MP you are making your user name
        <b><?=user_getname()?></b> and your made-up MP's voting record public.  
        Be aware, people viewing the Public Whip website will be able to
        associate the description, voting record and commentary relating to
        your dream MP with your user name.

        <p><INPUT TYPE="checkbox" NAME="confirmprivacy">Confirm you have read the
        above privacy notes
        <p><INPUT TYPE="SUBMIT" NAME="submit" VALUE="Create Dream MP">
        </FORM>

        <p>If you like you can <a href="http://www.publicwhip.org.uk/forum/viewforum.php?f=1">discuss dream MP on our forum</a>.

    <?php
    }
}
else
{
    login_screen();
}
?>

<?php include "../footer.inc" ?>
