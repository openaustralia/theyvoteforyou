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
    include "dream.inc";
    include_once "account/user.inc";
    $dbo = new DB(); 
    $db = new DB(); 

    check_table_cache_all_dream_mps($db);

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
   <br><a href="http://www.publicwhip.org.uk/forum/viewforum.php?f=1">Discuss dream MPs on our forum</a>
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
   a Dream MP to all Real MPs.  </p>
   <p><b>You can get your Dream MP to the top by editing and
   correcting motion text for its divisions.</b> </p>
<?php

    print "<table class=\"mps\">\n";
    print "<tr class=\"headings\">
        <td>Voted</td>
        <td>Edited Motions</td>
        <td>Name</td>
        <td>Made by</td>
        <td>Description</td>
        </tr>";

    $query = "select name, description, pw_dyn_user.user_id as user_id, user_name,
                pw_dyn_rolliemp.rollie_id, votes_count as count, edited_motions_count,
                round(100 * edited_motions_count / votes_count, 1) as motions_percent
        from pw_dyn_rolliemp, pw_dyn_user, pw_cache_dreaminfo where 
            pw_dyn_rolliemp.user_id = pw_dyn_user.user_id and
            pw_cache_dreaminfo.rollie_id = pw_dyn_rolliemp.rollie_id 
            order by motions_percent desc, edited_motions_count desc, votes_count desc";
    $dbo->query($query);

    $prettyrow = 0;
    while ($row = $dbo->fetch_row_assoc())
    {
        $prettyrow = pretty_row_start($prettyrow);
        $dreamid = $row['rollie_id'];

        if (user_isloggedin())
            $your_dmp = ($row['user_id'] == user_getid());
        else
            $your_dmp = false;

        print "<td>" . $row['count'] . "</td>\n";
        print "<td>" . percentise($row['motions_percent']) . "</td>\n";
        print "<td><a href=\"dreammp.php?id=$dreamid\">" . $row['name'] . "</a></td>";
        print "<td>" . html_scrub($row['user_name']) . "</td>";
        print "<td>" . trim_characters(str_replace("\n", "<br>", html_scrub($row['description'])), 0, 300); 
        if ($your_dmp) {
            print " [<a href=\"account/editdream.php?id=$dreamid\">Edit...</a>]";
        }
        print "</td></tr>";
    }
    print "</table>\n";

?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
