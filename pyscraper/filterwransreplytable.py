#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from miscfuncs import FixHTMLEntities

# replies can have tables
def ParseTable(stable):
	# remove the table bracketing
	stable = re.match('<table[^>]*>\s*([\s\S]*?)\s*</table>(?i)', stable).group(1)

	# take out all the useless font and paragraph junk


	# break into rows, making sure we deal with non-closed <tr> symbols
	sprows = re.split('(<tr[^>]*>[\s\S]*?(?:</tr>|(?=<tr>)))(?i)', stable)

	# build the rows
	stitle = ''
	srows = []
	for sprow in sprows:
		trg = re.match('<tr[^>]*>\s*([\s\S]*?)\s*(?:</tr>)?$(?i)', sprow)
		if trg:
			srows.append(trg.group(1))

		else:
			if re.search('\S', sprow):
				if (not srows) and (not stitle):
					stitle = sprow
				else:
     					print ' non-row text ' + sprow

	# take out tags round the title; they're always out of order
	stitle = string.strip(re.sub('</?font[^>]*>|</?p>|\n(?i)', ' ', stitle))
	if stitle:
		ts = re.match('(?:\s|<b>|<center>)+([\s\S]*?)(?:</b>|</center>)+\s*([\s\S]*?)\s*$(?i)', stitle)
		if ts:
			if ts.group(2):
				stitle = ts.group(1) + ' -- ' + ts.group(2)
			else:
				stitle = ts.group(1)
		else:
			print ' non-standard table title:' + stitle + ':'
			sys.exit()

		stitle = FixHTMLEntities(stitle)

	# find where the headings stop and the rows begin
	for ih in range(len(srows)):
		if re.search('<td>(?i)', srows[ih]):
			break

	# break each row down into columns
	for i in range(len(srows)):
		colt = 'td'
		colregexp = '(<td[^>]*>[\s\S]*?(?:</td>|(?=<td>)))(?i)'
		colexregexp = '<td[^>]*>\s*([\s\S]*?)\s*(?:</td>)?$(?i)'
		if i < ih:
			colregexp = '(<th[^>]*>[\s\S]*?(?:</th>|(?=<th>)))(?i)'
			colexregexp = '<th[^>]*>\s*([\s\S]*?)\s*(?:</th>)?$(?i)'
			colt = 'th'

		srow = srows[i]
		spcols = re.split(colregexp, srow)

		scols = [ colt ]
		for spcol in spcols:
			col = re.match(colexregexp, spcol)
			if col:
				coltext = col.group(1)
				coltext = re.sub('</?font[^>]*>|</?p>|\n(?i)', ' ', coltext)
				coltext = FixHTMLEntities(coltext)
				scols.append(coltext)
			elif re.search('\S', spcol):
				col = re.sub('</t[dh]>(?i)', '', spcol)
				if re.search('\S', col):
					print ' non column text ' + srows[i]
					print spcols
					sys.exit()

		# copy the list back into the table
		srows[i] = scols


	# construct the text for writing the table
	sio = cStringIO.StringIO()

	sio.write('<table>\n')
	if stitle:
		sio.write('\t\t<div class="tabletitle">')
		sio.write(stitle)
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
