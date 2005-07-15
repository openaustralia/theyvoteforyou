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
    require_once "constituencies.inc";
    include "render.inc";
    include "dream.inc";
    include_once "account/user.inc";
    $dbo = new DB();
    $db = new DB();
	global $bdebug;

	update_dreammp_votemeasures($db, null, 0); # for all

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

    $query = "SELECT name, description, pw_dyn_user.user_id AS user_id,
					 user_name, pw_dyn_dreammp.rollie_id,
					 votes_count AS count, edited_motions_count,
                	 round(100 * edited_motions_count / votes_count, 0) AS motions_percent
        	  FROM pw_dyn_dreammp
			  LEFT JOIN pw_dyn_user
			  			ON pw_dyn_user.user_id = pw_dyn_dreammp.user_id
			  LEFT JOIN pw_cache_dreaminfo
			  			ON pw_cache_dreaminfo.rollie_id = pw_dyn_dreammp.rollie_id
			  WHERE votes_count > 0
			  ORDER BY motions_percent DESC, edited_motions_count DESC, votes_count DESC";
	if ($bdebug == 1)
		print "<h5>$query</h5>\n";
    $dbo->query($query);

    print "<table class=\"mps\">\n";
    print "<tr class=\"headings\">
        <td>Voted</td>
        <td>Motions Edited</td>
        <td>Name</td>
        <td>Made by</td>
        <td>Description</td>
        <td>MP Dists</td>
        </tr>";


    $prettyrow = 0;
    $c = 0;
    while ($row = $dbo->fetch_row_assoc())
    {
        $prettyrow = pretty_row_start($prettyrow);
        $dreamid = $row['rollie_id'];

        if (user_isloggedin())
            $your_dmp = ($row['user_id'] == user_getid());
        else
            $your_dmp = false;

        print "<td>" . $row['count'] . "</td>\n";
        print "<td>" . percentise($row['motions_percent']) . "</td>";
        print "<td><a href=\"dreammp.php?id=$dreamid\">" . soft_hyphen($row['name'],25) . "</a></td>";
        print "<td>" . html_scrub($row['user_name']) . "</td>";
        print "<td>" . trim_characters(str_replace("\n", "<br>", html_scrub($row['description'])), 0, 150);
        if ($your_dmp) {
            print " [<a href=\"account/editdream.php?id=$dreamid\">Edit...</a>]";
        }
        print "</td>";
        print "<td>0&nbsp;<img src=\"dreamplot.php?id=$dreamid\">&nbsp;1";
        print "</td>\n";

        print "</tr>";
        $c++;
    }
    print "</table>\n";
    print "That makes $c Dream MPs who have voted at least once.";

?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
