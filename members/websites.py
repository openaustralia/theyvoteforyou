#!/usr/local/bin/python2.3
# -*- coding: latin-1 -*-

# Makes file connecting MP ids to their homepages

import datetime
import sys
import urllib
import urlparse
import re
import sets

sys.path.append("../pyscraper/")
import re
from resolvemembernames import memberList

# date_today = datetime.date.today().isoformat()

expmembers = sets.Set()
fout = open('websites.xml', 'w')
fout.write('''<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>\n''')

file = open('../rawdata/websites.tsv')
content = file.readlines()
file.close()

for line in content:
	cols = line.split("\t")
	cons = cols[0]
	first = cols[1]
	last = cols[2]
	party = cols[3]
	website = cols[4].strip()
	if not website:
		continue
	id, name, cons =  memberList.matchfullnamecons(first + " " + last, cons, '2005-02-17')
	if not id:
		print >>sys.stderr, "Failed to find MP %s %s" % (first, last)
		continue

	pid = memberList.membertoperson(id)
#	print >>sys.stderr, last, first, money
	if pid in expmembers:
		print >>sys.stderr, "Ignored repeated entry for " , pid
	else:
		fout.write('<personinfo id="%s" ' % pid)
		fout.write('mp_website="%s" ' % website)
		fout.write('/>\n')
	expmembers.add(pid)

sys.stdout.flush()

fout.write('</publicwhip>\n')
fout.close()
