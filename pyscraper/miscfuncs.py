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
		qisup = re.search('(<sup>(.*?)</sup>)(?i)', stex)
		if qisup:
			qtag = ('<sup>', '</sup>')

	if qisup:
		sres = StraightenHTMLrecurse(stex[:qisup.span(1)[0]])
		sres.append(qtag[0])
		sres.extend(StraightenHTMLrecurse(qisup.group(2)))
		sres.append(qtag[1])
		sres.extend(StraightenHTMLrecurse(stex[qisup.span(1)[1]:]))
		return sres

	sres = re.split('(&\S*?;|"|&|<[^>]*>|<|>)', stex)
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
				print sres[i]
				sres[i] = 'UNKNOWN-ENTITY'

		elif sres[i] == '"':
			sres[i] = '&quot;'

		elif sres[i] == '<i>':
			sres[i] = 'OPEN-i-TAG-OUT-OF-PLACE'
		elif sres[i] == '</i>':
			sres[i] = 'CLOSE-i-TAG-OUT-OF-PLACE'

		elif sres[i][0] == '<' or sres[i][0] == '>':
			print sres[i]
			sres[i] = 'TAG-OUT-OF-PLACE'

	return sres



def FixHTMLEntities(stex):
	return string.join(StraightenHTMLrecurse(stex), '')

