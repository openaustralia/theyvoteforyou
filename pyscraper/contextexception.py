#! $Id: contextexception.py,v 1.11 2004/10/14 17:04:00 goatchurch Exp $
# vim:sw=8:ts=8:et:nowrap

import os
import string
import re
import sys
import shutil

from resolvemembernames import memberList

import miscfuncs
toppath = miscfuncs.toppath




class ContextException(Exception):

    def __init__(self, description, stamp = None, fragment = None):
        self.description = description
        self.stamp = stamp
        self.fragment = fragment
        self.insertstring = ""  # this is what gets shoved at the front of the patched file in the editor

    def __str__(self):
        ret = ""
        if self.fragment:
            ret = ret + "Fragment: " + repr(self.fragment) + "\n"
        ret = ret + self.description + "\n"
        if self.stamp:
            ret = ret + repr(self.stamp) + "\n"
        return ret

