#! /usr/bin/perl -w 
use strict;
use lib "../scraper/";

# $Id: cluster-iraq.pl,v 1.1 2003/10/08 11:05:54 frabcus Exp $
# Outputs a matrix of distances between pairs of MPs for
# use by the GNU Octave script mds.m to do clustering.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use db;
my $dbh = db::connect();

# Count MPs (which have voted at least once)
use mpquery;
my $mp_ixs = mpquery::get_mp_ixs($dbh, "votes_attended > 0", "");

# Work out distance metric (for all divisions)
my $metricD = mpquery::vote_distance_metric($dbh, $mp_ixs, "where division_name like '%Iraq%' or division_name like '%1441%'");

# Feed to octave
open(PIPE, ">DN.m");
mpquery::octave_writer(\*PIPE, $dbh, $mp_ixs, $metricD);
system("octave --silent mds.m");

