#! /usr/bin/env python2.3
# vim:sw=4:ts=4:et:nowrap

# Converts names of MPs into unique identifiers

import xml.sax
import sets
import datetime
import sys
import re
import os

sys.path.append("../pyscraper")
from resolvemembernames import memberList

today = datetime.date.today().isoformat()

#uk.org.publicwhip/member/651
#uk.org.publicwhip/member/674
#uk.org.publicwhip/member/1335

# People who have been in two different constituencies.  The like of Michael
# Portillo will eventually appear here.
manualmatches = {
    "Shaun Woodward [St Helens South]" : "Shaun Woodward [St Helens South / Witney]",
    "Shaun Woodward [Witney]" : "Shaun Woodward [St Helens South / Witney]",
    }

# Cases we want to specially match - add these in as we need them
class MultipleMatchException(Exception):
    pass

class PersonSets(xml.sax.handler.ContentHandler):

    def __init__(self):
        self.fullnamescons={} # "Firstname Lastname Constituency" --> MPs
        self.fullnames={} # "Firstname Lastname" --> MPs
		self.ministermap={}

        parser = xml.sax.make_parser()
        parser.setContentHandler(self)
        parser.parse("all-members.xml")
        parser.parse("ministers.xml")

    def outputxml(self, fout):
        for personset in self.fullnamescons.values():
            # OK, we generate a person id based on the mp id.

            # We pick one member id.  The lowest is picked as this is
            # idempotent - we only add new member ids on at the end, with
            # larger numbers.  Each time this script is run, even though a
            # person may have more members associated with them, the same id
            # will be selected.  i.e. the earliest by date added to our
            # database
            mpidtouse = None
            for attr in personset:
                mpidm = re.match("uk.org.publicwhip/member/(\d+)$", attr["id"])
                if mpidm:
                    mpnewid = int(mpidm.group(1))
                    if not mpidtouse or mpnewid < mpidtouse:
                        mpidtouse = mpnewid

            # Now we add 10000 to the one MP id we chose, to make the person ID
            personid = "uk.org.publicwhip/person/%d" % (mpidtouse + 10000)

            # Get their final name
            maxdate = "1000-01-01"
            attr = None
            for attr in personset:
                if attr["fromdate"] > maxdate and attr.has_key("firstname"):
                    maxdate = attr["fromdate"]
                    maxattr = attr
            latestname = "%s %s" % (maxattr["firstname"], maxattr["lastname"])

            # Output the XML
            fout.write('<person id="%s" latestname="%s">\n' % (personid, latestname.encode("latin-1")))
            for attr in personset:
                fout.write('    <office id="%s"/>\n' % (attr["id"]))
            fout.write('</person>\n')

    def crosschecks(self):
        # check date ranges don't overlap
        for personset in self.fullnamescons.values():
            dateset = map(lambda attr: (attr["fromdate"], attr["todate"]), personset)
            dateset.sort(lambda x, y: cmp(x[0], y[0]))
            prevtodate = None
            for fromdate, todate in dateset:
                assert fromdate < todate, "date ranges bad"
                if prevtodate:
                    assert prevtodate < fromdate, "date ranges overlap"
                prevtodate = todate

	# put ministerialships into each of the sets, based on matching matchid values
	# this works because the members code forms a basis to which ministerialships get attached
	def mergeministers(self):
        for p in self.fullnamescons:
			pset = self.fullnamescons[p]
			for a in pset.copy():
				memberid = a["id"]
				for moff in self.ministermap.get(memberid, []):
					pset.add(moff)




    def findotherpeoplewhoaresame(self):
        goterror = False

        # Look for people of the same name, but their constituency differs
        for (name, nameset) in self.fullnames.iteritems():
            # Find out ids of MPs that we have
            ids = sets.Set(map(lambda attr: attr["id"], nameset))

            # This name matcher includes fuzzier alias matches (e.g. Michael Foster ones)...
            fuzzierids =  memberList.fullnametoids(name, None)

            # ... so it should be a superset of the ones we have that just match canonical name
            assert fuzzierids.issuperset(ids)
            fuzzierids = list(fuzzierids)

            # hunt for pairs whose constituencies differ, and don't overlap in time
            # (as one person can't hold office twice at once)
            for id1 in range(len(fuzzierids)):
                attr1 = memberList.getmember(fuzzierids[id1])
                cancons1 = memberList.canonicalcons(attr1["constituency"])
                for id2 in range(id1 + 1, len(fuzzierids)):
                    attr2 = memberList.getmember(fuzzierids[id2])
                    cancons2 = memberList.canonicalcons(attr2["constituency"])
                    # check constituencies differ
                    if cancons1 != cancons2:

                        # Check that there is no MP with the same name/constituency
                        # as one of the two, and who overlaps in date with the other.
                        # That would mean they can't be the same person, as nobody
                        # can be MP twice at once (and I think the media would
                        # notice that!)
                        match = False
                        for id3 in range(len(fuzzierids)):
                            attr3 = memberList.getmember(fuzzierids[id3])
                            cancons3 = memberList.canonicalcons(attr3["constituency"])

                            if cancons2 == cancons3 and \
                                ((attr1["fromdate"] <= attr3["fromdate"] <= attr1["todate"])
                                or (attr3["fromdate"] <= attr1["fromdate"] <= attr3["todate"])):
                                #print "matcha %s %s %s (%s) %s to %s" % (attr3["id"], attr3["firstname"], attr3["lastname"], attr3["constituency"], attr3["fromdate"], attr3["todate"])
                                match = True
                            if cancons1 == cancons3 and \
                                ((attr2["fromdate"] <= attr3["fromdate"] <= attr2["todate"])
                                or (attr3["fromdate"] <= attr2["fromdate"] <= attr3["todate"])):
                                #print "matchb %s %s %s (%s) %s to %s" % (attr3["id"], attr3["firstname"], attr3["lastname"], attr3["constituency"], attr3["fromdate"], attr3["todate"])
                                match = True

                        if not match:
                            # we have a differing cons, but similar name name
                            # check not in manual match overload
                            fullnameconskey1 = "%s %s [%s]" % (attr1["firstname"], attr1["lastname"], cancons1)
                            fullnameconskey2 = "%s %s [%s]" % (attr2["firstname"], attr2["lastname"], cancons2)
                            if fullnameconskey1 in manualmatches and fullnameconskey2 in manualmatches \
                                and manualmatches[fullnameconskey1] == manualmatches[fullnameconskey2]:
                                pass
                            else:
                                goterror = True
                                print "these are possibly the same person: "
                                print " %s %s %s (%s) %s to %s" % (attr1["id"], attr1["firstname"], attr1["lastname"], attr1["constituency"], attr1["fromdate"], attr1["todate"])
                                print " %s %s %s (%s) %s to %s" % (attr2["id"], attr2["firstname"], attr2["lastname"], attr2["constituency"], attr2["fromdate"], attr2["todate"])

        return goterror

    def startElement(self, name, attr):
        if name == "member":
            # index by "Firstname Lastname Constituency"
            cancons = memberList.canonicalcons(attr["constituency"])

			# MAKE A COPY.  (The xml documentation warns that the attr object can be reused, so shouldn't be put into your structures if it's not a copy).
			attr = attr.copy()

            fullnameconskey = "%s %s [%s]" % (attr["firstname"], attr["lastname"], cancons)
            if fullnameconskey in manualmatches:
                fullnameconskey = manualmatches[fullnameconskey]
            self.fullnamescons.setdefault(fullnameconskey, sets.Set()).add(attr)

            fullnamekey = "%s %s" % (attr["firstname"], attr["lastname"])
            self.fullnames.setdefault(fullnamekey, sets.Set()).add(attr)

		if name == "moffice":
			assert attr["id"] not in self.ministermap
			if attr.has_key("matchid"):
				self.ministermap.setdefault(attr["matchid"], sets.Set()).add(attr.copy())

    def endElement(self, name):
        pass

    def currentmpslist(self):
        matches = self.members.values()
        ids = []
        for attr in matches:
            if today >= attr["fromdate"] and today <= attr["todate"]:
                ids.append(attr["id"])
        return ids


# the main code
personSets = PersonSets()
personSets.crosschecks()
if personSets.findotherpeoplewhoaresame():
    print
    print "If they are, correct it with the manualmatches array"
    print "Or add another array to show people who appear to be but are not"
    print
    sys.exit(1)
personSets.mergeministers()


tempfile = "temppeople.xml"
fout = open(tempfile, "w")
fout.write("""<?xml version="1.0" encoding="ISO-8859-1"?>

<!--

Contains a unique identifier for each person, and a list of ids
of offices which they have held.

Generated exclusively by personsets.py, don't hand edit it just now
(it would be such a pain to manually match up all these ids)

-->

<publicwhip>""")

personSets.outputxml(fout)
fout.write("</publicwhip>\n")
fout.close()

# overwrite people.xml
os.rename("temppeople.xml", "people.xml")
