<?php

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

?>
