#! /usr/bin/perl -w 
use strict;

# $Id: cluster-parliament-static.pl,v 1.2 2003/10/03 21:46:10 frabcus Exp $
# Outputs a matrix of distances between pairs of MPs for
# use by the GNU Octave script mds.m to do clustering.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require "../scraper/error.pm";
require "../scraper/db.pm";
my $dbh = db::connect();

# Count MPs (which have voted at least once)
require "mpquery.pm";
my $mp_ixs = mpquery::get_mp_ixs($dbh, "votes_attended > 0", "");

# Work out distance metric (for all divisions)
my $metricD = mpquery::vote_distance_metric($dbh, $mp_ixs, "");

# Store in database, for use by website (friends list)
db::query($dbh, "drop table if exists pw_cache_mpdist");
db::query($dbh, 
"create table pw_cache_mpdist (
    mp_id_1 int not null,
    mp_id_2 int not null,
    distance float not null,
    unique(mp_id_1, mp_id_2)
);");
for my $mp_1 (@$mp_ixs)
{
    for my $mp_2 (@$mp_ixs)
    {
        # Only do half triangle
        next if $mp_1 > $mp_2;

        my $distance = $$metricD[$mp_1][$mp_2];
        db::query($dbh, "insert into pw_cache_mpdist (mp_id_1, mp_id_2, distance) values (?, ?, ?)",
            $mp_1, $mp_2, $distance);
    }
}

# Feed to octave
open(PIPE, ">DN.m");
mpquery::octave_writer(\*PIPE, $dbh, $mp_ixs, $metricD);
system("octave --silent mds.m");

