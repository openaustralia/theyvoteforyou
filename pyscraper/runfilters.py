#! /usr/bin/python2.3

import sys
import re
import os
import string
import cStringIO

from filterwranscolnum import FilterWransColnum
from filterwransspeakers import FilterWransSpeakers
from filterwranssections import FilterWransSections

toppath = os.path.expanduser('~/pwdata/')

# master function which carries the glued pages into the xml filtered pages

# in/output directories
pwcmdirs = toppath + "pwcmpages/"
pwcmwrans = pwcmdirs + "wrans/"

pwxmldirs = toppath + "pwscrapedxml/"
pwxmwrans = pwxmldirs + "wrans/"

tempfile = toppath + "filtertemp"


# filter twice through stringfiles, and then to the real file
def RunFilters(fout, text, sdate):
	si = cStringIO.StringIO()
	FilterWransColnum(si, text, sdate)
	text = si.getvalue()
	si.close()

	si = cStringIO.StringIO()
	FilterWransSpeakers(si, text, sdate)
	text = si.getvalue()
	si.close()

	FilterWransSections(fout, text, sdate)


###############
# Main Function
###############
def RunFiltersDir():
	if not os.path.isdir(pwxmldirs):
		os.mkdir(pwxmldirs)

	# filtering on written answers (will generalize into others)
	if not os.path.isdir(pwxmwrans):
		os.mkdir(pwxmwrans)

	dirin = pwcmwrans
	dirout = pwxmwrans

	fdirin = os.listdir(dirin)
	fdirin.sort()
	fdirin.reverse()
	for fin in fdirin:
		jfin = os.path.join(dirin, fin)

		sdate = re.findall('\d{4}-\d{2}-\d{2}', fin)[0]
		jfout = os.path.join(dirout, re.sub('[.]html$', '.xml', fin))

		if os.path.isfile(jfout):
			continue

		ofin = open(jfin)
		text = ofin.read()
		ofin.close()

		print fin
		fout = open(tempfile, "w")
		RunFilters(fout, text, sdate)
		fout.close()
		os.rename(tempfile, jfout)

RunFiltersDir()


