#! /usr/bin/python2.3

import sys
import re
import os
import string

# this filter finds the speakers and replaces with full itendifiers
# <speaker name="Eric Martlew  (Carlisle)"><p>Eric Martlew  (Carlisle)</p></speaker>

def WransSpeakerNames(fout, finr, sdate):

	# <B> Mrs. Iris Robinson: </B>
	lspeakerregexp = '<b>.*?</b>\s*?:|<b>.*?</b>'
	ltableregexp = '<table.*?>[\s\S]*?</table>'	# these have bolds, so must be separated out
	speakerregexp = '<b>\s*([^:]*?):?\s*</b>(?i)'
	tableregexp = ltableregexp + '(?i)'

	lregexp = '(%s|%s)(?i)' % (lspeakerregexp, ltableregexp)

	# setup for scanning through the file.
	# we should have a name matching module which gets the unique ids, and
	# takes the full speaker name and date to find a match.
	fs = re.split(lregexp, finr)


	for i in range(len(fs)):
		fss = fs[i]

		if re.match(tableregexp, fss):
			continue

		speakergroup = re.findall(speakerregexp, fss)
		if len(speakergroup) == 0:
			continue

		# we have a string in bold
		boldnamestring = speakergroup[0]

		# we need to call a name matching module here

		# try to pull in the question number if preceeding
		# These signify aborted oral questions, and are normally useless and at the start of the page.
		# 27. <B> Mr. Steen: </B>
		if i > 0:
			oqnsep = re.findall('^([\s\S]*?)Q?(\d+[.])\s*?$', fs[i - 1])
			if len(oqnsep) != 0:
				fs[i - 1] = oqnsep[0][0]
				boldnamestring = oqnsep[0][1] + ' ' + boldnamestring

		# now output what we've decided
		#print boldnamestring
		fs[i] = '<p><speaker name="%s"><font color="#003fcf">%s</font></speaker></p>\n' % (boldnamestring, boldnamestring)


	# output everything now
	for fss in fs:
		fout.write(fss)
