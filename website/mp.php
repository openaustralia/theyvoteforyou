<?php include "cache-begin.inc"; ?>
<?php 
    # $Id: mp.php,v 1.13 2003/10/21 18:16:18 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "parliaments.inc";
    $db = new DB(); 

    $first_name = db_scrub($_GET["firstname"]);
    $last_name = db_scrub($_GET["lastname"]);
    $constituency = db_scrub($_GET["constituency"]);

    $show_all = false;
    if ($_GET["showall"] == "yes")
        $show_all = true;
    $all_friends = false;
    if ($_GET["allfriends"] == "yes")
        $all_friends = true;

    $title .= html_scrub("$first_name $last_name, $constituency");
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

    print "<h2>General Information</h2>
        <p>Periods of continuous office for this MP with their rebellion and
        division attendance rates.
        Read a <a href=\"faq.php#clarify\">clear explanation</a> 
        of these terms, as they may not have the meanings you expect.";
    $prettyrow = 0;
    $mp_ids = array();
    $parties = array();
    $dates = array();
    print "<table><tr class=\"headings\">
            <td>Party</td>
            <td>From</td><td>To</td>
            <td>Rebellions</td><td>Attendance</td>
            </tr>";
    while ($row = $db->fetch_row())
    {
        $prettyrow = pretty_row_start($prettyrow);
        $row[6] = percentise($row[6]);
        $row[7] = percentise($row[7]);
        if ($row[12] == "9999-12-31") { $row[12] = "still in office"; }
        print "
            <td>" . pretty_party($row[4]) . "</td>
            <td>$row[11]</td>
            <td>$row[12]</td>
            <td class=\"percent\">$row[8] out of $row[9], $row[6]</td>
            <td class=\"percent\">$row[9] out of $row[10], $row[7]</td>
            ";
        print "</tr>\n";
        array_push($mp_ids, $row[5]);
        array_push($parties, $row[4]);
        array_push($dates, $row[11]);
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
            $query .= "and vote <> whip_guess and whip_guess <> 'unknown' and vote <> 'both'";
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

    $this_anchor = "mp.php?firstname=" . urlencode($first_name) .
        "&lastname=" . urlencode($last_name) . "&constituency=" .
        urlencode($constituency);
    if (!$show_all)
        print "<p><a href=\"$this_anchor&showall=yes\">Show all divisions this MP voted in</a>";
    else
        print "<p><a href=\"$this_anchor\">Show only divisions MP rebelled in</a>";

    print "<h2>Possible Friends</h2>";
    print "<p>Shows which MPs voted most similarly to this one. The
    distance is measured from 0 (always voted the same) to 1 (always
    voted differently).  Only divisions that both MPs voted in are
    counted.  This may reveal relationships between MPs that were
    previously unsuspected.  Or it may be nonsense.";

    for ($i = 0; $i < count($mp_ids); ++$i)
    {
        print "<h3>" . parliament_name(date_to_parliament($dates[$i])) .  " Parliament</h3>";
        print "<table class=\"mps\">\n";
        $query = "select first_name, last_name, title, constituency,
            party, pw_mp.mp_id, 
            round(100*rebellions/votes_attended,1),
            round(100*votes_attended/votes_possible,1),
            distance, entered_reason, left_reason from pw_mp,
            pw_cache_mpinfo, pw_cache_mpdist where
            pw_mp.mp_id = pw_cache_mpinfo.mp_id and 

            (pw_mp.mp_id = pw_cache_mpdist.mp_id_1
            and pw_cache_mpdist.mp_id_2 = $mp_ids[$i]
            and pw_cache_mpdist.mp_id_1 <> $mp_ids[$i])
            ";

        print "<tr class=\"headings\"><td>Name</td><td>Constituency</td><td>Party</td><td>Distance</td><td>Rebellions</td><td>Attendance</td></tr>";
        $prettyrow = 0;

        $db->query($query . " and distance = 0");
        $same_voters = $db->rows();

        $limit = "";
        if (!$all_friends)
            $limit .= " limit 0,5"; 
        $db->query($query . " order by distance $limit");

        while ($row = $db->fetch_row())
        {
            $prettyrow = pretty_row_start($prettyrow);
            $anchor = "\"mp.php?firstname=" . urlencode($row[0]) .
                "&lastname=" . urlencode($row[1]) . "&constituency=" .
                urlencode($row[3]) . "\"";
            if ($row[8] == "0")
                $row[8] = "0 (always vote same)";
            if ($row[8] == "1")
                $row[8] = "1 (always vote different)";

            print "<td><a href=$anchor>$row[2] $row[0] $row[1]</a></td>
                <td>$row[3]</td>
                <td>" . pretty_party($row[4], $row[9], $row[10]) . "</td>
                <td>$row[8]</td>";

            $row[6] = percentise($row[6]);
            $row[7] = percentise($row[7]);
            print "<td class=\"percent\">$row[6]</td>";
            print "<td class=\"percent\">$row[7]</td>";
            print "</tr>\n";
        }
        if ($db->rows() == 0)
        {
            $prettyrow = pretty_row_start($prettyrow, "");
            print "<td colspan=6>no votes to compare</td></tr>\n";
        }
        print "</table>\n";
        if (!$all_friends)
        {
            print "<p><a href=\"$this_anchor&allfriends=yes\">Show all MPs in order of friendliness to this one</a>";
            if ($same_voters > 4)
                print " ($same_voters MPs voted exactly the same as this one)";
        }
        else
        {
            print "<p><a href=\"$this_anchor\">Show only a few possible friends</a>";
        }
    }
?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
