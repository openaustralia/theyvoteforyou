<?php
# $Id: cache-begin.inc,v 1.1 2003/10/14 22:39:06 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$cache_dir = "/home/francis/pwcache/";
$cache_file = $cache_dir . md5($_SERVER['REQUEST_URI']) . ".html";
if (file_exists($cache_file))
{
    $page = readfile($cache_file);
    print $page;
    exit(0);
}
ob_start();    

?>

