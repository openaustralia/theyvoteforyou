#! /usr/bin/python2.3

import sys
import re

# this filter removes all <!-- comments --> tags
#    and <a name="01107-28_para6"></a> tags
# These are of no use in the data since they are undocumented and largely reflect
# what is said in the text itself.


# in and out files for this filter
filein = "hocdaydebate2000-11-07.htm"
fileout = "f2hocdaydebate2000-11-07.htm"
filejunk = "f2hocdaydebate2000-11-07-junk.htm"

# <!--META NAME="Colno" CONTENT="236"-->
commentregexp = '<!--.*?-->'
# <A NAME = "01107-28_para6"></a>
anameregexp = '<a\s+name\s*=\s*".*?"></a>(?i)'

combiregexp = '(%s|%s)' % (commentregexp, anameregexp)
print combiregexp

fin = open(filein);
fs = re.split(combiregexp, fin.read())
fin.close()

fout = open(fileout, "w");
junk = open(filejunk, "w");

for fss in fs:
	if re.match(combiregexp, fss):
		junk.write(fss)
	else:
		fout.write(fss)

fout.close()
junk.close()
