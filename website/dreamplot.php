<?php require_once "common.inc";
header("Content-Type: image/png");
$dreamid = intval($_GET["id"]);
$display = $_GET["display"];
# $Id: dreamplot.php,v 1.9 2007/02/08 16:28:44 goatchurch Exp $

# Draw thumbsketch histogram of how many MPs are each distance away
# from the Dream MP.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "db.inc";
require_once "parliaments.inc";
require_once "dream.inc";

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
if ($display != 'reverse')
    $data = array_reverse($data);

// Draw bar
require_once('sparkline/lib/Sparkline_Bar.php');

$sparkline = new Sparkline_Bar();
$sparkline->SetDebugLevel(DEBUG_NONE);
//$sparkline->SetDebugLevel(DEBUG_ERROR | DEBUG_WARNING | DEBUG_STATS | DEBUG_CALLS, '../log.txt');
$sparkline->SetBarWidth(2);
$sparkline->SetBarSpacing(1);

$string = "Oogabooga";
$width = 200;
$height = 100;
$im    = imagecreate($width, $height);
$orange = imagecolorallocate($im, 220, 210, 60);
$red = imagecolorallocate($im, 255, 0, 0);
$blue = imagecolorallocate($im, 0, 0, 255);
$white = imagecolorallocate($im, 255, 255, 255);
$px    = (imagesx($im) - 7.5 * strlen($string)) / 2;

while (list($k, $v) = each($data)) {
  $sparkline->SetData($k, $v, 'black');
  imagefilledrectangle($im, $k * 5, 0, $k * 5 + 5, $v * 5, $blue);
}
#$sparkline->Render(16); // height only for Sparkline_Bar

#$sparkline->Output();



imagestring($im, 3, $px, 9, $string, $red);
imageline ($im, 0, 0, 50, 50, $white);


imagepng($im);
imagedestroy($im);

?>
