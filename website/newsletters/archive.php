<? 
# $Id: archive.php,v 1.6 2004/01/23 12:26:50 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
$issue = intval($_GET["issue"]);

function newsletter_title($newsletter)
{
	$handle = fopen($newsletter, 'r');
	$line = fgets($handle);
    fclose($handle);
    return str_replace("Subject: ", "", $line);
}
function newsletter_date($newsletter)
{
	$handle = fopen($newsletter, 'r');
	$dummy = fgets($handle);
	$line = fgets($handle);
    fclose($handle);
    return strtotime(str_replace("Date: ", "", $line));
}


function render_newsletter($newsletter)
{
	$handle = fopen($newsletter, 'r');
    $c = 0;
	while ($line = fgets($handle))
	{
        $line = preg_replace("/\b(\S+\@\S+)\b/is", "<a href=\"mailto:\\1\">\\1</a>", $line);
        $line = preg_replace("/(\s|^)(http:\/\/\S+)(\s)/is", "\\1<a href=\"\\2\">\\2</a>\\3", $line);

        $c++;
        if ($c >= 4)
            print $line . "<br>";
	}
	fclose($handle);
}

$title = "Newsletter Archive"; 
if ($issue != 0)
{
    $title = newsletter_title("issue" . $issue . ".txt") . " - " .
        date("Y-m-d", newsletter_date("issue" . $issue . ".txt"));
}
include "../header.inc";

if ($issue == 0)
{
?><p>This is the archive of old issues of the Public Whip newsletter.  At most
every month we'll email you with news, articles and comment about the
project.  <a href="../account/register.php">Sign up now!</a>  It's free!<p><?

    $dh = opendir(".");
    while (false !== ($filename = readdir($dh)))
    {
        if (preg_match("/^issue(.*)\.txt$/", $filename, $matches))
        {
            print "<a href=\"archive.php?issue=" . $matches[1] . "\">";
            print date("Y-m-d", newsletter_date($filename));
            print " - ";
            print newsletter_title($filename);
            print "</a>";
            print "<br>";
        }
    }
    print "<p><a href=\"old.php\">Older site news</a><?";
   /*3 December 2003
   31 October 2003 */

}
else
{
    print "<p><a href=\"archive.php\">Full list of old newsletter issues here</a>";
    print "<br><a href=\"../account/register.php\">Subscribe to the newsletter for free!</a> ";
    print "</p><hr><p>";
    render_newsletter("issue" . $issue . ".txt");
}

?>

<?php include "../footer.inc" ?>

