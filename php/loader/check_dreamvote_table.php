#!/usr/bin/php -q
<?php

# The 'house' column of pw_dyn_dreamvote has not been set correctly in
# the past.  This script should check for errors in that table and
# correct them.

require_once "../website/config.php";
require_once "../website/db.inc";
require_once "../website/parliaments.inc";

$repair = ( count($argv) > 1 and ($argv[1] == '-r' || $argv[1] == '--repair') );

$db = new DB();
$db2 = new DB();

$db->query("SELECT * FROM pw_dyn_dreamvote WHERE house = 'scotland'");
if( $db->rows() > 0 ) {
	print "There are rows in pw_dyn_dreamvote with house = 'scotland'.\n";
	print "This script assumes that there are no votes from policies on\n";
	print "Scottish Parliament divisions yet.\n";
	exit(-1);
}

$db->query("SELECT * FROM pw_dyn_dreamvote ORDER BY division_date, division_number");

while ($row = $db->fetch_row_assoc())
{
	$dream_id = $row['dream_id'];
	$division_date = $row['division_date'];
	$division_number = $row['division_number'];
	$possibly_wrong_house = $row['house'];
	$db2->query("SELECT * FROM pw_division WHERE
                    division_date = '$division_date' AND
                    division_number = '$division_number' AND
                    house != 'scotland'");
	$nrows = $db2->rows();
	if ($nrows == 0) {
		print "### MISSING: $nrows house $possibly_wrong_house, dream_id $dream_id, date $division_date, division_number $division_number\n";
	} elseif ($nrows == 1) {
		$row2 = $db2->fetch_row_assoc();
		$correct_house = $row2['house'];
		if ($correct_house != $possibly_wrong_house) {
			print "$nrows house $possibly_wrong_house, dream_id $dream_id, date $division_date, division_number $division_number\n";
			print "  Should correct house to: $correct_house\n";
			if( $repair ) {
				print "  Repairing... ";
				$db2->query( "UPDATE pw_dyn_dreamvote SET house = '$correct_house' WHERE
                                  division_date = '$division_date' AND
                                  division_number = $division_number AND
                                  dream_id = $dream_id" );
				print "done\n";
			}
		}
	} else {
		print "### AMBIGUITY: $nrows house $possibly_wrong_house, dream_id $dream_id, date $division_date, division_number $division_number\n";
		while ($row2 = $db2->fetch_row_assoc()) {
			$alternative_house = $row2['house'];
			print "  could be house: $house\n";
		}
	}
}
