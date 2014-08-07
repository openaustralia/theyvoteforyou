sub count_word_frequencies
{
    my $dbh = shift;

    db::query($dbh, "drop table if exists pw_cache_wordfreq");
    db::query($dbh, 
    "create table pw_cache_wordfreq (
        day_date date not null,
        word varchar(200) not null,
        count int not null,
    );");

    my $sth = db::query($dbh, "select day_date, content from pw_debate_content");

    while (my @data = $sth->fetchrow_array())
    {
        my ($date, $content) = @data;
        print "Doing $date\n";

        # Convert to plain text
        require HTML::TreeBuilder;
        my $tree = HTML::TreeBuilder->new->parse($content);

        require HTML::FormatText;
        my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 75);
        my $plain = $formatter->format($tree);

        # Frequency count
        use Text::ExtractWords;
        my %hash = ();
        Text::ExtractWords::words_count(\%hash, $plain);

        # Store in database
        foreach (keys(%hash))
        {
            db::query($dbh, "insert into pw_cache_wordfreq (day_date, word, count) values (?,?,?)",
                $date, $_, $hash{$_});
        }
    }
}


