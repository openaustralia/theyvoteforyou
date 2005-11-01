<?php require_once "../common.inc";

# $Id: logout.php,v 1.9 2005/11/01 01:23:17 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../database.inc";
require_once "user.inc";

if (user_isloggedin()) {
	user_logout();
	$user_name='******'; // invalid but true
}

if ($_GET["r"]) {
    header("Location: " . $_GET["r"]);
    exit;
}

$title = "Logout"; 
pw_header();

echo 'You are now logged out.';

?>

<?php pw_footer() ?>
