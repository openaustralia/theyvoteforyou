<?php

# $Id: divisionvote.inc,v 1.33 2010/04/07 17:55:42 publicwhip Exp $
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
    $policyname = html_scrub($row["name"]);

    # See if changeable
    $legacydreammp = ($row["private"] == 1);
    $votechangeable = user_getid() && (!$legacydreammp || ($row["user_id"] == user_getid()));


    # Election? 
    if (policy_totally_frozen($voter)) {
        $votechangeable = false;
    }

    # a submit was posted on this page
    $voteannouce = "";
    if (mysql_real_escape_string($_POST["submit"]) && $votechangeable)
    {
        $newbvote = mysql_real_escape_string($_POST["vote$voter"]);
        #print "newbvote, bvote: $newbvote $bvote";
        if ($newbvote != $bvote)
        {
            # these are caching notifications
            notify_dream_mp_updated($db, intval($voter));

            global $domain_name;
            $forum_division_link = $divattr["house"] . " division " .
                $divattr['division_date'] . " #".$divattr['division_number'] . ", " .
                " [url=http://$domain_name/division.php?date=".
                $divattr["division_date"]."&number=".$divattr['division_number']."&house=".$divattr["house"].
                "&dmp=".$voter."]".$divattr["name"]."[/url]";
            $forum_policy_link = "[url=http://$domain_name/policy.php?id=$voter]".$policyname."[/url]";

            # set the query that deletes, inserts, or changes the vote
            if ($newbvote == "--")
            {
                $query = "DELETE FROM pw_dyn_dreamvote
                          WHERE dream_id=$voter AND $qdivmatch";
                dream_post_forum_action($db, $voter, "Stopped voting in $forum_division_link.");
                divisionvote_post_forum_action($db, $divattr['division_date'], $divattr['division_number'], 
                    $divattr['house'], "$forum_policy_link policy stopped voting in this division.");
            }
            elseif ($bvote == "--")
            {
                $query = "INSERT INTO pw_dyn_dreamvote
                            (vote, dream_id, division_date, division_number, house)
                          VALUES
                            ('$newbvote', $voter, '".$divattr["division_date"]."', ".$divattr["division_number"].", '".$divattr["house"]."')";
                dream_post_forum_action($db, $voter, "Voted $newbvote in $forum_division_link.");
                divisionvote_post_forum_action($db, $divattr['division_date'], $divattr['division_number'], 
                    $divattr['house'], "$forum_policy_link policy voted $newbvote in this division.");
            }
            else
            {
                $query = "UPDATE pw_dyn_dreamvote
                          SET vote='$newbvote'
                          WHERE dream_id=$voter AND $qdivmatch";
                dream_post_forum_action($db, $voter, "Changed vote from $bvote to $newbvote in $forum_division_link.");
                divisionvote_post_forum_action($db, $divattr['division_date'], $divattr['division_number'], 
                    $divattr['house'], "$forum_policy_link policy changed vote from $bvote to $newbvote in this division.");
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
        print "<FORM CLASS=\"policyvote\" ACTION=\"".$divattr["divhref"]."&display=policies&dmp=$voter\" METHOD=\"POST\"> ";
    if ($votechangeable)
        print ' <strong>Please read policy definition and division description before altering vote</strong> <br>';
    print "And policy ";
    print "<a href=\"policy.php?id=$voter\">$policyname</a>";
    if ($votechangeable)
        print ' (<a href="/policies.php">change</a>)';
    if ($legacydreammp)
        print " (legacy Dream MP)";
    if ($votechangeable)
        print " voted \n";

    if ($votechangeable)
        print " <select name=\"vote$voter\" size=\"1\">
                    <option " . vote_value("--", $bvote) . ">Non-voter</option>
                    <option " . vote_value("aye3", $bvote) . ">Aye (strong)</option>
                    <option " . vote_value("aye", $bvote) . ">Aye</option>
                    <option " . vote_value("both", $bvote) . ">Abstain</option>
                    <option " . vote_value("no", $bvote) . ">No</option>
                    <option " . vote_value("no3", $bvote) . ">No (strong)</option>
                </select>";
    elseif ($bvote == "--")
        print " did not vote.";
    else
        print " voted '$bvote'";

    if ($votechangeable) {
        print '<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Update"> '.$voteannouce.'</FORM>';
    }
    print "</p>\n";

    return ($bvote == "--" ? "" : $bvote);
}

# Post action made to division into the forum for record keeping, notification etc.
function divisionvote_post_forum_action($db, $date, $number, $house, $content) {
    $forum = "Division Forum";
    $topic_match = ucfirst($house) . " $date #$number";
    $motion_data = get_wiki_current_value("motion", array($date, $number, $house));
	$name = extract_title_from_wiki_text($motion_data['text_body']);
    $topic = $topic_match . " - " . $name;
    forummagic_post($db, $forum, $topic_match, $topic, $content);
}

# Get link to forum 
function divisionvote_post_forum_link($db, $date, $number, $house) {
    $forum = "Division Forum";
    $topic_match = ucfirst($house) . " $date #$number";
    return forummagic_getlink($db, $forum, $topic_match);
}

?>
