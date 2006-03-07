<?php

# $Id: render.inc,v 1.15 2006/03/07 13:52:39 frabcus Exp $

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
