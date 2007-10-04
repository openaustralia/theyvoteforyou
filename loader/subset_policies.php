#!/usr/bin/php -q
<?php
# $Id: subset_policies.php,v 1.2 2007/10/04 23:11:43 publicwhip Exp $

# Make policies that are subsets of other policies.

# The Public Whip, Copyright (C) 2007 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$toppath = "../website/";
require_once "../website/config.php";
require_once "../website/db.inc";
require_once "../website/parliaments.inc";
require_once "../website/dream.inc";
require_once "../website/cache-tools.inc";

$db = new DB();

// Make the new policy first - this wipes all its votes, and copies from new to
// old, subsetting to the given date range.
function copy_vote_subset($db, $id_from, $id_to, $date_start, $date_end = "9999-12-31") {
    $db->query("delete from pw_dyn_dreamvote where dream_id = $id_to");
    $db->query("insert into pw_dyn_dreamvote 
                    (division_date, division_number, dream_id, vote, house)
                select division_date, division_number, $id_to, vote, house
                       from pw_dyn_dreamvote where dream_id = $id_from
                       and division_date > \"$date_start\"
                       and division_date < \"$date_end\"");
    notify_dream_mp_updated($db, $id_to);
}

// Sets a policy as private so nobody can edit it except the creator.
function make_private($db, $id) {
    $db->query("update pw_dyn_dreammp set private = 1 where dream_id = $id");
}

# General election 2007
copy_vote_subset($db, 975, 999, "2005-05-05");
copy_vote_subset($db, 811, 1000, "2005-05-05");
copy_vote_subset($db, 996, 1001, "2005-05-05");
copy_vote_subset($db, 863, 1002, "2005-05-05");
copy_vote_subset($db, 984, 1003, "2005-05-05");
copy_vote_subset($db, 258, 1004, "2005-05-05");
copy_vote_subset($db, 230, 1005, "2005-05-05");
make_private($db, 999);
make_private($db, 1000);
make_private($db, 1001);
make_private($db, 1002);
make_private($db, 1003);
make_private($db, 1004);
make_private($db, 1005);

