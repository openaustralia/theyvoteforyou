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

def ExtractPhraseRecurse(qs, stex, depth, rectag):
	qspan = None
	depth = depth+1
	brecmiddle = 0

	# split the text into known mpjobs
	if depth == 1:
		qjobs = rejobs.search(stex)
		if qjobs:
			qtags = ('<mpjob>', '</mpjob>')
			qstr = qjobs.group(1)
			qspan = qjobs.span(1)

	# or split at italics,
	if not qspan:
		qit = re.search('(<i>(.*?)</i>)', stex)
		if qit:
			qtags = ('<i>', '</i>')
			qstr = qit.group(2)
			qspan = qit.span(1)
			brecmiddle = 1

	# or split at sup (since these get confounded by parentheses
	if not qspan:
		qsup = re.search('(<sup>(.*?)</sup>)', stex)
		if qsup:
			qtags = ('<sup>', '</sup>')
			qstr = qsup.group(2)
			qspan = qsup.span(1)
			brecmiddle = 1

	# or split at parenthesis, finding known names
	if not qspan:
		qbrack = re.search('(\(([^)]*)\))', stex)
		if qbrack:
			qstr = qbrack.group(2)
			qspan = qbrack.span(1)

			if memberList.mpnameexists(qbrack.group(2), qs.sdate):
				# we maybe can leave out the brackets if the xml thing puts them back in.
				qtags = ('<mpname>(', ')</mpname>')
			else:
				qtags = ('(', ')')
				brecmiddle = 1

	# or split at official report statement
	if not qspan:
		qoffrep = reoffrepw.search(stex)
		if qoffrep:
			qtags = ('<offrep>', '</offrep>')
			qstr = qoffrep.group(2)
			qspan = qoffrep.span(1)

	# or split at a detectable date
	if (not qspan) and (rectag != '<datephrase>'):
		qdateph = parlPhrases.redatephrase.search(stex)
		if qdateph:
			qtags = ('<datephrase>', '</datephrase>')
			qstr = qdateph.group(2)
			qspan = qdateph.span(1)

	# we have a splitting off which we now recursesymbols down both ends and middle
	if qspan:
		res = ExtractPhraseRecurse(qs, stex[:qspan[0]], depth+1, '')
		res.append(qtags[0])
		if brecmiddle:
			res.extend(ExtractPhraseRecurse(qs, qstr, depth+1, qtags[0]))
		else:
			res.append(FixHTMLEntities(qstr))

		res.append(qtags[1])
		res.extend(ExtractPhraseRecurse(qs, stex[qspan[1]:], depth+1, ''))
		return res

	# bottom level
	return [ FixHTMLEntities(stex) ]


# main breaking up function.
def BreakUpText(stex, qs):
	sres = ExtractPhraseRecurse(qs, stex, 1, '')
	#MergePersonPhrases(qs, sres)
	return sres


resqbrack = re.compile('(\s*(?:\s|</?i>)*\[(?:\s|</?i>)*(.*?)(?:</i>|:|;|\s)*\](?:</i>|:|;|\s)*)')
relettfrom = re.compile('<i>Letter from (.*?)(?: to (.*?))?(?:(?:,? dated| of)? %s)?:?</i>[.:]?$' % parlPhrases.datephrase)

# main breaking up function.
def BreakUpTextSB(i, n, stex, qs):

	# First convert from the text into a list where the first entry is always a bracketed phrase
	# only in the first paragraph
	# <i>[holding answer 17 September 2003]:</i>
	sres = [ ]
	if i == 0:
		# the delimeters are in a variety of different orders
		qha = resqbrack.match(stex)
		if qha:
			sres.append('<sqbracket>')
			sres.extend(BreakUpText(qha.group(2), qs))
			sres.append('</sqbracket>')
			stex = stex[qha.span(1)[1]:]

	# might want to hive off the square-bracket clause into a paragraph on its own.

	# letter from paragraph form
	# <i>Letter from Ruth Kelly to Mr. Frank Field dated 2 December 2003:</i>
	# introducing a previous letter from a civil servant to an MP
	qlettfrom = relettfrom.match(stex)
	if qlettfrom:
		perphxto = ''
		if qlettfrom.group(2):
			if memberList.mpnameexists(qlettfrom.group(2), qs.sdate):
				perphxto = ' to <mpname>%s</mpname>' % qlettfrom.group(2)
			else:
				perphxto = ' to <perph>%s</perph>' % qlettfrom.group(2)
				print ' Letter to unknown MP %s' % qlettfrom.group(2)
				print stex

		datephr = ''
		if qlettfrom.group(3):
			datephr = ' dated <datephrase>%s</datephrase>' % qlettfrom.group(3)
		# build the entire paragraph
		sres = [ '<letterfrom>', 'Letter from ', '<perph>', qlettfrom.group(1), '</perph>',
				perphxto, datephr, '</letterfrom>' ]
		return sres

	# failed to detect the letter from case
	qitpara = re.match('<i>Letter from(?i)', stex)
	if qitpara:
		print stex
		raise Exception, ' failed to detect Letter from '


	# otherwise go straight into the recursion
	sres.extend(BreakUpText(stex, qs))
	return sres


# this is the main function.
def FilterReply(qs):
	# break into paragraphs
	nfj = re.split('(<table[\s\S]*?</table>|</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', qs.text)

	# break up into sections separated by paragraph breaks
	# these alternate in the list, with the spaces already as lists
	dell = []

	spclist = []
	spclistinter = []
	for nf in nfj:
		if re.match('</?p>|</?ul>|<br>|</?font[^>]*>(?i)', nf):
			spclist.append(nf)

		# sometimes italics are hidden among the paragraph choss
		elif re.match('\s*<i>\s*$', nf):
			spclistinter.append(string.strip(nf))
		else:
			if re.search('\S', nf):
				dell.append(spclist)
				spclist = []

				pstring = string.strip(nf)
				if spclistinter:
					spclistinter.append(pstring)
					pstring = string.join(spclistinter, '')

				dell.append(pstring)

	dell.append(spclist)



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
			lstex = string.join(sres, '')
			if re.search('TAG-OUT', lstex):
				print dell[i2]
				print lstex
				#sys.exit()
			qs.stext.append(lstex)

	if not qs.stext:
		print 'empty answer'
		raise Exception, 'empty answer'


