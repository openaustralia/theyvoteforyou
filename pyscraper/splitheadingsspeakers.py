#! /usr/bin/python2.3

import sys
import re
import os
import string
import StringIO


# this breaks the text into a list of triples; headings, unspokentext
# (pre-speaker), and list of speaker-pairs.
# where a speaker-pair is speaker and text that was said.

class SepHeadText:
	def EndSpeech(self):
		if self.speaker != 'No one':
			self.shspeak.append((self.speaker, self.text))
			if re.match('(?:<[^>]*?>|\s)*$', self.text):
				print 'Speaker with no text'
		elif not self.shspeak:
			self.unspoketext = self.text
		else:
			raise Exception, 'logic error in EndSpeech'

		self.speaker = 'No one'
		self.text = ''

	def EndHeading(self, nextheading):
		self.EndSpeech()
		if (self.heading == 'Initial') and (len(self.shspeak) != 0):
			print 'Speeches without heading'

		# concatenate unspoken text with the title if it's a dangle outside heading
		if not re.match('(?:<[^>]*?>|\s)*$', self.unspoketext):
			ho = re.findall('^\s*(.*?)(?:\s|<p>)*$(?i)', self.unspoketext)
			if ho:
				self.heading = self.heading + ' ' + ho[0]
				self.unspoketext = ''
			else:
				print 'text without speaker'
				print self.unspoketext

		# push block into list
		self.shtext.append((self.heading, self.unspoketext, self.shspeak))

		self.heading = nextheading
		self.unspoketext = ''	# for holding colstamps
		self.shspeak = []


	def __init__(self, text):

		# the fixed strings for piecing apart the text
		# we need to split off tables because they often contain a heading type in them.
		lsectionregexp = '<h\d><center>.*?</center></h\d>|<h\d align=center>.*?</h\d>'
		lspeakerregexp = '<speaker [^>]*>.*?</speaker>'
		ltableregexp = '<table[^>]*>[\s\S]*?</table>'	# these have centres, so must be separated out

		lregexp = '(%s|%s|%s)(?i)' % (lsectionregexp, lspeakerregexp, ltableregexp)

		tableregexp = ltableregexp + '(?i)'
		speakerregexp = '<speaker ([^>]*)>.*?</speaker>'
		sectionregexp1 = '<center>\s*(.*?)\s*</center>(?i)'
		sectionregexp2 = '<h\d align=center>\s*(.*?)\s*</h\d>(?i)'

		fs = re.split(lregexp, text)

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

				self.EndHeading(headinggroup[0])
				continue


			if self.text != '':
				self.text = self.text + fss
			else:
				self.text = fss

		self.EndHeading('No more')


# main function.
def SplitHeadingsSpeakers(text):
	sht = SepHeadText(text)
	return sht.shtext

