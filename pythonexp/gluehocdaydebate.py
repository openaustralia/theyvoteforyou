#! /usr/bin/python2.3

import sys
import urllib
import urlparse
import re
import os.path

# this does the main loading and gluing of the initial day debate files from which everything else feeds forward
# the outputs go into glueddaydebates/

dglueddaydebates = 'glueddaydebates'

# read through our index list of daydebates
hocdaydebatelist = "hocdaydebatelist.xml"
fhocdaydebatelist = open(hocdaydebatelist);

# generate the filenames we will use, and the urls that will point into them
daydebateurl = []
while 1:
	ls = fhocdaydebatelist.readline()
	if not ls:
		break

	# <daydeb date="Tuesday 11 November 2003" type="Written Ministerial Statements" url="http://www.publications.parliament.uk/pa/cm200203/cmhansrd/cm031111/wmsindx/31111-x.htm">
	ddate = re.findall('date="(.*?)"', ls)
	dtype = re.findall('type="(.*?)"', ls)
	durl = re.findall('url="(.*?)"', ls)



	if (len(ddate) != 1) or (len(dtype) != 1) or (len(durl) != 1):
		print "BAD XML file"
	if not re.search('debate(?i)', dtype[0]):
		continue

	# quick and dirty file name for now
	sdate = 'daydeb' + re.sub('\s', '', ddate[0]) + '.html'
	daydebateurl.append( (sdate, durl[0]) )

# glueddaydebates


# this is used to check the results
junkfile = "daydebjunk.htm"

# this is used to avoid partial files
tempfile = "daydebtemp.htm"

# output files
junk = open(junkfile, "a");

for dnu in daydebateurl:
	dgf = os.path.join(dglueddaydebates, dnu[0])

	# if we already have got the file, no need to scrape it in again
	if os.path.exists(dgf):
		print "skipping " + dgf
		continue

	# now we have the difficulty of pulling in the first link out of this silly index page
	print dnu[1]
	urx = urllib.urlopen(dnu[1])
	while 1:
		xline = urx.readline()
		if not xline:
			break
		if re.search('<hr>(?i)', xline):
			break
	lk = []
	while xline:
		# <a HREF =" ../debtext/31106-01.htm#31106-01_writ0">Oral Answers to Questions [6 Nov 2003] </a>
		lk = re.findall('<a\s+href\s*=\s*"(.*?)">.*?</a>(?i)', xline)
		if len(lk) != 0:
			break
		xline = urx.readline()
	urx.close()
	if len(lk) == 0:
		print "No link found!!!"

	# now we take out the local pointer and start the gluing
	url = urlparse.urljoin(dnu[1], re.sub('#.*?$' , '', lk[0]))
	dtemp = open(tempfile, "w")
	while 1:
		print "reading " + url
		ur = urllib.urlopen(url)
		sr = ur.read()
		ur.close();

		# split by sections
		hrsections = re.split('<hr>(?i)', sr)

		# write the junk
		junk.write('<page url="' + url + '">\n')
		junk.write(hrsections[0])

		# write the body of the text
		dtemp.write('<page url="' + url + '">\n')
		map(dtemp.write, hrsections[1:(len(hrsections) - 1)])

		# find the lead on with the footer
		footer = hrsections[len(hrsections) - 1]
		junk.write(footer)

		# the files are sectioned by the <hr> tag into header, body and footer.
		nextsectionlink = re.findall('<\s*a\s+href\s*=\s*"?(.*?)"?\s*>next section</a>(?i)', footer)
		if len(nextsectionlink) > 1:
			print "More than one Next Section!!!"
		if len(nextsectionlink) == 0:
			break
		url = urlparse.urljoin(url, nextsectionlink[0])

	# close and move
	dtemp.close()
	os.rename(tempfile, dgf)


junk.close()




