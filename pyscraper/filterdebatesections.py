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
from miscfuncs import WriteXMLHeader

from filterdivision import FilterDivision
from filterdebatespeech import FilterDebateSpeech

fixsubs = 	[
	( "(<H3 align=center>.*?)(House of Commons</H3>)\s*(<H2.*?</H2>)\s*(The House.*?clock)", \
		'\\1</H3>\n<H3 align=center>\\2\n\\3\n<H3 align=center>\\4</H3>', 1, '2003-10-27'),
	( "(<H4><center>FOURTEENTH VOLUME OF SESSION 2002&#150;2003)<P>(House of Commons</center></H4>)", \
		'\\1</center></H4>\n<H4><center>\\2', 1, '2003-06-16'),
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
		stithead += ' title="%s"' % (qb.sstampurl.title)

	stime = re.match('<stamp( time=".*?")/>', qb.sstampurl.timestamp).group(1)
	sstamp = 'colnum="%s"%s' % (colnum, stime)

	spurl = qb.sstampurl.GetUrl()

	speaker = ''

	# OK, having DIVISION here is a bit of a hack - the qb.speaker variable could
	# be renamed to qb.attributes, for this new general purpose attribute store
	# (it contains divnumber= and divdate= for divisions)
	if tagname == 'speech' or tagname == 'DIVISION':
		speaker = qb.speaker

	# get the stamps from the stamp on first speaker in block
	fout.write('\n<%s id="%s" %s %s %s url="%s">\n' % (tagname, sid, speaker, stithead, sstamp, spurl)) 

	# put out the paragraphs in body text 
	for lb in body:
		fout.write('\t')
		fout.write(lb)
		fout.write('\n')

	fout.write('</%s>\n' % (tagname))



# Handle normal type heading 
def NormalHeadingPart(sht0, stampurl, sdate): 
	# This is an attempt at major heading detection.
	# This theory is utterly flawed since you can only tell the major headings
	# by context, for example, the title of the adjournment debate, which is a
	# separate entity from whatever came before, and so should not be within that
	# prior major heading.  Also, Oral questions heading is a super-major heading,
	# so doesn't fit into the scheme.

	# detect if this is a major heading and record it in the correct variable

	# set the title for this batch
	stampurl.title = string.strip(FixHTMLEntities(sht0))

	bmajorheading = False

	# detect division headings 
	gdiv = re.match('Division No. (\d+)', sht0)
	divno = -1
	if gdiv:
		divno = string.atoi(gdiv.group(1))
		
	# All upper case headings - these tend to be uniform, so we can check their names
	elif not re.search('[a-z]', sht0):
		bmajorheading = True

	# Other major headings, marked by _head in their anchor tag - doesn't seem
	# worth checking their names.
	elif re.search('_head', stampurl.aname):
		bmajorheading = True


	# write out block for headings
	if bmajorheading:
		stampurl.majorheading = stampurl.title
		stampurl.title = ''
		qb = qspeech('', stampurl.majorheading, stampurl, sdate)
		qb.typ = 'debmajor'
		qb.stext = [ stampurl.majorheading ] 

	else:
		qb = qspeech('', stampurl.title, stampurl, sdate)
		qb.typ = 'debminor'
		qb.stext = [ stampurl.title ] 

	return (divno, qb)	


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
	qbl = [ ]
	for i in range(ih, len(headspeak)):
		# triplet of ( heading, unspokentext, [(speaker, text)] ) 
		sht = headspeak[i]

		# we convert this section into a list of speeches with an empty 
		# speech block at the top.  (If we didn't, we'd miss titles with no speeches).  
		# the stampurl object keeps the title info in it as well.  
		qblock = [ ]

		# the heading (empty speech) object 
		(divno, qb) = NormalHeadingPart(sht[0], stampurl, sdate)
		qblock.append(qb)  

		# the unspoken text after the heading part 

		# division case 
		sht1 = sht[1]
		if divno != -1:
			# find the ending of the division 
			gquesacc = re.search("(Question accordingly)", sht1)
			if gquesacc:
				divtext = sht1[:gquesacc.end(1)]
				sht1 = sht1[gquesacc.start(1):]
			else:
				divtext = sht1
				print "division missing question accordingly" 
				sht1 = ''
			
			

			# Add a division object (will contain votes and motion text)
			qb = qspeech('divdate="%s" divnumber="%s"' % (sdate, divno), divtext, stampurl, sdate) 
			qb.typ = 'debdiv' # this type field seems easiest way  
			qblock.append(qb)


		# non-division unspoken text
		if True:
			# case of unspoken text (between heading and first speaker)
			# which we will frig for now.
			# there is some text
			if (not re.match('(?:<[^>]*>|\s)*$', sht1)):
				qb = qspeech('nospeaker="true"', sht1, stampurl, sdate)
				qb.typ = 'debspeech'
				qblock.append(qb)

			else:
				# there is no text
				# update from stamps if there are any
				stampurl.UpdateStampUrl(sht1)



		# go through each of the speeches in a block and put it into our batch of speeches
		for ss in sht[2]:
			qb = qspeech(ss[0], ss[1], stampurl, sdate)
			qb.typ = 'debspeech'
			qblock.append(qb)

		# put this heading block into the speech block.  
		qbl.append(qblock)


	# we now have headings and series of speeches in qbl.
	# this is where we do some transformation and gluing together of the parts


	# go through all the speeches in all the batches and clear them up (converting text to stext)
	for qblock in qbl:
		for qb in qblock:
			if qb.typ == 'debdiv':
				FilterDivision(qb)
			else:
				FilterDebateSpeech(qb)
		


	# output the list of entities
	WriteXMLHeader(fout);
	fout.write("<publicwhip>\n")

	for qblock in qbl:
		for qb in qblock:
			if qb.typ == 'debmajor':
				fout.write('\n')
				WriteXMLChunk(fout, qb, sdate, 'MAJOR-HEADING', qb.stext)
				fout.write('\n')
			elif qb.typ == 'debminor':
				fout.write('\n')
				WriteXMLChunk(fout, qb, sdate, 'MINOR-HEADING', qb.stext)
				fout.write('\n')
			elif qb.typ == 'debspeech':
				WriteXMLChunk(fout, qb, sdate, 'speech', qb.stext)
			elif qb.typ == 'debdiv':
				fout.write('\n')
				WriteXMLChunk(fout, qb, sdate, 'DIVISION', qb.stext)
				fout.write('\n')
			else:
				raise Exception, 'question block type unknown %s ' % qb.type

	fout.write("</publicwhip>\n")
	


