<?php require_once "../common.inc";

# $Id: logout.php,v 1.7 2005/10/06 12:45:07 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('../database.inc');
include_once('user.inc');

if (user_isloggedin()) {
	user_logout();
	$user_name='******'; // invalid but true
}

if ($_GET["r"]) {
    header("Location: " . $_GET["r"]);
    exit;
}

$title = "Logout"; 
include "../header.inc";

echo 'You are now logged out.';

?>

<?php include "../footer.inc" ?>
