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

def FindOfficialReport(text):
	res = []
	if not re.search(rexoffrep, text):
		return res


	# dig out the the rest of the date.
	# 10 June 2003, <i>Official Report,</i> column 771W
	ho = re.findall(rex1, text)
	for hho in ho:
		colno = hho[1]
		date = mx.DateTime.DateTimeFrom(hho[0]).date
		res.append((date, colno))
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
