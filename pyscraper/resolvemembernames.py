#! /usr/bin/python2.3
# vim:sw=4:ts=4:et:nowrap

# Converts names of MPs into unique identifiers

import xml.sax
import re
import string
import copy
import sets
import sys
import datetime

from parlphrases import parlPhrases

# These we don't necessarily match to a speaker id, deliberately
regnospeakers = "Hon\.? Members|Members of the House of Commons|" + \
        "Deputy Speaker|Second Deputy Chairman(?i)|The Chairman|First Deputy Chairman|Temporary Chairman"

# Cases we want to specially match - add these in as we need them
class MultipleMatchException(Exception):
    pass

class MemberList(xml.sax.handler.ContentHandler):
    def __init__(self):
        self.reloadXML()

    def reloadXML(self):
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
        self.titles = "Dr |Hon |hon |rah |rh |Mrs |Ms |Mr |Miss |Ms |Rt Hon |Reverend |The Rev |The Reverend |Sir |Rev |Prof "
        self.retitles = re.compile('^(?:%s)' % self.titles)
        self.rejobs = re.compile('^%s$' % parlPhrases.regexpjobs)

        self.honourifics = " MP| CBE| OBE| MBE| QC| BEM| rh| RH| Esq| QPM| JP| FSA| Bt| B.Ed \(Hons\)";
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
            if self.members.get(attr["id"]):
                raise Exception, "Repeated identifier %s in members XML file" % attr["id"]
            self.members[attr["id"]] = attr

            # index by "Firstname Lastname" for quick lookup ...
            compoundname = attr["firstname"] + " " + attr["lastname"]
            self.fullnames.setdefault(compoundname, []).append(attr)

            # add in names without the middle initial
            fnnomidinitial = re.findall('^(\S*)\s\S$', attr["firstname"])
            if fnnomidinitial:
                compoundname = fnnomidinitial[0] + " " + attr["lastname"]
                self.fullnames.setdefault(compoundname, []).append(attr)

            # ... and also by "Lastname"
            lastname = attr["lastname"]
            self.lastnames.setdefault(lastname, []).append(attr)

            # ... and by constituency
            cons = attr["constituency"]
            # check first date ranges don't overlap
            for curattr in self.constituencies.get(cons, []):
                if curattr['fromdate'] <= attr['fromdate'] <= curattr['todate'] \
                    or curattr['fromdate'] <= attr['todate'] <= curattr['todate'] \
                    or attr['fromdate'] <= curattr['fromdate'] <= attr['todate'] \
                    or attr['fromdate'] <= curattr['todate'] <= attr['todate']:
                    raise Exception, "Two entries for constituency %s with overlapping dates" % cons
             # then add in
            self.constituencies.setdefault(cons, []).append(attr)

            # ... and by party
            cons = attr["party"]
            self.parties.setdefault(cons, []).append(attr)

        elif name == "alias":
            # search for the canonical name or the constituency name for this alias
            matches = None
            alternateisfullname = True
            if attr.has_key("fullname"):
                matches = self.fullnames.get(attr["fullname"], None)
                if not matches:
                    raise Exception, 'Canonical fullname not found ' + attr["fullname"]
            elif attr.has_key("lastname"):
                matches = self.lastnames.get(attr["lastname"], None)
                alternateisfullname = False
                if not matches:
                    raise Exception, 'Canonical lastname not found ' + attr["lastname"]
            elif attr.has_key("constituency"):
                matches = self.constituencies.get(attr["constituency"], None)
                if not matches:
                    raise Exception, 'Canonical constituency not found ' + attr["constituency"]
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
                    if alternateisfullname:
                        self.fullnames.setdefault(attr["alternate"], []).append(newattr)
                    else:
                        self.lastnames.setdefault(attr["alternate"], []).append(newattr)

        elif name == "constituency":
            self.loadconsid = attr["id"]
            pass
        elif name == "name":
            if self.loadconsid: # name tag within constituency tag
                if not self.loadconscanon:
                    self.loadconscanon = attr["text"] # canonical constituency name is first listed
                if self.conscanonical.get(attr["text"], None):
                    raise Exception, "Constituency file has two names the same %s" % attr["text"]
                self.conscanonical[attr["text"]] = self.loadconscanon
            pass
            
    def endElement(self, name):
        if name == "constituency":
            self.loadconsid = None
            self.loadconscanon = None

    def partylist(self):
        return self.parties.keys()

    def currentmpslist(self):
        today = datetime.date.today().isoformat()
        matches = self.members.values()
        ids = []
        for attr in matches:
            if today >= attr["fromdate"] and today <= attr["todate"]:
                ids.append(attr["id"])
        return ids

    def fullnametoids(self, input, date):
        text = input

        # Remove dots, but leave a space between them
        text = text.replace(".", " ")
        text = text.replace("  ", " ")

        # Remove initial titles (may be several)
        titletotal = 0
        titlegot = 1
        while titlegot > 0:
            (text, titlegot) = self.retitles.subn("", text)
            titletotal = titletotal + titlegot

        # Remove final honourifics (may be several)
        # e.g. for "Mr Menzies Campbell QC CBE" this removes " QC CBE" from the end
        honourtotal = 0
        honourgot = 1
        while honourgot > 0:
            (text, honourgot) = self.rehonourifics.subn("", text)
            honourtotal = honourtotal + honourgot

        # Find unique identifier for member
        ids = sets.Set()
        matches = self.fullnames.get(text, None)
        if not matches and titletotal > 0:
            matches = self.lastnames.get(text, None)

        # If a speaker, then match agains the secial speaker parties
        if not matches and (text == "Speaker" or text == "The Speaker"):
            matches = self.parties.get("SPK", None)
        if not matches and text == "Deputy Speaker":
            matches = copy.copy(self.parties.get("DCWM", None))
            matches.extend(self.parties.get("CWM", None))

        if matches:
            for attr in matches:
                if date >= attr["fromdate"] and date <= attr["todate"]:
                    ids.add(attr["id"])

        return ids

    # Returns id, corrected name, corrected constituency
    def matchfullnamecons(self, fullname, cons, date, alwaysmatchcons = True):
        fullname = fullname.strip()
        if cons:
            cons = cons.strip()
        ids = self.fullnametoids(fullname, date)

        cancons = self.conscanonical.get(cons, None)
        if alwaysmatchcons and cons and not cancons:
            raise Exception, "Unknown constituency %s" % cons

        if cancons and len(ids) > 1:
            newids = sets.Set()
            matches = self.constituencies[cancons]
            for attr in matches:
                if date >= attr["fromdate"] and date <= attr["todate"]:
                    if attr["id"] in ids:
                        newids.add(attr["id"])
            ids = newids

        if len(ids) == 0:
            raise Exception, 'No match: ' + fullname + " " + (cons or "[nocons]")
        if len(ids) > 1:
            raise MultipleMatchException, 'Matched multiple times: ' + fullname + " " + (cons or "[nocons]")

        for id in ids: # pop is no good as it changes the set
            pass
        remadename = self.members[id]["firstname"] + " " + self.members[id]["lastname"]
        remadecons = self.members[id]["constituency"]
        return id, remadename, remadecons

    # Exclusively for wrans
    def matchwransname(self, fullname, cons, date):
        # Have got first instance like this:
        # The Deputy Prime Minister and First Secretary of State   (Mr. Prescott)
        # Just turning alwaysmatchcons off for now
        # Do something fancier if it happens a lot
        return self.matchfullnamecons(fullname, cons, date, alwaysmatchcons = False)

    # Lowercases a surname, getting cases like these right:
    #     CLIFTON-BROWN to Clifton-Brown
    #     MCAVOY to McAvoy
    def lowercaselastname(self, name):
        words = re.split("( |-|')", name)
        words = [ string.capitalize(word) for word in words ]

        def handlescottish(word):
            if (re.match("Mc[a-z]", word)):
                return word[0:2] + string.upper(word[2]) + word[3:]
            if (re.match("Mac[a-z]", word)):
                return word[0:3] + string.upper(word[3]) + word[4:]
            return word
        words = map(handlescottish, words)

        return string.join(words , "")

    # Resets history - exclusively for debates pages
    # The name history stores all recent names:
    #   Mr. Stephen O'Brien (Eddisbury)
    # So it can match them when listed in shortened form:
    #   Mr. O'Brien
    def cleardebatehistory(self):
        # TODO: Perhaps this is a bit loose - how far back in the history should
        # we look?  Perhaps clear history every heading?  Currently it uses the
        # entire day.  Check to find the maximum distance back Hansard needs
        # to rely on.
        self.debatenamehistory = []
        self.debateofficehistory = {}

    # Matches names - exclusively for debates pages
    def matchdebatename(self, input, bracket, date):
        speakeroffice = ""

        # Clear name history if date change
        if self.debatedate != date:
            self.debatedate = date
            self.cleardebatehistory()

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
            # [1:] here we misses the first entry, i.e. it misses the previous
            # speaker.  This is necessary for example here:
            #     http://www.publications.parliament.uk/pa/cm200304/cmhansrd/cm040127/debtext/40127-08.htm#40127-08_spnew13
            # Mr. Clarke refers to Charles Clarke, even though it immediately
            # follows a Mr. Clarke in the form of Kenneth Clarke.  By ignoring
            # the previous speaker, we correctly match the one before.  As the
            # same person never speaks twice in a row, this shouldn't cause
            # trouble.
            for x in history[1:]:
                if x in ids:
                    # first match, use it and exit
                    ids = sets.Set([x,])
                    break

        # Special case - the AGforS is referred to as just the AG after first appearance
        office = input
        if office == "The Advocate-General":
            office = "The Advocate-General for Scotland"
        # Office name history ("The Deputy Prime Minster (John Prescott)" is later
        # referred to in the same day as just "The Deputy Prime Minister")
        officeids = self.debateofficehistory.get(office, None)
        if officeids:
            if len(ids) == 0:
                ids = officeids

        # Match between office and name - store for later use in the same days text
        if speakeroffice <> "":
            self.debateofficehistory.setdefault(input, sets.Set()).union_update(ids)

        # Put together original in case we need it
        rebracket = input
        if bracket:
            rebracket += " (" + bracket + ")"

        # Return errors
        if len(ids) == 0:
            if not re.search(regnospeakers, input):
                raise Exception, "No matches %s" % (rebracket)
            self.debatenamehistory.append(None) # see below
            return 'speakerid="unknown" error="No match" speakername="%s"' % (rebracket)
        if len(ids) > 1:
            names = ""
            for id in ids:
                names += self.members[id]["firstname"] + " " + self.members[id]["lastname"] + " (" + self.members[id]["constituency"] + ") "
            if not re.search(regnospeakers, input):
                raise Exception, "Multiple matches %s, possibles are %s" % (rebracket, names)
            self.debatenamehistory.append(None) # see below
            return 'speakerid="unknown" error="Matched multiple times" speakername="%s"' % (rebracket)
        # Extract one id left
        for id in ids:
            pass
        
        # In theory this would be a useful check - in practice it is no good, as in motion
        # text and the like it breaks.  It finds a few errors though.
        # (note that we even store failed matches as None above, so they count
        # as a speaker for the purposes of this check working)
        #if len(self.debatenamehistory) > 0 and self.debatenamehistory[-1] == id and not self.isspeaker(id):
        #    raise Exception, "Same person speaks twice in a row %s" % rebracket
        
        # Store id in history for this day
        self.debatenamehistory.append(id)

        # Return id and name as XML attributes
        remadename = self.members[id]["firstname"] + " " + self.members[id]["lastname"]
        if self.members[id]["party"] == "SPK" and re.search("Speaker", input):
            remadename = input
        if (self.members[id]["party"] == "CWM" or self.members[id]["party"] == "DCWM") and re.search("Deputy Speaker", input):
            remadename = input
        return 'speakerid="%s" speakername="%s"%s' % (id, remadename, speakeroffice)


    def mpnameexists(self, input, date):
        ids = self.fullnametoids(input, date)

        if len(ids) > 0:
            return 1

        if re.match('Mr\. |Mrs\. |Miss |Dr\. ', input):
            print ' potential missing MP name ' + input

        return 0

    def isspeaker(self, id):
        if self.members[id]["party"] == "SPK":
            return True
        if self.members[id]["party"] == "CWM" or self.members[id]["party"] == "DCWM":
            return True
        return False


# Construct the global singleton of class which people will actually use
memberList = MemberList()

