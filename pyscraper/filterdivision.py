#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from resolvemembernames import memberList
from parlphrases import parlPhrases
from miscfuncs import FixHTMLEntities

# it's possible we want to make this a class, like with speeches.
# so that it sits in our list easily.

sionsm = "Sio\(r\)n|Sio\[circ\]n"
fullnm = "([ \w\-'#&;]*), ([ \w.#&;]*?|%s)(?:[ \.]rh)?" % sionsm
constnm = "(?:(?:<i>|\()+([ \w&',.\-]*)(?:\)|</i>)+)"
reflipname = re.compile("%s\s*%s?$" % (fullnm, constnm))

def MpList(fsm, vote, sdate):
	res = [ ]
	pfss = ''
	for fss in fsm:

		# break up concattenated lines
		# Beresford, Sir PaulBlunt, Crispin

		while re.search('\S', fss):
			regsep = re.search('(.*?,.*?(?:[a-z]|</i>|\.|\)))([A-Z&].*?,.*)$', fss)
			if regsep:
				fssf = regsep.group(1)
				fss = regsep.group(2)
			else:
				fssf = fss
				fss = ''

			# check alphabetical - but "rh" and so on confound so don't bother
			#if pfss and (pfss > fssf):
			#	print pfss, fssf
			#	raise Exception, ' out of alphabetical order %s and %s' % (pfss, fssf)
			#pfss = fssf

			# fliprount the name
			# Bradley, rh Keith <i>(Withington)</i>
			# Simon, Sio(r)n <i>(Withington)</i>
			ginp = reflipname.match(fssf)
			if ginp:
				fnam = '%s %s' % (ginp.group(2), ginp.group(1))
				cons = ginp.group(3)
			else:
				raise Exception, "No reverse name match (filterdivision): %s" % fssf
				fnam = fssf;

                        #print "fss ", fssf
			(mpid, remadename, remadecons) = memberList.matchfullnamecons(fnam, cons, sdate, alwaysmatchcons = False)
			res.append('\t<mpname id="%s" vote="%s">%s</mpname>' % (mpid, vote, FixHTMLEntities(fssf)))

	return res

# this pulls out two tellers with the and between them.
def MpTellerList(fsm, vote, sdate):
	res = [ ]
	for fss in fsm:
		while fss:
			gftell = re.match('\s*(?:and )?([ \w.\-]*?)(?: and(.*))?\s*$', fss)
			fssf = gftell.group(1)
			fss = gftell.group(2)

			if len(res) >= 2:
				print fsm
				raise Exception, ' too many tellers '

			(mpid, remadename, remadecons) = memberList.matchfullnamecons(fssf.strip(), None, sdate)
			res.append('\t<mpname id="%s" vote="%s" teller="yes">%s</mpname>' % (mpid, vote, FixHTMLEntities(fssf)))

	return res


# this splitting up isn't going to deal with some of the bad cases in 2003-09-10
def FilterDivision(qs):

	# the intention is to splice out the known parts of the division
	fs = re.split('\s*(?:<br>|<p>|\n)\s*(?i)', qs.text)

	# extract the positions of the key statements
	statem = [ 'AYES', 'Tellers for the Ayes:', 'NOES', 'Tellers for the Noes:', 'Question accordingly.*' ]
	istatem = [ -1, -1, -1, -1, -1 ]

	for i in range(len(fs)):
		for si in range(5):
			if re.match(statem[si], fs[i]):
				if istatem[si] != -1:
					print '--------------- ' + fs[i]
					raise Exception, ' already set '
				istatem[si] = i


	mpayes = [ ]
	mptayes = [ ]
	mpnoes = [ ]
	mptnoes = [ ]

	if (istatem[0] < istatem[1]) and (istatem[0] != -1) and (istatem[1] != -1):
		mpayes = MpList(fs[istatem[0]+1:istatem[1]], 'aye', qs.sdate)
	if (istatem[2] < istatem[3]) and (istatem[2] != -1) and (istatem[3] != -1):
		mpnoes = MpList(fs[istatem[2]+1:istatem[3]], 'no', qs.sdate)

	if (istatem[1] < istatem[2]) and (istatem[1] != -1) and (istatem[2] != -1):
		mptayes = MpTellerList(fs[istatem[1]+1:istatem[2]], 'aye', qs.sdate)
	if (istatem[3] < istatem[4]) and (istatem[3] != -1) and (istatem[4] != -1):
		mptnoes = MpTellerList(fs[istatem[3]+1:istatem[4]], 'no', qs.sdate)

	qs.stext = [ ]
	qs.stext.append('<divisioncount ayes="%d" noes="%d" tellerayes="%d" tellernoes="%d"/>' % (len(mpayes), len(mpnoes), len(mptayes), len(mptnoes)))
	qs.stext.append('<mplist vote="aye">')
	qs.stext.extend(mpayes)
	qs.stext.extend(mptayes)
	qs.stext.append('</mplist>')
	qs.stext.append('<mplist vote="no">')
	qs.stext.extend(mpnoes)
	qs.stext.extend(mptnoes)
	qs.stext.append('</mplist>')



rebr = re.compile('\s*<br>\s*')
# Cope of Berkeley, L. [Teller]
retell = re.compile('(.*?)\s*\[Teller\]$')
def ExtrVotes(text, side):
	res = [ ]
	for nam in rebr.split(text):
		if nam:
			# do the unique id thing
			gtell = retell.match(nam)
			lnam = nam
			if gtell:
				lnam = gtell.group(1)

			id = "unknown" # id from lnam

			res.append('\t<vote id="')
			res.append(id)
			res.append('" side="')
			res.append(side)
			res.append('"')
			if gtell:
				res.append(' Teller="1"')
			res.append('>')
			res.append(nam)
			res.append('</vote>\n')

	return res


#regdivsecs = '<P>\s*<center><b>(CONTENTS)\s*</B></center><br>(([^<>/]|<br>)*)<P>\s*<center><b>(NOT-CONTENTS)\s*</B></center><br>(([^<>/]|<br>)*)([\s\S]*)$(?i)'
regdivsecs = '\s*<P>\s*<center><b>(CONTENTS)\s*</B></center><br>((?:[^<>/]|<br>)*)<P>\s*<center><b>(NOT-CONTENTS)\s*</B></center><br>(([^<>/]|<br>)*)([\s\S]*)$(?i)'
def LordsFilterDivision(divno, divtext, sdate):

# <P>\s<center><b>CONTENTS\s</B></center><br>
# <P>\s<center><b>NOT-CONTENTS\s</B></center><br>
	gcontents = re.match(regdivsecs, divtext)
	if not gcontents:
		print divtext
		sys.exit(0)

	res = [ ]
	res.append('<divisionside side="content">\n')
	res.extend(ExtrVotes(gcontents.group(2), 'yes'))
	res.append('</divisionside>\n')
	res.append('<divisionside side="not-content">\n')
	res.extend(ExtrVotes(gcontents.group(4), 'no'))
	res.append('</divisionside>\n')

	return string.join(res, '')



