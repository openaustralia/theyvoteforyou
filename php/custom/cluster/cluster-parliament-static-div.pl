#! /usr/bin/perl -w 
use strict;
use lib "../../loader/";

# $Id: cluster-parliament-static-div.pl,v 1.5 2006/08/01 06:21:00 publicwhip Exp $
# Outputs a matrix of distances between pairs of divisions for
# use by the GNU Octave script mds.m to do clustering.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use PublicWhip::Error;
use PublicWhip::DB;
my $dbh = PublicWhip::DB::connect();

use divquery;

# error::setverbosity(error::CHITTER);

# Load data of distance between divisions
my $metricD;
my $where = "";#" and division_id > 19379 ";
my $where2 = "";#" and division_id2 > 19379 ";
my $sth = PublicWhip::DB::query($dbh, "select division_id, division_id2, distance from pw_cache_divdiv_distance where division_id <= division_id2 $where $where2");
while ( my @data = $sth->fetchrow_array() ) {
    my ( $division_id, $division_id2, $distance ) = @data;
    $$metricD[$division_id][$division_id2] = $distance;
}
my $div_ixs = divquery::get_div_ixs($dbh, $where);

# Feed to octave
open(PIPE, ">DN.m");
divquery::octave_writer(\*PIPE, $dbh, $div_ixs, $metricD);
undef $metricD;
#system("octave mds.m");
system("octave --silent mds.m");
rename "out.txt", "divcoords.txt";


