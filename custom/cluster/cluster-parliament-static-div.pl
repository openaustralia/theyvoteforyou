#! /usr/bin/perl -w 
use strict;
use lib "../scraper/";

# $Id: cluster-parliament-static-div.pl,v 1.1 2005/03/28 14:26:32 frabcus Exp $
# Outputs a matrix of distances between pairs of divisions for
# use by the GNU Octave script mds.m to do clustering.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use error;
use db;
my $dbh = db::connect();

# error::setverbosity(error::CHITTER);

# Wipe metric database
db::query($dbh, "drop table if exists pw_cache_divdist");
db::query($dbh, 
"create table pw_cache_divdist (
    div_id_1 int not null,
    div_id_2 int not null,
    distance float not null,
    unique(div_id_1, div_id_2)
);");

use parliaments;
foreach my $parliament (@parliaments::list)
{
    # Count divisions 
    use divquery;
    my $div_ixs = divquery::get_div_ixs($dbh, 
    "division_date >= '" . $$parliament{'from'} . "' and division_date <= '" . $$parliament{'to'} . "'",
        "");

    # Work out distance metric 
    my $metricD = divquery::rebel_distance_metric($dbh, $div_ixs, 
        "votes_attended > 0 and " .
        "entered_house >= '" . $$parliament{'from'} . "' and entered_house <= '" . $$parliament{'to'} . "'");

    # Store in database, for use by website (friends list)
    for my $div_1 (@$div_ixs)
    {
        for my $div_2 (@$div_ixs)
        {
            # Only do half triangle
            next if $div_1 > $div_2;
            
            my $distance = $$metricD[$div_1][$div_2];
            db::query($dbh, "insert into pw_cache_divdist (div_id_1, div_id_2, distance) values (?, ?, ?)",
                $div_1, $div_2, $distance);

            # Add both halves of triangle to database, as then a lot quicker to do queries
            if ($div_1 != $div_2)
            {
                db::query($dbh, "insert into pw_cache_divdist (div_id_1, div_id_2, distance) values (?, ?, ?)",
                    $div_2, $div_1, $distance);
            }
        }
    }

    # Feed to octave
#    open(PIPE, ">DN.m");
#    divquery::octave_writer(\*PIPE, $dbh, $mp_ixs, $metricD);
#    system("octave --silent mds.m");
#    rename "mpcoords.txt", "mpcoords-" . $$parliament{'id'} . ".txt";
}


