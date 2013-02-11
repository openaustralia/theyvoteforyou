<?php
# $Id: wiki.inc,v 1.20 2010/01/04 17:17:58 publicwhip Exp $
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
    $text_body = preg_replace("/&#8212;/", "-", $text_body);
    return $text_body;
}

# Given a wiki type and parameters, returns where clause to use to get data from table.
function get_wiki_where_fragment($type, $params) 
{
    if ($type == 'motion') {
        return " (division_date = '$params[0]' and division_number = '$params[1]' and house = '$params[2]') ";
    } else {
        trigger_error("Unknown wiki type '" . html_scrub($type). "'", E_USER_ERROR);
    }
}
# Give a wiki type, returns table
function get_wiki_table($type) 
{
    if ($type == 'motion') {
        return "pw_dyn_wiki_motion";
    } else {
        trigger_error("Unknown wiki type '" . html_scrub($type). "'", E_USER_ERROR);
    }
}
# Returns link to history view of given wiki item
function get_wiki_history_link($type, $params) {
    if ($type == 'motion') {
        return "/edits.php?type=$type&date=$params[0]&number=$params[1]&house=$params[2]";
    } else {
        trigger_error("Unknown wiki type '" . html_scrub($type). "'", E_USER_ERROR);
    }
}

# Returns current value of wiki text based on type and params.  Return value is
# a hash with text_body, user_id, edit_date.

# !!! this should take the $db as a parameter so that it can't be reused when it's in other loops
function get_wiki_current_value($type, $params)
{
    global $pwpdo;
    # See if page has been altered
    if ($type!=='motion') {
        trigger_error('Unknown wiki type');
        die();
    }
    $query='select text_body, user_id, edit_date FROM pw_dyn_wiki_motion WHERE division_date=? AND division_number=? AND house=? order by wiki_id desc limit 1';
    $placeheld=array($params[0],$params[1],$params[2]);
    $allRows=$pwpdo->fetch_all_rows($query,$placeheld);
    if (count($allRows) >= 1) {
        $result = $allRows[0];
    }

    if ($type == 'motion') {
        list($motion, $division_name) = get_motion_default_values($db, $params);
        if (!$result) {
            $result = array(
                'text_body' => $motion,
                'edit_date' => $params[0],
                'user_id' => 0
            );
        }
        $result['text_body'] = add_motion_missing_wrappers($result['text_body'], $division_name);
    } else {
        trigger_error("Unknown wiki type '" . html_scrub($type). "'", E_USER_ERROR);
    }
    return $result;
}


# Call this to get motion from wiki text for display
function extract_action_text_from_wiki_text($text)
{
    $motion = extract_motion_text_from_wiki_text_for_edit($text);
    $motionlines = explode("\n", $motion);
    $res = array("title" => extract_title_from_wiki_text($text)); 
    $matches = array();
    foreach ($motionlines as $motionline)
    {
        if (preg_match("/^@\s*MP voted (aye|no)(.*)$/i", $motionline, $matches))
            $res[$matches[1]] = $matches[2]; 
    }
    return $res; 
}

# Call this to get motion from wiki text for display
function extract_motion_text_from_wiki_text($text)
{
    $motion = extract_motion_text_from_wiki_text_for_edit($text);
    if (!preg_match("/.*<\/.*?>/", $motion))
    {
        $motionlines = explode("\n", $motion);
        $binUL = 0;
        $res = array();
        $matches = array();
        foreach ($motionlines as $motionline)
        {
            $ml = preg_replace("/''(.*?)''/", "<em>\\1</em>", $motionline);
            $ml = preg_replace("/\[(https?:\S*)\s+(.*?)\]/", "<a href=\"\\1\">\\2</a>", $ml);
            $ml = preg_replace("/(?<![*\s])(\[(\d+)\])/", "<sup class=\"sup-\\2\"><a class=\"sup\" href='#footnote-\\2' onclick=\"ClickSup(\\2); return false;\">\\1</a></sup>", $ml);
            #$ml = preg_replace("/(\[\d+])/", "<sup>\\1</sup>", $ml);
            if (preg_match("/^\s\s*$/", $ml))
                continue;
            if (preg_match("/^@/", $ml))  // skip comment lines we lift up for the short sentences
                continue;
            if (preg_match("/^(\*|:)/", $ml))
            {
                if (!$binUL)
                    $res[] = "<ul>";
                $binUL = (preg_match("/^\*\*/", $ml) ? 2 : 1);
                if (preg_match("/^:/", $ml))
                    $binUL = 3;
                else if (preg_match("/^\s*\*\s*\[\d+\]/", $ml, $matches))
                {
                    $binUL = 4; 
                    $footnum = preg_replace("/[\s\*\[\]]+/", "", $matches[0]);  // awful stuff because I can't pull out bits like in python
                }
                $ml = preg_replace("/^(\*\*|\*|:)\s*/", "", $ml);
            }
            else if ($binUL != 0)
            {
                $binUL = 0;
                $res[] = "</ul>";
            }

            
            if ($binUL == 0)
                $res[] = "<p>";
            else if ($binUL == 2)
                $res[] = "<li class=\"house\">";
            else if ($binUL == 3)
                $res[] = "<li class=\"block\">";
            else if ($binUL == 4)
                $res[] = "<li class=\"footnote\" id=\"footnote-$footnum\">";
            else
                $res[] = "<li>";
            
            $res[] = $ml;
            
            if ($binUL == 0)
                $res[] = "</p>";
            else
                $res[] = "</li>";
        }
        if ($binUL)
            $res[] = "</ul>";
        $motion = implode("\n", $res);
    #$motion = preg_replace("/\*/", "HIHI", $motion);
    }
    $motion = guy2html(guy_strip_bad($motion));

    return $motion;
}

# Call this to get motion from wiki text for edit
function extract_motion_text_from_wiki_text_for_edit($text)
{
    if (preg_match("/--- MOTION EFFECT ---(.*)--- COMMENT/s", $text, $matches)) {
        $motion = $matches[1];
    }
	$motion = preg_replace("/<p\b.*?class=\"italic\".*?>(.*)<\/p>/",'<p><i>\\1</i></p>',$motion);
	$motion = preg_replace("/<p\b.*?class=\"indent\".*?>(.*)<\/p>/",'<blockquote>\\1</blockquote>',$motion);

    return $motion;
}


# Call this to get title from wiki text for display
function extract_title_from_wiki_text($text)
{
    if (preg_match("/--- DIVISION TITLE ---(.*)--- MOTION EFFECT/s", $text, $matches)) {
        $title = $matches[1];
    }
    $title = trim(strip_tags($title));
    $title = str_replace(" - ", " &#8212; ", $title);
    return $title;
}

# Returns a list of: 
#  the default text for a motion, 
#  the default title of the motion. 
# In both cases, that is what was screen scraped originally.  
function get_motion_default_values($db, $params)
{
    global $pwpdo;
    $query='select motion, division_name from pw_division  where division_date=? AND division_number=? AND house=?';
    $allRows=$pwpdo->fetch_all_rows($query,array($params[0],$params[1],$params[2]));
    if (count($allRows) >= 1) {
        $row = $allRows[0];
        $motion = $row['motion'];
        $motion = str_replace(' class=""', '', $motion);
        $motion = str_replace(' pwmotiontext="yes"', '', $motion);
        return array($motion, $row['division_name']);
    }

    trigger_error("Couldn't find motion text for division " . htmlspecialchars($parmas[0]) . " " . htmlspecialchars($params[1]) 
        . " " . htmlspecialchars($params[2]), E_USER_ERROR);
}

# Makes sure the wiki_id value is up to date in pw_cache_divwiki for every
# division.
function update_divisions_wiki_id($db)
{
    global $pwpdo;
    $result = $pwpdo->query("INSERT INTO pw_cache_divwiki 
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
    ",array());
}

?>
