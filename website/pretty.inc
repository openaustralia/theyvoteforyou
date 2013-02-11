<?php

# $Id: pretty.inc,v 1.48 2011/05/10 17:17:27 publicwhip Exp $

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
    else if ($party == "Bp")
        return "Bishop";
    else if ($party == "XB")
        return "Crossbench";

    return $party;
}

function pretty_party_long($party, $house)
{
    $tail = ($house == "commons" ? " MPs" : ($house == "lords" ? " Lords" : "")); 
    if ($party == "Con")
        return "Conservative Party$tail"; 
    if ($party == "Lab")
        return "Labour Party$tail";
    if ($party == "LDem")
        return ($house ? "Liberal Democrat Party$tail" : "Libdem Party");
    if ($party == "Bp")
        return "Anglican Bishops"; 
    if ($party == "XB")
        return "Crossbench$tail";
    if ($party == "DU")
        return "Democratic Unionist".($house ? $tail : "s"); 
    if ($party == "PC")
        return "Plaid Cymru$tail"; 
    if ($party == "UU")
        return "Ulseter Unionist".($house ? $tail : "s"); 
    if ($party == "Ind")
        return "Independent$tail"; 
    if ($party == "Res")
        return "Respect$tail"; 
    if ($party == "SDLP")
        return "SDLP$tail"; 
    if ($party == "SF")
        return "Sinn Fein$tail"; 
    if ($party == "SNP")
        return "Scottish National Party$tail"; 
    return pretty_party_raw($party); 
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
    $words = explode(" ", $phrase);
#    print "<p>words: "; foreach ($words as $word) { print "'$word';"; }
    $lesswords = array_filter($words, "interesting_word");
#    print "<p>lesswords: "; foreach ($lesswords as $word) { print "'$word';"; }
    return $lesswords[array_rand($lesswords)];
}

function searchtip_random_mp($db, $house = "commons")
{
   global $pwpdo;
    $row = $pwpdo->get_single_row("select title, first_name, last_name from pw_mp
        where house = ?
        order by rand() desc limit 1",array($house));
    if (!$row) {
    	return "*no members of $house*";
    }
    $random_mp = trim($row['title'] . " " . $row['first_name'] . " " . $row['last_name']);
    return $random_mp;
}

function searchtip_random_constituency($db)
{
   global $pwpdo;
    $row = $pwpdo->get_single_row("select constituency from pw_mp
        order by rand() desc limit 1",array());
    $random_constituency = random_big_word($row[0]);
    if ($random_constituency == "")
        $random_constituency = "Liverpool";
    $random_constituency = ', "' . $random_constituency . '"';
    return $random_constituency;
}

function searchtip_random_topic($db)
{
    global $pwpdo;
    $row = $pwpdo->get_single_row("select division_name from pw_division
        order by rand() desc limit 1",array());
    if (!$row) {
    	return "*no divisions*";
    }
    $random_topic = random_big_word($row[0]);
    if ($random_topic == "")
        $random_topic = "Trade";
    return $random_topic;
}

function percentise($num)
{
    if ($num == "")
        $num = "n/a";
    else
        $num .= "%";
    return $num;
}

function percentise_votes($num, $outof)
{
	$pcent = "";
	if ($outof != 0)
		$pcent = ", <b>".number_format(100 * $num / $outof, 1)."%</b>";
	$strout = ($num != 1 ? ' votes out of ' : ' vote out of ');
	return $num.$strout.$outof.$pcent;
}

function percentise_votes_short($num, $outof)
{
	if ($outof == 0 or $num === "")
		return "n/a";
	return number_format(100 * $num / $outof, 1)."%";
}

function make_percent($a, $b)
{
    if ($b == 0)
        $frac = "";
    else
        $frac = sprintf("%6.1f", 100*$a/$b);

    return $frac;
}

// This function from Phil Gyford
function trim_characters ($text, $start, $length) {
	// Pass it a string, a numeric start position and a numeric length.
	// If the start position is > 0, the string will be trimmed to start at the
	// nearest word boundary after (or at) that position.
	// If the string is then longer than $length, it will be trimmed to the nearest
	// word boundary below (or at) that length.
	// If either end is trimmed, ellipses will be added.
	// The modified string is then returned - its *maximum* length is $length.
	// HTML is always stripped (must be for trimming to prevent broken tags).

	$text = strip_tags($text);

	// Trim start.
	if ($start > 0) {
		$text = substr($text, $start);
		
		// Word boundary.         
		if (preg_match ("/.+?\b(.*)/", $text, $matches)) {
			$text = $matches[1];
			// Strip spare space at the start.
			$text = preg_replace ("/^\s/", '', $text);
		}
		$text = '...' . $text;
	}
	
	// Trim end.
	if (strlen($text) > $length) {

		// Allow space for ellipsis.
		$text = substr($text, 0, $length - 3); 

		// Word boundary.         
		if (preg_match ("/(.*)\b.+/", $text, $matches)) {
			$text = $matches[1];
			// Strip spare space at the end.
			$text = preg_replace ("/\s$/", '', $text);
		}
		// We don't want to use the HTML entity for an ellipsis (&#8230;), because then 
		// it screws up when we subsequently use htmlentities() to print the returned
		// string!
		$text .= '...'; 
	}
	
	return $text;
}

// This function from http://uk2.php.net/wordwrap
/**
 * soft_hypen() inserts soft hyphens (or user defined) in words that exceed certain length.
 *
 * @param $text    Text to hyphenate.
 * @param $max    Max word size.
 * @param $char Hyphenate character.  Defaults to HTML soft hyphen �.
 * @return    The text with inserted soft hyphens.
 **/
function soft_hyphen($text, $max, $char = "- <br>")
{
   $words = explode(' ', $text);
   foreach($words as $key => $word)
   {
       $length = strlen($word);
       if($length > $max)
           $word = chunk_split($word, floor($length/ceil($length/$max)), $char);
       $words[$key] = $word;
   }
   return implode(' ', $words);
} 

/* Safe tag stripping code from Matthew Somerville, thanks Matthew! */

$guy_c = array('lt'=>'[[[', 'gt'=>']]]', 'quot'=>'{|}'); /* Let's hope 
no-one ever tries to use these in text... */
$guy_cq = array('lt'=>'\[\[\[', 'gt'=>'\]\]\]', 'quot'=>'\{\|\}');

/* Removes all non-ISO characters, escapes all HTML entities */
function safehtml($in) {
    return htmlentities($in,ENT_COMPAT,'UTF-8');
}

/* Removes all HTML and escapes HTML entities */
function strip_all($str) {
    return safehtml(strip_tags($str));
}

function guy_formdisplay($str) {
    global $guy_c;
    return str_replace(array($guy_c['lt'], $guy_c['gt'], 
$guy_c['quot']),array('&lt;','&gt;','&quot;'),$str);
}

/* Used upon submission; only keeps allowed HTML (see array below) */
function guy_strip_bad($str, $mode='') {
    global $guy_c;
    $html_allowed = array('a', 'b', 'i', 'p', 'ol', 'ul', 'li', 'blockquote', 'br', 'em', 'sup', 'sub');
	$html_allowed_regexp = join('|',$html_allowed);
	$html_allowed_striptags = '<'.join('><',$html_allowed).'>';
	$str = strip_tags($str,$html_allowed_striptags);
	$str = preg_replace_callback("/<($html_allowed_regexp)\b(.*?)>/si",'guy_attrcheck',$str);
	$str = preg_replace('/<\/([^ 
>]+)[^>]*>/si',$guy_c['lt'].'/$1'.$guy_c['gt'],$str);
	$str = preg_replace('#^\s+$#m','',$str);
	$str = safehtml($str);
	return $str;
}

function guy_mangle_ip($ipnum)
{
    $ipm = preg_replace("/\./", "", $ipnum);
    return (int)((int)($ipm)/3);
}

/* PRIVATE; only keeps allowed attributes of allowed HTML */
function guy_attrcheck($arr) {
	global $guy_c;
	$element = strtolower($arr[1]); $attributes = $arr[2];
	$nosp = ''; $sp = 'title|class|id|onclick'; $dims = '';
	$ok = array();

	if ($element == 'a') {
		$nosp = 'href|hreflang|name|lang';
	} elseif ($element == 'img') {
		$nosp = 'longdesc|src|align';
		$sp .= '|class|alt';
		if (!preg_match('/alt/i',$attributes)) {
			$ok = array('alt={|}{|}');
		}
		preg_match("/src\s*=\s*\"([^\s\">]+)\"/is",$attributes,$matches);
		if (isset($matches[1])) {
			$dims = guy_imagedims($matches[1]);
		} else {
			preg_match("/src\s*=\s*'([^\s'>]+)'/is",$attributes,$matches);
			if (isset($matches[1])) {
				$dims = guy_imagedims($matches[1]);
			} else {
				preg_match("/src\s*=\s*([^'\"][^\s>]+)/is",$attributes,$matches);
				if (isset($matches[1])) {
					$dims = guy_imagedims($matches[1]);
				}
			}
		}
	} elseif ($element == 'ins' || $element == 'del') {
		$nosp = 'cite|datetime|lang';
	} elseif ($element == 'blockquote' || $element == 'q') {
		$nosp = "cite|lang";
	} elseif ($element == 'br' || $element == 'news' || $element == 
	'column') {
		$sp='';
	} elseif ($element == 'span') {
		$sp .= '|class';
		$nosp = 'lang';
	} elseif ($element == 'form') {
		$sp = '';
		$nosp = 'cc|counter';
	} elseif ($element == 'submenu') {
		$sp = '';
		$nosp = 'level';
	} elseif ($element == 'ol') {
		$nosp = 'type';
	} else {
		$nosp = "lang";
	}

	if ($nosp) {
		preg_match_all("/(?:$nosp)\s*=\s*\"[^\s\">]+\"/is",$attributes,$matches);
		$ok = 
		array_merge($ok,str_replace('"',$guy_c['quot'],$matches[0]));
		preg_match_all("/(?:$nosp)\s*=\s*'[^\s'>]+'/is",$attributes,$matches);
		$ok = array_merge($ok,$matches[0]);
		preg_match_all("/(?:$nosp)\s*=\s*[^\s>'\"][^\s>]*/is",$attributes,$matches);
		$ok = array_merge($ok,$matches[0]);
	}
	if ($sp) {	
		preg_match_all("/(?:$sp)\s*=\s*\"[^\"]*\"/is",$attributes,$matches);
		$ok = 
		array_merge($ok,str_replace('"',$guy_c['quot'],$matches[0]));
		preg_match_all("/(?:$sp)\s*=\s*'[^']*'/is",$attributes,$matches);
		$ok = array_merge($ok,$matches[0]);
		preg_match_all("/(?:$sp)\s*=\s*[^\s>'\"][^\s>]*/is",$attributes,$matches);
		$ok = array_merge($ok,$matches[0]);
	}
	$ok = join(' ',$ok);
	return $guy_c['lt'] . $element . ($ok ? " $ok" : '') . ($dims ? ' 
'.str_replace('"',$guy_c['quot'],$dims) : '') .$guy_c['gt'];
}

/* PRIVATE; finds image dimensions, if possible */
function guy_imagedims($src) {
	if (substr($src,0,1)=='/') $src = 
substr_replace($src,$_SERVER['DOCUMENT_ROOT'].'/',0,1);
	if (is_file($src)) {
		$wh = @GetImageSize($src);
		return $wh[3];
	}
	return '';
}

/* Used upon generation; does only minimal replacement */
function guy2html($input) {
	global $guy_cq;
	$patterns = array("/&amp;(#?[A-Za-z0-9]+?;)/", 
	'/'.$guy_cq['lt'].'/', '/'.$guy_cq['gt'].'/', '/'.$guy_cq['quot'].'/');
	$replace = array("&\\1", '<', '>', '"');
	$input = preg_replace($patterns,$replace,$input);
	return $input;
}

/* make_plural NUMBER SINGULAR PLURAL
 * If NUMBER is 1, return SINGULAR; if NUMBER is not 1, return PLURAL
 * if it's there, otherwise WORD catenated with "s". */
function make_plural($number, $singular, $plural='') {
    if ($number == 1)
        return $singular;
    if ($plural)
        return $plural;
    return $singular . 's';
}

function relative_time ($datetime) {
	// Pass it a 'YYYY-MM-DD HH:MM:SS' and it will return something
	// like "Two hours ago", "Last week", etc.
	
	// http://maniacalrage.net/projects/relative/
	
	if (!preg_match("/\d\d\d\d-\d\d-\d\d \d\d\:\d\d\:\d\d/", $datetime)) {
		return '';
	}

	$in_seconds = strtotime($datetime);
	$now = time();

	$diff 	=  $now - $in_seconds;
	$months	=  floor($diff/2419200);
	$diff 	-= $months * 2419200;
	$weeks 	=  floor($diff/604800);
	$diff	-= $weeks*604800;
	$days 	=  floor($diff/86400);
	$diff 	-= $days * 86400;
	$hours 	=  floor($diff/3600);
	$diff 	-= $hours * 3600;
	$minutes = floor($diff/60);
	$diff 	-= $minutes * 60;
	$seconds = $diff;
    
	
	if ($months > 0) {
		// Over a month old, just show the actual date.
		$date = substr($datetime, 0, 9);
		return date("j M Y", strtotime($date));

	} else {
		$relative_date = '';
		if ($weeks > 0) {
			// Weeks 
			$relative_date .= ($relative_date?', ':'').$weeks.' week'.($weeks>1?'s':'');
		} elseif ($days > 0) {
			// days 
			$relative_date .= ($relative_date?', ':'').$days.' day'.($days>1?'s':'');
		} elseif ($hours > 0) {
			// hours 
			$relative_date .= ($relative_date?', ':'').$hours.' hour'.($hours>1?'s':'');
		} elseif ($minutes > 0) {
			// minutes only
			$relative_date .= ($relative_date?', ':'').$minutes.' minute'.($minutes>1?'s':'');
		} else {
			// seconds only
			$relative_date .= ($relative_date?', ':'').$seconds.' second'.($seconds>1?'s':'');
		}
	}
	
	// Return relative date and add proper verbiage
	return $relative_date.' ago';
	
}

function pretty_minister($row) {
    $position = $row["position"];
    if ($position == "PPS")
        $position = "Parliamentary Private Secretary";
    $responsibility = $row["responsibility"];
    if ($responsibility == "Team PPS")
        $responsibility = "Team";
    if ($responsibility)
        return $position." (".$responsibility."), ".$row["dept"];
    elseif ($position)
        return $position.", ".$row["dept"];
    else
        return "a member of the " . $row["dept"]; // committee membership uses this
}

function pretty_user_name($db, $name, $text = null) {
    global $pwpdo;
    if (!$text)
        $text = $name;
    $row = $pwpdo->get_single_row("select user_id from phpbb_users where username = ?",db_scrub($name));
    if ($row)
        return "<a href=\"/forum/profile.php?mode=viewprofile&u=".$row['user_id']."\">$text</a>";

    return $name;
}

function pretty_distance_to_agreement($distance) {
    $agreement = (1.0 - (float)($distance)) * 100.0;
    return number_format($agreement, 1)."%";
}

function pretty_date($date) {
    return str_replace(" ", "&nbsp;", date("j M Y", strtotime($date)));
}

# from http://news.bbc.co.uk/nol/shared/bsp/hi/vote2004/css/styles.css
global $party_colours;
$party_colours = array(
    "Con" => "#333399",
    "DU" => "#cc6666",
    "Ind" => "#eeeeee",
    "Ind Con" => "#ddddee",
    "Ind Lab" => "#eedddd",
    "Ind UU" => "#ccddee",
    "Lab" => "#cc0000",
    "Lab/Co-op" => "#cc0000",
    "LDem" => "#f1cc0a", #"#ff9900", 
    "PC" => "#33CC33",
    "SDLP" => "#8D9033",
    "SF" => "#2B7255",
    "SNP" => "#FFCC00",
    "UKU" => "#99CCFF",
    "UU" => "#003677",

    "Speaker" => "#999999",
    "Deputy Speaker" => "#999999",
    "CWM" => "#999999",
    "DCWM" => "#999999",
    "SPK" => "#999999",
);

function party_to_colour($party)     {
    global $party_colours;
    if (isset($party_colours[$party])) {
        return $party_colours[$party];
    } else {
        return "#eeeeee";
    }
}

