#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import re
import sys
import string
import os
import xml.sax

from contextexception import ContextException

def WriteXMLHeader(fout):
	fout.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')

	# These entity definitions for latin-1 chars are from here:
	# http://www.w3.org/TR/REC-html40/sgml/entities.html
        # NOTE: also update ../website/protodecode.inc when you update this
        # TODO: make these share the chunk of entity code somehow
	fout.write('''

<!DOCTYPE publicwhip
[
<!ENTITY ndash   "&#8211;">
<!ENTITY mdash   "&#8212;">
<!ENTITY iexcl   "&#161;">
<!ENTITY divide  "&#247;">

<!ENTITY egrave "&#232;" >
<!ENTITY eacute "&#233;" >
<!ENTITY ecirc  "&#234;" >
<!ENTITY euml   "&#235;" >
<!ENTITY agrave "&#224;" >
<!ENTITY aacute "&#225;" >
<!ENTITY acirc  "&#226;" >
<!ENTITY ocirc  "&#244;" >
<!ENTITY ouml   "&#246;" >
<!ENTITY Ouml   "&#214;" >
<!ENTITY oacute "&#243;" >
<!ENTITY iacute "&#237;" >
<!ENTITY icirc  "&#238;" >
<!ENTITY ccedil "&#231;" >
<!ENTITY Ccedil "&#199;" >
<!ENTITY uuml   "&#252;" >
<!ENTITY ntilde "&#241;" >

<!ENTITY plusmn "&#177;" >
<!ENTITY pound  "&#163;" >
<!ENTITY middot "&#183;" >
<!ENTITY deg    "&#176;" >

<!ENTITY frac14 "&#188;" >
<!ENTITY frac12 "&#189;" >
<!ENTITY frac34 "&#190;" >

<!ENTITY euro "&#8364;" >
]>

''');

regid = re.compile("([^/]*/[^/]*/[^.]*\.[^.]*)\.(.*)$")
class PrevParsedFile(xml.sax.handler.ContentHandler):
	def __init__(self, xfil):
		self.lflatb = [ ]
		self.gid = None
		self.binp = False

		parser = xml.sax.make_parser()
		parser.setContentHandler(self)
		parser.parse(xfil)

	def startElement(self, name, attr):
		# a division will get nothing since there are no paras
		# however we might want to put in some code anyway just to compare if any names change.
		if re.search("division$|-heading|speech|ques|reply", name):
			self.gid = attr["id"] # uk.org.publicwhip/debate/2004-05-27.1695.0
			self.paras = [ ("<%s>" % name) ]
		elif name == "p":
			self.paras.append("<p>")
			self.binp = True

	def characters(self, content):
		if self.binp:
			self.paras.append(content)

	def endElement(self, name):
		if re.search("division$|-heading|speech|ques|reply", name):
			self.lflatb.append((self.gid, string.join(self.paras, "")))

			self.gid = None
			self.paras = None

		elif name == "p":
			self.binp = False

	def endDocument(self):
		pass #print "doc leng", len(self.lflatb)




	# the verification that the files have the same GIDs
	# id="uk.org.publicwhip/debate/2004-05-27.1695.1"
	def CompareGIDScols(self, ccol, cgidbatchm, cgidbatchmv, ilf):
		# work through and find the set of matching numbers for this column
		lgidbatch = [ ]
		lgidbatchv = [ ]
		while ilf < len(self.lflatb):
			lccol = regid.match(self.lflatb[ilf][0])
			if lccol.group(1) != ccol:
				break
			lgidbatch.append(lccol.group(2))
			lgidbatchv.append(self.lflatb[ilf][1])
			ilf += 1

		if lgidbatch != cgidbatchm:
			print "Mismatch in cols", ccol, cgidbatchm, lgidbatch, ilf
			assert False
		return ilf

	def CompareGIDS(self, flatb):
		print "Comparing GIDs of XML file before over-write"
		# divide GIDs into groups of columns
		ilf = 0
		ccol = None
		for fi in flatb:
			nccol = regid.match(fi.GID)
			if ccol and (ccol != nccol.group(1)):
				ilf = self.CompareGIDScols(ccol, cgidbatch, cgidbatchv, ilf)
				ccol = None
			if not ccol:
				ccol = nccol.group(1)
				cgidbatch = [ ]
				cgidbatchv = [ ]
			cgidbatch.append(nccol.group(2))
			cgidbatchv.append(fi)

		# final entry
		if ccol:
			ilf = self.CompareGIDScols(ccol, cgidbatch, cgidbatchv, ilf)

		# fires if there are more columns left in the xml file unaccounted for
		assert ilf == len(self.lflatb)




# write out a whole file which is a list of qspeeches, and construct the ids.
def CreateGIDs(gidpart, flatb, sdate):
	pcolnum = "####"
	picolnum = -1
	ncid = -1
	for qb in flatb:

		# construct the gid
		colnum = re.search('colnum="([^"]*)"', qb.sstampurl.stamp).group(1)
		if colnum != pcolnum:
			# check that the column numbers are increasing
			# this is essential if the gids are to be unique.
			icolnum = string.atoi(re.match('(\d+)[W]*$', colnum).group(1))
			if icolnum <= picolnum:
				print qb.sstampurl.stamp
				raise Exception, "non-increasing column numbers %s %d" % (colnum, picolnum)
			picolnum = icolnum

			pcolnum = colnum
			ncid = 0
		else:
			ncid += 1

		# this is our GID !!!!
		qb.GID = 'uk.org.publicwhip/%s/%s.%s.%d' % (gidpart, sdate, colnum, ncid)



# write out a whole file which is a list of qspeeches, and construct the ids.
def WriteXMLFile(gidpart, fout, jfout, flatb, sdate):

	# make the GIDS and compare the files
	ppf = os.path.isfile(jfout) and PrevParsedFile(jfout)
	CreateGIDs(gidpart, flatb, sdate)
	if ppf:
		ppf.CompareGIDS(flatb)

	WriteXMLHeader(fout);
	fout.write("<publicwhip>\n")

	pcolnum = "####"
	picolnum = -1
	ncid = -1
	for qb in flatb:

		# Is this value needed?
		colnum = re.search('colnum="([^"]*)"', qb.sstampurl.stamp).group(1)

		# extract the time stamp (if there is one)
		stime = ""
		if qb.sstampurl.timestamp:
			stime = re.match('<stamp( time=".*?")/>', qb.sstampurl.timestamp).group(1)

		# build the full tag for this object
		# some of the info is a repeat of the text in the GID
		fulltag = '<%s id="%s" %s colnum="%s" %s url="%s">\n' % (qb.typ, qb.GID, qb.speaker, colnum, stime, qb.sstampurl.GetUrl())
		fout.write('\n')
		fout.write(fulltag)

		# put out the paragraphs in body text
		for lb in qb.stext:
			fout.write('\t')
			fout.write(lb)
			fout.write('\n')

		# end tag
		fout.write('</%s>\n' % qb.typ)

	fout.write("</publicwhip>\n\n")

	# don't over-write parsed files
	#if os.path.isfile(jfout):
	#	raise ContextException("No over-writing parsed file") #, stamp=stampurl, fragment=unspoketxt)
		#os.remove(jfout)



