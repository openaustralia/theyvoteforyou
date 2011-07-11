#!/usr/bin/php -q
<?php
# $Id: calc_caches.php,v 1.18 2010/09/20 15:26:40 publicwhip Exp $

# Calculate lots of cache tables, run after update.

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../website/config.php";
require_once "../website/db.inc";
require_once "../website/parliaments.inc";

$db = new DB();
$db2 = new DB();

current_rankings($db);
count_party_stats($db, $db2);
guess_whip_for_all($db, $db2);
count_mp_info($db);
count_div_info($db);

# then we loop through the missing entries and fill them in
function count_party_stats($db, $db2)
{
    # TODO: redo this per parliament
	$db->query("DROP TABLE IF EXISTS pw_cache_partyinfo");
	$db->query("CREATE TABLE pw_cache_partyinfo (
						party varchar(100) not null,
						house enum('commons', 'lords', 'scotland') not null,
						total_votes int not null
                        )");

	$query = "SELECT party, house, COUNT(vote) AS total_votes
			  FROM pw_vote
			  LEFT JOIN pw_mp ON pw_vote.mp_id = pw_mp.mp_id
              WHERE party IS NOT NULL
			  GROUP BY party, house";

    #print $query;
	$db->query($query);

	while ($row = $db->fetch_row_assoc())
	{
        #print_r($row);
		$qattrs = "party, house, total_votes";
		$qvalues = "'".$row['party']."', '".$row['house']."', '".$row['total_votes']."'";
		$db2->query("INSERT INTO pw_cache_partyinfo ($qattrs) VALUES ($qvalues)");
    };
}


# party whip calc everything
function guess_whip_for_all($db, $db2)
{
	# this table runs parallel to the table of divisions
	$db->query("DROP TABLE IF EXISTS pw_cache_whip_tmp");
	$db->query("CREATE TABLE pw_cache_whip_tmp (
					division_id int not null,
					party varchar(200) not null,
					aye_votes int not null,
					aye_tells int not null,
					no_votes int not null,
					no_tells int not null,
					both_votes int not null,
					abstention_votes int not null,
					possible_votes int not null,
					whip_guess enum('aye', 'no', 'abstention', 'unknown', 'none') not null,
					unique(division_id, party)
			    )");

	$qselect = "SELECT sum(pw_vote.vote = 'aye') AS ayevotes,
					   sum(pw_vote.vote = 'tellaye') AS ayetells,
					   sum(pw_vote.vote = 'no') AS novotes,
					   sum(pw_vote.vote = 'tellno') AS notells,
					   sum(pw_vote.vote = 'both') AS boths,
					   sum(pw_vote.vote = 'abstention') AS abstentions,
					   sum(1) AS possible_votes,
					   pw_division.division_id AS division_id, party,
					   division_date, division_number, pw_division.house as house";
	$qfrom =  " FROM pw_division";

	$qjoin .= " LEFT JOIN pw_mp ON
            		pw_division.house = pw_mp.house AND
            		pw_mp.entered_house <= pw_division.division_date AND
            		pw_division.division_date < pw_mp.left_house";
    $qjoin .= " LEFT JOIN pw_vote ON
		            pw_vote.mp_id = pw_mp.mp_id AND
        		    pw_vote.division_id = pw_division.division_id";

	$qgroup = " GROUP BY pw_division.division_id, pw_mp.party, pw_division.house";
	$query = $qselect.$qfrom.$qjoin.$qgroup;

    #print $query;
	$db->query($query);

	while ($row = $db->fetch_row_assoc())
	{
		$party = $row['party'];
		$ayevotes = intval($row['ayevotes']);
		$ayetells = intval($row['ayetells']);
		$novotes = intval($row['novotes']);
		$notells = intval($row['notells']);
		$boths = intval($row['boths']);
		$abstentions = intval($row['abstentions']);
		$possibles = intval($row['possible_votes']);
		$house = $row['house'];

		$ayes = $ayevotes + $ayetells;
		$noes = $novotes + $notells;

		# this would be the point where we add in some if statements accounting for the exceptions
		# where the algorithm doesn't work.  Or we do it against another special table.

		# to detect abstentions we'd need an accurate partyinfo that worked per parliament
		$whip_guess = "unknown";
		if (whipless_party($party)) {
			$whip_guess = "none";
			if ($party == "CWM" or $party == "DCWM")
				$whip_guess = "abstention";
		}

		# keep it very simple so it doesn't change and we can easily keep the set of exceptions constant.
		# if it can be tuned then there will be a maintenance issue whenever the algorithm got changed
		else
		{

			if ($house == 'scotland') {
				if( ($ayes > $noes) and ($ayes > $abstentions) )
					$whip_guess = "aye";
				else if( ($noes > $ayes) and ($noes > $abstentions) )
					$whip_guess = "no";
				else if( ($abstentions > $ayes) and ($abstentions > $noes) )
					$whip_guess = "abstention";
				else
					$whip_guess = "unknown";
			} else {
				if ($ayes > $noes)
					$whip_guess = "aye";
				else if ($ayes < $noes)
					$whip_guess = "no";
				else
					$whip_guess = "unknown";
			}
		}

		$qattrs = "division_id, party, aye_votes, aye_tells, no_votes, no_tells, both_votes, abstention_votes, possible_votes, whip_guess";
		$qvalues = $row['division_id'].", '".$row['party']."', $ayevotes, $ayetells, $novotes, $notells, $boths, $abstentions, $possibles, '".$whip_guess."'";
        $query = "INSERT INTO pw_cache_whip_tmp ($qattrs) VALUES ($qvalues)";
        #print_r($row);
        #print $query;
		$db2->query($query);
    }

	$db->query("DROP TABLE IF EXISTS pw_cache_whip");
	$db->query("RENAME TABLE pw_cache_whip_tmp TO pw_cache_whip");
}

function count_mp_info($db) {
    count_4d_info($db, "pw_cache_mpinfo", "pw_mp.mp_id", "mp_id", "votes_attended", "votes_possible");
}

function count_div_info($db) {
    count_4d_info($db, "pw_cache_divinfo", "pw_division.division_id", "division_id", "turnout", "possible_turnout");
}

function count_4d_info($db, $table, $group_by, $id, $votes_attended, $votes_possible) {
    #print "Creating table $table\n";
    $db->query( "DROP TABLE IF EXISTS ${table}_tmp" );
    $db->query(
        "CREATE TABLE ${table}_tmp (
        $id int not null,
        rebellions int not null,
        tells int not null,
        $votes_attended int not null,
        $votes_possible int not null,
        aye_majority int not null,
        index($id)
    )");
    // majority is meaningless in the case of the mp_info -- just how many more ayes than noes in the lifetime of the MP

    $scottish_rebellion_condition = "( (pw_division.house = 'scotland') and
                ((whip_guess = 'aye' AND (vote = 'no' or vote = 'abstention')) OR
                 (whip_guess = 'no' AND (vote = 'aye' or vote = 'abstention')) OR
                 (whip_guess = 'abstention' AND (vote = 'aye' or vote = 'no'))) )";

    $other_rebellion_condition = "( (pw_division.house != 'scotland') and
                ((whip_guess = 'aye' AND (vote = 'no' or vote = 'tellno')) OR
                 (whip_guess = 'no' AND (vote = 'aye' or vote = 'tellaye')) OR
                 (whip_guess = 'abstention' AND (vote IS NOT NULL))) )";

    $query = "
        INSERT INTO ${table}_tmp
            ($id, rebellions, tells, $votes_attended, $votes_possible, aye_majority)
        SELECT
            $group_by,
            SUM($scottish_rebellion_condition or $other_rebellion_condition) AS rebellions,
            SUM(vote = 'tellaye' OR vote = 'tellno') AS tells,
            SUM(vote IS NOT NULL) as $votes_attended,
            SUM(pw_division.division_id IS NOT NULL) AS $votes_possible,
            SUM((vote = 'aye' or vote = 'tellaye') - (vote = 'no' or vote = 'tellno')) AS aye_majority

        FROM pw_division

        LEFT JOIN pw_mp ON
            pw_division.house = pw_mp.house AND
            pw_mp.entered_house <= pw_division.division_date AND
            pw_division.division_date < pw_mp.left_house

        LEFT JOIN pw_vote ON
            pw_vote.mp_id = pw_mp.mp_id AND
            pw_vote.division_id = pw_division.division_id

        LEFT JOIN pw_cache_whip ON
            pw_cache_whip.party = pw_mp.party AND
            pw_cache_whip.division_id = pw_division.division_id

        GROUP BY $group_by
    ";

    #print $query;
    $db->query($query);

	$db->query("DROP TABLE IF EXISTS $table");
	$db->query("RENAME TABLE ${table}_tmp TO $table");
}

function current_rankings($db) {
    # Create tables to store in
    $db->query("drop table if exists pw_cache_rebelrank_today" );
    $db->query("create table pw_cache_rebelrank_today (
        mp_id int not null,
        rebel_rank int not null,
        rebel_outof int not null,
        index(mp_id)
        )"
    );
    $db->query("drop table if exists pw_cache_attendrank_today" );
    $db->query("create table pw_cache_attendrank_today (
            mp_id int not null,
            attend_rank int not null,
            attend_outof int not null,
            index(mp_id)
        )"
    );

    do_house_ranking($db, "commons");
    do_house_ranking($db, "scotland");
    do_house_ranking($db, "lords");
}

function rebelcomp($a, $b) {
    global $mprebel;
    if ($mprebel[$a] == $mprebel[$b]) return 0;
    return ($mprebel[$a] > $mprebel[$b]) ? -1 : 1;
}
function attendcomp($a, $b) {
    global $mpattend;
    if ($mpattend[$a] == $mpattend[$b]) return 0;
    return ($mpattend[$a] > $mpattend[$b]) ? -1 : 1;
}

function do_house_ranking($db, $house) {
    # Select all MPs in force today, and their attendance/rebellions
    $mps_query_start = "select pw_mp.mp_id as mp_id, 
            round(100*rebellions/votes_attended,2) as rebellions,
            round(100*votes_attended/votes_possible,2) as attendance,
            party
            from pw_mp, pw_cache_mpinfo 
            where pw_mp.mp_id = pw_cache_mpinfo.mp_id 
                  and house = '$house' ";
    $db->query($mps_query_start . "and entered_house <= curdate() and curdate() <= left_house");
    if ($db->rows() == 0) {
        $db->query($mps_query_start .  "and left_house = '2011-03-23'");
        if ($db->rows() == 0) {
            die("No MPs/MSPs/Lords currently active have been found (house: '$house'), change General Election date in code if you are coming up to one");
            return;
        }
    }

    # Store their rebellions and divisions for sorting
    global $mprebel;
    global $mpattend;
    $mpsrebel = array();
    $mprebel = array();
    $mpsattend = array();
    $mpattend = array();
	while ($row = $db->fetch_row()) {
        list( $mpid, $rebel, $attend, $party ) = $row;
        if ( $rebel ) {
            if (!whipless_party($party)) {
                $mpsrebel[] = $mpid;
                $mprebel[$mpid] = $rebel;
            }
        }
        if ( $attend ) {
            $mpsattend[] = $mpid;
            $mpattend[$mpid] = $attend;
        }
    }

    # Sort, and calculate ranking for rebellions
    usort($mpsrebel, "rebelcomp");
    $mprebelrank = array();
    $rank       = 0;
    $activerank = 0;
    $prevvalue  = -1;
    foreach ($mpsrebel as $mp) {
        $rank++;
        if ( $mprebel[$mp] != $prevvalue )
            $activerank = $rank;
        $prevvalue = $mprebel{$mp};
        $db->query("insert into pw_cache_rebelrank_today (mp_id, rebel_rank, rebel_outof)
            values ($mp, $activerank, ".count($mpsrebel).")"
        );
    }

    # Sort, and calculate ranking for attendance
    usort($mpsattend, "attendcomp");
    $mpattendrank = array();
    $rank       = 0;
    $activerank = 0;
    $prevvalue  = -1;
    foreach ($mpsattend as $mp) {
        $rank++;
        if ( $mpattend{$mp} != $prevvalue )
            $activerank = $rank;
        $prevvalue = $mpattend{$mp};
        $db->query("insert into pw_cache_attendrank_today (mp_id, attend_rank, attend_outof)
            values ($mp, $activerank, ".count($mpsattend).")"
        );
    }
}



