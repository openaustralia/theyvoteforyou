#! /usr/bin/python2.3
import sys
import os
import urllib
import urlparse
import string
import re
import xml.sax

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

import miscfuncs

toppath = miscfuncs.toppath

# Generates an xml file with all the links into the daydebates, written questions, etc.
# The output file is used as a basis for planning the larger scale scraping.
# This prog is not yet reliable for all cases.

# this only does the commons index.
# Lords index is a completely different format.

# An index page is a page with links to a set of days,
#   NOT an index page into the pages for a single day.

# url for commons index
urlcmindex = "http://www.publications.parliament.uk/pa/cm/cmhansrd.htm"
# index file which is created
pwcmindex = os.path.join(toppath, "cmindex.xml")

# scrape limit date
earliestdate = '2001-11-25'
#earliestdate = '1994-05-01'

# regexps for decoding the data on an index page
monthnames = 'January|February|March|April|May|June|July|August|September|October|November|December'
redateindexlinks = re.compile('<b>\s*(\S+\s+\d+\s+(?:%s)\s+\d+)\s*</b>|<a\s+href="([^"]*)">([^<]*)</a>(?i)' % monthnames)


# this pulls out all the direct links on this particular page
def CmIndexFromPage(urllinkpage):
	urlinkpage = urllib.urlopen(urllinkpage)
	srlinkpage = urlinkpage.read()
	urlinkpage.close()

	# remove comments because they sometimes contain wrong links
	srlinkpage = re.sub('<!--[\s\S]*?-->', ' ', srlinkpage)

	# <b>Wednesday 5 November 2003</b>
	#<td colspan=2><font size=+1><b>Wednesday 5 November 2003</b></font></td>
	# <a href="../cm199900/cmhansrd/vo000309/debindx/00309-x.htm">Oral Questions and Debates</a>
	datelinks = redateindexlinks.findall(srlinkpage)

	# read the dates and links in order, and associate last date with each matching link
	res = []
	sdate = ''
	for link in datelinks:
		if link[0]:
			odate = re.sub('\s', ' ', link[0])
			sdate = mx.DateTime.DateTimeFrom(odate).date

		# the link types by name
		elif re.search('debate|westminster|written(?i)', link[2]):
			if not sdate:
				raise Exception, 'No date for link in: ' + urllinkpage
			#if re.search('debate(?i)', link[2]):
                        #        print sdate

			# take out spaces and linefeeds we don't want
			uind = urlparse.urljoin(urllinkpage, re.sub('\s', '', link[1]))
			typ = string.strip(re.sub('\s\s+', ' ', link[2]))
			res.append((sdate, typ, uind))
	return res


# Find all the index pages from the front index page by recursing into the months
# and then the years and volumes pages
def CmAllIndexPages(urlindex):

	# all urls pages which have links into day debates are put into this list
	# except the first one, which will have been looked at
	res = [ ]

	#print urlindex
	urindex = urllib.urlopen(urlindex)
	srindex = urindex.read()
	urindex.close()

	# extract the per month volumes
	# <a href="cmhn0310.htm"><b>October</b></a>
	monthindexp = '<a href="([^"]*)"><b>(?:%s)</b>(?i)' %  monthnames
	monthlinks = re.findall(monthindexp, srindex)
	for monthl in monthlinks:
		res.append(urlparse.urljoin(urlindex, re.sub('\s', '', monthl)))

	# extract the year links to volumes
	# <a href="cmse9495.htm"><b>Session 1994-95</b></a>
	# sessions before 94 have the bold tag the wrong way round,
	# but we don't want to go that far back now anyhow.
	yearvollinks = re.findall('<a href="([^"]*)"><b>session[^<]*</b></a>(?i)', srindex);

	# extract the volume links
	for yearvol in yearvollinks:
		#print yearvol
		urlyearvol = urlparse.urljoin(urlindex, re.sub('\s', '', yearvol))
		uryearvol = urllib.urlopen(urlyearvol)
		sryearvol = uryearvol.read()
		uryearvol.close()

		# <a href="cmvol352.htm"><b>Volume 352</b>
		vollinks = re.findall('<a href="([^"]*)"><b>volume[^<]*</b>(?i)', sryearvol)
		for vol in vollinks:
			#print vol
			res.append(urlparse.urljoin(urlyearvol, re.sub('\s', '', vol)))

	return res


def WriteXML(fout, urllist):
	fout.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
	fout.write("<publicwhip>\n\n")

	# avoid printing duplicates
	for i in range(len(urllist)):
		r = urllist[i]
		if (i == 0) or (r != urllist[i-1]):
			if r[0] >= earliestdate:
				fout.write('<cmdaydeb date="%s" type="%s" url="%s"/>\n' % r)

	fout.write("\n</publicwhip>\n")


# gets the old file so we can compare the head values
class LoadOldIndex(xml.sax.handler.ContentHandler):
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

	def CompareHeading(self, urllisthead):
		if not self.res:
			return 0

		for i in range(len(urllisthead)):
			if (i >= len(self.res)) or (self.res[i] != urllisthead[i]):
				#print i
				return 0
		return 1



###############
# main function
###############
def UpdateHansardIndex():
	# get front page (which we will compare against)
	urllisth = CmIndexFromPage(urlcmindex)
	urllisth.sort()
	urllisth.reverse()

	# compare this leading term against the old index
	oldindex = LoadOldIndex(pwcmindex)
	if oldindex.CompareHeading(urllisth):
		#print ' Head appears the same, no new list '
		return
	#print 'compare heading now doesnt work because Im sorting the data'
	#print 'and there are discrepancies between the front page and those'
	#print 'listed in the November page!!!'


	# extend our list to all the pages
	cres = CmAllIndexPages(urlcmindex)
	for cr in cres:
		urllisth.extend(CmIndexFromPage(cr))
	urllisth.sort()
	urllisth.reverse()

	fpwcmindex = open(pwcmindex, "w");
	WriteXML(fpwcmindex, urllisth)
	fpwcmindex.close()

