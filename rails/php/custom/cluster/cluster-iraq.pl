#! /usr/bin/perl -w 
use strict;
use lib "../scraper/";

# $Id: cluster-iraq.pl,v 1.1 2005/03/28 14:26:32 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use error;
use db;
my $dbh = db::connect();

# Count MPs (which have voted at least once)
use mpquery;
my $mp_ixs = mpquery::get_mp_ixs($dbh, "entered_house >= '2001-06-07' and votes_attended > 0", "");

# Work out distance metric (for all divisions)
my $metricD = mpquery::vote_distance_metric($dbh, $mp_ixs, "where division_name like '%Iraq%' or division_name like '%1441%'");

# Feed to octave
open(PIPE, ">DN.m");
mpquery::octave_writer(\*PIPE, $dbh, $mp_ixs, $metricD);
system("octave --silent mds.m");

rename "mpcoords.txt", "mpcoords-iraq.txt"

