<?
require_once "common.inc";
require_once "forummagic.inc";
require_once "db.inc";

$db = new DB();

trigger_error("This is test fatal error", E_USER_ERROR);

#forummagic_post($db, "Policies", "Another Topic", "Another Topic Made Auto Post", "This is the content with lots of stuff in it blah blah.\nAnd so it goes on.\n");


?>
