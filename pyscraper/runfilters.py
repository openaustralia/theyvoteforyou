#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import re
import os
import string
import cStringIO

import xml.sax
xmlvalidate = xml.sax.make_parser()

from patchfilter import ApplyPatches

from filterwranscolnum import FilterWransColnum
from filterwransspeakers import FilterWransSpeakers
from filterwranssections import FilterWransSections


from filterdebatecoltime import FilterDebateColTime
from filterdebatespeakers import FilterDebateSpeakers
from filterdebatesections import FilterDebateSections

from lordsfiltercoltime import SplitLordsText
from lordsfiltercoltime import FilterLordsColtime
from lordsfilterspeakers import LordsFilterSpeakers
from lordsfiltersections import LordsFilterSections

from contextexception import ContextException
from contextexception import RunPatchTool

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

tempfile = os.path.join(toppath, "filtertemp")
patchtempfile = os.path.join(toppath, "applypatchtemp")

# create the output directory
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

# this
def RunFiltersDir(filterfunction, dname, options, deleteoutput):
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

		if deleteoutput:
			if os.path.isfile(jfout):
				os.remove(jfout)
			continue

		# skip already processed files, if date is earler
                # (checking output date against input and patchfile, if there is one)
		if os.path.isfile(jfout):
                        out_modified = os.stat(jfout).st_mtime
                        in_modified = os.stat(jfin).st_mtime
                        patchfile = "patches/%s/%s.patch" % (dname,fin)
                        patch_modified = None
                        if os.path.isfile(patchfile):
                                patch_modified = os.stat(patchfile).st_mtime
                        if in_modified < out_modified and ((not patchfile) or patch_modified < out_modified):
                                continue
                        print "input modified since output reparsing, out: ", out_modified, " in: ", in_modified, " patch: ", repr(patch_modified)

                again = True
                while again:
                        again = False
                        
                        # apply patch filter
                        kfin = jfin
                        if ApplyPatches(jfin, patchtempfile):
                                kfin = patchtempfile

                        # read the text of the file
                        print "runfilters " + fin
                        ofin = open(kfin)
                        text = ofin.read()
                        ofin.close()

                        # store
                        newlistf = os.path.join(pwxmldirout, recentnewfile)
                        file = open(newlistf,'a+')
                        file.write(sdate + '\n')
                        file.close()

                        # call the filter function and copy the temp file into the correct place.
                        # this avoids partially processed files getting into the output when you hit escape.
                        try:
                                fout = open(tempfile, "w")
                                filterfunction(fout, text, sdate)
                                fout.close()
                                if sys.platform != "win32":
                                        # this function leaves the file open which can't be renamed in win32
                                        xmlvalidate.parse(tempfile) # validate XML before renaming
                                os.rename(tempfile, jfout)
                        except ContextException, ce:
                                if options.patchtool:
                                        print ce
                                        RunPatchTool(dname, sdate, ce)
                                        again = True
                                else:
                                        raise


# These text filtering functions filter twice through stringfiles,
# before directly filtering to the real file.
def RunWransFilters(fout, text, sdate):
	si = cStringIO.StringIO()
	FilterWransColnum(si, text, sdate)
	text = si.getvalue()
	si.close()

	si = cStringIO.StringIO()
	FilterWransSpeakers(si, text, sdate)
	text = si.getvalue()
	si.close()

	FilterWransSections(fout, text, sdate)


def RunDebateFilters(fout, text, sdate):
        memberList.cleardebatehistory()

	si = cStringIO.StringIO()
	FilterDebateColTime(si, text, sdate)
	text = si.getvalue()
	si.close()

	si = cStringIO.StringIO()
	FilterDebateSpeakers(si, text, sdate)
	text = si.getvalue()
	si.close()

	FilterDebateSections(fout, text, sdate)





# These text filtering functions filter twice through stringfiles,
# before directly filtering to the real file.
def RunLordsFilters(fout, text, sdate):
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

		LordsFilterSections(fout, text, sdate)

	return



