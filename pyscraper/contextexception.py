#! $Id: contextexception.py,v 1.9 2004/05/04 10:07:59 goatchurch Exp $
# vim:sw=8:ts=8:et:nowrap

import os
import string
import re
import sys
import shutil

from resolvemembernames import memberList

import miscfuncs
toppath = miscfuncs.toppath

# windows version of the patchtool shell script
# this calls the contTEXT editor.
def RunPatchToolW(typ, sdate, stamp, frag):
	qfolder = toppath
	if typ != "lordspages":
		qfolder = os.path.join(qfolder, "cmpages")
	folder = os.path.join(qfolder, typ)
	stub = typ
	if stub == "wrans":
		stub = "answers"
	elif stub == "lordspages":
		stub = "daylord"

	pdire = os.path.join("patches", typ)
	if not os.path.isdir(pdire):
		os.mkdir(pdire)
	patchfile = os.path.join(pdire, "%s%s.html.patch" % (stub, sdate))
	orgfile = os.path.join(folder, "%s%s.html" % (stub, sdate))
	tmpfile = os.path.join(folder, "%s%s-patchtmp.html" % (stub, sdate))
	tmppatchfile = os.path.join(pdire, "%s%s.html.patch.new" % (stub, sdate))

	shutil.copyfile(orgfile, tmpfile)
	if os.path.isfile(patchfile):
		print "Patching ", patchfile
		status = os.system("patch --quiet %s <%s" % (tmpfile, patchfile))

	# run the editor (first finding the line number to be edited)
	gp = 0
	finforlines = open(tmpfile, "r")
	rforlines = finforlines.read();
	finforlines.close()

	if stamp:
		aname = stamp.GetAName()
		ganamef = re.search(('<a name\s*=\s*"%s">([\s\S]*?)<a name(?i)' % aname), rforlines)
		if ganamef:
			gp = ganamef.start(1)
	else:
		ganamef = None

	if not frag:
		fragl = -1
	elif ganamef:
		fragl = string.find(ganamef.group(1), frag)
	else:
		fragl = string.find(rforlines, frag)
	if fragl != -1:
		gp += fragl

	gl = string.count(rforlines, '\n', 0, gp)
	gc = 0
	if gl:
		gc = gp - string.rfind(rforlines, '\n', 0, gp)
	print "find loc codes ", gp, gl, gc
	os.system('"C:\Program Files\ConTEXT\ConTEXT" %s /g%d:%d' % (tmpfile, gc + 1, gl + 1))


	# now create the diff file
	if os.path.isfile(tmppatchfile):
		os.remove(tmppatchfile)
	ern = os.system("diff -u %s %s > %s" % (orgfile, tmpfile, tmppatchfile))
	if ern == 2:
		print "Error running diff"
		sys.exit(1)
	os.remove(tmpfile)
	if os.path.isfile(patchfile):
		os.remove(patchfile)
	if os.path.getsize(tmppatchfile):
		os.rename(tmppatchfile, patchfile)
		print "Making patchfile ", patchfile






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
			RunPatchToolW(type, sdate, ce.stamp, ce.fragment)
        memberList.reloadXML()


# should work from command line really.
# Run mainloop when run directly (for testing)
if __name__ == '__main__':
	print sys.argv
	if len(sys.argv) != 3:
		print "Usage ./contextexception.py wrans 2004-03-25"
		sys.exit(1)
	RunPatchToolW(sys.argv[1], sys.argv[2], None, "")

