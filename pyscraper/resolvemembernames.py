#! /usr/bin/python2.3
# vim:sw=4:ts=4:et:nowrap

# Converts names of MPs into unique identifiers

import xml.sax
import re
import string
import copy
import sets
import sys

from parlphrases import parlPhrases

class MemberList(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.members={} # ID --> MPs
        self.fullnames={} # "Firstname Lastname" --> MPs
        self.lastnames={} # Surname --> MPs
        self.debatedate=None
        self.debatenamehistory=[] # recent speakers in debate
        self.debateofficehistory={} # recent offices ("The Deputy Prime Minister")
        self.conscanonical = {} # constituency aliases --> canonical constituency
        self.constituencies = {} # constituency --> MPs
        self.parties = {} # constituency --> MPs

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

            # and by party
            cons = attr["party"]
            self.parties.setdefault(cons, []).append(attr)

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
        ids = sets.Set()
        matches = self.fullnames.get(text, None)
        if not matches and titlec == 1:
            matches = self.lastnames.get(text, None)

        # If a speaker, then match agains the secial speaker parties
        if not matches and text == "Speaker":
            matches = self.parties.get("SPK", None)
        if not matches and text == "Deputy Speaker":
            matches = copy.copy(self.parties.get("DCWM", None))
            matches.extend(self.parties.get("CWM", None))

        if matches:
            for attr in matches:
                if date >= attr["fromdate"] and date <= attr["todate"]:
                    ids.add(attr["id"])

        return ids

    def matchfullname(self, input, date):
        ids = self.fullnametoids(input, date)

        if len(ids) == 0:
            return 'unknown', 'No match: ' + input, ''
        if len(ids) > 1:
            return 'unknown', 'Matched multiple times: ' + input, ''

        for id in ids:
            pass
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
            # TODO: Perhaps this is a bit loose - how far back in the history should
            # we look?  Perhaps clear history every heading?  Currently it uses the
            # entire day.  Check to find the maximum distance back Hansard needs
            # to rely on.
            self.debatedate = date
            self.debatenamehistory = []
            self.debateofficehistory = {}
        
        # Sometimes no bracketed component: Mr. Prisk
        ids = self.fullnametoids(input, date)
        # Different types of brackets...
        if bracket:
            # Sometimes name in brackets: 
            # The Minister for Industry and the Regions (Jacqui Smith)
            brackids = self.fullnametoids(bracket, date)
            if brackids:
                speakeroffice = ' speakeroffice="%s" ' % input
                # If so, intersect those matches with ones from the first part
                # (some offices get matched in first part - like Mr. Speaker)
                if len(ids) > 0:
                    ids = ids.intersection(brackids)
                else:
                    ids = brackids

            # Sometimes constituency in brackets: Malcolm Bruce (Gordon)
            # Get constituency in the form used in the MP table
            cons = self.conscanonical.get(bracket, None)
            if cons:
                # Search for constituency matches, and intersect results with them
                newids = sets.Set()
                matches = self.constituencies.get(cons, None)
                if matches:
                    for attr in matches:
                        if date >= attr["fromdate"] and date <= attr["todate"]:
                            if attr["id"] in ids:
                                newids.add(attr["id"])
                ids = newids

        # If ambiguous (either form "Mr. O'Brien" or full name, ambiguous due
        # to missing constituency) look in recent name match history
        if len(ids) > 1:
            # search through history, starting at the end
            history = copy.copy(self.debatenamehistory)
            history.reverse()
            for x in history:
                if x in ids:
                    # first match, use it and exit
                    ids = sets.Set([x,])
                    break

        # Office name history ("The Deputy Prime Minster (John Prescott)" is later
        # referred to in the same day as just "The Deputy Prime Minister")
        officeids = self.debateofficehistory.get(input, None)
        if officeids:
            if len(ids) == 0:
                ids = officeids

        # Match between office and name - store for later use in the same days text
        if speakeroffice <> "":
            self.debateofficehistory.setdefault(input, sets.Set()).union_update(ids)

        # Return errors
        if len(ids) == 0:
            if not re.search("Hon\.? Members|Deputy Speaker(?i)", input):
                print "No matches %s (%s)" % (input, bracket)
            return 'speakerid="unknown" error="No match" speakername="%s (%s)"' % (input, bracket)
        if len(ids) > 1:
            names = ""
            for id in ids:
                names += self.members[id]["firstname"] + " " + self.members[id]["lastname"] + " (" + self.members[id]["constituency"] + ") "
            print "Multiple matches %s (%s), possibles are %s" % (input, bracket, names)
            return 'speakerid="unknown" error="Matched multiple times" speakername="%s (%s)"' % (input, bracket)
        # Extract one id left
        for id in ids:
            pass
        
        # Store id in history for this day
        self.debatenamehistory.append(id)

        # Return id and name as XML attributes
        remadename = self.members[id]["firstname"] + " " + self.members[id]["lastname"]
        if self.members[id]["party"] == "SPK" and re.search("Speaker", input):
            remadename = input
        if (self.members[id]["party"] == "CWM" or self.members[id]["party"] == "DCWM") and re.search("Deputy Speaker", input):
            remadename = input
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

