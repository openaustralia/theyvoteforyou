<?php

include_once "gather.inc";

# Return score and what it is out of for how much the MP follows the "whip" of
# the Dream MP.
function calc_dream_mp_score($db, $dreamid, $mpid) {
    $query = "select pw_vote.vote mpvote, pw_dyn_rollievote.vote as rollievote from 
        pw_vote, pw_dyn_rollievote, pw_division where 
        pw_vote.division_id = pw_division.division_id and
        pw_dyn_rollievote.division_number = pw_division.division_number and 
            pw_dyn_rollievote.division_date = pw_division.division_date
        and pw_vote.mp_id = '" . $mpid . "' and pw_dyn_rollievote.rolliemp_id = '$dreamid'";

    $db->query($query);
    $qrowarray = $db->fetch_rows_assoc();
    $t = 0.0;
    $c = 0.0;
    foreach ($qrowarray as $qrow)
    {
        $t++;
        $mpvote = $qrow['mpvote'];
        $mpvote = str_replace("tell", "", $mpvote);
        $rollievote = $qrow['rollievote'];

        if ($mpvote == $rollievote)
            $c++;
        elseif ($mpvote == "both" or $rollievote == "both")
            $c = $c + 0.5;
    }

    return array($c, $t);
}

# Store data about this MP in cache tables, if it needs updating
function check_table_cache_dream_mp($db, $dreamid) {
    list($uptodate) = $db->query_one_row("select cache_uptodate from pw_dyn_rolliemp where rollie_id = '$dreamid'");
    list($cacherows) = $db->query_one_row("select count(*) from pw_cache_dreaminfo where rollie_id = '$dreamid'");

    if ($uptodate and $cacherows == 1) {
        return;
    }
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

    # Mark as updated
    $db->query("update pw_dyn_rolliemp set cache_uptodate = 1 where rollie_id = '$dreamid'"); 
}
# ... and do it for all Dream MPs
function check_table_cache_all_dream_mps($db) {
    $db->query("select rollie_id from pw_dyn_rolliemp where cache_uptodate = 0");
    while ($row = $db->fetch_row_assoc()) {
        check_table_cache_dream_mp($db, $row['rollie_id']);
    }
}

?>
