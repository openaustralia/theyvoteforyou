<?php require_once "common.inc";
header("Content-Type: text/html");
//header("Content-Type: image/png");
$dreamid = intval($_GET["id"]);
$display = $_GET["display"];
# $Id: dreamplot.php,v 1.11 2007/02/08 17:16:37 publicwhip Exp $

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
$query = "SELECT party, distance_a AS distance, house
          FROM pw_mp
		  LEFT JOIN pw_cache_dreamreal_distance
            ON pw_cache_dreamreal_distance.person = pw_mp.person
            AND pw_cache_dreamreal_distance.dream_id = $dreamid
          ORDER BY party, house";

$db->query($query);
$bars = 10;
$pdata = array();
for ($i = 0; $i < $bars; $i++)
    $pdata[$i] = array();

while ($row = $db->fetch_row_assoc())
{
    $party = $row['party'].":".$row['house'];
    $distance = $row['distance'];
    $i = min(intval($distance * floatval($bars)), $bars - 1);
    $pdata[$i][$party] = $pdata[$i][$party] + 1;
}
print_r($pdata);
if ($display != 'reverse')
    $pdata = array_reverse($pdata);
die; 

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
