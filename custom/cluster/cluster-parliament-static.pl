#! /usr/bin/perl -w 
use strict;
use lib "../../loader/";

# $Id: cluster-parliament-static.pl,v 1.3 2005/11/03 09:45:25 theyworkforyou Exp $
# Outputs a matrix of distances between pairs of MPs for
# use by the GNU Octave script mds.m to do clustering.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use PublicWhip::Error;
use PublicWhip::DB;
use PublicWhip::Parliaments;
my $dbh = PublicWhip::DB::connect();

# error::setverbosity(error::CHITTER);

# Wipe metric database
PublicWhip::DB::query($dbh, "drop table if exists pw_cache_mpdist");
PublicWhip::DB::query($dbh, 
"create table pw_cache_mpdist (
    mp_id_1 int not null,
    mp_id_2 int not null,
    distance float not null,
    unique(mp_id_1, mp_id_2)
);");

foreach my $parliament (@PublicWhip::Parliaments::list)
{
    print "parliament ".$$parliament{'name'}."\n";
    # Count MPs (which have voted at least once)
    use mpquery;
    my $mp_ixs = mpquery::get_mp_ixs($dbh, "votes_attended > 0 and " .
        "entered_house >= '" . $$parliament{'from'} . "' and entered_house <= '" . $$parliament{'to'} . "'",
        "");

    # Work out distance metric (for all divisions)
    my $metricD = mpquery::vote_distance_metric($dbh, $mp_ixs, "where division_date >= '" . $$parliament{'from'}
     . "' and division_date <= '" . $$parliament{'to'} . "'");

    # Store in database, for use by website (friends list)
    for my $mp_1 (@$mp_ixs)
    {
        for my $mp_2 (@$mp_ixs)
        {
            # Only do half triangle
            next if $mp_1 > $mp_2;
            
            my $distance = $$metricD[$mp_1][$mp_2];
            PublicWhip::DB::query($dbh, "insert into pw_cache_mpdist (mp_id_1, mp_id_2, distance) values (?, ?, ?)",
                $mp_1, $mp_2, $distance);

            # Add both halves of triangle to database, as then a lot quicker to do queries
            if ($mp_1 != $mp_2)
            {
                PublicWhip::DB::query($dbh, "insert into pw_cache_mpdist (mp_id_1, mp_id_2, distance) values (?, ?, ?)",
                    $mp_2, $mp_1, $distance);
            }
        }
    }

    # Feed to octave
    open(PIPE, ">DN.m");
    mpquery::octave_writer(\*PIPE, $dbh, $mp_ixs, $metricD);
    system("octave --silent mds.m");
    rename "mpcoords.txt", "mpcoords-" . $$parliament{'id'} . ".txt";
}


