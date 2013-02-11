<?php
# $Id: distances.inc,v 1.29 2009/05/25 13:57:19 marklon Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# FIXME: in adding cases for explicit abstentions (where vote = 'abstention')
# for the Scottish Parliament, I've just added the abstention case to whether
# votes agree or disagree.  Probably there should be more careful changes, so
# that "both" in Westminster and "abstention" in Edinburgh are both treated
# as being first class abstentions - treating "both" and absences the same is
# a bit odd.  However, my first priority is to not break the existing code
# (which is a little brittle by this stage) so I'm just making the simpler
# changes...

function matchvoteqstr($vote, $votenumber)
{
	if ($vote == "absent")
		return "(pw_vote$votenumber.vote = 'both' OR pw_vote$votenumber.vote IS null)";
	elseif ($vote == "abstention")
		return "(pw_vote$votenumber.vote = 'abstention')";
	return "(pw_vote$votenumber.vote = '$vote' OR pw_vote$votenumber.vote = 'tell$vote')";
}

# FIXME: Appears not to be used anywhere any more:
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
                      (".matchvoteqstr("abstention", 1)." AND ".matchvoteqstr("abstention",2).") OR
					  (".matchvoteqstr("aye", 1)." AND ".matchvoteqstr("aye", 2).")) AS nvotessame, ";
	$qselect .= " SUM((".matchvoteqstr("aye", 1)." AND (".matchvoteqstr("no", 2)." OR ".matchvoteqstr("abstention",2).")) OR
					  (".matchvoteqstr("no", 1)." AND (".matchvoteqstr("aye", 2)." OR ".matchvoteqstr("abstention",2).")) OR
                      (".matchvoteqstr("abstention",1)." AND (".matchvoteqstr("aye",2)." OR ".matchvoteqstr("no",2)."))) AS nvotesdiffer, ";
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
    for ($i = 0; $i < 2; ++$i) {
        $delme = array();
        $suffix = $i ? "2" : "";
        $qselect = "SELECT pw_cache_divdiv_distance.division_id$suffix";
        $qfrom = " FROM pw_cache_divdiv_distance
              LEFT JOIN pw_division 
               ON pw_division.division_id = pw_cache_divdiv_distance.division_id$suffix
              WHERE pw_division.division_id IS null GROUP BY pw_cache_divdiv_distance.division_id$suffix
              ";
        #print "$qselect $qfrom\n";
        $db->query($qselect.$qfrom);
        while ($row = $db->fetch_row()) {
            $delme[] = $row[0];
        }

        #print "selected ".count($delme)." rows for deletion"; 
        if (count($delme) > 0) {
            $query = "delete from pw_cache_divdiv_distance where 
                division_id$suffix in (" . join(",", $delme).")";
            $db->query($query);
        }
    }
}

# Fill in missing entries in chunks until all done
function fill_division_distances($db, $db2, $house, $divattr) {
	remove_dead_division_distances($db);
	$some_done = 1;
	while($some_done) {
		$some_done = fill_division_distances_internal($db, $db2, $house, $divattr, 5000);
		#print "done...";
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

	$qfrom = " FROM pw_division AS pw_division1 ";
    $qjoin = " LEFT JOIN pw_division AS pw_division2 
                    ON pw_division1.house = pw_division2.house ";
	$qjoin .= " LEFT JOIN pw_cache_divdiv_distance
					ON pw_cache_divdiv_distance.division_id = pw_division1.division_id
					AND pw_cache_divdiv_distance.division_id2 = pw_division2.division_id";
	$qwhere = " WHERE pw_cache_divdiv_distance.distance IS null
                    AND pw_division1.house = '$house'";

	if ($divattr)
		$qwhere .= " AND pw_division1.division_id = '".$divattr['division_id']."'";

	#$qorder = " ORDER BY LEAST(pw_division1.division_id, pw_division2.division_id) DESC";
	if ($batchnumber)
		$qlimit = " LIMIT $batchnumber"; # to stop the calculation running on forever on one run

	$query = $qselect.$qfrom.$qjoin.$qwhere.$qorder.$qlimit;

	$db->query($query);
	$some_done = 0;
	while ($row = $db->fetch_row_assoc())
	{
		$some_done = 1;
        #print_r($row);
        if (!$row['division_id1'] || !$row['division_id2']) {
            print "divdiv query missing id";
        } else {
            update_divdiv_distance($db2, $row['division_date1'], $row['division_id1'], $row['division_date2'], $row['division_id2'], $house);
        }
	}
	return $some_done;
}


# write out an explanation of the calculation above
function print_divdiv_distance( $divattr1, $divattr2, $housenoun)
{
	global $bdebug;
    global $pwpdo;

	$query = "SELECT nvotespossible, nvotessame, nvotesdiff, nvotesabsent, distance
			  FROM pw_cache_divdiv_distance
			  WHERE division_id = ?	AND division_id2 = ?";

    $row=$pwpdo->get_single_row($query,array($divattr1['division_id'],$divattr2['division_id']));
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

}



// delete old entries by removing ones whose left_house comes >= last update time
function delete_mpid_outofdate_distances($db, $lastupdatedate, $house)
{
	$lastupdatedate = "2005-01-01";
	$qdelete = "DELETE pw_cache_realreal_distance";
	$qfrom =  " FROM pw_cache_realreal_distance";
	$qjoin =  " LEFT JOIN pw_mp AS pw_mp1
					ON pw_mp1.mp_id = pw_cache_realreal_distance.mp_id1";
	$qjoin .= " LEFT JOIN pw_mp AS pw_mp2
					ON pw_mp2.mp_id = pw_cache_realreal_distance.mp_id2";
	$qwhere = " WHERE pw_mp1.left_house >= '$lastupdatedate'
					AND pw_mp2.left_house >= '$lastupdatedate'";
	$query = $qdelete.$qfrom.$qjoin.$qwhere;
	$db->query($query);
}

# then we loop through the missing entries and fill them in
function fill_mpid_distances_internal($db, $db2, $house, $batchnumber)
{
	# find missing entries in the table
	$qselect = "SELECT pw_mp1.mp_id AS mp_id1, pw_mp2.mp_id AS mp_id2,
					   GREATEST(pw_mp1.entered_house, pw_mp2.entered_house) AS max_entered_house, 
                       LEAST(pw_mp1.left_house, pw_mp2.left_house) AS min_left_house";

	$qfrom = " FROM pw_mp AS pw_mp1";
    $qjoin = " LEFT JOIN pw_mp AS pw_mp2 ON pw_mp1.house = pw_mp2.house
                            AND pw_mp1.mp_id <= pw_mp2.mp_id
                            AND pw_mp1.entered_house < pw_mp2.left_house
                            AND pw_mp1.left_house > pw_mp2.entered_house";

	$qjoin .= " LEFT JOIN pw_cache_realreal_distance
					ON pw_cache_realreal_distance.mp_id1 = pw_mp1.mp_id
					AND pw_cache_realreal_distance.mp_id2 = pw_mp2.mp_id";

	// we only do the lower diagonal
	$qwhere = " WHERE pw_cache_realreal_distance.distance_a IS null";
	// Some of these are NULL now; ignore those cases:
	$qwhere .= " AND pw_mp1.entered_house IS NOT NULL";
	$qwhere .= " AND pw_mp2.entered_house IS NOT NULL";
	$qwhere .= " AND pw_mp1.left_house IS NOT NULL";
	$qwhere .= " AND pw_mp2.left_house IS NOT NULL";
	// Ignore any MP who left parliament before the 1997 general election:
	$qwhere .= " AND pw_mp1.left_house > date '1997-05-01'";
	$qwhere .= " AND pw_mp2.left_house > date '1997-05-01'";
	if ($house)
		$qwhere .= " AND pw_mp1.house = '$house'";
# $qwhere .= " AND pw_mp1.mp_id > 1200"; 

#	$qorder = " ORDER BY pw_mp1.mp_id, pw_mp2.mp_id DESC";
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
        update_realreal_distance($db2, $row['mp_id1'], $row['mp_id2'], $row['max_entered_house'], $row['min_left_house'], $house);
	}
	return $some_done;
}



# then we loop through the missing entries and fill them in
function update_realreal_distance($db, $mp_id1, $mp_id2, $max_entered_house, $min_left_house, $house)
{
	# make the set of voting MPs in the first division
	$qselect = "SELECT 1 AS ssss, sum(1) AS nvotestotal, ";

	$qselect .= "SUM(((pw_vote1.vote = 'aye' OR pw_vote1.vote = 'tellaye') AND
                            (pw_vote2.vote = 'aye' OR pw_vote2.vote = 'tellaye'))
					 OR ((pw_vote1.vote = 'no' OR pw_vote1.vote = 'tellno') AND
                            (pw_vote2.vote = 'no' OR pw_vote2.vote = 'tellno'))
                     OR ((pw_vote1.vote = 'abstention') AND (pw_vote2.vote = 'abstention')))
					 AS nvotessame, ";
	$qselect .= "SUM(((pw_vote1.vote = 'aye' OR pw_vote1.vote = 'tellaye') AND
                            (pw_vote2.vote = 'no' OR pw_vote2.vote = 'tellno' OR pw_vote2.vote = 'abstention'))
					 OR ((pw_vote1.vote = 'no' OR pw_vote1.vote = 'tellno') AND
                            (pw_vote2.vote = 'aye' OR pw_vote2.vote = 'tellaye' OR pw_vote2.vote = 'abstention'))
					 OR ((pw_vote1.vote = 'abstention') AND
                            (pw_vote2.vote = 'aye' OR pw_vote2.vote = 'tellaye' OR pw_vote2.vote = 'no' OR pw_vote2.vote = 'tellno')))
					 AS nvotesdiffer, ";
	$qselect .= "SUM((pw_vote1.vote = 'both' OR pw_vote1.vote IS null)
					 AND (pw_vote2.vote = 'both' OR pw_vote2.vote IS null))
					 AS nvotesabsentboth, ";
	$qselect .= "SUM((pw_vote1.vote = 'both' OR pw_vote1.vote IS null)
					 AND not (pw_vote2.vote = 'both' OR pw_vote2.vote IS null))
					 AS nvotesabsentfirst, ";
	$qselect .= "SUM(not (pw_vote1.vote = 'both' OR pw_vote1.vote IS null)
					 AND (pw_vote2.vote = 'both' OR pw_vote2.vote IS null))
					 AS nvotesabsentsecond ";

	$qfrom =  " FROM pw_division";
	$qwhere = " WHERE pw_division.division_date >= '$max_entered_house'
				   AND pw_division.division_date < '$min_left_house'
				   AND pw_division.house = '$house'";

	# now line up the votes (including the missing ones)
	$qjoin =  " LEFT JOIN pw_vote AS pw_vote1
					ON pw_vote1.division_id = pw_division.division_id
					AND pw_vote1.mp_id = $mp_id1";

	# now line up the mps who could have voted on the second division
	$qjoin .= " LEFT JOIN pw_vote AS pw_vote2
					ON pw_vote2.division_id = pw_division.division_id
					AND pw_vote2.mp_id = $mp_id2";

	$qgroup = " GROUP BY ssss"; # sum all rows

	$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup;

	$row = $db->query_onez_row_assoc($query); # can get zero if no divisions in overlap

	$nvotessame = ($row['nvotessame'] ? $row['nvotessame'] : 0);
	$nvotesdiff = ($row['nvotesdiffer'] ? $row['nvotesdiffer'] : 0);
	$nabsentboth = ($row['nvotesabsentboth'] ? $row['nvotesabsentboth'] : 0);
	$nabsentfirst = ($row['nvotesabsentfirst'] ? $row['nvotesabsentfirst'] : 0);
	$nabsentsecond = ($row['nvotesabsentfirst'] ? $row['nvotesabsentfirst'] : 0);

	$nvotesabsent = $nabsentfirst + $nabsentsecond;
	$distancea = calc_dreammp_person_distance($nvotessame, 0,
										   	  $nvotesdiff, 0,
										   	  $nvotesabsent, 0);
	# score without absentions
	$distanceb = calc_dreammp_person_distance($nvotessame, 0,
										   	  $nvotesdiff, 0,
                                                  0, 0);


	$qattrs = "mp_id1, mp_id2, nvotessame, nvotesdiffer, nvotesabsent, distance_a, distance_b";
	$qvalues = "$mp_id1, $mp_id2, $nvotessame, $nvotesdiff, $nvotesabsent, $distancea, $distanceb";
    #print $qvalues."\n"; 

	$query  = "INSERT INTO pw_cache_realreal_distance ($qattrs) VALUES ($qvalues)";
	$db->query($query);
}


function fill_mp_distances($db, $db2, $house) {
	$some_done = 1;
	while($some_done) {
	    $some_done = fill_mpid_distances_internal($db, $db2, $house, 5000);
		#print "done...";
	}
}

