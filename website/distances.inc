<?php
# $Id: distances.inc,v 1.19 2006/02/16 23:30:58 publicwhip Exp $

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

	$nsame = $row['nvotessame'] ? $row['nvotessame'] : 0;
	$ndiff = $row['nvotesdiffer'] ? $row['nvotesdiffer'] : 0;

	$qattrs = "division_id, division_id2, ";
	$qvalues = "$divid1, $divid2, ";

	$qattrs .= "nvotespossible, nvotessame, nvotesdiff, nvotesabsent, ";
	$qvalues .= $row['nvotestotal'].", ".$nsame.", ".$ndiff.", ".$row['nabsentabsent'].", ";

	# calculate the distances
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


# remove distances to divisions that are no longer in our table
# due to a messup with the corrections not matching in vote list and being 
# merged later, such divisions get removed 
# and reloaded into the database every time it updates
function remove_dead_division_distances($db)
{
	$qselect = "SELECT pw_cache_divdiv_distance.division_id, pw_cache_divdiv_distance.division_id2"; 
	$qdelete = "DELETE pw_cache_divdiv_distance"; 
	$qfrom = " FROM pw_cache_divdiv_distance
		  LEFT JOIN pw_division AS pw_division1 
		   ON pw_division1.division_id = pw_cache_divdiv_distance.division_id
		  LEFT JOIN pw_division AS pw_division2
		   ON pw_division2.division_id = pw_cache_divdiv_distance.division_id2
		  WHERE pw_division1.division_id IS null 
		     OR pw_division2.division_id IS null"; 

#we need to change the qselect to qdelete in this line. and make sure it works
$db->query($qselect.$qfrom);
	print "<h4>Selecting for deletion rows ".$db->rows()."</h4>"; 
}

# Fill in missing entries in chunks until all done
function fill_division_distances($db, $db2, $house, $divattr) {
	remove_dead_division_distances($db); # not yet actually doing it 
	$some_done = 1;
	while($some_done) {
		$some_done = fill_division_distances_internal($db, $db2, $house, $divattr, 5000);
		print "done...";
	}
}

# then we loop through the missing entries and fill them in
function fill_division_distances_internal($db, $db2, $house, $divattr, $batchnumber)
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
	if ($batchnumber)
		$qlimit = " LIMIT $batchnumber"; # to stop the calculation running on forever on one run

	$query = $qselect.$qfrom.$qjoin.$qwhere.$qorder.$qlimit;
	if ($bdebug == 1)
		print $query;
	$db->query($query);
	$some_done = 0;
	while ($row = $db->fetch_row_assoc())
	{
		$some_done = 1;
		update_divdiv_distance($db2, $row['division_date1'], $row['division_id1'], $row['division_date2'], $row['division_id2'], $house);
	}
	return $some_done;
}


# write out an explanation of the calculation above
function print_divdiv_distance($db, $divattr1, $divattr2, $housenoun)
{
	global $bdebug;

	$query = "SELECT nvotespossible, nvotessame, nvotesdiff, nvotesabsent, distance
			  FROM pw_cache_divdiv_distance
			  WHERE division_id = ".$divattr1['division_id']."
			  	AND division_id2 = ".$divattr2['division_id'];
	$row = $db->query_onez_row_assoc($query);
	if (!$row)
	{
		print "<p>This particular comparison seems to be missing from our database</p>";
		return;
	}

	$nvotespossible = $row['nvotespossible'];
	$nvotessame = $row['nvotessame'];
	$nvotesdiff = $row['nvotesdiff'];
	$nvotesabsent = $row['nvotesabsent'];
	$nvotesabstainnon = $nvotespossible - ($nvotessame + $nvotesdiff + $nvotesabsent);

	print "<p class=\"indent\">There were
				$nvotespossible ".make_plural($nvotespossible, $housenoun)." who could have voted in both of these divisions,
				and $nvotessame voted the same way, with $nvotesdiff voting in opposite ways.
				There were $nvotesabsent ".make_plural($nvotesabsent, $housenoun)." who didn't vote in either division,
				and $nvotesabstainnon who voted in only one of them.</p>";

	print "<p>We invert the vote on the second division if it makes the distance closer (since the meaning of
			  'Aye' and 'No' are often interchangeable depending on how the question was put).
			  In this case, they line up ".($nvotessame >= $nvotesdiff ? "the same way" : "on opposite sides").".
			  An ".$housenounvote."'s vote in in only one of the divisions contributes a factor of 0.2 to the distance.
			  The calculation runs as follows:</p>";


	#$distance = (1.0 * min($nsame, $ndiff) + 0.2 * $nabstainnon) / ($nsame + $ndiff + 0.2 * $nabstainnon);
	$samevotes = max($nvotessame, $nvotesdiff);
	$diffvotes = min($nvotessame, $nvotesdiff);
	$weight = $samevotes + $diffvotes + 0.2 * $nvotesabstainnon;
	$agreement = 1.0 - $row['distance'];
	$agreementpercent = 100 * $agreement;
	print "<p><div class=\"equals break\"> <b>ratio</b> = </div>
		   <div class=\"fraction\">
		   		<span class=\"numerator\">[same-votes]</span>
				   <hr class=\"divider\" />
		   		<span class=\"denominator\">([same-votes] + [differing-votes] + 0.2x[abstain-in-one])</span>
		   </div>
			  <div class=\"equals break\">=</div>
		   <div class=\"fraction\">
		   		<span class=\"numerator\">$samevotes</span>
				   <hr class=\"divider\" />
		   		<span class=\"denominator\">($samevotes + $diffvotes + 0.2x$nvotesabstainnon)</span>
		   </div>
			  <div class=\"equals\">=</div>
		   <div class=\"fraction\">
		   		<span class=\"numerator\">$samevotes</span>
 				   <hr class=\"divider\" />
		   		<span class=\"denominator\">$weight</span>
		   </div>
			  <div class=\"equals\">=
		   ".number_format($agreement, 3)."
			  =
		   <b>".number_format($agreementpercent, 1)." %</b>.</div>
		   </p>\n\n<br clear=\"all\">\n";

	print "<p>Please post comments and feedback about this equation in
			<a href=\"forum/viewtopic.php?t=825\">our forum</a>.</p>\n";
}

function fill_mp_distances($db, $db2) {
    $bdebug = 1;
	$qselect = "SELECT pw_vote.mp_id AS mp_id";#, mp_person.person AS person ";

/*	$qselect .= "SUM(((person_vote.vote = 'aye' OR person_vote.vote = 'tellaye') AND 
                            (mp_vote.vote = 'aye' OR mp_vote.vote = 'tellaye'))
					 OR ((person_vote.vote = 'no' OR person_vote.vote = 'tellno') AND 
                            (mp_vote.vote = 'no' OR mp_vote.vote = 'tellno')))
					 AS nvotessame, ";
	$qselect .= "SUM(((person_vote.vote = 'aye' OR person_vote.vote = 'tellaye') AND 
                            (mp_vote.vote = 'no' OR mp_vote.vote = 'tellno'))
					 OR ((person_vote.vote = 'no' OR person_vote.vote = 'tellno') AND 
                            (mp_vote.vote = 'aye' OR mp_vote.vote = 'tellaye')))
					 AS nvotesdiffer, ";
	$qselect .= "SUM(mp_vote.vote <> 'both'
					 AND (person_vote.vote = 'both' OR person_vote.vote IS null))
					 AS nvotesabsent, ";
	$qselect .= "SUM(person_vote.vote IS NOT null)
					 AS nvotesoverlap ";
*/
	# (no score from dreamMP absents or abstentions)

	$qfrom  = " FROM pw_vote \n";
	$qjoin = " LEFT JOIN pw_mp 
					ON pw_mp.mp_id = pw_vote.mp_id\n";
    $qjoin .= " LEFT JOIN pw_division
        			ON pw_division.division_id = pw_vote.division_id\n";
	$qjoin .= " LEFT JOIN pw_mp AS mp_person
                    ON mp_person.house = pw_division.house AND
                    mp_person.entered_house <= pw_division.division_date AND
                    pw_division.division_date < mp_person.left_house\n";
#	$qjoin .= " LEFT JOIN pw_vote AS person_vote
#					ON person_vote.mp_id = mp_person.mp_id\n";

	$qgroup = " GROUP BY pw_vote.mp_id, mp_person.person";  

	$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup." LIMIT 10";
	if ($bdebug == 1)
		print "$query\n";
#$query = " SELECT pw_vote.mp_id FROM pw_vote 
#                left join pw_division on pw_division.division_id = pw_vote.division_id
#                left join pw_mp on pw_mp.mp_id = pw_vote.mp_id
#                group By pw_vote.mp_id LIMIT 10"; 

	# do the database/scoring thing
    print "DddOING QUERY\n";
	$db->query($query);
    print "DNE QUERY\n"; exit;
	$rowarray = $db->fetch_rows_assoc();
	if ($bdebug == 1)
		print "DONE\n";

	# lock and clear the table
	$db->query("LOCK TABLE pw_cache_realreal_distance WRITE");
	$db->query("DELETE FROM pw_cache_realreal_distance ");

	# this likes votes that are all one side or other
	foreach ($rowarray as $row)
	{
		if (!$row['nvotesoverlap']) # can't quite see how to filter these out in the query
			continue;
		$nvotessame = $row['nvotessame'];
		$nvotesdiffer = $row['nvotesdiffer'];
		$nvotesabsent = $row['nvotesabsent'];
		$person = $row['person'];
		$mp_id = $row['mp_id'];

		$distancea = calc_dreammp_person_distance($nvotessame, 0,
											   	  $nvotesdiffer, 0,
											   	  $nvotesabsent, 0);

		# score without absentions
		$distanceb = calc_dreammp_person_distance($nvotessame, 0,
											   	  $nvotesdiffer, 0, 
                                                  0, 0);

		if ($bdebug == 1)
			print "<p>mpmpdist $person $mp_id distance $distancea vs $nvotessame</p>\n";

		$query   = "INSERT INTO pw_cache_realreal_distance
                    (mp_id, person,
						nvotessame, 
						nvotesdiffer, 
						nvotesabsent,
						distance_a, distance_b)
                	VALUES ($mp_id, $person,
						$nvotessame, 
						$nvotesdiffer,
						$nvotesabsent,
						$distancea, $distanceb)";
		#if ($bdebug == 1)
		#	print "<h5>$query</h5>\n";
		$db->query($query);
	}
	$db->query("UNLOCK TABLES");
}
/*
"create table pw_cache_mpdist (
    mp_id_1 int not null,
    mp_id_2 int not null,
    distance float not null,
    unique(mp_id_1, mp_id_2)
i
CREATE TABLE `pw_cache_realreal_distance` (
  `mp_id` int(11) NOT NULL default '0',
  `person` int(11) NOT NULL default '0',
  `nvotessame` int(11) default NULL,
  `nvotesdiffer` int(11) default NULL,
  `nvotesabsent` int(11) default NULL,
  `distance_a` float default NULL,
  `distance_b` float default NULL,
  UNIQUE KEY `mp_id_2` (`mp_id`,`person`),
  KEY `mp_id` (`mp_id`),
  KEY `person` (`person`)
)

*/
