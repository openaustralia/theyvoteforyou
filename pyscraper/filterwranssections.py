#! /usr/bin/python2.3
import sys
import re
import os
import string


# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime


from miscfuncs import ApplyFixSubstitutions
from splitheadingsspeakers import SplitHeadingsSpeakers
from clsinglespeech import qspeech
from parlphrases import parlPhrases

from miscfuncs import FixHTMLEntities


fixsubs = 	[
	( '<h2><center>written answers to</center></h2>\s*questions(?i)', \
	  	'<h2><center>Written Answers to Questions</center></h2>', -1, 'all'),
	( '<h\d align=center>written answers[\s\S]{10,150}?\[continued from column \d+?W\](?:</h\d>)?(?i)', '', -1, 'all'),
	( '<h\d><center>written answers[\s\S]{10,150}?\[continued from column \d+?W\](?i)', '', -1, 'all'),


	( '<H2 align=center> </H2>', '', 1, '2003-09-15'),
	( '<H1 align=center></H1>\s*<H2 align=center>Monday 15 September 2003</H2>', '', 1, '2003-09-15'),
	( '<H1 align=center></H1>', '', 1, '2003-10-06'),

	( '<BR>\s*</FONT>\s*<H4><center>Energy Policy</center></H4>', '', 1, '2003-04-29'),

	( 'To as the Deputy Prime Minister', 'To ask the Deputy Prime Minister', 1, '2003-10-06'),
	( '\n What ', '\n To ask the Secretary of State for Northern Ireland what ', 4, '2003-09-10'),
	( '\n If he will ', '\n To ask the Secretary of State for Northern Ireland if he will ', 2, '2003-09-10'),

 	( '\n If he will ', '\n To ask the Secretary of State for Scotland if he will ', 1, '2003-09-09'),
 	( '\n How many ', '\n To ask the Secretary of State for Scotland how many ', 1, '2003-09-09'),
 	( '\n What recent ', '\n To ask the Secretary of State for Scotland what recent ', 2, '2003-09-09'),
 	( '\n When he ', '\n To ask the Secretary of State for Scotland when he ', 2, '2003-09-09'),

 	( '\n If he ', '\n To ask the Secretary of State for Work and Pensions if he ', 2, '2003-07-07'),
 	( '\n What ', '\n To ask the Secretary of State for Work and Pensions what ', 2, '2003-07-07'),
 	( '\n How many ', '\n To ask the Secretary of State for Work and Pensions how many ', 1, '2003-07-07'),
 	( '\n What ', '\n To ask the Secretary of State for Culture, Media and Sport what ', 1, '2003-06-30'),


 	( '\n To\s*ask ', '\n To ask ', 10, '2003-07-07'), # linefeed example I can't piece apart
 	( 'Worcestershire</FONT></TD>', 'Worcestershire', 1, '2003-07-15'),

	( '\{\*\*con\*\*\}\{\*\*/con\*\*\}', '', 3, '2002-07-24'),
	( '\n\s*\(1\)\s*To ask', '\n To ask (1) ', 3, '2002-07-24'),

	( '<i>The following questions were answered on 10 June</i>', '', 1, '2003-06-10'),

	( 'Vol. No. 412,', '', 1, '2003-11-10'),
	( '</TH></TH>', '</TH>', 1, '2003-11-17'),
	( '<TR valign=top><TD><FONT SIZE=-1>Quarter to', '<TR valign=top><TH><FONT SIZE=-1>Quarter to', 1, '2003-05-06'),

	( 'Asked the Minister', 'To ask the Minister', 1, '2003-05-19'),
	( 'Asked the Minister', 'To ask the Minister', 1, '2003-05-21'),

	( '2003&#150;11&#150;21', '2003', 1, '2003-11-20'),
	( '27Ooctober', '27 October', 1, '2003-10-27'), 
		]


# these types of stamps must be available in every question and batch.
# <stamp coldate="2003-11-17" colnum="518" type="W"/>
# <page url="http://www.publications.parliament.uk/pa/cm200102/cmhansrd/vo020522/text/20522w01.htm">

class StampUrl:
	def __init__(self):
		self.stamp = ''
		self.pageurl = ''
		self.majorheading = 'BLANK MAJOR HEADING'
		self.ncid = 0

	def UpdateStampUrl(self, text):
		for st in re.findall('(<stamp [^>]*?/>)', text):
			self.stamp = st
		for stp in re.findall('<(page url[^>]*?)/?>', text):
			self.pageurl = '<%s/>' % stp  # puts missing slash back in.


# parse through the usual intro headings at the beginning of the file.
def StripWransHeadings(headspeak, sdate):
	# check and strip the first two headings in as much as they are there
	i = 0
	if (headspeak[i][0] != 'Initial') or headspeak[i][2]:
		print headspeak[0]
		raise Exception, 'non-conforming Initial heading '
	i = i + 1

	if (not re.match('written answers to questions(?i)', headspeak[i][0])) or headspeak[i][2]:
		if not re.match('The following answers were received.*', headspeak[i][0]):
			print headspeak[i]
			raise Exception, 'non-conforming Initial heading '
	else:
		i = i + 1

	if (not re.match('The following answers were received.*', headspeak[i][0]) and \
			(sdate != mx.DateTime.DateTimeFrom(headspeak[i][0]).date)) or headspeak[i][2]:
		if (not parlPhrases.majorheadings.has_key(headspeak[i][0])) or headspeak[i][2]:
			print headspeak[i]
			raise Exception, 'non-conforming second heading '
	else:
		i = i + 1

	# find the url and colnum stamps that occur before anything else
	stampurl = StampUrl()
	for j in range(0, i):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl):
		raise Exception, ' missing stamp url at beginning of file '
	return (i, stampurl)


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
def WritexmlSpeechBlock(fout, qblock, sdate):
	# all the titles are in each speech, so lift from first speech
	qb0s = qblock[0].sstampurl

	colnumg = re.findall('colnum="([^"]*)"', qb0s.stamp)
	if not colnumg:
		raise Exception, 'missing column number'
	colnum = colnumg[0]

	# (we could choose answers to be the id code??)
	sid = 'uk.org.publicwhip/wrans/%s.%s.%d' % (sdate, colnum, qb0s.ncid)

	# get the stamps from the stamp on first speaker in block
	fout.write('\n<wrans id="%s" title="%s" majorheading="%s">\n' % \
				(sid, FixHTMLEntities(qb0s.title), qb0s.majorheading))
	fout.write(qb0s.stamp)
	fout.write('\n')
	fout.write(qb0s.pageurl)
	fout.write('\n')

	# output the speeches themselves (type single speech)
	for qs in qblock:
		fout.write('\t<speech %s type="%s">\n' % (qs.speaker, qs.typ))

		# add in some tabbing
		for st in qs.stext:
			fout.write('\t\t')
			fout.write(st)
			fout.write('\n')

		fout.write('\t</speech>\n')

	fout.write('</wrans>\n')


################
# main function
################
def FilterWransSections(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)
	headspeak = SplitHeadingsSpeakers(text)

	# break down into lists of headings and lists of speeches
	(ih, stampurl) = StripWransHeadings(headspeak, sdate)


	# full list of question batches
	# We create a list of lists of speeches
	qbl = []

	for i in range(ih, len(headspeak)):
		sht = headspeak[i]

		# update the stamps from the pre-spoken text
		stampurl.UpdateStampUrl(sht[1])

		# detect if this is a major heading
		if not re.search('[a-z]', sht[0]) and not sht[2]:
			if not parlPhrases.majorheadings.has_key(sht[0]):
				print '"%s":"%s",' % (sht[0], sht[0])
				raise Exception, "unrecognized major heading: "
			else:
				# correct spellings and copy over
				stampurl.majorheading = parlPhrases.majorheadings[sht[0]]

		# non-major heading; to a question batch
		else:
			if parlPhrases.majorheadings.has_key(sht[0]):
				print sht[0]
				raise Exception, ' speeches found in major heading '

			stampurl.title = sht[0]
			qbl.extend(ScanQBatch(sht[2], stampurl, sdate))


	# go through all the speeches in all the batches and clear them up (converting text to stext)
	for qb in qbl:
		qnums = []	# used to account for spurious qnums seen in answers
		for qs in qb:
			qs.FixSpeech(qnums)


	#
	# we have built up the list of question blocks, now write it out
	#
	fout.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
	fout.write("<publicwhip>\n")
	for qb in qbl:
		WritexmlSpeechBlock(fout, qb, sdate)

	fout.write("</publicwhip>\n")


