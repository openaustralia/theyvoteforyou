#!/usr/bin/env python2.3
# -*- coding: latin-1 -*-
# $Id: edmconv.py,v 1.5 2004/12/17 11:06:19 theyworkforyou Exp $

# Makes file connecting MP ids to URL in the Early Day Motion EDM)
# database at http://edm.ais.co.uk/

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

import datetime
import sys
import urllib
import urlparse
import re
import sets

sys.path.append("../pyscraper/")
import re
from resolvemembernames import memberList

# NOTE: These pages will probably not work until they have been viewed via
# EDM's crappy web interface, so that they are created and cached.
#
# curl http://edm.ais.co.uk/weblink/html/members.html/start=[a-z]/order=1/EDMI_SES=
# is your friend.

edm_index_url = "http://edm.ais.co.uk/cache/members/list.1.%s.html"
date_today = datetime.date.today().isoformat()

aismembers  = sets.Set() # for storing who we have found links for

print '''<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>'''

for letter in [ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
    'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' ]:
    
    # Construct URL
    test_url = edm_index_url % (letter)

    # Grab page 
    ur = urllib.urlopen(test_url)
    content = ur.read()
    ur.close()

    if re.search("Not Found(?i)", content):
        raise Exception, "Failed to get content in url %s" % test_url

    matcher = '<TD ALIGN="LEFT" VALIGN="TOP"><A HREF="(/weblink/html/member.html/.*)/log=\d+/pos=\d+" TARGET="_parent"><font face="arial,helvetica" size=2>(.*)/(.*)</A></TD>\s*<TD ALIGN="LEFT" VALIGN="TOP"><font face="arial,helvetica" size=2>(.*)</TD>'
    matches = re.findall(matcher, content)
    for (url, last, first, cons) in matches:
        print >>sys.stderr, last, first, url
    
        first = re.sub(" \(.*\)", "", first)
        id, name, cons =  memberList.matchfullnamecons(first + " " + last, cons, date_today)
        url = urlparse.urljoin(test_url, url)

        if id in aismembers:
            print >>sys.stderr, "Ignored repeated entry for " , id
        else:
            print '<memberinfo id="%s" edm_ais_url="%s" />' % (id, url)

        aismembers.add(id)

    sys.stdout.flush()

print '</publicwhip>'

# Check we have everybody
allmembers = sets.Set(memberList.currentmpslist())
symdiff = allmembers.symmetric_difference(aismembers)
if len(symdiff) > 0:
    print >>sys.stderr, "Failed to get all MPs, these ones in symmetric difference"
    print >>sys.stderr, symdiff


