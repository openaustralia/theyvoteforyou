<?php

# $Id: pretty.inc,v 1.12 2004/02/10 00:18:32 frabcus Exp $

# The Public Whip, Copyright (C) 2003 Francis Irving and Julian Todd
# This is free software, and you are welcome to redistribute it under
# certain conditions.  However, it comes with ABSOLUTELY NO WARRANTY.
# For details see the file LICENSE.html in the top level of the source.

#function print_link($page, $params)
#{
#    print "<a href=\"" . $page . $params;
#    if ($_GET["parliament"] != "")
#    {
#        if ($parms == "")
#            print "?";
#        else
#            print "&";
#        print urlencode($_GET["parliament"]);
#    }
#    print "\">";
#}

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

function pretty_party($party, $entered_reason="", $left_reason="")
{
    $ret = pretty_party_raw($party);
    if ($entered_reason == "changed_party" || $left_reason == "changed_party")
    {
        $ret = "<span title=\"At some point, this MP changed party. 
They are listed separately for each party 
they were a member of.  This entry contains 
details only for whilst they were in the 
party shown.\">whilst " . $ret . "</span>";
    }
    return $ret;

    # Was going to use a special tag, but they aren't supported
    # very well, so just went for clarity of raw text
    #   "<acronym title=\"$raw\">$party</acronym>";
}

function pretty_parliament_and_party($date, $party, $entered_reason="", $left_reason="")
{
    $ret = parliament_name(date_to_parliament($date)) . " Parliament";
    if ($entered_reason == "changed_party" || $left_reason == "changed_party")
    {
        $ret = $ret . " <span title=\"At some point, this MP changed party.
They are listed separately for each party
they were a member of.  This entry contains 
details only for whilst they were in the 
party shown.\">(whilst " . pretty_party_raw($party) . ")</span>";
    }
    return $ret;
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

function search_example($db, $long)
{
    $row = $db->query_one_row("select first_name, last_name from pw_mp
        order by rand() desc limit 1");
    $random_mp = $row[0] . " " . $row[1];

    if ($long)
    {
        $row = $db->query_one_row("select constituency from pw_mp
            order by rand() desc limit 1");
        $random_constituency = random_big_word($row[0]);
        if ($random_constituency == "")
            $random_constituency = "Liverpool";
        $random_constituency = ', "' . $random_constituency . '"';
    }
    else
        $random_constituency = "";

    $row = $db->query_one_row("select division_name from pw_division
        order by rand() desc limit 1");
    $random_topic = random_big_word($row[0]);
    if ($random_topic == "")
        $random_topic = "Trade";
?>
<p class="search"><i>Example: "OX1 3DR", "<?=$random_mp?>"<?=$random_constituency?> or "<?=$random_topic?>"</i>

<?php
}

function percentise($num)
{
    if ($num == "") 
        $num = "n/a";
    else
        $num .= "%";
    return $num;
}

function make_percent($a, $b)
{
    if ($b == 0)
        $frac = "";
    else
        $frac = sprintf("%6.1f", 100*$a/$b);

    return $frac;
}

?>
