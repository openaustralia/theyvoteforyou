#! /usr/bin/python2.3

import sys
import re
import os
import string
from stripsections import StripSections

# this filter finds the speakers and replaces with full itendifiers
# <speaker name="Eric Martlew  (Carlisle)"><p>Eric Martlew  (Carlisle)</p></speaker>

def Folding(fout, finr):

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

	fout.write(foldhtmlhead)

	#sdatel = re.findall('(\d{4}-\d{2}-\d{2})', finr)
	sdate = '1900-01-01'  # sdatel[0]
	stsec = StripSections(finr, sdate)

	stsec.foldwrite(fout)

	fout.write(foldhtmlfoot)
