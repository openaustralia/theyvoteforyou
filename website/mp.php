<?php require_once "common.inc";
    # $Id: mp.php,v 1.44 2005/01/22 14:54:11 goatchurch Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "cache-begin.inc";

    include "db.inc";
    include "parliaments.inc";
    include "constituencies.inc";
    $db = new DB();

    $first_name = db_scrub($_GET["firstname"]);
    $last_name = db_scrub($_GET["lastname"]);
    # The consmatch converts constituency to canonical form as it comes in
    $constituency = $_GET["constituency"];
    $constituency = $consnames[$consmatch[strtolower(stripslashes(html_entity_decode($constituency)))]];
    $constituency = db_scrub($constituency);
    $id = db_scrub($_GET["id"]);
    if ($constituency == "" and $id == "") {
        print "Error, constituency " . $_GET["constituency"] . " not found";
        exit;
    }

    $show_all = false;
    if ($_GET["showall"] == "yes")
        $show_all = true;
    $all_friends = false;
    if ($_GET["allfriends"] == "yes")
        $all_friends = true;
    $expand = false;
    if ($_GET["expand"] == "yes")
        $expand = true;

	if ($constituency == "")
	{
		$id = str_replace("uk.org.publicwhip/member/", "", $id);
		$query = "select first_name, last_name, constituency
			from pw_mp where mp_id = '$id'
			order by entered_house desc limit 1";
		$row = $db->query_one_row($query);
		$first_name = db_scrub($row[0]);
		$last_name = db_scrub($row[1]);
		$constituency = db_scrub($row[2]);
	}
	else
	{
		$query = "select first_name, last_name, mp_id
			from pw_mp where constituency = '$constituency'
			order by entered_house desc limit 1";
		$row = $db->query_one_row($query);
		$first_name = db_scrub($row[0]);
		$last_name = db_scrub($row[1]);
		$id = db_scrub($row[2]);
	}
	# find the person code for this mp
	$row = $db->query_one_row("SELECT person, party FROM pw_mp WHERE pw_mp.mp_id = $id");
	$person = $row[0];
	$party = $row[1];

    $this_anchor = "mp.php?id=".urlencode($id);

    $title = html_scrub("Voting Record - $first_name $last_name MP, $constituency");
    include "header.inc";

	print '<p>';
	print '<a href="#divisions">Interesting Divisions</a>';
	print ' | ';
	print '<a href="#friends">Possible Friends</a>';
	print ' | ';
	print '<a href="#wrans">Written Answers</a>';

?>

<?
 	$query = "select dept, position, from_date, to_date
        from pw_moffice where pw_moffice.person = '$person'
        order by from_date desc";
    $db->query($query);
    $prettyrow = 0;
    $events = array();
    $now = strftime("%Y-%m-%d");
    $currently_minister = "";
    while ($row = $db->fetch_row_assoc())
    {
        if ($row["from_date"] <= $now && $now <= $row["to_date"]) 
        {
            $currently_minister = $row["position"].  ", " .  $row["dept"];
        }
        if ($row["to_date"] != "9999-12-31")
        {
            array_push($events, array($row["to_date"], "Stopped being " .  $row["position"].  ", " . $row["dept"]));
        }
        array_push($events, array($row["from_date"], "Became " .  $row["position"]. ", " . $row["dept"]));
    }
?>

<?
	$query = "select first_name, last_name, title, constituency,
        party, pw_mp.mp_id, round(100*rebellions/votes_attended,1),
        round(100*votes_attended/votes_possible,1), 
        rebellions, votes_attended, votes_possible,
        entered_house, left_house,
        entered_reason, left_reason,
        tells, person from pw_mp,
        pw_cache_mpinfo where
        pw_mp.mp_id = pw_cache_mpinfo.mp_id and ";
    $query .= "first_name = '$first_name' and last_name='$last_name' and";
    $query .= " constituency = '$constituency' order by entered_house desc";
    $db->query($query);

    print "<h2><a name=\"general\">General Information</a></h2>";

    if ($currently_minister) 
    {
        print "<p><b>$first_name $last_name</b> is currently <b>$currently_minister</b>.<br>
            MP for <b>$constituency</b> during the following periods of time during the last two
            parliaments:<br>
            Read a <a href=\"faq.php#clarify\">clear explanation</a> of attendance
            and rebellions, as they may not have the meanings you expect.";
    }
    else
    {
        print "<p><b>$first_name $last_name</b> has been MP for <b>$constituency</b> during
            the following periods of time during the last two
            parliaments:<br>
            Read a <a href=\"faq.php#clarify\">clear explanation</a> of attendance
            and rebellions, as they may not have the meanings you expect.";
    }

    $prettyrow = 0;
    $mp_ids = array();
    $parties = array();
    $from_dates = array();
    $to_dates = array();
    $enter_reason = array();
    $left_reason = array();
    $person = 0;
    print "<table><tr class=\"headings\">";
    print "<td>Party</td>
            <td>From</td><td>To</td>
            <td>Rebellions (estimate)</td><td>Attendance (divisions)</td>
            <td>Teller</td></tr>";
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
            <td class=\"percent\">$row[8] votes out of $row[9], $row[6]</td>
            <td class=\"percent\">$row[9] votes out of $row[10], $row[7]</td>
            <td>$row[15] times</td>
            ";
        print "</tr>\n";
        array_push($mp_ids, $row[5]);
        array_push($parties, $row[4]);
        array_push($from_dates, $row[11]);
        array_push($to_dates, $row[12]);
        array_push($enter_reason, $row[13]);
        array_push($left_reason, $row[14]);
        $person = $row[16];
    }
    print "</table>";

    print "<p>";
    print "<a href=\"http://www.theyworkforyou.com/mp/?m=" .  $mp_ids[0]. "\">";
    print "Performance data, recent speeches, and biographical links</a> ";
    print "at TheyWorkForYou.com.";
    print "<br>Contact your MP with 
    <a href=\"http://www.faxyourmp.com\">Fax Your MP</a> for free.  Find
    the <a
    href=\"http://www.parliament.uk/directories/hciolists/alms.cfm\">email
    address</a> of some MPs.";

?>


<?php
    if (!$show_all)
    {
        print "<h2><a name=\"divisions\">Interesting Divisions</a></h2>
        <p>Votes in parliament for which this MP's vote differed from the
        majority vote of their party (Rebel), or in which this MP was
        a teller (Teller) or both (Rebel Teller).  ";
        print "You can also <a href=\"$this_anchor&showall=yes#divisions\">see all divisions this MP voted in</a>.";
    }
    else
    {
        print "<h2><a name=\"divisions\">Divisions Attended</a></h2>
        <p>Divisions in which this MP voted.  The first column
        indicates if they voted against the majority vote of 
        their party (Rebel), were a teller for that side (Teller)
        or both (Rebel Teller). "; 
    }
    print " Also shows when the MP became or stopped
        being a paid minister. ";

    function print_event($event)
    {
        global $prettyrow;
        $prettyrow = pretty_row_start($prettyrow);
        print "<td>&nbsp;</td><td>&nbsp;</td>";
        print "<td>" . $event[0] . "</td>";
        print "<td colspan=7>" . $event[1] .  "</td></tr>\n";
    }

    print "<table>\n";
    $events_ix = 0;
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
            $query .= "and ((vote <> whip_guess and whip_guess <>
            'unknown' and vote <> 'both') or vote = 'tellaye' or vote = 'tellno' )";
        }
        $query .= "order by division_date desc, division_number desc";
        $db->query($query);

        print "<tr class=\"headings\">
        <td>Role</td>
        <td>No.</td><td>Date</td><td>Subject</td>
        <td>Vote</td><td>$parties[$i] Vote</td>
        <td>Debate</td></tr>";
        $prettyrow = 0;
        while ($row = $db->fetch_row())
        {
            while ($events_ix < count($events) && $row[2] <= $events[$events_ix][0]) {
                print_event($events[$events_ix]);
                $events_ix ++;
            }

            $class = "";
            $votedesc = "";
            if ($row[6] != "unknown")
            {
                $detelled = $row[5];
                if ($detelled == "tellaye") $detelled = "aye";
                if ($detelled == "tellno") $detelled = "no";

                if ($detelled != $row[6])
                {
                    $class .= "rebel";
                    $votedesc = "Rebel";
                }
                if ($row[5] == "tellaye" || $row[5] == "tellno")
                {
                    $class .= "teller";
                    if ($votedesc == "Rebel")
                        $votedesc = "Rebel Teller";
                    else
                        $votedesc = "Teller";
                }
            }
            if ($votedesc == "")
                $votedesc = "Loyal";

            $prettyrow = pretty_row_start($prettyrow);
            print "<td class=\"$class\">$votedesc</td>";
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
            if ($show_all)
                print "<td colspan=7>no votes</td></tr>\n";
            else
                print "<td colspan=7>no rebellions, never teller</td></tr>\n";
        }
    }
    while ($events_ix < count($events))
    {
        print_event($events[$events_ix]);
        $events_ix ++;
    }
    print "</table>\n";

    if (!$show_all)
        print "<p><a href=\"$this_anchor&showall=yes#divisions\">Show all divisions this MP voted in</a>";
    else
        print "<p><a href=\"$this_anchor#divisions\">Show only divisions MP rebelled in</a>";

    print "<h2><a name=\"friends\">Possible Friends</a></h2>";
    print "<p>Shows which MPs voted most similarly to this one. The
    distance is measured from 0 (always voted the same) to 1 (always
    voted differently).  Only divisions that both MPs voted in are
    counted.  This may reveal relationships between MPs that were
    previously unsuspected.  Or it may be nonsense.";

    for ($i = 0; $i < count($mp_ids); ++$i)
    {
        print "<h3>" . pretty_parliament_and_party($from_dates[$i], $parties[$i], $enter_reason[$i], $left_reason[$i]). "</h3>";
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
            print "<p><a href=\"$this_anchor&allfriends=yes#friends\">Show all MPs in order of friendliness to this one</a>";
            if ($same_voters > 4)
                print " ($same_voters MPs voted exactly the same as this one)";
        }
        else
        {
            print "<p><a href=\"$this_anchor#friends\">Show only a few possible friends</a>";
        }
    }
?>

<?php
	print "<h2><a name=\"wrans\">Written Answers</a></h2>";
    print "<p>Parliamentary written questions which this MP has asked or answered. ";
	print "<br>These are now available from <a href=\"http://www.theyworkforyou.com/search?pid=".urlencode($person).
        "&maj=wrans\">TheyWorkForYou.com</a>.";
    $searchkey = $mp_ids[0];
?>

<?php
    function print_selected_dream($db, $id, $dreammpid)
    {
		// should count overlapping votes between dream and mp
	    $query = "SELECT name, description, rollie_id, user_name, count(pw_dyn_rollievote.vote) as count
		          FROM pw_dyn_rolliemp, pw_dyn_rollievote, pw_dyn_user
				  WHERE pw_dyn_rollievote.rolliemp_id = $dreammpid and pw_dyn_rolliemp.user_id = pw_dyn_user.user_id and pw_dyn_rollievote.rolliemp_id = rollie_id
				  GROUP BY rollie_id
				  ORDER BY count desc";
	    $db->query($query);
	    $row = $db->fetch_row();
		$link = "jmp.php?id=".urlencode($id)."&dreammpid=".urlencode($dreammpid);
        print "<td>$row[4]</td>\n";
        print "<td>".html_scrub($row[3])."</td>\n";
        print "<td><a href=\"$link\">".html_scrub($row[0])."</a></td>\n";
        //print "<td>" . trim_characters(str_replace("\n", "<br>", html_scrub($dmp_description)), 0, 300);
        print "</tr>\n";
    }

	print "<h2><a name=\"dreammotions\">Votes on Motions Chosen by a Dream MP</a></h2>";
    print "<p>Selected list which can be used to find what they stand for. ";
    print "<table>\n";
    print "<tr class=\"headings\">
        <td>Votes</td>
        <td>Author</td>
        <td>Name</td>
        </tr>";

    $prettyrow = 0;
	$prettyrow = pretty_row_start($prettyrow);
    print_selected_dream($db, $id, 219);
    print_selected_dream($db, $id, 223);
    print "</table>\n";
?>


<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
