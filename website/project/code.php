<?php $title = "Source Code"; include "../header.inc" 
# $Id: code.php,v 1.11 2004/11/24 20:36:40 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.
?>

<h2>Introduction</h2>

<p>Hello!  This is the area to come to if you want to find out how the
Public Whip website works.  All the "source code" which makes the
website is freely available.  You can download it, run it on your own
computer, and try out your own anlayses and algorithms.  The code is
licensed under the <a href="../GPL.php">GPL</a>, a standard open source
software license.  

<p>At the moment I've only run this on Linux. It will certainly work on
other Unixes, and it should run on Windows.  You need to install at
least Python, preferably preferably MySQL, Perl and a web server with PHP also.
Since so few people have used this code, there are bound to be problems.  Don't
hesitate to <a href="mailto:team@publicwhip.org.uk">email us</a> for help,
or even better join the <a href="https://lists.sourceforge.net/lists/listinfo/publicwhip-playing">publicwhip-playing email list</a> and ask us there.

<p>If all this sounds like gobbledygook, then email me and ask for help.
I can tell you where to go and what to read to learn how to get it up
and running.  Or if there is a particular good idea that you want to try
out, I might help more directly by implementing it.

<h2>Roughly how it works</h2>
<p>Python code downloads data from the UK parliament website, stores it as an
HTML file for each day, and parses those files into XML files.  A Perl script
loads that data into a MySQL database.  A combination of Perl and Octave (an
open source mathematics package, compatible with Matlab) code perform various
calculations on the data to form other database tables.  The website is written
in PHP and makes pages by querying the MySQL database.

<p>You can skip a whole stage by grabbing the database dumps from the
bottom of the <a href="data.php">raw data</a> page, and loading these
into MySQL.  Then go straight to "Running the website locally" below.

<h2>Getting the source code</h2>
<A href="http://sourceforge.net/projects/publicwhip"> <IMG align=right vspace=8 hspace=8
src="http://sourceforge.net/sflogo.php?group_id=87640&amp;type=5"
width="210" height="62" border="0" alt="SourceForge.net Logo" /></A>

<p><span class="ptitle">Browse</span> - If you're just curious, you can
<a href="http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/publicwhip/publicwhip/">browse
the code online</a>.  Of general interest are the various text files in
the top level directory - have a look at todo.txt, ideas.txt and
README.txt.

<p><span class="ptitle">File download</span> - To use the code,
download a snapshot.  Go to our <a
href="http://sourceforge.net/projects/publicwhip">SourceForge project
page</a>, and follow the link to Files.  You want the latest
publicwhip-source file.

<p><span class="ptitle">From CVS</span> - For the live
code-as-we-change-it, you can use the version control system CVS.  Go to
our <a href="http://sourceforge.net/projects/publicwhip">SourceForge
project page</a>, and follow the link to CVS for instructions.  The
module you want is called <i>publicwhip</i>.

<p>There is README.txt file with the source code, explaining what is in
each directory, and what the various todo and idea list files are.

<h2>Setting up Python, Unix-utils, Perl and MySQL</h2>

<p><span class="ptitle">Python</span> - Under Windows download <a
href="http://www.python.org/download/">Python 2.3</a>.  Unix-based operating
systems probably have Python already installed, but you may need to
upgrade to Python 2.3.  You also need the <a
href="http://www.egenix.com/files/python/mxDateTime.html">mxDateTime</a> module
by eGenix, go to downloads on that page.  Under Debian this is in the package
python2.3-egenix-mxdatetime.

<p><span class="ptitle">Patch and Diff</span> - 
The parser has a preprocessor which applies patches to Hansard to fix
uncommon errors.  This is done using the tools "patch" and "diff",
which will be installed by default if you are using Unix.  On Windows
you can download them from 
<a href="http://unxutils.sourceforge.net/">GNU utilities for win32</a>.

<p><span class="ptitle">Perl</span> - Under Windows download <a
href="http://www.activestate.com/ActivePerl/">ActivePerl</a>.
Unix-based operating systems will probably have Perl already installed.

<p> You will need to install some extra Perl modules.  To install them follow the <a
href="http://www.cpan.org/misc/cpan-faq.html#How_install_Perl_modules">CPAN
instructions</a> (Comprehensive Perl Archive Network) under Unix or <a
href="http://aspn.activestate.com/ASPN/docs/ActivePerl-5.6/faq/ActivePerl-faq2.html">PPM
instructions</a> (Perl Package Manager) under Windows.    When using
PPM, if you get errors about Text::Reform then see 
<a href="http://www.mail-archive.com/dbi-users%40perl.org/msg20734.html">this message</a>.

<p>The modules you need to make sure you have installed are:  
Text::ExtractWords,
Text::Autoformat,
Date::Parse,
Getopt::Long,
XML::Twig.
DBI,
DBD-mysql,
encode.
Tell me if this list is wrong.

<p>

<p><span class="ptitle">MySQL</span> - Get this database server from <a
href="http://www.mysql.com">MySQL.com</a>.  You need version 4.0 or above.  After
installing it you need to set up the instructions to create a database and a
user with privileges to access that database. The database can have any name.
You need to set up the database tables, which all begin with <i>pw_</i>.  To do
this read the instructions at the top of the file
create.sql.  It contains the SQL commands which create the tables.

<h2>Scraping parliamentary transcripts</h2>

<p>Use the command line and change to the <i>pyscraper</i> directory.  The
script called <i>lazyrunall.py</i> in there does all of the screen scraping
from Hansard.  Run it with no parameters to find out its syntax.  Then
do something like this, include a date limit as the parser gives errors
if you go too far back.

<p><tt>./lazyrunall.py --from 2001-06-01 scrape parse
debates wrans</tt>

<p>That will screen scrape back to the start of the 2001 parliament, 
writing the files in pwdata/cmpages.  Then it will parse these
files into XML files and put them in pwdata/scrapedxml.  On Unix
the pwdata folder is in your home directory, on Windows it will
be in the same folder as the publicwhip folder which contains
the source code.

<p>The command above will gather both debates and written answers (wrans).
You can run a command again and it will lazily make only those files which
weren't downloaded/parsed last time.  When you are done, you should have
lots of XML files in the pwdata/scrapedxml/debates folder.  Take a look
at them.  These are used by the Perl script in the next phase.

<p>Change to the <i>loader</i> directory.    You need
<i>memxml2db.pl</i>, which will load the information about MPs into
database tables.  First you have to tell Perl your MySQL username and
password.  Copy the file config.pm.incvs to config.pm and edit it.  Now
run:

<p><tt>./memxml2db.pl

<p>Next you need the script called <i>load.pl</i>. It loads the divisons
from the XML files into the database and does various cached
calculations for use on the website.  Run it with no parameters to find
out its syntax.  Now do this:

<p><tt>./load.pl divsxml check calc

<p>While you're doing this all, you probably want to run a tool like the <a
href="http://www.mysql.com/products/mysqlcc/">MySQL Control Center</a>
to browse the database tables and see what data they are filling up
with.

<h2>Running the website locally</h2>

<p>You need to install a web server with PHP if you would like to run
the website locally as a way of viewing your local database.  Which web
server you use isn't important. I'm using Apache, but you can use PHP
with IIS.  Download Apache from <a href="http://httpd.apache.org/">The
Apache Software Foundation</a> and get PHP from <a
href="http://www.php.net/downloads.php">php.net</a>.

<p>Configure the web server to serve the files in the website folder
from the Public Whip distribution.  For Apache, add lines like this to
httpd.conf.  (This installs Public Whip as the top level site for a
domain on your web server, it only runs properly in that configuration,
as some URLs are referred to as, for example, /publicwhip.css).

<pre>
DocumentRoot /home/francis/devel/publicwhip/website/

&lt;Directory /home/francis/devel/publicwhip/website&gt;
    Options Indexes Includes FollowSymLinks MultiViews
    AllowOverride All

    Order allow,deny
    Allow from all
&lt;/Directory&gt;
</pre>

<p>You also need a .htaccess file to say how to handle .php files.  Two
example ones htaccess-francis and htaccess-pworg are in the website
folder.  Rename htaccess-francis to .htaccess as a first go - exactly
what you need to do depends on the rest of your Apache configuration.  
When you're done make sure you restart the webserver so it reloads its
config files. 

<p>Finally you need to tell the PHP scripts about the database.  Copy
the file pwdb.inc.incvs to pwdb.inc and edit it with your MySQL 
settings.  You also need to edit db.inc to point to this file (TODO:
work out a way to remove that need).

<p>Now browse to <a href="http://localhost/">http://localhost/</a>.

<h2>Vote map (Clustering, Multi-dimensional scaling)</h2>

<p>Octave is a mathematics package which we use to perform linear
algebra for the MP clustering.  Download it from the <a
href="http://www.octave.org">Octave website</a>.  You also need Java to
compile and view the clustering applet.  
Download the latest stable J2SE 1.4 from <a
href="http://java.sun.com">Sun's Java website</a>.

<p>Now go into the cluster folder.  There is a Makefile here which lets
you build the clustering data.  If you do <tt>make test</tt> it will
export the data from your database as a distance matrix DN.m, then use
Octave to perform MDS on this, and create mpcoords.txt containing the
coordinates.  It will then run the Java applet as an application for you
to see the results.

<p>To play with the distance metric which is fed into the clustering,
have a look in octavein.pl.  To see the formula we use for the
calculation, look at mds.m.  To alter the set of MPs used for
clustering, edit mpquery.pm.  You may want to add a "limit 20" to the
end of the query to reduce the number of MPs so you can try out
different algorithms quicker.

<h2>Ask me to make it easier</h2>

<p>This stuff isn't in the easiest form for you to use at the moment.
Do <a href="mailto:team@publicwhip.org.uk">email us</a> for help, and make
suggestions as to how it could be better.  I'd love to hear from you if
you've got the thing working at all, and what you're using it for if you
have.

<?php include "../footer.inc" ?>

