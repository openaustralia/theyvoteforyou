#!/usr/local/bin/python2.3
# -*- coding: latin-1 -*-

# Makes file connecting MP ids to their expenses

import datetime
import sys
import urllib
import urlparse
import re
import sets

sys.path.append("../pyscraper/")
import re
from resolvemembernames import memberList

date_today = datetime.date.today().isoformat()
expmembers  = sets.Set() # for storing who we have found links for

print '''<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>'''

yearstr = 'expenses2002'
for year in [ '200102' ]:
	file = open('../rawdata/mpsexpenses' + year + '.tsv')
	content = file.readlines()
	file.close()

#    if re.search("Not Found(?i)", content):
#        raise Exception, "Failed to get content in url %s" % test_url

#    matcher = '<TD ALIGN="LEFT" VALIGN="TOP"><A HREF="(/weblink/html/member.html/.*)/log=\d+/pos=\d+" TARGET="_parent"><font face="arial,helvetica" size=2>(.*)/(.*)</A></TD>\s*<TD ALIGN="LEFT" VALIGN="TOP"><font face="arial,helvetica" size=2>(.*)</TD>'
#    matches = re.findall(matcher, content)

# Members’ Allowance Expenditure April 2003 – March 2004
# Member	Constituency	Column 1 - Additional Costs Allowance	Column 2 - London Supplement	Column 3 - IEP	Column 4 - Staff Costs	Column 5 - Members' Travel	Column 6 - Members' Staff Travel	Column 7 - Centrally Purchased Stationery	Column 7a - Stationery: Associated Postage Costs	Column 8 - Central IT Provision	Column 9 - Other Costs

	for line in content:
		cols = line.split("\t")
		first = cols[0]
		last = cols[1]
		cons = cols[2]
		money = cols[3:]
		money = map(lambda x: re.sub("\xa3","", x), money)
		id, name, cons =  memberList.matchfullnamecons(first + " " + last, cons, '2002-03-31')
		if not id:
			raise Exception, "Failed to find MP %s %s" % (first, last)

		pid = memberList.membertoperson(id)
		print >>sys.stderr, last, first, money
		if id in expmembers:
			print >>sys.stderr, "Ignored repeated entry for " , id
		else:
			print '<memberinfo id="%s" ' % id
			for i in [ 0,1,2,3,4,5,6,7,8 ]:
#				if (i==7):
#					col = '7a'
#				elif (i==8 or i==9):
#					col = i
#				else:
				col = i+1
				print '%s_col%s="%s" ' % (yearstr, col, money[i].strip())
			print '/>'
		expmembers.add(id)

	sys.stdout.flush()

print '</publicwhip>'

# Check we have everybody
#allmembers = sets.Set(memberList.currentmpslist())
#symdiff = allmembers.symmetric_difference(expmembers)
#if len(symdiff) > 0:
#    print >>sys.stderr, "Failed to get all MPs, these ones in symmetric difference"
#    print >>sys.stderr, symdiff
