# $Id: Content.pm,v 1.1 2004/06/08 11:50:48 frabcus Exp $
# For each day which we have the start URL for (from PublicWhip::FindDays.pm),
# downloads the transcript for the entire day and stores it in the
# database as one HTML file.

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

package PublicWhip::Content;
use strict;

use WWW::Mechanize;
use HTML::TokeParser;
use HTTP::Status;
use Data::Dumper;
use PublicWhip::Divisions;
use PublicWhip::Error;

sub fetch_day_content {
    my $dbh   = shift;
    my $agent = shift;
    my $date  = shift;

    PublicWhip::Error::die(
        "Error getting day index URL " . $agent->response->status_line,
        $agent->uri() )
      unless $agent->success;

    my $all_content = "";
    do {
        PublicWhip::Error::log( "$date debate page read",
            $agent->uri(), ERR_USEFUL );

        my $content = $agent->content();
        if ( $content !~ m/<hr>(.*)<hr>/si ) {

            # print Dumper($content);
            PublicWhip::Error::die( "Error finding <hr> demarkers in content",
                $agent->uri() );
        }
        $all_content .= "\n<!-- Public Whip source " . $agent->uri() . " -->\n";
        $all_content .= $1;

        my @link = $agent->find_link( text => "Next Section" );
    } while ( $agent->follow_link( text => "Next Section" ) );

    # remove strange hyphens
    $all_content =~ s/&#150;/-/g;
    $all_content =~ s/&#151;/-/g;

    PublicWhip::DB::query(
        $dbh, "insert into pw_debate_content 
        (day_date, content, download_date) values
        (?, ?, NOW())", $date, $all_content
    );
}

1;
