The Public Whip Source Code
---------------------------

Hello!  Here's the source code used to generate the Public Whip website.
To see the end product go to http://www.publicwhip.org.uk.  If you don't
know what this is all about, have a look at the FAQ there.

To learn how to use the code look at
http://www.publicwhip.org.uk/project/code.php or locally in
webpage/project/code.php.  A description of the files and folders in
this package follows.

LICENSE.html - Details of open source licensing terms, under the GNU GPL
todo.txt - Things I'm thinking of doing in the short term
ideas.txt - Zillions of ideas of things which could be done
errata.txt - Errors in Hansard that the software has found

pyscraper - Hansard screen scraper which makes XML files, written in Python
loader    - Load XML files into the database
rawdata   - Source data files not previously available on the Internet
cluster   - MP cluster analysis using Multi-dimensional Scaling

members   - MP list as one fat XML file (used by pyscraper)
pyindex   - Indexing code for wrans XML files made by pyscraper

website   - Code for www.publicwhip.org.uk, PHP extracts data from database/XML
build     - Scripts I use for admin, such as to upload to www.publicwhip.org.uk
custom    - Various one off scripts and graphics made for special purposes

If you need any help, please email me francis@flourish.org.
