#!/usr/bin/env python2.3
# $Id: writetothemfympconv.py,v 1.1 2005/02/22 13:35:19 frabcus Exp $
# vim:sw=4:ts=4:et:nowrap

# Quick hack match for loading FaxYourMP data into DaDem.

input = '/home/francis/devel/goveval/faxyourmp-mp-20041207.csv'

import sys
import string
import datetime
import csv
import sets
import urllib
sys.path.append("../pyscraper")
from resolvemembernames import memberList

date_today = datetime.date.today().isoformat()

ih = open(input)
ih.next() # skip first line
csvreader = csv.reader(ih)
csvwriter = csv.writer(sys.stdout)

print "name, constituency, email, fax, phone, constituencyfax"
for row in csvreader:
    if row == ["</b>"]:
        break

    origname, region, email, fax, phone, constituencyfax, image_file = map(string.strip, row)

    # ambiguous names
    cons = None
    if origname == "Mr Gareth Thomas":
        cons = "Clwyd West"
    if origname == "Mr Gareth R. Thomas":
        cons = "Harrow West"
    if origname == "Mr Michael Foster":
        cons = "Hastings and Rye"
    if origname == "Mr Michael J. Foster":
        cons = "Worcester"
    if origname == "Mr Anthony D. Wright":
        cons = "Great Yarmouth"
    if origname == "Dr Tony Wright":
        cons = "Cannock Chase"

    id, name, cons =  memberList.matchfullnamecons(origname, cons, date_today)
    if id == None:
        raise Exception("Failed to match '%s'" % origname)

    row = [name, cons, email, fax, phone, constituencyfax]
    row = [x.encode("latin-1") for x in row];
    csvwriter.writerow(row);

