#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import re
import os
import string

from resolvemembernames import memberList
from miscfuncs import FixHTMLEntities
from miscfuncs import ApplyFixSubstitutions
import miscfuncs
toppath = miscfuncs.toppath

# directories
pwcmdirs = os.path.join(toppath, "cmpages")
pwxmldirs = os.path.join(toppath, "scrapedxml")
tempfile = os.path.join(toppath, "filtertemp")
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

fixsubs = 	[
	( 'Nestle&#171;', 'Nestle', 1, '2004-01-31' ),
]

def RunRegmemFilters(fout, text, sdate):
	text = ApplyFixSubstitutions(text, sdate, fixsubs)

        miscfuncs.WriteXMLHeader(fout)
	fout.write("<publicwhip>\n")

        rows = re.findall("<TR>(.*)</TR>", text)
        rows = [ re.sub("(<B>)|(</B>)", "", row) for row in rows ]
        rows = [ re.sub('<IMG SRC="3lev.gif">', "", row) for row in rows ]
        rows = [ re.sub("&#173;", "-", row) for row in rows ]
        rows = [ re.sub('\[<A NAME="n\d+"><A HREF="\#note\d+">\d+</A>\]', '', row) for row in rows ]
        rows = [ re.findall("<TD.*?>(.*?)</TD>", row) for row in rows ]

        membercount = 0
        needmemberend = False
        category = None
        categoryname = None
        subcategory = None
        for row in rows:
                if len(row) == 1 and row[0] == "&nbsp;":
                        # <TR><TD COLSPAN=4>&nbsp;</TD></TR>
                        pass
                elif len(row) == 1:
                        # <TR><TD COLSPAN=4><B>JACKSON, Robert (Wantage)</B></TD></TR>
                        (lastname, firstname, constituency) = re.search("^([^,]*), ([^(]*) \((.*)\)$", row[0]).groups()
                        (id, remadename, remadecons) = memberList.matchfullnamecons(firstname + " " + memberList.lowercaselastname(lastname), constituency, sdate)
                        if category:
                                fout.write('\t</category>\n')
                        if needmemberend:
                                fout.write('</regmem>\n')                                
                                needmemberend = False
                        fout.write('<regmem memberid="%s">\n' % id)
                        membercount = membercount + 1
                        needmemberend = True
                        category = None
                        categoryname = None
                        subcategory = None
                elif len(row) == 2 and row[0] == '' and re.match('Nil\.\.?', row[1]):
                        # <TR><TD></TD><TD COLSPAN=3><B>Nil.</B></TD></TR> 
                        fout.write('Nil.\n')
                elif len(row) == 2:
                        # <TR><TD><B>1.</B></TD><TD COLSPAN=3><B>Remunerated directorships</B></TD></TR>
                        if category:
                                fout.write('\t</category>\n')
                        category = re.match("(\d\d?)\.$", row[0]).group(1)
                        categoryname = row[1]
                        subcategory = None
                        fout.write('\t<category type="%s" name="%s">\n' % (category, categoryname))
                elif len(row) == 3 and row[0] == '' and row[1] == '':
                        # <TR><TD></TD><TD></TD><TD COLSPAN=2>19 and 20 September 2002, two days fishing on the River Tay in Scotland as a guest of Scottish Coal. (Registered 3 October 2002)</TD></TR>
                        if subcategory:
                                fout.write('\t\t<item subcategory="%s">%s</item>\n' % (subcategory, FixHTMLEntities(row[2])))
                        else:
                                fout.write('\t\t<item>%s</item>\n' % FixHTMLEntities(row[2]))
                elif len(row) == 4 and row[0] == '' and (row[1] == '' or row[1] == '<IMG SRC="3lev.gif">'):
                        # <TR><TD></TD><TD></TD><TD>(b)</TD><TD>Great Portland Estates PLC</TD></TR>
                        subcategorymatch = re.match("\(([ab])\)$", row[2])
                        if not subcategorymatch:
                                content = FixHTMLEntities(row[2] + " " + row[3])
                                if subcategory:
                                        fout.write('\t\t<item subcategory="%s">%s</item>\n' % (subcategory, content))
                                else:
                                        fout.write('\t\t<item>%s</item>\n' % content)
                        else:
                                subcategory = subcategorymatch.group(1)
                                fout.write('\t\t(%s)\n' % subcategory)
                                fout.write('\t\t<item subcategory="%s">%s</item>\n' % (subcategory, FixHTMLEntities(row[3])))
                else:
                        print row
                        raise Exception, "Unknown row type match"
        if category:
                fout.write('\t</category>\n')
        if needmemberend:
                fout.write('</regmem>\n')                                
                needmemberend = False

        assert membercount == 659, "Not found exactly 659 members in regmem, found %d" % membercount

	fout.write("</publicwhip>\n")

if __name__ == '__main__':
        from runfilters import RunFiltersDir
        RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', True)
        RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', False)





