#! /usr/bin/python2.3

import sys
import urllib
import urlparse
import re

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

# Run this module to generate an xml file of all the links into the daydebates, written questions, etc.
# The output file is used as a basis for planning the larger scale scraping.
# This prog is not yet reliable for all cases.

def FindAllHocDayDebate(daydebates, urlindex):
	# all urls pages which have links into day debates are put into this list
	urlindexpages = [ ]
	urlindexpages.append(urlindex)

	urindex = urllib.urlopen(urlindex)
	srindex = urindex.read()
	urindex.close()

	# extract the per month volumes
	# <a href="cmhn0310.htm"><b>October</b></a>
	monthnames = 'January|February|March|April|May|June|July|August|September|October|November|December'
	monthlinks = re.findall('<a href="(.*?)"><b>(?:' + monthnames + ')</b>(?i)', srindex)
	for month in monthlinks:
		urlindexpages.append(urlparse.urljoin(urlindex, month))

	# extract the year links to volumes
	# <a href="cmse9495.htm"><b>Session 1994-95</b></a>
	yearvollinks = re.findall('<a href="(.*?)"><b>session.*?</b></a>(?i)', srindex);

	# extract the volume links
	for yearvol in yearvollinks:
		urlyearvol = urlparse.urljoin(urlindex, yearvol)
		uryearvol = urllib.urlopen(urlyearvol)
		sryearvol = uryearvol.read()
		uryearvol.close()
		# <a href="cmvol352.htm"><b>Volume 352</b>
		vollinks = re.findall('<a href="(.*?)"><b>volume.*?</b>(?i)', sryearvol)

		for vol in vollinks:
			urlindexpages.append(urlparse.urljoin(urlyearvol, vol))




	print urlindexpages

	for urlindexpage in urlindexpages:
		urindexpage = urllib.urlopen(urlindexpage)
		srindexpage = urindexpage.read()
		urindexpage.close()

		# these index pages are very broken, need to collapse linefeeds to spaces and find all the links out of them
		srindexpage = re.sub('(\n|\r)+', ' ', srindexpage)

		# <b>Wednesday 5 November 2003</b>
		#<td colspan=2><font size=+1><b>Wednesday 5 November 2003</b></font></td>
		# <a href="../cm199900/cmhansrd/vo000309/debindx/00309-x.htm">Oral Questions and Debates</a>
		datelinks = re.findall('<b>([^<>]*?(?:' + monthnames + ')[^<>]*?)</b>|<a href="([^<>]*)">([^<>]*)</a>(?i)', srindexpage)

		date = ''
		for link in datelinks:
			# print "link0 " , link[0], " link1 ", link[1], " link2 ", link[2]
			if link[0] != '':
				date = link[0]
				date = mx.DateTime.DateTimeFrom(date).date
			elif re.search('debate|westminster|written(?i)', link[2]):
				uind = urlparse.urljoin(urlindexpage, link[1])
				daydebates.write('<daydeb date="%s" type="%s" url="%s"/>\n' % (date, link[2], uind))
		print date


