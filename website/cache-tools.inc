<?php
# $Id: cache-tools.inc,v 1.23 2005/10/11 23:17:45 theyworkforyou Exp $

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
    $this_place = $_SERVER["REQUEST_URI"];
    if (stristr($this_place, "logout.php")) 
        $this_place = "";

    $ret = "";
    if (user_isloggedin()) {
        global $user_name;
        $ret .= '<a title="Change account settings, such as whether you get the newsletter" href="/account/settings.php">';
        $ret .= "You are: $user_name";
        $ret .= '</a> ';
        $ret .= '<a title="Make your browser forget that you are logged into The Public Whip as ' . $user_name .'" href="/account/logout.php'.
                "?r=".urlencode($this_place).'">';
        $ret .= "Logout";
        $ret .= '</a> ';
    } else {
        $ret .= '<a title="Register to get a newsletter or make/edit policies" href="/account/register.php">';
        $ret .= "Signup";
        $ret .= '</a> ';
        $ret .= '<a title="Login to edit policies or change your newsletter settings" href="/account/settings.php'.
                "?r=".urlencode($this_place)."\">";
        $ret .= "Login";
        $ret .= '</a> ';
    }
    return $ret;
}

# Mark database caches for update...

# ... when anything about a Dream MP changes
function notify_dream_mp_updated($db, $dreamid) {
    $db->query("delete from pw_cache_dreaminfo where dream_id = '$dreamid'"); 
}
# ... when piece of motion text is edited
function notify_motion_updated($db, $division_date, $division_number, $house) {
    $db->query("delete from pw_cache_divwiki where division_date = '$division_date'
        and division_number = '$division_number' and house = '$house'"); 
}

