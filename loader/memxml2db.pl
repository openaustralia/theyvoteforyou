#!/usr/bin/perl -w
use strict;
use lib "PublicWhip";

# $Id: memxml2db.pl,v 1.1 2004/06/19 08:22:22 frabcus Exp $

# Convert all-members.xml into the database format for Public Whip website

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use XML::Twig;
use HTML::Entities;

use PublicWhip::Error;
use PublicWhip::DB;
my $dbh = PublicWhip::DB::connect();

my $sth = PublicWhip::DB::query($dbh, "delete from pw_mp");
my %membertoperson;

my $twig = XML::Twig->new(
    twig_handlers => { 'member' => \&loadmember, 'person' => \&loadperson }, 
    output_filter => 'safe');
$twig->parsefile("../members/people.xml");
$twig->parsefile("../members/all-members.xml");

sub loadperson
{
	my ($twig, $person) = @_;
    my $curperson = $person->att('id');

    for (my $office = $person->first_child('office'); $office;
        $office = $office->next_sibling('office'))
    {
        $membertoperson{$office->att('id')} = $curperson;
    }
}

sub loadmember
{ 
	my ($twig, $memb) = @_;

    my $id = $memb->att('id');
    $id =~ s#uk.org.publicwhip/member/##;

    my $person = $membertoperson{$memb->att('id')};
    die "mp " . $id . " " . $memb->att('firstname') . " " . $memb->att('lastname') . " has no person" if !defined($person);
    $person =~ s#uk.org.publicwhip/person/##;

    # We encode entities as e.g. &Ouml;, as otherwise non-ASCII characters
    # get lost somewhere between Perl, the database and the browser.
    # Just done for names (not constituency and party) as they are the
    # only place to have accents, and constituencies have & signs and
    # the postcode search matching system uses them.
    my $sth = PublicWhip::DB::query($dbh, "insert into pw_mp (first_name, last_name, title, constituency, party, 
        entered_house, left_house, entered_reason, left_reason, mp_id, person) values
        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
        encode_entities($memb->att('firstname')), 
        encode_entities($memb->att('lastname')), 
        $memb->att('title'), 
        encode_entities($memb->att('constituency')), 
        $memb->att('party'), 
        $memb->att('fromdate'), 
        $memb->att('todate'), 
        $memb->att('fromwhy'), 
        $memb->att('towhy'), 
        $id,
        $person,
        );
}

