<?php include "cache-begin.inc"; ?>
<?php 
    # $Id: mps-xml.php,v 1.1 2004/03/03 18:32:43 frabcus Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    include "render.inc";
    $db = new DB(); 

    header("Content-type: text/xml");

    include "parliaments.inc";
    $title = "MP Attendance and Rebelliousness";
	if ($parlsession != "")
		$title .= " - " . parlsession_name($parlsession) . " Session";
	else
		$title .= " - " . parliament_name($parliament) . " Parliament";

    print '<?xml version="1.0" encoding="ISO-8859-1"?>';
    print '<publicwhip>';

	if ($parlsession == "")
	{
		$query = "$mps_query_start and entered_house <= '" .
			parliament_date_to($parliament) . "' and entered_house >= '".
			parliament_date_from($parliament) . "' order by $order";
	}
	else
	{
		$query = "$mps_query_start and (" .
		"(entered_house >= '" .  parlsession_date_from($parlsession) . "' and " .
		"entered_house <= '".  parlsession_date_to($parlsession) . "') " .
		" or " .
		"(left_house >= '" .  parlsession_date_from($parlsession) . "' and " .
		"left_house <= '".  parlsession_date_to($parlsession) . "') " .
		" or " .
		"(entered_house < '" .  parlsession_date_from($parlsession) . "' and " .
		"left_house > '".  parlsession_date_to($parlsession) . "') " .
		") order by $order";
		$query = str_replace('pw_cache_mpinfo', 'pw_cache_mpinfo_session'.$parlsession, $query);
	}

	$db->query($query);
    while ($row = $db->fetch_row_assoc())
    {
        print '<memberinfo id="' . $row['mp_id'] . '" ';
        print ' division_attendance_WHEN=' . $row['attendance'] ' . 
            $row['rebellions']
        print "</tr>\n";
    }    $anchor = "\"mp.php?firstname=" . urlencode($row['first_name']) .
        "&lastname=" . urlencode($row['last_name']) . "&constituency=" .
        urlencode($row['constituency']) . "\"";


    print '</publicwhip>';

?>

<?php include "cache-end.inc"; ?>
