<?php

/* $Id: auth.inc,v 1.1 2006/03/06 19:09:56 frabcus Exp $
 *
 * Functions in this file are taken from mySociety, and are licensed
 * under the Affero GPL.
 *
 * Copyright (c) 2005 UK Citizens Online Democracy. All rights reserved.
 * Email: francis@mysociety.org; WWW: http://www.mysociety.org/
*/

/* random_bytes NUM
 * Return NUM bytes of random data. */
function random_bytes($num) {
    global $random_bytes_filehandle;
    if ($num < 0)
        err("NUM must be nonnegative in random_bytes");
    if (!isset($random_bytes_filehandle)
        && !($random_bytes_filehandle = fopen("/dev/random", "r")))
            err("Unable to open /dev/random");
    $res = '';
    while (strlen($res) < $num)
        $res .= fread($random_bytes_filehandle, $num - strlen($res));
    return $res;
}

/* auth_ab64_encode DATA
 * Return a "almost base64" encoding of DATA (a nearly six-bit encoding using
 * email-client-friendly characters; specifically the encoded data match
 * /^[0-9A-Za-z]+$/).
 * TODO: Change this to proper base62_encode :) */
function auth_ab64_encode($i) {
    $t = base64_encode($i);
    $t = str_replace("+", "a", &$t);
    $t = str_replace("/", "b", &$t);
    $t = str_replace("=", "c", &$t);
    return $t;
}

/* auth_random_token
 * Returns a random token. */
function auth_random_token() {
    $token = auth_ab64_encode(random_bytes(12));
    return $token;
}

