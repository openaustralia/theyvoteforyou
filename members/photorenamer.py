#! /usr/bin/env python2.3

# Renames a folder of MP photos from filenames containing their names to
# filenames containing their member id

import os
import re
import sys

sys.path.append("../pyscraper/")
from resolvemembernames import memberList

photodir = "/home/francis/devel/fawkes/www/docs/images/orig/"
photodate = "2004-04-13"

dir = os.listdir(photodir)
renamemap = {}

# Perform name matching
for file in dir:
    match = re.match("([a-z_-]+)_([a-z-]+)(?:_(\d+))?_?.jpg", file) 
    assert match, "didn't match %s" % file
    (last, first, alienid) = match.groups()

    cons = None
    if file == "thomas_gareth_591.jpg":
        cons = "Clwyd West"
    if file == "thomas_gareth_r_592.jpg":
        cons = "Harrow West"
    if file == "wright_tony_w_654.jpg":
        cons = "Cannock Chase"
    if file == "wright_tony_653.jpg":
        cons = "Great Yarmouth"

    last = last.replace("_", " ")
    fullname = "%s %s" % (first, last)
    fullname = memberList.fixnamecase(fullname)
    (id, correctname, correctcons) = memberList.matchfullnamecons(fullname, cons, photodate)
    id = id.replace("uk.org.publicwhip/member/", "")

    renamemap[file] = "%s.jpg" % id

assert len(renamemap.keys()) == 659, "got %d keys, not 659" % len(renamemap.keys())

# Do renaming
for name, newname in renamemap.iteritems():
    assert not os.path.exists(newname), "file %s already exists" % newname
    print name, "=>", newname
    os.rename(photodir + name, photodir + newname)

