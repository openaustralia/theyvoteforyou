#! /usr/bin/python2.3

import sys
import re
import os
import string
import StringIO

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

from filterwranssinglespeech import FixReply
from filterwranssinglespeech import FixQuestion

from miscfuncs import ApplyFixSubstitutions


# we do the work in several passes in several classes to keep it separate
class SepHeadText:

	def EndSpeech(self):
		if self.speaker != 'No one':
			self.shspeak.append((self.speaker, self.text))
			if re.match('(?:<[^>]*?>|\s)*$', self.text):
				print 'Speaker with no text'
		elif not self.shspeak:
			self.unspoketext = self.text
		else:
			print 'logic error in EndSpeech'
			raise Exception, 'logic error in EndSpeech'


		self.speaker = 'No one'
		self.text = ''

	def EndHeading(self, nextheading):
		self.EndSpeech()
		if (self.heading == 'Initial') and (len(self.shspeak) != 0):
			print 'Speeches without heading'

		# concatenate unspoken text with the title if it's a dangle outside heading
		if not re.match('(?:<[^>]*?>|\s)*$', self.unspoketext):
			ho = re.findall('^\s*(.*?)(?:\s|<p>)*$(?i)', self.unspoketext)
			if ho:
				self.heading = self.heading + ' ' + ho[0]
				self.unspoketext = ''
			else:
				print 'text without speaker'
				print self.unspoketext

		# push block into list
		self.shtext.append((self.heading, self.unspoketext, self.shspeak))

		self.heading = nextheading
		self.unspoketext = ''	# for holding colstamps
		self.shspeak = []


	def __init__(self, finr):
		lsectionregexp = '<h\d><center>.*?</center></h\d>|<h\d align=center>.*?</h\d>'
		lspeakerregexp = '<speaker [^>]*>.*?</speaker>'
		ltableregexp = '<table[^>]*>[\s\S]*?</table>'	# these have centres, so must be separated out

		lregexp = '(%s|%s|%s)(?i)' % (lsectionregexp, lspeakerregexp, ltableregexp)

		tableregexp = ltableregexp + '(?i)'
		speakerregexp = '<speaker ([^>]*)>.*?</speaker>'
		sectionregexp1 = '<center>\s*(.*?)\s*</center>(?i)'
		sectionregexp2 = '<h\d align=center>\s*(.*?)\s*</h\d>(?i)'

		fs = re.split(lregexp, finr)

		# this makes a list of pairs of headings and their following text
		self.shtext = [] # return value

		self.heading = 'Initial'
		self.shspeak = []
		self.unspoketext = ''

		self.speaker = 'No one'
		self.text = ''

		for fss in fs:
			# stick tables back into the text
			if re.match(tableregexp, fss):
				self.text = self.text + fss
				continue

			speakergroup = re.findall(speakerregexp, fss)
			if len(speakergroup) != 0:
				self.EndSpeech()
				self.speaker = speakergroup[0]
				continue

			headinggroup = re.findall(sectionregexp1, fss)
			if len(headinggroup) == 0:
				headinggroup = re.findall(sectionregexp2, fss)
			if len(headinggroup) != 0:
				if headinggroup[0] == '':
					print 'missing heading'
					print self.heading

				self.EndHeading(headinggroup[0])
				continue


			if self.text != '':
				self.text = self.text + fss
			else:
				self.text = fss

		self.EndHeading('No more')


	# functions here are a second pass, batching the stamps and pageurls
	# this could be in a different class
	def StampPageUrl(self, text):
		for st in re.findall('(<stamp [^>]*?/>)', text):
			self.laststamp = st
		for stp in re.findall('<(page url[^>]*?)/?>', text):
			self.lastpageurl = '<%s/>' % stp


	def StripHeadings(self, sdate):
		self.lastpageurl = ''
		self.laststamp = ''

		# check and strip the first two headings in as much as they are there
		i = 0
		if (self.shtext[i][0] != 'Initial') or (len(self.shtext[i][2]) != 0):
			print 'non-conforming Initial heading '
		else:
			self.StampPageUrl(self.shtext[i][1])
			i = i + 1

		if (not re.match('written answers to questions(?i)', self.shtext[i][0])) or (len(self.shtext[i][2]) != 0):
			if not re.match('The following answers were received.*', self.shtext[i][0]):
				print 'non-conforming first heading '
				print self.shtext[0]
		else:
			self.StampPageUrl(self.shtext[i][1])
			i = i + 1

		#if (not re.match('The following answers were received.*', self.shtext[i][0]) and \
		#		(sdate != mx.DateTime.DateTimeFrom(self.shtext[i][0]).date)) or (len(self.shtext[i][2]) != 0):
		if (not re.match('The following answers were received.*', self.shtext[i][0])) or (len(self.shtext[i][2]) != 0):
			if (not majorheadings.has_key(self.shtext[i][0])) or (len(self.shtext[i][2]) != 0):
				print 'non-conforming second heading '
				print self.shtext[i]
		else:
			self.StampPageUrl(self.shtext[i][1])
			i = i + 1
		self.ifh = i



class qspeech:
	# static value used to carry qnums found in questions and compare any that show up
	# spuriously in answers so we can delete them without printing an error.
	questionqnums = []

	# function to shuffle column stamps out of the way to the front, so we can glue paragraphs together
	def StampToFront(self):
		# remove the stamps from the text, checking for cases where we can glue back together.
		sp = re.split('(<stamp [^>]*>|<page url[^>]*>)', self.text)
		for i in range(len(sp)):
			if re.match('<stamp [^>]*>', sp[i]):
				self.laststamp = sp[i]
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
				self.lastpageurl = sp[i]
				sp[i] = ''

		# stick everything together
		self.text = ''
		for s in sp:
			if s:
				self.text = self.text + s

	def __init__(self, lspeaker, ltext, llaststamp, llastpageurl, lncid):
		self.speaker = lspeaker
		self.stamp = llaststamp
		self.laststamp = llaststamp
		self.pageurl = llastpageurl
		self.lastpageurl = self.pageurl
		self.text = ltext
		self.ncid = lncid

		# this is a bit shambolic as it's done in the other class as well.
		self.StampToFront()


		# set the type and clear up qnums
		if re.match('(?:<[^>]*?>|\s)*?to ask(?i)', self.text):
			self.typ = 'ques'
			(self.text, qnums) = FixQuestion(self.text)
			self.questionqnums.extend(qnums)

		else:
			self.typ = 'reply'
			self.text = FixReply(self.text, self.questionqnums)

			# the only way to clear this static class
			while self.questionqnums:
				self.questionqnums.pop()

	def writexml(self, fout):
		fout.write('\t<speech %s type="%s">\n' % (self.speaker, self.typ))

		# add in some tabbing
		sio = StringIO.StringIO(self.text)
		while 1:
			rl = sio.readline()
			if not rl:
				break
			fout.write('\t\t')
			fout.write(rl)

		fout.write('\t</speech>\n')

class qbatch:
	def __init__(self, lmajorheading, ltitle, shspeak, llaststamp, llastpageurl, lncid):
		self.majorheading = lmajorheading
		self.title = ltitle
		self.stamp = llaststamp
		self.laststamp = llaststamp
		self.pageurl = llastpageurl
		self.lastpageurl = llastpageurl
		self.ncid = lncid

		self.shansblock = [ ]
		qblock = [ ]

		# need to do supertitles
		# and also page urls

		# throw in a batch of speakers
		for shs in shspeak:
			qb = qspeech(shs[0], shs[1], self.laststamp, self.lastpageurl, self.ncid)
			qblock.append(qb)
			self.laststamp = qb.laststamp
			self.lastpageurl = qb.lastpageurl

			if qb.typ == 'reply':
				self.shansblock.append(qblock)
				qblock = []

			# reset the id if the column changes
			if qb.laststamp != qb.stamp:
				self.ncid = 0
			else:
				self.ncid = self.ncid + 1

		if qblock:
			print "block without answer " + self.title
			self.shansblock.append(qblock)

	# this obviously can be changed to suit
	def writexml(self, fout, sdate):
		for sha in self.shansblock:
			colnumg = re.findall('colnum="([^"]*)"', sha[0].stamp)
			if colnumg:
				colnum = colnumg[0]
			else:
				colnum = 'BADCOL'
				print 'missing column number'
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

def ApplyFixSubs(finr, sdate):
	for sub in fixsubs:
		if sub[3] == 'all' or sub[3] == sdate:
			res = re.subn(sub[0], sub[1], finr)
			if sub[2] != -1 and res[1] != sub[2]:
				print 'wrong substitutions %d on %s' % (res[1], sub[0])
			finr = res[0]

	return finr



# these types of stamps must be available in every question and batch.
# <stamp coldate="2003-11-17" colnum="518" type="W"/>
# <page url="http://www.publications.parliament.uk/pa/cm200102/cmhansrd/vo020522/text/20522w01.htm">

def FilterWransSections(fout, finr, sdate):

	# get rid of spurious headings in the middle of the text
	finr = ApplyFixSubs(finr, sdate)

	# break down into lists of headings and lists of speeches
	shta = SepHeadText(finr)

	shta.StripHeadings(sdate)

	lastmajorheading = ''

	# full list of question batches
	qbl = []

	ncid = 0
	for i in range(shta.ifh, len(shta.shtext)):
		sht = shta.shtext[i]

		# update the stamps (keeping only the last ones)
		shta.StampPageUrl(sht[1])

		# detect if this is a major heading
		if not re.search('[a-z]', sht[0]) and len(sht[2]) == 0:
			if not majorheadings.has_key(sht[0]):
				print "unknown major heading: " + sht[0]
				print '"%s":"%s",' % (sht[0], sht[0])
				print lastmajorheading
			else:
				lastmajorheading = majorheadings[sht[0]]	# correct spellings

		# non-major heading; to a question batch
		else:
			if majorheadings.has_key(sht[0]):
				print 'speeches found in major heading ' + sht[0]
			qb = qbatch(lastmajorheading, sht[0], sht[2], shta.laststamp, shta.lastpageurl, ncid)
			qbl.append(qb)
			ncid = qb.ncid
			shta.lastpageurl = qb.lastpageurl
			shta.laststamp = qb.laststamp
			qbl.append(qb)

	fout.write("<?xml version='1.0' encoding='us-ascii'?>\n")
	fout.write("<publicwhip>\n")
	for qb in qbl:
		qb.writexml(fout, sdate)
	fout.write("</publicwhip>\n")


