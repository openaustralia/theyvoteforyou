#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap
# -*- coding: latin-1 -*-

import sys
import re
import os
import string
from resolvemembernames import memberList
from splitheadingsspeakers import StampUrl

from miscfuncs import ApplyFixSubstitutions
from contextexception import ContextException


# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = [

        ('23. (Mr. David Rendel)', '\\1', 1, '2003-06-30'),

        ('<B> Caroline Flint\): </B>', '<B> Caroline Flint: </B>', 1, '2003-07-14'),
        ('<B> Ms King </B>', '<B> Oona King </B>', 1, '2003-09-11'),

	('<B> Simon Hughes:  \(Southwark', '<B> Simon Hughes  (Southwark', 1, '2003-11-19'),
	( '<B>\("(The registers of political parties)</B>', '//1', 1, '2000-11-29'),
	( '\(Mr. Denis MacShane </B>\s*\)', '(Mr. Denis MacShane) </B>', 1, '2003-05-21'),

	( '\(Sir Alan Haselhurst </B>', '(Sir Alan Haselhurst) </B>', 1, '2003-03-25'),
	( '<B> Yvette Cooper: I </B>', '<B> Yvette Cooper: </B> I ', 1, '2003-02-03'),
	( '\(Mr. Nick Raynsford </B>\s*\)', '(Mr. Nick Raynsford) </B>', 1, '2003-01-23'),

        ( '(<B> Mr. Adrian Bailey  \()Blaby(\):</B> )', '\\1West Bromwich West\\2', 1, '2003-10-30'),

        ( '(<B> Ms Hazel Blears)\)', '\\1', 1, '2003-06-16'),
        ( 'Mr. Melanie Leigh', 'Mr. Leigh', 1, '2003-06-13'),
        ( 'The Chairman: Order', '<B>The Chairman:</B> Order', 1, '2003-06-05'),
        ( '(<B> Mr\. John Hutton)\)', '\\1', 1, '2003-06-03'),
        ( '(<B> Mr Jamieson)\)', '\\1', 1, '2003-05-16'),
        ( '(The Parliamentary Under-Secretary of State for Defence \()<P>\s*?<P>\s*?<P>(\s*?<stamp aname="30512-01_spnew16"/><B> )(Dr. Lewis Moonie\)\: </B>)', \
                '\\2\\1\\3', 1, '2003-05-12'),
        ( '(The Parliamentary Under-Secretary of State for the Home Department \()<P>\s*?<P>\s*?<P>(\s*?<stamp aname="30428-02_spnew0"/><B> )(Hilary Benn\)\: </B>)', \
                '\\2\\1\\3', 1, '2003-04-28'),
        ( '(The Parliamentary Under-Secretary of State for the Home Department \()<P>\s*?<P>\s*?<P>(\s*?<stamp aname="30428-04_spnew0"/><B> )(Mr\. Bob Ainsworth\)\: </B>)', \
                '\\2\\1\\3', 1, '2003-04-28'),
        ( '(The Parliamentary Under-Secretary of State for the Home Department \()<P>\s*?<P>\s*?<P>(\s*?<stamp aname="30428-05_spnew7"/><B> )(Mr\. Bob Ainsworth\)\: </B>)', \
                '\\2\\1\\3', 1, '2003-04-28'),
        ( '(The Parliamentary Under-Secretary of State for the Home Department \()<P>\s*?<P>\s*?<P>(\s*?<stamp aname="30324-04_spnew11"/><B> )(Hilary Benn\)\: </B>)', \
                '\\2\\1\\3', 1, '2003-03-24'),
        ( '(The Minister for Policing, Crime Reduction and Community Safety \()<P>\s*?<P>\s*?<P>(\s*?<stamp aname="30224-04_spnew4"/><B> )(Mr\. John Denham\)\: </B>)', \
                '\\2\\1\\3', 1, '2003-02-24'),

        ( '(<B> Mr\. Spellar)\)', '\\1', 1, '2003-03-31'),

        # wrong constituency in debates
        ( 'Sir Archy Kirkwood  \(Brecon and Radnorshire\)', 'Sir Archy Kirkwood (Roxburgh and Berwickshire)', 1, '2003-06-26'),

]

# 2. <B> Mr. Colin Breed  (South-East Cornwall)</B> (LD):
# <B> Mr. Hutton: </B>
# 2. <stamp aname="40205-06_para4"/><B> Mr. Colin Breed</B>:

# Q4.  [161707]<a name="40317-03_wqn5"><B> Mr. Andy Reed  (Loughborough)</B>

parties = "|".join(map(string.lower, memberList.partylist())) + "|uup|ld|dup"
# Rough match:
recomb = re.compile('((?:Q?\d+\.\s*)?(?:\[\d+\]\s*)?(?:<stamp aname=".*?"/>)?<b>[^<]*</b>(?:\s*\((?:%s)\))?\s*:?)(?i)' % parties)
# Specific match:
# Notes - sometimes party appears inside bold tags, so we match and throw it away on either side
respeakervals = re.compile('(?:Q?(\d+)\.\s*)?(\[\d+\]\s*)?(<stamp aname=".*?"/>)?<b>\s*(?:Q?(\d+)\.)?([^:<(]*?):?\s*(?:\((.*?)\))?(?:\s*\((%s)\))?\s*:?\s*</b>(?:\s*\((%s)\))?(?i)' % (parties, parties))

# <B>Division No. 322</B>
redivno = re.compile('<b>division no\. \d+</b>$(?i)')

remarginal = re.compile('<b>[^<]*</b>(?i)')

def FilterDebateSpeakers(fout, text, sdate, typ):

	if typ == "westminhall":
		depspeakerrg = re.search("\[(.*?) in the Chair\]", text)
		if not depspeakerrg:
			print "can't find the [... in the Chair] phrase"
		depspeaker = depspeakerrg.group(1)


	# old style fixing (before patches existed)
	if typ == "debate":
		text = ApplyFixSubstitutions(text, sdate, fixsubs)

        # for error messages
	stampurl = StampUrl(sdate)

	# setup for scanning through the file.
	for fss in recomb.split(text):
		stampurl.UpdateStampUrl(fss)
                #print fss
                #print "--------------------"

		# division number detection (these get through the speaker detection regexp)
		if redivno.match(fss):
			fout.write(fss.encode("latin-1"))
			continue

		# speaker detection
		speakerg = respeakervals.match(fss)
		if speakerg:
			# optional parts of the group
			# we can use oqnum to detect oral questions
			anamestamp = speakerg.group(3) or ""
			oqnum = speakerg.group(1)
			if speakerg.group(4):
				assert not oqnum
				oqnum = speakerg.group(4)
			if oqnum:
				oqnum = ' oral-qnum="%s"' % oqnum
			else:
				oqnum = ""

			# the preceding square bracket qnums
			sqbnum = speakerg.group(2) or ""

			party = speakerg.group(7)

			spstr = string.strip(speakerg.group(5))
			spstrbrack = speakerg.group(6) # the bracketted phrase

			# do quick substitution for dep speakers in westminster hall
			if typ == "westminhall" and re.search("deputy[ \-]speaker(?i)", spstr) and not spstrbrack:
				#spstrbrack = depspeaker
				spstr = depspeaker

			# match the member to a unique identifier and displayname
			try:
                                #print "spstr", spstr, ",", spstrbrack
				result = memberList.matchdebatename(spstr, spstrbrack, sdate)
			except Exception, e:
				# add extra stamp info to the exception
				raise ContextException(str(e), stamp=stampurl, fragment=fss)

			# put record in this place
			spxm = '%s<speaker %s%s>%s</speaker>\n%s' % (anamestamp, result.encode("latin-1"), oqnum, spstr, sqbnum)
			fout.write(spxm)
			continue


		# nothing detected
		# check if we've missed anything obvious
		if recomb.match(fss):
			raise ContextException('regexpvals not general enough', fragment=fss, stamp=stampurl)
		if remarginal.search(fss):
			raise ContextException(' marginal speaker detection case: %s' % remarginal.search(fss).group(0), fragment=fss, stamp=stampurl)

		# this is where we phase in the ascii encoding
		fout.write(fss)

