<?php
# $Id: cache-begin.inc,v 1.9 2004/06/13 15:51:52 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$cache_dir = "/home/francis/pwcache/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_NAME"]),1) . "/";
if (!isset($cache_params))
    $cache_params = md5($_SERVER['QUERY_STRING']);
$cache_file = $cache_dir . $cache_params . ".html";

if (file_exists($cache_file) && ($_SERVER["SERVER_NAME"] != "localhostNOT"))
{
    #print "using cache\n";
    readfile($cache_file);
    exit("");
}
ob_start();    

?>
