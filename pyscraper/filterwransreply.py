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


	# or split at official report statement
	if not qspan:
		qoffrep = reoffrepw.search(stex)
		if qoffrep:
			# extract the proper column without the dash
			qcpart = re.match('(\d+)(?:&#150;(\d+))?([WS]*)(?i)$', qoffrep.group(2))
			if qcpart.group(2):
				qcpartlead = qcpart.group(1)[len(qcpart.group(1)) - len(qcpart.group(2)):]
				if string.atoi(qcpartlead) >= string.atoi(qcpart.group(2)):
					print qoffrep.group(1)
					raise Exception, ' non-following column leadoff '

			qcolcode = qcpart.group(1) + string.upper(qcpart.group(3))
			qtags = ('<offrep column="%s">' % qcolcode, '</offrep>')
			qstr = '<i>Official Report</i> Column %s' % qoffrep.group(2)
			qspan = qoffrep.span(1)

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


relettfrom = re.compile('<i>Letter from (.*?)(?: to (.*?))?(?:(?:,? dated| of)?,? %s)?:?</i>[.:]?$' % parlPhrases.datephrase)


# main breaking up function.
def BreakUpTextSB(i, n, stex, qs):

	sres = [ ]

	# recognize the structure of known paragraphs

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
		sres = [ '<p class="letterfrom">', 'Letter from ', '<perph>', qlettfrom.group(1), '</perph>',
				perphxto, datephr, '</p>' ]
		return sres

	# failed to detect the letter from case
	qitpara = re.match('<i>Letter from(?i)', stex)
	if qitpara:
		print stex
		raise Exception, ' failed to detect Letter from '


	# otherwise go straight into the recursion
	sres.extend(BreakUpText(stex, qs))
	return sres



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


reaskedtoreply = re.compile('I have been asked to reply\.?$')

###########################
# this is the main function
def FilterReply(qs):

	# split into paragraphs.  The second results is a parallel array of bools
	(textp, textpindent) = SplitParaIndents(qs.text)
	if not textp:
		raise Exception, ' no paragraphs in result '


	# deal with holding answer phrase
	# <i>[holding answer 17 September 2003]:</i>
	textnholdinganswer = ''
	qha = resqbrack.match(textp[0])
	if qha:
		textnholdinganswer = qha.group(1)
		textp[0] = textp[0][qha.span(0)[1]:]
		if not textp[0]:
			textp.pop(0)
			textpindent.pop(0)



	# the resulting list of paragraphs
	qs.stext = []

	if textnholdinganswer:
		sres = [ '<p class="holdinganswer">' ]
		sres.extend(BreakUpText(textnholdinganswer, qs))
		sres.append('</p>')
		lstex = string.join(sres, '')
		qs.stext.append(lstex)

	# asked to reply
	if reaskedtoreply.match(textp[0]):
		textp.pop(0)
		textpindent.pop(0)
		qs.stext.append('<p class="askedtoreply">I have been asked to reply.</p>')
	if re.search('have been asked to reply', textp[0]):
		print textp
		#sys.exit()


	# copy in library type phrase
	if reletterinlibrary.match(textp[0]) and (len(textp) == 1):
		qs.stext.append('<p class="letterinlibrary">I will write to my hon. Friend and place a copy of my letter in the Library.</p>')
		return

	if re.search('I will write.*?library(?i)', textp[len(textp)-1]):
		print textp
		#sys.exit()


	# we now have the paragraphs interspersed with inter-paragraph symbols
	# for now ignore these inter-paragraph symbols and parse the paragraphs themselves
	n = len(textp)
	for i in range(len(textp)):
		# this puts a list into the result
		if re.search('<table(?i)', textp[i]):
			qs.stext.append(ParseTable(textp[i]))
		else:
			sres = [ '<p>' ]
			sres.extend(BreakUpTextSB(i, n, textp[i], qs))
			sres.append('</p>')
			lstex = string.join(sres, '')
			if re.search('TAG-OUT', lstex):
				print textp[i]
				print lstex
				#sys.exit()
			qs.stext.append(lstex)



