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
	def Compareqbs(self, qb):
		if self.gid != qb.GID:
			return False

		if self.nametype != qb.typ:
			# forgive heading mixups if it's a lost heading
			if re.search("heading", self.nametype) and re.search("heading", qb.typ) and re.search("-- Lost Heading --", qb.stext[0]):
				pass
			else:
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


	# the exception throwing function which should give good hits as to
	# what we can do to fix this.
	def MessageForCompareGIDError(self, ilf, flatb, ifgb, bquietc):

		# this flag set if running in a cron job
		exdesc = "Failed to match gid %s (%d out of %d)" % (self.prevflatb[ilf].gid, ilf, len(self.prevflatb))
		if not bquietc:
			print "\n*** GID match fault ***"
			print "old version: %s" % self.lfilenames[0]
			print "new version: %s" % self.lfilenames[1]
			print ""

			# print out errors and hints how to fix
			print "Unmatched line gid: %s" % self.prevflatb[ilf].gid

			print "first record in old XML file that we failed to match:"
			print "gid", self.prevflatb[ilf].gid
			print "    ", self.prevflatb[ilf].nametype, self.prevflatb[ilf].speakerid, "|", self.prevflatb[ilf].speakername
			oldparatxt = string.join(self.prevflatb[ilf].paras, "|")
			print "    ", oldparatxt[:70].encode("latin-1", "ignore") # this is unprepared text
			print ""

			if ifgb < len(flatb):
				qb = flatb[ifgb]
				print "Line attempting to match: %s" % qb.GID
				print "    ", qb.typ
				print "    ", qb.speaker
				newparatxt = string.join(qb.stext, "|")
				print "    ", newparatxt[:70].encode("latin-1", "ignore")

				if re.sub("<[^>]*>|\s+", "", oldparatxt)[:50] == re.sub("<[^>]*>|\s+", "", newparatxt)[:50]:
					print "First 50 chars of speech match"

				ggidold = re.search("\.((\d+)[WAS]*)\.(\d+)$", self.prevflatb[ilf].gid)
				ggidnew = re.search("\.((\d+)[WAS]*)\.(\d+)$", flatb[ifgb].GID)

				if ggidold and ggidnew:

					# have a good guess at this being a column number move
					if (string.atoi(ggidold.group(2)) > string.atoi(ggidnew.group(2))) and (string.atoi(ggidold.group(3)) == 0):
						print "I think you should insert the following command before the listed speech: "
						print '<stamp parsemess-colnum="%s"/>' % ggidold.group(1)

				else:
					print "Gids don't fit the format"

			else:
				print "Can't find matches beyond end of new file"

			print ""
			print "missing speeches can be fixed by inserting a placeholder:"
			print '    <parsemess-misspeech type="speech|heading" redirect="up|down|nowhere"/>'
			print "changes in column number can be reset by inserting a command:"
			print '    <stamp parsemess-colnum="888|888W"/>'
			print "additional speeches can be fixed by inserting a numbering skip command:"
			print '    <stamp parsemess-missgid="4"/>'
			print '    where the missing number is of the paragraph as it would have been without it knocked out'
			print "See readme.txt for full set of commands\n"


		# get a position we will jump to of last match (if we can)
		prevstampurl = None
		if ifgb < len(flatb):
			prevstampurl = flatb[ifgb].sstampurl
		elif flatb:
			prevstampurl = flatb[-1].sstampurl
		raise ContextException(exdesc, stamp=prevstampurl)


	# the verification that the files have the same GIDs
	# id="uk.org.publicwhip/debate/2004-05-27.1695.1"
	def CompareGIDS(self, flatb, bquietc):
		# work through and find the set of matching numbers for this column

		ilf = 0  # index into flatb
		ifgb = 0  # index in flatbgidbatch

		# we try to make sure that what is in prevflatb can be found somewhere in flatbgidbatch
		# ie that the new html file contains all that is in the xml file
		while ilf < len(self.prevflatb):

			# no match on this pair
			if not ((ifgb < len(flatb)) and self.prevflatb[ilf].Compareqbs(flatb[ifgb])):
				# skip forward looking for any later matches
				nifgb = ifgb + 1
				while ((nifgb < len(flatb)) and not self.prevflatb[ilf].Compareqbs(flatb[nifgb])):
					nifgb += 1

				# this means there are new entries in the new xml file (marked by the <stamp parsemess-missgid> patch to the html)
				# which we are skipping over here.
				if nifgb < len(flatb):
					ifgb = nifgb
				# otherwise this is the first failed match
				else:
					self.MessageForCompareGIDError(ilf, flatb, ifgb, bquietc)

			# move on to the next pair
			ifgb += 1
			ilf += 1

		# fires if there are more entries left in the old xml file unaccounted for
		if ilf < len(self.prevflatb):
			# throws an exception
			self.MessageForCompareGIDError(ilf, flatb, ifgb, bquietc)


# write out a whole file which is a list of qspeeches, and construct the ids.
def CreateGIDs(gidpart, flatb, sdate):
	pcolnum = "####"
	picolnum = -1
	ncid = -1

	# the missing gid numbers come previous to the gid they would have gone, to handle missing ones before the 0
	# 0-1, 0-2, 0, 1, 2, 3-0, 3-1, 3, ...
	ncmissedgidrun = 0
	ncmissedgid = 0

	for qb in flatb:

		# construct the gid
		colnum = re.search('colnum="([^"]*)"', qb.sstampurl.stamp).group(1)

		# this updates any column number corrections that were appended on the end of the stamp
		for colnum in re.findall('parsemess-colnum="([^"]*)"', qb.sstampurl.stamp):
			pass

		# this numbers the speech numbers in the column numbers
		if colnum != pcolnum:
			# check that the column numbers are increasing
			# this is essential if the gids are to be unique.
			icolnum = string.atoi(re.match('(\d+)[W]*$', colnum).group(1))
			if icolnum <= picolnum:
				print qb.sstampurl.stamp
				raise ContextException("non-increasing column numbers %s %d" % (colnum, picolnum), stamp=qb.sstampurl, fragment=colnum)
			picolnum = icolnum

			pcolnum = colnum
			ncid = 0
			ncmissedgidrun = 0
			ncmissedgid = 0
		else:
			ncid += 1

		# this executes the missing ncid numbering command
		bmissgid = False
		for missgid in re.findall('parsemess-missgid="([^"]*)"', qb.sstampurl.stamp):
			if ncid == string.atoi(missgid):
				bmissgid = True

		if bmissgid:
			ncmissedgidrun += 1
			missedgidext = "-%d" % ncmissedgidrun
		else:
			ncmissedgidrun = 0
			missedgidext = ""

		# this is our GID !!!!
		qb.GID = 'uk.org.publicwhip/%s/%s.%s.%d%s' % (gidpart, sdate, colnum, ncid - ncmissedgid, missedgidext)
		if bmissgid:
			ncmissedgid += 1

# quite involved to make this
def getXMLdiffname(jfout):
	renn = re.compile("%s.diff(\d+)" % os.path.basename(jfout))
	ipp = 1
	for pp in os.listdir(os.path.dirname(jfout)):
		regpp = renn.match(pp)
		if regpp:
			ipp = string.atoi(regpp.group(1)) + 1
	res = "%s.diff%d" % (jfout, ipp)
	assert renn.match(os.path.basename(res))
	assert not os.path.isfile(res)
	return res

# write out a whole file which is a list of qspeeches, and construct the ids.
def WriteXMLFile(gidpart, tempname, jfout, flatb, sdate, bquietc):

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

	# load up a previous xml file, if it exists, compare, and delete if fine.
	if os.path.isfile(jfout):
		# load file
		ppf = PrevParsedFile(jfout)
		ppf.lfilenames = (jfout, tempname)  # used in the message in case of error

		# compare (throws exception if failure)
		ppf.CompareGIDS(flatb, bquietc)

		# make a file to record the differences (for keeping track of later)
		jfoutpatch = getXMLdiffname(jfout)

		# the regexp on this diff line is limited, but this factors any line that has a changeable url in it, and will
		# let us see changes in votes and changes in speeches in enough of a context
		ern = os.system('diff -u --ignore-matching-lines="<.*?url=[^>]*>" %s %s > %s' % (tempname, jfout, jfoutpatch))
		if ern == 2:
			print "Error running diff"
			raise Exception, "Error running diff"

		# remove diff file if empty as no point in keeping it
		if not os.path.getsize(jfoutpatch):
			os.remove(jfoutpatch)
		else:
			print "Writing difffile %s of over-written XML output" % jfoutpatch

		# file is satisfactory, and diff file of minor changes has been recorded,
		# now safe to delete the old XML file
		os.remove(jfout)

	# the rename from tempname to jfout is done in the function above.

