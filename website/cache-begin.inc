<?php
# $Id: cache-begin.inc,v 1.2 2003/10/15 06:59:00 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$cache_dir = "/home/francis/pwcache/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_FILENAME"]),1) . "/";
$cache_file = $cache_dir . "cache-" . $_SERVER['QUERY_STRING'] . ".html";
if (file_exists($cache_file))
{
    readfile($cache_file);
    exit("");
}
ob_start();    

?>

