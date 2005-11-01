<?php
# $Id: cache-tools.inc,v 1.28 2005/11/01 01:30:27 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once $toppath . "account/user.inc";

function cache_begin($cache_params) {
    global $cache_dir, $cache_dir, $cache_file, $pw_cache_top, $pw_cache_enable;

    $cache_dir = $pw_cache_top . "/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_NAME"]),1) . "/";
    if (!isset($cache_params))
        $cache_params = md5($_SERVER['QUERY_STRING']);
    $cache_file = $cache_dir . $cache_params . ".html";

    require_once $toppath . "account/user.inc";
    require_once $toppath . "cache-tools.inc";

    if (file_exists($cache_file) && $pw_cache_enable)
    {
    #    print "using cache\n";
        $content = file_get_contents($cache_file);
        $content = preg_replace("/<!--ACCOUNTBEGIN[\s\S]*ACCOUNTEND-->/", account_navbar(), $content);
        $content = preg_replace("/<!--NEWSLETTERBEGIN[\s\S]*NEWSLETTEREND-->/", newsletter_navbar(), $content);
        print $content;
        exit("");
    }
    ob_start();    
}

function cache_end() {
    global $pw_cache_enable, $cache_dir, $cache_file;

    # See if the user is a robot
    $user_agent = $_SERVER['HTTP_USER_AGENT'];
    $bot = false;
    if (stristr($user_agent, "bot")) {
        $bot = true;
    }

    # Cache the page if they are not a bot (otherwise we cache loads
    # of spurious pages as mindless things crawl the site)
    if (!$bot && $pw_cache_enable) {
        $page = ob_get_contents();
        if (!file_exists($cache_dir))
            mkdir($cache_dir, 0770);
        $handle = fopen($cache_file, 'w');
        fwrite($handle, $page);
        fclose($handle);
    }

    ob_end_flush();
}

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
    global $this_place;
    $this_place = $_SERVER["REQUEST_URI"];
    # don't go back to confusing/logging out pages after login
    if (stristr($this_place, "logout.php")) 
        $this_place = "";
    if (stristr($this_place, "lostpass.php")) 
        $this_place = "";
    if (stristr($this_place, "register.php")) 
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
        $ret .= '<a title="Register to get a newsletter or make/edit policies" href="/account/register.php?r='.  ($_GET['r']?urlencode($_GET['r']):urlencode($this_place)).'">';
        $ret .= "Sign Up";
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

