<?
phpinfo();
exit;

require_once "common.inc";
require_once "forummagic.inc";
require_once "db.inc";

$title = "Test";
include "header.inc";

require_once "DifferenceEngine.inc";
$df = new WordLevelDiff(
array("Hello, this is some text. It is really quite long and took me ages to type and I got a bit fed up.\n\nIt has some paragraphs."), 
array("Hello, this is some text. It is really quite short and took me ages to type and I got a bit fed up.\n\nIt has no paragraphs.")
);
print "<pre>";print_r($df->edits);print"</pre>";
$opening = $df->orig();
$closing = $df->closing();
$inline_diff = $df->inline_diff();

print "<h1>inline_diff</h1>";
print join($inline_diff, "<p>");
print "<h1>opening</h1>";
print join($opening, "<p>");
print "<h1>closing</h1>";
print join($closing, "<p>");

include "footer.inc";

#$db = new DB();
#forummagic_post($db, "Policies", "Another Topic", "Another Topic Made Auto Post", "This is the content with lots of stuff in it blah blah.\nAnd so it goes on.\n");


?>
