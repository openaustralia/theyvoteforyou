#!/usr/bin/php -q
<?php
# $Id: mp_distance.php,v 1.2 2009/05/25 10:54:35 marklon Exp $

# Run from the CLI to populate all of the MP distance cache table.

# The Public Whip, Copyright (C) 2006 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$toppath = "../website/";
require_once "../website/config.php";
require_once "../website/db.inc";
require_once "../website/distances.inc";
require_once "../website/dream.inc"; 

global $pwpdo;
global $pwpdo2;

fill_mp_distances($pwpdo, $pwpdo2, 'commons');
fill_mp_distances($pwpdo, $pwpdo2, 'lords');
fill_mp_distances($pwpdo, $pwpdo2, 'scotland');