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
def FilterDivision(divno, divtext, followspeeches, sdate):
	print "-- lots of work for Francis Division no. %d " % divno

	# GIVE UP FOR NOW!
	return [ ]

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


