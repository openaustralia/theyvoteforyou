#! /usr/bin/python2.3

import sys
import re
import os
import string

# this filter finds the speakers and replaces with full itendifiers
# <speaker name="Eric Martlew  (Carlisle)"><p>Eric Martlew  (Carlisle)</p></speaker>

# in and out files for this filter
dirin = "c3daydebatematchspeakers"
dirout = "c4folding"
dtemp = "daydebtemp.htm"

lsectionregexp = '(<center>.*?</center>|<h\d align=center>.*?</h\d>)(?i)'
sectionregexp1 = '<center>(.*?)</center>(?i)'
sectionregexp2 = '<h\d align=center>(.*?)</h\d>(?i)'


foldhtmlhead = """
<html>
<head>
<title>Folding Debates</title>
<style type="text/css">
span
{
    color: #00003f;
    cursor: pointer;
    cursor: hand;
}


.pvis
{
    color: #00003f;
}

.phid
{
    color: #7f007f;
    display: none;
}
</style>

<script>
<!--
function cycle(me)
{
	me.style.display="none";
        me.setAttribute('class', 'phid');
        var other = me;

        if (me.getAttribute('pos') == 'last')
        {
		while (other.getAttribute('pos') != 'first')
		{
			other = other.previousSibling;
		}
	}
	else
		other = me.nextSibling;
	other.setAttribute('class', 'pvis');
	other.style.display="inline";
        return true;
}
// -->
</script>
</head>
<body>
"""
foldhtmlfoot = "</body></html>"

# scan through directory
fdirin = os.listdir(dirin)

for fin in fdirin:
	jfin = os.path.join(dirin, fin)
	jfout = os.path.join(dirout, fin)
	if os.path.isfile(jfout):
		print "skipping " + fin
		continue

	print fin
	fin = open(jfin);
	fr = fin.read()
	fin.close()

	tempfile = open(dtemp, "w")
	tempfile.write(foldhtmlhead)

	# setup for scanning through the file.
	# we should have a name matching module which gets the unique ids, and
	# takes the full speaker name and date to find a match.
	fs = re.split(lsectionregexp, fr)

	# the map which will expand the names from the common abbreviations
	for fss in fs:
		if not fss:
			continue
		sectiongroup = re.findall(sectionregexp1, fss)
		if len(sectiongroup) == 0:
			sectiongroup = re.findall(sectionregexp2, fss)
			if len(sectiongroup) == 0:

				# don't fold nothing
				if (len(fss) < 20):
					tempfile.write(fss)
					continue

				# put folds around this text
				tempfile.write('<span onclick="cycle(this)" class="phid" pos="first">')
				tempfile.write(fss)
				tempfile.write('</span><span onclick="cycle(this)" class="pvis" pos="last">')
				tempfile.write('<center>(')
				for i in range(len(fss) / 300):
					tempfile.write('-')
				tempfile.write(')</center>')
				tempfile.write('</span>')

				continue

		# we can detect divisions here, but keep simple for now.
		heading = sectiongroup[0]
		tempfile.write('<h3 align=center><font color="#004f3f">%s</font></h3>\n' % heading)

	tempfile.write(foldhtmlfoot)
	tempfile.close()
	os.rename(dtemp, jfout)
