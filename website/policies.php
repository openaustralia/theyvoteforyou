<?php require_once "common.inc";
    # $id: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

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

    $title = "Policies";
    include "header.inc";
?>
<p>Policies are stated positions on a particular issue. For example "Privatise
the NHS", or "Join the Euro". Each policy has a definition and a way to
vote in relevant divisions in Parliament.
 
   <p><a href="account/addpolicy.php">Make a new policy
   <br><a href="http://www.publicwhip.org.uk/forum/viewforum.php?f=1">Discuss policies on our forum</a>
  <?php
        if (!user_isloggedin())
        {
            print "(you will need to log in or register)";
        }
    ?>
    </a>

   <p>This table summarises all policies, including how many times they have
   "voted".  Click on their name to get a comparison of a policy to all MPs.
   <b>You can get a policy to the top by editing and
   correcting motion text for its divisions.</b> </p>
<?php

    $query = "SELECT name, description, pw_dyn_user.user_id AS user_id,
					 user_name, pw_dyn_dreammp.dream_id,
					 votes_count AS count, edited_motions_count,
                	 round(100 * edited_motions_count / votes_count, 0) AS motions_percent
        	  FROM pw_dyn_dreammp
			  LEFT JOIN pw_dyn_user
			  			ON pw_dyn_user.user_id = pw_dyn_dreammp.user_id
			  LEFT JOIN pw_cache_dreaminfo
			  			ON pw_cache_dreaminfo.dream_id = pw_dyn_dreammp.dream_id
			  WHERE votes_count > 0 AND NOT private
			  ORDER BY motions_percent DESC, edited_motions_count DESC, votes_count DESC";
	if ($bdebug == 1)
		print "<h5>$query</h5>\n";
    $dbo->query($query);

    print "<table class=\"mps\">\n";
    print "<tr class=\"headings\">
        <td>Voted</td>
        <td>Motions Edited</td>
        <td>Name</td>
        <td>Definition</td>
        <!--<td>MP Dists</td>-->
        </tr>";


    $prettyrow = 0;
    $c = 0;
    while ($row = $dbo->fetch_row_assoc())
    {
        $prettyrow = pretty_row_start($prettyrow);
        $dreamid = $row['dream_id'];

        print "<td>" . $row['count'] . "</td>\n";
        print "<td>" . percentise($row['motions_percent']) . "</td>";
        print "<td><a href=\"policy.php?id=$dreamid\">" . soft_hyphen($row['name'],25) . "</a></td>";
        print "<td>" . trim_characters(str_replace("\n", "<br>", html_scrub($row['description'])), 0, 150);
        print "</td>";
        #print "<td>0&nbsp;<img src=\"dreamplot.php?id=$dreamid\">&nbsp;1";
        #print "</td>\n";

        print "</tr>";
        $c++;
    }
    print "</table>\n";
    print "That makes $c policies which have voted in at least one division.";

?>

<?php include "footer.inc" ?>
