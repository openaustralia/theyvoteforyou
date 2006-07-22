#! /usr/bin/perl -w 
use strict;
use lib "../../loader/";

# $Id: cluster-parliament-static.pl,v 1.9 2006/07/22 12:38:20 publicwhip Exp $
# Outputs a matrix of distances between pairs of MPs/Lords for
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

# Lords, do in one clump
{
    print "clustering lords\n";
    # Count Lords (which have voted at least once)
    use mpquery;
    my $mp_ixs = mpquery::get_mp_ixs($dbh, "votes_attended > 0 and house = 'lords'", "",
        "concat(pw_mp.first_name, substring(pw_mp.last_name, 4))"); # substring to remove "of "

    # Work out distance metric (for all divisions)
    my $metricD = mpquery::vote_metric_from_db($dbh, $mp_ixs);

    # Feed to octave
    open(PIPE, ">DN.m");
    mpquery::octave_writer(\*PIPE, $dbh, $mp_ixs, $metricD);
    system("octave --silent mds.m");
    rename "out.txt", "lordcoords.txt";
}

# Commons, do per parliament
foreach my $parliament (@PublicWhip::Parliaments::list)
{
    print "clustering commons parliament ".$$parliament{'name'}."\n";
    # Count MPs (which have voted at least once)
    use mpquery;
    my $mp_ixs = mpquery::get_mp_ixs($dbh, "votes_attended > 0 and " .
        "entered_house >= '" . $$parliament{'from'} . "' and entered_house <= '" . $$parliament{'to'} . "'
        and house = 'commons'",
        "", "pw_mp.last_name, pw_mp.first_name, pw_mp.constituency");

    # Work out distance metric (for all divisions)
    my $metricD = mpquery::vote_metric_from_db($dbh, $mp_ixs);

    # Feed to octave
    open(PIPE, ">DN.m");
    mpquery::octave_writer(\*PIPE, $dbh, $mp_ixs, $metricD);
    system("octave --silent mds.m");
    rename "out.txt", "mpcoords-" . $$parliament{'id'} . ".txt";
}


