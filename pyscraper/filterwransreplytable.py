#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from miscfuncs import FixHTMLEntities
from miscfuncs import FixHTMLEntitiesL

regtablejunk = '</?font[^>]*>|</?p>|\n(?i)'

# replies can have tables
def ParseTable(stable):
	# remove the table bracketing
	stable = re.match('<table[^>]*>\s*([\s\S]*?)\s*</table>(?i)', stable).group(1)

	# break into rows, making sure we can deal with non-closed <tr> symbols
	sprows = re.split('(<tr[^>]*>[\s\S]*?(?:</tr>|(?=<tr>)))(?i)', stable)

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
	stitle = string.strip(re.sub(regtablejunk, '', stitle))
	if stitle:
		ts = re.match('(?:\s|<b>|<center>)+([\s\S]*?)(?:</b>|</center>)+\s*([\s\S]*?)\s*$(?i)', stitle)
		if not ts:
			print stitle
			raise Exception, ' non-standard table 9title'

		Lstitle.append('<div class="tabletitle">')
		Lstitle.extend(FixHTMLEntitiesL(ts.group(1)))
		if ts.group(2):
			Lstitle.append(' -- ')
			Lstitle.extend(FixHTMLEntitiesL(ts.group(2), '</?font[^>]*>|</?p>|\n(?i)'))
		Lstitle.append('</div>\n')


	# write out the rows, th type and then td type
	Lshrows = [ ]
	for ih in range(len(srows)):
		# move onto standard rows
		if re.search('<td[^>]*>(?i)', srows[ih]):
			break

		# build up the list of entries for this row
		Lscols = [ '<tr> ' ]
		for spcol in re.split('(<th[^>]*>[\s\S]*?(?:</th>|(?=<th>)))(?i)', srows[ih]):
			col = re.match('<th(?: colspan=(\d+)(?: align=center)?)?>\s*([\s\S]*?)\s*(?:</th>)?$(?i)', spcol)
			if col:
				if col.group(1):
					Lscols.append('<th colspan="%s">' % col.group(1))
				else:
					Lscols.append('<th>')
				Lscols.extend(FixHTMLEntitiesL(col.group(2), '</?font[^>]*>|</?p>|\n(?i)'))
				Lscols.append('</th> ')

			# check that the outside text contains nothing but bogus close column tags
			elif re.search('\S', re.sub('</th>|</font>(?i)', '', spcol)):
				print spcol
				print srows[ih]
				raise Exception, ' non column text '
		Lscols.append('</tr>')
		Lshrows.append(Lscols)


	Lsdrows = [ ]
	for i in range(ih, len(srows)):
		# build up the list of entries for this row
		Lscols = [ '<tr> ' ]
		for spcol in re.split('(<td[^>]*>[\s\S]*?(?:</td>|(?=<td>)))(?i)', srows[i]):
			col = re.match('<td(?: colspan=(\d+))?(?: align=center)?>\s*([\s\S]*?)\s*(?:</td>)?$(?i)', spcol)
			if col:
				if col.group(1):
					Lscols.append('<td colspan="%s">' % col.group(1))
				else:
					Lscols.append('<td>')
				Lscols.extend(FixHTMLEntitiesL(col.group(2), '</?font[^>]*>|</?p>|\n(?i)'))
				Lscols.append('</td> ')

			# check that the outside text contains nothing but bogus close column tags
			elif re.search('\S', re.sub('</td>|</font>(?i)', '', spcol)):
				print spcol
				print srows[i]
				raise Exception, ' non column text '
		Lscols.append('</tr>')
		Lsdrows.append(Lscols)



	# construct the text for writing the table
	sio = cStringIO.StringIO()


	sio.write('<table>\n')
	if Lstitle:
		sio.write('\t\t')
		map(sio.write, Lstitle)
		sio.write('\n')

	for Lsh in Lshrows:
		sio.write('\t\t\t')
		map(sio.write, Lsh)
		sio.write('\n')

	for Lsd in Lsdrows:
		sio.write('\t\t\t')
		map(sio.write, Lsd)
		sio.write('\n')

	sio.write('\t\t</table>\n')

	res = sio.getvalue()
	sio.close()

	return res
