#! /usr/bin/python2.3

import sys
import re
import os
import string
import StringIO

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

toaskregexp = '^\s*' +\
		'to ask the (secretary of state for (?:' +\
				'defence|' +\
				'northern ireland|' +\
				'education and employment|' +\
				'education and skills|' +\
				'health|' +\
				'trade and industry|' +\
				'social security|' +\
				'the home department|' +\
				'scotland|' +\
				'wales|' +\
				'culture, media and sport|' +\
				'the environment, transport and the regions|' +\
				'transport, local government and the regions|' +\
				'international development|' +\
				'foreign and commonwealth affairs|' +\
				'environment, food and rural affairs|' +\
				'transport|' +\
				'works? and pensions)|' +\
							\
				'chairman of the (?:' +\
				'accommodation and works committee|' +\
				'catering committee|' +\
				'public accounts committee|' +\
				'administration committee)' +\
							\
				'secretary of wales|' +\
				'leader of the house|' +\
				'minister of state, department for international development|' +\
				'secretary of state, department for international development|' +\
				'minister of state for international development|' +\
				'minister of agriculture, fisheries and food|' +\
				'minister for the cabinet office|' +\
				'minister for women|' +\
				'prime minister|' +\
				'(?:office of the )?deputy prime minister|' +\
				'parliamentary secretary, department for constitutional affairs|' +\
				'parliamentary secretary|' +\
				'chancellor of the exchequer|' +\
				'president of the council|' +\
				'solicitor[-\s]general|' +\
				'advocate[-\s]general' +\
				')([\s\S]*)$(?i)'

retoask = re.compile(toaskregexp)
# split off the to ask part
#se = retoask.findall(text)
#if len(se) == 0:
#	if not re.search('to ask the hon[.] member for(?i)', text):
#		print text



def QuestionBreakIntoParagraphs(text):
	# To ask ... (1) how many ...;  [138423]
	# <P>
	# <P>
	# <UL>(2) what the ... United Kingdom;  [138424]
	# <P>
	# (3) if she will ... grants.  [138425]<P></UL>
	nfj = re.split('(</?p>|</?ul>)(?i)', text)

	# break up into sections separated by paragraph breaks
	dell = []
	spc = ''
	for nf in nfj:
		if re.match('(</?p>|</?ul>)(?i)', nf):
			if not spc:
				spc = ''
			spc = spc + nf
		elif re.search('\S', nf):
			if not spc:
				print 'error space'
				print nfj
				sys.exit()
			dell.append(spc)
			spc = None
			dell.append(nf)
	if not spc:
		spc = ''
	dell.append(spc)

	# the result strong
	pres = []

	# deal with subsets
	if len(dell) < 3:
		print 'error no space parsing'
		return pres

	# sometimes column numbers have added in line breaks that shouldn't be there.
	# this recognizes the pattern and takes them out
	# remove any breaks that look like a column had been there
	# \n\n\n\n', '<P><P><P>', '\n
	for i in range(len(dell) - 3, 1, -2):
		if re.match('(<p>){3}$(?i)', dell[i]) and re.search('\n{4}$', dell[i-1]) and \
							  re.match('\n', dell[i+1]):
			# merge the string across the middle string
			dell[i-1] = re.sub('\n{4}$', ' ', dell[i-1]) + dell[i+1][1:]
			delltail = dell[i+2:]
			dell = dell[0:i]
			dell.extend(delltail)

	# remove whitespace (linefeeds) on all the strings
	for i in range(len(dell)):
		dell[i] = string.strip(dell[i])

	# no paragraph breaks in the block of text
	if len(dell) == 3:
		pres.append(dell[1])
		return pres

	if not re.search('\(2\)', dell[3]):
		print 'no find'
		#print dell
		#sys.exit()

	# the text is broken into questions (1), (2) etc, with a <ul> surrounding the secondary parts
	if (not re.search('<ul>(?i)', dell[2])) or (not re.search('</ul>(?i)', dell[len(dell)-1])):
		print '<ul> things not conforming to pattern in part-question'
		#print dell
		#sys.exit()


	# break out the numbers
	p1 = re.findall('^([\s\S]*?\S)\s*?\(1\)\s*?(\S[\s\S]*?)$', dell[1])
	if p1:
		pres.append(p1[0][0])
		pres.append('(1) ' + p1[0][1])
	else:
		print 'no first number match'
		pres.append(dell[1])

	# do the rest of the paragraphs and look for numbers
	for i in range(3, len(dell)-1, 2):
		if p1:
			pi = re.findall('^\((\d+?)\)\s*(\S[\s\S]*?)$', dell[i])
			if pi:
				pin = string.atoi(pi[0][0])
				if pin != len(pres):
					print 'numbers not consecutive'
					p1 = None
			else:
				print 'no number match'
				print dell[i]
				p1 = None
		if p1:
			pres.append('(%d) %s' % (len(pres), pi[0][1]))
		else:
			pres.append(dell[i])


	return pres


def FixQuestion(text):
	res = StringIO.StringIO()

	# sort out qnums
	bqnum = re.subn('\[(\d+?)\]', '<qcode qnum="\\1"/>', text)
	text = bqnum[0]
	if bqnum[1] != 0:
		ntext = QuestionBreakIntoParagraphs(text)
		for nt in ntext:
			res.write('<p>')
			res.write(nt)
			res.write('</p>\n')

	else:
		res.write("<error>qnum missing</error>\n")


	sres = res.getvalue()
	res.close()
	return sres




# replies can have tables

def ReplyBreakIntoParagraphs(text):
	nfj = re.split('(<table [\s\S]*?</table>|</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', text)

	# break up into sections separated by paragraph breaks
	dell = []
	spc = ''
	for nf in nfj:
		if re.match('(</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', nf):
			spc = spc + nf
		elif re.search('\S', nf):
			dell.append(spc)
			spc = ''
			dell.append(nf)
	if not spc:
		spc = ''
	dell.append(spc)

	# remove whitespace (linefeeds) on all the strings
	for i in range(len(dell)):
		dell[i] = string.strip(dell[i])

	pres = []
	for i in range(1, len(dell)-1, 2):
		if re.search('<table (?i)', dell[i]):
			pres.append('<table>Stuff</table>')
		else:
			pres.append(dell[i])
	return pres


def FixReply(text):
	res = StringIO.StringIO()

	if not re.search('\[\d+?\]', text):
		ntext = ReplyBreakIntoParagraphs(text)
		for nt in ntext:
			res.write('<p>')
			res.write(nt)
			res.write('</p>\n')
	else:
		res.write("<error>qnum present in answer</error>\n")
		print 'qnum present in answer'


	sres = res.getvalue()
	res.close()
	return sres
