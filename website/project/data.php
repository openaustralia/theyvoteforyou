<?php 
# $Id: data.php,v 1.3 2004/02/23 00:29:24 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    include "../config.inc";
    $wransdir = $toppath . "/scrapedxml/wrans";

    if ($_GET["wrans"])
    {
        $filename = $_GET["wrans"];
        $filename = preg_replace("/[^0-9\-]/", "", $filename);
        $filename = $wransdir . "/answers" . $filename . ".xml";
        header("Content-type: text/xml");
        readfile($filename);
    }
    else
    {
        $title = "Raw Data"; include "../header.inc";
?>

<p>Here you can find raw data compiled by the Public Whip project.
For example, if you want to load a voting record into a spreadsheet, or to get
XML files of Written Answers.  For legal and copyright information, see
<a href="../faq.php#legal">our FAQ</a>. However, we ask that if you do
anything fun or important with this data, you let us know!  Any problems using
the data, or requests for a different format?  Email <a
href="mailto:francis@publicwhip.org.uk">francis@publicwhip.org.uk</a>


<h2>MP votes for each division</h2>

<p>These are CSV files for loading into a spreadsheet.  They contain a matrix
of every vote of each MP in each division.  1 for aye, -1 for noe, 0 for both, 
-- if they didn't vote.  Very very occasionally you will see -2 or 2 when
Hansard recorded that an MP both voted and telled.  The columns are headed
by the names of the MPs, and the rows begin with the date and number of the
division.

<p>
<a href="../data/votematrix-1997.csv.zip">votematrix-1997.csv.zip</a> - 271k
<br><a href="../data/votematrix-2001.csv.zip">votematrix-2001.csv.zip</a> - 171k
<br><a href="../data/divnames.txt">divnames.txt</a> - Names of divisions indexed by
number/date pair

<h2>MP and constituency names, dates and aliases</h2>

<p>Structured data about Members of Parliament.  These are all XML files, open
them in any text editor or XML viewer.  In the files there are comments with
more information.  Data is for the 1997 and 2001 parliaments.

<p><a href="../data/all-members.xml">all-members.xml</a> - list of all MPs.
Includes their name, party and constituency.  There is a unique identifier for
each entry, which is used by Public Whip.  Each entry is a continuous period of
holding office, loyal to the same party.  An MP who was in both parliaments
will appear twice.  An MP who also changed party will appear three times.
Dates of deaths, byelections and party changes or whip revocations are
recorded.

<p><a href="../data/member-aliases.xml">member-aliases.xml</a> - list of
alternative names for MPs.  Includes abbreviations, misspellings and name
changes due to marriage.  Canonical names from the all-members.xml file above
are given.

<p><a href="../data/constituencies.xml">constituencies.xml</a> - list of Parliamentary 
constituencies.  Includes alternative spellings of each constituency.

<h2>Hansard tidied up, in XML</h2>

<p>Dirty work should only be done once.  Instead of parsing Hansard again, just
download and enjoy our XML files.  At the moment there are files containing
Written Answers from the start of 2003.

<p>

<?php
    $dh = opendir($wransdir);
    $wrans = array();
    while (false !== ($filename = readdir($dh)))
    {
        if (preg_match("/^answers(.*)\.xml$/", $filename, $matches))
        {
            array_push($wrans, $matches[1]);
        }
    }
    sort($wrans);
    $wrans = array_reverse($wrans);
    foreach ($wrans as $date)
    {
        print "<a href=\"data.php?wrans=" . $date . "\">";
        print "answers" . $date . ".xml";
        print "</a><br>";
    }

    include "../footer.inc";
    }
?>
