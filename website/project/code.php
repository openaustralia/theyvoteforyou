<?php require_once "../common.inc";
# $Id: code.php,v 1.23 2011/05/10 14:26:12 publicwhip Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

$title = "Source Code"; pw_header()
?>

<h2>Introduction</h2>

<p>Hello!  This is the area to come to if you want to find out how the
Public Whip website works.  All the "source code" which makes the
website is freely available.  You can download it, run it on your own
computer, and try out your own anlayses and algorithms.  The code is
licensed under the <a href="http://www.fsf.org/licensing/licenses/agpl-3.0.html">GNU Affero GPL</a>, 
a standard open source software license.  

<p>At the moment I've only run this on Linux. It will certainly work on
other Unixes, and it should run on Windows.  You need to install MySQL, Perl
and a web server with PHP also.  Since so few people have used this code, there
are bound to be problems.  Don't hesitate to <a
href="mailto:team@publicwhip.org.uk">email us</a> for help.

<p>If all this sounds like gobbledygook, then email me and ask for help.
I can tell you where to go and what to read to learn how to get it up
and running.  Or if there is a particular good idea that you want to try
out, I might help more directly by implementing it.

<h2>Ideas and things to do</h2>

<p>You'll find these interesting.

<p><a href="/data/todo.txt">todo.txt</a> - Things we're working on now
<br><a href="/data/ideas.txt">ideas.txt</a> - Good ideas, that we'd like to do
<br><a href="/data/ideas-marginal.txt">ideas-marginal.txt</a> - Ideas we think aren't worthwhile

<h2>Roughly how it all works</h2>
<p>The separate <a href="http://ukparse.kforge.net/parlparse">Parliament Parser</a>
project supplies XML files of debates in parliament.  These are downloaded
to Public Whip by HTTP or using rsync.  A Perl script loads the divisions
from the XML files into a MySQL database.  A combination of Perl and Octave (an
open source mathematics package, compatible with Matlab) code perform various
calculations on the data to form other database tables.  The website is written
in PHP and makes pages by querying the MySQL database.

<p>You can skip a whole stage by grabbing the database dumps from the bottom of
the <a href="data.php">raw data</a> page, and loading these into MySQL.  Then
go straight to "Running the website locally" below.

<h2>Getting the source code</h2>

<p><span class="ptitle">Browse</span> - If you're just curious, you can
<a href="https://bitbucket.org/publicwhip/publicwhip-v1/">browse
the code online</a>.  Look at README.txt in the top level for more information.</p>

<p><span class="ptitle">File download</span> - To use the code,
download a snapshot.  Go to our <a
href="https://bitbucket.org/publicwhip/publicwhip-v1/">BitBucket project page</a>,
and click the Downloads link.</p>

<p><span class="ptitle">From CVS</span> - For the live code-as-we-change-it,
you can use the version control system Git.  Go to our <a
href="https://bitbucket.org/publicwhip/publicwhip-v1/">BitBucket project page</a> where you
will find the appropriate links to clone the repository.</p>

<p>There is README.txt file with the source code, explaining what is in each
directory, and what the various todo and idea list files are.</p>

<h2>Setting up Unix-utils, Perl and MySQL</h2>

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

    <p>You will also need the "ttf-bitstream-vera" package for producting graphs.</p>
    
<p><span class="ptitle">MySQL</span> - Get this database server from <a
href="http://www.mysql.com">MySQL.com</a>.  You need version 4.0 or above.  After
installing it you need to set up the instructions to create a database and a
user with privileges to access that database. The database can have any name.
You need to set up the database tables, which all begin with <i>pw_</i>.  To do
this read the instructions at the top of the file
create.sql.  It contains the SQL commands which create the tables.

<h2>Getting the XML files</h2>

<p>Download these from the separate <a
href="http://ukparse.kforge.net/parlparse">Parliament Parse</a> project.  The
division listings are in the main debate files, but are also available in
smaller division only files.  To get them do something like this:

<p><tt>rsync --recursive ukparse.kforge.net::parldata/scrapedxml/divisionsonly /home/francis/pwdata/scrapedxml</tt>

<h2>Loading data into the database</h2>

<p>Change to the <i>loader</i> directory.    You need
<i>memxml2db.pl</i>, which will load the information about MPs into
database tables.  First you have to tell Perl your MySQL username and
password.  Copy the file PublicWhip/Config.pm.incvs to PublicWhip/Config.pm and edit it.  Now
run:

<p><tt>./memxml2db.pl</tt>

<p>Next you need the script called <i>load.pl</i>. It loads the divisons
from the XML files into the database and does various cached
calculations for use on the website.  Run it with no parameters to find
out its syntax.  Now do this:

<p><tt>./load.pl divsxml check calc</tt>

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
the file config.php.incvs to config.php and edit it with your MySQL 
settings.  

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

<?php pw_footer() ?>

