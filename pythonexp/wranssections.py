#! /usr/bin/python2.3

import sys
import re
import os
import string

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime




# we do the work in several passes in several classes to keep it separate
class SepHeadText:

	def EndSpeech(self):
		# check for no text
		fltext = re.sub('<[^>]*?>|\s', '', self.text)
		if len(fltext) == 0:
			if self.speaker != 'No one':
				print 'Speaker with no text: ' + self.speaker
				self.shspeak.append((self.speaker, self.text))

			# output no one text in case there's colstamps and pageurls
			elif len(self.shspeak) == 0:
				self.unspoketext = self.text
		else:
			if self.speaker == 'No one':
				print 'Text with no speaker\n' + self.text
			self.shspeak.append((self.speaker, self.text))
		self.speaker = 'No one'
		self.text = ''

	def EndHeading(self):
		self.EndSpeech()
		if self.heading == 'Initial':
			if len(self.shspeak) == 0:
				return
			print 'Speeches without heading'
		self.shtext.append((self.heading, self.unspoketext, self.shspeak))

		self.heading = 'Initial'
		self.unspoketext = ''	# for holding colstamps
		self.shspeak = []


	def __init__(self, finr):
		lsectionregexp = '<h\d><center>.*?</center></h\d>|<h\d align=center>.*?</h\d>'
		lspeakerregexp = '<speaker .*?>.*?</speaker>'
		ltableregexp = '<table.*?>[\s\S]*?</table>'	# these have centres, so must be separated out

		lregexp = '(%s|%s|%s)(?i)' % (lsectionregexp, lspeakerregexp, ltableregexp)

		tableregexp = ltableregexp + '(?i)'
		speakerregexp = '<speaker name="(.*?)">.*?</speaker>'
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

				self.EndHeading()
				self.heading = headinggroup[0]
				continue


			if self.text != '':
				self.text = self.text + fss
			else:
				self.text = fss

		self.EndHeading()


class qbatch_toask:
	toask = [
		"To ask the Secretary of State for Defence",
		"To ask the Secretary of State for Northern Ireland",
		"To ask the Secretary of State for Education and Employment",
		"To ask the Secretary of State for Education and Skills",
		"To ask the Secretary of State for Health",
		"To ask the Secretary of State for Trade and Industry",
		"To ask the Secretary of State for Social Security",
		"To ask the Secretary of State for the Home Department",
		"To ask the Secretary of State for Scotland",
		"To ask the Secretary of State for Wales",
		"To ask the Secretary of State for Culture, Media and Sport",
		"To ask the Secretary of State for the Environment, Transport and the Regions",
		"To ask the Secretary of State for Transport, Local Government and the Regions",
		"To ask the Secretary of State for Transport, Local government and the Regions",
		"To ask the Secretary of State for International Development",
		"To ask the Secretary of State for Foreign and Commonwealth Affairs",
		"To ask the Secretary of State for Environment, Food and Rural Affairs",
		"To ask the Secretary of State for Work and Pensions",

		"To ask the Secretary of Wales",

		"To ask the Chairman of the Accommodation and Works Committee",
		"To ask the Chairman of the Catering Committee",
		"To ask the Chairman of the Public Accounts Commission",
		"To ask the Chairman of the Administration Committee",

		"To ask the Minister of Agriculture, Fisheries and Food",
		"To ask the Minister for the Cabinet Office",

		"To ask the Prime Minister",
		"To ask the Deputy Prime Minister",
		"To ask the Parliamentary Secretary",
		"To ask the Chancellor of the Exchequer",
		"To ask the President of the Council",
		"To ask the Solicitor-General",
		"To ask the Advocate-General",

		"To ask the hon. Member for",
		"To ask the right hon. Member for",
		]

class qspeech:

	# function to shuffle column stamps out of the way to the front, so we can glue paragraphs together
	def StampToFront(self):
		# we make a batch of stamps, leaving the last stamp in if none are being included
		ts = re.findall('(<stamp[^>]*?/>)', self.text)
		if len(ts) == 0:
			self.stamp = self.laststamp
			return
		for self.laststamp in ts:
			self.stamp = self.stamp + self.laststamp

		# remove the stamps from the text, checking for cases where we can glue back together.
		sp = re.split('<stamp[^>]*?/>', self.text)
		self.text = ''
		for i in range(len(sp)):
			# string ends with a lower case character, and next begins with a lower case char
			if (i < len(sp) - 1):
				esp = re.findall('^([\s\S]*?[a-z])(?:<[^>]*?>|\s)*?$', sp[i])
				if len(esp) != 0:
					bsp = re.findall('^(?:<[^>]*?>|\s)*?([a-z][\s\S]*?)$', sp[i + 1])
					if len(bsp) != 0:
						sp[i] = esp[0] + ' '
						sp[i + 1] = bsp[0]
			self.text = self.text + sp[i]

	def __init__(self, lspeaker, ltext, llaststamp, llastpageurl):
		self.speaker = lspeaker
		self.stamp = ''
		self.laststamp = llaststamp
		self.pageurl = llastpageurl
		self.text = ltext

		# set the type and clear up qnums
		if re.match('(?:<[^>]*?>|\s)*?To ask(?i)', self.text):
			self.typ = 'ques'
			# sort out qnums
			bqnum = re.subn('\[(\d+?)\]', '<qcode qnum="\\1"/>', self.text)
			if bqnum[1] == 0:
				print "qnum missing " + self.laststamp
			self.text = bqnum[0]

		else:
			self.typ = 'reply'
			if re.search('\[\d+?\]', self.text):
				print 'qnum present in answer'

		self.StampToFront()

		# find any pageurls which will actually go into the text for next bit
		self.lastpageurl = self.pageurl
		ps = re.findall('<(<page url[^>]*?)>', self.text)
		if len(ps) != 0:
			self.lastpageurl = '<%s/>' % ps[len(ps) - 1] # put the / in where it should be

	def writexml(self, fout):
		fout.write('\t<speech speaker="%s" type="%s">\n' % (self.speaker, self.typ))
		fout.write('\t\t%s\n' % self.stamp)
		fout.write('\t\t%d\n' % len(self.text))
		fout.write('\t</speech>\n\n')

class qbatch:
	def __init__(self, lmajorheading, ltitle, shspeak, llaststamp, llastpageurl):
		self.majorheading = lmajorheading
		self.title = ltitle
		self.laststamp = llaststamp
		self.pageurl = llastpageurl
		self.lastpageurl = llastpageurl

		self.shansblock = [ ]
		qblock = [ ]

		# need to do supertitles
		# and also page urls

		# throw in a batch of speakers
		for shs in shspeak:
			qb = qspeech(shs[0], shs[1], self.laststamp, self.lastpageurl)
			qblock.append(qb)
			self.laststamp = qb.laststamp
			self.lastpageurl = qb.lastpageurl

			if qb.typ == 'reply':
				self.shansblock.append(qblock)
				qblock = []

		if len(qblock) != 0:
			print "block without answer " + self.title
			self.shansblock.append(qblock)

	# this obviously can be changed to suit
	def writexml(self, fout):
		fout.write('\n<wransblock title="%s" majorheading="%s">\n' % (self.title, self.majorheading))
		for sha in self.shansblock:
			fout.write('<wrans title="%s">\n' % (self.title,))
			fout.write(self.pageurl)
			fout.write('\n')
			fout.write(self.laststamp)
			fout.write('\n')
			for i in range(len(sha)):
				sha[i].writexml(fout)
			fout.write('</wrans>\n\n')
		fout.write('</wransblock>\n')


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
	( '<H\d align=center>Written Answers[\s\S]{10,99}?\[Continued from column \d+?W\]', '', -1, 'all'),
	( '<H\d><center>Written Answers[\s\S]{10,99}?\[Continued from column \d+?W\]', '', -1, 'all'),
	( '<h2><center>written answers to</center></h2>\s*questions(?i)', \
	  	'<h2><center>Written Answers to Questions</center></h2>', -1, 'all'),
	( '<H2 align=center> </H2>', '', 1, '2003-09-15'),
	( '<H1 align=center></H1>\s*<H2 align=center>Monday 15 September 2003</H2>', '', 1, '2003-09-15'),
	( '<H1 align=center></H1>', '', 1, '2003-10-06'),

	( '</H3>\s*Trading Arrangements', ' Trading Arrangements</H3>', 1, '2003-09-01'),
	( '</H3>\s*Support Services', ' Support Services</H3>', 1, '2003-09-01'),
	( '</H3>\s*Support Service', ' Support Service</H3>', 1, '2003-09-01'),
	( '</H3>\s*\(Clinical Trials\) Regulations', ' (Clinical Trials) Regulations</H3>', 1, '2003-09-01'),

	( '</H3>\s*Control Programme', ' Control Programme</H3>', 1, '2003-07-17'),
	( '</H3>\s*\(Regulatory Impact Assessments\)', ' (Regulatory Impact Assessments)</H3>', 1, '2003-07-17'),
	( '</H3>\s*Involvement in Health', ' Involvement in Health</H3>', 1, '2003-07-17'),



		]

def ApplyFixSubs(finr, sdate):
	for sub in fixsubs:
		if sub[3] == 'all' or sub[3] == sdate:
			res = re.subn(sub[0], sub[1], finr)
			if sub[2] != -1 and res[1] != sub[2]:
				print 'wrong substitutions %d on %s' % (res[1], sub[0])
			finr = res[0]
	return finr

def StripHeadings(shtext, sdate):
	# check and strip the first two headings in as much as they are there
	i = 0
	if (not re.match('written answers to questions(?i)', shtext[i][0])) or (len(shtext[i][2]) != 0):
		if not re.match('The following answers were received.*', shtext[i][0]):
			print 'non-conforming first heading '
			print shtext[0]
	else:
		i = i + 1

	if (not re.match('The following answers were received.*', shtext[i][0]) and \
			(sdate != mx.DateTime.DateTimeFrom(shtext[i][0]).date)) or (len(shtext[i][2]) != 0):
		if (not majorheadings.has_key(shtext[i][0])) or (len(shtext[i][2]) != 0):
			print 'non-conforming second heading '
			print shtext[i]
	else:
		i = i + 1
	return i

# these types of stamps must be available in every question and batch.
# <stamp coldate="2003-11-17" colnum="518" type="W"/>
# <page url="http://www.publications.parliament.uk/pa/cm200102/cmhansrd/vo020522/text/20522w01.htm">

def WransSections(fout, finr, sdate):

	# get rid of spurious headings in the middle of the text
	finr = ApplyFixSubs(finr, sdate)

	# break down into lists of headings and lists of speeches
	shtext = SepHeadText(finr).shtext

	shtext = shtext[StripHeadings(shtext, sdate):]

	# go through and build up the question batches associated to each heading
	laststamp = ''
	lastpageurl = ''
	lastmajorheading = ''
	for sht in shtext:
		# update the stamps (keeping only the last ones)
		for st in re.findall('(<stamp [^>]*?/>)', sht[1]):
			laststamp = st
		for stp in re.findall('(<page [^>]*?/>)', sht[1]):
			lastpageurl = stp

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
			qb = qbatch(lastmajorheading, sht[0], sht[2], laststamp, lastpageurl)
			qb.writexml(fout)
			laststamp = qb.laststamp
			lastpageurl = qb.lastpageurl

			#print lastpageurl
	#sys.exit()
