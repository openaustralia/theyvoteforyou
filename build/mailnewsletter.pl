#!/usr/bin/perl
use strict;
use lib "loader/";

my $text = "website/newsletters/issueX.txt";
#my $test_name = "";
my $test_name = "Francis Irving";
#my $test_name = "Julian Todd";

use PublicWhip::Error;
use PublicWhip::DB;
my $dbh = PublicWhip::DB::connect();

my $query = "select real_name, email, user_name from pw_dyn_user where is_confirmed = 1 ";
if ($test_name ne "")
{
    $query .= "and real_name = '$test_name'";
}
my $sth = PublicWhip::DB::query($dbh, $query);
print "Sending to " . $sth->rows . " people\n";
while (my @data = $sth->fetchrow_array())
{
    my $email = $data[1];
    my $username = $data[2];
    my $realname = $data[0];
    $realname =~ s/@/(at)/;
    my $to = $realname . " <" . $email . ">";

    print "Sending to $to who is $username...";

    open(SENDMAIL, "|/usr/lib/sendmail -oi -t") or die "Can't fork for sendmail: $!\n";
    print SENDMAIL <<"EOF";
From: Francis Irving <francis\@publicwhip.org.uk>
To: $to
EOF

    open (TEXT, $text) || die "Can't open newsletter $text : $!";
    while (<TEXT>) {
            print SENDMAIL $_;
    }

    print SENDMAIL "\nYou are subscribed as user $username with email $email\n";

    close(SENDMAIL) or warn "sendmail didn't close nicely";

    print "done\n";

    sleep 3; # One second probably enough
}

