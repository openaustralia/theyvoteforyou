#!/usr/bin/python2.3
# -*- coding: latin-1 -*-
# $Id: edmconv.py,v 1.1 2004/03/08 13:59:01 frabcus Exp $

# Makes file connecting MP ids to URL in the Early Day Motion EDM)
# database at http://edm.ais.co.uk/

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

import xml.sax
import datetime
import sys
import urllib
import urlparse
import re

sys.path.append("../pyscraper/")
import re
from resolvemembernames import memberList

edm_framed_url = "http://edm.ais.co.uk/weblink/html/member.html/mem=%sSlAsHcOdEsTrInG%s"
date_today = datetime.date.today().isoformat()

class MemberLoad(xml.sax.handler.ContentHandler):
    def startElement(self, name, attr):
        if name == "member" and attr["house"] == "commons":
            if attr["fromdate"] <= date_today and attr["todate"] >= date_today:

                lastname = attr["lastname"]
                firstname = attr["firstname"]
                # EDM doesn't have the accented characters
                lastname = lastname.replace('ô'.decode('latin1'), 'o')
                lastname = lastname.replace('Ö'.decode('latin1'), 'O')
                # Special cases for MP names
                if firstname == "A J":
                    firstname = "AJ"
                if lastname == "Bennett" and firstname == "Andrew":
                    firstname = "Andrew F"
                if lastname == "Brown" and firstname == "Nick":
                    firstname = "Nicholas"
                if lastname == "Browne" and firstname == "Des":
                    firstname = "Desmond"
                if lastname == "Foster" and firstname == "Michael" and attr["constituency"] == "Worcester":
                    firstname = "Michael John"
                if firstname == "Gareth" and lastname == "Thomas":
                    lastname = lastname + " (" + attr["constieuncy"] + ")"

                # Construct URL
                test_url = edm_framed_url % (lastname, firstname)
                test_url = test_url.replace(' ', '%20')

                # Grab frame page 
		ur = urllib.urlopen(test_url)
		frame_content = ur.read()
		ur.close()
                
                # Search for where the content page is
                find_url = re.search('<FRAME\s*SRC="(.*?)"\s*NAME="CONTENT"', frame_content)
                if not find_url:
                    print >>sys.stderr, "Failed to find content url from frame ", test_url
                    return

                content_url = find_url.group(1)
                content_url = urlparse.urljoin(test_url, content_url)

                # Grab content page, and check our search succeeded.
                # We assume that success is if and only if a constituency was matched
                ur = urllib.urlopen(content_url)
                content = ur.read()
                ur.close()
                find_cons = re.search('<i>Constituency:</i>&nbsp;<FONT SIZE="\+1">(.*?)</FONT>', content)
                if not find_cons:
                    print content
                    print >>sys.stderr, "Failed to find constituency in result ", test_url, " innerpage " , content_url
                    return

                # See if constituency matches
                constituency = find_cons.group(1)
                constituency = memberList.canonicalisecons(constituency)
                if constituency <> attr["constituency"]:
                    print >>sys.stderr, "Constituencies don't match ", constituency, " and ", attr["constituency"]
                    return

                print '<memberinfo id="%s" edm_ais_url="%s" />' % (attr['id'], test_url)
                sys.stdout.flush()
                
print '''<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>'''

ml = MemberLoad()
parser = xml.sax.make_parser()
parser.setContentHandler(ml)
parser.parse("../members/all-members.xml")

print '</publicwhip>'

