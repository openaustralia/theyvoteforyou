#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from resolvemembernames import memberList
from parlphrases import parlPhrases

# do your conversion from perl to python here!!

# it's possible we want to make this a class, like with speeches.
# so that it sits in our list easily.

def MpList(fsm, sdate):
	res = [ ]
	pfss = ''
	for fss in fsm:
		if not re.search('\S', fss):
			continue

		# check alphabetical
		if pfss and (pfss > fss):
			print pfss, fss
			raise Exception, ' out of order '
		(mpid, errmess, remadename) = memberList.matchfulldivisionname(fss, sdate)
		res.append('<mpname id="%s">$%s</mpname>' % (mpid, remadename))



# this pulls out two tellers with the and between them.
def MpTellerList(fsm, sdate):
	res = [ ]
	for fss in fsm:
		if not re.search('\S', fss):
			continue

		if len(res) >= 2:
			print fss
			raise Exception, ' too many tellers '
		if not res:
			gftell = re.match('([ \w.\-]*?) and$', fss)
			if not gftell:
				print fss
				raise Exception, ' teller mismatch '
			(mpid, errmess, remadename) = memberList.matchfullname(gftell.group(1), sdate)
		else:
			(mpid, errmess, remadename) = memberList.matchfullname(fss, sdate)
		res.append('<mpname id="%s">$%s</mpname>' % (mpid, remadename))


# this splitting up isn't going to deal with some of the bad cases in 2003-09-10
def FilterDivision(divno, divtext, sdate):

	# GIVE UP FOR NOW!
	return [ None ]

	# the intention is to splice out the known parts of the division
	fs = re.split('\s*(?:<br>|<p>)\s*(?i)', divtext)

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


	print istatem
	mpayes = [ ]
	mptayes = [ ]
	mpnoes = [ ]
	mptnoes = [ ]
	if (istatem[0] < istatem[1]) and (istatem[0] != -1) and (istatem[1] != -1):
		mpayes = MpList(fs[istatem[0]+1:istatem[1]], sdate)
	if (istatem[2] < istatem[3]) and (istatem[2] != -1) and (istatem[3] != -1):
		mpnoes = MpList(fs[istatem[2]+1:istatem[3]], sdate)

	if (istatem[1] < istatem[2]) and (istatem[1] != -1) and (istatem[2] != -1):
		mptayes = MpTellerList(fs[istatem[1]+1:istatem[2]], sdate)
	if (istatem[3] < istatem[4]) and (istatem[3] != -1) and (istatem[4] != -1):
		mptnoes = MpTellerList(fs[istatem[3]+1:istatem[4]], sdate)


	return [ ]



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



