#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO



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
				srows[0] = ts[0][0] + ' - ' + ts[0][1]
			else:
				srows[0] = ts[0][0]
		else:
			print ' non-standard table title: ' + srows[0]

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
				scols.append(col[0])
			elif re.search('\S', spcol):
				print ' non column text ' + srows[i]
				print spcols
				#sys.exit()

		# copy the list back into the table
		srows[i] = scols
		# if i > 1 and len(srows[i]) != len(srows[1]):  print 'columns not consistent'


	# construct the text for writing the table
	sio = cStringIO.StringIO()

	sio.write('<table>\n')
	sio.write('\t<title>')
	sio.write(srows[0])
	sio.write('</title>\n')

	for i in range(1, len(srows)):
		colt = srows[i][0]    # td or th
		sio.write('\t<tr>')
		for j in range(1, len(srows[i])):
			sio.write(' <%s> %s </%s> ' % (colt, srows[i][j], colt))
		sio.write('</tr>\n')

	sio.write('</table>\n')

	res = sio.getvalue()
	sio.close()
	return res


def RemoveHoldingAnswer(line):
	# take out holding answer string [<i>holding answer 8 April 2003</i>]:
	# this information is not interesting and can be recreated from cross-reference with the question book.
	qha = re.findall('^\s*\[(.*?holding answer.*?)\]:?\s*(.*)$(?i)', line)
	if not qha:
		qha = re.findall('^\s*<i>(.*?holding answer.*?)</i>:?\s*(.*)$(?i)', line)
	if qha:
		return qha[0][1]
	return line


def FilterReply(qs):
	# break into pieces
	nfj = re.split('(<table[\s\S]*?</table>|</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', qs.text)

	# break up into sections separated by paragraph breaks
	dell = []
	spc = ''
	for nf in nfj:
		if re.match('(</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', nf):
			spc = spc + nf
		else:
			# first line
			if not dell:
				nf = RemoveHoldingAnswer(nf)

			if re.search('\S', nf):
				dell.append(spc)
				spc = ''
				dell.append(nf)
	if not spc:
		spc = ''
	dell.append(spc)

	# remove whitespace (linefeeds) on all the strings
	for i in range(len(dell)):
		dell[i] = string.strip(dell[i])


	qs.stext = []
	n = (len(dell)-1) / 2
	for i in range(1, len(dell)-1, 2):
		# this puts a list into the result
		if re.search('<table(?i)', dell[i]):
			qs.stext.append(ParseTable(dell[i]))

		else:
			lline = dell[i]
			#lline = IdentCodes(lline, i, n)

			qs.stext.append(lline)

	if not qs.stext:
		print 'empty answer'


