#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from resolvemembernames import memberList
from parlphrases import parlPhrases
from miscfuncs import SplitParaIndents

from filterwransreplytable import ParseTable

from filtersentence import FilterSentence
from filtersentence import PhraseTokenize

# lots of work to do here on the internal structure of each speech

pcode = [ '', 'indent', 'italic', 'indentitalic' ]

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
			i = i+1
			continue


		# nothing special about this paragraph (except it may be indented)
		pht = PhraseTokenize(qs, textp[i])
		qs.stext.append(pht.GetPara(pcode[textpindent[i]]))
		i = i+1


