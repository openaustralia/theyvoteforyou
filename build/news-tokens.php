#!/usr/bin/php -q
<?php
# $Id: news-tokens.php,v 1.2 2006/03/10 17:24:44 publicwhip Exp $

# Script to fill in missing tokens in newsletter table.

# The Public Whip, Copyright (C) 2006 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../website/config.php";
require_once "../website/db.inc";
require_once "../website/auth.inc";

$db = new DB();

while(true) {
    $token = auth_random_token();
    $row = $db->query_onez_row('select email from pw_dyn_newsletter where token is null limit 1');
    if (!$row)
        exit;
    $email = $row[0];
    print "$email\n";
    $query = "update pw_dyn_newsletter set token = '$token' where email = '$email'";
    $db->query($query);
}

