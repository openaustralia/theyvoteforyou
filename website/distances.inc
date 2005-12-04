<?php
# $Id: distances.inc,v 1.2 2005/12/04 17:02:31 publicwhip Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

function matchvoteqstr($vote, $votenumber)
{
	if ($vote == "absent")
		return "(pw_vote$votenumber.vote = 'both' OR pw_vote$votenumber.vote IS null)";
	return "(pw_vote$votenumber.vote = '$vote' OR pw_vote$votenumber.vote = 'tell$vote')";
}

function matchvoteqsum($vote1, $vote2)
{
	return ", sum(".matchvoteqstr($vote1, 1)." AND ".matchvoteqstr($vote2, 2).") AS nvotes$vote1$vote2";
}

# calculate the distance between two divisions from their ids
function update_divdiv_distance($db, $division_date1, $divid1, $division_date2, $divid2, $house)
{
	global $bdebug;

	# make the set of voting MPs in the first division
	$qselect = "SELECT 1 AS ssss, sum(1) AS nvotestotal";
#$qselect .= matchvoteqsum("absent", "no"); 
	$qselect .= matchvoteqsum("no", "no").matchvoteqsum("no", "aye").matchvoteqsum("aye", "no").matchvoteqsum("aye", "aye");
	$qselect .= matchvoteqsum("no", "absent").matchvoteqsum("aye", "absent").matchvoteqsum("absent", "no").matchvoteqsum("absent", "aye");

	$qfrom =  " FROM pw_mp AS pw_mp1";
	$qwhere = " WHERE pw_mp1.entered_house <= '$division_date1'
				   AND pw_mp1.left_house > '$division_date1'
				   AND pw_mp1.house = '$house'";

	# now line up the votes (including the missing ones)
	$qjoin =  " LEFT JOIN pw_vote AS pw_vote1
					ON pw_vote1.division_id = $divid1
					AND pw_vote1.mp_id = pw_mp1.mp_id";

	# now line up the mps who could have voted on the second division
	$qjoin .= " LEFT JOIN pw_mp AS pw_mp2
					ON pw_mp2.person = pw_mp1.person
					AND pw_mp2.entered_house <= '$division_date2'
					   AND pw_mp2.left_house > '$division_date2'
					   AND pw_mp2.house = '$house'";

	# and line them up with their votes
	$qjoin .= " LEFT JOIN pw_vote AS pw_vote2
					ON pw_vote2.division_id = $divid2
					AND pw_vote2.mp_id = pw_mp2.mp_id";

	$qgroup = " GROUP BY ssss"; # sum all rows




	$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup;
	if ($bdebug == 1)
		print "<h4>$query</h4>";
    $row = $db->query_one_row_assoc($query);
	print_r($row);
}


function get_divid($db, $division_date, $division_number, $house)
{
	$query = "SELECT division_id
			  FROM pw_division
			  WHERE division_date = '$division_date'
			    AND division_number = $division_number
			    AND house = '$house'";
	print $query; 
	$row = $db->query_one_row_assoc($query);
	return $row["division_id"];
}

function gen_division_distance($db, $division_date1, $division_number1, $division_date2, $division_number2, $house)
{
	$divid1 = get_divid($db, $division_date1, $division_number1, $house);
	$divid2 = get_divid($db, $division_date2, $division_number2, $house);

	update_divdiv_distance($db, $division_date1, $divid1, $division_date2, $divid2, $house);
}

# then we loop through the missing entries and fill them in
