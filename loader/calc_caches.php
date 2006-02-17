#!/usr/bin/php -q
<?php
# $Id: calc_caches.php,v 1.6 2006/02/17 15:51:21 publicwhip Exp $

# Calculate lots of cache tables, run after update.

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../website/config.php";
require_once "../website/db.inc";
require_once "../website/distances.inc";
require_once "../website/dream.inc"; 

$db = new DB();
$db2 = new DB();


fill_mp_distances($db, $db2);
exit;

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
						house enum('commons', 'lords') not null,
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
					whip_guess enum('aye', 'no', 'abstain', 'unknown', 'none') not null,
					unique(division_id, party)
			    )");

	$qselect = "SELECT sum(pw_vote.vote = 'aye' or pw_vote.vote = 'tellaye') AS ayes,
					   sum(pw_vote.vote = 'no' or pw_vote.vote = 'tellno') AS noes,
					   count(*) AS party_count,
					   pw_division.division_id AS division_id, party,
					   division_date, division_number, pw_division.house as house";
	$qfrom =  " FROM pw_division";
	$qjoin =  " LEFT JOIN pw_vote
					ON pw_vote.division_id = pw_division.division_id";
	$qjoin .= " LEFT JOIN pw_mp
					ON pw_mp.mp_id = pw_vote.mp_id";
	$qgroup = " GROUP BY pw_division.division_id, pw_mp.party, pw_division.house";
	$query = $qselect.$qfrom.$qjoin.$qgroup;

    #print $query;
	$db->query($query);

	while ($row = $db->fetch_row_assoc())
	{
		$party = $row['party'];
		$ayes = intval($row['ayes']);
		$noes = intval($row['noes']);
		$total = intval($row['party_count']);


		# this would be the point where we add in some if statements accounting for the exceptions
		# where the algorithm doesn't work.  Or we do it against another special table.


		# to detect abstentions we'd need an accurate partyinfo that worked per parliament
		$whip_guess = "unknown";
		if ($party == "XB" or $party == "Other" or substr($party, 0, 3) == "Ind")
			$whip_guess = "none";
		else if ($party == "CWM" or $party == "DCWM")
			$whip_guess = "abstain";

		# keep it very simple so it doesn't change and we can easily keep the set of exceptions constant.
		# if it can be tuned then there will be a maintenance issue whenever the algorithm got changed
		else
		{
			if ($ayes > $noes)
				$whip_guess = "aye";
			else if ($ayes < $noes)
				$whip_guess = "no";
			else
				$whip_guess = "unknown";
		}


		$qattrs = "division_id, party, whip_guess";
		$qvalues = $row['division_id'].", '".$row['party']."', '".$whip_guess."'";
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
    $db->query( "DROP TABLE IF EXISTS ${table}_tmp" );
    $db->query(
        "CREATE TABLE ${table}_tmp (
        $id int not null,
        rebellions int not null,
        tells int not null,
        $votes_attended int not null,
        $votes_possible int not null,
        index($id)
    )");

    $query = "
        INSERT INTO ${table}_tmp
            ($id, rebellions, tells, $votes_attended, $votes_possible)
        SELECT 
            $group_by,
            SUM((whip_guess = 'aye' AND (vote = 'no' or vote = 'tellno')) OR
                (whip_guess = 'no' AND (vote = 'aye' or vote = 'tellaye'))) AS rebellions,
            SUM(vote = 'tellaye' OR vote = 'tellno') AS tells,
            SUM(vote IS NOT NULL) as $votes_attended,
            SUM(pw_division.division_id IS NOT NULL) AS $votes_possible

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

function old_count_division_info($db) {
    $db->query( "DROP TABLE IF EXISTS pw_cache_divinfo_tmp" );
    $query = "INSERT INTO pw_cache_divinfo_tmp (division_id, rebellions, turnout, possible_turnout)
        SELECT 

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

        GROUP BY pw_division.division_id
    ";

    $db->query($query);

	$db->query("DROP TABLE IF EXISTS pw_cache_divinfo");
	$db->query("RENAME TABLE pw_cache_divinfo_tmp TO pw_cache_divinfo");
/*
    my $sth =
      PublicWhip::DB::query( $dbh, "select division_id from pw_division" );
    while ( my @data = $sth->fetchrow_array() ) {
        my ($division_id) = @data;

        my $sth = PublicWhip::DB::query(
            $dbh, "select count(*) from pw_vote,
            pw_cache_whip, pw_mp where pw_vote.division_id = ? and
            pw_cache_whip.division_id = ? and 
            pw_mp.party = pw_cache_whip.party and 
            pw_vote.mp_id = pw_mp.mp_id and 
            pw_cache_whip.whip_guess <> 'unknown' and 
            pw_vote.vote <> 'both' and
            pw_cache_whip.whip_guess <> replace(pw_vote.vote, 'tell', '')
            ", $division_id, $division_id
        );

        die "Failed to count rebels for div $division_id" if $sth->rows != 1;
        my $rebellions = $sth->fetchrow_arrayref()->[0];

        $sth = PublicWhip::DB::query(
            $dbh, "select count(*) from pw_vote
            where pw_vote.division_id = ?", $division_id
        );
        my $turnout = $sth->fetchrow_arrayref()->[0];

        #        print "division $division_id $rebellions\n";

        PublicWhip::DB::query(
            $dbh,
            "insert into pw_cache_divinfo (division_id, rebellions, turnout)
            values (?, ?, ?)", $division_id, $rebellions, $turnout
        );
    }
    */
}


