<?

# converted from ../pyindex/protodecode.py
# Doing our own indexing using partly the filesystem,
# and partly byte offsets listed in text files.

include "config.inc";

# in/output directories
$pwprotoidxdir = $xmltoppath . '/protoidx';
$pwprotoindexdir = $xmltoppath . '/protoindex';
$pwxmldirs = $xmltoppath . '/scrapedxml';
$pwxmwrans = $pwxmldirs . '/wrans';

function ReadNumberPair($fin)
{
	$ln = fread($fin, 20);
	$matches = preg_match('|\s*(\d+)\s*(\d+)\n$|', $ln, $lng);
	if ($matches != 1)
		#print 'Error in protodecode: ' . $ln . ' does not match pair of numbers ';
        return array(false, false);
	return array(intval($lng[1]), intval($lng[2]));
}

function FetchWrans($wrid)
{
	global $pwxmwrans;
	global $pwprotoidxdir;

	# extract the filenames and the column number
	preg_match("|uk.org.publicwhip/wrans/(.*?)\.(\d+)W(?:\.(\d+))?|", $wrid, $gcolid);

	$fname = sprintf('answers%s.xml', $gcolid[1]);
	$fname = $pwxmwrans . '/' . $fname;

	$fninx = sprintf('answers%s-ind.txt', $gcolid[1]);
	$fninx = $pwprotoidxdir . '/' . $fninx;

	$colnum = intval($gcolid[2]);

	# get the first line of the index to find the column number
	if (!file_exists($fninx))
		return false;
	$finx = fopen($fninx, 'r');
	list($lcolnum, $lse) = ReadNumberPair($finx);
    if (!$lcolnum)
        return false;

	# seek to correct column number
	if ($colnum > $lcolnum)
	{
		fseek($finx, ($colnum - $lcolnum) * 20);
		list($lcolnum, $lse) = ReadNumberPair($finx);
        if (!$lcolnum)
            return false;
	}
	if ($lcolnum != $colnum)
		#print 'Error in protodecode: colnum mismatch';
        return false;

	# length of string we will read out
	list($dummy, $end) = ReadNumberPair($finx);
    if (!$end)
        return false;
	$lgth = $end - $lse;
	fclose($finx);

	# open, seek and snip out the string with the column of answers
	$fwrin = fopen($fname, 'r');
	fseek($fwrin, $lse);
	$wranscol = fread($fwrin, $lgth);
	fclose($fwrin);

	# we have the column.  bail out if we don't need the question
	if ($gcolid[3] == "")
		return $wranscol;
	
	# find specific question
	$regsq = sprintf('|<wrans id="%s"[\s\S]*?</wrans>|', $wrid);
	$matches = preg_match($regsq, $wranscol, $wrg);
	if ($matches != 1)
		#print 'Error in protodecode: not exactly one matching question! Instead, ' . $matches . ' matches. ' . $wrid;
        return false;
	return $wrg[0];
}

function WrapResult($result)
{
	return '<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE publicwhip
[
<!ENTITY ndash   "&#8211;">
<!ENTITY mdash   "&#8212;">
<!ENTITY iexcl   "&#161;">

<!ENTITY egrave "&#232;" >
<!ENTITY eacute "&#233;" >
<!ENTITY ecirc  "&#234;" >
<!ENTITY euml   "&#235;" >
<!ENTITY agrave "&#224;" >
<!ENTITY aacute "&#225;" >
<!ENTITY acirc  "&#226;" >
<!ENTITY ocirc  "&#244;" >
<!ENTITY ouml   "&#246;" >
<!ENTITY Ouml   "&#214;" >
<!ENTITY oacute "&#243;" >
<!ENTITY iacute "&#237;" >
<!ENTITY ccedil "&#231;" >
<!ENTITY uuml   "&#252;" >
<!ENTITY ntilde "&#241;" >

<!ENTITY plusmn "&#177;" >
<!ENTITY pound  "&#163;" >
<!ENTITY middot "&#183;" >
<!ENTITY deg    "&#176;" >

<!ENTITY frac14 "&#188;" >
<!ENTITY frac12 "&#189;" >
<!ENTITY frac34 "&#190;" >

<!ENTITY euro "&#8364;" >
]>

<publicwhip>\n' . 
$result .
"</publicwhip>\n";
}

function DecodeWord($ww)
{
	global $pwprotoindexdir;

	# find the two-letter named file
	$lww = strtolower($ww);
	$fname = $pwprotoindexdir . '/' . substr($lww, 0, 2) . '.txt';
	if (!file_exists($fname))
		return array();

	# open and get the header information
	$finw = fopen($fname, 'r');
	$head = fread($finw, 20);
	$matches = preg_match_all('|\d+|', $head, $headn);
	$nwords = intval($headn[0][0]);
	$wlsz = intval($headn[0][1]);

	# read in the string of words and their indexes
	# (we could search this string with a binary chop)
	$wl = fread($finw, $wlsz + $nwords * 10);

	# search by regular expression for index and given word
	$regww = sprintf('|(\\d+) %s\n|', $lww);
	$matches = preg_match($regww, $wl, $maww);
	$res = array();
	if ($matches > 0)
	{
		# go to the correct location in the column of numbers of that index,
		# and pull it and the subsequent lseek values out
		$ind = intval($maww[1]);
		fseek($finw, 20 + $wlsz + $nwords * 10 + $ind * 10, 0);
		$rg = fread($finw, 20);

		# fetch the string between the range, which will be our list of indexes
		preg_match_all('|\d+|', $rg, $rgn);
		$rglo = intval($rgn[0][0]);
		$rghi = intval($rgn[0][1]);
		fseek($finw, $rglo, 0);

		$sinx = fread($finw, $rghi - $rglo);
		preg_match_all('|\S+|', $sinx, $sinall);
		foreach ($sinall[0] as $sin)
			array_push($res, preg_replace('|[qrt]:|', 'uk.org.publicwhip/wrans/', $sin));
	}

	fclose($finw);
	return $res;
}

/*
# main calling function which demonstrates the searching
word = 'coastguard'
indl = DecodeWord(word)
print indl
for wrid in indl:
	print FetchWrans(wrid)
*/
?>
