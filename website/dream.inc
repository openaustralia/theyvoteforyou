<?php

include_once "wiki.inc";


# the equation that should be reused on the different places
function calc_dreammp_person_distance($nvotessame, $nvotessamestrong,
									  $nvotesdiffer, $nvotesdifferstrong,
									  $nvotesabsent, $nvotesabsentstrong)
{
	# absents have low weighting, except where it was 3-line
	# 3-line has higher than 3 to make it rise above the noise.
	$tlw = 5.0;
	$weight = $nvotessame + $tlw * $nvotessamestrong + $nvotesdiffer + $tlw * $nvotesdifferstrong +
			  0.2 * $nvotesabsent + $tlw * $nvotesabsentstrong;

	$score = $nvotesdiffer + $tlw * $nvotesdifferstrong + 0.1 * $nvotesabsent + ($tlw / 2) * $nvotesabsentstrong;
	if ($weight == 0.0)
		return -1.0;
	return $score / $weight;
}


# ensures rebuilds the table of dreammp counts across the board
# does all or just this one dreammp
# It's entries are considered out of date if they are blank,
# or you can force everything is $dreamid = "force"
function update_dreammp_votemeasures($db, $dreamid)
{
	global $bdebug;

	$qselect  = "SELECT pw_dyn_rollievote.rolliemp_id, COUNT(*) AS nvotes";
	$qselect .= ", SUM(pw_cache_divinfo.wiki_id IS NOT null) AS neditedmotions";

	# (no score from dreamMP absents or abstentions)

	$qfrom  = " FROM pw_dyn_rollievote";
	$qjoin .= " LEFT JOIN pw_cache_dreaminfo
					ON pw_cache_dreaminfo.rollie_id = pw_dyn_rollievote.rolliemp_id";

	# factor through division due to the division_id not being common
	$qjoin .= " LEFT JOIN pw_division
					ON pw_division.division_date = pw_dyn_rollievote.division_date
					AND pw_division.division_number = pw_dyn_rollievote.division_number";
	$qjoin .= " LEFT JOIN pw_cache_divinfo
					ON pw_cache_divinfo.division_id = pw_division.division_id";


	# fill in the holes, or do where there is none
	if ($dreamid == "force")
		$qwhere = " WHERE 1=1";
	elseif ($dreamid == null)
		$qwhere = " WHERE pw_cache_dreaminfo.cache_uptodate IS null";
	else
		$qwhere = " WHERE pw_cache_dreaminfo.rollie_id = $dreamid";

	$qgroup = " GROUP BY pw_cache_dreaminfo.rollie_id";
	$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup;
	if ($bdebug == 1)
		print "<h3>$query</h3>\n";
    $db->query($query);

	$rowarray = $db->fetch_rows_assoc();
    foreach ($rowarray as $row)
	{
		$nvotes = $row["nvotes"];
		$neditedmotions = $row["neditedmotions"];
		$query ="REPLACE INTO pw_cache_dreaminfo
				(rollie_id, cache_uptodate, votes_count, edited_motions_count)
				VALUES (".$row['rolliemp_id'].", ".($dreamid != null ? 1 : 0).", $nvotes, $neditedmotions)";
		$db->query($query);
	}
}



# calculate the distance to all MPs of one dreamMP
# "absent" means the MP was absent when the DreamMP voted
function update_dreammp_person_distance($db, $dreamid)
{
# update the number of votes and number of motions edited
# pw_cache_dreaminfo

	global $bdebug;
	$query = "SELECT cache_uptodate
			  FROM pw_cache_dreaminfo
			  WHERE rollie_id = $dreamid";
	$row = $db->query_onez_row_assoc($query); # allows no rows
	if ($row == null)
	{
		update_dreammp_votemeasures($db, $dreamid);
		$row = $db->query_one_row_assoc($query);
	}
	else
		update_dreammp_votemeasures($db, $dreamid); # forces the sums to add up properly
	if ($row["cache_uptodate"] == 1)
		return;
    if ($bdebug)
        print "<p>cache_uptodate: ".$row["cache_uptodate"]."</p>\n";

	# now go and rebuild all the distances

	$qselect = "SELECT pw_mp.person AS person, ";

	$qselect .= "SUM((pw_dyn_rollievote.vote = 'aye' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye'))
					 OR (pw_dyn_rollievote.vote = 'no' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno')))
					 AS nvotessame, ";
	$qselect .= "SUM((pw_dyn_rollievote.vote = 'aye3' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye'))
					 OR (pw_dyn_rollievote.vote = 'no3' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno')))
					 AS nvotessamestrong, ";
	$qselect .= "SUM((pw_dyn_rollievote.vote = 'aye' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno'))
					 OR (pw_dyn_rollievote.vote = 'no' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye')))
					 AS nvotesdiffer, ";
	$qselect .= "SUM((pw_dyn_rollievote.vote = 'aye3' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno'))
					 OR (pw_dyn_rollievote.vote = 'no3' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye')))
					 AS nvotesdifferstrong, ";
	$qselect .= "SUM((pw_dyn_rollievote.vote = 'aye' OR pw_dyn_rollievote.vote = 'no')
					 AND (pw_vote.vote = 'both' OR pw_vote.vote IS null))
					 AS nvotesabsent, ";
	$qselect .= "SUM((pw_dyn_rollievote.vote = 'aye3' OR pw_dyn_rollievote.vote = 'no3')
					 AND (pw_vote.vote = 'both' OR pw_vote.vote IS null))
					 AS nvotesabsentstrong, ";
	$qselect .= "SUM(pw_vote.vote IS NOT null)
					 AS nvotesoverlap ";

	# (no score from dreamMP absents or abstentions)

	$qfrom  = " FROM pw_dyn_rollievote";
	$qjoin  = " LEFT JOIN pw_division
					ON pw_division.division_date = pw_dyn_rollievote.division_date
					AND pw_division.division_number = pw_dyn_rollievote.division_number";
	$qjoin .= " LEFT JOIN pw_cache_divinfo
					ON pw_cache_divinfo.division_id = pw_division.division_id";
	$qjoin .= " LEFT JOIN pw_vote
					ON pw_vote.division_id = pw_division.division_id";
	$qjoin .= " LEFT JOIN pw_mp
					ON pw_mp.mp_id = pw_vote.mp_id";

	# we do for one dreammp against all the votes they share with each MP
	$qwhere = " WHERE pw_dyn_rollievote.rolliemp_id = $dreamid";
	$qgroup = " GROUP BY pw_mp.person";

	$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup;
	if ($bdebug == 1)
		print "<h2>$query</h2>";

	# do the database/scoring thing
	$db->query($query);
	$rowarray = $db->fetch_rows_assoc();
	if ($bdebug == 1)
		print "<h2>DONE</h2>";

	# lock and clear the table
	$db->query("LOCK TABLE pw_cache_dreamreal_distance WRITE");
	$db->query("DELETE FROM pw_cache_dreamreal_distance
				WHERE rollie_id = '$dreamid'");

	# this likes votes that are all one side or other
	$dconsistencyn = 0.0;
	$dconsistencyc = 0.0;

	foreach ($rowarray as $row)
	{
		if (!$row['nvotesoverlap']) # can't quite see how to filter these out in the query
			continue;
		$nvotessame = $row['nvotessame'];
		$nvotessamestrong = $row['nvotessamestrong'];
		$nvotesdiffer = $row['nvotesdiffer'];
		$nvotesdifferstrong = $row['nvotesdifferstrong'];
		$nvotesabsent = $row['nvotesabsent'];
		$nvotesabsentstrong = $row['nvotesabsentstrong'];
		$person = $row['person'];

		$distancea = calc_dreammp_person_distance($nvotessame, $nvotessamestrong,
											   	  $nvotesdiffer, $nvotesdifferstrong,
											   	  $nvotesabsent, $nvotesabsentstrong);

		# score without absentions
		$distanceb = calc_dreammp_person_distance($nvotessame, $nvotessamestrong,
											   	  $nvotesdiffer, $nvotesdifferstrong, 0, 0);

		if ($bdebug == 1)
			print "<p>mpnum ".$row['person']." distance $distancea vs $nvotessame</p>\n";

		$query   = "INSERT INTO pw_cache_dreamreal_distance
                    (rollie_id, person,
						nvotessame, nvotessamestrong,
						nvotesdiffer, nvotesdifferstrong,
						nvotesabsent, nvotesabsentstrong,
						distance_a, distance_b)
                	VALUES ($dreamid, $person,
						$nvotessame, $nvotessamestrong,
						$nvotesdiffer, $nvotesdifferstrong,
						$nvotesabsent, $nvotesabsentstrong,
						$distancea, $distanceb)";
		#if ($bdebug == 1)
		#	print "<h5>$query</h5>\n";
		$db->query($query);

		# quick hack until better formulae are found
		if ($distancea < 0.1 or $distancea > 0.9)
			$dconsistencyn += 1.0;
		$dconsistencyc += 1.0;
	}

	# unlock, then post update(?)
	$db->query("UNLOCK TABLES");


	$dconsistency = ($dconsistencyc != 0.0 ? $dconsistencyn / $dconsistencyc : 0.0);

    # Mark as updated
    $db->query("UPDATE pw_cache_dreaminfo
				SET cache_uptodate = 1, consistency_with_mps = $dconsistency
				WHERE rollie_id = $dreamid");
}





# Return score and what it is out of for how much the MP follows the "whip" of
# the Dream MP.  The "_a" here means this is scoring system A.
function calc_dream_mp_score_a($db, $dreamid, $personid) {
    $query = "select pw_vote.vote as mpvote, pw_dyn_rollievote.vote as rollievote from
        pw_vote, pw_dyn_rollievote, pw_division, pw_mp where
        pw_vote.division_id = pw_division.division_id and
        pw_dyn_rollievote.division_number = pw_division.division_number and
            pw_dyn_rollievote.division_date = pw_division.division_date
        and pw_vote.mp_id = pw_mp.mp_id
        and pw_mp.person = '" . $personid . "' and pw_dyn_rollievote.rolliemp_id = '$dreamid'";

    $db->query($query);
    $qrowarray = $db->fetch_rows_assoc();
    $t = 0.0;
    $c = 0.0;
    foreach ($qrowarray as $qrow)
    {
        $weight = 1;
        $mpvote = $qrow['mpvote'];
        $mpvote = str_replace("tell", "", $mpvote);
        $rollievote = $qrow['rollievote'];
        if ($rollievote == "aye3" or $rollievote == "no3") {
            $rollievote = str_replace("3", "", $rollievote);
            $weight = 3;
        }
        $t += $weight;

        if ($mpvote == $rollievote)
            $c += $weight;
        elseif ($mpvote == "both" or $rollievote == "both")
            $c = $c + ($weight / 2);
    }

    return array($c, $t);
}

# Query to return top Dream MPs, or all if count is none
function get_top_dream_query($count) {
    $query = "select name, pw_dyn_rolliemp.rollie_id, votes_count as count,
        round(100 * edited_motions_count / votes_count, 0) as motions_percent
        from pw_dyn_rolliemp, pw_cache_dreaminfo where
            pw_cache_dreaminfo.rollie_id = pw_dyn_rolliemp.rollie_id and votes_count > 0
            order by motions_percent desc, edited_motions_count desc, votes_count desc";
    if ($count)
        $query .= " limit $count";
    return $query;
}

# Returns HTML postcode search box for MP/DreamMP comparison.
function dream_box($dreamid, $dmp_name) {
    $html = '
<div style="position: relative; width: 23em; color: #000000;
background-color: #eeeeee; font-family: Verdana, Arial, Sans-serif;
margin: 0 0 0 0; border: 1px solid #003300; padding: 0 0 0 0;">
    <div style="text-align: center; background-color: #003300">
        <a href="http://www.publicwhip.org.uk" style="color: #ffffff">
            <img src="http://www.publicwhip.org.uk/smallpublicwhip.gif"
                alt="The Public Whip" border="0">
        </a>
    </div>
    <form style="text-align: left" action="http://www.publicwhip.org.uk/mp.php" name="pw">
        <p style="padding: 0 10px 0 10px">
            <b>'.html_scrub($dmp_name).'<br>How did your MP vote?</b>
            <br>Your postcode:
            <input maxLength="256" size="10" name="mppc" value="">
            <input type="hidden" name="display" value="motions">
            <input type="hidden" name="dmp" value="'.html_scrub($dreamid).'">
            <input type="submit" value="Go" name="button">
        </p>
    </form>
</div>
';
    return $html;
}

