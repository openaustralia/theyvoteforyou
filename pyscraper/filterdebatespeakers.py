#! /usr/bin/python2.3
# -*- coding: latin-1 -*-

import sys
import re
import os
import string
from resolvemembernames import memberList

from miscfuncs import ApplyFixSubstitutions


fixsubs = 	[
	('<B> Sir Sydney Chapman: I </B>', '<B> Sir Sydney Chapman: </B> I ', 1, '2003-12-09'),
	('<B> Simon Hughes:  \(Southwark', '<B> Simon Hughes  (Southwark', 1, '2003-11-19'),
	('<B> (I wish to revert to a subject that I have raised before: the Agricultural Holdings  \(Scotland\))</B>', '//1', 1, '2003-06-24'),
	("<B> (The Prime Minister's website.*?McCartney\))</B>", '//1', 1, '2003-06-04'),
	( '<B>\("(The registers of political parties)</B>', '//1', 1, '2000-11-29'),
	( '\(Mr. Denis MacShane </B>\s*\)', '(Mr. Denis MacShane) </B>', 1, '2003-05-21'),
	( '] Andy King', ' Andy King', 1, '2003-12-10'),

	( '\(Sir Alan Haselhurst </B>', '(Sir Alan Haselhurst) </B>', 1, '2003-03-25'),
	( '<B> Yvette Cooper: I </B>', '<B> Yvette Cooper: </B> I ', 1, '2003-02-03'),
	( '\(Mr. Nick Raynsford </B>\s*\)', '(Mr. Nick Raynsford) </B>', 1, '2003-01-23'),
	( '<B> (I also have real worries .*?\(Mrs. Dunwoody\))</B>', '\\1', 1, '2003-09-16'),

		]

# 2. <B> Mr. Colin Breed  (South-East Cornwall)</B> (LD):
# <B> Mr. Hutton: </B>


regspeaker = '(?:\d+\. )?<b>[^<]*</b>(?:\s*\((?:con|lab|ld)\))?\s*:?(?i)'
respeakervals = re.compile('(?:(\d+)\. )?<b>([^:<(]*?):?\s*(?:\((.*?)\))?\s*:?\s*</b>(?:\s*\((con|lab|ld)\))?(?i)')

# <B>Division No. 322</B>
redivno = re.compile('<b>division no\. \d+</b>$(?i)')

recomb = re.compile('(%s)' % (regspeaker, ))
remarginal = re.compile('<b>[^<]*</b>')

renonperson = re.compile('(?:Several h|H)on\. Members|Mr\. Speaker')

def FilterDebateSpeakers(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# setup for scanning through the file.
	for fss in recomb.split(text):

		# division number detection (these get through the speaker detection regexp)
		if redivno.match(fss):
			fout.write(fss.encode("latin-1"))
			continue

		# speaker detection
		speakerg = respeakervals.match(fss)
		if speakerg:
			# optional parts of the group
			# we can use oqnum to detect oral questions
			oqnum = speakerg.group(1)
			party = speakerg.group(4)

			spstr = string.strip(speakerg.group(2))
			spstrbrack = speakerg.group(3) # the bracketted phrase

			# filter out the boring cases to see what's missing from this filter.
			if (not renonperson.match(spstr)) and (not re.search('Deputy|General|Minister|Lords|Chairman', spstr)):
				if not memberList.mpnameexists(spstr, sdate):
					if (not spstrbrack) or (not memberList.mpnameexists(spstrbrack, sdate)):
						print ' unmatchable name --- ' + spstr


			# match the member to a unique identifier
			#(id, reason, remadename) = memberList.matchfullname(boldnamestring, sdate)
			spxm = '<speaker name="%s">%s</speaker>\n' % (spstr, spstr)
			fout.write(spxm)
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
		fout.write(fss.encode("latin-1"))

