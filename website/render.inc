<?php

# $Id: render.inc,v 1.11 2005/03/04 02:22:45 theyworkforyou Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

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

$mps_query_start = "select first_name, last_name, title, constituency,
        party, pw_mp.mp_id as mp_id, round(100*rebellions/votes_attended,0) as rebellions,
        round(100*votes_attended/votes_possible,0) as attendance, entered_reason,
        left_reason, entered_house, left_house from pw_mp,
        pw_cache_mpinfo where
        pw_mp.mp_id = pw_cache_mpinfo.mp_id";

# This isn't used in as many places as it should be - 
# TODO: Make it so it is, if you change it
function set_mp_with_link($row)
{
    $anchor = "\"mp.php?firstname=" . urlencode($row['first_name']) .
        "&lastname=" . urlencode($row['last_name']) . "&constituency=" .
        urlencode($row['constituency']) . "\"";

    return "<a href=$anchor>" . $row['title'] . " ". $row['first_name'] . " " . $row['last_name'] . "</a>";
}

function set_party($row)
{
    return pretty_party($row['party'], $row['entered_reason'], $row['left_reason']);
}

function render_mps_table($db)
{
    $prettyrow = 0;
    while ($row = $db->fetch_row_assoc())
    {
        $prettyrow = pretty_row_start($prettyrow);

        print "<td>" . set_mp_with_link($row) . "</td></td>
            <td>" . $row['constituency'] . "</td>
            <td>" . set_party($row). "</td>
            <td class=\"percent\">" . percentise($row['rebellions']) . "</td>
            <td class=\"percent\">" . percentise($row['attendance']) . "</td>
            ";
        print "</tr>\n";
    }
}

?>
