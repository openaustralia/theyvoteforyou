#!/usr/bin/perl -w
use strict;
use lib "../scraper/";

# $Id: wrans2db.pl,v 1.1 2003/11/25 12:53:17 frabcus Exp $

# Outputs MP list from database as XML file
# (used to migrate from when database was main form of data)

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

use XML::Twig;
use error;
use db;
my $dbh = db::connect();

db::query($dbh, "drop table if exists pw_wrans");
db::query($dbh, 
"create table pw_wrans (
    id int not null,
    day date not null,
    department blob not null,
    title blob not null,

);");
    #party varchar(200) not null,
    #whip_guess enum(\"aye\", \"no\", \"unknown\") not null,
    #unique(division_id, party)
    #division_number int not null,

my $twig = new XML::Twig(TwigHandlers => { wransblock => \&wransblock });
$twig->parsefile( "../pythonexp/test.xml");

sub wransblock
{ 
    my( $twig, $wransblock) = @_;

#    my $g  = $player->first_child( 'g')->text;
#    my $blk= $player->first_child( 'blk')->text;
#    my $sth = db::query($dbh, "insert into pw_cache_whip (division_id, party, whip_guess) values (?, ?, ?)", $divid, $_, $vote);

    my $title = $wransblock->att('title');
    my $department = $wransblock->att('majorheading');
    print "$department $title\n";

    $twig->purge;
}


