#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

from miscfuncs import FixHTMLEntities
from miscfuncs import SplitParaIndents


# standard multi-paragraph format reads:
# To ask ... (1) how many ...;  [138423]
# <P>
# <P>
# <UL>(2) what the ... United Kingdom;  [138424]
# <P>
# (3) if she will ... grants.  [138425]<P></UL>

# we break this into separate paragraphs and discover that the final ones are indentent.
# the other question form is as a single paragraph
def FilterQuestion(text):

	# split into paragraphs.  The second results is a parallel array of bools
	(textp, textpindent) = SplitParaIndents(text)
	if not textp:
		raise Exception, ' no paragraphs in result '

	textn = []

	# multi-part type
	if len(textp) > 1:
		# find the first (1)
		gbone = re.search('\(1\)', textp[0])
		if not gbone:
			print text
			raise Exception, ' no (1) in first multipart para '
		textn.append(textp[0][:gbone.span(0)[0]])
		textn.append(textp[0][gbone.span(0)[1]:])

		# scan through the rest of the numbered paragraphs
		for i in range(1, len(textp)):
			gbnum = re.search('^\((\d+)\)', textp[i])
			if (not gbnum) or (string.atoi(gbnum.group(1)) != i + 1):
				print text
				print textp
				raise Exception, ' no number match in paragraph '
			textn.append(textp[i][gbnum.span(0)[1]:])


	# single paragraph type
	else:
		textn.append(textp[0])


	# put the paragraphs back in together, with their numbering
	# should do some blocking out of this, especially the "to ask" phrase.
	firstpara = FixHTMLEntities(textn[0])
	stext = [ '<p>%s</p>' % firstpara ]

	# should do some blocking out of this
	for i in range(1, len(textn)):
		stext.append('<p class="numindent">(%d) %s</p>' % (i, FixHTMLEntities(textn[i])))

	return stext

