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

from filterdivision import FilterDivision
from filterdebatespeech import FilterDebateSpeech

fixsubs = 	[
	( "(<H3 align=center>.*?)(House of Commons</H3>)\s*(<H2.*?</H2>)\s*(The House.*?clock)", \
		'\\1</H3>\n<H3 align=center>\\2\n\\3\n<H3 align=center>\\4</H3>', 1, '2003-10-27'),
	( "(<H4><center>FOURTEENTH VOLUME OF SESSION 2002&#150;2003)<P>(House of Commons</center></H4>)", \
		'\\1</center></H4>\n<H4><center>\\2', 1, '2003-06-16'),
	( "<P>\s*(The House met at half-past Two o'clock)", '<H4><center>\\1</center></H4>', 1, '2003-04-28'),
	( "(<H3 align=center>TENTH VOLUME OF SESSION 2002&#150;2003)(House of Commons</H3>)", \
		'\\1</H3>\n<H3 align=center>\\2', 1, '2003-04-07'),
	( "(<H3 align=center>NINTH VOLUME OF SESSION 2002&#150;2003)ana(House of Commons</H3>)", \
		'\\1</H3>\n<H3 align=center>\\2', 1, '2003-03-24'),
	( '\{\*\*pq num="76041"\*\*\}', '', 1, '2002-10-30'),

	( '<i> </i>', '', 1, '2003-01-27'),

	( '<UL><UL>Adjourned', '</UL><UL><UL><UL>Adjourned', 1, '2003-05-22'), # putting a consistent error back in
	( '<UL><UL>End', '</UL><UL><UL><UL>End', 1, '2002-11-07'), # as above

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
	stampurl = StampUrl()

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


# A series of speeches blocked up into question and answer.
def WritexmlSpeech(fout, qb, sdate):
	gcolnum = re.search('colnum="([^"]*)"', qb.sstampurl.stamp)
	if not gcolnum:
		raise Exception, 'missing column number'
	colnum = gcolnum.group(1)

	# (we could choose answers to be the id code??)
	sid = 'uk.org.publicwhip/debate/%s.%s.%d' % (sdate, colnum, qb.sstampurl.ncid)

	# title headings
	stithead = 'title="%s" majorheading="%s"' % (qb.sstampurl.title, qb.sstampurl.majorheading)

	stime = re.match('<stamp( time=".*?")/>', qb.sstampurl.timestamp).group(1)
	sstamp = 'colnum="%s"%s' % (colnum, stime)

	spurl = re.match('<page (url=".*?")/>', qb.sstampurl.pageurl).group(1)

	# get the stamps from the stamp on first speaker in block
	fout.write('\n<speech id="%s" %s %s %s %s>\n' % \
				(sid, qb.speaker, stithead, sstamp, spurl))
	# add in some tabbing
	for st in qb.stext:
		fout.write('\t')
		fout.write(st)
		fout.write('\n')
	fout.write('</speech>\n')


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


	# full list of question batches
	# We create a list of lists of speeches
	qbl = [ ]

	for i in range(ih, len(headspeak)):
		sht = headspeak[i]

		# set the title for this batch
		stampurl.title = FixHTMLEntities(sht[0])

		qblock = [ ]


		# deal with divisions separately
		gdiv = re.match('Division No. (\d+)', sht[0])
		if gdiv:
			divno = string.atoi(gdiv.group(1))

			# gotta learn how to deal with the procedural text too.
			# for now think of this as a division object, maybe.
			# either that, or we'll make the Ayes and Noes as speech statements
			qbl.extend(FilterDivision(divno, sht[1], sdate))

			if sht[2]:
				print ' speeches found in division ' + sht[0]

		else:

		# This is an attempt at major heading detection.
		# This theory is utterly flawed since you can only tell the major headings
		# by context, for example, the title of the adjournment debate, which is a
		# separate entity from whatever came before, and so should not be within that
		# prior major heading.  Also, Oral questions heading is a super-major heading,
		# so doesn't fit into the scheme.

			# detect if this is a major heading and record it in the correct variable
			bmajorheading = sht[0] and (not re.search('[a-z]', sht[0])) and not sht[2]
			if bmajorheading:
				stampurl.majorheading = None
				for knhd in parlPhrases.debatemajorheadings:
					if re.match(knhd, sht[0]):
						stampurl.majorheading = stampurl.title
						break
				if not stampurl.majorheading:
					print '"%s"' % sht[0]
					raise Exception, "unrecognized major heading: "
				stampurl.title = ''

			# case of unspoken text (between heading and first speaker)
			# which we will frig for now.
			# force major headings to have at least one thing here.
			if (not re.match('(?:<[^>]*>|\s)*$', sht[1])) or bmajorheading or (not sht[2]):
				qb = qspeech('name="NOBODY-SPOKE-THIS"', sht[1], stampurl, sdate)
				qb.typ = 'debspeech'
				qblock.append(qb)

			# update the stamps from any of the pre-spoken text
			else:
				stampurl.UpdateStampUrl(sht[1])


		# go through each of the speeches in a block and put it into our batch of speeches
		for ss in sht[2]:
			qb = qspeech(ss[0], ss[1], stampurl, sdate)
			qb.typ = 'debspeech'
			qblock.append(qb)

		qbl.append(qblock)


	# we now have headings and series of speeches in qbl.
	# this is where we do some transformation and gluing together of the parts


	# go through all the speeches in all the batches and clear them up (converting text to stext)
	for qblock in qbl:
		if qblock:	# avoiding division types here
			for qb in qblock:
				FilterDebateSpeech(qb)



	# output the list of entities
	fout.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
	fout.write("<publicwhip>\n")
	for qblock in qbl:

		if not qblock:
			fout.write('\n\n<DIVISION/>\n\n')
			continue

		# major heading signal
		if not qblock[0].sstampurl.title:
			fout.write('\n\n<MAJOR-HEADING>%s</MAJOR-HEADING>\n\n' % qblock[0].sstampurl.majorheading)
			if not qblock[0].stext:
				continue

		# go through the components of this block
		if qblock[0].sstampurl.title:
			fout.write('\n\n<MINOR-HEADING>%s</MINOR-HEADING>\n\n' % qblock[0].sstampurl.title)
		for qb in qblock:
			WritexmlSpeech(fout, qb, sdate)


	fout.write("</publicwhip>\n")


