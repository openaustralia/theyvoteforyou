#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import re
import os
import string
import cStringIO

import xml.sax
xmlvalidate = xml.sax.make_parser()

import miscfuncs
toppath = miscfuncs.toppath

from HTMLParser import HTMLParser

# directories
pwcmdirs = os.path.join(toppath, "cmpages")
pwxmldirs = os.path.join(toppath, "scrapedxml")
tempfile = os.path.join(toppath, "filtertemp")
if not os.path.isdir(pwxmldirs):
	os.mkdir(pwxmldirs)

class MyHTMLParser(HTMLParser):
        def __init__(self):
                HTMLParser.__init__(self)
                self.state = 'start'
                self.data = ''
                self.datastore = {}

        def handle_starttag(self, tag, attrs):
                self.tagstack.append((tag, attrs))
                self.datastack.append(self.data)
                self.data = ''

        def handle_endtag(self, tag):
                if self.tagstack[-1][0] == tag:
                        (tag, attr) = self.tagstack.pop()
                        self.data = self.datastack.pop()
                else:
                        self.data = self.datastack.pop()
                        print "Spurious close tag %s data %s" % (tag, self.data)


        def handle_data(self, data):
                self.data = self.data + data

def RunRegmemFilters(fout, text, sdate):
        miscfuncs.WriteXMLHeader(fout)
	fout.write("<publicwhip>\n")

        print "RunRegmemFilters ", sdate
        p = MyHTMLParser()
        p.feed(text)

	fout.write("</publicwhip>\n")

if __name__ == '__main__':
        from runfilters import RunFiltersDir
        print "Doing"
        RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', True)
        RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', False)





