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

	#The House met at half-past Ten o'clock 0
	ih = StripDebateHeading('the house met at .*(?i)', ih, headspeak)

	#PRAYERS 0
	ih = StripDebateHeading('prayers(?i)', ih, headspeak)


	# find the url, colnum and time stamps that occur before anything else in the unspoken text
	stampurl = StampUrl()
	for j in range(0, ih):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl):
		raise Exception, ' missing stamp url at beginning of file '
	return (ih, stampurl)


def ScanQBatch(shspeak, stampurl, sdate):
	shansblock = [ ]
	qblock = [ ]

	# throw in a batch of speakers
	for shs in shspeak:
		qb = qspeech(shs[0], shs[1], stampurl, sdate)
		qblock.append(qb)

		if qb.typ == 'reply':
			if len(qblock) < 2:
				print ' Reply with no question ' + stampurl.stamp
				print shs[1]
			shansblock.append(qblock)
			qblock = []

		# reset the id if the column changes
		if stampurl.stamp != qb.sstampurl.stamp:
			stampurl.ncid = 0
		else:
			stampurl.ncid = stampurl.ncid + 1

	if qblock:
		# these are common failures of the data
		print "block without answer " + stampurl.title
		shansblock.append(qblock)
	return shansblock




# A series of speeches blocked up into question and answer.
def WritexmlSpeech(fout, qb, sdate):
	gcolnum = re.search('colnum="([^"]*)"', qb.sstampurl.stamp)
	if not gcolnum:
		raise Exception, 'missing column number'
	colnum = gcolnum.group(1)

	# (we could choose answers to be the id code??)
	sid = 'uk.org.publicwhip/debate/%s.%s.%d' % (sdate, colnum, qb.sstampurl.ncid)

	# get the stamps from the stamp on first speaker in block
	fout.write('\n<speech id="%s" %s title="%s" majorheading="%s">\n' % \
				(sid, qb.speaker, FixHTMLEntities(qb.sstampurl.title), qb.sstampurl.majorheading))
	fout.write(qb.sstampurl.stamp)
	fout.write('\n')
	fout.write(qb.sstampurl.timestamp)
	fout.write('\n')
	fout.write(qb.sstampurl.pageurl)
	fout.write('\n')

	# add in some tabbing
	for st in qb.stext:
		fout.write('\t\t')
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

		# update the stamps from the pre-spoken text
		stampurl.UpdateStampUrl(sht[1])

		# deal with divisions separately
		gdiv = re.match('Division No. (\d+)', sht[0])
		if gdiv:
			divno = string.atoi(gdiv.group(1))
			qbl.extend(FilterDivision(divno, sht[1], sht[2]))
			continue

		# detect if this is a major heading and record it
		if sht[0] and (not re.search('[a-z]', sht[0])) and not sht[2]:
			stampurl.majorheading = None
			for knhd in parlPhrases.debatemajorheadings:
				if re.match(knhd, sht[0]):
					stampurl.majorheading = sht[0]
					break
			if not stampurl.majorheading:
				print '"%s"' % sht[0]
				raise Exception, "unrecognized major heading: "
			continue

		# ensure that non-major heading doesn't show up in the list anyway.
		# (this suggest structure not understood)
		for knhd in parlPhrases.debatemajorheadings:
			if re.match(knhd, sht[0]):
				print sht[0]
				print ' speeches found in known major heading '

		# batch up the speeches in one heading
		stampurl.title = sht[0]

		# put a title into this list too
		# qbl.append(stampurl.title)

		# go through each of the speeches in a block and put it into our batch of speeches
		qblock = [ ]
		for shs in sht[2]:
			qb = qspeech(shs[0], shs[1], stampurl, sdate)
			qb.typ = 'debspeech'
			qblock.append(qb)
		qbl.append(qblock)


	# we now have headings and series of speeches in qbl.
	# this is where we do some transformation and gluing together of the parts

	# go through all the speeches in all the batches and clear them up (converting text to stext)
	for qblock in qbl:
		for qb in qblock:
			FilterDebateSpeech(qb)

	# for now we just output it as a flat object
	fout.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
	fout.write("<publicwhip>\n")
	for qblock in qbl:
		for qb in qblock:
			WritexmlSpeech(fout, qb, sdate)

	fout.write("</publicwhip>\n")


