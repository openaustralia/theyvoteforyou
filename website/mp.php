<?php 
    # $Id: mp.php,v 1.3 2003/09/19 16:06:37 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    $db = new DB(); 

    $first_name = mysql_escape_string($_GET["firstname"]);
    $last_name = mysql_escape_string($_GET["lastname"]);
    $constituency = mysql_escape_string($_GET["constituency"]);

    $show_all = false;
    if (mysql_escape_string($_GET["showall"]) == "yes")
    {
        $show_all = true;
    }

    $title .= "$first_name $last_name, $constituency";
    include "header.inc";
       
    $db->query("select first_name, last_name, title, constituency,
        party, pw_mp.mp_id, round(100*rebellions/votes_attended,1),
        round(100*votes_attended/votes_possible,1), 
        rebellions, votes_attended, votes_possible,
        entered_house, left_house from pw_mp,
        pw_cache_mpinfo where
        pw_mp.mp_id = pw_cache_mpinfo.mp_id and
        first_name = '$first_name' and last_name='$last_name' and
        constituency = '$constituency' 
        order by entered_house desc");

    print "<h2>General Information</h2>";
    $prettyrow = 0;
    $mp_ids = array();
    $parties = array();
    print "<table><tr class=\"headings\">
            <td>Party</td>
            <td>From</td><td>To</td>
            <td>Rebellions</td><td>Attendance</td>
            </tr>";
    while ($row = $db->fetch_row())
    {
        $prettyrow = pretty_row_start($prettyrow);
        if ($row[6] == "") { $row[6] = "n/a"; } else { $row[6] .= "%"; }
        if ($row[12] == "9999-12-31") { $row[12] = "still in office"; }
        print "
            <td>" . pretty_party($row[4]) . "</td>
            <td>$row[11]</td>
            <td>$row[12]</td>
            <td class=\"percent\">$row[8] out of $row[9], $row[6]</td>
            <td class=\"percent\">$row[9] out of $row[10], $row[7]%</td>
            ";
        print "</tr>\n";
        array_push($mp_ids, $row[5]);
        array_push($parties, $row[4]);
    }
    print "</table>";

?>
<?php
    if (!$show_all)
    {
        print "<h2>Rebel Divisions</h2>
        <p>Divisions for which this MP's vote differed from the
        majority vote of their party.";
    }
    else
    {
        print "<h2>Divisions Attended</h2>
        <p>Divisions in which this MP voted.  Those where they
        voted differently from the majority in their party are
        highlighted in red."; 
    }

    print "<table>\n";
    for ($i = 0; $i < count($mp_ids); ++$i)
    {
        # Table of votes in each division
        $query = "select pw_division.division_id, division_number, division_date,
            division_name, source_url, vote, whip_guess, rebellions from pw_division,
            pw_vote, pw_cache_whip, pw_cache_divinfo where pw_vote.mp_id = $mp_ids[$i] and
            pw_division.division_id = pw_vote.division_id and
            pw_cache_whip.division_id = pw_division.division_id and
            pw_cache_divinfo.division_id = pw_division.division_id and
            pw_cache_whip.party = \"$parties[$i]\" ";

        if (!$show_all)
        {
            $query .= "and vote <> whip_guess and whip_guess <> 'unknown' ";
        }
        $query .= "order by division_date desc, division_number desc";
        $db->query($query);

        print "<tr
        class=\"headings\"><td>No.</td><td>Date</td><td>Subject</td>
        <td>Vote</td><td>$parties[$i] Vote</td>
        <td>Debate</td></tr>";
        $prettyrow = 0;
        while ($row = $db->fetch_row())
        {
            $class = "";
            if ($show_all && $row[5] != $row[6] && $row[6] != "unknown")
                $class = "rebel";
            $prettyrow = pretty_row_start($prettyrow, $class);
            print "<td>$row[1]</td> <td>$row[2]</td> <td><a
                href=\"division.php?date=" . urlencode($row[2]) . "&number="
                . urlencode($row[1]) . "\">$row[3]</a></td>
                <td>$row[5]</td><td>$row[6]</td>
                <td><a href=\"$row[4]\">Hansard</a></td>"; 
            print "</tr>\n";
        }
        if ($db->rows() == 0)
        {
            $prettyrow = pretty_row_start($prettyrow, "");
            print "<td colspan=6>no rebellions</td></tr>\n";
        }
    }
    print "</table>\n";

    $anchor = "mp.php?firstname=" . urlencode($first_name) .
        "&lastname=" . urlencode($last_name) . "&constituency=" .
        urlencode($constituency);
    if (!$show_all)
    {
        $anchor .= "&showall=yes";
        print "<p><a href=\"$anchor\">Show all divisions this MP voted in</a>";
    }
    else
    {
        print "<p><a href=\"$anchor\">Show only divisions MP rebelled in</a>";
    }

    print "<h2>Possible Friends</h2>";
    print "<p>Shows which MPs voted most similarly to this one. The
    distance is measured from 0 (always voted the same) to 1 (always
    voted differently).  Only divisions that both MPs voted in are
    counted.  This may reveal relationships between MPs that were
    previously unsuspected.  Or it may be nonsense.";

    print "<table class=\"mps\">\n";
    for ($i = 0; $i < count($mp_ids); ++$i)
    {
        $query = "select first_name, last_name, title, constituency,
            party, pw_mp.mp_id, round(100*rebellions/votes_attended,1),
            round(100*votes_attended/votes_possible,1),
            distance from pw_mp,
            pw_cache_mpinfo, pw_cache_mpdist where
            pw_mp.mp_id = pw_cache_mpinfo.mp_id and 

            ((pw_mp.mp_id = pw_cache_mpdist.mp_id_1
            and pw_cache_mpdist.mp_id_2 = $mp_ids[$i]
            and pw_cache_mpdist.mp_id_1 <> $mp_ids[$i]) or

            (pw_mp.mp_id = pw_cache_mpdist.mp_id_2 and
            pw_cache_mpdist.mp_id_1 = $mp_ids[$i]
            and pw_cache_mpdist.mp_id_2 <> $mp_ids[$i]))

            order by distance limit 0,5";

        $db->query($query);
        print "<tr class=\"headings\"><td>Name</td><td>Constituency</td><td>Party</td><td>Distance</td></tr>";
        $prettyrow = 0;
        while ($row = $db->fetch_row())
        {
            $prettyrow = pretty_row_start($prettyrow);
            $anchor = "\"mp.php?firstname=" . urlencode($row[0]) .
                "&lastname=" . urlencode($row[1]) . "&constituency=" .
                urlencode($row[3]) . "\"";

            print "<td><a href=$anchor>$row[2] $row[0] $row[1]</a></td></td>
                <td>$row[3]</td>
                <td>" . pretty_party($row[4]) . "</td>
                <td>$row[8]</td>";
            print "</tr>\n";
        }
        if ($db->rows() == 0)
        {
            $prettyrow = pretty_row_start($prettyrow, "");
            print "<td colspan=4>no votes to compare</td></tr>\n";
        }
    }
    print "</table>\n";
?>

<?php include "footer.inc" ?>


