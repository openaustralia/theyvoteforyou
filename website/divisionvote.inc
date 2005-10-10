<?php

# $Id: divisionvote.inc,v 1.18 2005/10/10 23:52:23 goatchurch Exp $
# Handles the dreammp vote on the divisions page

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# Dream MP feature
function vote_value($value, $curr)
{
    $ret = "value=\"" . html_scrub($value) . "\" ";
    if ($value == $curr)
    {
        $ret .= "selected ";
    }
    return $ret;
}

# the generated table on the division page
function write_single_policy_vote($db, $divattr, $voter)
{
    global $bdebug;

    $qdivmatch = "division_date = '".$divattr["division_date"]."'
                  AND division_number = ".$divattr["division_number"];

    # get the value from the database
    $query = "SELECT vote FROM pw_dyn_dreamvote
              WHERE dream_id = $voter AND $qdivmatch";
    $row = $db->query_onez_row_assoc($query);
    $vote = ($row ? $row["vote"] : "");
    $bvote = (!$vote ? "--" : $vote); # blank space filled

    # get the type of dream mp we have here
    $query = "SELECT name, private, user_id FROM pw_dyn_dreammp WHERE dream_id = $voter";
    $row = $db->query_one_row_assoc($query);
    $legacydreammp = $row["private"];
    $votechangeable = !$legacydreammp or $row["user_id"] == user_getid();
    $policyname = html_scrub($row["name"]);

    # See if changeable
    $legacydreammp = $row["private"];
    $votechangeable = user_getid() && (!$legacydreammp || ($row["user_id"] == user_getid()));

    # a submit was posted on this page
    $voteannouce = "";
    if (mysql_escape_string($_POST["submit"]) && $votechangeable)
    {
        $newbvote = mysql_escape_string($_POST["vote$voter"]);
        #print "newbvote, bvote: $newbvote $bvote";
        if ($newbvote != $bvote)
        {
            # these are caching notifications
            notify_dream_mp_updated($db, intval($voter));

            # set the query that deletes, inserts, or changes the vote
            if ($newbvote == "--")
            {
                $query = "DELETE FROM pw_dyn_dreamvote
                          WHERE dream_id=$voter AND $qdivmatch";
            }
            elseif ($bvote == "--")
            {
                $query = "INSERT INTO pw_dyn_dreamvote
                            (vote, dream_id, division_date, division_number)
                          VALUES
                            ('$newbvote', $voter, '".$divattr["division_date"]."', ".$divattr["division_number"].")";
            }
            else
            {
                $query = "UPDATE pw_dyn_dreamvote
                          SET vote='$newbvote'
                          WHERE dream_id=$voter AND $qdivmatch";
            }
            $vchange = ($newbvote == "--" ? "non-voter" : $newbvote);

            if ($bdebug == 1)
                print "<h2>$query</h2>";
            $db->query($query);

            if ($db->rows() == 0)
                print "Error changing $policyname to $vchange (no change)";
            elseif ($db->rows() > 1)
                print "Error changing $policyname to $vchange (too many rows)";
            audit_log("Changed '$policyname' to $vchange for division ".$divattr["division_date"]." ".$divattr["division_no"]);

            $voteannouce = "<span class=\"error\">Changed from ".($bvote == "--" ? "non-voter" : $bvote)."</span>";
            $bvote = $newbvote;
        } else {
            $voteannouce = "<span class=\"error\">No change made</span>";
        }
    }

    # display dream MP vote
    print "<p>";
    if ($votechangeable)
        print "<FORM ACTION=\"".$divattr["divhref"]."&dmp=$voter\" METHOD=\"POST\">";
    print "<a href=\"policy.php?id=$voter\">$policyname</a>";
    if ($legacydreammp)
        print " (legacy Dream MP)";
    if ($votechangeable)
        print ": \n";

    if ($votechangeable)
        print " <select name=\"vote$voter\" size=\"1\">
                    <option " . vote_value("--", $bvote) . ">Non-voter</option>
                    <option " . vote_value("aye3", $bvote) . ">Aye 3-Line</option>
                    <option " . vote_value("aye", $bvote) . ">Aye</option>
                    <option " . vote_value("both", $bvote) . ">Abstain</option>
                    <option " . vote_value("no", $bvote) . ">No</option>
                    <option " . vote_value("no3", $bvote) . ">No 3-Line</option>
                </select>";
    elseif ($bvote == "--")
        print " did not vote.";
    else
        print " voted '$bvote'";

    if ($votechangeable)
        print '<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Update"> '.$voteannouce.
            '<a href="/policies.php">(change active policy)</a></FORM>';
    print "</p>\n";

    return ($bvote == "--" ? "" : $bvote);
}


?>
