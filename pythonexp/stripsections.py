#! /usr/bin/python2.3

import sys
import re
import os
import string


class QuestionBatch:

	def __init__(self, pfs):
		self.i = 0

		# look for evidence of question
		self.oqsubject = pfs[0][0]

		if re.search('was asked', pfs[1][0]):
			if not re.match('\s*?The .*? was asked&#151;', pfs[1][0]):
				print "Bad question caller match: " + pfs[1][0]
			self.oqminister = re.findall('The (.*?) was asked', pfs[1][0])
			self.oqminister = self.oqminister[0]
			it = 2
		else:
			qnums = re.findall('\[(\d+)\]', pfs[2][1])
			if len(qnums) == 0:
				return  # no questions found
			print 'warning: missing oral questions title'
			self.oqminister = ''
			it = 1

		if re.search('[a-z]', self.oqsubject):
			print 'warning: subject not caps'

		for i in range(it,len(pfs)):
			# detect if this is a question
			qnums = re.findall('\[(\d+)\]', pfs[i][1])
			if len(qnums) == 0:
				break
		self.oqpfs = pfs[it:i]
		if i == it:
			print 'no questions found in section'


		self.i = i   # to use for trimming

	def writerep(self, fout):
		fout.write('<h2>Oral questions (%s) to (%s)</h2>\n' % (self.oqsubject, self.oqminister) )
		fout.write('<p>')
		for s in self.oqpfs:
			fout.write(s[0])
			fout.write(';')
		fout.write('</p>\n')

lsectionregexp = '(<center>.*?</center>|<h\d align=center>.*?</h\d>)(?i)'
sectionregexp1 = '<center>(.*?)</center>(?i)'
sectionregexp2 = '<h\d align=center>(.*?)</h\d>(?i)'

class StripSections:

	# this gets down to the first bit of actual stuff.
	def stripheadings(self):
		for i in range(len(self.pfs)):
			if re.search('oral(?i)', self.pfs[i][0]):
				break
		self.pfsheadings = self.pfs[0:i]
		self.pfs = self.pfs[i:]

	# this gets down to the first bit of actual stuff.
	def striporalqs(self):
		# deal with full heading
		if not re.search('oral(?i)', self.pfs[0][0]):
			return
		if not re.match('Oral Answers to Questions', self.pfs[0][0]):
			print 'Mismatch on title: ' + self.pfs[0][0]

		self.pfs = self.pfs[1:]

		while 1:
			qb = QuestionBatch(self.pfs)
			if qb.i == 0:
				break
			self.qbatches.append(qb)
			self.pfs = self.pfs[qb.i:]
		if len(self.qbatches) == 0:
			print 'No question batches found'

	# this gets the adjournment debate out
	#def stripadjourn(self):


	# build into pairs
	def splitintopairs(self, fr):
		fs = re.split(lsectionregexp, fr)
		heading = "Initial"
		for fss in fs:
			sectiongroup = re.findall(sectionregexp1, fss)
			if len(sectiongroup) == 0:
				sectiongroup = re.findall(sectionregexp2, fss)
				if len(sectiongroup) == 0:
					if not heading:
						print " no heading for text"
						print fss
						heading = ''
						sys.exit()
					self.pfs.append( (heading, fss ) )
					heading = None
					continue

			if heading:
				self.pfs.append( (heading, '' ) )
			heading = sectiongroup[0]
		if not heading:
			self.pfs.append( (heading, '' ) )

	# main function.
	def __init__(self, fr):
		self.pfs = []  # set of heading, text pairs
		self.splitintopairs(fr)
		self.stripheadings()

		self.qbatches = []
		self.striporalqs()


	def foldwrite(self, fout):

		# write out the oral questions
		for qb in self.qbatches:
			qb.writerep(fout)

		for fss in self.pfs:
			fout.write('<h3 align=center><font color="#004f3f">%s</font></h3>\n' % fss[0])
			if len(fss[1]) < 30:
				fout.write(fss[1])
			else:
				# put folds around this text
				fout.write('<span onclick="cycle(this)" class="phid" pos="first">')
				fout.write(fss[1])
				fout.write('</span><span onclick="cycle(this)" class="pvis" pos="last">')
				fout.write('<center>(')
				for i in range(len(fss[1]) / 300):
					fout.write('-')
				fout.write(')</center>')
				fout.write('</span>')
