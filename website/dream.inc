<?php
# $Id: dream.inc,v 1.65 2010/09/09 00:29:51 publicwhip Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once $toppath . "wiki.inc";
require_once $toppath . "forummagic.inc";

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

# write out an explanation of the calculation above
function print_dreammp_person_distance($nvotessame, $nvotessamestrong,
					  $nvotesdiffer, $nvotesdifferstrong,
					  $nvotesabsent, $nvotesabsentstrong,
					  $db, $person, $dreamid)
{
	global $bdebug;

	if ($bdebug == 1)
		print "<p>$person ddddd   $dreamid</p>";

    print "<table>";
    print "<tr class=\"headings\"><th></th></th><th>No of votes</th><th>Points</th><th>Out of</th></tr>";

    print "<tr class=\"jobevent\"><td>Most important votes (50 points)</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>";
    print "<tr class=\"evenstrong\"><td>MP voted with policy</td><td class=\"teller\">$nvotessamestrong</td><td>".(50*$nvotessamestrong)."</td><td>".(50*$nvotessamestrong)."</td></tr>";
    print "<tr class=\"evenstrong\"><td>MP voted against policy</td><td class=\"rebel\">$nvotesdifferstrong</td><td>".(0)."</td><td>".(50*$nvotesdifferstrong)."</td></tr>";
    print "<tr class=\"evenstrong\"><td>MP absent</td><td class=\"rebelteller\">$nvotesabsentstrong</td><td>".(25 * $nvotesabsentstrong)."</td><td>".(50 * $nvotesabsentstrong)."</td></tr>";

    print "<tr class=\"jobevent\"><td>Less important votes (10 points)</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>";
    print "<tr class=\"odd\"><td>MP voted with policy</td><td class=\"teller\">$nvotessame</td><td>".(10*$nvotessame)."</td><td>".(10*$nvotessame)."</td></tr>";
    print "<tr class=\"odd\"><td>MP voted against policy</td><td class=\"rebel\">$nvotesdiffer</td><td>".(0)."</td><td>".(10*$nvotesdiffer)."</td></tr>";
    print "<tr class=\"jobevent\"><td>Less important absentees (2 points)</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>";
    print "<tr class=\"odd\"><td>MP absent*</td><td class=\"rebelteller\">$nvotesabsent</td><td>".(1 * $nvotesabsent)."</td><td>".(2 * $nvotesabsent)."</td></tr>";

/*    print "<tr class=\"odd\"><td>MP voted with policy</td><td class=\"teller\">$nvotessame</td><td>&times;10=".(10*$nvotessame)."</td><td>&times;10=".(10*$nvotessame)."</td></tr>";
    print "<tr class=\"evenstrong\"><td>MP voted with (strong) policy</td><td class=\"teller\">$nvotessamestrong</td><td>&times;50=".(50*$nvotessamestrong)."</td><td>&times;50=".(50*$nvotessamestrong)."</td></tr>";
    print "<tr class=\"odd\"><td>MP voted against policy</td><td class=\"rebel\">$nvotesdiffer</td><td>&times;0=".(0)."</td><td>&times;10=".(10*$nvotesdiffer)."</td></tr>";
    print "<tr class=\"evenstrong\"><td>MP voted against (strong) policy</td><td class=\"rebel\">$nvotesdifferstrong</td><td>&times;0=".(0)."</td><td>&times;50=".(50*$nvotesdifferstrong)."</td></tr>";
    print "<tr class=\"odd\"><td>MP absent</td><td class=\"rebelteller\">$nvotesabsent</td><td>&times;1=".(1 * $nvotesabsent)."</td><td>&times;2=".(2 * $nvotesabsent)."</td></tr>";
    print "<tr class=\"evenstrong\"><td>MP absent (strong policy)</td><td class=\"rebelteller\">$nvotesabsentstrong</td><td>&times;25=".(25 * $nvotesabsentstrong)."</td><td>&times;50=".(50 * $nvotesabsentstrong)."</td></tr>";
*/
    $points_total = 10*$nvotessame + 50*$nvotessamestrong + 10*$nvotesdiffer + 50*$nvotesdifferstrong +  2*$nvotesabsent + 50 * $nvotesabsentstrong;
    $values_total = 10*$nvotessame + 50*$nvotessamestrong + 0*$nvotesdiffer + 0*$nvotesdifferstrong +  1*$nvotesabsent + 25*$nvotesabsentstrong;
    print "<tr class=\"jobevent\"><td colspan=\"2\">Total:</td><td>$values_total</td><td>$points_total</td></tr>";

    print "<tr><td colspan=\"4\"><p style=\"width: 35em;\"><small>*Pressure of
    other work means MPs or Lords are not always available to vote &ndash; it does not
    always indicate they have abstained. Therefore, being absent on a less important vote
    makes a disproportionatly small difference.</small></td></tr>";

 print "</table>";

	$dist = calc_dreammp_person_distance($nvotessame, $nvotessamestrong,
									  $nvotesdiffer, $nvotesdifferstrong,
									  $nvotesabsent, $nvotesabsentstrong);

	print "<p><div class=\"equals break\"> <b>agreement score</b> =&nbsp;</div>
		   <div class=\"fraction\">
		   		<span class=\"numerator\">MP's points</span>
 				   <hr class=\"divider\" />
		   		<span class=\"denominator\">total points</span>
		   </div>
		   <div class=\"equals break\">&nbsp;=&nbsp;</div>
		   <div class=\"fraction\">
		   		<span class=\"numerator\">$values_total</span>
 				   <hr class=\"divider\" />
		   		<span class=\"denominator\">$points_total</span>
		   </div>
		   <div class=\"equals break\">&nbsp;= <b>".number_format(100.0 * $values_total / ($points_total == 0 ? 1 : $points_total), 1)." %</b>.</div>
		   </p>\n\n<br clear=\"all\">\n";
}


# ensures rebuilds the table of dreammp counts across the board
# does all or just this one dreammp
# It's entries are considered out of date if they are blank,
# or you can force everything is $dreamid = "force"
function update_dreammp_votemeasures($db, $dreamid, $cache_uptodate_default)
{
    update_divisions_wiki_id($db);

	global $bdebug;
	global $pwpdo;

	$qselect  = "SELECT pw_dyn_dreamvote.dream_id, COUNT(*) AS nvotes";
	$qselect .= ", SUM(pw_cache_divwiki.wiki_id != -1) AS neditedmotions";

	# (no score from dreamMP absents or abstentions)

	$qfrom  = " FROM pw_cache_divwiki, pw_dyn_dreamvote";
	$qjoin .= " LEFT JOIN pw_cache_dreaminfo
					ON pw_cache_dreaminfo.dream_id = pw_dyn_dreamvote.dream_id";
	$placeheld=array();
	# fill in the holes, or do where there is none
	if ($dreamid == "force") {
  		$qwhere = " WHERE 1=1";
	} elseif ($dreamid == null) {
		$qwhere = " WHERE pw_cache_dreaminfo.cache_uptodate IS null";
	} else {
		$qwhere = " WHERE pw_dyn_dreamvote.dream_id = $dreamid";
		$placeheld[]=$dreamid;
	}
	$qwhere .= " AND pw_cache_divwiki.division_date = pw_dyn_dreamvote.division_date
					AND pw_cache_divwiki.division_number = pw_dyn_dreamvote.division_number";

	$qgroup = " GROUP BY pw_dyn_dreamvote.dream_id";
	$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup;

	$rowarray = $pwpdo->fetch_all_rows($query,$placeheld);
    foreach ($rowarray as $row)
	{
		$nvotes = $row["nvotes"];
		$neditedmotions = $row["neditedmotions"];
		$query ="REPLACE INTO pw_cache_dreaminfo
				(dream_id, cache_uptodate, votes_count, edited_motions_count)
 				VALUES (?,?,?,?)";
		$pwpdo->query($query,array($row['dream_id'],$cache_uptodate_default,$nvotes,$neditedmotions));
	}
}



# calculate the distance to all MPs of one dreamMP
# "absent" means the MP was absent when the DreamMP voted
function update_dreammp_person_distance($db, $dreamid)
{
    # update the number of votes and number of motions edited
#    print "update_dreammp_person_distance $dreamid<p>\n";

    global $pwpdo;
	global $bdebug;
	$query = "SELECT cache_uptodate
			  FROM pw_cache_dreaminfo
			  WHERE dream_id = ?";
    $row=$pwpdo->get_single_row($query,array($dreamid));
	if ($row == null) {
		update_dreammp_votemeasures($db, $dreamid, 0);
        $row=$pwpdo->get_single_row($query,array($dreamid));
		if ($row == null) {
			// case of no votes yet by Dream MP
			return;
		}
	}
	else
		update_dreammp_votemeasures($db, $dreamid, $row["cache_uptodate"]); # forces the sums to add up properly
	if ($row["cache_uptodate"] == 1)
		return;

	# now go and rebuild all the distances

	$qselect = "SELECT pw_mp.person AS person, ";

	$qselect .= "SUM((pw_dyn_dreamvote.vote = 'aye' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye'))
					 OR (pw_dyn_dreamvote.vote = 'no' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno')))
					 AS nvotessame, ";
	$qselect .= "SUM((pw_dyn_dreamvote.vote = 'aye3' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye'))
					 OR (pw_dyn_dreamvote.vote = 'no3' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno')))
					 AS nvotessamestrong, ";
	$qselect .= "SUM((pw_dyn_dreamvote.vote = 'aye' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno'))
					 OR (pw_dyn_dreamvote.vote = 'no' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye')))
					 AS nvotesdiffer, ";
	$qselect .= "SUM((pw_dyn_dreamvote.vote = 'aye3' AND (pw_vote.vote = 'no' OR pw_vote.vote = 'tellno'))
					 OR (pw_dyn_dreamvote.vote = 'no3' AND (pw_vote.vote = 'aye' OR pw_vote.vote = 'tellaye')))
					 AS nvotesdifferstrong, ";
	$qselect .= "SUM((pw_dyn_dreamvote.vote = 'aye' OR pw_dyn_dreamvote.vote = 'no')
					 AND (pw_vote.vote = 'both' OR pw_vote.vote IS null))
					 AS nvotesabsent, ";
	$qselect .= "SUM((pw_dyn_dreamvote.vote = 'aye3' OR pw_dyn_dreamvote.vote = 'no3')
					 AND (pw_vote.vote = 'both' OR pw_vote.vote IS null))
					 AS nvotesabsentstrong, ";
	$qselect .= "SUM(pw_vote.vote IS NOT null)
					 AS nvotesoverlap ";

	# (no score from dreamMP absents or abstentions)

	$qfrom  = " FROM pw_mp";
	$qjoin = " LEFT JOIN pw_dyn_dreamvote ON pw_dyn_dreamvote.dream_id = ?";
	$qjoin .= " LEFT JOIN pw_division
					ON pw_division.division_date = pw_dyn_dreamvote.division_date
					AND pw_division.division_number = pw_dyn_dreamvote.division_number
					AND pw_division.house = pw_dyn_dreamvote.house";
	$qjoin .= " LEFT JOIN pw_cache_divinfo
					ON pw_cache_divinfo.division_id = pw_division.division_id";
	$qjoin .= " LEFT JOIN pw_vote
					ON pw_vote.division_id = pw_division.division_id
					AND pw_vote.mp_id = pw_mp.mp_id";

	# we do for one dreammp against all the votes they share with each MP
	$qwhere = " WHERE pw_mp.entered_house <= pw_division.division_date
				   AND pw_mp.left_house > pw_division.division_date
                   AND pw_mp.house = pw_division.house";
	$qgroup = " GROUP BY pw_mp.person";

	$query = $qselect.$qfrom.$qjoin.$qwhere.$qgroup;

	# do the database/scoring thing
    $rowarray=$pwpdo->fetch_all_rows($query,array($dreamid));

	# lock and clear the table
    $pwpdo->query('LOCK TABLE pw_cache_dreamreal_distance WRITE',array());
    $pwpdo->query('DELETE FROM pw_cache_dreamreal_distance WHERE dream_id = ?',array($dreamid));

	# this likes votes that are all one side or other
	$dconsistencyn = 0.0;
	$dconsistencyc = 0.0;

	foreach ($rowarray as $row)
	{
		if (!$row['nvotesoverlap']) { # can't quite see how to filter these out in the query
            #print "nvotesoverlap ".$row['person']."\n";
            #print_r($row);

            # Actually, don't bother filtering it! We want to know when somebody didn't
            # attend all the votes on one subject, and need that recording in table. Can
            # check for their being no common attendance elsewhere.
            #continue

            if (!$row['nvotessame']) {
                $row['nvotessame']= 0;
            }
            if (!$row['nvotessamestrong']) {
                $row['nvotessamestrong']= 0;
            }
            if (!$row['nvotesdiffer']) {
                $row['nvotesdiffer']= 0;
            }
            if (!$row['nvotesdifferstrong']) {
                $row['nvotesdifferstrong']= 0;
            }
            if (!$row['nvotesabsent']) {
                $row['nvotesabsent']= 0;
            }
            if (!$row['nvotesabsentstrong']) {
                $row['nvotesabsentstrong']= 0;
            }
        }
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


		$query   = "INSERT INTO pw_cache_dreamreal_distance
                    (dream_id, person,
						nvotessame, nvotessamestrong,
						nvotesdiffer, nvotesdifferstrong,
						nvotesabsent, nvotesabsentstrong,
						distance_a, distance_b)
                	VALUES (?,?,?,?,
                	?,?,?,?,
					?,?)";
		$placeholders=array($dreamid,$person,$nvotessame, $nvotessamestrong,
            $nvotesdiffer, $nvotesdifferstrong,$nvotesabsent, $nvotesabsentstrong,
            $distancea, $distanceb);

        $pwpdo->query($query,$placeholders);

		# quick hack until better formulae are found
		if ($distancea < 0.1 or $distancea > 0.9)
			$dconsistencyn += 1.0;
		$dconsistencyc += 1.0;
	}

	# unlock, then post update(?)
	$pwpdo->query("UNLOCK TABLES",array());


	$dconsistency = ($dconsistencyc != 0.0 ? $dconsistencyn / $dconsistencyc : 0.0);

    # Mark as updated
    $pwpdo->query('UPDATE pw_cache_dreaminfo
				SET cache_uptodate = 1, consistency_with_mps = ?
				WHERE dream_id =?',array($dconsistency,$dreamid));
}

# Return score and what it is out of for how much the MP follows the "whip" of
# the Dream MP.  The "_a" here means this is scoring system A.
function calc_dream_mp_score_a($db, $dreamid, $personid) {
    global $pwpdo;
    $query = "select pw_vote.vote as mpvote, pw_dyn_dreamvote.vote as dreamvote from
        pw_vote, pw_dyn_dreamvote, pw_division, pw_mp where
        pw_vote.division_id = pw_division.division_id and
        pw_dyn_dreamvote.division_number = pw_division.division_number and
            pw_dyn_dreamvote.division_date = pw_division.division_date
        and pw_vote.mp_id = pw_mp.mp_id
        and pw_mp.person = ? and pw_dyn_dreamvote.dream_id = ?";

    $qrowarray=$pwpdo->fetch_all_rows($query,array($personid,$dreamid));
    $t = 0.0;
    $c = 0.0;
    foreach ($qrowarray as $qrow)
    {
        $weight = 1;
        $mpvote = $qrow['mpvote'];
        $mpvote = str_replace("tell", "", $mpvote);
        $dreamvote = $qrow['dreamvote'];
        if ($dreamvote == "aye3" or $dreamvote == "no3") {
            $dreamvote = str_replace("3", "", $dreamvote);
            $weight = 3;
        }
        $t += $weight;

        if ($mpvote == $dreamvote)
            $c += $weight;
        elseif ($mpvote == "both" or $dreamvote == "both")
            $c = $c + ($weight / 2);
    }

    return array($c, $t);
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
                alt="The Public Whip" border="0" style="float:none">
        </a>
    </div>
    <form style="text-align: left" action="http://www.publicwhip.org.uk/mp.php" name="pw">
        <p style="padding: 0 10px 0 10px">
            <b>'.html_scrub($dmp_name).'<br>How did your MP vote?</b>
            <br>Your postcode:
            <input maxLength="256" size="10" name="mppc" value="">
            <input type="hidden" name="dmp" value="'.html_scrub($dreamid).'">
            <input type="submit" value="Go" name="button">
        </p>
    </form>
</div>
';
    return $html;
}

# Post action made to Dream MP into the forum for record keeping, notification etc.
function dream_post_forum_action($db, $dreamid, $content) {
    global $pwpdo;
    $forum = "Policy Forum";
    $topic_match = "Policy #$dreamid";
	$query = "SELECT name, private FROM pw_dyn_dreammp WHERE dream_id = ?";
	list ($name, $private) =$pwpdo->get_single_row($query,array($dreamid)); # allows no rows
    $topic = $topic_match . " - " . $name;
    if ($private != 1)
        forummagic_post($db, $forum, $topic_match, $topic, $content);
}

# Get link to forum
function dream_post_forum_link($db, $dreamid) {
    $forum = "Policy Forum";
    $topic_match = "Policy #$dreamid";
    return forummagic_getlink($db, $forum, $topic_match);
}

# Used to freeze a policy entirely (e.g. during an Election campaign)
function policy_totally_frozen($dreamid) {
    #return in_array($dreamid, array(1049, 1053, 1050, 363, 826, 1051, 1052, 856, 811, 975, 996, 984, 1030,
    #                837, 1071, 1074, 1077, 1079, 1080));
    return false;
}


