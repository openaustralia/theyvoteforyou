#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import re
import os
import string

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

from miscfuncs import ApplyFixSubstitutions
from contextexception import ContextException

from splitheadingsspeakers import SplitHeadingsSpeakers
from splitheadingsspeakers import StampUrl

from clsinglespeech import qspeech
from parlphrases import parlPhrases

from miscfuncs import FixHTMLEntities
from xmlfilewrite import WriteXMLFile

from filterwmsspeech import FilterWMSSpeech

# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = 	[
]

# parse through the usual intro headings at the beginning of the file.
def StripWMSHeadings(headspeak, sdate):
	# check and strip the first two headings in as much as they are there
	i = 0
	if (headspeak[i][0] != 'Initial') or headspeak[i][2]:
		print headspeak[i]
		raise ContextException, 'non-conforming Initial heading '
	i += 1

	if (not re.match('written ministerial ?statements?(?i)', headspeak[i][0])) or headspeak[i][2]:
		print headspeak[i]
		raise ContextException, 'non-conforming Initial heading '
	elif (not re.search('<date>', headspeak[i][0])):
		i += 1

	if (sdate != mx.DateTime.DateTimeFrom(string.replace(headspeak[i][0], "&nbsp;", " ")).date) or headspeak[i][2]:
#		if (not parlPhrases.wransmajorheadings.has_key(headspeak[i][0])) or headspeak[i][2]:
		print headspeak[i]
		raise ContextException, 'non-conforming second heading '
	else:
		i += 1

	# find the url and colnum stamps that occur before anything else
	stampurl = StampUrl(sdate)
	for j in range(0, i):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl) or (not stampurl.aname):
		raise ContextException('missing stamp url at beginning of file')
	return (i, stampurl)

def NormalHeadingPart(headingtxt, stampurl):
	bmajorheading = False

	if not re.search('[a-z]', headingtxt):
		bmajorheading = True
	elif re.search('_dpthd', stampurl.aname):
		bmajorheading = True

	headingtxtfx = FixHTMLEntities(headingtxt)
	qb = qspeech('nospeaker="true"', headingtxtfx, stampurl)
	if bmajorheading:
		qb.typ = 'major-heading'
	else:
		qb.typ = 'minor-heading'

	# headings become one unmarked paragraph of text
	qb.stext = [ headingtxtfx ]
	return qb

def FilterWMSSections(text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)
	# split into list of triples of (heading, pre-first speech text, [ (speaker, text) ])
	headspeak = SplitHeadingsSpeakers(text)

	(ih, stampurl) = StripWMSHeadings(headspeak, sdate)

	flatb = [ ]
	for sht in headspeak[ih:]:
		try:
			headingtxt = string.strip(sht[0])
			unspoketxt = sht[1]
			speechestxt = sht[2]

			if (not re.match('(?:<[^>]*>|\s)*$', unspoketxt)):
				raise ContextException("unspoken text under heading in WMS", stamp=stampurl, fragment=unspoketxt)
#				qb = qspeech('nospeaker="true"', unspoketxt, stampurl)
#				qb.typ = 'speech'
#				FilterDebateSpeech(qb)
#				flatb.append(qb)
#			else:
#			stampurl.UpdateStampUrl(unspoketxt)

# DEBATE
			qbh = NormalHeadingPart(headingtxt, stampurl)
			flatb.append(qbh)

                        stampurl.UpdateStampUrl(unspoketxt)
# WRANS
#			# detect if this is a major heading
#			if not re.search('[a-z]', headingtxt) and not speechestxt:
#				if not parlPhrases.wransmajorheadings.has_key(headingtxt):
#					raise ContextException("unrecognized major heading, please add to parlPhrases.wransmajorheadings", fragment = headingtxt, stamp = stampurl)
#				majheadingtxtfx = parlPhrases.wransmajorheadings[headingtxt] # no need to fix since text is from a map.
#				qbH = qspeech('nospeaker="true"', majheadingtxtfx, stampurl)
#				qbH.typ = 'major-heading'
#				qbH.stext = [ majheadingtxtfx ]
#				flatb.append(qbH)
#				continue
#			# non-major heading; to a question batch
#			if parlPhrases.wransmajorheadings.has_key(headingtxt):
#				raise Exception, ' speeches found in major heading %s' % headingtxt
#			headingtxtfx = FixHTMLEntities(headingtxt)
#			headingmark = 'nospeaker="True"'
#			bNextStartofQ = True
# DEBATES:
			for ss in speechestxt:
				qb = qspeech(ss[0], ss[1], stampurl)
				qb.typ = 'speech'
				FilterWMSSpeech(qb)
				flatb.append(qb)

		except ContextException, e:
			raise
		except Exception, e:
			# add extra stamp info to the exception
			raise ContextException(str(e), stamp=stampurl)

	return flatb

