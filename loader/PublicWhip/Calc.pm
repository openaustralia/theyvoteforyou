# $Id: Calc.pm,v 1.11 2006/03/15 17:57:32 frabcus Exp $
# Calculates various data and caches it in the database.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package PublicWhip::Calc;
use strict;

use HTML::TokeParser;
use PublicWhip::Parliaments;
use PublicWhip::Error;
use Data::Dumper;

sub current_rankings {
    my $dbh = shift;

    # Create tables to store in
    PublicWhip::DB::query( $dbh,
        "drop table if exists pw_cache_rebelrank_today" );
    PublicWhip::DB::query(
        $dbh,
        "create table pw_cache_rebelrank_today (
        mp_id int not null,
        rebel_rank int not null,
        rebel_outof int not null,
        index(mp_id)
    );"
    );
    PublicWhip::DB::query( $dbh,
        "drop table if exists pw_cache_attendrank_today" );
    PublicWhip::DB::query(
        $dbh,
        "create table pw_cache_attendrank_today (
            mp_id int not null,
            attend_rank int not null,
            attend_outof int not null,
            index(mp_id)
        );"
    );

    # Select all MPs in force today, and their attendance/rebellions
    my $mps_query_start = "select pw_mp.mp_id as mp_id, 
            round(100*rebellions/votes_attended,2) as rebellions,
            round(100*votes_attended/votes_possible,2) as attendance
            from pw_mp, pw_cache_mpinfo 
            where pw_mp.mp_id = pw_cache_mpinfo.mp_id 
                  and house = 'commons' ";
    my $sth = PublicWhip::DB::query( $dbh, $mps_query_start .
            "and entered_house <= curdate() and curdate() <= left_house");
    if ($sth->rows == 0) {
        $sth = PublicWhip::DB::query( $dbh, $mps_query_start .
            "and left_house = '2005-04-11'");
        if ($sth->rows == 0) {
            PublicWhip::Error::log( "No MPs currently active have been found, change General Election date in code if you are coming up to one", "", ERR_IMPORTANT );
            return;
        }
    }

    # Store their rebellions and divisions for sorting
    my @mpsrebel;
    my %mprebel;
    my @mpsattend;
    my %mpattend;
    while ( my @data = $sth->fetchrow_array() ) {
        my ( $mpid, $rebel, $attend ) = @data;
        if ( defined $rebel ) {
            push @mpsrebel, $mpid;
            $mprebel{$mpid} = $rebel;
        }
        if ( defined $attend ) {
            push @mpsattend, $mpid;
            $mpattend{$mpid} = $attend;
        }
    }

    {

        # Sort, and calculate ranking for rebellions
        @mpsrebel = sort { $mprebel{$b} <=> $mprebel{$a} } @mpsrebel;
        my %mprebelrank;
        my $rank       = 0;
        my $activerank = 0;
        my $prevvalue  = -1;
        for my $mp (@mpsrebel) {
            $rank++;
            $activerank = $rank if ( $mprebel{$mp} != $prevvalue );
            $prevvalue = $mprebel{$mp};
            PublicWhip::Error::log( $mp . " rebel $activerank of " . scalar(@mpsrebel), "", ERR_CHITTER );
            PublicWhip::DB::query(
                $dbh,
"insert into pw_cache_rebelrank_today (mp_id, rebel_rank, rebel_outof)
                values (?, ?, ?)", $mp, $activerank, scalar(@mpsrebel)
            );
        }
    }

    {

        # Sort, and calculate ranking for rebellions
        @mpsattend = sort { $mpattend{$b} <=> $mpattend{$a} } @mpsattend;
        my %mpattendrank;
        my $rank       = 0;
        my $activerank = 0;
        my $prevvalue  = -1;
        for my $mp (@mpsattend) {
            $rank++;
            $activerank = $rank if ( $mpattend{$mp} != $prevvalue );
            $prevvalue = $mpattend{$mp};
            PublicWhip::Error::log(
                $mp . " attend $activerank of " . scalar(@mpsattend),
                "", ERR_CHITTER );
            PublicWhip::DB::query(
                $dbh,
"insert into pw_cache_attendrank_today (mp_id, attend_rank, attend_outof)
                values (?, ?, ?)", $mp, $activerank, scalar(@mpsattend)
            );
        }
    }
}

1;

