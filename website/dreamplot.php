<?php require_once "common.inc";
require_once "db.inc"; 

//header("Content-Type: text/html");
header("Content-Type: image/png");
$dreamid = intval($_GET["id"]);
$display = $_GET["display"];
$rdisplay_house = db_scrub($_GET["house"]);
$bsmall = ($_GET["size"] != 'large'); 

$fontfile = "/usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf";
$fontsize = 10;

# $Id: dreamplot.php,v 1.20 2009/05/19 15:03:43 marklon Exp $

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

$bars = 9;
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
	"Con:scotland" 	=> array(51, 51, 153),
	"Con:lords" 	=> array(71, 71, 173),
	"Ind:commons"	=> array(238, 238, 238),
	"Ind:scotland"	=> array(238, 238, 238),
	"Independent:scotland"	=> array(238, 238, 238),
	"Ind Con:commons"=> array(221, 221, 238),
	"Ind Lab:commons"=> array(238, 221, 221),
    "LDem:commons"	=> array(241, 204, 10),
    "LDem:scotland"	=> array(241, 204, 10),
    "LDem:lords"	=> array(251, 224, 30),
    "PC:commons"	=> array(51, 204, 51),
    "SDLP:commons"	=> array(141, 144, 51),
    "SNP:commons"	=> array(255, 224, 0),
    "SNP:scotland"	=> array(255, 224, 0),
    "Green:scotland"	=> array(0, 255, 0),
    "Ind UU:commons"=> array(0, 54, 102),
	"Res:commons"	=> array(20, 200, 20),
	"Lab:commons"	=> array(204, 0, 0),
	"Lab:scotland"	=> array(204, 0, 0),
	"Lab:lords"		=> array(224, 20, 20),
	"XB:lords"		=> array(180, 212, 190),
	"Bp:lords"		=> array(0, 0, 0),
);

$placeholders=array();

// Calculate number of MPs with distance to Dream MP in each of
// $divisions blocked off ranges (between 0.0 and 1.0).
$qsel = "SELECT party, distance_a AS distance, house, left_house
          FROM pw_mp
		  LEFT JOIN pw_cache_dreamreal_distance
            ON pw_cache_dreamreal_distance.person = pw_mp.person
            AND pw_cache_dreamreal_distance.dream_id = :dream_id";
$placeholders[':dream_id']=$dreamid;
$qwhere = " WHERE distance_a <> -1 AND left_house = '9999-12-31'"; 
$maxmembers = 700;
if ($rdisplay_house == "lords" || $rdisplay_house == "commons" || $rdisplay_house == "scotland") {
	$qwhere .= " AND house = :house";
    $placeholders[':house']=$rdisplay_house;
} else
{
	$maxmembers = 1400;
    $rdisplay_house = ""; 
}

$qorder = " ORDER BY party, house";

$pwpdo->query($qsel.$qwhere.$qorder,$placeholders);

$pdata = array();
$pdatacol = array();
for ($i = 0; $i < $bars; $i++)
{
    $pdata[$i] = array();
    $pdatacol[$i] = 0; 
}    

$countrows = 0; 
$maxcol = 0; 
while ($row = $pwpdo->fetch_row())
{
    $party = $row['party'].":".$row['house'];
    $distance = $row['distance'];
    $i = min(intval($distance * floatval($bars)), $bars - 1);
    $pdata[$i][$party] = $pdata[$i][$party] + 1;
    $countrows = $countrows + 1; 
    $pdatacol[$i] = $pdatacol[$i] + 1; 
    if ($pdatacol[$i] > $maxcol)
        $maxcol = $pdatacol[$i]; 
}
//print_r($pdata);
if ($display != 'reverse')
    $pdata = array_reverse($pdata);

// revalue the scale up a bit
if ($maxmembers - 200 > $maxcol)
    $maxmembers = $maxmembers - 200; 
//$maxmembers = $maxcol + 1; 

$memberheight = $height / floatval($maxmembers);


$im    = imagecreate($width, $height + ($bsmall ? 0 : $fontsize + 8));
imagecolorallocate($im, 255, 255, 255); // has the effect of filling the colour 

$px    = ($width - $fontsize * strlen($rdisplay_house)) / 2;

foreach ($pdata as $i => $pd)
{
	$xlo = $i * $width / $bars + 1;
	$xhi = ($i + 1) * $width / $bars - 1;
	$bh = 2.0;

	foreach ($partycols as $partyhouse => $acol)
	{
		$bhN = $bh + $pd[$partyhouse] * $memberheight;
		$ibh = $height - floor($bh + 0.9);
		$ibhN = $height - floor($bhN + 0.9);
        //$xhi -= 1;
		if ($ibh != $ibhN)
		{
			$icol = imagecolorallocate($im, $acol[0], $acol[1], $acol[2]);
			ImageFilledRectangle($im, $xlo, $ibhN, $xhi, $ibh, $icol);
        }
		$bh = $bhN;
	}
    if (!$bsmall)
    {
        $icol = imagecolorallocate($im, 200, 200, 200); 
        ImageFilledRectangle($im, $xlo, $height, $xhi, $height, $icol);
    }
}

if (!$bsmall)
{
    $tcol = imagecolorallocate($im, 20, 20, 20); 
    $belowhist = $height + $fontsize + 4;
    if ($display != 'reverse')
    {
        imagettftext($im, $fontsize, 0, 5, $belowhist, $tcol, $fontfile, "disagree");
        imagettftext($im, $fontsize, 0, $width - 10 * 4, $belowhist, $tcol, $fontfile, "agree"); 
    }
    else
    {
        imagettftext($im, $fontsize, 0, 5, $belowhist, $tcol, $fontfile, "agree");
        imagettftext($im, $fontsize, 0, $width - 10 * 6, $belowhist, $tcol, $fontfile, "disagree"); 
    }
    //$rdisplay_house = $countrows;
    //$rdisplay_house = $maxcol; 
    if ($rdisplay_house)
        imagettftext($im, $fontsize, 0, $px, 12, $tcol, $fontfile, $rdisplay_house); 
}

imagepng($im);
imagedestroy($im);
