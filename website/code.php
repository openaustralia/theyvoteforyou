<?php $title = "Source Code"; include "header.inc" 
# $Id: code.php,v 1.2 2003/08/19 17:47:40 frabcus Exp $

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
licensed under the <a href="/GPL.html">GPL</a>, a standard open source
software license.  

<p>At the moment I've only run this on Linux. It will certainly work on
other Unixes, and it should run on Windows.  You need to install at
least Perl and MySQL though, and preferably a web server with PHP also.
Since so few people have used this code, there are bound to be problems.
Don't hesitate to <a href="mailto:francis@flourish.org">email me</a> for
help.

<p>If all this sounds like gobbledygook, then email me and ask for help.
I can tell you where to go and what to read to learn how to get it up
and running.  Or if there is a particular good idea that you want to try
out, I might help more directly by implementing it.

<h2>Roughly how it works</h2>
<p>Perl code downloads data from the UK parliament
website, and stores it in a MySQL database. A combination of Perl and
Octave (an open source mathematics package, compatible with Matlab) code
perform various calculations on the data to form other database tables.
The website is written in PHP and makes pages by querying the MySQL
database.

<h2>Getting the source code</h2>
<A href="http://sourceforge.net/projects/publicwhip"> <IMG align=right vspace=8 hspace=8
src="http://sourceforge.net/sflogo.php?group_id=87640&amp;type=5"
width="210" height="62" border="0" alt="SourceForge.net Logo" /></A>

<p>For casual examination of it, you can browse the code online.  In
order to use it you can either download a snapshot of the code, or get
the latest version direct from the version control system CVS.

<p><span class="ptitle">Browse</span> - You can
<a href="http://cvs.sourceforge.net/cgi-bin/viewcvs.cgi/publicwhip/publicwhip/">browse
the code online</a>.  Of general interest are the various text files in
the top level directory - have a look at todo.txt, ideas.txt and
README.txt.

<p><span class="ptitle">File download</span> - Go to our <a
href="http://sourceforge.net/projects/publicwhip">SourceForge project
page</a>, and follow the link to Files.  You want the latest
publicwhip-source file.

<p><span class="ptitle">From CVS</span> - Go to our <a
href="http://sourceforge.net/projects/publicwhip">SourceForge project
page</a>, and follow the link to CVS for instructions.  The module you
want is called <i>publicwhip</i>.

<p>There is README.txt file with the source code, explaining what is in
each directory, and what the various todo and idea list files are.

<h2>Setting up Perl and MySQL</h2>

<p><span class="ptitle">Perl</span> - Under Windows download <a
href="http://www.activestate.com/ActivePerl/">ActivePerl</a>.
Unix-based operating systems will probably have Perl already installed.
You also need to install some extra special Perl modules for screen
scraping (the automated downloading and parsing of Hansard's website).

<p>My favourite of these is WWW::Mechanize, which provides
an object that can programmatically browse the web - following links
containing certain text, submitting forms and so on.  My second
favourite is HTML::TokeParser which makes it a lot easier to extract
data from an HTML file.

<p>To install them follow the <a
href="http://www.cpan.org/misc/cpan-faq.html#How_install_Perl_modules">CPAN
instructions</a> (Comprehensive Perl Archive Network) under Unix or <a
href="http://aspn.activestate.com/ASPN/docs/ActivePerl-5.6/faq/ActivePerl-faq2.html">PPM instructions</a> (Perl Package Manager) under Windows.  

The modules you need to install are:  
HTML::TokeParser,
HTML::TreeBuilder,
HTML::FormatText,
Text::ExtractWords,
WWW::Mechanize,
HTTP::Status,
Text::Autoformat,
Date::Parse,
Getopt::Long.  
Tell me if this list is wrong.

<p>

<p><span class="ptitle">MySQL</span> - Get this database server from <a
href="http://www.mysql.com">MySQL.com</a>.  After installing it you need
to set up the instructions to create a database and a user with
privileges to access that database. The database can have any name.

<p>You need to set up the database tables, which all begin with
<i>pw_</i>.  To do this read the instructions at the top of the file
create.sql.  It contains the SQL commands which create the tables.

<h2>Scraping parliamentary transcripts</h2>

<p>Use the command line and change to the <i>scraper</i> directory.
The script called <i>scraper.pl</i> in there does all of the screen
scraping from Hansard, and various cached calculations for use on the
website.

<p>Run scraper.pl with no parameters to find out its syntax.  Then you
need to run it once with each of the following commands.  Or you can do
them all in one go, such as <tt>./scrape.pl mps months sessions content
divisions clean calc</tt>.

<p><span class="ptitle">mps</span> - Reads the files from the rawdata
folder, which contain lists of MPs from the Parliamentary intranet.
Adds these to the pw_mp database table.

<p><span class="ptitle">months sessions</span> - Finds the URLs for the
first page of each day's transcript, and adds them to the pw_hansard_day
table.  months does this for recent months not yet in a bound volume.
sessions does recent sessions, currently back to the start of this
parliament.  Use just months to get going with a smaller amount of data,
or both if you want the entire parliament. The script won't add URLs
which already exist in the database, so you can run it multiple times,
or run it for a short while and stop it.

<p><span class="ptitle">content</span> - For every URL in the database,
downloads the complete content of Hansard for that day.  This is
extracted from multiple web pages, and made into one HTML file stored in
pw_debate_content.  This takes some time and bandwidth; there are 155Mb
of data for just the first two years of the 2001- parliament.  Only
downloads data it doesn't already have. 

<p><span class="ptitle">divisions</span> - For any days as yet
unscanned (according to the divisions_extracted column in
pw_debate_content), searches them for divisions.  Adds the divisions and
voting record of MPs to the pw_division and pw_vote tables.

<p><span class="ptitle">clean</span> - Having the misfortune to be using
a database that doesn't support transactions, you need to run this after
running divisions.  It removes any half-inserted divisions where there
was an error during parsing.  Also checks for special cases where there
are two divisions where one is a correction of another, and amalgamates
them.

<p><span class="ptitle">calc</span> - Fills in all the various pw_cache_
tables with data calculated from the other tables.  This is stuff like
guessing the rebellious votes and counting the attendance rates.  Note
that the website won't work at all until you have done this, as it
realies on the cached data tables.

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
httpd.conf.

<pre>
Alias /publicwhip/ /home/francis/devel/publicwhip/website/

&lt;Directory /home/francis/devel/publicwhip/&gt;
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

<p>When you're done make sure you restart the webserver so it reloads its
config files, and browse to http://localhost/publicwhip/.

<p>There's an extra hidden webpage which only works on your local
machine, called hansard.php.  This lets you view complete days of
hansard, extracted from pw_content.  View URLs in this form:
http://localhost/publicwhip/hansard.php?date=2003-06-05

<h2>Clustering (Multi-dimensional scaling)</h2>

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
Do <a href="mailto:francis@flourish.org">email me</a> for help, and make
suggestions as to how it could be better.  I'd love to hear from you if
you've got the thing working at all, and what you're using it for if you
have.

<?php include "footer.inc" ?>

