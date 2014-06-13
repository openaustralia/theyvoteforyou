#!/bin/sh
# Fetches the required xml data from data.openaustralia.org
# and feeds it into the database via the perl scripts

set -e

MEMXML2DB_PERL=memxml2db.pl
LOAD_PERL=load.pl
CALC_CACHES_PHP=calc_caches.php

if [ ! -d data.openaustralia.org/members ] ; then
    # ~2MB download as of June 2014
    wget -r -np -A *.xml data.openaustralia.org/members/
fi

if [ ! -d data.openaustralia.org/scrapedxml ] ; then
    # ~700MB download as of June 2014
    wget -r -np -A *.xml data.openaustralia.org/scrapedxml/
fi

if [ ! -f $MEMXML2DB_PERL ] ; then
    echo "Cannot find $MEMXML2DB_PERL" >&2
    exit 1
fi

perl $MEMXML2DB_PERL

if [ ! -f $LOAD_PERL ] ; then
    echo "Cannot find $LOAD_PERL" >&2
    exit 1
fi

perl $LOAD_PERL divsxml check
php $CALC_CACHES_PHP