<?php require_once "../common.inc";
# $Id: wiki.php,v 1.18 2005/10/19 23:42:24 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('../database.inc');
include_once('user.inc');

include "../db.inc";
include "../cache-tools.inc";
include "../wiki.inc";
$db = new DB(); 

$just_logged_in = do_login_screen();

if (user_isloggedin()) # User logged in, show settings screen
{
    $type = db_scrub($_GET["type"]);
    if ($type == 'motion')
        $params = array(db_scrub($_GET["date"]), db_scrub($_GET["number"]), db_scrub($_GET["house"]));
    else
        trigger_error("Unknown wiki type " . htmlspecialchars($type), E_USER_ERROR);

    $newtext = db_scrub($_POST["newtext"]);
    $submit = db_scrub($_POST["submit"]);
    $r = db_scrub($_GET["r"]);

    $db->query("select * from pw_division where division_date = '$params[0]' 
        and division_number = '$params[1]' and house = '$params[2]'");
    $division_details = $db->fetch_row_assoc();
    $prettydate = date("j M Y", strtotime($params[0]));
    $title = "Edit Division Description - " . $division_details['division_name'] . " - $prettydate - Division No. $params[1]";
    $debate_gid = str_replace("uk.org.publicwhip/debate/", "", $division_details['debate_gid']);
    
    if ($submit && (!$just_logged_in))
    {
        if ($submit == "Save") {
            $db->query_errcheck("insert into pw_dyn_wiki_motion
                (division_date, division_number, house, text_body, user_id, edit_date) values
                ('$params[0]', '$params[1]', '$params[2]', '$newtext', '" . user_getid() . "', now())");
            audit_log("Edited $type wiki text $params[0] $params[1] $params[2]");
            if ($type == 'motion') {
                notify_motion_updated($db, $params[0], $params[1], $params[2]);
            }
        }
        header("Location: ". $r);
        exit;
    }
    else
    {
        include "../header.inc";

        $values = get_wiki_current_value($type, $params);

        if ($type == 'motion') {
?>
        <p>Describe the <i>result</i> of this division.  This will require you
        to check through the debate leading up to the vote.
        The raw, and frequently
        wrong, motion text is there by default.  Feel free to remove it when
        you've replaced it with something better. </p>

        <p>Please, keep it accurate, authorative, and as jargon-free as
        possible so that new readers who don't know Parliamentary procedure can
        gain enlightenment. You are urged to include hyperlinks to the
        legislation, command papers, reports, and committee
        proceedings that are referred to so that readers who want to follow the
        story further will know where to look.</p>

		<p>Links that may be of use: 
		<ul>
<?
        if ($debate_gid != "") {
            print "<li><a href=\"http://www.theyworkforyou.com/debates/?id=$debate_gid\">The debate</a> leading up to the vote</li>";
        } else {
            print "<li>Warning: old division; need to make hyperlink to old Parl data from division details</li>";
        }
?>
		<li><a href="http://www.publications.parliament.uk/pa/pabills.htm">Public Bills before Parliament</a> 
		(the link gets deleted from here once the next version is printed, though the page remains.)</li>
		<li><a href="http://www.publications.parliament.uk/pa/cm/stand.htm">Standing Committees reviewing Bills</a></li>
		<li><a href="http://www.publications.parliament.uk/pa/cm/cmdeleg.htm">Standing Committees on delegated legislation</a></li>
		<li><a href="http://www.official-documents.co.uk/menu/browseDocuments.htm">Command Papers</a> Back to 2002, and in pdf</li>
		</ul>


        <!-- use tables here as textarea style width=64% behaves differently on IE vs. Firefox) -->
        <table border="0" width="100%">
        <tr>

        <td width="64%" valign="top">
        <p><b>Edit division title and description:</b>
<?
        }

?>
        <P>
        <FORM ACTION="<?=$REQUEST_URI?>" METHOD="POST">
        <textarea name="newtext" style="width: 100%" rows="25" cols="45"><?=html_scrub($values['text_body'])?></textarea>
        <p>
        <INPUT TYPE="SUBMIT" NAME="submit" VALUE="Save">
        <INPUT TYPE="SUBMIT" NAME="submit" VALUE="Cancel">
        </FORM>
        </P>
<?
        if ($type == 'motion') {
?>
        <p><a href="<?=get_wiki_history_link($type, $params)?>">View change history</a>

<?
        }
?>
        </td>

      <td width="3%">&nbsp;</td>
        
      <td width="33%" valign="top">

        <p><b>Editing tips:</b></p>

        <p><span class="ptitle">Separators</span>. Leave the "DIVISION TITLE", "MOTION EFFECT" and "COMMENTS AND NOTES"
        in place, so our computer knows how to break it up.
		If you don't want to delete text, move it out of the way below "COMMENTS AND NOTES"
		where it will be hidden.</p>

        <p><span class="ptitle">Questions, thoughts?</span>
        <a href="/forum/viewforum.php?f=2">Discuss</a>
		with other motion researchers on our special forum. (especially when we get the deep link working).

        <p><span class="ptitle">Allowable HTML tags</span>. You can use the following:
        <ul>
        <li>&lt;p&gt; - begin paragraph
        <li>&nbsp;&lt;p class="italic"&gt; - begin italic paragraph
        <li>&nbsp;&lt;p class="indent"&gt; - begin indented paragraph
        <li>&lt;/p&gt; - end paragraph
        <li>&lt;i&gt; &lt;/i&gt; - italic
        <li>&lt;b&gt; &lt;/b&gt; - bold
        <li>&lt;a href="http://..."&gt; &lt;/a&gt; - link
        </ul>

        </td>

 

        </tr></table>
<?

    }
}
else
{
    login_screen();
}

?> 
<?php include "../footer.inc" ?>
