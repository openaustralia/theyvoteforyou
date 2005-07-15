<?php require_once "common.inc";
    $dreamid = intval($_GET["id"]);
    $cache_params = "id=$dreamid";
    include "cache-begin.inc";

    # $dreamid: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

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
					   votes_count, edited_motions_count, consistency_with_mps";
	$qfrom	 = " FROM pw_dyn_dreammp";
	$qjoin 	 = " LEFT JOIN pw_cache_dreaminfo ON pw_cache_dreaminfo.rollie_id = pw_dyn_dreammp.rollie_id";
	$qjoin 	.= " LEFT JOIN pw_dyn_user ON pw_dyn_user.user_id = pw_dyn_dreammp.user_id";
	$qwhere  = " WHERE pw_dyn_dreammp.rollie_id = $dreamid";
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

    $title = "'" . html_scrub($dmp_name) . "' - Dream MP";
    include "header.inc";

    #print "User of MP: $dmp_user_id Your id: " . user_getid() . " Name: ". user_getname();
    if (user_isloggedin())
        $your_dmp = ($dmp_user_id == user_getid());
    else
        $your_dmp = false;

    print "<div class=\"tableexplain\">";
    print '<h2><a name="compare">Compare to Your MP</a></h2><p>';
    print dream_box($dreamid, $dmp_name);
    print '<p>Why not <a href="#dreambox">add this to your own website?</a>';
    print "</div>";

    print '<p><a href="#divisions">Divisions Attended</a>';
	print ' | ';
	print '<a href="#comparison">Comparison to Real MPs</a>';

    print "<p><b>Description:</b> " . str_replace("\n", "<br>", html_scrub($dmp_description)). "</p>";
    print "<p><b>Made by:</b> " . html_scrub($dmp_user_name) . ". ";
    print "</p>";

    if ($your_dmp) {
        print "<p><a href=\"account/editdream.php?id=$dreamid\">Edit name/description of this dream MP</a>";
        print "<br><a href=\"account/adddream.php\">Make a new dream MP</a>";
    }
    else
        print "<p><a href=\"account/adddream.php\">Make your own dream MP</a>";
    print "<br><a href=\"dreammps.php\">See all dream MPs</a>";
    print '<br><a href="http://www.publicwhip.org.uk/forum/viewforum.php?f=1">Discuss dream MP on our forum</a>';


    print "<h2><a name=\"divisions\">Divisions Attended</a></h2>
    <p>Divisions in which this dream MP has voted.";
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

    if ($your_dmp)
    {
        print "You need to choose which divisions your dream MP votes in, and
        how they vote for each one. To do this <a
        href=\"search.php\">search</a> or <a href=\"divisions.php\">browse</a>
        for divisions.  On the page for each division you can choose how your
        made-up MP would have voted.  Only vote on divisions which your MP
        cares about.";

    }


    print "<h2><a name=\"comparison\">Comparison to Real MPs</a></h2>";

    print "<p>Grades MPs acording to how often they voted the same as the dream
	    	MP.  If, in divisions where both voted, they always voted the same then
    		the score is 0.0.  If they always voted differently, the score is 1.0.";

	$mptabattr = array("listtype" => 'dreamdistance',
					   'dreammpid' => $dreamid);
	print "<table class=\"mps\">\n";
	print "<tr class=\"headings\"><td>Name</td><td>Constituency</td><td>Party</td><td>Distance</td></tr>\n";
	mp_table($db, $mptabattr);
	print "</table>\n";


    print '<h2><a name="dreambox">Add Dream MP to Your Website</a></h2>';
    print '<p>Get people thinking about your issue, by adding a Dream MP search
			box to your website.  This lets people compare their own MP to your Dream MP,
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
<?php include "cache-end.inc"; ?>

