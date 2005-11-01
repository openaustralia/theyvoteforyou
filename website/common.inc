<?php

# $Id: common.inc,v 1.9 2005/11/01 00:56:21 frabcus Exp $

# Included from all main .php files on the first line

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

ini_set('log_errors', 'On');
ini_set('log_errors_max_len', '0');
ini_set('error_log', null);
ini_set('ignore_repeated_errors', 'Off');
ini_set('html_errors', 'Off');

if (get_magic_quotes_gpc()) {
    trigger_error("Public Whip only works with magic_quotes_gpc off in php.ini", E_USER_ERROR);
}
if (ini_get('register_globals')) {
    trigger_error("Public Whip only works with register_globals off in php.ini", E_USER_ERROR);
}

// Display errors better
function pw_handle_error($num, $message, $file, $line, $context) {
    if ($num == E_USER_NOTICE || $num == E_NOTICE) {
        // Alas, Public Whip is written to expect no errors when referring to variable undefined
        // If you're bored, please remove this check and fix lots of the bugs and commit :)
        return;
    }

    error_log($message);

    print "<hr>";
    print "<p>Sorry! Something's gone wrong. Please <a href=\"mailto:team@publicwhip.org.uk\">email us</a> to let us know.</p>";
    print "<p><strong>Copy and paste this entire page into your email</strong>.";
    print "<br>To do this press Ctrl+A (select all) then Ctrl+C (copy). Then paste into your email.</p>";
    print "<hr>";
    print "<p><strong>Error:</strong> $message";

    print "<p>";
    print " <strong>Date:</strong> ".date("D M d H:i:s Y");
    print " <strong>IP:</strong> ".$_SERVER[REMOTE_ADDR];
    print " <strong>URI:</strong> ".$_SERVER[REQUEST_URI];

    require_once "debug_print_backtrace.inc";
    print "<p><pre>";
    debug_print_backtrace();
    print "</pre>";

    print "<hr>";
    exit;
}
set_error_handler('pw_handle_error');

$loc = dirname($_SERVER['REQUEST_URI'] . "dummy"); # Dummy for / is really /index.php
if (!is_bool(strpos($loc, "/forum")) || 
    !is_bool(strpos($loc, "/account")) || 
    !is_bool(strpos($loc, "/project")) || 
    !is_bool(strpos($loc, "/newsletters")) || 
    !is_bool(strpos($loc, "/feeds")) )
    $toppath = "../"; 
else 
    $toppath = "";

function getmicrotime()
{
    list($usec, $sec) = explode(" ", microtime());
    return ((float)$usec + (float)$sec);
}

require_once $toppath . "config.php";

?>
