#! /usr/bin/env python2.3
# vim:sw=8:ts=8:et:nowrap

import os
import datetime
import re
import sys
import urllib
import string


import miscfuncs
import difflib

rawdatapath = miscfuncs.rawdatapath


# This code is for grabbing pages of government and party positions off the hansard webpage,
# testing for changes and filing them into directories where they can be parsed at leisure

# These links come from the page "http://www.parliament.uk/directories/directories.cfm"

watchpages = {  "govposts":"http://www.parliament.uk/directories/hciolists/hmg.cfm",
				"offoppose":"http://www.parliament.uk/directories/hciolists/opp.cfm",
				"libdem":"http://www.parliament.uk/directories/hciolists/libdems.cfm",
				"dup":"http://www.parliament.uk/directories/hciolists/dup.cfm",
				"ulsterun":"http://www.parliament.uk/directories/hciolists/ulster.cfm",
				"plaidsnp":"http://www.parliament.uk/directories/hciolists/PCSNP.cfm",
				"privsec":"http://www.parliament.uk/directories/hciolists/Pps.cfm",
				"selctee":"http://www.parliament.uk/directories/hciolists/selmem.cfm",
                                "clerks":"http://www.publications.parliament.uk/pa/cm/listgovt.htm",
			 }


# go through each of the pages in the above map and make copies where there are changes
# compared to the last version that's there.
# This is general code that works for single pages at single urls only and doesn't strip any of the garbage.
def GrabWatchCopies(sdate):
	# make directories that don't exist
	chggdir = os.path.join(rawdatapath, "chggpages")
	if not os.path.isdir(chggdir):
            raise Exception, 'Data directory %s does not exist, you\'ve not got a proper checkout from CVS.' % (chggdir)

	for ww in watchpages:
		watchdir = os.path.join(chggdir, ww)
		if not os.path.isdir(watchdir):
			os.mkdir(watchdir)
		wl = os.listdir(watchdir)
		wl.sort()

		lastval = ""
		lastnum = 0
		if wl:
			lin = open(os.path.join(watchdir, wl[-1]), "r")
			lastval = lin.read()
			lin.close()
			numg = re.match("\D*(\d+)_", wl[-1])
			assert numg
			lastnum = string.atoi(numg.group(1))

		# get copy from web
		#print "urling", watchpages[ww]
		ur = urllib.urlopen(watchpages[ww])
		currval = ur.read()
		ur.close()

		# comparison with previous page
		# we use 4 digit numbering at the front to ensure that cases are separate and ordered
		if currval != lastval:

			# build the name for this page and make sure it follows, even when we have the same date
			wwn = "%s%04d_%s.html" % (ww, lastnum + 1, sdate)
			wwnj = os.path.join(watchdir, wwn)
			# print "changed page", wwnj

			assert not os.path.isfile(wwn)
			wout = open(wwnj, "w")
			wout.write(currval)
			wout.close()

			# make a report of the diffs (can't find a way to use charjunk to get rid of \r's)
			#diffs = list(difflib.Differ().compare(lastval.splitlines(1), currval.splitlines(1)))
			#sys.stdout.writelines(diffs[:50])


