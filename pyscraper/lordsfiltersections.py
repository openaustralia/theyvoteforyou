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
from miscfuncs import WriteXMLHeader

from filterdivision import FilterDivision
from filterdivision import LordsFilterDivision
from filterdebatespeech import FilterDebateSpeech

fixsubs = 	[
				# heading so full of crap I can only discard it completely
				('<FONT SIZE=4><center>\s*THE PARLIAMENTARY DEBATES[\s\S]*<HR WIDTH=50%>', '<H2><center>House of Lords</center></H2>', 1, '2004-01-26'),
				('<FONT SIZE=4><center>\s*THE PARLIAMENTARY DEBATES[\s\S]*<HR WIDTH=50%>', '<H2><center>House of Lords</center></H2>', 1, '2004-01-05'),
				( '<UL><UL><UL>', '<UL>', -1, 'all'),
				( '</UL></UL></UL>', '</UL>', -1, 'all'),
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
	stampurl = StampUrl()

	# set the time from the wording 'house met at' thing.
	for j in range(0, ih):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl):
		raise Exception, ' missing stamp url at beginning of file '
	return (ih, stampurl)


# A series of speeches blocked up into question and answer.
def WriteXMLSpeech(fout, qb, sdate):
       	# add in some tabbing
        body = ''
	for st in qb.stext:
		body += '\t'
		body += st
		body += '\n'

        WriteXMLChunk(fout, qb, sdate, 'speech', body)

# A series of speeches blocked up into question and answer.
def WriteXMLChunk(fout, qb, sdate, tagname, body):
	gcolnum = re.search('colnum="([^"]*)"', qb.sstampurl.stamp)
	if not gcolnum:
		raise Exception, 'missing column number'
	colnum = gcolnum.group(1)

	# (we could choose answers to be the id code??)
	sid = 'uk.org.publicwhip/debate/%s.%s.%d' % (sdate, colnum, qb.sstampurl.ncid)

	# title headings
        stithead = 'majorheading="%s"' % (qb.sstampurl.majorheading)
        if qb.sstampurl.title <> "":
                stithead += ' minorheading="%s"' % (qb.sstampurl.title)

	stime = '9999'  #re.match('<stamp( time=".*?")/>', qb.sstampurl.timestamp).group(1)
	sstamp = 'colnum="%s"%s' % (colnum, stime)

	spurl = re.match('<page (url=".*?")/>', qb.sstampurl.pageurl).group(1)

	speaker = ''
	if tagname == 'speech':
		speaker = 'speaker="%s" ' % qb.speaker

	# get the stamps from the stamp on first speaker in block
	fout.write('\n<%s id="%s" %s %s %s %s>\n' % \
				(tagname, sid, speaker, stithead, sstamp, spurl))
        fout.write(body)

	fout.write('</%s>\n' % (tagname))




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
			print sht[0]

			# gotta learn how to deal with the procedural text too.
			# for now think of this as a division object, maybe.
			# either that, or we'll make the Ayes and Noes as speech statements
			divxml = LordsFilterDivision(divno, sht[1], sdate)
			qb = qspeech('', divxml, stampurl, sdate)
			qb.typ = 'division'
			qblock.append(qb)


		else:


			# detect if this is a major heading and record it in the correct variable
			qb = qspeech('', stampurl.title, stampurl, sdate)
			qb.typ = 'debminor'
			qblock.append(qb)

			# case of unspoken text (between heading and first speaker)
			# which we will frig for now.
			if (not re.match('(?:<[^>]*>|\s)*$', sht[1])):
				qb = qspeech('nospeaker="true"', sht[1], stampurl, sdate)
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
		for qb in qblock:
			if qb.typ != 'division':
				FilterDebateSpeech(qb)



	# output the list of entities
	WriteXMLHeader(fout);
	fout.write("<publicwhip>\n")
	for qblock in qbl:

		if not qblock:
                        raise Exception, "No content in qblock"

		for qb in qblock:
                        if qb.typ == 'debmajor':
                                fout.write('\n')
                                WriteXMLChunk(fout, qb, sdate, 'major-heading', qb.sstampurl.majorheading)
                                fout.write('\n')
                        elif qb.typ == 'debminor':
                                fout.write('\n')
                                WriteXMLChunk(fout, qb, sdate, 'minor-heading', qb.sstampurl.title)
                                fout.write('\n')
                        elif qb.typ == 'division':
                                fout.write('\n')
                                WriteXMLChunk(fout, qb, sdate, 'division', qb.text)
                                fout.write('\n')
                        elif qb.typ == 'debspeech':
                                WriteXMLSpeech(fout, qb, sdate)
                        else:
                                raise Exception, 'question block type unknown %s ' % qb.typ


	fout.write("</publicwhip>\n")


