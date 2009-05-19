<?php
# $Id: links.inc,v 1.4 2009/05/19 14:47:21 marklon Exp $

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

# Create MP/Lord URL parameters from row of database table pw_mp about them. 
# $i can be set to 2 to create the mpn2/mpc2 link parts.  The default is
# to create mpn/mpc.
function link_to_mp($row, $i = 1)
{
    if ($i == 1)
        $i = "";

    $mpn = '';
    if ($row['house'] == 'lords')
        $mpn .= $row['title'] . ' ';
    $mpn .= $row['first_name'].' '.$row['last_name'];
    $mpn = trim($mpn);

    if ($row['house'] == 'lords')
        $mpc = "Lords";
    else 
        $mpc = $row['constituency'];

    return "mpn$i=".urlencode(str_replace(" ", "_", $mpn))."&"."mpc$i=".urlencode(str_replace(" ", "_", $mpc))."&"."house$i=".urlencode($row['house']);
}


