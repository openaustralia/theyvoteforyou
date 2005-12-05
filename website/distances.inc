<?php
# $Id: distances.inc,v 1.12 2005/12/05 02:36:06 publicwhip Exp $

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
	return "sum(".matchvoteqstr($vote1, 1)." AND ".matchvoteqstr($vote2, 2).") AS nvotes$vote1$vote2";
}

# calculate the distance between two divisions from their ids
function update_divdiv_distance($db, $division_date1, $divid1, $division_date2, $divid2, $house)
{
	global $bdebug;

	# make the set of voting MPs in the first division
	$qselect = "SELECT 1 AS ssss, sum(1) AS nvotestotal, ";
	$qselect .= " SUM((".matchvoteqstr("no", 1)." AND ".matchvoteqstr("no", 2).") OR
					  (".matchvoteqstr("aye", 1)." AND ".matchvoteqstr("aye", 2).")) AS nvotessame, ";
	$qselect .= " SUM((".matchvoteqstr("aye", 1)." AND ".matchvoteqstr("no", 2).") OR
					  (".matchvoteqstr("no", 1)." AND ".matchvoteqstr("aye", 2).")) AS nvotesdiffer, ";
	$qselect .= " SUM(".matchvoteqstr("absent", 1)." AND ".matchvoteqstr("absent", 2).") AS nabsentabsent";

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


	$qattrs = "division_id, division_id2, ";

	$qvalues = "$divid1, $divid2, ";

	$qattrs .= "nvotespossible, nvotessame, nvotesdiff, nvotesabsent, ";
	$qvalues .= $row['nvotestotal'].", ".$row['nvotessame'].", ".$row['nvotesdiffer'].", ".$row['nabsentabsent'].", ";

	# calculate the distances
	$nsame = $row['nvotessame'];
	$ndiff = $row['nvotesdiffer'];
	$nabstainnon = $row['nvotestotal'] - ($row['nabsentabsent'] + $nsame + $ndiff);
	$distance = (1.0 * min($nsame, $ndiff) + 0.2 * $nabstainnon) / ($nsame + $ndiff + 0.2 * $nabstainnon);

	$qattrs .= "distance";
	$qvalues .= "$distance";

	if ($bdebug == 1)
		print "<h4>$qattrs</h4>";
	if ($bdebug == 1)
		print "<h4>$qvalues</h4>";
	$db->query("REPLACE INTO pw_cache_divdiv_distance ($qattrs) VALUES ($qvalues)");

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
					ON pw_cache_divdiv_distance.division_id = pw_division1.division_id
					AND pw_cache_divdiv_distance.division_id2 = pw_division2.division_id";
	$qwhere = " WHERE pw_division1.house = '$house' AND pw_division2.house = '$house'
				  AND pw_cache_divdiv_distance.distance IS null";

	if ($divattr)
		$qwhere .= " AND pw_division1.division_id = '".$divattr['division_id']."'";

	$qorder = " ORDER BY LEAST(pw_division1.division_id, pw_division2.division_id) DESC";
	#$qlimit = " LIMIT 2000"; # to stop the calculation running on forever on one run
	$qlimit = "";

	$query = $qselect.$qfrom.$qjoin.$qwhere.$qorder.$qlimit;
	if ($bdebug == 1)
		print $query;
	$db->query($query);
	while ($row = $db->fetch_row_assoc())
	{
		update_divdiv_distance($db2, $row['division_date1'], $row['division_id1'], $row['division_date2'], $row['division_id2'], $house);
	}
}



