#! /usr/bin/python2.3

import sys
import re
import os
import string

from questionbatch import QuestionBatch


lsectionregexp = '(<h\d><center>.*?</center></h\d>|<h\d align=center>.*?</h\d>|<center>.*?</center>)(?i)'
sectionregexp1 = '<center>(.*?)</center>(?i)'
sectionregexp2 = '<h\d align=center>(.*?)</h\d>(?i)'

# the day always has
# heading stuff
# oral questions
# statements
# debates
# adjournment debate

class StripSections:

	# this gets down to the first bit of actual stuff.
	def stripheadings(self):
		for i in range(len(self.pfs)):
			if re.search('oral|orders(?i)', self.pfs[i][0]):
				break
		self.pfsheadings = self.pfs[0:i]
		self.pfs = self.pfs[i:]

		# this will find the speaker in the chair bit.
		# bk = re.findall('^\[(.*?)\]$', pfss[0])


	# this gets down to the first bit of actual stuff.
	def striporalqs(self):
		# deal with full heading
		if not re.search('oral(?i)', self.pfs[0][0]):
			return
		if not re.match('Oral Answers to Questions', self.pfs[0][0]):
			print 'Mismatch on title: ' + self.pfs[0][0]

		self.pfs = self.pfs[1:]

		while 1:
			qb = QuestionBatch(self.pfs, self.sdate)
			if qb.i == 0:
				break
			self.qbatches.append(qb)
			self.pfs = self.pfs[qb.i:]
		if len(self.qbatches) == 0:
			print 'No question batches found'


	def detectstatement(self, pfss, pss):
		sby = None
		for ppss in pss:
			if re.search('with permission.*?i .*? make a statement(?i)', ppss[1]):
				sby = ppss[0]
		if sby:
			print 'statement by ' + sby
			return 'STATEMENT * '
		return None

	def detectajourn(self, pfss, pss):
		sby = None
		for ppss in pss:
			if re.search('that this house .*? adjourn(?i)', ppss[1]):
				sby = ppss[0]
		if sby:
			print 'motion by ' + sby
			return 'ADJOURN * '
		return None

	def detectmotion(self, pfss, pss):
		sby = None
		for ppss in pss:
			if re.search('i beg to move(?i)', ppss[1]):
				sby = ppss[0]
		if sby:
			print 'motion by ' + sby
			return 'MOTION * '
		return None


	def marktitles(self):
		for i in range(len(self.pfs)):
			pfss = self.pfs[i]
			if re.search('division(?i)', pfss[0]):
				continue
			pss = self.splitintospeakerpairs(pfss[1])
			pref = self.detectstatement(pfss, pss)
			if not pref:
				pref = self.detectmotion(pfss, pss)
			if not pref:
				pref = self.detectajourn(pfss, pss)
			if pref:
				self.pfs[i] = (pref + self.pfs[i][0], self.pfs[i][1])




	# this gets the adjournment debate out
	#def stripadjourn(self):

	# build into speaker pairs
	# <speaker name="Mrs. Gwyneth Dunwoody  (Crewe and Nantwich)"><font color="#003fcf">Mrs. Gwyneth Dunwoody  (Crewe and Nantwich)</font></speaker>
	def splitintospeakerpairs(self, fr):
		pss = []  # result
		fs = re.split('(<speaker .*?>.*?</speaker>)', fr)
		speaker = 'Initial'
		for fss in fs:
			speakergroup = re.findall('<speaker name="(.*?)">.*?</speaker>', fss)
			if len(speakergroup) == 0:
				if speaker:
					pss.append( (speaker, fss ) )
				else:
					print " no speaker for text"
				speaker = None

			else:
				if speaker and (speaker != 'Initial'):
					print " no text for speaker " + speaker
				speaker = speakergroup[0]
		if speaker and (speaker != 'Initial'):
			print " no text for speaker at end " + speaker
		return pss


	# build into pairs bloocked by title
	def splitintoblockpairs(self, fr):
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
					self.pfs.append( (heading, fss ) )
					heading = None
					continue

			if heading:
				self.pfs.append( (heading, '' ) )
			heading = sectiongroup[0]
		if heading:
			self.pfs.append( (heading, '' ) )

 # main function.
	def __init__(self, fr, sdate):
		self.pfs = []  # set of heading, text pairs
		self.sdate = sdate   # date is used to kill off warnings

		self.splitintoblockpairs(fr)
		self.stripheadings()

		self.qbatches = []
		self.striporalqs()

		self.marktitles()

	def foldwrite(self, fout):

		# write out the oral questions
		for qb in self.qbatches:
			qb.writerep(fout)

		for fss in self.pfs:
			fout.write('\n<h3 align=center><font color="#004f3f">%s</font></h3>\n' % fss[0])
			if len(fss[1]) < 30:
				fout.write(fss[1])
			else:
				# put folds around this text
				fout.write('<span onclick="cycle(this)" class="phid" pos="first">\n')
				fout.write(fss[1])
				fout.write('</span><span onclick="cycle(this)" class="pvis" pos="last">\n')
				fout.write('<center>(')
				for i in range(len(fss[1]) / 300):
					fout.write('-')
				fout.write(')</center>\n')
				fout.write('</span>\n')
