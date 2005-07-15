<?php 
    $dreamid = intval($_GET["id"]);
    $cache_params = "id=$dreamid";
    include "cache-begin.inc"; 

    # $dreamid: dreammp.php,v 1.4 2004/04/16 12:32:42 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
    require_once "constituencies.inc";
    include "dream.inc";
    $db = new DB(); 

    $query = "select name, description, pw_dyn_user.user_id, user_name 
        from pw_dyn_dreammp, pw_dyn_user
        where pw_dyn_dreammp.user_id = pw_dyn_user.user_id and dream_id = '$dreamid'";
    $row = $db->query_one_row($query);
    $dmp_name = $row[0];
    $dmp_description = $row[1];
    $dmp_user_id = $row[2];
    $dmp_user_name = $row[3];

    $title = "'" . html_scrub($dmp_name) . "' - Dream MP";
    include "s8-header.inc";

    #print "User of MP: $dmp_user_id Your id: " . user_getid() . " Name: ". user_getname();
    $your_dmp = false;

    print '<p><a href="#divisions">Divisions Attended</a>';
	print ' | ';
	print '<a href="#comparison">Comparison to Real MPs</a>';

    print "<p><b>Description:</b> " . str_replace("\n", "<br>", html_scrub($dmp_description)). "</p>";
    print "<p><b>Made by:</b> " . html_scrub($user_name) . "</p>";
    if ($your_dmp)
    {
        print "<p><a href=\"http://www.publicwhip.org.uk/account/editdream.php?id=$dreamid\">Edit name/description of this dream MP</a>";
        print "<br><a href=\"http://www.publicwhip.org.uk/account/adddream.php\">Make a new dream MP</a>";
    }
    else
        print "<p><a href=\"http://www.publicwhip.org.uk/account/adddream.php\">Make your own dream MP</a>";
        print "<br><a href=\"http://www.publicwhip.org.uk/dreammps.php\">See all dream MPs</a>";

    print "<h2><a name=\"divisions\">Divisions Attended</a></h2>
    <p>Divisions in which this dream MP has voted."; 

    print "<table>\n";
    # Table of votes in each division
    $query = "select pw_division.division_id, pw_division.division_number, pw_division.division_date,
        division_name, source_url, vote from pw_division,
        pw_dyn_dreamvote where pw_dyn_dreamvote.dream_id = '$dreamid' and
        pw_division.division_date = pw_dyn_dreamvote.division_date and 
        pw_division.division_number = pw_dyn_dreamvote.division_number ";

    $query .= "order by division_date desc, division_number desc";
    $db->query($query);

    print "<tr class=\"headings\">
    <td>No.</td><td>Date</td><td>Subject</td>
    <td>Dream Vote</td>
    <td>Debate</td></tr>";
    $prettyrow = 0;
    $rollievote = array();
    while ($row = $db->fetch_row())
    {
        $rollievote[$row[0]] = $row[5];
        $prettyrow = pretty_row_start($prettyrow);
        $vote = $row[5];
        if ($vote == "both")
            $vote = "abstain";
        print "<td>$row[1]</td> <td>$row[2]</td> <td><a
            href=\"http://www.publicwhip.org.uk/division.php?date=" . urlencode($row[2]) . "&number=" . urlencode($row[1]) . "\">$row[3]</a></td>
            <td>$vote</td>
            <td><a href=\"$row[4]\">Hansard</a></td>"; 
        print "</tr>\n";
    }

    if ($db->rows() == 0)
    {
        $prettyrow = pretty_row_start($prettyrow, "");
        print "<td colspan=7>this virtual MP has not yet voted in any divisions</td></tr>\n";
    }
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
    $query = "select first_name, last_name, title, constituency,
        party, pw_mp.mp_id as mp_id,
        entered_reason, left_reason, entered_house, left_house from pw_mp ";
    $query .= " where " . parliament_query_range($parliament);
    $query .= "order by rand()";

	$db->query($query);

    print "<table class=\"mps\">\n";
    print "<tr class=\"headings\">";
    print "<td>Rank</td><td>Name</td><td>Constituency</td><td>Party</td><td colspan=2>'" . html_scrub($dmp_name) . "'<br>agreement score</td>";
    print "</tr>";

    $prettyrow = 0;
    $rowarray = $db->fetch_rows_assoc();
    foreach ($rowarray as $key=>$copy_row)
    {
        $row =& $rowarray[$key]; # so we can modify $row values
        $ret  = calc_dream_mp_score($db, $dreamid, $row['mp_id']);
        $row['score'] = $ret[0];
        $row['scoremax'] = $ret[1];
    }

    function sortbyscore($row1, $row2)
    {
        // First compare percentage (allow for n/a when MP has never voted in
        // same division as dream MP)
        if ($row1['scoremax'] == 0)
            $frac1 = 0; // change to -1 to put n/a at end
        else
            $frac1 = $row1['score'] / $row1['scoremax'];
        if ($row2['scoremax'] == 0)
            $frac2 = 0; // change to -1 to put n/a at end
        else
            $frac2 = $row2['score'] / $row2['scoremax'];
        if ($frac1 <> $frac2)
            return $frac1 < $frac2;
        
        // Then compare absolute (so it is better to have voted lots and
        // agreed, than a little and agreed)
        if ($row1['score'] <> $row2['score'])
            return $row1['score'] < $row2['score'];

        // Then reverse compare number of disagreed votes
        // so 0 of 1 is better than 0 of 10
        if ($row1['scoremax'] - $row1['score'] <> $row2['scoremax'] - $row2['score'])
            return ($row1['scoremax'] - $row1['score']) > ($row2['scoremax'] - $row2['score']);

        // Arbitarily sort after that
        if ($row1['last_name'] <> $row2['last_name'])
            return strcmp($row1['last_name'], $row2['last_name']);
        
        if ($row1['first_name'] <> $row2['first_name'])
            return strcmp($row1['first_name'], $row2['first_name']);
        
        if ($row1['constituency'] <> $row2['constituency'])
            return strcmp($row1['constituency'], $row2['constituency']);

        if ($row1['party'] <> $row2['party'])
            return strcmp($row1['party'], $row2['party']);

        
    }

    usort($rowarray, sortbyscore);

    $rank = 0;
    $userank = -1;
    $prevscore = "";
    foreach ($rowarray as $row)
    {
        $rank += 1;

        $score = $row['score'] . " of ". $row['scoremax'];
        if ($score != $prevscore)
            $userank = $rank;
        $prevscore = $score;

        $perc = percentise(make_percent($row['score'], $row['scoremax']));
        
        $prettyrow = pretty_row_start($prettyrow);

        print "<td>" . $userank . "</td>";
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
    print "took $timetook from $timestart $timenow";
    
?>

<?php include "s8-footer.inc" ?>
<?php include "cache-end.inc"; ?>
