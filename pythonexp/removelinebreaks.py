#! /usr/bin/python2.3

import sys
import os
import re

# this filter removes trailing angle brackets and linefeeds that break up tags
# we also take out comments and local pointers <a name=>


def RemoveLineChars(fout, finr, sdate):
	nrems = 0

	# get rid of dos linefeeds
	finr = re.sub('\r', '', finr)

	abf = re.split('(<[^>]*>)', finr)
	for ab in abf:
		# delete comments and links
		if re.match('<!-[^>]*?->', ab):
			pass #junk.write(ab)
		elif re.match('<a[^>]*>(?i)', ab):
			pass #junk.write(ab)

			# this would catch if we've actually found a link
			if not re.match('<a name\s*?=\s*\S*?\s*?>(?i)', ab):
				print ab
		elif re.match('</a>(?i)', ab):
			pass #junk.write(ab)

		# take out linefeeds
		elif re.match('<[^>]*>', ab):
			fn = re.subn('\n', '', ab)
			nrems = nrems + fn[1]
			fout.write(fn[0])

		# take out spurious > symbols
		else:
			fn = re.subn('>', '', ab)
			nrems = nrems + fn[1]
			fout.write(fn[0])

	print "removed %d" % nrems

