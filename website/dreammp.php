<?php 
    # $Id: dreammp.php,v 1.1 2004/02/10 00:18:32 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
    include "constituencies.inc";
    include "xquery.inc";
    include "protodecode.inc";
    include "render.inc";
    include "account/user.inc";
    $db = new DB(); 

    $id = db_scrub($_GET["id"]);

    $query = "select name, description, pw_dyn_user.user_id, user_name, real_name, email
        from pw_dyn_rolliemp, pw_dyn_user
        where pw_dyn_rolliemp.user_id = pw_dyn_user.user_id and rollie_Id = '$id'";
    $row = $db->query_one_row($query);
    $name = $row[0];
    $description = $row[1];
    $user_id = $row[2];
    $user_name = $row[3];
    $real_name = $row[4];
    $email = preg_replace("/(.+)@(.+)/", "email: $2", $row[5]);

    $title = "'" . html_scrub($name) . "' - Roll Your Own MP";
    include "header.inc";

    print '<p><a href="#divisions">Divisions Attended</a>';
	print ' | ';
	print '<a href="#comparison">Comparison to Real MPs</a>';

    print "<p><b>Description:</b> " . html_scrub($description). "</p>";
    print "<p><b>Made by:</b> " . html_scrub($real_name) . " (" . html_scrub($email) . ")</p>";
    if (user_isloggedin())
        print "<p><a href=\"account/adddream.php\">Make a new dream MP</a>";
    else
        print "<p><a href=\"account/adddream.php\">Make your own dream MP</a>";

    print "<h2><a name=\"divisions\">Divisions Attended</a></h2>
    <p>Divisions in which this dream MP voted."; 

    print "<table>\n";
    # Table of votes in each division
    $query = "select pw_division.division_id, pw_division.division_number, pw_division.division_date,
        division_name, source_url, vote from pw_division,
        pw_dyn_rollievote where pw_dyn_rollievote.rolliemp_id = '$id' and
        pw_division.division_date = pw_dyn_rollievote.division_date and 
        pw_division.division_number = pw_dyn_rollievote.division_number ";

    $query .= "order by division_date desc, division_number desc";
    $db->query($query);

    print "<tr class=\"headings\">
    <td>No.</td><td>Date</td><td>Subject</td>
    <td>Vote</td>
    <td>Debate</td></tr>";
    $prettyrow = 0;
    $rollievote = array();
    while ($row = $db->fetch_row())
    {
        $rollievote[$row[0]] = $row[5];
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>$row[1]</td> <td>$row[2]</td> <td><a
            href=\"division.php?date=" . urlencode($row[2]) . "&number=" . urlencode($row[1]) . "\">$row[3]</a></td>
            <td>$row[5]</td>
            <td><a href=\"$row[4]\">Hansard</a></td>"; 
        print "</tr>\n";
    }

    if ($db->rows() == 0)
    {
        $prettyrow = pretty_row_start($prettyrow, "");
        print "<td colspan=7>this virtual MP has not yet voted in any divisions</td></tr>\n";
    }
    print "</table>\n";

    if (user_isloggedin())
    {
        print "To select votes for your virtual MP, <a href=\"search.php\">search</a> or
                <a href=\"divisions.php\">browse</a> for divisions.  On the page for
                each division you can choose how your made-up MP would have voted.  Only vote
                on divisions which your MP cares about.";

    }

    print "<h2><a name=\"comparison\">Comparison to Real MPs</a></h2>";
    print "<p>Grades MPs acording to how often they voted the same as the dream
    MP.  If, in divisions where both voted, they always voted the same then
    the score is 100%.  If they always voted differently, the score is 0%.";
    $query = "select first_name, last_name, title, constituency,
        party, pw_mp.mp_id as mp_id,
        entered_reason, left_reason, entered_house, left_house from pw_mp ";
    $query .= " where entered_house <= '" .
        parliament_date_to($parliament) . "' and entered_house >= '".
        parliament_date_from($parliament) . "' ";
    $query .= "order by rand()";

	$db->query($query);

    print "<table class=\"mps\">\n";
    print "<tr class=\"headings\">";
    print "<td>Name</td><td>Constituency</td><td>Party</td><td colspan=2>'" . html_scrub($name) . "'<br>agreement score</td>";
    print "</tr>";

    $prettyrow = 0;
    $rowarray = $db->fetch_rows_assoc();
    foreach ($rowarray as $key=>$copy_row)
    {
        $row =& $rowarray[$key]; # so we can modify $row values

        $query = "select pw_vote.vote mpvote, pw_dyn_rollievote.vote as rollievote from 
            pw_vote, pw_dyn_rollievote, pw_division where 
            pw_vote.division_id = pw_division.division_id and
            pw_dyn_rollievote.division_number = pw_division.division_number and 
                pw_dyn_rollievote.division_date = pw_division.division_date
            and pw_vote.mp_id = " . $row['mp_id'] . " and pw_dyn_rollievote.rolliemp_id = '$id'";

        $db->query($query);
        $qrowarray = $db->fetch_rows_assoc();
        $t = 0.0;
        $c = 0.0;
        foreach ($qrowarray as $qrow)
        {
            $t++;
            $mpvote = $qrow['mpvote'];
            $mpvote = str_replace("tell", "", $mpvote);
            $rollievote = $qrow['rollievote'];

            if ($mpvote == $rollievote)
                $c++;
            elseif ($mpvote == "both" or $rollievote == "both")
                $c = $c + 0.5;
        }
        $row['score'] = $c;
        $row['scoremax'] = $t;

    }

    function sortbyscore($row1, $row2)
    {
        if ($row1['scoremax'] == 0)
            $frac1 = -1;
        else
            $frac1 = $row1['score'] / $row1['scoremax'];
        if ($row2['scoremax'] == 0)
            $frac2 = -1;
        else
            $frac2 = $row2['score'] / $row2['scoremax'];
        if ($frac1 <> $frac2)
            return $frac1 < $frac2;
        
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

    foreach ($rowarray as $row)
    {
        $score = $row['score'] . " of ". $row['scoremax'];
        $perc = percentise(make_percent($row['score'], $row['scoremax']));
        
        $prettyrow = pretty_row_start($prettyrow);

        print "<td>" . set_mp_with_link($row) . "</td></td>
            <td>" . $row['constituency'] . "</td>
            <td>" . set_party($row). "</td>
            <td>" . $score . "</td> 
            <td class=\"percent\">" . $perc . "</td>";
        print "</tr>\n";
    }

    print "</table>\n";
    
?>

<?php include "footer.inc" ?>

