#!/bin/sh
# Fetches the required xml data from data.openaustralia.org
# and feeds it into the database via the perl scripts

set -e

MEMXML2DB_PERL=memxml2db.pl
LOAD_PERL=load.pl
CALC_CACHES_PHP=calc_caches.php
MP_DISTANCE_PHP=mp_distance.php
SCRAPED_XML_DOWNLOAD_PATTERN="2009-11-*.xml"

while getopts ":eh" option; do
    case $option in
        e)
            SCRAPED_XML_DOWNLOAD_PATTERN="*.xml"
            ;;

        h)
            echo "Downloads a small sample of data from data.openaustralia.org and inserts it into the publicwhip database."
            echo "Usage: $0 [OPTION]"
            echo "Options:"
            echo "-e    download all data, not just a small sample"
            echo "-h    print this help"
            exit 0
            ;;

        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
    esac
done

if [ ! -d data.openaustralia.org/members ] ; then
    # ~2MB download as of June 2014
    wget -r -np -A *.xml data.openaustralia.org/members/
fi

if [ ! -d data.openaustralia.org/scrapedxml ] ; then
    #  ~15MB for partial download
    # ~700MB for full download as of June 2014
    wget -r -np -A "$SCRAPED_XML_DOWNLOAD_PATTERN" data.openaustralia.org/scrapedxml/
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
php $MP_DISTANCE_PHP
