#! /usr/bin/python2.3

import sys
import re
import os
import string
import cStringIO

from lordsfiltercoltime import FilterLordsColtime

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
		print jfout
		os.rename(tempfile, jfout)

# These text filtering functions filter twice through stringfiles,
# before directly filtering to the real file.
def RunLordsFilters(fout, text, sdate):
	si = cStringIO.StringIO()
	FilterLordsColtime(fout, text, sdate)


###############
# Main Function
###############

# create the output directory
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

RunFiltersDir(RunLordsFilters, 'lords')


