#! /usr/bin/python2.3

# Converts names of MPs into unique identifiers

import xml.sax
import re

class MemberList(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.members={}
        self.fullnames={}
        self.lastnames={}
        self.aliases={}

        # "rah" here is a typo in division 64 on 13 Jan 2003 "Ancram, rah Michael"
        self.titles = "Dr\\ |Hon\\ |hon\\ |rah\\ |rh\\ |Mrs\\ |Ms\\ |Dr\\ |Mr\\ |Miss\\ |Ms\\ |Rt\\ Hon\\ |The\\ Reverend\\ |Sir\\ |Rev\\ ";

        parser = xml.sax.make_parser()
        parser.setContentHandler(self)
        parser.parse("../members/all-members.xml")
        parser.parse("../members/member-aliases.xml")

    def startElement(self, name, attr):
        """ This handler is invoked for each XML element (during loading)"""
        if name == "member":
            self.members[attr["id"]] = attr
            # index by "Firstname Lastname" for quick lookup
            compoundname = attr["firstname"] + " " + attr["lastname"]
            if self.fullnames.has_key(compoundname):
                self.fullnames[compoundname].append(attr)
            else:
                self.fullnames[compoundname] = [attr,]

            # add in names without the middle initial -- should be made in a second
            # pass to make sure we're not adding in matches that shouldn't be there.
            fnnomidinitial = re.findall('^(\S*)\s\S$', attr["firstname"])
            if fnnomidinitial:
                compoundname = fnnomidinitial[0] + " " + attr["lastname"]
                if not self.fullnames.has_key(compoundname):
                    self.fullnames[compoundname] = [attr,]

	    # and also by "Lastname"
            lastname = attr["lastname"]
            if self.lastnames.has_key(lastname):
                self.lastnames[lastname].append(attr)
            else:
                self.lastnames[lastname] = [attr,]
                
        if name == "alias":
            if self.fullnames.has_key(attr["alternate"]):
                raise Exception, 'Already have alternate ' + attr["alternate"]
            else:
                self.fullnames[attr["alternate"]] = self.fullnames[attr["canonical"]]

    def matchfullname(self, input, date):
        text = input

        # Remove dots, but leave a space between them
        text = text.replace(".", " ")
        text = text.replace("  ", " ")

	# doesn't seem to improve matching, and anyway python doesn't like it, even in a comment
	#text = text.replace('&#214;', 'Oe')

        # Remove initial titles
        (text, titlec) = re.subn("^(" + self.titles + ")", "", text)
        if titlec > 1:
            raise Exception, 'Multiple titles: ' + input



        # Find unique identifier for member
        id = ""
        matches = self.fullnames.get(text, None)
        if not matches and titlec == 1:
            matches = self.lastnames.get(text, None)
        if matches:
            for attr in matches:
                if date >= attr["fromdate"] and date <= attr["todate"]:
                    if id <> "":
                        return 'unknown', 'Matched multiple times: ' + input, ''
                    id = attr["id"]

        if id == "":
            return 'unknown', 'No match: ' + input, ''

        remadename = self.members[id]["firstname"] + " " + self.members[id]["lastname"]
        return id, '', remadename

# Construct the global singleton of class which people will actually use
memberList = MemberList()

