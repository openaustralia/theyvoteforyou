#! /usr/bin/python2.3

import sys
import urllib
import urlparse
import re
import os.path
import xml.sax
import time

import miscfuncs
toppath = miscfuncs.toppath

# Pulls in all the debates, written answers, etc, glues them together, removes comments,
# and stores them on the disk

# index file which is created
pwcmindex = os.path.join(toppath, "pwcmindex.xml")

# output directories
pwcmdirs = os.path.join(toppath, "pwcmpages")

pwcmwrans = os.path.join(pwcmdirs, "wrans")
pwcmdebates = os.path.join(pwcmdirs, "debates")
# statements and westminster hall

tempfile = os.path.join(toppath, "gluetemp")

# this does the main loading and gluing of the initial day debate files from which everything else feeds forward

# gets the index file which we use to go through the pages
class LoadCmIndex(xml.sax.handler.ContentHandler):
	def __init__(self, lpwcmindex):
		self.res = []
		if not os.path.isfile(lpwcmindex):
			return
		parser = xml.sax.make_parser()
		parser.setContentHandler(self)
		parser.parse(lpwcmindex)

	def startElement(self, name, attr):
		if name == "cmdaydeb":
			ddr = (attr["date"], attr["type"], attr["url"])
			self.res.append(ddr)



def WriteCleanText(fout, text):

	abf = re.split('(<[^>]*>)', text)
	for ab in abf:
		# delete comments and links
		if re.match('<!-[^>]*?->', ab):
			pass

		elif re.match('<a[^>]*>(?i)', ab):
			# this would catch if we've actually found a link
			if not re.match('<a name\s*?=\s*\S*?\s*?>(?i)', ab):
				print ab

		elif re.match('</a>(?i)', ab):
			pass

		# spaces only inside tags
		elif re.match('<[^>]*>', ab):
			fout.write(re.sub('\s', ' ', ab))

		# take out spurious > symbols and dos linefeeds
		else:
			fout.write(re.sub('>|\r', '', ab))


def GlueByNext(fout, url, urlx):
	# put out the indexlink for comparison with the hansardindex file
	lt = time.gmtime()
	fout.write('<pagex url="%s" scrapedate="%s" scrapetime="%s"/>\n' % \
			(urlx, time.strftime('%Y-%m-%d', lt), time.strftime('%X', lt)))

	# loop which scrapes through all the pages following the nextlinks
	while 1:
		# print " reading " + url
		ur = urllib.urlopen(url)
		sr = ur.read()
		ur.close();

		# write the marker telling us which page this comes from
		fout.write('<page url="' + url + '"/>\n')


		# split by sections
		hrsections = re.split('<hr>(?i)', sr)

		# this is the case for debates on 2003-03-13 page 30
		# http://www.publications.parliament.uk/pa/cm200203/cmhansrd/vo030313/debtext/30313-32.htm
		if len(hrsections) == 1:
			print len(hrsections)
			print ' page missing '
			print url
			fout.write('<UL><UL><UL></UL></UL></UL>\n')
			break


		# write the body of the text
		for i in range(1,len(hrsections) - 1):
			WriteCleanText(fout, hrsections[i])

		# find the lead on with the footer
		footer = hrsections[len(hrsections) - 1]

		# the files are sectioned by the <hr> tag into header, body and footer.
		nextsectionlink = re.findall('<\s*a\s+href\s*=\s*"?(.*?)"?\s*>next section</a>(?i)', footer)
		if not nextsectionlink:
			break
		if len(nextsectionlink) > 1:
			raise Exception, "More than one Next Section!!!"
		url = urlparse.urljoin(url, nextsectionlink[0])


# now we have the difficulty of pulling in the first link out of this silly index page
def ExtractFirstLink(url):
	urx = urllib.urlopen(url)
	while 1:
		xline = urx.readline()
		if not xline:
			break
		if re.search('<hr>(?i)', xline):
			break

	lk = []
	while xline:
		# <a HREF =" ../debtext/31106-01.htm#31106-01_writ0">Oral Answers to Questions </a>
		lk = re.findall('<a\s+href\s*=\s*"(.*?)">.*?</a>(?i)', xline)
		if lk:
			break
		xline = urx.readline()
	urx.close()

	if not lk:
		raise Exception, "No link found!!!"
	return urlparse.urljoin(url, re.sub('#.*$' , '', lk[0]))


# read through our index list of daydebates
def GlueAllType(pcmdir, cmindex, nametype, fproto):
	if not os.path.isdir(pcmdir):
		os.mkdir(pcmdir)

	for dnu in cmindex:
		# pick only the right type
		if not re.search(nametype, dnu[1]):
			continue

		# make the filename
		dgf = os.path.join(pcmdir, (fproto % dnu[0]))

		# hansard index page
		urlx = dnu[2]

		# if we already have got the file, check the pagex link agrees in the first line
		# no need to scrape it in again
		if os.path.exists(dgf):
			fpgx = open(dgf, "r")
			pgx = fpgx.readline()
			fpgx.close()
			if pgx:
				pgx = re.findall('<pagex url="([^"]*)"[^/]*/>', pgx)
				if pgx:
					if pgx[0] == urlx:
						# print 'skipping ' + urlx
						continue
			print 'RE-scraping ' + urlx
		else:
			print 'scraping ' + urlx

		url0 = ExtractFirstLink(urlx)

		# now we take out the local pointer and start the gluing
		dtemp = open(tempfile, "w")
		GlueByNext(dtemp, url0, urlx)

		# close and move
		dtemp.close()
		os.rename(tempfile, dgf)



###############
# main function
###############
def PullGluePages(datefrom, dateto):
	# make the output firectory
	if not os.path.isdir(pwcmdirs):
		os.mkdir(pwcmdirs)

	# load the index file previously made by createhansardindex
	ccmindex = LoadCmIndex(pwcmindex)

        # extract date range we want
        def indaterange(x): 
                return x[0] >= datefrom and x[0] <= dateto
        ccmindex.res = filter(indaterange,ccmindex.res)

	# bring in and glue together parliamentary debates, and answers and put into their own directories.
	# third parameter is a regexp, fourth is the filename (%s becomes the date).
	GlueAllType(pwcmdebates, ccmindex.res, 'debates(?i)', 'debates%s.html')
	GlueAllType(pwcmwrans, ccmindex.res, 'answers(?i)', 'answers%s.html')



