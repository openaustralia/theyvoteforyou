<?php require_once "common.inc";
require_once "db.inc"; 

//header("Content-Type: text/html");
header("Content-Type: image/png");
$dreamid = intval($_GET["id"]);
$display = $_GET["display"];
$rdisplay_house = db_scrub($_GET["house"]);
$bsmall = ($_GET["size"] != 'large'); 

# $Id: dreamplot.php,v 1.15 2007/02/08 18:57:01 publicwhip Exp $

# Draw thumbsketch histogram of how many MPs are each distance away
# from the Dream MP.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "parliaments.inc";
require_once "dream.inc";

$db = new DB();
update_dreammp_person_distance($db, $dreamid); # new method

$bars = 10;
$width = 200;
$height = 100;
if ($bsmall)
{
    $width = 90; 
    $height = 50; 
}


$partycols = array(
    "UKU:commons"	=> array(145, 224, 255),
    "DU:commons"	=> array(224, 102, 102),
    "UU:commons"	=> array(0, 54, 102),
	"Con:commons" 	=> array(51, 51, 153),
	"Con:lords" 	=> array(71, 71, 173),
	"Ind:commons"	=> array(238, 238, 238),
	"Ind Con:commons"=> array(221, 221, 238),
	"Ind Lab:commons"=> array(238, 221, 221),
    "LDem:commons"	=> array(241, 204, 10),
    "LDem:lords"	=> array(251, 224, 30),
    "PC:commons"	=> array(51, 204, 51),
    "SDLP:commons"	=> array(141, 144, 51),
    "SNP:commons"	=> array(255, 224, 0),
    "Ind UU:commons"=> array(0, 54, 102),
	"Res:commons"	=> array(20, 200, 20),
	"Lab:commons"	=> array(204, 0, 0),
	"Lab:lords"		=> array(224, 20, 20),
	"XB:lords"		=> array(180, 212, 190),
	"Bp:lords"		=> array(0, 0, 0),
);



// Calculate number of MPs with distance to Dream MP in each of
// $divisions blocked off ranges (between 0.0 and 1.0).
$qsel = "SELECT party, distance_a AS distance, house
          FROM pw_mp
		  LEFT JOIN pw_cache_dreamreal_distance
            ON pw_cache_dreamreal_distance.person = pw_mp.person
            AND pw_cache_dreamreal_distance.dream_id = $dreamid";

$maxmembers = 700;
if ($rdisplay_house == "lords" || $rdisplay_house == "commons")
	$qwhere = " WHERE house = '$rdisplay_house'";
else
{
	$maxmembers = 1400;
    $rdisplay_house = ""; 
}

$qorder = " ORDER BY party, house";
$db->query($qsel.$qwhere.$qorder);

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
//print_r($pdata);
if ($display != 'reverse')
    $pdata = array_reverse($pdata);


$memberheight = $height / floatval($maxmembers);

$im    = imagecreate($width, $height);
$white = imagecolorallocate($im, 255, 255, 255);
$jjred = imagecolorallocate($im, 200, 90, 190);
$px    = ($width - 7.5 * strlen($rdisplay_house)) / 2;

foreach ($pdata as $i => $pd)
{
	$xlo = $i * $width / $bars + 1;
	$xhi = ($i + 1) * $width / $bars - 1;
	$bh = 2.0;

	foreach ($partycols as $partyhouse => $acol)
	{
		$bhN = $bh + $pd[$partyhouse] * $memberheight;
		$ibh = $height - floor($bh);
		$ibhN = $height - floor($bhN);
        //$xhi -= 1;
		if ($ibh != $ibhN)
		{
			$icol = imagecolorallocate($im, $acol[0], $acol[1], $acol[2]);
			ImageFilledRectangle($im, $xlo, $ibhN, $xhi, $ibh, $icol);
		}
		$bh = $bhN;
	}
}

if (!$bsmall)
{
$tcol = imagecolorallocate($im, 20, 20, 20); 
if ($display == 'reverse')
{
    imagestring($im, 3, 1, 2, "0%", $tcol);
    imagestring($im, 3, $width - 30, 2, "100%", $tcol);  
}
else
{
    imagestring($im, 3, 1, 2, "100%", $tcol);
    imagestring($im, 3, $width - 15, 2, "0%", $tcol); 
}
if ($rdisplay_house)
    imagestring($im, 3, $px, 2, $rdisplay_house, $tcol); 
}

imagepng($im);
imagedestroy($im);

?>
