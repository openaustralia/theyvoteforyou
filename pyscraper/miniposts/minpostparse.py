#! /usr/bin/env python2.3
# vim:sw=8:ts=8:et:nowrap

# to do:
# Fill in the 2003-2004 gap



import os
import datetime
import re
import sys
import urllib
import string

import miscfuncs
import difflib
import mx.DateTime
from resolvemembernames import memberList

from xmlfilewrite import WriteXMLHeader

toppath = miscfuncs.toppath
rawdatapath = miscfuncs.rawdatapath
chggdir = os.path.join(rawdatapath, "chggpages")
chgtmp = os.path.join(toppath, "tempchgg.xml")


uniqgovposns = ["Prime Minister",
				"Chancellor of the Exchequer",
				"Lord Steward",
				"Treasurer of Her Majesty's Household",
				"Chancellor of the Duchy of Lancaster",
				"President of the Council",
				"Parliamentary Secretary to the Treasury",
				"Second Church Estates Commissioner",
				"Chief Secretary",
				"Advocate General for Scotland",
				"Deputy Chief Whip (House of Lords)",
				"Vice Chamberlain",
				"Attorney General",
				"Chief Whip (House of Lords)",
				"Lord Privy Seal",
				"Solicitor General",
				"Economic Secretary",
				"Financial Secretary",
				"Lord Chamberlain",
				"Comptroller",
				"Deputy Prime Minister",
				"Paymaster General",
				"Master of the Horse",
				]

govposns = ["Secretary of State",
			"Minister without Portfolio",
			"Minister of State",
			"Parliamentary Secretary",
			"Parliamentary Under-Secretary",
			"Assistant Whip",
			"Lords Commissioner",
			"Lords in Waiting",
			"Baronesses in Waiting",
			 ]

govdepts = ["Department of Health",
			"HM Treasury",
			"HM Household",
			"Home Office",
			"Cabinet Office",
			"Privy Council Office",
			"Ministry of Defence",
			"Department for Environment, Food and Rural Affairs",
			"Department for International Development",
			"Department for Culture, Media & Sport",
			"Department for Constitutional Affairs",
			"Department for Education and Skills",
			"Office of the Deputy Prime Minister",
			"Department for Transport",
			"Department for Work and Pensions",
			"Northern Ireland Office",
			"Law Officers' Department",
			"Department of Trade and Industry",
			"House of Commons",
			"Foreign & Commonwealth Office",
			"No Department",
			]

import newlabministers2003_10_15

renampos = re.compile("<td><b>([^,]*),\s*([^<]*)</b></td><td>([^,<]*)(?:,\s*([^<]*))?(?:</td>)?\s*$(?i)")

class protooffice:
	def __init__(self, lsdatet, e, deptno):  # department number to extract multiple departments
		self.sdatet = lsdatet

		nampos = renampos.match(e)
		self.lasname = nampos.group(1)
		self.froname = nampos.group(2)
		self.froname = re.sub(" (?:QC|MBE)$", "", self.froname)
		self.fullname = "%s %s" % (self.froname, self.lasname)
		pos = nampos.group(3)
		dept = nampos.group(4) or "No Department"

		# separate out the departments if more than one
		if dept not in govdepts:
			self.depts = None

			# go through and try to match <dept> + " and "
			for gd in govdepts:
				dept0 = dept[:len(gd)]
				if (gd == dept0) and (dept[len(gd):len(gd) + 5] == " and "):
					dept1 = dept[len(gd) + 5:]

					# we're trying to split these strings up, but it's pretty rigid
					if dept1 in govdepts:
						self.depts = [ (pos, dept0), (pos, dept1) ]
						break
					pd1 = re.match("([^,]+),\s*(.+)$", dept1)
					if pd1 and pd1.group(2) in govdepts:
						self.depts = [ (pos, dept0), (pd1.group(1), pd1.group(2)) ]
						break
					print "Attempted match on", dept0

			if not self.depts:
				print "No match with", dept

		else:
			self.depts = [ (pos, dept) ]


		# map down to the department for this record
		self.pos = self.depts[deptno][0]
		self.dept = self.depts[deptno][1]

	# do the xml thing
	def WriteXML(self, fout):
		fout.write('<moffice id="%s" name="%s"' % (self.moffid, self.fullname))
		if self.matchid:
			fout.write(' matchid="%s"' % self.matchid)
		fout.write("\n")
		fout.write('\tdept="%s" position="%s"\n' % (re.sub("&", "&amp;", self.dept), self.pos))
		fout.write('\tfromdate="%s" fromtime="%s"%s\n' % (self.sdatestart, self.stimestart, self.sxfromincomplete))
		if self.bopen:
			fout.write('\ttodate="%s" totime="%s"\n' % ("9999-99-99", "99:99"))
		else:
			fout.write('\ttodate="%s" totime="%s"\n' % (self.sdateend, self.stimeend))
		fout.write('\tsource="chgpages"/>\n')

	# turns the protooffice into a part of a chain
	def SetChainFront(self, fn):
		(self.sdatestart, self.stimestart) = self.sdatet
		(self.sdateend, self.stimeend) = self.sdatet
		self.fn = fn
		self.bopen = True

	def SetChainBack(self, sdatet):
		(self.sdateend, self.stimeend) = self.sdatet  # when we close it, it brings it up to the day the file changed
		self.bopen = False

	# this helps us chain the offices
	def StickChain(self, nextrec, fn):
		assert (self.sdateend, self.stimeend) < nextrec.sdatet
		assert self.bopen

		if (self.lasname == nextrec.lasname) and (self.froname == nextrec.froname) and (self.dept == nextrec.dept):
			(self.sdateend, self.stimeend) = nextrec.sdatet
			self.fn = fn
			return True
		return False


def ParsePage(fr):

	# extract the updated date and time
	frupdated = re.search('<td class="lastupdated">\s*Updated (.*?)&nbsp;(.*?)\s*</td>', fr)
	lsudate = re.match("(\d\d)/(\d\d)/(\d\d)$", frupdated.group(1))
	y2k = int(lsudate.group(3)) < 50 and "20" or "19"
	sudate = "%s%s-%s-%s" % (y2k, lsudate.group(3), lsudate.group(2), lsudate.group(1))
	sutime = frupdated.group(2)

	# extract the date on the document
	frdate = re.search(">Her Majesty's Government at\s+(.*?)\s*<", fr)
	msdate = mx.DateTime.DateTimeFrom(frdate.group(1)).date

	if  msdate != sudate:   # is it always posted up on the day it is announced?
                print "Updated date is %s, but date of change %s" % (sudate, msdate)

	sdate = msdate
	stime = sutime	# or midnight if not posted properly to match the msdate

	# extract the alphabetical list
	alphl = re.search("ALPHABETICAL LIST OF HM GOVERNMENT([\s\S]*?)</table>", fr).group(1)
	lst = re.split("</?tr>(?i)", alphl)

	# match the name form on each entry
	#<TD><B>Abercorn, Duke of</B></TD><TD>Lord Steward, HM Household</TD>

	res = [ ]

	luniqgov = uniqgovposns[:]
	for e1 in lst:
		e = e1.strip()
		if re.match("(?:<[^<]*>|\s)*$", e):
			continue

		# multiple entry of departments (simple inefficient method)
		for deptno in range(3):  # at most 3 offices at a time, we'll handle
			ec = protooffice((sdate, stime), e, deptno)

			# prove we've got all the posts
			if ec.pos not in govposns:
				if ec.pos in luniqgov:
					luniqgov.remove(ec.pos)
				else:
					print "Unnaccounted govt position", ec.pos

			res.append(ec)

			if len(ec.depts) == deptno + 1:
				break

	return (sdate, stime), res

# this goes through all the files and chains govt positions together
def ParseGovPostsChggdir():
	govpostdir = os.path.join(chggdir, "govposts")

	gps = os.listdir(govpostdir)
        gps = [ x for x in gps if re.match(".*\.html$", x) ]
        gps.sort() # important to do in order of date

        chainprotos = [ ]
        sdatetlist = [ ]
        for gp in gps:
                print os.path.join(govpostdir, gp)
                f = open(os.path.join(govpostdir, gp))
                fr = f.read()
                f.close()

                # get the protooffices from this file
                sdatet, proff = ParsePage(fr)


                # stick any chains we can
                proffnew = [ ]
                lsxfromincomplete = ((not chainprotos) and ' fromdateincomplete="yes"') or ''
                for prof in proff:
                        bstuck = False
                        for chainproto in chainprotos:
                                if chainproto.bopen and (chainproto.fn != gp) and chainproto.StickChain(prof, gp):
                                        assert not bstuck
                                        bstuck = True
                        if not bstuck:
                                prof.sxfromincomplete = lsxfromincomplete;
                                proffnew.append(prof)

                # close the chains that have not been stuck
                for chainproto in chainprotos:
                        if chainproto.bopen and (chainproto.fn != gp):
                                chainproto.SetChainBack(sdatet)
                                #print "closing", chainproto.lasname

                # append on the new chains
                for prof in proffnew:
                        prof.SetChainFront(gp)
                        chainprotos.append(prof)

                sdatetlist.append(sdatet)

        # no need to close off the running cases with year 9999, because it's done in the writexml
        return chainprotos, sdatetlist

# endeavour to get an id into all the names
def SetNameMatch(cp, busedateend):
        cp.matchid = ""

        # don't match names that are in the lords
        if not re.search("Duke |Lord |Baroness ", cp.fullname):
                fullname = cp.fullname
                cons = ""
                fnm = re.match("(.*?)\s+\[(.*?)\]", fullname)
                if fnm:
                        fullname = fnm.group(1)
                        cons = fnm.group(2)
                elif fullname == "Mr Gareth Thomas" and cp.dept == "Department for International Development" and cp.sdatestart == "2004-04-16":
                        cons = "Harrow West"

                # helps to glue end to end
                # but try other date end if first doesn't work
                cpsdates = [cp.sdatestart, cp.sdateend]
                if busedateend:
                        cpsdates = [cp.sdateend, cp.sdatestart]

                res0 = cpsdates[0] and memberList.matchfullnamecons(fullname, cons, cpsdates[0])
                res1 = cpsdates[1] and memberList.matchfullnamecons(fullname, cons, cpsdates[1])
                if not (res0 or res1):
                        raise Exception, 'No match: ' + fullname + " : " + (cons or "[nocons]")
                cp.matchid, cp.remadename, cp.remadecons = (res0 or res1)

        else:
                cp.remadename = cp.fullname
                cp.remadecons = ""

        # make the structure we will sort by.  Note the ((,),) structure
        cp.sortobj = ((re.sub("(.*) (\S+)$", "\\2 \\1", cp.remadename), cp.remadecons), cp.sdatestart)

# main function that sticks it together
def ParseGovPosts():

        # get from our two sources (which unfortunately don't overlap, so they can't be merged)
        # We have a gap from 2003-10-15 to 2004-06-06 which needs filling !!!
        porres = newlabministers2003_10_15.ParseOldRecords()
        cpres, sdatetlist = ParseGovPostsChggdir()

        # allocate ids and merge lists
        rpcp = []

        moffidn = 1;
        for po in porres:
                po.sxfromincomplete = None
                SetNameMatch(po, True)
                po.moffid = "uk.org.publicwhip/moffice/%d" % moffidn
                rpcp.append((po.sortobj, po))
                moffidn += 1
        for cp in cpres:
                SetNameMatch(cp, False)
                cp.moffid = "uk.org.publicwhip/moffice/%d" % moffidn
                rpcp.append((cp.sortobj, cp))
                moffidn += 1


        # (this would be a good place for matching and gluing overlapping duplicates together)
        rpcp.sort()



        fout = open(chgtmp, "w")
        WriteXMLHeader(fout)
        fout.write("<publicwhip>\n")

        fout.write("\n")
        for lsdatet in sdatetlist:
                fout.write('<chgpageupdates date="%s" time="%s"/>\n' % lsdatet)

        # output the file, a tag round the groups of offices which form a single person
        prevrpm = None
        for rp in rpcp:

                if not prevrpm:
                        fout.write("\n<ministerofficegroup>\n")

                elif prevrpm[0][0] != rp[0][0]:
                        fout.write("</ministerofficegroup>\n")
                        fout.write("\n<ministerofficegroup>\n")

                # output un-glued ends
                if not rp[1].sdateend:
                        print "\n"
                        print rp[1].remadename, rp[1].pos, rp[1].dept
                if rp[1].sxfromincomplete:
                        print "  ", rp[1].remadename, rp[1].pos, rp[1].dept

                rp[1].WriteXML(fout)
                prevrpm = rp

        if prevrpm:
                fout.write("</ministerofficegroup>\n")
        fout.write("</publicwhip>\n\n")
        fout.close();

        # copy file over to its place
        # ...

        # we get the members directory and overwrite the file that's there
        # (in future we'll have to load and check match it)
        membersdir = os.path.normpath(os.path.abspath(os.path.join("..", "members")))
        ministersxml = os.path.join(membersdir, "ministers.xml")

        print "Over-writing %s;\nDon't forget to check it in" % ministersxml
        if os.path.isfile(ministersxml):
                os.remove(ministersxml)
        os.rename(chgtmp, ministersxml)


