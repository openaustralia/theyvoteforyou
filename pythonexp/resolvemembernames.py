#! /usr/bin/python2.3

import xml.sax
import re

class MemberList(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.members={}
        self.matches=[]

        parser = xml.sax.make_parser()
        parser.setContentHandler(self)
        parser.parse("../migrate/members.xml")

        regexpstring = "(%s)" % "|".join(map(re.escape, self.matches))
        self.regexp = re.compile(regexpstring)

    def matchName(self, attr):
        return attr["firstname"] + " " + attr["lastname"]

    def startElement(self, name, attr):
        """ This handler is invoked for each XML element """
        if name == "member":
            self.members[attr["id"]] = attr
            self.matches += [self.matchName(attr),]

    def replace(self, text):
        return self.regexp.sub(self, text)

    def __call__(self, mo): 
        """ This handler is invoked for each regex match """
        matchstr = mo.string[mo.start():mo.end()]
        ret = []
        for m in self.members.values():
            if self.matchName(m) == matchstr:
               ret += [m["party"],]
        return matchstr + " (" + ",".join(ret) + ")"

text = "I love George Galloway, and George loves Tony Blair."
print "Original: ", text
memberList = MemberList()
text = memberList.replace(text)
print "Replaced: ", text;

