#! /usr/bin/python2.3
# -*- coding: latin-1 -*-

import sys
import re
import os
import string
from resolvemembernames import memberList


from miscfuncs import ApplyFixSubstitutions

# this filter finds the speakers and replaces with full itendifiers
# <speaker name="Eric Martlew  (Carlisle)"><p>Eric Martlew  (Carlisle)</p></speaker>
knownbadmatches = 'prime minister|solicitor-general|nicholas brown|gareth thomas|lembit|' +\
		  'advocate-general|ainsworth|jonathan shaw|gareth r[.] thomas|multiple times(?i)'

fixsubs = 	[
	( '<B> Mr. </B>\s* Shepherd:', '<B> Mr. Shepherd:</B>', 1, '2003-10-23'),
	( '<B> Margaret Becket </B>', '<B> Margaret Beckett </B>', 1, '2003-11-11'),

	( '<B> Yvette Cooper/Ms Rosie Winterton: </B>', '<B> Ms Rosie Winterton: </B>', 1, '2003-05-14'),

	( '<UL><i>Mr. Bradshaw \[holding answer 11 September 2003\]:</i>', \
		'<B>Mr. Bradshaw </B> [holding answer 11 September 2003]:', 1, '2003-09-18'),
	( ' and the Northern Ireland Administration[.]\s*<P></UL>', \
		' and the Northern Ireland Administration. <P>', 1, '2003-09-18'),
	( '<P></UL>\s*<P>\s*\{\*\*con\*\*\}\{\*\*/con\*\*\}<P>\s*<B> Mr. Moss:  \(4\)</B>', \
							'<p>(4)', 1, '2002-06-10'),

	( '<UL><i>Fiona Mactaggart \[holding answer 3 July 2003\]:</i>', \
		'<B>Fiona Mactaggart </B> [holding answer 3 July 2003]', 1, '2003-07-07'),
	( '<UL><i>Mr. Bradshaw \[holding answer 23 June 2003\]</i>:', \
		'<B>Mr. Bradshaw </B> [holding answer 23 June 2003]', 1, '2003-06-24'),
	( '<i>Mr. Bradshaw </i>\[holding answer 17 June 2003\]:', \
		'</ul><B>Mr. Bradshaw </B> [holding answer 17 June 2003]', 1, '2003-06-18'),
	( '<UL><i>(Mr. Morley) (\[holding answer 22 May 2003\]):</i>', \
		'<B>\\1</B> \\2', 1, '2003-06-03'),
	( '<UL><i>(Mr. Morley) (\[holding answer 9 April 2003\]):</i>', \
		'<B>\\1</B> \\2', 1, '2003-05-08'),
	( '<UL>(Mr. MacShane):', '<B>\\1</B>', 1, '2003-05-07'),
	( '<UL>(Mr. Morley):', '<B>\\1</B>', 1, '2003-04-28'),
	( '<UL>(Beverley Hughes):', '<B>\\1</B>', 1, '2003-04-10'),

	( '<UL>\(1\) (Tim Loughton): (To ask the Deputy Prime Minister) (how many times he has been in residence at Dorneywood since June 2001; and on what dates;  \[97476\])', '<B>\\1</B> \\2 (1) \\3 <p><UL>', 1, '2003-03-28'),
	( '<UL>Mr. Denham:', '<B>Mr. Denham</B>', 1, '2003-03-06'),


	( '<B> Mr. Bercow: Mr. John Bercow: </B>', '<B> Mr. John Bercow: </B>', 1, '2003-06-03'),
	( '<B> Mr. Drew: Mr. David Drew: </B>', '<B> Mr. David Drew: </B>', 1, '2003-05-01'),
	( '<B> Matthew Taylor: Matthew Taylor: </B>', '<B> Matthew Taylor: </B>', 1, '2003-07-02'),

	( '</B>\s*\(Leeds, North-West\):', ' (Leeds, North-West) </B>', 1, '2003-09-15'),

	( '<TR valign=top><TD><FONT SIZE=-1>\s*<P>\s*<page', '</TABLE>\n<page', 1, '2002-07-24'),
	( '<i>Mr. Ingram \[holding answer 4 December 2003\]:</i>', '<B>Mr. Ingram:</B> [holding answer 4 December 2003]', 1, '2003-12-08' ),
	( '</B>\s*ask', '</B> To ask', 1, '2003-12-08'),
	( '<UL>Paul Goggins:([^<]*)<P></UL>', '<B>Paul Goggins:</B> \\1', 1, '2003-11-19'),
	( '\): To ask', ' To ask', 1, '2003-05-06'),

	# completely delete an answer that refers to the next response as answer
	( '<B> Mr. Jamieson </B>[\s\S]*\[114072\]\.', '', 1, '2003-06-03'),

	( '</UL>\s*<P>\s*<P>\s*<B>  Barbara Follett </B>\s*\(4\)', '<P>(4)', 1, '2003-02-06'),
	( '<UL>\(5\)', '(5)', 1, '2003-02-06'),
	( '<UL>(We are intending to have)', '<B>Beverley Hughes</B> \\1', 1, '2003-01-29'), 

	# this removes a bogus y-dotdot character that the latin-1 encoding can't deal with
	( '</sup> .38-0030</FONT>', '</sup> 38-0030</FONT>', 1, '2003-09-17'),
	( 'credit of .45 per', 'credit of 45 per', 1, '2002-12-02'),
	( 'units of .5,000 or more', 'units of 5,000 or more', 1, '2002-11-26'),
	( 'available .23 million', 'available 23 million', 1, '2002-11-26'),
	( 'approved a .4 million', 'approved a 4 million', 1, '2002-11-26'),
	( '<FONT SIZE=-1>[^\d]0\.3\s*</FONT>', '<FONT SIZE=-1>0.3</FONT>', 2, '2002-10-22'), # note the 2; the problem is a dropped dot



 		]

def FilterWransSpeakers(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# <B> Mrs. Iris Robinson: </B>
	lspeakerregexp = '<b>.*?</b>\s*?:|<b>.*?</b>'
	ltableregexp = '<table[^>]*>[\s\S]*?</table>'	# these have bolds, so must be separated out
	tableregexp = ltableregexp + '(?i)'

	lregexp = '(%s|%s)(?i)' % (ltableregexp, lspeakerregexp)

	# setup for scanning through the file.
	fs = re.split(lregexp, text)

	for i in range(len(fs)):
		fss = fs[i]

		if re.match(tableregexp, fss):
			continue

		speakerg = re.findall('<b>\s*([^:]*):*?([^<:]*)</b>(?i)', fss)
		if not speakerg:
			continue

		# we have a string in bold
		boldnamestring = string.strip(speakerg[0][0])

		# trailing text after the colon in the bold speech bit
		if re.search('\S', speakerg[0][1]):
			fs[i+1] = speakerg[0][1] + fs[i+1]


		# push the square brackets outside of the boldstring if there is one
		# <B> Mr. Miliband [ </B> <i>holding answer 24 March</i>]:
		sqb = re.findall('^([^\[]*)(\[.*)$', boldnamestring)
		if sqb:
			boldnamestring = string.strip(sqb[0][0])
			fs[i+1] = sqb[0][1] + fs[i+1]

		# get rid of blank bold strings
		if not re.search('\S', boldnamestring):
			fs[i] = ''
			continue

		# try to pull in the question number if preceeding
                # These signify aborted oral questions, and are normally
                # useless and at the start of the page.
		# 27. <B> Mr. Steen: </B>
		if i > 0:
			oqnsep = re.findall('^([\s\S]*?)Q?(\d+\.)\s*?$', fs[i-1])
			if oqnsep:
				fs[i-1] = oqnsep[0][0]
				boldnamestring = oqnsep[0][1] + ' ' + boldnamestring

		# take out the initial digits and a dot which we may have just put in
		# (although sometimes it would have already been there)
		robj = re.match(r"(\d*\. )(.*)$", boldnamestring)
		deci = None
		if robj:
			(deci, boldnamestring) = robj.groups()

                # TODO: do something with deci here (it is the "failed
                # oral questions" signifier)

                # match the member to a unique identifier
                (id, reason, remadename) = memberList.matchfullname(boldnamestring, sdate)

		# now output what we've decided
                if reason:
			if not re.search(knownbadmatches, reason):
				print reason
        		reason = ' reason="%s"' % (reason)
                if remadename:
        		remadename = ' displayname="%s"' % (remadename)

		# put record in this place
		fs[i] = '<speaker name="%s" id="%s"%s%s>%s</speaker>\n' % \
						(boldnamestring, id, reason, remadename, boldnamestring)

	# scan through everything and output it into the file
	for fss in fs:
		try:
			fout.write(fss.encode("latin-1")) # For accent in "Siôn Simon"
		except:
			print ' --- latin-1 encoding failed --- '

			print fss
			for c in fss:
				print c,
				c.encode("latin-1")
			sys.exit()
