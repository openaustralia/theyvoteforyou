#! /usr/bin/python2.3

import sys
import re
import os
import string

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

# this filter converts time and column number tags into xml form
# <I>23 Oct 2003 : Column 637W</I>
# <stamp coldate="7 Nov 2000" colnum="637"/>

fixsubs = 	[
	( 'Continued in col 47W', '', 1, '2003-10-27' ),
	( '<H1 align=center></H1>[\s\S]{10,99}?\[Continued from column \d+?W\]', '', 1, '2003-11-17' ),
	( '<H2 align=center> </H2>[\s\S]{10,99}?Monday 13 October 2003', '', 1, '2003-10-14' ),

	# this really belongs in the fix names part
	( '<B> Alun Michael: For </B>', '<B> Alun Michael: </B> For', 1, '2003-11-17'), 
		]
def ApplyFixSubs(finr, sdate):
	for sub in fixsubs:
		if sub[3] == 'all' or sub[3] == sdate:
			res = re.subn(sub[0], sub[1], finr)
			if sub[2] != -1 and res[1] != sub[2]:
				print 'wrong substitutions %d on %s' % (res[1], sub[0])
			finr = res[0]
	return finr


def FixWransColumnNumbers(fout, finr, sdate):

	finr = ApplyFixSubs(finr, sdate)

	# <I>23 Oct 2003 : Column 637W</I>
	lcolumnregexp = '<i>\s*.*?\s*:\s*column:?\s*\d+w\s*</i>(?i)'
	columnregexp = '<i>\s*(.*?)\s*:\s*column:?\s*(\d+)w\s*</i>(?i)'

	#<i>23 Oct 2003 : Column 640W&#151;continued</i>
	lcolumncontregexp = '<i>\s*.*?\s*:\s*column\s*\d+w&#151;continued\s*</i>(?i)'
	columncontregexp = '<i>\s*(.*?)\s*:\s*column\s*(\d+)w&#151;continued\s*</i>(?i)'

	combiregexp = '(%s|%s)' % (lcolumnregexp, lcolumncontregexp)

	fs = re.split(combiregexp, finr)

	lcoldate = ''
	lcolnum = -1

	for fss in fs:
		columngroup = re.findall(columnregexp, fss)
		if len(columngroup) != 0:
			if lcoldate == '':
				lcoldate = columngroup[0][0]
				jlcoldate = mx.DateTime.DateTimeFrom(lcoldate).date # should get from filename
			elif lcoldate != columngroup[0][0]:
				print "Column date disagrees %s -- %s" % (lcoldate, fss)

			llcolnum = string.atoi(columngroup[0][1])
			if llcolnum != lcolnum - 1:
				if (lcolnum == -1) or (llcolnum == lcolnum + 1):
					pass  # good
				elif llcolnum < lcolnum:
					print "Column number not incrementing %d -- %s" % (lcolnum, fss)
				# column numbers do get skipped during division listings

				lcolnum = llcolnum
				fout.write('<stamp coldate="%s" colnum="%s" type="W"/>' % (jlcoldate, lcolnum))
 			else:
				pass #print "spurious column number decrementation -- don't output"

			continue

		columncontgroup = re.findall(columncontregexp, fss)
		if len(columncontgroup) != 0:
			if lcoldate != columncontgroup[0][0]:
				print "Continuation column date disagrees %s -- %s" % (lcoldate, fss)
			llcolnum = string.atoi(columncontgroup[0][1])
			if lcolnum != llcolnum:
				print "Continuation column number disagrees %d -- %s" % (lcolnum, fss)

			# no need to output result
			continue

		fout.write(fss)
