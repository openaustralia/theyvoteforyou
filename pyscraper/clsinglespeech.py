#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import re
import copy
import string

from filterwransques import FilterQuestion
from filterwransreply import FilterReply


class qspeech:

	def __init__(self, lspeaker, ltext, stampurl):
		self.speaker = lspeaker
		self.text = ltext
		self.sstampurl = copy.copy(stampurl)
		self.sdate = self.sstampurl.sdate

		self.text = stampurl.UpdateStampUrl(self.text)

		# we also fix the question text as we know what type it is by the 'to ask' prefix.
		if re.match('(?:<[^>]*?>|\s)*?(to ask)(?i)', self.text):
			self.typ = 'ques'
		else:
			self.typ = 'reply'


	def FixSpeech(self, qnums):
		self.qnums = re.findall('\[(\d+)R?\]', self.text)

		# find the qnums
		if self.typ == 'ques':
			#self.text = re.sub('\[(\d+?)\]', ' ', self.text)
			self.stext = FilterQuestion(self.text, self.sdate)

			qnums.extend(self.qnums)	# a return value mapped back into reply types
			if not self.qnums:
				errmess = ' <p class="error">Question number missing in Hansard, possibly truncated question.</p> '
				self.stext.append(errmess)

		elif self.typ == 'reply':
			FilterReply(self)

			# check against qnums which are sometimes repeated in the answer code
			for qn in self.qnums:
				# sometimes [n] is an enumeration or part of a title
				nqn = string.atoi(qn)
				if (not qnums.count(qn)) and (nqn > 100) and \
                                            (nqn != 2003) and (nqn != 2002) and (nqn != 1995):
					print ' unknown qnum present in answer ' + self.sstampurl.stamp
					print qn
					raise Exception, ' make it clear '
					self.stext.append('<error>qnum presen in answer</error>')

		else:
			raise Exception, ' unrecognized speech type '

