<?php
// This files used for user login, should be merged with db.inc (patches
// welcome :)
//
// SourceForge: Breaking Down the Barriers to Open Source Development
// Copyright 1999-2000 (c) The SourceForge Crew
// http://sourceforge.net
//
// $Id: database.inc,v 1.3 2005/01/15 20:38:10 frabcus Exp $
//
// /etc/local.inc includes the machine specific database connect info

function db_connect() {
	global $host,$user,$password;
	$conn = mysql_connect($host,$user,$password);
	if (!$conn) {
		echo mysql_error();
	}
	return $conn;
}

function db_query($qstring,$print=0) {
	global $database;
	return @mysql($database,$qstring);
}

function db_numrows($qhandle) {
	// return only if qhandle exists, otherwise 0
	if ($qhandle) {
		return @mysql_numrows($qhandle);
	} else {
		return 0;
	}
}

function db_result($qhandle,$row,$field) {
	return @mysql_result($qhandle,$row,$field);
}

function db_numfields($lhandle) {
	return @mysql_numfields($lhandle);
}

function db_fieldname($lhandle,$fnumber) {
           return @mysql_fieldname($lhandle,$fnumber);
}

function db_affected_rows($qhandle) {
	return @mysql_affected_rows();
}
	
function db_fetch_array($qhandle) {
	return @mysql_fetch_array($qhandle);
}
	
function db_insertid($qhandle) {
	return @mysql_insert_id($qhandle);
}

function db_error() {
	return "\n\n<P><B>".@mysql_error()."</B><P>\n\n";
}

//connect to the db
//I usually call from pre.php
db_connect();

?>
