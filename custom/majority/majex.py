#! /usr/bin/python2.3

import re
import xml.sax
import sys
import string
import MySQLdb
import os
from resolvemembernames import memberList

######################################################################
# Read wrans count

class WransCount(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.count={}

    def startElement(self, name, attr):
        """ This handler is invoked for each XML element (during loading)"""
        if (name == "speech") and (attr["type"] == "ques"):
            id = attr["speakerid"]
            id = re.sub("uk.org.publicwhip/member/", "", id)
            self.count.setdefault(id, 0)
            self.count[id] += 1

wranscount = WransCount()
parser = xml.sax.make_parser()
parser.setContentHandler(wranscount)
dir = "/home/francis/pwdata/pwscrapedxml/wrans/"
fdirin = os.listdir(dir)
for fin in fdirin:
    print >>sys.stderr, fin
    parser.parse(dir + fin)


######################################################################
# Read rebellions

f = open("rebellions.txt")
rb = f.read()
f.close()
rbl = re.findall("(.*?)\n", rb)
rs = {}
for x in rbl:
    (mp, r) = re.split("\t", x)
    rs[mp] = r

######################################################################
# Read majorities

s = "../rawdata/majorities2001.html"

f = open(s, "r")
tx = f.read()
f.close()

sl = re.split("<table[^>]*>([\s\S]*?)</table>(?i)", tx)

mpt = sl[3]

pr = re.findall("<tr><td><a[^>]*>(.*?)</a></td><td>(?:<a[^>]*>)?([^<]*?)(?:</a>)?</td><td>(?:<font[^>]*>)?(.*?)(?:</font>)?</td><td[^>]*>(?:<font[^>]*>)?(.*?)(?:</font>)?</td>.*?</tr>(?i)", mpt)

for jp in pr:
	maj = string.atoi(string.replace(jp[3], ",", ""))
        id = memberList.matchfulldivisionname(jp[1], '2001-06-07')
        if id[0] <> "unknown":
            thisid = re.sub("uk.org.publicwhip/member/", "", id[0])
            print "%s, %s" % (maj, wranscount.count.setdefault(thisid, 0))
	#print jp
# rs[thisid],


