#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import sys
import urllib
import urlparse
import re
import os.path
import time

import miscfuncs
toppath = miscfuncs.toppath

# Pulls in register of members interests, glues them together, removes comments,
# and stores them on the disk

# output directories
pwcmdirs = os.path.join(toppath, "cmpages")
pwcmregmem = os.path.join(pwcmdirs, "regmem")

tempfile = os.path.join(toppath, "gluetemp")

def GlueByNext(fout, url):
	# loop which scrapes through all the pages following the nextlinks
        starttablewritten = False
	while 1:
		print " reading " + url
		ur = urllib.urlopen(url)
		sr = ur.read()
		ur.close();

		# write the marker telling us which page this comes from
                lt = time.gmtime()
                fout.write('<page url="%s" scrapedate="%s" scrapetime="%s"/>\n' % \
			(url, time.strftime('%Y-%m-%d', lt), time.strftime('%X', lt)))

		# split by sections
		hrsections = re.split(
                        '<TABLE border=0 width="90%">|' +
                        '</TABLE>\s*?<!-- end of variable data -->|' +
                        '<!-- end of variable data -->\s*</TABLE>' +
                        '(?i)', sr)

		# write the body of the text
#		for i in range(0,len(hrsections)):
#                        print "------"
#                        print hrsections[i]
                text = hrsections[2] 
                m = re.search('<TABLE .*?>([\s\S]*)</TABLE>', text)
                if m:
                        text = m.group(1)
                m = re.search('<TABLE .*?>([\s\S]*)', text)
                if m:
                        text = m.group(1)
                if not starttablewritten and re.search('COLSPAN=4', text):
                        text = "<TABLE>\n" + text
                        starttablewritten = True
                miscfuncs.WriteCleanText(fout, text)

		# find the lead on with the footer
		footer = hrsections[3]

                nextsectionlink = re.findall('<A href="(.*?)"><IMG border=0 align=top src="/pa/img/nextgrn.gif" ALT="next page"></A>', footer)
		if not nextsectionlink:
			break
		if len(nextsectionlink) > 1:
			raise Exception, "More than one Next Section!!!"
		url = urlparse.urljoin(url, nextsectionlink[0])
        
        fout.write('</TABLE>')


# read through our index list of daydebates
def GlueAllType(pcmdir, cmindex, fproto, deleteoutput):
	if not os.path.isdir(pcmdir):
		os.mkdir(pcmdir)

	for dnu in cmindex:
		# make the filename
		dgf = os.path.join(pcmdir, (fproto % dnu[0]))

                if deleteoutput:
                    if os.path.isfile(dgf):
                            os.remove(dgf)
                else:
                    # hansard index page
                    url = dnu[1]

                    # now we take out the local pointer and start the gluing
                    dtemp = open(tempfile, "w")
                    GlueByNext(dtemp, url)

                    # close and move
                    dtemp.close()
                    os.rename(tempfile, dgf)



###############
# main function
###############
def PullGluePages(deleteoutput):
	# make the output firectory
	if not os.path.isdir(pwcmdirs):
		os.mkdir(pwcmdirs)
                
        # Current data
        # http://www.publications.parliament.uk/pa/cm/cmhocpap.htm#register
        urls = [ ('2003-12-04', 'http://www.publications.parliament.uk/pa/cm/cmregmem/memi01.htm') ]

	# bring in and glue together parliamentary register of members interests and put into their own directories.
	# third parameter is a regexp, fourth is the filename (%s becomes the date).
	GlueAllType(pwcmregmem, urls, 'regmem%s.html', deleteoutput)

if __name__ == '__main__':
        PullGluePages(False)

