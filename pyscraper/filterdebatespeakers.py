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
        ( '(<B> Mr. Prisk)( rose&#151; )(</B>)', '\\1\\3\n<I>\\2</I>', 1, '2004-01-06'),

        ( '(<B>The Advocate-General)(:</B>)', '\\1 for Scotland\\2', 7, '2004-02-10'),
        ( '(<B>The Advocate-General)(:</B>)', '\\1 for Scotland\\2', 5, '2004-01-13'),
        ( '(<B>The Advocate-General)(:</B>)', '\\1 for Scotland\\2', 4, '2003-12-02'),
        ( '(<B>The Advocate-General)(:</B>)', '\\1 for Scotland\\2', 6, '2003-10-28'),
        ( '(<B>The Advocate-General)(:</B>)', '\\1 for Scotland\\2', 6, '2003-09-09'),

        ( '(<B> Mr. Blunkett:)( I )(</B>)', '\\1\\3\\2', 1, '2003-12-17'),
        ( '(<B> )(25. )(Mr. Gordon Prentice  \(Pendle\):</B>)', '\\2\\1\\3', 1, '2003-11-10'),
        ( '(<B> Several hon. Members)( rose&#151; )(</B>)', '\\1\\3\n<I>\\2</I>', 1, '2003-11-10'),
        ( '(<B> Mr. Adrian Bailey  \()Blaby(\):</B> )', '\\1West Bromwich West\\2', 1, '2003-10-30'),
]

# 2. <B> Mr. Colin Breed  (South-East Cornwall)</B> (LD):
# <B> Mr. Hutton: </B>
# 2. <stamp aname="40205-06_para4"/><B> Mr. Colin Breed</B>:

parties = "|".join(map(string.lower, memberList.partylist())) + "|uup"
regspeaker = '(?:\d+\. )?(?:<stamp aname=".*?"/>)?<b>[^<]*</b>(?:\s*\((?:' + parties + ')\))?\s*:?(?i)'
respeakervals = re.compile('(?:(\d+)\. )?(<stamp aname=".*?"/>)?<b>([^:<(]*?):?\s*(?:\((.*?)\))?\s*:?\s*</b>(?:\s*\((' + parties + ')\))?(?i)')

# <B>Division No. 322</B>
redivno = re.compile('<b>division no\. \d+</b>$(?i)')

recomb = re.compile('(%s)' % (regspeaker, ))
remarginal = re.compile('<b>[^<]*</b>(?i)')

def FilterDebateSpeakers(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# setup for scanning through the file.
	for fss in recomb.split(text):

		# division number detection (these get through the speaker detection regexp)
		if redivno.match(fss):
			fout.write(fss.encode("latin-1"))
			continue

#                print "fss=",fss
#                print "######################"

		# speaker detection
		speakerg = respeakervals.match(fss)
		if speakerg:
			# optional parts of the group
			# we can use oqnum to detect oral questions
			oqnum = speakerg.group(1)
			anamestamp = speakerg.group(2)
			party = speakerg.group(5)

			spstr = string.strip(speakerg.group(3))
			spstrbrack = speakerg.group(4) # the bracketted phrase

			# match the member to a unique identifier and displayname
			result = memberList.matchdebatename(spstr, spstrbrack, sdate)

			# put record in this place
			spxm = '<speaker %s>%s</speaker>\n' % (result, spstr)
                        if anamestamp:
                            spxm = anamestamp + spxm
			fout.write(spxm.encode("latin-1")) # For accents in names
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

