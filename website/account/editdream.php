<?php require_once "../common.inc";

# $dreamid: editdream.php,v 1.1 2004/04/16 13:38:56 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('../database.inc');
include_once('user.inc');
include "../db.inc";
include "../cache-tools.inc";

$db = new DB(); 
$just_logged_in = do_login_screen();

if (user_isloggedin()) # User logged in, show settings screen
{
    $title = "Modify Your Dream MP"; 
    include "../header.inc";

    $dreamid=db_scrub($_GET["id"]);
    
    $name=db_scrub($_POST["name"]);
    $description=db_scrub($_POST["description"]);
    $submit=db_scrub($_POST["submit"]);

    $query = "select name, description, user_id from pw_dyn_rolliemp where rollie_Id = '$dreamid'";
    $row = $db->query_one_row($query);
    if (!$name)
        $name = $row[0];
    if (!$description)
        $description = $row[1];
    $user_id = $row[2];

    if (user_getid() != $user_id)
    {
        print "<p>This is not your Dream MP, so you can't edit their name or description.";
    }
    else
    {
        $ok = false;
        if ($submit && (!$just_logged_in)) 
        {
            if ($name == "" or $description == "")
                $feedback = "Please name your dream MP, and give a description.";
            else
            {
                $db = new DB(); 

                cache_delete("dreammp.php", "id=" . intval($dreamid));
                cache_delete("dreammps.php", "");
                # delete cache pages of divisions which print name of this rolliemp
                $query = "select pw_division.division_number, pw_division.division_date
                    from pw_division, pw_dyn_rollievote where
                    pw_dyn_rollievote.rolliemp_id = '$dreamid' and
                    pw_division.division_date = pw_dyn_rollievote.division_date and 
                    pw_division.division_number = pw_dyn_rollievote.division_number group
                    by division_number, division_date";
                $ret = $db->query($query);
                while ($row = $db->fetch_row()) {
                    cache_delete("division.php", "#date=".$row[1]."#div_no=".$row[0]."#*");
                }

                $ret = $db->query_errcheck("update pw_dyn_rolliemp set name='$name', description='$description' where rollie_id='$dreamid'");

                if ($ret)
                {
                    $ok = true;
                    $feedback = "Successfully edited dream MP '" . html_scrub($name) . "'.  
                     To see the changes, go to <a href=\"../dreammp.php?id=$dreamid\">your
                     dream MP's page</a>.";
                    audit_log("Edited description dream MP '" . $name . "'");
                }
                else
                {
                    $feedback = "Failed to edit dream MP. " . mysql_error();
                }
            }
        }

        if ($feedback && (!$just_logged_in)) {
            if ($ok)
            {
                echo "<p>$feedback</p>";
            }
            else
            {
                echo "<div class=\"error\"><h2>Modifying your dream MP not complete, please try again
                    </h2><p>$feedback</div>";
            }
        }
        else
        {
            print "<p>Here you change the name or description of your dream
            MP.";

        }

        if (!$ok)
        {
        ?>
            <P>
            <FORM ACTION="editdream.php?id=<?=$dreamid?>" METHOD="POST">
            <B>Name (the name of your organisation or the issue your dream MP votes on behalf of):</B><BR>
            <INPUT TYPE="TEXT" NAME="name" VALUE="<?=html_scrub($name)?>" SIZE="40" MAXLENGTH="50">
            <P>
            <B>Description (the criteria you will use to choose how your dream MP votes, give as much detail as possible):</B><BR>
            <textarea name="description" rows="6" cols="80"><?=html_scrub($description)?></textarea></p>

            <p><INPUT TYPE="SUBMIT" NAME="submit" VALUE="Edit Dream MP">
            </FORM>
        <?php
        }
    }
}
else
{
    login_screen();
}
?>

<?php include "../footer.inc" ?>
