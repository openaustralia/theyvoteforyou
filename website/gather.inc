<?php
# $Id: gather.inc,v 1.1 2005/01/14 19:00:44 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# Gather information from the database

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under

# Returns label wiki code uses for motion text of particular division
function get_motion_wiki_key($date, $div_no)
{
    return "motion-$date-$div_no";
}

# 
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
    global $db;
    $key = get_motion_wiki_key($date, $div_no);
    $db->query("select text_body, user_id, edit_date from 
        pw_dyn_wiki where object_key = '$key' order by wiki_id desc limit 1");
    if ($db->rows() >= 1) {
        $row = $db->fetch_row_assoc();
        return $row;
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
        return $result;
    }

    die("Couldn't find motion text for division " . htmlspecialchars($date) . " " . htmlspecialchars($div_no));
}

?>
