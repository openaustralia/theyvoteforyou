#! /usr/bin/python2.3

import sys
import re
import os
import string
import cStringIO

import mx.DateTime

import miscfuncs
toppath = miscfuncs.toppath




# master function which carries the glued pages into the xml filtered pages

# incoming directory of glued pages directories

pwlordspages = os.path.join(toppath, "pwlordspages")

# outgoing directory of scaped pages directories
pwxmldirs = os.path.join(toppath, "pwscrapedxml")

tempfile = os.path.join(toppath, "filtertemp")



# the new Lords thing
# <B>19 Nov 2003 : Column 1926</B></P>
# <p></UL>\n<B>29 Jan 2004 : Column 321</B></P>\n<UL>
# <P>\n</UL><FONT SIZE=3>\n<B>29 Jan 2004 : Column 369</B></P>\n<UL><FONT SIZE=2>
# <P>\n<FONT SIZE=3>\n<B>29 Jan 2004 : Column 430</B></P>\n<FONT SIZE=2>

regcolumnum1 = '<p>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\n(?i)'
regcolumnum2 = '<p>\s*</ul>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*<ul>(?i)'
regcolumnum3 = '<p>\s*</ul><font size=3>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*<ul><font size=2>(?i)'
regcolumnum4 = '<p>\s*<font size=3>\s*<b>[^:<]*:\s*column\s*(?:GC|WA|WS)?\d+\s*</b></p>\s*<font size=2>(?i)'

recolumnumvals = re.compile('(?:<p>|</ul>|<font size=\d>|\s)*?<b>([^:<]*)\s*:\s*column\s*(\D*?)(\d+)\s*</b>(?:</p>|<ul>|<font size=\d>|\s)*$(?i)')

recomb = re.compile('(%s|%s|%s|%s)' % (regcolumnum1, regcolumnum2, regcolumnum3, regcolumnum4))

remarginal = re.compile(':\s*column\s*\D*(\d+)(?i)')

def FilterLordsColtime(fout, text, sdate):

	for fss in recomb.split(text):
		# column number type

		colnum = -1

		columng = recolumnumvals.match(fss)
		if columng:
			# check date
			ldate = mx.DateTime.DateTimeFrom(columng.group(1)).date
			#if sdate != ldate:
			#	raise Exception, "Column date disagrees %s -- %s" % (sdate, fss)

			lindexstyle = columng.group(2)
			
			# check number
			lcolnum = string.atoi(columng.group(3))
			#if lcolnum == colnum - 1:
			#	pass	# spurious decrementing of column number stamps
			#elif (colnum == -1) or (lcolnum == colnum + 1):
			#	pass  # good
			
			# column numbers do get skipped during division listings
			#elif lcolnum < colnum:
			#	raise Exception, "Colnum not incrementing %d -- %s" % (lcolnum, fss)

			# write a column number stamp
			colnum = lcolnum
			#fout.write('<stamp coldate="%s" colnum="%s"/>' % (sdate, colnum))

			print (ldate, colnum, lindexstyle)
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


# this
def RunFiltersDir(filterfunction, dname):
	# the in and out directories for the type
	pwcmdirin = pwlordspages
	pwxmldirout = os.path.join(pwxmldirs, dname)

	# create output directory
	if not os.path.isdir(pwxmldirout):
		os.mkdir(pwxmldirout)

	# loop through file in input directory in reverse date order
	fdirin = os.listdir(pwcmdirin)
	fdirin.sort()
	fdirin.reverse()

	for fin in fdirin:
		jfin = os.path.join(pwcmdirin, fin)

		# extract the date from the file name
		sdate = re.search('\d{4}-\d{2}-\d{2}', fin).group(0)

		# create the output file name
		jfout = os.path.join(pwxmldirout, re.sub('\.html$', '.xml', fin))		

		# skip already processed files
		if os.path.isfile(jfout):
			continue

		# read the text of the file
		print jfin
		ofin = open(jfin)
		text = ofin.read()
		ofin.close()
		
		# call the filter function and copy the temp file into the correct place.
		# this avoids partially processed files getting into the output when you hit escape.
		fout = open(tempfile, "w")
		filterfunction(fout, text, sdate)
		fout.close()
		print jfout
		os.rename(tempfile, jfout)

# These text filtering functions filter twice through stringfiles,
# before directly filtering to the real file.
def RunLordsFilters(fout, text, sdate):
	si = cStringIO.StringIO()
	FilterLordsColtime(fout, text, sdate)


###############
# Main Function
###############

# create the output directory
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

RunFiltersDir(RunLordsFilters, 'lords')


