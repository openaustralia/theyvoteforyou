<?php
# $Id: wiki.inc,v 1.1 2005/03/28 10:06:21 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# Gather information from the database

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under

# Returns label wiki code uses for motion text of particular division
function get_motion_wiki_key($date, $div_no)
{
    return "motion-$date-$div_no";
}

# Returns date, number pair or false if key isn't a motion-key
function get_motion_from_key($key) {
    preg_match("/^motion-(\d\d\d\d-\d\d-\d\d)-(\d+)$/",$key, $matches);
    return $matches;
}

# Returns current value of wiki text based on a key.  Return value
# is a hash with text_body, user_id, edit_date.
function get_wiki_current_value($key) 
{
    # See if page has been altered
    global $db;
    $db->query("select text_body, user_id, edit_date from 
        pw_dyn_wiki where object_key = '$key' order by wiki_id desc limit 1");
    if ($db->rows() >= 1) {
        $result = $db->fetch_row_assoc();
    }

    $matches = array();
    if (preg_match("/^motion-(\d\d\d\d-\d\d-\d\d)-(\d+)$/",$key, $matches)) {
        if (!$result) {
            $result = get_motion_default_text($matches[1], $matches[2]);
        }
        # Put wrapper on if not there
        if (!preg_match("/--- MOTION EFFECT ---/s", $result['text_body'])) {
            $result['text_body'] = "--- MOTION EFFECT ---\n\n" . $result['text_body'] .
                "\n--- COMMENTS AND NOTES ---\n\n(put thoughts and notes for other researchers here)\n";
        }
    } else {
        die("Unknown wiki key type '" . html_scrub($key). "'");
    }
    return $result;
}

# Call this if display the wiki text, as opposed to letting somebody edit it
function sanitise_wiki_text_for_display($text)
{
    if (preg_match("/--- MOTION EFFECT ---(.*)--- COMMENT/s", $text, $matches)) {
        $text = $matches[1];
    }
    $text = guy2html(guy_strip_bad($text));

    return $text;
}

# Returns the default text for a motion, that is what was screen scraped
# originally.  Return value is a hash with keys text_body, user_id, edit_date.
# user_id is 0 as this text has never been edited.
function get_motion_default_text($date, $div_no)
{
    global $db;
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
        return $result;
    }

    die("Couldn't find motion text for division " . htmlspecialchars($date) . " " . htmlspecialchars($div_no));
}

?>
