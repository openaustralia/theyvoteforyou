#! /usr/bin/python2.3
# vim:sw=8:ts=8:et:nowrap

import os
import shutil

def ApplyPatches(filein, fileout):
        # Generate short name such as wrans/answers2003-03-31.html
        (rest, name) = os.path.split(filein)
        (rest, dir) = os.path.split(rest)
        fileshort = os.path.join(dir, name)

        # Look for a patch file from our collection (which is
        # in the pyscraper/patches folder in Public Whip CVS)
        patchfile = os.path.join("patches", fileshort + ".patch")
        if not os.path.isfile(patchfile):
                return False
        
        # Apply the patch
        shutil.copyfile(filein, fileout)
        status = os.system("patch --quiet %s <%s" % (fileout, patchfile))
        if status != 0:
                raise Exception, "Error running 'patch' file %s" % fileshort

        return True

