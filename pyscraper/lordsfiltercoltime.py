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
	( 'Column 35', 'Column WS35', 1, '2004-01-16'),
	( 'Column 36', 'Column WS36', 1, '2004-01-16'),

	( 'Column 15', 'Column WS15', 1, '2004-01-12'),
	( 'Column 16', 'Column WS16', 1, '2004-01-12'),
	( 'Column 17', 'Column WS17', 1, '2004-01-12'),
	( 'Column 18', 'Column WS18', 1, '2004-01-12'),

	( 'Column 11', 'Column WS11', 1, '2004-01-08'),
	( 'Column 12', 'Column WS12', 1, '2004-01-08'),
	( 'Column 13', 'Column WS13', 1, '2004-01-08'),
	( 'Column 14', 'Column WS14', 1, '2004-01-08'),

	( 'Column 9', 'Column WS9', 1, '2004-01-07'),
	( 'Column 10', 'Column WS10', 1, '2004-01-07'),

	( 'Column 5', 'Column WS5', 1, '2004-01-06'),
	( 'Column 6', 'Column WS6', 1, '2004-01-06'),
	( 'Column 7<', 'Column WS7<', 2, '2004-01-06'),
	( 'Column 8<', 'Column WS8<', 1, '2004-01-06'),

        ( '(clock\.\s*<P>\s*<B>5 Jan 2004 : Column )1', '\\1WS1', 1, '2004-01-05'), 
	( 'Column 2<', 'Column WS2<', 1, '2004-01-05'),
	( 'Column 3<', 'Column WS3<', 1, '2004-01-05'),
	( 'Column 4<', 'Column WS4<', 1, '2004-01-05'),
		]




# the new Lords thing
# <B>19 Nov 2003 : Column 1926</B></P>
# <p></UL>\n<B>29 Jan 2004 : Column 321</B></P>\n<UL>
# <P>\n</UL><FONT SIZE=3>\n<B>29 Jan 2004 : Column 369</B></P>\n<UL><FONT SIZE=2>
# <P>\n<FONT SIZE=3>\n<B>29 Jan 2004 : Column 430</B></P>\n<FONT SIZE=2>

regcolumnum1 = '<p>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\n(?i)'
regcolumnum2 = '<p>\s*(?:</ul>){1,3}\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*(?:<ul>){1,3}(?i)'
regcolumnum3 = '<p>\s*</ul><font size=3>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*<ul><font size=2>(?i)'
regcolumnum4 = '<p>\s*<font size=3>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*<font size=2>(?i)'

recolumnumvals = re.compile('(?:<p>|</ul>|<font size=\d>|\s)*?<b>([^:<]*)\s*:\s*column\s*(\D*?)(\d+)\s*</b>(?:</p>|<ul>|<font size=\d>|\s)*$(?i)')

# <H5>12.31 pm</H5>
regtime = '(?:</?p>\s*|<h[45]>|\[|\n)(?:\d+(?:[:\.]\d+)?\s*[ap]m(?:</st>)?|12 noon)(?:\s*</?p>|\s*</h[45]>|\n)(?i)'
retimevals = re.compile('(?:</?p>\s*|<h\d>|\[|\n)\s*(\d+(?:[:\.]\d+)?\s*[apmnon]+)(?i)')


recomb = re.compile('(%s|%s|%s|%s|%s)' % (regcolumnum1, regcolumnum2, regcolumnum3, regcolumnum4, regtime))

remarginal = re.compile(':\s*column\s*\D*(\d+)(?i)')




def FilterLordsColtime(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

        indexstyle = " NONE "
	colnum = -1
        time = ''
        
	for fss in recomb.split(text):

		# column number type
		columng = recolumnumvals.match(fss)
		if columng:
			# check date
			ldate = mx.DateTime.DateTimeFrom(columng.group(1)).date
			if sdate != ldate:
				raise Exception, "Column date disagrees %s -- %s" % (sdate, fss)

                        # get the index style out
			lindexstyle = columng.group(2)
                        if not re.match('(?:|GC|WS|WA)$', lindexstyle):
				raise Exception, "Colnum index style not recognized: %s" % lindexstyle
                        if indexstyle != lindexstyle:
                                indexstyle = lindexstyle
                                colnum = -1  # restart the numbering
                                print indexstyle
			
			# check number
			lcolnum = string.atoi(columng.group(3))
			if lcolnum == colnum - 1:
				pass	# spurious decrementing of column number stamps
			elif lcolnum == colnum:
				pass	# spurious repeat of column number stamps
			# good (we get skipped columns in divisions)
			elif (colnum == -1) or (lcolnum == colnum + 1) or (lcolnum == colnum + 2):
                            colnum = lcolnum
                            fout.write('<stamp coldate="%s" colnum="%s" colstyle="%s"/>' % (sdate, colnum, lindexstyle))
			
			# column numbers do get skipped during division listings
			else:
				raise Exception, "Colnum not incrementing %d -- %d -- %s" % (colnum, lcolnum, fss)

			#print (ldate, colnum, lindexstyle)
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
