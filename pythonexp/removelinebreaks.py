#! /usr/bin/python2.3

import sys
import os
import re

# this filter removes trailing angle brackets and linefeeds that break up tags
# we also take out comments and local pointers <a name=>


# in and out files for this filter
dirin = "glueddaydebates"
dirout = "c1daydebateremovechars"
dtemp = "daydebtemp.htm"

# this is used to check the results
junkfile = "daydebjunk.htm"
junk = open(junkfile, "a");


fdirin = os.listdir(dirin)


for fin in fdirin:
	jfin = os.path.join(dirin, fin)
	jfout = os.path.join(dirout, fin)
	if os.path.isfile(jfout):
		print "skipping " + fin
		continue

	tempfile = open(dtemp, "w")
	nrems = 0

	ofin = open(jfin)
	finr = ofin.read()
	ofin.close()

	# get rid of dos linefeeds
	finr = re.sub('\r', '', finr)

	abf = re.split('(<[^>]*>)', finr)
	for ab in abf:
		# delete comments and links
		if re.match('<!-[^>]*?->', ab):
			junk.write(ab)
		elif re.match('<a[^>]*>(?i)', ab):
			junk.write(ab)

			# this would catch if we've actually found a link
			if not re.match('<a name\s*?=\s*\S*?\s*?>(?i)', ab):
				print ab
		elif re.match('</a>(?i)', ab):
			junk.write(ab)

		# take out linefeeds
		elif re.match('<[^>]*>', ab):
			fn = re.subn('\n', '', ab)
			nrems = nrems + fn[1]
			tempfile.write(fn[0])

		# take out spurious > symbols
		else:
			fn = re.subn('>', '', ab)
			nrems = nrems + fn[1]
			tempfile.write(fn[0])

	tempfile.close()
	os.rename(dtemp, jfout)
	print "%s removed %d" % (fin, nrems)

