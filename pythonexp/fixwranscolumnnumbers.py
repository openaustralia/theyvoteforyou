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

def FixWransColumnNumbers(fout, finr):

	# <I>23 Oct 2003 : Column 637W</I>
	lcolumnregexp = '<i>\s*.*?\s*:\s*column\s*\d+w\s*</i>(?i)'
	columnregexp = '<i>\s*(.*?)\s*:\s*column\s*(\d+)w\s*</i>(?i)'

	#<i>23 Oct 2003 : Column 640W&#151;continued</i>
	lcolumncontregexp = '<i>\s*.*?\s*:\s*column\s*\d+w&#151;continued\s*</i>(?i)'
	columncontregexp = '<i>\s*(.*?)\s*:\s*column\s*(\d+)w&#151;continued\s*</i>(?i)'

	combiregexp = '(%s|%s)' % (lcolumnregexp, lcolumncontregexp)

	fs = re.split(combiregexp, finr)

	lcoldate = ''
	lcolnum = -1

	for fss in fs:
		if not fss:
			continue

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
