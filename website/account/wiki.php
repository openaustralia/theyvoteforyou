<?php
# $Id: wiki.php,v 1.1 2005/01/15 15:08:03 frabcus Exp $
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
    
    if ($submit && (!$just_logged_in))
    {
        $db->query_errcheck("insert into pw_dyn_wiki 
            (object_key, text_body, user_id, edit_date) values
            ('$key', '$newtext', '" . user_getid() . "', now())");
        audit_log("Edited wiki text '" . $key . "'");
        $matches = null;
        if (preg_match("/^motion-(\d\d\d\d-\d\d-\d\d)-(\d+)$/",$key, $matches)) {
            cache_delete("division.php", "#date=".$matches[1]."#div_no=".$matches[2]."#*");
        }
        header("Location: ". $r);
        exit;
    }
    else 
    {
        $title = "Edit Text"; 
        include "../header.inc";

        $values = get_wiki_current_value($key);
        
        if (strstr($key, "motion-")) {
?>
        <p>Please describe the <i>effect</i> of the division.  This will require some
        research, carefully reading the debate.  The raw motion text is there by default,
        but feel free to remove it and explain it if that will make things
        clearer.  If there are relevant bills or committee pages, provide links
        to them.</p>

        <p>Overall, we are aiming for a factual description of the effect of
        the motion, so that a general reader looking at the division page could
        work out what is going on.
        
        <p><b>Motion text:</b>
<?
        }

?>
        <P>
        <FORM ACTION="<?=$REQUEST_URI?>" METHOD="POST">
        <textarea name="newtext" rows="20" cols="80"><?=html_scrub($values['text_body'])?></textarea>
        <p><INPUT TYPE="SUBMIT" NAME="submit" VALUE="Save">
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
