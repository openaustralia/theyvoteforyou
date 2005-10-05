<?php require_once "common.inc";
    $dreamid = intval($_GET["id"]);

    # $id: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include('database.inc');
    $db = new DB();

	# standard decoding functions for the url attributes
	include "decodeids.inc";
	include "tablemake.inc";

    include "render.inc";
    include "dream.inc";
	include "tablepeop.inc";

	update_dreammp_person_distance($db, $dreamid); # new method

	$qselect = "SELECT pw_dyn_dreammp.name AS name, pw_dyn_dreammp.description AS description,
					   pw_dyn_user.user_id AS user_id, user_name,
					   votes_count, edited_motions_count, consistency_with_mps,
                       private";
	$qfrom	 = " FROM pw_dyn_dreammp";
	$qjoin 	 = " LEFT JOIN pw_cache_dreaminfo ON pw_cache_dreaminfo.dream_id = pw_dyn_dreammp.dream_id";
	$qjoin 	.= " LEFT JOIN pw_dyn_user ON pw_dyn_user.user_id = pw_dyn_dreammp.user_id";
	$qwhere  = " WHERE pw_dyn_dreammp.dream_id = $dreamid";
	$query = $qselect.$qfrom.$qjoin.$qwhere;


	if ($bdebug == 1)
		print "<h3>$query</h3>\n";
    $row = $db->query_one_row_assoc($query);
    $dmp_name = $row["name"];
    $dmp_description = $row["description"];
    $dmp_user_id = $row["user_id"];
    $dmp_user_name = $row["user_name"];
    $dmp_votes_count = $row["votes_count"];
    $dmp_edited_count = $row["edited_motions_count"];
    $dmp_private = $row["private"];

    $title = "Policy - " . html_scrub($dmp_name);
    include "header.inc";

    print "<div class=\"tabledreambox\">";
#    print '<h2><a name="compare">Compare to Your MP</a></h2>';
    print dream_box($dreamid, $dmp_name);
    print '<p>Why not <a href="#dreambox">add this to your own website?</a></p>';
    print "</div>";

    print "<p><b>Definition:</b> " . str_replace("\n", "<br>", html_scrub($dmp_description)). "</p>";
    if ($dmp_private)
        print "<p><b>Made by:</b> " . html_scrub($dmp_user_name) . " (this is a legacy Dream MP)";
    print "</p>";

    print "<p><a href=\"account/editpolicy.php?id=$dreamid\">Edit definition</a>";
    print ' | <a href="http://www.publicwhip.org.uk/forum/viewforum.php?f=1">Discuss</a>';


    print "<h2><a name=\"divisions\">Divisions Selected</a></h2>
    <p>Divisions which have been selected for this policy.";
    if ($dmp_votes_count)
        print " <b>$dmp_votes_count</b> votes, of which <b>$dmp_edited_count</b> have edited motion text.";

    print "<table class=\"divisions\">\n";
	$divtabattr = array(
			"voter1type" 	=> "dreammp",
			"voter1"        => $dreamid,
			"showwhich"		=> "all1",
			"headings"		=> 'columns',
			"motionwikistate" => "listunedited");
	division_table($db, $divtabattr);
    print "</table>\n";

/*    print "You need to select which votes support your policy.
    To do this <a href=\"search.php\">search</a> or <a
    href=\"divisions.php\">browse</a> for divisions.  On the page for each
    division you can choose how someone supporting your policy would have
    voted.  Only vote on divisions which are relevant to your policy."; */

    print "<h2><a name=\"comparison\">Comparison to MPs</a></h2>";

    print "<p>Grades MPs acording to how often they voted with the policy.
            If, in policy divisions where the MP voted, they
            always voted the same as the policy then the score is 0.0.  If they always voted
            differently, the score is 1.0.";

	$mptabattr = array("listtype" => 'dreamdistance',
					   'dreammpid' => $dreamid);
	print "<table class=\"mps\">\n";
	print "<tr class=\"headings\"><td>Name</td><td>Constituency</td><td>Party</td><td>Distance</td></tr>\n";
	mp_table($db, $mptabattr);
	print "</table>\n";


    print '<h2><a name="dreambox">Add Policies to Your Website</a></h2>';
    print '<p>Get people thinking about your issue, by adding a policy search
			box to your website.  This lets people compare their own MP to your policy,
			like this.</p>';
    print dream_box($dreamid, $dmp_name);
    print '<p>To do this copy and paste the following HTML into your website.
			Feel free to fiddle with it to fit the look of your site better.  We only
			ask that you leave the link to Public Whip in.';
    print '<pre class="htmlsource">';
    print htmlspecialchars(dream_box($dreamid, $dmp_name));
    print '</pre>';

?>

<?php include "footer.inc" ?>

