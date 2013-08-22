<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<?php require_once "common.inc";
# $Id: twfydivinsert.php,v 1.3 2005/12/22 18:22:28 publicwhip Exp $
# vim:sw=4:ts=4:et:nowrap

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    require_once "db.inc";
    $db = new DB();

   	require_once "decodeids.inc";
	require_once "tablepeop.inc";
	require_once "tablemake.inc";
	require_once "tableoth.inc";
	require_once "pretty.inc";

	# decode the attributes
	$divattr = get_division_attr_decode( "");
	$div_id = $divattr["division_id"];

	print_party_summary_division( $div_id, "www.publicwhip.org.uk/", $divattr["house"]);
?>
</html>

