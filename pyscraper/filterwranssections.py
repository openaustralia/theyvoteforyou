#! /usr/bin/python2.3

import sys
import re
import os
import string
import cStringIO

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

from filterwranssinglespeech import FixReply
from filterwranssinglespeech import FixQuestion

from miscfuncs import ApplyFixSubstitutions
from splitheadingsspeakers import SplitHeadingsSpeakers

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
		if (not majorheadings.has_key(headspeak[i][0])) or headspeak[i][2]:
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


class qspeech:
	# static value used to carry qnums found in questions and compare any that show up
	# spuriously in answers so we can delete them without printing an error.
	questionqnums = []

	# function to shuffle column stamps out of the way to the front, so we can glue paragraphs together
	def StampToFront(self, stampurl):
		# remove the stamps from the text, checking for cases where we can glue back together.
		sp = re.split('(<stamp [^>]*>|<page url[^>]*>)', self.text)
		for i in range(len(sp)):
			if re.match('<stamp [^>]*>', sp[i]):
				stampurl.stamp = sp[i]
				sp[i] = ''

				# string ends with a lower case character, and next begins with a lower case char
				if (i > 0) and (i < len(sp) - 1):
					esp = re.findall('^([\s\S]*?[a-z])(?:<p>|\s)*$', sp[i-1])
					if len(esp) != 0:
						bsp = re.findall('^(?:<p>|\s)*([\s\S]*?)$', sp[i + 1])
						if len(bsp) != 0:
							sp[i-1] = esp[0]
							sp[i+1] = bsp[0]
							sp[i] = ' '

			elif re.match('<page url[^>]*>', sp[i]):
				stampurl.pageurl = sp[i]
				sp[i] = ''

		# stick everything back together
		self.text = ''
		for s in sp:
			if s:
				self.text = self.text + s

	def __init__(self, lspeaker, ltext, stampurl):
		self.speaker = lspeaker
		self.text = ltext

		self.stamp = stampurl.stamp
		self.pageurl = stampurl.pageurl
		self.ncid = stampurl.ncid

		# this is a bit shambolic as it's done in the other class as well.
		self.StampToFront(stampurl)


		# set the type and clear up qnums
		# we also fix the question text as we know what type it is by the 'to ask' prefix.
		#
		# these fix functions are very big and somewhere else.
		if re.match('(?:<[^>]*?>|\s)*?to ask(?i)', self.text):
			self.typ = 'ques'
			(self.text, qnums) = FixQuestion(self.text)
			self.questionqnums.extend(qnums)

		else:
			self.typ = 'reply'
			self.text = FixReply(self.text, self.questionqnums)

			# the only way I know to clear this static class
			while self.questionqnums:
				self.questionqnums.pop()

	def writexml(self, fout):
		fout.write('\t<speech %s type="%s">\n' % (self.speaker, self.typ))

		# add in some tabbing
		sio = cStringIO.StringIO(self.text)
		while 1:
			rl = sio.readline()
			if not rl:
				break
			fout.write('\t\t')
			fout.write(rl)

		fout.write('\t</speech>\n')

class qbatch:
	def __init__(self, ltitle, shspeak, stampurl):
		self.title = ltitle
		self.majorheading = stampurl.majorheading

		self.stamp = stampurl.stamp
		self.pageurl = stampurl.pageurl
		self.ncid = stampurl.ncid

		self.shansblock = [ ]
		qblock = [ ]

		# need to do supertitles
		# and also page urls

		# throw in a batch of speakers
		for shs in shspeak:
			qb = qspeech(shs[0], shs[1], stampurl)
			qblock.append(qb)

			if qb.typ == 'reply':
				if len(qblock) < 2:
					print ' Reply with no question ' + stampurl.stamp
				self.shansblock.append(qblock)
				qblock = []

			# reset the id if the column changes
			if stampurl.stamp != qb.stamp:
				stampurl.ncid = 0
			else:
				stampurl.ncid = stampurl.ncid + 1

		if qblock:
			# these are common failures of the data
			print "block without answer " + self.title
			self.shansblock.append(qblock)


	# this obviously can be changed to suit
	def writexml(self, fout, sdate):
		for sha in self.shansblock:
			colnumg = re.findall('colnum="([^"]*)"', sha[0].stamp)
			if not colnumg:
				raise Exception, 'missing column number'
			colnum = colnumg[0]
			sid = 'uk.org.publicwhip/wrans/%s.%s.%d' % (sdate, colnum, sha[0].ncid)
			fout.write('\n<wrans id="%s" title="%s" majorheading="%s">\n' % \
						(sid, self.title, self.majorheading))
			fout.write(sha[0].stamp)
			fout.write('\n')
			fout.write(sha[0].pageurl)
			fout.write('\n')
			for i in range(len(sha)):
				sha[i].writexml(fout)
			fout.write('</wrans>\n')

majorheadings = {
		"ADVOCATE-GENERAL":"ADVOCATE-GENERAL",
			"ADVOCATE GENERAL":"ADVOCATE-GENERAL",
		"ADVOCATE-GENERAL FOR SCOTLAND":"ADVOCATE-GENERAL FOR SCOTLAND",
		"CABINET OFFICE":"CABINET OFFICE",
			"CABINET":"CABINET OFFICE",
		"CULTURE MEDIA AND SPORT":"CULTURE MEDIA AND SPORT",
			"CULTURE, MEDIA AND SPORT":"CULTURE MEDIA AND SPORT",
			"CULTURE, MEDIA AND SPORTA":"CULTURE MEDIA AND SPORT",
			"CULTURE, MEDIA, SPORT":"CULTURE MEDIA AND SPORT",
		"CHURCH COMMISSIONERS":"CHURCH COMMISSIONERS",
		"CONSTITUTIONAL AFFAIRS":"CONSTITUTIONAL AFFAIRS",
		"DEFENCE":"DEFENCE",
		"DEPUTY PRIME MINISTER":"DEPUTY PRIME MINISTER",
		"ENVIRONMENT FOOD AND RURAL AFFAIRS":"ENVIRONMENT FOOD AND RURAL AFFAIRS",
			"ENVIRONMENT, FOOD AND RURAL AFFAIRS":"ENVIRONMENT FOOD AND RURAL AFFAIRS",
			"DEFRA":"ENVIRONMENT, FOOD AND RURAL AFFAIRS",
		"ENVIRONMENT, FOOD AND THE REGIONS":"ENVIRONMENT, FOOD AND THE REGIONS",
		"ENVIRONMENT":"ENVIRONMENT",
		"EDUCATION AND SKILLS":"EDUCATION AND SKILLS",
		"EDUCATION":"EDUCATION",
		"ELECTORAL COMMISSION COMMITTEE":"ELECTORAL COMMISSION COMMITTEE",
			"ELECTORAL COMMISSION":"ELECTORAL COMMISSION COMMITTEE",
		"FOREIGN AND COMMONWEALTH AFFAIRS":"FOREIGN AND COMMONWEALTH AFFAIRS",
			"FOREIGN AND COMMONWEALTH":"FOREIGN AND COMMONWEALTH AFFAIRS",
			"FOREIGN AND COMMONWEALTH OFFICE":"FOREIGN AND COMMONWEALTH AFFAIRS",
		"HOME DEPARTMENT":"HOME DEPARTMENT",
			"HOME OFFICE":"HOME DEPARTMENT",
			"HOME":"HOME DEPARTMENT",
		"HEALTH":"HEALTH",
		"HOUSE OF COMMONS":"HOUSE OF COMMONS",
		"HOUSE OF COMMONS COMMISSION":"HOUSE OF COMMONS COMMISSION",
			"HOUSE OF COMMMONS COMMISSION":"HOUSE OF COMMONS COMMISSION",
		"INTERNATIONAL DEVELOPMENT":"INTERNATIONAL DEVELOPMENT",
			"INTERNATIONAL DEVELOPENT":"INTERNATIONAL DEVELOPMENT",
		"LEADER OF THE HOUSE":"LEADER OF THE HOUSE",
		"LEADER OF THE COUNCIL":"LEADER OF THE COUNCIL",
		"LORD CHANCELLOR":"LORD CHANCELLOR",
			"LORD CHANCELLOR'S DEPARTMENT":"LORD CHANCELLOR",
			"LORD CHANCELLORS DEPARTMENT":"LORD CHANCELLOR",
			"LORD CHANCELLOR'S DEPT":"LORD CHANCELLOR",
		"MINISTER FOR WOMEN":"MINISTER FOR WOMEN",
		"NORTHERN IRELAND":"NORTHERN IRELAND",
		"PRIME MINISTER":"PRIME MINISTER",
		"PRIVY COUNCIL":"PRIVY COUNCIL",
			"PRIVY COUNCIL OFFICE":"PRIVY COUNCIL",
		"PRESIDENT OF THE COUNCIL":"PRESIDENT OF THE COUNCIL",
		"PUBLIC ACCOUNTS COMMISSION":"PUBLIC ACCOUNTS COMMISSION",
		"SOLICITOR-GENERAL":"SOLICITOR-GENERAL",
			"SOLICITOR GENERAL":"SOLICITOR-GENERAL",
		"SCOTLAND":"SCOTLAND",
		"TRANSPORT":"TRANSPORT",
		"TRANSPORT, LOCAL GOVERNMENT AND THE REGIONS":"TRANSPORT, LOCAL GOVERNMENT AND THE REGIONS",
		"TRADE AND INDUSTRY":"TRADE AND INDUSTRY",
		"TREASURY":"TREASURY",
		"WALES":"WALES",
		"WORK AND PENSIONS":"WORK AND PENSIONS",
		}


fixsubs = 	[
	( '<h2><center>written answers to</center></h2>\s*questions(?i)', \
	  	'<h2><center>Written Answers to Questions</center></h2>', -1, 'all'),
	( '<h\d align=center>written answers[\s\S]{10,150}?\[continued from column \d+?W\](?i)', '', -1, 'all'),
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

		]


def FilterWransSections(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)
	headspeak = SplitHeadingsSpeakers(text)

	# break down into lists of headings and lists of speeches
	(ih, stampurl) = StripWransHeadings(headspeak, sdate)


	# full list of question batches
	qbl = []

	for i in range(ih, len(headspeak)):
		sht = headspeak[i]

		# update the stamps from the pre-spoken text
		stampurl.UpdateStampUrl(sht[1])

		# detect if this is a major heading
		if not re.search('[a-z]', sht[0]) and not sht[2]:
			if not majorheadings.has_key(sht[0]):
				print '"%s":"%s",' % (sht[0], sht[0])
				raise Exception, "unrecognized major heading: "
			else:
				# correct spellings and copy over
				stampurl.majorheading = majorheadings[sht[0]]

		# non-major heading; to a question batch
		else:
			if majorheadings.has_key(sht[0]):
				print sht[0]
				raise Exception, ' speeches found in major heading '

			qb = qbatch(sht[0], sht[2], stampurl)
			qbl.append(qb)


	#
	# we have built up the list of question blocks, now write it out
	#

	fout.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
	fout.write("<publicwhip>\n")
	for qb in qbl:
		qb.writexml(fout, sdate)
	fout.write("</publicwhip>\n")


