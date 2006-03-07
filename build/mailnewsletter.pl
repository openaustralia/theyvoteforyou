#!/usr/bin/perl
use strict;
use lib "loader/";

my $text = "website/newsletters/extra6.txt";
my $test_name = "";

#my $type = "dream"; 
my $type = "all";

#$test_name = "Jo Kibble";
$test_name = "Francis Irving";
#$test_name = "Julian Todd";

my $amount = 1000000;

use PublicWhip::Error;
use PublicWhip::DB;
my $dbh = PublicWhip::DB::connect();

# Extra where clause
my $where = "";
if ($test_name ne "") {
    $where = "and real_name = '$test_name'";
}
my $already_clause = "
    left join pw_dyn_newsletters_sent on pw_dyn_newsletters_sent.newsletter_id = pw_dyn_newsletter.newsletter_id 
        and newsletter_name = ?
    left join pw_dyn_user on pw_dyn_newsletter.email = pw_dyn_user.email
    where newsletter_name is null and confirm";

# Create query string
my $query;
if ($type eq "all") {
    $query = "select real_name, pw_dyn_newsletter.email, user_name, pw_dyn_user.user_id, pw_dyn_newsletter.token 
        from pw_dyn_newsletter
        $already_clause $where group by pw_dyn_newsletter.email";

} elsif ($type eq "dream") {
    die "todo with new newsletter system";
    $query = "select real_name, email, user_name, pw_dyn_user.user_id, count(pw_dyn_dreamvote.vote) as count
            from pw_dyn_dreammp, pw_dyn_newsletter, pw_dyn_dreamvote 
                $already_clause and
                pw_dyn_dreammp.user_id = pw_dyn_user.user_id and
                pw_dyn_dreamvote.dream_id = pw_dyn_dreammp.dream_id
                $where
                group by pw_dyn_user.user_id
                order by count desc";
} else {
    die "Choose type"
}
$query .= " limit $amount";

# Send mailshot
my $sth = PublicWhip::DB::query($dbh, $query, $text);
my $all = $sth->fetchall_hashref('user_id');
print "Sending to " . $sth->rows . " people\n";
exit;
foreach my $k (keys %$all)
{
    my $data = $all->{$k};

    my $email = $data->{'email'};
    my $newsletter_id = $data->{'newsletter_id'};
    my $username = $data->{'user_name'};
    my $realname = $data->{'real_name'};
    my $userid = $data->{'user_id'};
    my $dreamcount = $data->{'count'};

    $realname =~ s/@/(at)/;
    my $to = $realname . " <" . $email . ">";

    print "Sending to $to who is $username";
    print " (dream count $dreamcount)" if ($type eq "dream");
    print "...";

    open(SENDMAIL, "|/usr/lib/sendmail -oi -t") or die "Can't fork for sendmail: $!\n";
    print SENDMAIL <<"EOF";
From: Public Whip Team <team\@publicwhip.org.uk>
To: $to
EOF

    open (TEXT, $text) || die "Can't open newsletter $text : $!";
    while (<TEXT>) {
            print SENDMAIL $_;
    }

    print SENDMAIL "\nYou are subscribed as user $username with email $email\n";

    close(SENDMAIL) or die "sendmail didn't close nicely";

    PublicWhip::DB::query($dbh, "insert into pw_dyn_newsletters_sent (newsletter_id, newsletter_name)
            values (?, ?)", $newsletter_id, $text);

    print "done\n";

    sleep 2; # One second probably enough
}

