#! /usr/bin/python2.3
# vim:sw=4:ts=4:et:nowrap

# Converts names of MPs into unique identifiers

import xml.sax
import re
import string
import copy

from parlphrases import parlPhrases

class MemberList(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.members={}
        self.fullnames={}
        self.lastnames={}
        self.aliases={}
        self.debatedate=None
        self.debatenamehistory=[]
        self.conscanonical = {} # constituency aliases --> canonical constituency
        self.constituencies = {} # constituency --> MP ids

        # "rah" here is a typo in division 64 on 13 Jan 2003 "Ancram, rah Michael"
        self.titles = "Dr |Hon |hon |rah |rh |Mrs |Ms |Dr |Mr |Miss |Ms |Rt Hon |Reverend |The Reverend |Sir |Rev "
        self.retitles = re.compile('^(?:%s)' % self.titles)
        self.rejobs = re.compile('^%s$' % parlPhrases.regexpjobs)

        self.honourifics = " CBE| OBE| MBE| QC| BEM| rh| RH| Esq| QPM";
        self.rehonourifics = re.compile('(?:%s)$' % self.honourifics)

        parser = xml.sax.make_parser()
        parser.setContentHandler(self)
        parser.parse("../members/all-members.xml")
        parser.parse("../members/member-aliases.xml")
        self.loadconsid = None
        self.loadconscanon = None
        parser.parse("../members/constituencies.xml")

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

            # and by constituency
            cons = attr["constituency"]
            self.constituencies.setdefault(cons, []).append(attr)

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

        elif name == "constituency":
            self.loadconsid = attr["id"]
            pass
        elif name == "name":
            if self.loadconsid: # name tag within constituency tag
                if not self.loadconscanon:
                    self.loadconscanon = attr["text"] # canonical constituency name is first listed
                self.conscanonical[attr["text"]] = self.loadconscanon
            pass
            
    def endElement(self, name):
        if name == "constituency":
            self.loadconsid = None
            self.loadconscanon = None

    def fullnametoids(self, input, date):
        text = input

        # Remove dots, but leave a space between them
        text = text.replace(".", " ")
        text = text.replace("  ", " ")

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

    # Matches names - exclusively for debates pages
    def matchdebatename(self, input, bracket, date):
        speakeroffice = ""

        # Clear name history if date change
        # The name history stores all recent names:
        #   Mr. Stephen O'Brien (Eddisbury) 
        # So it can match them when listed in shortened form:
        #   Mr. O'Brien
        if self.debatedate != date:
            self.debatedate = date
            self.debatenamehistory = []
        
        # Sometimes no bracketed component: Mr. Prisk
        ids = self.fullnametoids(input, date)
        # Different types of brackets...
        if bracket:
            if len(ids) == 0:
                # Sometimes name in brackets: 
                # The Minister for Industry and the Regions (Jacqui Smith)
                ids = self.fullnametoids(bracket, date)
                speakeroffice = ' speakeroffice="%s" ' % input
            elif len(ids) > 1:
                # Disambiguate by constituency if we need to
                # Sometimes constituency in brackets: Malcolm Bruce (Gordon)

                # Get constituency in the form used in the MP table
                cons = self.conscanonical.get(bracket, None)

                # Search for constituency matches 
                newids = []
                matches = self.constituencies.get(cons, None)
                if matches:
                    for attr in matches:
                        if date >= attr["fromdate"] and date <= attr["todate"]:
                            if attr["id"] in ids:
                                newids.append(attr["id"])
                if len(newids) > 0:
                    print "cons disambig! " , input, bracket
                    ids = newids

        # If of form "Mr. O'Brien" and ambiguous, look in recent name match history
        if len(ids) > 1 and not bracket:
            # check of form "Mr. O'Brien"
            text = input
            text = text.replace(".", " ")
            text = text.replace("  ", " ")
            text = self.retitles.sub("", text)
            matches = self.lastnames.get(text, None)
            if matches:
                # search through history, starting at the end
                history = copy.copy(self.debatenamehistory)
                history.reverse()
                for x in history:
                    if x in ids:
                        # print "Hit history match " + input
                        # first match, use it and exit
                        ids = [x,]
                        break
            else:
                print "No matches " + input

        # Return errors
        if len(ids) == 0:
        #    print "No matches " + input
            return 'speakerid="unknown" error="No match" speakername="%s (%s)"' % (input, bracket)
        if len(ids) > 1:
        #    print "Multiple matches " + input
            return 'speakerid="unknown" error="Matched multiple times" speakername="%s (%s)"' % (input, bracket)
        id = ids[0]
        
        # Store id in history for this day
        self.debatenamehistory.append(id)

        # Return id and name as XML attributes
        remadename = self.members[id]["firstname"] + " " + self.members[id]["lastname"]
        return 'speakerid="%s" speakername="%s"%s' % (id, remadename, speakeroffice)

        # Bradley, rh Keith <i>(Withington)</i>
        def matchfulldivisionname(self, inp, date):
            ginp = re.match("([\w\-']*), ([ \w.#&;]*?)\s*(?:<i>\(([ \w&'.\-]*)\)</i>)?$", inp)
            if ginp:
                inp = '%s %s' % (ginp.group(2), ginp.group(1))
            else:
                print "No match:", inp
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

