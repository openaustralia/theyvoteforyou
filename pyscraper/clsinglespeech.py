#! /usr/bin/python2.3

import sys
import re
import copy
import string

from filterwransques import FilterQuestion
from filterwransreply import FilterReply


def TestMergeAcrossStamp(s0, s1):
	# extract the last word of one, and first word of other, and check if they should glue
	# they always do if we don't end with a dot punctuation, or some html symbol
	# there may be more gluing conditions
	gesp = re.match('([\s\S]*?([\w,]+))(?:<p>|\s)*$(?i)', s0)
	if not gesp:
		return None
	gbsp = re.match('(?:<p>|\s)*((\w+)[\s\S]*)$(?i)', s1)
	if not gbsp:
		return None

	#if re.search(',$', gesp.group(2)):
	#	print 'TXMERGE', gesp.group(2), gbsp.group(2)
	return ( gesp.group(1), gbsp.group(1) )



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
					# strip out new paragraph symbols that we don't need
					ebsp = TestMergeAcrossStamp(sp[i-1], sp[i+1])
					if ebsp:
						sp[i-1] = ebsp[0]
						sp[i] = ' '
						sp[i+1] = ebsp[1]

			elif re.match('<page url[^>]*>', sp[i]):
				stampurl.pageurl = sp[i]
				sp[i] = ''

		# stick everything back together
		self.text = string.join(sp, '')

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
				if (not qnums.count(qn)) and (qn > 100):	# sometimes [n] is an enumeration
					print ' unknown qnum present in answer ' + self.sstampurl.stamp
					self.stext = [ '<error>qnum present</error>' ]
					return

			FilterReply(self)

		else:
			raise Exception, ' unrecognized speech type '

