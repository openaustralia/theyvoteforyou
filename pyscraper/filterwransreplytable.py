#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from miscfuncs import FixHTMLEntities

# replies can have tables
def ParseTable(stable):
	# take out all the useless font and paragraph junk
	stable = re.sub('</?font[^>]*>|</?p>|\n(?i)', ' ', stable)

	# take out the bracketing
	stable = re.findall('<table[^>]*>\s*(.*?)\s*</table>(?i)', stable)[0]

	# break into rows
	sprows = re.split('(<tr[^>]*>.*?</tr>)(?i)', stable)

	# first row is title
	srows = []
	for sprow in sprows:
		row = re.findall('^<tr[^>]*>\s*(.*?)\s*</tr>$(?i)', sprow)
		if row:
			if not srows:
				srows.append('')
			srows.append(row[0])

		else:
			sprow = string.strip(sprow)
			if not srows:
				srows.append(sprow)
			elif sprow:
				print ' non-row text ' + sprow

	# take out tags round the title; they're always out of order
	if srows[0]:
		ts = re.findall('^(?:<b>|<center>)+\s*(.*?)\s*(?:</b>|</center>)+\s*(.*)\s*$(?i)', srows[0])
		if ts:
			if ts[0][1]:
				srows[0] = ts[0][0] + ' -- ' + ts[0][1]
			else:
				srows[0] = ts[0][0]
		else:
			print ' non-standard table title: ' + srows[0]
		srows[0] = FixHTMLEntities(srows[0])

	# find where the headings stop and the rows begin
	for ih in range(1, len(srows)):
		if re.search('<td>(?i)', srows[ih]):
			break

	# break each row down into columns
	for i in range(1, len(srows)):
		colt = 'td'
		colregexp = '(<td[^>]*>.*?</td>)(?i)'
		colexregexp = '^<td[^>]*>\s*(.*?)\s*</td>$(?i)'
		if i < ih:
			colregexp = '(<th[^>]*>.*?</th>)(?i)'
			colexregexp = '^<th[^>]*>\s*(.*?)\s*</th>$(?i)'
			colt = 'th'

		srow = srows[i]
		srow = re.sub('<td>\s*<td>\s*</td>(?i)', '<td></td><td>', srow)

		spcols = re.split(colregexp, srow)
		scols = [ colt ]
		for spcol in spcols:
			col = re.findall(colexregexp, spcol)
			if col:
				coltext = FixHTMLEntities(col[0])
				scols.append(coltext)
			elif re.search('\S', spcol):
				print ' non column text ' + srows[i]
				print spcols
				#sys.exit()

		# copy the list back into the table
		srows[i] = scols


	# construct the text for writing the table
	sio = cStringIO.StringIO()

	sio.write('<table>\n')
	sio.write('\t\t<div class="tabletitle">')
	sio.write(srows[0])
	sio.write('</div>\n')

	for i in range(1, len(srows)):
		colt = srows[i][0]    # td or th
		sio.write('\t\t\t<tr>')
		for j in range(1, len(srows[i])):
			sio.write(' <%s>%s</%s> ' % (colt, srows[i][j], colt))
		sio.write('</tr>\n')

	sio.write('\t\t</table>\n')

	res = sio.getvalue()
	sio.close()
	return res
