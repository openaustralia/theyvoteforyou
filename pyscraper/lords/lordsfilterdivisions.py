#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import re
import os
import string


# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

from splitheadingsspeakers import SplitHeadingsSpeakers
from splitheadingsspeakers import StampUrl

from clsinglespeech import qspeech
from parlphrases import parlPhrases

from miscfuncs import FixHTMLEntities

from filterdivision import FilterDivision
from filterdebatespeech import FilterDebateSpeech

from lordsfilterspeakers import lordlist



recontma = re.compile('<center><b>(.*?)\s*</b></center>(?i)')
retellma = re.compile('(.*?)\s*\[(Teller)\]$')
reoffma = re.compile('(.*?)\s*\((.*?)\)$')
def LordsFilterDivision(text, stampurl, sdate):

	# the intention is to splice out the known parts of the division
	fs = re.split('\s*(?:<br>|<p>)\s*(?i)', text)

	contentlords = [ ]
	notcontentlords = [ ]
	contstate = ''

	for fss in fs:
		if not fss:
			continue
		cfs = recontma.match(fss)
		if cfs:
			if cfs.group(1) == "CONTENTS":
				assert contstate == ''
				contstate = 'content'
			elif cfs.group(1) == 'NOT-CONTENTS':
				assert contstate == 'content'
				contstate = 'not-content'
			else:
				print "$$$%s$$$" % cfs.group(1)
				raise Exception, "unrecognized content state"
		else:
			assert contstate != ''

            # split off teller case
			teller = retellma.match(fss)
			tels = ''
			lfss = fss
			if teller:
				lfss = teller.group(1)
				tels = ' teller="yes"'

			# strip out the office
			offm = reoffma.match(lfss)
			if offm:
				lfss = offm.group(1)

			lordid = lordlist.MatchRevName(lfss, stampurl)
			lordw = '\t<lord id="%s" vote="%s"%s>%s</lord>' % (lordid, contstate, tels, FixHTMLEntities(fss))

			if contstate == 'content':
				contentlords.append(lordw)
			else:
				notcontentlords.append(lordw)

	# now build up the return value
	stext = [ ]
	stext.append('<divisioncount content="%d" not-content="%d"/>' % (len(contentlords), len(notcontentlords)))
	stext.append('<lordlist vote="content">')
	stext.extend(contentlords)
	stext.append('</lordlist>')
	stext.append('<lordlist vote="not-content">')
	stext.extend(notcontentlords)
	stext.append('</lordlist>')

	return stext


# handle a division case (resolved comes from the lords)
regenddiv = '(Resolved in the)'
def LordsDivisionParsingPart(divno, unspoketxt, stampurl, sdate):
	# find the ending of the division and split it off.
	gquesacc = re.search(regenddiv, unspoketxt)
	if gquesacc:
		divtext = unspoketxt[:gquesacc.start(1)]
		unspoketxt = unspoketxt[gquesacc.start(1):]
	else:
		divtext = unspoketxt
		print "division missing %s" % regenddiv
		unspoketxt = ''

	# Add a division object (will contain votes and motion text)
	spattr = 'nospeaker="true" divdate="%s" divnumber="%s"' % (sdate, divno)
	qbd = qspeech(spattr, divtext, stampurl)
	qbd.typ = 'division' # this type field seems easiest way

	# filtering divisions here because we may need more sophisticated detection
	# of end of division than the "Question accordingly" marker.
	qbd.stext = LordsFilterDivision(qbd.text, stampurl, sdate)

	return (unspoketxt, qbd)

