#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import re
import os
import string

from resolvemembernames import memberList
import miscfuncs
toppath = miscfuncs.toppath

# directories
pwcmdirs = os.path.join(toppath, "cmpages")
pwxmldirs = os.path.join(toppath, "scrapedxml")
tempfile = os.path.join(toppath, "filtertemp")
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

def RunRegmemFilters(fout, text, sdate):
        miscfuncs.WriteXMLHeader(fout)
	fout.write("<publicwhip>\n")

        print "RunRegmemFilters ", sdate

        rows = re.findall("<TR>(.*)</TR>", text)
        rows = [ re.sub("(<B>)|(</B>)", "", row) for row in rows ]
        rows = [ re.sub("&#173;", "-", row) for row in rows ]
        rows = [ re.findall("<TD.*?>(.*?)</TD>", row) for row in rows ]

        for row in rows:
                if len(row) == 1 and row[0] != "&nbsp;":
                        print row
                        (lastname, firstname, constituency) = re.search("^([^,]*), ([^(]*) \((.*)\)$", row[0]).groups()
                        print memberList.matchfullnamecons(firstname + " " + memberList.lowercaselastname(lastname), constituency, sdate)

	fout.write("</publicwhip>\n")

if __name__ == '__main__':
        from runfilters import RunFiltersDir
        print "Doing"
        RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', True)
        RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', False)





