#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import re
import os
import string
import cStringIO
import tempfile

import xml.sax
xmlvalidate = xml.sax.make_parser()

from patchfilter import ApplyPatches

from filterwranscolnum import FilterWransColnum
from filterwransspeakers import FilterWransSpeakers
from filterwranssections import FilterWransSections

from filterwmscolnum import FilterWMSColnum
from filterwmsspeakers import FilterWMSSpeakers
from filterwmssections import FilterWMSSections

from filterdebatecoltime import FilterDebateColTime
from filterdebatespeakers import FilterDebateSpeakers
from filterdebatesections import FilterDebateSections

from lordsfiltercoltime import SplitLordsText
from lordsfiltercoltime import FilterLordsColtime
from lordsfilterspeakers import LordsFilterSpeakers
from lordsfiltersections import LordsFilterSections

from contextexception import ContextException
from patchtool import RunPatchTool

from xmlfilewrite import WriteXMLFile

from resolvemembernames import memberList

import miscfuncs
toppath = miscfuncs.toppath

# master function which carries the glued pages into the xml filtered pages

# incoming directory of glued pages directories
pwcmdirs = os.path.join(toppath, "cmpages")
# outgoing directory of scaped pages directories
pwxmldirs = os.path.join(toppath, "scrapedxml")
# file to store list of newly done dates
recentnewfile = "recentnew.txt"

tempfilename = tempfile.mktemp(".xml", "pw-filtertemp-", miscfuncs.tmppath)
patchtempfilename = tempfile.mktemp("", "pw-applypatchtemp-", miscfuncs.tmppath)

# create the output directory
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

# this
def RunFiltersDir(filterfunction, dname, options, forcereparse):
	# the in and out directories for the type
	if dname == 'lordspages':
		pwcmdirin = os.path.join(toppath, dname)
	else:
		pwcmdirin = os.path.join(pwcmdirs, dname)
	pwxmldirout = os.path.join(pwxmldirs, dname)

	# create output directory
	if not os.path.isdir(pwxmldirout):
		os.mkdir(pwxmldirout)

	# loop through file in input directory in reverse date order
	fdirin = os.listdir(pwcmdirin)
	fdirin.sort()
	fdirin.reverse()
	for fin in fdirin:
		jfin = os.path.join(pwcmdirin, fin)
		if not re.search('\.html$', fin): # avoid vim swap files etc.
			continue
		if re.search('patch', fin): # avoid patch files
			continue

		# extract the date from the file name
		sdate = re.search('\d{4}-\d{2}-\d{2}', fin).group(0)

		# skip dates outside the range specified on the command line
		if sdate < options.datefrom or sdate > options.dateto:
			continue

		# create the output file name
		jfout = os.path.join(pwxmldirout, re.sub('\.html$', '.xml', fin))

		# skip already processed files, if date is earler
		# (checking output date against input and patchfile, if there is one)
		if os.path.isfile(jfout):
			out_modified = os.stat(jfout).st_mtime
			in_modified = os.stat(jfin).st_mtime
			patchfile = "patches/%s/%s.patch" % (dname,fin)
			patch_modified = None
			if os.path.isfile(patchfile):
				patch_modified = os.stat(patchfile).st_mtime
			if (not forcereparse) and (in_modified < out_modified) and ((not patchfile) or patch_modified < out_modified):
				continue
			if not forcereparse:
				print "input modified since output reparsing ", fin

		# here we repeat the parsing and run the patchtool editor until this file goes through.
		while True:
			# apply patch filter
			kfin = jfin
			if ApplyPatches(jfin, patchtempfilename):
				kfin = patchtempfilename

			# read the text of the file
			print "parsing " + fin
			ofin = open(kfin)
			text = ofin.read()
			ofin.close()

			# call the filter function and copy the temp file into the correct place.
			# this avoids partially processed files getting into the output when you hit escape.
			try:
				# do the filtering, then write the result
                                if dname == 'regmem':
                                        regmemout = open(tempfilename, 'w')
                                        filterfunction(regmemout, text, sdate)
                                        regmemout.close()
                                else:
                                        (flatb, gidname) = filterfunction(text, sdate)
                                        WriteXMLFile(gidname, tempfilename, jfout, flatb, sdate, options.quietc)

				if sys.platform != "win32":
					# this function leaves the file open which can't be renamed in win32
					xmlvalidate.parse(tempfilename) # validate XML before renaming

				# we will signal that it's safe by doing this in write function
                                # file override can happen for regmem
				if os.path.isfile(jfout) and dname != 'regmem':
					assert False # shouldn't happen (we leave by an exception)
					print "Leave for XML match testing: No over-write of file"
				else:
					os.rename(tempfilename, jfout)

				# store
				newlistf = os.path.join(pwxmldirout, recentnewfile)
				fil = open(newlistf,'a+')
				fil.write(sdate + '\n')
				fil.close()

				# we leave the loop
				break

			except ContextException, ce:
				if options.patchtool:
					print "runfilters.py", ce
					RunPatchTool(dname, sdate, ce)
					continue # emphasise that this is the repeat condition

				elif options.quietc:
					print ce.description
                                        print "\tERROR! failed, quietly moving to next day"
					# sys.exit(1) # remove this and it will continue past an exception (but then keep throwing the same tired errors)
					break # leave the loop having not written the xml file; go onto the next day

				else:
					raise


# These text filtering functions filter twice through stringfiles,
# before directly filtering to the real file.
def RunWransFilters(text, sdate):
	si = cStringIO.StringIO()
	FilterWransColnum(si, text, sdate)
	text = si.getvalue()
	si.close()

	si = cStringIO.StringIO()
	FilterWransSpeakers(si, text, sdate)
	text = si.getvalue()
	si.close()

	flatb = FilterWransSections(text, sdate)
	return (flatb, "wrans")


def RunDebateFilters(text, sdate):
	memberList.cleardebatehistory()

	si = cStringIO.StringIO()
	FilterDebateColTime(si, text, sdate, "debate")
	text = si.getvalue()
	si.close()

	si = cStringIO.StringIO()
	FilterDebateSpeakers(si, text, sdate, "debate")
	text = si.getvalue()
	si.close()

	flatb = FilterDebateSections(text, sdate, "debate")
	return (flatb, "debate")


def RunWestminhallFilters(text, sdate):
	memberList.cleardebatehistory()

	si = cStringIO.StringIO()
	FilterDebateColTime(si, text, sdate, "westminhall")
	text = si.getvalue()
	si.close()

	si = cStringIO.StringIO()
	FilterDebateSpeakers(si, text, sdate, "westminhall")
	text = si.getvalue()
	si.close()

	flatb = FilterDebateSections(text, sdate, "westminhall")
	return (flatb, "westminhall")

def RunWMSFilters(text, sdate):
        si = cStringIO.StringIO()
        FilterWMSColnum(si, text, sdate)
        text = si.getvalue()
        si.close()

        si = cStringIO.StringIO()
        FilterWMSSpeakers(si, text, sdate)
        text = si.getvalue()
        si.close()

        flatb = FilterWMSSections(text, sdate)
        return (flatb, "wms")

# These text filtering functions filter twice through stringfiles,
# before directly filtering to the real file.
def RunLordsFilters(text, sdate):
	fourstream = SplitLordsText(text, sdate)

	# the debates section (only)
	if fourstream[0]:
		si = cStringIO.StringIO()
		FilterLordsColtime(si, fourstream[0], sdate)
	   	text = si.getvalue()
		si.close()

		si = cStringIO.StringIO()
		LordsFilterSpeakers(si, text, sdate)
	   	text = si.getvalue()
		si.close()

		flatb = LordsFilterSections(text, sdate)
		return (flatb, "lords")

	# error for now
	assert False
	return None



