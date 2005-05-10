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

# People who have been in two different constituencies.  The like of Michael
# Portillo will eventually appear here.
manualmatches = {
    "Shaun Woodward [St Helens South]" : "Shaun Woodward [St Helens South / Witney]",
    "Shaun Woodward [Witney]" : "Shaun Woodward [St Helens South / Witney]",

    "George Galloway [Bethnal Green & Bow]" : "George Galloway [Bethnal Green & Bow / Glasgow, Kelvin]",
    "George Galloway [Glasgow, Kelvin]" : "George Galloway [Bethnal Green & Bow / Glasgow, Kelvin]",

    # Scottish boundary changes 2005
    "Menzies Campbell [North East Fife]" : "Menzies Campbell [North East Fife / Fife North East]",
    "Menzies Campbell [Fife North East]" : "Menzies Campbell [North East Fife / Fife North East]",
    "Ann McKechin [Glasgow North]" : "Ann McKechin [Glasgow North / Glasgow, Maryhill]",
    "Ann McKechin [Glasgow, Maryhill]" : "Ann McKechin [Glasgow North / Glasgow, Maryhill]",
    "Frank Doran [Aberdeen Central]" : "Frank Doran [Aberdeen Central / Aberdeen North]",
    "Frank Doran [Aberdeen North]" : "Frank Doran [Aberdeen Central / Aberdeen North]",
    "Tom Harris [Glasgow, Cathcart]" : "Tom Harris [Glasgow, Cathcart / Glasgow South]",
    "Tom Harris [Glasgow South]" : "Tom Harris [Glasgow, Cathcart / Glasgow South]",
    "Mohammed Sarwar [Glasgow Central]" : "Mohammed Sarwar [Glasgow Central / Glasgow, Govan]",
    "Mohammad Sarwar [Glasgow, Govan]" : "Mohammed Sarwar [Glasgow Central / Glasgow, Govan]",
    "John McFall [Dumbarton]" : "John McFall [Dumbarton / Dunbartonshire West]",
    "John McFall [Dunbartonshire West]" : "John McFall [Dumbarton / Dunbartonshire West]",
    "Jimmy Hood [Clydesdale]" : "Jimmy Hood [Clydesdale / Lanark & Hamilton East]",
    "Jimmy Hood [Lanark & Hamilton East]" : "Jimmy Hood [Clydesdale / Lanark & Hamilton East]",
    "Ian Davidson [Glasgow, Pollok]" : "Ian Davidson [Glasgow, Pollok / Glasgow South West]",
    "Ian Davidson [Glasgow South West]" : "Ian Davidson [Glasgow, Pollok / Glasgow South West]",
    "Gordon Brown [Kirkcaldy & Cowdenbeath]" : "Gordon Brown [Kirkcaldy & Cowdenbeath / Dunfermline East]",
    "Gordon Brown [Dunfermline East]" : "Gordon Brown [Kirkcaldy & Cowdenbeath / Dunfermline East]",
    "Michael Martin [Glasgow, Springburn]" : "Michael Martin [Glasgow, Springburn / Glasgow North East]",
    "Michael Martin [Glasgow North East]" : "Michael Martin [Glasgow, Springburn / Glasgow North East]",
    "Sandra Osborne [Ayr, Carrick & Cumnock]" : "Sandra Osborne [Ayr, Carrick & Cumnock / Ayr]",
    "Sandra Osborne [Ayr]" : "Sandra Osborne [Ayr, Carrick & Cumnock / Ayr]",
    "Jim Sheridan [West Renfrewshire]" : "Jim Sheridan [West Renfrewshire / Paisley & Renfrewshire North]",
    "Jim Sheridan [Paisley & Renfrewshire North]" : "Jim Sheridan [West Renfrewshire / Paisley & Renfrewshire North]",
    "Robert Smith [Aberdeenshire West & Kincardine]" : "Robert Smith [Aberdeenshire West & Kincardine / West Aberdeenshire & Kincardine]",
    "Robert Smith [West Aberdeenshire & Kincardine]" : "Robert Smith [Aberdeenshire West & Kincardine / West Aberdeenshire & Kincardine]",
    "Brian Donohoe [Ayrshire Central]" : "Brian Donohoe [Ayrshire Central / Cunninghame South]",
    "Brian H Donohoe [Cunninghame South]" : "Brian Donohoe [Ayrshire Central / Cunninghame South]",
    "Charles Kennedy [Ross, Skye & Inverness West]" : "Charles Kennedy [Ross, Skye & Inverness West / Ross, Skye & Lochaber]",
    "Charles Kennedy [Ross, Skye & Lochaber]" : "Charles Kennedy [Ross, Skye & Inverness West / Ross, Skye & Lochaber]",
    "Eric Joyce [Falkirk West]" : "Eric Joyce [Falkirk West / Falkirk]",
    "Eric Joyce [Falkirk]" : "Eric Joyce [Falkirk West / Falkirk]",
    "David Marshall [Glasgow, Shettleston]" : "David Marshall [Glasgow, Shettleston / Glasgow East]",
    "David Marshall [Glasgow East]" : "David Marshall [Glasgow, Shettleston / Glasgow East]",
    "Tommy McAvoy [Rutherglen & Hamilton West]" : "Tommy McAvoy [Rutherglen & Hamilton West / Glasgow, Rutherglen]",
    "Thomas McAvoy [Glasgow, Rutherglen]" : "Tommy McAvoy [Rutherglen & Hamilton West / Glasgow, Rutherglen]",
    "Pete Wishart [North Tayside]" : "Pete Wishart [North Tayside / Perth and Perthshire North]",
    "Pete Wishart [Perth and Perthshire North]" : "Pete Wishart [North Tayside / Perth and Perthshire North]",
    "David Cairns [Greenock & Inverclyde]" : "David Cairns [Greenock & Inverclyde / Inverclyde]",
    "David Cairns [Inverclyde]" : "David Cairns [Greenock & Inverclyde / Inverclyde]",
    "Michael Connarty [Linlithgow & Falkirk East]" : "Michael Connarty [Linlithgow & Falkirk East / Falkirk East]",
    "Michael Connarty [Falkirk East]" : "Michael Connarty [Linlithgow & Falkirk East / Falkirk East]",
    "John Robertson [Glasgow North West]" : "John Robertson [Glasgow North West / Glasgow, Anniesland]",
    "John Robertson [Glasgow, Anniesland]" : "John Robertson [Glasgow North West / Glasgow, Anniesland]",
    "Douglas Alexander [Paisley & Renfrewshire South]" : "Douglas Alexander [Paisley & Renfrewshire South / Paisley South]",
    "Douglas Alexander [Paisley South]" : "Douglas Alexander [Paisley & Renfrewshire South / Paisley South]",
    "Russell Brown [Dumfries & Galloway]" : "Russell Brown [Dumfries & Galloway / Dumfries]",
    "Russell Brown [Dumfries]" : "Russell Brown [Dumfries & Galloway / Dumfries]",
    "Alistair Darling [Edinburgh Central]" : "Alistair Darling [Edinburgh Central / Edinburgh South West]",
    "Alistair Darling [Edinburgh South West]" : "Alistair Darling [Edinburgh Central / Edinburgh South West]",
    "Rosemary McKenna [Cumbernauld, Kilsyth & Kirkintilloch East]" : "Rosemary McKenna [Cumbernauld, Kilsyth & Kirkintilloch East / Cumbernauld & Kilsyth]",
    "Rosemary McKenna [Cumbernauld & Kilsyth]" : "Rosemary McKenna [Cumbernauld, Kilsyth & Kirkintilloch East / Cumbernauld & Kilsyth]",
    "John Reid [Hamilton North & Bellshill]" : "John Reid [Hamilton North & Bellshill / Airdrie & Shotts]",
    "John Reid [Airdrie & Shotts]" : "John Reid [Hamilton North & Bellshill / Airdrie & Shotts]",
    "Adam Ingram [East Kilbride, Strathaven & Lesmahagow]" : "Adam Ingram [East Kilbride, Strathaven & Lesmahagow / East Kilbride]",
    "Adam Ingram [East Kilbride]" : "Adam Ingram [East Kilbride, Strathaven & Lesmahagow / East Kilbride]",
    "Tom Clarke [Coatbridge, Chryston & Bellshill]" : "Tom Clarke [Coatbridge, Chryston & Bellshill / Coatbridge & Chryston]",
    "Tom Clarke [Coatbridge & Chryston]" : "Tom Clarke [Coatbridge, Chryston & Bellshill / Coatbridge & Chryston]",
    "Michael Moore [Tweeddale, Ettrick & Lauderdale]" : "Michael Moore [Tweeddale, Ettrick & Lauderdale / Berwickshire, Roxburgh & Selkirk]",
    "Michael Moore [Berwickshire, Roxburgh & Selkirk]" : "Michael Moore [Tweeddale, Ettrick & Lauderdale / Berwickshire, Roxburgh & Selkirk]",
    "Rachel Squire [Dunfermline & Fife West]" : "Rachel Squire [Dunfermline & Fife West / Dunfermline West]",
    "Rachel Squire [Dunfermline West]" : "Rachel Squire [Dunfermline & Fife West / Dunfermline West]",
    "Christopher Fraser [Mid Dorset & North Poole]" : "Christopher Fraser [Mid Dorset & North Poole / South West Norfolk]",
    "Christopher Fraser [South West Norfolk]" : "Christopher Fraser [Mid Dorset & North Poole / South West Norfolk]",
    "Gavin Strang [Edinburgh East]" : "Gavin Strang [Edinburgh East / Edinburgh East & Musselburgh]",
    "Gavin Strang [Edinburgh East & Musselburgh]" : "Gavin Strang [Edinburgh East / Edinburgh East & Musselburgh]",
    "John MacDougall [Glenrothes]" : "John MacDougall [Glenrothes / Central Fife]",
    "John MacDougall [Central Fife]" : "John MacDougall [Glenrothes / Central Fife]",
    "Thomas McAvoy [Glasgow, Rutherglen]" : "Thomas McAvoy [Glasgow, Rutherglen / Rutherglen & Hamilton West]",
    "Thomas McAvoy [Rutherglen & Hamilton West]" : "Thomas McAvoy [Glasgow, Rutherglen / Rutherglen & Hamilton West]",
    "Brian H Donohoe [Ayrshire Central]" : "Brian H Donohoe [Ayrshire Central / Cunninghame South]",
    "Brian H Donohoe [Cunninghame South]" : "Brian H Donohoe [Ayrshire Central / Cunninghame South]",
    "Mohammad Sarwar [Glasgow, Govan]" : "Mohammad Sarwar [Glasgow, Govan / Glasgow Central]",
    "Mohammad Sarwar [Glasgow Central]" : "Mohammad Sarwar [Glasgow, Govan / Glasgow Central]",
    "Pete Wishart [North Tayside]" : "Pete Wishart [North Tayside / Perth & Perthshire North]",
    "Pete Wishart [Perth & Perthshire North]" : "Pete Wishart [North Tayside / Perth & Perthshire North]",

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

            # Output the XML (sorted)
            fout.write('<person id="%s" latestname="%s">\n' % (personid, latestname.encode("latin-1")))
			ofidl = [ str(attr["id"])  for attr in personset ]
			ofidl.sort()
            for ofid in ofidl:
                fout.write('    <office id="%s"/>\n' % (ofid))
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
                cancons1 = memberList.canonicalcons(attr1["constituency"], attr1["fromdate"])
                for id2 in range(id1 + 1, len(fuzzierids)):
                    attr2 = memberList.getmember(fuzzierids[id2])
                    cancons2 = memberList.canonicalcons(attr2["constituency"], attr2["fromdate"])
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
                            cancons3 = memberList.canonicalcons(attr3["constituency"], attr3["fromdate"])

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
                                #  print in this form for handiness "Shaun Woodward [St Helens South]" : "Shaun Woodward [St Helens South / Witney]",
                                print '"%s %s [%s]" : "%s %s [%s / %s]",' % (attr1["firstname"], attr1["lastname"], attr1["constituency"], attr1["firstname"], attr1["lastname"], attr1["constituency"], attr2["constituency"])
                                print '"%s %s [%s]" : "%s %s [%s / %s]",' % (attr2["firstname"], attr2["lastname"], attr2["constituency"], attr1["firstname"], attr1["lastname"], attr1["constituency"], attr2["constituency"])

        return goterror

    def startElement(self, name, attr):
        if name == "member":
            # index by "Firstname Lastname Constituency"
            cancons = memberList.canonicalcons(attr["constituency"], attr["fromdate"])
            cancons2 = memberList.canonicalcons(attr["constituency"], attr["todate"])
            assert cancons == cancons2

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


