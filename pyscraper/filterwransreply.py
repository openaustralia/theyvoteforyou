#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from resolvemembernames import memberList
from parlphrases import parlPhrases
from miscfuncs import FixHTMLEntities
from miscfuncs import FixHTMLEntitiesL
from miscfuncs import SplitParaIndents

from filterwransreplytable import ParseTable
from filterwransemblinks import ExtractHTTPlink

from filtersentence import FilterSentence


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



redatephraseval = re.compile('(?:(?:%s) )?(\d+ (?:%s)( \d+)?)' % (parlPhrases.daysofweek, parlPhrases.monthsofyear))
reoffrepw = re.compile('<i>official(?:</i> <i>| )report,?</i>,? c(?:olumns?)?\.? (\d+(?:&#150;\d+)?[WS]*)(?i)')

class PhraseTokenize:

	def RawTokensN(self, qs, stex):
		self.toklist.append( ('', '', FixHTMLEntities(stex)) )
		return

	def OffrepTokens2(self, qs, stex):
		nextfunc = self.RawTokensN
		qoffrep = reoffrepw.search(stex)
		if not qoffrep:
			return nextfunc(qs, stex)

		# extract the proper column without the dash
		qcpart = re.match('(\d+)(?:&#150;(\d+))?([WS]*)(?i)$', qoffrep.group(1))
		if qcpart.group(2):
			qcpartlead = qcpart.group(1)[len(qcpart.group(1)) - len(qcpart.group(2)):]
			if string.atoi(qcpartlead) >= string.atoi(qcpart.group(2)):
				print qoffrep.group(0)
				raise Exception, ' non-following column leadoff '

		qcolcode = qcpart.group(1) + string.upper(qcpart.group(3))
		offrepid = 'http://www.publicwhip.org.uk/wrans.php?id=uk.org.publicwhip/wrans/%s.%s' % (self.lastdate, qcolcode)

		nextfunc(qs, stex[:qoffrep.span(0)[0]])
		# self.toklist.append( ('phrase', ' class="offrep" id="%s"' % offrepid, offrepid) )
		self.toklist.append( ('a', ' href="%s"' % offrepid, '<i>Official Report</i> Column %s' % qoffrep.group(1)) )
		self.OffrepTokens2(qs, stex[qoffrep.span(0)[1]:])

	def DateTokens1(self, qs, stex):
		nextfunc = self.OffrepTokens2
		qdateph = redatephraseval.search(stex)
		if not qdateph:
			return nextfunc(qs, stex)

		# find the date string and should append on the year if not there
		ldate = qdateph.group(1)
		if not qdateph.group(2):
			pass
		try:
			ldate = mx.DateTime.DateTimeFrom(ldate).date
		except:
			return self.RawTokensN(qs, stex)

		# output the three pieces
		nextfunc(qs, stex[:qdateph.span(0)[0]])
		self.toklist.append( ('phrase', ' class="date" id="%s"' % ldate, qdateph.group(0)) )
		self.lastdate = ldate
		self.DateTokens1(qs, stex[qdateph.span(0)[1]:])


	def __init__(self, qs, stex):
		self.lastdate = ''
		self.toklist = [ ]

		self.DateTokens1(qs, stex)

	def GetPara(self, ptype):
		if ptype:
			res = [ '<p class="%s">' % ptype ]
		else:
			res = [ '<p>' ]
		for tok in self.toklist:
			if tok[0]:
				res.append('<%s%s>' % (tok[0], tok[1]))
				res.append(tok[2])
				res.append('</%s>' % tok[0])
			else:
				res.append(tok[2])
		res.append('</p>')
		return string.join(res, '')


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


	# or split at a detectable date, avoiding
	if not qspan:
		qdateph = parlPhrases.redatephrase.search(stex)
		if qdateph:
			qtags = ('<datephrase>', '</datephrase>')
			qstr = qdateph.group(2)
			qspan = qdateph.span(1)

	# of split at a detectable http link
	# This is really hard to piece apart!
	if not qspan:
		(qspan,qstr,qtags) = ExtractHTTPlink(stex, qs)


	# we have a splitting off which we now recursesymbols down both ends and middle
	if qspan:
		res = ExtractPhraseRecurse(qs, stex[:qspan[0]], depth+1, '')
		res.append(qtags[0])
		if brecmiddle:
			res.extend(ExtractPhraseRecurse(qs, qstr, depth+1, qtags[0]))
		else:
			res.extend(FixHTMLEntitiesL(qstr))

		res.append(qtags[1])
		res.extend(ExtractPhraseRecurse(qs, stex[qspan[1]:], depth+1, ''))
		return res


	# bottom level which does further recursing
	return FixHTMLEntitiesL(stex)


#stex = 'site: www.dti.gov.uk/coalhealth The information is complied in the middle of the month and shows the figur'
#print re.findall('(www(?:\.[^\s.]+?)*/[^\s.]*)', stex)
#sys.exit()


# main breaking up function.
def BreakUpText(stex, qs):
	sres = ExtractPhraseRecurse(qs, stex, 1, '')
	#MergePersonPhrases(qs, sres)
	return sres

def BreakUpTextP(ptype, stex, qs):
	if ptype:
		sres = [ '<p class="%s">' % ptype ]
	else:
		sres = [ '<p>' ]
	sres.extend(ExtractPhraseRecurse(qs, stex, 1, ''))
	sres.append('</p>')
	return string.join(sres, '')



relettfrom = re.compile('Letter from (.*?)(?: to (.*?))?(?:(?:,? dated| of)?,? %s)?:?$' % parlPhrases.datephrase)




# square bracket at the beginning of an answer
resqbrack = re.compile('\s*(?:\s|</?i>)*\[(?:\s|</?i>)*(.*?)(?:</i>|:|;|\s)*\](?:</i>|:|;|\s)*')


listlinlprorogue = 	[
		'I am unable to provide the information requested before the House prorogues. ?',
		'I have not been able to answer this Question before Prorogation. ',
		'I regret that it has not been possible to provide an answer before Prorogation, ',
		'The information requested will take some time to collate and ',
		'This information will take some time to collate. ',
		'The information is not readily available. ',
		'It will not be possible to collate the information requested by the hon. Gentleman within the accepted timescale. ',
			]

linliww = 'I will write to'
listlinlhm = [	' my hon.? Friend',
		' the hon. Member, and my hon. Friend',
		' the hon. Member',
		' the hon. Gentleman',
		' my right hon. Friend',
		' my hon. Member',
		' the right hon. and learned Member',
		' the right hon. Member',
	 ]
linlwi = ' with (?:the|this) information'
linlsoon = ' as soon as possible| in due course| shortly'
linlcopy = '(?: and place|, placing) a copy(?: of (?:my|the) letter)?|(?: and|, ) a copy(?: of (?:my|the) (?:letter|reply))? will be placed'
linlliby = ' in the (?:House of Commons Library|(?:Library|Libraries)(?: of the House)?)'


regletterinlib = '(?:%s)?%s(?:%s)(?:%s)?(?:%s)?(?:(?:%s)(?:%s))?\.' % \
		(string.join(listlinlprorogue, '|'), linliww, string.join(listlinlhm, '|'), linlwi, linlsoon, linlcopy, linlliby)
reletterinlibrary = re.compile(regletterinlib)

#print reletterinlibrary.findall('The information is not readily available. I will write to the hon. Member, placing a copy of my letter in the Library of the House.')
#sys.exit()


reaskedtoreply = re.compile('I have been asked to reply\.?\s*')
renotes = re.compile('Notes?:?|Source:?')


pcode = [ '', 'indent', 'italic', 'indentitalic' ]


###########################
# this is the main function
def FilterReply(qs):

	# split into paragraphs.  The second results is a parallel array of bools
	(textp, textpindent) = SplitParaIndents(qs.text)
	if not textp:
		raise Exception, ' no paragraphs in result '


	# the resulting list of paragraphs
	qs.stext = []

	# index into the textp array as we consume it.
	i = 0

	# deal with holding answer phrase at front
	# <i>[holding answer 17 September 2003]:</i>
	qholdinganswer = resqbrack.match(textp[0])
	if qholdinganswer:
		qs.stext.append(BreakUpTextP('holdinganswer', qholdinganswer.group(1), qs))
		textp[i] = textp[i][qholdinganswer.span(0)[1]:]
		if not textp[i]:
			i = i+1


	# asked to reply
	qaskedtoreply = reaskedtoreply.match(textp[i])
	if qaskedtoreply:
		qs.stext.append(BreakUpTextP('askedtoreply', qaskedtoreply.group(0), qs))
		textp[i] = textp[i][qaskedtoreply.span(0)[1]:]
		if not textp[i]:
			i = i+1


	# go through the rest of the paragraphs
	while i < len(textp):
		# deal with tables
		if re.match('<table(?i)', textp[i]):
			qs.stext.append(ParseTable(textp[i]))
			i = i+1
			continue

		qletterinlibrary = reletterinlibrary.match(textp[i])
		if qletterinlibrary:
			qs.stext.append(BreakUpTextP('letterinlibrary', qletterinlibrary.group(0), qs))
			textp[i] = textp[i][qletterinlibrary.span(0)[1]:]
			if not textp[i]:
				i = i+1
			continue

		# <i>Letter from Ruth Kelly to Mr. Frank Field dated 2 December 2003:</i>
		# introducing a previous letter from a civil servant to an MP
		qlettfrom = relettfrom.match(textp[i])
		if qlettfrom:
			qs.stext.append(BreakUpTextP('letterfrom', qlettfrom.group(0), qs))
			i = i+1
			continue

		qnotes = renotes.match(textp[i])
		if qnotes:
			qs.stext.append(BreakUpTextP('notes', qnotes.group(0), qs))
			i = i+1
			continue


		# nothing special about this paragraph (except it may be indented)
		#qs.stext.append(BreakUpTextP(pcode[textpindent[i]], textp[i], qs))
		pht = PhraseTokenize(qs, textp[i])
		qs.stext.append(pht.GetPara(pcode[textpindent[i]]))
		i = i+1




