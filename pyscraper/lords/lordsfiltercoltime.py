#! /usr/bin/python2.3

import sys
import re
import os
import string

import mx.DateTime

from miscfuncs import ApplyFixSubstitutions
from contextexception import ContextException
from splitheadingsspeakers import StampUrl

# this filter converts column number tags of form:
#     <B>9 Dec 2003 : Column 893</B>
# into xml form
#     <stamp coldate="2003-12-09" colnum="893"/>

# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = 	[
( '<P>\s*</UL></UL></UL>', '</UL></UL></UL><P>', -1, 'all'),
# to insert a break which is otherwise not detectable
('<a name="column_15"></a>', '<a name="wms"></a>\\s', 1, '2004-01-12'),
('<a name="column_5"></a>', '<a name="wms"></a>\\s', 1, '2004-01-06'),
('(<a name="column_)=(\d+"></a>)', '\\1\\2', 21, '2003-06-19'),
('(Column )=(\d+)', '\\1\\2', 21, '2003-06-19'),

#('column_CWH', 'column_GC', 57, '2002-12-18'),

		]




# the new Lords thing
# <B>19 Nov 2003 : Column 1926</B></P>
# <p></UL>\n<B>29 Jan 2004 : Column 321</B></P>\n<UL>
# <P>\n</UL><FONT SIZE=3>\n<B>29 Jan 2004 : Column 369</B></P>\n<UL><FONT SIZE=2>
# <P>\n<FONT SIZE=3>\n<B>29 Jan 2004 : Column 430</B></P>\n<FONT SIZE=2>
# <P><a name="column_1442"></a><B>1 Apr 2004 : Column 1442</B></P><FONT SIZE=3>
# <P></UL><a name="column_1519"></a><B>1 Apr 2004 : Column 1519</B></P><UL><FONT SIZE=3>

regcolmat = '\s*<a name="column_\d+"></a>\s*<b>[^:<]*:\s*column\s*\d+\s*</b>'
regcolumnum11 = '<p>%s</p>\s*<font size=3>' % regcolmat
regcolumnum1 = '<p>%s</p>' % regcolmat
regcolumnum2 = '<p>\s*<font size=3>%s</p>\s*<font size=2>' % regcolmat
regcolumnum3 = '<p>\s*</ul>%s</p>\s*<ul><font size=3>' % regcolmat
regcolumnum4 = '<p>\s*</ul><font size=3>%s</p>\s*<ul><font size=2>' % regcolmat
regcolumnum5 = '<p>\s*(?:<font size=3>\s*)?<a name="column_\d+"></a>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\s*<font size=[23]>'
regcolumnum6 = '<p>\s*</ul>\s*<a name="column_\d+"></a>\s*<b>[^:<]*:\s*column\s*\d+\s*</b></p>\s*<ul><font size=3>'
regcolumnum7 = '%s\s*<br>&nbsp;<br>' % regcolmat

recolumnumvals = re.compile('(?:<br>&nbsp;<br>|<p>|</ul>|<font size=\d>|\s|</?a[^>]*>)*?<b>([^:<]*)\s*:\s*column\s*(\D*?)(\d+)\s*</b>(?:<br>&nbsp;<br>|</p>|<ul>|<font size=\d>|\s)*$(?i)')

# <H5>12.31 p.m.</H5>
# the lords times put dots in "p.m."  but the commons never do.
regtime1 = '(?:</?p>\s*|<h[45]>|\[|\n)(?:\d+(?:[:\.]\d+)?\.?\s*[ap]\.m\.\s*(?:</st>)?|12 noon)(?:\s*</?p>|\s*</h[45]>|\n)'
regtime2 = '<H5>(?:Noon|Midnight)\s*</st></H5>'
retimevals = re.compile('(?:</?p>\s*|<h\d>|\[|\n)\s*(\d+(?:[:\.]\d+)?\s*[apmnon\.]+|Noon|Midnight)(?i)')

# <a name="column_1099">
reaname = '<a name\s*=\s*"[^"]*"></a>(?i)'
reanamevals = re.compile('<a name\s*=\s*"([^"]*)">(?i)')

recomb = re.compile('(%s|%s|%s|%s|%s|%s|%s|%s|%s)(?i)' % (regcolumnum11, regcolumnum1, regcolumnum2, regcolumnum3, regcolumnum4, regcolumnum7, regtime1, regtime2, reaname))

remarginal = re.compile(':\s*column\s*\D*(\d+)(?i)')

def FilterLordsColtime(fout, text, sdate):
	colnum = -1
	time = ''

	stampurl = StampUrl(sdate)
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

			# check number
			lcolnum = string.atoi(columng.group(3))
			if lcolnum == colnum - 1:
				pass	# spurious decrementing of column number stamps
			elif lcolnum == colnum:
				pass	# spurious repeat of column number stamps
			# good (we get skipped columns in divisions)
			elif (colnum == -1) or (lcolnum == colnum + 1) or (lcolnum == colnum + 2):
				colnum = lcolnum
				fout.write('<stamp coldate="%s" colnum="%s"/>' % (sdate, colnum))

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

		# anchor names from HTML <a name="xxx">
		anameg = reanamevals.match(fss)
		if anameg:
			aname = anameg.group(1)
			fout.write('<stamp aname="%s"/>' % aname)
			stampurl.aname = aname
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
			raise ContextException(' marginal coltime detection case ', stamp=stampurl, fragment=fss)
		fout.write(fss)




##############
# lords filters stuff -- to be cleared up in a bit.
##############

# this is not working easily.

# split the text into the four categories.

# the parsing for each is quite different, which is why this is done first.

# against my instincts, I'm using the <a name> tags to break it up since
# the column numbering can be errant and on either side of the title

# this is not very elegant or orthogonal, but there are few enough cases
# to do it brutally like this

regacol = '<a name="column_([^\d>"]*)\d+"></a>'

def SplitLordsText(text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)
	res = [ '', '', '', '' ]

	wagc = re.search('<a name="(?:column_(?:GC|CWH)\d+|[0-9-]+_cmtee0)"></a>', text)
	wams = re.search('<a name="(?:wms|column_WS\d+)"></a>', text)
	wama = re.search('<a name="(?:column_WA\d+|[\dw]*_writ0)"></a>', text)

	# set end of house of lords section and check order
	if wagc:
		holend = wagc.start(0)
		if wams:
			assert holend < wams.start(0)
		elif wama:
			assert holend < wama.start(0)
	elif wams:
		holend = wams.start(0)
		if wama:
			assert holend < wama.start(0)
	elif wama:
		holend = wama.start(0)
	else:
		holend = len(text)

	# set the grand committee end
	res[0] = text[:holend]
	if wagc:
		if wams:
			gcend = wams.start(0)
		elif wama:
			gcend = wama.start(0)
		else:
			gcend = len(text)
		res[1] = text[holend:gcend]
	else:
		gcend = holend

	# set the ministerial statements end
	if wams:
		if wama:
			msend = wama.start(0)
		else:
			msend = len(text)
		res[2] = text[gcend:msend]
	else:
		msend = gcend

	# set the written answers end
	maend = len(text)
	if wama:
		res[3] = text[msend:]

	# check the wrong column numbering or wrong titles aren't found in the wrong place
	chns = re.search('<a name="column_\D+\d+">', res[0])
	if chns:
		print chns.group(0)
		raise ContextException("wrong column numbering in main debate", fragment=chns.group(0))
	#assert re.search('House of Lords\s*(?:<FONT SIZE=3>)?</center>', res[0])
	assert re.search('(?:<ul><ul>|</a>)\s*(?:Parliament was prorogued|House adjourned )(?i)', res[0])

	if res[1]:
		assert not re.search('<a name="column_(?!(?:GC|CWH))\D+\d+">', res[1])
		assert re.search('<(?:h2 align=)?center>Official Report of the (?:Northern Ireland Orders )?Grand Committee', res[1])

	if res[2]:
		assert not re.search('<a name="column_(?!WS)\D+\d+">', res[2])
		assert re.search('center>Written Statements', res[2])

	if res[3]:
		assert not re.search('<a name="column_(?!WA)\D+\d+">', res[3])
		assert re.search('<(?:h3 align=)?center>\s*Written Answers?', res[3]) # sometimes the s is missing

# could grab leading url labels to put into each section.

	print map(len, res)
	return res




