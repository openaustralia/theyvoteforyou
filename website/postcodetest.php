<?php

include "postcode.inc";

#$cons = postcode_to_constituency("le5 6pn");
#print $cons;
#exit;

$pcs = file_get_contents("/home/francis/devel/publicwhip/rawdata/postcodes.txt");
$pcs = split("\n", $pcs);
foreach ($pcs as $pc)
{
    print $pc . " ";
    $cons = postcode_to_constituency($pc);
    print $cons;
    print "<br>";
}

#$cons = postcode_to_constituency("bt36 5aa");
#$cons = postcode_to_constituency("g13 1aa");
#$cons = postcode_to_constituency("kt17 3jb");
#$cons = postcode_to_constituency("yo1 2qt"); # city of
#$cons= postcode_to_constituency("cv32 5na"); # &

if (isset($cons))
    print "def";
else
    print "not";
print $cons . "\n<br>";

?>
