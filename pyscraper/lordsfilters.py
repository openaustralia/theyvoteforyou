#! /usr/bin/python2.3

import sys
import re
import os
import string
import cStringIO

from lordsfiltercoltime import FilterLordsColtime
from lordsfilterspeakers import LordsFilterSpeakers
from lordsfiltersections import LordsFilterSections


import mx.DateTime

import miscfuncs
toppath = miscfuncs.toppath




# master function which carries the glued pages into the xml filtered pages

# incoming directory of glued pages directories

pwlordspages = os.path.join(toppath, "pwlordspages")

# outgoing directory of scaped pages directories
pwxmldirs = os.path.join(toppath, "pwscrapedxml")

tempfile = os.path.join(toppath, "filtertemp")



# this is a standard copy from one directory to the other
# should move to miscfuncs
def RunFiltersDir(filterfunction, dname):
	# the in and out directories for the type
	pwcmdirin = pwlordspages
	pwxmldirout = os.path.join(pwxmldirs, dname)

	# create output directory
	if not os.path.isdir(pwxmldirout):
		os.mkdir(pwxmldirout)
        print pwxmldirout;

	# loop through file in input directory in reverse date order
	fdirin = os.listdir(pwcmdirin)
	fdirin.sort()
	fdirin.reverse()

	for fin in fdirin:
		jfin = os.path.join(pwcmdirin, fin)

		# extract the date from the file name
		sdate = re.search('\d{4}-\d{2}-\d{2}', fin).group(0)

		# create the output file name
		jfout = os.path.join(pwxmldirout, re.sub('\.html$', '.xml', fin))

		# skip already processed files
		if os.path.isfile(jfout):
			continue

		# read the text of the file
		print jfin
		ofin = open(jfin)
		text = ofin.read()
		ofin.close()

		# call the filter function and copy the temp file into the correct place.
		# this avoids partially processed files getting into the output when you hit escape.
		fout = open(tempfile, "w")
		filterfunction(fout, text, sdate)
		fout.close()
		os.rename(tempfile, jfout)



# this is not working easily.

# the lords block can be split into four pieces

regbeggc = '<H2><center>Official Report of the Grand Committee'
regbegws1 = '<h3 align=center>Written Statements</h3>'
regbegws2 = '<H3><center>Written Statements</center></H3>'
regbegwa = '<H3><center>Written Answers</center></H3>'

regoralwritten = re.compile('([\s\S]*?)((?:%s|%s|%s|%s)[\s\S]*)$' % (regbeggc, regbegws1, regbegws2, regbegwa) )


# split out and throw away written stuff for now.
def SplitLordsText(text):
	morwr = regoralwritten.match(text)
	if morwr:
		print 'debate %d  rest %d' % (len(morwr.group(1)), len(morwr.group(2)))
		return morwr.group(1)
	return text



# These text filtering functions filter twice through stringfiles,
# before directly filtering to the real file.
def RunLordsFilters(fout, text, sdate):
	text = SplitLordsText(text)

	si = cStringIO.StringIO()
	FilterLordsColtime(si, text, sdate)
   	text = si.getvalue()
	si.close()

	si = cStringIO.StringIO()
	LordsFilterSpeakers(si, text, sdate)
   	text = si.getvalue()
	si.close()

	LordsFilterSections(fout, text, sdate)


###############
# Main Function
###############

# create the output directory
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

RunFiltersDir(RunLordsFilters, 'lords')



