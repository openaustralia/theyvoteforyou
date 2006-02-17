<?php require_once "common.inc";
# $Id: mpplot.php,v 1.1 2006/02/17 11:47:07 frabcus Exp $

# Draw thumbsketch histogram of how many MPs are each distance away
# from the Dream MP.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "db.inc";
require_once "decodeids.inc";
$db = new DB(); 
$db2 = new DB(); 

$voter1attr = get_mpid_attr_decode($db, $db2, "");
$person = db_scrub($voter1attr['mpprop']['person']);

// Calculate number of MPs with distance to Dream MP in each of
// $divisions blocked off ranges (between 0.0 and 1.0).
$query = "select division_date, vote, whip_guess
            from pw_vote
            left join pw_division on pw_division.division_id = pw_vote.division_id 
            left join pw_mp on pw_mp.mp_id = pw_vote.mp_id
            left join pw_cache_whip on pw_cache_whip.division_id = pw_division.division_id and pw_mp.party = pw_cache_whip.party
            where pw_mp.person = $person
            order by division_date";
$db->query($query);
#$divisions = 10;
#$data = array();
#for ($i = 0; $i < $divisions; $i++) {
#    $data[$i] = 0;
#}
$data = array();
while ($row = $db->fetch_row_assoc())
{
    $vote = str_replace("tell", "", $row['vote']);
    $whip = $row['whip_guess'];
    if ($vote <> "aye" && $vote <> "no" && $vote <> "both") {
        trigger_error("Unknown vote type '$vote'", E_USER_ERROR);
    }
    $score = 0;
    if ($vote == "both") {
        $score = 0.5;
    } elseif ($vote == $whip) {
        $score = 0;
    } elseif ($vote != $whip) {
        $score = 1;
    }
#    print $score . "-";
#    print_r($row);
#    print "<br>";
    $data[] = $score;
#    $personid = $row['person'];
#    $division = intval($row['distance_a'] * floatval($divisions));
#    if ($division == $divisions)
#        $division--;
#    $data[$division]++;
}
#print_r($data);

// Draw bar
header("Content-Type: image/png");
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

?>
