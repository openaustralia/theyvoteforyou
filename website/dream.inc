<?php

include_once "gather.inc";

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

# Used inside check_table_cache_dream_mp
function sortbyscore_a($row1, $row2)
{
    // First compare percentage (allow for n/a when MP has never voted in
    // same division as dream MP)
    if ($row1['scoremax_a'] == 0)
        $frac1 = 0; // change to -1 to put n/a at end
    else
        $frac1 = $row1['score_a'] / $row1['scoremax_a'];
    if ($row2['scoremax_a'] == 0)
        $frac2 = 0; // change to -1 to put n/a at end
    else
        $frac2 = $row2['score_a'] / $row2['scoremax_a'];
    if ($frac1 <> $frac2)
        return $frac1 < $frac2;
    
    // Then compare absolute (so it is better to have voted lots and
    // agreed, than a little and agreed)
    if ($row1['score_a'] <> $row2['score_a'])
        return $row1['score_a'] < $row2['score_a'];

    // Then reverse compare number of disagreed votes
    // so 0 of 1 is better than 0 of 10
    if ($row1['scoremax_a'] - $row1['score_a'] <> $row2['scoremax_a'] - $row2['score_a'])
        return ($row1['scoremax_a'] - $row1['score_a']) > ($row2['scoremax_a'] - $row2['score_a']);

    // Arbitarily sort after that
    if ($row1['last_name'] <> $row2['last_name'])
        return strcmp($row1['last_name'], $row2['last_name']);
    
    if ($row1['first_name'] <> $row2['first_name'])
        return strcmp($row1['first_name'], $row2['first_name']);
    
    if ($row1['constituency'] <> $row2['constituency'])
        return strcmp($row1['constituency'], $row2['constituency']);

    if ($row1['party'] <> $row2['party'])
        return strcmp($row1['party'], $row2['party']);
    
}


# Store data about this MP in cache tables, if it needs updating
function check_table_cache_dream_mp($db, $dreamid) {
    $dreamid = intval($dreamid);

    # See if it is already in cache
    list($uptodate) = $db->query_one_row("select cache_uptodate from pw_dyn_rolliemp where rollie_id = '$dreamid'");
    if ($uptodate) {
        return;
    }

    check_table_cache_counts_dream_mp($db, $dreamid);

    # Calculate score for Dream MP, and rank
    $now = strftime("%Y-%m-%d");
    $query = "select distinct(person), max(left_house) >= '$now' as still_in_office from pw_mp group by person ";
	$db->query($query);
    $rowarray = $db->fetch_rows_assoc();
    $rank_outof = 0;
    foreach ($rowarray as $key=>$copy_row) {
        $row =& $rowarray[$key]; # so we can modify $row values
        $ret  = calc_dream_mp_score_a($db, $dreamid, $row['person']);
        $row['score_a'] = $ret[0];
        $row['scoremax_a'] = $ret[1];
        if ($row['still_in_office']) {
            $rank_outof++;
        }
    }
    usort($rowarray, sortbyscore_a);
    $rank = 0;
    $userank = -1;
    $prevscore = "";
    $db->query("lock table pw_cache_dreamreal_score write");
    $db->query("delete from pw_cache_dreamreal_score where rollie_id = '$dreamid'");
    foreach ($rowarray as $row) {
        $dbrank = 'null';
        $dbrank_outof = 'null';
        if ($row['still_in_office']) {
            $rank += 1;
            $score = $row['score_a'] . " of ". $row['scoremax_a'];
            if ($score != $prevscore)
                $userank = $rank;
            $prevscore = $score;
            $dbrank = $userank;
            $dbrank_outof = $rank_outof;
        }

        if ($row['scoremax_a'] > 0) {
            $db->query("insert into pw_cache_dreamreal_score
                    (rollie_id, person, score_a, scoremax_a, rank_a, rank_outof_a)
                values ('$dreamid', '".$row['person']."', 
                        '".$row['score_a']."', '".$row['scoremax_a']."',
                        $dbrank, $dbrank_outof)");
        }
    }
    $db->query("unlock tables");

    # Mark as updated
    $db->query("update pw_dyn_rolliemp set cache_uptodate = 1 where rollie_id = '$dreamid'"); 
}

# Update cache of just the counts part
function check_table_cache_counts_dream_mp($db, $dreamid) {
    # TODO: This isn't a good check for when to reevaluate this - prob need
    # separate cache_uptodate field :(  this is getting too complicated
    list($cacherows) = $db->query_one_row("select count(*) from pw_cache_dreaminfo where rollie_id = '$dreamid'");
    if ($cacherows == 1)
        return;

    # Calculate number of divisions, and number of motion texts edited
    list($votes) = $db->query_one_row("select count(*) from pw_dyn_rollievote where
        pw_dyn_rollievote.rolliemp_id = '$dreamid'");
    $res = $db->query("
        select count(*) from pw_dyn_rollievote, pw_division, pw_dyn_wiki where
        pw_dyn_rollievote.division_date = pw_division.division_date and
        pw_dyn_rollievote.division_number = pw_division.division_number and
        pw_dyn_wiki.object_key = concat('motion-', pw_division.division_date, 
            '-', pw_division.division_number)
        and pw_dyn_rollievote.rolliemp_id = '$dreamid'
        group by pw_dyn_rollievote.division_date, pw_dyn_rollievote.division_number");
    $motion_count = $db->rows();

    $db->query("replace into pw_cache_dreaminfo 
        (rollie_id, votes_count, edited_motions_count) 
        values ('$dreamid', '$votes', '$motion_count')");
}

# ... and counts for all Dream MPS
function check_table_cache_counts_all_dream_mps($db) {
    $db->query("select rollie_id from pw_dyn_rolliemp where cache_uptodate = 0");
    while ($row = $db->fetch_row_assoc()) {
        #check_table_cache_counts_dream_mp($db, $row['rollie_id']);
        check_table_cache_counts_dream_mp($db, $row['rollie_id']);
    }
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

?>
