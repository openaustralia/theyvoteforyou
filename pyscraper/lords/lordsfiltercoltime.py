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

# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = 	[

		]




# the new Lords thing
# <B>19 Nov 2003 : Column 1926</B></P>
# <p></UL>\n<B>29 Jan 2004 : Column 321</B></P>\n<UL>
# <P>\n</UL><FONT SIZE=3>\n<B>29 Jan 2004 : Column 369</B></P>\n<UL><FONT SIZE=2>
# <P>\n<FONT SIZE=3>\n<B>29 Jan 2004 : Column 430</B></P>\n<FONT SIZE=2>
# <P><a name="column_1442"></a><B>1 Apr 2004 : Column 1442</B></P><FONT SIZE=3>
# <P></UL><a name="column_1519"></a><B>1 Apr 2004 : Column 1519</B></P><UL><FONT SIZE=3>

regcolumnum1 = '<p>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\n(?:<font size=3>)?'
regcolumnum2 = '<p>\s*(?:</ul>){1,3}\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*(?:<ul>){1,3}(?:<FONT SIZE=3>)?'
regcolumnum3 = '<p>\s*</ul><font size=3>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*<ul><font size=2>'
regcolumnum4 = '<p>\s*<font size=3>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*<font size=2>'
regcolumnum5 = '<p>\s*(?:<font size=3>\s*)?<a name="column_\d+"></a>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\s*<font size=[23]>'
regcolumnum5 = '<p>\s*(?:<font size=3>\s*)?<a name="column_\d+"></a>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\s*<font size=[23]>'
regcolumnum6 = '<p>\s*</ul>\s*<a name="column_\d+"></a>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\s*<ul><font size=3>'

recolumnumvals = re.compile('(?:<p>|</ul>|<font size=\d>|\s|</?a[^>]*>)*?<b>([^:<]*)\s*:\s*column\s*(\D*?)(\d+)\s*</b>(?:</p>|<ul>|<font size=\d>|\s)*$(?i)')

# <H5>12.31 p.m.</H5>
# the lords times put dots in "p.m."  but the commons never do.
regtime1 = '(?:</?p>\s*|<h[45]>|\[|\n)(?:\d+(?:[:\.]\d+)?\.?\s*[ap]\.m\.\s*(?:</st>)?|12 noon)(?:\s*</?p>|\s*</h[45]>|\n)'
regtime2 = '<H5>Noon\s*</st></H5>'
retimevals = re.compile('(?:</?p>\s*|<h\d>|\[|\n)\s*(\d+(?:[:\.]\d+)?\s*[apmnon\.]+|Noon)(?i)')



recomb = re.compile('(%s|%s|%s|%s|%s|%s|%s|%s)(?i)' % (regcolumnum1, regcolumnum2, regcolumnum3, regcolumnum4, regcolumnum5, regcolumnum6, regtime1, regtime2))

remarginal = re.compile(':\s*column\s*\D*(\d+)(?i)')



# We have to separate into sections since they are on different time-lines and will
# require different detection.
# foutarr[0]  debates
# foutarr[1]  Grand Committee
# foutarr[2]  Written Statements
# foutarr[3]  Written Answers


def FilterLordsColtime(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)
        indexstyle = " NONE "
	colnum = -1
        time = ''

	for fss in recomb.split(text):

		# column number type

		# we need some very elaboirate checking to sort out the sections, by
		# titles that are sometimes on the wrong side of the first column,
		# and by colnums that miss the GC code in that section.
		# column numbers are also missed during divisions, and this exception
		# should be detected and noted.

		# That implies that this is the filter which detects the boundaries
		# between the standard four sections.
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
                                #print indexstyle

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
				pass #print "Colnum not incrementing %d -- %d -- %s" % (colnum, lcolnum, fss)
				#raise Exception, "Colnum not incrementing %d -- %d -- %s" % (colnum, lcolnum, fss)

			#print (ldate, colnum, lindexstyle)
			continue

		timeg = retimevals.match(fss)
		if timeg:
			time = timeg.group(1)
			#print "time %s " % time

			fout.write('<stamp time="%s"/>' % time)
			continue

		# nothing detected
		# check if we've missed anything obvious
		if recomb.match(fss):
			print fss
			raise Exception, ' regexpvals not general enough '
		if remarginal.search(fss):
			print remarginal.search(fss).group(0)
			lregcolumnum6 = '<p>\s*</ul>\s*<a name="column_\d+"></a>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\s*<ul><font size=3>(?i)'
			print re.findall(lregcolumnum6, fss)
			#print fss
			raise Exception, ' marginal coltime detection case '
		fout.write(fss)


