#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import re
import copy
import string

from filterwransques import FilterQuestion
from filterwransreply import FilterReply


qnummisserrors = {
		'<stamp coldate="2003-11-17" colnum="616W"/>':'<error>truncated question</error>',
		'<stamp coldate="2003-11-05" colnum="660W"/>':'<error>truncated question</error>',
		'<stamp coldate="2003-10-27" colnum="29W"/>':'<error>truncated question</error>',
		'<stamp coldate="2003-07-16" colnum="349W"/>':'<error>truncated question</error>',
		}



class qspeech:
	# function to shuffle column stamps out of the way to the front, so we can glue paragraphs together
	def StampToFront(self, stampurl):
                # print "StampToFront in clsinglespeech.py", self.text
		# remove the stamps from the text, checking for cases where we can glue back together.
		sp = re.split('(<stamp [^>]*>|<page url[^>]*>)', self.text)
		for i in range(len(sp)):
			if re.match('<stamp [^>]*>', sp[i]):
				if re.match('<stamp time[^>]*>', sp[i]):
					stampurl.timestamp = sp[i]
				elif re.match('<stamp aname[^>]*>', sp[i]):
                                        stampurl.aname = sp[i] 
				else:
					stampurl.stamp = sp[i]
				sp[i] = ''

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
                # yes, it's atrocious! - other class is in splitheadingsspeakers.py
		self.StampToFront(stampurl)

		# we also fix the question text as we know what type it is by the 'to ask' prefix.
                # - put special cases which don't have the 'to ask' in filtewranssections.py,
                # rather than adding them here.
		if re.match('(?:<[^>]*?>|\s)*?((to ask)' +
#                                '|(if s?he will make a statement)' +
#                                '|(what plans s?he has to)' +
                                ')(?i)', self.text):
			self.typ = 'ques'
		else:
			self.typ = 'reply'

		# reset the id if the column changes
		if stampurl.stamp != self.sstampurl.stamp:
			stampurl.ncid = 0
		else:
			stampurl.ncid = stampurl.ncid + 1


	def FixSpeech(self, qnums):
		self.qnums = re.findall('\[(\d+)R?\]', self.text)

		# find the qnums
		if self.typ == 'ques':
			#self.text = re.sub('\[(\d+?)\]', ' ', self.text)
			self.stext = FilterQuestion(self.text, self.sdate)

			qnums.extend(self.qnums)	# a return value mapped back into reply types
			if not self.qnums:
				if not qnummisserrors.has_key(self.sstampurl.stamp):
					print ' qnum missing in question ' + self.sstampurl.stamp
				errmess = qnummisserrors.get(self.sstampurl.stamp, '<error>qnum missing</error>')
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
					self.stext.append('<error>qnum present</error>')

		else:
			raise Exception, ' unrecognized speech type '

