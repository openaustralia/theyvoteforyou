#! /usr/bin/python2.3

# Converts names of MPs into unique identifiers

import xml.sax
import re
import string

class MemberList(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.members={}
        self.fullnames={}
        self.lastnames={}
        self.aliases={}

        # "rah" here is a typo in division 64 on 13 Jan 2003 "Ancram, rah Michael"
        self.titles = "Dr\\ |Hon\\ |hon\\ |rah\\ |rh\\ |Mrs\\ |Ms\\ |Dr\\ |Mr\\ |Miss\\ |Ms\\ |Rt\\ Hon\\ |The\\ Reverend\\ |Sir\\ |Rev\\ ";
	self.retitles = re.compile('^(?:%s)' % self.titles)

	self.honourifics = "\\ CBE|\\ OBE|\\ MBE|\\ QC|\\ BEM|\\ rh|\\ RH|\\ Esq|\\ QPM";
	self.rehonourifics = re.compile('(?:%s)$' % self.honourifics)

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
	    self.fullnames.setdefault(compoundname, []).append(attr)

            # add in names without the middle initial
            fnnomidinitial = re.findall('^(\S*)\s\S$', attr["firstname"])
            if fnnomidinitial:
                compoundname = fnnomidinitial[0] + " " + attr["lastname"]
		self.fullnames.setdefault(compoundname, []).append(attr)

	    # and also by "Lastname"
            lastname = attr["lastname"]
	    self.lastnames.setdefault(lastname, []).append(attr)

        elif name == "alias":
	    matches = self.fullnames.get(attr["canonical"], None)
	    if not matches:
		raise Exception, 'Canonical name not found ' + attr["canonical"]
	    # append every canonical match to the alternates
	    for m in matches:
		newattr = {}
		newattr['id'] = m['id']
		# merge date ranges - take the smallest range covered by
		# the canonical name, and the alias's range (if it has one)
		early = max(m['fromdate'], attr.get('from', '1000-01-01'))
		late = min(m['todate'], attr.get('to', '9999-12-31'))
		# sometimes the ranges don't overlap
		if early <= late:
		    newattr['fromdate'] = early
		    newattr['todate'] = late
		    self.fullnames.setdefault(attr["alternate"], []).append(newattr)

    def fullnametoids(self, input, date):
	text = input

        # Remove dots, but leave a space between them
        text = text.replace(".", " ")
        text = text.replace("  ", " ")

	# doesn't seem to improve matching, and anyway python doesn't like it,
	# even in a comment
	#text = text.replace('&#214;', 'Oe')

        # Remove initial titles
        (text, titlec) = self.retitles.subn("", text)
        if titlec > 1:
            raise Exception, 'Multiple titles: ' + input

        # Remove final honourifics
        (text, honourc) = self.rehonourifics.subn("", text)
        if honourc > 1:
            raise Exception, 'Multiple honourifics: ' + input

        # Find unique identifier for member
        ids = []
        matches = self.fullnames.get(text, None)
        if not matches and titlec == 1:
            matches = self.lastnames.get(text, None)
        if matches:
            for attr in matches:
                if date >= attr["fromdate"] and date <= attr["todate"]:
                    ids.append(attr["id"])

	return ids

    def matchfullname(self, input, date):
	ids = self.fullnametoids(input, date)

        if len(ids) == 0:
            return 'unknown', 'No match: ' + input, ''
	if len(ids) > 1:
	    return 'unknown', 'Matched multiple times: ' + input, ''

	id = ids[0]
        remadename = self.members[id]["firstname"] + " " + self.members[id]["lastname"]
        return id, '', remadename

    # Bradley, rh Keith <i>(Withington)</i>
    def matchfulldivisionname(self, inp, date):
	ginp = re.match("([\w\-']*), ([ \w.#&;]*?)\s*(?:<i>\(([ \w&'.\-]*)\)</i>)?$", inp)
	if ginp:
		inp = '%s %s' % (ginp.group(2), ginp.group(1))
	else:
		print inp
	return self.matchfullname(inp, date)


    def mpnameexists(self, input, date):
	ids = self.fullnametoids(input, date)

        if len(ids) > 0:
	    return 1

        if re.match('Mr\. |Mrs\. |Miss |Dr\. ', input):
		print ' potential missing MP name ' + input

	return 0

# Construct the global singleton of class which people will actually use
memberList = MemberList()

