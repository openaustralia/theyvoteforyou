<?php require_once "common.inc";
    $cache_params = "";
    include "cache-begin.inc"; 

    # $dreamid: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include('database.inc');
    include "parliaments.inc";
    include "constituencies.inc";
    include "render.inc";
    include_once "account/user.inc";
    $dbo = new DB(); 
    $db = new DB(); 

    $title = "Dream MPs";
    include "header.inc";
?>
<p>Politicians as you want them to be.  A Dream MP can represent anything
you like.  For example:
    <ul>
    <li>Organisation.  e.g. Greenpeace, Confederation of British Industry.
    <li>Single issue campaign.  e.g. Pro-Hunting, Anti-Europe, Anti-Iraq war.
    <li>Political party.  e.g. Labour party whip.
    <li>Prospective parliamentary candidate.  e.g. Tory candidate for Sedgefield.
    <li>Your self.  Issues that you personally care about.
    </ul>
 
   <p><a href="account/adddream.php">Make your own dream MP
  <?php 
        if (!user_isloggedin())
        {
            print "(you will need to log in or register)";
        }
    ?>
    </a>

   <p>These are the Dream MPs people like you have made so far.  This
   table shows who made each MP, what they stand for, and how many times
   they have "voted".  Click on their name to get a comparison of
   a Dream MP to all Real MPs.  Only Dream MPs who have voted are shown.
<?php

    print "<table>\n";
    print "<tr class=\"headings\">
        <td>Voted</td>
        <td>Name</td>
        <td>Made by</td><td>Email</td>
        <td>Description</td>
        </tr>";

    $query = "select name, description, pw_dyn_user.user_id, user_name, real_name, 
                email, rollie_id, count(pw_dyn_rollievote.vote) as count
        from pw_dyn_rolliemp, pw_dyn_user, pw_dyn_rollievote where 
            pw_dyn_rolliemp.user_id = pw_dyn_user.user_id and
            pw_dyn_rollievote.rolliemp_id = rollie_id group by rollie_id order by count desc";
    $dbo->query($query);

    $prettyrow = 0;
    while ($row = $dbo->fetch_row())
    {
        $prettyrow = pretty_row_start($prettyrow);

        $dmp_name = $row[0];
        $dmp_description = $row[1];
        $dmp_user_id = $row[2];
        $dmp_user_name = $row[3];
        $dmp_real_name = $row[4];
        $dmp_email = preg_replace("/(.+)@(.+)/", "$2", $row[5]);
        $dreamid = $row[6];
        $count = $row[7];

        if (user_isloggedin())
            $your_dmp = ($dmp_user_id == user_getid());
        else
            $your_dmp = false;

        print "<td>$count</td>\n";
        print "<td><a href=\"dreammp.php?id=$dreamid\">" . $dmp_name . "</a></td>";

        print "<td>" . html_scrub($dmp_real_name) . "</td>";
        print "<td>" . html_scrub($dmp_email) . "</td>";

        print "<td>" . trim_characters(str_replace("\n", "<br>", html_scrub($dmp_description)), 0, 300); 
        if ($your_dmp) {
            print " [<a href=\"account/editdream.php?id=$dreamid\">Edit...</a>]";
        }
        print "</td>";

        print "</tr>";
    }
    print "</table>\n";

?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
