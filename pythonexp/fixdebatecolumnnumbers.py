import sys
import re
import os
import string

# this filter converts time and column number tags into xml form
# <stamp time="3.55 pm"/>
# <stamp coldate="7 Nov 2000" colnum="139"/>

# in and out files for this filter
dirin = "c1daydebateremovechars"
dirout = "c2daydebatefixcolumnnumbers"
dtemp = "daydebtemp.htm"

# <B>7 Nov 2000 : Column 180</B>
lcolumnregexp = '<b>\s*.*?\s*:\s*column\s*\d+\s*</b>(?i)'
columnregexp = '<b>\s*(.*?)\s*:\s*column\s*(\d+)\s*</b>(?i)'

#<i>14 Oct 2003 : Column 31&#151;continued</i>
lcolumncontregexp = '<i>\s*.*?\s*:\s*column\s*\d+&#151;continued\s*</i>(?i)'
columncontregexp = '<i>\s*(.*?)\s*:\s*column\s*(\d+)&#151;continued\s*</i>(?i)'

# <H5>4.40 pm</H5>  or <H4>4 pm</H4>
ltimeregexp = '<h\d>[\d.]+\s*[ap]m(?:</st>)?</h\d>(?i)'
timeregexp = '<h\d>([\d.]+\s*[ap]m(?:</st>)?)</h\d>(?i)'

combiregexp = '(%s|%s|%s)' % (lcolumnregexp, lcolumncontregexp, ltimeregexp)

# scan through directory
fdirin = os.listdir(dirin)

for fin in fdirin:
	jfin = os.path.join(dirin, fin)
	jfout = os.path.join(dirout, fin)
	if os.path.isfile(jfout):
		print "skipping " + fin
		continue

	print fin
	fin = open(jfin);
	fr = fin.read()
	fs = re.split(combiregexp, fr)
	fin.close()

	tempfile = open(dtemp, "w")
	lcoldate = ''
	lcolnum = -1

	for fss in fs:
		if not fss:
			continue

		columngroup = re.findall(columnregexp, fss)
		if len(columngroup) != 0:
			if lcoldate == '':
				lcoldate = columngroup[0][0]
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
				tempfile.write('<stamp coldate="%s" colnum="%s"/>' % columngroup[0])  # a tuple

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

		timegroup = re.findall(timeregexp, fss)
		if len(timegroup) != 0:
			tempfile.write('<stamp time="%s"/>' % timegroup[0])
			continue

		tempfile.write(fss)

	tempfile.close()
	os.rename(dtemp, jfout)

