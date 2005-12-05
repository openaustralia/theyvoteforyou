<?php require_once "common.inc";
# $Id: redir.php,v 1.1 2005/12/05 00:09:56 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$_ = $_POST['r'];
if (!$_)
    $_ = $_GET['r'];
header("Location: " . $_);

