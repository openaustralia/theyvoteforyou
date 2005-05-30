<?php
# $Id: constituencies.inc,v 1.10 2005/05/30 20:54:36 theyworkforyou Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

function normalise_constituency_name($db, $name) {
    // Use &amp; everywhere, as in DB
    $name = str_replace("&amp;", "&", $name);
    $name = str_replace("&", "&amp;", $name);

    $query = "select cons_id from pw_constituency where name like '" . db_scrub($name) . "' 
	order by to_date desc limit 1";
    $sth1 = $db->query_onez_row_assoc($query);
    if (!$sth1)
        return false;

    $query = "select name from pw_constituency where main_name and cons_id = '".$sth1['cons_id']."'";
    $sth2 = $db->query_onez_row_assoc($query);
    if (!$sth2)
        return false;

    return $sth2["name"];
}

?>
