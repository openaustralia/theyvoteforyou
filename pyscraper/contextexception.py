#! $Id: contextexception.py,v 1.5 2004/04/20 14:13:47 goatchurch Exp $
# vim:sw=8:ts=8:et:nowrap

import os
import sys
from resolvemembernames import memberList

import miscfuncs
toppath = miscfuncs.toppath

def RunPatchToolW(typ, sdate, aname):
	qfolder = os.path.join(toppath, "cmpages")
	folder = os.path.join(qfolder, typ)
	stub = typ
	if stub == "wrans":
		stub = "answers"

	pdire = os.path.join("patches", typ)
	if not os.path.isdir(pdire):
		os.mkdir(pdire)
	patchfile = os.path.join(pdire, "%s%s.html.patch" % (stub, sdate))
	orgfile = os.path.join(folder, "%s%s.html" % (stub, sdate))
	tmpfile = os.path.join(folder, "%s%s-patchtmp.html" % (stub, sdate))

	print patchfile
	print orgfile
	print tmpfile

	if os.path.isfile(tmpfile):
		os.remove(tmpfile)
	sys.exit(0)
	# how can there be no copy command??
	#os.copy(orgfile, tmpfile)
	if os.path.isfile(patchfile):
		status = os.system("patch --quiet context %s <%s" % (tmpfile, patchfile))
	os.system("context %s" % tmpfile)

	# create patch file nonsense







class ContextException(Exception):

    def __init__(self, description, stamp = None, fragment = None):
        self.description = description
        self.stamp = stamp
        self.fragment = fragment

    def __str__(self):
        ret = ""
        if self.fragment:
            ret = ret + "Fragment: " + repr(self.fragment) + "\n"
        ret = ret + self.description + "\n"
        if self.stamp:
            ret = ret + repr(self.stamp) + "\n"
        return ret

def RunPatchTool(type, sdate, ce):
        if not ce.stamp:
                print "No stamp available, so won't move your cursor to right place"
        else:
                assert ce.stamp.sdate == sdate

        print "\nHit RETURN to launch your editor to make patches "
        sys.stdin.readline()
        if sys.platform != "win32":
            if not ce.stamp:
                    status = os.system("./patchtool %s %s" % (type, sdate))
            else:
                    status = os.system("./patchtool %s %s -c /%s" % (type, sdate, ce.stamp.GetAName()))
        else:
            status = os.system("pachtwin.bat %s %s" % (type, sdate))
        memberList.reloadXML()


# should work from command line really.
#RunPatchToolW("debates", "2002-02-26", "")

