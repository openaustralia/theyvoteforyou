#! /usr/bin/python2.3
import sys
import os
import urllib
import urlparse
import string
import re
import xml.sax

# In Debian package python2.3-egenix-mxdatetime
import mx.DateTime

import miscfuncs

toppath = miscfuncs.toppath

# Creates an xml with the links into the index files for the Lords.
# From here we get links into the Main Pages, the Grand Committee,
# the Written Statements, and the Written Answers, which are all
# linked across using the Next Section button (which will really
# screw things up) and all have independent column numbering systems.


# url with bound volumes 
urlbndvols = 'http://www.publications.parliament.uk/pa/ld199900/ldhansrd/pdvn/home.htm'

# url with the alldays thing on it.  
urlalldays = 'http://www.publications.parliament.uk/pa/ld199900/ldhansrd/pdvn/allddays.htm'

pwlordindex = os.path.join(toppath, "pwlordindex.xml")

# scrape limit date
earliestdate = '2001-11-25'
#earliestdate = '1994-05-01'

def LordsIndexFromAll(urlalldays):
    urlinkpage = urllib.urlopen(urlalldays)
    srlinkpage = urlinkpage.read()
    urlinkpage.close()
    
    # remove comments because they sometimes contain wrong links
    srlinkpage = re.sub('<!--[\s\S]*?-->', ' ', srlinkpage)

    # Find lines of the form: 
    # <p><a href="lds04/index/40129-x.htm">29 Jan 2004</a></p>
    realldayslinks = re.compile('<p><a href="([^"]*)">([^<]*)</a></p>(?i)')
    datelinks = realldayslinks.findall(srlinkpage)

    res = []
    for link in datelinks:
        sdate = mx.DateTime.DateTimeFrom(link[1]).date
        uind = urlparse.urljoin(urlalldays, re.sub('\s', '', link[0]))
        res.append((sdate, uind))
        
    return res


def WriteXML(fout, urllist):
	fout.write('<?xml version="1.0" encoding="ISO-8859-1"?>\n')
	fout.write("<publicwhip>\n\n")

	# avoid printing duplicates
	for i in range(len(urllist)):
		r = urllist[i]
		if (i == 0) or (r != urllist[i-1]):
			if r[0] >= earliestdate:
				fout.write('<lordsdaydeb date="%s" url="%s"/>\n' % r) 

	fout.write("\n</publicwhip>\n")


###############
# main function
###############
def UpdateLordsHansardIndex():
	# get front page (which we will compare against)
	urllisth = LordsIndexFromAll(urlalldays)

	urllisth.sort()
	urllisth.reverse()

        # we need to extend it to the volumes, but this will do for now.  

	fpwlordindex = open(pwlordindex, "w");
	WriteXML(fpwlordindex, urllisth)
	fpwlordindex.close()

UpdateLordsHansardIndex()

