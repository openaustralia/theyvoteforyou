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

def ExtractQnum(tex):
	qn = re.match('(.*?)\s*\[?(\d+R?)\]$', tex)
	if not qn:
		# print tex, 'qnum not at end of line'
		return (tex, '0')

	if re.search('\[(\d+R?)\]', qn.group(1)):
		print tex
		print 'qnum in middle of index block'
	return (qn.group(1), qn.group(2))


# we break this into separate paragraphs and discover that the final ones are indentent.
# the other question form is as a single paragraph
def FilterQuestion(text, sdate):
	# split into paragraphs.  The second results is a parallel array of bools
	(textp, textpindent) = SplitParaIndents(text)
	if not textp:
		raise Exception, ' no paragraphs in result '

	textn = [ ]

        # special case exceptions.  Indented text in questions nearly always marks numbered sections 
        # - rarely is it quoted text like this:
        if sdate == '2004-01-05' and len(textp) > 1 and re.search('"Given that 98.5 per cent', text):
            # if this happens a lot - do this properly, so the indented bit gets its own paragraph
            textp = (string.join(textp, " "),)
            textpindent = (0,)

	# multi-part type
	if len(textp) > 1:
		# find the first (1)
		gbone = re.search('\(1\)', textp[0])
		if not gbone:
			print text
			raise Exception, ' no (1) in first multipart para '
		textn.append( (textp[0][:gbone.span(0)[0]], '') )
		eqnum = ExtractQnum(textp[0][gbone.span(0)[1]:])
		textn.append(eqnum)

		# scan through the rest of the numbered paragraphs
		for i in range(1, len(textp)):
			gbnum = re.search('^\((\d+)\)', textp[i])
			if (not gbnum) or (string.atoi(gbnum.group(1)) != i + 1):
				print textp
				raise Exception, ' no number match in paragraph '
			eqnum = ExtractQnum(textp[i][gbnum.span(0)[1]:])
			textn.append(eqnum)


	# single paragraph type
	else:
		eqnum = ExtractQnum(textp[0])
		textn.append(eqnum)


	# put the paragraphs back in together, with their numbering
	# should do some blocking out of this, especially the "to ask" phrase.
	firstpara = FixHTMLEntities(textn[0][0])

	if len(textn) > 1:
		stext = [ '<p>%s</p>' % firstpara ]
		for i in range(1, len(textn)):
			tpara = FixHTMLEntities(textn[i][0])
			stext.append('<p class="numindent" qnum="%s">(%d) %s</p>' % (textn[i][1], i, tpara))

	else:
		stext = [ '<p qnum="%s">%s</p>' % (textn[0][1], firstpara) ]

	return stext

