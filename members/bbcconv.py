#!/usr/bin/env python2.3
# -*- coding: latin-1 -*-
# $Id: bbcconv.py,v 1.4 2005/03/25 23:33:35 theyworkforyou Exp $

# Makes file connecting MP ids to URL of their BBC political profile
# http://news.bbc.co.uk/1/hi/uk_politics/2160988.stm

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

# Get region pages
bbc_index_url = "http://news.bbc.co.uk/1/shared/mpdb/html/region_%d.stm"
date_today = datetime.date.today().isoformat()
bbcmembers  = sets.Set() # for storing who we have found links for

print '''<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>'''

for i in range(12):
    # Grab page 
    ur = urllib.urlopen(bbc_index_url % (i+1))
    content = ur.read()
    ur.close()

#    content = content.replace("McGuire Anne", "McGuire, Anne")

    matcher = '<a\s*href="(/1/shared/mpdb/html/\d+.stm)" title="Profile of the MP for (.*?)(?: \(.*?\))?"><b>\s*([\s\S]*?)\s*</b></a></td>';
    matches = re.findall(matcher, content)
    for match in matches:
        match = map(lambda x: re.sub("&amp;", "&", x), match)
        match = map(lambda x: re.sub("\s+", " ", x), match)
        match = map(lambda x: re.sub("\xa0", "", x), match)
        match = map(lambda x: x.strip(), match)
        (url, cons, name) = match

#        first = re.sub(" \(.*\)", "", first)
        id, name, cons =  memberList.matchfullnamecons(name, cons, date_today)
        url = urlparse.urljoin(bbc_index_url, url)

        if id in bbcmembers:
            print >>sys.stderr, "Ignored repeated entry for " , id
        else:
            print '<memberinfo id="%s" bbc_profile_url="%s" />' % (id, url)

        bbcmembers.add(id)

    sys.stdout.flush()

print '</publicwhip>'

# Check we have everybody
allmembers = sets.Set(memberList.currentmpslist())
symdiff = allmembers.symmetric_difference(bbcmembers)
if len(symdiff) > 0:
    print >>sys.stderr, "Failed to get all MPs, these ones in symmetric difference"
    print >>sys.stderr, symdiff


