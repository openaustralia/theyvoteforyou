# $Id: mplist.pm,v 1.1 2003/08/14 19:35:48 frabcus Exp $
# Parses lists of MPs, adds them to database.  Also has
# special code to add in midterm changes such as bielections, 
# party loyalty switching etc.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package mplist;
use strict;

use HTML::TokeParser;
use db;
use mputils;

sub insert_mps
{
    my $dbh = shift;

    my $p = HTML::TokeParser->new("../rawdata/Members2001.htm");
    my $updated;

    # Find start of main table of MPs
    while (my $token = $p->get_tag("tr")) 
    {
        $_ = $p->get_tag("td");
        $_ = $p->get_trimmed_text("/td");
        last if (m/^Member$/);
    }
    $_ = $p->get_tag("/tr");

    # Parse main table of MPs
    while (1) 
    {
        my $token = $p->get_tag("td");
        my $name = $p->get_trimmed_text("/td");
        $token = $p->get_tag("td");
        my $constituency = $p->get_trimmed_text("/td");
        $token = $p->get_tag("td");
        my $party = $p->get_trimmed_text("/td");

        next if $name eq "";
        last if $name =~ m/Where can I find\.\.\./;
        
        my ($firstname, $lastname, $title, $dummy) = mputils::parse_formal_name($name . " (dummy)");
        $title = "" if !$title;
        $party = "LDem" if $party eq "LD";

        db::query($dbh, "insert into pw_mp (first_name, last_name, 
            title, constituency, party) values (?, ?, ?, ?, ?)",
            $firstname, $lastname, $title, $constituency, $party);
#        print "!!! $firstname/$lastname/$title/$party --- $constituency\n";
    }

    # Bielections and loyalty changes. Data from here:
    # http://www.parliament.uk/directories/hcio/by_elections.cfm

    insert_mid_depart($dbh, "Jamie", "Cann", "Ipswich", "Lab", "2001-10-15");
    insert_mid_arrive($dbh, "Chris", "Mole", "", "Ipswich", "Lab", "2001-11-22");

    insert_mid_depart($dbh, "Raymond", "Powell", "Ogmore", "Lab", "2001-12-08");
    insert_mid_arrive($dbh, "Huw", "Irranca-Davies", "", "Ogmore", "Lab", "2002-02-14");

    insert_mid_depart($dbh, "Paul", "Marsden", "Shrewsbury & Atcham", "Lab", "2001-12-09");
    insert_mid_arrive($dbh, "Paul", "Marsden", "", "Shrewsbury & Atcham", "LDem", "2001-12-10");
    
    insert_mid_depart($dbh, "Andrew", "Hunter", "Basingstoke", "Con", "2002-10-01");
    insert_mid_arrive($dbh, "Andrew", "Hunter", "", "Basingstoke", "Ind Con", "2002-10-02");

    # no replacement elected for this death yet:
    insert_mid_depart($dbh, "Paul", "Daisley", "Brent East", "Lab", "2003-06-18");

    insert_mid_depart($dbh, "David", "Burnside", "South Antrim", "UU", "2003-06-22");
    insert_mid_depart($dbh, "Jeffrey M", "Donaldson", "Lagan Valley", "UU", "2003-06-22");
    insert_mid_depart($dbh, "Martin", "Smyth", "Belfast South", "UU", "2003-06-22");
    insert_mid_arrive($dbh, "David", "Burnside", "", "South Antrim", "Ind UU", "2003-06-23");
    insert_mid_arrive($dbh, "Jeffrey M", "Donaldson", "", "Lagan Valley", "Ind UU", "2003-06-23");
    insert_mid_arrive($dbh, "Martin", "Smyth", "", "Belfast South", "Ind UU", "2003-06-23");
    
    # set date entered parliament for everyone
    db::query($dbh, 'update pw_mp set entered_house = "2001-06-07" where entered_house = "1000-01-01"');
}

sub insert_mid_depart()
{
    my ($dbh, $first_name, $last_name, $constituency, $party, $left_date) = @_;
    my $sth = db::query($dbh, 'update pw_mp set left_house = ? where first_name = ? and last_name = ? and party = ? and constituency = ? and entered_house <= ? and left_house > ?', $left_date, $first_name, $last_name, $party, $constituency, $left_date, $left_date);
    die "Setting mid-parliament departure date for $first_name $last_name but affected " . $sth->rows . " rows rather than 1" if $sth->rows != 1;
}

sub insert_mid_arrive()
{
    my ($dbh, $first_name, $last_name, $title, $constituency, $party, $appear_date) = @_;
    my $sth = db::query($dbh, 'insert into pw_mp (first_name, last_name, title, constituency, party, entered_house) values (?, ?, ?, ?, ?, ?)', $first_name, $last_name, $title, $constituency, $party, $appear_date);
    die "Adding mid-parliament arrival $first_name $last_name but affected " . $sth->rows . " rows rather than 1" if $sth->rows != 1;
}

1;
