<?php
# $Id: wiki.inc,v 1.7 2005/10/05 13:53:21 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# Editable text with history

# Types:
# 'motion' - motion text on a division, parameters are (date, number, house)

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

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

# Given a wiki type and parameters, returns where clause to use to get data from table.
function get_wiki_where_fragment($type, $params) 
{
    if ($type == 'motion') {
        return " (division_date = '$params[0]' and division_number = '$params[1]' and house = '$params[2]') ";
    } else {
        fatal_error("Unknown wiki type '" . html_scrub($type). "'");
    }
}
# Give a wiki type, returns table
function get_wiki_table($type) 
{
    if ($type == 'motion') {
        return "pw_dyn_wiki_motion";
    } else {
        fatal_error("Unknown wiki type '" . html_scrub($type). "'");
    }
}
# Returns link to history view of given wiki item
function get_wiki_history_link($type, $params) {
    if ($type == 'motion') {
        return "/edits.php?type=$type&date=$params[0]&number=$params[1]&house=$params[2]";
    } else {
        fatal_error("Unknown wiki type '" . html_scrub($type). "'");
    }
}

# Returns current value of wiki text based on type and params.  Return value is
# a hash with text_body, user_id, edit_date.
function get_wiki_current_value($type, $params) 
{
    # See if page has been altered
    global $db;
    $db->query("select text_body, user_id, edit_date from 
        ".get_wiki_table($type)." where ".get_wiki_where_fragment($type, $params)." order by wiki_id desc limit 1");
    if ($db->rows() >= 1) {
        $result = $db->fetch_row_assoc();
    }

    if ($type == 'motion') {
        list($motion, $division_name) = get_motion_default_values($params);
        if (!$result) {
            $result = array(
                'text_body' => $motion,
                'edit_date' => $params[0],
                'user_id' => 0
            );
        }
        $result['text_body'] = add_motion_missing_wrappers($result['text_body'], $division_name);
    } else {
        fatal_error("Unknown wiki type '" . html_scrub($type). "'");
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
function get_motion_default_values($params)
{
    global $db;
    $db->query("select motion, division_name from pw_division 
        where " . get_wiki_where_fragment("motion", $params));
    if ($db->rows() >= 1) {
        $row = $db->fetch_row_assoc();
        $motion = $row['motion'];
        $motion = str_replace(' class=""', '', $motion);
        $motion = str_replace(' pwmotiontext="yes"', '', $motion);
        return array($motion, $row['division_name']);
    }

    fatal_error("Couldn't find motion text for division " . htmlspecialchars($parmas[0]) . " " . htmlspecialchars($params[1]) 
        . " " . htmlspecialchars($params[2]));
}

# Makes sure the wiki_id value is up to date in pw_cache_divwiki for every
# division.
function update_divisions_wiki_id($db)
{
    $result = $db->query("INSERT INTO pw_cache_divwiki 
        (division_date, division_number, house, wiki_id)
        SELECT pw_division.division_date AS division_date, 
               pw_division.division_number AS division_number,
               pw_division.house AS house,
               IFNULL(MAX(pw_dyn_wiki_motion.wiki_id), -1) AS value
        FROM pw_division
        LEFT JOIN pw_cache_divwiki ON pw_division.division_date = pw_cache_divwiki.division_date AND
            pw_division.division_number = pw_cache_divwiki.division_number
        LEFT JOIN pw_dyn_wiki_motion ON pw_dyn_wiki_motion.division_date = pw_division.division_date
            AND pw_dyn_wiki_motion.division_number = pw_division.division_number
            AND pw_dyn_wiki_motion.house = pw_division.house
        WHERE pw_cache_divwiki.wiki_id IS NULL
        GROUP BY pw_division.division_id
    ");
}

?>
