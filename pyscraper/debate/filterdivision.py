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

sionsm = "Sio\(r\)n|Sio\[circ\]n|Si\&\#244\;n|Si\&\#246\;n"
fullnm = "([ \w\-'#&;]*), ([ \w.#&;]*?|%s)(?:[ \.]rh)?" % sionsm
constnm = "(?:(?:<i>|\()+([ \w&#;\d',.\-]*)(?:\)|</i>)+)"
reflipname = re.compile("%s\s*%s?$" % (fullnm, constnm))
reconstnm = re.compile("%s$" % constnm)

def MpList(fsm, vote, sdate):
        # Merge constituencies alone onto end of previous line
        newfsm = []
        for fss in fsm:
            if reconstnm.match(fss):
                # print "constnm only %s appending to previous line %s" % (fss, newfsm[-1])
                newfsm[-1] += " "
                newfsm[-1] += fss
            else:
                newfsm.append(fss)

	res = [ ]
	pfss = ''
	for fss in newfsm:
                #print "fss ", fss

		# break up concattenated lines
		# Beresford, Sir PaulBlunt, Crispin

		while re.search('\S', fss):
                        # there was an & in [A-Z] on line below, but it broke up this incorrectly:
                        # Simon, Si&#244;n <i>(B'ham Erdington)</i>
			regsep = re.search('(.*?,.*?(?:[a-z]|</i>|\.|\)))([A-Z].*?,.*)$', fss)
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

			# flipround the name
			# Bradley, rh Keith <i>(Withington)</i>
			# Simon, Sio(r)n <i>(Withington)</i>
                        #print "fssf ", fssf
			ginp = reflipname.match(fssf)
			if ginp:
                                #print "grps ", ginp.groups()
				fnam = '%s %s' % (ginp.group(2), ginp.group(1))
				cons = ginp.group(3)
			else:
				raise Exception, "No flipped name match (filterdivision): %s" % fssf
				fnam = fssf;

                        #print "fss ", fssf
			(mpid, remadename, remadecons) = memberList.matchfullnamecons(fnam, cons, sdate, alwaysmatchcons = False)
			if not mpid:
				print "no match for", fnam, cons, sdate
				raise Exception, "No match on name %s" % fnam
                        #print fnam, " --> ", remadename.encode("latin-1")
			res.append('\t<mpname id="%s" vote="%s">%s</mpname>' % (mpid, vote, FixHTMLEntities(fssf)))

	return res

# this pulls out two tellers with the and between them.
def MpTellerList(fsm, vote, sdate):
	res = [ ]
	for fss in fsm:
		while fss: # split by lines, but linefeed sometimes missing
			gftell = re.match('\s*(?:and )?([ \w.\-\'&#;]*?)(?:\(([ \w.\-\'&#;]*)\))?(?: and(.*))?\s*\.?\s*$', fss)
			if not gftell:
				raise Exception, "no match on teller line %s" % fss

			fssf = gftell.group(1)
			fssfcons = gftell.group(2)
			fss = gftell.group(3)

			if len(res) >= 2:
				print fsm
				raise Exception, ' too many tellers '

			(mpid, remadename, remadecons) = memberList.matchfullnamecons(fssf.strip(), fssfcons, sdate)
                        #print fssf, " ++> ", remadename.encode("latin-1")
			res.append('\t<mpname id="%s" vote="%s" teller="yes">%s</mpname>' % (mpid, vote, FixHTMLEntities(fssf)))

	return res


# this splitting up isn't going to deal with some of the bad cases in 2003-09-10
def FilterDivision(text, sdate):

	# the intention is to splice out the known parts of the division
	fs = re.split('\s*(?:<br>|<p>|\n)\s*(?i)', text)

	# extract the positions of the key statements
	statem = [ 'AYES', 'Tellers for the Ayes:', 'NOES', 'Tellers for the Noes:', 'Question accordingly.*|</FONT>|</p>' ]
	istatem = [ -1, -1, -1, -1, -1 ]

	for i in range(len(fs)):
		for si in range(5):
			if re.match(statem[si], fs[i]):
				if istatem[si] != -1:
					print '--------------- ' + fs[i]
					raise Exception, ' already set '
				istatem[si] = i

	# protect against truncating before the question accordingly  
	if istatem[4] == -1:
		istatem[4] = len(fs)

	# deferred division, no tellers
	if istatem[1] == -1 and istatem[3] == -1:
		istatem[1] = istatem[2]
		istatem[3] = istatem[4]


	for si in range(5):
		if istatem[si] == -1:
			print istatem
			raise Exception, ' division delimeter not set '

	mpayes = [ ]
	mptayes = [ ]
	mpnoes = [ ]
	mptnoes = [ ]

	if (istatem[0] < istatem[1]) and (istatem[0] != -1) and (istatem[1] != -1):
		mpayes = MpList(fs[istatem[0]+1:istatem[1]], 'aye', sdate)
	if (istatem[2] < istatem[3]) and (istatem[2] != -1) and (istatem[3] != -1):
		mpnoes = MpList(fs[istatem[2]+1:istatem[3]], 'no', sdate)

	if (istatem[1] < istatem[2]) and (istatem[1] != -1) and (istatem[2] != -1):
		mptayes = MpTellerList(fs[istatem[1]+1:istatem[2]], 'aye', sdate)
	if (istatem[3] < istatem[4]) and (istatem[3] != -1) and (istatem[4] != -1):
		mptnoes = MpTellerList(fs[istatem[3]+1:istatem[4]], 'no', sdate)


	stext = [ ]
	stext.append('<divisioncount ayes="%d" noes="%d" tellerayes="%d" tellernoes="%d"/>' % (len(mpayes), len(mpnoes), len(mptayes), len(mptnoes)))
	stext.append('<mplist vote="aye">')
	stext.extend(mpayes)
	stext.extend(mptayes)
	stext.append('</mplist>')
	stext.append('<mplist vote="no">')
	stext.extend(mpnoes)
	stext.extend(mptnoes)
	stext.append('</mplist>')

	return stext




