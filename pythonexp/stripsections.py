#! /usr/bin/python2.3

import sys
import re
import os
import string

from questionbatch import QuestionBatch
from sepsectionsspeeches import SepSectionsSpeeches

lsectionregexp = '(<h\d><center>.*?</center></h\d>|<h\d align=center>.*?</h\d>|<center>.*?</center>)(?i)'
sectionregexp1 = '<center>(.*?)</center>(?i)'
sectionregexp2 = '<h\d align=center>(.*?)</h\d>(?i)'

# the day always has
# heading stuff
# oral questions
# statements
# debates
# adjournment debate

mqputs = [ 	'<i>question put\s*?(?:accordingly)?,?</i>,?(.*?):&#151;(?i)',
		'<i>question put and (.*?)</i>(?i)',
		'<i>motion made, and question put forthwith, (pursuant .*?)</i>(?i)',
		'<i>motion made, and question proposed, (.*? adjourn.*?)</i>(?i)',
		'<i>(question put):&#151;(?i)</i>',
		'<i>motion made, and</i> <i>question put</i> <i>forthwith, (pursuant *.?)[.]</i>(?i)',
		'<i>(?:motion made, and )question put,</i> (.*?):&#151;(?i)',
		'(adjourned the house without question put)(?i)',
		'(motion for adjournment lapsed, without question put)(?i)',
		'<i>it being *.?, the (motion for the adjournment .*?, without question put)[.]</i>(?i)',
		'<i>motion made, and question put,</i> (.*?)[.](?i)',
		'<i>motion made, and question proposed,</i> (.*?)&#151;(?i)',
		'<i>question put forthwith, (.*?):&#151;</i>(?i)',
	 ]


class StripSections:
	# this gets down to the first bit of actual stuff.
	def stripheadings(self):
		for i in range(len(self.pfs)):
			if re.search('oral|orders(?i)', self.pfs[i][1]):
				break
		self.pfsheadings = self.pfs[0:i]
		self.pfs = self.pfs[i:]
		# this will find the speaker in the chair bit.
		# bk = re.findall('^\[(.*?)\]$', pfss[0])


	# this gets down to the first bit of actual stuff.
	def striporalqs(self):
		# deal with full heading
		if not re.search('oral(?i)', self.pfs[0][1]):
			return
		if not re.match('Oral Answers to Questions', self.pfs[0][1]):
			print 'Mismatch on title: ' + self.pfs[0][1]

		self.pfs = self.pfs[1:]

		while 1:
			qb = QuestionBatch(self.pfs, self.sdate)
			if qb.i == 0:
				break
			self.qbatches.append(qb)
			self.pfs = self.pfs[qb.i:]
		if len(self.qbatches) == 0:
			print 'No question batches found'


	def detectqput(self, pss):
		# <i>Question put,</i> That the original words stand part of the Question:&#151;
		sby = None
		for ppss in pss:
			if re.search('question put (?i)', ppss[1]):
				for mqput in mqputs:
					qput = re.findall(mqput, ppss[1])
					if len(qput) != 0:
						break

				if len(qput) != 0:
					sby = qput[0]
				else:
					print "question incon " + ppss[0]
					#print ppss[1]
		return sby

	def detectstatement(self, pss):
		sby = None
		for ppss in pss:
			if re.search('with permission.*?i .*? make a statement(?i)', ppss[1]):
				sby = ppss[0]
		if sby:
			print 'statement by ' + sby
			return 'STATEMENT * '
		return None

	def detectajourn(self, pss):
		sby = None
		for ppss in pss:
			if re.search('that this house .*? adjourn(?i)', ppss[1]):
				sby = ppss[0]
		if sby:
			print 'motion by ' + sby
			return 'ADJOURN * '
		return None
		# <i>Motion made, and Question proposed,</i> That this House do now adjourn.&#151;<i>[Joan Ryan.]</i>


	def detectmotion(self, pss):
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
			if re.search('division(?i)', pfss[1]):
				continue
			self.detectqput(pfss[2])
			pref = self.detectstatement(pfss[2])
			if not pref:
				pref = self.detectmotion(pfss[2])
			if not pref:
				pref = self.detectajourn(pfss[2])
			if pref:
				self.pfs[i] = (self.pfs[i][0], pref + self.pfs[i][1], self.pfs[i][2])




	# this gets the adjournment debate out
	#def stripadjourn(self):

	# build into speaker pairs
	# <speaker name="Mrs. Gwyneth Dunwoody  (Crewe and Nantwich)"><font color="#003fcf">Mrs. Gwyneth Dunwoody  (Crewe and Nantwich)</font></speaker>

# main function.
	def __init__(self, fr, sdate):
		self.pfs = []  # set of heading, text pairs
		self.sdate = sdate   # date is used to kill off warnings

		self.pfs = SepSectionsSpeeches(fr)

		self.stripheadings()

		self.qbatches = []
		self.striporalqs()

		self.marktitles()

	def foldwrite(self, fout):
		# write out the oral questions
		for qb in self.qbatches:
			qb.writerep(fout)

		for fss in self.pfs:
			fout.write('\n<h3 align=center><font color="#004f3f">%s</font></h3>\n' % fss[1])

			# question put detection
			qp = self.detectqput(fss[2])
			if qp:
				fout.write('<h4 align=center>Question put: %s</h4>\n' % qp)


			if len(fss[2]) != 0:
				# put folds around this text
				fout.write('<span onclick="cycle(this)" class="phid" pos="first">\n')

				for sp in fss[2]:
					fout.write('<p><speaker name="%s"><font color="#003fcf">%s</font></speaker></p>\n' % (sp[0], sp[0]))
					fout.write(sp[1])

				fout.write('</span><span onclick="cycle(this)" class="pvis" pos="last">\n')
				fout.write('<center>(')
				for i in range(len(fss[2]) / 5):
					fout.write('-')
				fout.write(')</center>\n')
				fout.write('</span>\n')
