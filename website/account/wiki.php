<?php require_once "../common.inc";
# $Id: wiki.php,v 1.6 2005/02/18 19:43:41 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('../database.inc');
include_once('user.inc');

include "../db.inc";
include "../cache-tools.inc";
include "../gather.inc";
$db = new DB(); 

$just_logged_in = do_login_screen();

if (user_isloggedin()) # User logged in, show settings screen
{
    $key = db_scrub($_GET["key"]);
    $newtext = db_scrub($_POST["newtext"]);
    $r = db_scrub($_GET["r"]);

    $title = "Edit Text"; 
    if ($matches = get_motion_from_key($key)) {
        $division_date = $matches[1];
        $division_number = $matches[2];
        $db->query("select * from pw_division where division_date = '$division_date' 
            and division_number = '$division_number'");
        $division_details = $db->fetch_row_assoc();
        $prettydate = date("j M Y", strtotime($division_date));
        $title = "Edit Motion Effect - " . $division_details['division_name'] . " - $prettydate - Division No. $division_number";
        $debate_gid = str_replace("uk.org.publicwhip/debate/", "", $division_details['debate_gid']);
    }
    
    if ($submit && (!$just_logged_in))
    {
        if ($submit == "Save") {
            $db->query_errcheck("insert into pw_dyn_wiki 
                (object_key, text_body, user_id, edit_date) values
                ('$key', '$newtext', '" . user_getid() . "', now())");
            audit_log("Edited wiki text '" . $key . "'");
            if ($division_date) {
                notify_motion_updated($db, $division_date, $division_number);
            }
            $matches = null;
        }
        header("Location: ". $r);
        exit;
    }
    else 
    {
        include "../header.inc";

        $values = get_wiki_current_value($key);
        
        if (strstr($key, "motion-")) {
?>
        <p>Describe the <i>result</i> of this division.  This will require you
        to check through the 
<?
        if ($debate_gid != "") {
            print "<a href=\"http://www.theyworkforyou.com/debates/?id=$debate_gid\">debate leading up to the vote</a>.";
        } else {
            print "debate leading up to the vote.";
        }
?>
        The raw, and frequently
        wrong, motion text is there by default.  Feel free to remove it when
        you've replaced it with something better. </p>

        <p>Please, keep it accurate, authorative, brief, and as jargon-free as
        possible so that new readers who don't know Parliamentary procedure can
        gain enlightenment. You are encouraged to include hyperlinks to the
        statutory legislation, command papers, reports, and committee
        proceedings that are referred to so that readers who want to follow the
        story further will know where to look.</p>

        <p>You can write comments, but please keep them below the "COMMENTS AND
        NOTES" line so that they don't interfere with the provision of what we
        hope could be the most authoratitive and accessible record of what's
        going on in Parliament.</p>

        <p>Questions, thoughts? 
        <a href="http://www.publicwhip.org.uk/forum/viewforum.php?f=2">Chat
with other motion researchers on our special forum</a>.

        <p>Leave the "MOTION EFFECT" and "COMMENTS AND NOTES" in place, so our
        computer can work it out.

        <p><b>Motion result:</b>
<?
        }

?>
        <P>
        <FORM ACTION="<?=$REQUEST_URI?>" METHOD="POST">
        <textarea name="newtext" rows="20" cols="80"><?=html_scrub($values['text_body'])?></textarea>
        <p>
        <INPUT TYPE="SUBMIT" NAME="submit" VALUE="Save">
        <INPUT TYPE="SUBMIT" NAME="submit" VALUE="Cancel">
        </FORM>
        </P>
<?
        if (strstr($key, "motion-")) {
?>
        You can use the following HTML tags:
        <ul>
        <li>&lt;p&gt; - begin paragraph
        <li>&lt;p class="italic"&gt; - begin italic paragraph
        <li>&lt;p class="indent"&gt; - begin indented paragraph
        <li>&lt;/p&gt; - end paragraph
        <li>&lt;i&gt; &lt;/i&gt; - italic
        <li>&lt;b&gt; &lt;/b&gt; - bold
        <li>&lt;a href="http://..."&gt; &lt;/a&gt; - link
        </ul>

        <p><a href="http://www.publicwhip.org.uk/forum/viewforum.php?f=2">Discuss this
with other motion text editors on our forum</a>.

        
<?
        }

    }
}
else
{
    login_screen();
}

?> 
<?php include "../footer.inc" ?>
