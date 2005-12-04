<?php
# $Id: distances.inc,v 1.5 2005/12/04 19:26:24 goatchurch Exp $

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
function update_divdiv_distance($db, $division_date1, $division_number1, $divid1, $division_date2, $division_number2, $divid2, $house)
{
	global $bdebug;

	# make the set of voting MPs in the first division
	$qselect = "SELECT 1 AS ssss, sum(1) AS nvotestotal";
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


	$qattrs = "division_date, division_number, house,
			   division_date2, division_number2, house2, ";

	$qvalues = "'$division_date1', $division_number1, '$house',
			   '$division_date2', $division_number2, '$house', ";

	$qattrs .= "nvotespossible, ";
	$qvalues .= $row['nvotestotal'].", ";

	$qattrs .= "nvotesnono, nvotesnoaye, nvotesayeno, nvotesayeaye, ";
	$qvalues .= $row['nvotesnono'].", ".$row['nvotesnoaye'].", ".$row['nvotesayeno'].", ".$row['nvotesayeaye'].", ";

	$qattrs .= "nvotesnoabsent, nvotesayeabsent, nvotesabsentno, nvotesabsentaye, ";
	$qvalues .= $row['nvotesnoabsent'].", ".$row['nvotesayeabsent'].", ".$row['nvotesabsentno'].", ".$row['nvotesabsentaye'].", ";

	# calculate the distances
	$nabstainnon = $row['nvotesnoabsent'] + $row['nvotesayeabsent'] + $row['nvotesabsentno'] + $row['nvotesabsentaye'];
	$nsame = $row['nvotesnono'] + $row['nvotesayeaye'];
	$ndiff = $row['nvotesnoaye'] + $row['nvotesayeno'];

	$distance_a = (1.0 * min($nsame, $ndiff) + 0.2 * $nabstainnon) / ($nsame + $ndiff + 0.2 * $nabstainnon);
	$distance_b = 1.0 * min($nsame, $ndiff) / ($nsame + $ndiff);

	$qattrs .= "distance_a, distance_b";
	$qvalues .= "$distance_a, $distance_b";

	if ($bdebug == 1)
		print "<h4>$qattrs</h4>";
#	if ($bdebug == 1)
		print "<h4>$qvalues</h4>";
	$db->query("INSERT INTO pw_cache_divdiv_distance ($qattrs) VALUES ($qvalues)");

	#print_r($row);
}


function get_divid($db, $division_date, $division_number, $house)
{
	$query = "SELECT division_id
			  FROM pw_division
			  WHERE division_date = '$division_date'
			    AND division_number = $division_number
			    AND house = '$house'";
	$row = $db->query_one_row_assoc($query);
	return $row["division_id"];
}


# then we loop through the missing entries and fill them in
function fill_division_distances($db, $db2, $house, $divattr)
{
	# find missing entries in the table
	$qselect = "SELECT pw_division1.division_date AS division_date1,
					   pw_division1.division_number AS division_number1,
					   pw_division1.division_id AS division_id1,
					   pw_division2.division_date AS division_date2,
					   pw_division2.division_number AS division_number2,
					   pw_division2.division_id AS division_id2";

	$qfrom = " FROM pw_division AS pw_division1, pw_division AS pw_division2";
	$qjoin = " LEFT JOIN pw_cache_divdiv_distance
					ON pw_cache_divdiv_distance.division_date = pw_division1.division_date
						AND pw_cache_divdiv_distance.division_number = pw_division1.division_number AND pw_cache_divdiv_distance.house = '$house'
					AND pw_cache_divdiv_distance.division_date2 = pw_division2.division_date
						AND pw_cache_divdiv_distance.division_number2 = pw_division2.division_number AND pw_cache_divdiv_distance.house2 = '$house'";
	$qwhere = " WHERE pw_cache_divdiv_distance.division_date IS null";

	if ($divattr)
		$qwhere .= " AND pw_division1.division_id = ".$divattr['division_id'];

	$qorder = " ORDER BY LEAST(pw_division1.division_date, pw_division2.division_date) DESC";
	$qlimit = " LIMIT 1000"; # to stop the calculation running on forever

	$query = $qselect.$qfrom.$qjoin.$qwhere.$qorder.$qlimit;
	if ($bdebug == 1)
		print $query;
	$db->query($query);
	while ($row = $db->fetch_row_assoc())
	{
		update_divdiv_distance($db2, $row['division_date1'], $row['division_number1'], $row['division_id1'],
									 $row['division_date2'], $row['division_number2'], $row['division_id2'], $house);
	}
}



