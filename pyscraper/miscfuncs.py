#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

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

if (not os.path.isdir(toppath)):
        raise Exception, 'Data directory %s does not exist, please create' % (toppath)
# print "Data directory (set in miscfuncs.py): %s" % toppath

# temporary files are stored here
tmppath = os.path.join(toppath, "tmp")
if (not os.path.isdir(tmppath)):
        os.mkdir(tmppath)

# migrate names to forms without pw
if os.path.exists(toppath + "/pwcmpages"):
        raise Exception, 'Folders have changed name, and you need to rescrape everything anyway.  Clear out %s and start again.' % (toppath)

# find raw data path
rawdatapath = os.path.join(os.getcwd(), "../rawdata")
if (not os.path.isdir(toppath)):
        raise Exception, 'Raw data directory %s does not exist, you\'ve not got a proper checkout from CVS.' % (toppath)

# import lower down so we get the top-path into the contextexception file
from contextexception import ContextException

# The names of entities and what they are are here:
# http://www.bigbaer.com/reference/character_entity_reference.htm
# Make sure you update WriteXMLHeader below also!
# And update website/proto decode.inc
entitymap = {
        '&nbsp;':' ',
        '&':'&amp;',

        # see http://www.cs.tut.fi/~jkorpela/www/windows-chars.html for a useful, if now dated in
        # terms of browser support for the proper solutions, info on windows ndash/mdash (150/151)
        '&#150;':'&ndash;',  # convert windows latin-1 extension ndash into a real one
        '&#151;':'&mdash;',  # likewise mdash
        '&#161;':'&iexcl;',  # inverted exclamation mark
        '&#247;':'&divide;', # division sign

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
        '&#243;':'&oacute;',   # this is o-acute

        '&#237;':'&iacute;', # this is i-acute
        '&#238;':'&icirc;', # this is i-circumflex

        '&#231;':'&ccedil;',   # this is cedilla
        '&#199;':'&Ccedil;',   # this is capital C-cedilla
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

		'&#039;':"'",   # posession apostrophe
        "&#8364;":'&euro;', # this is euro currency
        '&lquo;':"'",
        '&rquo;':"'",
}
entitymaprev = entitymap.values()


def StripAnchorTags(text):
        raise Exception, "I've never called this function, so test it"

        abf = re.split('(<[^>]*>)', text)

        ret = ''
	for ab in abf:
		if re.match('<a[^>]*>(?i)', ab):
                        pass

		elif re.match('</a>(?i)', ab):
			pass

                else:
                        ret = ret + ab

        return ret


def WriteCleanText(fout, text):
    	abf = re.split('(<[^>]*>)', text)
	for ab in abf:
		# delete comments and links
		if re.match('<!-[^>]*?->', ab):
			pass

		# spaces only inside tags
		elif re.match('<[^>]*>', ab):
			fout.write(re.sub('\s', ' ', ab))

		# take out spurious > symbols and dos linefeeds
		else:
			fout.write(re.sub('>|\r', '', ab))


# Legacy patch system, use patchfilter.py and patchtool now
def ApplyFixSubstitutions(text, sdate, fixsubs):
	for sub in fixsubs:
		if sub[3] == 'all' or sub[3] == sdate:
			(text, n) = re.subn(sub[0], sub[1], text)
			if (sub[2] != -1) and (n != sub[2]):
				print sub
				raise Exception, 'wrong number of substitutions %d on %s' % (n, sub[0])
	return text


# this only accepts <sup> and <i> tags
def StraightenHTMLrecurse(stex, stampurl):
	# split the text into <i></i> and <sup></sup> and <sub></sub>
	qisup = re.search('(<i>(.*?)</i>)(?i)', stex)
	if qisup:
		qtag = ('<i>', '</i>')
	else:
		qisup = re.search('(<sup>(.*?)</sup>)(?i)', stex)
		if qisup:
			qtag = ('<sup>', '</sup>')
                else:
                        qisup = re.search('(<sub>(.*?)</sub>)(?i)', stex)
                        if qisup:
                                qtag = ('<sub>', '</sub>')

	if qisup:
		sres = StraightenHTMLrecurse(stex[:qisup.span(1)[0]], stampurl)
		sres.append(qtag[0])
		sres.extend(StraightenHTMLrecurse(qisup.group(2), stampurl))
		sres.append(qtag[1])
		sres.extend(StraightenHTMLrecurse(stex[qisup.span(1)[1]:], stampurl))
		return sres

	sres = re.split('(&[a-z]*?;|&#\d+;|"|\xa3|&|\x01|\x0e|\x14|<[^>]*>|<|>)', stex)
	for i in range(len(sres)):
                #print "sresi ", sres[i], "\n"
                #print "-----------------------------------------------\n"

		if not sres[i]:
			pass
		elif sres[i][0] == '&':

                        # Put new entities in entitymap if you can, or special cases
                        # in this if statement.

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
			elif sres[i] == '&ldquo;':
				sres[i] = '&quot;'
			elif sres[i] == '&rdquo;':
				sres[i] = '&quot;'
			else:
				raise Exception, sres[i] + ' unknown ent'
				sres[i] = 'UNKNOWN-ENTITY'

		elif sres[i] == '"':
			sres[i] = '&quot;'

                # junk chars sometimes get in
		elif sres[i] == '\x01':
			sres[i] = ''
		elif sres[i] == '\x0e':
			sres[i] = ' '
		elif sres[i] == '\x14':
			sres[i] = ' '

		elif sres[i] == '\xa3':
			sres[i] = '&pound;'

		elif sres[i] == '<i>':
			sres[i] = '' # 'OPEN-i-TAG-OUT-OF-PLACE'
		elif sres[i] == '</i>':
			sres[i] = '' # 'CLOSE-i-TAG-OUT-OF-PLACE'

		elif re.match('<xref locref=\d+>', sres[i]): # what is this? wrans 2003-05-13 has one
			sres[i] = ''

		# allow brs through
		elif re.match('<br>(?i)', sres[i]):
			sres[i] = '<br/>'

		elif sres[i][0] == '<' or sres[i][0] == '>':
                        print "Part:", sres[i][0]
                        print "All:",sres[i]
                        print "stex:", stex
                        print "raising"
			raise ContextException('tag %s tag out of place in %s' % (sres[i], stex), stamp=stampurl, fragment=stex)

	return sres


def FixHTMLEntitiesL(stex, signore='', stampurl=None):
	# will formalize this into the recursion later
	if signore:
		stex = re.sub(signore, '', stex)
	return StraightenHTMLrecurse(stex, stampurl)

def FixHTMLEntities(stex, signore='', stampurl=None):
	return string.join(FixHTMLEntitiesL(stex, signore, stampurl), '')





# The lookahead assertion (?=<table) stops matching tables when another begin table is reached
restmatcher = '</?p(?: class[= ]"tabletext")?>|</?ul>|<br>|</?font[^>]*>(?i)'
reparts = re.compile('(<table[\s\S]*?(?:</table>|(?=<table))|' + restmatcher + ')')
reparts2 = re.compile('(<table[^>]*?>|' + restmatcher + ')')

retable = re.compile('<table[\s\S]*?</table>(?i)')
retablestart = re.compile('<table[\s\S]*?(?i)')
reparaspace = re.compile('</?p(?: class[= ]"tabletext")?>|</?ul>|<br>|</?font[^>]*>|<table[^>].*>$(?i)')
reparaempty = re.compile('\s*(?:<i>)?</i>\s*$|\s*$(?i)')
reitalif = re.compile('\s*<i>\s*$(?i)')

# Break text into paragraphs.
# the result alternates between lists of space types, and strings
def SplitParaSpace(text, stampurl):
	res = []

	# used to detect over breaking in spaces
	bprevparaalone = True

	# list of space objects, list of string
	spclist = []
	pstring = ''
	parts = reparts.split(text)
	newparts = []
	# split up the start <table> bits without end </table> into component parts
	for nf in parts:

		# a tiny bit of extra splitting up as output
		if retablestart.match(nf) and not retable.match(nf):
			newparts.extend(reparts2.split(nf))
		else:
			newparts.append(nf)

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

		else:
			lnf = re.sub("\s+", " ", nf)
			if pstring:
				pstring = pstring + " " + string.strip(lnf)
			else:
				pstring = string.strip(lnf)


		# check that paragraphs have some text
		if re.match('(?:<[^>]*>|\s)*$', pstring):
			print "\nspclist:", spclist
			print "\npstring:", pstring
			print "\nthe text:", text
			raise ContextException('no text in paragraph', stamp=stampurl, fragment=pstring)

		# check that paragraph spaces aren't only font text, and have something
		# real in them, unless they are breaks because of tables
		if not (bprevparaalone or bthisparaalone):
			bnonfont = False
			for sl in spclist:
				if not re.match('</?font[^>]*>(?i)', sl):
					bnonfont = True
			if not bnonfont:
				print "text:", text
				print "spclist:", spclist
				print "pstring", pstring
				print "----------"
				print "nf", nf
				print "----------"
				raise ContextException('font found in middle of paragraph should be a paragraph break or removed', stamp=stampurl, fragment=pstring)
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
def SplitParaIndents(text, stampurl):
	dell = SplitParaSpace(text, stampurl)
        #print "dell", dell

	res =  [ ]
	resdent = [ ]
	bIndent = 0
	for i in range(len(dell)):
		if (i % 2) == 0:
			for sp in dell[i]:
				if re.match('<ul>(?i)', sp):
					if bIndent:
						print text
						raise ContextException(' already indentented ', stamp=stampurl, fragment=sp)
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







