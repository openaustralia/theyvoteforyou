#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from resolvemembernames import memberList
from parlphrases import parlPhrases
from miscfuncs import FixHTMLEntities
from miscfuncs import FixHTMLEntitiesL
from miscfuncs import SplitParaIndents

from filterwransemblinks import rreglink
from filterwransemblinks import rregemail


rewdsl =  [ rreglink, rregemail,
		'\$?\d+(?:,\d+)*\.?\d*',
		'(?:[\w\'\-/%%]|&#\d+;)+',
		'\$\d+\.?\d*',
		'&quot;',
		'&amp;',
		'</?i>',
		'</?sup>',
		'\[\w+\]',
		'[();&".,:]',
		'\*+',
		'='
	  ]

rewds = re.compile('(%s)' % string.join(rewdsl, '|'))
#print rewds.findall('amounted to $2.479 billion.')
#sys.exit()

# this is highly experimental methods here, of tokenizing the words
def FilterSentence(text):
	return
	swords = rewds.split(text)
	for sw in swords:
		if not re.match('\s*$', sw):
			if not rewds.match(sw):
				print text
				print sw
				sys.exit()

