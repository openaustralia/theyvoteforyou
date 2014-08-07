<?php require_once "common.inc";
    # $Id: mps-xml.php,v 1.8 2006/03/12 13:14:30 publicwhip Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $db = new DB(); 

    header("Content-type: text/xml");
    header("Content-Disposition: attachment; filename=\"mpinfo.xml\"");

    require_once "parliaments.inc";

    print "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n";
    print "<publicwhip>\n";

    $query = "select division_date from pw_division order by division_date desc limit 1";
	$db->query($query);
    $row = $db->fetch_row_assoc();
    $last_div_date = $row['division_date'];

    $mps_query_start = "select first_name, last_name, title, constituency,
            party, pw_mp.mp_id as mp_id,
            round(100*rebellions/votes_attended,0) as rebellions,
            round(100*votes_attended/votes_possible,0) as attendance,
            entered_reason, left_reason, entered_house, left_house,
            house
            from pw_mp,
            pw_cache_mpinfo where
            pw_mp.mp_id = pw_cache_mpinfo.mp_id";

    $order = "entered_house, last_name, first_name, constituency";
    $query = "$mps_query_start and house = 'commons' order by $order";

	$db->query($query);
    while ($row = $db->fetch_row_assoc())
    {
        print "\n";
        print "<memberinfo id=\"uk.org.publicwhip/member/" . $row['mp_id'] . "\" \n";
        if ($row['left_house'] >= $last_div_date)
            print " data_date=\"" . $last_div_date . "\"\n";
        else
            print " data_date=\"complete\"\n";

        $att = $row['attendance'];
        if ($att == "") $att="n/a";
        $reb = $row['rebellions'];
        if ($reb == "") $reb="n/a";
        print " division_attendance=\"$att%\"\n";
        print " rebellions_estimate=\"$reb%\"\n";

        print "/>\n";
    }

    print "\n</publicwhip>\n";

?>
