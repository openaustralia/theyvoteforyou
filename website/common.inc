<?php

# $Id: common.inc,v 1.2 2005/01/15 22:32:14 frabcus Exp $

# Included from all main .php files on the first line

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

ini_set('log_errors', 'On');

$loc = dirname($_SERVER['REQUEST_URI'] . "dummy"); # Dummy for / is really /index.php
if (!is_bool(strpos($loc, "/forum")) || !is_bool(strpos($loc, "/account")) || !is_bool(strpos($loc, "/project")) || !is_bool(strpos($loc, "/newsletters")) )
    $toppath = "../"; 
else 
    $toppath = "";

include_once $toppath . "config.php";

?>
