<?php require_once "common.inc";
    # $Id: mps.php,v 1.13 2005/03/09 19:38:51 goatchurch Exp $

    # The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
    # This is free software, and you are welcome to redistribute it under
    # certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
    # For details see the file LICENSE.html in the top level of the source.
    include "cache-begin.inc";

    include "db.inc";
    include "tablemake.inc";
    include "tablepeop.inc";

    include "render.inc";
    $db = new DB();

    $sort = db_scrub($_GET["sort"]);
    if ($sort != "rebellions")
        $title = "MPs";
    else
        $title = "Rebels";

    include "parliaments.inc";
	if ($parlsession != "")
		$title .= " - " . parlsession_name($parlsession) . " Session";
	else
		$title .= " - " . parliament_name($parliament) . " Parliament";
    include "header.inc";

?>
<p>The Members of Parliament are listed with the number of times they
voted against the majority vote for their party and how often they turn up
to vote.  Read a <a href="faq.php#clarify">clear
explanation</a> of these terms, as they may not have the meanings
you expect. You can change the order of the table by selecting the headings.
<?php
	# this stuff to be tabbed like with the divisions table
    if ($parliament != "1997" or $parlsession != "")
        print "<p><a href=\"mps.php?parliament=1997&sort=" . html_scrub($sort) . "\">View MPs for 1997-2001 parliament</a>";
    if ($parliament != "2001" or $parlsession != "")
        print "<p><a href=\"mps.php?parliament=2001&sort=" .  html_scrub($sort) . "\">View MPs for 2001-2005 parliament</a>";

    print "<table class=\"mps\">\n";

    $url = "mps.php?parliament=" . urlencode($parliament) . "&";
    print "<tr class=\"headings\">";
    head_cell($url, $sort, "Name", "lastname", "Sort by surname");
    head_cell($url, $sort, "Constituency", "constituency", "Sort by constituency");
    head_cell($url, $sort, "Party", "party", "Sort by party");
    head_cell($url, $sort, "Rebellions<br>(estimate)", "rebellions", "Sort by rebels");
    head_cell($url, $sort, "Attendance<br>(divisions)", "attendance", "Sort by attendance");
    print "</tr>";


	# a function which generates any table of mps for printing,
	$mptabattr = array("listtype" 	=> "parliament",
					   "parliament" => $parliaments[$parliament],
					   "showwhich" 	=> "all",
					   "sortby"		=> $sort);
	mp_table($db, $mptabattr);
    print "</table>\n";
?>

<?php include "footer.inc" ?>
<?php include "cache-end.inc"; ?>
