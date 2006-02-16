#!/usr/bin/php -q
<?php
# $Id: calc_caches.php,v 1.1 2006/02/16 10:24:14 publicwhip Exp $

# Calculate lots of cache tables, run after update.

# The Public Whip, Copyright (C) 2005 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

require_once "../website/config.php";
require_once "../website/db.inc";
require_once "../website/distances.inc";

$db = new DB();
$db2 = new DB();

count_party_stats($db);

function count_party_stats($dbh) {

    PublicWhip::DB::query( $dbh, "drop table if exists pw_cache_partyinfo" );
    PublicWhip::DB::query(
        $dbh,
        "create table pw_cache_partyinfo (
        party varchar(100) not null,
        house enum('commons', 'lords') not null,
        total_votes int not null
    )"
    );

    my $sth = PublicWhip::DB::query(
        $dbh,
        "select party, house, count(vote) from pw_vote, pw_mp where pw_vote.mp_id =
                pw_mp.mp_id group by party, house"
    );
    while ( my @data = $sth->fetchrow_array() ) {
        my ( $party, $house, $count ) = @data;

        PublicWhip::DB::query(
            $dbh, "insert into pw_cache_partyinfo (party, house, total_votes)
            values (?, ?, ?)", $party, $house, $count
        );
    }
}

