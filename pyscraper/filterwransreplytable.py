#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from miscfuncs import FixHTMLEntities
from miscfuncs import FixHTMLEntitiesL

regtablejunk = '</?font[^>]*>|</?p>|\n(?i)'



recolsplit = re.compile('(<t[dh][^>]*>[\s\S]*?(?:</t[dh]>|(?=<t[dh][^>]*>)))(?i)')
recolmatch = re.compile('<t[dh](?: colspan=(\d+)(?: align=(center))?)?>\s*([\s\S]*?)\s*(?:</t[dh]>)?$(?i)')
def ParseRow(srow, hdcode):
	# build up the list of entries for this row
	Lscols = [ '<tr> ' ]
	for spcol in recolsplit.split(srow):
		col = recolmatch.match(spcol)
		if col:
			tcolspan = ''
			if col.group(1):
				colspan = ' colspan="%s"' % col.group(1)
			talign = ''
			if col.group(2):
				talign = ' align="center"'
			Lscols.append('<%s%s%s>' % (hdcode, tcolspan, talign))
			Lscols.extend(FixHTMLEntitiesL(col.group(3), '</?font[^>]*>|</?p>|\n|</?center>|</?B>(?i)'))
			Lscols.append('</%s> ' % hdcode)

		# check that the outside text contains nothing but bogus close column tags
		elif re.search('\S', re.sub('</t[dh]>|</font>(?i)', '', spcol)):
			print spcol
			print srow
			raise Exception, ' non column text '
	Lscols.append('</tr>')
	return Lscols


# replies can have tables
def ParseTable(stable):
	# remove the table bracketing
	stable = re.match('<table[^>]*>\s*([\s\S]*?)\s*</table>(?i)', stable).group(1)

	# break into rows, making sure we can deal with non-closed <tr> symbols
	sprows = re.split('(<tr[^>]*>[\s\S]*?(?:</tr>|(?=<tr[^>]*>)))(?i)', stable)

	# build the rows
	stitle = ''
	srows = []
	for sprow in sprows:
		trg = re.match('<tr[^>]*>([\s\S]*?)(?:</tr>)?$(?i)', sprow)
		if trg:
			srows.append(trg.group(1))

		elif re.search('\S', sprow):
			if (not srows) and (not stitle):
				stitle = sprow
			else:
				print sprow
				raise Exception, ' non-row text '


	# take out tags round the title; they're always out of order
	Lstitle = []
	stitle = string.strip(re.sub('</?font[^>]*>|</?p>|\s|<br>|&nbsp;(?i)', '', stitle))
	if stitle:
		ts = re.match('(?:\s|<b>|<center>)+([\s\S]*?)(?:</b>|</center>)+\s*([\s\S]*?)\s*$(?i)', stitle)
		if not ts:
			print ' non-standard table title '
			print stitle
		else:
			Lstitle.append('<caption>')
			Lstitle.extend(FixHTMLEntitiesL(ts.group(1), '</?font[^>]*>|</?p>|\n(?i)'))
			if ts.group(2):
				Lstitle.append(' -- ')
				Lstitle.extend(FixHTMLEntitiesL(ts.group(2), '</?font[^>]*>|</?p>|\n(?i)'))
			Lstitle.append('</caption>\n')


	# split into header and body
	for ih in range(len(srows)):
		if re.search('<td[^>]*>(?i)', srows[ih]):
			break

	# parse out each of batches
	Lshrows = [ ]
	for srow in srows[:ih]:
		Lshrows.append(ParseRow(srow, 'th'))

	Lsdrows = [ ]
	for srow in srows[ih:]:
		Lsdrows.append(ParseRow(srow, 'td'))



	# construct the text for writing the table
	sio = cStringIO.StringIO()

	sio.write('<table>\n')
	if Lstitle:
		sio.write('\t\t')
		map(sio.write, Lstitle)
		sio.write('\n')

	if Lshrows:
		sio.write('\t\t\t<thead>\n')
		for Lsh in Lshrows:
			sio.write('\t\t\t')
			map(sio.write, Lsh)
			sio.write('\n')
		sio.write('\t\t\t</thead>\n')

	sio.write('\t\t\t<tbody>\n')
	for Lsd in Lsdrows:
		sio.write('\t\t\t')
		map(sio.write, Lsd)
		sio.write('\n')
	sio.write('\t\t\t</tbody>\n')

	sio.write('\t\t</table>\n')

	res = sio.getvalue()
	sio.close()

	return res


