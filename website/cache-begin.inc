<?php
# $Id: cache-begin.inc,v 1.15 2005/01/14 16:07:25 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include_once "config.inc";

$cache_dir = $cache_top . "/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_NAME"]),1) . "/";
if (!isset($cache_params))
    $cache_params = md5($_SERVER['QUERY_STRING']);
$cache_file = $cache_dir . $cache_params . ".html";

include_once $toppath . "account/user.inc";
include_once $toppath . "cache-tools.inc";

if (file_exists($cache_file) && ($_SERVER["SERVER_NAME"] != "localhost"))
{
#    print "using cache\n";
    $content = file_get_contents($cache_file);
    $content = preg_replace("/<!--ACCOUNTBEGIN[\s\S]*ACCOUNTEND-->/", account_navbar(), $content);
    $content = preg_replace("/<!--NEWSLETTERBEGIN[\s\S]*NEWSLETTEREND-->/", newsletter_navbar(), $content);
    print $content;
    exit("");
}
ob_start();    

?>
