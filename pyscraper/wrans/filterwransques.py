#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

from miscfuncs import FixHTMLEntities
from miscfuncs import SplitParaIndents

from contextexception import ContextException

# standard multi-paragraph format reads:
# To ask ... (1) how many ...;  [138423]
# <P>
# <P>
# <UL>(2) what the ... United Kingdom;  [138424]
# <P>
# (3) if she will ... grants.  [138425]<P></UL>

def ExtractQnum(tex, stampurl):
	qn = re.match('(.*?)\s*\[?(\d+R?)\]$', tex)
	if not qn:
		# print tex, 'qnum not at end of line'
		return (tex, '0')

	isqn = re.search('\[(\d+R?)\]', qn.group(1))
	if isqn:
		print tex
		print 'A colnum may be removing a necessary <p> tag before the (2)'
		raise ContextException('qnum in middle of index block', stamp=stampurl, fragment=isqn.group(1))
	return (qn.group(1), qn.group(2))


# we break this into separate paragraphs and discover that the final ones are indentent.
# the other question form is as a single paragraph
def FilterQuestion(text, sdate, stampurl):
	# split into paragraphs.  The second results is a parallel array of bools
	(textp, textpindent) = SplitParaIndents(text, stampurl)
	if not textp:
		raise ContextException('no paragraphs in result', stamp=stampurl, fragment=text)

	textn = [ ]

        # special case exceptions.  Indented text in questions nearly always marks numbered sections 
        # - rarely is it quoted text like this:
        # 2002-11-07 - happened again.  Did a patch.
        if sdate == '2004-01-05' and len(textp) > 1 and re.search('"Given that 98.5 per cent', text):
            # if this happens a lot - do this properly, so the indented bit gets its own paragraph
            textp = (string.join(textp, " "),)
            textpindent = (0,)

	# multi-part type
	if len(textp) > 1:
		# find the first (1)
		gbone = re.search('\(1\)', textp[0])
		if not gbone:
			raise ContextException('no (1) in first multipart para', fragment=text, stamp=stampurl)
		textn.append( (textp[0][:gbone.span(0)[0]], '') )
		eqnum = ExtractQnum(textp[0][gbone.span(0)[1]:], stampurl)
		textn.append(eqnum)

		# scan through the rest of the numbered paragraphs
		for i in range(1, len(textp)):
			gbnum = re.search('^\((\d+)\)', textp[i])
			if not gbnum:
				raise ContextException('no number match in paragraph', fragment=textp[i], stamp=stampurl)
			gbnumseq = string.atoi(gbnum.group(1))
			if gbnumseq != i + 1:
				raise ContextException('paragraph numbers not consecutive', fragment=textp[i], stamp=stampurl)
			eqnum = ExtractQnum(textp[i][gbnum.span(0)[1]:], stampurl)
			textn.append(eqnum)


	# single paragraph type
	else:
		eqnum = ExtractQnum(textp[0], stampurl)
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

