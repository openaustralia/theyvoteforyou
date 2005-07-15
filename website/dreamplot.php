<?php require_once "common.inc";
header("Content-Type: image/png");
$dreamid = intval($_GET["id"]);
$cache_params = "id=$dreamid"; include "cache-begin.inc";
# $Id: dreamplot.php,v 1.5 2005/07/15 16:57:29 frabcus Exp $

# Draw thumbsketch histogram of how many MPs are each distance away
# from the Dream MP.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include "db.inc";
include "parliaments.inc";
include "dream.inc";

$db = new DB(); 
update_dreammp_person_distance($db, $dreamid); # new method

// Calculate number of MPs with distance to Dream MP in each of
// $divisions blocked off ranges (between 0.0 and 1.0).
$query = "select person, distance_a 
          from pw_cache_dreamreal_distance 
          where dream_id = $dreamid";
$db->query($query);
$divisions = 10;
$data = array();
for ($i = 0; $i < $divisions; $i++) {
    $data[$i] = 0;
}
while ($row = $db->fetch_row_assoc())
{
    $personid = $row['person'];
    $division = intval($row['distance_a'] * floatval($divisions));
    if ($division == $divisions)
        $division--;
    $data[$division]++;
}
#print_r($data);

// Draw bar
require_once('sparkline/lib/Sparkline_Bar.php');

$sparkline = new Sparkline_Bar();
$sparkline->SetDebugLevel(DEBUG_NONE);
//$sparkline->SetDebugLevel(DEBUG_ERROR | DEBUG_WARNING | DEBUG_STATS | DEBUG_CALLS, '../log.txt');
$sparkline->SetBarWidth(2);
$sparkline->SetBarSpacing(1);

while (list($k, $v) = each($data)) {
  $sparkline->SetData($k, $v, 'black');
}
$sparkline->Render(16); // height only for Sparkline_Bar

$sparkline->Output();

include "cache-end.inc";

?>
