# $Id: Calc.pm,v 1.9 2006/02/16 12:58:19 publicwhip Exp $
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

sub count_mp_info {
    my $dbh = shift;
    count_mp_info_dated( $dbh, "1000-01-01", "9999-12-31", "pw_cache_mpinfo", undef );
}

sub count_mp_info_session2002 {
    my $dbh = shift;
    count_mp_info_dated( $dbh, "2002-11-13", "2003-11-20",
        "pw_cache_mpinfo_session2002", "commons" );
}

sub count_mp_info_dated {
    my $dbh   = shift;
    my $from  = shift;
    my $to    = shift;
    my $table = shift;
    my $house = shift;

    PublicWhip::DB::query( $dbh, "drop table if exists $table" );
    PublicWhip::DB::query(
        $dbh,
        "create table $table (
        mp_id int not null,
        rebellions int not null,
        tells int not null,
        votes_attended int not null,
        votes_possible int not null,
        index(mp_id)
    );"
    );

    my @params = ($from, $to, $from, $to, $from, $to);
    push @params, $house if $house;
    my $sth = PublicWhip::DB::query(
        $dbh, "select mp_id, party, entered_house, left_house 
        from pw_mp where 
            ((entered_house >= ? and entered_house <= ?) or
            (left_house >= ? and left_house <= ?) or
            (entered_house < ? and left_house > ?))".
            ($house ? " and house = ?" : ""),
        @params
    );

    while ( my @data = $sth->fetchrow_array() ) {
        my ( $mpid, $party, $entered_house, $left_house ) = @data;

        my $sth = PublicWhip::DB::query(
            $dbh, "select pw_vote.division_id, pw_vote.vote, pw_cache_whip.whip_guess 
            from pw_cache_whip, pw_vote, pw_division 
            where pw_cache_whip.party = ? and pw_cache_whip.division_id = pw_vote.division_id 
                and pw_vote.mp_id = ?  and pw_cache_whip.whip_guess <> 'unknown'
                and pw_vote.vote <> 'both' 
                and pw_cache_whip.whip_guess <> replace(pw_vote.vote, 'tell', '') 
                and pw_division.division_id = pw_vote.division_id 
                and (division_date >= ? and division_date <= ?)
            ", $party, $mpid, $from, $to
        );
        my $rebel_count = $sth->rows;

        $sth = PublicWhip::DB::query(
            $dbh, " select pw_vote.division_id, vote
            from pw_vote, pw_division where mp_id = ? 
            and (vote = 'tellaye' or vote = 'tellno') and
			pw_division.division_id = pw_vote.division_id and
			(division_date >= ? and division_date <= ?)
			", $mpid, $from, $to
        );
        my $tell_count = $sth->rows;

        $sth = PublicWhip::DB::query(
            $dbh, "select count(*) from pw_vote,
			pw_division where mp_id = $mpid
			and pw_division.division_id = pw_vote.division_id and
			(division_date >= ? and division_date <= ?)
			", $from, $to
        );
        die "Failed to get vote count" if $sth->rows != 1;
        my $votes = $sth->fetchrow_arrayref()->[0];

        $sth = PublicWhip::DB::query(
            $dbh, "select count(*) from pw_division
            where division_date >= ? and division_date <= ?
			and division_date >= ? and division_date <= ?",
            $entered_house, $left_house, $from, $to
        );
        die "Failed to get division count" if $sth->rows != 1;
        my $divisions = $sth->fetchrow_arrayref()->[0];

        #        print "MP $mpid $party $rebel_count\n";

        PublicWhip::DB::query(
            $dbh, "insert into $table (mp_id, rebellions,
        tells, votes_attended, votes_possible)
            values (?, ?, ?, ?, ?)", $mpid, $rebel_count, $tell_count, $votes,
            $divisions
        );
    }
}

sub count_division_info {
    my $dbh = shift;

    PublicWhip::DB::query( $dbh, "drop table if exists pw_cache_divinfo" );
    PublicWhip::DB::query(
        $dbh,
        "create table pw_cache_divinfo (
        division_id int not null,
        rebellions int not null,
        turnout int not null,
        index(division_id)
    );"
    );

    my $sth =
      PublicWhip::DB::query( $dbh, "select division_id from pw_division" );
    while ( my @data = $sth->fetchrow_array() ) {
        my ($division_id) = @data;

        my $sth = PublicWhip::DB::query(
            $dbh, "select count(*) from pw_vote,
            pw_cache_whip, pw_mp where pw_vote.division_id = ? and
            pw_cache_whip.division_id = ? and 
            pw_mp.party = pw_cache_whip.party and 
            pw_vote.mp_id = pw_mp.mp_id and 
            pw_cache_whip.whip_guess <> 'unknown' and 
            pw_vote.vote <> 'both' and
            pw_cache_whip.whip_guess <> replace(pw_vote.vote, 'tell', '')
            ", $division_id, $division_id
        );

        die "Failed to count rebels for div $division_id" if $sth->rows != 1;
        my $rebellions = $sth->fetchrow_arrayref()->[0];

        $sth = PublicWhip::DB::query(
            $dbh, "select count(*) from pw_vote
            where pw_vote.division_id = ?", $division_id
        );
        my $turnout = $sth->fetchrow_arrayref()->[0];

        #        print "division $division_id $rebellions\n";

        PublicWhip::DB::query(
            $dbh,
            "insert into pw_cache_divinfo (division_id, rebellions, turnout)
            values (?, ?, ?)", $division_id, $rebellions, $turnout
        );
    }
}

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
            PublicWhip::Error::log( $mp . " rebel $activerank of " . $#mpsrebel, "", ERR_CHITTER );
            PublicWhip::DB::query(
                $dbh,
"insert into pw_cache_rebelrank_today (mp_id, rebel_rank, rebel_outof)
                values (?, ?, ?)", $mp, $activerank, $#mpsrebel
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
                $mp . " attend $activerank of " . $#mpsattend,
                "", ERR_CHITTER );
            PublicWhip::DB::query(
                $dbh,
"insert into pw_cache_attendrank_today (mp_id, attend_rank, attend_outof)
                values (?, ?, ?)", $mp, $activerank, $#mpsattend
            );
        }
    }
}

1;

