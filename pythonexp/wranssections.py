#! /usr/bin/python2.3

import sys
import re
import os
import string


# we do the work in several passes in several classes to keep it separate
class SepHeadText:
	def DetectNoText(self, text):
		fltext = re.sub('<[^>]*?>|\s', '', text)
		return len(fltext) == 0

	# shuffle column stamps out of the way to the front, so we can glue paragraphs together
	# probably a general purpose function
	def StampToFront(self, text):
		# <stamp coldate="2003-11-17" colnum="518" type="W"/>
		ts = re.findall('(<stamp[^>]*?/>)', text)
		if len(ts) == 0:
			return text
		res = ''
		for tss in ts:
			res = res + tss
		sp = re.split('<stamp[^>]*?/>', text)
		for ssp in sp:
			res = res + ssp

		return res

	def EndSpeech(self):
		if self.DetectNoText(self.text):
			if self.speaker != 'No one':
				print 'Speaker with no text: ' + self.speaker
				self.shspeak.append((self.speaker, ''))

		else:
			if self.speaker == 'No one':
				print 'Text with no speaker\n' + self.text
			self.text = self.StampToFront(self.text)
			self.shspeak.append((self.speaker, self.text))
		self.speaker = 'No one'
		self.text = ''

	def EndHeading(self):
		self.EndSpeech()
		if self.heading == 'Initial':
			if len(self.shspeak) == 0:
				return
			print 'Speeches without heading'
		self.shtext.append((self.heading, self.shspeak))
		self.heading = 'Initial'
		self.shspeak = []


	def __init__(self, finr):
		lsectionregexp = '<center>.*?</center>|<h\d align=center>.*?</h\d>'
		lspeakerregexp = '<speaker .*?>.*?</speaker>'
		ltableregexp = '<table.*?>[\s\S]*?</table>'	# these have centres, so must be separated out


		lregexp = '(%s|%s|%s)(?i)' % (lsectionregexp, lspeakerregexp, ltableregexp)

		tableregexp = ltableregexp + '(?i)'
		speakerregexp = '<speaker name="(.*?)">.*?</speaker>'
		sectionregexp1 = '<center>(.*?)</center>(?i)'
		sectionregexp2 = '<h\d align=center>(.*?)</h\d>(?i)'

		fs = re.split(lregexp, finr)

		# this makes a list of pairs of headings and their following text
		self.shtext = [] # return value

		self.heading = 'Initial'

		self.shspeak = []
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
				self.EndHeading()
				self.heading = headinggroup[0]
				continue


			if self.text != '':
				self.text = self.text + fss
			else:
				self.text = fss

		self.EndHeading()


class qbatch:
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



	# substitutes our question number things in too.
	def DetectQuestionType(self, text):
		btoask = re.match('(?:<[^>]*?>|\s)*?To ask(?i)', text)
		bqnum = re.search('\[\d+?\]', text)
		if btoask:
			if not bqnum:
				print "qnum missing"
		elif bqnum:
			print 'qnum present'



	def __init__(self, ltitle, shspeak):
		self.title = ltitle
		self.shansblock = [ ]
		self.qblock = [ ]

		# move timestamps to front on everywhere
		for shs in shspeak:
			if re.match('(?:<[^>]*?>|\s)*?To ask(?i)', shs[1]):
				self.qblock.append(shs)
			else:
				self.qblock.append(shs)
				self.shansblock.append(self.qblock)
				self.qblock = []
		if len(self.qblock) != 0:
			print "block without answer"
			self.shansblock.append(self.qblock)

	def writexml(self, fout):
		for sha in self.shansblock:
			fout.write('<wrans title=%s>\n' % (self.title,))
			fout.write('\t%d\n' % len(sha))
			fout.write('</wrans>\n')



def WransSections(fout, finr):
	sht = SepHeadText(finr)
	print len(sht.shtext)

	for shtext in sht.shtext:
		qb = qbatch(shtext[0], shtext[1])
		qb.writexml(fout)



