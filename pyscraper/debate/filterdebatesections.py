#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

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
from filterdebatespeech import FilterDebateSpeech

from debdivisionsections import PreviewDivisionTextGuess
from debdivisionsections import DivisionParsingPart
from debdivisionsections import GrabDivisionProced

# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = 	[
        ( 'Taylor, Andrew', 'Turner, Andrew', 1, '2003-02-26'),
        ( '(Brown, Russell),', '\\1', 1, '2003-09-10'),
        ( 'Baird Vera', 'Baird, Vera', 1, '2003-09-10'),
        ( 'itemMercer', 'Mercer', 1, '2003-10-15'),
        ( 'Livingston\)', '(Livingston)', 1, '2003-10-27'),
        ( '<BR>\n, David', '<BR>\nBorrow, David', 1, '2003-11-18'),
        ( '(Charlotte Atkins an)<BR>\s*d', '\\1d<BR>', 1, '2004-03-15'),
	( "(<H3 align=center>.*?)(House of Commons</H3>)\s*(<H2.*?</H2>)\s*(The House.*?clock)", \
		'\\1</H3>\n<H3 align=center>\\2\n\\3\n<H3 align=center>\\4</H3>', 1, '2003-10-27'),
        ( '(<H4><center>THIRD VOLUME OF SESSION 2003&#150;2004)(House of Commons</center></H4>)', \
                '\\1</center></H4>\n<H4><center>\\2', 1, '2004-01-26'),
	( "(<H3 align=center>TENTH VOLUME OF SESSION 2002&#150;2003)(House of Commons</H3>)", \
		'\\1</H3>\n<H3 align=center>\\2', 1, '2003-04-07'),
	( "(<H3 align=center>NINTH VOLUME OF SESSION 2002&#150;2003)ana(House of Commons</H3>)", \
		'\\1</H3>\n<H3 align=center>\\2', 1, '2003-03-24'),
	( '\{\*\*pq num="76041"\*\*\}', '', 1, '2002-10-30'),
        ( '(2003)(House of Commons)', '\\1</center></H4>\n<H4><center>\\2', 1, '2003-06-03'),
        ( '(2003)(House of Commons)', '\\1</center></H4>\n<H4><center>\\2', 1, '2003-05-12'),
        ( '(2003)(House of Commons)', '\\1</center></H4>\n<H4><center>\\2', 1, '2003-04-28'),

        ( '(<FONT SIZE=-1>2 Dec. 2003)', '\\1\n</FONT></TD></TR>\n</TABLE>', 1, '2004-02-05'),

	( '<i> </i>', '', 1, '2003-01-27'),

	( '<UL><UL>Adjourned', '</UL><UL><UL><UL>Adjourned', 1, '2003-05-22'), # putting a consistent error back in
	( '<UL><UL>End', '</UL><UL><UL><UL>End', 1, '2002-11-07'), # as above
        ( '<UL><UL>', '<UL><UL><UL>', 1, '2003-06-25'),

	( '<UL><UL><UL>Adjourned', '<UL>Adjourned', 1, '2004-03-05'),
	( 'o\'clock\.\s*</UL></UL></UL>', 'o\'clock.</UL>', 1, '2004-03-05'),

	( '<UL><UL><UL>', '<UL>', 1, 'all'),
	( '</UL></UL></UL>', '</UL>', 1, 'all'),
		]



# parse through the usual intro headings at the beginning of the file.
#[Mr. Speaker in the Chair] 0
def StripDebateHeading(hmatch, ih, headspeak, bopt=False):
	if (not re.match(hmatch, headspeak[ih][0])) or headspeak[ih][2]:
		if bopt:
			return ih
		print headspeak[ih]
		raise Exception, 'non-conforming "%s" heading ' % hmatch
	return ih + 1

def StripDebateHeadings(headspeak, sdate):
	# check and strip the first two headings in as much as they are there
	ih = 0
	ih = StripDebateHeading('Initial', ih, headspeak)

	# volume type heading
	if headspeak[ih][0] == 'THE PARLIAMENTARY DEBATES':
		ih = StripDebateHeading('THE PARLIAMENTARY DEBATES', ih, headspeak)
		ih = StripDebateHeading('OFFICIAL REPORT', ih, headspeak)
		ih = StripDebateHeading('IN THE .*? SESSION OF THE .*? PARLIAMENT OF THE', ih, headspeak)
		ih = StripDebateHeading('UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND', ih, headspeak, True)
		ih = StripDebateHeading('\[WHICH OPENED .*?\]', ih, headspeak, True)
		ih = StripDebateHeading('.*? YEAR OF THE REIGN OF.*?', ih, headspeak)
		ih = StripDebateHeading('HER MAJESTY QUEEN ELIZABETH II', ih, headspeak, True)
		ih = StripDebateHeading('SI.*? SERIES', ih, headspeak)
		ih = StripDebateHeading('VOLUME \d+', ih, headspeak)
		ih = StripDebateHeading('.*? VOLUME OF SESSION .*?', ih, headspeak)


	#House of Commons
	ih = StripDebateHeading('house of commons(?i)', ih, headspeak)

	# Tuesday 9 December 2003
	if not re.match('the house met at .*(?i)', headspeak[ih][0]):
		if ((sdate != mx.DateTime.DateTimeFrom(headspeak[ih][0]).date)) or headspeak[ih][2]:
			print headspeak[ih]
			raise Exception, 'non-conforming date heading '
		ih = ih + 1


	#The House met at half-past Ten o'clock
	gstarttime = re.match('the house met at (.*)(?i)', headspeak[ih][0])
	if (not gstarttime) or headspeak[ih][2]:
		print headspeak[ih]
		raise Exception, 'non-conforming "%s" heading ' % hmatch
	ih = ih + 1


	#PRAYERS
	ih = StripDebateHeading('prayers(?i)', ih, headspeak)


	# in the chair
	ih = StripDebateHeading('\[.*? in the chair\](?i)', ih, headspeak, True)


	# find the url, colnum and time stamps that occur before anything else in the unspoken text
	stampurl = StampUrl(sdate)

	# set the time from the wording 'house met at' thing.
	time = gstarttime.group(1)
	if re.match("^half-past Nine(?i)", time):
		newtime = '09:30:00'
	elif re.match("^half-past Ten(?i)", time):
		newtime = '10:30:00'
	elif re.match("^twenty-five minutes pastEleven(?i)", time):
		newtime = '11:25:00'
	elif re.match("^half-past Eleven(?i)", time):
		newtime = '11:30:00'
	elif re.match("^half-past Two(?i)", time):
		newtime = '14:30:00'
	else:
		newtime = "unknown " + time
		raise Exception, "Start time not known: " + time
	stampurl.timestamp = '<stamp time="%s"/>' % newtime

	for j in range(0, ih):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl):
		raise Exception, ' missing stamp url at beginning of file '
	return (ih, stampurl)




# Handle normal type heading
def NormalHeadingPart(headingtxt, stampurl):
	# This is an attempt at major heading detection.
	# This theory is utterly flawed since you can only tell the major headings
	# by context, for example, the title of the adjournment debate, which is a
	# separate entity from whatever came before, and so should not be within that
	# prior major heading.  Also, Oral questions heading is a super-major heading,
	# so doesn't fit into the scheme.

	# detect if this is a major heading and record it in the correct variable

	bmajorheading = False
        boralheading = False

	# Oral question are really a major heading
	if headingtxt == 'Oral Answers to Questions':
		boralheading = True
	# Check if there are any other spellings of "Oral Answers to Questions" with a loose match
	elif re.search('oral(?i)', headingtxt) and re.search('ques(?i)', headingtxt):
		raise Exception, 'Oral question match not precise enough: %s' % headingtxt

	# All upper case headings
	elif not re.search('[a-z]', headingtxt):
		bmajorheading = True

	# Other major headings, marked by _head in their anchor tag
	elif re.search('_head', stampurl.aname):
		bmajorheading = True

	# we're not writing a block for division headings
	# write out block for headings
	headingtxtfx = FixHTMLEntities(headingtxt)
	qb = qspeech('nospeaker="true"', headingtxtfx, stampurl)
        if boralheading:
                qb.typ = 'oral-heading'
	elif bmajorheading:
		qb.typ = 'major-heading'
	else:
		qb.typ = 'minor-heading'

	# headings become one unmarked paragraph of text
	qb.stext = [ headingtxtfx ]
	return qb



################
# main function
################
def FilterDebateSections(fout, text, sdate):
	# make the corrections at this level which enables the headings to be resolved.
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# split into list of triples of (heading, pre-first speech text, [ (speaker, text) ])
	headspeak = SplitHeadingsSpeakers(text)

	# break down into lists of headings and lists of speeches
	(ih, stampurl) = StripDebateHeadings(headspeak, sdate)

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
			qbh = NormalHeadingPart(headingtxt, stampurl)

			# ram together minor headings into previous ones which have no speeches
			if qbh.typ == 'minor-heading' and len(flatb) > 0 and flatb[-1].typ == 'minor-heading':
				flatb[-1].stext.append(" &mdash; ")
				flatb[-1].stext.extend(qbh.stext)

			# ram together major headings into previous ones which have no speeches
			elif qbh.typ == 'major-heading' and len(flatb) > 0 and flatb[-1].typ == 'major-heading':
				flatb[-1].stext.append(" &mdash; ")
				flatb[-1].stext.extend(qbh.stext)


			# otherwise put out this heading
			else:
				flatb.append(qbh)

		# division case
		else:
			(unspoketxt, qbd) = DivisionParsingPart(string.atoi(gdiv.group(1)), unspoketxt, stampurl, sdate)

			# grab some division text off the back end of the previous speech
			# and wrap into a new no-speaker speech
			qbdp = GrabDivisionProced(flatb[-1], qbd)
			if qbdp:
				flatb.append(qbdp)
			flatb.append(qbd)

			# write out our file with the report of all divisions
			PreviewDivisionTextGuess(flatb)

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
	WriteXMLFile("debate", fout, flatb, sdate)



