#! /usr/bin/python2.3

import sys
import re
import copy

from filterwransques import FilterQuestion
from filterwransreply import FilterReply

class qspeech:
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

	def __init__(self, lspeaker, ltext, stampurl, lsdate):
		self.speaker = lspeaker

		self.text = ltext

		self.sdate = lsdate

		self.sstampurl = copy.copy(stampurl)

		# this is a bit shambolic as it's done in the other class as well.
		self.StampToFront(stampurl)

		# we also fix the question text as we know what type it is by the 'to ask' prefix.
		if re.match('(?:<[^>]*?>|\s)*?to ask(?i)', self.text):
			self.typ = 'ques'
		else:
			self.typ = 'reply'



	def FixSpeech(self, qnums):
		self.qnums = re.findall('\[(\d+)R?\]', self.text)

		# find the qnums
		if self.typ == 'ques':
			if not self.qnums:
				print ' qnum missing in question ' + self.sstampurl.stamp
				self.stext = [ '<error>qnum missing</error>' ]
				return

			qnums.extend(self.qnums)	# a return value mapped into reply types
			self.text = re.sub('\[(\d+?)\]', ' ', self.text)
			FilterQuestion(self)


		elif self.typ == 'reply':
			for qn in self.qnums:
				if not qnums.count(qn):
					print ' unknown qnum present in answer ' + self.sstampurl.stamp
					self.stext = [ '<error>qnum present</error>' ]
					return

			FilterReply(self)

		else:
			raise Exception, ' unrecognized speech type '

