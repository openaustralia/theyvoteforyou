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

For Chequers, I refer the hon. Member to the answer I gave to the hon. Member for north Devon (Mr. Harvey) on 13 February 2003, <i>Official Report</i>, column 952W.
I refer the hon. Member to the answer I gave to the hon. Member for Sevenoaks (Mr. Fallon) at Prime Minister's Questions on 29 October 2003, <i>Official Report</i>, column 300.
I refer the hon. Member to the answer given on 1 September 2003, <i>Official Report</i>, column 845W, which noted that the Government would be presenting an overview of progress against commitments made at the Johannesburg World Summit on Sustainable Development. That progress report, which covers actions across Government, has now been published and is available at: http://www.sustainable-development.gov.uk/eac-wssd/progress.htm
I refer my hon. Friend to my answer given on 14 October 2003, <i>Official Report,</i> column 102W.
I refer the hon. Member to my written ministerial statement on 30 October 2003 regarding the United Nations Office on Drugs and Crime (UNODC) survey results for the 2003 opium poppy crop in Afghanistan, <i>Official Report</i>, column 20WS.
I refer the hon. Member to the answer I gave him on 3 June 2003, <i>Official Report</i>, column 214W, which gave the latest available figures for applicants and accepted applicants through the Universities and Colleges Admissions Service (UCAS) to full time and sandwich undergraduate courses in the UK.
I refer the hon. Member to the answer I gave him on 3 June 2003, <i>Official Report</i>, column 215W, which gave the latest available information on non-completion rates contained in "Performance Indicators in Higher Education", published by the Higher Education Funding Council for England (HEFCE).
I refer the hon. Member to the answer I gave on 23 October 2003, <i>Official Report</i>, column 654W, to the hon. Member for Aldershot (Mr. Gerald Howarth). I can add that the detailed eligibility criteria have since been completed by the Department and passed to the Committee on the Grant of Honours, Decorations and Medals for their approval. The work is progressing well.
I refer the hon. Member to the answer given by my right hon. Friend the Secretary of State for Foreign and Commonwealth Affairs on 5 November 2003, <i>Official Report</i>, column 662W, to the right hon. Member for North-East Fife (Mr. Menzies Campbell).
I refer my hon. Friend to the answers given by my right hon. Friend the Secretary of State for Defence on 16 June 2003, <i>Official Report</i>, column 55W, to the hon. Member for Lewes (Norman Baker) and the answer I gave to the hon. Member for East Carmarthen and Dinefwr (Adam Price) on 14 October 2003, <i>Official Report</i>, column 7W.
I refer the hon. Member to the answer given to the hon. Member for Brentwood and Ongar (Mr. Pickles) on 7 May 2003, <i>Official Report,</i> column 771W.
I refer the hon. Gentleman to the answer I gave to the hon. Member for Eddisbury (Mr. Stephen O'Brien) on 28 October 2003, <i>Official Report</i>, column 206W. Levels of all taxes are reviewed as part of the annual Budget process, taking account of a range of social, economic and environmental considerations. The Chicago Convention prohibits the imposition of taxes or charges on fuel kept on board aircraft and
As I said in my answer of 14 October 2003, <i>Official Report</i>, column 141W, the market-making exercise was conceived by the Inland Revenue between August and October 2001; it was also committed to at this time. Potential suppliers were also identified between August and October 2001 as part of the planning for the market-making exercise.
Final decisions have yet to be taken on where reallocations will occur and I refer the hon. Member for Carshalton and Wallington to the answers I gave the hon. Member for Meriden (Mrs. Spelman) on 4 November 2003, <i>Official Report</i>, columns 486W and 490W.
Final decisions have yet to be taken on where reallocations will occur and I refer the hon. Member for Blaby to the answers I gave the hon. Member for Meriden (Mrs. Spelman) on 4 November 2003, <i>Official Report</i>, columns 486W and 490W.
Final decisions have yet to be taken on where reallocations will occur and I refer my hon. Friend to the to the answers I gave the hon. Member for Meriden (Mrs. Spelman) on 4 November 2003, <i>Official Report</i>, columns 486&#150;90W.
I refer the hon. Member to the answers given by my hon. Friend the Minister of State for Lifelong Learning, Further and Higher Education on 3 November 2003, <i>Official Report</i>, columns 449W and 455W.
for Environment, Food and Rural Affairs on 3 November 2003, <i>Official Report</i>, column 403W. This is based on annual returns provided by this Department.
I refer my hon. Friend to the answer given on 22 October 2003, <i>Official Report</i>, column 564. The Office of the Deputy Prime Minister expects all local authorities involved in housing transfer to follow the guidance on involving tenants and other stakeholders in the Housing Transfer Manual. All comments provided to Stroud district council have been in accordance with this guidance.
I refer the hon. Member to the answer I gave her on 21 October 2003, <i>Official Report</i>, column 510W.
The Future Carrier project is currently in the Assessment Phase and I refer my hon. Friend to my Written Ministerial Statement made on 16 September 2003, <i>Official Report</i>, columns 44&#150;45WS.
answers2003-11-03.html
I refer the hon. Member to the answer I gave the hon. Member Stone on 17 March, <i>Official Report</i>, column 515W. This set out the written answer given by the Attorney General in the House of Lords on the same day, which explained how, in his view, authority to use force against Iraq existed from the combined effect of resolutions 678, 687 and 1441.
I refer the hon. Member to the answer I gave to the hon. Member for Linlithgow (Mr. Dalyell) on 16 September 2003, <i>Official Report,</i> column 635W.
I would refer the hon. Member to the answer I gave to her on Tuesday 14 October 2003, <i>Official Report</i>, column 118W.
"""

ss = s.split('\n')



def Sx(sm, st, text):
	while 1:
		m = re.search(sm, text)
		if not m:
			return text

		text = text[:m.span(0)[0]] + st + text[m.span(0)[1]:]

def Munge(text):
	st = re.split('([,.]|\s+)', text)
	tx = ''
	for ss in st:
		if re.search('\S', ss):
			tx = tx + ':' + string.strip(ss) + ':'
	#print re.sub('::', ' ', tx)

	tx = Sx('.*?::I::refer:', ':I::refer:', tx)
	tx = Sx(':I::would::refer:', ':I::refer:', tx)

	tx = Sx(':<i>Official::Report</i>:', ':OffReport:', tx)
	tx = Sx(':<i>Official::Report::,::</i>:', ':OffReport:', tx)
	tx = Sx(':hon::\.:', ':honourable:', tx)
	tx = Sx(':the::honourable::[Mm]ember:', ':MP:', tx)
	tx = Sx(':the::honourable::[Gg]entleman:', ':MP:', tx)
	tx = Sx(':right::honourable:', ':honourable:', tx)
	tx = Sx(':my::honourable::[Ff]riend:', ':MP:', tx)

	tx = Sx(':[Ww]ritten::[Aa]nswer:', ':reply:', tx)
	tx = Sx(':answers?:', ':reply:', tx)
	tx = Sx(':reply:', ':statement:', tx)
	tx = Sx(':Parliamentary::Statement:', ':statement:', tx)
	tx = Sx(':[Ww]ritten::[Mm]inisterial::[Ws]tatement:', ':statement:', tx)
	tx = Sx(':[Ww]ritten::[Ws]tatement:', ':statement:', tx)

	tx = Sx(':my::statement:', ':the::statement::given::by::me:', tx)
	tx = Sx(':I::provided:', ':I::gave:', tx)
	tx = Sx(':I::gave:', ':given::by::me:', tx)
	tx = Sx(':gave::to:', ':gave:', tx)

	tx = Sx(':to::this::[Hh]ouse:', '', tx)

	tx = Sx(':MP::for:.*?\(.*?\):', ':MP:', tx)
	tx = Sx(':MP::the:.*?\(.*?\):', ':MP:', tx)
	tx = Sx(':MP::the::Member::for::.*?::OffReport:', ':MP::OffReport:', tx)

	tx = Sx(':o[nf]::\d+::[^:]*::\d+:', ':DATE:', tx)
	tx = Sx(':o[nf]::\w+::\d+::[^:]*::\d+:', ':DATE:', tx)
	tx = Sx(':o[nf]::\d+::[^:]*:', ':DATE:', tx)
	tx = Sx(':columns:', ':column:', tx)
	tx = Sx(':column::\.:', ':column:', tx)
	tx = Sx(':column::\d+[^:]*?[WS]*?:', ':COLNUM:', tx)
	tx = Sx(':COLNUM::and::\d+[^:]*?[WS]*?:', ':COLNUM:', tx)

	tx = Sx(':DATE::to::MP:', ':to::MP::DATE:', tx)

	tx = Sx(':DATE::,:', ':DATE:', tx)
	tx = Sx(':OffReport::,:', ':OffReport:', tx)

	tx = Sx(':DATE::OffReport::COLNUM:', ':OFFREP:', tx)

	tx = Sx(':OFFREP::to::MP:', ':to::MP::OFFREP:', tx)

	tx = Sx(':OFFREP::[.,]::.*?:$', ':OFFREP::.:', tx)

	print re.sub('::', ' ', tx)


for s in ss:
	Munge(s)
