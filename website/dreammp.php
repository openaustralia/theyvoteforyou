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
    #include_once "account/user.inc";

    check_table_cache_dream_mp($db, $dreamid);
    $query = "SELECT name, description, pw_dyn_user.user_id, user_name,
				votes_count, edited_motions_count
        	  FROM pw_dyn_rolliemp, pw_dyn_user, pw_cache_dreaminfo
			  WHERE pw_dyn_rolliemp.user_id = pw_dyn_user.user_id
				AND pw_cache_dreaminfo.rollie_id = pw_dyn_rolliemp.rollie_id
				AND pw_cache_dreaminfo.rollie_id = '$dreamid'";
	if ($bdebug == 1)
		print "<h3>$query</h3>\n";
    $row = $db->query_one_row($query);
    $dmp_name = $row[0];
    $dmp_description = $row[1];
    $dmp_user_id = $row[2];
    $dmp_user_name = $row[3];
    $dmp_votes_count = $row[4];
    $dmp_edited_count = $row[5];

    $title = "'" . html_scrub($dmp_name) . "' - Dream MP";
    include "header.inc";

    #print "User of MP: $dmp_user_id Your id: " . user_getid() . " Name: ". user_getname();
    if (user_isloggedin())
        $your_dmp = ($dmp_user_id == user_getid());
    else
        $your_dmp = false;

    print '<p><a href="#divisions">Divisions Attended</a>';
	print ' | ';
	print '<a href="#comparison">Comparison to Real MPs</a>';

    print "<p><b>Description:</b> " . str_replace("\n", "<br>", html_scrub($dmp_description)). "</p>";
    print "<p><b>Made by:</b> " . html_scrub($dmp_user_name) . ". ";
    print "</p>";
    if ($your_dmp)
    {
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
			"headings"		=> 'columns');
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

    $timestart = getmicrotime();

    print "<h2><a name=\"comparison\">Comparison to Real MPs</a></h2>";
    print "<p>Grades MPs acording to how often they voted the same as the dream
    MP.  If, in divisions where both voted, they always voted the same then
    the score is 100%.  If they always voted differently, the score is 0%.";

    $now = strftime("%Y-%m-%d");
    $query = "select first_name, last_name, title, constituency,
        party, pw_mp.mp_id as mp_id, pw_mp.person,
        entered_reason, left_reason, entered_house, left_house,
        score_a, scoremax_a, rank_a, rank_outof_a
        from pw_mp, pw_cache_dreamreal_score
        where pw_mp.person = pw_cache_dreamreal_score.person
        and pw_cache_dreamreal_score.rollie_id = '$dreamid'";
    $query .= " and rank_outof_a is not null
        and left_house > '$now'
        order by rank_a";
    $row = $db->query($query);

    print "<table class=\"mps\">\n";
    print "<tr class=\"headings\">";
    print "<td>Rank</td><td>Name</td><td>Constituency</td><td>Party</td><td colspan=2>'" . html_scrub($dmp_name) . "'<br>agreement score</td>";
    print "</tr>";

    $prettyrow = 0;
    while ($row = $db->fetch_row_assoc())
    {
        $rank = $row['rank_a']; # . "/" . $row['rank_outof_a'];
        $score = $row['score_a'] . " of ". $row['scoremax_a'];
        $perc = percentise(make_percent($row['score_a'], $row['scoremax_a']));
        $prettyrow = pretty_row_start($prettyrow);

        print "<td>" . $rank . "</td>";
        print "<td>" . set_mp_with_link($row) . "</td></td>
            <td>" . $row['constituency'] . "</td>
            <td>" . set_party($row). "</td>
            <td>" . $score . "</td>
            <td class=\"percent\">" . $perc . "</td>";
        print "</tr>\n";
    }

    print "</table>\n";

    $timenow = getmicrotime();
    $timetook = $timenow - $timestart;
//    print "took $timetook from $timestart $timenow";

?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>

