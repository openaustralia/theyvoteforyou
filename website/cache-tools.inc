<?php
# $Id: cache-tools.inc,v 1.13 2005/03/28 19:59:24 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include_once $toppath . "account/user.inc";

function newsletter_navbar() {
    $ret = "";
    if (!user_isloggedin()) {
        $ret .= '<a title="Subscribe to our email newsletter" href="/account/register.php">News</a>';
    } else {
        $ret .= '<a title="Email newsletter archives" href="/newsletters/archive.php">News</a>';
    }
    return $ret;
}

function account_navbar() {
    $ret = "";
    if (user_isloggedin()) {
        global $user_name;
        $ret .= '<a title="Change account settings, such as whether you get the newsletter" href="/account/settings.php">';
        $ret .= "You are: $user_name";
        $ret .= '</a> ';
        $ret .= '<a title="Make your browser forget that you are logged into The Public Whip as ' . $user_name .'" href="/account/logout.php">';
        $ret .= "Logout";
        $ret .= '</a> ';
        $ret .= '<a title="Chat with other users" href="/forum">Forum</a> ';
    } else {
        $ret .= '<a title="Register to get a newsletter or make a Dream MP" href="/account/register.php">';
        $ret .= "Signup";
        $ret .= '</a> ';
        $ret .= '<a title="Login to edit your Dream MPs or change your newsletter settings" href="/account/settings.php">';
        $ret .= "Login";
        $ret .= '</a> ';
        $ret .= '<a title="Chat with other users" href="/forum">Forum</a>';
    }
    return $ret;
}

function cache_delete($file_stub, $cache_params) {
    global $pw_cache_top;
#    print "toppath $toppath";
    $cache_dir = $pw_cache_top . "/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_NAME"]),1);
#    print "<br>1. $cache_dir";
    $cache_dir = str_replace("account-", "", $cache_dir);
#    print "<br>2. $cache_dir";
    $cache_dir = str_replace(strrchr($cache_dir, "/"), "/" . $file_stub, $cache_dir);
#    print "<br>3. $cache_dir";

    $cache_file = $cache_dir . "/" . $cache_params . ".html";

#    print "<br>$cache_file";
    foreach (glob($cache_file) as $filename) {
#        print "<br>delete $filename\n<p>";
        unlink($filename);
    }

    #if (file_exists($cache_file))
#        unlink($cache_file);
}

# Mark caches as being updated...

# ... when anything about a Dream MP changes
function notify_dream_mp_updated($db, $dreamid) {
    cache_delete("dreammp.php", "id=" . intval($dreamid));
    cache_delete("dreammps.php", "");

    # delete cache pages of divisions which print stuff about this rolliemp
    $query = "select pw_division.division_number, pw_division.division_date
        from pw_division, pw_dyn_rollievote where
        pw_dyn_rollievote.rolliemp_id = '$dreamid' and
        pw_division.division_date = pw_dyn_rollievote.division_date and
        pw_division.division_number = pw_dyn_rollievote.division_number group
        by division_number, division_date";
    $ret = $db->query($query);
    while ($row = $db->fetch_row()) {
        cache_delete("division.php", "#date=".$row[1]."#div_no=".$row[0]."#*");
    }

    # Mark cache table for updating    
    $db->query("delete from pw_cache_dreaminfo where rollie_id = '$dreamid'"); 
}
# ... when a Dream MP is added or deleted
function notify_dream_list_changed($db) {
    cache_delete("dreammps.php", "");
}
# ... when a Dream MP votes on it
function notify_division_updated($db, $division_date, $division_number) {
    cache_delete("division.php", "#date=".$division_date."#div_no=".$division_number."#*");
}
# ... when piece of motion text is edited
function notify_motion_updated($db, $division_date, $division_number) {
    cache_delete("division.php", "#date=".$division_date."#div_no=".$division_number."#*");
    # Mark cache table for updating    
    $db->query("delete from pw_cache_divwiki where division_date = '$division_date'
        and division_number = '$division_number'"); 
}

