#! /usr/bin/python2.3
# -*- coding: latin-1 -*-

import sys
import re
import os
import string
from resolvemembernames import memberList

from miscfuncs import ApplyFixSubstitutions


# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = 	[
	( '(<B> Baroness Barker:)( My .*?)</B>', '\\1</B>\\2', 1, '2004-01-07'),

	# this is special to grand committee section
	#( 'Committees\):', 'Committees:', 1, '2004-02-03'),
]

# <B> Baroness Anelay of St Johns: </B>


regcentrebold = '<center><b>[^<]*</b></center>(?i)'
recentrebold = re.compile('<center><b>[^<]*</b></center>$(?i)')

regspeaker = '<b>[^<]*</b>(?i)'
respeakervals = re.compile('<b>\s*([^:<(]*?)\s*(?:\(([^<):]*)\))?:?\s*</b>(?i)')

# <B>Division No. 322</B>

# centred statements come first, so they will take priority
recomb = re.compile('(%s|%s)' % (regcentrebold, regspeaker, ))
remarginal = re.compile('<b>[^<]*</b>(?i)')

regenericspeak = re.compile('(?:The (?:Deputy )?Chairman(?: of Committees)?|Noble Lords|A Noble Lord)$')
retitlesep = re.compile('(Lord|Baroness|Viscount|Earl|The Earl of|The Lord Bishop of|The Duke of|The Countess of|Lady)\s*(.*)$')


def LordsFilterSpeakers(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# setup for scanning through the file.
	for fss in recomb.split(text):


		if recentrebold.match(fss):
			fout.write(fss)
			continue

		# speaker detection
		speakerg = respeakervals.match(fss)
		if speakerg:

			# optional parts of the group
			# we sometimes have titles given names

			jobpos = ''
			spstr = speakerg.group(1)
			if speakerg.group(2):
				jobpos = spstr
				spstr = speakerg.group(2)

			if regenericspeak.match(spstr):
				if jobpos:
					print 'nongeneric match: %s' % fss

			else:
				titsep = retitlesep.match(spstr)
				if not titsep:
					print spstr

			# match the member to a unique identifier and displayname
			result = spstr #memberList.matchdebatename(spstr, '', sdate)

			# put record in this place
			spxm = '<speaker %s>%s</speaker>\n' % (result, spstr)
			fout.write(spxm) # For accents in names
			continue



		# nothing detected
		# check if we've missed anything obvious
		if recomb.match(fss):
			print fss
			raise Exception, ' regexpvals not general enough '
		if remarginal.search(fss):
			print ' marginal speaker detection case '
			print remarginal.search(fss).group(0)
			print fss
			sys.exit()

		# this is where we phase in the ascii encoding
		fout.write(fss)






















































































