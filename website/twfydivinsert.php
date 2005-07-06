<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php require_once "common.inc";
# $Id: twfydivinsert.php,v 1.1 2005/07/06 14:46:52 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    include "db.inc";
    $db = new DB();

   	include "decodeids.inc";
	include "tablepeop.inc";
	include "tablemake.inc";
	include "tableoth.inc";
	include "pretty.inc";

	# decode the attributes
	$divattr = get_division_attr_decode($db, "");
	$div_id = $divattr["division_id"];

	print_party_summary_division($db, $div_id, "www.publicwhip.org.uk/");
?>
</html>

