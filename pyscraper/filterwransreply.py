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




# A common prefix on answers which needs to be taken out.
def RemoveHoldingAnswer(qs, line):
	# <i>[holding answer 17 September 2003]:</i>
	# the delimeters are in a variety of different orders
	qha = re.match('((?:\s|</?i>)*\[(?:\s|</?i>)*holding answers?\s*(?:on|of|issued|issued on)?\s*([\w\s]*?)(?:</i>|:|;|\s)*\](?:</i>|:|;|\s)*)', line)
	if qha:
		line = line[qha.span(1)[1]:]	# take the tail of the string.
		dt = qha.group(2)

		# could deal with 'and' in this string.
		dgroups = re.match('(\d+)\s*([A-Z][a-z]*)\s*(\d*)$', dt)
		if dgroups:
			dgyr = dgroups.group(3)
			if not dgyr:
				dgyr = '%d' % mx.DateTime.DateTimeFrom(qs.sdate).year
			ddt = dgroups.group(1) + ' ' + dgroups.group(2) + ' ' +  dgyr
			holdans = mx.DateTime.DateTimeFrom(ddt).date
			qs.holdinganswer.append(holdans)
		else:
			print ' not pure date: ' + dt
			print qha.group(1)

	# successfully cleared this quote from front of line
	if qs.sdate != '2003-02-28' and qs.sdate != '2003-02-25':
		if re.search('holding answer ', line):
			print line
			#sys.exit()

	return line



# The following functions are very contorted and recursive, breaking up the paragraph into
# phrases and putting tags around them.  Can't say that it's reliable yet, but what it
# calculates should be the marked up grouping that a later parser can scan and use easily.
# What it is trying to calculate is in the long run correct I believe, although the reliability
# and scalability to total reliability of this particular algorithm is questionable.

# official report phrases
# on 4 June 2003, <i>Official Report,</i> column 22WS
# columns 687&#150;89W

offrepwre = '<i>official(?:</i> <i>| )report,?</i>,?'
offrepre = '((?:on|of|in|and)? ?%s[.,]? %s c(?:olumns?)?\.? (\d+(?:&#150;\d+)?[WS]*)[,.]?)(?i)' % (parlPhrases.datephrase, offrepwre)
reoffrep = re.compile(offrepre)


def ExtractOffRepRecurse(qs, stex):
	# we are now down to a segment of text in which we can look for these official reports
	qoffrep = reoffrep.search(stex)
	if qoffrep:
		res = ExtractOffRepRecurse(qs, string.strip(stex[:qoffrep.span(1)[0]]))
		offdate = mx.DateTime.DateTimeFrom(qoffrep.group(2)).date
		offcolnum = re.sub('&#150;', '-', qoffrep.group(3))

		res.append('<offrep date="%s" column="%s">%s</offrep>' % (offdate, offcolnum, qoffrep.group(1)))
		print offdate + "  " + offcolnum
		res.extend(ExtractBracketNamesRecurse(qs, string.strip(stex[qoffrep.span(1)[1]:])))
		return res

	if re.search('official report(?i)', stex):
		seelines.write(stex)
		seelines.write('\n')

	return [ string.strip(FixHTMLEntities(stex)) ]


# the set of known parliamentary offices.
rejobs = re.compile('((?:[Mm]y (?:rt\. |[Rr]ight )?[Fh]on\.? [Ff]riend )?[Tt]he (?:then |former )?(?:%s))' % parlPhrases.regexpjobs)

def ExtractBracketNamesRecurse(qs, stex):
	# split the remaining chunks at the brackets
	qbrack = re.search('(\(([^)]*)\))', stex)
	if qbrack:
		if memberList.mpnameexists(qbrack.group(2), qs.sdate):
			res = ExtractBracketNamesRecurse(qs, string.strip(stex[:qbrack.span(1)[0]]))
			res.append('(<mpname>%s</mpname>)' % qbrack.group(2))
			res.extend(ExtractBracketNamesRecurse(qs, string.strip(stex[qbrack.span(1)[1]:])))
			return res

	# we are now down to a segment of text in which we can look for these official reports
	return ExtractOffRepRecurse(qs, stex)

def ExtractJobRecurse(qs, stex):
	# split the text into known mpjobs
	qjobs = rejobs.search(stex)
	if qjobs:
		res = ExtractJobRecurse(qs, string.strip(stex[:qjobs.span(1)[0]]))
		res.append('<mpjob>%s</mpjob>' % qjobs.group(1))
		res.extend(ExtractJobRecurse(qs, string.strip(stex[qjobs.span(1)[1]:])))
		return res
	return ExtractBracketNamesRecurse(qs, stex)


# this should pick out phrases refering to members for constituencies without being tooo greedy
# and jumping across a long sentence to grab an hon member part of a later phrase where it occurs
# just before a brackets.
rememconstit = re.compile('((?:[Mm]y (?:[Rr]ight )?[Hh]on\.? [Ff]riend,?(?: the [Mm]ember)|[Tt]he (?:[Rr]ight )?[Hh]on\.? [Mm]ember) for (.*?(?! [Mm]ember ).*?),?)$')
def ExtractPersonPhrases(qs, stex):
	sres = ExtractJobRecurse(qs, stex)

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


def FindHonMembers(i, n, line, qs):
	# first determin the jobs that are in the text
	line = string.join(ExtractPersonPhrases(qs, line))
	return line



# this is the main function.
def FilterReply(qs):
	# break into pieces
	nfj = re.split('(<table[\s\S]*?</table>|</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', qs.text)
	qs.holdinganswer = []

	# break up into sections separated by paragraph breaks
	dell = []
	spc = ''
	for nf in nfj:
		# first line may have this holding answer value which we want to take out
		# and discard if in a paragraph on its own.
		if not dell:
			nf = RemoveHoldingAnswer(qs, nf)

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
	for i in range(1, len(dell)-1, 2):
		# this puts a list into the result
		if re.search('<table(?i)', dell[i]):
			qs.stext.append(ParseTable(dell[i]))
		else:
			lline = dell[i]
			lline = FindHonMembers(len(qs.stext), n, lline, qs)

			qs.stext.append(lline)

	if not qs.stext:
		print 'empty answer'
		raise Exception, 'empty answer'


