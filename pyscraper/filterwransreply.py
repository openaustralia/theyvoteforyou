#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from resolvemembernames import memberList
from parlphrases import parlPhrases
from miscfuncs import FixHTMLEntities

from filterwransreplytable import ParseTable

# output to check for undetected member names
seelines = open('ghgh.txt', "w")







# The following functions are very contorted and recursive, breaking up the paragraph into
# phrases and putting tags around them.  Can't say that it's reliable yet, but what it
# calculates should be the marked up grouping that a later parser can scan and use easily.
# What it is trying to calculate is in the long run correct I believe, although the reliability
# and scalability to total reliability of this particular algorithm is questionable.

# official report phrases
# on 4 June 2003, <i>Official Report,</i> column 22WS
# columns 687&#150;89W

reoffrepw = re.compile('(<i>official(?:</i> <i>| )report,?</i>,? c(?:olumns?)?\.? (\d+(?:&#150;\d+)?[WS]*))(?i)')

# the set of known parliamentary offices.
rejobs = re.compile('((?:[Mm]y (?:rt\. |[Rr]ight )?[Fh]on\.? [Ff]riend )?[Tt]he (?:then |former )?(?:%s))' % parlPhrases.regexpjobs)



# this should pick out phrases refering to members for constituencies without being too greedy
# and jumping across a long sentence to grab an hon member part of a later phrase where it occurs
# just before a brackets.
rememconstit = re.compile('((?:[Mm]y (?:[Rr]ight )?[Hh]on\.? [Ff]riend,?(?: the [Mm]ember)|[Tt]he (?:[Rr]ight )?[Hh]on\.? [Mm]ember) for (.*?(?! [Mm]ember ).*?),?)$')
def MergePersonPhrases(qs, sres):
	i = 0
	while i < len(sres):
		sr1 = ''
		if i+1 < len(sres):
			sr1 = sres[i+1]

		# merge the two if it's the position/name type
		if re.search('<mpname>', sr1):
			if re.search('<mpjob>', sres[i]):
				sres[i] = '<mpphrase>%s %s</mpphrase>' % (sres[i], sr1)
				sres.pop(i+1)
				print sres[i]

			else:
				qconstit = rememconstit.search(sres[i])
				if qconstit:
					#seelines.write('\t\t"%s",\n' % qconstit.group(2))
					sres[i] = string.strip(sres[i][:qconstit.span(1)[0]])
					sres[i+1] = '<mpphrase>%s %s</mpphrase>' % (qconstit.group(1), sres[i+1])
		i = i+1
	return sres

def ExtractPhraseRecurse(qs, stex):
	qspan = None

	# split the text into known mpjobs
	qjobs = rejobs.search(stex)
	if qjobs:
		qstr = '<mpjob>%s</mpjob>' % qjobs.group(1)
		qspan = qjobs.span(1)

	# or split at known names in parenthesis
	if not qspan:
		qbrack = re.search('(\(([^)]*)\))', stex)
		if qbrack:
			if memberList.mpnameexists(qbrack.group(2), qs.sdate):
				# we maybe can leave out the brackets if the xml thing puts them back in.
				qstr = '<mpname>(%s)</mpname>)' % qbrack.group(2)
				qspan = qbrack.span(1)

	# or split at official report statement
	if not qspan:
		qoffrep = reoffrepw.search(stex)
		if qoffrep:
			qstr = '<offrep>%s</offrep>' % re.sub('&#150;', '-', qoffrep.group(2))
			qspan = qoffrep.span(1)

	# or split at a detectable date
	if not qspan:
		qdateph = parlPhrases.redatephrase.search(stex)
		if qdateph:
			qstr = '<datephrase>%s</datephrase>' % qdateph.group(2)
			qspan = qdateph.span(1)

	# we have a splitting off which we now recursymbolsse down both ends
	if qspan:
		res = ExtractPhraseRecurse(qs, stex[:qspan[0]])
		res.append(qstr)
		res.extend(ExtractPhraseRecurse(qs, stex[qspan[1]:]))
		return res

	return [ FixHTMLEntities(stex) ]


# main breaking up function.
def BreakUpText(stex, qs):
	sres = ExtractPhraseRecurse(qs, stex)
	#MergePersonPhrases(qs, sres)
	return sres


# main breaking up function.
def BreakUpTextSB(i, n, stex, qs):

	# First convert from the text into a list where the first entry is always a bracketed phrase
	# only in the first paragraph
	# <i>[holding answer 17 September 2003]:</i>
	sres = [ ]
	if i == 0:
		# the delimeters are in a variety of different orders
		qha = re.match('(\s*(?:\s|</?i>)*\[(?:\s|</?i>)*(.*?)(?:</i>|:|;|\s)*\](?:</i>|:|;|\s)*)', stex)
		if qha:
			sres.append('<sqbracket>')
			sres.extend(BreakUpText(qha.group(2), qs))
			sres.append('</sqbracket>')
			stex = stex[qha.span(1)[1]:]
	sres.extend(BreakUpText(stex, qs))
	return sres


# this is the main function.
def FilterReply(qs):
 # break into pieces
	nfj = re.split('(<table[\s\S]*?</table>|</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', qs.text)

	# break up into sections separated by paragraph breaks
	# these alternate in the list.
	dell = []
	spc = ''
	for nf in nfj:
		if re.match('</?p>|</?ul>|<br>|</?font[^>]*>(?i)', nf):
			spc = spc + nf
		else:
			if re.search('\S', nf):
				dell.append(spc)
				spc = ''
				dell.append(string.strip(nf))
	if not spc:
		spc = ''
	dell.append(spc)



	# we now have the paragraphs interspersed with inter-paragraph symbols
	# for now ignore these inter-paragraph symbols and parse the paragraphs themselves
	qs.stext = []
	n = (len(dell)-1) / 2
	for i in range(n):
		# this puts a list into the result
		i2 = i*2 + 1
		if re.search('<table(?i)', dell[i2]):
			qs.stext.append(ParseTable(dell[i2]))
		else:
			sres = BreakUpTextSB(i, n, dell[i2], qs)
			qs.stext.append(string.join(sres, ''))

	if not qs.stext:
		print 'empty answer'
		raise Exception, 'empty answer'


