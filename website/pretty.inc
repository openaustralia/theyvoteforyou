<?php

# $Id: pretty.inc,v 1.1 2003/08/14 19:35:48 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

function pretty_row_start($prettyrow, $append = "")
{
    $prettyrow++;
    if ($prettyrow % 2 == 1)
    {
        print "<tr class=\"odd$append\">";
    }
    else
    {
        print "<tr class=\"even$append\">";
    }
    return $prettyrow;
}

function pretty_party_raw($party)
{
    if ($party == "SPK")
        return "Speaker";
    else if ($party == "CWM") # Chairman of Ways and Means (Deputy Speaker)
        return "Deputy Speaker";
    else if ($party == "DCWM") # Deputy Chariman of Ways and Means
        return "Deputy Speaker";

    return $party;
}

function pretty_party($party)
{
    $raw = pretty_party_raw($party);
    return $raw;

    # Was going to use a special tag, but they aren't supported
    # very well, so just went for clarity of raw text
    #   "<acronym title=\"$raw\">$party</acronym>";
}

# Helper function for random_big_word
function interesting_word($word)
{
    if (strlen($word) < 7)
        return false;
    $first_char = substr($word, 0, 1);
    if ($first_char != strtoupper($first_char))
        return false;
    return true;
}

# Returns a randomword from the phrase that is sufficiently long and
# capitalised that it must be interesting.  Removes punctuation from the
# phrase.
function random_big_word($phrase)
{
    $phrase = preg_replace("/[()\[\]0-9.,]/", "", $phrase);
    $words = split(" ", $phrase);
#    print "<p>words: "; foreach ($words as $word) { print "'$word';"; }
    $lesswords = array_filter($words, "interesting_word");
#    print "<p>lesswords: "; foreach ($lesswords as $word) { print "'$word';"; }
    return $lesswords[array_rand($lesswords)];
}

?>
