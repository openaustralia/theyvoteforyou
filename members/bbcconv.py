#!/usr/bin/python2.3
# -*- coding: latin-1 -*-
# $Id: bbcconv.py,v 1.1 2004/03/11 11:18:47 frabcus Exp $

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

# Get list of alphabetical pages
bbc_index_url = "http://news.bbc.co.uk/1/hi/uk_politics/2160988.stm"
ur = urllib.urlopen(bbc_index_url)
content = ur.read()
ur.close()
alphaurls = re.findall('<option value="(/1/hi/uk_politics/\d*.stm)">[A-Z]</option>', content)

date_today = datetime.date.today().isoformat()
bbcmembers  = sets.Set() # for storing who we have found links for

print '''<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>'''

for test_url in alphaurls:
    # Grab page 
    ur = urllib.urlopen(urlparse.urljoin(bbc_index_url, test_url))
    content = ur.read()
    ur.close()

    content = content.replace("McGuire Anne", "McGuire, Anne")

    matcher = '<td><a\s*href="(/1/hi/uk_politics/\d+.stm)" style="text-decoration: none; color:333366;">([\s\S]*?),\s*([\s\S]*?)</a></td>\s*<td(?: valign="top")?>([\s\S]*?)</td>';
    matches = re.findall(matcher, content)
    for match in matches:
        match = map(lambda x: re.sub("&amp;", "&", x), match)
        match = map(lambda x: re.sub("\s+", " ", x), match)
        match = map(lambda x: re.sub("\xa0", "", x), match)
        match = map(lambda x: x.strip(), match)
        (url, last, first, cons) = match

        print "%s %s, %s" % (first, last, cons)
        first = re.sub(" \(.*\)", "", first)
        id, name, cons =  memberList.matchfullnamecons(first + " " + last, cons, date_today)
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


