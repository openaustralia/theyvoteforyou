<?  

# $Id: logout.php,v 1.1 2003/10/11 10:29:13 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

include('user.inc');
include('database.inc');

if (user_isloggedin()) {
	user_logout();
	$user_name='';
}

$title = "Logout"; 
include "../header.inc";

echo 'You are now logged out';

?>

<?php include "../footer.inc" ?>
