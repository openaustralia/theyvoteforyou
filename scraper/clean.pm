# $Id: clean.pm,v 1.4 2003/10/27 09:36:41 frabcus Exp $
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

# An MP can vote both aye and no in the same division
# See under "Abstention" here: http://www.parliament.uk/documents/upload/p09.pdf
sub fix_bothway_voters
{
    my $dbh = shift;

    my $sth = db::query($dbh, "select a.mp_id, a.division_id, a.vote, b.vote from pw_vote as a, pw_vote as b where 
        a.mp_id = b.mp_id and a.division_id = b.division_id and a.vote < b.vote"); # use < so only get the asymmetric half o entries
    while (my @data = $sth->fetchrow_array())
    {
        my ($mp_id, $division_id) = @data;
        my $sth2 = db::query($dbh, "update pw_vote set vote = 'both' where mp_id = ? and division_id = ? and vote = ?",
            $mp_id, $division_id, "aye");
        error::die("Unexpectedly altered " . $sth2->rows . " fixing bothway votes aye", "$division_id $mp_id") if ($sth2->rows != 1);
        $sth2 = db::query($dbh, "delete from pw_vote where mp_id = ? and division_id = ? and vote = ?",
            $mp_id, $division_id, "no");
        error::die("Unexpectedly altered " . $sth2->rows . " fixing bothway votes no", "$division_id $mp_id") if ($sth2->rows != 1);
    }
    error::log("Fixed up " . $sth->rows . " bothway votes", "", error::IMPORTANT) if ($sth->rows > 0);
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
    
    # Check no two MPs were in the same constituency at the same time
    $sth = db::query($dbh, "select a.mp_id, b.mp_id, a.entered_house,
        a.left_house, b.entered_house, b.left_house, a.constituency from
        pw_mp as a, pw_mp as b where a.constituency = b.constituency and
        a.mp_id <> b.mp_id and ( (a.entered_house <= b.left_house and
        a.left_house >= b.entered_house) or (b.entered_house <=
        a.left_house and b.left_house >= a.entered_house))");
    error::warn("Database contains " . $sth->rows . " MPs in the same constituency at the same time", "") if ($sth->rows > 0);
    
    # Check there aren't divisions in the future
    $sth = db::query($dbh, "select * from pw_division where division_date > current_date()");
    error::warn("Database contains " . $sth->rows . " division(s) in the future!", "") if ($sth->rows > 0);

    # Check nobody voted when they were not in the house (e.g. dead)
    $sth = db::query($dbh, "select pw_mp.mp_id from pw_vote, pw_mp,pw_division where pw_vote.mp_id = pw_mp.mp_id and pw_vote.division_id = pw_division.division_id and (division_date < entered_house or division_date > left_house)");
    error::warn("Database contains " . $sth->rows . " MP(s) who voted when they were not in the house!", "") if ($sth->rows > 0);
}

1;
