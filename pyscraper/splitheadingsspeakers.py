#! /usr/bin/python2.3

import sys
import re
import os
import string
import StringIO


# these types of stamps must be available in every question and batch.
# <stamp coldate="2003-11-17" colnum="518W"/>
# <page url="http://www.publications.parliament.uk/pa/cm200102/cmhansrd/vo020522/text/20522w01.htm">

# this class contains the running values for place identification as we scan through the file.
class StampUrl:
	def __init__(self):
		self.stamp = ''
		self.pageurl = ''
		self.majorheading = 'BLANK MAJOR HEADING'
		self.ncid = 0
		self.timestamp = ''

	def UpdateStampUrl(self, text):
		for st in re.findall('(<stamp coldate[^>]*?/>)', text):
			self.stamp = st
		for stp in re.findall('<(page url[^>]*?)/?>', text):
			self.pageurl = '<%s/>' % stp  # puts missing slash back in.
		for st in re.findall('(<stamp time[^>]*?/>)', text):
			self.timestamp = st




# the following class is used to break the text into a list of triples; headings, unspokentext
# (pre-speaker), and list of speaker-pairs.
# where a speaker-pair is speaker and text below it.

# the fixed strings for piecing apart the text
# we need to split off tables because they often contain a heading type in them.
regsection1 = '<h\d><center>.*?</center></h\d>'
regsection2 = '<h\d align=center>.*?</h\d>'
regsection3 = '<center><b>.*?</b></center>'
regspeaker = '<speaker [^>]*>.*?</speaker>'
regtable = '<table[^>]*>[\s\S]*?</table>'	# these have centres, so must be separated out

recomb = re.compile('(%s|%s|%s|%s|%s)(?i)' % (regsection1, regsection2, regsection3, regspeaker, regtable))

retableval = re.compile('(%s)(?i)' % regtable)
respeakerval = re.compile('<speaker ([^>]*)>.*?</speaker>')
resectiont1val = re.compile('<h\d><center>\s*(.*?)\s*</center></h\d>(?i)')
resectiont2val = re.compile('<h\d align=center>\s*(.*?)\s*</h\d>(?i)')
resectiont3val = re.compile('<center><b>(.*?)</b></center>(?i)')


class SepHeadText:
	def EndSpeech(self):
		sptext = string.join(self.textl, '')
		if self.speaker != 'No one':
			self.shspeak.append((self.speaker, sptext))
			if re.match('(?:<[^>]*?>|\s)*$', sptext):
				print 'Speaker with no text ' + self.speaker
				#print sptext
				#print self.unspoketext
				print self.heading

		elif not self.shspeak:
			self.unspoketext = sptext
		else:
			raise Exception, 'logic error in EndSpeech'

		self.speaker = 'No one'
		self.textl = [ ]

	def EndHeading(self, nextheading):
		self.EndSpeech()
		if (self.heading == 'Initial') and self.shspeak:
			print 'Speeches without heading'

		# concatenate unspoken text with the title if it's a dangle outside heading
		if not re.match('(?:<[^>]*?>|\s)*$', self.unspoketext):
			gho = re.match('\s*(.*?)(?:\s|<p>)*$(?i)', self.unspoketext)
			if gho:
				self.heading = self.heading + ' ' + gho.group(1)
				self.unspoketext = ''

		# push block into list
		self.shtext.append((self.heading, self.unspoketext, self.shspeak))

		self.heading = nextheading
		self.unspoketext = ''	# for holding colstamps
		self.shspeak = [ ]


	def __init__(self, text):

		# this makes a list of pairs of headings and their following text
		self.shtext = [] # return value

		self.heading = 'Initial'
		self.shspeak = []
		self.unspoketext = ''

		self.speaker = 'No one'
		self.textl = [ ]

		for fss in recomb.split(text):

			# stick tables back into the text
			if retableval.match(fss):
				self.textl.append(fss)
				continue

			# recognize a speaker type
			gspeaker = respeakerval.match(fss)
			if gspeaker:
				self.EndSpeech()
				self.speaker = gspeaker.group(1)
				continue

			# recognize a heading instance
			gheading = resectiont1val.match(fss)
			if not gheading:
				gheading = resectiont2val.match(fss)
			if not gheading:
				gheading = resectiont3val.match(fss)
			if gheading:
				if not gheading.group(1):
					print 'empty heading following: ' + self.heading

				self.EndHeading(gheading.group(1))
				continue


			# more plain text; throw back into the pot.
			if recomb.match(fss):
				print fss
				raise Exception, ' vals matches not general enough '
			self.textl.append(fss)

		self.EndHeading('No more')

# main function.
def SplitHeadingsSpeakers(text):
	sht = SepHeadText(text)
	return sht.shtext

