#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from parlphrases import parlPhrases
from miscfuncs import SplitParaIndents

from filterwransreplytable import ParseTable

from miscfuncs import FixHTMLEntities

from filtersentence import FilterSentence
from filtersentence import PhraseTokenize

# lots of work to do here on the internal structure of each speech

pcode = [ '', 'indent', 'italic', 'indentitalic' ]

rehousediv = re.compile('<i>The House divided:</i> Ayes (\d+), Noes (\d+)\.$')
rehousedivmarginal = re.compile('house divided.*?ayes.*?Noes')

def ProceduralTextDetector(tp, tpcode):
	#<i>The House divided:</i> Ayes 335, Noes 129.
	hdg = rehousediv.match(tp)
	if hdg: 
		return '<p class="announce-division" ayes="%s" noes="%s">%s</p>' % (hdg.group(1), hdg.group(2), FixHTMLEntities(tp))

	if rehousedivmarginal.search(tp): 
		print "Marginal case: %s" % tp

	return ''
	

# this is the main function.
def FilterDebateSpeech(qs):

	# split into paragraphs.  The second results is a parallel array of bools
	(textp, textpindent) = SplitParaIndents(qs.text)

	qs.stext = [ ]
	i = 0

	# go through the rest of the paragraphs
	while i < len(textp):
		# deal with tables
		if re.match('<table(?i)', textp[i]):
			qs.stext.append(ParseTable(textp[i]))


		# nothing special about this paragraph (except it may be indented)
		else:
			tpx = ProceduralTextDetector(textp[i], textpindent[i])

			# otherwise it's a line of standard text that may be italicked 
			if not tpx: 
				pht = PhraseTokenize(qs, textp[i])
				tpx = pht.GetPara(pcode[textpindent[i]])
				
			qs.stext.append(tpx)

		i = i + 1



