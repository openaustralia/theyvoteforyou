<?php
# $Id: constituencies.inc,v 1.7 2005/05/08 22:06:14 frabcus Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

function normalise_constituency_name($db, $name) {
    $query = "select (select name from pw_constituency where main_name and cons_id = o.cons_id) as norm_name
              from pw_constituency as o where name like '" . db_scrub($name) . "'";
    $normal_form = $db->query_onez_row_assoc($query);
    if ($normal_form) 
        return $normal_form["norm_name"];
    else
        return false;
}

?>
