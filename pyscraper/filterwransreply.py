#! /usr/bin/python2.3

import sys
import re
import string
import cStringIO

import mx.DateTime

from resolvemembernames import memberList
from parlphrases import parlPhrases
from miscfuncs import FixHTMLEntities

# output to check for undetected member names
seelines = open('ghgh.txt', "w")


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
				coltext = col[0]
				coltext = re.sub(' & ', ' &amp ', coltext)
				scols.append(coltext)
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


# A common prefix on answers.
def RemoveHoldingAnswer(qs, line):
	# <i>[holding answer 17 September 2003]:</i>
	# the delimeters are in a variety of different orders
	qha = re.match('((?:\s|</?i>)*\[(?:\s|</?i>)*holding answers? ?(?:on|of |issued)?\s*([\w\s]*?)(?:</i>|:|;|\s)*\](?:</i>|:|;|\s)*)', line)
	if qha:
		line = line[qha.span(1)[1]:]	# take the tail of the string.
		dt = qha.group(2)

		# could deal with 'and' in this string.
		dgroups = re.match('(\d+)\s*([A-Z][a-z]*)\s*(\d*)$', dt)
		if dgroups:
			dgyr = dgroups.group(3)
			if not dgyr:
				dgyr = '%d' % mx.DateTime.DateTimeFrom(qs.sdate).year
			ddt = dgroups.group(1) + ' ' + dgroups.group(2) + ' ' +  dgyr
			holdans = mx.DateTime.DateTimeFrom(ddt).date
			qs.holdinganswer.append(holdans)
		else:
			print ' not pure date: ' + dt

	# successfully cleared this quote from front of line
	if qs.sdate != '2003-02-28' and qs.sdate != '2003-02-25':
		if re.search('holding answer ', line):
			print line
			#sys.exit()

	return line


# codes for getting the hon member strings out and into a normal form
honmemextrlist = [
	( '([Mm]y (?:[Rr]ight )?[Hh]on\.? [Ff]riend,? the [Mm]ember for (.*?) \((.*?)\))', (3, 2, -1) ),
	( '([Tt]he (?:[Rr]ight )?[Hh]on\.? [Mm]ember for (.*?) \((.*?)\))', (3, 2, -1) ),
	( '([Mm]y (?:[Rr]ight )?[Hh]on\.? [Ff]riend,? <mpjob>([^<]*)</mpjob> \((.*?)\))', (3, -1, 2) ),
	( '([Mm]y [Hh]on\.? [Ff]riend for (.*?) \((.*?)\))', (3, 2, -1) ),
		]
def ExtractHonMembersRecurse(qs, stex):
	# find a matching string type
	mps = ''
	for honmem in honmemextrlist:
		qhm = re.search(honmem[0], stex)
		if not qhm:
			continue

		# extract the fields from this match
		mpname = qhm.group(honmem[1][0])
		mpconst = ''
		if honmem[1][1] != -1:
			mpconst = qhm.group(honmem[1][1])
		mpjob = ''
		if honmem[1][2] != -1:
			mpjob = qhm.group(honmem[1][2])


		# check if the member is in the list (unreliable code at the moment)
		if not memberList.matchfullname(mpname, qs.sdate)[1]:
			#pass
			print ' MP name not found in honmemrecurse: ' + mpname
			#continue

		mps = '<MP name="%s" constituency="%s" job="%s">%s</MP>' % (mpname, mpconst, mpjob, qhm.group(1))
		break


	# recursion part
	if mps:
		res = ExtractHonMembersRecurse(qs, stex[:qhm.span(1)[0]])
		res.append(mps)
		res.extend(ExtractHonMembersRecurse(qs, stex[qhm.span(1)[1]:]))
		return res
	else:
                print "stexing"
                print stex
                oldstex = stex
                stex = FixHTMLEntities(stex)
                if stex <> oldstex:
                        print "newstex"
                        print stex
		return [ stex ]





rejobs = re.compile('((?:[Mm]y (?:rt\. |[Rr]ight )?[Fh]on\.? [Ff]riend )?[Tt]he (?:then |former )?(?:%s))' % parlPhrases.regexpjobs)
def ExtractJobRecurse(stex):
	qjobs = rejobs.search(stex)
	if qjobs:
		res = ExtractJobRecurse(string.strip(stex[:qjobs.span(1)[0]]))
		res.append('<mpjob>%s</mpjob>' % qjobs.group(1))
		res.extend(ExtractJobRecurse(string.strip(stex[qjobs.span(1)[1]:])))
		return res

	# break into brackets
	res = [ ]
	for qbrack in re.split('(\([^)]*\))', stex):
		if re.search('\S', qbrack):
			res.append(string.strip(qbrack))
	return res


def FindHonMembers(i, n, line, qs):
	# first determin the jobs that are in the text
	line = string.join(ExtractJobRecurse(line))
	return line

	res = ExtractHonMembersRecurse(qs, line)
	return string.join(res, '')

	if len(res) == 1:
		qhb = re.search('(\([A-Z][a-z]+\s+[A-Z][a-z]+\))', line)
		if qhb:
			seelines.write('%d/%d\t%s:\t%s\n' % (i, n, qhb.group(1), line))


def FilterReply(qs):
	# break into pieces
	nfj = re.split('(<table[\s\S]*?</table>|</?p>|</?ul>|<br>|</?font[^>]*>)(?i)', qs.text)
	qs.holdinganswer = []

	# break up into sections separated by paragraph breaks
	dell = []
	spc = ''
	for nf in nfj:
		# first line may have this holding answer value which we want to take out
		# and discard if in a paragraph on its own.
		if not dell:
			nf = RemoveHoldingAnswer(qs, nf)

		if re.match('</?p>|</?ul>|<br>|</?font[^>]*>(?i)', nf):
			spc = spc + nf
		else:
			if re.search('\S', nf):
				dell.append(spc)
				spc = ''
				dell.append(string.strip(nf))
	if not spc:
		spc = ''
	dell.append(spc)

	# we now have the paragraphs interspersed with inter-paragraph symbols
	# for now ignore these inter-paragraph symbols.
	qs.stext = []
	n = (len(dell)-1) / 2
	for i in range(1, len(dell)-1, 2):
		# this puts a list into the result
		if re.search('<table(?i)', dell[i]):
			qs.stext.append(ParseTable(dell[i]))
		else:
			lline = dell[i]
			lline = FindHonMembers(len(qs.stext), n, lline, qs)

			qs.stext.append(lline)

	if not qs.stext:
		print 'empty answer'


