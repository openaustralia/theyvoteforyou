#! /usr/bin/python2.3
import sys
import re
import os
import string


# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime


from miscfuncs import ApplyFixSubstitutions

from splitheadingsspeakers import SplitHeadingsSpeakers
from splitheadingsspeakers import StampUrl

from clsinglespeech import qspeech
from parlphrases import parlPhrases

from miscfuncs import FixHTMLEntities
from miscfuncs import WriteXMLFile

from filterdivision import FilterDivision
from lordsfilterdivisions import LordsFilterDivision
from lordsfilterdivisions import LordsDivisionParsingPart
from filterdebatespeech import FilterDebateSpeech

# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = 	[
				# heading so full of crap I can only discard it completely
				('<center>\s*(<TABLE[\s\S]*?</TABLE>)\s*</center>', '\\1', 2, '2004-03-04'),
				('colspan=center', 'align=center', 4, '2004-03-04'),

				('<H5>(Second Reading debate resumed.</H5>)', '<H5 align=center>\\1', 1, '2003-12-15'),
				('<hr width=25%>', '', 1, '2004-03-25'),
    			('(<ul><ul>House adjourned.*?.</ul></ul>)', '<ul>\\1</ul>', 1, '2004-03-25'),

				('(\[\*The Tellers for .*?\s*<P>)([\s\S]*?)(Resolved .*? accordingly.)', '\\3 \\2 \\1', 1, '2004-03-23'),
				('(Renfrew of Kaimsthorn,)\s*<br>\s*(L.)', '\\1 \\2', 1, '2004-03-23'),

				('<FONT SIZE=4><center>\s*THE PARLIAMENTARY DEBATES[\s\S]*<HR WIDTH=50%>', '<H2><center>House of Lords</center></H2>', 1, '2004-03-15'),
				('<FONT SIZE=4><center>\s*THE PARLIAMENTARY DEBATES[\s\S]*<HR WIDTH=50%>', '<H2><center>House of Lords</center></H2>', 1, '2004-02-23'),
				('<FONT SIZE=4><center>\s*THE PARLIAMENTARY DEBATES[\s\S]*<HR WIDTH=50%>', '<H2><center>House of Lords</center></H2>', 1, '2004-01-26'),
				('<FONT SIZE=4><center>\s*THE PARLIAMENTARY DEBATES[\s\S]*<HR WIDTH=50%>', '<H2><center>House of Lords</center></H2>', 1, '2004-01-05'),

# this is the queens speech, and this sub doesn't fix it.
				('<FONT SIZE=6><center>\s*THE PARLIAMENTARY DEBATES[\s\S]*<HR WIDTH=50%>', '<H2><center>House of Lords</center></H2>', 1, '2003-11-26'),
				( '<UL><UL><UL>(?i)', '<UL>', -1, 'all'),
				( '</UL></UL></UL>(?i)', '</UL>', -1, 'all'),
		]


def StripDebateHeading(hmatch, ih, headspeak, bopt=False):
	if (not re.match(hmatch, headspeak[ih][0])) or headspeak[ih][2]:
		if bopt:
			return ih
		print headspeak[ih]
		raise Exception, 'non-conforming "%s" heading ' % hmatch
	return ih + 1

def StripLordsDebateHeadings(headspeak, sdate):
	# check and strip the first two headings in as much as they are there
	ih = 0
	ih = StripDebateHeading('Initial', ih, headspeak)


	# House of Lords
	ih = StripDebateHeading('house of lords(?i)', ih, headspeak)

	# Thursday, 18th December 2003.
	if not re.match('the house met at .*(?i)', headspeak[ih][0]):
		if ((sdate != mx.DateTime.DateTimeFrom(headspeak[ih][0]).date)) or headspeak[ih][2]:
			print headspeak[ih]
			raise Exception, 'non-conforming date heading '
		ih = ih + 1


	# The House met at eleven of the clock (Prayers having been read earlier at the Judicial Sitting by the Lord Bishop of St Albans): The CHAIRMAN OF COMMITTEES on the Woolsack.
	gstarttime = re.match('the house met at (.*)(?i)', headspeak[ih][0])
	if (not gstarttime) or headspeak[ih][2]:
		print headspeak[ih]
		raise Exception, 'non-conforming "%s" heading ' % hmatch
	ih = ih + 1


	# Prayers&#151;Read by the Lord Bishop of Southwell.
	ih = StripDebateHeading('prayers(?i)', ih, headspeak, True)



	# find the url, colnum and time stamps that occur before anything else in the unspoken text
	stampurl = StampUrl(sdate)

	# set the time from the wording 'house met at' thing.
	for j in range(0, ih):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl):
		raise Exception, ' missing stamp url at beginning of file '
	return (ih, stampurl)



# Handle normal type heading
def LordsHeadingPart(headingtxt, stampurl):
	bmajorheading = False

	headingtxtfx = FixHTMLEntities(headingtxt)
	qb = qspeech('nospeaker="true"', headingtxtfx, stampurl)
	if bmajorheading:
		qb.typ = 'major-heading'
	else:
		qb.typ = 'minor-heading'

	# headings become one unmarked paragraph of text
	qb.stext = [ headingtxtfx ]
	return qb


################
# main function
################
def LordsFilterSections(fout, text, sdate):
	# make the corrections at this level which enables the headings to be resolved.
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# split into list of triples of (heading, pre-first speech text, [ (speaker, text) ])
	headspeak = SplitHeadingsSpeakers(text)


	# break down into lists of headings and lists of speeches
	(ih, stampurl) = StripLordsDebateHeadings(headspeak, sdate)

	# loop through each detected heading and the detected partitioning of speeches which follow.
	# this is a flat output of qspeeches, some encoding headings, and some divisions.
	# see the typ variable for the type.
	flatb = [ ]

	for sht in headspeak[ih:]:
		# triplet of ( heading, unspokentext, [(speaker, text)] )
		headingtxt = string.strip(sht[0])
		unspoketxt = sht[1]
		speechestxt = sht[2]

		# the heading detection, as a division or a heading speech object
		# detect division headings
		gdiv = re.match('Division No. (\d+)', headingtxt)

		# heading type
		if not gdiv:
			qbh = LordsHeadingPart(headingtxt, stampurl)
			flatb.append(qbh)

		# division type
		else:
			(unspoketxt, qbd) = LordsDivisionParsingPart(string.atoi(gdiv.group(1)), unspoketxt, stampurl, sdate)

			# grab some division text off the back end of the previous speech
			# and wrap into a new no-speaker speech
			#qbdp = GrabDivisionProced(flatb[-1], qbd)
			#if qbdp:
			#	flatb.append(qbdp)
			flatb.append(qbd)

		# continue and output unaccounted for unspoken text occuring after a
		# division, or after a heading
		if (not re.match('(?:<[^>]*>|\s)*$', unspoketxt)):
			qb = qspeech('nospeaker="true"', unspoketxt, stampurl)
			qb.typ = 'speech'
			FilterDebateSpeech(qb)
			flatb.append(qb)

		# there is no text; update from stamps if there are any
		else:
			stampurl.UpdateStampUrl(unspoketxt)

		# go through each of the speeches in a block and put it into our batch of speeches
		for ss in speechestxt:
			qb = qspeech(ss[0], ss[1], stampurl)
			qb.typ = 'speech'
			FilterDebateSpeech(qb)
			flatb.append(qb)


	# we now have everything flattened out in a series of speeches

	# output the list of entities
	WriteXMLFile("lords", fout, flatb, sdate)

