<?php
# $Id: cache-begin.inc,v 1.8 2004/05/24 00:59:00 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$cache_dir = "/home/francis/pwcache/" . substr(str_replace("/", "-", $_SERVER["SCRIPT_FILENAME"]),1) . "/";
$cache_file = $cache_dir . md5($_SERVER['QUERY_STRING']) . "-" .  $cache_postfix . ".html";
if (file_exists($cache_file) && ($_SERVER["SERVER_NAME"] != "localhostNOT"))
{
    readfile($cache_file);
    exit("");
}
ob_start();    

?>
