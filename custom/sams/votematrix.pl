#!/usr/bin/perl
# vim:sw=4:ts=4:et:nowrap

# Creates a Tab Seperated file for reading into analysis packages such
# as SPSS/Stata or reading into databases for other analsyses.

# Original by Francis Irving
# Many modifications by Sam Smith  S@mSmith.net

use strict;
use warnings;
use lib "../../loader/";
use PublicWhip::Error;
use PublicWhip::DB;
use PublicWhip::Parliaments;
use DBI;
my $dbh = PublicWhip::DB::connect();

my %Output_Values;
$Output_Values{missing}='-9';
$Output_Values{tellaye}='1';
$Output_Values{aye}=    '2';
$Output_Values{both}=   '3';
$Output_Values{no}=     '4';
$Output_Values{tellno}= '5';

foreach my $parliament (&PublicWhip::Parliaments::getlist())
{
    my $outfile = "votematrix-" . $$parliament{'name'} ;

    open(OUT , "> $outfile.dat") || die "can't open $outfile.dat:$!";
    open(METADATA, "> $outfile.txt") || die "can't open $outfile.txt:$!";
    print METADATA "file: $outfile.csv covering $$parliament{'name'}\n";
    print METADATA "file created: " . scalar localtime() . "by http://www.publicwhip.org.uk/\n";
    # Get ids of MPs
    my $where = "votes_attended > 0 and " .
        "entered_house >= '" . $$parliament{'from'} . "' and entered_house <= '" . $$parliament{'to'} . "'";
    my $limit = "";

    my $mp_query = PublicWhip::DB::query($dbh, "select pw_mp.mp_id, pw_mp.first_name, pw_mp.last_name, pw_mp.party from pw_mp, pw_cache_mpinfo where
        pw_mp.mp_id = pw_cache_mpinfo.mp_id and $where 
        order by pw_mp.last_name, pw_mp.first_name, pw_mp.constituency $limit");
    print METADATA $mp_query->rows . " mps\n";
    my @mp_ixs;
    my %mp_name;
    # Get ids of divisions
    my $clause = "where division_date >= '" . $$parliament{'from'} . "' and division_date <= '" . $$parliament{'to'} . "'";
    my $vote_query= PublicWhip::DB::query($dbh, "select division_id, division_date, division_number, division_name from pw_division $clause" .
            " order by division_date desc, division_number desc");

    print METADATA $vote_query->rows . " divisions\n";
    print METADATA "\n\n\n";
    print METADATA "Variables match to MP names as mpidXXX where XXX is the mpid number below\n\n";
    print METADATA "mpid\tfirstname\tsurname\tparty\tPublicWhip URL\n";

    while (my @data = $mp_query->fetchrow_array())
    {
        push @mp_ixs, $data[0];
        #$mp_name{$data[0]} = $data[0] . " " . $data[1] . " " . $data[2] . " (" . $data[3] . ")";
        $mp_name{$data[0]} = "mpid$data[0]\t$data[3]";
        print METADATA $data[0] . "\t" . $data[1] . "\t" . $data[2] . "\t" . $data[3] .
        "\thttp://publicwhip.com/mp.php?mpid=$data[0]\n";
    }

    my @div_ixs;
    my %div_name;
    while (my @data = $vote_query->fetchrow_array())
    {
        push @div_ixs, $data[0];
        $data[3]=~ s/&#8212;/-/g;
        $div_name{$data[0]} = $data[1] . " " . $data[2] . "\t" . $data[3];
    }

    $limit=""; # reset limit from use above
    my @data;
    my ($div_dat, $mp_dat, $vote);
    my @votematrix;
    foreach my $division (@div_ixs) { #iterate over divisions, and select each one individually
        $vote_query = PublicWhip::DB::query($dbh, "select division_id, mp_id, vote from pw_vote where division_id=$division ");
        while (($div_dat, $mp_dat, $vote) = $vote_query->fetchrow_array()){
            my $votescore = undef;
            $votescore = $Output_Values{$vote};
            die "Unexpected $vote voted" if (!defined $votescore);
            $votematrix[$mp_dat][$div_dat] = $votescore;
       } 
    }

    # Print out
    print OUT "rowid\tdate\tvoteno\tparty\t";
    for my $mp (sort {$a <=>$b} @mp_ixs) # XXX mp_ixs MUST always be sorted
    {
        print OUT $mp_name{$mp} . "\t ";
    }
    print OUT "\n";
    my $rowid=1;
    for my $div (@div_ixs)
    {
        print OUT "$rowid\t";
        $rowid++;
        #print OUT $div_name{$div} . "\t ";
        my $name= $div_name{$div};
        $name =~s# #\t#; # date [space] vote [tab] name
        print OUT "$name\t";

        for my $mp (sort  {$a <=>$b} @mp_ixs) # XXX mp_ixs MUST always be sorted
        {
            if (! defined $votematrix[$mp][$div]) { print OUT $Output_Values{"missing"}; }
            else { print OUT $votematrix[$mp][$div]; }
            print OUT "\t ";
        }
        print OUT "\n";
    }
    print OUT "\n";
    print METADATA "\n\n\n\n";

    close (OUT);
    close (METADATA);
}

