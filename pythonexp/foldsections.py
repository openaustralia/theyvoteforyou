#! /usr/bin/python2.3

import sys
import re
import os
import string
from stripsections import StripSections

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
	#if os.path.isfile(jfout):
	#	print "skipping " + fin
	#	continue

	print fin
	fin = open(jfin);
	fr = fin.read()
	fin.close()

	tempfile = open(dtemp, "w")
	tempfile.write(foldhtmlhead)

	stsec = StripSections(fr)

	stsec.foldwrite(tempfile)

	tempfile.write(foldhtmlfoot)
	tempfile.close()

	os.rename(dtemp, jfout)
