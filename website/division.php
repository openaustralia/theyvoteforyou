<?php include "cache-begin.inc"; ?>
<?php
# $Id: division.php,v 1.15 2003/11/05 17:25:06 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    $db = new DB(); 

    $date = db_scrub($_GET["date"]);
    $div_no = db_scrub($_GET["number"]);

    $show_all = false;
    if ($_GET["showall"] == "yes")
        $show_all = true;

    $row = $db->query_one_row("select pw_division.division_id, division_name,
            source_url, rebellions, turnout, notes, motion from pw_division,
            pw_cache_divinfo where pw_division.division_id =
            pw_cache_divinfo.division_id and division_date = '$date'
            and division_number='$div_no'");
    $div_id = $row[0];
    $name = $row[1];
    $source = $row[2];
    $rebellions = $row[3];
    $turnout = $row[4];
    $notes = $row[5];
    $motion = $row[6];
    $prettydate = date("j M Y", strtotime($date));
    $div_no = html_scrub($div_no);

    $title = "$name - $prettydate - Division No. $div_no";
    include "header.inc";

    print "<h2>Summary</h2>";

    $ayes = $db->query_one_value("select count(*) from pw_vote
        where division_id = $div_id and vote = 'aye'");
    $noes = $db->query_one_value("select count(*) from pw_vote
        where division_id = $div_id and vote = 'no'");
    $boths = $db->query_one_value("select count(*) from pw_vote
        where division_id = $div_id and vote = 'both'");
    $tellers = $db->query_one_value("select count(*) from pw_vote
        where division_id = $div_id and (vote = 'tellaye' or vote = 'tellno')");
    print "<br>Turnout of $turnout. Votes were $ayes aye, $noes no, $boths both, $tellers tellers.  Guess $rebellions rebellions.";
    print "<br><a href=\"$source\">Read the full debate leading up to this division (on Hansard website)</a>";
    print "$notes";
    
    print "<h2>Motion</h2> <p>Procedural text extracted from the debate.
    This is for guidance only, irrelevant text may be shown, crucial
    text may be missing.  Check Hansard thoroughly and have knowledge of
    parliamentary procedure to fully understand the meaning of the
    division.
    </p>";
    print "<div class=\"motion\">$motion";
    print "</div>\n";

    # Work out proportions for party voting (todo: cache)
    $db->query("select party, total_votes from pw_cache_partyinfo");
    $alldivs = array();
    while ($row = $db->fetch_row())
    {
        $alldivs[$row[0]] = $row[1];
    }
    $alldivs_total = array_sum(array_values($alldivs));

    # Table of votes by party
    $db->query("select pw_mp.party, count(*), vote, whip_guess from pw_vote,
        pw_mp, pw_cache_whip where pw_vote.division_id = $div_id and
        pw_vote.mp_id = pw_mp.mp_id and pw_cache_whip.division_id =
        pw_vote.division_id and pw_cache_whip.party = pw_mp.party group
        by pw_mp.party, vote order by party, vote");
    print "<h2>Party Summary</h2>";
    print "<p>Votes by party, red entries are votes against the majority for that party.  ";
    print "
    <div class=\"tableexplain\">
    <span class=\"ptitle\">What is Tell?</span> 
    '+1 tell' means that in addition one member of that party was a
    teller for that division lobby. Tellers are usually whips, or else
    particularly support the vote they tell for.</p>
    <p>
    <span class=\"ptitle\">What are Boths?</span> An MP can vote both
    aye and no in the same division. The <a href=\"boths.php\">boths
    page</a> explains this, and lists all cases of it happening.
    <p>
    <span class=\"ptitle\">What is Abstain?</span> Abstentions are
    calculated from the expected turnout, which is statistical based on
    the average proporionate turnout for that party in all divisions. A
    negative abstention indicates that more members of that party than
    expected voted; this is always relative, so it could be that another
    party has failed to turn out <i>en masse</i>.</p>
    </div>";

    # Precalc values
    $ayes = array();
    $noes = array();
    $boths = array();
    $tellayes = array();
    $tellnoes = array();
    $whips = array();
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $party = $row[0];
        $count = $row[1];
        $vote = $row[2];
        $whip = $row[3];

        if ($vote == "aye")
        {
            $ayes[$party] += $count;
        }
        else if ($vote == "no")
        {
            $noes[$party] += $count;
        }
        else if ($vote == "both")
        {
            $boths[$party] += $count;
        }
        else if ($vote == "tellaye")
        {
            $tellayes[$party] += $count;
        }
        else if ($vote == "tellno")
        {
            $tellnoes[$party] += $count;
        }
        else
        {
            print "Unknown vote type: " + $vote;
        }

        $whips[$party] = $whip;
    }

    # Make table
    print "<table><tr class=\"headings\"><td>Party</td><td>Ayes</td><td>Noes</td>";
    print "<td>Both</td>";
#    print "<td>Tell<br>Ayes</td><td>Tell<br>Noes</td>";
    print "<td>Turnout</td>";
    print "<td>Expected</td><td>Abstain</td></tr>";
    $allparties = array_keys($alldivs);
    usort($allparties, strcasecmp);
    $votes = array_sum(array_values($ayes)) +
        array_sum(array_values($noes)) + array_sum(array_values($boths)) +
        array_sum(array_values($tellayes)) + array_sum(array_values($tellnoes));
    if ($votes <> $turnout)
    {
        print "<p>Error $votes <> $turnout\n";
    }
    foreach ($allparties as $party)
    {
        $aye = $ayes[$party];
        $no = $noes[$party];
        $both = $boths[$party];
        $tellaye = $tellayes[$party];
        $tellno = $tellnoes[$party];
        if ($aye == "") { $aye = 0; }
        if ($no == "") { $no = 0; }
        if ($both == "") { $both = 0; }
        $whip = $whips[$party];
        $total = $aye + $no + $both + $tellaye + $tellno;
        $classaye = "normal";
        $classno = "normal";
        if ($whip == "aye") { if ($no + $tellno > 0) { $classno = "rebel";} ;} else { $classno = "whip"; }
        if ($whip == "no") { if ($aye + $tellaye> 0) { $classaye = "rebel";} ;} else { $classaye = "whip"; }

        $classboth = "normal";
        if ($both > 0) { $classboth = "important"; }

        $alldiv = $alldivs[$party];
        $expected = round($votes * ($alldiv / $alldivs_total), 0);
        $abstentions = round($expected - $total, 0);
        $classabs = "normal";
        if (abs($abstentions) >= 2) { $classabs = "important"; }
        
        if ($tellaye > 0 or $tellno > 0 or $aye > 0 or $no > 0 or $both > 0 or $abstentions >= 2)
        {
            if ($tellaye > 0)
                $aye .= " (+" . $tellaye . " tell)";
            if ($tellno > 0)
                $no .= " (+" . $tellno . " tell)";

            $prettyrow = pretty_row_start($prettyrow);        
            print "<td>" . pretty_party($party) . "</td>";
            print "<td class=\"$classaye\">$aye</td>";
            print "<td class=\"$classno\">$no</td>";
            print "<td class=\"$classboth\">$both</td>";
#            print "<td>$tellaye</td>";
 #           print "<td>$tellno</td>";
            print "<td>$total</td>";
            print "<td>$expected</td>";
            print "<td class=\"$classabs\">$abstentions</td>";
            print "</tr>";
        }
    }
    print "</table>";

    # Table of MP votes
    $query = "select first_name, last_name, title, pw_mp.party,
        vote, pw_mp.mp_id, whip_guess, constituency from pw_vote, pw_mp,
        pw_cache_whip where pw_vote.division_id = $div_id and
        pw_vote.mp_id = pw_mp.mp_id and pw_cache_whip.division_id =
        $div_id and pw_cache_whip.party = pw_mp.party ";
    if (!$show_all)
    {
        $query .= "and whip_guess <> 'unknown' and vote <> 'both' and
                whip_guess <> replace(vote, 'tell', '')";
    }
    $query .= "order by party, last_name, first_name desc";
    $db->query($query);

    if (!$show_all)
    {
        print "<h2>Rebel Voters</h2>
        <p>MPs for which their vote in this division differed from
        the majority vote of their party.";
    }
    else
    {
        print "<h2>Vote List</h2>
            <p>Vote of each MP. Those where they voted differently from
            the majority in their party are marked in red.";
    }

    print "<table class=\"votes\"><tr class=\"headings\"><td>MP</td><td>Constituency</td><td>Party</td><td>Vote</td></tr>";
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $class = "";
        if ($showall && $row[6] != $row[4] && $row[6] <> "unknown" && $row[4] <> "both")
        {
            $class = "rebel";
        }
        $prettyrow = pretty_row_start($prettyrow, $class);
        print "<td><a href=\"mp.php?firstname=" . urlencode($row[0]) .
            "&lastname=" . urlencode($row[1]) . "&constituency=" .
            urlencode($row[7]) . "\">$row[2] $row[0] $row[1]</a></td>
            <td>$row[7]</td><td>" . pretty_party($row[3]) . "</td><td>$row[4]</td>";
        print "</tr>";
    }
    if ($db->rows() == 0)
    {
        $prettyrow = pretty_row_start($prettyrow, "");
        print "<td colspan=4>no rebellions</td></tr>\n";
    }
    print "</table>";

    $anchor = "division.php?date=" . urlencode($date) .
        "&number=" . urlencode($div_no);
    if (!$show_all)
    {
        $anchor .= "&showall=yes";
        print "<p><a href=\"$anchor\">Show all MPs who voted in this division</a>";
    }
    else
    {
        print "<p><a href=\"$anchor\">Show only MPs who rebelled in this division</a>";
    }

?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
