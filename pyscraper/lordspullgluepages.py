#! /usr/bin/python2.3

import sys
import urllib
import urlparse
import re
import os.path
import xml.sax
import time
import string

import miscfuncs
toppath = miscfuncs.toppath

# Pulls in all the debates, written answers, etc, glues them together, removes comments,
# and stores them on the disk

# index file which is created
pwlordsindex = os.path.join(toppath, "pwlordindex.xml")

# output directories (everything of one day in one file).  
pwlordspages = os.path.join(toppath, "pwlordspages")

tempfile = os.path.join(toppath, "gluetemp")

# this does the main loading and gluing of the initial day debate
# files from which everything else feeds forward

# gets the index file which we use to go through the pages
class LoadLordsIndex(xml.sax.handler.ContentHandler):
	def __init__(self, lpwcmindex):
		self.res = []
		if not os.path.isfile(lpwcmindex):
			return
		parser = xml.sax.make_parser()
		parser.setContentHandler(self)
		parser.parse(lpwcmindex)

	def startElement(self, name, attr):
		if name == "lordsdaydeb":
			ddr = (attr["date"], attr["url"])
			self.res.append(ddr)


# extract the table of contents from an index page
def ExtractIndexContents(urlx):
    urx = urllib.urlopen(urlx)

    # find the contents label
    stcont = '<a name="contents"></a>\s*$'
    while 1:
        xline = urx.readline()
        if not xline:
            print '%s not found in %s' % (stcont, urlx) 
            raise Exception, "cannot index"
	if re.match(stcont, xline):
            break
    
    lklins = []
    while 1:
        xline = urx.readline()
        if not xline:
            print '<hr> not found in %s' % urlx 
            raise Exception, "cannot index"
	if re.match('<hr>\s*$', xline):
            break
        lklins.append(xline)
    
    lktex = string.join(lklins, '')

    # get the links
    #<p><a href="../text/40129w01.htm#40129w01_sbhd7"><H3><center>Olympic Games 2012: London Bid</center></H3>
    #</a></p>
    relkex = re.compile('<p><a href="(\S*?.htm)#\S*"><H3><center>(.*?)</center></H3>\s*</a></p>')
    res = relkex.findall(lktex)
    return res


def GlueByNext(fout, url, urlx):
	# put out the indexlink for comparison with the hansardindex file
	lt = time.gmtime()
	fout.write('<pagex url="%s" scrapedate="%s" scrapetime="%s"/>\n' % \
			(urlx, time.strftime('%Y-%m-%d', lt), time.strftime('%X', lt)))

	# loop which scrapes through all the pages following the nextlinks
	while 1:
		print " reading " + url
		ur = urllib.urlopen(url)
		sr = ur.read()
		ur.close();

		# write the marker telling us which page this comes from
		fout.write('<page url="' + url + '"/>\n')


		# split by sections
		hrsections = re.split('<hr>(?i)', sr)

		# this is the case for debates on 2003-03-13 page 30
		# http://www.publications.parliament.uk/pa/cm200203/cmhansrd/vo030313/debtext/30313-32.htm
		if len(hrsections) == 1:
			print len(hrsections)
			print ' page missing '
			print url
			fout.write('<UL><UL><UL></UL></UL></UL>\n')
			break


		# write the body of the text
		for i in range(1,len(hrsections) - 1):
			miscfuncs.WriteCleanText(fout, hrsections[i])

		# find the lead on with the footer
		footer = hrsections[len(hrsections) - 1]

		# the files are sectioned by the <hr> tag into header, body and footer.
		nextsectionlink = re.findall('<\s*a\s+href\s*=\s*"?(.*?)"?\s*>next section</a>(?i)', footer)
		if not nextsectionlink:
			break
		if len(nextsectionlink) > 1:
			raise Exception, "More than one Next Section!!!"
		url = urlparse.urljoin(url, nextsectionlink[0])



###############
# main function
###############
def PullGluePages():
	# make the output firectory
	if not os.path.isdir(pwlordspages):
		os.mkdir(pwlordspages)

	# load the index file previously made by createhansardindex
	clordsindex = LoadLordsIndex(pwlordsindex)

        # loop through the index of each lord line.  
        for dnu in clordsindex.res:
		# make the filename
		dgf = os.path.join(pwlordspages, ('daylord%s.html' % dnu[0])) 

		# hansard index page
		urlx = dnu[1]

		# if we already have got the file, check the pagex link agrees in the first line
		# no need to scrape it in again
		if os.path.exists(dgf):
			fpgx = open(dgf, "r")
			pgx = fpgx.readline()
			fpgx.close()
			if pgx:
				pgx = re.findall('<pagex url="([^"]*)"[^/]*/>', pgx)
				if pgx:
					if pgx[0] == urlx:
						print 'skipping ' + urlx
						continue
			print '\nRE-scraping ' + urlx
		else:
			print '\nscraping ' + urlx

                # The different sections are often all run together
                # with the title of written answers in the middle of a page.  
                icont = ExtractIndexContents(urlx)
                url0 = urlparse.urljoin(urlx, icont[0][0])

		# now we take out the local pointer and start the gluing
		dtemp = open(tempfile, "w")
		GlueByNext(dtemp, url0, urlx)

		# close and move
		dtemp.close()
		os.rename(tempfile, dgf)


# run main function
PullGluePages()

