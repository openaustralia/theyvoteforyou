#! /usr/bin/python2.3
# -*- coding: latin-1 -*-

import sys
import re
import os
import string
from resolvemembernames import memberList

from miscfuncs import ApplyFixSubstitutions
from contextexception import ContextException




################## the start of lords resolve names
import xml.sax

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

class LordsList(xml.sax.handler.ContentHandler):
	def __init__(self):
		self.lords={} # ID --> MPs
		self.lordnames={} # "lordnames" --> lords
		self.parties = {} # constituency --> MPs

		parser = xml.sax.make_parser()
		parser.setContentHandler(self)
		parser.parse("../members/all-lords.xml")

	def startElement(self, name, attr):
		""" This handler is invoked for each XML element (during loading)"""
		if name == "lord":
			if self.lords.get(attr["id"]):
				raise Exception, "Repeated identifier %s in members XML file" % attr["id"]
			self.lords[attr["id"]] = attr

			lname = attr["lordname"]
			if not lname:
				lname = attr["lordofname"]
			if lname:
				self.lordnames.setdefault(lname, []).append(attr)
				lnamed = string.replace(lname, ".", "")
				if lnamed != lname:
					self.lordnames.setdefault(lnamed, []).append(attr)


	def MatchLordName(self, ltitle, llordname, llordofname):
		lname = llordname
		if not lname:
			lname = llordofname

		lmatches = self.lordnames.get(lname, None)
		if lmatches: ## any number for now
			return lmatches[0]["id"]
 		print "Not found " + lname
		return "unrecognized"


	def MatchRevName(self, fss, stampurl):
		lfn = re.match('(.*?)(?: of (.*?))?, (.*?\.)$', fss)
		if not lfn:
			print fss
			raise ContextException("No match of format", stamp=stampurl, fragment=fss)
		ltitle = titleconv[lfn.group(3)]
		llordname = lfn.group(1)
		llordofname = None
		if lfn.group(2):
			llordofname = lfn.group(2)

		return self.MatchLordName(ltitle, llordname, llordofname)

# main function
lordlist = LordsList()
def GetLordSpeakerID(ltitle, llordname, llordofname, loffice, sdate):
	lid = lordlist.MatchLordName(ltitle, llordname, llordofname)
	if lid == "unrecognized":
		print (ltitle, llordname, llordofname)
	return lid




################## the end of lords resolve names















fixsubs = 	[
#	( '(<B> Baroness Barker:)( My .*?)</B>', '\\1</B>\\2', 1, '2004-01-07'),

	( '<center><b>(The Government .*? 4,000 this September. )</B></center>', '\\1', 1, '2004-03-15' ),
	( '(<B>The Parliamentary .*?Affairs\))</B>  (Lord Filkin)', '\\1 (\\2)</B>', 1, '2004-02-10'),
	( '(<B> Lord Davies of Oldham:)( My Lords,)  (</B>)', '\\1 \\3 \\2', 1, '2004-02-09'),
	( '(<B> Baroness Barker: )(My Lords, .*?Order Paper.) (</B>)', '\\1 \\3 \\2', 1, '2004-01-07'),
	( '<B>( In the Title )</B>', '\\1', 1, '2003-11-11'),

	# this is special to grand committee section
	#( 'Committees\):', 'Committees:', 1, '2004-02-03'),
]

# <B> Baroness Anelay of St Johns: </B>


# marks out center types bold headings which are never speakers
respeaker = re.compile('(<center><b>[^<]*</b></center>|<b>[^<]*</b>)(?i)')
respeakerb = re.compile('<b>\s*([^<]*?)\s*</b>(?i)')
respeakervals = re.compile('([^:(]*?)\s*(?:\(([^:)]*)\))?(:)?$')

renonspek = re.compile('division|contents|amendment(?i)')
reboldempty = re.compile('<b>\s*</b>(?i)')

regenericspeak = re.compile('(?:The (?:Deputy )?Chairman(?: of Committees)?|Noble Lords|A Noble Lord)$')
#retitlesep = re.compile('(Lord|Baroness|Viscount|Earl|The Earl of|The Lord Bishop of|The Duke of|The Countess of|Lady)\s*(.*)$')

hontitles = [ 'Lord Bishop', 'Lord', 'Baroness', 'Viscount', 'Earl', 'Countess', 'Archbishop', 'Duke', 'Lady' ]
hontitleso = string.join(hontitles, '|')

honcompl = re.compile('(?:The (%s)|(%s) (.*?)\s*)(?: of (.*))?$' % (hontitleso, hontitleso))

def LordsFilterSpeakers(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

	# setup for scanning through the file.
	for fss in respeaker.split(text):

		# strip off the bolds tags
		# get rid of non-bold stuff
		bffs = respeakerb.match(fss)
		if not bffs:
			fout.write(fss)
			continue
		fssb = bffs.group(1)

		# empty bold phrase
		if not re.search('\S', fssb):
			continue

		# division/contents/amendment which means this is not a speaker
		if renonspek.search(fssb):
			fout.write(fss)
			continue

		# part of quotes as an inserted title in an amendment
		if re.match('["[]', fssb):
			fout.write(fss)
			continue

		# another title type (all caps)
		if not re.search('[a-z]', fssb):
			fout.write(fss)
			continue

		# start piecing apart the name by office and leadout type
		namec = respeakervals.match(fssb)
		if not namec:
			print fssb
		assert namec
		if namec.group(2):
			name = namec.group(2)
			loffice = namec.group(1)
		else:
			name = namec.group(1)
			loffice = None
		colon = namec.group(3)
		if not colon:
			colon = ""

		# get rid of some standard ones
		if re.match('noble lords|a noble lord|a noble baroness(?i)', name):
			fout.write('<speaker speakerid="%s">%s</speaker>' % ('no-match', name))
			continue
		if re.match('the (?:deputy )?chairman of committees|the deputy speaker|the clerk of the parliaments(?i)', name):
			fout.write('<speaker speakerid="%s">%s</speaker>' % ('no-match', name))
			continue

		hom = honcompl.match(name)
		if not hom:
			fout.write('<speaker speakerid="%s">%s</speaker>' % ('no-match', name))
			print name
			continue

		# now we have a speaker, try and break it up
		ltit = hom.group(1)
		if not ltit:
			ltit = hom.group(2)
			lname = hom.group(3)
		else:
			lname = None   # or "The"
		lplace = hom.group(4)

		lsid = GetLordSpeakerID(ltit, lname, lplace, loffice, sdate)

		fout.write('<speaker speakerid="%s" colon="%s">%s</speaker>' % (lsid, colon, name))



















































































