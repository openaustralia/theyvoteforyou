<?
exit;
require_once "common.inc";
require_once "forummagic.inc";
require_once "db.inc";
print "<p>doing";

$db = new DB();
#post_to_forum($db, "Policies", "Renaming Dream MPs as Policies", "This is the content with lots of stuff in it blah blah.\nAnd so it goes on.\n");
forummagic_post($db, "Policies", "Another Topic Made Auto Post", "This is the content with lots of stuff in it blah blah.\nAnd so it goes on.\n");



?>
