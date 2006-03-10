#!/usr/bin/perl -I ../../loader
# vim:sw=4:ts=4:et:nowrap

use lib "../../scraper/";
use PublicWhip::Error;
use PublicWhip::DB;
my $dbh = PublicWhip::DB::connect();

my $outfile = "votematrix-lords.csv";
print STDERR "opening $outfile\n";
print "Parliament lords\n";
open(STDOUT, "> $outfile");
print "Parliament lords\n";

# Get ids of MPs
my $where = "house = 'lords' and votes_attended > 0 ";
my $limit = "";

my $sth = PublicWhip::DB::query($dbh, "select pw_mp.mp_id, pw_mp.first_name, pw_mp.last_name, pw_mp.party from pw_mp, pw_cache_mpinfo where
    pw_mp.mp_id = pw_cache_mpinfo.mp_id and $where 
    order by pw_mp.last_name, pw_mp.first_name, pw_mp.constituency $limit");
print $sth->rows . " mps\n";
my @mp_ixs;
my %mp_name;
while (my @data = $sth->fetchrow_array())
{
    push @mp_ixs, $data[0];
    $mp_name{$data[0]} = $data[0] . " " . $data[1] . " " . $data[2] . " (" . $data[3] . ")";
}

# Get ids of divisions
my $clause = "where house = 'lords' ";
my $sth = PublicWhip::DB::query($dbh, "select division_id, division_date, division_number from pw_division $clause" .
        " order by division_date desc, division_number desc");
print $sth->rows . " divisions\n";
my @div_ixs;
my %div_name;
while (my @data = $sth->fetchrow_array())
{
    push @div_ixs, $data[0];
    $div_name{$data[0]} = $data[1] . " " . $data[2];
}

# Read all votes in, and make array of MPs and their vote in each division
my $limit = " where (mp_id = " . join(" or mp_id = ", @mp_ixs) . ")";
$limit .= " and (division_id = " . join(" or division_id = ", @div_ixs) . ")";
$sth = PublicWhip::DB::query($dbh, "select division_id, mp_id, vote from pw_vote $limit");
print $sth->rows . " votes\n";
my @votematrix;
while (my @data = $sth->fetchrow_array())
{
    my ($div_dat, $mp_dat, $vote) = @data;
    my $votescore = undef;
    $votescore = 1 if ($vote eq "aye");
    $votescore = 1 if ($vote eq "tellaye");
    $votescore = -1 if ($vote eq "no");
    $votescore = -1 if ($vote eq "tellno");
    $votescore = 0 if ($vote eq "both");
    die "Unexpected $vote voted" if (!defined $votescore);
    
    $votematrix[$mp_dat][$div_dat] += $votescore;
}

# Print out
print ", ";
for my $mp (@mp_ixs)
{
    print $mp_name{$mp} . ", ";
}
print "\n";
for my $div (@div_ixs)
{
    print $div_name{$div} . ", ";
    for my $mp (@mp_ixs)
    {
        if (! defined $votematrix[$mp][$div])
            { print "--"; }
        else
            { print $votematrix[$mp][$div]; }
        print ", ";
    }
    print "\n";
}
print "\n";

