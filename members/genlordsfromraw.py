import re
import os
import sys

import mx.DateTime

# go through the raw lords data and generate our files of lords members

#<lord
#    id="uk.org.publicwhip/lord/1158"
#    house="lords"
#    title="Lord" lordname="Ackner" lordofname="Weedon"
#    peeragetype="Law Lord" affiliation="Cross bench"
#    fromdate="2001-06-07"
#    source="Lords2004-02-09WithFromDate.html"
#/>


# more tedious stuff to do: "earl of" and "sitting as" cases

titleconv = {  'L.':'Lord',
			   'B.':'Baroness',
			   'Abp.':'Arch-bishop',
			   'Bp.':'Bishop',
			   'V.':'Viscount',
			   'E.':'Earl',
			   'D.':'Duke',
			   'M.':'Marquess',
			   'C.':'Countess',
			   'Ly.':'Lady',
			}


class lordrecord:
	def __init__(self):
		self.title = ''
		self.lordname = ''
		self.lordofname = ''
		self.frontnames = ''

		self.peeragetype = ''
		self.affiliation = ''
		self.date = ''
		self.source = ''

	def OutRecord(self, fout):
		fout.write('<lord\n')
		fout.write('\tid="uk.org.publicwhip/lord/%d"\n\thouse="lords"\n' % self.lid)
		fout.write('\ttitle="%s" lordname="%s" lordofname="%s"\n' % (self.title, self.lordname, self.lordofname))
		fout.write('\tfrontnames="%s"\n' % self.frontnames)
		fout.write('\tpeeragetype="%s" affiliation="%s"\n' % (self.peeragetype, self.affiliation))
		fout.write('\tfromdate="%s"\n' % self.date)
		fout.write('\tsource="%s"\n' % self.source)
		fout.write('/>\n')

#	<TR VALIGN=TOP>
#		<TD WIDTH=222 HEIGHT=16 BGCOLOR="#ffffbf">
#			<P><FONT COLOR="#000000"><FONT FACE="Arial"><FONT SIZE=2>Aberdare,
#			L.</FONT></FONT></FONT></P>
#		</TD>
#		<TD WIDTH=157 BGCOLOR="#ffffbf">
#			<P><FONT COLOR="#000000"> <FONT FACE="Arial"><FONT SIZE=2>Deputy
#			Hereditary</FONT></FONT></FONT></P>
#		</TD>
#		<TD WIDTH=119 BGCOLOR="#ffffbf">
#			<P><FONT COLOR="#000000"> <FONT FACE="Arial"><FONT SIZE=2>Other</FONT></FONT></FONT></P>
#		</TD>
#		<TD WIDTH=175 BGCOLOR="#ffffbf">
#			<P><FONT COLOR="#000000"> <FONT FACE="Arial"><FONT SIZE=2>4/10/1957</FONT></FONT></FONT></P>
#		</TD>
#	</TR>

class lordsrecords:
	def __init__(self):
		self.lordrec = [ ]

	# find a record with matching stuff
	def FindRec(self, lname, ltitle, lofname, bForce):

        # match by name
		renam = re.compile(lname, re.I)
		lr1 = [ ]
		for r in self.lordrec:
			if renam.match(r.lordname):
				lr1.append(r)

		# no match cases
		if not lr1:
			if bForce:
				print "failed to find " + lname
			return None

		# match by title
		retit = re.compile(ltitle, re.I)
		lr2 = [ ]
		for r in lr1:
			if retit.match(r.title):
				lr2.append(r)

		if not lr2:
			if bForce:
				print "failed to find " + ltitle + " " + lname + " in " + lr1[0].title
			return None

		return lr2[0]

	# run through and find extended names information
	def LoadExtendedNames(self, fpath, fname):
		fin = open(os.path.join(fpath, fname), "r")
		text = fin.read()
		fin.close()

		# extract the rows (very cheeky splitting of the <br> tag
		rows = re.findall('[rp]>\s*([^<]*)<b(?i)', text)
		for row in rows:
			if not row:
				continue
			row = re.sub('\s+', ' ', row)

			#ACTON, RICHARD GERALD, Lord (sits as Lord Acton of Bridgnorth)
			fnm = re.match('(.*?)(?: OF (.*?))?,\s*(.*?),\s*(.*?)\s*(?:\((.*?)\))?$', row)
			if fnm.group(5):
				continue # don't know what to do here

			ltitle = fnm.group(4)
			lname = re.sub('&#8217;', "'", fnm.group(1))
			lofname = fnm.group(2)
			lfrontnames = fnm.group(3)	# needs here to case down by case

			# find the record in the list
			r = self.FindRec(lname, ltitle, lofname, True)

			# we have the name, now give it the full thing
			if r: # should never fail
				r.frontnames = lfrontnames

	def AddRecord(self, nr):
		r = self.FindRec(nr.lordname, nr.title, nr.lordofname, False)
		if not r:
			# check consistency
			self.lordrec.append(nr)


def LoadTableWithFromDate(fpath, fname):
	fin = open(os.path.join(fpath, fname), "r")
	text = fin.read()
	fin.close()

	res = [ ]

	# extract the rows
	rows = re.findall('<tr[^>]*>\s*([\s\S]*?)\s*</tr>(?i)', text)
	for row in rows:

		# extract the columns of a row
		row = re.sub('(&nbsp;|\s)+', ' ', row)
		cols = re.findall('<td[^>]*>(?:<p[^>]*>|<font[^>]*>|<b>|\s)*([\s\S]*?)(?:</p>|</font>|</b>|\s)*</td>(?i)', row)

		# get rid of known non-lord lines
		if not cols[0] or re.search("members of the house|<br>|short\s*title(?i)", cols[0]) or not cols[1]:
			continue

		lordrec = lordrecord()

		# decode the easy parts
		lordrec.peeragetype = cols[1]
		lordrec.affiliation = cols[2]
		lordrec.date = cols[3] # mx.DateTime.DateFrom(cols[3]).date
		lordrec.source = fname

		# decode the fullname
		lordfname = cols[0]
		lfn = re.match('(.*?)(?: of (.*?))?, (.*?\.)$', lordfname)
		if not lfn:
			print lordfname
		lordrec.title = titleconv[lfn.group(3)]
		lordrec.lordname = lfn.group(1)
		if lfn.group(2):
			lordrec.lordofname = lfn.group(2)

		res.append(lordrec)

	return res




##################
# run through the inputs of information.
##################

rr1 = LoadTableWithFromDate('../rawdata/lords', 'Lords2004-02-09WithFromDate.html')
rr2 = LoadTableWithFromDate('../rawdata/lords', 'LordsSince1997.html')

# combine the inputs (could then sort and check duplicates)
rr = lordsrecords()
rr.lordrec.extend(rr1)
for nr in rr2:
	rr.AddRecord(nr)

rr.LoadExtendedNames('../rawdata/lords', 'Lords2003-11-26.html')


# write out the file
lordsxml = open('all-lords.xml', "w")
lordsxml.write("""<?xml version="1.0" encoding="ISO-8859-1"?>
<publicwhip>

""")
lid = 1
for r in rr.lordrec:
	r.lid = lid
	r.OutRecord(lordsxml)
	lid += 1
lordsxml.write("\n</publicwhip>\n")
lordsxml.close()


