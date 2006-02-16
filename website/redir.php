<?php require_once "common.inc";
# $Id: redir.php,v 1.2 2006/02/16 19:14:24 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$_ = $_POST['r'];
if (!$_)
    $_ = $_POST['r2'];
if (!$_)
    $_ = $_GET['r'];
if (!$_)
    $_ = $_GET['r2'];
if (!$_) {
    print_r($_POST);
    print_r($_GET);
    die("Error in redir.php: parameter r and r2 not set");
}
header("Location: " . $_);

