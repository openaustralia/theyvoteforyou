<?php

header("Content-type: image/png");
$string = "Oogabooga";
$im    = imagecreate(300,300);
$orange = imagecolorallocate($im, 220, 210, 60);
$red = imagecolorallocate($im, 255, 0, 0);
$white = imagecolorallocate($im, 255, 255, 255);
$px    = (imagesx($im) - 7.5 * strlen($string)) / 2;
imagestring($im, 3, $px, 9, $string, $red);
imageline ($im, 0, 0, 50, 50, $white);
imagepng($im);
imagedestroy($im);

