#! /usr/bin/env python2.3
# vim:sw=8:ts=8:et:nowrap

# Run the script with --help to see command line options

import sys

from optparse import OptionParser
from createhansardindex import UpdateHansardIndex
from pullgluepages import PullGluePages
from runfilters import RunFiltersDir, RunDebateFilters, RunWransFilters
from regmemfilter import RunRegmemFilters
from regmempullgluepages import RegmemPullGluePages

# Parse the command line parameters

parser = OptionParser()

parser.set_usage("""
Crawls the website of the proceedings of the UK parliament, also known as
Hansard.  Converts them into handy XML files, tidying up HTML errors,
generating unique identifiers for speeches, reordering sections, name matching
MPs and so on as it goes.

Specify at least one of the following actions to take:
scrape          update Hansard page index, and download new raw pages
parse           process scraped HTML into tidy XML files

And choose at least one of these sections to apply them to:
wrans           process Written Answers into XML files
debates         process Debates into XML files
regmem          process Register of Members Interests into XML files

Example command line
        ./lazyrunall.py --date=2004-03-03 --force-scrape scrape parse wrans
It forces redownload of the Written Answers for 3rd March, and reprocesses them.""")


# See what options there are

parser.add_option("--force-parse",
                  action="store_true", dest="forceparse", default=False,
                  help="forces reprocessing of wrans/debates by first deleting output files")
parser.add_option("--force-scrape",
                  action="store_true", dest="forcescrape", default=False,
                  help="forces redownloading of HTML first deleting output files")

parser.add_option("--from", dest="datefrom", metavar="date", default="1000-01-01",
                  help="date to process back to, default is start of time")
parser.add_option("--to", dest="dateto", metavar="date", default="9999-12-31",
                  help="date to process up to, default is present day")
parser.add_option("--date", dest="date", metavar="date", default=None,
                  help="date to process (overrides --from and --to)")

(options, args) = parser.parse_args()
if (options.date):
        options.datefrom = options.date
        options.dateto = options.date

# See what commands there are

options.scrape = False
options.parse = False
options.wrans = False
options.debates = False
options.regmem = False
for arg in args:
        if arg == "scrape":
                options.scrape = True
        elif arg == "parse":
                options.parse = True
        elif arg == "wrans":
                options.wrans = True
        elif arg == "debates":
                options.debates = True
        elif arg == "regmem":
                options.regmem = True
        else:
                parser.print_help()
                print >>sys.stderr, "error: no such option %s" % arg
                sys.exit(1)

# Do the work - all the conditions are so beautifully symmetrical, there
# must be a nicer way of doing it all...

if options.scrape:
        UpdateHansardIndex()
        if options.forcescrape:
                if options.wrans:
                        PullGluePages(options.datefrom, options.dateto, True, "wrans", "answers")
                if options.debates:
                        PullGluePages(options.datefrom, options.dateto, True, "debates", "debates")
                if options.regmem:
                        RegmemPullGluePages(True)
        if options.wrans:
                PullGluePages(options.datefrom, options.dateto, False, "wrans", "answers")
        if options.debates:
                PullGluePages(options.datefrom, options.dateto, False, "debates", "debates")
        if options.regmem:
                # TODO - date ranges when we do index page stuff for regmem
                RegmemPullGluePages(False)

if options.parse:
        if options.forceparse:
                if options.wrans:
                        RunFiltersDir(RunWransFilters, 'wrans', options.datefrom, options.dateto, True)
                if options.debates:
                        RunFiltersDir(RunDebateFilters, 'debates', options.datefrom, options.dateto, True)
                if options.regmem:
                        RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', True)
        if options.wrans:
                RunFiltersDir(RunWransFilters, 'wrans', options.datefrom, options.dateto, False)
        if options.debates:
                RunFiltersDir(RunDebateFilters, 'debates', options.datefrom, options.dateto, False)
        if options.regmem:
                # TODO - date ranges when we do index page stuff for regmem
                RunFiltersDir(RunRegmemFilters, 'regmem', '1000-01-01', '9999-12-31', False)

