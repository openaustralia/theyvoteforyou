#! /usr/bin/env python2.4
# vim:sw=4:ts=4:et:nowrap

import sys
import os
import urllib
from Ft.Xml.Domlette import NonvalidatingReader
import xml.sax.saxutils

# Load in our constituency names
consdoc = NonvalidatingReader.parseUri("file:constituencies.xml")
cons = {}
for name in consdoc.xpath('//constituency/name'):
    id = name.xpath('string(../@id)')
    name = name.xpath('string(@text)')
    cons[name] = id

# Load in BBC identifiers and constituency names
bbc_ids = {}
consfile = open("../rawdata/bbc-constituencies2005.txt")
for line in consfile:
    line = line.strip()
    (bbc_id, name) = line.split("|")
    name = name.replace(" (ex Speaker)", "")
#    win_name = consdoc.xpath('string(//Party[string(Code)="%s"]/CandidateName)' % bbc_win_party)
    if name not in cons:
        print name
    bbc_ids[int(bbc_id)] = name

sys.exit()

# Map from BBC party identifiers to ones used in all-members.xml
party_map = {
    'LAB':'Lab',
    'LD':'LDem',
    'CON':'Con',

    'DUP':'DU',
    'SDLP':'SDLP',
    'SF':'SF',
    'UUP':'UU',

    'SNP':'SNP',

    'PC':'PC',

    'RES':'Res',
    'IND':'Ind',
    'IKHH':'Ind',
}
    
# Read XML files from flash applet
mp_id = 1367
items = bbc_ids.iteritems()
#for i in range(0, 1834-mp_id):
#    mp_id = mp_id + 1
#    items.next() 
for bbc_id, cons_name in items:
    mp_id = mp_id + 1

    # Download and parse XML
    url = "http://news.bbc.co.uk/1/shared/vote2005/flash_map/resultdata/%d.xml" % bbc_id
    content = urllib.urlopen(url).read()
    #print content
    content = content.replace("skinkers:", "skinkers-") # remove XML namespace shite
    content = " ".join(content.split()) # replace all contiguous whitespace with one space
    doc = NonvalidatingReader.parseString(content, url)

    # Find winner
    bbc_win_party = doc.xpath('string(//winningParty)')
    # Missing data (bugs in BBC feed)
    if (cons_name == "Hertfordshire North East"):
        bbc_win_party = "CON"
    if (cons_name == "Lagan Valley"):
        bbc_win_party = "DUP"
    if (cons_name == "Staffordshire South"):
        continue # not declared yet
    win_party = party_map[bbc_win_party]
    win_name = doc.xpath('string(//Party[string(Code)="%s"]/CandidateName)' % bbc_win_party)


    # Make into first and surname
    names = win_name.split(" ")
    if len(names) == 2:
        (first_name, last_name) = names
    elif win_name == "Iain Duncan Smith":
        (first_name, last_name) = ("Iain", "Duncan Smith")
    else:
        assert "Unknown multi-name '%s'" % win_name

    # Print out our XML
    print """<member
        id="uk.org.publicwhip/member/%d"
        house="commons"
        title="" firstname="%s" lastname="%s"
        constituency="%s" party="%s"
        fromdate="2005-05-05" todate="9999-12-31" fromwhy="general_election" towhy="still_in_office"
    />
    """ % (mp_id, first_name, last_name, xml.sax.saxutils.escape(cons_name), win_party)


     

