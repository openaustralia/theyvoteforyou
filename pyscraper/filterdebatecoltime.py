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

# this accounts for the cases where the colnum at the very start is left out.
fixsubs = 	[
	( '(<H3 align=center>THE PARLIAMENTARY DEBATES</H3>)', '<P>\n\n<B>14 Oct 2003 : Column 1</B></P>\n\\1', 1, '2003-10-14'),
	( '(<H4><center>THE PARLIAMENTARY DEBATES</center></H4>)', '<P>\n\n<B>14 Jul 2003 : Column 1</B></P>\n\\1', 1, '2003-07-14'),

	( '(<P>\n</FONT></UL>)(\s*<B>23 Jun 2003 : Column 836</B></P>)', '\\1<P>\\2', 1, '2003-06-23'),
	( '<B>27 Mar 2003 : Column 563</B></P>\s*<UL><UL><UL>\s*</UL></UL></UL>', '', 1, '2003-03-27'),
	( '<B>10 Mar 2003 : Column 141</B></P>\s*<UL><UL><UL>\s*</UL></UL></UL>', '', 1, '2003-03-10'),
	( '<B>4 Feb 2003 : Column 251</B></P>\s*<UL><UL><UL>\s*</UL></UL></UL>', '', 1, '2003-02-04'),
	( '<B>24 Sept 2002 : Column 155</B></P>\s*<UL><UL><UL><FONT SIZE=-1>\s*</UL></UL></UL>', '', 1, '2002-09-24'),
	( '<H4>2.20</H4>', '<H4>2.20 pm</H4>', 1, '2003-02-28'), 
        ( '(<H5>2.58)(</H5>)', '\\1 pm\\2', 1, '2004-01-13'),
]


# <B>9 Dec 2003 : Column 893</B>
regcolumnum1 = '<p>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\n(?i)'
regcolumnum2 = '<p>\s*</ul>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\n<ul>(?i)'
regcolumnum3 = '<p>\s*</ul></font>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\n<ul><font[^>]*>(?i)'
regcolumnum4 = '<p>\s*</font>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\n<font[^>]*>(?i)'
recolumnumvals = re.compile('(?:<p>|</ul>|</font>|\s)*<b>([^:<]*):\s*column\s*(\d+)\s*</b>(?:</p>|<ul>|<font[^>]*>|\s)*$(?i)')


#<i>13 Nov 2003 : Column 431&#151;continued</i>
# these occur infrequently
regcolnumcont = '<i>[^:<]*:\s*column\s*\d+&#151;continued</i>(?i)'
recolnumcontvals = re.compile('<i>([^:<]*):\s*column\s*(\d+)&#151;continued</i>(?i)')



# <H5>12.31 pm</H5>
# <p>\n12.31 pm\n<p>
# [3:31 pm<P>    -- at the beginning of divisions
regtime = '(?:</?p>\s*|<h[45]>|\[|\n)(?:\d+(?:[:\.]\d+)?\s*[ap]\.?m\.?(?:</st>)?|12 noon)(?:\s*</?p>|\s*</h[45]>|\n)(?i)'
retimevals = re.compile('(?:</?p>\s*|<h\d>|\[|\n)\s*(\d+(?:[:\.]\d+)?\s*[apmnon.]+)(?i)')

recomb = re.compile('(%s|%s|%s|%s|%s|%s)' % (regcolumnum1, regcolumnum2, regcolumnum3, regcolumnum4, regcolnumcont, regtime))
remarginal = re.compile(':\s*column\s*(\d+)|\n(?:\d+[.:])?\d+\s*[ap]\.?m\.?[^,\w](?i)')

# This one used to break times into component parts: 7.10 pm
regparsetime = re.compile("^(\d+)[\.:](\d+)\s?([\w\.]+)$")
# 7 pm
regparsetimeonhour = re.compile("^(\d+)()\s?([\w\.]+)$")

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
                        #print "time ", time

			# This code lifted from fix_time PHP code from easyParliament
			# (thanks Phil!)
			timeparts = regparsetime.match(time)
			if not timeparts:
			    timeparts = regparsetimeonhour.match(time)
			if timeparts:
			    hour = int(timeparts.group(1))
			    if (timeparts.group(2) <> ""):
				mins = int(timeparts.group(2))
			    else:
				mins = 0
			    meridien = timeparts.group(3)

			    if (meridien == 'pm' or meridien == 'p.m.') and hour <> 12:
				hour += 12

			    time = "%02d:%02d:00" % (hour, mins)
			else:
			    time = "unknown " + time
			    raise Exception, "Time not matched: " + time
			    
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

