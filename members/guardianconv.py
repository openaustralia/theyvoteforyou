#!/usr/bin/python2.3
# $Id: guardianconv.py,v 1.7 2004/06/11 09:10:07 theyworkforyou Exp $

# Converts tab file of Guardian URLs into XML.  Also extracts swing/majority
# from the constituency page on the Guardian.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

input = '../rawdata/mpinfo/guardian-mpsurls.txt'
date = '2004-02-25'

import sys
import string
import urllib
import re
sys.path.append("../pyscraper")
from resolvemembernames import memberList

print '''<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>
'''

ih = open(input, 'r')

c = 0
for l in ih:
    c = c + 1
    origname, origcons, personurl, consurl = map(string.strip, l.split("\t"))

    # Match the name, and output basic URLs
    id, name, cons =  memberList.matchfullnamecons(origname, origcons, date)
    personid = memberList.membertoperson(id)
    cons = cons.replace("&", "&amp;")
    print '<personinfo id="%s" guardian_mp_summary="%s" />' % (personid, personurl)
    print '<consinfo canonical="%s" guardian_election_results="%s" />' % (cons.encode("latin-1"), consurl)

    # Majority
    setsameelection =  memberList.getmembersoneelection(id)
    #print setsameelection

    # Grab swing from the constituency page
    ur = urllib.urlopen(consurl)
    content = ur.read()
    ur.close()
    m = re.search("requires a (\d+\.\d+) \&\#037\; swing to gain seat", content)
    if m:
        for id in setsameelection:
            print '<memberinfo id="%s" swing_to_lose_seat="%s" />' % (id, m.group(1))
    else:
        print >>sys.stderr, "no match for swing at url %s" % consurl

    m = re.search("majority: ([\d,]+)", content)
    if m:
        for id in setsameelection:
            print '<memberinfo id="%s" majority_in_seat="%s" />' % (id, m.group(1).replace(",", ""))
    else:
        print >>sys.stderr, "no match for majority at url %s" % consurl

    print ''

assert c == 659, "Expected %d MPs" % c

ih.close()

print '</publicwhip>'

