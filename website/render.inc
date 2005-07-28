<?php

# $Id: render.inc,v 1.13 2005/07/28 15:33:19 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# unlikely to last.  
function head_cell($url, $current_sort, $heading, $heading_sort, $title)
{
    print "<td>";
    if ($current_sort != $heading_sort)
    {
        print "<a href=\"" . $url . "sort=$heading_sort\" title=\"$title\">$heading</a>";
    }
    else
    {
        print $heading;
    }
    print "</td>";
}


# this function is probably dead
$divisions_query_start = "select pw_division.division_id,
    division_number, division_date, division_name, source_url,
    rebellions, turnout from pw_division, pw_cache_divinfo where
    pw_division.division_id = pw_cache_divinfo.division_id";

function render_divisions_table($db)
{
    $prettyrow = 0;
    while ($row = $db->fetch_row())
    {
        $class = "";
        if ($row[5] >= 10)
        {
            $class = "rebel";
        }
        $prettyrow = pretty_row_start($prettyrow, $class);
        print "<td>$row[1]</td> <td>$row[2]</td> <td><a
            href=\"division.php?date=" . urlencode($row[2]) . "&number="
            . urlencode($row[1]) . "\">$row[3]</a></td>
            <td>$row[5]</td>
            <td>$row[6]</td>";
        print "</tr>\n";
    }
}


# these functions should hopefully disappear soon
$mps_query_start = "select first_name, last_name, title, constituency,
        party, pw_mp.mp_id as mp_id, 
        round(100*rebellions/votes_attended,0) as rebellions,
        round(100*votes_attended/votes_possible,0) as attendance, 
        entered_reason, left_reason, entered_house, left_house,
        house
        from pw_mp,
        pw_cache_mpinfo where
        pw_mp.mp_id = pw_cache_mpinfo.mp_id";

function set_party($row)
{
    return pretty_party($row['party'], $row['entered_reason'], $row['left_reason']);
}

?>
