#! /usr/bin/python2.3
import sys
import re
import os
import string

# there's more processing of the questions that we could do, but not now.
# intention is to slam this stuff into the full questions database from
# the written questions section.
# One thing is to remove the numbers at the front of the questions.
# The next is to convert the bracket numbers intoo <qnum> types


def qwarn(sdate, mess):
	print "warning " + mess

# given a list of heading/text pairs, extract a batch of questions at the head.
class QuestionBatch:

	def __init__(self, pfs, sdate):
		# self.i is the return value - 0 for no questions.

		# look for evidence of question in second line as the minister
		if re.search('was asked', pfs[1][0]):
			if not re.match('\s*?The .*? was asked:?(?:&#151;)?\s*?$', pfs[1][0]):
				qwarn(sdate, "Bad question caller match: " + pfs[1][0])
			self.oqminister = re.findall('The (.*?) was asked', pfs[1][0])
			self.oqminister = self.oqminister[0]
			self.i = 2
		else:
			qnums = re.findall('\[(\d+)\]', pfs[2][1])
			if len(qnums) != 0:
				qwarn(sdate, 'missing oral questions title')
				self.oqminister = ''
				self.i = 1
			else:
				self.i =  0 # no questions found

		# no questions case; check all the way down if any bracket numbers or was askeds are present
		# which would suggest we've got this wrong
		if self.i == 0:
			for pfss in pfs:
				if re.search('was asked(?i)', pfss[0]):
					qwarn(sdate, 'no questions, but title exists, ' + pfss[0])
				if re.search('\[\d+\]', pfss[1]):
					qwarn(sdate, 'no questions, but square bracket number exists, ' + pfss[0])
			return

		# the question subject
		self.oqsubject = pfs[0][0]
		if re.search('[a-z]', self.oqsubject):
			qwarn(sdate, 'subject not caps')

		# go through all the subsequent titles till we find one with text without a square bracket number
		for i in range(self.i, len(pfs)):
			# detect if this is a question
			qnums = re.findall('\[(\d+)\]', pfs[i][1])
			if len(qnums) == 0:
				break
		self.oqpfs = pfs[self.i:i]
		if i == self.i:
			qwarn(sdate, 'no questions found in section')

		# cut-off point for trimming pfs (can't be done locally)
		self.i = i


	def writerep(self, fout):
		fout.write('<h2>Oral questions (%s) to (%s)</h2>\n' % (self.oqsubject, self.oqminister) )
		fout.write('<p>')
		for s in self.oqpfs:
			fout.write(s[0])
			fout.write(';')
		fout.write('</p>\n')
