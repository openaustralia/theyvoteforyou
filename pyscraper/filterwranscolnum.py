#! /usr/bin/python2.3

import sys
import re
import os
import string

import mx.DateTime

from miscfuncs import ApplyFixSubstitutions

# this filter converts column number tags of form:
#     <I>23 Oct 2003 : Column 637W</I>
# into xml form
#     <stamp coldate="2003-10-23" colnum="637W"/>

fixsubs = 	[
	( 'Continued in col 47W', '', 1, '2003-10-27' ),

	# Note the 2!
	( '<H1 align=center></H1>[\s\S]{10,99}?\[Continued from column \d+?W\](?:</H2>)?', '', 2, '2003-11-17' ),
	( '<H2 align=center> </H2>[\s\S]{10,99}?Monday 13 October 2003', '', 1, '2003-10-14' ),
	( '<P>\[Continued from column 278W\]', '', 1, '2003-12-08'),
 		]

#<P>
#</UL><P><I>20 Nov 2003 : Column 1203W</I><P>
#<UL>
# <I>23 Oct 2003 : Column 637W</I>

# These are very specific cases which attempt to undo the full column inserting macro which
# they use, which pushes column stamps right into the middle of sentences and paragraphs that
# may be indented with ul and font changed.
# Undoing the insertion fully means we can automatically glue paragraphs back together.  

# columns never show up in the middle of tables.


regcolumnum1 = '<p>\s<p><i>[^:<]*:\s*column:?\s*\d+w?\s*</i><p>(?i)'
regcolumnum2 = '<p>\s</ul><p><i>[^:<]*:\s*column:?\s*\d+w?\s*</i><p>\s<ul>(?i)'
regcolumnum3 = '<p>\s</ul>(?:</font>)+<p><i>[^:<]*:\s*column:?\s*\d+w?\s*</i><p>\s<ul>(?:<font[^>]*>)?(?i)'
recolumnumvals = re.compile('(?:<p>|\s|</ul>|</font>)*<i>([^:<]*):\s*column:?\s*(\d+)w?\s*</i>(?:<p>|\s|<ul>|<font[^>]*>)*$(?i)')

#<i>23 Oct 2003 : Column 640W&#151;continued</i>
regcolnumcont = '<i>[^:<]*:\s*column\s*\d+w?&#151;continued\s*</i>(?i)'
recolnumcontvals = re.compile('<i>([^:<]*):\s*column\s*(\d+)w?&#151;continued</i>(?i)')

recomb = re.compile('\s*(%s|%s|%s|%s)\s*' % (regcolumnum1, regcolumnum2, regcolumnum3, regcolnumcont))
remarginal = re.compile(':\s*column\s*\d+(?i)')



def FilterWransColnum(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	colnum = -1
	for fss in recomb.split(text):

		columng = recolumnumvals.match(fss)
		if columng:
			ldate = mx.DateTime.DateTimeFrom(columng.group(1)).date
			if sdate != ldate:
				raise Exception, "Column date disagrees %s -- %s" % (sdate, fss)

			lcolnum = string.atoi(columng.group(2))
			if (colnum == -1) or (lcolnum == colnum + 1):
				pass  # good
			elif lcolnum < colnum:
				raise Exception, "Colnum not incrementing %d -- %s" % (lcolnum, fss)
			# column numbers do get skipped during division listings

			colnum = lcolnum
			fout.write(' <stamp coldate="%s" colnum="%sW"/>' % (sdate, lcolnum))

			continue

		columncontg = recolnumcontvals.match(fss)
		if columncontg:
			ldate = mx.DateTime.DateTimeFrom(columncontg.group(1)).date
			if sdate != ldate:
				raise Exception, ("Cont column date disagrees %s -- %s" % (sdate, fss))
			lcolnum = string.atoi(columncontg.group(2))
			if colnum != lcolnum:
				raise Exception, "Cont column number disagrees %d -- %s" % (colnum, fss)

			# no need to output anything
			fout.write(' ')
			continue


		# nothing detected
		# check if we've missed anything obvious
		if recomb.match(fss):
			print fss
			raise Exception, ' regexpvals not general enough '
		if remarginal.search(fss):
			print ' marginal colnum detection case '
			print remarginal.search(fss).group(0)
			print fss
			raise Exception, ' marginal colnum detection case '

		fout.write(fss)

