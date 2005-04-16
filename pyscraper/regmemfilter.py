#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import re
import os
import string
import sets

from resolvemembernames import memberList
from miscfuncs import FixHTMLEntities
from miscfuncs import ApplyFixSubstitutions
from xmlfilewrite import WriteXMLHeader
import miscfuncs
toppath = miscfuncs.toppath

# directories
pwcmdirs = os.path.join(toppath, "cmpages")
pwxmldirs = os.path.join(toppath, "scrapedxml")
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

# Legacy patch system, use patchfilter.py and patchtool now
fixsubs = 	[
	( 'Nestle&#171;', 'Nestle', 1, '2004-01-31' ),
]

def RunRegmemFilters(fout, text, sdate):
        # message for cron so I check I'm using this
        print "New register of members interests!  Check it is working properly (via mpinfoin.pl) - %s" % sdate

	text = ApplyFixSubstitutions(text, sdate, fixsubs)

        WriteXMLHeader(fout)
	fout.write("<publicwhip>\n")

        rows = re.findall("<TR>(.*)</TR>", text)
        rows = [ re.sub("(<B>)|(</B>)", "", row) for row in rows ]
        rows = [ re.sub('<IMG SRC="3lev.gif">', "", row) for row in rows ]
        rows = [ re.sub("&#173;", "-", row) for row in rows ]
        rows = [ re.sub('\[<A NAME="n\d+"><A HREF="\#note\d+">\d+</A>\]', '', row) for row in rows ]
        rows = [ re.findall("<TD.*?>(.*?)</TD>", row) for row in rows ]

        memberset = sets.Set()
        needmemberend = False
        category = None
        categoryname = None
        subcategory = None
        for row in rows:
                (striprow, stripcount) = re.subn('</?[^>]+>', '', "".join(row))
                if striprow.strip() == "":
                        # There is no text on the row, just tags
                        pass
                elif len(row) == 1 and row[0] == "&nbsp;":
                        # <TR><TD COLSPAN=4>&nbsp;</TD></TR>
                        pass
                elif len(row) == 1:
                        # <TR><TD COLSPAN=4><B>JACKSON, Robert (Wantage)</B></TD></TR>
                        (lastname, firstname, constituency) = re.search("^([^,]*), ([^(]*) \((.*)\)$", row[0]).groups()
                        (id, remadename, remadecons) = memberList.matchfullnamecons(firstname + " " + memberList.lowercaselastname(lastname), constituency, sdate)
                        if not id:
                                raise Exception, "Failed to match name %s %s (%s) date %s" % (firstname, lastname, constituency, sdate)
                        if category:
                                fout.write('\t</category>\n')
                        if needmemberend:
                                fout.write('</regmem>\n')                                
                                needmemberend = False
                        fout.write(('<regmem personid="%s" memberid="%s" membername="%s" date="%s">\n' % (memberList.membertoperson(id), id, remadename, sdate)).encode("latin-1"))
                        memberset.add(id)
                        needmemberend = True
                        category = None
                        categoryname = None
                        subcategory = None
                elif len(row) == 2 and row[0] == '' and re.match('Nil\.\.?', row[1]):
                        # <TR><TD></TD><TD COLSPAN=3><B>Nil.</B></TD></TR> 
                        fout.write('Nil.\n')
                elif len(row) == 2 and row[0] != '':
                        # <TR><TD><B>1.</B></TD><TD COLSPAN=3><B>Remunerated directorships</B></TD></TR>
                        if category:
                                fout.write('\t</category>\n')
                        digits = row[0].replace("&nbsp;", "")
                        category = re.match("\s*(\d\d?)\.$", digits).group(1)
                        categoryname = row[1]
                        subcategory = None
                        fout.write('\t<category type="%s" name="%s">\n' % (category, categoryname))
                elif len(row) == 2 and row[0] == '':
                        # <TR><TD></TD><TD COLSPAN=3><B>Donations to the Office of the Leader of the Liberal Democrats received from:</B></TD></TR>
                        if subcategory:
                                fout.write('\t\t<item subcategory="%s">%s</item>\n' % (subcategory, FixHTMLEntities(row[1])))
                        else:
                                fout.write('\t\t<item>%s</item>\n' % FixHTMLEntities(row[1]))
                elif len(row) == 3 and row[0] == '' and row[1] == '':
                        # <TR><TD></TD><TD></TD><TD COLSPAN=2>19 and 20 September 2002, two days fishing on the River Tay in Scotland as a guest of Scottish Coal. (Registered 3 October 2002)</TD></TR>
                        if subcategory:
                                fout.write('\t\t<item subcategory="%s">%s</item>\n' % (subcategory, FixHTMLEntities(row[2])))
                        else:
                                fout.write('\t\t<item>%s</item>\n' % FixHTMLEntities(row[2]))
                elif len(row) == 3 and row[0] == '':
                        # <TR><TD></TD><TD><B>(a)</B></TD><TD COLSPAN=2>Smithville Associates; training consultancy.</TD></TR>
                        if subcategory:
                                fout.write('\t\t<item subcategory="%s">%s</item>\n' % (subcategory, FixHTMLEntities(row[1] + ' ' + row[2])))
                        else:
                                fout.write('\t\t<item>%s</item>\n' % FixHTMLEntities(row[1] + ' ' + row[2]))
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

        membersetexpect = sets.Set(memberList.mpslistondate(sdate))
        
        # check for missing/extra entries
        missing = membersetexpect.difference(memberset)
        if len(missing) > 0:
                print "Missing %d MP entries:\n" % len(missing), missing
        extra = memberset.difference(membersetexpect)
        if len(extra) > 0:
                print "Extra %d MP entries:\n" % len(missing), extra

	fout.write("</publicwhip>\n")

if __name__ == '__main__':
        from runfilters import RunFiltersDir
        RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', True)





