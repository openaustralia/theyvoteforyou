#!/usr/bin/perl -w
use strict;
use lib "../scraper/";

# $Id: xml2db.pl,v 1.1 2004/03/25 13:10:45 frabcus Exp $

# Convert all-members.xml into the database format for Public Whip website

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use XML::Twig;

use error;
use db;
my $dbh = db::connect();

my $sth = db::query($dbh, "delete from pw_mp");

my $twig = XML::Twig->new(twig_handlers => { 'member' => \&loadmember }, output_filter => 'safe');
$twig->parsefile("all-members.xml");

sub loadmember
{ 
	my ($twig, $memb) = @_;

    my $id = $memb->att('id');
    $id =~ s#uk.org.publicwhip/member/##;
    my $sth = db::query($dbh, "insert into pw_mp (first_name, last_name, title, constituency, party, 
        entered_house, left_house, entered_reason, left_reason, mp_id) values
        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
        $memb->att('firstname'), 
        $memb->att('lastname'), 
        $memb->att('title'), 
        $memb->att('constituency'), 
        $memb->att('party'), 
        $memb->att('fromdate'), 
        $memb->att('todate'), 
        $memb->att('fromwhy'), 
        $memb->att('towhy'), 
        $id
        );
}

