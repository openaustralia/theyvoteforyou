<?php
# $Id: cache-end.inc,v 1.5 2005/02/18 11:09:54 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

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
?>
