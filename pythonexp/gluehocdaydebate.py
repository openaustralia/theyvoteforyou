import sys
import urllib
import urlparse
import re

# hard-coded for now
url = "http://www.publications.parliament.uk/pa/cm199900/cmhansrd/vo001107/debtext/01107-01.htm"
daydebatefile = "hocdaydebate2000-11-07.htm"
junkfile = "hocdaydebate2000-11-07-junk.htm"

# output files
daydebate = open(daydebatefile, "w");
junk = open(junkfile, "w");

while 1:
	print "reading " + url
	ur = urllib.urlopen(url)
	hrsections = re.split("<hr>(?i)", ur.read())
	ur.close();

	# the files are sectioned by the <hr> tag into header, body and footer.

	# output the junk so we can look at it
	junk.write('<hr url="' + url + '">\n')
	junk.write(hrsections[0])
	map(junk.write, hrsections[2:])

	# output the body text with hr label so we can tell where the file boundaries are
	daydebate.write('<hr url="' + url + '">\n')
	daydebate.write(hrsections[1])

	# find the link to the next section using a regexp
	nextsectiongroup = re.search('<\s*a\s+href\s*=\s*"?(.*?)"?\s*>next section</a>(?i)', hrsections[2])
	if not nextsectiongroup:
		break
	nexturl = nextsectiongroup.group(1)
	url = urlparse.urljoin(url, nexturl)

# close and finish
daydebate.close()
junk.close()




