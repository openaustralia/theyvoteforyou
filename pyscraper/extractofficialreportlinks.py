#! /usr/bin/python2.3
import sys
import re
import string

import mx.DateTime

rexoffrep = '<i>official(?:\s|</?i>)*report,?</i>(?i)'
rexdate = '(\d+\s+\S+(?:\s+\d+)?)'
rexcolnum = 'column[s.]*?\s+(\d+[ws]*|[wa]*\d+)'
rexhonmem = '(to the hon.*?\(.*?\))'

rex1 = '%s[.,]?\s+\(?%s,?\s+%s\)?(?i)' % (rexdate, rexoffrep, rexcolnum)
rex2 = '%s[.,]?\s+%s,\s+%s,?\s+%s(?i)' % (rexdate, rexhonmem, rexoffrep, rexcolnum)

rexirefer = '(i (?:therefore |would )?refer)\s+(.*?%s.*?)$(?i)' % rexoffrep
rextoans = 'to (?:the|my) answers?'
#(.*?\s+given|gave)\s+(.*?%s.*?)' % rexoffrep

def ExtractOfficialReportLinks(text):
	res = []

	if not re.search(rexoffrep, text):
		return res

	words = re.findall('(\S+)\s*', text)
	if len(words) < 20:
		print words
	return res

	# dig out the the rest of the date.
	# 10 June 2003, <i>Official Report,</i> column 771W
	ho = re.findall(rex1, text)
	for hho in ho:
		colno = hho[1]
		date = mx.DateTime.DateTimeFrom(hho[0]).date
		res.append((date, colno, 'someone', 'someone'))
	return res

	ho.extend(re.findall(rex2, text))
	if ho:
		for hho in ho:
			print hho
	else:
		print text
		#sys.exit()

	# dig out the full statement if possible.

	#I refer my hon. Friend to the written answer which I gave to the hon. Member for Eltham (Clive Efford) on 15 September 2003, <i>Official Report,</i> column 559W.

	# separate out the clauses of the sentence
	ir = re.findall(rexirefer, text)
	if not ir:
		return
	otext = text
	text = ir[0][1]

	# transformal grammar
	text = re.sub('hon[.](?i)', 'honourable', text)
	text = re.sub('Member', 'member', text)
	text = re.sub('my honourable friend(?i)', 'the honourable member', text)
	text = re.sub('honourable (?:lady|gentleman)(?i)', 'honourable member', text)

	text = re.sub('written ', '', text)
	text = re.sub('reply', 'answer', text)
	text = re.sub('Parliamentary Statement', 'answer', text)
	text = re.sub('statement', 'answer', text)
	text = re.sub('response', 'answer', text)

	text = re.sub('answer made', 'answer given', text)
	text = re.sub('member the answer', 'member to the answer', text)
	text = re.sub('to my answer of', 'to the answer I gave on', text)
	text = re.sub('to my answer', 'to the answer given by me', text)
	text = re.sub('(?:which|that) I gave', 'I gave', text)
	text = re.sub('I gave him', 'I gave to him', text)
	text = re.sub('I gave the', 'I gave to the', text)
	text = re.sub('I gave', 'given by me', text)
	text = re.sub('answer (my .*?) gave', 'answer given by \\1', text)
	text = re.sub('to this house on', 'on', text)

	# transform the given clause
	text = re.sub('given to (.*?) by (.*?) on', 'given by \\2 to \\1 on', text)
	text = re.sub('given on', 'given by someone on', text)
	text = re.sub('(given by .*?) on', '\\1 to someone on', text)
	text = re.sub('given (to .*? on)', 'given by someone \\1', text)

	#print text
	#return

	#print '\t' + text

	# filter the text down
	rexfilt = '^(^the honourable member to the answers?) given (by .*?) (to .*?) on (.*?%s.*?)$(?i)' % rexoffrep
	rm = re.findall(rexfilt, text)
	if not rm:
		return

	print rm[0][1:3]

	#sys.exit()

s = """Evaluation is continuing of the four expressions of interest, in response to the international invitation issued in April of this year, concerning possible private sector participation and potential investment in developing air access for St. Helena. I refer the hon. Gentleman to my written statement to this House on 16 September 2003, <i>Official Report</i>, column 43WS.
I refer my hon. Friend to my answer of 23 October 2003 to the hon. Member for Moray (Angus Robertson), <i>Official Report</i>, column 691W.
I refer the hon. Member to the reply given by Defra on 3 November 2003 (<i>Official Report</i> column 404W).
I refer the hon. Member to the reply I gave him on 14 October 2003, <i>Official Report</i>, column 18W.
I refer my hon. Friend to the answer I gave on 16 September 2003, <i>Official Report</i>, column 674W.
I refer my hon. Friend to the answer given by my hon. Friend the Parliamentary Under Secretary of State for the Environment, Food and Rural Affairs (Mr. Bradshaw) on 3 November 2003, <i>Official Report,</i> columns. 403W,
I refer the hon. Member to the answer given to the hon. Member for Southwark, North and Bermondsey (Simon Hughes) on 4 November 2003, <i>Official Report</i>, column 610W.
I refer the hon. Member to the written answer I gave the hon. Member for Northavon (Mr. Webb) on 23 October 2003, <i>Official Report</i>, columns 703&#150;04W.
I refer my hon. Friend to the written answer I gave the hon. Member for Moray (Angus Robertson) on 16 September 2003, <i>Official Report</i>, columns 696&#150;97W.
should be reformed in the light of the arguments presented during the Westminster Hall Debate on 29 October 2003, <i>Official Report,</i> column 105WH.
I refer the hon. Member to the Parliamentary Statement given on 6 November 2003, <i>Official Report</i>, column 39WS.
I refer my hon. Friend to the answer given on 6 October 2003, <i>Official Report</i>, column 1026W.
I refer my hon. Friend to the answer given to my hon. Friend the Member for Coventry, South on 22 October 2002, <i>Official Report,</i> column 564W.
I refer the hon. Member to the answers I gave to the hon. Member for Lewes (Mr. Baker) on 22 July 2002, <i>Official Report</i>, column 804W,
and on 28 February 2002, <i>Official Report</i>, columns 1443&#150;44W.
"""

ss = s.split('\n')


def Subs(matchl, subl, li):
	for i in range(len(li)):
		if i + len(matchl) >= len(li):
			return
		bm = 1
		for j in range(len(matchl)):
			if not re.match(matchl[j], li[i + j]):
				bm = 0
				break
		if bm:
			print 'substituting'
			for j in range(len(matchl)):
				li.pop(i)
			for j in range(len(subl)):
				li.insert(i, subl[j])



def Extract(text):
	words = []
	st = re.split('([,.]|\s+|<i>official(?:\s|</?i>)*report,?</i>(?i))', text)
	for ss in st:
		if re.search('\S', ss):
			words.append(ss)
	print words

	Subs(['hon', '.'], ['honourable'], words)
	Subs(['St', '.'], ['Saint'], words)
	Subs(['St', '.'], ['Saint'], words)
	Subs(['gentleman(?i)'], ['person'], words)
	Subs(['friend(?i)'], ['person'], words)
	Subs(['the', 'honourable', 'person'], ['you'], words)
	Subs(['to', 'this', 'house(?i)'], [ ], words)
	Subs(['\d+', '\w+', '\d+'], [ 'DATE' ], words)

	print ''
	print words


	return words


Extract(ss[3])
