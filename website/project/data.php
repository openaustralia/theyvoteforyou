<?php 
# $Id: data.php,v 1.13 2004/11/09 23:17:51 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

    include "../config.inc";
    $title = "Raw Data"; include "../header.inc";
?>

<p>Here you can find raw data compiled by the Public Whip project.
For example, if you want to load a voting record into a spreadsheet, or to get
XML files of Debates or Written Answers.  For legal and copyright information, see
<a href="../faq.php#legal">our FAQ</a>. However, we ask that if you do
anything fun or important with this data, you let us know!  Any problems using
the data, or requests for a different format?  Email <a
href="mailto:support@publicwhip.org.uk">support@publicwhip.org.uk</a>
or ask on the <a href="https://lists.sourceforge.net/lists/listinfo/publicwhip-playing">publicwhip-playing email list</a>.


<h2>MP votes for each division</h2>

<p>These are CSV files for loading into a spreadsheet.  They contain a matrix
of every vote of each MP in each division.  1 for aye, -1 for noe, 0 for both, 
-- if they didn't vote.  Very very occasionally you will see -2 or 2 when
Hansard recorded that an MP both voted and telled.  The columns are headed by
the names of the MPs, and the rows begin with the date and number of the
division.  

<p>
<a href="../data/votematrix-1997.csv.zip">votematrix-1997.csv.zip</a> - 271k
<br><a href="../data/votematrix-2001.csv.zip">votematrix-2001.csv.zip</a> - 171k
<br><a href="../data/divnames.txt">divnames.txt</a> - Names of divisions indexed by
number/date pair

<p>You may have problems using these files because they have more than 256
columns, and some spreadsheets don't go beyond column IV.  See if your
spreadsheet can import "from column x" so you can load the files in chunks.
OpenOffice (or StarOffice) has a "Column type" drop down on the import dialog. 
You can select multiple columns and choose "Hide", then more of the other
columns will be loaded.  Try to find a copy of Quattro Pro, it works fine with
more columns.  If you are really stuck, email me and I'll export the data in
multiple files.

<h2>MP and constituency names, dates and aliases</h2>

<p>Structured data about Members of Parliament.  These are all XML files, open
them in any text editor, XML viewer or some spreadsheets.  In the files there
are comments with more information.  Data is for the 1997 and 2001 parliaments.

<p><a href="../data/all-members.xml">all-members.xml</a> - list of all MPs.
Includes their name, party and constituency.  There is a unique identifier for
each entry, which is used by Public Whip.  Each entry is a continuous period of
holding office, loyal to the same party.  An MP who was in both parliaments
will appear twice.  An MP who also changed party will appear three times.
Dates of deaths, byelections and party changes or whip revocations are
recorded.

<p><a href="../data/people.xml">people.xml</a> - links together groups of MPs from
all-members.xml who are the same real world person. Usually this is because they
have the same name and are in the same constituency.  Sometimes someone changes
constituency between two parliaments, such as Shaun Woodward (Witney)
and Shaun Woodward (St Helens South).  This file records that they are the same person.
Also includes offices from ministers.xml which were held by that person.

<p><a href="../data/ministers.xml">ministers.xml</a> - contains ministerial 
positions and the department they were in.  Each one has a date
range, the MP became a minister at some time on the start day, and
stopped being one at some time on the end day.  The matchid field is one
sample MP office which that person also held.  Alternatively, use
the people.xml file to find out which person held the ministerial post.

<p><a href="../mp-info.xml">mp-info.xml</a> - list of division attendance rate
and rebelliousness for MPs in the all-members.xml file.  This is a live file,
correct to the latest division in the Public Whip database.  The field data_date
shows the date it applies up to.  For members who have left the house it says
"complete".

<p><a href="../data/member-aliases.xml">member-aliases.xml</a> - list of
alternative names for MPs.  Includes abbreviations, misspellings and name
changes due to marriage.  Canonical names from the all-members.xml file above
are given.

<p><a href="../data/constituencies.xml">constituencies.xml</a> - list of Parliamentary 
constituencies.  Includes alternative spellings of each constituency.

<p>
<a href="../data/edm-links.xml">edm-links.xml</a>, 
<a href="../data/guardian-links.xml">guardian-links.xml</a>,
<a href="../data/bbc-links.xml">bbc-links.xml</a>
- various links to external websites which have information about MPs.  Indexed
by MP identifier.

<h2>Hansard tidied up, in XML</h2>

<p>Dirty work should only be done once.  Instead of parsing Hansard again, just
download and enjoy our XML files.  At the moment there are files containing
Debates and Written Answers from the start of the 2001 parliament.  They are
available from the <a href="http://www.theyworkforyou.com/raw">raw data page on
the TheyWorkForYou.com website</a>.

<h2>Database dumps</h2>

<p><a href="../data/pw_static_tables.sql.bz2">pw_static_tables.sql.bz2</a> -
Text dump of MySQL tables containing raw voting and MP data.
<br><a href="../data/pw_cache_tables.sql.bz2">pw_cache_tables.sql.bz2</a> -
Text dump of MySQL tables containing cached calculations.

<?php include "../footer.inc"; ?>
