<?php

#print "Public Whip is down for maintenance. When it is back up it will have some new things for you though :)";
#exit;

# $Id: common.inc,v 1.27 2011/04/11 13:20:43 publicwhip Exp $

# Included from all main .php files on the first line

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

#print "Sorry about this, but Public Whip is unavailable for a few minutes due to maintenance. We'll be back up shortly.";
#exit;

global $toppath;
$loc = dirname($_SERVER['REQUEST_URI'] . "dummy"); # Dummy for / is really /index.php
if (!is_bool(strpos($loc, "/forum/admin")))
    $toppath = "../../"; 
else if (!is_bool(strpos($loc, "/forum")) || 
    !is_bool(strpos($loc, "/account")) || 
    !is_bool(strpos($loc, "/project")) || 
    !is_bool(strpos($loc, "/newsletters")) || 
    !is_bool(strpos($loc, "/N")) || 
    !is_bool(strpos($loc, "/U")) || 
    !is_bool(strpos($loc, "/feeds")) )
    $toppath = "../"; 
else 
    $toppath = "";

require_once $toppath . "config.php";
require_once $toppath . "cache-tools.inc";
require_once $toppath . "debug_print_backtrace.inc";

ini_set('log_errors', 'On');
ini_set('log_errors_max_len', '0');
ini_set('error_log', null);
ini_set('ignore_repeated_errors', 'Off');
ini_set('html_errors', 'Off');
if (version_compare(PHP_VERSION, "5.0", ">="))
    date_default_timezone_set("Europe/London");

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

    $requesturi = (isset($_SERVER['REQUEST_URI']) === true ? $_SERVER['REQUEST_URI'] : '[no url]');
    error_log($requesturi.': '.$message);

    print "<hr>";
    print "<p>Sorry! Something's gone wrong. Please <a href=\"mailto:team@publicwhip.org.uk\">email us</a> to let us know.</p>";
    print "<p><strong>Copy and paste this entire page into your email</strong>.";
    print "<br>To do this press Ctrl+A (select all) then Ctrl+C (copy). Then paste into your email.</p>";
    print "<hr>";
    print "<p><strong>Error:</strong> $message";

    print "<p>";
    print " <strong>Date:</strong> ".date("D M d H:i:s Y");
    print " <strong>IP:</strong> ".$_SERVER['REMOTE_ADDR'];
    print " <strong>URI:</strong> ".$_SERVER['REQUEST_URI'];

    print "<p><pre>";
    debug_print_backtrace();
    print "</pre>";

    print "<hr>";
    exit;
}
set_error_handler('pw_handle_error');

function getmicrotime()
{
    list($usec, $sec) = explode(" ", microtime());
    return ((float)$usec + (float)$sec);
}

require_once $toppath . "pretty.inc";
require_once $toppath . "account/user.inc";
function pw_header() 
{
    global $toppath, $title, $headtitle, $h1title, $onload, $second_links, $second_links2, $second_links3, $colour_scheme, $second_type;
    if (!$second_type) {
        $second_type = "";
        if ($second_links)
            $second_type = "default";
    }
    include $toppath . "header.inc";
}
/*  pw_header_notitle - Added by katy to allow homepage redesign */
function pw_header_notitle() 
{
    global $toppath, $headtitle, $h1title, $onload, $second_links, $second_links2, $second_links3, $colour_scheme, $second_type;
    if (!$second_type) {
        $second_type = "";
        if ($second_links)
            $second_type = "default";
    }
    include $toppath . "header.inc";
}

function pw_footer() 
{
    global $toppath, $paddingforanchors, $colour_scheme;
    include $toppath . "footer.inc";
}

/* get_http_var NAME [DEFAULTorALLOW]
 * Return the value of the GET or POST parameter with the given NAME; or, if no
 * such parameter is present, DEFAULT; or, if DEFAULT is not specified or is a
 * boolean, the empty string ("").
 * If DEFAULT is a boolean, allow the input to be changed (currently, only
 * for Esperanto input to take .x to various accented characters). It's thus
 * currently impossible to have a default and have changed input, but nowhere
 * on the PledgeBank site requires a default anyway.
 */
function get_http_var($name, $default='') {
    global $lang;

    if (is_bool($default)) {
        $allow_changes = true;
        $default = '';
    } else {
        $allow_changes = false;
    }

    if (array_key_exists($name, $_GET)) {
        $var = $_GET[$name];
        if (!is_array($var)) $var = trim($var);
    } elseif (array_key_exists($name, $_POST)) {
        $var = $_POST[$name];
        if (!is_array($var)) $var = trim($var);
    } else { 
        $var = $default;
    }
    if ($allow_changes && $lang == 'eo')
        $var = input_esperanto($var);
    return $var;
}

