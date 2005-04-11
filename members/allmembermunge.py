#! /usr/bin/env python2.3
# vim:sw=4:ts=4:et:nowrap

import xml.sax
import sets
import datetime
import re
import os
import sys

# Used for one off scripts to do fancy things to all-members.xml
# Read it before you run it :)
sys.exit()

sys.path.append("../pyscraper")
from resolvemembernames import memberList

today = datetime.date.today().isoformat()

standing_down = {}
for line in file("../rawdata/mps-retiring2005.txt"):
    (origname, origcons) = line.split(",")  
    id, name, cons =  memberList.matchfullnamecons(origname, origcons, today)
    assert id, "Couldn't match %s" % line
    standing_down[id] = 1
standing_down_count = 0
restanding_count = 0

class MemberMunge(xml.sax.handler.ContentHandler):
    def __init__(self, fout):
		# self.ministermap={}
        self.fout = fout

        parser = xml.sax.make_parser()
        parser.setContentHandler(self)
        parser.setProperty(xml.sax.handler.property_lexical_handler, self)
        parser.parse("all-members.xml")

    def startElement(self, name, attr):
        newattr = {}
        for k in attr.getNames():
            newattr[k] = attr[k]
            
        if name == "member":
            if attr['towhy'] == 'still_in_office':
                assert attr['todate'] == "9999-12-31"
                newattr['todate'] = '2005-04-11'

                if attr['id'] in standing_down:
                    newattr['towhy'] = 'general_election_not_standing'
                    del standing_down[attr['id']]
                    global standing_down_count
                    standing_down_count = standing_down_count + 1
                else:
                    newattr['towhy'] = 'general_election_standing'
                    global restanding_count
                    restanding_count = restanding_count + 1
                    

            self.fout.write(("""<member
    id="%s"
    house="%s"
    title="%s" firstname="%s" lastname="%s"
    constituency="%s" party="%s"
    fromdate="%s" todate="%s" fromwhy="%s" towhy="%s"
/>
"""          % (newattr['id'], newattr['house'], newattr['title'], 
                newattr['firstname'], newattr['lastname'],
                newattr['constituency'].replace("&", "&amp;"), newattr['party'], 
                newattr['fromdate'], newattr['todate'], newattr['fromwhy'], newattr['towhy'])
            ).encode("latin-1"))

        if name == "publicwhip":
            fout.write("<publicwhip>\n\n")

    def endElement(self, name):
        if name == "publicwhip":
            fout.write("\n\n</publicwhip>\n")

    # property_lexical_handler requires we have these functions...
    def startCDATA(self, content):
        pass
    def endCDATA(self, content):
        pass
    def endDTD(self, content):
        pass
    
    # ...when really we just want this one
    def comment(self, comment):
        self.fout.write("<!--%s-->\n" % comment)

# the main code
tempfile = "tempallmembers.xml"
fout = open(tempfile, "w")
fout.write("""<?xml version="1.0" encoding="ISO-8859-1"?>
""")
MemberMunge = MemberMunge(fout)
fout.close()

if standing_down:
    print "Didn't find some standing down members"
    print standing_down.keys()

print "Standing down: %d" % standing_down_count
print "Restanding: %d" % restanding_count
print "Total: %d" % (standing_down_count + restanding_count)

