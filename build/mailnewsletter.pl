#!/usr/bin/perl
use strict;
use lib "loader/";

my $text = "website/newsletters/extra10.txt";
my $test_email = "";

#my $type = "dream"; 
my $type = "all";

#$test_email = 'frabcus@fastmail.fm';
#$test_email = 'francis@flourish.org';
#$test_email = 'julian@publicwhip.org.uk';

my $amount = 1000000;

use PublicWhip::Error;
use PublicWhip::DB;
my $dbh = PublicWhip::DB::connect();

# Extra where clause
my $where = "";
if ($test_email ne "") {
    $where = "and pw_dyn_newsletter.email = '$test_email'";
}
my $already_clause = "
    left join pw_dyn_newsletters_sent on 
        pw_dyn_newsletters_sent.newsletter_id = pw_dyn_newsletter.newsletter_id 
        and newsletter_name = ?
    left join pw_dyn_user on pw_dyn_newsletter.email = pw_dyn_user.email
    where newsletter_name is null and confirm";

# Create query string
my $query;
if ($type eq "all") {
    $query = "select real_name, pw_dyn_newsletter.email, user_name, pw_dyn_user.user_id, 
        pw_dyn_newsletter.token as token, pw_dyn_newsletter.newsletter_id as newsletter_id
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
my $all = $sth->fetchall_hashref('email');
print "Sending to " . $sth->rows . " people\n";
foreach my $k (keys %$all)
{
    my $data = $all->{$k};

    my $email = $data->{'email'};
    my $newsletter_id = $data->{'newsletter_id'};
    my $username = $data->{'user_name'};
    my $realname = $data->{'real_name'};
    my $userid = $data->{'user_id'};
    my $dreamcount = $data->{'count'};
    my $token = $data->{'token'};

    my $to;
    if ($realname) {
        $realname =~ s/@/(at)/;
        $realname =~ s/,/ /;
        $to = $realname . " <" . $email . ">";
    } else {
        $to = $email;
    }

    print "Sending to $to";
    print " who is $username" if ($username);
    print " (dream count $dreamcount)" if ($type eq "dream");
    print "...";

    open(SENDMAIL, "|/usr/lib/sendmail -oi -t") or die "Can't fork for sendmail: $!\n";

    print SENDMAIL <<"EOF";
From: Public Whip <team\@publicwhip.org.uk>
To: $to
EOF

    open (TEXT, $text) or die "Can't open newsletter $text : $!";
    while (<TEXT>) {
            s/\$TOKEN/$token/g;
            print SENDMAIL $_;
    }

    if ($username) {
        print SENDMAIL "\nYour user name is $username\n";
    }

    close(SENDMAIL) or die "sendmail didn't close nicely";

    PublicWhip::DB::query($dbh, "insert into pw_dyn_newsletters_sent (newsletter_id, newsletter_name)
            values (?, ?)", $newsletter_id, $text);

    print "done\n";

    sleep 0.1; # probably enough :)
}

