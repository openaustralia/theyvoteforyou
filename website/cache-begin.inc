<?php
# $Id: cache-begin.inc,v 1.19 2005/01/18 02:05:59 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$cache_dir = $pw_cache_top . "/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_NAME"]),1) . "/";
if (!isset($cache_params))
    $cache_params = md5($_SERVER['QUERY_STRING']);
$cache_file = $cache_dir . $cache_params . ".html";

include_once $toppath . "account/user.inc";
include_once $toppath . "cache-tools.inc";

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

?>
