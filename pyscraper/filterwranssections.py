#! /usr/bin/python2.3
import sys
import re
import os
import string


# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime


from miscfuncs import ApplyFixSubstitutions

from splitheadingsspeakers import SplitHeadingsSpeakers
from splitheadingsspeakers import StampUrl

from clsinglespeech import qspeech
from parlphrases import parlPhrases

from miscfuncs import FixHTMLEntities
from miscfuncs import WriteXMLHeader


fixsubs = 	[
	( '<h2><center>written answers to</center></h2>\s*questions(?i)', \
	  	'<h2><center>Written Answers to Questions</center></h2>', -1, 'all'),
	( '<h\d align=center>written answers[\s\S]{10,150}?\[continued from column \d+?W\](?:</h\d>)?(?i)', '', -1, 'all'),
	( '<h\d><center>written answers[\s\S]{10,150}?\[continued from column \d+?W\](?i)', '', -1, 'all'),


	( '<H2 align=center> </H2>', '', 1, '2003-09-15'),
	( '<H1 align=center></H1>\s*<H2 align=center>Monday 15 September 2003</H2>', '', 1, '2003-09-15'),
	( '<H1 align=center></H1>', '', 1, '2003-10-06'),

	( '<BR>\s*</FONT>\s*<H4><center>Energy Policy</center></H4>', '', 1, '2003-04-29'),


        ( '(\<UL\>\(2\) what research work he has \<i\>\(a\)</i> commissioned and \<i\>\(b\)\</i\> evaluated on external)(\<P\>\</UL\>)', '\\1 counter pulsation; and what conclusions about its efficacy were drawn. [143813] \\2', 1, '2003-12-16'),


	# sort out a lot of nasty to-ask problems
	( 'To as the Deputy Prime Minister', 'To ask the Deputy Prime Minister', 1, '2003-10-06'),
	( '\n What ', '\n To ask the Secretary of State for Northern Ireland what ', 4, '2003-09-10'),
	( '\n If he will ', '\n To ask the Secretary of State for Northern Ireland if he will ', 2, '2003-09-10'),

 	( '\n If he will ', '\n To ask the Secretary of State for Scotland if he will ', 1, '2003-09-09'),
 	( '\n How many ', '\n To ask the Secretary of State for Scotland how many ', 1, '2003-09-09'),
 	( '\n What recent ', '\n To ask the Secretary of State for Scotland what recent ', 2, '2003-09-09'),
 	( '\n When he ', '\n To ask the Secretary of State for Scotland when he ', 2, '2003-09-09'),

 	( '\n If he ', '\n To ask the Secretary of State for Work and Pensions if he ', 2, '2003-07-07'),
 	( '\n What ', '\n To ask the Secretary of State for Work and Pensions what ', 2, '2003-07-07'),
 	( '\n How many ', '\n To ask the Secretary of State for Work and Pensions how many ', 1, '2003-07-07'),
 	( '\n What ', '\n To ask the Secretary of State for Culture, Media and Sport what ', 1, '2003-06-30'),

	( '(that initiatives the Government)', 'To ask the Secretary of State for Wales \\1', 1, '2003-06-04'),
	( ' What (recent discussions he has)', 'To ask the Secretary of State for Wales what \\1', 1, '2003-06-04'),
	( ' What (meetings he has held)', 'To ask the Secretary of State for Wales what \\1', 1, '2003-06-04'),
	( ' What (discussions he has had)', 'To ask the Secretary of State for Wales what \\1', 1, '2003-06-04'),
 	( ' (on military flights at Northolt)', 'To ask the Secretary of State for Defence SOMETHING \\1', 1, '2003-06-03'),
	( '\n What (steps her Department)', '\n To ask the Secretary of State for Trade and Industry what \\1', 1, '2003-05-01'),
	( '\n If (she will make a statement)', '\n To ask the Secretary of State for Trade and Industry if \\1', 1, '2003-05-01'),
	( '\n When he expects', '\nTo ask the Secretary of State for Education and Skills when he expects', 1, '2003-04-10'),
	( '\n Asked the Secretary', '\nTo ask the Secretary', 1, '2003-03-21'),
	( ' What (measures will be)', 'To ask the Secretary of State for Work and Pensions what \\1', 1, '2003-03-17'),

	( ' What (plans he has to reform)', 'To ask the Chancellor of the Exchequer what \\1', 1, '2004-01-29'),
	( ' If (he will make a statement)', 'To ask the Chancellor of the Exchequer if \\1', 2, '2004-01-29'),
	( '( To) (the Secretary of State for Trade and Industry)', '\\1 ask \\2', 1, '2004-01-26'),

	# this is complicated because the speaker name has already been tokenized (into part \\1)
	( '\{\*\*con\*\*\}\{\*\*/con\*\*\}(<P>[\s\S]*?)(\(1\)\s*pursuant to his response)', '\\1 To ask the Secretary of State for Defence \\2', 1, '2003-06-03'),

	( '\n (ask the Secretary of State)', '\n To \\1', 1, '2003-06-03'),
	( '\((115021)\)', '[\\1]', 1, '2003-06-03'),
	( '\{\*\*con\*\*\}\{\*\*/con\*\*\}', '', 1, '2003-05-19'),
        ( '(\[142901)', '\\1]', 1, '2003-12-11'),

 	( '\n To\s*ask ', '\n To ask ', 10, '2003-07-07'), # linefeed example I can't piece apart
 	#( '\n To as the Secretary', '\n To ask the Secretary', 1, '2003-05-19'),
 	( '\n To as the Secretary', '\n To ask the Secretary', 1, '2003-05-12'),
 	( '\n To as the Secretary', '\n To ask the Secretary', 1, '2003-04-29'),
 	( '\n To as the Secretary', '\n To ask the Secretary', 2, '2003-01-14'),
 	( '\n To\s*ask ', '\n To ask ', 7, '2003-04-10'),
 	( '\n To\s*ask ', '\n To ask ', 9, '2003-03-06'),
 	( '\n To\s*ask ', '\n To ask ', 37, '2003-01-27'),

	( '\((108679)\)', '[\\1]', 1, '2003-05-12'),
	( '\((109290)\)', '[\\1]', 1, '2003-05-06'),

	( '24 April \[108495\]', '24 April reference 108495', 1, '2003-04-28'),

 	( 'Worcestershire</FONT></TD>', 'Worcestershire', 1, '2003-07-15'),

	( '\{\*\*con\*\*\}\{\*\*/con\*\*\}', '', 3, '2002-07-24'),
	( '\{\*\*con\*\*\}\{\*\*/con\*\*\}', '', 1, '2003-01-13'),
	( '\n\s*\(1\)\s*To ask', '\n To ask (1) ', 3, '2002-07-24'),

	( 'how the proposed', '(1) how the proposed', 1, '2003-04-28'),
	( 'Cabinet Office if', 'Cabinet Office (1) if', 1, '2003-04-03'),
	( '<P>\s*<UL> (\[106584\])<P></UL>', '\\1', 1, '2003-04-01'),
	( 'Home Department when he will', 'Home Department (1) when he will', 1, '2003-03-13'),
 	( '\(1\) Asked (the Secretary of State for International Development) what', ' To ask \\1 (1) what', 1, '2003-03-07'),
 	( ' Asked the Secretary', 'To ask the Secretary', 7, '2003-03-07'),
	( 'Commonwealth Affairs what assessment', 'Commonwealth Affairs (1) what assessment', 1, '2003-03-07'),
 	( '\n What discussions he', '\nTo ask the Secretary of State for Wales what discussions he', 2, '2003-02-12'),
	( '\{\*\*con\*\*\}\{\*\*/con\*\*\}', '', 1, '2003-01-30'),
	( 'Rural Affairs what estimates', 'Rural Affairs (1) what estimates', 1, '2003-01-29'),


	( '<i>The following questions were answered on 10 June</i>', '', 1, '2003-06-10'),

	( 'Vol. No. 412,', '', 1, '2003-11-10'),
	( '</TH></TH>', '</TH>', 1, '2003-11-17'),
	( '<TR valign=top><TD><FONT SIZE=-1>Quarter to', '<TR valign=top><TH><FONT SIZE=-1>Quarter to', 1, '2003-05-06'),

	( 'Asked the Minister', 'To ask the Minister', 1, '2003-05-19'),
	( 'Asked the Minister', 'To ask the Minister', 1, '2003-05-21'),
	#( '</B>\s*Asked', '</B> To ask', 1, '2003-03-21'),

	( '2003&#150;11&#150;21', '2003', 1, '2003-11-20'),
	( '27Ooctober', '27 October', 1, '2003-10-27'),

	( '<TD <', '<TD> <', 1, '2003-07-15'),
	( '<TABLE BORDER=1>\s*<P>\s*</FONT></TH></TR>', '<TABLE BORDER=1>', 2, '2002-10-22'),

	( '131278\]', ' [131278]', 1, '2003-10-06'),
	( 'Department how many asylum applications', 'Department (1) how many asylum applications', 1, '2003-09-18'),

	#( '<TABLE BORDER=1>\s*<H4>', '<H4>', 6, '2002-10-22'),

	( '"</i>Guidance', '</i>"Guidance', 1, '2003-10-30'),
	( ' \[116654\]', '', 1, '2003-06-10'),

	# broken link fixing material
	( 'standards.php\*', 'standards.php', 1, '2003-12-08'), 
	( 'http://www/', 'http://www.', 1, '2003-11-03'),
	( 'www.mod.ukyissues', 'www.mod.uk/issues', 1, '2003-10-22'),
	( 'http.V/', 'http://', 1, '2003-09-18'),
	( 'hhtp://', 'http://', 1, '2003-09-08'),
	( 'http:www', 'http://www', 1, '2003-07-17'),
	( 'www.lshtm.ac/', 'www.lshtm.ac.uk/', 1, '2003-07-10'),
	( 'www.g8.fr.Evian', 'www.g8.fr/evian', 1, '2003-06-13'),
	( 'http//wwwstatisticsgovuk/', 'http//www.statistics.gov.uk/', 1, '2003-09-01'),
	( 'http:www', 'http://www', 1, '2003-07-01'),
	( 'www.mod.ulc', 'www.mod.uk', 1, '2003-01-15'),
	( 'www://defraweb', 'http://defraweb', 1, '2003-05-07'),
	( 'www.hypo-org', 'www.hypo.org', 1, '2003-04-29'),
	( 'www.btselem.orR', 'www.btselem.org', 1, '2003-04-14'),
	( 'www.unicef-org', 'www.unicef.org', 1, '2003-02-28'),
	( 'gov.ukyStatBase', 'gov.uk/StatBase', 1, '2003-05-22'),
        ( 'defraweb', 'www.defra.gov.uk', 1, '2003-12-18'),

        # special note not end of block - when we have multiple answers
        ( '(Decisions on proposed closures of post offices are an operational matter for Post Office Ltd)', '<another-answer-to-follow>\\1', 1, '2004-01-22'),

]

# parse through the usual intro headings at the beginning of the file.
def StripWransHeadings(headspeak, sdate):
	# check and strip the first two headings in as much as they are there
	i = 0
	if (headspeak[i][0] != 'Initial') or headspeak[i][2]:
		print headspeak[0]
		raise Exception, 'non-conforming Initial heading '
	i = i + 1

	if (not re.match('written answers to questions(?i)', headspeak[i][0])) or headspeak[i][2]:
		if not re.match('The following answers were received.*', headspeak[i][0]):
			print headspeak[i]
			raise Exception, 'non-conforming Initial heading '
	else:
		i = i + 1

	if (not re.match('The following answers were received.*', headspeak[i][0]) and \
			(sdate != mx.DateTime.DateTimeFrom(headspeak[i][0]).date)) or headspeak[i][2]:
		if (not parlPhrases.majorheadings.has_key(headspeak[i][0])) or headspeak[i][2]:
			print headspeak[i]
			raise Exception, 'non-conforming second heading '
	else:
		i = i + 1

	# find the url and colnum stamps that occur before anything else
	stampurl = StampUrl()
	for j in range(0, i):
		stampurl.UpdateStampUrl(headspeak[j][1])

	if (not stampurl.stamp) or (not stampurl.pageurl):
		raise Exception, ' missing stamp url at beginning of file '
	return (i, stampurl)


def ScanQBatch(shspeak, stampurl, sdate):
	shansblock = [ ]
	qblock = [ ]

	# go through the speeches in each block under a title, and output
	# a Q&A block after every answer.
	for shs in shspeak:
		qb = qspeech(shs[0], shs[1], stampurl, sdate)
		qblock.append(qb)
                #print "type ", qb.typ, " len qblock ", len(qblock)

                # special case: multiple replies
                replytofollow = False
		if re.search("\<another-answer-to-follow\>", qb.text):
                    qb.text = qb.text.replace("<another-answer-to-follow>", "")
                    replytofollow = True

		# reply detected, output the block
		if qb.typ == 'reply' and (not replytofollow):
			# no preceeding question blocks with this reply
			if len(qblock) < 2:
				print shs[1]
				raise Exception, ' Reply with no question ' + stampurl.stamp
			shansblock.append(qblock)
			qblock = []

	# there's still questions sitting in this block
	# errors to be generated later.
	if qblock:
		# these are common failures of the data
		print "block without answer " + stampurl.title + stampurl.stamp
		shansblock.append(qblock)
	return shansblock




# A series of speeches blocked up into question and answer.
def WritexmlSpeechBlock(fout, qblock, sdate):
	# all the titles are in each speech, so lift from first speech
	qb0s = qblock[0].sstampurl

	colnumg = re.findall('colnum="([^"]*)"', qb0s.stamp)
	if not colnumg:
		raise Exception, 'missing column number'
	colnum = colnumg[0]

	# (we could choose answers to be the id code??)
	sid = 'uk.org.publicwhip/wrans/%s.%s.%d' % (sdate, colnum, qb0s.ncid)

	# get the stamps from the stamp on first speaker in block
	fout.write('\n<wrans id="%s" title="%s" majorheading="%s">\n' % \
				(sid, FixHTMLEntities(qb0s.title), qb0s.majorheading))
	fout.write(qb0s.stamp)
	fout.write('\n')
	fout.write(qb0s.pageurl)
	fout.write('\n')

	# output the speeches themselves (type single speech)
	for qs in qblock:
		fout.write('\t<speech %s type="%s">\n' % (qs.speaker, qs.typ))

		# add in some tabbing
		for st in qs.stext:
			fout.write('\t\t')
			fout.write(st)
			fout.write('\n')

		fout.write('\t</speech>\n')

	fout.write('</wrans>\n')


################
# main function
################
def FilterWransSections(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)
	headspeak = SplitHeadingsSpeakers(text)

	# break down into lists of headings and lists of speeches
	(ih, stampurl) = StripWransHeadings(headspeak, sdate)


	# full list of question batches
	# We create a list of lists of speeches
	qbl = []

	for i in range(ih, len(headspeak)):
		sht = headspeak[i]

		# update the stamps from the pre-spoken text
		stampurl.UpdateStampUrl(sht[1])
                #print "heading " , sht[0]

		# detect if this is a major heading
		if not re.search('[a-z]', sht[0]) and not sht[2]:
			if not parlPhrases.majorheadings.has_key(sht[0]):
				print '"%s":"%s",' % (sht[0], sht[0])
				raise Exception, "unrecognized major heading: "
			else:
				# correct spellings and copy over
				stampurl.majorheading = parlPhrases.majorheadings[sht[0]]

		# non-major heading; to a question batch
		else:
			if parlPhrases.majorheadings.has_key(sht[0]):
				print sht[0]
				raise Exception, ' speeches found in major heading '

			stampurl.title = sht[0]
			qbl.extend(ScanQBatch(sht[2], stampurl, sdate))


	# go through all the speeches in all the batches and clear them up (converting text to stext)
	for qb in qbl:
		qnums = []	# used to account for spurious qnums seen in answers
		for qs in qb:
			qs.FixSpeech(qnums)


	#
	# we have built up the list of question blocks, now write it out
	#
	WriteXMLHeader(fout);
	fout.write("<publicwhip>\n")
	for qb in qbl:
		WritexmlSpeechBlock(fout, qb, sdate)

	fout.write("</publicwhip>\n")


