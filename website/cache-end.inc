<?php
# $Id: cache-end.inc,v 1.2 2003/10/15 06:59:00 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$page = ob_get_contents();
if (!file_exists($cache_dir))
    mkdir($cache_dir, 0770);
$handle = fopen($cache_file, 'w');
fwrite($handle, $page);
fclose($handle);

ob_end_flush();
?>
