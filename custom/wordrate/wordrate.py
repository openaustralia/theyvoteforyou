import sys
import os.path
import re
import string


countries = """
Saudi Arabia
Iraq
Ecuador
Kuwait
Vietnam
England
Scotland
Ireland
Wales
United States|U.S.
Canada
Cambodia
Tuvalu
Chaigos
India
China
Japan
Mongolia
Greenland
Panama
Israel
Jordan
Iran
Antarctica
Chile
Falkland
Belgium
Norway
Austria
South Africa
Western Sahara
Morocco
Libya
Cyprus
"""

class cstats:
	def __init__(self, lname):
		self.name = lname
		self.reg = re.compile(lname)
		self.paracount = 0

	def CountForPara(self, lin):
		if self.reg.search(lin):
			self.paracount += 1


def MakeMatchList():
	res = []
	for c in re.split("\n", countries):
		lc = string.strip(c)
		if lc:
			res.append(cstats(lc))
	return res

def AddUpForDate(cstatlist, fname):
	numparas = 0
	fin = open(fname)
	for lin in fin.readlines():
		if re.match("\s*<p>", lin):
			numparas += 1
			for c in cstatlist:
				c.CountForPara(lin)
	fin.close()
	return numparas

def WriteResult(cstatlist, totalnumparas, totaldays):
	print "total number of paragraphs", totalnumparas, "in", totaldays, "days"
	for c in cstatlist:
		print '"%s"\t%d' % (c.name, c.paracount)


# main loop call
cstatlist = MakeMatchList()
debatesxmldir = "C:/publicwhip/pwdata/scrapedxml/debates"
debfiles = os.listdir(debatesxmldir)
totalnumparas = 0
totaldays = 0
for fil in debfiles:
	if re.search("\.xml$", fil):
		totaldays += 1
		print fil
		totalnumparas += AddUpForDate(cstatlist, os.path.join(debatesxmldir, fil))
WriteResult(cstatlist, totalnumparas, totaldays)

