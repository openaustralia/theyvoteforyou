#!/usr/bin/php -q
<?php
# $Id: mp_distance.php,v 1.2 2009/05/25 10:54:35 marklon Exp $

# Run from the CLI to populate all of the MP distance cache table.

# The Public Whip, Copyright (C) 2006 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../website/config.php";
require_once "../website/db.inc";
require_once "../website/distances.inc";
require_once "../website/dream.inc"; 

$db = new DB();
$db2 = new DB();

fill_mp_distances($db, $db2, 'commons');
fill_mp_distances($db, $db2, 'lords');
fill_mp_distances($db, $db2, 'scotland');

