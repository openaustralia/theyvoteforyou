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


# lots of work to do here on the internal structure of each speech

# this is the main function.
def FilterDebateSpeech(qs):
	# break into paragraphs
	nfj = re.split('(<table[\s\S]*?</table>|</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', qs.text)

	# break up into sections separated by paragraph breaks
	# these alternate in the list, with the spaces already as lists
	dell = []
	spclist = []
	spclistinter = []
	for nf in nfj:
		# list of space type objects
		if re.match('</?p>|</?ul>|<br>|</?font[^>]*>(?i)', nf):
			spclist.append(nf)

		# sometimes italics are hidden among the paragraph choss, and we want to bring it forward
		elif re.match('\s*<i>\s*$', nf):
			spclistinter.append(string.strip(nf))

		# a non space type
		elif re.search('\S', nf):
			# bring the string together with choss in between paragraph stuff
			pstring = string.strip(nf)

			# pull forward any italics problems
			if spclistinter:
				spclistinter.append(pstring)
				pstring = string.join(spclistinter, '')
				spclistinter = [ ]

			# table detected
			if re.search('<table(?i)', pstring):
				print nf
				print ' table in debate '

			dell.append(spclist)
			dell.append(pstring)

	dell.append(spclist)

	qs.stext = [ ]

	# the resulting list of paragraphs
	# we now have the paragraphs interspersed with inter-paragraph symbols
	# for now ignore these inter-paragraph symbols and parse the paragraphs themselves
	n = (len(dell)-1) / 2
	for i in range(n):
		# this puts a list into the result
		i2 = i*2 + 1

		sres = [ '<p>' ]
		sres.extend(FixHTMLEntitiesL(dell[i2]))
		sres.append('</p>')
		lstex = string.join(sres, '')
		qs.stext.append(lstex)


