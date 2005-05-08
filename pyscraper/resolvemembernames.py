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
        "Deputy?Speaker|Second Deputy Chairman(?i)|Speaker-Elect|" + \
        "The Chairman|First Deputy Chairman|Temporary Chairman"

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
        self.constoidmap = {} # constituency name --> cons attributes (with date and ID)
        self.considtomembermap = {} # cons ID --> MPs
        self.considtonamemap = {} # cons ID --> name
        self.parties = {} # party --> MPs
        self.officetopersonmap = {} # member ID --> person ID
        self.persontoofficemap = {} # person ID --> office

        # "rah" here is a typo in division 64 on 13 Jan 2003 "Ancram, rah Michael"
        self.titles = "Dr |Hon |hon |rah |rh |Mrs |Ms |Mr |Miss |Rt Hon |Reverend |The Rev |The Reverend |Sir |Dame |Rev |Prof "
        self.retitles = re.compile('^(?:%s)' % self.titles)
        self.rejobs = re.compile('^%s$' % parlPhrases.regexpjobs)

        self.honourifics = " MP| CBE| OBE| MBE| QC| BEM| rh| RH| Esq| QPM| JP| FSA| Bt| B.Ed \(Hons\)";
        self.rehonourifics = re.compile('(?:%s)$' % self.honourifics)

        parser = xml.sax.make_parser()
        parser.setContentHandler(self)
        self.loadconsattr = None
        parser.parse("../members/constituencies.xml")
        parser.parse("../members/all-members.xml")
        self.loadperson = None
        parser.parse("../members/people.xml")
        parser.parse("../members/ministers.xml")
        # member-aliases has to be loaded after ministers, as we alias
        # to ministerial positions sometimes (e.g. Solicitor-General) in
        # member-aliases.xml
        parser.parse("../members/member-aliases.xml")

    def startElement(self, name, attr):
        # all-members.xml loading
        if name == "member":

			# MAKE A COPY.  (The xml documentation warns that the attr object can be reused, so shouldn't be put into your structures if it's not a copy).
			attr = attr.copy()

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
            consids = self.constoidmap[cons]
            consid = None
            # find the constituency id for this MP
            for consattr in consids:
                if (consattr['fromdate'] <= attr['fromdate'] and
                    attr['fromdate'] <= attr['todate'] and
                    attr['todate'] <= consattr['todate']):
                    if consid:
                        raise Exception, "Two constituency ids %s %s overlap with MP %s" % (consid, consattr['id'], attr['id'])
                    consid = consattr['id']
            # check first date ranges don't overlap
            for curattr in self.considtomembermap.get(consid, []):
                if curattr['fromdate'] <= attr['fromdate'] <= curattr['todate'] \
                    or curattr['fromdate'] <= attr['todate'] <= curattr['todate'] \
                    or attr['fromdate'] <= curattr['fromdate'] <= attr['todate'] \
                    or attr['fromdate'] <= curattr['todate'] <= attr['todate']:
                    raise Exception, "Two MP entries for constituency %s with overlapping dates" % consid
            # then add in
            self.considtomembermap.setdefault(consid, []).append(attr)

            # ... and by party
            party = attr["party"]
            self.parties.setdefault(party, []).append(attr)

        # member-aliases.xml loading
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
                consids = self.constoidmap.get(attr["constituency"], None)
                if not consids:
                    raise Exception, 'Constituency name not found ' + attr["constituency"]
                matches = []
                for consattr in consids:
                    consid = consattr['id']
                    members = self.considtomembermap.get(consid, None)
                    if members:
                        matches.extend(members)
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

        # constituencies.xml loading
        elif name == "constituency":
            self.loadconsattr = attr
            pass
        elif name == "name":
            if self.loadconsattr: # name tag within constituency tag
                if not self.loadconsattr["id"] in self.considtonamemap:
                    self.considtonamemap[self.loadconsattr["id"]] = attr["text"] # preferred constituency name is first listed
                self.constoidmap.setdefault(attr["text"], []).append(self.loadconsattr)
            pass

        # people.xml loading
        elif name == "person":
            self.loadperson = attr["id"]
        elif name == "office":
            assert self.loadperson, "<office> tag before <person> tag"
            if attr["id"] in self.officetopersonmap:
                raise Exception, "Same office id %s appeared twice" % attr["id"]
            self.officetopersonmap[attr["id"]] = self.loadperson
            self.persontoofficemap.setdefault(self.loadperson, []).append(attr["id"])

        # ministers.xml loading
        elif name == "moffice":
            # we load these two positions and alias them into fullnames,
            # as they are often used in wrans instead of fullnames, with
            # no way of telling.
            if attr["position"] == "Solicitor General" or attr["position"] == "Advocate General for Scotland":
                if self.officetopersonmap.has_key(attr["id"]):
                    # find all the office ids for this person
                    person = self.officetopersonmap[attr["id"]]
                    ids = self.persontoofficemap[person]
                    for id in ids:
                        # we only want MP ids
                        if id.find("/member/") == -1:
                            continue
                        m = self.members[id]
                        # add ones which overlap the moffice dates to the alias
                        newattr = {}
                        newattr['id'] = m['id']
                        early = max(m['fromdate'], attr.get('fromdate', '1000-01-01'))
                        late = min(m['todate'], attr.get('todate', '9999-12-31'))
                        # sometimes the ranges don't overlap
                        if early <= late:
                            newattr['fromdate'] = early
                            newattr['todate'] = late
                            self.fullnames.setdefault(attr["position"], []).append(newattr)
                            # print attr["position"], early, late, attr['name']

    def endElement(self, name):
        if name == "constituency":
            self.loadconsattr = None

    def partylist(self):
        return self.parties.keys()

    def currentmpslist(self):
        today = datetime.date.today().isoformat()
        return self.mpslistondate(today)

    def mpslistondate(self, date):
        matches = self.members.values()
        ids = []
        for attr in matches:
            if date >= attr["fromdate"] and date <= attr["todate"]:
                ids.append(attr["id"])
        return ids

	# useful to have this function out there
	def striptitles(self, text):
        # Remove dots, but leave a space between them
        text = text.replace(".", " ")
        text = text.replace("&nbsp;", " ")
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

		return text.strip(), titletotal

    # date can be none, will give more matches
    def fullnametoids(self, tinput, date):
        text, titletotal = self.striptitles(tinput)

        # Find unique identifier for member
        ids = sets.Set()
        matches = self.fullnames.get(text, None)
        if not matches and titletotal > 0:
            matches = self.lastnames.get(text, None)

        # If a speaker, then match against the secial speaker parties
        if not matches and (text == "Speaker" or text == "The Speaker"):
            matches = self.parties.get("SPK", None)
        if not matches and (text == "Deputy Speaker" or text == "Deputy-Speaker" or text == "Madam Deputy Speaker"):
            matches = copy.copy(self.parties.get("DCWM", None))
            matches.extend(self.parties.get("CWM", None))

        if matches:
            for attr in matches:
                if (date == None) or (date >= attr["fromdate"] and date <= attr["todate"]):
                    ids.add(attr["id"])
        return ids

    # Returns id, corrected name, corrected constituency
    # alwaysmatchcons says it is an error to have an unknown/mismatching constituency
    # (rather than just treating cons as None if the cons is unknown)
    # date or cons can be None
    def matchfullnamecons(self, fullname, cons, date, alwaysmatchcons = True):
        fullname = self.basicsubs(fullname)
        fullname = fullname.strip()
        if cons:
            cons = cons.strip()
        ids = self.fullnametoids(fullname, date)

        consids = self.constoidmap.get(cons, None)
        if alwaysmatchcons and cons and not consids:
            raise Exception, "Unknown constituency %s" % cons

        if consids and (len(ids) > 1 or alwaysmatchcons):
            newids = sets.Set()

            for consattr in consids:
                if consattr["fromdate"] <= date and date <= consattr["todate"]:
                    consid = consattr['id']
                    matches = self.considtomembermap[consid]
                    for attr in matches:
                        if (date == None) or (date >= attr["fromdate"] and date <= attr["todate"]):
                            if attr["id"] in ids:
                                newids.add(attr["id"])
            ids = newids

        if len(ids) == 0:
	        return None, None, None
        if len(ids) > 1:
            raise MultipleMatchException, 'Matched multiple times: ' + fullname + " : " + (cons or "[nocons]") + " : " + date

        for lid in ids: # pop is no good as it changes the set
            pass
        remadename = self.members[lid]["firstname"] + " " + self.members[lid]["lastname"]
        remadecons = self.members[lid]["constituency"]
        return lid, remadename, remadecons

    # Exclusively for WMS
    def matchwmsname(self, office, fullname, date):
        office = self.basicsubs(office)
        speakeroffice = ' speakeroffice="%s"' % office
        fullname = self.basicsubs(fullname)
        ids = self.fullnametoids(fullname, date)

#        rebracket = office
#        rebracket += " (" + fullname + ")"
        if len(ids) == 0:
#            if not re.search(regnospeakers, office):
#               raise Exception, "No matches %s" % (rebracket)
            return 'speakerid="unknown" error="No match" speakername="%s"%s' % (fullname, speakeroffice)
        if len(ids) > 1:
            names = ""
            for id in ids:
                names += self.members[id]["firstname"] + " " + self.members[id]["lastname"] + " (" + self.members[id]["constituency"] + ") "
#            if not re.search(regnospeakers, office):
#                raise Exception, "Multiple matches %s, possibles are %s" % (rebracket, names)
            return 'speakerid="unknown" error="Matched multiple times" speakername="%s"%s' % (fullname, speakeroffice)

        for id in ids:
            pass

        remadename = self.members[id]["firstname"] + " " + self.members[id]["lastname"]
        return 'speakerid="%s" speakername="%s"%s' % (id, remadename, speakeroffice)
    
    # Exclusively for wrans
    def matchwransname(self, fullname, cons, date):
        # Have got first instance like this:
        # The Deputy Prime Minister and First Secretary of State   (Mr. Prescott)
        # Just turning alwaysmatchcons off for now
        # Do something fancier if it happens a lot
        res = self.matchfullnamecons(fullname, cons, date, alwaysmatchcons = False)
		if not res or not res[0] or not res[1] or not res[2]:
			raise Exception, 'No match: ' + fullname + " : " + (cons or "[nocons]")
		return res

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

    def fixnamecase(self, name):
        return self.lowercaselastname(name)

    # Replace common annoying characters
    def basicsubs(self, txt):
        txt = txt.replace("&#150;", "-")
        txt = txt.replace("&#039;", "'")
        txt = txt.replace("&nbsp;", " ")
        return txt

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
        input = self.basicsubs(input)

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
	        bracket = self.basicsubs(bracket)
            brackids = self.fullnametoids(bracket, date)
            if brackids:
                speakeroffice = ' speakeroffice="%s" ' % input

                # If so, intersect those matches with ones from the first part
                # (some offices get matched in first part - like Mr. Speaker)
                if len(ids) == 0 or (len(brackids) == 1 and re.search("speaker(?i)", input)):
                    ids = brackids
                else:
                    ids = ids.intersection(brackids)

            # Sometimes constituency in brackets: Malcolm Bruce (Gordon)
            consids = self.constoidmap.get(bracket, None)
            if consids:
                # Search for constituency matches, and intersect results with them
                newids = sets.Set()
                for consattr in consids:
                    if consattr["fromdate"] <= date and date <= consattr["todate"]:
                        consid = consattr['id']
                        matches = self.considtomembermap.get(consid, None)
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

			# old wasteful way of coding it
			#history = copy.copy(self.debatenamehistory)
            #history.reverse()

            # [1:] here we misses the first entry, i.e. it misses the previous
            # speaker.  This is necessary for example here:
            #     http://www.publications.parliament.uk/pa/cm200304/cmhansrd/cm040127/debtext/40127-08.htm#40127-08_spnew13
            # Mr. Clarke refers to Charles Clarke, even though it immediately
            # follows a Mr. Clarke in the form of Kenneth Clarke.  By ignoring
            # the previous speaker, we correctly match the one before.  As the
            # same person never speaks twice in a row, this shouldn't cause
            # trouble.


			# this looking back two can sometimes fail if a speaker is interrupted
			# by something procedural, and then picks up his thread straight after himself
			# (eg in westminsterhall if there is a suspension to go vote in a division in the main chamber on something about which they haven't heard the debate)
            ix = len(self.debatenamehistory) - 2
			while ix >= 0:
			    x = self.debatenamehistory[ix]
                if x in ids:
                    # first match, use it and exit
                    ids = sets.Set([x,])
                    break
                ix -= 1



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

        # Extract the one id remaining
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

    def canonicalcons(self, cons, date):
        consids = self.constoidmap.get(cons, None)
        if not consids:
            raise Exception, "Unknown constituency %s" % cons
        consid = None
        for consattr in consids:
            if consattr["fromdate"] <= date and date <= consattr["todate"]:
                if consid:
                    raise Exception, "Two like-named constituency ids %s %s overlap with date %s" % (consid, consattr['id'], date)
                consid = consattr['id']
        if not consid in self.considtonamemap:
            raise Exception, "Not known name of consid %s cons %s date %s" % (consid, cons, date)
        return self.considtonamemap[consid]

    def getmember(self, memberid):
        return self.members[memberid]

    # Returns the set of members which are the same person in the same
    # parliament / byelection continuously in time.  i.e. We ignore
    # changing party.
    # There must be a simpler way of doing this function, too complex
    def getmembersoneelection(self, memberid):
        personid = self.officetopersonmap[memberid]
        members = self.persontoofficemap[personid]
   
        ids = [memberid, ]
        def scanoneway(whystr, datestr, delta, whystrrev, datestrrev):
            id = memberid
            while 1:
                attr = self.getmember(id)
                if attr[whystr] != "changed_party":
                    break
                dayend = datetime.date(*map(int, attr[datestr].split("-")))
                dayafter = datetime.date.fromordinal(dayend.toordinal() + delta).isoformat()
                for m in members:
                    mattr = self.getmember(m)
                    if mattr[whystrrev] == "changed_party" and mattr[datestrrev] == dayafter:
                        id = mattr["id"]
                        break
                else:
                    raise Exception, "Couldn't find %s %s member party changed from %s date %s" % (whystr, attr[whystr], id, dayafter)

                ids.append(id)

        scanoneway("towhy", "todate", +1, "fromwhy", "fromdate")
        scanoneway("fromwhy", "fromdate", -1, "towhy", "todate")

        return ids
            

    def membertoperson(self, memberid):
        return self.officetopersonmap[memberid]


# Construct the global singleton of class which people will actually use
memberList = MemberList()

