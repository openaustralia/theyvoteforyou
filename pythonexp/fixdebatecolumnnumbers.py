import sys
import re

# this filter converts time and column number tags into xml form
# <stamp time="3.55 pm"/>
# <stamp coldate="7 Nov 2000" colnum="139"/>

# in and out files for this filter
filein = "f2hocdaydebate2000-11-07.htm"
fileout = "f3hocdaydebate2000-11-07.htm"

# <B>7 Nov 2000 : Column 180</B>
lcolumnregexp = '<b>\s*.*?\s*:\s*column\s*\d+\s*</b>(?i)'
columnregexp = '<b>\s*(.*?)\s*:\s*column\s*(\d+)\s*</b>(?i)'
# <H5>4.40 pm</H5>
ltimeregexp = '<h5>\d+[.]\d+\s*[ap]m</h5>(?i)'
timeregexp = '<h5>(.*?)</h5>(?i)'

combiregexp = '(%s|%s)' % (lcolumnregexp, ltimeregexp)

fin = open(filein);
fr = fin.read()
fs = re.split(combiregexp, fr)
fin.close()

fout = open(fileout, "w");

for fss in fs:
	if not fss:
		continue
	timegroup = re.search(timeregexp, fss)
	if timegroup:
		fout.write('<stamp time="%s"/>' % timegroup.group(1))
		continue
	columngroup = re.search(columnregexp, fss)
	if columngroup:
		fout.write('<stamp coldate="%s" colnum="%s"/>' % (columngroup.group(1), columngroup.group(2)))
		continue
	fout.write(fss)

fout.close()
