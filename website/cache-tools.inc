<?php
# $Id: cache-tools.inc,v 1.6 2005/01/15 14:54:01 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include_once "config.php";
include_once 'account/user.inc';

function newsletter_navbar() {
    $ret = "";
    if (!user_isloggedin()) {
        $ret .= '<a title="Subscribe to our email newsletter" href="/account/register.php">Newsletter</a>';
    } else {
        $ret .= '<a title="Email newsletter archives" href="/newsletters/archive.php">Newsletter</a>';
    }
    return $ret;
}

function account_navbar() {
    $ret = "";
    if (user_isloggedin()) {
        global $user_name;
        $ret .= $user_name . " ";
        $ret .= '<a title="Change account settings, such as whether you get the newsletter" href="/account/settings.php">';
        $ret .= "Settings";
        $ret .= '</a>';
        $ret .= '<a title="Make your browser forget that you are logged into The Public Whip as ' . $user_name .'" href="/account/logout.php">';
        $ret .= "Logout";
        $ret .= '</a>';
    } else {
        $ret .= '<a title="Login to edit your Dream MPs or change your newsletter settings" href="/account/settings.php">';
        $ret .= "Login";
        $ret .= '</a>';
        $ret .= '<a title="Register to get a newsletter or make a Dream MP" href="/account/register.php">';
        $ret .= "Signup";
        $ret .= '</a>';
    }
    return $ret;
}

function cache_delete($file_stub, $cache_params) {
    global $cache_top;
#    print "toppath $toppath";
    $cache_dir = $cache_top . "/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_NAME"]),1);
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

?>
