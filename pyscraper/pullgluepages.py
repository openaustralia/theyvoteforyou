#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import urllib
import urllib2
import urlparse
import re
import os.path
import xml.sax
import time
import tempfile
import string
import miscfuncs
toppath = miscfuncs.toppath

# Pulls in all the debates, written answers, etc, glues them together, removes comments,
# and stores them on the disk

# index file which is created   
pwcmindex = os.path.join(toppath, "cmindex.xml")

# output directories
pwcmdirs = os.path.join(toppath, "cmpages")

tempfilename = tempfile.mktemp("", "pw-gluetemp-", miscfuncs.tmppath)

# this does the main loading and gluing of the initial day debate files from which everything else feeds forward

class DefaultErrorHandler(urllib2.HTTPDefaultErrorHandler):
        def http_error_default(self, req, fp, code, msg, headers):
                result = urllib2.HTTPError(
                                req.get_full_url(), code, msg, headers, fp)
                result.status = code
                return result

# gets the index file which we use to go through the pages
class LoadCmIndex(xml.sax.handler.ContentHandler):
	def __init__(self, lpwcmindex):
		self.res = []
                self.check = {}
		if not os.path.isfile(lpwcmindex):
			return
		parser = xml.sax.make_parser()
		parser.setContentHandler(self)
		parser.parse(lpwcmindex)

	def startElement(self, name, attr):
		if name == "cmdaydeb":
			ddr = (attr["date"], attr["type"], attr["url"])
			self.res.append(ddr)

			# check for repeats - error in input XML
			key = (attr["date"], attr["type"])
			if key in self.check:
				raise Exception, "Same date/type twice %s %s\nurl1: %s\nurl2: %s" % (ddr + (self.check[key],))
			if not re.search("answers|debates|westminster|ministerial|votes(?i)", attr["type"]):
				raise Exception, "cmdaydeb of unrecognized type: %s" % attr["type"]
			self.check[key] = attr["url"]



def WriteCleanText(fout, text):
	abf = re.split('(<[^>]*>)', text)
	for ab in abf:
		# delete comments and links
		if re.match('<!-[^>]*?->', ab):
			pass

		elif re.match('<a[^>]*>(?i)', ab):
			anamem = re.match('<a name\s*?=\s*?"?(\S*?)"?\s*?>(?i)', ab)
                        if anamem:
                                aname = anamem.group(1)
                                if not re.search('column', aname): # these get in the way
                                        fout.write('<a name="%s">' % aname)
                        else:
                                # We should never find any other sort of <a> tag - such
                                # as a link (as there aren't any on parliament.uk)
                                print "Caught a link ", ab

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
                if (url != urlx):
                        fout.write('<page url="' + url + '"/>\n')

                sr = re.sub('<!-- end of variable data -->.*<hr>(?si)', '<hr>', sr)

		# split by sections
                hrsections = re.split('<hr(?: size=3)?>(?i)', sr)

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
		footer = hrsections[-1]

		# the files are sectioned by the <hr> tag into header, body and footer.
		nextsectionlink = re.findall('<\s*a\s+href\s*=\s*"?(.*?)"?\s*>next section</a>(?i)', footer)
		if not nextsectionlink:
			break
		if len(nextsectionlink) > 1:
			raise Exception, "More than one Next Section!!!"
		url = urlparse.urljoin(url, nextsectionlink[0])


# now we have the difficulty of pulling in the first link out of this silly index page
def ExtractFirstLink(url, dgf, forcescrape):
        request = urllib2.Request(url)
        if not forcescrape and os.path.exists(dgf):
                mtime = os.path.getmtime(dgf)
                mtime = time.gmtime(mtime)
                mtime = time.strftime("%a, %d %b %Y %H:%M:%S GMT", mtime)
                request.add_header('If-Modified-Since', mtime)
        opener = urllib2.build_opener( DefaultErrorHandler() )
        urx = opener.open(request)
        if hasattr(urx, 'status'):
                if urx.status == 304:
                        return ''

	while 1:
		xline = urx.readline()
		if not xline:
			break
		if re.search('<hr>(?i)', xline):
			break

	lk = []
	while xline:
		# <a HREF =" ../debtext/31106-01.htm#31106-01_writ0">Oral Answers to Questions </a>
		lk = re.findall('<a\s+href\s*=\s*"(.*?)">.*?\s*</a>(?i)', xline)
		if lk:
			break
		xline = urx.readline()
	urx.close()

	if not lk:
		print urx
		raise Exception, "No link found!!!"
	return urlparse.urljoin(url, re.sub('#.*$' , '', lk[0]))

def getHTMLdiffname(jfout):
        renn = re.compile("%s.diff(\d+)" % os.path.basename(jfout))
        ipp = 1
        for pp in os.listdir(os.path.dirname(jfout)):
                regpp = renn.match(pp)
                if regpp:
                        ipp = string.atoi(regpp.group(1)) + 1
        res = "%s.diff%d" % (jfout, ipp)
        assert renn.match(os.path.basename(res))
        assert not os.path.isfile(res)
        return res

# read through our index list of daydebates
def GlueAllType(pcmdir, cmindex, nametype, fproto, forcescrape):
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


                if dnu[1] == 'Votes and Proceedings':
                        url0 = urlx
                else:
                        url0 = ExtractFirstLink(urlx, dgf, forcescrape)
                if not url0:
                        continue

		# now we take out the local pointer and start the gluing
		dtemp = open(tempfilename, "w")
		GlueByNext(dtemp, url0, urlx)
		dtemp.close()

                if os.path.exists(dgf):
                        outpatch = getHTMLdiffname(dgf)
                        ern = os.system('diff -u --ignore-matching-lines="<.*?url=[^>]*>" %s %s > %s' % (tempfilename, dgf, outpatch))
                        if ern == 2:
                                print "Error running diff"
                                raise Exception, "Error running diff"
                        if not os.path.getsize(outpatch):
                                os.remove(outpatch)
                        else:
                                print "Hansard has changed, writing difffile %s" % outpatch
                                os.remove(dgf)
	        	        os.rename(tempfilename, dgf)
                else:
                        print 'scraping %s %s' % (dnu[0], dnu[1])
        		os.rename(tempfilename, dgf)

###############
# main function
###############
def PullGluePages(datefrom, dateto, forcescrape, folder, typ):
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
	# type is "answers" or "debates"
	pwcmfolder = os.path.join(pwcmdirs, folder)
	GlueAllType(pwcmfolder, ccmindex.res, typ + '(?i)', typ + '%s.html', forcescrape)


