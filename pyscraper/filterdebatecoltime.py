#! /usr/bin/python2.3

import sys
import re
import os
import string

import mx.DateTime

from miscfuncs import ApplyFixSubstitutions

# this filter converts column number tags of form:
#     <B>9 Dec 2003 : Column 893</B>
# into xml form
#     <stamp coldate="2003-12-09" colnum="893"/>

fixsubs = 	[
	( '(<H3 align=center>THE PARLIAMENTARY DEBATES</H3>)', '<B>14 Oct 2003 : Column 1</B>\n\\1', 1, '2003-10-14'),
	( '(<H4><center>THE PARLIAMENTARY DEBATES</center></H4>)', '<B>14 Jul 2003 : Column 1</B>\n\\1', 1, '2003-07-14'),
 		]

# <B>9 Dec 2003 : Column 893</B>
regcolumnum = '<b>[^:<]*:\s*column\s*\d+\s*</b>(?i)'
recolumnumvals = re.compile('<b>([^:<]*):\s*column\s*(\d+)\s*</b>(?i)')

#<i>13 Nov 2003 : Column 431&#151;continued</i>
# these occur infrequently  
regcolnumcont = '<i>[^:<]*:\s*column\s*\d+&#151;continued</i>(?i)'
recolnumcontvals = re.compile('<i>([^:<]*):\s*column\s*(\d+)&#151;continued</i>(?i)')

# <H5>12.31 pm</H5>
# <p>\n12.31 pm\n<p>
# [3:31 pm<P>    -- at the beginning of divisions
regtime = '(?:</?p>\s*|<h[45]>|\[|\n)\d+(?:[:\.]\d+)?\s*[ap]m(?:\s*</?p>|</h[45]>|\n)(?i)'
retimevals = re.compile('(?:</?p>\s*|<h\d>|\[|\n)\s*(\d+(?:[:\.]\d+)?\s*[ap]m)(?:\s*</?p>|</h\d>|\n)(?i)')

recomb = re.compile('(%s|%s|%s)' % (regcolumnum, regcolnumcont, regtime))
remarginal = re.compile(':\s*column\s*(\d+)|\n(?:\d+[.:])?\d+\s*[ap]m[^,\w](?i)')



def FilterDebateColTime(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	colnum = -1
	time = ''	# need to use a proper timestamp code class
	#fs =
	for fss in recomb.split(text):

		# column number type
		columng = recolumnumvals.match(fss)
		if columng:
			# check date
			ldate = mx.DateTime.DateTimeFrom(columng.group(1)).date
			if sdate != ldate:
				raise Exception, "Column date disagrees %s -- %s" % (sdate, fss)

			# check number
			lcolnum = string.atoi(columng.group(2))
			if lcolnum == colnum - 1:
				pass	# spurious decrementing of column number stamps
			elif (colnum == -1) or (lcolnum == colnum + 1):
				pass  # good
			# column numbers do get skipped during division listings
			elif lcolnum < colnum:
				raise Exception, "Colnum not incrementing %d -- %s" % (lcolnum, fss)

			# write a column number stamp
			colnum = lcolnum
			fout.write('<stamp coldate="%s" colnum="%s"/>' % (sdate, colnum))
			continue

		columncg = recolnumcontvals.match(fss)
		if columncg:
			ldate = mx.DateTime.DateTimeFrom(columncg.group(1)).date
			if sdate != ldate:
				raise Exception, "Column date disagrees %s -- %s" % (sdate, fss)

			lcolnum = string.atoi(columncg.group(2))
			if colnum != lcolnum:
				raise Exception, "Cont column number disagrees %d -- %s" % (colnum, fss)

			continue

		timeg = retimevals.match(fss)
		if timeg:
			time = timeg.group(1)
			fout.write('<stamp time="%s"/>' % time)
			continue

		# nothing detected
		# check if we've missed anything obvious
		if recomb.match(fss):
			print fss
			raise Exception, ' regexpvals not general enough '
		if remarginal.search(fss):
			print ' marginal coltime detection case '
			print remarginal.search(fss).group(0)
			print fss
			sys.exit()
		fout.write(fss)

