#! /usr/bin/python2.3
import re
import sys
import string

def ApplyFixSubstitutions(text, sdate, fixsubs):
	for sub in fixsubs:
		if sub[3] == 'all' or sub[3] == sdate:
			(text, n) = re.subn(sub[0], sub[1], text)
			if (sub[2] != -1) and (n != sub[2]):
				raise Exception, 'wrong substitutions %d on %s' % (n, sub[0])
	return text


# this only accepts <sup> and <i> tags
def StraightenHTMLrecurse(stex):

	# split the text into <i></i> and <sup></sup>
	qisup = re.search('(<i>(.*?)</i>)(?i)', stex)
	if qisup:
		qtag = ('<i>', '</i>')
	else:
		qisup = re.search('(<sup>([\s\S]*?)</sup>)(?i)', stex)
		if qisup:
			qtag = ('<sup>', '</sup>')

	if qisup:
		sres = StraightenHTMLrecurse(stex[:qisup.span(1)[0]])
		sres.append(qtag[0])
		sres.extend(StraightenHTMLrecurse(qisup.group(2)))
		sres.append(qtag[1])
		sres.extend(StraightenHTMLrecurse(stex[qisup.span(1)[1]:]))
		return sres

	sres = re.split('(&[a-z]*?;|&#\d+;|"|&|<[^>]*>|<|>)', stex)
	for i in range(len(sres)):
		if not sres[i]:
			pass
		elif sres[i][0] == '&':
			if sres[i] == '&#150;':
				sres[i] = '-'
			elif sres[i] == '&#151;':
				sres[i] = ' -- '
			elif sres[i] == '&#163;':
				sres[i] = 'POUNDS'
			elif sres[i] == '&#233;':   # this is e-acute
				sres[i] = 'e'
			elif sres[i] == '&#232;':   # this is e-grave
				sres[i] = 'e'
			elif sres[i] == '&#234;':   # this is e-hat
				sres[i] = 'e'
			elif sres[i] == '&#235;':   # this is e-double-dot
				sres[i] = 'e'
			elif sres[i] == '&#225;':   # this is a-acute
				sres[i] = 'a'
			elif sres[i] == '&#224;':   # this is a-acute
				sres[i] = 'a'
			elif sres[i] == '&#244;':   # this is o-hat
				sres[i] = 'o'
			elif sres[i] == '&#252;':   # this is u-double-dot
				sres[i] = 'u'
			elif sres[i] == '&#177;':   # this is +/- symbol
				sres[i] = '+/-'
			elif sres[i] == '&#188;':   # this is one quarter symbol
				sres[i] = '1/4'
			elif sres[i] == '&#189;':   # this is one half symbol
				sres[i] = '1/2'
			elif sres[i] == '&#190;':   # this is three quarter symbol
				sres[i] = '3/4'
			elif sres[i] == '&#176;':   # this is the degrees
				sres[i] = 'DEGREES'
			elif sres[i] == '&#95;':    # this is underscore symbol
				sres[i] = '_'
			elif sres[i] == '&#183;':   # this is an unknown symbol
				sres[i] = '&quot'
			elif sres[i] == '&pound;':
				sres[i] = 'POUNDS'
			elif sres[i] == '&nbsp;':
				sres[i] = ' '
			elif sres[i] == '&':
				sres[i] = '&amp;'
			elif sres[i] == '&quot;':
				pass
			elif sres[i] == '&amp;':
				pass
			elif sres[i] == '&lt;':
				pass
			elif sres[i] == '&gt;':
				pass
			else:
				print sres[i] + ' unknown ent'
				sres[i] = 'UNKNOWN-ENTITY'

		elif sres[i] == '"':
			sres[i] = '&quot;'

		elif sres[i] == '<i>':
			sres[i] = 'OPEN-i-TAG-OUT-OF-PLACE'
		elif sres[i] == '</i>':
			sres[i] = 'CLOSE-i-TAG-OUT-OF-PLACE'

		elif sres[i][0] == '<' or sres[i][0] == '>':
			print sres[i] + ' tag out'
			sres[i] = 'TAG-OUT-OF-PLACE'

	return sres


def FixHTMLEntitiesL(stex, signore=''):
	# will formalize this into the recursion later
	if signore:
		stex = re.sub(signore, '', stex)
	return StraightenHTMLrecurse(stex)

def FixHTMLEntities(stex):
	return string.join(StraightenHTMLrecurse(stex), '')






retable = re.compile('<table[\s\S]*?</table>(?i)')
reparaspace = re.compile('</?p>|</?ul>|<br>|</?font[^>]*>(?i)')
reparaempty = re.compile('\s*(?:<i>)?</i>\s*|\s*$(?i)')
reitalif = re.compile('\s*<i>\s*$(?i)')

# Break text into paragraphs.
# the result alternates between lists of space types, and strings
def SplitParaSpace(text):
	res = []

	# used to detect over breaking in spaces
	bprevparaalone = True

	# list of space objects, list of string
	spclist = []
	pstring = ''
	for nf in re.split('(<table[\s\S]*?</table>|</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', text):

		# get rid of blank and boring paragraphs
		if reparaempty.match(nf):
			if pstring and re.search('\S', nf):
				print text
				print '---' + pstring
				print '---' + nf
				raise Exception, ' it carried across empty para '
			continue

		# list of space type objects
		if reparaspace.match(nf):
			spclist.append(nf)
			continue

		# sometimes italics are hidden among the paragraph choss
		# bring forward onto the next string
		if reitalif.match(nf):
			if pstring:
				print text
				print spclist
				print pstring
				raise Exception, ' double italic in paraspace '
			pstring = '<i>'
			continue


		# we now have a string of a paragraph which we are putting into the list.

		# table type
		bthisparaalone = False
		if retable.match(nf):
			if pstring:
				print text
				raise Exception, ' non-empty preceding string '
			pstring = nf
			bthisparaalone = True

		elif pstring:
			pstring = pstring + string.strip(nf)
		else:
			pstring = string.strip(nf)


		# check that paragraphs have some text
		if re.match('(?:<[^>]*>|\s)*$', pstring):
			print text
			print spclist
			print pstring
			raise Exception, ' no text in paragraph '

		# check that paragraph spaces aren't only font text, and have something
		# real in them, unless they are breaks because of tables
		if not (bprevparaalone or bthisparaalone):
			bnonfont = False
			for sl in spclist:
				if not re.match('</?font[^>]*>(?i)', sl):
					bnonfont = True
			if not bnonfont:
				print text
				print spclist
				print pstring
				raise Exception, ' font only in paragraph break '
		bprevparaalone = bthisparaalone


		# put the preceding space, then the string into output list
		res.append(spclist)
		res.append(pstring)

		spclist = [ ]
		pstring = ''

	# findal spaces into the output list
	res.append(spclist)

	return res


# Break text into paragraphs and mark the paragraphs according to their <ul> indentation
def SplitParaIndents(text):
	dell = SplitParaSpace(text)

	res =  [ ]
	resdent = [ ]
	bIndent = False
	for i in range(len(dell)):
		if (i % 2) == 0:
			for sp in dell[i]:
				if re.match('<ul>(?i)', sp):
					if bIndent:
						print text
						raise Exception, ' already indentented '
					bIndent = True
				elif re.match('</ul>(?i)', sp):
					# no error 
					#if not bIndent:
					#	raise Exception, ' already not-indentented '
					bIndent = False
		else:
			resdent.append(bIndent)
			res.append(dell[i])
	if bIndent:
		print text
		raise ' still indented after last space '
	return (res, resdent)

