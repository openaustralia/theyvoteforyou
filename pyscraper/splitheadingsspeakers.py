#! /usr/bin/python2.3

import sys
import re
import os
import string
import StringIO


# these types of stamps must be available in every question and batch.
# <stamp coldate="2003-11-17" colnum="518W"/>
# <page url="http://www.publications.parliament.uk/pa/cm200102/cmhansrd/vo020522/text/20522w01.htm">
# <stamp aname="40205-01_sbhd0"/>

# this class contains the running values for place identification as we scan through the file.
class StampUrl:
	def __init__(self, lsdate):
		self.sdate = lsdate

		# url of this record
		self.pageurl = ''
		# column number stamp
		self.stamp = ''
		# last time stamp
		self.timestamp = ''
		# last <a name=""> html code, for identifying major headings
		self.aname = ''

        def __repr__(self):
                col = re.search('colnum="(.*?)"', self.stamp).group(1)
                anchor = re.search('aname="(.*?)"', self.aname).group(1)
                return "<< StampURL date:%s col:%s aname:%s >>" % (self.sdate, col, anchor)

	# extract the stamp codes from the text, and return the glued together text.
	def UpdateStampUrl(self, text):
		# remove the stamps from the text, checking for cases where we can glue back together.
		sp = re.split('(<stamp [^>]*>|<page url[^>]*>)', text)
		for i in range(len(sp)):
			if re.match('<stamp [^>]*>', sp[i]):
				if re.match('<stamp time[^>]*>', sp[i]):
					self.timestamp = sp[i]
				elif re.match('<stamp aname[^>]*>', sp[i]):
					self.aname = sp[i]
				else:
					self.stamp = sp[i]
				sp[i] = ''

			elif re.match('<page url[^>]*>', sp[i]):
				self.pageurl = sp[i]
				sp[i] = ''

		# stick everything back together
		return string.join(sp, '')


	# extract a url and hash link to position in the web.
	def GetUrl(self):
		spurl = re.match('<page url="(.*?)"/>', self.pageurl).group(1)
		anamem = re.match('<stamp aname="(.*?)"/>', self.aname)
		if anamem:
			saname = anamem.group(1)
			return '%s#%s' % (spurl, saname)
		else:
			return spurl




# the following class is used to break the text into a list of triples; headings, unspokentext
# (pre-speaker), and list of speaker-pairs.
# where a speaker-pair is speaker and text below it.

# the fixed strings for piecing apart the text
# we need to split off tables because they often contain a heading type in them.
regsection1 = '<h\d><center>.*?</center></h\d>'
regsection2 = '<h\d align=center>.*?</h\d>'
regsection3 = '<center><b>.*?</b></center>'
regsection4 = '<p>\s*<center>.*?</center><p>'
regspeaker = '<speaker [^>]*>.*?</speaker>'
regtable = '<table[^>]*>[\s\S]*?</table>'	# these have centres, so must be separated out

recomb = re.compile('(%s|%s|%s|%s|%s|%s)(?i)' % (regtable, regspeaker, regsection1, regsection2, regsection3, regsection4))

retableval = re.compile('(%s)(?i)' % regtable)
respeakerval = re.compile('<speaker ([^>]*)>.*?</speaker>')
resectiont1val = re.compile('<h\d><center>\s*(.*?)\s*</center></h\d>(?i)')
resectiont2val = re.compile('<h\d align=center>\s*(.*?)\s*</h\d>(?i)')
resectiont3val = re.compile('<center><b>(.*?)</b></center>(?i)')
resectiont4val = re.compile('<p>\s*<center>(.*?)</center><p>(?i)')

# These aren't actually headings, even though they are <H4><center>
renotheading = re.compile('>\s*(The .* was asked\s*&#151;)\s*<')
# catch cases of the previous regexp not being broad enough
renotheadingmarg = re.compile('asked')

class SepHeadText:
	def EndSpeech(self):
		sptext = string.join(self.textl, '')
		if self.speaker != 'No one':
			self.shspeak.append((self.speaker, sptext))
                        # Specifically "unknown" speakers e.g. "Several hon members rose" don't
                        # have text in their "speech" bit.
			if re.match('(?:<[^>]*?>|\s)*$', sptext) and not re.match('speakerid="unknown"', self.speaker):
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

			# recognize a heading instance from the four kinds
			gheading = resectiont1val.match(fss)
			if not gheading:
				gheading = resectiont2val.match(fss)
			if not gheading:
				gheading = resectiont3val.match(fss)
			if not gheading:
				gheading = resectiont4val.match(fss)

			# we have matched a heading thing
			if gheading:
				if not gheading.group(1):
					# print 'ignored heading tag containing no text following: ' + self.heading
					continue

				# there's a negative regexp match (for "The ... was asked - " which
				# isn't a heading even though it looks like one).  Check we don't
				#  match it.
				negativematch = renotheading.search(fss)
				if not negativematch:
					if renotheadingmarg.search(fss):
						raise Exception, '"The ... was asked" match not broad enough: %s' % fss

					# we are definitely a heading
					self.EndHeading(gheading.group(1))
					continue

				#print "renotheading matched ", fss
				fss = negativematch.group(1)


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

