# $Id: Clean.pm,v 1.16 2006/10/18 12:45:50 publicwhip Exp $
# Integrety checking and tidying of database.  Lots of this wouldn't be
# needed with transactions.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package PublicWhip::Clean;
use strict;
use PublicWhip::Error;

sub erase_duff_divisions {
    my $dbh = shift;
    my $sth = PublicWhip::DB::query($dbh, "select pw_vote.division_id, pw_vote.mp_id from 
        pw_vote left join pw_division on
        pw_division.division_id = pw_vote.division_id where
        (pw_division.valid = 0 or pw_division.valid is null)");
    while ( my @data = $sth->fetchrow_array() ) {
        my ( $division_id, $mp_id ) = @data;
        PublicWhip::DB::query($dbh, "delete from pw_vote where division_id = ? and mp_id = ?", $division_id, $mp_id);
    }

    PublicWhip::DB::query( $dbh,
        "delete from pw_division where pw_division.valid = 0" );
}

# An MP can vote both aye and no in the same division
# See under "Abstention" here: http://www.parliament.uk/documents/upload/p09.pdf
sub fix_bothway_voters {
    my $dbh = shift;

    my $sth = PublicWhip::DB::query(
        $dbh,
"select a.mp_id, a.division_id, a.vote, b.vote from pw_vote as a, pw_vote as b where 
        a.mp_id = b.mp_id and a.division_id = b.division_id and a.vote < b.vote"
    );    # use < so only get the asymmetric half of entries
    while ( my @data = $sth->fetchrow_array() ) {
        my ( $mp_id, $division_id, $a_vote, $b_vote ) = @data;
        if ( $a_vote ne "aye" || $b_vote ne "no" ) {
# TODO: Reenable this warning, and work out what to do with them (I think they
# may need merging together, and so be slightly preturbing attendance figures)
#            PublicWhip::Error::warn(
#                "Voted twice but not aye/no pair; they are $a_vote/$b_vote",
#                "$division_id $mp_id" );
        }
        else {
            my $sth2 = PublicWhip::DB::query(
                $dbh,
"update pw_vote set vote = 'both' where mp_id = ? and division_id = ? and vote = ?",
                $mp_id,
                $division_id,
                "aye"
            );
            PublicWhip::Error::die(
                "Unexpectedly altered "
                  . $sth2->rows
                  . " fixing bothway votes aye",
                "$division_id $mp_id"
              )
              if ( $sth2->rows != 1 );
            $sth2 = PublicWhip::DB::query(
                $dbh,
"delete from pw_vote where mp_id = ? and division_id = ? and vote = ?",
                $mp_id,
                $division_id,
                "no"
            );
            PublicWhip::Error::die(
                "Unexpectedly altered "
                  . $sth2->rows
                  . " fixing bothway votes no",
                "$division_id $mp_id"
              )
              if ( $sth2->rows != 1 );
        }
    }
    PublicWhip::Error::log( "Fixed up " . $sth->rows . " bothway votes",
        "", ERR_USEFUL )
      if ( $sth->rows > 0 );
}

sub check_integrity {
    my $dbh = shift;
    my $from = shift;
    my $to   = shift;

    my $where = "division_date >= '$from' and division_date <= '$to'";

    # Check deferred divisions
    my $sth = PublicWhip::DB::query(
        $dbh, "select division_date, division_number, division_name,
        count(*) from pw_vote, pw_division where
        (vote = 'tellaye' or vote = 'tellno') and
        pw_vote.division_id = pw_division.division_id and $where group by pw_vote.division_id"
    );
    while ( my @data = $sth->fetchrow_array() ) {
        my ( $date, $number, $name, $count ) = @data;
        if ( $count != 0 && $count != 4 ) {
            # TODO: Reenable this check
            #PublicWhip::Error::warn( "Teller count " . $count . " in division",
            #    "$date no. $number $name" );
        }
        else {

            # Division no. 7 at the start of the 2001 parliament is
            # actually about deferred divisions and title "Deferred
            # Divisions", but is itself not a deferred division!  Hence
            # the second clause in the following if.
            my $deferred =
              (       $name =~ m/Deferred Division/
                  and $name ne "Deferred Divisions" );
            if ( $deferred && $count != 0 ) {
                PublicWhip::Error::warn(
                    "Tellers in deferred division!",
                    "$date no. $number $name"
                );
            }
            if ( !$deferred && $count != 4 ) {
                PublicWhip::Error::warn( "No tellers in non-deferred division",
                    "$date no. $number $name" );
            }
        }
    }

    # Check all divisions are present in sequence for Commons
    $sth = PublicWhip::DB::query( $dbh,
"select division_date, division_number from pw_division where $where and house = 'commons' order by
division_date, division_number"
    );
    my $prev_number = 0;
    my $prev_date   = "the-start-of-time";
    while ( my @data = $sth->fetchrow_array() ) {
        my ( $date, $number ) = @data;
        if ( ( $number != $prev_number + 1 ) and ( $number != 1 ) ) {
            PublicWhip::Error::warn(
"Missing/repeat division after $prev_number $prev_date, before $number $date",
                ""
            );
        }
        $prev_number = $number;
        $prev_date   = $date;
    }

    # Check no two MPs were in the same constituency at the same time
    $sth = PublicWhip::DB::query(
        $dbh, "select a.mp_id, b.mp_id, a.entered_house,
            a.left_house, b.entered_house, b.left_house, a.constituency 
        from pw_mp as a, pw_mp as b 
        where a.constituency = b.constituency
            and a.mp_id <> b.mp_id 
            and ( (a.entered_house <= b.left_house and a.left_house >= b.entered_house) 
                or (b.entered_house <= a.left_house and b.left_house >= a.entered_house))
            and a.house = 'commons'
            and b.house = 'commons'
        "
    );
    PublicWhip::Error::warn(
        "Database contains "
          . $sth->rows
          . " MPs in the same constituency at the same time",
        ""
      ) if $sth->rows;

    # Check there aren't divisions in the future
    $sth =
      PublicWhip::DB::query( $dbh,
        "select * from pw_division where division_date > current_date()" );
    PublicWhip::Error::warn(
        "Database contains " . $sth->rows . " division(s) in the future!", "" )
      if $sth->rows;

    # Check nobody voted when they were not in the house (e.g. dead)
    $nobody_query = "select pw_mp.mp_id, pw_mp.house, pw_mp.first_name, pw_mp.last_name, 
                pw_division.division_date, pw_division.division_number
        from pw_vote, pw_mp,pw_division 
        where pw_vote.mp_id = pw_mp.mp_id 
            and pw_vote.division_id = pw_division.division_id and 
            (division_date < entered_house or division_date > left_house)"
    $sth = PublicWhip::DB::query($dbh, $nobody_query);
    PublicWhip::Error::warn(
        "Database contains "
          . $sth->rows
          . " member(s) who voted when they were not in the house!"
          . "\n\n" . $nobody_query,
        ""
      ) if $sth->rows;
}

1;
