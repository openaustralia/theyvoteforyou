The Public Whip Source Code
---------------------------

Hello!  Here's the source code used to generate the Public Whip website.
To see the end product go to http://www.publicwhip.org.uk.  If you don't
know what this is all about, have a look at the FAQ there.  The rest of
this file is if you are interested in the code - for example, if you
want to add your own analyses, fix bugs or whatever.

If you need any help, please email me francis@flourish.org.

LICENSE.html - Details of open source licensing terms, under the GNU GPL
todo.txt - Things I'm thinking of doing in the short term
ideas.txt - Zillions of ideas of things which could be done
errata.txt - Errors in Hansard that the software has found

Here's how it works:  Perl code downloads data from the UK parliament
website, and stores it in a MySQL database. A combination of Perl and
Octave (an open source mathematics package, compatible with Matlab) code
perform various calculations on the data to form other database tables.
A website in PHP is provided to make it easy to look up information and
search the database. 

At the moment I've only run this on Linux, but it should run on Windows.

scraper - Screen scrapes Hansard website to fill the database, some analysis
rawdata - Source data files not previously available on the Internet
cluster - MP cluster analysis using Multi-dimensional Scaling
website - Code for www.publicwhip.org.uk, PHP extracts data from database
build   - Scripts I use to upload to www.publicwhip.org.uk

