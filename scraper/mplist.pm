# $Id: mplist.pm,v 1.5 2003/10/03 17:56:36 frabcus Exp $
# Parses lists of MPs, adds them to database.  Also has
# special code to add in midterm changes such as byelections, 
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

our $current_parliament_end_date;
our $current_parliament_end_reason;

sub insert_mps
{
    my $dbh = shift;

    insert_1997_parliament($dbh);
    insert_2001_parliament($dbh);
}

# Byelections and loyalty changes. Data from here:
# http://www.parliament.uk/directories/hcio/by_elections.cfm
# http://www.election.demon.co.uk/strengths.html

sub insert_1997_parliament()
{
    my $dbh = shift;

    insert_mps_general_election($dbh, "../rawdata/Members1997.htm", "1997-05-01", "2001-05-14", "general_election");

    insert_mid_depart($dbh, "Michael", "Shersby", "Uxbridge", "Con", "1997-05-08", "died");
    insert_mid_depart($dbh, "Gordon", "McMaster", "Paisley South", "Lab", "1997-07-25", "died");
    insert_mid_arrive($dbh, "John", "Randall", "", "Uxbridge", "Con", "1997-07-31", "by_election");
    insert_mid_depart($dbh, "Mark", "Oaten", "Winchester", "LDem", "1997-10-06", "declared_void");
    insert_mid_depart($dbh, "Piers", "Merchant", "Beckenham", "Con", "1997-10-27", "resigned");
    insert_mid_arrive($dbh, "Douglas", "Alexander", "", "Paisley South", "Lab", "1997-11-06", "by_election");
    insert_mid_arrive($dbh, "Jacqui", "Lait", "", "Beckenham", "Con", "1997-11-20", "by_election");
    insert_mid_arrive($dbh, "Mark", "Oaten", "", "Winchester", "LDem", "1997-11-20", "by_election");
    insert_mid_depart($dbh, "Peter", "Temple-Morris", "Leominster", "Con", "1997-11-21", "changed_party");
    insert_mid_arrive($dbh, "Peter", "Temple-Morris", "", "Leominster", "Ind Con", "1997-11-22", "changed_party");
    insert_mid_depart($dbh, "Peter", "Temple-Morris", "Leominster", "Ind Con", "1998-06-20", "changed_party");
    insert_mid_arrive($dbh, "Peter", "Temple-Morris", "", "Leominster", "Lab", "1998-06-21", "changed_party");
    insert_mid_depart($dbh, "Tommy", "Graham", "West Renfrewshire", "Lab", "1998-09-09", "changed_party");
    insert_mid_arrive($dbh, "Tommy", "Graham", "", "West Renfrewshire", "Ind Lab", "1998-09-10", "changed_party");
    insert_mid_depart($dbh, "Fiona", "Jones", "Newark", "Lab", "1999-03-19", "disqualified");
    insert_mid_depart($dbh, "Dennis", "Canavan", "Falkirk West", "Lab", "1999-03-26", "changed_party");
    insert_mid_arrive($dbh, "Dennis", "Canavan", "", "Falkirk West", "Ind", "1999-03-27", "changed_party");
    insert_mid_arrive($dbh, "Fiona", "Jones", "", "Newark", "Lab", "1999-04-29", "reinstated");
    insert_mid_depart($dbh, "Derek", "Fatchett", "Leeds Central", "Lab", "1999-05-09", "died");
    insert_mid_arrive($dbh, "Hilary", "Benn", "", "Leeds Central", "Lab", "1999-06-10", "by_election");
    insert_mid_depart($dbh, "Alastair", "Goodlad", "Eddisbury", "Con", "1999-06-28", "resigned");
    insert_mid_arrive($dbh, "Stephen", "O'Brien", "", "Eddisbury", "Con", "1999-07-22", "by_election");
    insert_mid_depart($dbh, "Roger", "Stott", "Wigan", "Lab", "1999-08-09", "died");
    insert_mid_depart($dbh, "George", "Robertson", "Hamilton South", "Lab", "1999-08-24", "became_peer");
    insert_mid_depart($dbh, "Alan", "Clark", "Kensington & Chelsea", "Con", "1999-09-05", "died");
    insert_mid_arrive($dbh, "Bill", "Tynan", "", "Hamilton South", "Lab", "1999-09-23", "by_election");
    insert_mid_arrive($dbh, "Neil", "Turner", "", "Wigan", "Lab", "1999-09-23", "by_election");
    insert_mid_arrive($dbh, "Michael", "Portillo", "Rt Hon", "Kensington & Chelsea", "Con", "1999-11-25", "by_election");
    insert_mid_depart($dbh, "Shaun", "Woodward", "Witney", "Con", "1999-12-17", "changed_party");
    insert_mid_arrive($dbh, "Shaun", "Woodward", "", "Witney", "Lab", "1999-12-18", "changed_party");
    insert_mid_depart($dbh, "Cynog", "Dafis",  "Ceredigion", "PC", "2000-01-10", "resigned");
    insert_mid_arrive($dbh, "Simon", "Thomas", "", "Ceredigion", "PC", "2000-02-03", "by_election");
    insert_mid_depart($dbh, "Michael", "Colvin", "Romsey", "Con", "2000-02-24", "died");
    insert_mid_depart($dbh, "Ken", "Livingstone", "Brent East", "Lab", "2000-03-06", "changed_party");
    insert_mid_arrive($dbh, "Ken", "Livingstone", "", "Brent East", "Ind", "2000-03-07", "changed_party");
    insert_mid_depart($dbh, "Bernie", "Grant", "Tottenham", "Lab", "2000-04-08", "died");
    insert_mid_depart($dbh, "Clifford", "Forsythe", "South Antrim", "UU", "2000-04-27", "died");
    insert_mid_arrive($dbh, "Sandra", "Gidley", "", "Romsey", "LDem", "2000-05-04", "by_election");
    insert_mid_arrive($dbh, "David", "Lammy", "", "Tottenham", "Lab", "2000-06-22", "by_election");
    insert_mid_depart($dbh, "Audrey", "Wise", "Preston", "Lab", "2000-09-02", "died");
    insert_mid_arrive($dbh, "William", "McCrea", "", "South Antrim", "DU", "2000-09-21", "by_election");
    insert_mid_depart($dbh, "Donald", "Dewar", "Glasgow, Anniesland", "Lab", "2000-10-11", "died");
    insert_mid_depart($dbh, "Betty", "Boothroyd", "West Bromwich West", "SPK", "2000-10-23", "resigned");
    insert_mid_depart($dbh, "Michael", "Martin", "Glasgow, Springburn", "DCWM", "2000-10-23", "changed_party");
    insert_mid_arrive($dbh, "Michael", "Martin", "Rt Hon", "Glasgow, Springburn", "SPK", "2000-10-24", "changed_party");
    insert_mid_depart($dbh, "Sylvia", "Heal", "Halesowen & Rowley Regis", "Lab", "2000-11-01", "changed_party");
    insert_mid_arrive($dbh, "Sylvia", "Heal", "", "Halesowen & Rowley Regis", "SPK", "2000-11-02", "changed_party");
    insert_mid_depart($dbh, "Dennis", "Canavan", "Falkirk West", "Ind", "2000-11-21", "resigned");
    insert_mid_arrive($dbh, "Mark", "Hendrick", "", "Preston", "Lab", "2000-11-23", "by_election");
    insert_mid_arrive($dbh, "Adrian", "Bailey", "", "West Bromwich West", "Lab/Co-op", "2000-11-23", "by_election");
    insert_mid_arrive($dbh, "John", "Robertson", "", "Glasgow, Anniesland", "Lab", "2000-11-23", "by_election");
    insert_mid_arrive($dbh, "Eric", "Joyce", "", "Falkirk West", "Lab", "2000-12-21", "by_election");
    insert_mid_depart($dbh, "Charles", "Wardle", "Bexhill & Battle", "Con", "2001-04-11", "changed_party");
    insert_mid_arrive($dbh, "Charles", "Wardle", "", "Bexhill & Battle", "Ind", "2001-04-12", "changed_party");
}

sub insert_2001_parliament()
{
    my $dbh = shift;

    insert_mps_general_election($dbh, "../rawdata/Members2001.htm", "2001-06-07", "9999-12-31", "still_in_office");

    insert_mid_depart($dbh, "Jamie", "Cann", "Ipswich", "Lab", "2001-10-15", "died");
    insert_mid_arrive($dbh, "Chris", "Mole", "", "Ipswich", "Lab", "2001-11-22", "by_election");

    insert_mid_depart($dbh, "Raymond", "Powell", "Ogmore", "Lab", "2001-12-08", "died");
    insert_mid_arrive($dbh, "Huw", "Irranca-Davies", "", "Ogmore", "Lab", "2002-02-14", "by_election");

    insert_mid_depart($dbh, "Paul", "Marsden", "Shrewsbury & Atcham", "Lab", "2001-12-09", "changed_party");
    insert_mid_arrive($dbh, "Paul", "Marsden", "", "Shrewsbury & Atcham", "LDem", "2001-12-10", "changed_party");
    
    insert_mid_depart($dbh, "Andrew", "Hunter", "Basingstoke", "Con", "2002-10-01", "changed_party");
    insert_mid_arrive($dbh, "Andrew", "Hunter", "", "Basingstoke", "Ind Con", "2002-10-02", "changed_party");

    # no replacement elected for this death yet:
    insert_mid_depart($dbh, "Paul", "Daisley", "Brent East", "Lab", "2003-06-18", "died");
    insert_mid_arrive($dbh, "Sarah", "Teather", "", "Brent East", "LDem", "2003-09-18", "by_election");

    insert_mid_depart($dbh, "David", "Burnside", "South Antrim", "UU", "2003-06-22", "changed_party");
    insert_mid_depart($dbh, "Jeffrey M", "Donaldson", "Lagan Valley", "UU", "2003-06-22", "changed_party");
    insert_mid_depart($dbh, "Martin", "Smyth", "Belfast South", "UU", "2003-06-22", "changed_party");
    insert_mid_arrive($dbh, "David", "Burnside", "", "South Antrim", "Ind UU", "2003-06-23", "changed_party");
    insert_mid_arrive($dbh, "Jeffrey M", "Donaldson", "", "Lagan Valley", "Ind UU", "2003-06-23", "changed_party");
    insert_mid_arrive($dbh, "Martin", "Smyth", "", "Belfast South", "Ind UU", "2003-06-23", "changed_party");
}

sub insert_mps_general_election
{
    my $dbh = shift;
    my $source = shift;
    my $start_date = shift;
    my $end_date = shift;
    my $end_reason = shift;

    $current_parliament_end_date = $end_date;
    $current_parliament_end_reason = $end_reason;

    my $p = HTML::TokeParser->new($source);
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
            title, constituency, party, entered_house, entered_reason, left_house, left_reason) values (?, ?, ?, ?, ?, ?, 'general_election', ?, ?)",
            $firstname, $lastname, $title, $constituency, $party, $start_date, $end_date, $end_reason);
#        print "!!! $firstname/$lastname/$title/$party --- $constituency\n";
    }

}

sub insert_mid_depart()
{
    my ($dbh, $first_name, $last_name, $constituency, $party, $left_date, $left_reason) = @_;
    my $sth = db::query($dbh, "update pw_mp set left_house = ?, left_reason = ? where first_name = ? and last_name = ? and party = ? and constituency = ? and entered_house <= ? and left_house > ?", $left_date, $left_reason, $first_name, $last_name, $party, $constituency, $left_date, $left_date);
    die "Setting mid-parliament departure date for $first_name $last_name but affected " . $sth->rows . " rows rather than 1" if $sth->rows != 1;
}

sub insert_mid_arrive()
{
    my ($dbh, $first_name, $last_name, $title, $constituency, $party, $appear_date, $appear_reason) = @_;
    my $sth = db::query($dbh, "insert into pw_mp (first_name, last_name, title, constituency, party, entered_house, entered_reason, left_house, left_reason) values (?, ?, ?, ?, ?, ?, ?, ?, ?)", $first_name, $last_name, $title, $constituency, $party, $appear_date, $appear_reason, $current_parliament_end_date, $current_parliament_end_reason);
    die "Adding mid-parliament arrival $first_name $last_name but affected " . $sth->rows . " rows rather than 1" if $sth->rows != 1;
}

1;
