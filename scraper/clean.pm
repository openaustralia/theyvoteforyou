# $Id: clean.pm,v 1.2 2003/09/17 15:28:40 frabcus Exp $
# Integrety checking and tidying of database.  Lots of this wouldn't be
# needed with transactions.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package clean;
use strict;
use error;

sub erase_duff_divisions
{
    my $dbh = shift;
    db::query($dbh, "update pw_debate_content, pw_division set divisions_extracted = 0 
        where pw_division.valid = 0 and pw_division.division_date = pw_debate_content.day_date");
    db::query($dbh, "delete pw_vote from pw_division, pw_vote where
        pw_division.division_id = pw_vote.division_id and pw_division.valid
        = 0");
    db::query($dbh, "delete from pw_division where pw_division.valid = 0");
}

sub fix_division_corrections
{
    my $dbh = shift;
    fix_division_correction($dbh, 309, "2003-09-15", "2003-09-16");
    fix_division_correction($dbh, 99, "2003-03-04", "2003-03-06");
    fix_division_correction($dbh, 329, "2002-10-23", "2002-10-28");
}

sub fix_division_correction
{
    my $dbh = shift;
    my $num = shift;
    my $date_orig = shift;
    my $date_correction = shift;

    # Read useful data from correction
    my $sth = db::query($dbh, "select division_id, source_url from pw_division where division_number = ?
        and division_date = ?", $num, $date_correction);
    return if $sth->rows == 0; # must have already done
    error::die("More than one division $num", $date_correction) if $sth->rows > 1;
    my ($id_correction, $source_url) = @{$sth->fetchrow_arrayref()};
    # Read useful data from division
    $sth = db::query($dbh, "select division_id from pw_division where division_number = ?
        and division_date = ?", $num, $date_orig);
    return if $sth->rows == 0; # must have already done
    error::die("More than one division $num", $date_orig) if $sth->rows > 1;
    my ($id_orig) = $sth->fetchrow_arrayref()->[0];

    # Copy URL of correction into original, to leave audit trail
    my $corrected_text = "<p>Note:  This division was
        corrected on $date_correction, <a href=\"$source_url\">see the
        correction in Hansard</a>.";
    db::query($dbh, "update pw_division set notes = concat(notes, ?) where division_number = ?
        and division_date = ?", $corrected_text, $num, $date_orig);
    error::die("Wrong number of rows applying division correction " . $sth->rows, $date_orig) if $sth->rows != 1;

    # Rename voting record
    db::query($dbh, "delete pw_vote from pw_vote where division_id = ?", $id_orig);
    db::query($dbh, "update pw_vote set division_id = ? where division_id = ?", $id_orig, $id_correction);
     
    # Delete correction
    db::query($dbh, "delete from pw_division where division_id = ?" , $id_correction);

    error::log("Corrected division $num $date_orig with data from $date_correction", "", error::IMPORTANT);
}

sub check_integrity
{
    my $dbh = shift;

    # Check all divisions are present in sequence
    my $sth = db::query($dbh, "select division_date, division_number from pw_division order by division_date, division_number");
    my $prev_number = 0;
    my $prev_date = "the-start-of-time";
    while (my @data = $sth->fetchrow_array())
    {
        my ($date, $number) = @data;
        if (($number != $prev_number + 1) and ($number != 1))
        {
            error::warn("Missing/repeat division after $prev_number $prev_date, before $number $date", "");
        }
        $prev_number = $number;
        $prev_date = $date; 
    }
    
    # Check there aren't divisions in the future
    $sth = db::query($dbh, "select * from pw_division where division_date > current_date()");
    error::warn("Database contains " . $sth->rows . " division(S) in the future!", "") if ($sth->rows > 0);

    # Check nobody voted when they were not in the house (e.g. dead)
    # TODO Find a way of expressing this query without it overloading # db!
#    $sth = db::query($dbh, "select pw_mp.mp_id from pw_vote, pw_mp,pw_division where pw_vote.mp_id = pw_mp.mp_id and pw_vote.division_id = pw_division.division_id and division_date < entered_house or division_date > left_house");
 #   error::warn("Database contains " . $sth->rows . " MPs who voted when they were not in the house!", "") if ($sth->rows > 0);
}

1;
