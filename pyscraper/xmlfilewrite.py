#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import re
import sys
import string
import os
import xml.sax

from contextexception import ContextException
import miscfuncs
toppath = miscfuncs.toppath

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


# disentangles a GID of the form:  uk.org.publicwhip/debate/2004-05-27.1695.0
# and separates out just the final part before the last dot.
regid = re.compile("([^/]*/[^/]*/[^.]*\.[^.]*)\.(.*)$")

# local copy of a qspeech that's given in flatb for better comparisons
class lqspeech:
	def __init__(self, name, attr):
		self.gid = attr["id"]   # uk.org.publicwhip/debate/2004-05-27.1695.0
		self.nametype = name
		self.speakerid = attr.get("speakerid", "")  # uk.org.publicwhip/member/1224
		self.speakername = attr.get("speakername", "") # good for names which match no member
		self.redirect = attr.get("redirect", None) # good for names which match no member
		self.paras = [ ]
		self.binheading = re.search("-heading", name)

	# used to compare two speeches
	# prevqb = (gid, nametype, speakerid, speakername, paras)
	def Compareqbs(self, qb, bignoregid):
		if (not bignoregid) and (self.gid != qb.GID):
			return False
		if self.nametype != qb.typ:
			return False

		# need to unpack speakerid
		respid = re.search('speakerid="(.*?)"', qb.speaker)
		if respid and self.speakerid != "unknown":
			if respid.group(1) != self.speakerid:
				print "Speakerid mismatch", qb.speaker, self.speakerid
				return False

		# we're going to accept this, but we're going to make a diff file for inspection 
		# rather than compare across the <p> lines
		return True

class PrevParsedFile(xml.sax.handler.ContentHandler):
	def __init__(self, xfil):
		self.prevflatb = [ ]

		self.gid = None
		self.binp = False
		self.binheading = False # heading text has no paragraph marker around it
		self.lqb = None

		self.slippedgidbatch = [ ]
		self.slippedgidbatchifgb = 0

		parser = xml.sax.make_parser()
		parser.setContentHandler(self)
		parser.parse(xfil)

	# this reads the values  and put them into characters.
	# may want to read in the records more precisely so as to compare them
	def startElement(self, name, attr):
		# a division will get nothing since there are no paras
		# however we might want to put in some code anyway just to compare if any names change.
		if re.search("division$|-heading|speech|ques|reply", name):
			self.lqb = lqspeech(name, attr)

		elif name == "p":
			assert not self.lqb.binheading
			self.paracont = [ ]
			self.binp = True

	def characters(self, content):
		if self.binp:
			self.paracont.append(content.encode("latin-1", "ignore"))
		if self.lqb and self.lqb.binheading:
			self.lqb.paras.append(string.replace(content.encode("latin-1", "ignore"), "\n", "")) # may have to strip out linefeeds

	def endElement(self, name):
		if re.search("division$|-heading|speech|ques|reply", name):
			self.prevflatb.append(self.lqb)
			self.lqb = None
		elif name == "p":
			self.binp = False
			self.lqb.paras.append(string.join(self.paracont, ""))

	def endDocument(self):
		pass #print "doc leng", len(self.prevflatb)


	def MessageForCompareGIDError(self, prevflatbi, flatbgidbatch, ifgb):
		# print out errors and hints how to fix
		print ""
		print "*** Column compare match fault ***"
		print "gid", prevflatbi.gid
		print "    ", prevflatbi.nametype, prevflatbi.speakerid, "|", prevflatbi.speakername
		print "    ", string.join(prevflatbi.paras, "|")[:60].encode("latin-1", "ignore") # this is unprepared text
		print "    last matched line", ifgb

		print "------------------------"
		for qb in flatbgidbatch:
			print qb.GID, qb.typ
			print "    ", qb.speaker
			print "    ", string.join(qb.stext, "")[:60].encode("latin-1", "ignore")
		print "------------------------"

		print "missing speeches can be fixed by inserting a placeholder:"
		print '    <parsemess-misspeech type="speech|heading" redirect="up|down|nowhere"/>'
		print "changes in column number can be reset by inserting a command:"
		print '    <parsemess-miscolnum set="888W"/>'
		print ""


		# get a position we will jump to of last match (if we can)
		if ifgb < len(flatbgidbatch):
			prevstampurl = flatbgidbatch[ifgb].sstampurl
		elif flatbgidbatch:
			prevstampurl = flatbgidbatch[-1].sstampurl
		else:
			prevstampurl = None
		raise ContextException("GID mismatch", stamp=prevstampurl)#, fragment=unspoketxt)

	# the verification that the files have the same GIDs
	# id="uk.org.publicwhip/debate/2004-05-27.1695.1"
	def CompareGIDScols(self, ccol, flatbgidbatch, ilf):
		# work through and find the set of matching numbers for this column

		# index in flatbgidbatch
		ifgb = 0

		# we try to make sure that what is in prevflatb can be found somewhere in flatbgidbatch
		# ie that the new html file contains all that is in the xml file
		while ilf < len(self.prevflatb):

			# quit if we are onto the next column
			lccol = regid.match(self.prevflatb[ilf].gid)
			if lccol.group(1) != ccol:
				break

			# no match
			if not ((ifgb < len(flatbgidbatch)) and self.prevflatb[ilf].Compareqbs(flatbgidbatch[ifgb], False)):
				# attempt to find a match so we can give a better hint
				nifgb = ifgb + 1
				while ((nifgb < len(flatbgidbatch)) and not self.prevflatb[ilf].Compareqbs(flatbgidbatch[nifgb], True)):
					nifgb += 1
				if nifgb < len(flatbgidbatch):
					print "There is a possible match further down"
					print "This will be fixable with a <parsemess-skipnextgidincrement/>"

				self.MessageForCompareGIDError(self.prevflatb[ilf], flatbgidbatch, ifgb)

			# move on to the next pair
			ifgb += 1
			ilf += 1
			self.slippedgidbatch = [ ]	# one match means that we're not slipping

		# we're allowed to have extra things in the new one that the old stuff doesn't know about,
		# but when the slippage starts to happen, this is the likely place it's gone wrong.
		# and we find out because we don't get to the end of ilf
		if (ifgb < len(flatbgidbatch)) and not self.slippedgidbatch:
			self.slippedgidbatch = flatbgidbatch[:]
			self.slippedgidbatchifgb = ifgb

		return ilf


	# go through all the columns in the current file
	def CompareGIDS(self, flatb):

		print "Comparing GIDs of XML file before over-write"
		# divide GIDs into groups of columns
		ilf = 0
		ccol = None
		for qb in flatb:
			nccol = regid.match(qb.GID)
			if ccol and (ccol != nccol.group(1)):
				ilf = self.CompareGIDScols(ccol, cgidbatchv, ilf)
				ccol = None
			if not ccol:
				ccol = nccol.group(1)
				cgidbatchv = [ ]
			cgidbatchv.append(qb)


		# final entry
		if ccol:
			ilf = self.CompareGIDScols(ccol, cgidbatchv, ilf)

		# fires if there are more columns left in the xml file unaccounted for
		if ilf < len(self.prevflatb):
			# throws an exception
			self.MessageForCompareGIDError(self.prevflatb[ilf], self.slippedgidbatch, self.slippedgidbatchifgb)
			return False

		return True


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


# quite involved to make this
def getXMLpatchname(jfout):
	renn = re.compile("%s.patch(\d+)" % os.path.basename(jfout))
	ipp = 1
	for pp in os.listdir(os.path.dirname(jfout)):
		regpp = renn.match(pp)
		if regpp:
			ipp = string.atoi(regpp.group(1)) + 1
	res = "%s.patch%d" % (jfout, ipp)
	assert renn.match(os.path.basename(res))
	assert not os.path.isfile(res)
	return res

# write out a whole file which is a list of qspeeches, and construct the ids.
def WriteXMLFile(gidpart, tempname, jfout, flatb, sdate):

    #print "jfout is ", jfout
	# make the GIDS and compare the files
	CreateGIDs(gidpart, flatb, sdate)

	fout = open(tempname, "w")
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

	# end of file.  should close and copy
	# should also be opened in this function too
	fout.write("</publicwhip>\n\n")

	# end of current file
	fout.close()

	# load up a previous file and compare
	ppf = os.path.isfile(jfout) and PrevParsedFile(jfout)
	if ppf:

		# compare successful
		if ppf.CompareGIDS(flatb):

			# make a file to record the differences (for keeping track of later)
			jfoutpatch = getXMLpatchname(jfout)

        	# the regexp on this diff line is limited, but this factors any line that has a changeable url in it, and will
			# let us see changes in votes and changes in speeches in enough of a context
			ern = os.system('diff -u --ignore-matching-lines="<.*?url=[^>]*>" %s %s > %s' % (tempname, jfout, jfoutpatch))
			if ern == 2:
				print "Error running diff"
				sys.exit(1)
			# remove file if empty
			if not os.path.getsize(jfoutpatch):
				os.remove(jfoutpatch)
			else:
				print "Writing patchfile of changes to XML as", jfoutpatch
			# file is working, and patch file has been made, now safe to delete the old XML file
			os.remove(jfout)

		# GID comparison failed in some way.  (Shouldn't it throw an exception?)
		else:
			print "No over-write of parsed file for now"



