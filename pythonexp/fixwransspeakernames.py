#! /usr/bin/python2.3

import sys
import re
import os
import string
from resolvemembernames import memberList

# this filter finds the speakers and replaces with full itendifiers
# <speaker name="Eric Martlew  (Carlisle)"><p>Eric Martlew  (Carlisle)</p></speaker>
knownbadmatches = 'prime minister|solicitor-general|nicholas brown|gareth thomas|lembit|' +\
		  'advocate-general|ainsworth|jonathan shaw|gareth r[.] thomas|multiple times(?i)'

fixsubs = 	[
	( '<B> Alun Michael: For </B>', '<B> Alun Michael: </B> For', 1, '2003-11-17'),
	( '<B> Mr. </B>\s* Shepherd:', '<B> Mr. Shepherd:</B>', 1, '2003-10-23'),
	( '<B> Margaret Becket </B>', '<B> Margaret Beckett </B>', 1, '2003-11-11'),

	( '<B> Yvette Cooper/Ms Rosie Winterton: </B>', '<B> Ms Rosie Winterton: </B>', 1, '2003-05-14'),

	( '<UL><i>Mr. Bradshaw \[holding answer 11 September 2003\]:</i>', \
		'<B>Mr. Bradshaw </B> [holding answer 11 September 2003]:', 1, '2003-09-18'),
	( ' and the Northern Ireland Administration[.]\s*<P></UL>', \
		' and the Northern Ireland Administration. <P>', 1, '2003-09-18'),
	( '<P></UL>\s*<P>\s*\{**con**\}\{**/con**\}<P>\s*<B> Mr. Moss:  (4)</B>', '<p>(4)', 1, '2002-06-10'),

	( '<UL><i>Fiona Mactaggart [holding answer 3 July 2003]:</i>', \
		'<B>Fiona Mactaggart </B> [holding answer 3 July 2003]', 1, '2003-07-07'),
	( '<UL><i>Mr. Bradshaw [holding answer 23 June 2003]</i>:' \
		'<B>Mr. Bradshaw </B> [holding answer 23 June 2003]', 1, '2003-06-24'),
	( '<i>Mr. Bradshaw </i>[holding answer 17 June 2003]:' \
		'<B>Mr. Bradshaw </B> [holding answer 17 June 2003]', 1, '2003-06-18'),
	( '<B> Mr. Bercow: Mr. John Bercow: </B>', '<B> Mr. John Bercow: </B>', 1, '2003-06-03'),
	( '<B> Mr. Drew: Mr. David Drew: </B>', '<B> Mr. David Drew: </B>', 1, '2003-05-01'),



		]

def ApplyFixSubs(finr, sdate):
	for sub in fixsubs:
		if sub[3] == 'all' or sub[3] == sdate:
			res = re.subn(sub[0], sub[1], finr)
			if sub[2] != -1 and res[1] != sub[2]:
				print 'wrong substitutions %d on %s' % (res[1], sub[0])
			finr = res[0]
	return finr

def WransSpeakerNames(fout, finr, sdate):

	finr = ApplyFixSubs(finr, sdate)

	# <B> Mrs. Iris Robinson: </B>
	lspeakerregexp = '<b>.*?</b>\s*?:|<b>.*?</b>'
	ltableregexp = '<table[^>]*>[\s\S]*?</table>'	# these have bolds, so must be separated out
	tableregexp = ltableregexp + '(?i)'

	lregexp = '(%s|%s)(?i)' % (ltableregexp, lspeakerregexp)

	# setup for scanning through the file.
	# we should have a name matching module which gets the unique ids, and
	# takes the full speaker name and date to find a match.
	fs = re.split(lregexp, finr)


	for i in range(len(fs)):
		fss = fs[i]

		if re.match(tableregexp, fss):
			continue

		speakergroup = re.findall('<b>\s*([^:]*):*?([^<:]*)</b>(?i)', fss)
		if not speakergroup:
			continue


		# we have a string in bold
		boldnamestring = string.strip(speakergroup[0][0])

		# trailing text after the colon in the bold speech bit
		if re.search('\S', speakergroup[0][1]):
			fs[i+1] = speakergroup[0][1] + fs[i+1]
			print 'found trailing text to add: ' + fss


		# get rid of blank bold areas
		if not re.search('\S', boldnamestring):
			fs[i] = ''
			continue


		# push the square brackets outside of the boldstring if there is one
		# <B> Mr. Miliband [ </B> <i>holding answer 24 March</i>]:
		sqb = re.findall('^([^\[]*)(\[.*)$', boldnamestring)
		if sqb:
			boldnamestring = string.strip(sqb[0][0])
			fs[i+1] = sqb[0][1] + fs[i+1]


		# try to pull in the question number if preceeding
		# These signify aborted oral questions, and are normally useless and at the start of the page.
		# 27. <B> Mr. Steen: </B>
		if i > 0:
			oqnsep = re.findall('^([\s\S]*?)Q?(\d+[.])\s*?$', fs[i - 1])
			if len(oqnsep) != 0:
				fs[i - 1] = oqnsep[0][0]
				boldnamestring = oqnsep[0][1] + ' ' + boldnamestring

                # remove initial digits and a dot, if any
                robj = re.match(r"(\d*\. )(.*)", boldnamestring)
                deci = None
                if robj:
                    (deci, boldnamestring) = robj.groups()

                # TODO: do something with deci here (it is the "failed
                # oral questions" signifier)

                # match the member to a unique identifier
                (id, reason) = memberList.matchfullname(boldnamestring, sdate)

		# now output what we've decided
                if reason:
			if not re.search(knownbadmatches, reason):
				print reason
        		reason = ' reason="%s"' % (reason)

		fs[i] = '<speaker name="%s" id="%s"%s>%s</speaker>\n' % \
						(boldnamestring, id, reason, boldnamestring)


	# output everything now
	for fss in fs:
		fout.write(fss)
