<?php
# $Id: gather.inc,v 1.3 2005/01/14 20:36:08 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# Gather information from the database

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under

# Returns label wiki code uses for motion text of particular division
function get_motion_wiki_key($date, $div_no)
{
    return "motion-$date-$div_no";
}

# Returns current value of wiki text based on a key.  Return value
# is a hash with text_body, user_id, edit_date.
function get_wiki_current_value($key) 
{
    $matches = array();
    if (preg_match("/^motion-(\d\d\d\d-\d\d-\d\d)-(\d+)$/",$key, $matches)) {
        return get_motion_text($matches[1], $matches[2]);
    }
}

# Returns the most recent edited wiki text for motion, or the default
# text.  Return value is a hash with keys text_body, user_id, edit_date.
# user_id is 0 if this text has never been edited.
function get_motion_text($date, $div_no)
{
    $extra = array('help_pre' => "Motion text:");

    global $db;
    $key = get_motion_wiki_key($date, $div_no);
    $db->query("select text_body, user_id, edit_date from 
        pw_dyn_wiki where object_key = '$key' order by wiki_id desc limit 1");
    if ($db->rows() >= 1) {
        $row = $db->fetch_row_assoc();
        return array_merge($extra, $row);
    }

    $db->query("select motion from pw_division 
        where division_date = '$date' and division_number = '$div_no'");
    if ($db->rows() >=1) {
        $row = $db->fetch_row_assoc();
        $result = array(
            'text_body' => $row['motion'],
            'edit_date' => $date,
            'user_id' => 0
        );
        $result['text_body'] = str_replace(' class=""', '', $result['text_body']);
        $result['text_body'] = str_replace(' pwmotiontext="yes"', '', $result['text_body']);
        $result['text_body'] = "--- MOTION EFFECT ---\n\n" . $result['text_body'] .
            "\n--- COMMENTS AND NOTES ---\n\n(put thoughts and notes for other researchers here)\n";
        return array_merge($extra, $result);
    }

    die("Couldn't find motion text for division " . htmlspecialchars($date) . " " . htmlspecialchars($div_no));
}

# used for the party tables in mp votes, and the printer friendly mp dump
function GetPartyVoteSummary($db, $div_id)
{
    $db->query("select pw_mp.party, count(*), vote, whip_guess from pw_vote,
        pw_mp, pw_cache_whip where pw_vote.division_id = $div_id and
        pw_vote.mp_id = pw_mp.mp_id and pw_cache_whip.division_id =
        pw_vote.division_id and pw_cache_whip.party = pw_mp.party group
        by pw_mp.party, vote order by party, vote");

    # Precalc values
    $ayes = array();
    $noes = array();
    $boths = array();
    $tellayes = array();
    $tellnoes = array();
    $whips = array();
	$totalpartyvote = array();

    while ($row = $db->fetch_row())
    {
        $party = $row[0];
        $count = $row[1];
        $vote = $row[2];
        $whip = $row[3];

		$totalpartyvote[$party] += $count;

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
    $votes = array_sum(array_values($ayes)) +
        array_sum(array_values($noes)) + array_sum(array_values($boths)) +
        array_sum(array_values($tellayes)) + array_sum(array_values($tellnoes));

	$partysummary = array('ayes' => $ayes, 'noes' => $noes, 'boths' => $boths,
						  'tellayes' => $tellayes, 'tellnoes' => $tellnoes, 'whips' => $whips,
						  'votes' => $votes, 'totalpartyvote' => $totalpartyvote);
	return $partysummary;
}

?>
