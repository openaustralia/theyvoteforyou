<?php
    # $Id: mpcoords.php,v 1.1 2003/08/14 19:35:48 frabcus Exp $
    # Outputs a text file of coordinates for the Java applet

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "mpcoords-eigen.inc";
    include "pretty.inc";
    include "db.inc";
    $db = new DB(); 

    $mp_count = $db->query_one_value("select count(*) from pw_cache_mpcoords");
    print "$mp_count $eigx $eigy $eigz";
    
    $db->query("select pw_mp.mp_id, first_name, last_name, party,
    round(x,5), round(y,5), round(z,5) from pw_mp,
    pw_cache_mpcoords where pw_mp.mp_id = pw_cache_mpcoords.mp_id");

    while ($row = $db->fetch_row())
    {
        print "\n$row[0] $row[4] $row[5] $row[6] \"$row[2], $row[1]\" \"" . pretty_party_raw($row[3]) . "\"";
    }    

?>

