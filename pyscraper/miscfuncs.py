#! /usr/bin/python2.3
import re
import sys
import string
import os

# make the top path data directory value
toppath = os.path.abspath(os.path.expanduser('~/pwdata/'))
if os.name == 'nt':  # the case of julian developing on a university machine.  
    toppath = os.path.abspath('../../pwdata')
    if re.search('\.\.', toppath):
        toppath = 'C:\\pwdata'
        
print "Data directory (set in miscfuncs.py): %s" % toppath
if (not os.path.isdir(toppath)):
    raise Exception, 'Directory does not exist, please create'

entitymap = {
        '&nbsp;':' ',
        '&':'&amp;',

        '&#150;':'&ndash;',
        '&#151;':' &mdash; ',

        '&#232;':'&egrave;',   # this is e-grave
        '&#233;':'&eacute;',   # this is e-acute
        '&#234;':'&ecirc;',   # this is e-hat
        '&#235;':'&euml;',   # this is e-double-dot

        '&#224;':'&agrave;',   # this is a-grave
        '&#225;':'&aacute;',   # this is a-acute
        '&#226;':'&acirc;',   # this is a-hat as in debacle

        '&#244;':'&ocirc;',   # this is o-hat
        '&#246;':'&ouml;',   # this is o-double-dot
        '&#214;':'&Ouml;',   # this is capital o-double-dot

        '&#231;':'&ccedil;',   # this is cedilla
        '&#252;':'&uuml;',   # this is u-double-dot
        '&#241;':'&ntilde;',   # spanish n as in Senor

        '&#177;':'&plusmn;',   # this is +/- symbol
        '&#163;':'&pound;',   # UK currency
        '&#183;':'&middot;',   # middle dot
        '&#176;':'&deg;',   # this is the degrees

        '&#188;':'&frac14;',   # this is one quarter symbol
        '&#189;':'&frac12;',   # this is one half symbol
        '&#190;':'&frac34;',   # this is three quarter symbol

        '&#95;':'_',    # this is underscore symbol
}
entitymaprev = entitymap.values()



def WriteCleanText(fout, text):
    	abf = re.split('(<[^>]*>)', text)
	for ab in abf:
		# delete comments and links
		if re.match('<!-[^>]*?->', ab):
			pass

		elif re.match('<a[^>]*>(?i)', ab):
			# this would catch if we've actually found a link
			if not re.match('<a name\s*?=\s*\S*?\s*?>(?i)', ab):
				print 'Anchor left in clean text: %s' % ab
				fout.write(re.sub('\s', ' ', ab))

		elif re.match('</a>(?i)', ab):
			pass

		# spaces only inside tags
		elif re.match('<[^>]*>', ab):
			fout.write(re.sub('\s', ' ', ab))

		# take out spurious > symbols and dos linefeeds
		else:
			fout.write(re.sub('>|\r', '', ab))


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

	sres = re.split('(&[a-z]*?;|&#\d+;|"|&|<[^>]*>|<|>)', stex)
	for i in range(len(sres)):
		if not sres[i]:
			pass
		elif sres[i][0] == '&':

                        # Put new entities in entitymap if you can, or special cases
                        # in this if statement.

			# The names of entities and what they are are here:
			# http://www.bigbaer.com/reference/character_entity_reference.htm
			# Make sure you update WriteXMLHeader below also!

                        if sres[i] in entitymap:
                                sres[i] = entitymap[sres[i]]
                        elif sres[i] in entitymaprev:
                                pass
			elif sres[i] == '&mdash;': # special case as entitymap maps it with spaces
				pass
			elif sres[i] == '&quot;':
				pass
			elif sres[i] == '&amp;':
				pass
			elif sres[i] == '&lt;':
				pass
			elif sres[i] == '&gt;':
				pass
			else:
				raise Exception, sres[i] + ' unknown ent'
				sres[i] = 'UNKNOWN-ENTITY'

		elif sres[i] == '"':
			sres[i] = '&quot;'

		elif sres[i] == '<i>':
			sres[i] = 'OPEN-i-TAG-OUT-OF-PLACE'
		elif sres[i] == '</i>':
			sres[i] = 'CLOSE-i-TAG-OUT-OF-PLACE'

		elif sres[i][0] == '<' or sres[i][0] == '>':
			print sres[i] + ' tag out of place '
			sres[i] = 'TAG-OUT-OF-PLACE'
			#raise Exception, ' now'

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
	bIndent = 0
	for i in range(len(dell)):
		if (i % 2) == 0:
			for sp in dell[i]:
				if re.match('<ul>(?i)', sp):
					if bIndent:
						print text
						raise Exception, ' already indentented '
					bIndent = 1
				elif re.match('</ul>(?i)', sp):
					# no error
					#if not bIndent:
					#	raise Exception, ' already not-indentented '
					bIndent = 0
			continue

		# we have the actual text between the spaces
		# we might have full italics indent style
		# (we're ignoring fonts for now)

		# separate out italics type paragraphs
		tex = dell[i]
		cindent = bIndent

		qitbod = re.match('<i>([\s\S]*?)</i>[.:]?$', tex)
		if qitbod:
			tex = qitbod.group(1)
			cindent = cindent + 2

		res.append(tex)
		resdent.append(cindent)

	#if bIndent:
	#	print text
	#	raise ' still indented after last space '
	return (res, resdent)

def WriteXMLHeader(fout):
	fout.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
	
	# These entity definitions for latin-1 chars are from here:
	# http://www.w3.org/TR/REC-html40/sgml/entities.html
	fout.write('''

<!DOCTYPE publicwhip 
[

<!ENTITY ndash   "&#8211;">
<!ENTITY mdash   "&#8212;" >

<!ENTITY egrave "&#232;" >
<!ENTITY eacute "&#233;" >
<!ENTITY ecirc  "&#234;" >
<!ENTITY euml   "&#235;" >
<!ENTITY agrave "&#224;" >
<!ENTITY aacute "&#225;" >
<!ENTITY acirc  "&#226;" >
<!ENTITY ocirc  "&#244;" >
<!ENTITY ouml   "&#246;" >
<!ENTITY Ouml   "&#214;" >
<!ENTITY ccedil "&#231;" >
<!ENTITY uuml   "&#252;" >
<!ENTITY ntilde "&#241;" >

<!ENTITY plusmn "&#177;" >
<!ENTITY pound  "&#163;" >
<!ENTITY middot "&#183;" >
<!ENTITY deg    "&#176;" >

<!ENTITY frac14 "&#188;" >
<!ENTITY frac12 "&#189;" >
<!ENTITY frac34 "&#190;" >
]>

''');

