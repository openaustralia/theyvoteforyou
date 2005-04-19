<?php
# $Id: wiki.inc,v 1.4 2005/04/19 00:23:26 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# Gather information from the database

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# Returns label wiki code uses for motion text of particular division
function get_motion_wiki_key($date, $div_no)
{
    return "motion-$date-$div_no";
}

# Returns key, date, number triple or false if key isn't a motion-key
function get_motion_from_key($key) {
    preg_match("/^motion-(\d\d\d\d-\d\d-\d\d)-(\d+)$/",$key, $matches);
    return $matches;
}

# Puts the demarking text MOTION EFFECT etc. round body text
function add_motion_missing_wrappers($text_body, $division_name) {
    # Put wrappers on if they are not there
    if (!preg_match("/--- MOTION EFFECT ---/s", $text_body)) {
        $text_body = 
            "--- MOTION EFFECT ---\n\n" . $text_body .
            "\n--- COMMENTS AND NOTES ---\n\n(put thoughts and notes for other researchers here)\n";
    }
    if (!preg_match("/--- DIVISION TITLE ---/s", $text_body)) {
        $text_body = 
            "--- DIVISION TITLE ---\n\n" . $division_name . "\n\n" . $text_body;
    }
    return $text_body;
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
        list($motion, $division_name) = get_motion_default_values($matches[1], $matches[2]);
        if (!$result) {
            $result = array(
                'text_body' => $motion,
                'edit_date' => $matches[1],
                'user_id' => 0
            );
        }
        $result['text_body'] = add_motion_missing_wrappers($result['text_body'], $division_name);
    } else {
        die("Unknown wiki key type '" . html_scrub($key). "'");
    }
    return $result;
}

# Call this to get motion from wiki text for display
function extract_motion_text_from_wiki_text($text)
{
    if (preg_match("/--- MOTION EFFECT ---(.*)--- COMMENT/s", $text, $matches)) {
        $motion = $matches[1];
    }
    $motion = guy2html(guy_strip_bad($motion));

    return $motion;
}

# Call this to get title from wiki text for display
function extract_title_from_wiki_text($text)
{
    if (preg_match("/--- DIVISION TITLE ---(.*)--- MOTION EFFECT/s", $text, $matches)) {
        $title = $matches[1];
    }
    $title = trim(strip_tags($title));

    return $title;
}

# Returns a list of: 
#  the default text for a motion, 
#  the default title of the motion. 
# In both cases, that is what was screen scraped originally.  
function get_motion_default_values($date, $div_no)
{
    global $db;
    $db->query("select motion, division_name from pw_division 
        where division_date = '$date' and division_number = '$div_no'");
    if ($db->rows() >= 1) {
        $row = $db->fetch_row_assoc();
        $motion = $row['motion'];
        $motion = str_replace(' class=""', '', $motion);
        $motion = str_replace(' pwmotiontext="yes"', '', $motion);
        return array($motion, $row['division_name']);
    }

    die("Couldn't find motion text for division " . htmlspecialchars($date) . " " . htmlspecialchars($div_no));
}

# Makes sure the wiki_id value is up to date in pw_cache_divwiki for every
# division.
function update_divisions_wiki_id($db)
{
    $result = $db->query("INSERT INTO pw_cache_divwiki
        SELECT pw_division.division_date AS division_date, pw_division.division_number AS division_number,
                       IFNULL(MAX(pw_dyn_wiki.wiki_id), -1) AS value
        FROM pw_division
        LEFT JOIN pw_cache_divwiki ON pw_division.division_date = pw_cache_divwiki.division_date AND
            pw_division.division_number = pw_cache_divwiki.division_number
        LEFT JOIN pw_dyn_wiki ON pw_dyn_wiki.object_key =
            concat('motion-', pw_division.division_date, '-', pw_division.division_number)
        WHERE pw_cache_divwiki.wiki_id IS NULL
        GROUP BY pw_division.division_id
    ");
}

?>
